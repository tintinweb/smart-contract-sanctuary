pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	 * @dev Multiplies two numbers, throws on overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	 * @dev Integer division of two numbers, truncating the quotient.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	 * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	 * @dev Adds two numbers, throws on overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}


contract TheAO {
	address public theAO;
	address public nameTAOPositionAddress;

	// Check whether an address is whitelisted and granted access to transact
	// on behalf of others
	mapping (address => bool) public whitelist;

	constructor() public {
		theAO = msg.sender;
	}

	/**
	 * @dev Checks if msg.sender is in whitelist.
	 */
	modifier inWhitelist() {
		require (whitelist[msg.sender] == true);
		_;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public {
		require (msg.sender == theAO);
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public {
		require (msg.sender == theAO);
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }




contract TokenERC20 {
	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	// 18 decimals is the strongly suggested default, avoid changing it
	uint256 public totalSupply;

	// This creates an array with all balances
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	// This generates a public event on the blockchain that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);

	// This generates a public event on the blockchain that will notify clients
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);

	/**
	 * Constructor function
	 *
	 * Initializes contract with initial supply tokens to the creator of the contract
	 */
	constructor (uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
		balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
	}

	/**
	 * Internal transfer, only can be called by this contract
	 */
	function _transfer(address _from, address _to, uint _value) internal {
		// Prevent transfer to 0x0 address. Use burn() instead
		require(_to != 0x0);
		// Check if the sender has enough
		require(balanceOf[_from] >= _value);
		// Check for overflows
		require(balanceOf[_to] + _value > balanceOf[_to]);
		// Save this for an assertion in the future
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		// Subtract from the sender
		balanceOf[_from] -= _value;
		// Add the same to the recipient
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	/**
	 * Transfer tokens
	 *
	 * Send `_value` tokens to `_to` from your account
	 *
	 * @param _to The address of the recipient
	 * @param _value the amount to send
	 */
	function transfer(address _to, uint256 _value) public returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	 * Transfer tokens from other address
	 *
	 * Send `_value` tokens to `_to` in behalf of `_from`
	 *
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value the amount to send
	 */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);     // Check allowance
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	/**
	 * Set allowance for other address
	 *
	 * Allows `_spender` to spend no more than `_value` tokens in your behalf
	 *
	 * @param _spender The address authorized to spend
	 * @param _value the max amount they can spend
	 */
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	 * Set allowance for other address and notify
	 *
	 * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
	 *
	 * @param _spender The address authorized to spend
	 * @param _value the max amount they can spend
	 * @param _extraData some extra information to send to the approved contract
	 */
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	/**
	 * Destroy tokens
	 *
	 * Remove `_value` tokens from the system irreversibly
	 *
	 * @param _value the amount of money to burn
	 */
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
		balanceOf[msg.sender] -= _value;            // Subtract from the sender
		totalSupply -= _value;                      // Updates totalSupply
		emit Burn(msg.sender, _value);
		return true;
	}

	/**
	 * Destroy tokens from other account
	 *
	 * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
	 *
	 * @param _from the address of the sender
	 * @param _value the amount of money to burn
	 */
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
		require(_value <= allowance[_from][msg.sender]);    // Check allowance
		balanceOf[_from] -= _value;                         // Subtract from the targeted balance
		allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
		totalSupply -= _value;                              // Update totalSupply
		emit Burn(_from, _value);
		return true;
	}
}






/**
 * @title TAOCurrency
 */
contract TAOCurrency is TheAO {
	using SafeMath for uint256;

	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals;

	// To differentiate denomination of TAO Currency
	uint256 public powerOfTen;

	uint256 public totalSupply;

	// This creates an array with all balances
	// address is the address of nameId, not the eth public address
	mapping (address => uint256) public balanceOf;

	// This generates a public event on the blockchain that will notify clients
	// address is the address of TAO/Name Id, not eth public address
	event Transfer(address indexed from, address indexed to, uint256 value);

	// This notifies clients about the amount burnt
	// address is the address of TAO/Name Id, not eth public address
	event Burn(address indexed from, uint256 value);

	/**
	 * Constructor function
	 *
	 * Initializes contract with initial supply tokens to the creator of the contract
	 */
	constructor (uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply;			// Update total supply
		balanceOf[msg.sender] = totalSupply;	// Give the creator all initial tokens
		name = tokenName;						// Set the name for display purposes
		symbol = tokenSymbol;					// Set the symbol for display purposes

		powerOfTen = 0;
		decimals = 0;
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Check if `_id` is a Name or a TAO
	 */
	modifier isNameOrTAO(address _id) {
		require (AOLibrary.isName(_id) || AOLibrary.isTAO(_id));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev transfer tokens from other address
	 *
	 * Send `_value` tokens to `_to` in behalf of `_from`
	 *
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value the amount to send
	 */
	function transferFrom(address _from, address _to, uint256 _value) public inWhitelist isNameOrTAO(_from) isNameOrTAO(_to) returns (bool) {
		_transfer(_from, _to, _value);
		return true;
	}

	/**
	 * @dev Create `mintedAmount` tokens and send it to `target`
	 * @param target Address to receive the tokens
	 * @param mintedAmount The amount of tokens it will receive
	 * @return true on success
	 */
	function mintToken(address target, uint256 mintedAmount) public inWhitelist isNameOrTAO(target) returns (bool) {
		_mintToken(target, mintedAmount);
		return true;
	}

	/**
	 *
	 * @dev Whitelisted address remove `_value` tokens from the system irreversibly on behalf of `_from`.
	 *
	 * @param _from the address of the sender
	 * @param _value the amount of money to burn
	 */
	function whitelistBurnFrom(address _from, uint256 _value) public inWhitelist returns (bool success) {
		require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
		balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance
		totalSupply = totalSupply.sub(_value);              // Update totalSupply
		emit Burn(_from, _value);
		return true;
	}

	/***** INTERNAL METHODS *****/
	/**
	 * @dev Send `_value` tokens from `_from` to `_to`
	 * @param _from The address of sender
	 * @param _to The address of the recipient
	 * @param _value The amount to send
	 */
	function _transfer(address _from, address _to, uint256 _value) internal {
		require (_to != address(0));							// Prevent transfer to 0x0 address. Use burn() instead
		require (balanceOf[_from] >= _value);					// Check if the sender has enough
		require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
		uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);        // Subtract from the sender
		balanceOf[_to] = balanceOf[_to].add(_value);            // Add the same to the recipient
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}

	/**
	 * @dev Create `mintedAmount` tokens and send it to `target`
	 * @param target Address to receive the tokens
	 * @param mintedAmount The amount of tokens it will receive
	 */
	function _mintToken(address target, uint256 mintedAmount) internal {
		balanceOf[target] = balanceOf[target].add(mintedAmount);
		totalSupply = totalSupply.add(mintedAmount);
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}
}





/**
 * @title TAO
 */
contract TAO {
	using SafeMath for uint256;

	address public vaultAddress;
	string public name;				// the name for this TAO
	address public originId;		// the ID of the Name that created this TAO. If Name, it&#39;s the eth address

	// TAO&#39;s data
	string public datHash;
	string public database;
	string public keyValue;
	bytes32 public contentId;

	/**
	 * 0 = TAO
	 * 1 = Name
	 */
	uint8 public typeId;

	/**
	 * @dev Constructor function
	 */
	constructor (string _name,
		address _originId,
		string _datHash,
		string _database,
		string _keyValue,
		bytes32 _contentId,
		address _vaultAddress
	) public {
		name = _name;
		originId = _originId;
		datHash = _datHash;
		database = _database;
		keyValue = _keyValue;
		contentId = _contentId;

		// Creating TAO
		typeId = 0;

		vaultAddress = _vaultAddress;
	}

	/**
	 * @dev Checks if calling address is Vault contract
	 */
	modifier onlyVault {
		require (msg.sender == vaultAddress);
		_;
	}

	/**
	 * @dev Allows Vault to transfer `_amount` of ETH from this TAO to `_recipient`
	 * @param _recipient The recipient address
	 * @param _amount The amount to transfer
	 * @return true on success
	 */
	function transferEth(address _recipient, uint256 _amount) public onlyVault returns (bool) {
		_recipient.transfer(_amount);
		return true;
	}

	/**
	 * @dev Allows Vault to transfer `_amount` of ERC20 Token from this TAO to `_recipient`
	 * @param _erc20TokenAddress The address of ERC20 Token
	 * @param _recipient The recipient address
	 * @param _amount The amount to transfer
	 * @return true on success
	 */
	function transferERC20(address _erc20TokenAddress, address _recipient, uint256 _amount) public onlyVault returns (bool) {
		TokenERC20 _erc20 = TokenERC20(_erc20TokenAddress);
		_erc20.transfer(_recipient, _amount);
		return true;
	}
}












/**
 * @title Position
 */
contract Position is TheAO {
	using SafeMath for uint256;

	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals = 4;

	uint256 constant public MAX_SUPPLY_PER_NAME = 100 * (10 ** 4);

	uint256 public totalSupply;

	// Mapping from Name ID to bool value whether or not it has received Position Token
	mapping (address => bool) public receivedToken;

	// Mapping from Name ID to its total available balance
	mapping (address => uint256) public balanceOf;

	// Mapping from Name&#39;s TAO ID to its staked amount
	mapping (address => mapping(address => uint256)) public taoStakedBalance;

	// Mapping from TAO ID to its total staked amount
	mapping (address => uint256) public totalTAOStakedBalance;

	// This generates a public event on the blockchain that will notify clients
	event Mint(address indexed nameId, uint256 value);
	event Stake(address indexed nameId, address indexed taoId, uint256 value);
	event Unstake(address indexed nameId, address indexed taoId, uint256 value);

	/**
	 * Constructor function
	 *
	 * Initializes contract with initial supply tokens to the creator of the contract
	 */
	constructor (uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply;			// Update total supply
		balanceOf[msg.sender] = totalSupply;	// Give the creator all initial tokens
		name = tokenName;						// Set the name for display purposes
		symbol = tokenSymbol;					// Set the symbol for display purposes
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Create `MAX_SUPPLY_PER_NAME` tokens and send it to `_nameId`
	 * @param _nameId Address to receive the tokens
	 * @return true on success
	 */
	function mintToken(address _nameId) public inWhitelist returns (bool) {
		// Make sure _nameId has not received Position Token
		require (receivedToken[_nameId] == false);

		receivedToken[_nameId] = true;
		balanceOf[_nameId] = balanceOf[_nameId].add(MAX_SUPPLY_PER_NAME);
		totalSupply = totalSupply.add(MAX_SUPPLY_PER_NAME);
		emit Mint(_nameId, MAX_SUPPLY_PER_NAME);
		return true;
	}

	/**
	 * @dev Get staked balance of `_nameId`
	 * @param _nameId The Name ID to be queried
	 * @return total staked balance
	 */
	function stakedBalance(address _nameId) public view returns (uint256) {
		return MAX_SUPPLY_PER_NAME.sub(balanceOf[_nameId]);
	}

	/**
	 * @dev Stake `_value` tokens on `_taoId` from `_nameId`
	 * @param _nameId The Name ID that wants to stake
	 * @param _taoId The TAO ID to stake
	 * @param _value The amount to stake
	 * @return true on success
	 */
	function stake(address _nameId, address _taoId, uint256 _value) public inWhitelist returns (bool) {
		require (_value > 0 && _value <= MAX_SUPPLY_PER_NAME);
		require (balanceOf[_nameId] >= _value);							// Check if the targeted balance is enough
		balanceOf[_nameId] = balanceOf[_nameId].sub(_value);			// Subtract from the targeted balance
		taoStakedBalance[_nameId][_taoId] = taoStakedBalance[_nameId][_taoId].add(_value);	// Add to the targeted staked balance
		totalTAOStakedBalance[_taoId] = totalTAOStakedBalance[_taoId].add(_value);
		emit Stake(_nameId, _taoId, _value);
		return true;
	}

	/**
	 * @dev Unstake `_value` tokens from `_nameId`&#39;s `_taoId`
	 * @param _nameId The Name ID that wants to unstake
	 * @param _taoId The TAO ID to unstake
	 * @param _value The amount to unstake
	 * @return true on success
	 */
	function unstake(address _nameId, address _taoId, uint256 _value) public inWhitelist returns (bool) {
		require (_value > 0 && _value <= MAX_SUPPLY_PER_NAME);
		require (taoStakedBalance[_nameId][_taoId] >= _value);	// Check if the targeted staked balance is enough
		require (totalTAOStakedBalance[_taoId] >= _value);	// Check if the total targeted staked balance is enough
		taoStakedBalance[_nameId][_taoId] = taoStakedBalance[_nameId][_taoId].sub(_value);	// Subtract from the targeted staked balance
		totalTAOStakedBalance[_taoId] = totalTAOStakedBalance[_taoId].sub(_value);
		balanceOf[_nameId] = balanceOf[_nameId].add(_value);			// Add to the targeted balance
		emit Unstake(_nameId, _taoId, _value);
		return true;
	}
}






/**
 * @title NameTAOLookup
 *
 */
contract NameTAOLookup is TheAO {
	address public nameFactoryAddress;
	address public taoFactoryAddress;

	struct NameTAOInfo {
		string name;
		address nameTAOAddress;
		string parentName;
		uint256 typeId; // 0 = TAO. 1 = Name
	}

	uint256 public internalId;
	uint256 public totalNames;
	uint256 public totalTAOs;

	mapping (uint256 => NameTAOInfo) internal nameTAOInfos;
	mapping (bytes32 => uint256) internal internalIdLookup;

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress) public {
		nameFactoryAddress = _nameFactoryAddress;
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Check if calling address is Factory
	 */
	modifier onlyFactory {
		require (msg.sender == nameFactoryAddress || msg.sender == taoFactoryAddress);
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO set the taoFactoryAddress Address
	 * @param _taoFactoryAddress The address of TAOFactory
	 */
	function setTAOFactoryAddress(address _taoFactoryAddress) public onlyTheAO {
		require (_taoFactoryAddress != address(0));
		taoFactoryAddress = _taoFactoryAddress;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Check whether or not a name exist in the list
	 * @param _name The name to be checked
	 * @return true if yes, false otherwise
	 */
	function isExist(string _name) public view returns (bool) {
		bytes32 _nameKey = keccak256(abi.encodePacked(_name));
		return (internalIdLookup[_nameKey] > 0);
	}

	/**
	 * @dev Add a new NameTAOInfo
	 * @param _name The name of the Name/TAO
	 * @param _nameTAOAddress The address of the Name/TAO
	 * @param _parentName The parent name of the Name/TAO
	 * @param _typeId If TAO = 0. Name = 1
	 * @return true on success
	 */
	function add(string _name, address _nameTAOAddress, string _parentName, uint256 _typeId) public onlyFactory returns (bool) {
		require (bytes(_name).length > 0);
		require (_nameTAOAddress != address(0));
		require (bytes(_parentName).length > 0);
		require (_typeId == 0 || _typeId == 1);
		require (!isExist(_name));

		internalId++;
		bytes32 _nameKey = keccak256(abi.encodePacked(_name));
		internalIdLookup[_nameKey] = internalId;
		NameTAOInfo storage _nameTAOInfo = nameTAOInfos[internalId];
		_nameTAOInfo.name = _name;
		_nameTAOInfo.nameTAOAddress = _nameTAOAddress;
		_nameTAOInfo.parentName = _parentName;
		_nameTAOInfo.typeId = _typeId;

		if (_typeId == 0) {
			totalTAOs++;
		} else {
			totalNames++;
		}
		return true;
	}

	/**
	 * @dev Get the NameTAOInfo given a name
	 * @param _name The name to be queried
	 * @return the name of Name/TAO
	 * @return the address of Name/TAO
	 * @return the parent name of Name/TAO
	 * @return type ID. 0 = TAO. 1 = Name
	 */
	function getByName(string _name) public view returns (string, address, string, uint256) {
		require (isExist(_name));
		bytes32 _nameKey = keccak256(abi.encodePacked(_name));
		NameTAOInfo memory _nameTAOInfo = nameTAOInfos[internalIdLookup[_nameKey]];
		return (
			_nameTAOInfo.name,
			_nameTAOInfo.nameTAOAddress,
			_nameTAOInfo.parentName,
			_nameTAOInfo.typeId
		);
	}

	/**
	 * @dev Get the NameTAOInfo given an ID
	 * @param _internalId The internal ID to be queried
	 * @return the name of Name/TAO
	 * @return the address of Name/TAO
	 * @return the parent name of Name/TAO
	 * @return type ID. 0 = TAO. 1 = Name
	 */
	function getByInternalId(uint256 _internalId) public view returns (string, address, string, uint256) {
		require (nameTAOInfos[_internalId].nameTAOAddress != address(0));
		NameTAOInfo memory _nameTAOInfo = nameTAOInfos[_internalId];
		return (
			_nameTAOInfo.name,
			_nameTAOInfo.nameTAOAddress,
			_nameTAOInfo.parentName,
			_nameTAOInfo.typeId
		);
	}

	/**
	 * @dev Return the nameTAOAddress given a _name
	 * @param _name The name to be queried
	 * @return the nameTAOAddress of the name
	 */
	function getAddressByName(string _name) public view returns (address) {
		require (isExist(_name));
		bytes32 _nameKey = keccak256(abi.encodePacked(_name));
		NameTAOInfo memory _nameTAOInfo = nameTAOInfos[internalIdLookup[_nameKey]];
		return _nameTAOInfo.nameTAOAddress;
	}
}









/**
 * @title NamePublicKey
 */
contract NamePublicKey {
	using SafeMath for uint256;

	address public nameFactoryAddress;

	NameFactory internal _nameFactory;
	NameTAOPosition internal _nameTAOPosition;

	struct PublicKey {
		bool created;
		address defaultKey;
		address[] keys;
	}

	// Mapping from nameId to its PublicKey
	mapping (address => PublicKey) internal publicKeys;

	// Event to be broadcasted to public when a publicKey is added to a Name
	event AddKey(address indexed nameId, address publicKey, uint256 nonce);

	// Event to be broadcasted to public when a publicKey is removed from a Name
	event RemoveKey(address indexed nameId, address publicKey, uint256 nonce);

	// Event to be broadcasted to public when a publicKey is set as default for a Name
	event SetDefaultKey(address indexed nameId, address publicKey, uint256 nonce);

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress, address _nameTAOPositionAddress) public {
		nameFactoryAddress = _nameFactoryAddress;

		_nameFactory = NameFactory(_nameFactoryAddress);
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
	}

	/**
	 * @dev Check if calling address is Factory
	 */
	modifier onlyFactory {
		require (msg.sender == nameFactoryAddress);
		_;
	}

	/**
	 * @dev Check if `_nameId` is a Name
	 */
	modifier isName(address _nameId) {
		require (AOLibrary.isName(_nameId));
		_;
	}

	/**
	 * @dev Check if msg.sender is the current advocate of Name ID
	 */
	modifier onlyAdvocate(address _id) {
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _id));
		_;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Check whether or not a Name ID exist in the list of Public Keys
	 * @param _id The ID to be checked
	 * @return true if yes, false otherwise
	 */
	function isExist(address _id) public view returns (bool) {
		return publicKeys[_id].created;
	}

	/**
	 * @dev Store the PublicKey info for a Name
	 * @param _id The ID of the Name
	 * @param _defaultKey The default public key for this Name
	 * @return true on success
	 */
	function add(address _id, address _defaultKey)
		public
		isName(_id)
		onlyFactory returns (bool) {
		require (!isExist(_id));
		require (_defaultKey != address(0));

		PublicKey storage _publicKey = publicKeys[_id];
		_publicKey.created = true;
		_publicKey.defaultKey = _defaultKey;
		_publicKey.keys.push(_defaultKey);
		return true;
	}

	/**
	 * @dev Get total publicKeys count for a Name
	 * @param _id The ID of the Name
	 * @return total publicKeys count
	 */
	function getTotalPublicKeysCount(address _id) public isName(_id) view returns (uint256) {
		require (isExist(_id));
		return publicKeys[_id].keys.length;
	}

	/**
	 * @dev Check whether or not a publicKey exist in the list for a Name
	 * @param _id The ID of the Name
	 * @param _key The publicKey to check
	 * @return true if yes. false otherwise
	 */
	function isKeyExist(address _id, address _key) isName(_id) public view returns (bool) {
		require (isExist(_id));
		require (_key != address(0));

		PublicKey memory _publicKey = publicKeys[_id];
		for (uint256 i = 0; i < _publicKey.keys.length; i++) {
			if (_publicKey.keys[i] == _key) {
				return true;
			}
		}
		return false;
	}

	/**
	 * @dev Add publicKey to list for a Name
	 * @param _id The ID of the Name
	 * @param _key The publicKey to be added
	 */
	function addKey(address _id, address _key) public isName(_id) onlyAdvocate(_id) {
		require (!isKeyExist(_id, _key));

		PublicKey storage _publicKey = publicKeys[_id];
		_publicKey.keys.push(_key);

		uint256 _nonce = _nameFactory.incrementNonce(_id);
		require (_nonce > 0);

		emit AddKey(_id, _key, _nonce);
	}

	/**
	 * @dev Get default public key of a Name
	 * @param _id The ID of the Name
	 * @return the default public key
	 */
	function getDefaultKey(address _id) public isName(_id) view returns (address) {
		require (isExist(_id));
		return publicKeys[_id].defaultKey;
	}

	/**
	 * @dev Get list of publicKeys of a Name
	 * @param _id The ID of the Name
	 * @param _from The starting index
	 * @param _to The ending index
	 * @return list of publicKeys
	 */
	function getKeys(address _id, uint256 _from, uint256 _to) public isName(_id) view returns (address[]) {
		require (isExist(_id));
		require (_from >= 0 && _to >= _from);

		PublicKey memory _publicKey = publicKeys[_id];
		require (_publicKey.keys.length > 0);

		address[] memory _keys = new address[](_to.sub(_from).add(1));
		if (_to > _publicKey.keys.length.sub(1)) {
			_to = _publicKey.keys.length.sub(1);
		}
		for (uint256 i = _from; i <= _to; i++) {
			_keys[i.sub(_from)] = _publicKey.keys[i];
		}
		return _keys;
	}

	/**
	 * @dev Remove publicKey from the list
	 * @param _id The ID of the Name
	 * @param _key The publicKey to be removed
	 */
	function removeKey(address _id, address _key) public isName(_id) onlyAdvocate(_id) {
		require (isExist(_id));
		require (isKeyExist(_id, _key));

		PublicKey storage _publicKey = publicKeys[_id];

		// Can&#39;t remove default key
		require (_key != _publicKey.defaultKey);
		require (_publicKey.keys.length > 1);

		for (uint256 i = 0; i < _publicKey.keys.length; i++) {
			if (_publicKey.keys[i] == _key) {
				delete _publicKey.keys[i];
				_publicKey.keys.length--;

				uint256 _nonce = _nameFactory.incrementNonce(_id);
				break;
			}
		}
		require (_nonce > 0);

		emit RemoveKey(_id, _key, _nonce);
	}

	/**
	 * @dev Set a publicKey as the default for a Name
	 * @param _id The ID of the Name
	 * @param _defaultKey The defaultKey to be set
	 * @param _signatureV The V part of the signature for this update
	 * @param _signatureR The R part of the signature for this update
	 * @param _signatureS The S part of the signature for this update
	 */
	function setDefaultKey(address _id, address _defaultKey, uint8 _signatureV, bytes32 _signatureR, bytes32 _signatureS) public isName(_id) onlyAdvocate(_id) {
		require (isExist(_id));
		require (isKeyExist(_id, _defaultKey));

		bytes32 _hash = keccak256(abi.encodePacked(address(this), _id, _defaultKey));
		require (ecrecover(_hash, _signatureV, _signatureR, _signatureS) == msg.sender);

		PublicKey storage _publicKey = publicKeys[_id];
		_publicKey.defaultKey = _defaultKey;

		uint256 _nonce = _nameFactory.incrementNonce(_id);
		require (_nonce > 0);
		emit SetDefaultKey(_id, _defaultKey, _nonce);
	}
}


/**
 * @title NameFactory
 *
 * The purpose of this contract is to allow node to create Name
 */
contract NameFactory is TheAO {
	using SafeMath for uint256;

	address public positionAddress;
	address public nameTAOVaultAddress;
	address public nameTAOLookupAddress;
	address public namePublicKeyAddress;

	Position internal _position;
	NameTAOLookup internal _nameTAOLookup;
	NameTAOPosition internal _nameTAOPosition;
	NamePublicKey internal _namePublicKey;

	address[] internal names;

	// Mapping from eth address to Name ID
	mapping (address => address) public ethAddressToNameId;

	// Mapping from Name ID to its nonce
	mapping (address => uint256) public nonces;

	// Event to be broadcasted to public when a Name is created
	event CreateName(address indexed ethAddress, address nameId, uint256 index, string name);

	/**
	 * @dev Constructor function
	 */
	constructor(address _positionAddress, address _nameTAOVaultAddress) public {
		positionAddress = _positionAddress;
		nameTAOVaultAddress = _nameTAOVaultAddress;
		_position = Position(positionAddress);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Checks if calling address can update Name&#39;s nonce
	 */
	modifier canUpdateNonce {
		require (msg.sender == nameTAOPositionAddress || msg.sender == namePublicKeyAddress);
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO set the NameTAOLookup Address
	 * @param _nameTAOLookupAddress The address of NameTAOLookup
	 */
	function setNameTAOLookupAddress(address _nameTAOLookupAddress) public onlyTheAO {
		require (_nameTAOLookupAddress != address(0));
		nameTAOLookupAddress = _nameTAOLookupAddress;
		_nameTAOLookup = NameTAOLookup(nameTAOLookupAddress);
	}

	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
		_nameTAOPosition = NameTAOPosition(nameTAOPositionAddress);
	}

	/**
	 * @dev The AO set the NamePublicKey Address
	 * @param _namePublicKeyAddress The address of NamePublicKey
	 */
	function setNamePublicKeyAddress(address _namePublicKeyAddress) public onlyTheAO {
		require (_namePublicKeyAddress != address(0));
		namePublicKeyAddress = _namePublicKeyAddress;
		_namePublicKey = NamePublicKey(namePublicKeyAddress);
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Increment the nonce of a Name
	 * @param _nameId The ID of the Name
	 * @return current nonce
	 */
	function incrementNonce(address _nameId) public canUpdateNonce returns (uint256) {
		// Check if _nameId exist
		require (nonces[_nameId] > 0);
		nonces[_nameId]++;
		return nonces[_nameId];
	}

	/**
	 * @dev Create a Name
	 * @param _name The name of the Name
	 * @param _datHash The datHash to this Name&#39;s profile
	 * @param _database The database for this Name
	 * @param _keyValue The key/value pair to be checked on the database
	 * @param _contentId The contentId related to this Name
	 */
	function createName(string _name, string _datHash, string _database, string _keyValue, bytes32 _contentId) public {
		require (bytes(_name).length > 0);
		require (!_nameTAOLookup.isExist(_name));

		// Only one Name per ETH address
		require (ethAddressToNameId[msg.sender] == address(0));

		// The address is the Name ID (which is also a TAO ID)
		address nameId = new Name(_name, msg.sender, _datHash, _database, _keyValue, _contentId, nameTAOVaultAddress);

		// Increment the nonce
		nonces[nameId]++;

		ethAddressToNameId[msg.sender] = nameId;

		// Store the name lookup information
		require (_nameTAOLookup.add(_name, nameId, &#39;human&#39;, 1));

		// Store the Advocate/Listener/Speaker information
		require (_nameTAOPosition.add(nameId, nameId, nameId, nameId));

		// Store the public key information
		require (_namePublicKey.add(nameId, msg.sender));

		names.push(nameId);

		// Need to mint Position token for this Name
		require (_position.mintToken(nameId));

		emit CreateName(msg.sender, nameId, names.length.sub(1), _name);
	}

	/**
	 * @dev Get Name information
	 * @param _nameId The ID of the Name to be queried
	 * @return The name of the Name
	 * @return The originId of the Name (in this case, it&#39;s the creator node&#39;s ETH address)
	 * @return The datHash of the Name
	 * @return The database of the Name
	 * @return The keyValue of the Name
	 * @return The contentId of the Name
	 * @return The typeId of the Name
	 */
	function getName(address _nameId) public view returns (string, address, string, string, string, bytes32, uint8) {
		Name _name = Name(_nameId);
		return (
			_name.name(),
			_name.originId(),
			_name.datHash(),
			_name.database(),
			_name.keyValue(),
			_name.contentId(),
			_name.typeId()
		);
	}

	/**
	 * @dev Get total Names count
	 * @return total Names count
	 */
	function getTotalNamesCount() public view returns (uint256) {
		return names.length;
	}

	/**
	 * @dev Get list of Name IDs
	 * @param _from The starting index
	 * @param _to The ending index
	 * @return list of Name IDs
	 */
	function getNameIds(uint256 _from, uint256 _to) public view returns (address[]) {
		require (_from >= 0 && _to >= _from);
		require (names.length > 0);

		address[] memory _names = new address[](_to.sub(_from).add(1));
		if (_to > names.length.sub(1)) {
			_to = names.length.sub(1);
		}
		for (uint256 i = _from; i <= _to; i++) {
			_names[i.sub(_from)] = names[i];
		}
		return _names;
	}

	/**
	 * @dev Check whether or not the signature is valid
	 * @param _data The signed string data
	 * @param _nonce The signed uint256 nonce (should be Name&#39;s current nonce + 1)
	 * @param _validateAddress The ETH address to be validated (optional)
	 * @param _name The name of the Name
	 * @param _signatureV The V part of the signature
	 * @param _signatureR The R part of the signature
	 * @param _signatureS The S part of the signature
	 * @return true if valid. false otherwise
	 */
	function validateNameSignature(
		string _data,
		uint256 _nonce,
		address _validateAddress,
		string _name,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS
	) public view returns (bool) {
		require (_nameTAOLookup.isExist(_name));
		address _nameId = _nameTAOLookup.getAddressByName(_name);
		address _signatureAddress = AOLibrary.getValidateSignatureAddress(address(this), _data, _nonce, _signatureV, _signatureR, _signatureS);
		if (_validateAddress != address(0)) {
			return (
				_nonce == nonces[_nameId].add(1) &&
				_signatureAddress == _validateAddress &&
				_namePublicKey.isKeyExist(_nameId, _validateAddress)
			);
		} else {
			return (
				_nonce == nonces[_nameId].add(1) &&
				_signatureAddress == _namePublicKey.getDefaultKey(_nameId)
			);
		}
	}
}





/**
 * @title AOStringSetting
 *
 * This contract stores all AO string setting variables
 */
contract AOStringSetting is TheAO {
	// Mapping from settingId to it&#39;s actual string value
	mapping (uint256 => string) public settingValue;

	// Mapping from settingId to it&#39;s potential string value that is at pending state
	mapping (uint256 => string) public pendingValue;

	/**
	 * @dev Constructor function
	 */
	constructor() public {}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Set pending value
	 * @param _settingId The ID of the setting
	 * @param _value The string value to be set
	 */
	function setPendingValue(uint256 _settingId, string _value) public inWhitelist {
		pendingValue[_settingId] = _value;
	}

	/**
	 * @dev Move value from pending to setting
	 * @param _settingId The ID of the setting
	 */
	function movePendingToSetting(uint256 _settingId) public inWhitelist {
		string memory _tempValue = pendingValue[_settingId];
		delete pendingValue[_settingId];
		settingValue[_settingId] = _tempValue;
	}
}





/**
 * @title AOBytesSetting
 *
 * This contract stores all AO bytes32 setting variables
 */
contract AOBytesSetting is TheAO {
	// Mapping from settingId to it&#39;s actual bytes32 value
	mapping (uint256 => bytes32) public settingValue;

	// Mapping from settingId to it&#39;s potential bytes32 value that is at pending state
	mapping (uint256 => bytes32) public pendingValue;

	/**
	 * @dev Constructor function
	 */
	constructor() public {}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Set pending value
	 * @param _settingId The ID of the setting
	 * @param _value The bytes32 value to be set
	 */
	function setPendingValue(uint256 _settingId, bytes32 _value) public inWhitelist {
		pendingValue[_settingId] = _value;
	}

	/**
	 * @dev Move value from pending to setting
	 * @param _settingId The ID of the setting
	 */
	function movePendingToSetting(uint256 _settingId) public inWhitelist {
		bytes32 _tempValue = pendingValue[_settingId];
		delete pendingValue[_settingId];
		settingValue[_settingId] = _tempValue;
	}
}





/**
 * @title AOAddressSetting
 *
 * This contract stores all AO address setting variables
 */
contract AOAddressSetting is TheAO {
	// Mapping from settingId to it&#39;s actual address value
	mapping (uint256 => address) public settingValue;

	// Mapping from settingId to it&#39;s potential address value that is at pending state
	mapping (uint256 => address) public pendingValue;

	/**
	 * @dev Constructor function
	 */
	constructor() public {}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Set pending value
	 * @param _settingId The ID of the setting
	 * @param _value The address value to be set
	 */
	function setPendingValue(uint256 _settingId, address _value) public inWhitelist {
		pendingValue[_settingId] = _value;
	}

	/**
	 * @dev Move value from pending to setting
	 * @param _settingId The ID of the setting
	 */
	function movePendingToSetting(uint256 _settingId) public inWhitelist {
		address _tempValue = pendingValue[_settingId];
		delete pendingValue[_settingId];
		settingValue[_settingId] = _tempValue;
	}
}





/**
 * @title AOBoolSetting
 *
 * This contract stores all AO bool setting variables
 */
contract AOBoolSetting is TheAO {
	// Mapping from settingId to it&#39;s actual bool value
	mapping (uint256 => bool) public settingValue;

	// Mapping from settingId to it&#39;s potential bool value that is at pending state
	mapping (uint256 => bool) public pendingValue;

	/**
	 * @dev Constructor function
	 */
	constructor() public {}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Set pending value
	 * @param _settingId The ID of the setting
	 * @param _value The bool value to be set
	 */
	function setPendingValue(uint256 _settingId, bool _value) public inWhitelist {
		pendingValue[_settingId] = _value;
	}

	/**
	 * @dev Move value from pending to setting
	 * @param _settingId The ID of the setting
	 */
	function movePendingToSetting(uint256 _settingId) public inWhitelist {
		bool _tempValue = pendingValue[_settingId];
		delete pendingValue[_settingId];
		settingValue[_settingId] = _tempValue;
	}
}





/**
 * @title AOUintSetting
 *
 * This contract stores all AO uint256 setting variables
 */
contract AOUintSetting is TheAO {
	// Mapping from settingId to it&#39;s actual uint256 value
	mapping (uint256 => uint256) public settingValue;

	// Mapping from settingId to it&#39;s potential uint256 value that is at pending state
	mapping (uint256 => uint256) public pendingValue;

	/**
	 * @dev Constructor function
	 */
	constructor() public {}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Set pending value
	 * @param _settingId The ID of the setting
	 * @param _value The uint256 value to be set
	 */
	function setPendingValue(uint256 _settingId, uint256 _value) public inWhitelist {
		pendingValue[_settingId] = _value;
	}

	/**
	 * @dev Move value from pending to setting
	 * @param _settingId The ID of the setting
	 */
	function movePendingToSetting(uint256 _settingId) public inWhitelist {
		uint256 _tempValue = pendingValue[_settingId];
		delete pendingValue[_settingId];
		settingValue[_settingId] = _tempValue;
	}
}






/**
 * @title AOSettingAttribute
 *
 * This contract stores all AO setting data/state
 */
contract AOSettingAttribute is TheAO {
	NameTAOPosition internal _nameTAOPosition;

	struct SettingData {
		uint256 settingId;				// Identifier of this setting
		address creatorNameId;			// The nameId that created the setting
		address creatorTAOId;		// The taoId that created the setting
		address associatedTAOId;	// The taoId that the setting affects
		string settingName;				// The human-readable name of the setting
		/**
		 * 1 => uint256
		 * 2 => bool
		 * 3 => address
		 * 4 => bytes32
		 * 5 => string (catch all)
		 */
		uint8 settingType;
		bool pendingCreate;				// State when associatedTAOId has not accepted setting
		bool locked;					// State when pending anything (cannot change if locked)
		bool rejected;					// State when associatedTAOId rejected this setting
		string settingDataJSON;			// Catch-all
	}

	struct SettingState {
		uint256 settingId;				// Identifier of this setting
		bool pendingUpdate;				// State when setting is in process of being updated
		address updateAdvocateNameId;	// The nameId of the Advocate that performed the update

		/**
		 * A child of the associatedTAOId with the update Logos.
		 * This tells the setting contract that there is a proposal TAO that is a Child TAO
		 * of the associated TAO, which will be responsible for deciding if the update to the
		 * setting is accepted or rejected.
		 */
		address proposalTAOId;

		/**
		 * Signature of the proposalTAOId and update value by the associatedTAOId
		 * Advocate&#39;s Name&#39;s address.
		 */
		string updateSignature;

		/**
		 * The proposalTAOId moves here when setting value changes successfully
		 */
		address lastUpdateTAOId;

		string settingStateJSON;		// Catch-all
	}

	struct SettingDeprecation {
		uint256 settingId;				// Identifier of this setting
		address creatorNameId;			// The nameId that created this deprecation
		address creatorTAOId;		// The taoId that created this deprecation
		address associatedTAOId;	// The taoId that the setting affects
		bool pendingDeprecated;			// State when associatedTAOId has not accepted setting
		bool locked;					// State when pending anything (cannot change if locked)
		bool rejected;					// State when associatedTAOId rejected this setting
		bool migrated;					// State when this setting is fully migrated

		// holds the pending new settingId value when a deprecation is set
		uint256 pendingNewSettingId;

		// holds the new settingId that has been approved by associatedTAOId
		uint256 newSettingId;

		// holds the pending new contract address for this setting
		address pendingNewSettingContractAddress;

		// holds the new contract address for this setting
		address newSettingContractAddress;
	}

	struct AssociatedTAOSetting {
		bytes32 associatedTAOSettingId;		// Identifier
		address associatedTAOId;			// The TAO ID that the setting is associated to
		uint256 settingId;						// The Setting ID that is associated with the TAO ID
	}

	struct CreatorTAOSetting {
		bytes32 creatorTAOSettingId;		// Identifier
		address creatorTAOId;				// The TAO ID that the setting was created from
		uint256 settingId;						// The Setting ID created from the TAO ID
	}

	struct AssociatedTAOSettingDeprecation {
		bytes32 associatedTAOSettingDeprecationId;		// Identifier
		address associatedTAOId;						// The TAO ID that the setting is associated to
		uint256 settingId;									// The Setting ID that is associated with the TAO ID
	}

	struct CreatorTAOSettingDeprecation {
		bytes32 creatorTAOSettingDeprecationId;			// Identifier
		address creatorTAOId;							// The TAO ID that the setting was created from
		uint256 settingId;									// The Setting ID created from the TAO ID
	}

	// Mapping from settingId to it&#39;s data
	mapping (uint256 => SettingData) internal settingDatas;

	// Mapping from settingId to it&#39;s state
	mapping (uint256 => SettingState) internal settingStates;

	// Mapping from settingId to it&#39;s deprecation info
	mapping (uint256 => SettingDeprecation) internal settingDeprecations;

	// Mapping from associatedTAOSettingId to AssociatedTAOSetting
	mapping (bytes32 => AssociatedTAOSetting) internal associatedTAOSettings;

	// Mapping from creatorTAOSettingId to CreatorTAOSetting
	mapping (bytes32 => CreatorTAOSetting) internal creatorTAOSettings;

	// Mapping from associatedTAOSettingDeprecationId to AssociatedTAOSettingDeprecation
	mapping (bytes32 => AssociatedTAOSettingDeprecation) internal associatedTAOSettingDeprecations;

	// Mapping from creatorTAOSettingDeprecationId to CreatorTAOSettingDeprecation
	mapping (bytes32 => CreatorTAOSettingDeprecation) internal creatorTAOSettingDeprecations;

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameTAOPositionAddress) public {
		nameTAOPositionAddress = _nameTAOPositionAddress;
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev Add setting data/state
	 * @param _settingId The ID of the setting
	 * @param _creatorNameId The nameId that created the setting
	 * @param _settingType The type of this setting. 1 => uint256, 2 => bool, 3 => address, 4 => bytes32, 5 => string
	 * @param _settingName The human-readable name of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 * @return The ID of the "Associated" setting
	 * @return The ID of the "Creator" setting
	 */
	function add(uint256 _settingId, address _creatorNameId, uint8 _settingType, string _settingName, address _creatorTAOId, address _associatedTAOId, string _extraData) public inWhitelist returns (bytes32, bytes32) {
		// Store setting data/state
		require (_storeSettingDataState(_settingId, _creatorNameId, _settingType, _settingName, _creatorTAOId, _associatedTAOId, _extraData));

		// Store the associatedTAOSetting info
		bytes32 _associatedTAOSettingId = keccak256(abi.encodePacked(this, _associatedTAOId, _settingId));
		AssociatedTAOSetting storage _associatedTAOSetting = associatedTAOSettings[_associatedTAOSettingId];
		_associatedTAOSetting.associatedTAOSettingId = _associatedTAOSettingId;
		_associatedTAOSetting.associatedTAOId = _associatedTAOId;
		_associatedTAOSetting.settingId = _settingId;

		// Store the creatorTAOSetting info
		bytes32 _creatorTAOSettingId = keccak256(abi.encodePacked(this, _creatorTAOId, _settingId));
		CreatorTAOSetting storage _creatorTAOSetting = creatorTAOSettings[_creatorTAOSettingId];
		_creatorTAOSetting.creatorTAOSettingId = _creatorTAOSettingId;
		_creatorTAOSetting.creatorTAOId = _creatorTAOId;
		_creatorTAOSetting.settingId = _settingId;

		return (_associatedTAOSettingId, _creatorTAOSettingId);
	}

	/**
	 * @dev Get Setting Data of a setting ID
	 * @param _settingId The ID of the setting
	 */
	function getSettingData(uint256 _settingId) public view returns (uint256, address, address, address, string, uint8, bool, bool, bool, string) {
		SettingData memory _settingData = settingDatas[_settingId];
		return (
			_settingData.settingId,
			_settingData.creatorNameId,
			_settingData.creatorTAOId,
			_settingData.associatedTAOId,
			_settingData.settingName,
			_settingData.settingType,
			_settingData.pendingCreate,
			_settingData.locked,
			_settingData.rejected,
			_settingData.settingDataJSON
		);
	}

	/**
	 * @dev Get Associated TAO Setting info
	 * @param _associatedTAOSettingId The ID of the associated tao setting
	 */
	function getAssociatedTAOSetting(bytes32 _associatedTAOSettingId) public view returns (bytes32, address, uint256) {
		AssociatedTAOSetting memory _associatedTAOSetting = associatedTAOSettings[_associatedTAOSettingId];
		return (
			_associatedTAOSetting.associatedTAOSettingId,
			_associatedTAOSetting.associatedTAOId,
			_associatedTAOSetting.settingId
		);
	}

	/**
	 * @dev Get Creator TAO Setting info
	 * @param _creatorTAOSettingId The ID of the creator tao setting
	 */
	function getCreatorTAOSetting(bytes32 _creatorTAOSettingId) public view returns (bytes32, address, uint256) {
		CreatorTAOSetting memory _creatorTAOSetting = creatorTAOSettings[_creatorTAOSettingId];
		return (
			_creatorTAOSetting.creatorTAOSettingId,
			_creatorTAOSetting.creatorTAOId,
			_creatorTAOSetting.settingId
		);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId approves setting creation
	 * @param _settingId The ID of the setting to approve
	 * @param _associatedTAOAdvocate The advocate of the associated TAO
	 * @param _approved Whether to approve or reject
	 * @return true on success
	 */
	function approveAdd(uint256 _settingId, address _associatedTAOAdvocate, bool _approved) public inWhitelist returns (bool) {
		// Make sure setting exists and needs approval
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == true &&
			_settingData.locked == true &&
			_settingData.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.associatedTAOId)
		);

		if (_approved) {
			// Unlock the setting so that advocate of creatorTAOId can finalize the creation
			_settingData.locked = false;
		} else {
			// Reject the setting
			_settingData.pendingCreate = false;
			_settingData.rejected = true;
		}

		return true;
	}

	/**
	 * @dev Advocate of Setting&#39;s _creatorTAOId finalizes the setting creation once the setting is approved
	 * @param _settingId The ID of the setting to be finalized
	 * @param _creatorTAOAdvocate The advocate of the creator TAO
	 * @return true on success
	 */
	function finalizeAdd(uint256 _settingId, address _creatorTAOAdvocate) public inWhitelist returns (bool) {
		// Make sure setting exists and needs approval
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == true &&
			_settingData.locked == false &&
			_settingData.rejected == false &&
			_creatorTAOAdvocate != address(0) &&
			_creatorTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.creatorTAOId)
		);

		// Update the setting data
		_settingData.pendingCreate = false;
		_settingData.locked = true;

		return true;
	}

	/**
	 * @dev Store setting update data
	 * @param _settingId The ID of the setting to be updated
	 * @param _settingType The type of this setting
	 * @param _associatedTAOAdvocate The setting&#39;s associatedTAOId&#39;s advocate&#39;s name address
	 * @param _proposalTAOId The child of the associatedTAOId with the update Logos
	 * @param _updateSignature A signature of the proposalTAOId and update value by _associatedTAOAdvocate
	 * @param _extraData Catch-all string value to be stored if exist
	 * @return true on success
	 */
	function update(uint256 _settingId, uint8 _settingType, address _associatedTAOAdvocate, address _proposalTAOId, string _updateSignature, string _extraData) public inWhitelist returns (bool) {
		// Make sure setting is created
		SettingData memory _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.settingType == _settingType &&
			_settingData.pendingCreate == false &&
			_settingData.locked == true &&
			_settingData.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.associatedTAOId) &&
			bytes(_updateSignature).length > 0
		);

		// Make sure setting is not in the middle of updating
		SettingState storage _settingState = settingStates[_settingId];
		require (_settingState.pendingUpdate == false);

		// Make sure setting is not yet deprecated
		SettingDeprecation memory _settingDeprecation = settingDeprecations[_settingId];
		if (_settingDeprecation.settingId == _settingId) {
			require (_settingDeprecation.migrated == false);
		}

		// Store the SettingState data
		_settingState.pendingUpdate = true;
		_settingState.updateAdvocateNameId = _associatedTAOAdvocate;
		_settingState.proposalTAOId = _proposalTAOId;
		_settingState.updateSignature = _updateSignature;
		_settingState.settingStateJSON = _extraData;

		return true;
	}

	/**
	 * @dev Get setting state
	 * @param _settingId The ID of the setting
	 */
	function getSettingState(uint256 _settingId) public view returns (uint256, bool, address, address, string, address, string) {
		SettingState memory _settingState = settingStates[_settingId];
		return (
			_settingState.settingId,
			_settingState.pendingUpdate,
			_settingState.updateAdvocateNameId,
			_settingState.proposalTAOId,
			_settingState.updateSignature,
			_settingState.lastUpdateTAOId,
			_settingState.settingStateJSON
		);
	}

	/**
	 * @dev Advocate of Setting&#39;s proposalTAOId approves the setting update
	 * @param _settingId The ID of the setting to be approved
	 * @param _proposalTAOAdvocate The advocate of the proposal TAO
	 * @param _approved Whether to approve or reject
	 * @return true on success
	 */
	function approveUpdate(uint256 _settingId, address _proposalTAOAdvocate, bool _approved) public inWhitelist returns (bool) {
		// Make sure setting is created
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId && _settingData.pendingCreate == false && _settingData.locked == true && _settingData.rejected == false);

		// Make sure setting update exists and needs approval
		SettingState storage _settingState = settingStates[_settingId];
		require (_settingState.settingId == _settingId &&
			_settingState.pendingUpdate == true &&
			_proposalTAOAdvocate != address(0) &&
			_proposalTAOAdvocate == _nameTAOPosition.getAdvocate(_settingState.proposalTAOId)
		);

		if (_approved) {
			// Unlock the setting so that advocate of associatedTAOId can finalize the update
			_settingData.locked = false;
		} else {
			// Set pendingUpdate to false
			_settingState.pendingUpdate = false;
			_settingState.proposalTAOId = address(0);
		}
		return true;
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId finalizes the setting update once the setting is approved
	 * @param _settingId The ID of the setting to be finalized
	 * @param _associatedTAOAdvocate The advocate of the associated TAO
	 * @return true on success
	 */
	function finalizeUpdate(uint256 _settingId, address _associatedTAOAdvocate) public inWhitelist returns (bool) {
		// Make sure setting is created
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == false &&
			_settingData.locked == false &&
			_settingData.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.associatedTAOId)
		);

		// Make sure setting update exists and needs approval
		SettingState storage _settingState = settingStates[_settingId];
		require (_settingState.settingId == _settingId && _settingState.pendingUpdate == true && _settingState.proposalTAOId != address(0));

		// Update the setting data
		_settingData.locked = true;

		// Update the setting state
		_settingState.pendingUpdate = false;
		_settingState.updateAdvocateNameId = _associatedTAOAdvocate;
		address _proposalTAOId = _settingState.proposalTAOId;
		_settingState.proposalTAOId = address(0);
		_settingState.lastUpdateTAOId = _proposalTAOId;

		return true;
	}

	/**
	 * @dev Add setting deprecation
	 * @param _settingId The ID of the setting
	 * @param _creatorNameId The nameId that created the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _newSettingId The new settingId value to route
	 * @param _newSettingContractAddress The address of the new setting contract to route
	 * @return The ID of the "Associated" setting deprecation
	 * @return The ID of the "Creator" setting deprecation
	 */
	function addDeprecation(uint256 _settingId, address _creatorNameId, address _creatorTAOId, address _associatedTAOId, uint256 _newSettingId, address _newSettingContractAddress) public inWhitelist returns (bytes32, bytes32) {
		require (_storeSettingDeprecation(_settingId, _creatorNameId, _creatorTAOId, _associatedTAOId, _newSettingId, _newSettingContractAddress));

		// Store the associatedTAOSettingDeprecation info
		bytes32 _associatedTAOSettingDeprecationId = keccak256(abi.encodePacked(this, _associatedTAOId, _settingId));
		AssociatedTAOSettingDeprecation storage _associatedTAOSettingDeprecation = associatedTAOSettingDeprecations[_associatedTAOSettingDeprecationId];
		_associatedTAOSettingDeprecation.associatedTAOSettingDeprecationId = _associatedTAOSettingDeprecationId;
		_associatedTAOSettingDeprecation.associatedTAOId = _associatedTAOId;
		_associatedTAOSettingDeprecation.settingId = _settingId;

		// Store the creatorTAOSettingDeprecation info
		bytes32 _creatorTAOSettingDeprecationId = keccak256(abi.encodePacked(this, _creatorTAOId, _settingId));
		CreatorTAOSettingDeprecation storage _creatorTAOSettingDeprecation = creatorTAOSettingDeprecations[_creatorTAOSettingDeprecationId];
		_creatorTAOSettingDeprecation.creatorTAOSettingDeprecationId = _creatorTAOSettingDeprecationId;
		_creatorTAOSettingDeprecation.creatorTAOId = _creatorTAOId;
		_creatorTAOSettingDeprecation.settingId = _settingId;

		return (_associatedTAOSettingDeprecationId, _creatorTAOSettingDeprecationId);
	}

	/**
	 * @dev Get Setting Deprecation info of a setting ID
	 * @param _settingId The ID of the setting
	 */
	function getSettingDeprecation(uint256 _settingId) public view returns (uint256, address, address, address, bool, bool, bool, bool, uint256, uint256, address, address) {
		SettingDeprecation memory _settingDeprecation = settingDeprecations[_settingId];
		return (
			_settingDeprecation.settingId,
			_settingDeprecation.creatorNameId,
			_settingDeprecation.creatorTAOId,
			_settingDeprecation.associatedTAOId,
			_settingDeprecation.pendingDeprecated,
			_settingDeprecation.locked,
			_settingDeprecation.rejected,
			_settingDeprecation.migrated,
			_settingDeprecation.pendingNewSettingId,
			_settingDeprecation.newSettingId,
			_settingDeprecation.pendingNewSettingContractAddress,
			_settingDeprecation.newSettingContractAddress
		);
	}

	/**
	 * @dev Get Associated TAO Setting Deprecation info
	 * @param _associatedTAOSettingDeprecationId The ID of the associated tao setting deprecation
	 */
	function getAssociatedTAOSettingDeprecation(bytes32 _associatedTAOSettingDeprecationId) public view returns (bytes32, address, uint256) {
		AssociatedTAOSettingDeprecation memory _associatedTAOSettingDeprecation = associatedTAOSettingDeprecations[_associatedTAOSettingDeprecationId];
		return (
			_associatedTAOSettingDeprecation.associatedTAOSettingDeprecationId,
			_associatedTAOSettingDeprecation.associatedTAOId,
			_associatedTAOSettingDeprecation.settingId
		);
	}

	/**
	 * @dev Get Creator TAO Setting Deprecation info
	 * @param _creatorTAOSettingDeprecationId The ID of the creator tao setting deprecation
	 */
	function getCreatorTAOSettingDeprecation(bytes32 _creatorTAOSettingDeprecationId) public view returns (bytes32, address, uint256) {
		CreatorTAOSettingDeprecation memory _creatorTAOSettingDeprecation = creatorTAOSettingDeprecations[_creatorTAOSettingDeprecationId];
		return (
			_creatorTAOSettingDeprecation.creatorTAOSettingDeprecationId,
			_creatorTAOSettingDeprecation.creatorTAOId,
			_creatorTAOSettingDeprecation.settingId
		);
	}

	/**
	 * @dev Advocate of SettingDeprecation&#39;s _associatedTAOId approves deprecation
	 * @param _settingId The ID of the setting to approve
	 * @param _associatedTAOAdvocate The advocate of the associated TAO
	 * @param _approved Whether to approve or reject
	 * @return true on success
	 */
	function approveDeprecation(uint256 _settingId, address _associatedTAOAdvocate, bool _approved) public inWhitelist returns (bool) {
		// Make sure setting exists and needs approval
		SettingDeprecation storage _settingDeprecation = settingDeprecations[_settingId];
		require (_settingDeprecation.settingId == _settingId &&
			_settingDeprecation.migrated == false &&
			_settingDeprecation.pendingDeprecated == true &&
			_settingDeprecation.locked == true &&
			_settingDeprecation.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingDeprecation.associatedTAOId)
		);

		if (_approved) {
			// Unlock the setting so that advocate of creatorTAOId can finalize the creation
			_settingDeprecation.locked = false;
		} else {
			// Reject the setting
			_settingDeprecation.pendingDeprecated = false;
			_settingDeprecation.rejected = true;
		}
		return true;
	}

	/**
	 * @dev Advocate of SettingDeprecation&#39;s _creatorTAOId finalizes the deprecation once the setting deprecation is approved
	 * @param _settingId The ID of the setting to be finalized
	 * @param _creatorTAOAdvocate The advocate of the creator TAO
	 * @return true on success
	 */
	function finalizeDeprecation(uint256 _settingId, address _creatorTAOAdvocate) public inWhitelist returns (bool) {
		// Make sure setting exists and needs approval
		SettingDeprecation storage _settingDeprecation = settingDeprecations[_settingId];
		require (_settingDeprecation.settingId == _settingId &&
			_settingDeprecation.migrated == false &&
			_settingDeprecation.pendingDeprecated == true &&
			_settingDeprecation.locked == false &&
			_settingDeprecation.rejected == false &&
			_creatorTAOAdvocate != address(0) &&
			_creatorTAOAdvocate == _nameTAOPosition.getAdvocate(_settingDeprecation.creatorTAOId)
		);

		// Update the setting data
		_settingDeprecation.pendingDeprecated = false;
		_settingDeprecation.locked = true;
		_settingDeprecation.migrated = true;
		uint256 _newSettingId = _settingDeprecation.pendingNewSettingId;
		_settingDeprecation.pendingNewSettingId = 0;
		_settingDeprecation.newSettingId = _newSettingId;

		address _newSettingContractAddress = _settingDeprecation.pendingNewSettingContractAddress;
		_settingDeprecation.pendingNewSettingContractAddress = address(0);
		_settingDeprecation.newSettingContractAddress = _newSettingContractAddress;
		return true;
	}

	/**
	 * @dev Check if a setting exist and not rejected
	 * @param _settingId The ID of the setting
	 * @return true if exist. false otherwise
	 */
	function settingExist(uint256 _settingId) public view returns (bool) {
		SettingData memory _settingData = settingDatas[_settingId];
		return (_settingData.settingId == _settingId && _settingData.rejected == false);
	}

	/**
	 * @dev Get the latest ID of a deprecated setting, if exist
	 * @param _settingId The ID of the setting
	 * @return The latest setting ID
	 */
	function getLatestSettingId(uint256 _settingId) public view returns (uint256) {
		(,,,,,,, bool _migrated,, uint256 _newSettingId,,) = getSettingDeprecation(_settingId);
		while (_migrated && _newSettingId > 0) {
			_settingId = _newSettingId;
			(,,,,,,, _migrated,, _newSettingId,,) = getSettingDeprecation(_settingId);
		}
		return _settingId;
	}

	/***** Internal Method *****/
	/**
	 * @dev Store setting data/state
	 * @param _settingId The ID of the setting
	 * @param _creatorNameId The nameId that created the setting
	 * @param _settingType The type of this setting. 1 => uint256, 2 => bool, 3 => address, 4 => bytes32, 5 => string
	 * @param _settingName The human-readable name of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 * @return true on success
	 */
	function _storeSettingDataState(uint256 _settingId, address _creatorNameId, uint8 _settingType, string _settingName, address _creatorTAOId, address _associatedTAOId, string _extraData) internal returns (bool) {
		// Store setting data
		SettingData storage _settingData = settingDatas[_settingId];
		_settingData.settingId = _settingId;
		_settingData.creatorNameId = _creatorNameId;
		_settingData.creatorTAOId = _creatorTAOId;
		_settingData.associatedTAOId = _associatedTAOId;
		_settingData.settingName = _settingName;
		_settingData.settingType = _settingType;
		_settingData.pendingCreate = true;
		_settingData.locked = true;
		_settingData.settingDataJSON = _extraData;

		// Store setting state
		SettingState storage _settingState = settingStates[_settingId];
		_settingState.settingId = _settingId;
		return true;
	}

	/**
	 * @dev Store setting deprecation
	 * @param _settingId The ID of the setting
	 * @param _creatorNameId The nameId that created the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _newSettingId The new settingId value to route
	 * @param _newSettingContractAddress The address of the new setting contract to route
	 * @return true on success
	 */
	function _storeSettingDeprecation(uint256 _settingId, address _creatorNameId, address _creatorTAOId, address _associatedTAOId, uint256 _newSettingId, address _newSettingContractAddress) internal returns (bool) {
		// Make sure this setting exists
		require (settingDatas[_settingId].creatorNameId != address(0) && settingDatas[_settingId].rejected == false && settingDatas[_settingId].pendingCreate == false);

		// Make sure deprecation is not yet exist for this setting Id
		require (settingDeprecations[_settingId].creatorNameId == address(0));

		// Make sure newSettingId exists
		require (settingDatas[_newSettingId].creatorNameId != address(0) && settingDatas[_newSettingId].rejected == false && settingDatas[_newSettingId].pendingCreate == false);

		// Make sure the settingType matches
		require (settingDatas[_settingId].settingType == settingDatas[_newSettingId].settingType);

		// Store setting deprecation info
		SettingDeprecation storage _settingDeprecation = settingDeprecations[_settingId];
		_settingDeprecation.settingId = _settingId;
		_settingDeprecation.creatorNameId = _creatorNameId;
		_settingDeprecation.creatorTAOId = _creatorTAOId;
		_settingDeprecation.associatedTAOId = _associatedTAOId;
		_settingDeprecation.pendingDeprecated = true;
		_settingDeprecation.locked = true;
		_settingDeprecation.pendingNewSettingId = _newSettingId;
		_settingDeprecation.pendingNewSettingContractAddress = _newSettingContractAddress;
		return true;
	}
}




