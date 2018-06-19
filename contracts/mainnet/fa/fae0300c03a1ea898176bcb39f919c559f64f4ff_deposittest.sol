pragma solidity ^0.4.17;

contract owned {
    address public owner;    
    
    function owned() {
        owner=msg.sender;
    }

    modifier onlyowner{
        if (msg.sender!=owner)
            throw;
        _;
    }
}

contract deposittest is owned {
    address public owner;
    mapping (address=>uint) public deposits;
    
    function init() {
        owner=msg.sender;
    }
    
    function() payable {
        deposit();
    }
    
    function deposit() payable {
        if (msg.value >= 100 finney)
            deposits[msg.sender]+=msg.value;
        else
            throw;
    }
    
    function withdraw(uint amount) public onlyowner {
        uint depo = deposits[msg.sender];
        if (amount <= depo && depo>0)
            msg.sender.send(amount);
    }

	function kill() onlyowner {
	    if(this.balance==0) {  
		    selfdestruct(msg.sender);
	    }
	}
}