/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.5.0;

library JsmnSolLib {

    enum JsmnType { UNDEFINED, OBJECT, ARRAY, STRING, PRIMITIVE,ADDRESS }

    uint8 constant RETURN_SUCCESS = 0;
    uint8 constant RETURN_ERROR_INVALID_JSON = 1;
    uint8 constant RETURN_ERROR_PART = 2;
    uint8 constant RETURN_ERROR_NO_MEM = 3;
    //令牌组
    struct Token {
        JsmnType jsmnType;
        uint start; //开始字符串位置
        bool startSet; //初始化为false，转成true后表示指针已经开始读该节点
        uint end;   //结束字符串位置
        bool endSet;//初始化为false，转成true后表示指针已经读完该节点
        uint8 size; //该节点的子节点数量
    }

    //解析器
    struct Parser {
        uint pos; //当前指针
        uint toknext; //下一个节点
        int toksuper; //上一个节点
    }
    //判断json是否合法
    function isJson(string memory json,uint numberElements)public pure returns(bool){
        Token[] memory allTokens;
        uint8  res;
        uint   toknext;
        (res,allTokens,toknext) =  parse(json,numberElements);
        if(res == RETURN_SUCCESS){
            return true;
        }
        return false;
    }

    //根据key 获得value
    function getValue(string memory json,string memory key,uint numberElements)public pure returns(string memory){
        Token[] memory allTokens;
        uint8 res;
        uint  toknext;
        (res,allTokens,toknext) =  parse(json,numberElements);
        require(res == RETURN_SUCCESS, "json invalid");
        for(uint  i=1;i<allTokens.length-1;i++){
            //如果是key
            if(allTokens[i].jsmnType==JsmnType.STRING && allTokens[i].size !=0){
                if(strCompare(key,getBytes(json, allTokens[i].start, allTokens[i].end))== 0){
                    return getBytes(json, allTokens[i+1].start, allTokens[i+1].end);
                }                
            }
        }
        return "0";
    }


    function init(uint length) internal pure returns (Parser memory, Token[] memory) {
        Parser memory p = Parser(0, 0, -1);
        Token[] memory t = new Token[](length);
        return (p, t);
    }
    
    //初始化新节点
    function allocateToken(Parser memory parser, Token[] memory tokens) internal pure returns (bool, Token memory) {
        if (parser.toknext >= tokens.length) {
            // 节点的长度超过设置的长度，返回失败
            return (false, tokens[tokens.length-1]);
        }
        Token memory token = Token(JsmnType.UNDEFINED, 0, false, 0, false, 0);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }
    //封装子节点
    function fillToken(Token memory token, JsmnType jsmnType, uint start, uint end) internal pure {
        token.jsmnType = jsmnType;
        token.start = start;
        token.startSet = true;
        token.end = end;
        token.endSet = true;
        token.size = 0;
    }

    //字符串解析
    function parseString(Parser memory parser, Token[] memory tokens, bytes memory s) internal pure returns (uint8) {
        uint start = parser.pos;
        bool success;
        Token memory token;
        parser.pos++;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // 字符串结束
            if (c == '"') {
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return RETURN_ERROR_NO_MEM;
                }
                fillToken(token, JsmnType.STRING, start+1, parser.pos);
                return RETURN_SUCCESS;
            }

            //处理反斜杠\后的字符
            if (uint8(c) == 92 && parser.pos + 1 < s.length) {
                parser.pos++;
                if (s[parser.pos] == '\"' || s[parser.pos] == '/' || s[parser.pos] == '\\'
                    || s[parser.pos] == 'f' || s[parser.pos] == 'r' || s[parser.pos] == 'n'
                    || s[parser.pos] == 'b' || s[parser.pos] == 't') {
                        continue;
                        } else {
                            // 反斜杠后不是以上内容的字符提示报错
                            parser.pos = start;
                            return(RETURN_ERROR_INVALID_JSON);
                        }
                    }
            }
        parser.pos = start;
        return RETURN_ERROR_PART;
    }

    function parsePrimitive(Parser memory parser, Token[] memory tokens, bytes memory s) internal pure returns (uint8) {
        bool found = false;
        uint start = parser.pos;
        byte c;
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

    function parse(string memory json, uint numberElements) internal pure returns (uint8, Token[] memory tokens, uint) {
        bytes memory s = bytes(json);
        bool success;
        Parser memory parser;
        (parser, tokens) = init(numberElements);

        // Token memory token;
        uint8 r;
        uint count = parser.toknext;
        uint i;
        Token memory token;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // 0x7b, 0x5b 开花括号或者中括号{[
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

            // 关花括号或者中括号}]
            if (c == 0x7d || c == 0x5d) {
                JsmnType tokenType = (c == 0x7d ? JsmnType.OBJECT : JsmnType.ARRAY);
                bool isUpdated = false;
                //节点封装
                for (i=parser.toknext-1; i>=0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        if (token.jsmnType != tokenType) {
                            // 节点没有关闭，但是类型不符合报错，json格式错误
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                        parser.toksuper = -1;
                        tokens[i].end = parser.pos + 1;
                        tokens[i].endSet = true;
                        isUpdated = true;
                        break;
                    }
                }
                //有关闭括号，但没有封装，json格式错误
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
                        parser.toksuper = uint128(i);
                    }
                }
                continue;
            }

            // 字符串类型处理
            if (c == '"') {
                r = parseString(parser, tokens, s);

                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
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

            // number，boolean，null 类型处理
            if ((c >= '0' && c <= '9') || c == '-' || c == 'f' || c == 't' || c == 'n') {
                if (parser.toksuper != -1) {
                    token = tokens[uint(parser.toksuper)];
                    //如果改节点不是value则报错，这几种类型只能放value
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

            // 其他可打印的字符，格式错误
            if (c >= 0x20 && c <= 0x7e) {
                return (RETURN_ERROR_INVALID_JSON, tokens, 0);
            }
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    //获取某一段字符串
    function getBytes(string memory json, uint start, uint end) internal pure returns (string memory) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end-start);
        for (uint i=start; i<end; i++) {
            result[i-start] = s[i];
        }
        return string(result);
    }

    // 字符串保留整形
    function parseInt(string memory _a) internal pure returns (int) {
        return parseInt(_a, 0);
    }

    // 字符串转出整形，保留到小数点后_b位
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
                //是数字
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint8(bresult[i]) - 48; //48是ascii 0的位置
            } else if (uint8(bresult[i]) == 46) decimals = true;  //小数点
        }
        if (_b > 0) mint *= int(10**_b);
        if (negative) mint *= -1;
        return mint;
    }
    //无符号整形转字符串
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
    //字符串布尔型判断
    function parseBool(string memory _a) internal pure returns (bool) {
        if (strCompare(_a, 'true')== 0) {
            return true;
        } else {
            return false;
        }
    }

    function bytesToAddress(bytes memory bys) public pure returns (address addr) {
     require(bys.length==20, "address invalid");
      assembly {
        addr := mload(add(bys,20))
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