/**
 * @title AOTokenInterface
 */
contract AOTokenInterface is TheAO, TokenERC20 {
	using SafeMath for uint256;

	// To differentiate denomination of AO
	uint256 public powerOfTen;

	/***** NETWORK TOKEN VARIABLES *****/
	uint256 public sellPrice;
	uint256 public buyPrice;

	mapping (address => bool) public frozenAccount;
	mapping (address => uint256) public stakedBalance;
	mapping (address => uint256) public escrowedBalance;

	// This generates a public event on the blockchain that will notify clients
	event FrozenFunds(address target, bool frozen);
	event Stake(address indexed from, uint256 value);
	event Unstake(address indexed from, uint256 value);
	event Escrow(address indexed from, address indexed to, uint256 value);
	event Unescrow(address indexed from, uint256 value);

	/**
	 * @dev Constructor function
	 */
	constructor(uint256 initialSupply, string tokenName, string tokenSymbol)
		TokenERC20(initialSupply, tokenName, tokenSymbol) public {
		powerOfTen = 0;
		decimals = 0;
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev Prevent/Allow target from sending & receiving tokens
	 * @param target Address to be frozen
	 * @param freeze Either to freeze it or not
	 */
	function freezeAccount(address target, bool freeze) public onlyTheAO {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	/**
	 * @dev Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
	 * @param newSellPrice Price users can sell to the contract
	 * @param newBuyPrice Price users can buy from the contract
	 */
	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyTheAO {
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}

	/***** NETWORK TOKEN WHITELISTED ADDRESS ONLY METHODS *****/
	/**
	 * @dev Create `mintedAmount` tokens and send it to `target`
	 * @param target Address to receive the tokens
	 * @param mintedAmount The amount of tokens it will receive
	 * @return true on success
	 */
	function mintToken(address target, uint256 mintedAmount) public inWhitelist returns (bool) {
		_mintToken(target, mintedAmount);
		return true;
	}

	/**
	 * @dev Stake `_value` tokens on behalf of `_from`
	 * @param _from The address of the target
	 * @param _value The amount to stake
	 * @return true on success
	 */
	function stakeFrom(address _from, uint256 _value) public inWhitelist returns (bool) {
		require (balanceOf[_from] >= _value);						// Check if the targeted balance is enough
		balanceOf[_from] = balanceOf[_from].sub(_value);			// Subtract from the targeted balance
		stakedBalance[_from] = stakedBalance[_from].add(_value);	// Add to the targeted staked balance
		emit Stake(_from, _value);
		return true;
	}

	/**
	 * @dev Unstake `_value` tokens on behalf of `_from`
	 * @param _from The address of the target
	 * @param _value The amount to unstake
	 * @return true on success
	 */
	function unstakeFrom(address _from, uint256 _value) public inWhitelist returns (bool) {
		require (stakedBalance[_from] >= _value);					// Check if the targeted staked balance is enough
		stakedBalance[_from] = stakedBalance[_from].sub(_value);	// Subtract from the targeted staked balance
		balanceOf[_from] = balanceOf[_from].add(_value);			// Add to the targeted balance
		emit Unstake(_from, _value);
		return true;
	}

	/**
	 * @dev Store `_value` from `_from` to `_to` in escrow
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value The amount of network tokens to put in escrow
	 * @return true on success
	 */
	function escrowFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool) {
		require (balanceOf[_from] >= _value);						// Check if the targeted balance is enough
		balanceOf[_from] = balanceOf[_from].sub(_value);			// Subtract from the targeted balance
		escrowedBalance[_to] = escrowedBalance[_to].add(_value);	// Add to the targeted escrowed balance
		emit Escrow(_from, _to, _value);
		return true;
	}

	/**
	 * @dev Create `mintedAmount` tokens and send it to `target` escrow balance
	 * @param target Address to receive the tokens
	 * @param mintedAmount The amount of tokens it will receive in escrow
	 */
	function mintTokenEscrow(address target, uint256 mintedAmount) public inWhitelist returns (bool) {
		escrowedBalance[target] = escrowedBalance[target].add(mintedAmount);
		totalSupply = totalSupply.add(mintedAmount);
		emit Escrow(this, target, mintedAmount);
		return true;
	}

	/**
	 * @dev Release escrowed `_value` from `_from`
	 * @param _from The address of the sender
	 * @param _value The amount of escrowed network tokens to be released
	 * @return true on success
	 */
	function unescrowFrom(address _from, uint256 _value) public inWhitelist returns (bool) {
		require (escrowedBalance[_from] >= _value);						// Check if the targeted escrowed balance is enough
		escrowedBalance[_from] = escrowedBalance[_from].sub(_value);	// Subtract from the targeted escrowed balance
		balanceOf[_from] = balanceOf[_from].add(_value);				// Add to the targeted balance
		emit Unescrow(_from, _value);
		return true;
	}

	/**
	 *
	 * @dev Whitelisted address remove `_value` tokens from the system irreversibly on behalf of `_from`.
	 *
	 * @param _from the address of the sender
	 * @param _value the amount of money to burn
	 */
	function whitelistBurnFrom(address _from, uint256 _value) public inWhitelist returns (bool success) {
		require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
		balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance
		totalSupply = totalSupply.sub(_value);              // Update totalSupply
		emit Burn(_from, _value);
		return true;
	}

	/**
	 * @dev Whitelisted address transfer tokens from other address
	 *
	 * Send `_value` tokens to `_to` on behalf of `_from`
	 *
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value the amount to send
	 */
	function whitelistTransferFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool success) {
		_transfer(_from, _to, _value);
		return true;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Buy tokens from contract by sending ether
	 */
	function buy() public payable {
		require (buyPrice > 0);
		uint256 amount = msg.value.div(buyPrice);
		_transfer(this, msg.sender, amount);
	}

	/**
	 * @dev Sell `amount` tokens to contract
	 * @param amount The amount of tokens to be sold
	 */
	function sell(uint256 amount) public {
		require (sellPrice > 0);
		address myAddress = this;
		require (myAddress.balance >= amount.mul(sellPrice));
		_transfer(msg.sender, this, amount);
		msg.sender.transfer(amount.mul(sellPrice));
	}

	/***** INTERNAL METHODS *****/
	/**
	 * @dev Send `_value` tokens from `_from` to `_to`
	 * @param _from The address of sender
	 * @param _to The address of the recipient
	 * @param _value The amount to send
	 */
	function _transfer(address _from, address _to, uint256 _value) internal {
		require (_to != address(0));							// Prevent transfer to 0x0 address. Use burn() instead
		require (balanceOf[_from] >= _value);					// Check if the sender has enough
		require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
		require (!frozenAccount[_from]);						// Check if sender is frozen
		require (!frozenAccount[_to]);							// Check if recipient is frozen
		uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);        // Subtract from the sender
		balanceOf[_to] = balanceOf[_to].add(_value);            // Add the same to the recipient
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}

	/**
	 * @dev Create `mintedAmount` tokens and send it to `target`
	 * @param target Address to receive the tokens
	 * @param mintedAmount The amount of tokens it will receive
	 */
	function _mintToken(address target, uint256 mintedAmount) internal {
		balanceOf[target] = balanceOf[target].add(mintedAmount);
		totalSupply = totalSupply.add(mintedAmount);
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}
}




