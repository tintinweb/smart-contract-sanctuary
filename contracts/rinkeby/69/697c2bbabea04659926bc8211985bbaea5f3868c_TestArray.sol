/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

contract TestArray {
    string[] public names;
    
    function setNames(string[5] memory proposalNames) public {
        for(uint i = 0; i < proposalNames.length; i++) {
             names.push(proposalNames[i]);
        }
    }
}