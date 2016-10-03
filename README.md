# AlignAssign

Align the assignment operators within a highlighted area.

Before:
```{r}
a <- 1:5
bbb <- 6:10
c <- letters
```

After:
```{r}
a   <- 1:5
bbb <- 6:10
c   <- letters
```

### What
A very simple aligner for a highlighted region's single caret (`<-`) assignment operators. __It does not "reflow" your code if the alignment breaks the page width__ (it does not do anything like `Ctrl + Shift + /`). This addin also does not treat commented lines differently than uncommented lines. __If there is an assignment operator within a highlighted comment line, then it will either align that operator or align other operators to it.__

### Install
`devtools::install_github("seasmith/AlignAssign")`

### Demos

#### Demo 1
When you highlight the following chunk of code (region) - whether you highlight the entire line or just part of the line - and run the addin...
```{r}
# This is a commented line
# So is this
a <- 1:5
b <- 6:10
copy_a <- a
# More comments
```

...the result will look like this.
```{r}
# This is a commented line
# So is this
a      <- 1:5
b      <- 6:10
copy_a <- a
# More comments
```

#### Demo 2
Be mindful that highling the a chunk of code like the following and running the addin...
```{r}
# This is a commented line with an assignment operator <-
a <- 1:5
b <- 6:10
c <- 11:15
# There is an assignment operator here, too <-
```

...the result will look like this.
```{r}
# This is a commented line with an assignment operator <-
a                                                      <- 1:5
b                                                      <- 6:10
c                                                      <- 11:15
# There is an assignment operator here, too            <-
```
