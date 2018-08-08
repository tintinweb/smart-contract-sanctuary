pragma solidity ^0.4.21;

contract TokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20 {
	uint256 public totalSupply;
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool ok);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok);
	function approve(address _spender, uint256 _value) public returns (bool ok);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract WankCoin is ERC20 {
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint8 public decimals;
	string public name;
	string public symbol;
	
	bool public running;
	address public owner;
	address public ownerTemp;
	
	

	modifier isOwner {
		require(owner == msg.sender);
		_;
	}
	
	modifier isRunning {
		require(running);
		_;
	}
	
	
	function WankCoin() public {
		running = true;
		owner = msg.sender;
		decimals = 18;
		totalSupply = 2 * uint(10)**(decimals + 9);
		balances[owner] = totalSupply;
		name = "WANKCOIN";
		symbol = "WKC";
		emit Transfer(0x0, owner, totalSupply);
	}
	
	function transfer(address _to, uint256 _value) public isRunning returns (bool) {
		require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[_to] += _value;
		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public isRunning returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256) {
	  return allowed[_owner][_spender];
	}
	
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public isRunning returns (bool ok) {
		TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
    }
	
	
	
	function setName(string _name) public isOwner {
		name = _name;
	}
	
	function setSymbol(string _symbol) public isOwner {
		symbol = _symbol;
	}
	
	function setRunning(bool _run) public isOwner {
		running = _run;
	}
	
	function transferOwnership(address _owner) public isOwner {
		ownerTemp = _owner;
	}
	
	function acceptOwnership() public {
		require(msg.sender == ownerTemp);
		owner = ownerTemp;
		ownerTemp = 0x0;
	}
	
	function collectERC20(address _token, uint _amount) public isRunning isOwner returns (bool success) {
		return ERC20(_token).transfer(owner, _amount);
	}
}