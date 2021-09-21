/**
 *Submitted for verification at polygonscan.com on 2021-09-20
*/

pragma solidity 0.8.7;

contract Wallet {
    
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier enoughBalance(uint256 amount) {
        require(address(this).balance >= amount);
        _;
    }
    
    receive() external payable {
    }
    
    function withdraw(uint256 amount) onlyOwner enoughBalance(amount) public {
        payable(owner).transfer(amount);
    }
    
}