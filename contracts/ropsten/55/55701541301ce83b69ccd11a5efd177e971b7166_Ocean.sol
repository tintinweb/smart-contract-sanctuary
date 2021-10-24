/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity 0.5.0;

contract SafeMath {

	function safeAdd(uint a, uint b) public pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}

	function safeSub(uint a, uint b) public pure returns (uint c) {
		require(b <= a);
		c = a - b;
	}

	function safeMul(uint a, uint b) public pure returns (uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}

	function safeDiv(uint a, uint b) public pure returns (uint c) {
		require(b > 0);
		c = a / b;
	}
}

contract ERC20Interface {
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner)  public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
	address public owner;
	address public newOwner;
	event OwnershipTransferred(address indexed _from, address indexed _to);
	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}

}

contract Ocean is ERC20Interface, Owned, SafeMath {
	string public symbol;
	string public name;
	uint8 public decimals;
	uint public _totalSupply;
    event Burn(address indexed burner, uint256 value);
	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;
	constructor() public {
		symbol = "ocn";
		name = "Ocean";
		decimals = 18;
		_totalSupply = 1000000000000 * (10 ** decimals);
		balances[0x65E1Fcd0cfC6503986ccc6ed2f0026dc6AE91f0c] = _totalSupply;
		emit Transfer(address(0), 0x65E1Fcd0cfC6503986ccc6ed2f0026dc6AE91f0c, _totalSupply);
	}


    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who] - _value;
        _totalSupply = _totalSupply - _value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

	function totalSupply() public view returns (uint) {
		return _totalSupply - balances[address(0)];
	}

	function balanceOf(address tokenOwner) public view returns (uint balance) {
		return balances[tokenOwner];
	}

	function transfer(address to, uint tokens) public returns (bool success) {
		balances[msg.sender] = safeSub(balances[msg.sender], tokens);
		balances[to] = safeAdd(balances[to], tokens);
		emit Transfer(msg.sender, to, tokens);
		return true;
	}

	function approve(address spender, uint tokens) public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

 
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		balances[from] = safeSub(balances[from], tokens);
		allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
		balances[to] = safeAdd(balances[to], tokens);
		emit Transfer(from, to, tokens);
		return true;
	}

	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
	} 

	function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
		return true;
	}

	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}

}