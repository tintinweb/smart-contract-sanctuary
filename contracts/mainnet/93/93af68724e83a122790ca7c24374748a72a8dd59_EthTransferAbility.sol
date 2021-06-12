/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.4.24; 

contract EthTransferAbility{

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