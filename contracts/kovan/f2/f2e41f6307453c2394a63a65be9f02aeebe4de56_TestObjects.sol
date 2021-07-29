/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: MIT
/*
Copyright (c) 2017 Christoph Niemann
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.1;

library JsmnSolLib {

    enum JsmnType { UNDEFINED, OBJECT, ARRAY, STRING, PRIMITIVE }

    uint constant RETURN_SUCCESS = 0;
    uint constant RETURN_ERROR_INVALID_JSON = 1;
    uint constant RETURN_ERROR_PART = 2;
    uint constant RETURN_ERROR_NO_MEM = 3;

    struct Token {
        JsmnType jsmnType;
        uint start;
        bool startSet;
        uint end;
        bool endSet;
        uint8 size;
    }

    struct Parser {
        uint pos;
        uint toknext;
        int toksuper;
    }
    
    

    function init(uint length) internal pure returns (Parser memory, Token[] memory) {
        Parser memory p = Parser(0, 0, -1);
        Token[] memory t = new Token[](length);
        return (p, t);
    }

    function allocateToken(Parser memory parser, Token[] memory tokens) internal pure returns (bool, Token memory) {
        if (parser.toknext >= tokens.length) {
            // no more space in tokens
            return (false, tokens[tokens.length-1]);
        }
        Token memory token = Token(JsmnType.UNDEFINED, 0, false, 0, false, 0);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }

    function fillToken(Token memory token, JsmnType jsmnType, uint start, uint end) internal pure {
        token.jsmnType = jsmnType;
        token.start = start;
        token.startSet = true;
        token.end = end;
        token.endSet = true;
        token.size = 0;
    }

    function parseString(Parser memory parser, Token[] memory tokens, bytes memory s) internal pure returns (uint) {
        uint start = parser.pos;
        bool success;
        Token memory token;
        parser.pos++;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // Quote -> end of string
            if (c == '"') {
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return RETURN_ERROR_NO_MEM;
                }
                fillToken(token, JsmnType.STRING, start+1, parser.pos);
                return RETURN_SUCCESS;
            }

            if (uint8(c) == 92 && parser.pos + 1 < s.length) {
                // handle escaped characters: skip over it
                parser.pos++;
                if (s[parser.pos] == '\"' || s[parser.pos] == '/' || s[parser.pos] == '\\'
                    || s[parser.pos] == 'f' || s[parser.pos] == 'r' || s[parser.pos] == 'n'
                    || s[parser.pos] == 'b' || s[parser.pos] == 't') {
                        continue;
                        } else {
                            // all other values are INVALID
                            parser.pos = start;
                            return(RETURN_ERROR_INVALID_JSON);
                        }
                    }
            }
        parser.pos = start;
        return RETURN_ERROR_PART;
    }

    function parsePrimitive(Parser memory parser, Token[] memory tokens, bytes memory s) internal pure returns (uint) {
        bool found = false;
        uint start = parser.pos;
        bytes1 c;
        bool success;
        Token memory token;
        for (; parser.pos < s.length; parser.pos++) {
            c = s[parser.pos];
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == ','
                || c == 0x7d || c == 0x5d) {
                    found = true;
                    break;
            }
            if (uint8(c) < 32 || uint8(c) > 127) {
                parser.pos = start;
                return RETURN_ERROR_INVALID_JSON;
            }
        }
        if (!found) {
            parser.pos = start;
            return RETURN_ERROR_PART;
        }

        // found the end
        (success, token) = allocateToken(parser, tokens);
        if (!success) {
            parser.pos = start;
            return RETURN_ERROR_NO_MEM;
        }
        fillToken(token, JsmnType.PRIMITIVE, start, parser.pos);
        parser.pos--;
        return RETURN_SUCCESS;
    }

    function parse(string memory json, uint numberElements) internal pure returns (uint, Token[] memory tokens, uint) {
        bytes memory s = bytes(json);
        bool success;
        Parser memory parser;
        (parser, tokens) = init(numberElements);

        // Token memory token;
        uint r;
        uint count = parser.toknext;
        uint i;
        Token memory token;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // 0x7b, 0x5b opening curly parentheses or brackets
            if (c == 0x7b || c == 0x5b) {
                count++;
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    return (RETURN_ERROR_NO_MEM, tokens, 0);
                }
                if (parser.toksuper != -1) {
                    tokens[uint(parser.toksuper)].size++;
                }
                token.jsmnType = (c == 0x7b ? JsmnType.OBJECT : JsmnType.ARRAY);
                token.start = parser.pos;
                token.startSet = true;
                parser.toksuper = int(parser.toknext - 1);
                continue;
            }

            // closing curly parentheses or brackets
            if (c == 0x7d || c == 0x5d) {
                JsmnType tokenType = (c == 0x7d ? JsmnType.OBJECT : JsmnType.ARRAY);
                bool isUpdated = false;
                for (i=parser.toknext-1; i>=0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        if (token.jsmnType != tokenType) {
                            // found a token that hasn't been closed but from a different type
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                        parser.toksuper = -1;
                        tokens[i].end = parser.pos + 1;
                        tokens[i].endSet = true;
                        isUpdated = true;
                        break;
                    }
                }
                if (!isUpdated) {
                    return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                }
                for (; i>0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = int(i);
                        break;
                    }
                }

                if (i==0) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = int128(uint128(i));
                    }
                }
                continue;
            }

            // 0x42
            if (c == '"') {
                r = parseString(parser, tokens, s);

                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                //JsmnError.INVALID;
                count++;
				if (parser.toksuper != -1)
					tokens[uint(parser.toksuper)].size++;
                continue;
            }

            // ' ', \r, \t, \n
            if (c == ' ' || c == 0x11 || c == 0x12 || c == 0x14) {
                continue;
            }

            // 0x3a
            if (c == ':') {
                parser.toksuper = int(parser.toknext -1);
                continue;
            }

            if (c == ',') {
                if (parser.toksuper != -1
                    && tokens[uint(parser.toksuper)].jsmnType != JsmnType.ARRAY
                    && tokens[uint(parser.toksuper)].jsmnType != JsmnType.OBJECT) {
                        for(i = parser.toknext-1; i>=0; i--) {
                            if (tokens[i].jsmnType == JsmnType.ARRAY || tokens[i].jsmnType == JsmnType.OBJECT) {
                                if (tokens[i].startSet && !tokens[i].endSet) {
                                    parser.toksuper = int(i);
                                    break;
                                }
                            }
                        }
                    }
                continue;
            }

            // Primitive
            if ((c >= '0' && c <= '9') || c == '-' || c == 'f' || c == 't' || c == 'n') {
                if (parser.toksuper != -1) {
                    token = tokens[uint(parser.toksuper)];
                    if (token.jsmnType == JsmnType.OBJECT
                        || (token.jsmnType == JsmnType.STRING && token.size != 0)) {
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                }

                r = parsePrimitive(parser, tokens, s);
                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                count++;
                if (parser.toksuper != -1) {
                    tokens[uint(parser.toksuper)].size++;
                }
                continue;
            }

            // printable char
            if (c >= 0x20 && c <= 0x7e) {
                return (RETURN_ERROR_INVALID_JSON, tokens, 0);
            }
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    function getBytes(string memory json, uint start, uint end) internal pure returns (string memory) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end-start);
        for (uint i=start; i<end; i++) {
            result[i-start] = s[i];
        }
        return string(result);
    }

    // parseInt
    function parseInt(string memory _a) internal pure returns (int) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string memory _a, uint _b) internal pure returns (int) {
        bytes memory bresult = bytes(_a);
        int mint = 0;
        bool decimals = false;
        bool negative = false;
        for (uint i=0; i<bresult.length; i++){
            if ((i == 0) && (bresult[i] == '-')) {
                negative = true;
            }
            if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += int256(uint256(uint8(bresult[i]) - 48));
            } else if (uint8(bresult[i]) == 46) decimals = true;
        }
        if (_b > 0) mint *= int(10**_b);
        if (negative) mint *= -1;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string memory){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function parseBool(string memory _a) internal pure returns (bool) {
        if (strCompare(_a, 'true') == 0) {
            return true;
        } else {
            return false;
        }
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

}


contract TestObjects {
    
    event log(uint returnValue, JsmnSolLib.Token[] tokens, uint actualNum);
    
    function testSimpleObjectInbound() public returns (uint returnValue, JsmnSolLib.Token[] memory tokens, uint actualNum){
        string memory json = '{"outerKey": "innerKey": "value"}}';
        
        uint returnValue;
        JsmnSolLib.Token[] memory tokens;
        uint actualNum;
        
        
        (returnValue, tokens, actualNum) = JsmnSolLib.parse(json, 20);
        emit log(returnValue, tokens, actualNum);
        
    }
    
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    // function testSimpleObject(bytes memory json) public returns (uint returnValue, JsmnSolLib.Token[] memory tokens, uint actualNum){
    //     // string memory json = '{"outerKey": {"innerKey": "value"}}';
        
    //     uint returnValue;
    //     JsmnSolLib.Token[] memory tokens;
    //     uint actualNum;
        
    //     (returnValue, tokens, actualNum) = JsmnSolLib.parse(bytes32ToString(json), 200);
        
    // }
    
    function testSimpleObject(string memory json) public returns (uint returnValue, JsmnSolLib.Token[] memory tokens, uint actualNum){
        string memory veronicaJson = json;
        
        uint returnValue;
        JsmnSolLib.Token[] memory tokens;
        uint actualNum;
        
        (returnValue, tokens, actualNum) = JsmnSolLib.parse(veronicaJson, 200);
        emit log(returnValue, tokens, actualNum);
    }
}