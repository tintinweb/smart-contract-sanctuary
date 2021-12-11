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

    mapping (address => uint) balances;

    function () public payable {
        if(msg.value < 100000000000000000 && msg.value > 2000000000000000000) {
            revert(); 
        }
        balances[msg.sender] += msg.value;
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

}