/**
 * @title AOToken
 */
contract AOToken is AOTokenInterface {
	using SafeMath for uint256;

	address public settingTAOId;
	address public aoSettingAddress;
	// AO Dev Team addresses to receive Primordial/Network Tokens
	address public aoDevTeam1 = 0x5C63644D01Ba385eBAc5bcf2DDc1e6dBC1182b52;
	address public aoDevTeam2 = 0x156C79bf4347D1891da834Ea30662A14177CbF28;

	AOSetting internal _aoSetting;

	/***** PRIMORDIAL TOKEN VARIABLES *****/
	uint256 public primordialTotalSupply;
	uint256 public primordialTotalBought;
	uint256 public primordialSellPrice;
	uint256 public primordialBuyPrice;

	// Total available primordial token for sale 1,125,899,906,842,620 AO+
	uint256 constant public TOTAL_PRIMORDIAL_FOR_SALE = 1125899906842620;

	mapping (address => uint256) public primordialBalanceOf;
	mapping (address => mapping (address => uint256)) public primordialAllowance;

	// Mapping from owner&#39;s lot weighted multiplier to the amount of staked tokens
	mapping (address => mapping (uint256 => uint256)) public primordialStakedBalance;

	event PrimordialTransfer(address indexed from, address indexed to, uint256 value);
	event PrimordialApproval(address indexed _owner, address indexed _spender, uint256 _value);
	event PrimordialBurn(address indexed from, uint256 value);
	event PrimordialStake(address indexed from, uint256 value, uint256 weightedMultiplier);
	event PrimordialUnstake(address indexed from, uint256 value, uint256 weightedMultiplier);

	uint256 public totalLots;
	uint256 public totalBurnLots;
	uint256 public totalConvertLots;

	bool public networkExchangeEnded;

	/**
	 * Stores Lot creation data (during network exchange)
	 */
	struct Lot {
		bytes32 lotId;
		uint256 multiplier;	// This value is in 10^6, so 1000000 = 1
		address lotOwner;
		uint256 tokenAmount;
	}

	/**
	 * Struct to store info when account burns primordial token
	 */
	struct BurnLot {
		bytes32 burnLotId;
		address lotOwner;
		uint256 tokenAmount;
	}

	/**
	 * Struct to store info when account converts network token to primordial token
	 */
	struct ConvertLot {
		bytes32 convertLotId;
		address lotOwner;
		uint256 tokenAmount;
	}

	// Mapping from Lot ID to Lot object
	mapping (bytes32 => Lot) internal lots;

	// Mapping from Burn Lot ID to BurnLot object
	mapping (bytes32 => BurnLot) internal burnLots;

	// Mapping from Convert Lot ID to ConvertLot object
	mapping (bytes32 => ConvertLot) internal convertLots;

	// Mapping from owner to list of owned lot IDs
	mapping (address => bytes32[]) internal ownedLots;

	// Mapping from owner to list of owned burn lot IDs
	mapping (address => bytes32[]) internal ownedBurnLots;

	// Mapping from owner to list of owned convert lot IDs
	mapping (address => bytes32[]) internal ownedConvertLots;

	// Mapping from owner to his/her current weighted multiplier
	mapping (address => uint256) internal ownerWeightedMultiplier;

	// Mapping from owner to his/her max multiplier (multiplier of account&#39;s first Lot)
	mapping (address => uint256) internal ownerMaxMultiplier;

	// Event to be broadcasted to public when a lot is created
	// multiplier value is in 10^6 to account for 6 decimal points
	event LotCreation(address indexed lotOwner, bytes32 indexed lotId, uint256 multiplier, uint256 primordialTokenAmount, uint256 networkTokenBonusAmount);

	// Event to be broadcasted to public when burn lot is created (when account burns primordial tokens)
	event BurnLotCreation(address indexed lotOwner, bytes32 indexed burnLotId, uint256 burnTokenAmount, uint256 multiplierAfterBurn);

	// Event to be broadcasted to public when convert lot is created (when account convert network tokens to primordial tokens)
	event ConvertLotCreation(address indexed lotOwner, bytes32 indexed convertLotId, uint256 convertTokenAmount, uint256 multiplierAfterBurn);

	/**
	 * @dev Constructor function
	 */
	constructor(uint256 initialSupply, string tokenName, string tokenSymbol, address _settingTAOId, address _aoSettingAddress)
		AOTokenInterface(initialSupply, tokenName, tokenSymbol) public {
		settingTAOId = _settingTAOId;
		aoSettingAddress = _aoSettingAddress;
		_aoSetting = AOSetting(_aoSettingAddress);

		powerOfTen = 0;
		decimals = 0;
		setPrimordialPrices(0, 10000); // Set Primordial buy price to 10000 Wei/token
	}

	/**
	 * @dev Checks if buyer can buy primordial token
	 */
	modifier canBuyPrimordial(uint256 _sentAmount) {
		require (networkExchangeEnded == false && primordialTotalBought < TOTAL_PRIMORDIAL_FOR_SALE && primordialBuyPrice > 0 && _sentAmount > 0);
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev Set AO Dev team addresses to receive Primordial/Network tokens during network exchange
	 * @param _aoDevTeam1 The first AO dev team address
	 * @param _aoDevTeam2 The second AO dev team address
	 */
	function setAODevTeamAddresses(address _aoDevTeam1, address _aoDevTeam2) public onlyTheAO {
		aoDevTeam1 = _aoDevTeam1;
		aoDevTeam2 = _aoDevTeam2;
	}

	/***** PRIMORDIAL TOKEN The AO ONLY METHODS *****/
	/**
	 * @dev Allow users to buy Primordial tokens for `newBuyPrice` eth and sell Primordial tokens for `newSellPrice` eth
	 * @param newPrimordialSellPrice Price users can sell to the contract
	 * @param newPrimordialBuyPrice Price users can buy from the contract
	 */
	function setPrimordialPrices(uint256 newPrimordialSellPrice, uint256 newPrimordialBuyPrice) public onlyTheAO {
		primordialSellPrice = newPrimordialSellPrice;
		primordialBuyPrice = newPrimordialBuyPrice;
	}

	/***** PRIMORDIAL TOKEN WHITELISTED ADDRESS ONLY METHODS *****/
	/**
	 * @dev Stake `_value` Primordial tokens at `_weightedMultiplier ` multiplier on behalf of `_from`
	 * @param _from The address of the target
	 * @param _value The amount of Primordial tokens to stake
	 * @param _weightedMultiplier The weighted multiplier of the Primordial tokens
	 * @return true on success
	 */
	function stakePrimordialTokenFrom(address _from, uint256 _value, uint256 _weightedMultiplier) public inWhitelist returns (bool) {
		// Check if the targeted balance is enough
		require (primordialBalanceOf[_from] >= _value);
		// Make sure the weighted multiplier is the same as account&#39;s current weighted multiplier
		require (_weightedMultiplier == ownerWeightedMultiplier[_from]);
		// Subtract from the targeted balance
		primordialBalanceOf[_from] = primordialBalanceOf[_from].sub(_value);
		// Add to the targeted staked balance
		primordialStakedBalance[_from][_weightedMultiplier] = primordialStakedBalance[_from][_weightedMultiplier].add(_value);
		emit PrimordialStake(_from, _value, _weightedMultiplier);
		return true;
	}

	/**
	 * @dev Unstake `_value` Primordial tokens at `_weightedMultiplier` on behalf of `_from`
	 * @param _from The address of the target
	 * @param _value The amount to unstake
	 * @param _weightedMultiplier The weighted multiplier of the Primordial tokens
	 * @return true on success
	 */
	function unstakePrimordialTokenFrom(address _from, uint256 _value, uint256 _weightedMultiplier) public inWhitelist returns (bool) {
		// Check if the targeted staked balance is enough
		require (primordialStakedBalance[_from][_weightedMultiplier] >= _value);
		// Subtract from the targeted staked balance
		primordialStakedBalance[_from][_weightedMultiplier] = primordialStakedBalance[_from][_weightedMultiplier].sub(_value);
		// Add to the targeted balance
		primordialBalanceOf[_from] = primordialBalanceOf[_from].add(_value);
		emit PrimordialUnstake(_from, _value, _weightedMultiplier);
		return true;
	}

	/**
	 * @dev Send `_value` primordial tokens to `_to` on behalf of `_from`
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value The amount to send
	 * @return true on success
	 */
	function whitelistTransferPrimordialTokenFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool) {
		bytes32 _createdLotId = _createWeightedMultiplierLot(_to, _value, ownerWeightedMultiplier[_from]);
		Lot memory _lot = lots[_createdLotId];

		// Make sure the new lot is created successfully
		require (_lot.lotOwner == _to);

		// Update the weighted multiplier of the recipient
		ownerWeightedMultiplier[_to] = AOLibrary.calculateWeightedMultiplier(ownerWeightedMultiplier[_to], primordialBalanceOf[_to], ownerWeightedMultiplier[_from], _value);

		// Transfer the Primordial tokens
		require (_transferPrimordialToken(_from, _to, _value));
		emit LotCreation(_lot.lotOwner, _lot.lotId, _lot.multiplier, _lot.tokenAmount, 0);
		return true;
	}

	/***** PUBLIC METHODS *****/
	/***** Primordial TOKEN PUBLIC METHODS *****/
	/**
	 * @dev Buy Primordial tokens from contract by sending ether
	 */
	function buyPrimordialToken() public payable canBuyPrimordial(msg.value) {
		(uint256 tokenAmount, uint256 remainderBudget, bool shouldEndNetworkExchange) = _calculateTokenAmountAndRemainderBudget(msg.value);
		require (tokenAmount > 0);

		// Ends network exchange if necessary
		if (shouldEndNetworkExchange) {
			networkExchangeEnded = true;
		}

		// Send the primordial token to buyer and reward AO devs
		_sendPrimordialTokenAndRewardDev(tokenAmount, msg.sender);

		// Send remainder budget back to buyer if exist
		if (remainderBudget > 0) {
			msg.sender.transfer(remainderBudget);
		}
	}

	/**
	 * @dev Send `_value` Primordial tokens to `_to` from your account
	 * @param _to The address of the recipient
	 * @param _value The amount to send
	 * @return true on success
	 */
	function transferPrimordialToken(address _to, uint256 _value) public returns (bool success) {
		bytes32 _createdLotId = _createWeightedMultiplierLot(_to, _value, ownerWeightedMultiplier[msg.sender]);
		Lot memory _lot = lots[_createdLotId];

		// Make sure the new lot is created successfully
		require (_lot.lotOwner == _to);

		// Update the weighted multiplier of the recipient
		ownerWeightedMultiplier[_to] = AOLibrary.calculateWeightedMultiplier(ownerWeightedMultiplier[_to], primordialBalanceOf[_to], ownerWeightedMultiplier[msg.sender], _value);

		// Transfer the Primordial tokens
		require (_transferPrimordialToken(msg.sender, _to, _value));
		emit LotCreation(_lot.lotOwner, _lot.lotId, _lot.multiplier, _lot.tokenAmount, 0);
		return true;
	}

	/**
	 * @dev Send `_value` Primordial tokens to `_to` from `_from`
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value The amount to send
	 * @return true on success
	 */
	function transferPrimordialTokenFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require (_value <= primordialAllowance[_from][msg.sender]);
		primordialAllowance[_from][msg.sender] = primordialAllowance[_from][msg.sender].sub(_value);

		bytes32 _createdLotId = _createWeightedMultiplierLot(_to, _value, ownerWeightedMultiplier[_from]);
		Lot memory _lot = lots[_createdLotId];

		// Make sure the new lot is created successfully
		require (_lot.lotOwner == _to);

		// Update the weighted multiplier of the recipient
		ownerWeightedMultiplier[_to] = AOLibrary.calculateWeightedMultiplier(ownerWeightedMultiplier[_to], primordialBalanceOf[_to], ownerWeightedMultiplier[_from], _value);

		// Transfer the Primordial tokens
		require (_transferPrimordialToken(_from, _to, _value));
		emit LotCreation(_lot.lotOwner, _lot.lotId, _lot.multiplier, _lot.tokenAmount, 0);
		return true;
	}

	/**
	 * @dev Allows `_spender` to spend no more than `_value` Primordial tokens in your behalf
	 * @param _spender The address authorized to spend
	 * @param _value The max amount they can spend
	 * @return true on success
	 */
	function approvePrimordialToken(address _spender, uint256 _value) public returns (bool success) {
		primordialAllowance[msg.sender][_spender] = _value;
		emit PrimordialApproval(msg.sender, _spender, _value);
		return true;
	}

	/**
	 * @dev Allows `_spender` to spend no more than `_value` Primordial tokens in your behalf, and then ping the contract about it
	 * @param _spender The address authorized to spend
	 * @param _value The max amount they can spend
	 * @param _extraData some extra information to send to the approved contract
	 * @return true on success
	 */
	function approvePrimordialTokenAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approvePrimordialToken(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	/**
	 * @dev Remove `_value` Primordial tokens from the system irreversibly
	 *		and re-weight the account&#39;s multiplier after burn
	 * @param _value The amount to burn
	 * @return true on success
	 */
	function burnPrimordialToken(uint256 _value) public returns (bool success) {
		require (primordialBalanceOf[msg.sender] >= _value);
		require (calculateMaximumBurnAmount(msg.sender) >= _value);

		// Update the account&#39;s multiplier
		ownerWeightedMultiplier[msg.sender] = calculateMultiplierAfterBurn(msg.sender, _value);
		primordialBalanceOf[msg.sender] = primordialBalanceOf[msg.sender].sub(_value);
		primordialTotalSupply = primordialTotalSupply.sub(_value);

		// Store burn lot info
		_createBurnLot(msg.sender, _value);
		emit PrimordialBurn(msg.sender, _value);
		return true;
	}

	/**
	 * @dev Remove `_value` Primordial tokens from the system irreversibly on behalf of `_from`
	 *		and re-weight `_from`&#39;s multiplier after burn
	 * @param _from The address of sender
	 * @param _value The amount to burn
	 * @return true on success
	 */
	function burnPrimordialTokenFrom(address _from, uint256 _value) public returns (bool success) {
		require (primordialBalanceOf[_from] >= _value);
		require (primordialAllowance[_from][msg.sender] >= _value);
		require (calculateMaximumBurnAmount(_from) >= _value);

		// Update `_from`&#39;s multiplier
		ownerWeightedMultiplier[_from] = calculateMultiplierAfterBurn(_from, _value);
		primordialBalanceOf[_from] = primordialBalanceOf[_from].sub(_value);
		primordialAllowance[_from][msg.sender] = primordialAllowance[_from][msg.sender].sub(_value);
		primordialTotalSupply = primordialTotalSupply.sub(_value);

		// Store burn lot info
		_createBurnLot(_from, _value);
		emit PrimordialBurn(_from, _value);
		return true;
	}

	/**
	 * @dev Return all lot IDs owned by an address
	 * @param _lotOwner The address of the lot owner
	 * @return array of lot IDs
	 */
	function lotIdsByAddress(address _lotOwner) public view returns (bytes32[]) {
		return ownedLots[_lotOwner];
	}

	/**
	 * @dev Return the total lots owned by an address
	 * @param _lotOwner The address of the lot owner
	 * @return total lots owner by the address
	 */
	function totalLotsByAddress(address _lotOwner) public view returns (uint256) {
		return ownedLots[_lotOwner].length;
	}

	/**
	 * @dev Return the lot information at a given index of the lots list of the requested owner
	 * @param _lotOwner The address owning the lots list to be accessed
	 * @param _index uint256 representing the index to be accessed of the requested lots list
	 * @return id of the lot
	 * @return The address of the lot owner
	 * @return multiplier of the lot in (10 ** 6)
	 * @return Primordial token amount in the lot
	 */
	function lotOfOwnerByIndex(address _lotOwner, uint256 _index) public view returns (bytes32, address, uint256, uint256) {
		require (_index < ownedLots[_lotOwner].length);
		Lot memory _lot = lots[ownedLots[_lotOwner][_index]];
		return (_lot.lotId, _lot.lotOwner, _lot.multiplier, _lot.tokenAmount);
	}

	/**
	 * @dev Return the lot information at a given ID
	 * @param _lotId The lot ID in question
	 * @return id of the lot
	 * @return The lot owner address
	 * @return multiplier of the lot in (10 ** 6)
	 * @return Primordial token amount in the lot
	 */
	function lotById(bytes32 _lotId) public view returns (bytes32, address, uint256, uint256) {
		Lot memory _lot = lots[_lotId];
		return (_lot.lotId, _lot.lotOwner, _lot.multiplier, _lot.tokenAmount);
	}

	/**
	 * @dev Return all Burn Lot IDs owned by an address
	 * @param _lotOwner The address of the burn lot owner
	 * @return array of Burn Lot IDs
	 */
	function burnLotIdsByAddress(address _lotOwner) public view returns (bytes32[]) {
		return ownedBurnLots[_lotOwner];
	}

	/**
	 * @dev Return the total burn lots owned by an address
	 * @param _lotOwner The address of the burn lot owner
	 * @return total burn lots owner by the address
	 */
	function totalBurnLotsByAddress(address _lotOwner) public view returns (uint256) {
		return ownedBurnLots[_lotOwner].length;
	}

	/**
	 * @dev Return the burn lot information at a given ID
	 * @param _burnLotId The burn lot ID in question
	 * @return id of the lot
	 * @return The address of the burn lot owner
	 * @return Primordial token amount in the burn lot
	 */
	function burnLotById(bytes32 _burnLotId) public view returns (bytes32, address, uint256) {
		BurnLot memory _burnLot = burnLots[_burnLotId];
		return (_burnLot.burnLotId, _burnLot.lotOwner, _burnLot.tokenAmount);
	}

	/**
	 * @dev Return all Convert Lot IDs owned by an address
	 * @param _lotOwner The address of the convert lot owner
	 * @return array of Convert Lot IDs
	 */
	function convertLotIdsByAddress(address _lotOwner) public view returns (bytes32[]) {
		return ownedConvertLots[_lotOwner];
	}

	/**
	 * @dev Return the total convert lots owned by an address
	 * @param _lotOwner The address of the convert lot owner
	 * @return total convert lots owner by the address
	 */
	function totalConvertLotsByAddress(address _lotOwner) public view returns (uint256) {
		return ownedConvertLots[_lotOwner].length;
	}

	/**
	 * @dev Return the convert lot information at a given ID
	 * @param _convertLotId The convert lot ID in question
	 * @return id of the lot
	 * @return The address of the convert lot owner
	 * @return Primordial token amount in the convert lot
	 */
	function convertLotById(bytes32 _convertLotId) public view returns (bytes32, address, uint256) {
		ConvertLot memory _convertLot = convertLots[_convertLotId];
		return (_convertLot.convertLotId, _convertLot.lotOwner, _convertLot.tokenAmount);
	}

	/**
	 * @dev Return the average weighted multiplier of all lots owned by an address
	 * @param _lotOwner The address of the lot owner
	 * @return the weighted multiplier of the address (in 10 ** 6)
	 */
	function weightedMultiplierByAddress(address _lotOwner) public view returns (uint256) {
		return ownerWeightedMultiplier[_lotOwner];
	}

	/**
	 * @dev Return the max multiplier of an address
	 * @param _target The address to query
	 * @return the max multiplier of the address (in 10 ** 6)
	 */
	function maxMultiplierByAddress(address _target) public view returns (uint256) {
		return (ownedLots[_target].length > 0) ? ownerMaxMultiplier[_target] : 0;
	}

	/**
	 * @dev Calculate the primordial token multiplier, bonus network token percentage, and the
	 *		bonus network token amount on a given lot when someone purchases primordial token
	 *		during network exchange
	 * @param _purchaseAmount The amount of primordial token intended to be purchased
	 * @return The multiplier in (10 ** 6)
	 * @return The bonus percentage
	 * @return The amount of network token as bonus
	 */
	function calculateMultiplierAndBonus(uint256 _purchaseAmount) public view returns (uint256, uint256, uint256) {
		(uint256 startingPrimordialMultiplier, uint256 endingPrimordialMultiplier, uint256 startingNetworkTokenBonusMultiplier, uint256 endingNetworkTokenBonusMultiplier) = _getSettingVariables();
		return (
			AOLibrary.calculatePrimordialMultiplier(_purchaseAmount, TOTAL_PRIMORDIAL_FOR_SALE, primordialTotalBought, startingPrimordialMultiplier, endingPrimordialMultiplier),
			AOLibrary.calculateNetworkTokenBonusPercentage(_purchaseAmount, TOTAL_PRIMORDIAL_FOR_SALE, primordialTotalBought, startingNetworkTokenBonusMultiplier, endingNetworkTokenBonusMultiplier),
			AOLibrary.calculateNetworkTokenBonusAmount(_purchaseAmount, TOTAL_PRIMORDIAL_FOR_SALE, primordialTotalBought, startingNetworkTokenBonusMultiplier, endingNetworkTokenBonusMultiplier)
		);
	}

	/**
	 * @dev Calculate the maximum amount of Primordial an account can burn
	 * @param _account The address of the account
	 * @return The maximum primordial token amount to burn
	 */
	function calculateMaximumBurnAmount(address _account) public view returns (uint256) {
		return AOLibrary.calculateMaximumBurnAmount(primordialBalanceOf[_account], ownerWeightedMultiplier[_account], ownerMaxMultiplier[_account]);
	}

	/**
	 * @dev Calculate account&#39;s new multiplier after burn `_amountToBurn` primordial tokens
	 * @param _account The address of the account
	 * @param _amountToBurn The amount of primordial token to burn
	 * @return The new multiplier in (10 ** 6)
	 */
	function calculateMultiplierAfterBurn(address _account, uint256 _amountToBurn) public view returns (uint256) {
		require (calculateMaximumBurnAmount(_account) >= _amountToBurn);
		return AOLibrary.calculateMultiplierAfterBurn(primordialBalanceOf[_account], ownerWeightedMultiplier[_account], _amountToBurn);
	}

	/**
	 * @dev Calculate account&#39;s new multiplier after converting `amountToConvert` network token to primordial token
	 * @param _account The address of the account
	 * @param _amountToConvert The amount of network token to convert
	 * @return The new multiplier in (10 ** 6)
	 */
	function calculateMultiplierAfterConversion(address _account, uint256 _amountToConvert) public view returns (uint256) {
		return AOLibrary.calculateMultiplierAfterConversion(primordialBalanceOf[_account], ownerWeightedMultiplier[_account], _amountToConvert);
	}

	/**
	 * @dev Convert `_value` of network tokens to primordial tokens
	 *		and re-weight the account&#39;s multiplier after conversion
	 * @param _value The amount to convert
	 * @return true on success
	 */
	function convertToPrimordial(uint256 _value) public returns (bool success) {
		require (balanceOf[msg.sender] >= _value);

		// Update the account&#39;s multiplier
		ownerWeightedMultiplier[msg.sender] = calculateMultiplierAfterConversion(msg.sender, _value);
		// Burn network token
		burn(_value);
		// mint primordial token
		_mintPrimordialToken(msg.sender, _value);

		// Store convert lot info
		totalConvertLots++;

		// Generate convert lot Id
		bytes32 convertLotId = keccak256(abi.encodePacked(this, msg.sender, totalConvertLots));

		// Make sure no one owns this lot yet
		require (convertLots[convertLotId].lotOwner == address(0));

		ConvertLot storage convertLot = convertLots[convertLotId];
		convertLot.convertLotId = convertLotId;
		convertLot.lotOwner = msg.sender;
		convertLot.tokenAmount = _value;
		ownedConvertLots[msg.sender].push(convertLotId);
		emit ConvertLotCreation(convertLot.lotOwner, convertLot.convertLotId, convertLot.tokenAmount, ownerWeightedMultiplier[convertLot.lotOwner]);
		return true;
	}

	/***** NETWORK TOKEN & PRIMORDIAL TOKEN METHODS *****/
	/**
	 * @dev Send `_value` network tokens and `_primordialValue` primordial tokens to `_to` from your account
	 * @param _to The address of the recipient
	 * @param _value The amount of network tokens to send
	 * @param _primordialValue The amount of Primordial tokens to send
	 * @return true on success
	 */
	function transferTokens(address _to, uint256 _value, uint256 _primordialValue) public returns (bool success) {
		require (super.transfer(_to, _value));
		require (transferPrimordialToken(_to, _primordialValue));
		return true;
	}

	/**
	 * @dev Send `_value` network tokens and `_primordialValue` primordial tokens to `_to` from `_from`
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value The amount of network tokens tokens to send
	 * @param _primordialValue The amount of Primordial tokens to send
	 * @return true on success
	 */
	function transferTokensFrom(address _from, address _to, uint256 _value, uint256 _primordialValue) public returns (bool success) {
		require (super.transferFrom(_from, _to, _value));
		require (transferPrimordialTokenFrom(_from, _to, _primordialValue));
		return true;
	}

	/**
	 * @dev Allows `_spender` to spend no more than `_value` network tokens and `_primordialValue` Primordial tokens in your behalf
	 * @param _spender The address authorized to spend
	 * @param _value The max amount of network tokens they can spend
	 * @param _primordialValue The max amount of network tokens they can spend
	 * @return true on success
	 */
	function approveTokens(address _spender, uint256 _value, uint256 _primordialValue) public returns (bool success) {
		require (super.approve(_spender, _value));
		require (approvePrimordialToken(_spender, _primordialValue));
		return true;
	}

	/**
	 * @dev Allows `_spender` to spend no more than `_value` network tokens and `_primordialValue` Primordial tokens in your behalf, and then ping the contract about it
	 * @param _spender The address authorized to spend
	 * @param _value The max amount of network tokens they can spend
	 * @param _primordialValue The max amount of Primordial Tokens they can spend
	 * @param _extraData some extra information to send to the approved contract
	 * @return true on success
	 */
	function approveTokensAndCall(address _spender, uint256 _value, uint256 _primordialValue, bytes _extraData) public returns (bool success) {
		require (super.approveAndCall(_spender, _value, _extraData));
		require (approvePrimordialTokenAndCall(_spender, _primordialValue, _extraData));
		return true;
	}

	/**
	 * @dev Remove `_value` network tokens and `_primordialValue` Primordial tokens from the system irreversibly
	 * @param _value The amount of network tokens to burn
	 * @param _primordialValue The amount of Primordial tokens to burn
	 * @return true on success
	 */
	function burnTokens(uint256 _value, uint256 _primordialValue) public returns (bool success) {
		require (super.burn(_value));
		require (burnPrimordialToken(_primordialValue));
		return true;
	}

	/**
	 * @dev Remove `_value` network tokens and `_primordialValue` Primordial tokens from the system irreversibly on behalf of `_from`
	 * @param _from The address of sender
	 * @param _value The amount of network tokens to burn
	 * @param _primordialValue The amount of Primordial tokens to burn
	 * @return true on success
	 */
	function burnTokensFrom(address _from, uint256 _value, uint256 _primordialValue) public returns (bool success) {
		require (super.burnFrom(_from, _value));
		require (burnPrimordialTokenFrom(_from, _primordialValue));
		return true;
	}

	/***** INTERNAL METHODS *****/
	/***** PRIMORDIAL TOKEN INTERNAL METHODS *****/
	/**
	 * @dev Calculate the amount of token the buyer will receive and remaining budget if exist
	 *		when he/she buys primordial token
	 * @param _budget The amount of ETH sent by buyer
	 * @return uint256 of the tokenAmount the buyer will receiver
	 * @return uint256 of the remaining budget, if exist
	 * @return bool whether or not the network exchange should end
	 */
	function _calculateTokenAmountAndRemainderBudget(uint256 _budget) internal view returns (uint256, uint256, bool) {
		// Calculate the amount of tokens
		uint256 tokenAmount = _budget.div(primordialBuyPrice);

		// If we need to return ETH to the buyer, in the case
		// where the buyer sends more ETH than available primordial token to be purchased
		uint256 remainderEth = 0;

		// Make sure primordialTotalBought is not overflowing
		bool shouldEndNetworkExchange = false;
		if (primordialTotalBought.add(tokenAmount) >= TOTAL_PRIMORDIAL_FOR_SALE) {
			tokenAmount = TOTAL_PRIMORDIAL_FOR_SALE.sub(primordialTotalBought);
			shouldEndNetworkExchange = true;
			remainderEth = msg.value.sub(tokenAmount.mul(primordialBuyPrice));
		}
		return (tokenAmount, remainderEth, shouldEndNetworkExchange);
	}

	/**
	 * @dev Actually sending the primordial token to buyer and reward AO devs accordingly
	 * @param tokenAmount The amount of primordial token to be sent to buyer
	 * @param to The recipient of the token
	 */
	function _sendPrimordialTokenAndRewardDev(uint256 tokenAmount, address to) internal {
		(uint256 startingPrimordialMultiplier,, uint256 startingNetworkTokenBonusMultiplier, uint256 endingNetworkTokenBonusMultiplier) = _getSettingVariables();

		// Update primordialTotalBought
		(uint256 multiplier, uint256 networkTokenBonusPercentage, uint256 networkTokenBonusAmount) = calculateMultiplierAndBonus(tokenAmount);
		primordialTotalBought = primordialTotalBought.add(tokenAmount);
		_createPrimordialLot(to, tokenAmount, multiplier, networkTokenBonusAmount);

		// Calculate The AO and AO Dev Team&#39;s portion of Primordial and Network Token Bonus
		uint256 inverseMultiplier = startingPrimordialMultiplier.sub(multiplier); // Inverse of the buyer&#39;s multiplier
		uint256 theAONetworkTokenBonusAmount = (startingNetworkTokenBonusMultiplier.sub(networkTokenBonusPercentage).add(endingNetworkTokenBonusMultiplier)).mul(tokenAmount).div(AOLibrary.PERCENTAGE_DIVISOR());
		if (aoDevTeam1 != address(0)) {
			_createPrimordialLot(aoDevTeam1, tokenAmount.div(2), inverseMultiplier, theAONetworkTokenBonusAmount.div(2));
		}
		if (aoDevTeam2 != address(0)) {
			_createPrimordialLot(aoDevTeam2, tokenAmount.div(2), inverseMultiplier, theAONetworkTokenBonusAmount.div(2));
		}
		_mintToken(theAO, theAONetworkTokenBonusAmount);
	}

	/**
	 * @dev Create a lot with `primordialTokenAmount` of primordial tokens with `_multiplier` for an `account`
	 *		during network exchange, and reward `_networkTokenBonusAmount` if exist
	 * @param _account Address of the lot owner
	 * @param _primordialTokenAmount The amount of primordial tokens to be stored in the lot
	 * @param _multiplier The multiplier for this lot in (10 ** 6)
	 * @param _networkTokenBonusAmount The network token bonus amount
	 */
	function _createPrimordialLot(address _account, uint256 _primordialTokenAmount, uint256 _multiplier, uint256 _networkTokenBonusAmount) internal {
		totalLots++;

		// Generate lotId
		bytes32 lotId = keccak256(abi.encodePacked(this, _account, totalLots));

		// Make sure no one owns this lot yet
		require (lots[lotId].lotOwner == address(0));

		Lot storage lot = lots[lotId];
		lot.lotId = lotId;
		lot.multiplier = _multiplier;
		lot.lotOwner = _account;
		lot.tokenAmount = _primordialTokenAmount;
		ownedLots[_account].push(lotId);
		ownerWeightedMultiplier[_account] = AOLibrary.calculateWeightedMultiplier(ownerWeightedMultiplier[_account], primordialBalanceOf[_account], lot.multiplier, lot.tokenAmount);
		// If this is the first lot, set this as the max multiplier of the account
		if (ownedLots[_account].length == 1) {
			ownerMaxMultiplier[_account] = lot.multiplier;
		}
		_mintPrimordialToken(_account, lot.tokenAmount);
		_mintToken(_account, _networkTokenBonusAmount);

		emit LotCreation(lot.lotOwner, lot.lotId, lot.multiplier, lot.tokenAmount, _networkTokenBonusAmount);
	}

	/**
	 * @dev Create `mintedAmount` Primordial tokens and send it to `target`
	 * @param target Address to receive the Primordial tokens
	 * @param mintedAmount The amount of Primordial tokens it will receive
	 */
	function _mintPrimordialToken(address target, uint256 mintedAmount) internal {
		primordialBalanceOf[target] = primordialBalanceOf[target].add(mintedAmount);
		primordialTotalSupply = primordialTotalSupply.add(mintedAmount);
		emit PrimordialTransfer(0, this, mintedAmount);
		emit PrimordialTransfer(this, target, mintedAmount);
	}

	/**
	 * @dev Create a lot with `tokenAmount` of tokens at `weightedMultiplier` for an `account`
	 * @param _account Address of lot owner
	 * @param _tokenAmount The amount of tokens
	 * @param _weightedMultiplier The multiplier of the lot (in 10^6)
	 * @return bytes32 of new created lot ID
	 */
	function _createWeightedMultiplierLot(address _account, uint256 _tokenAmount, uint256 _weightedMultiplier) internal returns (bytes32) {
		require (_account != address(0));
		require (_tokenAmount > 0);

		totalLots++;

		// Generate lotId
		bytes32 lotId = keccak256(abi.encodePacked(this, _account, totalLots));

		// Make sure no one owns this lot yet
		require (lots[lotId].lotOwner == address(0));

		Lot storage lot = lots[lotId];
		lot.lotId = lotId;
		lot.multiplier = _weightedMultiplier;
		lot.lotOwner = _account;
		lot.tokenAmount = _tokenAmount;
		ownedLots[_account].push(lotId);
		// If this is the first lot, set this as the max multiplier of the account
		if (ownedLots[_account].length == 1) {
			ownerMaxMultiplier[_account] = lot.multiplier;
		}
		return lotId;
	}

	/**
	 * @dev Send `_value` Primordial tokens from `_from` to `_to`
	 * @param _from The address of sender
	 * @param _to The address of the recipient
	 * @param _value The amount to send
	 */
	function _transferPrimordialToken(address _from, address _to, uint256 _value) internal returns (bool) {
		require (_to != address(0));									// Prevent transfer to 0x0 address. Use burn() instead
		require (primordialBalanceOf[_from] >= _value);						// Check if the sender has enough
		require (primordialBalanceOf[_to].add(_value) >= primordialBalanceOf[_to]);	// Check for overflows
		require (!frozenAccount[_from]);								// Check if sender is frozen
		require (!frozenAccount[_to]);									// Check if recipient is frozen
		uint256 previousBalances = primordialBalanceOf[_from].add(primordialBalanceOf[_to]);
		primordialBalanceOf[_from] = primordialBalanceOf[_from].sub(_value);			// Subtract from the sender
		primordialBalanceOf[_to] = primordialBalanceOf[_to].add(_value);				// Add the same to the recipient
		emit PrimordialTransfer(_from, _to, _value);
		assert(primordialBalanceOf[_from].add(primordialBalanceOf[_to]) == previousBalances);
		return true;
	}

	/**
	 * @dev Store burn lot information
	 * @param _account The address of the account
	 * @param _tokenAmount The amount of primordial tokens to burn
	 */
	function _createBurnLot(address _account, uint256 _tokenAmount) internal {
		totalBurnLots++;

		// Generate burn lot Id
		bytes32 burnLotId = keccak256(abi.encodePacked(this, _account, totalBurnLots));

		// Make sure no one owns this lot yet
		require (burnLots[burnLotId].lotOwner == address(0));

		BurnLot storage burnLot = burnLots[burnLotId];
		burnLot.burnLotId = burnLotId;
		burnLot.lotOwner = _account;
		burnLot.tokenAmount = _tokenAmount;
		ownedBurnLots[_account].push(burnLotId);
		emit BurnLotCreation(burnLot.lotOwner, burnLot.burnLotId, burnLot.tokenAmount, ownerWeightedMultiplier[burnLot.lotOwner]);
	}

	/**
	 * @dev Get setting variables
	 * @return startingPrimordialMultiplier The starting multiplier used to calculate primordial token
	 * @return endingPrimordialMultiplier The ending multiplier used to calculate primordial token
	 * @return startingNetworkTokenBonusMultiplier The starting multiplier used to calculate network token bonus
	 * @return endingNetworkTokenBonusMultiplier The ending multiplier used to calculate network token bonus
	 */
	function _getSettingVariables() internal view returns (uint256, uint256, uint256, uint256) {
		(uint256 startingPrimordialMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;startingPrimordialMultiplier&#39;);
		(uint256 endingPrimordialMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;endingPrimordialMultiplier&#39;);

		(uint256 startingNetworkTokenBonusMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;startingNetworkTokenBonusMultiplier&#39;);
		(uint256 endingNetworkTokenBonusMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;endingNetworkTokenBonusMultiplier&#39;);

		return (startingPrimordialMultiplier, endingPrimordialMultiplier, startingNetworkTokenBonusMultiplier, endingNetworkTokenBonusMultiplier);
	}
}





















/**
 * @title AOTreasury
 *
 * The purpose of this contract is to list all of the valid denominations of AO Token and do the conversion between denominations
 */
contract AOTreasury is TheAO {
	using SafeMath for uint256;

	bool public paused;
	bool public killed;

	struct Denomination {
		bytes8 name;
		address denominationAddress;
	}

	// Mapping from denomination index to Denomination object
	// The list is in order from lowest denomination to highest denomination
	// i.e, denominations[1] is the base denomination
	mapping (uint256 => Denomination) internal denominations;

	// Mapping from denomination ID to index of denominations
	mapping (bytes8 => uint256) internal denominationIndex;

	uint256 public totalDenominations;

	// Event to be broadcasted to public when a token exchange happens
	event Exchange(address indexed account, uint256 amount, bytes8 fromDenominationName, bytes8 toDenominationName);

	// Event to be broadcasted to public when emergency mode is triggered
	event EscapeHatch();

	/**
	 * @dev Constructor function
	 */
	constructor() public {}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Checks if contract is currently active
	 */
	modifier isContractActive {
		require (paused == false && killed == false);
		_;
	}

	/**
	 * @dev Checks if denomination is valid
	 */
	modifier isValidDenomination(bytes8 denominationName) {
		require (denominationIndex[denominationName] > 0 && denominations[denominationIndex[denominationName]].denominationAddress != address(0));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO pauses/unpauses contract
	 * @param _paused Either to pause contract or not
	 */
	function setPaused(bool _paused) public onlyTheAO {
		paused = _paused;
	}

	/**
	 * @dev The AO triggers emergency mode.
	 *
	 */
	function escapeHatch() public onlyTheAO {
		require (killed == false);
		killed = true;
		emit EscapeHatch();
	}

	/**
	 * @dev The AO adds denomination and the contract address associated with it
	 * @param denominationName The name of the denomination, i.e ao, kilo, mega, etc.
	 * @param denominationAddress The address of the denomination token
	 * @return true on success
	 */
	function addDenomination(bytes8 denominationName, address denominationAddress) public onlyTheAO returns (bool) {
		require (denominationName.length != 0);
		require (denominationAddress != address(0));
		require (denominationIndex[denominationName] == 0);
		totalDenominations++;
		// Make sure the new denomination is higher than the previous
		if (totalDenominations > 1) {
			AOTokenInterface _lastDenominationToken = AOTokenInterface(denominations[totalDenominations - 1].denominationAddress);
			AOTokenInterface _newDenominationToken = AOTokenInterface(denominationAddress);
			require (_newDenominationToken.powerOfTen() > _lastDenominationToken.powerOfTen());
		}
		denominations[totalDenominations].name = denominationName;
		denominations[totalDenominations].denominationAddress = denominationAddress;
		denominationIndex[denominationName] = totalDenominations;
		return true;
	}

	/**
	 * @dev The AO updates denomination address or activates/deactivates the denomination
	 * @param denominationName The name of the denomination, i.e ao, kilo, mega, etc.
	 * @param denominationAddress The address of the denomination token
	 * @return true on success
	 */
	function updateDenomination(bytes8 denominationName, address denominationAddress) public onlyTheAO returns (bool) {
		require (denominationName.length != 0);
		require (denominationIndex[denominationName] > 0);
		require (denominationAddress != address(0));
		uint256 _denominationNameIndex = denominationIndex[denominationName];
		AOTokenInterface _newDenominationToken = AOTokenInterface(denominationAddress);
		if (_denominationNameIndex > 1) {
			AOTokenInterface _prevDenominationToken = AOTokenInterface(denominations[_denominationNameIndex - 1].denominationAddress);
			require (_newDenominationToken.powerOfTen() > _prevDenominationToken.powerOfTen());
		}
		if (_denominationNameIndex < totalDenominations) {
			AOTokenInterface _lastDenominationToken = AOTokenInterface(denominations[totalDenominations].denominationAddress);
			require (_newDenominationToken.powerOfTen() < _lastDenominationToken.powerOfTen());
		}
		denominations[denominationIndex[denominationName]].denominationAddress = denominationAddress;
		return true;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Get denomination info based on name
	 * @param denominationName The name to be queried
	 * @return the denomination short name
	 * @return the denomination address
	 * @return the denomination public name
	 * @return the denomination symbol
	 * @return the denomination num of decimals
	 * @return the denomination multiplier (power of ten)
	 */
	function getDenominationByName(bytes8 denominationName) public view returns (bytes8, address, string, string, uint8, uint256) {
		require (denominationName.length != 0);
		require (denominationIndex[denominationName] > 0);
		require (denominations[denominationIndex[denominationName]].denominationAddress != address(0));
		AOTokenInterface _ao = AOTokenInterface(denominations[denominationIndex[denominationName]].denominationAddress);
		return (
			denominations[denominationIndex[denominationName]].name,
			denominations[denominationIndex[denominationName]].denominationAddress,
			_ao.name(),
			_ao.symbol(),
			_ao.decimals(),
			_ao.powerOfTen()
		);
	}

	/**
	 * @dev Get denomination info by index
	 * @param index The index to be queried
	 * @return the denomination short name
	 * @return the denomination address
	 * @return the denomination public name
	 * @return the denomination symbol
	 * @return the denomination num of decimals
	 * @return the denomination multiplier (power of ten)
	 */
	function getDenominationByIndex(uint256 index) public view returns (bytes8, address, string, string, uint8, uint256) {
		require (index > 0 && index <= totalDenominations);
		require (denominations[index].denominationAddress != address(0));
		AOTokenInterface _ao = AOTokenInterface(denominations[index].denominationAddress);
		return (
			denominations[index].name,
			denominations[index].denominationAddress,
			_ao.name(),
			_ao.symbol(),
			_ao.decimals(),
			_ao.powerOfTen()
		);
	}

	/**
	 * @dev Get base denomination info
	 * @return the denomination short name
	 * @return the denomination address
	 * @return the denomination public name
	 * @return the denomination symbol
	 * @return the denomination num of decimals
	 * @return the denomination multiplier (power of ten)
	 */
	function getBaseDenomination() public view returns (bytes8, address, string, string, uint8, uint256) {
		require (totalDenominations > 1);
		return getDenominationByIndex(1);
	}

	/**
	 * @dev convert token from `denominationName` denomination to base denomination,
	 *		in this case it&#39;s similar to web3.toWei() functionality
	 *
	 * Example:
	 * 9.1 Kilo should be entered as 9 integerAmount and 100 fractionAmount
	 * 9.02 Kilo should be entered as 9 integerAmount and 20 fractionAmount
	 * 9.001 Kilo should be entered as 9 integerAmount and 1 fractionAmount
	 *
	 * @param integerAmount uint256 of the integer amount to be converted
	 * @param fractionAmount uint256 of the frational amount to be converted
	 * @param denominationName bytes8 name of the token denomination
	 * @return uint256 converted amount in base denomination from target denomination
	 */
	function toBase(uint256 integerAmount, uint256 fractionAmount, bytes8 denominationName) public view returns (uint256) {
		if (denominationName.length > 0 &&
			denominationIndex[denominationName] > 0 &&
			denominations[denominationIndex[denominationName]].denominationAddress != address(0) &&
			(integerAmount > 0 || fractionAmount > 0)) {

			Denomination memory _denomination = denominations[denominationIndex[denominationName]];
			AOTokenInterface _denominationToken = AOTokenInterface(_denomination.denominationAddress);
			uint8 fractionNumDigits = _numDigits(fractionAmount);
			require (fractionNumDigits <= _denominationToken.decimals());
			uint256 baseInteger = integerAmount.mul(10 ** _denominationToken.powerOfTen());
			if (_denominationToken.decimals() == 0) {
				fractionAmount = 0;
			}
			return baseInteger.add(fractionAmount);
		} else {
			return 0;
		}
	}

	/**
	 * @dev convert token from base denomination to `denominationName` denomination,
	 *		in this case it&#39;s similar to web3.fromWei() functionality
	 * @param integerAmount uint256 of the base amount to be converted
	 * @param denominationName bytes8 name of the target token denomination
	 * @return uint256 of the converted integer amount in target denomination
	 * @return uint256 of the converted fraction amount in target denomination
	 */
	function fromBase(uint256 integerAmount, bytes8 denominationName) public isValidDenomination(denominationName) view returns (uint256, uint256) {
		Denomination memory _denomination = denominations[denominationIndex[denominationName]];
		AOTokenInterface _denominationToken = AOTokenInterface(_denomination.denominationAddress);
		uint256 denominationInteger = integerAmount.div(10 ** _denominationToken.powerOfTen());
		uint256 denominationFraction = integerAmount.sub(denominationInteger.mul(10 ** _denominationToken.powerOfTen()));
		return (denominationInteger, denominationFraction);
	}

	/**
	 * @dev exchange `amount` token from `fromDenominationName` denomination to token in `toDenominationName` denomination
	 * @param amount The amount of token to exchange
	 * @param fromDenominationName The origin denomination
	 * @param toDenominationName The target denomination
	 */
	function exchange(uint256 amount, bytes8 fromDenominationName, bytes8 toDenominationName) public isContractActive isValidDenomination(fromDenominationName) isValidDenomination(toDenominationName) {
		require (amount > 0);
		Denomination memory _fromDenomination = denominations[denominationIndex[fromDenominationName]];
		Denomination memory _toDenomination = denominations[denominationIndex[toDenominationName]];
		AOTokenInterface _fromDenominationToken = AOTokenInterface(_fromDenomination.denominationAddress);
		AOTokenInterface _toDenominationToken = AOTokenInterface(_toDenomination.denominationAddress);
		require (_fromDenominationToken.whitelistBurnFrom(msg.sender, amount));
		require (_toDenominationToken.mintToken(msg.sender, amount));
		emit Exchange(msg.sender, amount, fromDenominationName, toDenominationName);
	}

	/**
	 * @dev Return the highest possible denomination given a base amount
	 * @param amount The amount to be converted
	 * @return the denomination short name
	 * @return the denomination address
	 * @return the integer amount at the denomination level
	 * @return the fraction amount at the denomination level
	 * @return the denomination public name
	 * @return the denomination symbol
	 * @return the denomination num of decimals
	 * @return the denomination multiplier (power of ten)
	 */
	function toHighestDenomination(uint256 amount) public view returns (bytes8, address, uint256, uint256, string, string, uint8, uint256) {
		uint256 integerAmount;
		uint256 fractionAmount;
		uint256 index;
		for (uint256 i=totalDenominations; i>0; i--) {
			Denomination memory _denomination = denominations[i];
			(integerAmount, fractionAmount) = fromBase(amount, _denomination.name);
			if (integerAmount > 0) {
				index = i;
				break;
			}
		}
		require (index > 0 && index <= totalDenominations);
		require (integerAmount > 0 || fractionAmount > 0);
		require (denominations[index].denominationAddress != address(0));
		AOTokenInterface _ao = AOTokenInterface(denominations[index].denominationAddress);
		return (
			denominations[index].name,
			denominations[index].denominationAddress,
			integerAmount,
			fractionAmount,
			_ao.name(),
			_ao.symbol(),
			_ao.decimals(),
			_ao.powerOfTen()
		);
	}

	/***** INTERNAL METHOD *****/
	/**
	 * @dev count num of digits
	 * @param number uint256 of the nuumber to be checked
	 * @return uint8 num of digits
	 */
	function _numDigits(uint256 number) internal pure returns (uint8) {
		uint8 digits = 0;
		while(number != 0) {
			number = number.div(10);
			digits++;
		}
		return digits;
	}
}

















contract Pathos is TAOCurrency {
	/**
	 * @dev Constructor function
	 */
	constructor(uint256 initialSupply, string tokenName, string tokenSymbol)
		TAOCurrency(initialSupply, tokenName, tokenSymbol) public {}
}





contract Ethos is TAOCurrency {
	/**
	 * @dev Constructor function
	 */
	constructor(uint256 initialSupply, string tokenName, string tokenSymbol)
		TAOCurrency(initialSupply, tokenName, tokenSymbol) public {}
}


























/**
 * @title TAOController
 */
contract TAOController {
	NameFactory internal _nameFactory;
	NameTAOPosition internal _nameTAOPosition;

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress, address _nameTAOPositionAddress) public {
		_nameFactory = NameFactory(_nameFactoryAddress);
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
	}

	/**
	 * @dev Check if `_taoId` is a TAO
	 */
	modifier isTAO(address _taoId) {
		require (AOLibrary.isTAO(_taoId));
		_;
	}

	/**
	 * @dev Check if `_nameId` is a Name
	 */
	modifier isName(address _nameId) {
		require (AOLibrary.isName(_nameId));
		_;
	}

	/**
	 * @dev Check if `_id` is a Name or a TAO
	 */
	modifier isNameOrTAO(address _id) {
		require (AOLibrary.isName(_id) || AOLibrary.isTAO(_id));
		_;
	}

	/**
	 * @dev Check is msg.sender address is a Name
	 */
	 modifier senderIsName() {
		require (_nameFactory.ethAddressToNameId(msg.sender) != address(0));
		_;
	 }

	/**
	 * @dev Check if msg.sender is the current advocate of TAO ID
	 */
	modifier onlyAdvocate(address _id) {
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _id));
		_;
	}
}


		// Store the name lookup for a Name/TAO







/**
 * @title TAOFamily
 */
contract TAOFamily is TAOController {
	using SafeMath for uint256;

	address public taoFactoryAddress;

	TAOFactory internal _taoFactory;

	struct Child {
		address taoId;
		bool approved;		// If false, then waiting for parent TAO approval
		bool connected;		// If false, then parent TAO want to remove this child TAO
	}

	struct Family {
		address taoId;
		address parentId;	// The parent of this TAO ID (could be a Name or TAO)
		uint256 childMinLogos;
		mapping (uint256 => Child) children;
		mapping (address => uint256) childInternalIdLookup;
		uint256 totalChildren;
		uint256 childInternalId;
	}

	mapping (address => Family) internal families;

	// Event to be broadcasted to public when Advocate updates min required Logos to create a child TAO
	event UpdateChildMinLogos(address indexed taoId, uint256 childMinLogos, uint256 nonce);

	// Event to be broadcasted to public when a TAO adds a child TAO
	event AddChild(address indexed taoId, address childId, bool approved, bool connected, uint256 nonce);

	// Event to be broadcasted to public when a TAO approves a child TAO
	event ApproveChild(address indexed taoId, address childId, uint256 nonce);

	// Event to be broadcasted to public when a TAO removes a child TAO
	event RemoveChild(address indexed taoId, address childId, uint256 nonce);

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress, address _nameTAOPositionAddress, address _taoFactoryAddress)
		TAOController(_nameFactoryAddress, _nameTAOPositionAddress) public {
		taoFactoryAddress = _taoFactoryAddress;
		_taoFactory = TAOFactory(_taoFactoryAddress);
	}

	/**
	 * @dev Check if calling address is Factory
	 */
	modifier onlyFactory {
		require (msg.sender == taoFactoryAddress);
		_;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Check whether or not a TAO ID exist in the list of families
	 * @param _id The ID to be checked
	 * @return true if yes, false otherwise
	 */
	function isExist(address _id) public view returns (bool) {
		return families[_id].taoId != address(0);
	}

	/**
	 * @dev Store the Family info for a TAO
	 * @param _id The ID of the TAO
	 * @param _parentId The parent ID of this TAO
	 * @param _childMinLogos The min required Logos to create a TAO
	 * @return true on success
	 */
	function add(address _id, address _parentId, uint256 _childMinLogos)
		public
		isTAO(_id)
		isNameOrTAO(_parentId)
		onlyFactory returns (bool) {
		require (!isExist(_id));

		Family storage _family = families[_id];
		_family.taoId = _id;
		_family.parentId = _parentId;
		_family.childMinLogos = _childMinLogos;
		return true;
	}

	/**
	 * @dev Get Family info given a TAO ID
	 * @param _id The ID of the TAO
	 * @return the parent ID of this TAO (could be a Name/TAO)
	 * @return the min required Logos to create a child TAO
	 * @return the total child TAOs count
	 */
	function getFamilyById(address _id) public view returns (address, uint256, uint256) {
		require (isExist(_id));
		Family memory _family = families[_id];
		return (
			_family.parentId,
			_family.childMinLogos,
			_family.totalChildren
		);
	}

	/**
	 * @dev Set min required Logos to create a child from this TAO
	 * @param _childMinLogos The min Logos to set
	 * @return the nonce for this transaction
	 */
	function updateChildMinLogos(address _id, uint256 _childMinLogos)
		public
		isTAO(_id)
		senderIsName()
		onlyAdvocate(_id) {
		require (isExist(_id));

		Family storage _family = families[_id];
		_family.childMinLogos = _childMinLogos;

		uint256 _nonce = _taoFactory.incrementNonce(_id);
		require (_nonce > 0);
		emit UpdateChildMinLogos(_id, _family.childMinLogos, _nonce);
	}

	/**
	 * @dev Check if `_childId` is a child TAO of `_taoId`
	 * @param _taoId The TAO ID to be checked
	 * @param _childId The child TAO ID to check
	 * @return true if yes. Otherwise return false.
	 */
	function isChild(address _taoId, address _childId) public view returns (bool) {
		require (isExist(_taoId) && isExist(_childId));
		Family storage _family = families[_taoId];
		Family memory _childFamily = families[_childId];
		uint256 _childInternalId = _family.childInternalIdLookup[_childId];
		return (
			_childInternalId > 0 &&
			_family.children[_childInternalId].approved &&
			_family.children[_childInternalId].connected &&
			_childFamily.parentId == _taoId
		);
	}

	/**
	 * @dev Add child TAO
	 * @param _taoId The TAO ID to be added to
	 * @param _childId The ID to be added to as child TAO
	 */
	function addChild(address _taoId, address _childId)
		public
		isTAO(_taoId)
		isTAO(_childId)
		onlyFactory returns (bool) {
		require (!isChild(_taoId, _childId));
		Family storage _family = families[_taoId];
		require (_family.childInternalIdLookup[_childId] == 0);

		_family.childInternalId++;
		_family.childInternalIdLookup[_childId] = _family.childInternalId;
		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);

		Child storage _child = _family.children[_family.childInternalId];
		_child.taoId = _childId;

		// If _taoId&#39;s Advocate == _childId&#39;s Advocate, then the child is automatically approved and connected
		// Otherwise, child TAO needs parent TAO approval
		address _taoAdvocate = _nameTAOPosition.getAdvocate(_taoId);
		address _childAdvocate = _nameTAOPosition.getAdvocate(_childId);
		if (_taoAdvocate == _childAdvocate) {
			_family.totalChildren++;
			_child.approved = true;
			_child.connected = true;

			Family storage _childFamily = families[_childId];
			_childFamily.parentId = _taoId;
		}

		emit AddChild(_taoId, _childId, _child.approved, _child.connected, _nonce);
		return true;
	}

	/**
	 * @dev Advocate of `_taoId` approves child `_childId`
	 * @param _taoId The TAO ID to be checked
	 * @param _childId The child TAO ID to be approved
	 */
	function approveChild(address _taoId, address _childId)
		public
		isTAO(_taoId)
		isTAO(_childId)
		senderIsName()
		onlyAdvocate(_taoId) {
		require (isExist(_taoId) && isExist(_childId));
		Family storage _family = families[_taoId];
		Family storage _childFamily = families[_childId];
		uint256 _childInternalId = _family.childInternalIdLookup[_childId];

		require (_childInternalId > 0 &&
			!_family.children[_childInternalId].approved &&
			!_family.children[_childInternalId].connected
		);

		_family.totalChildren++;

		Child storage _child = _family.children[_childInternalId];
		_child.approved = true;
		_child.connected = true;

		_childFamily.parentId = _taoId;

		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);

		emit ApproveChild(_taoId, _childId, _nonce);
	}

	/**
	 * @dev Advocate of `_taoId` removes child `_childId`
	 * @param _taoId The TAO ID to be checked
	 * @param _childId The child TAO ID to be removed
	 */
	function removeChild(address _taoId, address _childId)
		public
		isTAO(_taoId)
		isTAO(_childId)
		senderIsName()
		onlyAdvocate(_taoId) {
		require (isChild(_taoId, _childId));

		Family storage _family = families[_taoId];
		_family.totalChildren--;

		Child storage _child = _family.children[_family.childInternalIdLookup[_childId]];
		_child.connected = false;
		_family.childInternalIdLookup[_childId] = 0;

		Family storage _childFamily = families[_childId];
		_childFamily.parentId = address(0);

		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);

		emit RemoveChild(_taoId, _childId, _nonce);
	}

	/**
	 * @dev Get list of child TAO IDs
	 * @param _taoId The TAO ID to be checked
	 * @param _from The starting index (start from 1)
	 * @param _to The ending index, (max is childInternalId)
	 * @return list of child TAO IDs
	 */
	function getChildIds(address _taoId, uint256 _from, uint256 _to) public view returns (address[]) {
		require (isExist(_taoId));
		Family storage _family = families[_taoId];
		require (_from >= 1 && _to >= _from && _family.childInternalId >= _to);
		address[] memory _childIds = new address[](_to.sub(_from).add(1));
		for (uint256 i = _from; i <= _to; i++) {
			_childIds[i.sub(_from)] = _family.children[i].approved && _family.children[i].connected ? _family.children[i].taoId : address(0);
		}
		return _childIds;
	}
}
			// Store TAO&#39;s child information



