/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
    
    function Concatenate(string memory a, string memory b) public pure returns (string memory concatenatedString) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);
        string memory concatenatedAB = new string(bytesA.length + bytesB.length);
        bytes memory bytesAB = bytes(concatenatedAB);
        uint concatendatedIndex = 0;
        uint index = 0;
        for (index = 0; index < bytesA.length; index++) {
          bytesAB[concatendatedIndex++] = bytesA[index];
        }
        for (index = 0; index < bytesB.length; index++) {
          bytesAB[concatendatedIndex++] = bytesB[index];
        }
          
        return string(bytesAB);
    }

    function UintToString(uint value) public pure returns (string memory uintAsString) {
        uint tempValue = value;
        
        if (tempValue == 0) {
          return "0";
        }
        uint j = tempValue;
        uint length;
        while (j != 0) {
          length++;
          j /= 10;
        }
        bytes memory byteString = new bytes(length);
        uint index = length - 1;
        while (tempValue != 0) {
          byteString[index--] = byte(uint8(48 + tempValue % 10));
          tempValue /= 10;
        }
        return string(byteString);
    }
}