pragma solidity ^0.4.13;

contract IERC20 {
    function totalSupply() constant returns (uint _totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


library SafeMathLib {

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

/**
 * @title Ownable
 * @notice The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @notice The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @notice Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
  
}


/**
 * @title Erc20 Token
 * @notice The ERC20 Token for Cove Identity.
 */
contract Erc20 is IERC20, Ownable {
    
    using SafeMathLib for uint256;
    
    uint256 public constant totalTokenSupply = 100000000 * 10**18;

    string public name = "Dontoshi Token";
    string public symbol = "DTD";
    uint8 public constant decimals = 18;
    
    mapping (address => uint256) public balances;
    //approved[owner][spender]
    mapping(address => mapping(address => uint256)) approved;
    
    function Erc20() {
        balances[msg.sender] = totalTokenSupply;
    }
    
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalTokenSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);                // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]);   // Check for overflows
        balances[_from] = balances[_from].minus(_value);    // Subtract from the sender
        balances[_to] = balances[_to].plus(_value);         // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /**
     * @notice Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @notice Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_value <= approved[_from][msg.sender]);     // Check allowance
        approved[_from][msg.sender] = approved[_from][msg.sender].minus(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @notice Approve `_value` tokens for `_spender`
     * @param _spender The address of the sender
     * @param _value the amount to send
     */
    function approve(address _spender, uint256 _value) returns (bool success) {
        if(balances[msg.sender] >= _value) {
            approved[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }
    
    /**
     * @notice Check `_value` tokens allowed to `_spender` by `_owner`
     * @param _owner The address of the Owner
     * @param _spender The address of the Spender
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return approved[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}