/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

pragma solidity ^0.4.24; 

contract CrowdSale{

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public {
        require(msg.sender==owner);
        to.transfer(amount);
    }

    function () public payable {
        revert(); 
    }

}