/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
	
	function uintToPad2Str(uint _num) public pure returns (string memory _uintAsString) {
        require(_num < 100);
        if (_num == 0) 
            return "00";
        bytes memory bstr = new bytes(2);
        bstr[1] = bytes1(uint8(48 + _num % 10));
        _num /= 10;
        bstr[0] = bytes1(uint8(48 + _num % 10));
        return string(bstr);
    }
    
    function strMatch(string memory _test, string memory _pattern) public pure returns(bool)
    {
        bytes memory pattern = bytes(_pattern);
        bytes memory test = bytes(_test);
        if(pattern.length == test.length)
        {
            for(uint i=0; i<pattern.length; i++)
            {
                if(pattern[i] != "?" && pattern[i] != test[i])
                    return false;
            }
            return true;
        }
        else
            return false;
    }
}