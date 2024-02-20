+++
title = "Every python one liner I forget and have to google"
date = "2021-02-08"
+++

This is a living post where I document and share all the python one line code blocks. When switching between languages I feel like these are the first things I forget. 

The solution I found was to have a kind of scrap book of examples where I can quickly look up examples. That's what this post is about. Where possible I also comment on use and performance.

### List comprehension and variants
This is the mother of all python one-liners. Iterating through a list, creating a new list in a single line.
```
l = [1,3,5,7]
double_list = [num * 2 for num in l]
```

This defines a new list `double_list` where each element of the original list is multiplied by 2. 
#### Set comprehension
Changing the outer brackets and the above can be turned into a set.
```
l = [1,3,5,5,7]
double_set = {num * 2 for num in l}
```
The example creates `double_set` an object with 4 elements `{2,6,10,14}`.
#### Dictionary comprehension
Similarly we can create a new dictionary in the form of a comprehension using the syntax below.
```
l = [1,3,5,5,7]
double_dict = {num:num * 2 for num in l}
```
This will return a dictionary of the form `{1: 2, 3: 6, 5: 10, 7: 14}`
#### Generator comprehension
A final example we can create a generator for immediate use by using parenthesis enclosing the comprehension.
```
l = [1,3,5,5,7]
double_gen = (num * 2 for num in l)
double_gen.__next__()
```
This will return `2` from the call to the `__next__()` element in the generator. The [Python documentation](https://docs.python.org/3/tutorial/classes.html#generator-expressions) gives the following use case where a generator is passed to `sum()` instead of creating a list first.
`sum(i*i for i in range(10))`

### One line conditionals
Classic one line conditional is a single line `if-else` statement as below.
```
meaning_of_everything = 42
is_meaning_of_everything = True if meaning_of_everything == 42 else False
```

`if-else` statements can be combined with one line comprehensions in the following format.
```
odds = [i for i in range(10) if i % 2 == 1]
```
The above will output odd values only `[1, 3, 5, 7, 9]`.

### Functional arguments
When declaring a  function using the `*args` and `**kwargs` syntax allows passing a list or dictionary of arguments to a function. What if we want to do the opposite? for example we have a list or a dictionary that we want to expand into `*args` or `***kwargs`.

- Expanding a list of arguments: `function(*alist)`
- Expanding a dictionary of keyword arguments: `function(**adict)`