/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity 0.5.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}
							
contract USDT_Wallet{

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
		require( receiver.balance>=0);
		require(amount>=0);
		Amount[Owner] -= amount;
		Amount[receiver] += amount;
	}

	function MoneyReceive() public payable{
	}

	

    function withdrawToken(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
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