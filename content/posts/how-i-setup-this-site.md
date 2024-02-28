+++
title = "How I setup this site using Zola, Cloud Run, and Open Tofu"
date = "2024-02-27"
+++

This site started with the simple idea of writing short posts that documented learnings. I had a clear idea of writing notes in [Obsidian](https://obsidian.md/), pushing a Markdown post to GitHub, and CICD magically delivering the writing to the internet.

This broke down into three steps, although the reality was much more opaque.
1. Pick a static site generator
2. Setup cloud infrastructure to host
3. Automate deployment and updating
## Static site generator
Shopping around for a static HTML generator, I was looking for a straight forward framework that allowed me to write in Markdown. Asking the internet, I came across [Zola](https://www.getzola.org/), a static website generator written in Rust that *"makes no assumptions regarding the structure of your site"*.

Setting up Zola was as simple as following the [getting started documentation](https://www.getzola.org/documentation/getting-started/overview/#first-steps-with-zola). Zola uses Rust's `config.toml` configuration pattern to manage site attributes and provides deployment options straight from the documentation. This made the whole process of configuring, applying a template, beautifying locally, and deploying simple and fast. 
## Deployment with GCP Cloud Run
The site is deployed with Cloud Run, a managed compute service from GCP. I decided to go with Cloud Run as my deployment medium for a few reasons.
1. I'm serving static HTML so there's no need to persist data in a database.
2. It's simple. You build a container. Cloud Run will run the container. Perfect for running small apps like this one.
3. Generous free allocation. You only pay when the container is in use.
4. Fast scaling, especially from a cold state.

The whole architecture is simple. Versioned containers are deployed to Google Artefact Registry which each change to the website. When Cloud Run receives a request, it pulls the container from the registry, launches the application, and serves the user's request.

I used OpenTofu to define the infrastructure as code as it allows for checking in infrastructure configuration to version control and for automated deployment. The whole infrastructure breaks down into three parts.
- Cloud Run service description including a IAM role for unauthenticated traffic.
- Storage Bucket to hold OpenTofu backend state.
- Docker registry provider to access container digests.
### Cloud Run service
Cloud Run expects a container that exposes port 8000. The pre-built container layer provided by Zola uses port 80. So we need to specify that in the container template along with the image name.
```terraform
resource "google_cloud_run_v2_service" "default" {
  name     = "blog"
  location = "europe-west1"
  client   = "terraform"

  template {
    containers {
      image = data.google_container_registry_image.webserver_latest.image_url
      ports {
        container_port = 80
      }
    }
  }
}
```

### IAM policy for unauthenticated traffic
By default, Cloud Run services will not be available to users outside your VPC. In this case we want to allow access and create a IAM role allowing the service to be invoked by all users. 
```terraform
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

### Artefact registry container name
In my first attempt I used the `container-name:latest` tag to pull the container from Google Artefact Registry into the Cloud Run build. While this worked it did not update as fast as I'd expect. Pushing a new article would trigger a build and sometimes take hours to show up on the request side.

As a solution I set up the Cloud Run infrastructure template to reference the container by its `sha256_digest` name. Google Artefact Registry allows you to access this by setting up a docker provider that points to your registry.
```terraform
provider "docker" {
  registry_auth {
    address  = "gcr.io"
    username = "oauth2accesstoken"
    password = data.google_client_config.default.access_token
  }
}
```

Once that is available you can use the image's `latest` tag as a reference, and pull the digest value inside a `google_container_registry_image` data object.

```terraform
data "docker_registry_image" "webserver_image" {
  name = "gcr.io/${var.project}/${var.image_name}:latest"
}

data "google_container_registry_image" "webserver_latest" {
  name    = var.image_name
  project = var.project
  digest  = data.docker_registry_image.webserver_image.sha256_digest
}
```

## Automate deployment with GitHub Actions and Open Tofu
The last step to deploying end-to-end was to automate pushing the container to Google Artefact Registry and updating the infrastructure. I used a simple two step GitHub action for this which you can see [here](https://github.com/kolasniwash/nshaw.ca/blob/main/.github/workflows/push-gcr.yml).

For pushing the container to Artefact Registry I used an [existing GitHub Action template](https://github.com/RafikFarhad/push-to-gcr-github-action). It takes care of building the container, connecting to the registry, and uploading the image.

OpenTofu also provides an existing [GitHub action to set up OpenTofu](https://github.com/opentofu/setup-opentofu). Used  with the `google-github-actions/auth@v2` action for authenticating to Google Cloud, deployment is fully automated and smooth.

```yaml
tofu-deploy:
    runs-on: ubuntu-latest
    needs: build-and-push-to-gcr
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCLOUD_SERVICE_KEY }}
      - name: Set up Open Tofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: 1.6.1
      - name: OpenTofu fmt
        working-directory: ./terraform
        run: tofu fmt -check
      - name: OpenTofu init
        working-directory: ./terraform
        run: tofu init -upgrade
      - name: OpenTofu plan
        working-directory: ./terraform
        run: tofu plan -var="project=${{ secrets.GCLOUD_BLOG_PROJECT_ID }}" -var="image_name=${{ secrets.GCP_RUN_IMAGE_NAME }}" -out tofuplan
      - name: Terraform Apply
        working-directory: ./terraform
        run: tofu apply -auto-approve tofuplan
```
