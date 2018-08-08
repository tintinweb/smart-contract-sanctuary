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
		judgement(c>=a && c>=b);
		return c;
	}
	function safeMulWithPresent(uint256 a , uint256 b) pure internal returns (uint256){
		uint256 c = safeDiv(safeMul(a,b),100);
		judgement(b == (c*100)/a);
		return c;
	}
	function judgement(bool assertion) pure internal {
		if (!assertion) {
			revert();
		}
	}
}
contract XXCAuth{
	address public owner;
	constructor () public{
		owner = msg.sender;
	}
	event LogOwnerChanged (address msgSender );

	///@notice check if the msgSender is owner
	modifier onlyOwner{
		assert(msg.sender == owner);
		_;
	}//TODO need double check the authority checking

	function setOwner (address newOwner) public onlyOwner returns (bool){
		if (owner == msg.sender){
			owner = newOwner;
			emit LogOwnerChanged(msg.sender);
			return true;
		}else{
			return false;
		}
	}

}
contract XXCStop is XXCAuth{
	bool internal stopped = false;

	modifier stoppable {
		assert (!stopped);
		_;
	}

	function _status() view public returns (bool){
		return stopped;
	}
	function stop() public onlyOwner{
		stopped = true;
	}
	function start() public onlyOwner{
		stopped = false;
	}

}
contract Token is SafeMath {//TODO need review the oo
	/*
		Standard ERC20 token
	*/
	uint256 public totalSupply;                                 /// total amount of tokens
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

	function push(address _to,uint256 amount) public returns (bool);
	/*
		function _transfer(address to ,uint256 amount) public returns (bool);
	*/
	function burn(uint256 amount) public returns (bool);

	function mint(uint256 amount) public;

	function frozenCheck(address _from , address _to) view private returns (bool);

	function freezeAccount(address target , bool freeze) public;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn    (address indexed _owner , uint256 _value);
	event Minted  (uint256 amount);
}
contract StandardToken is Token ,XXCStop{

	function transfer(address _to, uint256 _value) stoppable public returns (bool ind) {
		//Default assumes totalSupply can&#39;t be over max (2^256 - 1).
		//If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
		//Replace the if with this one instead.
		//if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
		require(frozenCheck(msg.sender,_to));
		if (balances[msg.sender] >= _value && _value > 0) {
			balances[msg.sender] = safeSub(balances[msg.sender] , _value);
			balances[_to]  = safeAdd(balances[_to],_value);
			emit Transfer(msg.sender, _to, _value);
			return true;
		} else { return false; }
	}

	function transferFrom(address _from, address _to, uint256 _value) stoppable public returns (bool success) {
		//same as above. Replace this line with the following if you want to protect against wrapping uints.
		require(frozenCheck(_from,_to));
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
			balances[_to]  = safeAdd(balances[_to],_value);
			balances[_from] = safeSub(balances[_from] , _value);
			allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
			emit Transfer(_from, _to, _value);
			return true;
		} else { return false; }
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) stoppable public returns (bool success) {
		require(frozenCheck(_spender,msg.sender));
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	function burn(uint256 amount) stoppable onlyOwner public returns (bool){
		if(balances[msg.sender] > amount ){
			balances[msg.sender] = safeSub(balances[msg.sender],amount);
			totalSupply = safeSub(totalSupply,amount);
			emit Burn(msg.sender,amount);
			return true;
		}else{
			return false;
		}
	}
	function push(address _to , uint256 amount) onlyOwner public returns (bool){         ///only run once at initialize
		balances[_to] = safeAdd(balances[_to] ,amount);
		return true;
	}
	function mint(uint256 amount) onlyOwner public{
		totalSupply = safeAdd(totalSupply, amount);
		emit Minted(amount);
	}
	function frozenCheck(address _from , address _to) view private returns (bool){
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		return true;
	}
	function freezeAccount(address target , bool freeze) onlyOwner public{
		frozenAccount[target] = freeze;
	}

	mapping (address => uint256)                      private  balances;
	mapping (address => mapping (address => uint256)) private  allowed;
	mapping (address => bool)                         private  frozenAccount;    //Save frozen account

}
contract XXCToken is StandardToken{

	string public name = "XXC";                                   /// Set the full name of this contract
	uint256 public decimals = 18;                                 /// Set the decimal
	string public symbol = "XXC";                                 /// Set the symbol of this contract

	constructor() public {                    /// Should have sth in this
		owner = msg.sender;
	}

	function () stoppable public {
		revert();
	}

}