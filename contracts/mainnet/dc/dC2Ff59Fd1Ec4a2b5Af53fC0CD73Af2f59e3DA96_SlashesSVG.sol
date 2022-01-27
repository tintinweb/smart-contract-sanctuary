// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Random.sol";
import "./Palette.sol";
import {Utils} from "./Utils.sol";

contract SlashesSVG is Random, Palette {

    function path(uint256 _seed, bool dir, uint32 lxProba, uint32 lyProba, uint32 wProba, uint32 lProba) internal pure returns (string memory _path, uint256 seed) {
        uint32 x;
        uint32 y;
        uint32 w;
        uint32 l;
        bool lx;
        bool ly;

        // coords
        seed = prng(_seed);
        x = 950 + randUInt32(seed, 0, 1100);
        seed = prng(seed);
        y = 950 + randUInt32(seed, 0, 1100);
        seed = prng(seed);
        w = randUInt32(seed, 4, 20) * (randBool(seed, wProba) ? 4 : 1);
        seed = prng(seed);
        l = randUInt32(seed, 50, 250) * (randBool(seed, lProba) ? 3 : 1);
        seed = prng(seed);
        lx = randBool(seed, lxProba);
        seed = prng(seed);
        ly = randBool(seed, lyProba);

        _path = dir ? string(
            abi.encodePacked(
                "M", Utils.uint32ToString(x-w), " ", Utils.uint32ToString(y),
                " L", Utils.uint32ToString(lx ? x-w+l : x-w-l), " ", Utils.uint32ToString(ly ? y+l : y-l),
                " L", Utils.uint32ToString(lx ? x+w+l : x+w-l), " ", Utils.uint32ToString(ly ? y+l : y-l),
                " L", Utils.uint32ToString(x+w), " ", Utils.uint32ToString(y),
                " Z"
            )
        ) : string(
            abi.encodePacked(
                "M", Utils.uint32ToString(x), " ", Utils.uint32ToString(y-w),
                " L", Utils.uint32ToString(lx ? x+l : x-l), " ", Utils.uint32ToString(ly ? y-w+l : y-w-l),
                " L", Utils.uint32ToString(lx ? x+l : x-l), " ", Utils.uint32ToString(ly ? y+w+l : y+w-l),
                " L", Utils.uint32ToString(x), " ", Utils.uint32ToString(y+w),
                " Z"
            )
        );
    }

    function shape(uint256 _seed, uint32 gradientProba, uint32 lxProba, uint32 lyProba, uint32 wProba, uint32 lProba) 
    internal pure returns (string memory _shape, uint256 seed) 
    {
        uint32 offset;
        bool stroke;
        bool useGradient;
        bool dir;
        string memory _path;

        // attrs
        seed = prng(_seed);
        stroke = randBool(seed, 200);
        seed = prng(seed);
        offset = randUInt32(seed, 2, 10);
        seed = prng(seed);

        useGradient = randBool(seed, gradientProba);
        seed = prng(seed);
        dir = randBool(seed, 500);
        seed = prng(seed);

        (_path, seed) = path(seed, dir, lxProba, lyProba, wProba, lProba);

        _shape = string(
            abi.encodePacked(
                '<g class=\\"o\\"><path transform=\\"translate(',
                Utils.uint32ToString(offset),
                ",",
                Utils.uint32ToString(offset*2),
                ')\\" class=\\"S s',
                stroke ? 's' : 'f',
                useGradient ? dir ? 'h' :  'v' : '',
                '\\" d=\\"',
                _path,
                '\\"/>'
            )
        );

        _shape = string(
            abi.encodePacked(
                _shape,
                '<path class=\\"',
                stroke ? 's' : 'f',
                useGradient ? dir ? 'h' :  'v' : '',
                Utils.uint32ToString(randUInt32(seed, 1, 8)),
                '\\" d=\\"',
                _path,
                '\\" /></g>'
            )
        );
    }

    function generateSVG(uint256 _tokenId) public view returns (string memory svg, string memory attributes) {
        uint32 paletteId;
        uint32 gradientProba;
        uint32 lxProba;
        uint32 lyProba;
        uint32 wProba;
        uint32 lProba;
        uint32 slashesNumberx10;
        uint256 seed;
        string[8] memory paletteRGB;
        
        seed = prng(_tokenId + 31012022);
        (paletteRGB, paletteId, seed) = getRandomPalette(seed);
        
        attributes = string(
            abi.encodePacked(
                '{"trait_type":"Palette ID","value":',
                Utils.uint32ToString(paletteId)
            )
        );

        // viewbox
        svg = string(
            abi.encodePacked(
                '<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"750 750 1500 1500\\"><style>/*<![CDATA[*/svg{background:rgb(',
                paletteRGB[0],
                ');max-width:100vw;max-height:100vh}path{stroke-width:4}.o{opacity:.75}.S{opacity:.4}.sf{stroke:none;fill:black}.sfh{stroke:none;fill:url(#hs)}.sfv{stroke:none;fill:url(#vs)}.ss{stroke:black;fill:none}.ssh{stroke:url(#hs);fill:none}.ssv{stroke:url(#vs);fill:none}'
            )
        );
        
        // classes defs
        for (uint32 i = 1; i < 8; i++) {
            string memory index = ['0', '1', '2', '3', '4', '5', '6', '7'][i];
            svg = string(
                abi.encodePacked(
                    svg,
                    '.s', // stroke
                    index,
                    '{fill:none;stroke:rgb(',
                    paletteRGB[i],
                    ')}.f', //fill
                    index,
                    '{stroke:none;fill:rgb(',
                    paletteRGB[i],
                    ')}.sh', //stroke horizontal gradient
                    index,
                    '{fill:none;stroke:url(#h',
                    index,
                    ')}.fh' //fill horizontal gradient
                )
            );

            svg = string(
                abi.encodePacked(
                    svg,
                    index,
                    '{stroke:none;fill:url(#h',
                    index,
                    ')}.sv', //stroke vertical gradient
                    index,
                    '{fill:none;stroke:url(#v',
                    index,
                    ')}.fv', //fill vertical gradient
                    index,
                    '{stroke:none;fill:url(#v',
                    index,
                    ')}'
                )
            );
        }

        svg = string(
            abi.encodePacked(
                svg,
                '/*]]>*/</style><defs><linearGradient gradientTransform=\\"rotate(90)\\" id=\\"hs\\"><stop offset=\\"20%\\" stop-color=\\"#000\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(0, 0, 0, 0)\\" /></linearGradient><linearGradient id=\\"vs\\"><stop offset=\\"20%\\" stop-color=\\"#000\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(0, 0, 0, 0)\\" /></linearGradient>'
            )
        );

        // gradient defs
        for (uint32 i = 1; i < 8; i++) {
            string memory index = ['0', '1', '2', '3', '4', '5', '6', '7'][i];
            svg = string(
                abi.encodePacked(
                    svg,
                    '<linearGradient gradientTransform=\\"rotate(90)\\" id=\\"h',
                    index,
                    '\\"><stop offset=\\"20%\\" stop-color=\\"rgba(',
                    paletteRGB[i],
                    ',1)\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(',
                    paletteRGB[i],
                    ',0)\\" /></linearGradient>',
                    '<linearGradient id=\\"v',
                    index,
                    '\\"><stop offset=\\"20%\\" stop-color=\\"rgba(',
                    paletteRGB[i],
                    ',1)\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(',
                    paletteRGB[i],
                    ',0)\\" /></linearGradient>'
                )
            );
        }

        seed = prng(seed);
        attributes = string(
            abi.encodePacked(
                attributes,
                '},{"trait_type":"Background Opacity","value":"0.',
                ['2', '2', '2', '6', '8'][randUInt32(seed, 0, 5)]
            )
        );

        svg = string(abi.encodePacked(
            svg,
            '</defs><g transform-origin=\\"1500 1500\\" transform=\\"scale(2)\\" opacity=\\".',
            ['2', '2', '2', '6', '8'][randUInt32(seed, 0, 5)],
            '\\"><g id=\\"slashes\\">'
        ));

        seed = prng(seed);
        gradientProba = randBool(seed, 800) ? 800 : [0, 1000][randUInt32(seed, 0, 2)];
        seed = prng(seed);
        lxProba = randBool(seed, 300) ? 500 : [0, 1000, 500, 750][randUInt32(seed, 0, 4)];
        seed = prng(seed);
        lyProba = randBool(seed, 300) ? 500 : [0, 1000, 500, 750][randUInt32(seed, 0, 4)];
        seed = prng(seed);
        wProba = randBool(seed, 600) ? 100 : [0, 400, 750][randUInt32(seed, 0, 3)];
        seed = prng(seed);
        lProba = randBool(seed, 600) ? 200 : [0, 500][randUInt32(seed, 0, 2)];
        seed = prng(seed);
        slashesNumberx10 = randUInt32(seed, 12, 16);

        attributes = string(
            abi.encodePacked(
                attributes,
                '"},{"trait_type":"Gradients / 1000","value":',
                Utils.uint32ToString(gradientProba),
                '},{"trait_type":"X Direction Force","value":',
                Utils.uint32ToString(lxProba),
                '},{"trait_type":"Y Direction Force","value":',
                Utils.uint32ToString(lyProba),
                '},{"trait_type":"Wider Shapes / 1000","value":',
                Utils.uint32ToString(wProba),
                '},{"trait_type":"Complexity Level","value":',
                Utils.uint32ToString(slashesNumberx10 - 11)
            )
        );

        for (uint8 index = 0; index < slashesNumberx10; index++) {
            string[10] memory shapes;
            for (uint8 i = 0; i < 10; i++) {
                (shapes[i], seed) = shape(seed, gradientProba, lxProba, lyProba, wProba, lProba);
            }
            svg = string(abi.encodePacked(
                svg,
                shapes[0],
                shapes[1],
                shapes[2],
                shapes[3],
                shapes[4],
                shapes[5],
                shapes[6],
                shapes[7],
                shapes[8],
                shapes[9]
            ));
        }

        seed = prng(seed);

        attributes = string(
            abi.encodePacked(
                attributes,
                '},{"trait_type":"Shape Type","value":"',
                ['Rectangle', 'Circle', 'Diamond'][randBool(seed, 700) ? 0 : randUInt32(seed, 1, 3)],
                '"},{"trait_type":"Shape StrokeWidth","value":',
                ['10', '20', '40', '20', '40', '80', '160'][randUInt32(prng(prng(seed)), 0, 7)],
                '},{"trait_type":"Shape Filled","value":"',
                randBool(prng(seed), 800) ? 'False' : 'True',
                '"},{"trait_type":"Scales","value":"',
                ['.3', '.6', '.6', '.6', '.7', '.9', '.9', '.9', '.7', '1.3', '1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
                ' | ',
                ['.7', '.6', '.6', '.6', '.3', '.9', '.9', '.9', '1.3', '.7', '1,-1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
                '"}'
            )
        );

        svg = string(abi.encodePacked(
            svg,
            '</g><use href=\\"#slashes\\" transform-origin=\\"1500 1500\\" transform=\\"rotate(180) scale(2)\\"/></g>',
            [
                '<rect x=\\"1080\\" y=\\"1080\\" width=\\"840\\" height=\\"840\\" stroke-width=\\"',
                '<circle cx=\\"1500\\" cy=\\"1500\\" r=\\"450\\" stroke-width=\\"',
                '<polyline points=\\"1500,1010 1990,1500 1500,1990 1010,1500 1500,1010 1990,1500\\" stroke-width=\\"'
            ][randBool(seed, 700) ? 0 : randUInt32(seed, 1, 3)],
            ['10', '20', '40', '20', '40', '80', '160'][randUInt32(prng(prng(seed)), 0, 7)],
            '\\" class=\\"o ',
            randBool(prng(seed), 800) ? 's' : 'f',
            ['1', '2', 's', '4', '5', '6', '7'][randUInt32(seed, 0, 7)],
            '\\" /><use href=\\"#slashes\\" transform-origin=\\"1500 1500\\" transform=\\"scale(',
            ['.3', '.6', '.6', '.6', '.7', '.9', '.9', '.9', '.7', '1.3', '1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
            ')\\"/><use href=\\"#slashes\\" transform-origin=\\"1500 1500\\" transform=\\"rotate(180) scale(',
            ['.7', '.6', '.6', '.6', '.3', '.9', '.9', '.9', '1.3', '.7', '1,-1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
            ')\\"/></svg>'
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Random {

  /*
  * Compute x[n + 1] = (7^5 * x[n]) mod (2^31 - 1).
  * From "Random number generators: good ones are hard to find",
  * Park and Miller, Communications of the ACM, vol. 31, no. 10,
  * October 1988, p. 1195.
  */
  function prng (uint256 _seed) public pure returns (uint256 seed) {
    seed = (16807 * _seed) % 2147483647;
  }

  function randUInt32 (
    uint256 _seed, 
    uint32 _min, 
    uint32 _max
    ) public pure returns (uint32 rnd) {
      rnd = uint32(_min + _seed % (_max - _min));
  }

   function randBool(
    uint256 _seed, 
    uint32 _threshold
  ) public pure returns (bool rnd) {
    rnd = (_seed % 1000) < _threshold;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Random.sol';
import {Utils} from "./Utils.sol";

contract Palette is Random {

    uint32 constant PALETTE_COUNT = 48;

    uint32[5][PALETTE_COUNT] palettes = [
      [0x101010,0xc5c3c6,0x46494c,0x4c5c68,0x1985a1],
      [0x20bf55,0x0b4f6c,0x292a73,0xfbfbff,0x757575],
      [0x06aed5,0x086788,0x303030,0xcccccc,0xdd1c1a],
      [0x909090,0xf2dc9b,0x6b6b6b,0x260101,0x0d0d0d],
      [0xffa822,0x3a9efd,0x3e4491,0x292a73,0x1a1b4b],
      [0x1b3da6,0x26488c,0x2372d9,0x62abd9,0xf2f557],
      [0x2d3142,0x4f5d75,0xbfc0c0,0xffffff,0x292a73],
      [0xf6511d,0xffb400,0x00a6ed,0x292a73,0x0d2c54],
      [0xdddddd,0x404099,0x929bac,0x013d6f,0x071e44],
      [0x3f0259,0xf2e205,0x606060,0xf2ebdc,0xf6511d],
      [0x302840,0x1f1d59,0x3e518c,0x808080,0xdddddd],
      [0x606060,0xbfc0c0,0x348aa7,0x525174,0x513b56],
      [0xef476f,0xffd166,0x06d6a0,0x118ab2,0x073b4c],
      [0x0b132b,0x1c2541,0x3a506b,0x5bc0be,0x6fffe9],
      [0xbce784,0x5dd39e,0x348aa7,0x525174,0x513b56],
      [0x000000,0x14213d,0xfca311,0xe5e5e5,0xffffff],
      [0x114b5f,0x028090,0xe4fde1,0x456990,0xf45b69],
      [0xdcdcdd,0xc5c3c6,0x46494c,0x4c5c68,0x1985a1],
      [0x22223b,0x4a4e69,0x9a8c98,0xc9ada7,0xf2e9e4],
      [0x3d5a80,0x98c1d9,0xe0fbfc,0xee6c4d,0x293241],
      [0x06aed5,0x086788,0xf0c808,0xfff1d0,0xdd1c1a],
      [0x011627,0xf71735,0x41ead4,0xfdfffc,0xff9f1c],
      [0x13293d,0x006494,0x247ba0,0x1b98e0,0xe8f1f2],
      [0xcfdbd5,0xe8eddf,0xf5cb5c,0x242423,0x333533],
      [0xffbf00,0xe83f6f,0x2274a5,0x32936f,0xffffff],
      [0x540d6e,0xee4266,0xffd23f,0x3bceac,0x0ead69],
      [0xffa69e,0xfaf3dd,0xb8f2e6,0xaed9e0,0x5e6472],
      [0x8a00d4,0xd527b7,0xf782c2,0xf9c46b,0xe3e3e3],
      [0x272643,0xffffff,0xe3f6f5,0xbae8e8,0x2c698d],
      [0x361d32,0x543c52,0xf55951,0xedd2cb,0xf1e8e6],
      [0x122c91,0x2a6fdb,0x48d6d2,0x81e9e6,0xfefcbf],
      [0x27104e,0x64379f,0x9854cb,0xddacf5,0x75e8e7],
      [0xe0f0ea,0x95adbe,0x574f7d,0x503a65,0x3c2a4d],
      [0xffa822,0x134e6f,0xff6150,0x1ac0c6,0xdee0e6],
      [0xd9d9d9,0xa6a6a6,0x8c8c8c,0x595959,0x262626],
      [0xa6032f,0x022873,0x035aa6,0x04b2d9,0x05dbf2],
      [0xa6a6a6,0x737373,0x404040,0x262626,0x0d0d0d],
      [0x0f5cbf,0x072b59,0x0f6dbf,0x042940,0x72dbf2],
      [0x0b132b,0x1c2541,0x3a506b,0x5bc0be,0x6fffe9],
      [0x000000,0x14213d,0xfca311,0xe5e5e5,0xffffff],
      [0x22223b,0x4a4e69,0x9a8c98,0xc9ada7,0xf2e9e4],
      [0x3d5a80,0x98c1d9,0xe0fbfc,0xee6c4d,0x293241],
      [0x011627,0xf71735,0x41ead4,0xfdfffc,0xff9f1c],
      [0xd8dbe2,0xa9bcd0,0x58a4b0,0x373f51,0x1b1b1e],
      [0x13293d,0x006494,0x247ba0,0x1b98e0,0xe8f1f2],
      [0xcfdbd5,0xe8eddf,0xf5cb5c,0x242423,0x333533],
      [0x97151f,0xdfe5e5,0x176c6a,0x013b44,0x212220],
      [0xfef7ee,0xfef000,0xfb0002,0x1c82eb,0x190c28]
    ];

    function hexToRgb(uint32 _c) public pure returns(string memory)  {
      return string(
        abi.encodePacked(
          Utils.uint32ToString(_c >> 16 & 0xff),
          ",",
          Utils.uint32ToString(_c >> 8 & 0xff),
          ",",
          Utils.uint32ToString(_c & 0xff)
        )
      );
    }

    function getRandomPalette(uint256 _seed) 
    view public
    returns (
      string[8] memory paletteRGB,
      uint32 paletteId,
      uint256 seed
    )
    {
      seed = prng(_seed);
      paletteId = randUInt32(seed, 0, PALETTE_COUNT);

      for(uint8 i = 0; i < 5; i++) {
        paletteRGB[i] = hexToRgb(palettes[paletteId][i]);
      }

      paletteRGB[5] = hexToRgb(0x222222); // add blackish
      paletteRGB[6] = hexToRgb(0xffffff); // add white

      seed = prng(seed);
      paletteRGB[7] = hexToRgb([0xff0000, 0xffff00][randUInt32(seed, 0, 2)]); // add red or yellow

      string memory temp;
      // limit to 6 in order to avoid too many white/red/yellow backgrounds
      for (uint8 i = 0; i < 6; i++) {
        seed = prng(seed);
        uint32 n = randUInt32(seed, i, 6);
        temp = paletteRGB[n];
        paletteRGB[n] = paletteRGB[i];
        paletteRGB[i] = temp;
      }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Utils {
  // convert a uint to str
  function uint2str(uint _i) internal pure returns (string memory str) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      j = _i;
      while (j != 0) {
          bstr[--k] = bytes1(48 + uint8(_i - _i / 10 * 10));
          j /= 10;
      }
      str = string(bstr);
  }

  function uint32ToString(uint32 v) pure internal returns (string memory str) {
    if (v == 0) {
        return "0";
    }
    // max uint32 4294967295 so 10 digits
    uint maxlength = 10;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);
    for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1];
    }
    str = string(s);
  }

  function addressToString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
   }

   function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}