/**
 * @title TAOFactory
 *
 * The purpose of this contract is to allow node to create TAO
 */
contract TAOFactory is TheAO, TAOController {
	using SafeMath for uint256;
	address[] internal taos;

	address public taoFamilyAddress;
	address public nameTAOVaultAddress;
	address public settingTAOId;

	NameTAOLookup internal _nameTAOLookup;
	TAOFamily internal _taoFamily;
	AOSetting internal _aoSetting;
	Logos internal _logos;

	// Mapping from TAO ID to its nonce
	mapping (address => uint256) public nonces;

	// Event to be broadcasted to public when Advocate creates a TAO
	event CreateTAO(address indexed ethAddress, address advocateId, address taoId, uint256 index, address parent, uint8 parentTypeId);

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress, address _nameTAOLookupAddress, address _nameTAOPositionAddress, address _aoSettingAddress, address _logosAddress, address _nameTAOVaultAddress)
		TAOController(_nameFactoryAddress, _nameTAOPositionAddress) public {
		nameTAOPositionAddress = _nameTAOPositionAddress;
		nameTAOVaultAddress = _nameTAOVaultAddress;

		_nameTAOLookup = NameTAOLookup(_nameTAOLookupAddress);
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
		_aoSetting = AOSetting(_aoSettingAddress);
		_logos = Logos(_logosAddress);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Checks if calling address can update TAO&#39;s nonce
	 */
	modifier canUpdateNonce {
		require (msg.sender == nameTAOPositionAddress || msg.sender == taoFamilyAddress);
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO set the TAOFamily Address
	 * @param _taoFamilyAddress The address of TAOFamily
	 */
	function setTAOFamilyAddress(address _taoFamilyAddress) public onlyTheAO {
		require (_taoFamilyAddress != address(0));
		taoFamilyAddress = _taoFamilyAddress;
		_taoFamily = TAOFamily(taoFamilyAddress);
	}

	/**
	 * @dev The AO set settingTAOId (The TAO ID that holds the setting values)
	 * @param _settingTAOId The address of settingTAOId
	 */
	function setSettingTAOId(address _settingTAOId) public onlyTheAO isTAO(_settingTAOId) {
		settingTAOId = _settingTAOId;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Increment the nonce of a TAO
	 * @param _taoId The ID of the TAO
	 * @return current nonce
	 */
	function incrementNonce(address _taoId) public canUpdateNonce returns (uint256) {
		// Check if _taoId exist
		require (nonces[_taoId] > 0);
		nonces[_taoId]++;
		return nonces[_taoId];
	}

	/**
	 * @dev Name creates a TAO
	 * @param _name The name of the TAO
	 * @param _datHash The datHash of this TAO
	 * @param _database The database for this TAO
	 * @param _keyValue The key/value pair to be checked on the database
	 * @param _contentId The contentId related to this TAO
	 * @param _parentId The parent of this TAO (has to be a Name or TAO)
	 * @param _childMinLogos The min required Logos to create a child from this TAO
	 */
	function createTAO(
		string _name,
		string _datHash,
		string _database,
		string _keyValue,
		bytes32 _contentId,
		address _parentId,
		uint256 _childMinLogos
	) public senderIsName() isNameOrTAO(_parentId) {
		require (bytes(_name).length > 0);
		require (!_nameTAOLookup.isExist(_name));

		address _nameId = _nameFactory.ethAddressToNameId(msg.sender);

		uint256 _parentCreateChildTAOMinLogos;
		uint256 _createChildTAOMinLogos = _getSettingVariables();
		if (AOLibrary.isTAO(_parentId)) {
			(, _parentCreateChildTAOMinLogos,) = _taoFamily.getFamilyById(_parentId);
		}
		if (_parentCreateChildTAOMinLogos > 0) {
			require (_logos.sumBalanceOf(_nameId) >= _parentCreateChildTAOMinLogos);
		} else if (_createChildTAOMinLogos > 0) {
			require (_logos.sumBalanceOf(_nameId) >= _createChildTAOMinLogos);
		}

		// Create the TAO
		address taoId = new TAO(_name, _nameId, _datHash, _database, _keyValue, _contentId, nameTAOVaultAddress);

		// Increment the nonce
		nonces[taoId]++;

		// Store the name lookup information
		require (_nameTAOLookup.add(_name, taoId, TAO(_parentId).name(), 0));

		// Store the Advocate/Listener/Speaker information
		require (_nameTAOPosition.add(taoId, _nameId, _nameId, _nameId));

		require (_taoFamily.add(taoId, _parentId, _childMinLogos));
		taos.push(taoId);

		emit CreateTAO(msg.sender, _nameId, taoId, taos.length.sub(1), _parentId, TAO(_parentId).typeId());

		if (AOLibrary.isTAO(_parentId)) {
			require (_taoFamily.addChild(_parentId, taoId));
		}
	}

	/**
	 * @dev Get TAO information
	 * @param _taoId The ID of the TAO to be queried
	 * @return The name of the TAO
	 * @return The origin Name ID that created the TAO
	 * @return The name of Name that created the TAO
	 * @return The datHash of the TAO
	 * @return The database of the TAO
	 * @return The keyValue of the TAO
	 * @return The contentId of the TAO
	 * @return The typeId of the TAO
	 */
	function getTAO(address _taoId) public view returns (string, address, string, string, string, string, bytes32, uint8) {
		TAO _tao = TAO(_taoId);
		return (
			_tao.name(),
			_tao.originId(),
			Name(_tao.originId()).name(),
			_tao.datHash(),
			_tao.database(),
			_tao.keyValue(),
			_tao.contentId(),
			_tao.typeId()
		);
	}

	/**
	 * @dev Get total TAOs count
	 * @return total TAOs count
	 */
	function getTotalTAOsCount() public view returns (uint256) {
		return taos.length;
	}

	/**
	 * @dev Get list of TAO IDs
	 * @param _from The starting index
	 * @param _to The ending index
	 * @return list of TAO IDs
	 */
	function getTAOIds(uint256 _from, uint256 _to) public view returns (address[]) {
		require (_from >= 0 && _to >= _from && taos.length > _to);

		address[] memory _taos = new address[](_to.sub(_from).add(1));
		for (uint256 i = _from; i <= _to; i++) {
			_taos[i.sub(_from)] = taos[i];
		}
		return _taos;
	}

	/**
	 * @dev Check whether or not the signature is valid
	 * @param _data The signed string data
	 * @param _nonce The signed uint256 nonce (should be TAO&#39;s current nonce + 1)
	 * @param _validateAddress The ETH address to be validated (optional)
	 * @param _name The Name of the TAO
	 * @param _signatureV The V part of the signature
	 * @param _signatureR The R part of the signature
	 * @param _signatureS The S part of the signature
	 * @return true if valid. false otherwise
	 * @return The name of the Name that created the signature
	 * @return The Position of the Name that created the signature.
	 *			0 == unknown. 1 == Advocate. 2 == Listener. 3 == Speaker
	 */
	function validateTAOSignature(
		string _data,
		uint256 _nonce,
		address _validateAddress,
		string _name,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS
	) public isTAO(_getTAOIdByName(_name)) view returns (bool, string, uint256) {
		address _signatureAddress = AOLibrary.getValidateSignatureAddress(address(this), _data, _nonce, _signatureV, _signatureR, _signatureS);
		if (_isTAOSignatureAddressValid(_validateAddress, _signatureAddress, _getTAOIdByName(_name), _nonce)) {
			return (true, Name(_nameFactory.ethAddressToNameId(_signatureAddress)).name(), _nameTAOPosition.determinePosition(_signatureAddress, _getTAOIdByName(_name)));
		} else {
			return (false, "", 0);
		}
	}

	/***** INTERNAL METHOD *****/
	/**
	 * @dev Check whether or not the address recovered from the signature is valid
	 * @param _validateAddress The ETH address to be validated (optional)
	 * @param _signatureAddress The address recovered from the signature
	 * @param _taoId The ID of the TAO
	 * @param _nonce The signed uint256 nonce
	 * @return true if valid. false otherwise
	 */
	function _isTAOSignatureAddressValid(
		address _validateAddress,
		address _signatureAddress,
		address _taoId,
		uint256 _nonce
	) internal view returns (bool) {
		if (_validateAddress != address(0)) {
			return (_nonce == nonces[_taoId].add(1) &&
				_signatureAddress == _validateAddress &&
				_nameTAOPosition.senderIsPosition(_validateAddress, _taoId)
			);
		} else {
			return (
				_nonce == nonces[_taoId].add(1) &&
				_nameTAOPosition.senderIsPosition(_signatureAddress, _taoId)
			);
		}
	}

	/**
	 * @dev Internal function to get the TAO Id by name
	 * @param _name The name of the TAO
	 * @return the TAO ID
	 */
	function _getTAOIdByName(string _name) internal view returns (address) {
		return _nameTAOLookup.getAddressByName(_name);
	}

	/**
	 * @dev Get setting variables
	 * @return createChildTAOMinLogos The minimum required Logos to create a TAO
	 */
	function _getSettingVariables() internal view returns (uint256) {
		(uint256 createChildTAOMinLogos,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;createChildTAOMinLogos&#39;);
		return createChildTAOMinLogos;
	}
}


/**
 * @title NameTAOPosition
 */
contract NameTAOPosition is TheAO {
	address public nameFactoryAddress;
	address public taoFactoryAddress;

	NameFactory internal _nameFactory;
	TAOFactory internal _taoFactory;

	struct Position {
		address advocateId;
		address listenerId;
		address speakerId;
		bool created;
	}

	mapping (address => Position) internal positions;

	// Event to be broadcasted to public when current Advocate of TAO sets New Advocate
	event SetAdvocate(address indexed taoId, address oldAdvocateId, address newAdvocateId, uint256 nonce);

	// Event to be broadcasted to public when current Advocate of Name/TAO sets New Listener
	event SetListener(address indexed taoId, address oldListenerId, address newListenerId, uint256 nonce);

	// Event to be broadcasted to public when current Advocate of Name/TAO sets New Speaker
	event SetSpeaker(address indexed taoId, address oldSpeakerId, address newSpeakerId, uint256 nonce);

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress) public {
		nameFactoryAddress = _nameFactoryAddress;
		_nameFactory = NameFactory(_nameFactoryAddress);
		nameTAOPositionAddress = address(this);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Check if calling address is Factory
	 */
	modifier onlyFactory {
		require (msg.sender == nameFactoryAddress || msg.sender == taoFactoryAddress);
		_;
	}

	/**
	 * @dev Check if `_taoId` is a TAO
	 */
	modifier isTAO(address _taoId) {
		require (AOLibrary.isTAO(_taoId));
		_;
	}

	/**
	 * @dev Check if `_nameId` is a Name
	 */
	modifier isName(address _nameId) {
		require (AOLibrary.isName(_nameId));
		_;
	}

	/**
	 * @dev Check if `_id` is a Name or a TAO
	 */
	modifier isNameOrTAO(address _id) {
		require (AOLibrary.isName(_id) || AOLibrary.isTAO(_id));
		_;
	}

	/**
	 * @dev Check is msg.sender address is a Name
	 */
	 modifier senderIsName() {
		require (_nameFactory.ethAddressToNameId(msg.sender) != address(0));
		_;
	 }

	/**
	 * @dev Check if msg.sender is the current advocate of a Name/TAO ID
	 */
	modifier onlyAdvocate(address _id) {
		require (senderIsAdvocate(msg.sender, _id));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO set the taoFactoryAddress Address
	 * @param _taoFactoryAddress The address of TAOFactory
	 */
	function setTAOFactoryAddress(address _taoFactoryAddress) public onlyTheAO {
		require (_taoFactoryAddress != address(0));
		taoFactoryAddress = _taoFactoryAddress;
		_taoFactory = TAOFactory(_taoFactoryAddress);
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Check whether or not a Name/TAO ID exist in the list
	 * @param _id The ID to be checked
	 * @return true if yes, false otherwise
	 */
	function isExist(address _id) public view returns (bool) {
		return positions[_id].created;
	}

	/**
	 * @dev Check whether or not eth address is advocate of _id
	 * @param _sender The eth address to check
	 * @param _id The ID to be checked
	 * @return true if yes, false otherwise
	 */
	function senderIsAdvocate(address _sender, address _id) public view returns (bool) {
		return (positions[_id].created && positions[_id].advocateId == _nameFactory.ethAddressToNameId(_sender));
	}

	/**
	 * @dev Check whether or not eth address is either Advocate/Listener/Speaker of _id
	 * @param _sender The eth address to check
	 * @param _id The ID to be checked
	 * @return true if yes, false otherwise
	 */
	function senderIsPosition(address _sender, address _id) public view returns (bool) {
		address _nameId = _nameFactory.ethAddressToNameId(_sender);
		if (_nameId == address(0)) {
			return false;
		} else {
			return (positions[_id].created &&
				(positions[_id].advocateId == _nameId ||
				 positions[_id].listenerId == _nameId ||
				 positions[_id].speakerId == _nameId
				)
			);
		}
	}

	/**
	 * @dev Check whether or not _nameId is advocate of _id
	 * @param _nameId The name ID to be checked
	 * @param _id The ID to be checked
	 * @return true if yes, false otherwise
	 */
	function nameIsAdvocate(address _nameId, address _id) public view returns (bool) {
		return (positions[_id].created && positions[_id].advocateId == _nameId);
	}

	/**
	 * @dev Determine whether or not `_sender` is Advocate/Listener/Speaker of the Name/TAO
	 * @param _sender The ETH address that to check
	 * @param _id The ID of the Name/TAO
	 * @return 1 if Advocate. 2 if Listener. 3 if Speaker
	 */
	function determinePosition(address _sender, address _id) public view returns (uint256) {
		require (senderIsPosition(_sender, _id));
		Position memory _position = positions[_id];
		address _nameId = _nameFactory.ethAddressToNameId(_sender);
		if (_nameId == _position.advocateId) {
			return 1;
		} else if (_nameId == _position.listenerId) {
			return 2;
		} else {
			return 3;
		}
	}

	/**
	 * @dev Add Position for a Name/TAO
	 * @param _id The ID of the Name/TAO
	 * @param _advocateId The Advocate ID of the Name/TAO
	 * @param _listenerId The Listener ID of the Name/TAO
	 * @param _speakerId The Speaker ID of the Name/TAO
	 * @return true on success
	 */
	function add(address _id, address _advocateId, address _listenerId, address _speakerId)
		public
		isNameOrTAO(_id)
		isName(_advocateId)
		isNameOrTAO(_listenerId)
		isNameOrTAO(_speakerId)
		onlyFactory returns (bool) {
		require (!isExist(_id));

		Position storage _position = positions[_id];
		_position.advocateId = _advocateId;
		_position.listenerId = _listenerId;
		_position.speakerId = _speakerId;
		_position.created = true;
		return true;
	}

	/**
	 * @dev Get Name/TAO&#39;s Position info
	 * @param _id The ID of the Name/TAO
	 * @return the Advocate ID of Name/TAO
	 * @return the Listener ID of Name/TAO
	 * @return the Speaker ID of Name/TAO
	 */
	function getPositionById(address _id) public view returns (address, address, address) {
		require (isExist(_id));
		Position memory _position = positions[_id];
		return (
			_position.advocateId,
			_position.listenerId,
			_position.speakerId
		);
	}

	/**
	 * @dev Get Name/TAO&#39;s Advocate
	 * @param _id The ID of the Name/TAO
	 * @return the Advocate ID of Name/TAO
	 */
	function getAdvocate(address _id) public view returns (address) {
		require (isExist(_id));
		Position memory _position = positions[_id];
		return _position.advocateId;
	}

	/**
	 * @dev Get Name/TAO&#39;s Listener
	 * @param _id The ID of the Name/TAO
	 * @return the Listener ID of Name/TAO
	 */
	function getListener(address _id) public view returns (address) {
		require (isExist(_id));
		Position memory _position = positions[_id];
		return _position.listenerId;
	}

	/**
	 * @dev Get Name/TAO&#39;s Speaker
	 * @param _id The ID of the Name/TAO
	 * @return the Speaker ID of Name/TAO
	 */
	function getSpeaker(address _id) public view returns (address) {
		require (isExist(_id));
		Position memory _position = positions[_id];
		return _position.speakerId;
	}

	/**
	 * @dev Set Advocate for a TAO
	 * @param _taoId The ID of the TAO
	 * @param _newAdvocateId The new advocate ID to be set
	 */
	function setAdvocate(address _taoId, address _newAdvocateId)
		public
		isTAO(_taoId)
		isName(_newAdvocateId)
		senderIsName()
		onlyAdvocate(_taoId) {

		Position storage _position = positions[_taoId];
		address _currentAdvocateId = _position.advocateId;
		_position.advocateId = _newAdvocateId;

		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);
		emit SetAdvocate(_taoId, _currentAdvocateId, _position.advocateId, _nonce);
	}

	/**
	 * @dev Set Listener for a Name/TAO
	 * @param _id The ID of the Name/TAO
	 * @param _newListenerId The new listener ID to be set
	 */
	function setListener(address _id, address _newListenerId)
		public
		isNameOrTAO(_id)
		isNameOrTAO(_newListenerId)
		senderIsName()
		onlyAdvocate(_id) {

		// If _id is a Name, then new Listener can only be a Name
		// If _id is a TAO, then new Listener can be a TAO/Name
		bool _isName = false;
		if (AOLibrary.isName(_id)) {
			_isName = true;
			require (AOLibrary.isName(_newListenerId));
		}

		Position storage _position = positions[_id];
		address _currentListenerId = _position.listenerId;
		_position.listenerId = _newListenerId;

		if (_isName) {
			uint256 _nonce = _nameFactory.incrementNonce(_id);
		} else {
			_nonce = _taoFactory.incrementNonce(_id);
		}
		emit SetListener(_id, _currentListenerId, _position.listenerId, _nonce);
	}

	/**
	 * @dev Set Speaker for a Name/TAO
	 * @param _id The ID of the Name/TAO
	 * @param _newSpeakerId The new speaker ID to be set
	 */
	function setSpeaker(address _id, address _newSpeakerId)
		public
		isNameOrTAO(_id)
		isNameOrTAO(_newSpeakerId)
		senderIsName()
		onlyAdvocate(_id) {

		// If _id is a Name, then new Speaker can only be a Name
		// If _id is a TAO, then new Speaker can be a TAO/Name
		bool _isName = false;
		if (AOLibrary.isName(_id)) {
			_isName = true;
			require (AOLibrary.isName(_newSpeakerId));
		}

		Position storage _position = positions[_id];
		address _currentSpeakerId = _position.speakerId;
		_position.speakerId = _newSpeakerId;

		if (_isName) {
			uint256 _nonce = _nameFactory.incrementNonce(_id);
		} else {
			_nonce = _taoFactory.incrementNonce(_id);
		}
		emit SetSpeaker(_id, _currentSpeakerId, _position.speakerId, _nonce);
	}
}


/**
 * @title AOSetting
 *
 * This contract stores all AO setting variables
 */
contract AOSetting {
	address public aoSettingAttributeAddress;
	address public aoUintSettingAddress;
	address public aoBoolSettingAddress;
	address public aoAddressSettingAddress;
	address public aoBytesSettingAddress;
	address public aoStringSettingAddress;

	NameFactory internal _nameFactory;
	NameTAOPosition internal _nameTAOPosition;
	AOSettingAttribute internal _aoSettingAttribute;
	AOUintSetting internal _aoUintSetting;
	AOBoolSetting internal _aoBoolSetting;
	AOAddressSetting internal _aoAddressSetting;
	AOBytesSetting internal _aoBytesSetting;
	AOStringSetting internal _aoStringSetting;

	uint256 public totalSetting;

	/**
	 * Mapping from associatedTAOId&#39;s setting name to Setting ID.
	 *
	 * Instead of concatenating the associatedTAOID and setting name to create a unique ID for lookup,
	 * use nested mapping to achieve the same result.
	 *
	 * The setting&#39;s name needs to be converted to bytes32 since solidity does not support mapping by string.
	 */
	mapping (address => mapping (bytes32 => uint256)) internal nameSettingLookup;

	// Mapping from updateHashKey to it&#39;s settingId
	mapping (bytes32 => uint256) public updateHashLookup;

	// Event to be broadcasted to public when a setting is created and waiting for approval
	event SettingCreation(uint256 indexed settingId, address indexed creatorNameId, address creatorTAOId, address associatedTAOId, string settingName, uint8 settingType, bytes32 associatedTAOSettingId, bytes32 creatorTAOSettingId);

	// Event to be broadcasted to public when setting creation is approved/rejected by the advocate of associatedTAOId
	event ApproveSettingCreation(uint256 indexed settingId, address associatedTAOId, address associatedTAOAdvocate, bool approved);
	// Event to be broadcasted to public when setting creation is finalized by the advocate of creatorTAOId
	event FinalizeSettingCreation(uint256 indexed settingId, address creatorTAOId, address creatorTAOAdvocate);

	// Event to be broadcasted to public when a proposed update for a setting is created
	event SettingUpdate(uint256 indexed settingId, address indexed updateAdvocateNameId, address proposalTAOId);

	// Event to be broadcasted to public when setting update is approved/rejected by the advocate of proposalTAOId
	event ApproveSettingUpdate(uint256 indexed settingId, address proposalTAOId, address proposalTAOAdvocate, bool approved);

	// Event to be broadcasted to public when setting update is finalized by the advocate of associatedTAOId
	event FinalizeSettingUpdate(uint256 indexed settingId, address associatedTAOId, address associatedTAOAdvocate);

	// Event to be broadcasted to public when a setting deprecation is created and waiting for approval
	event SettingDeprecation(uint256 indexed settingId, address indexed creatorNameId, address creatorTAOId, address associatedTAOId, uint256 newSettingId, address newSettingContractAddress, bytes32 associatedTAOSettingDeprecationId, bytes32 creatorTAOSettingDeprecationId);

	// Event to be broadcasted to public when setting deprecation is approved/rejected by the advocate of associatedTAOId
	event ApproveSettingDeprecation(uint256 indexed settingId, address associatedTAOId, address associatedTAOAdvocate, bool approved);

	// Event to be broadcasted to public when setting deprecation is finalized by the advocate of creatorTAOId
	event FinalizeSettingDeprecation(uint256 indexed settingId, address creatorTAOId, address creatorTAOAdvocate);

	/**
	 * @dev Constructor function
	 */
	constructor(address _nameFactoryAddress,
		address _nameTAOPositionAddress,
		address _aoSettingAttributeAddress,
		address _aoUintSettingAddress,
		address _aoBoolSettingAddress,
		address _aoAddressSettingAddress,
		address _aoBytesSettingAddress,
		address _aoStringSettingAddress) public {
		aoSettingAttributeAddress = _aoSettingAttributeAddress;
		aoUintSettingAddress = _aoUintSettingAddress;
		aoBoolSettingAddress = _aoBoolSettingAddress;
		aoAddressSettingAddress = _aoAddressSettingAddress;
		aoBytesSettingAddress = _aoBytesSettingAddress;
		aoStringSettingAddress = _aoStringSettingAddress;

		_nameFactory = NameFactory(_nameFactoryAddress);
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
		_aoSettingAttribute = AOSettingAttribute(_aoSettingAttributeAddress);
		_aoUintSetting = AOUintSetting(_aoUintSettingAddress);
		_aoBoolSetting = AOBoolSetting(_aoBoolSettingAddress);
		_aoAddressSetting = AOAddressSetting(_aoAddressSettingAddress);
		_aoBytesSetting = AOBytesSetting(_aoBytesSettingAddress);
		_aoStringSetting = AOStringSetting(_aoStringSettingAddress);
	}

	/**
	 * @dev Check if `_taoId` is a TAO
	 */
	modifier isTAO(address _taoId) {
		require (AOLibrary.isTAO(_taoId));
		_;
	}

	/**
	 * @dev Check if `_settingName` of `_associatedTAOId` is taken
	 */
	modifier settingNameNotTaken(string _settingName, address _associatedTAOId) {
		require (settingNameExist(_settingName, _associatedTAOId) == false);
		_;
	}

	/**
	 * @dev Check if msg.sender is the current advocate of Name ID
	 */
	modifier onlyAdvocate(address _id) {
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _id));
		_;
	}

	/***** Public Methods *****/
	/**
	 * @dev Check whether or not a setting name of an associatedTAOId exist
	 * @param _settingName The human-readable name of the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @return true if yes. false otherwise
	 */
	function settingNameExist(string _settingName, address _associatedTAOId) public view returns (bool) {
		return (nameSettingLookup[_associatedTAOId][keccak256(abi.encodePacked(this, _settingName))] > 0);
	}

	/**
	 * @dev Advocate of _creatorTAOId adds a uint setting
	 * @param _settingName The human-readable name of the setting
	 * @param _value The uint256 value of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function addUintSetting(string _settingName, uint256 _value, address _creatorTAOId, address _associatedTAOId, string _extraData) public isTAO(_creatorTAOId) isTAO(_associatedTAOId) settingNameNotTaken(_settingName, _associatedTAOId) onlyAdvocate(_creatorTAOId) {
		// Update global variables
		totalSetting++;

		// Store the value as pending value
		_aoUintSetting.setPendingValue(totalSetting, _value);

		// Store setting creation data
		_storeSettingCreation(_nameFactory.ethAddressToNameId(msg.sender), 1, _settingName, _creatorTAOId, _associatedTAOId, _extraData);
	}

	/**
	 * @dev Advocate of _creatorTAOId adds a bool setting
	 * @param _settingName The human-readable name of the setting
	 * @param _value The bool value of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function addBoolSetting(string _settingName, bool _value, address _creatorTAOId, address _associatedTAOId, string _extraData) public isTAO(_creatorTAOId) isTAO(_associatedTAOId) settingNameNotTaken(_settingName, _associatedTAOId) onlyAdvocate(_creatorTAOId) {
		// Update global variables
		totalSetting++;

		// Store the value as pending value
		_aoBoolSetting.setPendingValue(totalSetting, _value);

		// Store setting creation data
		_storeSettingCreation(_nameFactory.ethAddressToNameId(msg.sender), 2, _settingName, _creatorTAOId, _associatedTAOId, _extraData);
	}

	/**
	 * @dev Advocate of _creatorTAOId adds an address setting
	 * @param _settingName The human-readable name of the setting
	 * @param _value The address value of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function addAddressSetting(string _settingName, address _value, address _creatorTAOId, address _associatedTAOId, string _extraData) public isTAO(_creatorTAOId) isTAO(_associatedTAOId) settingNameNotTaken(_settingName, _associatedTAOId) onlyAdvocate(_creatorTAOId) {
		// Update global variables
		totalSetting++;

		// Store the value as pending value
		_aoAddressSetting.setPendingValue(totalSetting, _value);

		// Store setting creation data
		_storeSettingCreation(_nameFactory.ethAddressToNameId(msg.sender), 3, _settingName, _creatorTAOId, _associatedTAOId, _extraData);
	}

	/**
	 * @dev Advocate of _creatorTAOId adds a bytes32 setting
	 * @param _settingName The human-readable name of the setting
	 * @param _value The bytes32 value of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function addBytesSetting(string _settingName, bytes32 _value, address _creatorTAOId, address _associatedTAOId, string _extraData) public isTAO(_creatorTAOId) isTAO(_associatedTAOId) settingNameNotTaken(_settingName, _associatedTAOId) onlyAdvocate(_creatorTAOId) {
		// Update global variables
		totalSetting++;

		// Store the value as pending value
		_aoBytesSetting.setPendingValue(totalSetting, _value);

		// Store setting creation data
		_storeSettingCreation(_nameFactory.ethAddressToNameId(msg.sender), 4, _settingName, _creatorTAOId, _associatedTAOId, _extraData);
	}

	/**
	 * @dev Advocate of _creatorTAOId adds a string setting
	 * @param _settingName The human-readable name of the setting
	 * @param _value The string value of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function addStringSetting(string _settingName, string _value, address _creatorTAOId, address _associatedTAOId, string _extraData) public isTAO(_creatorTAOId) isTAO(_associatedTAOId) settingNameNotTaken(_settingName, _associatedTAOId) onlyAdvocate(_creatorTAOId) {
		// Update global variables
		totalSetting++;

		// Store the value as pending value
		_aoStringSetting.setPendingValue(totalSetting, _value);

		// Store setting creation data
		_storeSettingCreation(_nameFactory.ethAddressToNameId(msg.sender), 5, _settingName, _creatorTAOId, _associatedTAOId, _extraData);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId approves setting creation
	 * @param _settingId The ID of the setting to approve
	 * @param _approved Whether to approve or reject
	 */
	function approveSettingCreation(uint256 _settingId, bool _approved) public {
		address _associatedTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		require (_aoSettingAttribute.approveAdd(_settingId, _associatedTAOAdvocate, _approved));

		(,,,address _associatedTAOId, string memory _settingName,,,,,) = _aoSettingAttribute.getSettingData(_settingId);
		if (!_approved) {
			// Clear the settingName from nameSettingLookup so it can be added again in the future
			delete nameSettingLookup[_associatedTAOId][keccak256(abi.encodePacked(this, _settingName))];
		}
		emit ApproveSettingCreation(_settingId, _associatedTAOId, _associatedTAOAdvocate, _approved);
	}

	/**
	 * @dev Advocate of Setting&#39;s _creatorTAOId finalizes the setting creation once the setting is approved
	 * @param _settingId The ID of the setting to be finalized
	 */
	function finalizeSettingCreation(uint256 _settingId) public {
		address _creatorTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		require (_aoSettingAttribute.finalizeAdd(_settingId, _creatorTAOAdvocate));

		(,,address _creatorTAOId,,, uint8 _settingType,,,,) = _aoSettingAttribute.getSettingData(_settingId);

		_movePendingToSetting(_settingId, _settingType);

		emit FinalizeSettingCreation(_settingId, _creatorTAOId, _creatorTAOAdvocate);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId submits a uint256 setting update after an update has been proposed
	 * @param _settingId The ID of the setting to be updated
	 * @param _newValue The new uint256 value for this setting
	 * @param _proposalTAOId The child of the associatedTAOId with the update Logos
	 * @param _updateSignature A signature of the proposalTAOId and update value by associatedTAOId&#39;s advocate&#39;s name address
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function updateUintSetting(uint256 _settingId, uint256 _newValue, address _proposalTAOId, string _updateSignature, string _extraData) public isTAO(_proposalTAOId) {
		// Store the setting state data
		require (_aoSettingAttribute.update(_settingId, 1, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _updateSignature, _extraData));

		// Store the value as pending value
		_aoUintSetting.setPendingValue(_settingId, _newValue);

		// Store the update hash key lookup
		updateHashLookup[keccak256(abi.encodePacked(this, _proposalTAOId, _aoUintSetting.settingValue(_settingId), _newValue, _extraData, _settingId))] = _settingId;

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId submits a bool setting update after an update has been proposed
	 * @param _settingId The ID of the setting to be updated
	 * @param _newValue The new bool value for this setting
	 * @param _proposalTAOId The child of the associatedTAOId with the update Logos
	 * @param _updateSignature A signature of the proposalTAOId and update value by associatedTAOId&#39;s advocate&#39;s name address
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function updateBoolSetting(uint256 _settingId, bool _newValue, address _proposalTAOId, string _updateSignature, string _extraData) public isTAO(_proposalTAOId) {
		// Store the setting state data
		require (_aoSettingAttribute.update(_settingId, 2, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _updateSignature, _extraData));

		// Store the value as pending value
		_aoBoolSetting.setPendingValue(_settingId, _newValue);

		// Store the update hash key lookup
		updateHashLookup[keccak256(abi.encodePacked(this, _proposalTAOId, _aoBoolSetting.settingValue(_settingId), _newValue, _extraData, _settingId))] = _settingId;

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId submits an address setting update after an update has been proposed
	 * @param _settingId The ID of the setting to be updated
	 * @param _newValue The new address value for this setting
	 * @param _proposalTAOId The child of the associatedTAOId with the update Logos
	 * @param _updateSignature A signature of the proposalTAOId and update value by associatedTAOId&#39;s advocate&#39;s name address
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function updateAddressSetting(uint256 _settingId, address _newValue, address _proposalTAOId, string _updateSignature, string _extraData) public isTAO(_proposalTAOId) {
		// Store the setting state data
		require (_aoSettingAttribute.update(_settingId, 3, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _updateSignature, _extraData));

		// Store the value as pending value
		_aoAddressSetting.setPendingValue(_settingId, _newValue);

		// Store the update hash key lookup
		updateHashLookup[keccak256(abi.encodePacked(this, _proposalTAOId, _aoAddressSetting.settingValue(_settingId), _newValue, _extraData, _settingId))] = _settingId;

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId submits a bytes32 setting update after an update has been proposed
	 * @param _settingId The ID of the setting to be updated
	 * @param _newValue The new bytes32 value for this setting
	 * @param _proposalTAOId The child of the associatedTAOId with the update Logos
	 * @param _updateSignature A signature of the proposalTAOId and update value by associatedTAOId&#39;s advocate&#39;s name address
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function updateBytesSetting(uint256 _settingId, bytes32 _newValue, address _proposalTAOId, string _updateSignature, string _extraData) public isTAO(_proposalTAOId) {
		// Store the setting state data
		require (_aoSettingAttribute.update(_settingId, 4, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _updateSignature, _extraData));

		// Store the value as pending value
		_aoBytesSetting.setPendingValue(_settingId, _newValue);

		// Store the update hash key lookup
		updateHashLookup[keccak256(abi.encodePacked(this, _proposalTAOId, _aoBytesSetting.settingValue(_settingId), _newValue, _extraData, _settingId))] = _settingId;

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId submits a string setting update after an update has been proposed
	 * @param _settingId The ID of the setting to be updated
	 * @param _newValue The new string value for this setting
	 * @param _proposalTAOId The child of the associatedTAOId with the update Logos
	 * @param _updateSignature A signature of the proposalTAOId and update value by associatedTAOId&#39;s advocate&#39;s name address
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function updateStringSetting(uint256 _settingId, string _newValue, address _proposalTAOId, string _updateSignature, string _extraData) public isTAO(_proposalTAOId) {
		// Store the setting state data
		require (_aoSettingAttribute.update(_settingId, 5, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _updateSignature, _extraData));

		// Store the value as pending value
		_aoStringSetting.setPendingValue(_settingId, _newValue);

		// Store the update hash key lookup
		updateHashLookup[keccak256(abi.encodePacked(this, _proposalTAOId, _aoStringSetting.settingValue(_settingId), _newValue, _extraData, _settingId))] = _settingId;

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	/**
	 * @dev Advocate of Setting&#39;s proposalTAOId approves the setting update
	 * @param _settingId The ID of the setting to be approved
	 * @param _approved Whether to approve or reject
	 */
	function approveSettingUpdate(uint256 _settingId, bool _approved) public {
		address _proposalTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		(,,, address _proposalTAOId,,,) = _aoSettingAttribute.getSettingState(_settingId);

		require (_aoSettingAttribute.approveUpdate(_settingId, _proposalTAOAdvocate, _approved));

		emit ApproveSettingUpdate(_settingId, _proposalTAOId, _proposalTAOAdvocate, _approved);
	}

	/**
	 * @dev Advocate of Setting&#39;s _associatedTAOId finalizes the setting update once the setting is approved
	 * @param _settingId The ID of the setting to be finalized
	 */
	function finalizeSettingUpdate(uint256 _settingId) public {
		address _associatedTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		require (_aoSettingAttribute.finalizeUpdate(_settingId, _associatedTAOAdvocate));

		(,,, address _associatedTAOId,, uint8 _settingType,,,,) = _aoSettingAttribute.getSettingData(_settingId);

		_movePendingToSetting(_settingId, _settingType);

		emit FinalizeSettingUpdate(_settingId, _associatedTAOId, _associatedTAOAdvocate);
	}

	/**
	 * @dev Advocate of _creatorTAOId adds a setting deprecation
	 * @param _settingId The ID of the setting to be deprecated
	 * @param _newSettingId The new setting ID to route
	 * @param _newSettingContractAddress The new setting contract address to route
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 */
	function addSettingDeprecation(uint256 _settingId, uint256 _newSettingId, address _newSettingContractAddress, address _creatorTAOId, address _associatedTAOId) public isTAO(_creatorTAOId) isTAO(_associatedTAOId) onlyAdvocate(_creatorTAOId) {
		(bytes32 _associatedTAOSettingDeprecationId, bytes32 _creatorTAOSettingDeprecationId) = _aoSettingAttribute.addDeprecation(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _creatorTAOId, _associatedTAOId, _newSettingId, _newSettingContractAddress);

		emit SettingDeprecation(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _creatorTAOId, _associatedTAOId, _newSettingId, _newSettingContractAddress, _associatedTAOSettingDeprecationId, _creatorTAOSettingDeprecationId);
	}

	/**
	 * @dev Advocate of SettingDeprecation&#39;s _associatedTAOId approves setting deprecation
	 * @param _settingId The ID of the setting to approve
	 * @param _approved Whether to approve or reject
	 */
	function approveSettingDeprecation(uint256 _settingId, bool _approved) public {
		address _associatedTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		require (_aoSettingAttribute.approveDeprecation(_settingId, _associatedTAOAdvocate, _approved));

		(,,, address _associatedTAOId,,,,,,,,) = _aoSettingAttribute.getSettingDeprecation(_settingId);
		emit ApproveSettingDeprecation(_settingId, _associatedTAOId, _associatedTAOAdvocate, _approved);
	}

	/**
	 * @dev Advocate of SettingDeprecation&#39;s _creatorTAOId finalizes the setting deprecation once the setting deprecation is approved
	 * @param _settingId The ID of the setting to be finalized
	 */
	function finalizeSettingDeprecation(uint256 _settingId) public {
		address _creatorTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		require (_aoSettingAttribute.finalizeDeprecation(_settingId, _creatorTAOAdvocate));

		(,, address _creatorTAOId,,,,,,,,,) = _aoSettingAttribute.getSettingDeprecation(_settingId);
		emit FinalizeSettingDeprecation(_settingId, _creatorTAOId, _creatorTAOAdvocate);
	}

	/**
	 * @dev Get setting Id given an associatedTAOId and settingName
	 * @param _associatedTAOId The ID of the AssociatedTAO
	 * @param _settingName The name of the setting
	 * @return the ID of the setting
	 */
	function getSettingIdByTAOName(address _associatedTAOId, string _settingName) public view returns (uint256) {
		return nameSettingLookup[_associatedTAOId][keccak256(abi.encodePacked(this, _settingName))];
	}

	/**
	 * @dev Get setting values by setting ID.
	 *		Will throw error if the setting is not exist or rejected.
	 * @param _settingId The ID of the setting
	 * @return the uint256 value of this setting ID
	 * @return the bool value of this setting ID
	 * @return the address value of this setting ID
	 * @return the bytes32 value of this setting ID
	 * @return the string value of this setting ID
	 */
	function getSettingValuesById(uint256 _settingId) public view returns (uint256, bool, address, bytes32, string) {
		require (_aoSettingAttribute.settingExist(_settingId));
		_settingId = _aoSettingAttribute.getLatestSettingId(_settingId);
		return (
			_aoUintSetting.settingValue(_settingId),
			_aoBoolSetting.settingValue(_settingId),
			_aoAddressSetting.settingValue(_settingId),
			_aoBytesSetting.settingValue(_settingId),
			_aoStringSetting.settingValue(_settingId)
		);
	}

	/**
	 * @dev Get setting values by taoId and settingName.
	 *		Will throw error if the setting is not exist or rejected.
	 * @param _taoId The ID of the TAO
	 * @param _settingName The name of the setting
	 * @return the uint256 value of this setting ID
	 * @return the bool value of this setting ID
	 * @return the address value of this setting ID
	 * @return the bytes32 value of this setting ID
	 * @return the string value of this setting ID
	 */
	function getSettingValuesByTAOName(address _taoId, string _settingName) public view returns (uint256, bool, address, bytes32, string) {
		return getSettingValuesById(getSettingIdByTAOName(_taoId, _settingName));
	}

	/***** Internal Method *****/
	/**
	 * @dev Store setting creation data
	 * @param _creatorNameId The nameId that created the setting
	 * @param _settingType The type of this setting. 1 => uint256, 2 => bool, 3 => address, 4 => bytes32, 5 => string
	 * @param _settingName The human-readable name of the setting
	 * @param _creatorTAOId The taoId that created the setting
	 * @param _associatedTAOId The taoId that the setting affects
	 * @param _extraData Catch-all string value to be stored if exist
	 */
	function _storeSettingCreation(address _creatorNameId, uint8 _settingType, string _settingName, address _creatorTAOId, address _associatedTAOId, string _extraData) internal {
		// Make sure _settingType is in supported list
		require (_settingType >= 1 && _settingType <= 5);

		// Store nameSettingLookup
		nameSettingLookup[_associatedTAOId][keccak256(abi.encodePacked(this, _settingName))] = totalSetting;

		// Store setting data/state
		(bytes32 _associatedTAOSettingId, bytes32 _creatorTAOSettingId) = _aoSettingAttribute.add(totalSetting, _creatorNameId, _settingType, _settingName, _creatorTAOId, _associatedTAOId, _extraData);

		emit SettingCreation(totalSetting, _creatorNameId, _creatorTAOId, _associatedTAOId, _settingName, _settingType, _associatedTAOSettingId, _creatorTAOSettingId);
	}

	/**
	 * @dev Move value of _settingId from pending variable to setting variable
	 * @param _settingId The ID of the setting
	 * @param _settingType The type of the setting
	 */
	function _movePendingToSetting(uint256 _settingId, uint8 _settingType) internal {
		// If settingType == uint256
		if (_settingType == 1) {
			_aoUintSetting.movePendingToSetting(_settingId);
		} else if (_settingType == 2) {
			// Else if settingType == bool
			_aoBoolSetting.movePendingToSetting(_settingId);
		} else if (_settingType == 3) {
			// Else if settingType == address
			_aoAddressSetting.movePendingToSetting(_settingId);
		} else if (_settingType == 4) {
			// Else if settingType == bytes32
			_aoBytesSetting.movePendingToSetting(_settingId);
		} else {
			// Else if settingType == string
			_aoStringSetting.movePendingToSetting(_settingId);
		}
	}
}




/**
 * @title AOEarning
 *
 * This contract stores the earning from staking/hosting content on AO
 */
contract AOEarning is TheAO {
	using SafeMath for uint256;

	address public settingTAOId;
	address public aoSettingAddress;
	address public baseDenominationAddress;
	address public treasuryAddress;
	address public nameFactoryAddress;
	address public pathosAddress;
	address public ethosAddress;

	bool public paused;
	bool public killed;

	AOToken internal _baseAO;
	AOTreasury internal _treasury;
	NameFactory internal _nameFactory;
	Pathos internal _pathos;
	Ethos internal _ethos;
	AOSetting internal _aoSetting;

	// Total earning from staking content from all nodes
	uint256 public totalStakeContentEarning;

	// Total earning from hosting content from all nodes
	uint256 public totalHostContentEarning;

	// Total The AO earning
	uint256 public totalTheAOEarning;

	// Mapping from address to his/her earning from content that he/she staked
	mapping (address => uint256) public stakeContentEarning;

	// Mapping from address to his/her earning from content that he/she hosted
	mapping (address => uint256) public hostContentEarning;

	// Mapping from address to his/her network price earning
	// i.e, when staked amount = filesize
	mapping (address => uint256) public networkPriceEarning;

	// Mapping from address to his/her content price earning
	// i.e, when staked amount > filesize
	mapping (address => uint256) public contentPriceEarning;

	// Mapping from address to his/her inflation bonus
	mapping (address => uint256) public inflationBonusAccrued;

	struct Earning {
		bytes32 purchaseId;
		uint256 paymentEarning;
		uint256 inflationBonus;
		uint256 pathosAmount;
		uint256 ethosAmount;
	}

	// Mapping from address to earning from staking content of a purchase ID
	mapping (address => mapping(bytes32 => Earning)) public stakeEarnings;

	// Mapping from address to earning from hosting content of a purchase ID
	mapping (address => mapping(bytes32 => Earning)) public hostEarnings;

	// Mapping from purchase ID to earning for The AO
	mapping (bytes32 => Earning) public theAOEarnings;

	// Mapping from stake ID to it&#39;s total earning from staking
	mapping (bytes32 => uint256) public totalStakedContentStakeEarning;

	// Mapping from stake ID to it&#39;s total earning from hosting
	mapping (bytes32 => uint256) public totalStakedContentHostEarning;

	// Mapping from stake ID to it&#39;s total earning earned by The AO
	mapping (bytes32 => uint256) public totalStakedContentTheAOEarning;

	// Mapping from content host ID to it&#39;s total earning
	mapping (bytes32 => uint256) public totalHostContentEarningById;

	// Event to be broadcasted to public when content creator/host earns the payment split in escrow when request node buys the content
	// recipientType:
	// 0 => Content Creator (Stake Owner)
	// 1 => Node Host
	// 2 => The AO
	event PaymentEarningEscrowed(address indexed recipient, bytes32 indexed purchaseId, uint256 totalPaymentAmount, uint256 recipientProfitPercentage, uint256 recipientPaymentEarning, uint8 recipientType);

	// Event to be broadcasted to public when content creator/host/The AO earns inflation bonus in escrow when request node buys the content
	// recipientType:
	// 0 => Content Creator (Stake Owner)
	// 1 => Node Host
	// 2 => The AO
	event InflationBonusEscrowed(address indexed recipient, bytes32 indexed purchaseId, uint256 totalInflationBonusAmount, uint256 recipientProfitPercentage, uint256 recipientInflationBonus, uint8 recipientType);

	// Event to be broadcasted to public when content creator/host/The AO earning is released from escrow
	// recipientType:
	// 0 => Content Creator (Stake Owner)
	// 1 => Node Host
	// 2 => The AO
	event EarningUnescrowed(address indexed recipient, bytes32 indexed purchaseId, uint256 paymentEarning, uint256 inflationBonus, uint8 recipientType);

	// Event to be broadcasted to public when content creator&#39;s Name earns Pathos when a node buys a content
	event PathosEarned(address indexed nameId, bytes32 indexed purchaseId, uint256 amount);

	// Event to be broadcasted to public when host&#39;s Name earns Ethos when a node buys a content
	event EthosEarned(address indexed nameId, bytes32 indexed purchaseId, uint256 amount);

	// Event to be broadcasted to public when emergency mode is triggered
	event EscapeHatch();

	/**
	 * @dev Constructor function
	 * @param _settingTAOId The TAO ID that controls the setting
	 * @param _aoSettingAddress The address of AOSetting
	 * @param _baseDenominationAddress The address of AO base token
	 * @param _treasuryAddress The address of AOTreasury
	 * @param _nameFactoryAddress The address of NameFactory
	 * @param _pathosAddress The address of Pathos
	 * @param _ethosAddress The address of Ethos
	 */
	constructor(address _settingTAOId, address _aoSettingAddress, address _baseDenominationAddress, address _treasuryAddress, address _nameFactoryAddress, address _pathosAddress, address _ethosAddress) public {
		settingTAOId = _settingTAOId;
		aoSettingAddress = _aoSettingAddress;
		baseDenominationAddress = _baseDenominationAddress;
		treasuryAddress = _treasuryAddress;
		pathosAddress = _pathosAddress;
		ethosAddress = _ethosAddress;

		_aoSetting = AOSetting(_aoSettingAddress);
		_baseAO = AOToken(_baseDenominationAddress);
		_treasury = AOTreasury(_treasuryAddress);
		_nameFactory = NameFactory(_nameFactoryAddress);
		_pathos = Pathos(_pathosAddress);
		_ethos = Ethos(_ethosAddress);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Checks if contract is currently active
	 */
	modifier isContractActive {
		require (paused == false && killed == false);
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO pauses/unpauses contract
	 * @param _paused Either to pause contract or not
	 */
	function setPaused(bool _paused) public onlyTheAO {
		paused = _paused;
	}

	/**
	 * @dev The AO triggers emergency mode.
	 *
	 */
	function escapeHatch() public onlyTheAO {
		require (killed == false);
		killed = true;
		emit EscapeHatch();
	}

	/**
	 * @dev The AO updates base denomination address
	 * @param _newBaseDenominationAddress The new address
	 */
	function setBaseDenominationAddress(address _newBaseDenominationAddress) public onlyTheAO {
		require (AOToken(_newBaseDenominationAddress).powerOfTen() == 0);
		baseDenominationAddress = _newBaseDenominationAddress;
		_baseAO = AOToken(baseDenominationAddress);
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Calculate the content creator/host/The AO earning when request node buys the content.
	 *		Also at this stage, all of the earnings are stored in escrow
	 * @param _buyer The request node address that buys the content
	 * @param _purchaseId The ID of the purchase receipt object
	 * @param _networkAmountStaked The amount of network tokens at stake
	 * @param _primordialAmountStaked The amount of primordial tokens at stake
	 * @param _primordialWeightedMultiplierStaked The weighted multiplier of primordial tokens at stake
	 * @param _profitPercentage The content creator&#39;s profit percentage
	 * @param _stakeOwner The address of the stake owner
	 * @param _host The address of the host
	 * @param _isAOContentUsageType whether or not the content is of AO Content Usage Type
	 */
	function calculateEarning(
		address _buyer,
		bytes32 _purchaseId,
		uint256 _networkAmountStaked,
		uint256 _primordialAmountStaked,
		uint256 _primordialWeightedMultiplierStaked,
		uint256 _profitPercentage,
		address _stakeOwner,
		address _host,
		bool _isAOContentUsageType
	) public isContractActive inWhitelist returns (bool) {
		// Split the payment earning between content creator and host and store them in escrow
		_escrowPaymentEarning(_buyer, _purchaseId, _networkAmountStaked.add(_primordialAmountStaked), _profitPercentage, _stakeOwner, _host, _isAOContentUsageType);

		// Calculate the inflation bonus earning for content creator/node/The AO in escrow
		_escrowInflationBonus(_purchaseId, _calculateInflationBonus(_networkAmountStaked, _primordialAmountStaked, _primordialWeightedMultiplierStaked), _profitPercentage, _stakeOwner, _host, _isAOContentUsageType);

		return true;
	}

	/**
	 * @dev Release the payment earning and inflation bonus that is in escrow for specific purchase ID
	 * @param _stakeId The ID of the staked content
	 * @param _contentHostId The ID of the hosted content
	 * @param _purchaseId The purchase receipt ID to check
	 * @param _buyerPaidMoreThanFileSize Whether or not the request node paid more than filesize when buying the content
	 * @param _stakeOwner The address of the stake owner
	 * @param _host The address of the node that host the file
	 * @return true on success
	 */
	function releaseEarning(bytes32 _stakeId, bytes32 _contentHostId, bytes32 _purchaseId, bool _buyerPaidMoreThanFileSize, address _stakeOwner, address _host) public isContractActive inWhitelist returns (bool) {
		// Release the earning in escrow for stake owner
		_releaseEarning(_stakeId, _contentHostId, _purchaseId, _buyerPaidMoreThanFileSize, _stakeOwner, 0);

		// Release the earning in escrow for host
		_releaseEarning(_stakeId, _contentHostId, _purchaseId, _buyerPaidMoreThanFileSize, _host, 1);

		// Release the earning in escrow for The AO
		_releaseEarning(_stakeId, _contentHostId, _purchaseId, _buyerPaidMoreThanFileSize, theAO, 2);

		return true;
	}

	/***** INTERNAL METHODS *****/
	/**
	 * @dev Calculate the payment split for content creator/host and store them in escrow
	 * @param _buyer the request node address that buys the content
	 * @param _purchaseId The ID of the purchase receipt object
	 * @param _totalStaked The total staked amount of the content
	 * @param _profitPercentage The content creator&#39;s profit percentage
	 * @param _stakeOwner The address of the stake owner
	 * @param _host The address of the host
	 * @param _isAOContentUsageType whether or not the content is of AO Content Usage Type
	 */
	function _escrowPaymentEarning(address _buyer, bytes32 _purchaseId, uint256 _totalStaked, uint256 _profitPercentage, address _stakeOwner, address _host, bool _isAOContentUsageType) internal {
		(uint256 _stakeOwnerEarning, uint256 _pathosAmount) = _escrowStakeOwnerPaymentEarning(_buyer, _purchaseId, _totalStaked, _profitPercentage, _stakeOwner, _isAOContentUsageType);
		(uint256 _ethosAmount) = _escrowHostPaymentEarning(_buyer, _purchaseId, _totalStaked, _profitPercentage, _host, _isAOContentUsageType, _stakeOwnerEarning);

		_escrowTheAOPaymentEarning(_purchaseId, _totalStaked, _pathosAmount, _ethosAmount);
	}

	/**
	 * @dev Calculate the inflation bonus amount
	 * @param _networkAmountStaked The amount of network tokens at stake
	 * @param _primordialAmountStaked The amount of primordial tokens at stake
	 * @param _primordialWeightedMultiplierStaked The weighted multiplier of primordial tokens at stake
	 * @return the bonus network amount
	 */
	function _calculateInflationBonus(uint256 _networkAmountStaked, uint256 _primordialAmountStaked, uint256 _primordialWeightedMultiplierStaked) internal view returns (uint256) {
		(uint256 inflationRate,,) = _getSettingVariables();

		uint256 _networkBonus = _networkAmountStaked.mul(inflationRate).div(AOLibrary.PERCENTAGE_DIVISOR());
		uint256 _primordialBonus = _primordialAmountStaked.mul(_primordialWeightedMultiplierStaked).div(AOLibrary.MULTIPLIER_DIVISOR()).mul(inflationRate).div(AOLibrary.PERCENTAGE_DIVISOR());
		return _networkBonus.add(_primordialBonus);
	}

	/**
	 * @dev Mint the inflation bonus for content creator/host/The AO and store them in escrow
	 * @param _purchaseId The ID of the purchase receipt object
	 * @param _inflationBonusAmount The amount of inflation bonus earning
	 * @param _profitPercentage The content creator&#39;s profit percentage
	 * @param _stakeOwner The address of the stake owner
	 * @param _host The address of the host
	 * @param _isAOContentUsageType whether or not the content is of AO Content Usage Type
	 */
	function _escrowInflationBonus(
		bytes32 _purchaseId,
		uint256 _inflationBonusAmount,
		uint256 _profitPercentage,
		address _stakeOwner,
		address _host,
		bool _isAOContentUsageType
	) internal {
		(, uint256 theAOCut,) = _getSettingVariables();

		if (_inflationBonusAmount > 0) {
			// Store how much the content creator earns in escrow
			uint256 _stakeOwnerInflationBonus = _isAOContentUsageType ? (_inflationBonusAmount.mul(_profitPercentage)).div(AOLibrary.PERCENTAGE_DIVISOR()) : 0;
			Earning storage _stakeEarning = stakeEarnings[_stakeOwner][_purchaseId];
			_stakeEarning.inflationBonus = _stakeOwnerInflationBonus;
			require (_baseAO.mintTokenEscrow(_stakeOwner, _stakeEarning.inflationBonus));
			emit InflationBonusEscrowed(_stakeOwner, _purchaseId, _inflationBonusAmount, _profitPercentage, _stakeEarning.inflationBonus, 0);

			// Store how much the host earns in escrow
			Earning storage _hostEarning = hostEarnings[_host][_purchaseId];
			_hostEarning.inflationBonus = _inflationBonusAmount.sub(_stakeOwnerInflationBonus);
			require (_baseAO.mintTokenEscrow(_host, _hostEarning.inflationBonus));
			emit InflationBonusEscrowed(_host, _purchaseId, _inflationBonusAmount, AOLibrary.PERCENTAGE_DIVISOR().sub(_profitPercentage), _hostEarning.inflationBonus, 1);

			// Store how much the The AO earns in escrow
			Earning storage _theAOEarning = theAOEarnings[_purchaseId];
			_theAOEarning.inflationBonus = (_inflationBonusAmount.mul(theAOCut)).div(AOLibrary.PERCENTAGE_DIVISOR());
			require (_baseAO.mintTokenEscrow(theAO, _theAOEarning.inflationBonus));
			emit InflationBonusEscrowed(theAO, _purchaseId, _inflationBonusAmount, theAOCut, _theAOEarning.inflationBonus, 2);
		} else {
			emit InflationBonusEscrowed(_stakeOwner, _purchaseId, 0, _profitPercentage, 0, 0);
			emit InflationBonusEscrowed(_host, _purchaseId, 0, AOLibrary.PERCENTAGE_DIVISOR().sub(_profitPercentage), 0, 1);
			emit InflationBonusEscrowed(theAO, _purchaseId, 0, theAOCut, 0, 2);
		}
	}

	/**
	 * @dev Release the escrowed earning for a specific purchase ID for an account
	 * @param _stakeId The ID of the staked content
	 * @param _contentHostId The ID of the hosted content
	 * @param _purchaseId The purchase receipt ID
	 * @param _buyerPaidMoreThanFileSize Whether or not the request node paid more than filesize when buying the content
	 * @param _account The address of account that made the earning (content creator/host)
	 * @param _recipientType The type of the earning recipient (0 => content creator. 1 => host. 2 => theAO)
	 */
	function _releaseEarning(bytes32 _stakeId, bytes32 _contentHostId, bytes32 _purchaseId, bool _buyerPaidMoreThanFileSize, address _account, uint8 _recipientType) internal {
		// Make sure the recipient type is valid
		require (_recipientType >= 0 && _recipientType <= 2);

		uint256 _paymentEarning;
		uint256 _inflationBonus;
		uint256 _totalEarning;
		uint256 _pathosAmount;
		uint256 _ethosAmount;
		if (_recipientType == 0) {
			Earning storage _earning = stakeEarnings[_account][_purchaseId];
			_paymentEarning = _earning.paymentEarning;
			_inflationBonus = _earning.inflationBonus;
			_pathosAmount = _earning.pathosAmount;
			_earning.paymentEarning = 0;
			_earning.inflationBonus = 0;
			_earning.pathosAmount = 0;
			_earning.ethosAmount = 0;
			_totalEarning = _paymentEarning.add(_inflationBonus);

			// Update the global var settings
			totalStakeContentEarning = totalStakeContentEarning.add(_totalEarning);
			stakeContentEarning[_account] = stakeContentEarning[_account].add(_totalEarning);
			totalStakedContentStakeEarning[_stakeId] = totalStakedContentStakeEarning[_stakeId].add(_totalEarning);
			if (_buyerPaidMoreThanFileSize) {
				contentPriceEarning[_account] = contentPriceEarning[_account].add(_totalEarning);
			} else {
				networkPriceEarning[_account] = networkPriceEarning[_account].add(_totalEarning);
			}
			inflationBonusAccrued[_account] = inflationBonusAccrued[_account].add(_inflationBonus);

			// Reward the content creator/stake owner with some Pathos
			require (_pathos.mintToken(_nameFactory.ethAddressToNameId(_account), _pathosAmount));
			emit PathosEarned(_nameFactory.ethAddressToNameId(_account), _purchaseId, _pathosAmount);
		} else if (_recipientType == 1) {
			_earning = hostEarnings[_account][_purchaseId];
			_paymentEarning = _earning.paymentEarning;
			_inflationBonus = _earning.inflationBonus;
			_ethosAmount = _earning.ethosAmount;
			_earning.paymentEarning = 0;
			_earning.inflationBonus = 0;
			_earning.pathosAmount = 0;
			_earning.ethosAmount = 0;
			_totalEarning = _paymentEarning.add(_inflationBonus);

			// Update the global var settings
			totalHostContentEarning = totalHostContentEarning.add(_totalEarning);
			hostContentEarning[_account] = hostContentEarning[_account].add(_totalEarning);
			totalStakedContentHostEarning[_stakeId] = totalStakedContentHostEarning[_stakeId].add(_totalEarning);
			totalHostContentEarningById[_contentHostId] = totalHostContentEarningById[_contentHostId].add(_totalEarning);
			if (_buyerPaidMoreThanFileSize) {
				contentPriceEarning[_account] = contentPriceEarning[_account].add(_totalEarning);
			} else {
				networkPriceEarning[_account] = networkPriceEarning[_account].add(_totalEarning);
			}
			inflationBonusAccrued[_account] = inflationBonusAccrued[_account].add(_inflationBonus);

			// Reward the host node with some Ethos
			require (_ethos.mintToken(_nameFactory.ethAddressToNameId(_account), _ethosAmount));
			emit EthosEarned(_nameFactory.ethAddressToNameId(_account), _purchaseId, _ethosAmount);
		} else {
			_earning = theAOEarnings[_purchaseId];
			_paymentEarning = _earning.paymentEarning;
			_inflationBonus = _earning.inflationBonus;
			_earning.paymentEarning = 0;
			_earning.inflationBonus = 0;
			_earning.pathosAmount = 0;
			_earning.ethosAmount = 0;
			_totalEarning = _paymentEarning.add(_inflationBonus);

			// Update the global var settings
			totalTheAOEarning = totalTheAOEarning.add(_totalEarning);
			inflationBonusAccrued[_account] = inflationBonusAccrued[_account].add(_inflationBonus);
			totalStakedContentTheAOEarning[_stakeId] = totalStakedContentTheAOEarning[_stakeId].add(_totalEarning);
		}
		require (_baseAO.unescrowFrom(_account, _totalEarning));
		emit EarningUnescrowed(_account, _purchaseId, _paymentEarning, _inflationBonus, _recipientType);
	}

	/**
	 * @dev Get setting variables
	 * @return inflationRate The rate to use when calculating inflation bonus
	 * @return theAOCut The rate to use when calculating the AO earning
	 * @return theAOEthosEarnedRate The rate to use when calculating the Ethos to AO rate for the AO
	 */
	function _getSettingVariables() internal view returns (uint256, uint256, uint256) {
		(uint256 inflationRate,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;inflationRate&#39;);
		(uint256 theAOCut,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;theAOCut&#39;);
		(uint256 theAOEthosEarnedRate,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;theAOEthosEarnedRate&#39;);

		return (inflationRate, theAOCut, theAOEthosEarnedRate);
	}

	/**
	 * @dev Calculate the payment split for content creator and store them in escrow
	 * @param _buyer the request node address that buys the content
	 * @param _purchaseId The ID of the purchase receipt object
	 * @param _totalStaked The total staked amount of the content
	 * @param _profitPercentage The content creator&#39;s profit percentage
	 * @param _stakeOwner The address of the stake owner
	 * @param _isAOContentUsageType whether or not the content is of AO Content Usage Type
	 * @return The stake owner&#39;s earning amount
	 * @return The pathos earned from this transaction
	 */
	function _escrowStakeOwnerPaymentEarning(address _buyer, bytes32 _purchaseId, uint256 _totalStaked, uint256 _profitPercentage, address _stakeOwner, bool _isAOContentUsageType) internal returns (uint256, uint256) {
		(uint256 inflationRate,,) = _getSettingVariables();

		Earning storage _stakeEarning = stakeEarnings[_stakeOwner][_purchaseId];
		_stakeEarning.purchaseId = _purchaseId;
		// Store how much the content creator (stake owner) earns in escrow
		// If content is AO Content Usage Type, stake owner earns 0%
		// and all profit goes to the serving host node
		_stakeEarning.paymentEarning = _isAOContentUsageType ? (_totalStaked.mul(_profitPercentage)).div(AOLibrary.PERCENTAGE_DIVISOR()) : 0;
		// Pathos = Price X Node Share X Inflation Rate
		_stakeEarning.pathosAmount = _totalStaked.mul(AOLibrary.PERCENTAGE_DIVISOR().sub(_profitPercentage)).mul(inflationRate).div(AOLibrary.PERCENTAGE_DIVISOR()).div(AOLibrary.PERCENTAGE_DIVISOR());
		require (_baseAO.escrowFrom(_buyer, _stakeOwner, _stakeEarning.paymentEarning));
		emit PaymentEarningEscrowed(_stakeOwner, _purchaseId, _totalStaked, _profitPercentage, _stakeEarning.paymentEarning, 0);
		return (_stakeEarning.paymentEarning, _stakeEarning.pathosAmount);
	}

	/**
	 * @dev Calculate the payment split for host node and store them in escrow
	 * @param _buyer the request node address that buys the content
	 * @param _purchaseId The ID of the purchase receipt object
	 * @param _totalStaked The total staked amount of the content
	 * @param _profitPercentage The content creator&#39;s profit percentage
	 * @param _host The address of the host node
	 * @param _isAOContentUsageType whether or not the content is of AO Content Usage Type
	 * @param _stakeOwnerEarning The stake owner&#39;s earning amount
	 * @return The ethos earned from this transaction
	 */
	function _escrowHostPaymentEarning(address _buyer, bytes32 _purchaseId, uint256 _totalStaked, uint256 _profitPercentage, address _host, bool _isAOContentUsageType, uint256 _stakeOwnerEarning) internal returns (uint256) {
		(uint256 inflationRate,,) = _getSettingVariables();

		// Store how much the node host earns in escrow
		Earning storage _hostEarning = hostEarnings[_host][_purchaseId];
		_hostEarning.purchaseId = _purchaseId;
		_hostEarning.paymentEarning = _totalStaked.sub(_stakeOwnerEarning);
		// Ethos = Price X Creator Share X Inflation Rate
		_hostEarning.ethosAmount = _totalStaked.mul(_profitPercentage).mul(inflationRate).div(AOLibrary.PERCENTAGE_DIVISOR()).div(AOLibrary.PERCENTAGE_DIVISOR());

		if (_isAOContentUsageType) {
			require (_baseAO.escrowFrom(_buyer, _host, _hostEarning.paymentEarning));
		} else {
			// If not AO Content usage type, we want to mint to the host
			require (_baseAO.mintTokenEscrow(_host, _hostEarning.paymentEarning));
		}
		emit PaymentEarningEscrowed(_host, _purchaseId, _totalStaked, AOLibrary.PERCENTAGE_DIVISOR().sub(_profitPercentage), _hostEarning.paymentEarning, 1);
		return _hostEarning.ethosAmount;
	}

	/**
	 * @dev Calculate the earning for The AO and store them in escrow
	 * @param _purchaseId The ID of the purchase receipt object
	 * @param _totalStaked The total staked amount of the content
	 * @param _pathosAmount The amount of pathos earned by stake owner
	 * @param _ethosAmount The amount of ethos earned by host node
	 */
	function _escrowTheAOPaymentEarning(bytes32 _purchaseId, uint256 _totalStaked, uint256 _pathosAmount, uint256 _ethosAmount) internal {
		(,,uint256 theAOEthosEarnedRate) = _getSettingVariables();

		// Store how much The AO earns in escrow
		Earning storage _theAOEarning = theAOEarnings[_purchaseId];
		_theAOEarning.purchaseId = _purchaseId;
		// Pathos + X% of Ethos
		_theAOEarning.paymentEarning = _pathosAmount.add(_ethosAmount.mul(theAOEthosEarnedRate).div(AOLibrary.PERCENTAGE_DIVISOR()));
		require (_baseAO.mintTokenEscrow(theAO, _theAOEarning.paymentEarning));
		emit PaymentEarningEscrowed(theAO, _purchaseId, _totalStaked, 0, _theAOEarning.paymentEarning, 2);
	}
}





/**
 * @title AOContent
 *
 * The purpose of this contract is to allow content creator to stake network ERC20 AO tokens and/or primordial AO Tokens
 * on his/her content
 */
contract AOContent is TheAO {
	using SafeMath for uint256;

	uint256 public totalContents;
	uint256 public totalContentHosts;
	uint256 public totalStakedContents;
	uint256 public totalPurchaseReceipts;

	address public settingTAOId;
	address public baseDenominationAddress;
	address public treasuryAddress;

	AOToken internal _baseAO;
	AOTreasury internal _treasury;
	AOEarning internal _earning;
	AOSetting internal _aoSetting;
	NameTAOPosition internal _nameTAOPosition;

	bool public paused;
	bool public killed;

	struct Content {
		bytes32 contentId;
		address creator;
		/**
		 * baseChallenge is the content&#39;s PUBLIC KEY
		 * When a request node wants to be a host, it is required to send a signed base challenge (its content&#39;s PUBLIC KEY)
		 * so that the contract can verify the authenticity of the content by comparing what the contract has and what the request node
		 * submit
		 */
		string baseChallenge;
		uint256 fileSize;
		bytes32 contentUsageType; // i.e AO Content, Creative Commons, or T(AO) Content
		address taoId;
		bytes32 taoContentState; // i.e Submitted, Pending Review, Accepted to TAO
		uint8 updateTAOContentStateV;
		bytes32 updateTAOContentStateR;
		bytes32 updateTAOContentStateS;
		string extraData;
	}

	struct StakedContent {
		bytes32 stakeId;
		bytes32 contentId;
		address stakeOwner;
		uint256 networkAmount; // total network token staked in base denomination
		uint256 primordialAmount;	// the amount of primordial AO Token to stake (always in base denomination)
		uint256 primordialWeightedMultiplier;
		uint256 profitPercentage; // support up to 4 decimals, 100% = 1000000
		bool active; // true if currently staked, false when unstaked
		uint256 createdOnTimestamp;
	}

	struct ContentHost {
		bytes32 contentHostId;
		bytes32 stakeId;
		address host;
		/**
		 * encChallenge is the content&#39;s PUBLIC KEY unique to the host
		 */
		string encChallenge;
		string contentDatKey;
		string metadataDatKey;
	}

	struct PurchaseReceipt {
		bytes32 purchaseId;
		bytes32 contentHostId;
		address buyer;
		uint256 price;
		uint256 amountPaidByBuyer;	// total network token paid in base denomination
		uint256 amountPaidByAO; // total amount paid by AO
		string publicKey; // The public key provided by request node
		address publicAddress; // The public address provided by request node
		uint256 createdOnTimestamp;
	}

	// Mapping from Content index to the Content object
	mapping (uint256 => Content) internal contents;

	// Mapping from content ID to index of the contents list
	mapping (bytes32 => uint256) internal contentIndex;

	// Mapping from StakedContent index to the StakedContent object
	mapping (uint256 => StakedContent) internal stakedContents;

	// Mapping from stake ID to index of the stakedContents list
	mapping (bytes32 => uint256) internal stakedContentIndex;

	// Mapping from ContentHost index to the ContentHost object
	mapping (uint256 => ContentHost) internal contentHosts;

	// Mapping from content host ID to index of the contentHosts list
	mapping (bytes32 => uint256) internal contentHostIndex;

	// Mapping from PurchaseReceipt index to the PurchaseReceipt object
	mapping (uint256 => PurchaseReceipt) internal purchaseReceipts;

	// Mapping from purchase ID to index of the purchaseReceipts list
	mapping (bytes32 => uint256) internal purchaseReceiptIndex;

	// Mapping from buyer&#39;s content host ID to the buy ID
	// To check whether or not buyer has bought/paid for a content
	mapping (address => mapping (bytes32 => bytes32)) public buyerPurchaseReceipts;

	// Event to be broadcasted to public when `content` is stored
	event StoreContent(address indexed creator, bytes32 indexed contentId, uint256 fileSize, bytes32 contentUsageType);

	// Event to be broadcasted to public when `stakeOwner` stakes a new content
	event StakeContent(address indexed stakeOwner, bytes32 indexed stakeId, bytes32 indexed contentId, uint256 baseNetworkAmount, uint256 primordialAmount, uint256 primordialWeightedMultiplier, uint256 profitPercentage, uint256 createdOnTimestamp);

	// Event to be broadcasted to public when a node hosts a content
	event HostContent(address indexed host, bytes32 indexed contentHostId, bytes32 stakeId, string contentDatKey, string metadataDatKey);

	// Event to be broadcasted to public when `stakeOwner` updates the staked content&#39;s profit percentage
	event SetProfitPercentage(address indexed stakeOwner, bytes32 indexed stakeId, uint256 newProfitPercentage);

	// Event to be broadcasted to public when `stakeOwner` unstakes some network/primordial token from an existing content
	event UnstakePartialContent(address indexed stakeOwner, bytes32 indexed stakeId, bytes32 indexed contentId, uint256 remainingNetworkAmount, uint256 remainingPrimordialAmount, uint256 primordialWeightedMultiplier);

	// Event to be broadcasted to public when `stakeOwner` unstakes all token amount on an existing content
	event UnstakeContent(address indexed stakeOwner, bytes32 indexed stakeId);

	// Event to be broadcasted to public when `stakeOwner` re-stakes an existing content
	event StakeExistingContent(address indexed stakeOwner, bytes32 indexed stakeId, bytes32 indexed contentId, uint256 currentNetworkAmount, uint256 currentPrimordialAmount, uint256 currentPrimordialWeightedMultiplier);

	// Event to be broadcasted to public when a request node buys a content
	event BuyContent(address indexed buyer, bytes32 indexed purchaseId, bytes32 indexed contentHostId, uint256 price, uint256 amountPaidByAO, uint256 amountPaidByBuyer, string publicKey, address publicAddress, uint256 createdOnTimestamp);

	// Event to be broadcasted to public when Advocate/Listener/Speaker wants to update the TAO Content&#39;s State
	event UpdateTAOContentState(bytes32 indexed contentId, address indexed taoId, address signer, bytes32 taoContentState);

	// Event to be broadcasted to public when emergency mode is triggered
	event EscapeHatch();

	/**
	 * @dev Constructor function
	 * @param _settingTAOId The TAO ID that controls the setting
	 * @param _aoSettingAddress The address of AOSetting
	 * @param _baseDenominationAddress The address of AO base token
	 * @param _treasuryAddress The address of AOTreasury
	 * @param _earningAddress The address of AOEarning
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	constructor(address _settingTAOId, address _aoSettingAddress, address _baseDenominationAddress, address _treasuryAddress, address _earningAddress, address _nameTAOPositionAddress) public {
		settingTAOId = _settingTAOId;
		baseDenominationAddress = _baseDenominationAddress;
		treasuryAddress = _treasuryAddress;
		nameTAOPositionAddress = _nameTAOPositionAddress;

		_baseAO = AOToken(_baseDenominationAddress);
		_treasury = AOTreasury(_treasuryAddress);
		_earning = AOEarning(_earningAddress);
		_aoSetting = AOSetting(_aoSettingAddress);
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/**
	 * @dev Checks if contract is currently active
	 */
	modifier isContractActive {
		require (paused == false && killed == false);
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev The AO pauses/unpauses contract
	 * @param _paused Either to pause contract or not
	 */
	function setPaused(bool _paused) public onlyTheAO {
		paused = _paused;
	}

	/**
	 * @dev The AO triggers emergency mode.
	 *
	 */
	function escapeHatch() public onlyTheAO {
		require (killed == false);
		killed = true;
		emit EscapeHatch();
	}

	/**
	 * @dev The AO updates base denomination address
	 * @param _newBaseDenominationAddress The new address
	 */
	function setBaseDenominationAddress(address _newBaseDenominationAddress) public onlyTheAO {
		require (AOToken(_newBaseDenominationAddress).powerOfTen() == 0);
		baseDenominationAddress = _newBaseDenominationAddress;
		_baseAO = AOToken(baseDenominationAddress);
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Stake `_networkIntegerAmount` + `_networkFractionAmount` of network token in `_denomination` and/or `_primordialAmount` primordial Tokens for an AO Content
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake
	 * @param _baseChallenge The base challenge string (PUBLIC KEY) of the content
	 * @param _encChallenge The encrypted challenge string (PUBLIC KEY) of the content unique to the host
	 * @param _contentDatKey The dat key of the content
	 * @param _metadataDatKey The dat key of the content&#39;s metadata
	 * @param _fileSize The size of the file
	 * @param _profitPercentage The percentage of profit the stake owner&#39;s media will charge
	 */
	function stakeAOContent(
		uint256 _networkIntegerAmount,
		uint256 _networkFractionAmount,
		bytes8 _denomination,
		uint256 _primordialAmount,
		string _baseChallenge,
		string _encChallenge,
		string _contentDatKey,
		string _metadataDatKey,
		uint256 _fileSize,
		uint256 _profitPercentage)
		public isContractActive {
		require (AOLibrary.canStake(treasuryAddress, _networkIntegerAmount, _networkFractionAmount, _denomination, _primordialAmount, _baseChallenge, _encChallenge, _contentDatKey, _metadataDatKey, _fileSize, _profitPercentage));
		(bytes32 _contentUsageType_aoContent,,,,,) = _getSettingVariables();

		/**
		 * 1. Store this content
		 * 2. Stake the network/primordial token on content
		 * 3. Add the node info that hosts this content (in this case the creator himself)
		 */
		_hostContent(
			msg.sender,
			_stakeContent(
				msg.sender,
				_storeContent(
					msg.sender,
					_baseChallenge,
					_fileSize,
					_contentUsageType_aoContent,
					address(0)
				),
				_networkIntegerAmount,
				_networkFractionAmount,
				_denomination,
				_primordialAmount,
				_profitPercentage
			),
			_encChallenge,
			_contentDatKey,
			_metadataDatKey
		);
	}

	/**
	 * @dev Stake `_networkIntegerAmount` + `_networkFractionAmount` of network token in `_denomination` and/or `_primordialAmount` primordial Tokens for a Creative Commons Content
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake
	 * @param _baseChallenge The base challenge string (PUBLIC KEY) of the content
	 * @param _encChallenge The encrypted challenge string (PUBLIC KEY) of the content unique to the host
	 * @param _contentDatKey The dat key of the content
	 * @param _metadataDatKey The dat key of the content&#39;s metadata
	 * @param _fileSize The size of the file
	 */
	function stakeCreativeCommonsContent(
		uint256 _networkIntegerAmount,
		uint256 _networkFractionAmount,
		bytes8 _denomination,
		uint256 _primordialAmount,
		string _baseChallenge,
		string _encChallenge,
		string _contentDatKey,
		string _metadataDatKey,
		uint256 _fileSize)
		public isContractActive {
		require (AOLibrary.canStake(treasuryAddress, _networkIntegerAmount, _networkFractionAmount, _denomination, _primordialAmount, _baseChallenge, _encChallenge, _contentDatKey, _metadataDatKey, _fileSize, 0));
		require (_treasury.toBase(_networkIntegerAmount, _networkFractionAmount, _denomination).add(_primordialAmount) == _fileSize);

		(,bytes32 _contentUsageType_creativeCommons,,,,) = _getSettingVariables();

		/**
		 * 1. Store this content
		 * 2. Stake the network/primordial token on content
		 * 3. Add the node info that hosts this content (in this case the creator himself)
		 */
		_hostContent(
			msg.sender,
			_stakeContent(
				msg.sender,
				_storeContent(
					msg.sender,
					_baseChallenge,
					_fileSize,
					_contentUsageType_creativeCommons,
					address(0)
				),
				_networkIntegerAmount,
				_networkFractionAmount,
				_denomination,
				_primordialAmount,
				0
			),
			_encChallenge,
			_contentDatKey,
			_metadataDatKey
		);
	}

	/**
	 * @dev Stake `_networkIntegerAmount` + `_networkFractionAmount` of network token in `_denomination` and/or `_primordialAmount` primordial Tokens for a T(AO) Content
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake
	 * @param _baseChallenge The base challenge string (PUBLIC KEY) of the content
	 * @param _encChallenge The encrypted challenge string (PUBLIC KEY) of the content unique to the host
	 * @param _contentDatKey The dat key of the content
	 * @param _metadataDatKey The dat key of the content&#39;s metadata
	 * @param _fileSize The size of the file
	 * @param _taoId The TAO (TAO) ID for this content (if this is a T(AO) Content)
	 */
	function stakeTAOContent(
		uint256 _networkIntegerAmount,
		uint256 _networkFractionAmount,
		bytes8 _denomination,
		uint256 _primordialAmount,
		string _baseChallenge,
		string _encChallenge,
		string _contentDatKey,
		string _metadataDatKey,
		uint256 _fileSize,
		address _taoId)
		public isContractActive {
		require (AOLibrary.canStake(treasuryAddress, _networkIntegerAmount, _networkFractionAmount, _denomination, _primordialAmount, _baseChallenge, _encChallenge, _contentDatKey, _metadataDatKey, _fileSize, 0));
		require (
			_treasury.toBase(_networkIntegerAmount, _networkFractionAmount, _denomination).add(_primordialAmount) == _fileSize &&
			_nameTAOPosition.senderIsPosition(msg.sender, _taoId)
		);

		(,,bytes32 _contentUsageType_taoContent,,,) = _getSettingVariables();

		/**
		 * 1. Store this content
		 * 2. Stake the network/primordial token on content
		 * 3. Add the node info that hosts this content (in this case the creator himself)
		 */
		_hostContent(
			msg.sender,
			_stakeContent(
				msg.sender,
				_storeContent(
					msg.sender,
					_baseChallenge,
					_fileSize,
					_contentUsageType_taoContent,
					_taoId
				),
				_networkIntegerAmount,
				_networkFractionAmount,
				_denomination,
				_primordialAmount,
				0
			),
			_encChallenge,
			_contentDatKey,
			_metadataDatKey
		);
	}

	/**
	 * @dev Set profit percentage on existing staked content
	 *		Will throw error if this is a Creative Commons/T(AO) Content
	 * @param _stakeId The ID of the staked content
	 * @param _profitPercentage The new value to be set
	 */
	function setProfitPercentage(bytes32 _stakeId, uint256 _profitPercentage) public isContractActive {
		require (_profitPercentage <= AOLibrary.PERCENTAGE_DIVISOR());

		// Make sure the staked content exist
		require (stakedContentIndex[_stakeId] > 0);

		StakedContent storage _stakedContent = stakedContents[stakedContentIndex[_stakeId]];
		// Make sure the staked content owner is the same as the sender
		require (_stakedContent.stakeOwner == msg.sender);

		// Make sure we are updating profit percentage for AO Content only
		// Creative Commons/T(AO) Content has 0 profit percentage
		require (_isAOContentUsageType(_stakedContent.contentId));

		_stakedContent.profitPercentage = _profitPercentage;

		emit SetProfitPercentage(msg.sender, _stakeId, _profitPercentage);
	}

	/**
	 * @dev Set extra data on existing content
	 * @param _contentId The ID of the content
	 * @param _extraData some extra information to send to the contract for a content
	 */
	function setContentExtraData(bytes32 _contentId, string _extraData) public isContractActive {
		// Make sure the content exist
		require (contentIndex[_contentId] > 0);

		Content storage _content = contents[contentIndex[_contentId]];
		// Make sure the content creator is the same as the sender
		require (_content.creator == msg.sender);

		_content.extraData = _extraData;
	}

	/**
	 * @dev Return content info at a given ID
	 * @param _contentId The ID of the content
	 * @return address of the creator
	 * @return file size of the content
	 * @return the content usage type, i.e AO Content, Creative Commons, or T(AO) Content
	 * @return The TAO ID for this content (if this is a T(AO) Content)
	 * @return The TAO Content state, i.e Submitted, Pending Review, or Accepted to TAO
	 * @return The V part of signature that is used to update the TAO Content State
	 * @return The R part of signature that is used to update the TAO Content State
	 * @return The S part of signature that is used to update the TAO Content State
	 * @return the extra information sent to the contract when creating a content
	 */
	function contentById(bytes32 _contentId) public view returns (address, uint256, bytes32, address, bytes32, uint8, bytes32, bytes32, string) {
		// Make sure the content exist
		require (contentIndex[_contentId] > 0);
		Content memory _content = contents[contentIndex[_contentId]];
		return (
			_content.creator,
			_content.fileSize,
			_content.contentUsageType,
			_content.taoId,
			_content.taoContentState,
			_content.updateTAOContentStateV,
			_content.updateTAOContentStateR,
			_content.updateTAOContentStateS,
			_content.extraData
		);
	}

	/**
	 * @dev Return content host info at a given ID
	 * @param _contentHostId The ID of the hosted content
	 * @return The ID of the staked content
	 * @return address of the host
	 * @return the dat key of the content
	 * @return the dat key of the content&#39;s metadata
	 */
	function contentHostById(bytes32 _contentHostId) public view returns (bytes32, address, string, string) {
		// Make sure the content host exist
		require (contentHostIndex[_contentHostId] > 0);
		ContentHost memory _contentHost = contentHosts[contentHostIndex[_contentHostId]];
		return (
			_contentHost.stakeId,
			_contentHost.host,
			_contentHost.contentDatKey,
			_contentHost.metadataDatKey
		);
	}

	/**
	 * @dev Return staked content information at a given ID
	 * @param _stakeId The ID of the staked content
	 * @return The ID of the content being staked
	 * @return address of the staked content&#39;s owner
	 * @return the network base token amount staked for this content
	 * @return the primordial token amount staked for this content
	 * @return the primordial weighted multiplier of the staked content
	 * @return the profit percentage of the content
	 * @return status of the staked content
	 * @return the timestamp when the staked content was created
	 */
	function stakedContentById(bytes32 _stakeId) public view returns (bytes32, address, uint256, uint256, uint256, uint256, bool, uint256) {
		// Make sure the staked content exist
		require (stakedContentIndex[_stakeId] > 0);

		StakedContent memory _stakedContent = stakedContents[stakedContentIndex[_stakeId]];
		return (
			_stakedContent.contentId,
			_stakedContent.stakeOwner,
			_stakedContent.networkAmount,
			_stakedContent.primordialAmount,
			_stakedContent.primordialWeightedMultiplier,
			_stakedContent.profitPercentage,
			_stakedContent.active,
			_stakedContent.createdOnTimestamp
		);
	}

	/**
	 * @dev Unstake existing staked content and refund partial staked amount to the stake owner
	 *		Use unstakeContent() to unstake all staked token amount. unstakePartialContent() can unstake only up to
	 *		the mininum required to pay the fileSize
	 * @param _stakeId The ID of the staked content
	 * @param _networkIntegerAmount The integer amount of network token to unstake
	 * @param _networkFractionAmount The fraction amount of network token to unstake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to unstake
	 */
	function unstakePartialContent(bytes32 _stakeId, uint256 _networkIntegerAmount, uint256 _networkFractionAmount, bytes8 _denomination, uint256 _primordialAmount) public isContractActive {
		// Make sure the staked content exist
		require (stakedContentIndex[_stakeId] > 0);
		require (_networkIntegerAmount > 0 || _networkFractionAmount > 0 || _primordialAmount > 0);

		StakedContent storage _stakedContent = stakedContents[stakedContentIndex[_stakeId]];
		uint256 _fileSize = contents[contentIndex[_stakedContent.contentId]].fileSize;

		// Make sure the staked content owner is the same as the sender
		require (_stakedContent.stakeOwner == msg.sender);
		// Make sure the staked content is currently active (staked) with some amounts
		require (_stakedContent.active == true && (_stakedContent.networkAmount > 0 || (_stakedContent.primordialAmount > 0 && _stakedContent.primordialWeightedMultiplier > 0)));
		// Make sure the staked content has enough balance to unstake
		require (AOLibrary.canUnstakePartial(treasuryAddress, _networkIntegerAmount, _networkFractionAmount, _denomination, _primordialAmount, _stakedContent.networkAmount, _stakedContent.primordialAmount, _fileSize));

		if (_denomination[0] != 0 && (_networkIntegerAmount > 0 || _networkFractionAmount > 0)) {
			uint256 _unstakeNetworkAmount = _treasury.toBase(_networkIntegerAmount, _networkFractionAmount, _denomination);
			_stakedContent.networkAmount = _stakedContent.networkAmount.sub(_unstakeNetworkAmount);
			require (_baseAO.unstakeFrom(msg.sender, _unstakeNetworkAmount));
		}
		if (_primordialAmount > 0) {
			_stakedContent.primordialAmount = _stakedContent.primordialAmount.sub(_primordialAmount);
			require (_baseAO.unstakePrimordialTokenFrom(msg.sender, _primordialAmount, _stakedContent.primordialWeightedMultiplier));
		}
		emit UnstakePartialContent(_stakedContent.stakeOwner, _stakedContent.stakeId, _stakedContent.contentId, _stakedContent.networkAmount, _stakedContent.primordialAmount, _stakedContent.primordialWeightedMultiplier);
	}

	/**
	 * @dev Unstake existing staked content and refund the total staked amount to the stake owner
	 * @param _stakeId The ID of the staked content
	 */
	function unstakeContent(bytes32 _stakeId) public isContractActive {
		// Make sure the staked content exist
		require (stakedContentIndex[_stakeId] > 0);

		StakedContent storage _stakedContent = stakedContents[stakedContentIndex[_stakeId]];
		// Make sure the staked content owner is the same as the sender
		require (_stakedContent.stakeOwner == msg.sender);
		// Make sure the staked content is currently active (staked) with some amounts
		require (_stakedContent.active == true && (_stakedContent.networkAmount > 0 || (_stakedContent.primordialAmount > 0 && _stakedContent.primordialWeightedMultiplier > 0)));

		_stakedContent.active = false;

		if (_stakedContent.networkAmount > 0) {
			uint256 _unstakeNetworkAmount = _stakedContent.networkAmount;
			_stakedContent.networkAmount = 0;
			require (_baseAO.unstakeFrom(msg.sender, _unstakeNetworkAmount));
		}
		if (_stakedContent.primordialAmount > 0) {
			uint256 _primordialAmount = _stakedContent.primordialAmount;
			uint256 _primordialWeightedMultiplier = _stakedContent.primordialWeightedMultiplier;
			_stakedContent.primordialAmount = 0;
			_stakedContent.primordialWeightedMultiplier = 0;
			require (_baseAO.unstakePrimordialTokenFrom(msg.sender, _primordialAmount, _primordialWeightedMultiplier));
		}
		emit UnstakeContent(_stakedContent.stakeOwner, _stakeId);
	}

	/**
	 * @dev Stake existing content with more tokens (this is to increase the price)
	 *
	 * @param _stakeId The ID of the staked content
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake. (The primordial weighted multiplier has to match the current staked weighted multiplier)
	 */
	function stakeExistingContent(bytes32 _stakeId, uint256 _networkIntegerAmount, uint256 _networkFractionAmount, bytes8 _denomination, uint256 _primordialAmount) public isContractActive {
		// Make sure the staked content exist
		require (stakedContentIndex[_stakeId] > 0);

		StakedContent storage _stakedContent = stakedContents[stakedContentIndex[_stakeId]];
		uint256 _fileSize = contents[contentIndex[_stakedContent.contentId]].fileSize;

		// Make sure the staked content owner is the same as the sender
		require (_stakedContent.stakeOwner == msg.sender);
		require (_networkIntegerAmount > 0 || _networkFractionAmount > 0 || _primordialAmount > 0);
		require (AOLibrary.canStakeExisting(treasuryAddress, _isAOContentUsageType(_stakedContent.contentId), _fileSize, _stakedContent.networkAmount.add(_stakedContent.primordialAmount), _networkIntegerAmount, _networkFractionAmount, _denomination, _primordialAmount));

		// Make sure we can stake primordial token
		// If we are currently staking an active staked content, then the stake owner&#39;s weighted multiplier has to match `stakedContent.primordialWeightedMultiplier`
		// i.e, can&#39;t use a combination of different weighted multiplier. Stake owner has to call unstakeContent() to unstake all tokens first
		if (_primordialAmount > 0 && _stakedContent.active && _stakedContent.primordialAmount > 0 && _stakedContent.primordialWeightedMultiplier > 0) {
			require (_baseAO.weightedMultiplierByAddress(msg.sender) == _stakedContent.primordialWeightedMultiplier);
		}

		_stakedContent.active = true;
		if (_denomination[0] != 0 && (_networkIntegerAmount > 0 || _networkFractionAmount > 0)) {
			uint256 _stakeNetworkAmount = _treasury.toBase(_networkIntegerAmount, _networkFractionAmount, _denomination);
			_stakedContent.networkAmount = _stakedContent.networkAmount.add(_stakeNetworkAmount);
			require (_baseAO.stakeFrom(_stakedContent.stakeOwner, _stakeNetworkAmount));
		}
		if (_primordialAmount > 0) {
			_stakedContent.primordialAmount = _stakedContent.primordialAmount.add(_primordialAmount);

			// Primordial Token is the base AO Token
			_stakedContent.primordialWeightedMultiplier = _baseAO.weightedMultiplierByAddress(_stakedContent.stakeOwner);
			require (_baseAO.stakePrimordialTokenFrom(_stakedContent.stakeOwner, _primordialAmount, _stakedContent.primordialWeightedMultiplier));
		}

		emit StakeExistingContent(msg.sender, _stakedContent.stakeId, _stakedContent.contentId, _stakedContent.networkAmount, _stakedContent.primordialAmount, _stakedContent.primordialWeightedMultiplier);
	}

	/**
	 * @dev Determine the content price hosted by a host
	 * @param _contentHostId The content host ID to be checked
	 * @return the price of the content
	 */
	function contentHostPrice(bytes32 _contentHostId) public isContractActive view returns (uint256) {
		// Make sure content host exist
		require (contentHostIndex[_contentHostId] > 0);

		bytes32 _stakeId = contentHosts[contentHostIndex[_contentHostId]].stakeId;
		StakedContent memory _stakedContent = stakedContents[stakedContentIndex[_stakeId]];
		// Make sure content is currently staked
		require (_stakedContent.active == true && (_stakedContent.networkAmount > 0 || (_stakedContent.primordialAmount > 0 && _stakedContent.primordialWeightedMultiplier > 0)));
		return _stakedContent.networkAmount.add(_stakedContent.primordialAmount);
	}

	/**
	 * @dev Determine the how much the content is paid by AO given a contentHostId
	 * @param _contentHostId The content host ID to be checked
	 * @return the amount paid by AO
	 */
	function contentHostPaidByAO(bytes32 _contentHostId) public isContractActive view returns (uint256) {
		bytes32 _stakeId = contentHosts[contentHostIndex[_contentHostId]].stakeId;
		bytes32 _contentId = stakedContents[stakedContentIndex[_stakeId]].contentId;
		if (_isAOContentUsageType(_contentId)) {
			return 0;
		} else {
			return contentHostPrice(_contentHostId);
		}
	}

	/**
	 * @dev Bring content in to the requesting node by sending network tokens to the contract to pay for the content
	 * @param _contentHostId The ID of hosted content
	 * @param _networkIntegerAmount The integer amount of network token to pay
	 * @param _networkFractionAmount The fraction amount of network token to pay
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _publicKey The public key of the request node
	 * @param _publicAddress The public address of the request node
	 */
	function buyContent(bytes32 _contentHostId, uint256 _networkIntegerAmount, uint256 _networkFractionAmount, bytes8 _denomination, string _publicKey, address _publicAddress) public isContractActive {
		// Make sure the content host exist
		require (contentHostIndex[_contentHostId] > 0);

		// Make sure public key is not empty
		require (bytes(_publicKey).length > 0);

		// Make sure public address is valid
		require (_publicAddress != address(0));

		ContentHost memory _contentHost = contentHosts[contentHostIndex[_contentHostId]];
		StakedContent memory _stakedContent = stakedContents[stakedContentIndex[_contentHost.stakeId]];

		// Make sure the content currently has stake
		require (_stakedContent.active == true && (_stakedContent.networkAmount > 0 || (_stakedContent.primordialAmount > 0 && _stakedContent.primordialWeightedMultiplier > 0)));

		// Make sure the buyer has not bought this content previously
		require (buyerPurchaseReceipts[msg.sender][_contentHostId][0] == 0);

		// Make sure the token amount can pay for the content price
		if (_isAOContentUsageType(_stakedContent.contentId)) {
			require (AOLibrary.canBuy(treasuryAddress, _stakedContent.networkAmount.add(_stakedContent.primordialAmount), _networkIntegerAmount, _networkFractionAmount, _denomination));
		}

		// Increment totalPurchaseReceipts;
		totalPurchaseReceipts++;

		// Generate purchaseId
		bytes32 _purchaseId = keccak256(abi.encodePacked(this, msg.sender, _contentHostId));
		PurchaseReceipt storage _purchaseReceipt = purchaseReceipts[totalPurchaseReceipts];

		// Make sure the node doesn&#39;t buy the same content twice
		require (_purchaseReceipt.buyer == address(0));

		_purchaseReceipt.purchaseId = _purchaseId;
		_purchaseReceipt.contentHostId = _contentHostId;
		_purchaseReceipt.buyer = msg.sender;
		// Update the receipt with the correct network amount
		_purchaseReceipt.price = _stakedContent.networkAmount.add(_stakedContent.primordialAmount);
		_purchaseReceipt.amountPaidByAO = contentHostPaidByAO(_contentHostId);
		_purchaseReceipt.amountPaidByBuyer = _purchaseReceipt.price.sub(_purchaseReceipt.amountPaidByAO);
		_purchaseReceipt.publicKey = _publicKey;
		_purchaseReceipt.publicAddress = _publicAddress;
		_purchaseReceipt.createdOnTimestamp = now;

		purchaseReceiptIndex[_purchaseId] = totalPurchaseReceipts;
		buyerPurchaseReceipts[msg.sender][_contentHostId] = _purchaseId;

		// Calculate content creator/host/The AO earning from this purchase and store them in escrow
		require (_earning.calculateEarning(
			msg.sender,
			_purchaseId,
			_stakedContent.networkAmount,
			_stakedContent.primordialAmount,
			_stakedContent.primordialWeightedMultiplier,
			_stakedContent.profitPercentage,
			_stakedContent.stakeOwner,
			_contentHost.host,
			_isAOContentUsageType(_stakedContent.contentId)
		));

		emit BuyContent(_purchaseReceipt.buyer, _purchaseReceipt.purchaseId, _purchaseReceipt.contentHostId, _purchaseReceipt.price, _purchaseReceipt.amountPaidByAO, _purchaseReceipt.amountPaidByBuyer, _purchaseReceipt.publicKey, _purchaseReceipt.publicAddress, _purchaseReceipt.createdOnTimestamp);
	}

	/**
	 * @dev Return purchase receipt info at a given ID
	 * @param _purchaseId The ID of the purchased content
	 * @return The ID of the content host
	 * @return address of the buyer
	 * @return price of the content
	 * @return amount paid by AO
	 * @return amount paid by Buyer
	 * @return request node&#39;s public key
	 * @return request node&#39;s public address
	 * @return created on timestamp
	 */
	function purchaseReceiptById(bytes32 _purchaseId) public view returns (bytes32, address, uint256, uint256, uint256, string, address, uint256) {
		// Make sure the purchase receipt exist
		require (purchaseReceiptIndex[_purchaseId] > 0);
		PurchaseReceipt memory _purchaseReceipt = purchaseReceipts[purchaseReceiptIndex[_purchaseId]];
		return (
			_purchaseReceipt.contentHostId,
			_purchaseReceipt.buyer,
			_purchaseReceipt.price,
			_purchaseReceipt.amountPaidByAO,
			_purchaseReceipt.amountPaidByBuyer,
			_purchaseReceipt.publicKey,
			_purchaseReceipt.publicAddress,
			_purchaseReceipt.createdOnTimestamp
		);
	}

	/**
	 * @dev Request node wants to become a distribution node after buying the content
	 *		Also, if this transaction succeeds, contract will release all of the earnings that are
	 *		currently in escrow for content creator/host/The AO
	 */
	function becomeHost(
		bytes32 _purchaseId,
		uint8 _baseChallengeV,
		bytes32 _baseChallengeR,
		bytes32 _baseChallengeS,
		string _encChallenge,
		string _contentDatKey,
		string _metadataDatKey
	) public isContractActive {
		// Make sure the purchase receipt exist
		require (purchaseReceiptIndex[_purchaseId] > 0);

		PurchaseReceipt memory _purchaseReceipt = purchaseReceipts[purchaseReceiptIndex[_purchaseId]];
		bytes32 _stakeId = contentHosts[contentHostIndex[_purchaseReceipt.contentHostId]].stakeId;
		bytes32 _contentId = stakedContents[stakedContentIndex[_stakeId]].contentId;

		// Make sure the purchase receipt owner is the same as the sender
		require (_purchaseReceipt.buyer == msg.sender);

		// Verify that the file is not tampered by validating the base challenge signature
		// The signed base challenge key should match the one from content creator
		Content memory _content = contents[contentIndex[_contentId]];
		require (AOLibrary.getBecomeHostSignatureAddress(address(this), _content.baseChallenge, _baseChallengeV, _baseChallengeR, _baseChallengeS) == _purchaseReceipt.publicAddress);

		_hostContent(msg.sender, _stakeId, _encChallenge, _contentDatKey, _metadataDatKey);

		// Release earning from escrow
		require (_earning.releaseEarning(
			_stakeId,
			_purchaseReceipt.contentHostId,
			_purchaseId,
			(_purchaseReceipt.amountPaidByBuyer > _content.fileSize),
			stakedContents[stakedContentIndex[_stakeId]].stakeOwner,
			contentHosts[contentHostIndex[_purchaseReceipt.contentHostId]].host)
		);
	}

	/**
	 * @dev Update the TAO Content State of a T(AO) Content
	 * @param _contentId The ID of the Content
	 * @param _taoId The ID of the TAO that initiates the update
	 * @param _taoContentState The TAO Content state value, i.e Submitted, Pending Review, or Accepted to TAO
	 * @param _updateTAOContentStateV The V part of the signature for this update
	 * @param _updateTAOContentStateR The R part of the signature for this update
	 * @param _updateTAOContentStateS The S part of the signature for this update
	 */
	function updateTAOContentState(
		bytes32 _contentId,
		address _taoId,
		bytes32 _taoContentState,
		uint8 _updateTAOContentStateV,
		bytes32 _updateTAOContentStateR,
		bytes32 _updateTAOContentStateS
	) public isContractActive {
		// Make sure the content exist
		require (contentIndex[_contentId] > 0);
		require (AOLibrary.isTAO(_taoId));
		(,, bytes32 _contentUsageType_taoContent, bytes32 taoContentState_submitted, bytes32 taoContentState_pendingReview, bytes32 taoContentState_acceptedToTAO) = _getSettingVariables();
		require (_taoContentState == taoContentState_submitted || _taoContentState == taoContentState_pendingReview || _taoContentState == taoContentState_acceptedToTAO);

		address _signatureAddress = AOLibrary.getUpdateTAOContentStateSignatureAddress(address(this), _contentId, _taoId, _taoContentState, _updateTAOContentStateV, _updateTAOContentStateR, _updateTAOContentStateS);

		Content storage _content = contents[contentIndex[_contentId]];
		// Make sure that the signature address is one of content&#39;s TAO ID&#39;s Advocate/Listener/Speaker
		require (_signatureAddress == msg.sender && _nameTAOPosition.senderIsPosition(_signatureAddress, _content.taoId));
		require (_content.contentUsageType == _contentUsageType_taoContent);

		_content.taoContentState = _taoContentState;
		_content.updateTAOContentStateV = _updateTAOContentStateV;
		_content.updateTAOContentStateR = _updateTAOContentStateR;
		_content.updateTAOContentStateS = _updateTAOContentStateS;

		emit UpdateTAOContentState(_contentId, _taoId, _signatureAddress, _taoContentState);
	}

	/***** INTERNAL METHODS *****/
	/**
	 * @dev Store the content information (content creation during staking)
	 * @param _creator the address of the content creator
	 * @param _baseChallenge The base challenge string (PUBLIC KEY) of the content
	 * @param _fileSize The size of the file
	 * @param _contentUsageType The content usage type, i.e AO Content, Creative Commons, or T(AO) Content
	 * @param _taoId The TAO (TAO) ID for this content (if this is a T(AO) Content)
	 * @return the ID of the content
	 */
	function _storeContent(address _creator, string _baseChallenge, uint256 _fileSize, bytes32 _contentUsageType, address _taoId) internal returns (bytes32) {
		// Increment totalContents
		totalContents++;

		// Generate contentId
		bytes32 _contentId = keccak256(abi.encodePacked(this, _creator, totalContents));
		Content storage _content = contents[totalContents];

		// Make sure the node does&#39;t store the same content twice
		require (_content.creator == address(0));

		(,,bytes32 contentUsageType_taoContent, bytes32 taoContentState_submitted,,) = _getSettingVariables();

		_content.contentId = _contentId;
		_content.creator = _creator;
		_content.baseChallenge = _baseChallenge;
		_content.fileSize = _fileSize;
		_content.contentUsageType = _contentUsageType;

		// If this is a TAO Content
		if (_contentUsageType == contentUsageType_taoContent) {
			_content.taoContentState = taoContentState_submitted;
			_content.taoId = _taoId;
		}

		contentIndex[_contentId] = totalContents;

		emit StoreContent(_content.creator, _content.contentId, _content.fileSize, _content.contentUsageType);
		return _content.contentId;
	}

	/**
	 * @dev Add the distribution node info that hosts the content
	 * @param _host the address of the host
	 * @param _stakeId The ID of the staked content
	 * @param _encChallenge The encrypted challenge string (PUBLIC KEY) of the content unique to the host
	 * @param _contentDatKey The dat key of the content
	 * @param _metadataDatKey The dat key of the content&#39;s metadata
	 */
	function _hostContent(address _host, bytes32 _stakeId, string _encChallenge, string _contentDatKey, string _metadataDatKey) internal {
		require (bytes(_encChallenge).length > 0);
		require (bytes(_contentDatKey).length > 0);
		require (bytes(_metadataDatKey).length > 0);
		require (stakedContentIndex[_stakeId] > 0);

		// Increment totalContentHosts
		totalContentHosts++;

		// Generate contentId
		bytes32 _contentHostId = keccak256(abi.encodePacked(this, _host, _stakeId));

		ContentHost storage _contentHost = contentHosts[totalContentHosts];

		// Make sure the node doesn&#39;t host the same content twice
		require (_contentHost.host == address(0));

		_contentHost.contentHostId = _contentHostId;
		_contentHost.stakeId = _stakeId;
		_contentHost.host = _host;
		_contentHost.encChallenge = _encChallenge;
		_contentHost.contentDatKey = _contentDatKey;
		_contentHost.metadataDatKey = _metadataDatKey;

		contentHostIndex[_contentHostId] = totalContentHosts;

		emit HostContent(_contentHost.host, _contentHost.contentHostId, _contentHost.stakeId, _contentHost.contentDatKey, _contentHost.metadataDatKey);
	}

	/**
	 * @dev actual staking the content
	 * @param _stakeOwner the address that stake the content
	 * @param _contentId The ID of the content
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake
	 * @param _profitPercentage The percentage of profit the stake owner&#39;s media will charge
	 * @return the newly created staked content ID
	 */
	function _stakeContent(address _stakeOwner, bytes32 _contentId, uint256 _networkIntegerAmount, uint256 _networkFractionAmount, bytes8 _denomination, uint256 _primordialAmount, uint256 _profitPercentage) internal returns (bytes32) {
		// Increment totalStakedContents
		totalStakedContents++;

		// Generate stakeId
		bytes32 _stakeId = keccak256(abi.encodePacked(this, _stakeOwner, _contentId));
		StakedContent storage _stakedContent = stakedContents[totalStakedContents];

		// Make sure the node doesn&#39;t stake the same content twice
		require (_stakedContent.stakeOwner == address(0));

		_stakedContent.stakeId = _stakeId;
		_stakedContent.contentId = _contentId;
		_stakedContent.stakeOwner = _stakeOwner;
		_stakedContent.profitPercentage = _profitPercentage;
		_stakedContent.active = true;
		_stakedContent.createdOnTimestamp = now;

		stakedContentIndex[_stakeId] = totalStakedContents;

		if (_denomination[0] != 0 && (_networkIntegerAmount > 0 || _networkFractionAmount > 0)) {
			_stakedContent.networkAmount = _treasury.toBase(_networkIntegerAmount, _networkFractionAmount, _denomination);
			require (_baseAO.stakeFrom(_stakeOwner, _stakedContent.networkAmount));
		}
		if (_primordialAmount > 0) {
			_stakedContent.primordialAmount = _primordialAmount;

			// Primordial Token is the base AO Token
			_stakedContent.primordialWeightedMultiplier = _baseAO.weightedMultiplierByAddress(_stakedContent.stakeOwner);
			require (_baseAO.stakePrimordialTokenFrom(_stakedContent.stakeOwner, _primordialAmount, _stakedContent.primordialWeightedMultiplier));
		}

		emit StakeContent(_stakedContent.stakeOwner, _stakedContent.stakeId, _stakedContent.contentId, _stakedContent.networkAmount, _stakedContent.primordialAmount, _stakedContent.primordialWeightedMultiplier, _stakedContent.profitPercentage, _stakedContent.createdOnTimestamp);

		return _stakedContent.stakeId;
	}

	/**
	 * @dev Get setting variables
	 * @return contentUsageType_aoContent Content Usage Type = AO Content
	 * @return contentUsageType_creativeCommons Content Usage Type = Creative Commons
	 * @return contentUsageType_taoContent Content Usage Type = T(AO) Content
	 * @return taoContentState_submitted TAO Content State = Submitted
	 * @return taoContentState_pendingReview TAO Content State = Pending Review
	 * @return taoContentState_acceptedToTAO TAO Content State = Accepted to TAO
	 */
	function _getSettingVariables() internal view returns (bytes32, bytes32, bytes32, bytes32, bytes32, bytes32) {
		(,,,bytes32 contentUsageType_aoContent,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;contentUsageType_aoContent&#39;);
		(,,,bytes32 contentUsageType_creativeCommons,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;contentUsageType_creativeCommons&#39;);
		(,,,bytes32 contentUsageType_taoContent,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;contentUsageType_taoContent&#39;);
		(,,,bytes32 taoContentState_submitted,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;taoContentState_submitted&#39;);
		(,,,bytes32 taoContentState_pendingReview,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;taoContentState_pendingReview&#39;);
		(,,,bytes32 taoContentState_acceptedToTAO,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, &#39;taoContentState_acceptedToTAO&#39;);

		return (
			contentUsageType_aoContent,
			contentUsageType_creativeCommons,
			contentUsageType_taoContent,
			taoContentState_submitted,
			taoContentState_pendingReview,
			taoContentState_acceptedToTAO
		);
	}

	/**
	 * @dev Check whether or not the content is of AO Content Usage Type
	 * @param _contentId The ID of the content
	 * @return true if yes. false otherwise
	 */
	function _isAOContentUsageType(bytes32 _contentId) internal view returns (bool) {
		(bytes32 _contentUsageType_aoContent,,,,,) = _getSettingVariables();
		return contents[contentIndex[_contentId]].contentUsageType == _contentUsageType_aoContent;
	}
}











/**
 * @title Name
 */
contract Name is TAO {
	/**
	 * @dev Constructor function
	 */
	constructor (string _name, address _originId, string _datHash, string _database, string _keyValue, bytes32 _contentId, address _vaultAddress)
		TAO (_name, _originId, _datHash, _database, _keyValue, _contentId, _vaultAddress) public {
		// Creating Name
		typeId = 1;
	}
}










contract Logos is TAOCurrency {
	NameTAOPosition internal _nameTAOPosition;

	// Mapping of a Name ID to the amount of Logos positioned by others to itself
	// address is the address of nameId, not the eth public address
	mapping (address => uint256) public positionFromOthers;

	// Mapping of Name ID to other Name ID and the amount of Logos positioned by itself
	mapping (address => mapping(address => uint256)) public positionToOthers;

	// Mapping of a Name ID to the total amount of Logos positioned by itself to others
	mapping (address => uint256) public totalPositionToOthers;

	// Mapping of Name ID to it&#39;s advocated TAO ID and the amount of Logos earned
	mapping (address => mapping(address => uint256)) public advocatedTAOLogos;

	// Mapping of a Name ID to the total amount of Logos earned from advocated TAO
	mapping (address => uint256) public totalAdvocatedTAOLogos;

	// Event broadcasted to public when `from` address position `value` Logos to `to`
	event PositionFrom(address indexed from, address indexed to, uint256 value);

	// Event broadcasted to public when `from` address unposition `value` Logos from `to`
	event UnpositionFrom(address indexed from, address indexed to, uint256 value);

	// Event broadcasted to public when `nameId` receives `amount` of Logos from advocating `taoId`
	event AddAdvocatedTAOLogos(address indexed nameId, address indexed taoId, uint256 amount);

	// Event broadcasted to public when Logos from advocating `taoId` is transferred from `fromNameId` to `toNameId`
	event TransferAdvocatedTAOLogos(address indexed fromNameId, address indexed toNameId, address indexed taoId, uint256 amount);

	/**
	 * @dev Constructor function
	 */
	constructor(uint256 initialSupply, string tokenName, string tokenSymbol, address _nameTAOPositionAddress)
		TAOCurrency(initialSupply, tokenName, tokenSymbol) public {
		nameTAOPositionAddress = _nameTAOPositionAddress;
		_nameTAOPosition = NameTAOPosition(_nameTAOPositionAddress);
	}

	/**
	 * @dev Check if `_taoId` is a TAO
	 */
	modifier isTAO(address _taoId) {
		require (AOLibrary.isTAO(_taoId));
		_;
	}

	/**
	 * @dev Check if `_nameId` is a Name
	 */
	modifier isName(address _nameId) {
		require (AOLibrary.isName(_nameId));
		_;
	}

	/**
	 * @dev Check if msg.sender is the current advocate of _id
	 */
	modifier onlyAdvocate(address _id) {
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _id));
		_;
	}

	/***** PUBLIC METHODS *****/
	/**
	 * @dev Get the total sum of Logos for an address
	 * @param _target The address to check
	 * @return The total sum of Logos (own + positioned + advocated TAOs)
	 */
	function sumBalanceOf(address _target) public isNameOrTAO(_target) view returns (uint256) {
		return balanceOf[_target].add(positionFromOthers[_target]).add(totalAdvocatedTAOLogos[_target]);
	}

	/**
	 * @dev `_from` Name position `_value` Logos onto `_to` Name
	 *
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value the amount to position
	 * @return true on success
	 */
	function positionFrom(address _from, address _to, uint256 _value) public isName(_from) isName(_to) onlyAdvocate(_from) returns (bool) {
		require (_from != _to);	// Can&#39;t position Logos to itself
		require (balanceOf[_from].sub(totalPositionToOthers[_from]) >= _value); // should have enough balance to position
		require (positionFromOthers[_to].add(_value) >= positionFromOthers[_to]); // check for overflows

		uint256 previousPositionToOthers = totalPositionToOthers[_from];
		uint256 previousPositionFromOthers = positionFromOthers[_to];
		uint256 previousAvailPositionBalance = balanceOf[_from].sub(totalPositionToOthers[_from]);

		positionToOthers[_from][_to] = positionToOthers[_from][_to].add(_value);
		totalPositionToOthers[_from] = totalPositionToOthers[_from].add(_value);
		positionFromOthers[_to] = positionFromOthers[_to].add(_value);

		emit PositionFrom(_from, _to, _value);
		assert(totalPositionToOthers[_from].sub(_value) == previousPositionToOthers);
		assert(positionFromOthers[_to].sub(_value) == previousPositionFromOthers);
		assert(balanceOf[_from].sub(totalPositionToOthers[_from]) <= previousAvailPositionBalance);
		return true;
	}

	/**
	 * @dev `_from` Name unposition `_value` Logos from `_to` Name
	 *
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value the amount to unposition
	 * @return true on success
	 */
	function unpositionFrom(address _from, address _to, uint256 _value) public isName(_from) isName(_to) onlyAdvocate(_from) returns (bool) {
		require (_from != _to);	// Can&#39;t unposition Logos to itself
		require (positionToOthers[_from][_to] >= _value);

		uint256 previousPositionToOthers = totalPositionToOthers[_from];
		uint256 previousPositionFromOthers = positionFromOthers[_to];
		uint256 previousAvailPositionBalance = balanceOf[_from].sub(totalPositionToOthers[_from]);

		positionToOthers[_from][_to] = positionToOthers[_from][_to].sub(_value);
		totalPositionToOthers[_from] = totalPositionToOthers[_from].sub(_value);
		positionFromOthers[_to] = positionFromOthers[_to].sub(_value);

		emit UnpositionFrom(_from, _to, _value);
		assert(totalPositionToOthers[_from].add(_value) == previousPositionToOthers);
		assert(positionFromOthers[_to].add(_value) == previousPositionFromOthers);
		assert(balanceOf[_from].sub(totalPositionToOthers[_from]) >= previousAvailPositionBalance);
		return true;
	}

	/**
	 * @dev Add `_amount` logos earned from advocating a TAO `_taoId` to its Advocate
	 * @param _taoId The ID of the advocated TAO
	 * @param _amount the amount to reward
	 * @return true on success
	 */
	function addAdvocatedTAOLogos(address _taoId, uint256 _amount) public inWhitelist isTAO(_taoId) returns (bool) {
		require (_amount > 0);
		address _nameId = _nameTAOPosition.getAdvocate(_taoId);

		advocatedTAOLogos[_nameId][_taoId] = advocatedTAOLogos[_nameId][_taoId].add(_amount);
		totalAdvocatedTAOLogos[_nameId] = totalAdvocatedTAOLogos[_nameId].add(_amount);

		emit AddAdvocatedTAOLogos(_nameId, _taoId, _amount);
		return true;
	}

	/**
	 * @dev Transfer logos earned from advocating a TAO `_taoId` from `_fromNameId` to `_toNameId`
	 * @param _fromNameId The ID of the Name that sends the Logos
	 * @param _toNameId The ID of the Name that receives the Logos
	 * @param _taoId The ID of the advocated TAO
	 * @return true on success
	 */
	function transferAdvocatedTAOLogos(address _fromNameId, address _toNameId, address _taoId) public inWhitelist isName(_fromNameId) isName(_toNameId) isTAO(_taoId) returns (bool) {
		require (_nameTAOPosition.nameIsAdvocate(_toNameId, _taoId));
		require (advocatedTAOLogos[_fromNameId][_taoId] > 0);
		require (totalAdvocatedTAOLogos[_fromNameId] >= advocatedTAOLogos[_fromNameId][_taoId]);

		uint256 _amount = advocatedTAOLogos[_fromNameId][_taoId];
		advocatedTAOLogos[_fromNameId][_taoId] = advocatedTAOLogos[_fromNameId][_taoId].sub(_amount);
		totalAdvocatedTAOLogos[_fromNameId] = totalAdvocatedTAOLogos[_fromNameId].sub(_amount);
		advocatedTAOLogos[_toNameId][_taoId] = advocatedTAOLogos[_toNameId][_taoId].add(_amount);
		totalAdvocatedTAOLogos[_toNameId] = totalAdvocatedTAOLogos[_toNameId].add(_amount);

		emit TransferAdvocatedTAOLogos(_fromNameId, _toNameId, _taoId, _amount);
		return true;
	}
}



/**
 * @title AOLibrary
 */
library AOLibrary {
	using SafeMath for uint256;

	uint256 constant private _MULTIPLIER_DIVISOR = 10 ** 6; // 1000000 = 1
	uint256 constant private _PERCENTAGE_DIVISOR = 10 ** 6; // 100% = 1000000

	/**
	 * @dev Check whether or not the given TAO ID is a TAO
	 * @param _taoId The ID of the TAO
	 * @return true if yes. false otherwise
	 */
	function isTAO(address _taoId) public view returns (bool) {
		return (_taoId != address(0) && bytes(TAO(_taoId).name()).length > 0 && TAO(_taoId).originId() != address(0) && TAO(_taoId).typeId() == 0);
	}

	/**
	 * @dev Check whether or not the given Name ID is a Name
	 * @param _nameId The ID of the Name
	 * @return true if yes. false otherwise
	 */
	function isName(address _nameId) public view returns (bool) {
		return (_nameId != address(0) && bytes(TAO(_nameId).name()).length > 0 && Name(_nameId).originId() != address(0) && Name(_nameId).typeId() == 1);
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 * @param _sender The address to check
	 * @param _theAO The AO address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 * @return true if yes, false otherwise
	 */
	function isTheAO(address _sender, address _theAO, address _nameTAOPositionAddress) public view returns (bool) {
		return (_sender == _theAO ||
			(
				(isTAO(_theAO) || isName(_theAO)) &&
				_nameTAOPositionAddress != address(0) &&
				NameTAOPosition(_nameTAOPositionAddress).senderIsAdvocate(_sender, _theAO)
			)
		);
	}

	/**
	 * @dev Return the divisor used to correctly calculate percentage.
	 *		Percentage stored throughout AO contracts covers 4 decimals,
	 *		so 1% is 10000, 1.25% is 12500, etc
	 */
	function PERCENTAGE_DIVISOR() public pure returns (uint256) {
		return _PERCENTAGE_DIVISOR;
	}

	/**
	 * @dev Return the divisor used to correctly calculate multiplier.
	 *		Multiplier stored throughout AO contracts covers 6 decimals,
	 *		so 1 is 1000000, 0.023 is 23000, etc
	 */
	function MULTIPLIER_DIVISOR() public pure returns (uint256) {
		return _MULTIPLIER_DIVISOR;
	}

	/**
	 * @dev Check whether or not content creator can stake a content based on the provided params
	 * @param _treasuryAddress AO treasury contract address
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake
	 * @param _baseChallenge The base challenge string (PUBLIC KEY) of the content
	 * @param _encChallenge The encrypted challenge string (PUBLIC KEY) of the content unique to the host
	 * @param _contentDatKey The dat key of the content
	 * @param _metadataDatKey The dat key of the content&#39;s metadata
	 * @param _fileSize The size of the file
	 * @param _profitPercentage The percentage of profit the stake owner&#39;s media will charge
	 * @return true if yes. false otherwise
	 */
	function canStake(address _treasuryAddress,
		uint256 _networkIntegerAmount,
		uint256 _networkFractionAmount,
		bytes8 _denomination,
		uint256 _primordialAmount,
		string _baseChallenge,
		string _encChallenge,
		string _contentDatKey,
		string _metadataDatKey,
		uint256 _fileSize,
		uint256 _profitPercentage) public view returns (bool) {
		return (
			bytes(_baseChallenge).length > 0 &&
			bytes(_encChallenge).length > 0 &&
			bytes(_contentDatKey).length > 0 &&
			bytes(_metadataDatKey).length > 0 &&
			_fileSize > 0 &&
			(_networkIntegerAmount > 0 || _networkFractionAmount > 0 || _primordialAmount > 0) &&
			_stakeAmountValid(_treasuryAddress, _networkIntegerAmount, _networkFractionAmount, _denomination, _primordialAmount, _fileSize) == true &&
			_profitPercentage <= _PERCENTAGE_DIVISOR
		);
	}

	/**
	 * @dev Check whether or the requested unstake amount is valid
	 * @param _treasuryAddress AO treasury contract address
	 * @param _networkIntegerAmount The integer amount of the network token
	 * @param _networkFractionAmount The fraction amount of the network token
	 * @param _denomination The denomination of the the network token
	 * @param _primordialAmount The amount of primordial token
	 * @param _stakedNetworkAmount The current staked network token amount
	 * @param _stakedPrimordialAmount The current staked primordial token amount
	 * @param _stakedFileSize The file size of the staked content
	 * @return true if can unstake, false otherwise
	 */
	function canUnstakePartial(
		address _treasuryAddress,
		uint256 _networkIntegerAmount,
		uint256 _networkFractionAmount,
		bytes8 _denomination,
		uint256 _primordialAmount,
		uint256 _stakedNetworkAmount,
		uint256 _stakedPrimordialAmount,
		uint256 _stakedFileSize) public view returns (bool) {
		if (
			(_denomination.length > 0 &&
				(_networkIntegerAmount > 0 || _networkFractionAmount > 0) &&
				_stakedNetworkAmount < AOTreasury(_treasuryAddress).toBase(_networkIntegerAmount, _networkFractionAmount, _denomination)
			) ||
			_stakedPrimordialAmount < _primordialAmount ||
			(
				_denomination.length > 0
					&& (_networkIntegerAmount > 0 || _networkFractionAmount > 0)
					&& (_stakedNetworkAmount.sub(AOTreasury(_treasuryAddress).toBase(_networkIntegerAmount, _networkFractionAmount, _denomination)).add(_stakedPrimordialAmount.sub(_primordialAmount)) < _stakedFileSize)
			) ||
			( _denomination.length == 0 && _networkIntegerAmount == 0 && _networkFractionAmount == 0 && _primordialAmount > 0 && _stakedPrimordialAmount.sub(_primordialAmount) < _stakedFileSize)
		) {
			return false;
		} else {
			return true;
		}
	}

	/**
	 * @dev Check whether the network token and/or primordial token is adequate to pay for existing staked content
	 * @param _treasuryAddress AO treasury contract address
	 * @param _isAOContentUsageType whether or not the content is of AO Content usage type
	 * @param _fileSize The size of the file
	 * @param _stakedAmount The total staked amount
	 * @param _networkIntegerAmount The integer amount of the network token
	 * @param _networkFractionAmount The fraction amount of the network token
	 * @param _denomination The denomination of the the network token
	 * @param _primordialAmount The amount of primordial token
	 * @return true when the amount is sufficient, false otherwise
	 */
	function canStakeExisting(
		address _treasuryAddress,
		bool _isAOContentUsageType,
		uint256 _fileSize,
		uint256 _stakedAmount,
		uint256 _networkIntegerAmount,
		uint256 _networkFractionAmount,
		bytes8 _denomination,
		uint256 _primordialAmount
	) public view returns (bool) {
		if (_isAOContentUsageType) {
			return AOTreasury(_treasuryAddress).toBase(_networkIntegerAmount, _networkFractionAmount, _denomination).add(_primordialAmount).add(_stakedAmount) >= _fileSize;
		} else {
			return AOTreasury(_treasuryAddress).toBase(_networkIntegerAmount, _networkFractionAmount, _denomination).add(_primordialAmount).add(_stakedAmount) == _fileSize;
		}
	}

	/**
	 * @dev Check whether the network token is adequate to pay for existing staked content
	 * @param _treasuryAddress AO treasury contract address
	 * @param _price The price of the content
	 * @param _networkIntegerAmount The integer amount of the network token
	 * @param _networkFractionAmount The fraction amount of the network token
	 * @param _denomination The denomination of the the network token
	 * @return true when the amount is sufficient, false otherwise
	 */
	function canBuy(address _treasuryAddress, uint256 _price, uint256 _networkIntegerAmount, uint256 _networkFractionAmount, bytes8 _denomination) public view returns (bool) {
		return AOTreasury(_treasuryAddress).toBase(_networkIntegerAmount, _networkFractionAmount, _denomination) >= _price;
	}

	/**
	 * @dev Calculate the new weighted multiplier when adding `_additionalPrimordialAmount` at `_additionalWeightedMultiplier` to the current `_currentPrimordialBalance` at `_currentWeightedMultiplier`
	 * @param _currentWeightedMultiplier Account&#39;s current weighted multiplier
	 * @param _currentPrimordialBalance Account&#39;s current primordial token balance
	 * @param _additionalWeightedMultiplier The weighted multiplier to be added
	 * @param _additionalPrimordialAmount The primordial token amount to be added
	 * @return the new primordial weighted multiplier
	 */
	function calculateWeightedMultiplier(uint256 _currentWeightedMultiplier, uint256 _currentPrimordialBalance, uint256 _additionalWeightedMultiplier, uint256 _additionalPrimordialAmount) public pure returns (uint256) {
		if (_currentWeightedMultiplier > 0) {
			uint256 _totalWeightedTokens = (_currentWeightedMultiplier.mul(_currentPrimordialBalance)).add(_additionalWeightedMultiplier.mul(_additionalPrimordialAmount));
			uint256 _totalTokens = _currentPrimordialBalance.add(_additionalPrimordialAmount);
			return _totalWeightedTokens.div(_totalTokens);
		} else {
			return _additionalWeightedMultiplier;
		}
	}

	/**
	 * @dev Return the address that signed the message when a node wants to become a host
	 * @param _callingContractAddress the address of the calling contract
	 * @param _message the message that was signed
	 * @param _v part of the signature
	 * @param _r part of the signature
	 * @param _s part of the signature
	 * @return the address that signed the message
	 */
	function getBecomeHostSignatureAddress(address _callingContractAddress, string _message, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
		bytes32 _hash = keccak256(abi.encodePacked(_callingContractAddress, _message));
		return ecrecover(_hash, _v, _r, _s);
	}

	/**
	 * @dev Return the address that signed the TAO content state update
	 * @param _callingContractAddress the address of the calling contract
	 * @param _contentId the ID of the content
	 * @param _taoId the ID of the TAO
	 * @param _taoContentState the TAO Content State value, i.e Submitted, Pending Review, or Accepted to TAO
	 * @param _v part of the signature
	 * @param _r part of the signature
	 * @param _s part of the signature
	 * @return the address that signed the message
	 */
	function getUpdateTAOContentStateSignatureAddress(address _callingContractAddress, bytes32 _contentId, address _taoId, bytes32 _taoContentState, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
		bytes32 _hash = keccak256(abi.encodePacked(_callingContractAddress, _contentId, _taoId, _taoContentState));
		return ecrecover(_hash, _v, _r, _s);
	}

	/**
	 * @dev Return the staking and earning information of a stake ID
	 * @param _contentAddress The address of AOContent
	 * @param _earningAddress The address of AOEarning
	 * @param _stakeId The ID of the staked content
	 * @return the network base token amount staked for this content
	 * @return the primordial token amount staked for this content
	 * @return the primordial weighted multiplier of the staked content
	 * @return the total earning from staking this content
	 * @return the total earning from hosting this content
	 * @return the total The AO earning of this content
	 */
	function getContentMetrics(address _contentAddress, address _earningAddress, bytes32 _stakeId) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 networkAmount, uint256 primordialAmount, uint256 primordialWeightedMultiplier) = getStakingMetrics(_contentAddress, _stakeId);
		(uint256 totalStakeEarning, uint256 totalHostEarning, uint256 totalTheAOEarning) = getEarningMetrics(_earningAddress, _stakeId);
		return (
			networkAmount,
			primordialAmount,
			primordialWeightedMultiplier,
			totalStakeEarning,
			totalHostEarning,
			totalTheAOEarning
		);
	}

	/**
	 * @dev Return the staking information of a stake ID
	 * @param _contentAddress The address of AOContent
	 * @param _stakeId The ID of the staked content
	 * @return the network base token amount staked for this content
	 * @return the primordial token amount staked for this content
	 * @return the primordial weighted multiplier of the staked content
	 */
	function getStakingMetrics(address _contentAddress, bytes32 _stakeId) public view returns (uint256, uint256, uint256) {
		(,, uint256 networkAmount, uint256 primordialAmount, uint256 primordialWeightedMultiplier,,,) = AOContent(_contentAddress).stakedContentById(_stakeId);
		return (
			networkAmount,
			primordialAmount,
			primordialWeightedMultiplier
		);
	}

	/**
	 * @dev Return the earning information of a stake ID
	 * @param _earningAddress The address of AOEarning
	 * @param _stakeId The ID of the staked content
	 * @return the total earning from staking this content
	 * @return the total earning from hosting this content
	 * @return the total The AO earning of this content
	 */
	function getEarningMetrics(address _earningAddress, bytes32 _stakeId) public view returns (uint256, uint256, uint256) {
		return (
			AOEarning(_earningAddress).totalStakedContentStakeEarning(_stakeId),
			AOEarning(_earningAddress).totalStakedContentHostEarning(_stakeId),
			AOEarning(_earningAddress).totalStakedContentTheAOEarning(_stakeId)
		);
	}

	/**
	 * @dev Calculate the primordial token multiplier on a given lot
	 *		Total Primordial Mintable = T
	 *		Total Primordial Minted = M
	 *		Starting Multiplier = S
	 *		Ending Multiplier = E
	 *		To Purchase = P
	 *		Multiplier for next Lot of Amount = (1 - ((M + P/2) / T)) x (S-E)
	 *
	 * @param _purchaseAmount The amount of primordial token intended to be purchased
	 * @param _totalPrimordialMintable Total Primordial token intable
	 * @param _totalPrimordialMinted Total Primordial token minted so far
	 * @param _startingMultiplier The starting multiplier in (10 ** 6)
	 * @param _endingMultiplier The ending multiplier in (10 ** 6)
	 * @return The multiplier in (10 ** 6)
	 */
	function calculatePrimordialMultiplier(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		if (_purchaseAmount > 0 && _purchaseAmount <= _totalPrimordialMintable.sub(_totalPrimordialMinted)) {
			/**
			 * Let temp = M + (P/2)
			 * Multiplier = (1 - (temp / T)) x (S-E)
			 */
			uint256 temp = _totalPrimordialMinted.add(_purchaseAmount.div(2));

			/**
			 * Multiply multiplier with _MULTIPLIER_DIVISOR/_MULTIPLIER_DIVISOR to account for 6 decimals
			 * so, Multiplier = (_MULTIPLIER_DIVISOR/_MULTIPLIER_DIVISOR) * (1 - (temp / T)) * (S-E)
			 * Multiplier = ((_MULTIPLIER_DIVISOR * (1 - (temp / T))) * (S-E)) / _MULTIPLIER_DIVISOR
			 * Multiplier = ((_MULTIPLIER_DIVISOR - ((_MULTIPLIER_DIVISOR * temp) / T)) * (S-E)) / _MULTIPLIER_DIVISOR
			 * Take out the division by _MULTIPLIER_DIVISOR for now and include in later calculation
			 * Multiplier = (_MULTIPLIER_DIVISOR - ((_MULTIPLIER_DIVISOR * temp) / T)) * (S-E)
			 */
			uint256 multiplier = (_MULTIPLIER_DIVISOR.sub(_MULTIPLIER_DIVISOR.mul(temp).div(_totalPrimordialMintable))).mul(_startingMultiplier.sub(_endingMultiplier));
			/**
			 * Since _startingMultiplier and _endingMultiplier are in 6 decimals
			 * Need to divide multiplier by _MULTIPLIER_DIVISOR
			 */
			return multiplier.div(_MULTIPLIER_DIVISOR);
		} else {
			return 0;
		}
	}

	/**
	 * @dev Calculate the bonus percentage of network token on a given lot
	 *		Total Primordial Mintable = T
	 *		Total Primordial Minted = M
	 *		Starting Network Token Bonus Multiplier = Bs
	 *		Ending Network Token Bonus Multiplier = Be
	 *		To Purchase = P
	 *		AO Bonus % = B% = (1 - ((M + P/2) / T)) x (Bs-Be)
	 *
	 * @param _purchaseAmount The amount of primordial token intended to be purchased
	 * @param _totalPrimordialMintable Total Primordial token intable
	 * @param _totalPrimordialMinted Total Primordial token minted so far
	 * @param _startingMultiplier The starting Network token bonus multiplier
	 * @param _endingMultiplier The ending Network token bonus multiplier
	 * @return The bonus percentage
	 */
	function calculateNetworkTokenBonusPercentage(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		if (_purchaseAmount > 0 && _purchaseAmount <= _totalPrimordialMintable.sub(_totalPrimordialMinted)) {
			/**
			 * Let temp = M + (P/2)
			 * B% = (1 - (temp / T)) x (Bs-Be)
			 */
			uint256 temp = _totalPrimordialMinted.add(_purchaseAmount.div(2));

			/**
			 * Multiply B% with _PERCENTAGE_DIVISOR/_PERCENTAGE_DIVISOR to account for 6 decimals
			 * so, B% = (_PERCENTAGE_DIVISOR/_PERCENTAGE_DIVISOR) * (1 - (temp / T)) * (Bs-Be)
			 * B% = ((_PERCENTAGE_DIVISOR * (1 - (temp / T))) * (Bs-Be)) / _PERCENTAGE_DIVISOR
			 * B% = ((_PERCENTAGE_DIVISOR - ((_PERCENTAGE_DIVISOR * temp) / T)) * (Bs-Be)) / _PERCENTAGE_DIVISOR
			 * Take out the division by _PERCENTAGE_DIVISOR for now and include in later calculation
			 * B% = (_PERCENTAGE_DIVISOR - ((_PERCENTAGE_DIVISOR * temp) / T)) * (Bs-Be)
			 * But since Bs and Be are in 6 decimals, need to divide by _PERCENTAGE_DIVISOR
			 * B% = (_PERCENTAGE_DIVISOR - ((_PERCENTAGE_DIVISOR * temp) / T)) * (Bs-Be) / _PERCENTAGE_DIVISOR
			 */
			uint256 bonusPercentage = (_PERCENTAGE_DIVISOR.sub(_PERCENTAGE_DIVISOR.mul(temp).div(_totalPrimordialMintable))).mul(_startingMultiplier.sub(_endingMultiplier)).div(_PERCENTAGE_DIVISOR);
			return bonusPercentage;
		} else {
			return 0;
		}
	}

	/**
	 * @dev Calculate the bonus amount of network token on a given lot
	 *		AO Bonus Amount = B% x P
	 *
	 * @param _purchaseAmount The amount of primordial token intended to be purchased
	 * @param _totalPrimordialMintable Total Primordial token intable
	 * @param _totalPrimordialMinted Total Primordial token minted so far
	 * @param _startingMultiplier The starting Network token bonus multiplier
	 * @param _endingMultiplier The ending Network token bonus multiplier
	 * @return The bonus percentage
	 */
	function calculateNetworkTokenBonusAmount(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		uint256 bonusPercentage = calculateNetworkTokenBonusPercentage(_purchaseAmount, _totalPrimordialMintable, _totalPrimordialMinted, _startingMultiplier, _endingMultiplier);
		/**
		 * Since bonusPercentage is in _PERCENTAGE_DIVISOR format, need to divide it with _PERCENTAGE DIVISOR
		 * when calculating the network token bonus amount
		 */
		uint256 networkTokenBonus = bonusPercentage.mul(_purchaseAmount).div(_PERCENTAGE_DIVISOR);
		return networkTokenBonus;
	}

	/**
	 * @dev Calculate the maximum amount of Primordial an account can burn
	 *		_primordialBalance = P
	 *		_currentWeightedMultiplier = M
	 *		_maximumMultiplier = S
	 *		_amountToBurn = B
	 *		B = ((S x P) - (P x M)) / S
	 *
	 * @param _primordialBalance Account&#39;s primordial token balance
	 * @param _currentWeightedMultiplier Account&#39;s current weighted multiplier
	 * @param _maximumMultiplier The maximum multiplier of this account
	 * @return The maximum burn amount
	 */
	function calculateMaximumBurnAmount(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _maximumMultiplier) public pure returns (uint256) {
		return (_maximumMultiplier.mul(_primordialBalance).sub(_primordialBalance.mul(_currentWeightedMultiplier))).div(_maximumMultiplier);
	}

	/**
	 * @dev Calculate the new multiplier after burning primordial token
	 *		_primordialBalance = P
	 *		_currentWeightedMultiplier = M
	 *		_amountToBurn = B
	 *		_newMultiplier = E
	 *		E = (P x M) / (P - B)
	 *
	 * @param _primordialBalance Account&#39;s primordial token balance
	 * @param _currentWeightedMultiplier Account&#39;s current weighted multiplier
	 * @param _amountToBurn The amount of primordial token to burn
	 * @return The new multiplier
	 */
	function calculateMultiplierAfterBurn(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _amountToBurn) public pure returns (uint256) {
		return _primordialBalance.mul(_currentWeightedMultiplier).div(_primordialBalance.sub(_amountToBurn));
	}

	/**
	 * @dev Calculate the new multiplier after converting network token to primordial token
	 *		_primordialBalance = P
	 *		_currentWeightedMultiplier = M
	 *		_amountToConvert = C
	 *		_newMultiplier = E
	 *		E = (P x M) / (P + C)
	 *
	 * @param _primordialBalance Account&#39;s primordial token balance
	 * @param _currentWeightedMultiplier Account&#39;s current weighted multiplier
	 * @param _amountToConvert The amount of network token to convert
	 * @return The new multiplier
	 */
	function calculateMultiplierAfterConversion(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _amountToConvert) public pure returns (uint256) {
		return _primordialBalance.mul(_currentWeightedMultiplier).div(_primordialBalance.add(_amountToConvert));
	}

	/**
	 * @dev Get TAO Currency Balances given a nameId
	 * @param _nameId The ID of the Name
	 * @param _logosAddress The address of Logos
	 * @param _ethosAddress The address of Ethos
	 * @param _pathosAddress The address of Pathos
	 * @return sum Logos balance of the Name ID
	 * @return Ethos balance of the Name ID
	 * @return Pathos balance of the Name ID
	 */
	function getTAOCurrencyBalances(
		address _nameId,
		address _logosAddress,
		address _ethosAddress,
		address _pathosAddress
	) public view returns (uint256, uint256, uint256) {
		return (
			Logos(_logosAddress).sumBalanceOf(_nameId),
			TAOCurrency(_ethosAddress).balanceOf(_nameId),
			TAOCurrency(_pathosAddress).balanceOf(_nameId)
		);
	}

	/**
	 * @dev Return the address that signed the data and nonce when validating signature
	 * @param _callingContractAddress the address of the calling contract
	 * @param _data the data that was signed
	 * @param _nonce The signed uint256 nonce
	 * @param _v part of the signature
	 * @param _r part of the signature
	 * @param _s part of the signature
	 * @return the address that signed the message
	 */
	function getValidateSignatureAddress(address _callingContractAddress, string _data, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
		bytes32 _hash = keccak256(abi.encodePacked(_callingContractAddress, _data, _nonce));
		return ecrecover(_hash, _v, _r, _s);
	}

	/***** Internal Methods *****/
	/**
	 * @dev Check whether the network token and/or primordial token is adequate to pay for the filesize
	 * @param _treasuryAddress AO treasury contract address
	 * @param _networkIntegerAmount The integer amount of network token to stake
	 * @param _networkFractionAmount The fraction amount of network token to stake
	 * @param _denomination The denomination of the network token, i.e ao, kilo, mega, etc.
	 * @param _primordialAmount The amount of primordial Token to stake
	 * @param _fileSize The size of the file
	 * @return true when the amount is sufficient, false otherwise
	 */
	function _stakeAmountValid(address _treasuryAddress, uint256 _networkIntegerAmount, uint256 _networkFractionAmount, bytes8 _denomination, uint256 _primordialAmount, uint256 _fileSize) internal view returns (bool) {
		return AOTreasury(_treasuryAddress).toBase(_networkIntegerAmount, _networkFractionAmount, _denomination).add(_primordialAmount) >= _fileSize;
	}
}


contract Epiphany is TheAO {
	string public what;
	string public when;
	string public why;
	string public who;
	address public where;
	string public aSign;
	string public logos;

	constructor() public {
		what = &#39;The AO&#39;;
		when = &#39;January 6th, 2019 a.d, year 1 a.c. Epiphany. An appearance or manifestation especially of a divine being. An illuminating discovery, realization, or disclosure.&#39;;
		why = &#39;To Hear, See, and Speak the Human inside Humanity.&#39;;
		who = &#39;You.  Set the world, Free. – Truth&#39;;
		aSign = &#39;08e2c4e1ccf3bccfb3b8eef14679b28442649a2a733960661210a0b00d9c93bf&#39;;
		logos = &#39;0920c6ab1848df83a332a21e8c9ec1a393e694c396b872aee053722d023e2a32&#39;;
	}

	/**
	 * @dev Checks if the calling contract address is The AO
	 *		OR
	 *		If The AO is set to a Name/TAO, then check if calling address is the Advocate
	 */
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	/***** The AO ONLY METHODS *****/
	/**
	 * @dev The AO set the NameTAOPosition Address
	 * @param _nameTAOPositionAddress The address of NameTAOPosition
	 */
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	/**
	 * @dev Transfer ownership of The AO to new address
	 * @param _theAO The new address to be transferred
	 */
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	/**
	 * @dev Whitelist `_account` address to transact on behalf of others
	 * @param _account The address to whitelist
	 * @param _whitelist Either to whitelist or not
	 */
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	/**
	 * @dev Set `where` value
	 * @param _where The new value to be set
	 */
	function setWhere(address _where) public onlyTheAO {
		where = _where;
	}
}