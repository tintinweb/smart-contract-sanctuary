//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";
import "./ITrait.sol";

contract Tops is Trait {
  // Skin view
  string private constant STRAPPY_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAMCI8BEk2B0FaMWNpOXR5QYaFvGz8AAAAAXRSTlMAQObYZgAAAHBJREFUSMft07sNgDAMRVE3GSArsILNBCZ9JPD+q5CPEEEYCoQUhHyKV93GhQGMUTmA2CcgYs67BafsvUBEopPqEPgk79RQb0AkJsbiItipgciMONZVA99Qg6GhBiEsSSieBcZ8DzNR/vKewc1f/t8KRdUnFMn/8bQAAAAASUVORK5CYII=";
  string private constant CHEF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAAyMzHNFB3gISLM2drh5unk5uPp7vCYXFw/AAAAAXRSTlMAQObYZgAAARtJREFUSMftlMFOwzAQRK1+BL2DENeqOfSMFJQfwPGdxtlzobvz+x0HWhHXSYS4ZuSDFb+dWSftOrdqVVHHqqque0EJcG5z3aMvAB/OPd0crOSw29wicB8BxP0eGr6qAwxphXFMwPHx86BoBMJTKoxdPOILnqE8iQkxrsyBz5VlLJcUYZlD0HjCNjnYeWCkzSI0CiuVPZyNEb0Ey3roWKbaqCk3bVpZD90JD7ynQRnR0iQD9Nsh0MP/KHOwhlccgLp+q5PGPXh7Nd7CEyh+bPXWGbxX9WH96a/6g2ALQI8FQJYcgIXj9L/sdQ5IyDQgaTZApmOGAWMzDqwmgzgN9AITmWmS04MZceY1cc6wjUmgOBt+i2Ph/W42/EsXOlyFE/2FZvkAAAAASUVORK5CYII=";
  string private constant PREHISTORIC =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVwcABjSBOEYBvhnhXspBT2yXBrTUdUAAAAAXRSTlMAQObYZgAAALxJREFUSMftlD0OwyAMRllygCRcgIQeINg9AP7MXqnh/lcpSdQlJUuXqhJv4cfPlkAYYxqNK7rfCJ6cGtPHQ1DNZ0Gn3hsz0L5YBelxEkiGe4nwNs+OP0soccnJ6xZfQ/Q2nYyc942ujM8ZAqwpVw+gCLcwkvKkWhUWgiMmliHOVSGqJwTAWa5XgAw0OrGCUK9A0SoketDiq0IPFIWhXlEXSMUCXJD27ht/gpb2PLr8gvTu8iv2nyO3m/ySF7D/I9Xi8JzlAAAAAElFTkSuQmCC";
  string private constant TSHIRT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAA2NjY4ODg5OTnWDzk4AAAAAXRSTlMAQObYZgAAALtJREFUOMtjYBgFmMCBEURGIgQOMIPI+egCdegC/+H8cAemUAfm0OX/66ECsVdE/9aGl8dfvw8V+JkaW/8/vzb2fzpU4P/Sq5W19+un1ZdDBepD42P/ViK5qzb07v2v/5EE/t8trf9fiiRQHhpa/f4vkkD89PDculokgfehqdVf/yEJ3A+9ej/3O7It0+K/lt8cTQX4wVV0gSh0gW3oAt/Q+KGh67+jCJRfrf6JqiIs/z+KQOy6+q+DKRQA8fVFNXs3A+0AAAAASUVORK5CYII=";
  string private constant TSHIRT_WHITE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAB9klEQVR42u2a3W7DIAyFnUFFpb3/o04C1YjdzJHrQNM2JKPt+W76k8TKsU8MghABAAAAAAAAAAAAbCTGWJ459kj8GGO5XC6lR7zulFLKM8fuRYQLW+N9vZrDcs4UQiAiImamj3NAMWyN53s+8yEESik1z2Xmah84n89TS6yNJ1UXJ9gkpJRmhxARTdM07ZoAKz6EMIt0zn3nnImIfqx95Wa1M1rJ07HlnFqcEMLVufcw9bI8M9OfWHLOzd9r7rh1cyklcs6R935RUZ2gllC5XpK95oBuTdB7TyEEcs4thNeqy8yUUrr6XwTZ5OlYEl+E1lwjyTvEATHGUrNj7eatXW0F9TFxVKs/9KLrMFgTbwXq3y3x2lF7060H1DqxrXZN+Nq1wztAbrT12XKGnsTo75KcI6rf7RHQ1tZN0IrQMzjv/dwEpWlJYzySLo+ACGpV2w6L0uR0t64NkcxMp9Np/CbYGrZEkBWvq55SImaujuePDGf/5gA9DOpJiK18TWBrUqPj7N0EAQAAAAAAAAAA8HkMt9hg9wP3XhDxoyVAxNsdpr0Y7v0A59zN7bG3T8ARC6FD9YC193zkUbCJkUXUtd3fl3CA3g2yq8c5Z/LeL16Hae0Mv5UDZGlcvy+wELDRAcOMArI3oC0vVa+JP3oLDQAAAADvxy8j65Qi++Br+AAAAABJRU5ErkJggg==";
  string private constant TSHIRT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAB/0lEQVR42u2awW7CMAyGG5qq6t6Syw6cdtszcJjEade9JVHVoOyA/s6YBBiEKMD/XaC0smL7txPVNA0hhBBCCCGEEELIjSzX23DNvf/YX6634f3LhRz2FrkDMPTmqnuX0tm9Ddvmsbd4NIVNPsyO+13zegGQWbft7fZszpofetO4MV2WfhfvAz+fb1EtrzYuaHvIOpSw2riDB9wYDoL0/TGYuwZAOz/0ZnYSjuFayheLhaPy+pRtPBOzM/Tm4NkiCtD16MbQdNY0kw9RdcjF6UXimc6aI3nH1AVbOhidvTwI2XoAujK6tA5QTMoIiHZo8mklwL50NLaWYj1AR1ovXktWqmDyxyrAPb/b20r1h1xk3QVi2dDylNepOs65z989ANohXd+6eaVqUzYwqZTqAyAXHPtMKUMeYuT3VIOsugRkVmUTjHV5OGzbvyyjaaExliTLNigzKJsgnMG2iGvb7p091QN0MKtWQGrbgkPyPuocWXdjOAoGfs9x1C26DcpDEDIYy6w+1KActJ3S5UAIIYQQQgghhJDXwNS2ID0PvPdcwNYWAPkesQTVjcc7a06Ox54+ACVehFbVA879z0f+JUaXytCbs/P/h1CAnAbp1+OTD/McQQcmx1vjKppgbJwGJycf5kmSLhXbmucIALKPeQAcRNZjfYEzA0IIIYTcyi9gyVB9JbpWGAAAAABJRU5ErkJggg==";
  string private constant VERTICAL_RED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVlLXTaT1Dg4t/t7+v6/PkXGOinAAAAAXRSTlMAQObYZgAAAIVJREFUSMft01EKhDAMBNAIHmAhcwGPMDfYQO5/Jq1UwSXdiPpn56vQR5IWItLTE+YrMmxnYwJoWYULACjA7CMyutPcgR9gaxSAu7UBoC3ACkqFqIWu9ywg/Ka9hSZA0wrLlA0wZeDEkKzPDIHWFs0he3rihJt9AEwA7V6LcLOfBvwPXpoZT/Eo1b+hauMAAAAASUVORK5CYII=";
  string private constant VERTICAL_GREEN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVlLXQ4xmPg4t/t7+v6/Pk83kfxAAAAAXRSTlMAQObYZgAAAIVJREFUSMft01EKhDAMBNAIHmAhcwGPMDfYQO5/Jq1UwSXdiPpn56vQR5IWItLTE+YrMmxnYwJoWYULACjA7CMyutPcgR9gaxSAu7UBoC3ACkqFqIWu9ywg/Ka9hSZA0wrLlA0wZeDEkKzPDIHWFs0he3rihJt9AEwA7V6LcLOfBvwPXpoZT/Eo1b+hauMAAAAASUVORK5CYII=";
  string private constant VERTICAL_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC3slA3/oxjg4t/5+/gVaV5HAAAAAXRSTlMAQObYZgAAAJhJREFUSMftlLENwzAMBOkgA7jgCD9BJsgT2n8mU7YDJBYpw3AZXSVAh3+qoEQGg5C3yONzNrstMBamjgDUBLNZ5FmKsRTgV1CrEArEAlbBAOguaCvQEzzCBUsTVA8XbYUmgm4VHtBNYB0yEV5bRTqD7kN2K1gTsiG9gk76zMEgJlz9b3gmhH/DhYpwcQ8CTwRa8zdcqvhTFu2fLhJzL3fyAAAAAElFTkSuQmCC";
  string private constant TURTLENECK_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAA9PT1CQkJGRkYh3l+BAAAAAXRSTlMAQObYZgAAAM1JREFUOMvt0rEKwjAQBmBn3+8KFepocbCbPbTgW6gEqbp0ucGxIMHHENGSjhWHdlTcbIe0zQniA/QfDvJxl5CQXq/Ld4iqWjSw71dVclB8BOs1KAWOOgqaaBACbPFekafhheAV17CBciSQqgXow7DqcOuOBFy5aQF6YOd4In0wOZJGiFuaa/BzUrs4pVhDKmntWgCWBllQdDBuT7SMul/wO4oDckg5BPybDaY3E8JZYoJjnxkUdxMW2cOEOBubgE8Oiu3h5xcDoMx/r/ABd61lED+9l94AAAAASUVORK5CYII=";
  string private constant TURTLENECK_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmz2jCD3mTn4plAa+3z3AAAAAXRSTlMAQObYZgAAAM1JREFUOMvt0rEKwjAQBmBn3+8KFepocbCbPbTgW6gEqbp0ucGxIMHHENGSjhWHdlTcbIe0zQniA/QfDvJxl5CQXq/Ld4iqWjSw71dVclB8BOs1KAWOOgqaaBACbPFekafhheAV17CBciSQqgXow7DqcOuOBFy5aQF6YOd4In0wOZJGiFuaa/BzUrs4pVhDKmntWgCWBllQdDBuT7SMul/wO4oDckg5BPybDaY3E8JZYoJjnxkUdxMW2cOEOBubgE8Oiu3h5xcDoMx/r/ABd61lED+9l94AAAAASUVORK5CYII=";
  string private constant STRIPE_RED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVoAADoSC76UDLg4t/t7+z3+fb+//xTrp1TAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant STRIPE_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVvcm0neeErhfXg4t/t7+z3+fb+//z67CVSAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant STRIPE_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEX7AwDrkw3/oxjg4t/t7+z3+fb+//zA9QaHAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVjb2wKFh8PHiyQBQAZKDb09/M4xg+kAAAAAXRSTlMAQObYZgAAAPhJREFUSMftlEtuwzAMRJ1F9pWiHIADXiCLHsAED9Cg8P2v0pFiI0jNSItsPStJfCL1nWk6dChUWpa0tYEAuE7TfWurDYA8BJ4lAHy1EVx/zncgURB2sZZhf60qv99ZDTWE7Gy9ltkAZSgzyJaEANwl1/AesMtN62yXYooAcLlxODMDgymZzv8AFVG34io6hxnabMvKDN7WMO8BI1B3gdy2uwNSnefFllVBhscphJfNo0ECAXkDHDoUK/SG18c3AmRU4h1w4k+Q6hd0h7hMs4r6R+sL7yyR/7L39B/O0AVYYO4B1Rms9DMUG6zBexloggLp3EfoDR/pD84DPQp5evZaAAAAAElFTkSuQmCC";
  string private constant LUMBER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAABgMhCSLidiQSi6OjFkY2LRVk37zFfc3Nzp6elLjlLzAAAAAXRSTlMAQObYZgAAANtJREFUSMftlL8KwjAQh6O+QGulu5gHsFZ0tVc87C7uxRPs7BuIS1fp0LytsVLon2tFEEHIl+WGH98dJBchDAaWuRCDsgbgA6OyJmICViXAGqxKC8aAuBQiJnKFCBGJUFMLSLnYDEOApZQzKQGkpmlIsiPRCjHoMIyj68sw7TbEhaFzht01AJj0zXDTM7g9huj+xnDOXoZApfoolbYNYWGYsneJuE+yE9EBccsGbM9ZXxzftn3PNk/f8AHsZldh/4ZvGkgD0NiqegNmq5qG1l7+neH5L+QqVz+8/AfiPlMwOCAUmQAAAABJRU5ErkJggg==";
  string private constant COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAkFwY4JwqOHQqmIwhvNxEMVWqJQBIVWm8TZnr+1QAbz5SLAAAAAXRSTlMAQObYZgAAASxJREFUSMftlLFOwzAQhiPxBFnZyMiE1DwAUirlAaqLKx4gcvcepiui7t2K1HC38qSYFqrGdRMxsOXLkEj+8vu3EjvLJiaSwMNN+fusnBAWWXYSyCaE9ZnAqQR4nJ0Eq5fD+FLNSgCsSiBhLxr1MG7zVs0RzaJGq2JJhXqCQyfz0jlTrx1zx8ocJ+DzR20w3JGsshCvooSn5hUNgnNOrJKI7wvGmOUuvB8uFBIVFo5Wgc37QUD0ItwGog6u2YX47xLCFIgT3CEBggjtDz1BAZotgO7BbJLfsiiK+8/iSFLI8/z2Lj8y/foTf0B0RPA0liAjgvrhYQ57jgZ6KOlKPfHAGsLWl4EexGI9ddeFUIE8d/b6FOyZ4rPhnLb1zDba2b0ORJenSz8hcTb8L1/HE4qVeT7A/AAAAABJRU5ErkJggg==";
  string private constant HIGHVIS_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAACcnpv7mQD/pAW8vrvCxMHy+gD4/wDT7TsBAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlEGOwjAMRVmVda+AJQ5gS+UCcXsBe9ii6TTdIqDN9XE1KhLUpRfIX0Xy0/d3oni3y8pyhdc9zGdlFyhoPktwALgWh5eDeA6X4tVCdFEmoMueTPeKmIVFFzngcbYWdD9h4BAM+myDXQ0TcCTlidCwcGjQgNuJVIWVP3JY9+EMRNBW6F5Tin1XpzHG2EcXKMvyUZf/coHYp64ZYz+OKbkAIVlIuw2bwn8qwr/aQtJvBb4DwPCDeMB2xQEIhsampHbFISvLl/Nx3xV4A+AtB+WNsu0G+ZJDJASx7bAOWF00fHGYdoMq5+d+1xN/Fj0+ISur7wAAAABJRU5ErkJggg==";
  string private constant POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAGGzMKJkICKUsGLE0eKDMqNUCwsq72yzL23DTj5eFBYsbWAAAAAXRSTlMAQObYZgAAARdJREFUSMftlEFOwzAQRXMF21CJpf9E2XsGWcCONFdI92mEe4NegCNwArY5JTYqC6dxEELd5S0sS3n+HjmjqaqNjUWaqjr+7EVuLtC1IOKn6fi9jiJCCrMUJv/yOQo8y5Fpj87CZgJx48zI7Ec/gFrgVbs8Ad49xLOnEM5we9teC8MuRCFEWGB1NxdoUKfA9q3vDyw1687kRWoa7vuDuJSg6dHWrUEmhDDs4v0hJRiq27qV/AqN9Ak2JRgnCkqpvAYOIdbASZsuzGpoQhgBH9fFn60uxGeWrfU3/sCvDXNzAYp4tXF1B3764LJwB6bnd3ZloTYcKQtx9BBjVdDMAIpCmgtC4BVBQyCqKMTBEF/BmqKwOBv+xRclPU913ozfnwAAAABJRU5ErkJggg==";
  string private constant DOCTOR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAABNTU0SYKEVbriournH2dnW4+Pp6enu7u7y8vL09PQCAr0yAAAAAXRSTlMAQObYZgAAAU9JREFUSMftlEFugzAQRVkmNylHYJ9F0n2P0DtkmaqVYrxqQxb+cwLPP2W/Q1OVyDSq1CUfBAae/e0xM02zaFFV583Grm2yAmya9eO17VYBds16d20DdwD692sjDuphwO59vTXwIvNyHQGwABQwdFvCSD3QaDbawHLBHHg7tU/6ap70dNaL0SbbXtfgJqB7Vj+1NNxZt3El4SiHZhXgL0ObyJ7IDv9wYZM1mOWhfaH39ER3K8cUYD51UYAjEa654AZAGrro7CELo5Zp03CbyyK6RTAH9CGFkCcAmU5tNGiE1OurFG+AMgdZOHJ1s+F4fVCIo8jl11/0B1Vrw09Va8Pk58MdwOYsVlDKYVIbboBLxrmSSnnrtSGiqziMp1XncfRopVBAXlVgtQ/hULJaB3+JgpuSez4WWofNWXwFuvSnzwJBpQEhhnlA6lMO/7f5n/dF3uKgDgDjAAAAAElFTkSuQmCC";
  string private constant SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcTXHw0fqUlkclQ/2RTAAAAAXRSTlMAQObYZgAAAD5JREFUOMtjYBgFmOBdHJpAAzOagAO6wKtqVP6y37d2vZuHJBCWuT1yWxiKGml0e9nQBbjRBVhGI2cUDCIAAPcdC0Sriwc2AAAAAElFTkSuQmCC";

  // Front view
  string private constant FRONT_STRAPPY_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAB5QYZpOXRaMWM8BEk2B0FPX/j/AAAAAXRSTlMAQObYZgAAAEFJREFUGNNjYKAaYGRgEMDBEBRgFAQzlIAAzDBSNlIGM4yBAMwQNjY2BDNcgADMCAUCMEMICFAZykBAiAE3hxIAAIn5CUPRP/A/AAAAAElFTkSuQmCC";
  string private constant FRONT_CHEF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADp7vDk5uPh5ungISLNFB0yMzHM2dqz5iDyAAAAAXRSTlMAQObYZgAAAGRJREFUGNO9jTEKwzAQBO8LcybuFxnUS0VqF35ACH6A/ANjiL6fU94QvM3CDOya/Sl42jaQwbI/VjAnvXg7Q6FJbijNNGkoCYUqOWqokmeOILUOUqtd3U/oz9j2j7ffieeYuzVfCIcMvEFIXXoAAAAASUVORK5CYII=";
  string private constant FRONT_PREHISTORIC =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAD2yXDspBSEYBtjSBPhnhV+54yIAAAAAXRSTlMAQObYZgAAAFlJREFUGNNjYKAmYIQxhKC0oAmUFgqG0KKmqmBGsGGwK5ihahIaBGYYhapC1DiHukJ0OSmpKkPUqDgpgRlKyk4Q7SZKSoJghouRogBEVyCEZggSgNlNDR8BADOYCcf2m7C4AAAAAElFTkSuQmCC";
  string private constant FRONT_TSHIRT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABfSURBVCjP3czBCcNAEEPRt5rUtLj/S8A9zZLD2iYlhOgi9IXEb2gcVvUJjoUxFe00qd6gZdlREp2gtKQMmKC8kfu9aDcopas9oPXVXyDUXl1g0fL1AbW2vyBLei/+Sh92QxnEYz6W1wAAAABJRU5ErkJggg==";
  string private constant FRONT_TSHIRT_WHITE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAQAAACxgDBHAAAAgElEQVQ4y+3Q2wrDIBCE4c8asND3f9RCJBV7kcOakgfoRRZEdMad3+UuSEunKapniuult90wdwqoyK/GG4o6Giqy/dUukqW1WQZtEDMmH0fu3IOgIG3K45c6eH4MZVt1IMB1BI5PHx3yEBD7YGgxi2uGYGmn8xQR6zzqKeCuf6ovmrclCB/qexQAAAAASUVORK5CYII=";
  string private constant FRONT_TSHIRT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABmjfdhifZqkPe4/L/QAAAAAXRSTlMAQObYZgAAAEBJREFUCNdjYCASRDcwrmJY/0LrFcO6WetWMmRGvYplYFi1Hiiz6h2QeLcLxFoFJLJXg1izQMQrIJG5nlgbsAIAPkMTzjoNkgwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_RED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADt7+vaT1D6/Png4t+h3+a4AAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYKASEDIyYGBgMjJiMIICBEPISAhICRkBVYH5DPgZTlikhNCk6AYAf9ELa7EDmbwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_GREEN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADt7+s4xmP6/Png4t9g4G7rAAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYKASEDIyYGBgMjJiMIICBEPISAhICRkBVYH5DPgZTlikhNCk6AYAf9ELa7EDmbwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAD5+/j/oxjslA3g4t9iQy2/AAAAAXRSTlMAQObYZgAAADZJREFUGNNjYKASEBIWYGBgEhICMoRAQBjKEAaKQGghkCohMIXKEEYVccKtxklIWJhaDiYOAAAMrAS1M4ONyAAAAABJRU5ErkJggg==";
  string private constant FRONT_TURTLENECK_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABpSURBVCjPzdCxDQNBCETRdwiCbesKd1sbQOBgT67Akj0/+iMmgf/IdXf12gdK0DUOJTtYnasPCPCZPMXjZamAx7NsYT0XldNk2MrxhMizqZzcmNh2r71MzrL1BXdOmpwXEoxhfv3Gr+cNlQs5SgvhgjUAAAAASUVORK5CYII=";
  string private constant FRONT_TURTLENECK_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD3mTn2jCD4plD1RLbEAAAAAXRSTlMAQObYZgAAAElJREFUCNdjYCASpL17t5QhMy0tjyHv9+51DHnv3gGJ3Tv3AlnPKxnqds/dzZC7rnw3w9ud93YyrHpbvoqBofwuUF9oKLE2YAUASgUcgbsGDRoAAAAASUVORK5CYII=";
  string private constant FRONT_STRIPE_RED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fboSC76UDL+//zg4t8rmtWlAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_STRIPE_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fYneeErhfX+//zg4t8twd8zAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_STRIPE_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fbrkw3/oxj+//zg4t+EruBNAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAAKFh8PHiz09/MZKDaQBQC6OIC8AAAAAXRSTlMAQObYZgAAAGBJREFUGNO1jYEJgDAMBCMuYCoOkOcHUIoLhC5Q3H8Xk3YFfcJzHCER+SgF+7leMCnN7idK4AmEcIIL4UePEmqzDk1Ds2GcXlrslASnSa109VrjdprxhFAMwLZM0DH/5QXVxg9lyNDWVAAAAABJRU5ErkJggg==";
  string private constant FRONT_LUMBER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADRVk26OjFiQShgMhCSLifp6enc3NxkY2L7zFc4dVrNAAAAAXRSTlMAQObYZgAAAFVJREFUGNNjYKASEBIyYmAQERJiUFU1VWBVVlUFiYglCYNFXNVK4SJQNeqlKlCRIogaU7VUkEhamZF4knBaGdBIoIgy2OwmsSQJMMPZcrIztRxMHAAAU3sPFfsn/DYAAAAASUVORK5CYII=";
  string private constant FRONT_COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAAAVWm8TZnoMVWqJQBKmIwiOHQpvNxH+1QA4JwokFwZY6uHRAAAAAXRSTlMAQObYZgAAAG9JREFUGNNjYKASEBJ2DEtLFVJkUDR0Eg0LVTJiUBZyUQxNVRJiUBJyd1YJUTRkUBKsKJZ0VxRkUFQqKRRxFxZiUBRyL9YEMQQFXYpFXASVGIyNQSLGxkAjy4vFy8Fmz5zRORPMWLVi1ipqOZg4AAAIXRUILf2sbAAAAABJRU5ErkJggg==";
  string private constant FRONT_HIGHVIS_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADCxMG8vrv/pAXy+gD4/wD7mQCcnpvRgHh+AAAAAXRSTlMAQObYZgAAAF1JREFUGNNjYKASEFI0dmA1FlJkUFJKDhJNU1JiUFQyc1RJVhICSiUHqZoBpRgYjANFk8HKXR1VQsGM8iCVcjAj1FE1BMwwBioGM8ycVCCKkwNFzKAMVWNqOZg4AAAc8g4MOkwg4gAAAABJRU5ErkJggg==";
  string private constant FRONT_POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAACKUsKJkIqNUDj5eEGLE0GGzP23DSwsq4eKDN1tAz/AAAAAXRSTlMAQObYZgAAAHFJREFUGNOtzjEOwyAQBMD9AofjnkOmh5OQ3Z/c4x9gS0R5jyt+G5QXpPCUW+wu8BDjrGpyhMJ22iMTDvZzjeRQgp3fqRI45EsSOyyU2yon4RXyp9+VsRz5GgnDtK33uxmoiqyiOrq9SPyNtOGpw//5AsJIFHjeSLgRAAAAAElFTkSuQmCC";
  string private constant FRONT_DOCTOR =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAADy8vL09PSournu7u4VbrgSYKHH2dnW4+NNTU3p6elNMf8JAAAAAXRSTlMAQObYZgAAAIBJREFUGNOtz8ENwjAMBdCPlAFqk0TiaCsLVOoAaTCHcssIkdiBEViEQQnJCODTk/1ly8CfimVdThsLlNdQN1HQ+RrbU2igvogglyM0TwzhFNohHZpiLcpQ8aEWVuzWR8U8zHzssL77mxlH6PbQiexoQLObnQTMzBu4D2TA/fzWB4aNEdL4EWwpAAAAAElFTkSuQmCC";
  string private constant FRONT_SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAAlkck0fqUTXHy1QV4JAAAAAXRSTlMAQObYZgAAACBJREFUCNdjYCAWRFYBiddzQUxLEMEHIjhBBA/RZpAOADMCAriGZfwcAAAAAElFTkSuQmCC";

  address public tops2;

  constructor(address _tops2) {
    tops2 = _tops2;

    _tiers = [
      500,
      1000,
      1400,
      1800,
      2100,
      2400,
      2700,
      3000,
      3300,
      3600,
      3900,
      4200,
      4500,
      4800,
      5100,
      5400,
      5700,
      6000,
      6300,
      6600,
      6900,
      7200,
      7500,
      7800,
      8100,
      8300,
      8500,
      8700,
      8900,
      9100,
      9290,
      9470,
      9620,
      9720,
      9820,
      9870,
      9920,
      9970,
      9990,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    view
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return "Strappy Top";
    } else if (traitIndex == 2) {
      return "Chef";
    } else if (traitIndex == 3) {
      return "Prehistoric";
    } else if (traitIndex == 4) {
      return "T-Shirt Black";
    } else if (traitIndex == 5) {
      return "T-Shirt White";
    } else if (traitIndex == 6) {
      return "T-Shirt Blue";
    } else if (traitIndex == 7) {
      return "Vertical Red";
    } else if (traitIndex == 8) {
      return "Vertical Green";
    } else if (traitIndex == 9) {
      return "Vertical Orange";
    } else if (traitIndex == 10) {
      return "Turtleneck Black";
    } else if (traitIndex == 11) {
      return "Turtleneck Orange";
    } else if (traitIndex == 12) {
      return "Stripe Red";
    } else if (traitIndex == 13) {
      return "Stripe Blue";
    } else if (traitIndex == 14) {
      return "Stripe Orange";
    } else if (traitIndex == 15) {
      return "Suit";
    } else if (traitIndex == 16) {
      return "Lumberjack";
    } else if (traitIndex == 17) {
      return "Cowboy";
    } else if (traitIndex == 18) {
      return "High-vis Vest";
    } else if (traitIndex == 19) {
      return "Police";
    } else if (traitIndex == 20) {
      return "Doctor";
    } else if (traitIndex == 21) {
      return "Scarf";
    } else {
      return ITrait(tops2).getName(traitIndex);
    }
  }

  function getSkinLayer(uint256 traitIndex, uint256)
    public
    view
    override
    returns (string memory layer)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return STRAPPY_TOP;
    } else if (traitIndex == 2) {
      return CHEF;
    } else if (traitIndex == 3) {
      return PREHISTORIC;
    } else if (traitIndex == 4) {
      return TSHIRT_BLACK;
    } else if (traitIndex == 5) {
      return TSHIRT_WHITE;
    } else if (traitIndex == 6) {
      return TSHIRT_BLUE;
    } else if (traitIndex == 7) {
      return VERTICAL_RED;
    } else if (traitIndex == 8) {
      return VERTICAL_GREEN;
    } else if (traitIndex == 9) {
      return VERTICAL_ORANGE;
    } else if (traitIndex == 10) {
      return TURTLENECK_BLACK;
    } else if (traitIndex == 11) {
      return TURTLENECK_ORANGE;
    } else if (traitIndex == 12) {
      return STRIPE_RED;
    } else if (traitIndex == 13) {
      return STRIPE_BLUE;
    } else if (traitIndex == 14) {
      return STRIPE_ORANGE;
    } else if (traitIndex == 15) {
      return SUIT;
    } else if (traitIndex == 16) {
      return LUMBER;
    } else if (traitIndex == 17) {
      return COWBOY;
    } else if (traitIndex == 18) {
      return HIGHVIS_JACKET;
    } else if (traitIndex == 19) {
      return POLICE;
    } else if (traitIndex == 20) {
      return DOCTOR;
    } else if (traitIndex == 21) {
      return SCARF;
    } else {
      return ITrait(tops2).getSkinLayer(traitIndex, 0);
    }
  }

  function getFrontLayer(uint256 traitIndex, uint256)
    public
    view
    override
    returns (string memory layer)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return FRONT_STRAPPY_TOP;
    } else if (traitIndex == 2) {
      return FRONT_CHEF;
    } else if (traitIndex == 3) {
      return FRONT_PREHISTORIC;
    } else if (traitIndex == 4) {
      return FRONT_TSHIRT_BLACK;
    } else if (traitIndex == 5) {
      return FRONT_TSHIRT_WHITE;
    } else if (traitIndex == 6) {
      return FRONT_TSHIRT_BLUE;
    } else if (traitIndex == 7) {
      return FRONT_VERTICAL_RED;
    } else if (traitIndex == 8) {
      return FRONT_VERTICAL_GREEN;
    } else if (traitIndex == 9) {
      return FRONT_VERTICAL_ORANGE;
    } else if (traitIndex == 10) {
      return FRONT_TURTLENECK_BLACK;
    } else if (traitIndex == 11) {
      return FRONT_TURTLENECK_ORANGE;
    } else if (traitIndex == 12) {
      return FRONT_STRIPE_RED;
    } else if (traitIndex == 13) {
      return FRONT_STRIPE_BLUE;
    } else if (traitIndex == 14) {
      return FRONT_STRIPE_ORANGE;
    } else if (traitIndex == 15) {
      return FRONT_SUIT;
    } else if (traitIndex == 16) {
      return FRONT_LUMBER;
    } else if (traitIndex == 17) {
      return FRONT_COWBOY;
    } else if (traitIndex == 18) {
      return FRONT_HIGHVIS_JACKET;
    } else if (traitIndex == 19) {
      return FRONT_POLICE;
    } else if (traitIndex == 20) {
      return FRONT_DOCTOR;
    } else if (traitIndex == 21) {
      return FRONT_SCARF;
    } else {
      return ITrait(tops2).getFrontLayer(traitIndex, 0);
    }
  }

  function _getLayer(
    uint256,
    uint256,
    string memory
  ) internal pure override returns (string memory layer) {
    return "";
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./ITrait.sol";

abstract contract Trait is ITrait {
  bool internal _frontArmorTraitsExists = false;
  uint256[] internal _tiers;

  /*
  READ FUNCTIONS
  */

  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    public
    view
    virtual
    override
    returns (string memory layer)
  {
    return _getLayer(traitIndex, layerIndex, "");
  }

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_");
  }

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontArmorLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_ARMOR_");
  }

  function sampleTraitIndex(uint256 rand)
    external
    view
    virtual
    override
    returns (uint256 index)
  {
    rand = rand % 10000;
    for (uint256 i = 0; i < _tiers.length; i++) {
      if (rand < _tiers[i]) {
        return i;
      }
    }
  }

  function _layer(string memory prefix, string memory name)
    internal
    view
    virtual
    returns (string memory trait)
  {
    bytes memory sig = abi.encodeWithSignature(
      string(abi.encodePacked(prefix, name, "()")),
      ""
    );
    (bool success, bytes memory data) = address(this).staticcall(sig);
    return success ? abi.decode(data, (string)) : "";
  }

  function _indexedLayer(
    uint256 layerIndex,
    string memory prefix,
    string memory name
  ) internal view virtual returns (string memory layer) {
    return
      _layer(
        string(abi.encodePacked(prefix, _getLayerPrefix(layerIndex))),
        name
      );
  }

  function _getLayerPrefix(uint256)
    internal
    view
    virtual
    returns (string memory prefix)
  {
    return "";
  }

  /*
  PURE VIRTUAL FUNCTIONS
  */

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view virtual returns (string memory layer);

  /*
  MODIFIERS
  */
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory layer);

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontLayer);

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontArmorLayer);

  function getName(uint256 traitIndex)
    external
    view
    returns (string memory name);

  function sampleTraitIndex(uint256 rand) external view returns (uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}