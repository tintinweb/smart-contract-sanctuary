/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity ^0.4.13;

contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {

		uint256 c = a / b;

		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;


	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);


		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}


	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

}


contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;


	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}


	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}


	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}


	function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}


contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	function Ownable() {
		owner = msg.sender;
	}


	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}



contract MintableToken is StandardToken, Ownable {
	event Mint(address indexed to, uint256 amount);
	event MintFinished();

	bool public mintingFinished = false;


	modifier canMint() {
		require(!mintingFinished);
		_;
	}


	function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
		totalSupply = totalSupply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		Mint(_to, _amount);
		Transfer(0x0, _to, _amount);
		return true;
	}


	function finishMinting() onlyOwner public returns (bool) {
		mintingFinished = true;
		MintFinished();
		return true;
	}
}


contract BurnableToken is StandardToken {

	event Burn(address indexed burner, uint256 value);


	function burn(uint256 _value) public {
		require(_value > 0);
		require(_value <= balances[msg.sender]);



		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(burner, _value);
	}
}


contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;



	modifier whenNotPaused() {
		require(!paused);
		_;
	}


	modifier whenPaused() {
		require(paused);
		_;
	}


	function pause() onlyOwner whenNotPaused public {
		paused = true;
		Pause();
	}


	function unpause() onlyOwner whenPaused public {
		paused = false;
		Unpause();
	}
}



contract PausableToken is StandardToken, Pausable {

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}
}


contract WithdrawVault is Ownable {
	using SafeMath for uint256;

	mapping (address => uint256) public deposited;
	address public wallet;


	function WithdrawVault(address _wallet) {
		require(_wallet != 0x0);
		wallet = _wallet;
	}

	function deposit(address investor) onlyOwner payable {
		deposited[investor] = deposited[investor].add(msg.value);
	}

	function close() onlyOwner {
		wallet.transfer(this.balance);
	}

}

contract Migrations {
	address public owner;
	uint public last_completed_migration;

	modifier restricted() {
		if (msg.sender == owner) _;
	}

	function Migrations() {
		owner = msg.sender;
	}

	function setCompleted(uint completed) restricted {
		last_completed_migration = completed;
	}

	function upgrade(address new_address) restricted {
		Migrations upgraded = Migrations(new_address);
		upgraded.setCompleted(last_completed_migration);
	}
}

contract TokenRecipient {

	function tokenFallback(address sender, uint256 _value, bytes _extraData) returns (bool) {}

}

contract FunctionX is MintableToken, BurnableToken, PausableToken {

	string public constant name = "Function X";
	string public constant symbol = "FX";
	uint8 public constant decimals = 18;

	function FunctionX() {
		mint(msg.sender, 1e26 );
		mint(0x901FCeaF2DC4A7b5c6d699a79DBf8468a29DD873, 1e25);
		mint(0xEd9dd2a4F4455C0B42b053343F74Af2F926537ae, 1e25);
		mint(0x14Aab2435DDa3A7b77538731750B49CA7733A65d, 1e25);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		bool result = super.transferFrom(_from, _to, _value);
		return result;
	}

	mapping (address => bool) stopReceive;

	function setStopReceive(bool stop) {
		stopReceive[msg.sender] = stop;
	}

	function getStopReceive() constant public returns (bool) {
		return stopReceive[msg.sender];
	}

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		require(!stopReceive[_to]);
		bool result = super.transfer(_to, _value);
		return result;
	}

	function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
		bool result = super.mint(_to, _amount);
		return result;
	}

	function burn(uint256 _value) public {
		super.burn(_value);
	}

	function pause() onlyOwner whenNotPaused public {
		super.pause();
	}

	function unpause() onlyOwner whenPaused public {
		super.unpause();
	}

	function transferAndCall(address _recipient, uint256 _amount, bytes _data) {
		require(_recipient != address(0));
		require(_amount <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_recipient] = balances[_recipient].add(_amount);

		require(TokenRecipient(_recipient).tokenFallback(msg.sender, _amount, _data));
		Transfer(msg.sender, _recipient, _amount);
	}

	function transferERCToken(address _tokenContractAddress, address _to, uint256 _amount) onlyOwner {
		require(ERC20(_tokenContractAddress).transfer(_to, _amount));
	}

}