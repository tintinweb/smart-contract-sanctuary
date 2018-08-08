pragma solidity ^0.4.24;

library SafeMath {

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20plus {
    function totalSupply() public view returns (uint); 
    function balanceOf(address tokenOwner) public view returns (uint balance);  
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
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

contract Nakama is ERC20plus, Owned {
    using SafeMath for uint;
 
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    bool public stopped = false;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "NKM"; 
        name = "Nakama";
        decimals = 18;
        _totalSupply = 10422698937 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier ifRunning {
        assert (!stopped);
        _;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function transfer(address to, uint tokens) public ifRunning returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public ifRunning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public ifRunning returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function stop() public onlyOwner {
        stopped = true;
    }

    function start() public onlyOwner {
        stopped = false;
    }

    function setName(string _name) public onlyOwner {
        name = _name;
    }

    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }

    function () public payable {
        revert();
    }
}