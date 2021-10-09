/**
 *Submitted for verification at polygonscan.com on 2021-10-09
*/

pragma solidity 0.8.0;

// Global Enums and Structs

enum AnimTransfType { translate, scale, rotate, skewX, skewY }

struct svgStyle {
    uint8 conf; 
    uint8 stroke_width;
    bytes element; // target element to apply the style
    bytes fill;    // rgba or plain id string
    bytes stroke;  // rgba or plain id string
}

// Part: ISvgTools

interface ISvgTools {
    function getColor(string memory) external view returns (bytes memory);
    function getColor(string memory, uint8 )
    external view returns (bytes memory);
    function toEthTxt(uint256, uint8) external pure returns (bytes memory);
    function autoLinearGradient(bytes memory, bytes memory, bytes memory)
    external view returns (bytes memory);
    function autoLinearGradient(bytes memory, bytes memory, bytes memory, bytes memory)
    external view returns (bytes memory);
    function startSvgRect(bytes memory, bytes memory, bytes memory)
    external view returns (bytes memory);
    function round2Txt(uint256, uint8, uint8)
    external pure returns (bytes memory);
}

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

// Part: SvgCore

library SvgCore {

    using Strings for uint256;
    using Strings for uint8;

    // Open <svg> tag
    // _vBSize defines the viewBox in 4 bytes
    //   [0] x
    //   [1] y
    //   [2] length
    //   [3] width
    // accepts custom attributes in _customAttributes
    function startSvg(
        bytes memory _vBSize,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg ',
            'viewBox="',
            stringifyIntSet(_vBSize, 0, 4),
            '" xmlns="http://www.w3.org/2000/svg" ',
            _customAttributes,
            '>'
        );
    }

    // Close </svg> tag
    function endSvg(
    ) public pure returns (bytes memory) {
        return('</svg>');
    }

    // <g _customAttributes></g> tag encloses _b
    function defs(
        bytes memory _b,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<g ',
            _customAttributes,
            '>',
            _b,
            '</g>'
        );
    }
    // <defs></defs> tag encloses _b
    function defs(
        bytes memory _b
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<defs>',
            _b,
            '</defs>'
        );
    }
    // returns a <symbol id=...>_content</symbol>
    function symbol(
        bytes memory _id,
        bytes memory _content
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<symbol id="',
            _id,
            '">',
            _content,
            '</symbol>'
        );
    }

    // <mask id="_id">_b<mask> tag encloses _b
    // accepts custom attributes in _customAttributes
    function mask(
        bytes memory _b,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<mask ',
            _customAttributes,
            '>',
            _b,
            '</mask>'
        );
    }

    // Takes 4 bytes starting from the given offset
    // Returns css' 'rgba(r,v,b,a%)'
    // so alpha should be between 0 and 100
    function toRgba(
        bytes memory _rgba,
        uint256 offset
    ) public pure returns (bytes memory){

        return abi.encodePacked(
            "rgba(",
            byte2uint8(_rgba, offset).toString(), ",",
            byte2uint8(_rgba, offset + 1).toString(), ",",
            byte2uint8(_rgba, offset + 2).toString(), ",",
            byte2uint8(_rgba, offset + 3).toString(),
            "%)"
        );
    }

    // defines a style for '_element' class or id string (eg. '#iprefix_1') 
    // colors are defined in 4 bytes ; red,green,blue,alpha OR url(#id)
    // then if set stroke color (RGBA or #id),
    // then if set stroke-width
    // see idoc about svgStyle.conf in the struct def.
    // note: As "_element" is a free string you can pass "svg" for a default style
    function style(
        svgStyle memory _style
    ) public pure returns (bytes memory) {
        return style(_style, '');
    }
    function style(
        svgStyle memory _style,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
            bytes memory attributes; 

            attributes = abi.encodePacked(
                '<style>', 
                _style.element, '{fill:');
            if (_style.conf & 1 == 1) {
                attributes = abi.encodePacked(
                    attributes,
                    'url(',
                    _style.fill,
                    ');'
                );
            } else {
                if (_style.fill.length == 4) {
                    attributes = abi.encodePacked(
                        attributes,
                        toRgba(_style.fill, 0), ';'
                    );
                } else {
                    attributes = abi.encodePacked(
                        attributes,
                        'none;'
                    );
                }
            }
            if (_style.conf & 2 == 2) {
                attributes = abi.encodePacked(
                    attributes,
                    'stroke:url(',
                    _style.stroke,
                    ');'
                );
            } else {
                if (_style.stroke.length == 4) {
                    attributes = abi.encodePacked(
                        attributes,
                        'stroke:',
                        toRgba(_style.stroke, 0),
                        ';'
                    );
                }
            }
            attributes = abi.encodePacked(
                attributes,
                'stroke-width:',
                _style.stroke_width.toString(),
                ';'
            );
            return abi.encodePacked(
                attributes,
                _customAttributes,
                '}</style>'
            );
    }

    // Returns a line element.
    // _coord:
    //   [0] : General format applies
    //   [1] : x1 
    //   [2] : y1
    //   [3] : x2
    //   [4] : y2
    function line(
        bytes memory _coord,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        // add .0001 is a workaround for stroke filling
        // doesn'n work on horizontal and vertical lines
        return abi.encodePacked(
            '<line x1="',
            byte2uint8(_coord, 1).toString(),
            '.0001" y1="',
            byte2uint8(_coord, 2).toString(),
            '.0001" x2="',
            byte2uint8(_coord, 3).toString(),
            '" y2="',
            byte2uint8(_coord, 4).toString(),
                '" ',
            _customAttributes,
            endingtag(_coord)
        );
    }
    // Returns a polyline: Variable length ; "infinite" coordinates
    // _coords:
    //   [0] : General format applies
    //   [1],[2] x,y 1st point
    //   [3],[4] x,y 2nd point
    //   [5],[6] x,y 3rd point
    //   ... , ...
    // Define one or more lines depending on the number of parameters
    function polyline(
        bytes memory _coords,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {

        return abi.encodePacked(
            '<polyline  points="', 
            stringifyIntSet(_coords, 1, _coords.length - 1),
            '" ',
            _customAttributes,
            endingtag(_coords)
        );
    }

    // Returns a rectangle
    // _r:
    //   [0] : General format applies
    //   [1],[2] x,y 1st point
    //   [3],[4] width, height
    function rect(
        bytes memory _r,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {

        return abi.encodePacked(
            '<rect x="', 
            byte2uint8(_r, 1).toString(),
            '" y="',
            byte2uint8(_r, 2).toString(),
            '" width="',
            byte2uint8(_r, 3).toString(),
            '" height="',
            byte2uint8(_r, 4).toString(),
            '" ',
            _customAttributes,
            endingtag(_r)
        );
    }

    // Returns a polygon, with a variable number of points
    // _p:
    //   [0] : General format applies
    //   [1],[2] x,y 1st point
    //   [3],[4] x,y 2nd point
    //   [5],[6] x,y 3rd point
    //   ... , ...
    // Define one or more lines depending on the number of parameters
    function polygon(
        bytes memory _p,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {

        return abi.encodePacked(
            '<polygon points="',
            stringifyIntSet(_p, 1, _p.length -1),
            '" ',
            _customAttributes,
            endingtag(_p)
        );
    }

    // Returns a circle
    // _c:
    //   [0] : General format applies
    //   [1] : cx 
    //   [2] : cy Where cx,cy defines the center.
    //   [3] : r = radius
    function circle(
        bytes memory _c,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<circle ', 
            'cx="', 
            byte2uint8(_c, 1).toString(),
            '" cy="',
            byte2uint8(_c, 2).toString(),
            '" r="',
            byte2uint8(_c, 3).toString(),
            '" ',
            _customAttributes,
            endingtag(_c)
        );  
    }

    // Returns an ellipse
    // _e:
    //   [0] : General format applies
    //   [1] : cx 
    //   [2] : cy Where cx,cy defines the center.
    //   [3] : rx = X radius
    //   [4] : ry = Y radius
    function ellipse(
        bytes memory _e,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<ellipse ',
            'cx="',
            byte2uint8(_e, 1).toString(),
            '" cy="',
            byte2uint8(_e, 2).toString(),
            '" rx="',
            byte2uint8(_e, 3).toString(),
            '" ry="',
            byte2uint8(_e, 4).toString(),
            '" ',
            _customAttributes,
            endingtag(_e)
        );  
    }


    // Returns a <use href='#id' ...
    // _coord:
    //   [0] : General format applies
    //   [1],[2] x,y
    function use(
        bytes memory _coord,
        bytes memory _href,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<use ', 
            'href="',
            _href,
            '" x="',
            byte2uint8(_coord, 1).toString(),
            '" y="',
            byte2uint8(_coord, 2).toString(),
            '" ',
            _customAttributes,
            endingtag(_coord)
        );
    }

    // Returns a linearGradient
    //  _lg:
    //   [0] General format applies but adds an option:
    //   [0] if i & 128:
    //      [3] x1
    //      [4] x2
    //      [5] y1
    //      [6] y2
    //      [7..10] RGBA
    //      [11] offset %
    //      [12..15] RGBA
    //      [16] offset %
    //      [...]
    //   else: RGBA starts at [3]
    // Define a linear gradient, better used in a <defs> tag. 
    // Applied to an object with 'fill:url(#id)'
    // Then loops, offset + RGBA = 5 bytes 
    function linearGradient(
        bytes memory _lg,
        bytes memory _id,
        bytes memory _customAttributes
    ) external pure returns (bytes memory) {
        bytes memory grdata; 
        uint8 offset = 1;

        if (uint8(_lg[0]) & 128 == 128) {
            grdata = abi.encodePacked(
                'x1="',
                byte2uint8(_lg, 1).toString(),
                '%" x2="',
                byte2uint8(_lg, 2).toString(),
                '%" y1="',
                byte2uint8(_lg, 3).toString(),
                '%" y2="',
                byte2uint8(_lg, 4).toString(), '%"'
            );
            offset = 5;
        }
        grdata = abi.encodePacked(
            '<linearGradient id="',
            _id,
            '" ',
            _customAttributes,
            grdata,
            '>'
        );
        for (uint i = offset ; i < _lg.length ; i+=5) {
            grdata = abi.encodePacked(
                grdata,
                '<stop offset="',
                byte2uint8(_lg, i).toString(),
                '%" stop-color="',
                toRgba(_lg, i+1),
                '" id="',
                _id,
                byte2uint8(_lg, i).toString(),
                '"/>'
            );
        }
        return abi.encodePacked(grdata, '</linearGradient>');
    }

    // Returns a <text ...>_text</text> block
    // Non standard ; _b only contains coordinates.
    function text(
        bytes memory _b,
        bytes memory _text,
        bytes memory _customAttributes
    ) external pure returns (bytes memory) {
        return abi.encodePacked(
            '<text x="', 
            byte2uint8(_b, 0).toString(),
            '" y="',
            byte2uint8(_b, 1).toString(),
            '" ',
            _customAttributes,
            '>',
            _text,
            '</text>'
        );

    }

    // Returns animate
    // Non standard function.
    // _b contains the 'values' Svg field.
    //   [0] : number of byte element per tuple
    //   [1:] values
    // the tuples are separated by ';'.
    // _element refers to the id to apply the animation
    // _attr contains the attribute name set to 'attribute'
    // _element is the target element to animate
    // _attr the attribute to animate
    // _duration of the animation is in seconds
    // repeatCount's default is 'indefinite'
    function animate(
        bytes memory _b,
        bytes memory _element,
        bytes memory _attr,
        uint8 _duration,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return animate(_b, _element, _attr, _duration, 0, _customAttributes);
    }

    function animate(
        bytes memory _b,
        bytes memory _element,
        bytes memory _attr,
        uint8 _duration,
        uint8 _repeatCount,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<animate href="',
            _element,
            '" attributeName="',
            _attr,
            '" values="',
            tuples2ValueMatrix(_b),
            '" dur="',
            _duration.toString(),
            's" repeatCount="',
            repeatCount(_repeatCount),
            '" ',
            _customAttributes,
            '/>'
        );
    }

    // Returns animateTransform
    // _b is the same as in animate
    // AnimTransfType is an enum: {translate, scale, rotate, skewX, skewY}
    function animateTransform(
        bytes memory _b,
        bytes memory _element,
        AnimTransfType _type,
        uint8 _duration,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return animateTransform(_b, _element, _type, _duration, 0, _customAttributes);
    }

    function animateTransform(
        bytes memory _b,
        bytes memory _element,
        AnimTransfType _type,
        uint8 _duration,
        uint8 _repeatCount,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<animateTransform href="',
            _element,
            '" attributeName="transform" type="',
            animTransfType(_type),
            '" dur="',
            _duration.toString(),
            's" repeatCount="',
            repeatCount(_repeatCount),
            '" values="',
            tuples2ValueMatrix(_b),
            '" ',
            _customAttributes,
            '/>'
        );
    }

    // Returns 'type' for animateTransform 
    function animTransfType(AnimTransfType _t)
    internal pure returns (bytes memory) {
        if (_t == AnimTransfType.translate) return "translate";
        if (_t == AnimTransfType.scale)     return "scale";
        if (_t == AnimTransfType.rotate)    return "rotate";
        if (_t == AnimTransfType.skewX)     return "skewX";
        if (_t == AnimTransfType.skewY)     return "skewY";
    }

    // Returns a path
    // See github's repo oh how to encode data for path
    // A Q and T are not implemented yet
    // _b:
    //   [0] : General format applies
    //   [1:] : encoded data
    function path(
        bytes memory _b,
        bytes memory _customAttributes
    ) external pure returns (bytes memory) {

        bytes memory pathdata; 
        pathdata = '<path d="';

        for (uint i = 1 ; i < _b.length ; i++) {
            if(uint8(_b[i]) == 77) {
                pathdata = abi.encodePacked(
                    pathdata, 'M',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 109) {
                pathdata = abi.encodePacked(
                    pathdata, 'm',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 76) {
                pathdata = abi.encodePacked(
                    pathdata, 'L',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 108) {
                pathdata = abi.encodePacked(
                    pathdata, 'l',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 67) {
                pathdata = abi.encodePacked(
                    pathdata, 'C',
                    stringifyIntSet(_b, i+1, 6)
                );
                i += 6;
            } else if (uint8(_b[i]) == 86) {
                pathdata = abi.encodePacked(
                    pathdata, 'V',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 118) {
                pathdata = abi.encodePacked(
                    pathdata, 'v',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 72) {
                pathdata = abi.encodePacked(
                    pathdata, 'H',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 104) {
                pathdata = abi.encodePacked(
                    pathdata, 'h',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 83) {
                pathdata = abi.encodePacked(
                    pathdata, 'S',
                    stringifyIntSet(_b, i+1, 4)
                );
                i += 4;
            } else if (uint8(_b[i]) == 115) {
                pathdata = abi.encodePacked(
                    pathdata, 's',
                    stringifyIntSet(_b, i+1, 4)
                );
                i += 4;
            } else if (uint8(_b[i]) == 65) {
                pathdata = abi.encodePacked(
                    pathdata, 'A',
                    stringifyIntSet(_b, i+1, 7)
                );
                i += 7;
            } else if (uint8(_b[i]) == 97) {
                pathdata = abi.encodePacked(
                    pathdata, 'a',
                    stringifyIntSet(_b, i+1, 7)
                );
                i += 4;
            } else if (uint8(_b[i]) == 90) {
                pathdata = abi.encodePacked(
                    pathdata, 'Z'
                );
            } else if (uint8(_b[i]) == 122) {
                pathdata = abi.encodePacked(
                    pathdata, 'z'
                );
            } else {
                pathdata = abi.encodePacked(
                    pathdata, '**' , i.toString(), '-', 
                    uint8(_b[i]).toString()
                    );
            }
        }
        return(
            abi.encodePacked(
                pathdata, '" ',
                _customAttributes,
                endingtag(_b)
            )
        );
    }
// ------ tools -----------

    // Returns the ending tag as defined in_b[3] (odd number)
    function endingtag(
        bytes memory _b
    ) pure public returns (string memory) {
        if (byte2uint8(_b,0) & 1 == 0) {
            return ' />';
        }
        return '>';
    }

    // Returns 'n' stringified and spaced uint8
    function stringifyIntSet(
        bytes memory _data,
        uint256 _offset,
        uint256 _len
    ) public pure returns (bytes memory) { 
        bytes memory res;
        require (_data.length >= _offset + _len, 'Out of range');
        for (uint i = _offset ; i < _offset + _len ; i++) {
            res = abi.encodePacked(
                res,
                byte2uint8(_data, i).toString(),
                ' '
            );
        }
        return res;
    }

    // Used by animation*, receives an array whose the first elements indicates
    // the number of tuples, and the values data
    // returns the values separated by spaces,
    // tuples separated by semicolon
    function tuples2ValueMatrix(
        bytes memory _data
    ) public pure returns (bytes memory) { 
        uint256 _len = byte2uint8(_data, 0);
        bytes memory res;

        for (uint i = 1 ; i <= _data.length - 1 ; i += _len) {
            res = abi.encodePacked(
                res,
                stringifyIntSet(_data, i, _len),
                ';'
            );
        }
        return res;

    }

    // returns a repeatCount for the animations.
    // If uint8 == 0 then indefinite loop
    // else a count of loops.
    function repeatCount(uint8 _r)
    public pure returns (string memory) {
        if (_r == 0) {
            return 'indefinite';
        } else {
            return _r.toString();
        }
    }

    // Returns one uint8 in a byte array
    function byte2uint8(
        bytes memory _data,
        uint256 _offset
    ) public pure returns (uint8) { 
        require (_data.length > _offset, 'Out of range');
        return uint8(_data[_offset]);
    }


}

// File: SvgWidgets.sol

contract SvgWidgets {

    using Strings for uint256;
    ISvgTools   sTools ;
    // path defines an arc
    bytes constant gaugeArcPath = hex'004d0a324128280000016432';
    bytes constant gaugeHLine   =  hex'0009096409';
    bytes constant gaugeVLine   =  hex'0009640909';
    bytes constant gaugeStyleStr = 'pathLength="100" ';
    // Compressed path data for SuperFluid logo (with prefix '00'):
    bytes constant logoSFPath  = hex'004d1f184c18184c18104c10104c10094c1f094c1f185a4d091f4c101f4c10184c09184c091f5a4d00044c0024430026022804284c2428432628282628244c2804432802260024004c0400430200000200044c00045a';

    constructor(address _sTools){
        sTools   = ISvgTools(_sTools);
    }

    /*  ---------------- Symbols ---------- */

    // returns an arc gauge <symbol> shape
    // can be displayed with <use href='#`_id`' ...
    function includeSymbolGaugeArc(
        bytes memory _id
    ) external view returns (bytes memory) {
        return SvgCore.symbol(
            _id,    
            abi.encodePacked(
                SvgCore.path( // background
                    gaugeArcPath,
                    gaugeStyleBgCustom(_id)
                ),
                SvgCore.path( // gauge's display
                    gaugeArcPath,
                    gaugeStyleFgCustom(_id)
                ),
                SvgCore.style(_gaugeBgStyle(_id), '')
            ) 
        );
    } 

    // returns a vertical bar gauge <symbol> shape
    // can be displayed with <use href='#`_id`' ...
    function includeSymbolGaugeV(
        bytes memory _id
    ) external view returns (bytes memory) {

        return SvgCore.symbol(
            _id,    
            abi.encodePacked(
                SvgCore.line(
                    gaugeVLine,
                    gaugeStyleBgCustom(_id)
                ),
                SvgCore.line(
                    gaugeVLine,
                    gaugeStyleFgCustom(_id)
                ),
                SvgCore.style(_gaugeBgStyle(_id), '')
            )
        );
    } 
    //  returns an eye symbol.
    function includeSymbolEye(
        bytes memory _id
    ) external view returns (bytes memory) {
        return SvgCore.symbol(
            _id,
            abi.encodePacked(
                SvgCore.ellipse(hex'0010100b0f', 'style="stroke:#a1830b;fill:#fff"'),
                SvgCore.circle(hex'00101006', 'id="swpupil" style="fill:#000"')
            )
        );
    }
/* Example of use:
    <use href="#eye" x="10" y="10" class="ee"/>
    <use href="#eye" x="40" y="10" class="ee" />
    <animate href="#p1" attributeName="cx" values="16;8;6;9;16" dur="2s" repeatCount="1"/>
    <symbol id="eye">
                                                             
        <ellipse  cx="16" cy="16" rx="11" ry="15" style="stroke:#a1830b; fill:#fff" />     
        <circle class="ckb" id="p1" cx="16" cy="16" r="6">                      
        </circle>
*/
    // returns Superfluid logo as a <symbol>
    // can be displayed with <use href='#`_id`' ...
    function includeSymbolSFLogo(bytes memory _id)
    public view returns (bytes memory){
        return SvgCore.symbol(
            _id,
            SvgCore.path(
                logoSFPath,
                'fill-rule="evenodd" fill="#12141E"'
            )
        );
    }

    /*  ---------------- Internal functions ---------- */
    // Returns a svgStyle for gauges background
    function _gaugeBgStyle(bytes memory _id) internal view returns (svgStyle memory) {
        return svgStyle(
            0,  // no option
            10, // stroke width 10
            abi.encodePacked('#', 'bg', _id), // id
            '', // no fill
            sTools.getColor('DarkGrey') // stroke color
        );
    }

    // Returns textual style attributes for background 
    function gaugeStyleBgCustom(bytes memory _id)
    internal pure returns (bytes memory) {
        return abi.encodePacked(
            gaugeStyleStr,
            'stroke-dasharray="100, 100" id="bg',
           _id,
            '"' 
        );
    }

    // Returns textual style attributes for the foreground 
    function gaugeStyleFgCustom(bytes memory _id)
    internal pure returns (bytes memory) {
        return abi.encodePacked(
            gaugeStyleStr,
            'id="fg',
           _id,
            '"' 
        );
    }
}