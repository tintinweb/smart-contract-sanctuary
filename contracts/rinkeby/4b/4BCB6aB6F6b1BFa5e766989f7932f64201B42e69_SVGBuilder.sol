//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Random.sol";
import "./Palette.sol";
import {Utils} from "./Utils.sol";

contract SVGBuilder is Random, Palette {

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
        w = randUInt32(seed, 4, 20) * (randUInt32(seed, 0, 1000) < wProba ? 4 : 1);
        seed = prng(seed);
        l = randUInt32(seed, 50, 250) * (randUInt32(seed, 0, 1000) < lProba ? 3 : 1);
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

    function shape(uint256 _seed, uint32 _color, uint32 gradientProba, uint32 lxProba, uint32 lyProba, uint32 wProba, uint32 lProba) 
    internal pure returns (string memory _shape, uint256 seed) 
    {
        uint32 color;
        uint32 offset;
        bool stroke;
        bool useGradient;
        bool dir;
        string memory _path;

        // attrs
        seed = prng(_seed);
        color = _color;

        seed = prng(seed);
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

    function generateSVG(uint256 _tokenId) public view returns (string memory) {
        uint32 gradientProba;
        uint32 lxProba;
        uint32 lyProba;
        uint32 wProba;
        uint32 lProba;
        uint32 N;
        uint256 seed;
        string memory svg;
        string[8] memory paletteRGB;
        
        seed = prng(_tokenId);
        (paletteRGB, seed) = getRandomPalette(seed);
        
        // viewbox
        svg = string(
            abi.encodePacked(
                '<svg xmlns=\\"http://www.w3.org/2000/svg\\"  style=\\"background:rgb(',
                paletteRGB[0],
                ')\\" viewBox=\\"500 1000 2000 1000 \\"><style>/*<![CDATA[*/path{stroke-width:4} .o{opacity:.75} .S{opacity:.4} .sf{stroke:none;fill:black} .sfh{stroke:none;fill:url(#hs)} .sfv{stroke:none;fill:url(#vs)} .ss{stroke:black;fill:none} .ssh{stroke:url(#hs);fill:none} .ssv{stroke:url(#vs);fill:none} '
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
                    ')} .f', //fill
                    index,
                    '{stroke:none;fill:rgb(',
                    paletteRGB[i],
                    ')} .sh', //stroke horizontal gradient
                    index,
                    '{fill:none;stroke:url(#h',
                    index,
                    ')} .fh' //fill horizontal gradient
                )
            );

            svg = string(
                abi.encodePacked(
                    svg,
                    index,
                    '{stroke:none;fill:url(#h',
                    index,
                    ')} .sv', //stroke vertical gradient
                    index,
                    '{fill:none;stroke:url(#v',
                    index,
                    ')} .fv', //fill vertical gradient
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

        svg = string(abi.encodePacked(
            svg,
            '</defs><g transform-origin=\\"1500 1500\\" transform=\\"scale(2)\\" opacity=\\".15\\"><g id=\\"slashes\\">'
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
        lProba = randBool(seed, 600) ? 200 : [0, 1000, 500, 750][randUInt32(seed, 0, 4)];
        seed = prng(seed);
        N = randUInt32(seed, 12, 16);
        for (uint8 index = 0; index < N; index++) {
            string[10] memory shapes;
            for (uint8 i = 0; i < 10; i++) {
                (shapes[i], seed) = shape(seed, randUInt32(seed, 1, 8), gradientProba, lxProba, lyProba, wProba, lProba);
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
        delete gradientProba;
        delete lxProba;
        delete lyProba;
        delete wProba;
        delete lProba;

        seed = prng(seed);
        svg = string(abi.encodePacked(
            svg,
            '</g><use href=\\"#slashes\\" transform-origin=\\"1500 1500\\" transform=\\"rotate(180) scale(2)\\"/></g>',
            randBool(seed, 700) ? '<rect x=\\"1080\\" y=\\"1080\\" width=\\"840\\" height=\\"840\\" stroke-width=\\"' : [
                '<circle cx=\\"1500\\" cy=\\"1500\\" r=\\"450\\" stroke-width=\\"',
                '<polyline points=\\"1500,1010 1990,1500 1500,1990 1010,1500 1500,1010\\" stroke-width=\\"'
            ][randUInt32(seed, 0, 2)],
            ['10', '20', '40', '10', '20', '40', '80'][randUInt32(prng(prng(seed)), 0, 7)],
            '\\" class=\\"o ',
            randBool(prng(seed), 800) ? 's' : 'f',
            ['1', '2', 's', '4', '5', '6', '7'][randUInt32(seed, 0, 7)],
            '\\" /><use href=\\"#slashes\\" transform-origin=\\"1500 1500\\" transform=\\"scale(',
            randBool(seed, 20) ? '1' : ['.3', '.6', '.6', '.6', '.7', '.9', '.9', '.9', '.7', '1.3', '1'][randUInt32(prng(seed), 0, 11)],
            ')\\"/><use href=\\"#slashes\\" transform-origin=\\"1500 1500\\" transform=\\"rotate(180) scale(',
            randBool(seed, 20) ? '1,-1' : ['.7', '.6', '.6', '.6', '.3', '.9', '.9', '.9', '1.3', '.7', '0'][randUInt32(prng(seed), 0, 11)],
            ')\\"/></svg>'
        ));
        return svg;
    }
}

//SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Random.sol';
import {Utils} from "./Utils.sol";

contract Palette is Random {

    uint32 constant PALETTE_COUNT = 81;

    uint32[5][PALETTE_COUNT] palettes = [
      [0x8a00d4,0xd527b7,0xf782c2,0xf9c46b,0xe3e3e3],
      [0xe74645,0xfb7756,0xfacd60,0xfdfa66,0x1ac0c6],
      [0x454d66,0x309975,0x58b368,0xdad873,0xefeeb4],
      [0x272643,0xffffff,0xe3f6f5,0xbae8e8,0x2c698d],
      [0x361d32,0x543c52,0xf55951,0xedd2cb,0xf1e8e6],
      [0x072448,0x54d2d2,0xffcb00,0xf8aa4b,0xff6150],
      [0x122c91,0x2a6fdb,0x48d6d2,0x81e9e6,0xfefcbf],
      [0x27104e,0x64379f,0x9854cb,0xddacf5,0x75e8e7],
      [0xf7a400,0x3a9efd,0x3e4491,0x292a73,0x1a1b4b],
      [0xe0f0ea,0x95adbe,0x574f7d,0x503a65,0x3c2a4d],
      [0xf9b4ab,0xfdebd3,0x264e70,0x679186,0xbbd4ce],
      [0xffa822,0x134e6f,0xff6150,0x1ac0c6,0xdee0e6],
      [0x613873,0x5d3b8c,0x382859,0xbf5b45,0xd9a19c],
      [0xd9d9d9,0xa6a6a6,0x8c8c8c,0x595959,0x262626],
      [0xa6032f,0x022873,0x035aa6,0x04b2d9,0x05dbf2],
      [0x58735c,0xf2dc9b,0xbf8a6b,0x260101,0x0d0d0d],
      [0x03738c,0x037f8c,0x04d9d9,0xf28972,0xf20505],
      [0x1b3da6,0x26488c,0x2372d9,0x62abd9,0xf2d857],
      [0xa65b69,0x733c4a,0x3e4c59,0xbfb19f,0xf2e5d5],
      [0x302840,0x1f1d59,0x3e518c,0x77a688,0xf2e2c4],
      [0x3f0259,0xf2e205,0xf2b705,0xf2ebdc,0xd95e32],
      [0x779da6,0x034001,0xf2df7e,0xf2efe9,0xf25244],
      [0xa6a6a6,0x737373,0x404040,0x262626,0x0d0d0d],
      [0x222e73,0x032ca6,0x85bff2,0xf2c84b,0xf29f05],
      [0x0476d9,0x05aff2,0xa4d932,0xf2be22,0xf2cc85],
      [0x314259,0xd9843b,0x73310a,0xa64914,0x0d0d0d],
      [0x0f5cbf,0x072b59,0x0f6dbf,0x042940,0x72dbf2],
      [0x0442bf,0x5cacf2,0xf2b705,0xf29f05,0xf2b8a2],
      [0x1f4c73,0x387ca6,0x96d2d9,0xf2e8c9,0x402f11],
      [0xf2bb13,0xf28c0f,0xd9a577,0xa61b0f,0xf2f2f2],
      [0x0468bf,0x05aff2,0xf2b705,0xf28705,0xbf3604],
      [0xd90d32,0xd3d9a7,0xf25116,0xbf3111,0xf2f2f2],
      [0xf2cb05,0xf2b705,0x262523,0xd97904,0xd92818],
      [0xf26d85,0xbf214b,0xc1d0d9,0x0e6973,0x0e7373],
      [0x89b3d9,0xf2e6d8,0xd9985f,0x59220e,0xa64521],
      [0x034c8c,0x69a7bf,0xf2e205,0xf2cb05,0xf2d49b],
      [0xef476f,0xffd166,0x06d6a0,0x118ab2,0x073b4c],
      [0x0b132b,0x1c2541,0x3a506b,0x5bc0be,0x6fffe9],
      [0x003049,0xd62828,0xf77f00,0xfcbf49,0xeae2b7],
      [0xbce784,0x5dd39e,0x348aa7,0x525174,0x513b56],
      [0x000000,0x14213d,0xfca311,0xe5e5e5,0xffffff],
      [0x114b5f,0x028090,0xe4fde1,0x456990,0xf45b69],
      [0xf2d7ee,0xd3bcc0,0xa5668b,0x69306d,0x0e103d],
      [0xdcdcdd,0xc5c3c6,0x46494c,0x4c5c68,0x1985a1],
      [0x22223b,0x4a4e69,0x9a8c98,0xc9ada7,0xf2e9e4],
      [0x114b5f,0x1a936f,0x88d498,0xc6dabf,0xf3e9d2],
      [0xff9f1c,0xffbf69,0xffffff,0xcbf3f0,0x2ec4b6],
      [0x3d5a80,0x98c1d9,0xe0fbfc,0xee6c4d,0x293241],
      [0x06aed5,0x086788,0xf0c808,0xfff1d0,0xdd1c1a],
      [0x011627,0xf71735,0x41ead4,0xfdfffc,0xff9f1c],
      [0xd8dbe2,0xa9bcd0,0x58a4b0,0x373f51,0x1b1b1e],
      [0x13293d,0x006494,0x247ba0,0x1b98e0,0xe8f1f2],
      [0x3d315b,0x444b6e,0x708b75,0x9ab87a,0xf8f991],
      [0xcfdbd5,0xe8eddf,0xf5cb5c,0x242423,0x333533],
      [0x083d77,0xebebd3,0xf4d35e,0xee964b,0xf95738],
      [0x20bf55,0x0b4f6c,0x01baef,0xfbfbff,0x757575],
      [0x292f36,0x4ecdc4,0xf7fff7,0xff6b6b,0xffe66d],
      [0x540d6e,0xee4266,0xffd23f,0x3bceac,0x0ead69],
      [0xc9cba3,0xffe1a8,0xe26d5c,0x723d46,0x472d30],
      [0xffa69e,0xfaf3dd,0xb8f2e6,0xaed9e0,0x5e6472],
      [0xefdec4,0xf8ab51,0xee8927,0x151829,0x080705],
      [0xf9f4e4,0xeebb4e,0xad7432,0x6dbdc4,0x0a203f],
      [0xbcbbb7,0xcd9e34,0x622834,0x164072,0x322424],
      [0xf8ead0,0xe1c7a2,0x7a786b,0x4f5146,0x3b372e],
      [0x97151f,0xdfe5e5,0x176c6a,0x013b44,0x212220],
      [0xfef7ee,0xfef000,0xfb0002,0x1c82eb,0x190c28],
      [0x5a8693,0xdfb064,0xe8e5de,0xb3beb0,0x576359],
      [0xede5d5,0xac9a82,0x6a5a43,0x347c8d,0x1a444c],
      [0xe2ded2,0xaca794,0xb3cfdb,0x8fafbc,0x5b737d],
      [0xe2ba9a,0xd0a07b,0xe5a367,0x9d652e,0x212530],
      [0xecd0bb,0xd26e3a,0x929bac,0x013d6f,0x071e44],
      [0xeee1cd,0xe1a850,0x79715c,0x53676e,0x2a2e31],
      [0xfcecc3,0xf1db8e,0x8d9d81,0x63806c,0x3d5958],
      [0xf36b3c,0xebd7bc,0xc9b099,0x84674c,0x3e3832],
      [0xe8e1c9,0xebd17c,0xf0623c,0x566680,0x28282a],
      [0xd6c3b5,0x9e997b,0x5b5e4a,0x3b3d30,0x192320],
      [0xc48d54,0x9c6c58,0x62685c,0x22404a,0x243431],
      [0xe0dcd9,0xaa9965,0x7e7a5a,0x414538,0x1e2428],
      [0x88b2ca,0x204d72,0xfa971e,0x979089,0x3a3c39],
      [0xe7d1a9,0xf1c202,0x807474,0xc5484c,0x633c3e],
      [0x21809e,0xd8c19f,0xb98748,0xad0327,0x2d1a14]
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
      uint256 seed
    )
    {
      seed = prng(_seed);
      uint n = randUInt32(seed, 0, PALETTE_COUNT);

      for(uint i = 0; i < 5; i++) {
        paletteRGB[i] = hexToRgb(palettes[n][i]);
      }

      paletteRGB[5] = hexToRgb(0x222222); // add blackish
      paletteRGB[6] = hexToRgb(0xffffff); // add white

      seed = prng(seed);
      paletteRGB[7] = hexToRgb([0xff0000, 0xffff00][randUInt32(seed, 0, 2)]); // add red or yellow

      string memory temp;
      // limit to 7 tin order to avoid too many red/yellow backgrounds
      for (uint32 i = 0; i < 7; i++) {
        seed = prng(seed);
        n = randUInt32(seed, i, 7);
        temp = paletteRGB[n];
        paletteRGB[n] = paletteRGB[i];
        paletteRGB[i] = temp;
      }
    }
}

//SPDX-License-Identifier: Unlicense
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

}