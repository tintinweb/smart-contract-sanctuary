/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.4.22;

contract owned {
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);
    
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}

contract Faucet is mortal {
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 0.1 ether);
        require(address(this).balance >= withdraw_amount, "Insufficient balance in faucet for withdrawal request");
        
        msg.sender.transfer (withdraw_amount);
        emit Withdrawal(msg.sender, withdraw_amount);
    }
    
    function () public payable {
        emit Deposit(msg.sender, msg.value);
    }
}