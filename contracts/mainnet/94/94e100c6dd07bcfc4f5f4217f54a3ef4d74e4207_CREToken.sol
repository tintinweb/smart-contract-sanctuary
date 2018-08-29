pragma solidity ^0.4.24;
/**
 * Math operations with safety checks
 */
contract SafeMath {

	function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a * b;
		judgement(a == 0 || c / a == b);
		return c;
	}

	function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
		judgement(b > 0);
		uint256 c = a / b;
		judgement(a == b * c + a % b);
		return c;
	}

	function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
		judgement(b <= a);
		return a - b;
	}

	function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a + b;
		judgement(c >= a && c >= b);
		return c;
	}

	function safeMulWithPresent(uint256 a, uint256 b) pure internal returns (uint256){
		uint256 c = safeDiv(safeMul(a, b), 1000);
		judgement(b == (c * 1000) / a);
		return c;
	}

	function judgement(bool assertion) pure internal {
		if (!assertion) {
			revert();
		}
	}
}

contract CREAuth {
	address public owner;
	constructor () public{
		owner = msg.sender;
	}
	event LogOwnerChanged (address msgSender);

	///@notice check if the msgSender is owner
	modifier onlyOwner{
		assert(msg.sender == owner);
		_;
	}

	function setOwner(address newOwner) public onlyOwner returns (bool){
		require(newOwner != address(0));
		owner = newOwner;
		emit LogOwnerChanged(msg.sender);
		return true;
	}

}

contract Token is SafeMath {
	/*
		Standard ERC20 token
	*/
	uint256 public totalSupply;
	uint256 internal maxSupply;
	/// total amount of tokens
	/// @param _owner The address from which the balance will be retrieved
	/// @return The balance
	function balanceOf(address _owner) public view returns (uint256 balance);

	/// @notice send `_value` token to `_to` from `msg.sender`
	/// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
	/// @return Whether the transfer was successful or not
	function transfer(address _to, uint256 _value) public returns (bool success);

	/// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
	/// @param _from The address of the sender
	/// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
	/// @return Whether the transfer was successful or not
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	/// @notice `msg.sender` approves `_spender` to spend `_value` tokens
	/// @param _spender The address of the account able to transfer the tokens
	/// @param _value The amount of tokens to be approved for transfer
	/// @return Whether the approval was successful or not
	function approve(address _spender, uint256 _value) public returns (bool success);

	/// @param _owner The address of the account owning tokens
	/// @param _spender The address of the account able to transfer the tokens
	/// @return Amount of remaining tokens allowed to spent
	function allowance(address _owner, address _spender) view public returns (uint256 remaining);

	/// @notice transferred
	/// @param amount The amount need to burn

	function burn(uint256 amount) public returns (bool);

	/// mapping the main chain&#39;s key to eth key
	/// @param key Tf main chain
	function register(string key) public returns (bool);

	/// mint the token to token owner
	/// @param amountOfMint of token mint
	function mint(uint256 amountOfMint) public returns (bool);

	event Transfer                           (address indexed _from, address indexed _to, uint256 _value);
	event Approval                           (address indexed _owner, address indexed _spender, uint256 _value);
	event Burn                               (address indexed _owner, uint256 indexed _value);
	event LogRegister                        (address user, string key);
	event Mint                               (address user,uint256 indexed amountOfMint);
}

contract StandardToken is Token, CREAuth {

	function transfer(address _to, uint256 _value) public returns (bool ind) {
		//Default assumes totalSupply can&#39;t be over max (2^256 - 1).
		//If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
		//Replace the if with this one instead.

		require(_to != address(0));
		assert(balances[msg.sender] >= _value && _value > 0);

		balances[msg.sender] = safeSub(balances[msg.sender], _value);
		balances[_to] = safeAdd(balances[_to], _value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		//same as above. Replace this line with the following if you want to protect against wrapping uints.
		require(_to != address(0));
		assert(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);

		balances[_to] = safeAdd(balances[_to], _value);
		balances[_from] = safeSub(balances[_from], _value);
		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_spender != address(0));
		require(_value > 0);
		require(allowed[msg.sender][_spender] == 0);
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function burn(uint256 amount) public onlyOwner returns (bool){

		require(balances[msg.sender] >= amount);
		balances[msg.sender] = safeSub(balances[msg.sender], amount);
		totalSupply = safeSub(totalSupply, amount);
		emit Burn(msg.sender, amount);
		return true;

	}

	function register(string key) public returns (bool){
		assert(bytes(key).length <= 64);

		keys[msg.sender] = key;
		emit LogRegister(msg.sender, key);
		return true;
	}

	function mint(uint256 amountOfMint) public onlyOwner returns (bool){
		//if totalSupply + amountOfMint <= maxSupply then mint token to contract owner
		require(safeAdd(totalSupply, amountOfMint) <= maxSupply);
		totalSupply = safeAdd(totalSupply, amountOfMint);
		balances[msg.sender] = safeAdd(balances[msg.sender], amountOfMint);
		emit Mint(msg.sender ,amountOfMint);
		return true;
	}

	mapping(address => uint256)                      internal balances;
	mapping(address => mapping(address => uint256))  private  allowed;
	mapping(address => string)                       private  keys;

}

contract CREToken is StandardToken {

	string public name = "CoinRealEcosystem";                                   /// Set the full name of this contract
	uint256 public decimals = 18;                                 /// Set the decimal
	string public symbol = "CRE";                                 /// Set the symbol of this contract


	constructor() public {/// Should have sth in this
		owner = msg.sender;
		totalSupply = 1000000000000000000000000000;
		/// 10 Billion for init mint
		maxSupply = 2000000000000000000000000000;
		/// set Max supply as 20 billion
		balances[msg.sender] = totalSupply;
	}

	function() public {
		revert();
	}

}