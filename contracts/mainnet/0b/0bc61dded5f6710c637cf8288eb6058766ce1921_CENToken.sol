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
		uint256 c = safeDiv(safeMul(a,b),1000);
		judgement(b == (c*1000)/a);
		return c;
	}
	function judgement(bool assertion) pure internal {
		if (!assertion) {
			revert();
		}
	}
}
contract CENAuth{
	address public owner;
	constructor () public{
		owner = msg.sender;
	}
	event LogOwnerChanged (address msgSender );

	///@notice check if the msgSender is owner
	modifier onlyOwner{
		assert(msg.sender == owner);
		_;
	}

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
contract CENStop is CENAuth{
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
contract Token is SafeMath {
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

	function burn(uint256 amount) public returns (bool);
	
	function frozenCheck(address _from , address _to) view private returns (bool);

	function freezeAccount(address target , bool freeze) public;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn    (address indexed _owner , uint256 _value);
}
contract StandardToken is Token ,CENStop{

	function transfer(address _to, uint256 _value) stoppable public returns (bool ind) {
		//Default assumes totalSupply can&#39;t be over max (2^256 - 1).
		//If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
		//Replace the if with this one instead.
		//if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
		require(_to!= address(0));
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
		require(_to!= address(0));
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
		require(_spender!= address(0));
		require(_value>0);
		require(allowed[msg.sender][_spender]==0);
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
	function frozenCheck(address _from , address _to) view private returns (bool){
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		return true;
	}
	function freezeAccount(address target , bool freeze) onlyOwner public{
		frozenAccount[target] = freeze;
	}

	mapping (address => uint256)                      internal  balances;
	mapping (address => mapping (address => uint256)) private  allowed;
	mapping (address => bool)                         private  frozenAccount;    //Save frozen account

}
contract CENToken is StandardToken{

	string public name = "CEN";                                   /// Set the full name of this contract
	uint256 public decimals = 18;                                 /// Set the decimal
	string public symbol = "CEN";                                 /// Set the symbol of this contract

	constructor() public {                    /// Should have sth in this
		owner = msg.sender;
		totalSupply = 1000000000000000000000000000;
		balances[msg.sender] = totalSupply;
	}

	function () stoppable public {
		revert();
	}

}