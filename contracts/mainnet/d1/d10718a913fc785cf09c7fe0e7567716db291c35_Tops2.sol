//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Tops2 is Trait {
  // Skin view
  string public constant SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcTXHw0fqUlkclQ/2RTAAAAAXRSTlMAQObYZgAAAD5JREFUOMtjYBgFmOBdHJpAAzOagAO6wKtqVP6y37d2vZuHJBCWuT1yWxiKGml0e9nQBbjRBVhGI2cUDCIAAPcdC0Sriwc2AAAAAElFTkSuQmCC";
  string public constant HAWAIIAN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEV5cGXWSzDaXUVDsk3s3STu7u4tUiWJAAAAAXRSTlMAQObYZgAAAPdJREFUSMftlLFtxDAMRaUivUiBA5ACB1CAGyCF+iNP+89ydOHCiRwjbeBvwGDxTH3T5k/p1q2lIKW619TWAOz19AVQUsp7rXwBSP95AFDJAMLCyMxNkO0AiM1nxk9vQBUNXaqOA0BDS240xKfToFEZjx3QuGRGfwyNe1xSj0bjiZJdEV+igFwhdAC8efkY84Xa53KOqo/oQIzTdAlM85IFOirzugPXzQNjk3UH61+bBwNvaw/StregmATT+mMDbKMGto73r3/rD9J2AUy7AEguAPwdYIn9jOU9BbpMiygY5wd0ogiQc6ORQdNj+8/TEjrx92z4/3oDTfIk2/rxqAMAAAAASUVORK5CYII=";
  string public constant XMAS_SWEATER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEUAAAAjJCKoHB6/ICQgiSz/tRnn6eYY2nN2AAAAAXRSTlMAQObYZgAAARFJREFUSMftlE2OwyAMhXuFSiP2taPsayMOALlCuy9Ivv8R5nk0lYYI5qezzVtEiHzhGcjz6XTo0FAiRM+x8gjA/HNMI4A/mE+YBgB9byGk7IiqsmDIIj1kA/UVCF3Pgo9VJcZSliUuO0CCYWEyk1JizLmUDlDh80OIKTx4aAEg3N3A7u5DrKK9BV2CVRSwbWBZ/dGfAjtAkmxrQwtswlegZG+ttZRqbW13jhezyprM/HVbU1p7gK5mOMTVQkMB2M6uBkzcbgIBO379Q3/pEz/9MMPo9wH4nwXiKx6rKTBM1Vfl7N0hlymwLN4dYnzdAqlDZ9B5kd4ZFAl83WJdvTukNAVaTUBqm98EWgPKkF9f/jtZK1S1bLGDIQAAAABJRU5ErkJggg==";
  string public constant EVENING_GOWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVhcAAADRgAGzcUNFcNQW4WT4KHuuC10OgWOPt/AAAAAXRSTlMAQObYZgAAAIFJREFUSMft1LsRgCAQRVESCrAFW+B1gOQEUoMdaPvykRF1gUDN9gZEhyVhVgiOu7Uu4ZRC2ArYtg7oTmgCQPuADB7sO+Ccs9KlSDAVkUApaGgVq4CzyhP++nGSYCwiwVBEAmNmn4ldQB5bBRzX3hON0p54M6EJwu8GAAa/A3L9+HbGSEv6sQygUAAAAABJRU5ErkJggg==";
  string public constant POLKADOT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAM1BMVEXQh6JNVPfoQ0v3SVPrQ9Vebfv2SOTzokRX9ENH893l5kDt5+b49knt7+z07u33+fb+//yPK+c7AAAAAXRSTlMAQObYZgAAAStJREFUWMPtleuuhCAMhBd0BS0Off+nPVPQTc6NlfUvY6Jo8KOdEvp4DA0NDTUk9YGf358OuATAPwDntAsgv74DcisFhej7n02vBXEmzYHam9htXhpe2AxxDodEz4FdfirjZRZpAkIB2OyyIFLSEoBMPhQSWhGkDWG3VSZ/hI0t2V1llxxQhy1AkhiZ56yKZRGw+BICLm8iSzdGX1efCXBP5hSkB0BNxS2tJq6ryPUI6JDmnBEjzWBFYQAaej0CGpBoWoy0joAYzcjJdwG2bV0zstW7RnJ1C9cUuGGFURNED1l1xtNTBctact4N8NqOPYChoaGhlthH7h0odsLfA/BsvpcCbgDO1n40anwQPg1gc6uYjg71rVeyTRBAiPefAGSvCVjPGf1h6E99AWGEFEnFUgLuAAAAAElFTkSuQmCC";
  string public constant TANK_TOP_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAD2q1/2rWP3sGiHdzRLAAAAAXRSTlMAQObYZgAAAHhJREFUOMtjYBgFmECAB03AgAVdBQe6CnQtCixoYkAtMjbIAiY2DNZ3kAXsvjB8/4/E3/+29O+9KiSBv9f+5/6PRxK4/vX+99vIWu7+3f/3ez2SwM/3t+99/4sk8P199Nv8OiSBbd/f16MYWr//39Xr20ZTwSggDAAK4iyGdCdywwAAAABJRU5ErkJggg==";
  string public constant SPECIAL_OPS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAAwMi9BQDlXWVaOg2CckG2EvoPKs2rRvIDax5H9LZzGAAAAAXRSTlMAQObYZgAAAcNJREFUSMftVEFu2zAQ1KH5QV5gJ0F7jex7US+h+FbYFNq+Iy60ey1SLPcapFjub7sSZUONDLgP8AiiIHIwmiW1U1VXXPEOi0U/vlXV03HG+Dxhe5yRdIbwMlHA7sInUj4ttu0+EkUQuTPaZnSdBrMyJ5GBQPKs/t6ZvC50S3oAeMqIklB59GvCZmQQFm+xkZcIDefvLCw0ENRYTJICbIMDAgDQr3tk6QohUyYUtfU+Otb7tZvi13tNmEqpdb3a1I4QYxtjiC4Adb3sp+qBwOnQKOcc4n61c0Jo26j6rXdZFLjLRjlTiLv1w21RYF9mURo3lYhJLMQvdy0UhaR/mBixbGoWr4IZYAWwWW36sdQS4mjycelXTW6EEmMizq2ruFI7nkNBZ15GQPRa2w/VTb/09doIV/xHTqBdIEw6+zyh4wuEd+lyhGrwHxlCQiTxTpsRSIjVOuSUmQVpRjD0FjT1B/4W1LlCtoxqlDLy7qNqNyewegsacaLdp2M2THHMCcfjKRumQDo07k7c40/yJp0RPIXEXfjtFNR5FYqqNDjFHy7A56rI4qHhwRAhjtkwRZ8S7m1ZkmHMhn/PoWDIhc83p/m/MbXfpjE6fSMAAAAASUVORK5CYII=";
  string public constant CHEESE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC3augXzzwb/4An/5j3kQasPAAAAAXRSTlMAQObYZgAAAVhJREFUSMftVIFtwzAMC7YP2gsWXTBJBwyg/r9ppGxkWOJ8ELV1AJumaKfktj311KkqemQdM/UPgF3jz7Z9HoBcAz6OGVu0yCosGABYJbLcovhAZvEDoocO90yYcyX2dMtvszIYAR6TgeKTm6sBRoxK20YbcIndixzBuYwMEhgb+xDq6ZxpGOdKIyWIYQJ6iUKkLGPwsWvwG/NA5Ac1mKjJlwj+dvHNK6loFan+YvA3Eq+g8nlJ2KVCPF9qFE55JZapwUNo597mxR68i94xjukhQQV1Vy+88vSiahR0z6o4vainnrqr4UbULSAx/oT3gHZC+H0U4W+8LrY7h4FQCx0lE7tcbW3AC4BWoZnSK958IBYMqSyB4kf+Wgi0ESLVFrsConMBe2eD17WFYky2H9kQ11Nwzhlg0f6uxSm0jyGHTohc3AMBRMjgI00Wic9joPL+PSgB65oNv9GBdukO3kh1AAAAAElFTkSuQmCC";
  string public constant ROBE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVlaWc8NgIQO10ZQGiim1bT1dJSzEMAAAAAAXRSTlMAQObYZgAAARVJREFUSMftVNttxDAM808GOKATUOcFKNwAF3gAI6j3X6VUnB7QQof2+tOfCIHs2BTNPKhSzjgjjToGPufuCaCXsj0A/AFA/p7B8d5KaSvRy+IA3d0sEnGQVU1g5K0vNDotEJEnC72aeAyOvqkcHhCIwOw4DTpZt7QKbWkTUa+KyQCvi3Is3hgwCuGRfWoYEqc8tLW5liVGAESeDMvo+2isG3dy6VA4v70LkwSLWp0+jvgCcNMzSKUYkH6q1lbgOnMKuFzeWrvP/ITh/sCcv/4ZL0TaG14D8K+Atppfm/yvC5YAwN1aDAu7pdS7/bUdY6reEO6LVpDab3p67y05w1ApwuKhJdNQwvFdLciC6+lbSHvDP8cHxI9GIivFm58AAAAASUVORK5CYII=";
  string public constant TRENCH_COAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVoAAA3MyOslk+4olq/q3DAr3/ItX9550JiAAAAAXRSTlMAQObYZgAAAWZJREFUSMftlE1ugzAQhVE4AUrDuoWk6wbs7lO/yb7y+AC0Efc/Qt8k0DaSI1Spy4wRWOLzm/HfK4p73CMbGEfM/YQMcBzH09yXHDCenwnQBUB/FETkpSg8gLGqRkwhAYqLCnB4LAon7hcgqtFFd1HRScHHU1Ud0TuVs4KL00yQkgHq4utQf/rokgQRqESZUyiBXXL6PNQfBIQA2IKkaUmUNeyY96IAq86eMNUg8kaFDgFhqL1GJDGGCfw3wHfZ9Hgf6k0KLDAyQ8Q8i65vDGg5eKidJwBtur7t266/Wkdm36+lFyuhaxtG11wBLhz2642YArKbzaFPa7BWONyP/j3+4hNpCdAFQJYAyI0fpdq1Fjh+sxa0erA754MX0ezRL5XWEH0whexMypR4xz0pkrlCS17rpBzPlnIKKwHNggZilYacwlatfvXmEDE3TwLbQDtjjqxC0ZgnWGvZu7mOZ2dom/b/Nv8LJztuDbfSUiUAAAAASUVORK5CYII=";
  string public constant KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAAA2NjZQOhFKSkpxcXF+fn6ZmZmzs7PAwMDNzc3a2trn5+fKqbdVAAAAAXRSTlMAQObYZgAAATtJREFUSMftlDFug0AQRanT+gaU6bgDIkaufQNiCGmtgHuLHZYWYSZuUlmbdRdFyMDlsovlKKxZk0gp+RJfoHn6I4r5hjFp0qCctzvv8t4ii68Bw/gG6pLTEYDEIytiFbBt58gfO/fatsUyxbYHRNH6+eBLr0JELCWhJMyLMFmthB8AywSSAHpATNaLyhfuVgEALIVUIM5D0nkphtZsZi1VABvSeWnJsXi0wHlsWX9LEH+BzbbzfDAhih7cyo4ix608x7PnALndA178p8ItNrvsc1GfsoZyXu97gGma9x/mWZyymLLd63QCk34hbAm9CaR7xkeAgW5QVpAbY9kLsh/0CzBF2Q9aIIAgRYBEC8hekP2gBcRVyvKYaYHBw1USrk//fxMAtrboB1cLcM6Op0zphp+ijFDG3zeX7y9G9KKihHPtTQAAAABJRU5ErkJggg==";
  string public constant FUR_COAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVjb2xvVjSBYzyGZzzXwqTfzraHrZ6jAAAAAXRSTlMAQObYZgAAASpJREFUSMftlE1uhTAMhNn0AHFeD5Bx3wFwTsBTcgCoff+r1FlQNZSfdo8jRKR8Gk8EnmG4667dsuHN1j14B9DGrAB2gDoMZd2L7AP1G/itoEVVF62lmIpkgDc+ADJ9mT61VCBzFuQOSJAPQyudc1MQ7tsgxWdhZBEkf/mi3mgUPJeUmWVd1CuQRF38nHOT904SeQvYa8RI2Y+59aLeZE5RNTIRIwUkaqsD/F76OcI7y1jpMYUpzP01ExmSuIKIVi+z2rcYSf2C4spipaqVoj0gqN6c/Qn3r3/XP0pwAeAKYL5S4AsHPld84oN9Pj0fTgCIsM/nsYPs+sLpWMHTxZEToHn0AT4x2fIjHyskCkDYZMPPeoQyp/o+HUe6h4NnqR0CxYqah+mfP/4XKss+cE9XuZYAAAAASUVORK5CYII=";
  string public constant HAZMAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAAAlJyQyMzE/QD5MTksApQaMjoumqKXAwr782QD+4Qn/5TXIk3luAAAAAXRSTlMAQObYZgAAAaNJREFUSMftlL9OwzAQxvsKsCGmpl1ctl6k7m0kxI7EE0AHRpAK4gVYiZAq+yYyIN15QyznvBzn/IGUpPAC/aK4if3r3dnKfaPRQQf90mQSx2I0mrUzlubzHpB3gLAHMO1MGQaAogv8RHDkxJKOlL/imY6b5xmLRUcsNRD0Yued5J9oWPL1w8yJL1FcDSBF1hPAIknudAS4c8Ki802E6hEVyi8vjOcYAYXJM4c2hTj2jPKxNMaFLcDjplEFtC+eiqet0SKvr2ZM1nrB7xrKmMRzcfpikIr1xlS7kG4NxOTCW4knyPnNxsSk37s4agRwXOIYoHi/VUBKZOYKAEhTvcHSR4kG7fHpy7j9UwUk6XIFAEmWZed6DDDNsuV8PlE1h5000rXFvVL6C3ExQodGOOhP1d+Qs3s/lQbw/wC+/C/CMOAsVi7hSBAZuQcwIXntMBTtSn3uAcjRa+KFewCqnYKDi1H2ppAdb+iqXcAQQuzt/i4aK4pmpLvo1+DqGjQ/DxfZtjxLiFH6RQKsog2sdrxhF0inK3WB2hsGDrv1idobfqz8C7dBCtwGEfnBAAAAAElFTkSuQmCC";
  string public constant KING =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAuHw09LBQyMzF/Kik/QD6ULi83THaqMi9MTkv/0SLo597w8u9Jhr56AAAAAXRSTlMAQObYZgAAAbFJREFUSMftVLFq3EAQ1Qek8h/Yv2GVy2JIGVQIuxTDYtKlEIQrzTI/oM61UyTdOVwxWxgOx9gzH5W3Wp3N6WSM+3uLRmL27ZvVwLyqOuKIGU5Oc0ySdJcx2yOcneX4UFVfdhlNHxDsfKGEqb4KvxWrAsfHtrkIfZ8sKaKK4rGu00LiwM/tEGLfW2014lq2VmvtnK53CiD4rKBmWUdEUhJHIkWB4t9m8Nz3EEh9v01bbJ+bp3W5EfP3ZxA8xDcrKLjOjYixcyOB6CtK2D3z9WZ1x0xAJAocIpWWqD22gxgz//rpEWNeIb+5/LGlthlaQeblD/IZoSBOTSoL4k+rmA9COxI+PE1tLsDhpx+jMAd0CrcgnQinJ5kQI21WhPM8SquIVrMS/PIb4YLDzXEAjviET8y84dAGZt5wSFjbR1aki5vNcIVBj+y9wavSYZl2+JaHhp3LPjF5wz6hKJATxVDIIaG5DBi4QF2dRLdLhKt/zF0XwmgPfqnEPbzCMPt5LsMC4dYSDCo7Q3aBhRKNmsoQR0zesN+ksnAaFahbaHMBbpD7RAuE4hMwybHf75aY5/8DqyAGq8v83lAAAAAASUVORK5CYII=";
  string public constant ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAAACALq5AAAyMzFvcW59f3yLjYqnqaa+wb3Mzsrm6OXy9PFknsqRAAAAAXRSTlMAQObYZgAAAURJREFUSMftlM1Og0AUhVn4EuoLGJ9Ady4K+gDQJ+Cn7A3YbmtqZtzbuXdWdmHnTnfGBSMv5yBpDJSCSbecCQlwPzhnQg6OM2pUp+4c52x/zkQY9gJI/nQACNwD4HkyefizyILWmImXPH9iosKYqFcDQCMvPw0q9lUySVIhoWkA0sidPYpVGKcWMAcAGtiVwIvlRt8gSbIANYBXJQ0YLFZap0cygCGwAMAMjV32LU3A+pKRagXnaW3QskAFF++MiSXAbT1uheS0vt7MgT7ieNaZAfK55msk0vrbPr09sLA7V1f2pipLnuI2i+Oo+bkYA82BCc6VzpIs8EL3fqzAqH+ICc/rBZAidwDwgwGLIOkdd3SiacBtM1u9bHd0AKiajXRKBln9X0yfxa9JP0DypAwL6t1FFCcLeoumRwHPD5IsefT31z8bKdM3hEelggAAAABJRU5ErkJggg==";
  string public constant HOODIE_GRAY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVoAAAvMS5GSEVOUE1SVFFXWFbLzsrKN/OgAAAAAXRSTlMAQObYZgAAAR1JREFUSMftlEFuxCAMRbOoeoNewDEXwM6+ss0BCqHrbub+V6jTdEYTmhBV6qqanwQh8fjGDjAM3wLX0NMp8ND/ks1m1z6mHeB1GJ6u/SpnQN4L8fWuCnlny+HHs4w01gqsDESmG4AFL++KClSAZc7ozxYoDghqhOgAR5QgjQNf3hQzRaBpD0DhlypuXKtMOrtLAwThugBL6w7+NZkE8bm6Ong4X276EeLOYRIswbaA4gpYUq+D54PzFihsppN6K0weCkxah2VIozUVvJV6HCGSVwkgPrb+Q7/QLCcA1hMgnAK5O0wEy7mw4/kSEmo4XijK6OcScx8oPUAhcRcoHqB0MlnvhuZk32u5GbBYzwG9Duk4TfDLi/wq+Luf/wlrxkv9+hdDjAAAAABJRU5ErkJggg==";
  string public constant RAINBOW =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAKlBMVEUAp0piceXlYmzlbGJilOXlfWJiruXlomJi0+Vi5XZi5bSQ5WLl2GLH5WLil5KjAAAAAXRSTlMAQObYZgAAAI1JREFUSMftlEsNgDAQBWsBC1ggOMABqQUsYAELWMACFrBQLxA40JfMpuFz3MkeephkD9tMCI6DNAf3G4R4zkUb3wiFFTWgCwARRkCEDRAhASKsgAgzIMICiDABIgyACF0GHrvK8K/vPOpEQYj9V6GwAttAnTAFbAN1whSwDdQJU8A2UCdMAdtAnfjv+DulGKU545vqogAAAABJRU5ErkJggg==";
  string public constant CRITENZA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAANlBMVEUAAQAgGhU8LBUjOnAuPW8rWWolXm7sTUT2T0nzg4A1up02yKnuvRSSy/fyxiDr49v47N/27eZWj7W3AAAAAXRSTlMAQObYZgAAAQ9JREFUWMPt1suOgzAMQNHGMXnYxsX//7PjJCMW1RQVWnU2uZsCgiNDI8TtNpvNZgel8QOPx3Xb0lcBfjyevwKk1i/ADAB9x1A152Lb0vbitukhsKwr+hW+5cCSVG0AmblzSCwHACKua0TZAdkBYuwTMD+fAFtmEVUG4CdrrR2oRLGfw/QcCAEx3i3GktcedSC8vIgagHZnLmUATKIA54BYK3PeAcRzgFermd9yrf0Woj/U1wFmBwDMiAfQRvI5TgClFABVJgf8rwsh++OkU4AvGFHEAag04OQERCI74AtAlOdLbjabfSRAzO8BIu8B/P9AezO3IsK1jy6R0gG8CPgHx5ggLZcB6y0J5qKe/dUPdpEN5YqLl3AAAAAASUVORK5CYII=";
  string public constant RAINBOW_FULL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAKlBMVEUAP7RccejkZWnneF9hk+bkfmBmrePnoWFh0+Ne5ndh5bKS5WDm2GHJ5WNmydx0AAAAAXRSTlMAQObYZgAAAMRJREFUSMftlNEJwyAURbOC0AmETuBHvwuZoOAKWaAfrpAVskJW6Apdobu0vjwh3ncjzb+H4Ec4KDz0DEOnA6SUV/+j/PHeuZ3wDHmN8m1c4+V+RmgeMSqeIMKkRIIIs5IIIqzKmyDConwIIrwaiFDshSBCOW8l6JA2ZoIIQZkIQxlwZiRUOzhCfwidvzpxeFXCTTLwqJ7+KaF5BHbCCNgJI2AnjICdMAJ2wgi0DXuwE0bATpAh1Z2wY4ZOGAE7cbgDtuELU+oOmmkBE30AAAAASUVORK5CYII=";

  // Front view
  string public constant FRONT_SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAAlkck0fqUTXHy1QV4JAAAAAXRSTlMAQObYZgAAACBJREFUCNdjYCAWRFYBiddzQUxLEMEHIjhBBA/RZpAOADMCAriGZfwcAAAAAElFTkSuQmCC";
  string public constant FRONT_HAWAIIAN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAADaXUXWSzBDsk3u7u7s3SQqBdx9AAAAAXRSTlMAQObYZgAAAFlJREFUGNNjYKASEBJWUWBSElFkUHR0dWBSdHViUAkRUWASVlEBiggpMAkJujIIKSsqMDkaqQCVOyqwhID1mQBFwAxHBSZBMEMZJhIEU6MIE1ECWkEtBxMHAEvwCWg6Yn3KAAAAAElFTkSuQmCC";
  string public constant FRONT_XMAS_SWEATER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAACoHB6/ICTn6eYgiSwjJCL/tRm6iBi8AAAAAXRSTlMAQObYZgAAAGJJREFUGNOtjtEJwCAMRLNCUhzgYhxAQxdwBXGCgvuP0AgdoB++r4PHcUd0CGEVBoP8g3rnMmFGZhjOvYeSeSOUsowHrCSahlfdrR1C5VwitEa1JfeaLwIX92jskbVw6vA/XhGPD8+sYrNsAAAAAElFTkSuQmCC";
  string public constant FRONT_EVENING_GOWN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAAWT4INQW4UNFcAGzcADRjdOGsVAAAAAXRSTlMAQObYZgAAAD9JREFUGNNjYKAaYGRgEMDBEBRgFAQzlIAAzDBSNlIGM4yBAMxQNjY2AjNcgADMCAUCMEMICFAZykBAYwbEGQDsBg0oE06G9QAAAABJRU5ErkJggg==";
  string public constant FRONT_POLKADOT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAMFBMVEUAAAD07u3t5+boQ0v3SVNNVPf+//xH893zokTt7+z3+fb2SOTrQ9VX9EP49knl5kBZ1M7mAAAAAXRSTlMAQObYZgAAAGFJREFUGNNjYKASEBRSYGBgVFRkUHZUDRQUTC9iULFoDRQ0ES9kmLSiU3CP80QhoKq7gmfSwMrvGgsmQvS5CAqCGasW3n0PZrwTvPsPzPhfvnAhmKFULnsRzNBaCWXQDQAA15kX2zugA+AAAAAASUVORK5CYII=";
  string public constant FRONT_TANK_TOP_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD2rWP2q1/3sGgbZkBTAAAAAXRSTlMAQObYZgAAADpJREFUCNdjYCAWCHAACQUWIGFhAyRsfwCJe7uAxMv/QOLXeyDxrx5I3H8OIpYDid/3gUT9X6JtwAYAB14PbgKbQFEAAAAASUVORK5CYII=";
  string public constant FRONT_SPECIAL_OPS =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADax5HKs2rRvIBBQDmOg2CckG1XWVaEvoMwMi+cVX6DAAAAAXRSTlMAQObYZgAAAKJJREFUGNOtzTsOwjAQhOGp6G0DvWUFam8kTpAHbRDetDyyzgUSchLuS7S5An/1SVMM8Kcs1cZ3wSPEfWU7R3gTVwcJFzShY2Ya0FhZ8wPaRbLIMuEVxnkQOiGWw+f6LR2OdK9zCk9wmlPqkyALOV9yxg4imfFY30Zh1tuz9aQw0RkFRRcUztuomPu5VxS34rZNxmyT99YqYnROMbVTq6jWgB+GliRsTLcGjgAAAABJRU5ErkJggg==";
  string public constant FRONT_CHEESE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAD/4An/5j3zzwbaugVUBbOAAAAAAXRSTlMAQObYZgAAAHFJREFUGNOtjdENw0AMQr0CeALYwLouUHX/nUpylw3iL8R7MlUvHTWwyBphsWeKfYXv1RgUlSZWs8swCaO0MBqt0i8FE4L0YVCAFjH53YTuEdHeIT/3bFbuYKs3MrfcGD+Nj+ONMnLkdWRk/yDNI6f5A9VxD+s4zctFAAAAAElFTkSuQmCC";
  string public constant FRONT_ROBE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAAZQGjT1dIQO12im1Y8NgKp3gzLAAAAAXRSTlMAQObYZgAAAHJJREFUGNOtz9EJxDAMA1CTDVQvEOxbwNFt0HSDdv9V6nPoAIXz10MCgUX+dECXBlUJ3XrTBMHuGpkgBpXMKjb9JdRwKBMcnk2I2WDQLJdcwZrcyW/hnPMoHNd1Fj5z7oXBXCkEFujAShrXThd7IPbyrRuubA/fWYVPWgAAAABJRU5ErkJggg==";
  string public constant FRONT_TRENCH_COAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAAC/q3DAr3+4olrItX83MyOslk9oxzqGAAAAAXRSTlMAQObYZgAAAIdJREFUGNOtjbEOwjAMRC1F6m6XsicRe5q27IiGncbZWwH5/08gjRdYmDh5eHo6+QD+FGrnlOZeg7Y7eCrmktKhGNRj4CshED4D3/DDoG0De28KnAIvHmF42MD9eYCccYqUc/ndTXGpI/oVUdac0hW6tbl/G+OUkbJTJLA2AkenNgEAgVzvR97nsxcsRoH68wAAAABJRU5ErkJggg==";
  string public constant FRONT_KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAJFBMVEUAAADn5+fNzc1xcXGZmZna2tp+fn7AwMCzs7NKSko2NjZQOhE2fSZVAAAAAXRSTlMAQObYZgAAAHBJREFUGNNjYKASEFQyCQx1UxJkUFJvdgzxKFJiUC8xV3EtcS9iKE9rNhTxSCtnSJvVruxasTKNYeXKdiXRilmzGGbNAjFWrkQWMVcSLQaKGJtbGIkYFxsziJY6qRiphAcyhLfv3iq9u6KUWk4mBgAAkz0ixyRbzfQAAAAASUVORK5CYII=";
  string public constant FRONT_FUR_COAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAACGZzyBYzzfzrbXwqRvVjSPEMelAAAAAXRSTlMAQObYZgAAAGVJREFUGNOtjsENgDAMA7NCIzFADBmA1ixAygCpYP9V6Ag8uNc9LJ1FfqKAZIVJsdF42hTo1qA6JddupmKKtXqBAMla5saQ7VwA8ZFkPpD7Uu5LPyRiNHiEBAfhnTOC8Oevw994AVEBEJCeN8OaAAAAAElFTkSuQmCC";
  string public constant FRONT_HAZMAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAD82QD/5TUyMzFMTkv+4Qk/QD6mqKUApQYlJyQ59LReAAAAAXRSTlMAQObYZgAAAKFJREFUGNOtjTEOgkAQRecKDG6M5SzuAUbMJpYGgvVCKKyXQE8MewEvoFZ7WydLaKx91cvP//kAfyLDfIcnQmh1fkRuCXqaynJBEZc/r6wchFBUzCFAlnXzno2RVfc+cE+g+rvGlwjpj8aLcRBjoZFjBGvr2zJaC96P06P2Xt4UoUu3ymzi1CroFK3J1gnCmmj86UQhyTA0TZKqGc5JSgHgC7iaI+T4hgFLAAAAAElFTkSuQmCC";
  string public constant FRONT_KING =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAJ1BMVEUAAADo597w8u8yMzF/Kik3THaULi+qMi//0SI/QD5MTksuHw09LBRIkdTGAAAAAXRSTlMAQObYZgAAAJ9JREFUGNOtzbENwkAMBVCvcBYpKM9SUHId2QDpxABHQ03hYwK7Bgl6QgUlc2SDMBQXk4IBsAs/fxcG+FM5QkJPDnxH1oCu7OQ8rKcVO4QYqUoUI3A+VukqDFn1st+qQM7SnLMIsHKdRBk8a71TRiiq0jQBtDmpfZO2zwYN9zkJcyLL2xeH0K8Mm9AvDNS+yIDPhzcM4zAa3qUMJRh+Th+hmy9ttf5c+AAAAABJRU5ErkJggg==";
  string public constant FRONT_ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAC+wb3Mzsqnqaby9PHm6OUCALq5AACLjYp9f3x2BTzSAAAAAXRSTlMAQObYZgAAAHBJREFUGNNjYKASEFIUNjY2FFJkUAlUSXF3EnViUHFSCQFiICNIKcRFSdUJqEbFSckJqEYVSAUpqQQxqAapOAU5qYIYSqlhQkCGkKJyabgRSE2wUaiosmkQQ7CFamBhULMpg8VMpVBRpZnN1HIyMQAAEasVVwWrM4sAAAAASUVORK5CYII=";
  string public constant FRONT_HOODIE_GRAY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAABOUE1SVFFGSEXLzspXWFYvMS44pxwmAAAAAXRSTlMAQObYZgAAAGRJREFUGNOtjsENgDAIRTm4gDQOAMQBCundSwewFTdw/xUkdgEP/aeX/xL4AJOCpsciRtC61ovKDpgCJFMA1psCmuHjYqEE3UVDkboTEmyjOUPpUNqRmYrEbWWW70m2tM4a/C8vbk0P9C/3IRIAAAAASUVORK5CYII=";
  string public constant FRONT_RAINBOW =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAJ1BMVEUAAADlYmzlfWLlomLl2GLH5WKQ5WJi5XZi5bRi0+ViruVilOViceWoBZwWAAAAAXRSTlMAQObYZgAAADxJREFUGNNjYKASEIQCBiUoYDCGAgYXKGAIhQKGNChgKIcChg4oYJgJBQyroABo9m4gAFtyBgio5WDiAADF2iNVmptoQwAAAABJRU5ErkJggg==";
  string public constant FRONT_CRITENZA =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAMAAAAsVwj+AAAANlBMVEUAAAD2T0n27eb47N8rWWolXm42yKnyxiDuvRTsTUSSy/cuPW81up0jOnDzg4Dr49sgGhU8LBW+i1ADAAAAAXRSTlMAQObYZgAAAHFJREFUKM/dzlkOwzAIBFBD4wHMkvj+l23TSrWPUHW+0GMRrf1IiB9H/5SAqDUD+jGGu0jvqtQs4D5GusrdsFYR6czpojfwezlPziQb38POJ0C0IKsA2+CqYjarBXMyBxbQnCKIBa/nVNy3iQjVHf4kT/rqBBQT3NJuAAAAAElFTkSuQmCC";

  string public constant FRONT_RAINBOW_FULL =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAKlBMVEUAAADkZWnkfmDnoWHm2GHJ5WOS5WBe5ndh5bJh0+NmreNhk+ZccejneF8EC9dyAAAAAXRSTlMAQObYZgAAAFtJREFUGNOtz1ERhEAMBNG2gAUsnAUsYAELWDgLZ+EsYAELeIGZ6qIQwPvLVpLJwksGMYqPmMQsFrGKr/iJv9jEriutdbQjOhPdEt0bTYpmR6+J3hfH5f7H4+UE6cBBWWJOAu0AAAAASUVORK5CYII=";

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 21) {
      return "Scarf";
    } else if (traitIndex == 22) {
      return "Hawaiian Shirt";
    } else if (traitIndex == 23) {
      return "Xmas Sweater";
    } else if (traitIndex == 24) {
      return "Evening Gown";
    } else if (traitIndex == 25) {
      return "Polka Dot";
    } else if (traitIndex == 26) {
      return "Tank Top Orange";
    } else if (traitIndex == 27) {
      return "Special Ops";
    } else if (traitIndex == 28) {
      return "Cheese";
    } else if (traitIndex == 29) {
      return "Robe";
    } else if (traitIndex == 30) {
      return "Trench Coat";
    } else if (traitIndex == 31) {
      return "Knight";
    } else if (traitIndex == 32) {
      return "Fur Coat";
    } else if (traitIndex == 33) {
      return "Hazmat";
    } else if (traitIndex == 34) {
      return "King";
    } else if (traitIndex == 35) {
      return "Astronaut";
    } else if (traitIndex == 36) {
      return "Hoodie Gray";
    } else if (traitIndex == 37) {
      return "Rainbow Shirt";
    } else if (traitIndex == 38) {
      return "Critenza";
    } else if (traitIndex == 39) {
      return "Full Rainbow";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 21) {
      return _layer(prefix, "SCARF");
    } else if (traitIndex == 22) {
      return _layer(prefix, "HAWAIIAN");
    } else if (traitIndex == 23) {
      return _layer(prefix, "XMAS_SWEATER");
    } else if (traitIndex == 24) {
      return _layer(prefix, "EVENING_GOWN");
    } else if (traitIndex == 25) {
      return _layer(prefix, "POLKADOT");
    } else if (traitIndex == 26) {
      return _layer(prefix, "TANK_TOP_ORANGE");
    } else if (traitIndex == 27) {
      return _layer(prefix, "SPECIAL_OPS");
    } else if (traitIndex == 28) {
      return _layer(prefix, "CHEESE");
    } else if (traitIndex == 29) {
      return _layer(prefix, "ROBE");
    } else if (traitIndex == 30) {
      return _layer(prefix, "TRENCH_COAT");
    } else if (traitIndex == 31) {
      return _layer(prefix, "KNIGHT");
    } else if (traitIndex == 32) {
      return _layer(prefix, "FUR_COAT");
    } else if (traitIndex == 33) {
      return _layer(prefix, "HAZMAT");
    } else if (traitIndex == 34) {
      return _layer(prefix, "KING");
    } else if (traitIndex == 35) {
      return _layer(prefix, "ASTRONAUT");
    } else if (traitIndex == 36) {
      return _layer(prefix, "HOODIE_GRAY");
    } else if (traitIndex == 37) {
      return _layer(prefix, "RAINBOW");
    } else if (traitIndex == 38) {
      return _layer(prefix, "CRITENZA");
    } else if (traitIndex == 39) {
      return _layer(prefix, "RAINBOW_FULL");
    }
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