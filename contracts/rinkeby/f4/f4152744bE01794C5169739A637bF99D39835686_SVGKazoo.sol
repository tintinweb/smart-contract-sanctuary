//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity 0.8.0;

import "./Base64.sol";

/**
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   id="svg2"
   version="1.1"
   inkscape:version="0.47 r22583"
   width="524.90448"
   height="274.68848"
   sodipodi:docname="Kazoo.jpg">
  <metadata
	 id="metadata8">
	<rdf:RDF>
	  <cc:Work
		 rdf:about="">
		<dc:format>image/svg+xml</dc:format>
		<dc:type
		   rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
		<dc:title></dc:title>
	  </cc:Work>
	</rdf:RDF>
  </metadata>
  <defs
	 id="defs6">
	<inkscape:perspective
	   sodipodi:type="inkscape:persp3d"
	   inkscape:vp_x="0 : 0.5 : 1"
	   inkscape:vp_y="0 : 1000 : 0"
	   inkscape:vp_z="1 : 0.5 : 1"
	   inkscape:persp3d-origin="0.5 : 0.33333333 : 1"
	   id="perspective10" />
  </defs>
  <sodipodi:namedview
	 pagecolor="#ffffff"
	 bordercolor="#666666"
	 borderopacity="1"
	 objecttolerance="10"
	 gridtolerance="10"
	 guidetolerance="10"
	 inkscape:pageopacity="0"
	 inkscape:pageshadow="2"
	 inkscape:window-width="1280"
	 inkscape:window-height="968"
	 id="namedview4"
	 showgrid="false"
	 inkscape:zoom="1.50625"
	 inkscape:cx="310.94014"
	 inkscape:cy="112.94821"
	 inkscape:window-x="-4"
	 inkscape:window-y="-4"
	 inkscape:window-maximized="1"
	 inkscape:current-layer="svg2" />

</svg>

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   id="svg2"
   version="1.1"
   inkscape:version="0.47 r22583"
   width="524.90448"
   height="274.68848"
   sodipodi:docname="Kazoo.jpg">
 */

