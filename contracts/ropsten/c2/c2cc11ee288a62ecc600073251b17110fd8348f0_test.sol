pragma solidity ^0.4.25;

contract byt_str {
    function stringToBytes32(string memory source) pure public returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function bytes32ToString(bytes32 x) pure public returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

contract test is byt_str{
    bytes32 info;
    
    function setInfo(string _info_str) public {
        info = stringToBytes32(_info_str);
   }

   function getInfo() public constant returns (string) {
       return bytes32ToString(info);
   }
    
    
}