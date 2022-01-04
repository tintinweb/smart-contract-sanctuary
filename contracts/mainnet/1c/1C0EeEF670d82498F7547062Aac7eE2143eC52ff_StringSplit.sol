// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "Strings.sol";
pragma experimental ABIEncoderV2;

contract StringSplit {                                                            
    using Strings for string;
    using Strings for Strings.slice;

    function splitStringByDeliminator(string memory input, string memory deliminator) public pure returns(string[] memory) {                                               
        Strings.slice memory stringSlice = input.toSlice();                
        Strings.slice memory deliminatorSlice = deliminator.toSlice();                            
        string[] memory parts = new string[](stringSlice.count(deliminatorSlice) + 1);                 
        for (uint i = 0; i < parts.length; i++) {                              
           parts[i] = stringSlice.split(deliminatorSlice).toString();                               
        }
        return parts;
    }
}