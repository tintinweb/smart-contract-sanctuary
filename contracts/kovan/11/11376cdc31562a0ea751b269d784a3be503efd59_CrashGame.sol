/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity ^0.8.5;

contract CrashGame {
    //bytes salt;

//placeholder for fn to convert integer to hex (do we need this?)

//patched for 0.5.0 breaking changes --
// "Conversions between bytesX and uintY of different size are now disallowed due to bytesX padding on the right
// and uintY padding on the left"
// seems to work correctly when tested on 0.8.4 with remix
function utfStringLength(string memory str) internal pure returns (uint length) {
    uint i=0;
    bytes memory string_rep = bytes(str);

    while (i<string_rep.length)
    {
        if (string_rep[i]>>7==0)
            i+=1;
        else if (string_rep[i]>>5==bytes1(uint8(0x6)))
            i+=2;
        else if (string_rep[i]>>4==bytes1(uint8(0xE)))
            i+=3;
        else if (string_rep[i]>>3==0x1E)
            i+=4;
        else
            //For safety
            i+=1;

        length++;
        }
}

function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
}

function bytessubstring(bytes memory str, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return bytes(result);
}


//TODO: test separately on remix
function reverse(string[] memory str) internal pure returns (string[] memory) {
    string memory s;
    for (uint256 i = 0; i < str.length/2; i++) {
        s = str[i];
        str[i] = str[str.length - i - 1];
        str[str.length - i - 1] = s;
    }
    return str;
}

function hmacsha256(bytes memory key, bytes memory message) internal pure returns (bytes32) {
    bytes32 keyl;
    bytes32 keyr;
    uint i;
    if (key.length > 64) {
        keyl = sha256(key);
    } else {
        // for (i = 0; i < key.length && i < 32; i++)
        //     keyl |= bytes32(uint(key[i]) * 2 ** (8 * (31 - i)));
        // for (i = 32; i < key.length && i < 64; i++)
        //     keyr |= bytes32(uint(key[i]) * 2 ** (8 * (63 - i)));
        for (i = 0; i < key.length && i < 32; i++)
            keyl |= bytes32(uint8(key[i]) * 2 ** (8 * (31 - i)));
        for (i = 32; i < key.length && i < 64; i++)
            keyr |= bytes32(uint8(key[i]) * 2 ** (8 * (63 - i)));
    }
    bytes32 threesix = 0x3636363636363636363636363636363636363636363636363636363636363636;
    bytes32 fivec = 0x5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c;
    return sha256(abi.encodePacked(fivec ^ keyl, fivec ^ keyr, sha256(abi.encodePacked(threesix ^ keyl, threesix ^ keyr, message))));
}

// Convert an hexadecimal character to their value
function fromHexChar(uint8 c) public pure returns (uint8) {
    if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
        return c - uint8(bytes1('0'));
    }
    if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
        return 10 + c - uint8(bytes1('a'));
    }
    if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
        return 10 + c - uint8(bytes1('A'));
    }
}

// Convert an hexadecimal string to raw bytes
function fromHex(string memory s) public pure returns (bytes memory) {
    bytes memory ss = bytes(s);
    require(ss.length%2 == 0); // length must be even
    bytes memory r = new bytes(ss.length/2);
    for (uint i=0; i<ss.length/2; ++i) {
        r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                    fromHexChar(uint8(ss[2*i+1])));
    }
    return r;
}
// contract C {
//     bytes s = "abcdefgh";
//     function f(bytes calldata c, bytes memory m) public view returns (bytes16, bytes3) {
//         require(c.length == 16, "");
//         bytes16 b = bytes16(m);  // if length of m is greater than 16, truncation will happen
//         b = bytes16(s);  // padded on the right, so result is "abcdefgh\0\0\0\0\0\0\0\0"
//         bytes3 b1 = bytes3(s); // truncated, b1 equals to "abc"
//         b = bytes16(c[:8]);  // also padded with zeros
//         return (b, b1);
//     }
// }

function toBytes32(bytes memory input) internal view returns (bytes32) {
    require(input.length <= 32, "invalid input size");
    bytes32 b = bytes32(input);
    return b;
}

//todo: test
function rpartitionAll(uint256 n, string memory hash) internal pure returns (string[] memory){
    uint256 length = utfStringLength(hash)/n; //we can do this in 0.8 since safemath is default
    if (utfStringLength(hash) %n!=0)
        length++;
    
    string[] memory hashArr;
    uint256 j = 0;
    for (uint i = utfStringLength(hash)-1; i >= 0; i-=n) {
        if (i>n-1){
                hashArr[j] = substring(hash, i+1-n, i+1);
            } else {
                hashArr[j] = substring(hash, 0, i+1);
            }
            j++;
    }
    hashArr = reverse(hashArr);
    return hashArr;
}

function crashPoint(bytes memory hash, bytes memory salt) public view returns (uint256){
    bytes32 hmacSha256 = hmacsha256(hash, salt); //terrible confusing variable name
    uint256 e = 2 ** 52;
    bytes memory _h = bytessubstring(abi.encodePacked(hmacSha256), 0, 13);
    bytes32 _h32 = toBytes32(_h);
    uint256 h = uint256(_h32);
    if (uint256(toBytes32(hash)) % 20 == 0){ //todo fix cast
        return 1e18;
    }
    else {
        //18 place multiplier here 
        // return (((100 * e - h) / (e-h))
        return 1e18 * ((100 * e - h) / (e-h));
    }
}

}