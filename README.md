# solv-sh

Soulver-like calculator for the command line, intended for [Vim](#vim).

Latest version: 1.1.0

Usage:

```sh
./solv.sh "1 + 1 - (2 * 2)
           LINE:-1 + 10
           LINE:-1 * 2
           SUM:-2,-1"

# Output
1 + 1 - (2 * 2)  #= -2
LINE:-1 + 10     #= 8
LINE:-1 * 2      #= 16
SUM:-2,-1        #= 24
```

You can pass `solv-sh` an input that includes previously generated answers and
they will be stripped and recalculated.


You can pipe:

```sh
echo "1 + 1 - (2 * 2)
      LINE:-1 + 10
      LINE:-1 * 2
      SUM:-2,-1" | ./solv.sh
```

## Supported syntax

`solv-sh` essentially tries to make its input
[bc](https://linux.die.net/man/1/bc) friendly (which it uses internally) while
adding support for the following tokens:

- `LINE:relative-line-number`
- `SUM:start-of-range,end-of-range`
- X `as % of` Y
- X `% off` Y
- X `% of` Y

Both LINE and SUM work with relative line numbers, so LINE:-1 means to replace
that token with the calculated value of the line before it, and SUM:-2,-1 means
to replace that token with the sum of the two previously lines.

X and Y correspond to any expression you can make with `bc`, plus the LINE and
SUM tokens above.

## Vim

As `solv-sh` works with relative line numbers it's especially handy to use
within Vim: You can pipe a VISUAL selection of calculations to `solv-sh` by
hitting `!` on your keyboard and entering the path to the script.

## Credits

- Soulver was written by [these guys](https://soulver.app/). You should buy their app.
- `solv-sh` was written by [Conan Theobald](https://github.com/shuckster/).

I hope you found it useful! If so, I like [coffee ☕️](https://www.buymeacoffee.com/shuckster) :)
