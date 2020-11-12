pragma solidity ^0.4.16;

contract owned {
	address public owner;


	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		owner = newOwner;
	}
}

interface tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)
	external;
}

contract TokenERC20 {
	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals = 18; //iap: change this to required value
	//18 decimals is the strongly suggested default, avoid changing it
	uint256 public totalSupply;

	//This creates an array with all balances
	mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

	//This generates a public event on the blockchain that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed _owner, address indexed _spender, uint256 value);

	//This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);

	//Contructor function
	//Initiates contract with initial supply tokens to the creator of the contract

	constructor(uint256 initialSupply, string tokenName, string tokenSymbol)
	public {
		totalSupply = initialSupply * 10 ** uint256(decimals); //update total supply with the deciml amount
		balanceOf[msg.sender] = totalSupply;
		//Give the creator all initial tokens
		name = tokenName;
		//Set the name for display purpose
		symbol = tokenSymbol;
		//Set the symbol for display purpose

	}

	//Internal transfer, can only be called by this contract
	function _transfer(address _from, address _to, uint _value) internal{
		//Prevent transfer to 0x0 address. User burn() instead 
		//iap: whats this?

		require(_to != 0x0);
		//Check if the sender has enough
		require(balanceOf[_from] >= _value);

		//Check for overflows
		require(balanceOf[_to] + _value > balanceOf[_to]);
		
		//Save this for an assertion in the future
		uint previousBalances = balanceOf[_from] + balanceOf[_to];

		//Subtract from the sender
		balanceOf[_from] -= _value;

		//Add the same to the recipient
		balanceOf[_to] += _value;

		emit Transfer(_from, _to, _value);

		//Asserts ae used to use static analysis to find bugs in your code. They should never fail
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	/**
		* Transfer tokens
		* Send '_value' tokens to '_to' from your account
		* @param _to The address of the recipient
		* @param _value the amount to be sent
		*/
	function transfer(address _to, uint256 _value) public returns (bool success){
		_transfer(msg.sender, _to, _value);
		return true;
	}

	/**
		* Transfer tokens from other address
		* 
		* Send '_value' tokens to '_to' on behalf of '_from'
		* @param _from The address of the sender
		* @param _to The address of the recipient
		* @param _value The amount to be sent
		*/
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
		
		//Check allowance
		require(_value <= allowance[_from][msg.sender]);
		
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;

	}

	/**
		* Set allowance for other address
		* Allows '_spender' to spend no more than '_value' tokens on your behalf
		* @param _spender The address authorized to spend
		* @param _value The max amount they can spend
		*/
	function approve(address _spender, uint256 _value) public returns(bool success){
		allowance[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	/**
		* Set allowance for other address and verify
		* Allows '_spender' to spend no more than '_value' tokens on your behalf, and then ping the contract about it
		* @param _spender The address authorized to spend
		* @param _value The max amount they can spend
		* @param _extraData some extra information to send to the approved contract
		*/
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success){
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)){
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	/**
		* Destroy toekns //iap: Why?
		* Remove '_value' tokens from the system irreversibly
		* @param _value the amount of money to burn
		*/
	function burn(uint256 _value) public returns (bool success){
		
		//Check if the sender has enough
		require(balanceOf[msg.sender] >= _value);

		//Subtract from the sender
		balanceOf[msg.sender] -= _value;

		//Update total supply
		totalSupply -= _value;

		emit Burn(msg.sender, _value);

		return true;

	}

	/**
		* Destroys tokens from other account
		* Remove '_value' tokens from the system irreversibly on behalf of '_from'
		* @param _from the address of the sender
		* @param _value The amount of money to burn
		*
		*/
	function burnFrom(address _from, uint256 _value) public returns(bool success){

		//Check if the targeted balance is enough
		require(balanceOf[_from] >= _value);

		//Check allowance
        require(_value <= allowance[_from][msg.sender]);

        //Subtract from the targeted balance
        balanceOf[_from] -= _value;
		
        //Subtract from the sender's allowance
		allowance[_from][msg.sender] -= _value;

        //Update totalSupply
        totalSupply -= _value;

        emit Burn(_from, _value);
        return true;
	}
}

//The Contract
contract Mudrika is owned, TokenERC20{

	uint256 public sellPrice;
	uint256 public buyPrice;

	mapping(address => bool) public frozenAccount;

	//This generates a public event on the blockchain that wull notify clients
	event FrozenFunds(address target, bool frozen);

	//Initializes contract with initial supply tokens to the creator of the contract
	constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

	//Internal transfer, can only be called by this contract
	function _transfer(address _from, address _to, uint _value) internal {

		//Prevent transfer to 0x0 address. User burn() instead
		require(_to != 0x0);

		//Check if sender has enough
		require(balanceOf[_from] >= _value);

		//Check for overflows
		require(balanceOf[_to] + _value >= balanceOf[_to]);

		//Check if sender is frozen
		require(!frozenAccount[_from]);

		//Check if recepient is frozen
		require(!frozenAccount[_to]);

		//Subtract from the sender
		balanceOf[_from] -= _value;

		//Add value to the recipient
		balanceOf[_to] += _value;

		emit Transfer(_from, _to, _value);
	}

	/** 
		* @notice Create 'mintedAmount' tokens and send it to 'target'
		* @param target Address to receive the tokens
		* @param mintedAmount The amount of tokens it will receive
		* 
		*/
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}

	/**
		* @notice 'freeze? Prevent Allow 'target' from sending and receiving tokens
		* @param target address to be frozen
		* @param freeze it or not
		*/
	function freezeAccount(address target, bool freeze) onlyOwner public {
		frozenAccount[target] = freeze;

		emit FrozenFunds(target, freeze);
	}

	/**
		* @notice Allow users to buy tokens for 'newBuyPrice' eth and sell tokens for 'newSellPrice' eth
		* @param newSellPrice Price the users can sell to the contract
		* @param newBuyPrice Price the users can buy from the contract
		*
		*/
	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;

	}

	/**
		* @notice Buy tokens from the contract by sending ether
		*/
	function buy() payable public {

		//calculates the amount
		uint amount = msg.value / buyPrice;

		//makes the transfer
		_transfer(this, msg.sender, amount);

	}

	/**
		* @notice Sell 'amount' tokens to contract
		* @param amount Amount of tokens to be sold
		* 
		*/
	function sell(uint256 amount) public {

		address myAddress = this;

		//check if the contract has enough ether to buy
		require(myAddress.balance >= amount * sellPrice);

		//make the transfer
		_transfer(msg.sender, this, amount);

		//send ether to the seller. Its important to do this last to avoid recursion attacks.
		msg.sender.transfer(amount * sellPrice);

	} 

}