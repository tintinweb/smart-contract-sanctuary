pragma solidity ^0.4.20;


/******************************************/
/*       OWNABLE CONTRACT STARTS HERE     */
/******************************************/
contract Ownable 
{
	address public owner;

	constructor() public 
	{
		owner = msg.sender;
	}

	modifier onlyOwner 
	{
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public 
	{
		owner = newOwner;
	}
}


interface tokenRecipient
{
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


contract TokenERC20 
{
	string  public name = &quot;HoneyNaps Token&quot;;
	string  public symbol = &quot;NAP&quot;;
	uint256 public totalSupply;
	uint8   public decimals = 6;

	mapping (address => uint256) public balanceOf;
	mapping (address => mapping(address => uint256)) public allowance;	

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Burn(address indexed from, uint256 value);


	constructor(uint256 initSupply, string tokenName, string tokenSymbol) public
	{
		totalSupply	= initSupply * (10 ** uint256(decimals));
		name 		= tokenName;
		symbol		= tokenSymbol;
		balanceOf[this] = totalSupply;
	}

	function _transfer(address _from, address _to, uint256 _amount) internal
	{
		require(_amount > 0, &quot;_amount is zero!!!&quot;);
		require(_to != 0x0, &quot;_to address invalid!!!&quot;);
		require(balanceOf[_from] >= _amount, &quot;_from&#39;s tokens are smaller than _amount!!!&quot;);
		require(balanceOf[_to] + _amount >= balanceOf[_to], &quot;_to&#39;s account overflow!!!&quot;);
		
		uint prevBalances = balanceOf[_from] + balanceOf[_to];
		balanceOf[_from] -= _amount;
		balanceOf[_to]   += _amount;
		emit Transfer(_from, _to, _amount);
		assert(balanceOf[_from] + balanceOf[_to] == prevBalances);
	}

	function transfer(address _to, uint256 _amount) public
	{
		_transfer(msg.sender, _to, _amount);
	}

	function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
	{
		require(_amount <= allowance[_from][msg.sender]);

		allowance[_from][msg.sender] -= _amount;
		_transfer(_from, _to, _amount);
		return true;
	}

	function approve(address _spender, uint256 _amount) public returns (bool)
	{
		allowance[msg.sender][_spender] = _amount;
		return true;
	}

	function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool)
	{
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _amount))
		{
			spender.receiveApproval(msg.sender, _amount, this, _extraData);
			return true;
		}
	}

	function burn(uint256 _amount) public returns (bool)
	{
		require(balanceOf[msg.sender] >= _amount);

		balanceOf[msg.sender] -= _amount;
		totalSupply -= _amount;
		emit Burn(msg.sender, _amount);
		return true;
	}

	function burnFrom(address _from, uint256 _amount) public returns (bool)
	{
		require(balanceOf[_from] >= _amount);
		require(_amount <= allowance[_from][msg.sender]);

		balanceOf[_from] -= _amount;
		allowance[_from][msg.sender] -= _amount;
		totalSupply -= _amount;
		emit Burn(_from, _amount);
		return true;
	}
}


/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/
contract TokenNAP is Ownable, TokenERC20 
{
	uint256 public sellPrice = 1;
	uint256 public buyPrice  = 1;

	mapping (address => bool) public frozenAccount;

	/* This generates a public event on the blockchain that will notify clients */
	event FrozenFunds(address target, bool frozen);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	constructor(uint256 initialSupply, string tokenName, string tokenSymbol) 
			 TokenERC20(initialSupply, tokenName, tokenSymbol) public
	{
	}

	/* Internal transfer, only can be called by this contract */
	function _transfer(address _from, address _to, uint _amount) internal 
	{
		require(_amount > 0, &quot;_amount is zero!!!&quot;);
		// Prevent transfer to 0x0 address. Use burn() instead
		require(_to != 0x0, &quot;_to address invalid!!!&quot;);
		// Check if the sender has enough
		require(balanceOf[_from] >= _amount, &quot;_from&#39;s tokens are smaller than _amount!!!&quot;);
		// Check for overflows
		require(balanceOf[_to] + _amount >= balanceOf[_to], &quot;_to&#39;s account overflow!!!&quot;);
		
		// Check if sender is frozen
		require(!frozenAccount[_from], &quot;_from&#39;s account is frozen!!!&quot;);
		// Check if recipient is frozen
		require(!frozenAccount[_to], &quot;_to&#39;s account is frozen!!!&quot;);

		balanceOf[_from] -= _amount;	// Subtract from the sender
		balanceOf[_to]   += _amount;	// Add the same to the recipient
		emit Transfer(_from, _to, _amount);
	}

	/// @notice Create `mintedAmount` tokens and send it to `target`
	/// @param target Address to receive the tokens
	/// @param mintedAmount the amount of tokens it will receive
	function mintToken(address target, uint256 mintedAmount) onlyOwner public 
	{
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}

	/// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
	/// @param target Address to be frozen
	/// @param freeze either to freeze it or not
	function freezeAccount(address target, bool freeze) onlyOwner public 
	{
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	/// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
	/// @param newSellPrice Price the users can sell to the contract
	/// @param newBuyPrice Price users can buy from the contract
	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public 
	{
		sellPrice = newSellPrice;
		buyPrice  = newBuyPrice;
	}

	
	function() payable public 
	{
		buy();
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// 
	/// @notice Buy tokens from contract by sending ether
	function buy() payable public 
	{
		uint units = 10 ** (18 - uint256(decimals));

		// calculates the amount
		uint amount = msg.value / units / buyPrice;

		// makes the transfers
		_transfer(this, msg.sender, amount);
	}

	/// @notice Sell `amount` tokens to contract
	/// @param amount amount of tokens to be sold
	function sell(uint256 amount) public 
	{
		uint units = 10 ** (18 - uint256(decimals));

		// checks if the contract has enough ether to buy
		uint weis = amount * units * sellPrice;
		require(address(this).balance >= weis, &quot;balance of this is less than amount&quot;);

		// makes the transfers
		_transfer(msg.sender, this, amount);

		// sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
		msg.sender.transfer(weis);
	}
	///////////////////////////////////////////////////////////////////////////////////////////////

}