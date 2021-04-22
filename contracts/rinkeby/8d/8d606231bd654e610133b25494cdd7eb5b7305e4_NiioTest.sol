/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: UNLICENSED

contract NiioTest {
    
    address private owner;
    uint private niioShare;
    
    constructor (uint _niioShare) {
        owner = msg.sender;
        require(_niioShare < 100);
        niioShare = _niioShare;
    }
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier positiveValue() {
        require(msg.value > 0, "Amount must be positive");
        _;
    }
    
    //receive function
    receive() external payable {}

    
    function setNiioShare(uint updatedValue) public
    onlyOwner {
        niioShare = updatedValue;
    }
    
    function pay(address payable to) public payable
    positiveValue {
        uint toNiio = msg.value / 100 * niioShare;
        uint amountToSeller = msg.value - toNiio;
        to.transfer(amountToSeller);
    }
    
    function withdraw(uint amount, address payable to) public
    onlyOwner {
        require(address(this).balance >= amount);
        to.transfer(amount);
    }
    
    function getNiioBalance() public
    view
    returns(uint) {
        return address(this).balance;
    }
}