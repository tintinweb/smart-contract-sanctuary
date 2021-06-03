/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.6.3;

contract CodeBkk{
    
    uint256 total;
    event Deposit(uint256 money);
    event Withdraw(uint256 money);
    
    
    constructor () public {
        total = 0;
    }
    
    function deposit(uint256 money) public {
        require(money > 0, "Not enough money");
        
        total += money;
        emit Deposit(money);
    }
    
    function withdraw(uint256 money) public {
        require(money > 0, "Not enough money");
        
        total -= money;
        emit Withdraw(money);
    }
    
    function balance() public view returns(uint256) {
        return total;
    }
    
}