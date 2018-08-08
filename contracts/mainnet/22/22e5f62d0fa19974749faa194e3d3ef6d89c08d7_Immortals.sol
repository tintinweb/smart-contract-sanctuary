pragma solidity ^0.4.13;

contract Owned {

    address owner;
    
    function Owned() { owner = msg.sender; }

    modifier onlyOwner { require(msg.sender == owner); _; }
}

contract SafeMath {
    
    function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TokenERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract TokenNotifier {

    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

contract ImmortalToken is Owned, SafeMath, TokenERC20 {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    uint8 public constant decimals = 0;
    uint8 public constant totalSupply = 100;
    string public constant name = "Immortal";
    string public constant symbol = "IMT";
    string public constant version = "1.0.1";

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) {
            return false;
        }
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        assert(balances[msg.sender] >= 0);
        balances[_to] = safeAdd(balances[_to], _value);
        assert(balances[_to] <= totalSupply);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
            return false;
        }
        balances[_from] = safeSub(balances[_from], _value);
        assert(balances[_from] >= 0);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        assert(balances[_to] <= totalSupply);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if (!approve(_spender, _value)) {
            return false;
        }
        TokenNotifier(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Immortals is ImmortalToken {

    uint256 public tokenAssigned = 0;

    event Assigned(address _contributor, uint256 _immortals);

    function () payable {
		//Assign immortals based on ethers sent
        require(tokenAssigned < totalSupply && msg.value >= 0.5 ether);
		uint256 immortals = msg.value / 0.5 ether;
		uint256 remainder = 0;
		//Find the remainder
		if (safeAdd(tokenAssigned, immortals) > totalSupply) {
			immortals = totalSupply - tokenAssigned;
			remainder = msg.value - (immortals * 0.5 ether);
		} else {
			remainder = (msg.value % 0.5 ether);
		}	
		require(safeAdd(tokenAssigned, immortals) <= totalSupply);
		balances[msg.sender] = safeAdd(balances[msg.sender], immortals);
		tokenAssigned = safeAdd(tokenAssigned, immortals);
		assert(balances[msg.sender] <= totalSupply);
		//Send remainder to sender
		msg.sender.transfer(remainder);
		Assigned(msg.sender, immortals);
    }

	function redeemEther(uint256 _amount) onlyOwner external {
        owner.transfer(_amount);
    }
}