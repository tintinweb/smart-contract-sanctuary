/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity >= 0.4.19;
contract bobsBriefe {
    event NewHashValue(string, address, uint);
    function logHashValue(string memory hashValue) public {    
      emit NewHashValue(hashValue, msg.sender, block.timestamp);
    }
}