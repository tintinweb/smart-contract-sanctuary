//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract LastWillDemo {

    address payable owner;
    address payable inheritor;

    constructor() {
        owner = payable(msg.sender);
    }

    function setInheritor(address payable _inheritor) public {
        require(msg.sender == owner, "You are not the owner");
        inheritor = _inheritor;
    }
    
    function withdrawMoney() public {
        address payable to = payable(msg.sender);
        require(0 < address(this).balance, "not enough funds.");
        require(msg.sender == owner || msg.sender == inheritor, "You are not the owner nor the inheritor");
        to.transfer(address(this).balance);
    }

    function destroySmartContract() public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(owner);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {
        // placeholder
    }
}