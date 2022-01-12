/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/IFantomonTrainerArt.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFantomonTrainerArt {
    function getArt(uint256 _face) external view returns (string memory);
}


// File contracts/FantomonTrainerArtEpic5to7.sol


contract FantomonTrainerArtEpic5to7 is IFantomonTrainerArt {
    string private PREFIX = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHwAAADhCAMAAAA9OCERAAAAAXNSR0IArs4c6QAAA';
    string[3] private PNGS = [
        // Epic5
        "GlQTFRFAAAAAAAAwebmsu///8N32t3DcIFV/7pq/7Bk+dWk6ptf/6Zhso9c/8yK6atf/8R2//bfoXpxyJNe/92iIxoOGBIREg8WCwsbBQgg/xlq/wCZ//fw956C/5WCxP/Eh/+3d+ChZLyHUQC8SzTkzwAAACN0Uk5TAP////////////////////////////////////////////+k8FOOAAAEIUlEQVR4nO3b7VrrIAwAYOMtbOMXPCvc/0UeSCCFtjsCtjA1ebTOzfk2fKQt1Q81MT4m45+TgnD8GBtkYuajaeTXzCe0ecLH214XXPC/h8+c57Mr3HA6q3Cj7YhS5uo2OEC9Bz6aRl5wwQUXXHDB3wAHjBm4Z58Y3+U7cLBP+3yewTfiwFmvfH8HtOEFbH2kB3070IRDxsaI3/tXOnagBc/s5/4h7cRUvElvwMGykYPPTTTw9XiwYe/B/sFF+EHAwVO1fDW+Q+JgB+qE8uVKvQW3Wxon2GH+dXotDmVfB5k+Q8kD2zfs6nCqqSUeI8Bg+/R6PAeyEoeFLby03YEKvQ2/x9+7Zg2QdsFC2fpn4RCzfZZ2SNpg4mkX7L1Jr8YXztxyskZjGN4ba7Pkz8GDfV/496aRbqKtDaXP449iuQwHTpv0Nfm1EH6t1+JLiesictymegNft/spuDZFt1d3eh1u7RL0HW6O9PoR14H7qbbN/GLc1uGQH3hPwW9Q5hRwYzY46X6z/Co8lpDXzZ51+hX4kvR7qO0HOlDh84PjXPwWcaDigfp+zIWyp3BeLCfWdsZJv2PDH+G+5xXlbi/Aud99ktq8wq3FaXkmvjDuNwclVoeDu1ZrqTkL9z8X8Djo0hGEc+bp9tBZjT8P97pdR7wtM0+T/nEVHioNDbp4OZzaGlLF8bQOOOBxoOaCtelCMcwiWongfqZN0Cl7wNG+1F2qN+F2Q5ej3Wf+iPj9fuJFA+uvbRpvOh3caux2vDyimHVrwl5BGJfnX6XiD+OJY8EbjPhANy5Nta7DhUKy1+PX1gWpPnyrE928GNaDa2zgLX/1Ohy+IV0trDo+0bMI2b72ejzTuhZAexZ+y/but38cHnVQSnFF77L77jTkI51q20D8lp9H+Ak+NPNVNxpn/Fj8hqcQoawN73N6J9ujm/1Gh7jU9uPxdbJPw/uOZ9/FVUpbtx/IT8LjTB9XXguc8u+7r9dbZJSic6cV77iv11fb4wqk4as0/71z7sqbevwez8SRRtlHu1nvOZ4HJJ414skUNoTr0DtOo1ys6xqbPvb2I8D4cSWOBB1NzGpTjzv8chUOSHNNT4OcbEeby65YZuIJQR5WusBd/XxvuT5Xjo1NOEjPuxa9YVlEOcZd7nLa7tE43+sXhBQlFif0YWTT/dSVCXZf41mtqcy9dhEQeDC9gIvXKgc94//7i18ezql7iyTzMVA89RWt6nDKZu/teMedXoO/y195T4i3+J+Gqc0+/F8qSnysjY0uuOCCCy644IILLrjgggsuuOCCCy644IILLrjgggsuuOCCt+BT7yjOvJc6IRifEnPxT8l8Bi6ZT8El8ym4ZD4F/7uZq0/BBRdccMEFF1zwH4vLCeQMXDKfgv/ddTjBBZ+ATwrE58VU/B+b528XTyjBlAAAAABJRU5ErkJggg==",
        // Epic6
        "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",
        // Epic7
        "F1QTFRFAAAAAAAAwebmsu///8N32t3DcIFV/7pq/7Bk+dWk6ptf/6Zhso9c/8yK6atf/8R2//bfoXpxyJNe/92iIxoOGBIREg8WCwsbBQggIxoOPUBIW2BsTQgg/3MAnUcAQ4z3rQAAAB90Uk5TAP///////////////////////////////9r//////xAoCZAAAASoSURBVHic7dvRdtsgDADQqS/Z8YPTemd+ivn/zxxIAgSxY3CM6U7FtizJml1LCBkn7a+54/jVGf/oNAjH39cOMjHyq2nkY+Qdcu7x622rK674z8N7rvPeHe5yWnS4q21GKfL5z8UD5u+BX00jr7jiiiuuuOKKh/+Ax/W4RW847vcj+js4yXcr32+/7weCP4xT0KMY9cEfxJEe81GrH8NXaafX8YdwS9/X7Nrgj+BgS2zDrtMP4Ln9BV/4p16vx+fNlFfr1Tg82Vnk461Yr8Wf7TdCr8RhZYXlkZfrJ+A0Bsx4S3zbTkZpo30Pp4fU7cQ/DZfgm6NMr8JhA4dxnNztrSn+ZAPe/B0nhzsdLsOJtoNxgPBkaxxYNgsMk9VhMeRDqV4551nkYOxYCB9gWdxDKA/9HRxQXhifAO/bA2gVudQZsza4rE8Qn2iEe30Q9ohTHmN3T52O48UB1twwDCDDdsVu17rQizpsBQ5gLw1ynDI+Iu50qEl8DY52igMHzSOkvhHupl3akR1l6otmvRK/2V/D4HEQYfu7rJ+PT66j3QZgXNojeHxE/XzczSSg7XDX0iUeZsAeYQMcN0sQ8CTjE8Tpb4A7feBaH8DEZjfFQ/C6OR1H/cYrLcl5NqbCtyrqcddhLb4pYwE06O1WH6zu8DzWDG+wmeBGk4dpByZ6CsfUZPdKJ5f0gglwA0HbCF/xjXA8v2RhuyUPaHNWGl0u4Uvuie02M9RRKfi2eNQHipttYH1qdolML8JmR+88GrYXzD5tYJvi2OeDzYH7G9MeZzew/ACfNC3nnPFF4nxrKAFNcbSDLgZw7TXGOcUhZq+bCv1gtVOhmYj7RPBsNMK5yvPZvgIH+LQjxf0iT8qvxeWSlR8PeMaXDC/Tq7ZRFn6QvVLp+QGduo0Caa/hz0dzGk4Zf8BGwaU4Nb3dTleK27ClbWAdDzNe9HlXBW7HnNgvcLMfdjkOmPNHavvzuCi4cL9IL8bRJt3wezFG4tRlQuRFel3ksuBM1tPQ5/t/LV6wqajCwesGg88mHiJO+6k9uxifOXLUcZ+cTLzvr7HgSrZTZThwzDHzJu0zkP8NmPgzcNvcrBs7HGY1gXOcJ2FHL8FdY7VR+7gfMXC/Z863VHQ8u5kvwKmpu6TjMXDwcqHH2Rd1QPhLfR8Xq+zTn1weYCIl404qgZL0Dh5sipg7nZEBy6SLOTCEv9D38BBrKHTcyhgZZYr7h4ZKxX7xUdyHytXGPK3xuKzycsMZIdy+ZFvfw0PS/SqP9fZ8HhcLzdDX42s29dd4mnSBi9reWuYGwgFv6Tt4tGkj40+sBvxm2d+IlPs5f/hkbc37Szy1g+7KzVd1bDaQToOLfA6vXq/5gK98x2+WdNRx5yxClG8ORBw49FCpazrML3AQOM6ea/Cfsb3lhZbv5ffx7/Jd3h3Gt/iZhq5pv/xHKlL8WhuTrrjiiiuuuOKKK6644oorrrjiiiuuuOKKK6644oorrrjiitfgXT9R7PlZaocR8C6jL/6hkffANfIuuEbeBdfIu+A/N/L5Q3HFFVdcccUVV/y/xXUD2QPXyLvgP/d9OMUV74B3Goj3G13xf/0fEgRRKAvVAAAAAElFTkSuQmCC"
    ];
    function getArt(uint256 _face) external view returns (string memory) {
        return string(abi.encodePacked(PREFIX, PNGS[_face]));
    }
}