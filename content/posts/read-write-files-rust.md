+++
title = "Reading and writing files in Rust"
date = "2024-03-06"
+++
Reading and writing data is an essential aspect of any programming language. Input and output operations on the file system allow new data to be brought into a running program, and persisted to disk when the program terminates. When working with frameworks these operations will often be abstracted for you. That said, having an idea how to do this is good basic knowledge of any language.

## Basic read/write flow

1. Create or open a file pointer object with `std::fs::File::create`
2. Buffer the read/write operation by wrapping the file pointer in a `BufWriter` or `BufReader` (Optional)
3. Call write or read methods passing in the content to be written or a variable to hold the data.

Consider that anything read or written without a `BufWriter` or `BufReader` means that all data will be held in the heap as the operation is executed. When reading large files, for example, this could result in an error where we run out of available memory. Using a buffered reader on the other hand will avoid this kind of error.

### Basic read and write examples
First lets look at simply reading in a whole text object and assigning it to a variable. Following the basic steps, we use `File::open` to create a pointer object to the file in memory. We then create a mutable variable that will hold the contents inside our program. Then we can call the `file.read_to_string` method that takes the reference to our content String variable and will store the entire book in our program's heap memory. 

```rust
fn read_phonebook() -> std::io::Result<String>{
    let mut file = File::open("hitchhikers-guide-to-the-galaxy.txt")?;
    // use String to read because the size is not known at compile time.
    let mut content = String::new();
    file.read_to_string(&mut content)?;
    Ok(content)
}
```

Writing follows the same pattern in reverse. However, when writing we have to distinguish between writing a new file (or overwriting) and appending to an existing file. In the example below we create a new file, and would overwrite existing data if a similar file was already present on the system. 
```rust
fn write_phonebook() -> std::io::Result<()> {
    println!("Create file");
    let mut file = File::create("phonebook.json")?;
    file.write_all(b"Yippee ki yay martha flockers")?;
    Ok(())
}
```

## Working with reading and writing to Json
To read and write Json files we'll need to use the `serde_json` crate. The `serde_json` crate gives us methods for the reading and writing of json objects, among others.

The methods we're interested in for reading and writing are `serde_json::from_reader` and `serde_json::from_writer` respectively. As their name implies each takes a reader or writer object. Following from the basic text example we can then read a json file.

```rust
fn read_json_to_hashmap() -> std::io::Result<HashMap<String, Vec<String>>>{
    let file = File::open("phonehash.json")?;
    let reader = BufReader::new(file);
    let hm_items: HashMap<String, Vec<String>> = serde_json::from_reader(reader)?;
    Ok(hm_items)
}
```
The default return type for `serde_json::from_reader` is a String. In this case we read directly into a `Hashmap<String, Vec<String>>` but could also define our own `struct` that mirrors the expected structure of the json file.

Writing to json follows the same pattern of opening a `Buffwriter` and passing the buffer object to the `serder_json::to_json` method.

```rust
fn write_hashmap_to_json(hm: &mut HashMap<&str, Vec<&str>>) -> std::io::Result<()> {
    let file = File::create("phonehash.json")?;
    let writer = BufWriter::new(file);
    serde_json::to_writer(writer, hm)?;
    Ok(())
}
```

To see how these funcitons all fit together a full example is available on [github](https://github.com/kolasniwash/rusty-bits/blob/main/read-write-files/src/main.rs)
