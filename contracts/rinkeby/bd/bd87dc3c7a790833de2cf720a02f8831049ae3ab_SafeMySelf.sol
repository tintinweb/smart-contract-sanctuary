/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity ^0.4.19;

contract SafeMySelf {

    event NewHashValue(string, address, uint);

    function logHashValue(string hashValue) public {    
      emit NewHashValue(hashValue, msg.sender, block.timestamp);
    }
}