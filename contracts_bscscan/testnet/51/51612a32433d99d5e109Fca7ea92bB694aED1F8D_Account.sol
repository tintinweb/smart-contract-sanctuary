/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// handled by solidity version 0.8 and onwards 

contract Account {
    uint256 public balance;

    constructor() public {
        balance = 0;
    } 

    function withdraw(uint256 amount) public {
        balance -= amount;
    }

    function deposit(uint256 amount) public {
        balance += amount;
    }
    
}