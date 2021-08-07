/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity 0.6.4;

contract ZYXBridge {
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit(uint256 amount) external payable {
        require(amount == msg.value, "Not exact");
    }
    
    function withdraw(uint256 amount, address payable to) external onlyOwner {
        to.transfer(amount);
    }
}