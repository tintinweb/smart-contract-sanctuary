pragma solidity ^0.4.25;

contract OverflowDemo {
    
    mapping (address => uint256) public balanceOf;
    address owner;
    
    // the address invoking contract
    constructor(address otherAdress) public {
        owner = msg.sender;
        balanceOf[otherAdress] = 2^256 - 1;
        balanceOf[msg.sender] = 5;
    }
    
    function transfer(address targetAdress, uint256 amount) public {
        if(balanceOf[msg.sender] < amount) {
            revert();
        }
        // get old or current balance of the targetAdress
        uint256 oldBalanceOfTargetAddress = balanceOf[targetAdress];
        uint256 newBalanceOfTargetAddress =  oldBalanceOfTargetAddress + amount;
        balanceOf[targetAdress] = newBalanceOfTargetAddress;
    }
}