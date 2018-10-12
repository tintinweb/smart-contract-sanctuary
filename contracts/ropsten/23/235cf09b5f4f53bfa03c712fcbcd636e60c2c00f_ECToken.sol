pragma solidity ^0.4.25;

contract ERC20Token {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Owned {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public returns (bool success) {
        require (newOwner != address(0));
        owner = newOwner;
        return true;
    }
}

contract ECToken is ERC20Token, Owned {
    using SafeMath for uint256;
    
    constructor() public {
        symbol = "EC";
        name = "ElephantChain";
        decimals = 8;
        totalSupply = 21000000 * 10 ** uint256(decimals);
        
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    //ERC20Token
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
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
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    //end ERC20Token
    
    //frozenAccount
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
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
    //end frozenAccount
    
    function increaseSupply(uint256 tokens) onlyOwner public returns (bool success) {
        require(tokens > 0);
        totalSupply = totalSupply.add(tokens);
        balances[owner] = balances[owner].add(tokens);
        _transfer(msg.sender, owner, tokens);
        return true;
    }

    function decreaseSupply(uint256 tokens) onlyOwner public returns (bool success) {
        require(tokens > 0);
        require(balances[owner] >= tokens);
        balances[owner] = balances[owner].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        _transfer(owner, msg.sender, tokens);
        return true;
    }
    
    function _transfer(address spender, address target, uint256 tokens) private {
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