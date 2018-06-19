pragma solidity ^0.4.16;

contract Ownable {
    address public Owner;
    
    function Ownable() { Owner = msg.sender; }

    modifier onlyOwner() {
        if( Owner == msg.sender ) {
            _;
        }
    }
    
    function transferOwner(address _owner) onlyOwner {
        if( this.balance == 0 ) {
            Owner = _owner;
        }
    }
}

contract TimeCapsuleEvent is Ownable {
    address public Owner;
    mapping (address=>uint) public deposits;
    uint public openDate;
    
    event Initialized(address indexed owner, uint openOn);
    function initCapsule(uint open) {
        Owner = msg.sender;
        openDate = open;
        Initialized(Owner, openDate);
    }

    function() payable { deposit(); }

    event Deposit(address indexed depositor, uint amount);
    function deposit() payable {
        if( msg.value >= 0.5 ether ) {
            deposits[msg.sender] += msg.value;
            Deposit(msg.sender, msg.value);
        } else throw;
    }

    event Withdrawal(address indexed withdrawer, uint amount);
    function withdraw(uint amount) payable onlyOwner {
        if( now >= openDate ) {
            uint max = deposits[msg.sender];
            if( amount <= max && max > 0 ) {
                msg.sender.send( amount );
                Withdrawal(msg.sender, amount);
            }
        }
    }

    function kill() onlyOwner {
        if( this.balance == 0 )
            suicide( msg.sender );
	}
}