pragma solidity ^0.4.20;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

contract OwnerHelper
{
    address public owner;
    
    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
}

    function OwnerHelper() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        OwnerTransferPropose(owner, _to);
    }
}

contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() constant public returns (uint _supply);
    function balanceOf( address _who ) constant public returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) constant public returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract Hellob is ERC20Interface, OwnerHelper
{
    using SafeMath for uint256;
    
    string public name;
    uint public decimals;
    string public symbol;
    uint public totalSupply;
    uint private E18 = 1000000000000000000;
    
    bool public tokenLock = false;
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    function Hellob() public
    {
        name = "DANCLE";
        decimals = 18;
        symbol = "DNCL";
        owner = msg.sender;
        
        totalSupply = 2000000000 * E18; // totalSupply
        
        balances[msg.sender] = totalSupply;
    }
 
    function totalSupply() constant public returns (uint) 
    {
        return totalSupply;
    }
    
    function balanceOf(address _who) constant public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(balances[msg.sender] >= _value);
        require(tokenLock == false);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(balances[msg.sender] >= _value);
        approvals[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint) 
    {
        return approvals[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) 
    {
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);        
        require(tokenLock == false);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        Transfer(_from, _to, _value);
        
        return true;
    }
}