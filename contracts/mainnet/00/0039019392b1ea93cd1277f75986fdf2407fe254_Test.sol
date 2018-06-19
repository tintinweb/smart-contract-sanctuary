pragma solidity ^ 0.4 .2;
contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newAdmin) onlyOwner public {
		owner = newAdmin;
	}
}

contract tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract token {
	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;

	// This creates an array with all balances
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	// This generates a public event on the blockchain that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);

	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);

	function token(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) public {
		totalSupply = initialSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount
		balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
		name = tokenName; // Set the name for display purposes
		symbol = tokenSymbol; // Set the symbol for display purposes
	}

	//Transfer tokens
	function transfer(address _to, uint256 _value) {
		if (balanceOf[msg.sender] < _value) throw; // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		balanceOf[msg.sender] -= _value; // Subtract from the sender
		balanceOf[_to] += _value; // Add the same to the recipient
		Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
	}

	//A contract attempts to get tokens
	function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		if (balanceOf[_from] < _value) throw; // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		if (_value > allowance[_from][msg.sender]) throw; // Check allowance
		balanceOf[_from] -= _value; // Subtract from the sender
		balanceOf[_to] += _value; // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	//Set allowance for another address
	function approve(address _spender, uint256 _value) public
	returns(bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}

	//Set allowance for another address and call a function
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	//Destroy tokens
	function burn(uint256 _value) public returns(bool success) {
		require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
		balanceOf[msg.sender] -= _value; // Subtract from the sender
		totalSupply -= _value; // Updates totalSupply
		Burn(msg.sender, _value);
		return true;
	}

	//Destroy tokens from another account
	function burnFrom(address _from, uint256 _value) public returns(bool success) {
		require(balanceOf[_from] >= _value); // Check if the targeted balance is enough
		require(_value <= allowance[_from][msg.sender]); // Check allowance
		balanceOf[_from] -= _value; // Subtract from the targeted balance
		allowance[_from][msg.sender] -= _value; // Subtract from the sender&#39;s allowance
		totalSupply -= _value; // Update totalSupply
		Burn(_from, _value);
		return true;
	}
}


contract Test is owned, token {

	uint256 public sellPrice;
	uint256 public buyPrice;
	bool public deprecated;
	address public currentVersion;
	mapping(address => bool) public frozenAccount;

	/* This generates a public event on the blockchain that will notify clients */
	event FrozenFunds(address target, bool frozen);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function Test(
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
	) token(initialSupply, tokenName, tokenSymbol) {}

	function update(address newAddress, bool depr) onlyOwner {
		if (msg.sender != owner) throw;
		currentVersion = newAddress;
		deprecated = depr;
	}

	function checkForUpdates() private {
		if (deprecated) {
			if (!currentVersion.delegatecall(msg.data)) throw;
		}
	}

	function withdrawETH(uint256 amount) onlyOwner {
		msg.sender.send(amount);
	}

	function airdrop(address[] recipients, uint256 value) public onlyOwner {
		for (uint256 i = 0; i < recipients.length; i++) {
			transfer(recipients[i], value);
		}
	}

	/* Send coins */
	function transfer(address _to, uint256 _value) {
		checkForUpdates();
		if (balanceOf[msg.sender] < _value) throw; // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		if (frozenAccount[msg.sender]) throw; // Check if frozen
		balanceOf[msg.sender] -= _value; // Subtract from the sender
		balanceOf[_to] += _value; // Add the same to the recipient
		Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
	}


	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		checkForUpdates();
		if (frozenAccount[_from]) throw; // Check if frozen            
		if (balanceOf[_from] < _value) throw; // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		if (_value > allowance[_from][msg.sender]) throw; // Check allowance
		balanceOf[_from] -= _value; // Subtract from the sender
		balanceOf[_to] += _value; // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

    function merge(address target) onlyOwner {
        checkForUpdates();
        token old = token(address(0x7F2176cEB16dcb648dc924eff617c3dC2BEfd30d));
        balanceOf[target] = old.balanceOf(target) / 10;
    }

	function mintToken(address target, uint256 mintedAmount) onlyOwner {
		checkForUpdates();
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
	}

	function freezeAccount(address target, bool freeze) onlyOwner {
		checkForUpdates();
		frozenAccount[target] = freeze;
		FrozenFunds(target, freeze);
	}

	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
		checkForUpdates();
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}

	function buy() payable {
		checkForUpdates();
		if (buyPrice == 0) throw;
		uint amount = msg.value / buyPrice; // calculates the amount
		if (balanceOf[this] < amount) throw; // checks if it has enough to sell
		balanceOf[msg.sender] += amount; // adds the amount to buyer&#39;s balance
		balanceOf[this] -= amount; // subtracts amount from seller&#39;s balance
		Transfer(this, msg.sender, amount); // execute an event reflecting the change
	}

	function sell(uint256 amount) {
		checkForUpdates();
		if (sellPrice == 0) throw;
		if (balanceOf[msg.sender] < amount) throw; // checks if the sender has enough to sell
		balanceOf[this] += amount; // adds the amount to owner&#39;s balance
		balanceOf[msg.sender] -= amount; // subtracts the amount from seller&#39;s balance
		if (!msg.sender.send(amount * sellPrice)) { // sends ether to the seller. It&#39;s important
			throw; // to do this last to avoid recursion attacks
		} else {
			Transfer(msg.sender, this, amount); // executes an event reflecting on the change
		}
	}
}