# solv-sh

Soulver-like calculator for the command line, intended for [Vim](#vim).

Latest version: 1.1.1 (2024-03-06)

Usage:

```sh
./solv.sh "a simple sum 1 + 1
           let us multiply that result LINE:-1 * 3
           and sum the previous lines SUM:-2,-1
           as a percentage demo 2 - 1 as % of LINE:+2
           percent off demo (5 * 2) % off 512
           percent of demo 10 % of 256"

# Output
a simple sum 1 + 1                          #= 2
let us multiply that result LINE:-1 * 3     #= 6
and sum the previous lines SUM:-2,-1        #= 8
as a percentage demo 2 - 1 as % of LINE:+2  #= 3.90625
percent off demo (5 * 2) % off 512          #= 460.8
percent of demo 10 % of 256                 #= 25.6
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
to replace that token with the sum of the two previous lines.

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
