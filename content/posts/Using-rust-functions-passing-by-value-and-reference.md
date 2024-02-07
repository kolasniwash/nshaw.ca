+++
title = "Using Rust Functions Passing By Value And Reference"
date = "2024-02-06"
+++
Coming from Python as a main working language thinking about how I pass values around functions as an after thought. My last exposure to thinking about pointers was implementing Fourier transform data processing in C back in university studying Engineering Physics.

Of course working with Rust there's a real benefit to thinking about how the data in your program is managed on the physical memory. Like other low level systems languages, managing data locality and duplication has direct impact on program performance in terms of both time and space.
### What is passing by reference and by value?
Ask for a definition of passing by reference or by value and you'll find a common computer science reference. 

What helped me solidify understanding each the [following metaphor](stackoverflow): 
- By value: I write on a piece of paper and give to you. You own this piece of paper and can do whatever you want with it. I have no ownership of the paper anymore. In Rust that means the variable is no longer available to the outer scope. In order to use the modified vector we need to return the value as a new variable.
- By reference: I write in my notebook and give it to you. You can write in it and change in some way but you have to give the notebook back. I maintain ownership of my notebook. In Rust this means the variable says in the outer scope and is *borrowed* to the inner scope.
### Rust borrow semantics
Rust has strict rules about how the ownership of variables are assigned. This affects how we can think about passing by reference and by value. In Rust the borrow checker asserts [ownership rules](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html#ownership-rules). When borrowing variables the following must be true:
- Is immutable and can have any number of references
- Is mutable and has only one reference

When thinking about passing by value or reference the mutability of the value will dictate how our program handles ownership.
### Passing by reference
We should think about passing by reference whenever working with a data type that:
- Is large and would be expensive to duplicate in memory.
- Doesn't implement the `Copy` trait.

Generally speaking using pass by reference is a good idea. There are specific cases covered below when you might want to pass by value.
#### How to pass by reference
To pass by reference a function declare the arguments with references `&`. In the example below ownership of the `vec` argument stays with the calling scope.

```
fn pass_by_reference_vector_int(vec: &mut Vec<i32>, val: i32) {  
	vec.insert(0, val);  
	vec.push(val);  
}
```

We can also pass in multiple references as in the example below. Here we take two vectors, each a mutable reference.
```
fn pass_by_reference_two_vectors(v1: &mut Vec<i32>, v2: &mut Vec<i32>) {  
	v1.append(v2);  
}
```

From the calling function the use of a pass by reference function would look like below.
```
let mut vector: Vec<i32> = vec![1, 2, 3, 4, 5];  
let val: i32 = 99;  
  
// Mutates vector in place. Vector is available after the function call.  
pass_by_reference_vector_int(&mut vector, val);  
println!("Vector modified in place: {:?}", &vector);
```

### Passing by value
Passing by value can be a design choice that is dependent on the context. As a non-exhaustive list passing by value is preferred in the following cases:
- A copy is small, like with primitive values `bool` and `i32`.
- Want to transfer ownership, such as when original value will go out of scope.
- The function will be used in method chaining.
- To enforce an invariant.
- To force an explicit clone.
To read more about these cases, see this [stack overflow response](stackoverflow). 
#### How to pass by value
When passing by value the function takes ownership of the variable. With ownership passed to the function it is no longer available in the original scope.

We know the value has been passed to the function because:
- there is no `&` to indicate a reference in the argument
- the function returns a vector allowing ownership to transfer back to the original scope

```
fn pass_by_value_vector_int(mut vec: Vec<i32>, val: i32) -> Vec<i32> {  
	vec.insert(0, val);  
	vec.push(val);  
	vec  
}
```

Passing multiple variables into a function by value.
```
fn pass_by_value_two_vectors(mut v1: Vec<i32>, mut v2: Vec<i32>) -> Vec<i32> {
	v1.append(&mut v2);  
	v1  
}
```

In the original scope, we see that the function returns a new variable that can be used.
```
let mut vector: Vec<i32> = vec![1, 2, 3, 4, 5];  
let val: i32 = 99;  

// Mutates the vector inside the function as a new value.  
let returned_vector: Vec<i32> = pass_by_value_vector_int(vector, val);  
println!("Vector returned by function {:?}", returned_vector);
```

Examples in this post are adapted from the [Rust Fundamentals](https://www.coursera.org/learn/rust-fundamentals) course on Coursera. Full working example can be found [here](https://github.com/kolasniwash/rusty-bits/blob/main/pass-by-reference-value/main.rs).