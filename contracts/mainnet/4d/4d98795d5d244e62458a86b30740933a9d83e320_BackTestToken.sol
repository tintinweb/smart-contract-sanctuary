pragma solidity ^0.4.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20: Token standard
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandartToken is ERC20 {
    using SafeMath for uint256;

    uint256 internal total;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() public constant returns (uint256) {
        return total;
    }
    
    function balanceOf(address owner) public constant returns (uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract BackTestToken is StandartToken
{
    uint8 public constant decimals = 18;
    string public constant name = "Back Test Token";
    string public constant symbol = "BTT";
    uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));
    uint256 private constant reqvalue = 1 * (10 ** uint256(decimals));

    address internal holder;

    constructor() public {
        holder = msg.sender;
        total = INITIAL_SUPPLY;
        balances[holder] = INITIAL_SUPPLY;
    }

    function() public payable {
        require(msg.sender != address(0));
        require(reqvalue <= balances[holder]);

        if(msg.value > 0) msg.sender.transfer(msg.value);

        balances[holder] = balances[holder].sub(reqvalue);
        balances[msg.sender] = balances[msg.sender].add(reqvalue);
        
        emit Transfer(holder, msg.sender, reqvalue);
    }
}