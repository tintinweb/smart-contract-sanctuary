pragma solidity ^0.4.25;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract ECToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    constructor() public {
        symbol = "EC";
        name = "大象链";
        decimals = 8;
        _totalSupply = 21000000 * 10 ** uint256(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        _transfer(msg.sender,to,tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function freezeAccount(address target) onlyOwner public returns (bool success) {
        require (target != address(0));
        frozenAccount[target] = true;
        emit FrozenFunds(target, true);
        return true;
    }
	
	function unfreezeAccount(address target) onlyOwner public returns (bool success) {
	    require (target != address(0));
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
        return true;
    }

    function increaseSupply(uint256 tokens) onlyOwner public returns (bool success) {
        require(tokens > 0);
        _totalSupply = _totalSupply.add(tokens);
        balances[owner] = balances[owner].add(tokens);
        _transfer(msg.sender, owner, tokens);
        return true;
    }

    function decreaseSupply(uint256 tokens) onlyOwner public returns (bool success) {
        require(tokens > 0);
        require(balances[owner] >= tokens);
        balances[owner] = balances[owner].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        _transfer(owner, msg.sender, tokens);
        return true;
    }
    
    function _transfer(address spender, address target, uint256 tokens) internal {
        require (target != address(0));
        require(tokens > 0);
        require (balances[spender] >= tokens);
        require (balances[target].add(tokens) >= balances[target]);
        require(!frozenAccount[spender]);
        require(!frozenAccount[target]);
        uint256 previousBalances = balances[spender].add(balances[target]);
        balances[spender] = balances[spender].sub(tokens);
        balances[target] = balances[target].add(tokens);
        emit Transfer(spender, target, tokens);
        assert(balances[spender].add(balances[target]) == previousBalances);
    }
}