library SVGKazoo {
    function getHeader(string memory _backgroundColor) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    //the header of the SVG
                    '<svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" id="svg2" version="1.1" inkscape:version="0.47 r22583" viewBox="-25 -25 600 320">',
                    "<style>",
                        'svg{ background-color:', _backgroundColor, '}',
                        ".italic { font: italic 25px sans-serif; } .bold{ font: bold 25px sans-serif; } .comic-sans{font-family:Comic Sans MS, Comic Sans, cursive;font-size:25px;}.impact{font-family:Impact, fantasy;font-size:25px; }",
                    "</style>"
                )
            );
    }

    function getStyle(string memory _backgroundColor) public pure returns(string memory){
        return string(abi.encodePacked(
        "<style>",
            'svg{ background-color:', _backgroundColor, ';}',
            ".italic { font: italic 25px sans-serif; } .bold{ font: bold 25px sans-serif; } .comic-sans{font-family:Comic Sans MS, Comic Sans, cursive;font-size:25px;}.impact{font-family:Impact, fantasy;font-size:25px; }",
        "</style>"));
    }

    function getSpecialStyles() public pure returns(string memory){
        return string(abi.encodePacked("<style>",
        'path{animation-name:special;animation-duration:1000ms;animation-iteration-count:infinite !important;animation-direction:normal}@keyframes special{0%{filter: hue-rotate(90deg)}25%{filter: hue-rotate(45deg)}50%{filter: hue-rotate(180deg)}100%{filter: hue-rotate(90deg)}}',
        "</style>"));
    }

    function buildKazoo(
        string[] memory _styles,
        string[] memory _names,
        string memory _backgroundColor,
        bool _isSpecial,
        uint256 _nonce
    ) public pure returns (string memory) {
        string[] memory paths = buildPaths(_styles);
        bytes memory _s;

        for (uint256 i = 0; i < 13; i++) {
            _s = abi.encodePacked(_s, paths[i]);
        }

        return (
            string(
                abi.encodePacked(
                    getHeader(_backgroundColor),
                    //add special styles
                    _isSpecial ? getSpecialStyles() : "",
                    //paths
                    _s,
                    //text area
                    buildTextArea(_names, _nonce),
                    getFooter()
                )
            )
        );
    }

    function buildTextArea(string[] memory _names, uint256 _nonce)
        public
        pure
        returns (string memory)
    {
        string memory class = "bold";
        string[] memory textAreas = new string[](_names.length);
        uint256 _nonceNumber = _nonce + 1;
        uint256 _cl;

        for (uint256 i = 0; i < _names.length; i++) {
            bytes memory _n = bytes(_names[i]);
            if (_n.length == 0) continue;



            if (_nonceNumber % 6 == 0) class = "italic";
            else if (_nonceNumber % 6 == 1) class = "bold";
            else if (_nonceNumber % 6 == 2 || _nonceNumber % 6 == 3) class = "impact";
            else class = "comic-sans"; //pretty much 1/2 of the time


            uint256 _sp;
            if(i == 0)
                _sp = 55;
            else
                _sp = (stringLength(_names[i - 1]) * 15);

            if(i == 2)
                _cl = _cl + 180;

            _cl = _cl + _sp;
            textAreas[i] = string(
                abi.encodePacked(
                    '<text dy="-2%">',
                        '<textPath href="#1" startOffset="', toString(_cl) ,'" class="',class,'">',
                            _names[i],
                        '</textPath>'
                    "</text>"
                )
            );
            _nonceNumber++;
        }

        string memory _ta;

        for (uint256 i = 0; i < _names.length; i++) {
            bytes memory _n = bytes(textAreas[i]);
            if (_n.length == 0) continue;

            _ta = string(abi.encodePacked(_ta, textAreas[i]));
        }

        return _ta;
    }

    function stringLength(string memory str) private pure returns (uint length)
    {

        bytes memory _b = bytes(str);
        uint256 i;

        while(i < _b.length){

            uint256 b = bytesToInt(_b[i]);

            if (b >> 7 == 0)
                i+=1;
            else if (b >> 5 == 0x6)
                i+=2;
            else if (b >> 4 == 0xE)
                i+=3;
            else if (b >> 3 == 0x1E)
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    function bytesToInt(bytes1 b) public pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint8(b[i]);
        }
        return number;
    }


    function getHexCode(uint256 _mNumber) public pure returns (string memory) {
        return string(abi.encodePacked("#", _intToHexString(uint24(_mNumber))));
    }

    function _intToHexString(uint24 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[4] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[3] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[2] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[1] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[0] = bytes1(_toHexChar(uint8(i & mask)));
        return string(o);
    }

    function _toHexChar(uint8 i) internal pure returns (uint8) {
        return
            (i > 9)
                ? (i + 87) // ascii a-f
                : (i + 48); // ascii 0-9
    }

    function toString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function buildPaths(string[] memory _styles)
        public
        pure
        returns (string[] memory)
    {
        string[] memory _cords = getKazooCords();
        string[] memory _return = new string[](13);

        for (uint256 i = 0; i < 13; i++) {
            _return[i] = buildPath(
                _styles[i],
                _cords[i],
                string(abi.encodePacked('id="', toString(i), '"'))
            );
        }

        return _return;
    }

    function getKazooCords() internal pure returns (string[] memory) {
        //the cords for the kazoo
        //maybe move this to the kazoo NFT as its kinda just sitting here LOL
        string[] memory _cords = new string[](13);
        _cords[0] = "M 1.438897,10.358418 0.5,35.23919 c 112.25619,93.33457 376.72295,214.61628 477.89856,238.94928 L 483.09304,254.47163 1.438897,10.358418 z";
        _cords[1] = "M 1.438897,9.88897 C 141.71843,124.29882 393.13787,225.22368 483.5625,254.00218 l 40.37256,-67.13113 C 361.26882,110.35993 180.66139,43.74209 13.644558,0.5 7.69821,2.377794 3.629657,5.507451 1.438897,9.88897 z";
        _cords[2] = "m 231.51711,111.4692 c 43.91004,11.65092 82.22192,6.91486 116.84647,-5.3112 l 0,21.07884 c -1.69764,27.25255 -83.22573,50.02984 -116.51453,3.9834 l -0.33194,-19.75104 z";
        _cords[3] = "m 229.35943,100.8468 120.82988,-0.33195 c -3.09393,47.80139 -118.51047,50.55913 -120.82988,0.33195 z";
        _cords[4] = "m 229.19345,100.1829 c 31.73314,44.04316 102.08864,32.31802 119.17013,2.6556 l -119.17013,-2.6556 z";
        _cords[5] = "M 206.80027,57.80154 C 226.31958,6.152344 343.06582,6.841636 372.85315,54.54711 c 1.22328,4.60971 2.1986,8.51524 1.5834,13.12495 -10.07214,61.41638 -147.71093,68.27081 -168.92529,2.80083 -0.51337,-3.91081 -0.0606,-8.99526 1.28901,-12.67135 z";
        _cords[6] = "m 230.25772,38.14111 c 61.73061,-37.985219 137.94067,-3.27901 133.85143,29.25534 -1.42523,8.27975 -6.38744,15.69384 -7.88418,16.81582 -15.67222,25.15589 -160.24039,27.85808 -137.94466,-31.41792 3.66586,-7.58193 6.61051,-9.79059 11.97741,-14.65324 z";
        _cords[7] = "M 226.69257,69.59763 C 225.98301,106.32248 349.2278,113.31095 353.08019,71.1731 345.17218,26.406275 237.09425,20.744939 226.69257,69.59763 z";
        _cords[8] = "m 232.93477,82.61512 c 9.65844,-53.18144 115.43585,-31.4868 113.84354,0.12727 -9.92783,18.57446 -89.89843,28.11135 -113.84354,-0.12727 z";
        _cords[9] = "m 239.47137,87.92636 c 21.41038,17.75501 76.03527,18.71165 99.25455,1.40041 -16.86878,-28.02994 -88.51338,-23.48461 -99.25455,-1.40041 z";
        _cords[10] = "m 245.07304,91.25235 c 12.15269,-23.33902 78.67774,-18.2816 88.40131,0.7002 -7.98436,10.15978 -67.45455,16.53878 -88.40131,-0.7002 z";
        _cords[11] = "m 259.42731,97.84079 c 14.57454,-13.96873 48.90685,-11.56993 64.41918,-1.20721 -18.97981,6.42898 -39.40963,9.62067 -64.41918,1.20721 z";
        _cords[12] = "m 519.24058,207.05734 5.16393,-19.24739 -40.84202,66.19223 -5.16393,19.71684 40.84202,-66.66168 z";

        return _cords;
    }

    function buildPath(
        string memory _style,
        string memory _cord,
        string memory _extras
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path ",
                    _style,
                    ' d="',
                    _cord,
                    '" ',
                    _extras,
                    "/>"
                )
            );
    }

    function getStyle(
        string memory fill,
        string memory stroke,
        uint256 strokewidth
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'style="fill:',
                    fill,
                    ";stroke:",
                    stroke,
                    ";stroke-width:",
                    strokewidth,
                    'px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"'
                )
            );
    }

    function getFooter() public pure returns (string memory) {
        return string("</svg>");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
* @dev Library to help with base64 functions.
* This seems to be increasingly useful for things like on-chain images.
*
* Adapted from https://github.com/OpenZeppelin/solidity-jwt/blob/master/contracts/Base64.sol
*/

library Base64 {
    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes private constant base64urlchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(string memory _str) internal pure returns (string memory) {
        bytes memory _bs = bytes(_str);
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            //(bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        // Add base64 padding.
        uint256 resRemainder = res.length;
        if (resRemainder % 4 != 0) {
            if (4 - (resRemainder % 4) == 1) {
                res = abi.encodePacked(res, '=');
            } else if (4 - (resRemainder % 4) == 2) {
                res = abi.encodePacked(res, '==');
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}