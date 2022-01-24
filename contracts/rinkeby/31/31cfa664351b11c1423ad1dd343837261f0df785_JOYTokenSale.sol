/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// File: JOYToken.sol

pragma solidity ^0.5.16;

contract JOYToken {
	string  public name   = "JOY Token";
	string  public symbol = "JOY"; 
	// string  public standard = "JOY Token v1.0";
	uint256 public totalSupply = 250000000000000000000000000; // 250 Million tokens
	uint8 	public decimals = 18;

	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
	);

	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	constructor () public {
		balanceOf[msg.sender] = totalSupply;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	// Delegated Transfer
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	
	function transferFrom(address _from , address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);
		require(allowance[_from][msg.sender] >= _value);
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;	
		allowance[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;
	}
}


// File: JOYCITYTokenSale.sol

pragma solidity ^0.5.16;


contract JOYTokenSale {
	address payable admin;
	JOYToken public tokenContract;
	uint256   public tokenPrice;
	uint256   public tokensSold;

	event Sell(address _buyer, uint256 _amount);

	constructor(JOYToken _tokenContract, uint256 _tokenPrice) public {
		admin = msg.sender;  				// Assign an admin
		tokenContract = _tokenContract; 	// Token Contract
		tokenPrice = _tokenPrice; 			// Token Price

	}
	
	function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

	function buyTokens(uint256 _numberOfTokens) public payable {
		// Require that value is equal to tokens
		require(msg.value == multiply(_numberOfTokens, tokenPrice));
		uint256 _scaledAmount = multiply(_numberOfTokens,
            uint256(10) ** tokenContract.decimals());
		// Require that the contract has enough tokens
		require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);   // "this" is a reference to the smart contract itself
		// Require that a transfer is successful
		require(tokenContract.transfer(msg.sender, _scaledAmount));
		// Keep track of tokens Sold
		tokensSold += _numberOfTokens;
		// Trigger Sell Event
		emit Sell(msg.sender, _scaledAmount);
	}

	// Ending Token JOYTokenSale

	function endSale() public {
		// Require only admin can end sale
		require(msg.sender == admin);
		// Transfer remaining JOYTokens to admin
		require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
		
		// Destroy contract
		selfdestruct(admin);
	}
}