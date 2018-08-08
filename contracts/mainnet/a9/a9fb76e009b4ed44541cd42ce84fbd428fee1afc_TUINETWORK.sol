pragma solidity ^0.4.21;

library SafeMath
{
    function mul(uint a, uint b) internal returns (uint)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint)
    {
assert(b > 0);       
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal returns (uint)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256)
    {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal
    {
        if (!assertion)
        {
            throw;
        }
    }
}

contract ERC20Basic
{
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic
{
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic
{
    using SafeMath for uint;
    mapping(address => uint) balances;

    modifier onlyPayloadSize(uint size)
    {
        if(msg.data.length < size + 4)
        {
            throw;
        }
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) constant returns (uint balance)
    {
        return balances[_owner];
    }
}

contract StandardToken is BasicToken, ERC20
{
    mapping (address => mapping (address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32)
    {
        uint _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value)
    {

        
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }
}

contract TUINETWORK is StandardToken
{
    string public name = "TUINETWORK";
    string public symbol = "TUI";
    uint public decimals = 8 ;

   
    uint public INITIAL_SUPPLY =  1680000000000000000;


    
    uint public constant ALLOCATION_LOCK_END_TIMESTAMP = 1559347200;

    address public constant TUI_ADDRESS = 0xCE08f414D107Fd863a3EAbb9817E6F85B81358ab;
    uint public constant    TUI_ALLOCATION = 1000000000000000000; 

   
    function TUINETWORK()
    {
        
        totalSupply = INITIAL_SUPPLY;

       
        balances[msg.sender] = totalSupply;

       
        balances[msg.sender] -= TUI_ALLOCATION;
       

        balances[TUI_ADDRESS]   = TUI_ALLOCATION;
      
    }

    function isAllocationLocked(address _spender) constant returns (bool)
    {
        return inAllocationLockPeriod() && isTeamMember(_spender);
    }

    function inAllocationLockPeriod() constant returns (bool)
    {
        return (block.timestamp < ALLOCATION_LOCK_END_TIMESTAMP);
    }

    function isTeamMember(address _spender) constant returns (bool)
    {
        return _spender == TUI_ADDRESS  ;
    }

        function approve(address spender, uint tokens)
    {
        if (isAllocationLocked(spender))
        {
            throw;
        }
        else
        {
            super.approve(spender, tokens);
        }
    }

    function transfer(address to, uint tokens) onlyPayloadSize(2 * 32)
    {
        if (isAllocationLocked(to))
        {
            throw;
        }
        else
        {
            super.transfer(to, tokens);
        }
    }

    function transferFrom(address from, address to, uint tokens) onlyPayloadSize(3 * 32)
    {
        if (isAllocationLocked(from) || isAllocationLocked(to))
        {
            throw;
        }
        else
        {
            super.transferFrom(from, to, tokens);
        }
    }
}