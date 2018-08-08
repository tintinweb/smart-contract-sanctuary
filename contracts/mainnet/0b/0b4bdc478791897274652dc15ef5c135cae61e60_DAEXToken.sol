pragma solidity ^0.4.17;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);
  function approve(address _spender, uint _value) public returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}


/**
 * @title Standard ERC20 token
 */
contract StandardToken is ERC20Basic {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

   /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public returns (bool success) {
	    require((_value > 0) && (balances[msg.sender] >= _value));
	    balances[msg.sender] -= _value;
    	balances[_to] += _value;
    	Transfer(msg.sender, _to, _value);
    	return true;
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    	allowed[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);
    	return true;
    }

   /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

/**
 * @title DAXToken
 */
contract DAEXToken is StandardToken {
    string public constant name = "DAEX Token";
    string public constant symbol = "DAX";
    uint public constant decimals = 18;

    address public target;

    function DAEXToken(address _target) public {
        target = _target;
        totalSupply = 2*10**27;
        balances[target] = totalSupply;
    }
}