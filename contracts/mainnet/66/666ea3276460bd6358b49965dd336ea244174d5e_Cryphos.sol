pragma solidity ^0.4.21;

/**
 * Math operations with safety checks
 */
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic
{
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic
{
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic
{
    using SafeMath for uint;
    mapping(address => uint) balances;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size)
    {
        if(msg.data.length < size + 4)
        {
            throw;
        }
        _;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) constant returns (uint balance)
    {
        return balances[_owner];
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20
{
    mapping (address => mapping (address => uint)) allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32)
    {
        uint _allowance = allowed[_from][msg.sender];
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value)
    {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Cryphos ERC20 token
 *
 * @dev Implementation of the Cryphos Token.
 */
contract Cryphos is StandardToken
{
    string public name = "Cryphos";
    string public symbol = "XCPS";
    uint public decimals = 8 ;

    // Initial supply is 30,000,000.00000000
    // AKA: 3 * (10 ** ( 7 + decimals )) when expressed as uint
    uint public INITIAL_SUPPLY = 3000000000000000;

    // Allocation Constants

    // Expiration Unix Timestamp: Friday, November 1, 2019 12:00:00 AM
    // https://www.unixtimestamp.com
    uint public constant ALLOCATION_LOCK_END_TIMESTAMP = 1572566400;

    address public constant RAVI_ADDRESS = 0xB75066802f677bb5354F0850A1e1d3968E983BE8;
    uint public constant    RAVI_ALLOCATION = 120000000000000; // 4%

    address public constant JULIAN_ADDRESS = 0xB2A76D747fC4A076D7f4Db3bA91Be97e94beB01C;
    uint public constant    JULIAN_ALLOCATION = 120000000000000; // 4%

    address  public constant ABDEL_ADDRESS = 0x9894989fd6CaefCcEB183B8eB668B2d5614bEBb6;
    uint public constant     ABDEL_ALLOCATION = 120000000000000; // 4%

    address public constant ASHLEY_ADDRESS = 0xb37B31f004dD8259F3171Ca5FBD451C03c3bC0Ae;
    uint public constant    ASHLEY_ALLOCATION = 210000000000000; // 7%

    constructor()
    {
        // Set total supply
        totalSupply = INITIAL_SUPPLY;

        // Allocate total supply to sender
        balances[msg.sender] = totalSupply;

        // Subtract team member allocations from total supply
        balances[msg.sender] -= RAVI_ALLOCATION;
        balances[msg.sender] -= JULIAN_ALLOCATION;
        balances[msg.sender] -= ABDEL_ALLOCATION;
        balances[msg.sender] -= ASHLEY_ALLOCATION;

        // Credit Team Member Allocation Addresses
        balances[RAVI_ADDRESS]   = RAVI_ALLOCATION;
        balances[JULIAN_ADDRESS] = JULIAN_ALLOCATION;
        balances[ABDEL_ADDRESS]  = ABDEL_ALLOCATION;
        balances[ASHLEY_ADDRESS] = ASHLEY_ALLOCATION;
    }
    
    // Stop transactions from team member allocations during lock period
    function isAllocationLocked(address _spender) constant returns (bool)
    {
        return inAllocationLockPeriod() && 
        (isTeamMember(_spender) || isTeamMember(msg.sender));
    }

    // True if the current timestamp is before the allocation lock period
    function inAllocationLockPeriod() constant returns (bool)
    {
        return (block.timestamp < ALLOCATION_LOCK_END_TIMESTAMP);
    }

    // Is the spender address one of the Cryphos Team?
    function isTeamMember(address _spender) constant returns (bool)
    {
        return _spender == RAVI_ADDRESS  ||
            _spender == JULIAN_ADDRESS ||
            _spender == ABDEL_ADDRESS ||
            _spender == ASHLEY_ADDRESS;
    }

    // Function wrapper to check for allocation lock
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

    // Function wrapper to check for allocation lock
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

    // Function wrapper to check for allocation lock
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