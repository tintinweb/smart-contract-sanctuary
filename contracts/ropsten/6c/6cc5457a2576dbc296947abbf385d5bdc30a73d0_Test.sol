pragma solidity ^0.4.23;

library JsmnSolLib {

    enum JsmnType {UNDEFINED, OBJECT, ARRAY, STRING, PRIMITIVE}

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

    function init(uint length) pure internal returns (Parser, Token[]) {
        Parser memory p = Parser(0, 0, - 1);
        Token[] memory t = new Token[](length);
        return (p, t);
    }

    function allocateToken(Parser parser, Token[] tokens) pure internal returns (bool, Token) {
        if (parser.toknext >= tokens.length) {
            // no more space in tokens
            return (false, tokens[tokens.length - 1]);
        }
        Token memory token = Token(JsmnType.UNDEFINED, 0, false, 0, false, 0);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }

    function fillToken(Token token, JsmnType jsmnType, uint start, uint end) pure internal {
        token.jsmnType = jsmnType;
        token.start = start;
        token.startSet = true;
        token.end = end;
        token.endSet = true;
        token.size = 0;
    }

    function parseString(Parser parser, Token[] tokens, bytes s) pure internal returns (uint) {
        uint start = parser.pos;
        bool success;
        Token memory token;
        parser.pos++;

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // Quote -> end of string
            if (c == &#39;&quot;&#39;) {
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return RETURN_ERROR_NO_MEM;
                }
                fillToken(token, JsmnType.STRING, start + 1, parser.pos);
                return RETURN_SUCCESS;
            }

            if (c == 92 && parser.pos + 1 < s.length) {
                // handle escaped characters: skip over it
                parser.pos++;
                if (s[parser.pos] == &#39;\&quot;&#39; || s[parser.pos] == &#39;/&#39; || s[parser.pos] == &#39;\\&#39;
                || s[parser.pos] == &#39;f&#39; || s[parser.pos] == &#39;r&#39; || s[parser.pos] == &#39;n&#39;
                || s[parser.pos] == &#39;b&#39; || s[parser.pos] == &#39;t&#39;) {
                    continue;
                } else {
                    // all other values are INVALID
                    parser.pos = start;
                    return (RETURN_ERROR_INVALID_JSON);
                }
            }
        }
        parser.pos = start;
        return RETURN_ERROR_PART;
    }

    function parsePrimitive(Parser parser, Token[] tokens, bytes s) pure internal returns (uint) {
        bool found = false;
        uint start = parser.pos;
        byte c;
        bool success;
        Token memory token;

        for (; parser.pos < s.length; parser.pos++) {
            c = s[parser.pos];
            if (c == &#39; &#39; || c == &#39;\t&#39; || c == &#39;\n&#39; || c == &#39;\r&#39; || c == &#39;,&#39;
            || c == 0x7d || c == 0x5d) {
                found = true;
                break;
            }
            if (c < 32 || c > 127) {
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

    function parse(string json, uint numberElements) pure internal returns (uint, Token[], uint) {
        bytes memory s = bytes(json);
        Parser memory parser;
        bool success;
        (parser, tokens) = init(numberElements);
        JsmnSolLib.Token[] memory tokens;
        Token memory token;

        // Token memory token;
        uint r;
        uint count = parser.toknext;
        uint i;

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // 0x7b, 0x5b opening curly parentheses or brackets
            if (c == 0x7b || c == 0x5b) {
                count++;
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    return (RETURN_ERROR_NO_MEM, tokens, 0);
                }
                if (parser.toksuper != - 1) {
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
                for (i = parser.toknext - 1; i >= 0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        if (token.jsmnType != tokenType) {
                            // found a token that hasn&#39;t been closed but from a different type
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                        parser.toksuper = - 1;
                        tokens[i].end = parser.pos + 1;
                        tokens[i].endSet = true;
                        isUpdated = true;
                        break;
                    }
                }
                if (!isUpdated) {
                    return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                }
                for (; i > 0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = int(i);
                        break;
                    }
                }

                if (i == 0) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = uint128(i);
                    }
                }
                continue;
            }

            // 0x42
            if (c == &#39;&quot;&#39;) {
                r = parseString(parser, tokens, s);

                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                //JsmnError.INVALID;
                count++;
                if (parser.toksuper != - 1)
                    tokens[uint(parser.toksuper)].size++;
                continue;
            }

            // &#39; &#39;, \r, \t, \n
            if (c == &#39; &#39; || c == 0x11 || c == 0x12 || c == 0x14) {
                continue;
            }

            // 0x3a
            if (c == &#39;:&#39;) {
                parser.toksuper = int(parser.toknext - 1);
                continue;
            }

            if (c == &#39;,&#39;) {
                if (parser.toksuper != - 1
                && tokens[uint(parser.toksuper)].jsmnType != JsmnType.ARRAY
                && tokens[uint(parser.toksuper)].jsmnType != JsmnType.OBJECT) {
                    for (i = parser.toknext - 1; i >= 0; i--) {
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
            if ((c >= &#39;0&#39; && c <= &#39;9&#39;) || c == &#39;-&#39; || c == &#39;f&#39; || c == &#39;t&#39; || c == &#39;n&#39;) {
                if (parser.toksuper != - 1) {
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
                if (parser.toksuper != - 1) {
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

    function getBytes(string json, uint start, uint end) pure internal returns (string) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end - start);
        for (uint i = start; i < end; i++) {
            result[i - start] = s[i];
        }
        return string(result);
    }

    // parseInt
    function parseInt(string _a) pure internal returns (int) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) pure internal returns (int) {
        bytes memory bresult = bytes(_a);
        int mint = 0;
        bool decimals = false;
        bool negative = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((i == 0) && (bresult[i] == &#39;-&#39;)) {
                negative = true;
            }
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += int(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= int(10 ** _b);
        if (negative) mint *= - 1;
        return mint;
    }

    function uint2str(uint i) pure internal returns (string){
        if (i == 0) return &quot;0&quot;;
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function parseBool(string _a) pure public returns (bool) {
        if (strCompare(_a, &#39;true&#39;) == 0) {
            return true;
        } else {
            return false;
        }
    }

    function strCompare(string _a, string _b) pure internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return - 1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return - 1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

}

// File: contracts/Test.sol

contract Test {

    string public json = &#39;{ &quot;key_1&quot;: &quot;value&quot;, &quot;key_2&quot;: 23, &quot;key_3&quot;: true }&#39;;

    constructor() public {
    }

    function getReturnValue(uint i) external view returns (uint){
        uint returnValue;
        JsmnSolLib.Token[] memory tokens;
        uint actualNum;

        (returnValue, tokens, actualNum) = JsmnSolLib.parse(json, i);

        return returnValue;
    }

//    function getTokens() external view returns (JsmnSolLib.Token[]){
//        uint returnValue;
//        JsmnSolLib.Token[] memory tokens;
//        uint actualNum;
//
//        (returnValue, tokens, actualNum) = JsmnSolLib.parse(json, 10);
//
//        return tokens;
//    }

    function getActualNum(uint i) external view returns (uint){
        uint returnValue;
        JsmnSolLib.Token[] memory tokens;
        uint actualNum;

        (returnValue, tokens, actualNum) = JsmnSolLib.parse(json, i);

        return actualNum;
    }
}