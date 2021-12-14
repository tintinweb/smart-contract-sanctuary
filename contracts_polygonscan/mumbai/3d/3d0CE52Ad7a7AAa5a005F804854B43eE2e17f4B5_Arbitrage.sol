/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Arbitrage {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

   // modifier to check if caller is owner
    modifier isOwner() {
     require(msg.sender == owner, "Caller is not owner");
        _;
    }

   constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

   function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }


    function receiveMoney() public payable {
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    
    function withdrawMoney(uint amount) public isOwner{
        require(getBalance() > amount, "Balance too low");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }

}