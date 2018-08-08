pragma solidity ^0.4.18;

// Symbol      : ATRA
// Name        : Atra
// Total supply: 100,000,000,000
// Decimals    : 0

interface ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint amount) public returns (bool success);
    function approve(address spender, uint amount) public returns (bool success);
    function transferFrom(address from, address to, uint amount) public returns (bool success);
}

interface ExtendERC20Interface {
    	function transferAndCall(address contractAddress, uint256 amount, bytes data) public returns(bool success);
}

interface TransferAndCallInterface {
    function transferComplete(address tokenOwner, uint amount, bytes data) public returns(bool success);
}

contract AtraOwner {
    address public owner;
    address private _newOwner;

    event OwnershipTransferred(address from, address to);

    function AtraOwner() public {
        owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        _newOwner = newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == _newOwner);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        _newOwner = address(0);
    }
}

contract Atra is AtraOwner, ERC20Interface, ExtendERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function Atra() public {
        symbol = "ATRA";
        name = "Atra";
        decimals = 0;
        _totalSupply = 100000000000; //100,000,000,000
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint amount) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        balances[from] = balances[from].sub(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        Transfer(from, to, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

	function transferAndCall(address contractAddress, uint256 amount, bytes data) public returns(bool success){
	  transfer(contractAddress, amount);
	  require(TransferAndCallInterface(contractAddress).transferComplete(msg.sender, amount, data));
	  return true;
	}

    function () public payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public isOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    event Transfer(address from, address to, uint amount);
    event Approval(address tokenOwner, address spender, uint amount);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}