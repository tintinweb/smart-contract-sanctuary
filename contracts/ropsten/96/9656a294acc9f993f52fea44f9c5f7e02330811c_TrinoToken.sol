pragma solidity ^0.4.23;

contract Ownable
{
    //--------------------------------------------------------------------------
    //
    //	Properties
    //
    //--------------------------------------------------------------------------

    address public owner;


    //--------------------------------------------------------------------------
    //
    //	Events
    //
    //--------------------------------------------------------------------------

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred
    (
        address indexed previousOwner,
        address indexed newOwner
    );


    //--------------------------------------------------------------------------
    //
    //	Constructor
    //
    //--------------------------------------------------------------------------

    constructor() public
    {
        owner = msg.sender;
    }

    //--------------------------------------------------------------------------
    //
    //	Modifiers
    //
    //--------------------------------------------------------------------------

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function renounceOwnership() public onlyOwner
    {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner
    {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal
    {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if(a == 0)
        {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic
{
    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    //--------------------------------------------------------------------------
    //
    //	Events
    //
    //--------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic
{
    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    //--------------------------------------------------------------------------
    //
    //	Events
    //
    //--------------------------------------------------------------------------

    event Approval
    (
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TokenDestructible is Ownable
{
    //--------------------------------------------------------------------------
    //
    //	Constructor
    //
    //--------------------------------------------------------------------------

    constructor() public payable { }

    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function destroy(address[] tokens) onlyOwner public
    {
        for (uint256 i = 0; i < tokens.length; i++)
        {
            ERC20Basic token = ERC20Basic(tokens[i]);
            uint256 balance = token.balanceOf(this);
            token.transfer(owner, balance);
        }

        selfdestruct(owner);
    }
}

contract BasicToken is ERC20Basic
{
    using SafeMath for uint256;

    //--------------------------------------------------------------------------
    //
    //	Properties
    //
    //--------------------------------------------------------------------------

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function totalSupply() public view returns (uint256)
    {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256)
    {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken
{
    //--------------------------------------------------------------------------
    //
    //	Properties
    //
    //--------------------------------------------------------------------------

    mapping (address => mapping (address => uint256)) internal allowed;

    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender,uint256 _value) public returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner,address _spender) public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender,uint _addedValue) public returns (bool)
    {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender,uint _subtractedValue) public returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue)
        {
            allowed[msg.sender][_spender] = 0;
        }
        else
        {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract BurnableToken is BasicToken
{

    //--------------------------------------------------------------------------
    //
    //	Events
    //
    //--------------------------------------------------------------------------

    event Burn(address indexed burner, uint256 value);

    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function burn(uint256 _value) public
    {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal
    {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract StandardBurnableToken is BurnableToken, StandardToken
{
    //--------------------------------------------------------------------------
    //
    //	Public Methods
    //
    //--------------------------------------------------------------------------

    function burnFrom(address _from, uint256 _value) public
    {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

}

contract TrinoToken is StandardBurnableToken,TokenDestructible
{
    //--------------------------------------------------------------------------
    //
    //	Properties
    //
    //--------------------------------------------------------------------------

    string public name = "TRINO";
    string public symbol = "TIO";

    uint public decimals = 18;
    uint256 public INITIAL_SUPPLY = 3750000000 * (10 ** decimals); // 3 750 000 000

    //--------------------------------------------------------------------------
    //
    //	Constructor
    //
    //--------------------------------------------------------------------------

    constructor() public
    {
        owner = msg.sender;
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
    }

}