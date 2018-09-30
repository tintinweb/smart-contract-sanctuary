pragma solidity ^0.4.8;

contract Bank {
    
    //mapping to save balances of users
	mapping (address => uint) public balances;

    //deposit payable function to let users
    //deposit the amount they wish to.
	function deposit() payable public {
    	balances[msg.sender] = msg.value;
	}
	//

    //withdrawAll function lets a user to withdraw
    //the amount that he deposited.
	function withdrawAll() public {
        uint amount = balances[msg.sender];
    	require(msg.sender.call.value(amount)());
    	balances[msg.sender] = 0;
    }
    
    //contractBalance function to check the smart contract 
    //total balance.
	function contractBalance() public view returns(uint) {
    	return address(this).balance;
	}

}