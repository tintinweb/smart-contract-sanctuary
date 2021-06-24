/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity >=0.7.0 <0.9.0;

contract HodlBank {
    
    address public owner;
    uint public witdrawTime;
    uint public balance = 0;
    
    constructor() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function deposit(uint256 delay) payable public onlyOwner {
        require(msg.value > 0, "You have to send some ether...");
        balance += msg.value;
        witdrawTime = block.timestamp + delay;
    }
    
    function witdraw() payable public onlyOwner {
        require(balance > 0, "You have no deposit...");
        require(block.timestamp > witdrawTime, "You have to wait..");
        
        uint amount = 1 * (1 wei);
        payable(msg.sender).transfer(amount);
        balance -= amount;
    }
}