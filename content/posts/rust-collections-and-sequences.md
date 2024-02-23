+++
title = "Overview of rust collections and sequences"
date = "2024-02-23"
+++

This is a loose summary of the Rust `std::collections` [documentation](https://doc.rust-lang.org/std/collections/index.html) formatted for personal reference. Rust offers a range of collection types for different use cases. Reading through the lines in the documentation the underlying theme is the following:
	
>Starting with `Vec` or `HashMap` is almost always good enough until you know more about your performance and needs.

| **Collection**                                                                    | **Description**                                       | **Use**                                                                                                              |
| --------------------------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| [`Vec`](https://doc.rust-lang.org/std/vec/struct.Vec.html)                        | A continuous array. Similar to a Python `List`        | - Resizable, heap allocated array or stack.<br>- Item properties unimportant<br>- Append to end of in order sequence |
| [`VecDeque`](https://doc.rust-lang.org/std/collections/struct.VecDeque.html)      | A double ended growable queue                         | - Insertion at front end back of sequence.<br>- Otherwise same use properties as `Vec`                               |
| [`LinkedList`](https://doc.rust-lang.org/std/collections/struct.LinkedList.html") | A doubly linked list                                  | - Efficient split and append of lists<br>- Avoid amortisation of `Vec` and `VecDeque`                                |
| [`HashMap`](https://doc.rust-lang.org/std/collections/struct.HashMap.html)        | Similar to Python `Dictionary`                        | - Associate keys with values i.e. a cache                                                                            |
| [`BTreeMap`](https://doc.rust-lang.org/std/collections/struct.BTreeMap.html)      | An ordered `HashMap`.                                 | - Need key value pairs with functionality for range slicing, get largest/smallest, and filtering                     |
| [`HashSet`](https://doc.rust-lang.org/std/collections/struct.HashSet.html)        | Similar to Python `Dictionary` with only Hashed keys. | - Hold unique keys i.e. values seen before                                                                           |
| [`BTreeSet`]( https://doc.rust-lang.org/std/collections/struct.BTreeSet.html)     | An ordered `HashSet`.                                 | - Need unique keys with functionality for range slicing, get largest/smallest, and filtering                         |
| [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html)  | A max value priority queue.                           | - Storing largest or highest priority item i.e. a scheduler                                                          |
