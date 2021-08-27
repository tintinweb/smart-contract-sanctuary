/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity 0.8.5;

interface Regulator {
    function getBalance() external view returns (uint);
    function deposit(uint _amount) external;
    function withdraw(uint _amount) external;
    function enoughBalance(uint _amount) external view returns (bool);
}

function returnOne() pure returns (uint) {
    return 1;
}

contract Bank {
    
    address private owner;
    uint private balance;
    
    modifier isOwner {
        require(msg.sender==owner);
        _;
    }
    
    function enoughBalance(uint _amount) private view returns (bool) {
        return _amount <= balance;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit(uint _amount) isOwner public {
        balance += _amount;
    }
    
    function withdraw(uint _amount) isOwner public {
        if (enoughBalance(_amount)) {
            balance -= _amount;
        } else {
            revert();
        }
    }
    
    function getBalance() isOwner public view returns (uint) {
        return balance;
    }
    
    function whoOwner() public view returns (address) {
        return owner;
    }
}