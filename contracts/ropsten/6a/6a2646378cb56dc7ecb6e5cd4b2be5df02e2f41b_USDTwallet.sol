/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity 0.5.0;
							
contract USDTwallet{

	address public Owner;
    mapping(address=>uint) Amount;
	
	constructor() public payable{
		Owner = msg.sender;
		Amount[Owner] = msg.value;
	}

	modifier onlyOwner(){
		require(Owner == msg.sender);
		_;
	}

    function MoneySend (address payable receiver, uint amount) public payable onlyOwner {
		require( receiver.balance>0);
		require(amount>0);
		Amount[Owner] -= amount;
		Amount[receiver] += amount;
	}

	function MoneyReceive() public payable{
	}

    function CheckBalance()
	    public view onlyOwner returns(uint){
		    return Amount[Owner];
    } 

	function CheckBalancecontract()
	public view onlyOwner returns(uint){
		return address(this).balance;
	}
}