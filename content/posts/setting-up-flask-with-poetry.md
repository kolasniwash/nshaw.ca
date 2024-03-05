+++
title = "Setting up a minimum flask app template"
date = "2024-03-02"
+++

I have limited backend experience with flask, and so I set out to set up a simple flask app with Google login. This is a simple guide to setting up a flask app with Google login using `flask_login` and `flask_sqlalchemy`.

### Project structure
Below is the file structure to use the application factory method where `app` is initialised as its own context.
```
project_root/
├── application_name.py
├── app/
│   └── __init__.py
│   └── routes.py
```

#### Call stack hierarchy
Of the three files listed `application_name.py` is the main entry point from where the `app` package is run and managed within a shell context. Each file has its own purpose described below. 
- `application_name.py` exists outside the context and is the entry point for launching the application
- `__init__.py` provides startup actions when the `app` package is called from inside `application_name.py`
- `routes.py` defines the web paths for the various endpoints in the web application 

As a package Flask works with a core package and a series of extension modules. In this example I use `flask`, `flask-login`, and `flask-blueprints`.

### Entrypoint
The entry point is the file defined in our `.flaskenv` using the `FLASK_APP=application_name.py` variable setting. It's contents are simple, load the `app` package and execute the application factory `create_app()`

```python
# application_name.py
from app import create_app

app = create_app()
```

Launching the app with poetry `poetry run flask run --debug` calls the `applicaiton_name.py` and runs the development webserver.

### Application Factory
The application factory itself is a series of object and function calls that initialises the app and creates the context. We see that it creates a flask `app` object, adds configurations to the app, and makes the app aware of the two flask extensions `login_manager` and `blueprint`. 

Application factory is also used to initialise the database connection via the ORM. Working in a development environment we also add a call to `db.create_all()` that will update or create any table changes or definitions we've made. In a production flow I'd expect table management to be decoupled from the application.

You might notice the import statement `from routes.app import blueprint` as being part of the application factory we are trying to create. If this statement is grouped in the context of the other application imports we'll get a circular import error.

`ImportError: cannot import name 'login_manager' from partially initialized module 'app' (most likely due to a circular import)`

By moving the `blueprint` import inside the `create_app()` factory this import is executed within the new application context and avoids this error.

```python
# app/__init__.py
from flask import Flask
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

from config import Config

login_manager = LoginManager()
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    login_manager.init_app(app)
    db.init_app(app)
    
    with app.app_context():
        db.create_all()
    
    from app.routes import blueprint
    app.register_blueprint(blueprint)
    
    return app
```

### Adding routes
Adding routes is done by registering a blueprint for an associated collection of views. This takes the place of the `app.route()` decorator.

Using blueprints we register a view set to a specific python view. In this case we have it set to `routes.py` when we create the `blueprint` object. Once created, assigning uris is the as using the `app.routes()` decorator.

```python
# app/routes.py
from flask import Blueprint

blueprint = Blueprint('routes', __name__)

@blueprint.route("/")
@blueprint.route("/index")
def index():
    return "I'm alive beaches!"
```

### Resources
This is a simple setup written to remind me how I set up the app the first time. Using `flask_blueprints` allows flexible structure in how your app is built out. Below are several resources I found useful when learning about this topic. You'll find examples of how to build and structure routes, views, and database connections.
- [Mega tutorial covering flask in depth](https://blog.miguelgrinberg.com/post/the-flask-mega-tutorial-part-i-hello-world)
- [GitHub repo Flask application template](https://github.com/nuvic/flask_for_startups/tree/5ae30346da25890a2f94225023ba890b5fcebdd4)
- [Set up tutorial for more advanced file structures](https://dev.to/bredmond1019/flask-application-factory-1j81)