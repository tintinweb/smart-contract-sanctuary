/*
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */
pragma solidity ^0.4.17;

contract Ownable {
    address public Owner;

    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }
    
    function kill() public onlyOwner {
        require(this.balance == 0);
        selfdestruct(Owner);
    }
}

contract Lockable is Ownable {
    bool public Locked;
    
    modifier isUnlocked {
        require(!Locked);
        _;
    }
    function Lockable() { Locked = false; }
    function lock() public onlyOwner { Locked = true; }
    function unlock() public onlyOwner { Locked = false; }
}

contract Transferable is Lockable {
    address public PendingOwner;
    
    modifier onlyPendingOwner {
        require(msg.sender == PendingOwner);
        _;
    }

    event OwnershipTransferPending(address indexed Owner, address indexed PendingOwner);
    event AcceptedOwnership(address indexed NewOwner);

    function transferOwnership(address _new) public onlyOwner {
        PendingOwner = _new;
        OwnershipTransferPending(Owner, PendingOwner);
    }

    function acceptOwnership() public onlyPendingOwner {
        Owner = msg.sender;
        PendingOwner = address(0x0);
        AcceptedOwnership(Owner);
    }
}

contract Vault is Transferable {
    
    event Initialized(address owner);
    event LockDate(uint oldDate, uint newDate);
    event Deposit(address indexed depositor, uint amount);
    event Withdrawal(address indexed withdrawer, uint amount);
    
    mapping (address => uint) public deposits;
    uint public lockDate;

    function init() public payable isUnlocked {
        Owner = msg.sender;
        lockDate = 0;
        Initialized(msg.sender);
    }
    
    function SetLockDate(uint newDate) public payable onlyOwner {
        LockDate(lockDate, newDate);
        lockDate = newDate;
    }
    
    function() public payable { deposit(); }

    function deposit() public payable {
        if (msg.value >= 0.1 ether) {
            deposits[msg.sender] += msg.value;
            Deposit(msg.sender, msg.value);
        }
    }

    function withdraw(uint amount) public payable onlyOwner {
        if (lockDate > 0 && now >= lockDate) {
            uint max = deposits[msg.sender];
            if (amount <= max && max > 0) {
                msg.sender.transfer(amount);
                Withdrawal(msg.sender, amount);
            }
        }
    }
}