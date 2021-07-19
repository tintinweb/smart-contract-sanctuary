/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.5.10;

contract generateNumber {
    uint public one;
    uint public two;
    uint public three;
    uint public four;
    uint public five;
    uint public six;
    
    function random() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        one = randomnumber;
        return randomnumber;
    }
}