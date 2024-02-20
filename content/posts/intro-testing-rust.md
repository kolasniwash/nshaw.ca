+++
title = "Intro to testing in rust"
date = "2024-02-20"
+++

Rust has three ways you can test your code: doc tests, private tests, and public tests. In this short post we'll look at when to use each, and an example of testing some private functions.

We can initiate cargo's test suite using the command `cargo test`. By default `cargo test` runs all tests in the project. To run a single test, use `cargo test test_name`.

### Types of tests
How do you know when to use each type of test? Here's a quick guide:

| **Test Type** | **Location**              | **Description**                                                                                                              |
|---------------|---------------------------|------------------------------------------------------------------------------------------------------------------------------|
| Doc Test      | Source file documentation | Use to describe functionality of code in documentation. Doc tests appear as code sampled in generated documentation.         |
| Private Test  | Source file               | Use for private functions. Decorate test mod with `#[cfg(tests)]` and each test with `#[test]`. Not included in final crate. |
| Public Test   | `/tests/` directory       | Use for public module testing. Code is made part of final crate.                                                             |

### Handling tests
When testing we need to tell the test compiler what code to run as tests. We also need to distinguish between indivdual tests, tests that should panic, and tests that are not yet implemented. To do this we use test handlers that decorate our testing module and functions. Here are some of the test handlers we can use:
Different test handlers
- `#[cfg(test)]`: Only compile and include when running test suite
- `#[test]`: Identify a test function
- `#[should_panic]`: A test that should panic
- `#[ignore]`: Ignore a test, for example if it is not yet implemented

## Example testing private functions
Let's look at a simple example of testing a struct from an Advent of Code problem. In the problem we are asked to update Santa's location based on input of specific characters.

To hold Santa's location we define a struct of `Location` with an `x` and `y` coordinate. We also define a method `update_location` to update the location based on the input.


```rust
#[derive(Debug, Clone, Copy, Eq, Hash, PartialEq)]
struct Location {
    x: i32,
    y: i32,
}

impl Location {
    fn new(x: i32, y: i32) -> Location {
        Location { x, y }
    }

    fn update_location(&mut self, step: char) {
        if step == '^' {
            self.y += 1;
        } else if step == 'v' {
            self.y -= 1;
        } else if step == '>' {
            self.x += 1;
        } else if step == '<' {
            self.x -= 1;
        }
    }
}
```

While this is a simple example it allows us to test the private struct using private tests. Within the same source file we define a tests module and decorate it with `#[cfg(test)]`.

First test checks that when an invalid move character is passed, the location does not change.
```rust
    #[test]
    fn test_invalid_move() {
        let mut loc = Location::new(0, 0);
        loc.update_location('a');
        assert_eq!(loc, Location::new(0, 0));
    }
```

The second test asserts that when each of the allows moved characters are passed the location x and y parameters are updated correctly. Also note that in these tests a message is passed to each `assert_eq!`. This helps see which test failed and why.
```rust
    #[test]
    fn test_update_location() {
        let mut loc = Location::new(0, 0);
        loc.update_location('^');
        assert_eq!(loc, Location::new(0, 1), "Failed to move up");
        loc.update_location('v');
        assert_eq!(loc, Location::new(0, 0), "Failed to move down");
        loc.update_location('>');
        assert_eq!(loc, Location::new(1, 0), "Failed to move right");
        loc.update_location('<');
        assert_eq!(loc, Location::new(0, 0), "Failed to move left");
    }
```

Complete code for this example is available [here](https://github.com/kolasniwash/rusty-bits/blob/main/intro-testing/main.rs).