/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity >=0.7.0 <0.9.0;

contract LongTransaction {
    uint256 public someValue = 0;
    
    function performLongTransaction(uint256 howLong) public{
        for (uint i = 0; i < howLong; i++) {
                someValue += ((howLong / (i + 1)) / howLong) * howLong;
        }
    }
}