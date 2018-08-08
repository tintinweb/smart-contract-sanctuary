pragma solidity ^0.4.24;
// Made By Yoondae - ydwinha@gmail.com - https://blog.naver.com/ydwinha

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

    constructor() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() constant public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract tokenProvider is OwnerHelper, ERC20Interface
{
    using SafeMath for uint;
    string public name;
    string public symbol;
    uint public decimals;
    address public wallet;
    uint constant private E18 = 1000000000000000000;
    uint public maxSupply = 100000000 * E18;
    uint public totalSupply = 0;
    uint public tokenPerEther = 1000;

    uint public etherReceived = 0;

    mapping (address => uint) internal balances;
    mapping (address => mapping ( address => uint )) internal approvals;

    constructor() public
    {
        name = "testTokenProvider";
        decimals = 18;
        symbol = "TTP";
        totalSupply = 0;
        
        owner = msg.sender;
        wallet = msg.sender;
    }
    
    function () payable public
    {
        buyCoin();
    }
    
    function buyCoin() private
    {
        uint tokens = msg.value.mul(tokenPerEther);
        
        require(maxSupply >= totalSupply.add(tokens));
        
        totalSupply = totalSupply.add(tokens);
        etherReceived = etherReceived.add(msg.value);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        
        wallet.transfer(address(this).balance);
    }
    function totalSupply() constant public returns (uint) 
    {
        return totalSupply;
    }
    
    function balanceOf(address _who) public view returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferMultiple(address[] _addresses, uint[] _values) onlyOwner public returns (bool) 
    {
        require(_addresses.length == _values.length);
        
        uint value = 0;
        
        for(uint i = 0; i < _addresses.length; i++)
        {
            value = _values[i] * E18;
            require(balances[msg.sender] >= value);
            
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[_addresses[i]] = balances[_addresses[i]].add(value);
            
            emit Transfer(msg.sender, _addresses[i], value);
        }
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
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
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
}