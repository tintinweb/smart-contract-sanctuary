pragma solidity ^0.4.24;

/**
 * title SafeMath
 * @dev Math operations with safety checks that throw on error
*/

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20 interface
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */

interface ERC20 {

    //Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external constant returns (uint256 balance);

    //Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
    //The function SHOULD throw if the _from account balance does not have enough tokens to spend.
    //
    //Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    //Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    //
    //The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    //This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge
    //fees in sub-currencies. The function SHOULD throw unless the _from account has deliberately authorized
    //the sender of the message via some mechanism.
    //
    //Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    //Allows _spender to withdraw from your account multiple times, up to the _value amount.
    //If this function is called again it overwrites the current allowance with _value.
    //
    //NOTE: To prevent attack vectors like the one described here and discussed here, clients SHOULD make
    //sure to create user interfaces in such a way that they set the allowance first to 0 before setting it
    //to another value for the same spender. THOUGH The contract itself shouldn&#39;t enforce it, to allow
    //backwards compatibility with contracts deployed before
    function approve(address _spender, uint256 _value) external returns (bool success);

    //Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external returns (uint256 remaining);

    //MUST trigger when tokens are transferred, including zero value transfers.
    //
    //A token contract which creates new tokens SHOULD trigger a Transfer event with the _from
    //address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}


contract POMZ is ERC20 {

    //use libraries section
	using SafeMath for uint256;

    //token characteristics section
    uint public constant decimals = 8;
    uint256 public totalSupply = 5000000000 * 10 ** decimals;
    string public constant name = "POMZ";
    string public constant symbol = "POMZ";

    //storage section
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    //all token to creator
	constructor() public {
		balances[msg.sender] = totalSupply;
	}

    //Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public view returns (uint256) {
	    return balances[_owner];
    }

    //Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
    //The function SHOULD throw if the _from account balance does not have enough tokens to spend.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        uint256 previousBalances = balances[_to];
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        assert(balances[_to].sub(_value) == previousBalances);
        return true;
    }

    //Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        uint256 previousBalances = balances[_to];
	    balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
		assert(balances[_to].sub(_value) == previousBalances);
        return true;
    }

    //Allows _spender to withdraw from your account multiple times, up to the _value amount.
    //If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // If ether is sent to this address, send it back.
	function () public {
        revert();
    }

}