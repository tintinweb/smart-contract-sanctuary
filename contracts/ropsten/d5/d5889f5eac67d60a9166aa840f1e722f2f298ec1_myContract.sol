/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.4.24; 

contract myContract{

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public {
        require(msg.sender==owner);
        to.transfer(amount);
    }

    function () public payable {}
}