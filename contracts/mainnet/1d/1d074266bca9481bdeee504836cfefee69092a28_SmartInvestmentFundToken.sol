pragma solidity ^0.4.21;
pragma experimental "v0.5.0";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract SmartInvestmentFundToken {
    using SafeMath for uint256;

    /* Map all our our balances for issued tokens */
    mapping (address => uint256) balances;

    /* Map between users and their approval addresses and amounts */
    mapping(address => mapping (address => uint256)) allowed;

    /* The name of the contract */
    string public name = "Smart Investment Fund Token v2";

    /* The symbol for the contract */
    string public symbol = "XSFT";

    /* How many DPs are in use in this contract */
    uint8 public decimals = 6;

    /* Defines the current supply of the token in its own units */
    uint256 public totalSupply = 722935000000;

    /* Our transfer event to fire whenever we shift XSFT around */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* Our approval event when one user approves another to control */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Create a new instance of this fund with links to other contracts that are required. */
    function SmartInvestmentFundToken (address _tokenConvertor) public {
		// Give the 0x00 address the fulll supply and allow the token convertor to transfer it
        balances[0] = totalSupply;
        allowed[0][_tokenConvertor] = totalSupply;
        emit Approval(0, _tokenConvertor, totalSupply);
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    } 
    
    /* Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines */
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3) returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /* Adds an approval for the specified account to spend money of the message sender up to the defined limit */
    function approve(address _spender, uint256 _amount) public onlyPayloadSize(2) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Gets the current allowance that has been approved for the specified spender of the owner address */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* Gets the balance of a specified account */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfer the balance from owner&#39;s account to another account */
    function transfer(address _to, uint256 _amount) public onlyPayloadSize(2) returns (bool) {
        /* Check if sender has balance and for overflows */
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

        /* Add and subtract new balances */
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        /* Fire notification event */
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}