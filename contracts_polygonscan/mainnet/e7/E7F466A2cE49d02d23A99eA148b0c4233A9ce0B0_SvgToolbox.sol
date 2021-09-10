/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: OpenZeppelin/[email protected]/Strings

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: svgtoolbox.sol

// General format for bytes array to Svg shape:
// [0] : id => i1, i2, i3.. unset if '0'.
// [1] : class => c1, c2, c3..
// [2] : if 0, no ending tag '/>', just '>'. Assumes that you close the tag.
// Specifics :
// - styleColor : [3], [4], [5], [6] : RGBA
// - ellipse: 
//   [3] : cx 
//   [4] : cy Where cx,cy defines the center.
//   [5] : rx = X radius
//   [6] : ry = Y radius
// - triangle:
//   [3],[4] x,y 1st point.
//   [5],[6] x,y 2nd point.
//   [7],[8] x,y 3rd point.


contract SvgToolbox {
    using Strings for uint256;
    using Strings for uint8;

    // Open <svg> tag
    function startSvg(uint _x, uint _y, uint _length, uint _width) external pure returns (bytes memory) {
        return abi.encodePacked(
            "<svg viewBox='",
            _x.toString(), " ",
            _y.toString(), " ",
            _length.toString(), " ",
            _width.toString(), "' xmlns='http://www.w3.org/2000/svg'>");
    }

    // Close </svg> tag
    function endSvg() external pure returns (bytes memory) {
        return("</svg>");
    }

    // defines a style for fully defined '_element' class or id string (eg. '#i1') 
    // colors are defined in 4 bytes ; red,green,blue,alpha
    function styleColor(bytes memory _element, bytes memory _b ) external pure returns (bytes memory) {
        return abi.encodePacked(
                "<style>", 
                _element, "{fill:",
                toRgba(_b, 0),
                ";}</style>"
        );
    }

    // Takes 4 bytes starting from the given offset
    // Returns css' rgba(r,v,b,a)
    function toRgba(bytes memory _b, uint256 offset) public pure returns (bytes memory){
        return abi.encodePacked(
            "rgba(",
             byte2uint8(_b, offset).toString(), ",",
             byte2uint8(_b, offset + 1).toString(), ",",
             byte2uint8(_b, offset + 2).toString(), ",",
             byte2uint8(_b, offset + 3).toString(), ")"
        );
    }

    // Define one or more lines depending on the number of parameters
    // General format applies
    function polyline(bytes memory _b) external pure returns (bytes memory) {
        bytes memory points; 
        for (uint i = 3 ; i < _b.length ; i++) {
            points = abi.encodePacked(points,
                byte2uint8(_b, i).toString(), " "
            );
        }
        return abi.encodePacked(
            "<polyline ", setIdClass(_b),
            " points='", points, "'",
            endingtag(_b)
        );
    }

    // Define a rectangle
    // General format applies
    function rect(bytes memory _b) external pure returns (bytes memory) {
        return abi.encodePacked(
            "<rect ", setIdClass(_b),
            " x='", byte2uint8(_b, 3).toString(),
            "' y='", byte2uint8(_b, 4).toString(),
            "' width='", byte2uint8(_b, 5).toString(),
            "' height='", byte2uint8(_b, 6).toString(),
            "'", endingtag(_b)
        );
    }

    // Define a circle
    // General format applies
    function circle(bytes memory _b) external pure returns (bytes memory) {
        return abi.encodePacked(
            "<circle ", setIdClass(_b),
            " cx='", byte2uint8(_b, 3).toString(),
            "' cy='", byte2uint8(_b, 4).toString(),
            "' r='", byte2uint8(_b, 5).toString(),
            "'", endingtag(_b)
        );  
    }

    // Define an ellipse
    // General format applies
    function ellipse(bytes memory _b) external pure returns (bytes memory) {
        return abi.encodePacked(
            "<ellipse ", setIdClass(_b),
            " cx='", byte2uint8(_b, 3).toString(),
            "' cy='", byte2uint8(_b, 4).toString(),
            "' rx='", byte2uint8(_b, 5).toString(),
            "' ry='", byte2uint8(_b, 6).toString(),
            "'", endingtag(_b)
        );  
    }

    // Define a polygon, variable number of points
    // General format applies
    function polygon(bytes memory _b) external pure returns (bytes memory) {
        bytes memory points; 
        for (uint i = 3 ; i < _b.length ; i++) {
            points = abi.encodePacked(points,
                byte2uint8(_b, i).toString(), " "
            );
        }
        return abi.encodePacked(
            "<polygon ", setIdClass(_b),
            " points='",
            points, "'", endingtag(_b)
        );
    }

    // Define a <use href='#id' ...
    // General format applies
    function use(bytes memory _b) external pure returns (bytes memory) {
        return abi.encodePacked(
            "<use ", setIdClass(_b),
            "href='#i", byte2uint8(_b, 3).toString(),
            "' x='", byte2uint8(_b, 4).toString(),
            "' y='", byte2uint8(_b, 5).toString(),
            "'", endingtag(_b)
        );
    }

    // Define a linear gradient in a <defs> tag. 
    // Applied to an object with 'fill:url(#id)'
    // General format applies
    function linearGradient(bytes memory _b) external pure returns (bytes memory) {
        bytes memory grdata; 
        for (uint i = 5 ; i < _b.length ; i+=5) {
            grdata = abi.encodePacked(
                grdata,
                "<stop offset='", byte2uint8(_b, i).toString(),
                "%' stop-color='", toRgba(_b, i+1),
                "'/>"
            );
        }
        return abi.encodePacked(
            "<defs><linearGradient id='i",
            byte2uint8(_b, 0).toString(),
            "' x1='", byte2uint8(_b, 1).toString(),
            "' x2='", byte2uint8(_b, 2).toString(),
            "' y1='", byte2uint8(_b, 3).toString(),
            "' y2='", byte2uint8(_b,4).toString(), "'>",
            grdata,
            "</linearGradient></defs>"
        );
    }

    // path data in plain text
    // General format applies
    function path(bytes memory _b, string memory _path) external pure returns (bytes memory) {
        return abi.encodePacked(
            "<path ", setIdClass(_b),
            "d='", _path, "'", endingtag(_b)
        );
    }
    
    // path data to be encoded
    // See github's repo for full documentation
    // A Q and T are not implemented yet
    function path(bytes memory _b) external pure returns (bytes memory) {
        bytes memory pathdata; 
        pathdata = abi.encodePacked(
            "<path ", setIdClass(_b), "d='"
        );

        for (uint i = 3 ; i < _b.length ; i++) {
            if(uint8(_b[i]) == 77) {
                pathdata = abi.encodePacked(
                    pathdata, "M",
                    getPoints(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 109) {
                pathdata = abi.encodePacked(
                    pathdata, "m",
                    getPoints(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 76) {
                pathdata = abi.encodePacked(
                    pathdata, "L",
                    getPoints(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 108) {
                pathdata = abi.encodePacked(
                    pathdata, "l",
                    getPoints(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 67) {
                pathdata = abi.encodePacked(
                    pathdata, "C",
                    getPoints(_b, i+1, 6)
                );
                i += 6;
            } else if (uint8(_b[i]) == 86) {
                pathdata = abi.encodePacked(
                    pathdata, "V",
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 118) {
                pathdata = abi.encodePacked(
                    pathdata, "v",
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 72) {
                pathdata = abi.encodePacked(
                    pathdata, "H",
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 104) {
                pathdata = abi.encodePacked(
                    pathdata, "h",
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 83) {
                pathdata = abi.encodePacked(
                    pathdata, "S",
                    getPoints(_b, i+1, 4)
                );
                i += 4;
            } else if (uint8(_b[i]) == 115) {
                pathdata = abi.encodePacked(
                    pathdata, "s",
                    getPoints(_b, i+1, 4)
                );
                i += 4;
            } else if (uint8(_b[i]) == 90) {
                pathdata = abi.encodePacked(
                    pathdata, "Z"
                );
            } else if (uint8(_b[i]) == 122) {
                pathdata = abi.encodePacked(
                    pathdata, "z"
                );
            } else {
                pathdata = abi.encodePacked(
                    pathdata, "**" , i.toString(), "-", 
                    uint8(_b[i]).toString()
                    );
            }
        }
        return(
            abi.encodePacked(
                pathdata, "'",
                endingtag(_b)
            )
        );
    }

// ------ tools -----------

    // @dev define id and class in css format "id='in' class='cn'" 
    // where 0 <= n  >= 255  
    function setIdClass(bytes memory _b) pure internal  returns (bytes memory) {
        bytes memory idText;
        if (byte2uint8(_b, 0) > 0){
            //idText = string(abi.encodePacked(
            idText = abi.encodePacked(
                "id='i",
                byte2uint8(_b, 0).toString(),
                "' "
            );
        }
        return abi.encodePacked(
            idText,
            "class='c", byte2uint8(_b, 1).toString(),
            "' "
        );
    }
    
    // Returns the ending tag as defined in_b[3]
    function endingtag(bytes memory _b) pure internal returns (string memory) {
        if (byte2uint8(_b,2) > 0) {
            return " />";
        }
        return ">";
    }


    // Returns 'n' stringified and spaced uint8
    function getPoints(bytes memory _data, uint256 _offset, uint256 _len) pure internal returns (bytes memory) { 
        bytes memory res;
        require (_data.length >= _offset + _len, "Out of range");
        for (uint i = _offset ; i < _offset + _len ; i++) {
            res = abi.encodePacked(
                res,
                byte2uint8(_data, i).toString(),
                " "
            );
        }
        return res;
    }
    // Returns one uint8 in a byte array
    function byte2uint8(bytes memory _data, uint256 _offset) pure internal returns (uint8) { 
        require (_data.length > _offset, "Out of range");
        return uint8(_data[_offset]);
    }
}