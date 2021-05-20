/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.21;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed from, uint256 value);
}
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); 
    return a - b; 
  } 
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) { 
    uint256 c = a + b; assert(c >= a);
    return c;
  }
 
}
 
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]); 
    // SafeMath.sub will throw if there is not enough balance. 
    balances[msg.sender] = balances[msg.sender].sub(_value); 
    balances[_to] = balances[_to].add(_value); 
    emit Transfer(msg.sender, _to, _value); 
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
} 
 
/** 
 * @title Standard ERC20 token 
 * 
 * @dev Implementation of the basic standard token. 
 * @dev https://github.com/ethereum/EIPs/issues/20 
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol 
 */ 
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) internal allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]); 
    balances[_from] = balances[_from].sub(_value); 
    balances[_to] = balances[_to].add(_value); 
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 
    emit Transfer(_from, _to, _value); 
    return true; 
  } 
 
 /** 
  * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender. 
  * 
  * Beware that changing an allowance with this method brings the risk that someone may use both the old 
  * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this 
  * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards: 
  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 
  * @param _spender The address which will spend the funds. 
  * @param _value The amount of tokens to be spent. 
  */ 
  function approve(address _spender, uint256 _value) public returns (bool) { 
    allowed[msg.sender][_spender] = _value; 
    emit Approval(msg.sender, _spender, _value); 
    return true; 
  }
 
 /** 
  * @dev Function to check the amount of tokens that an owner allowed to a spender. 
  * @param _owner address The address which owns the funds. 
  * @param _spender address The address which will spend the funds. 
  * @return A uint256 specifying the amount of tokens still available for the spender. 
  */ 
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { 
    return allowed[_owner][_spender]; 
  } 
 
 /** 
  * approve should be called when allowed[_spender] == 0. To increment 
  * allowed value is better to use this function to avoid 2 calls (and wait until 
  * the first transaction is mined) * From MonolithDAO Token.sol 
  */ 
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
    return true; 
  }
 
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender]; 
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
 
  function () public payable {
    revert();
  }
 
}
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

 
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract MintableToken is StandardToken {
    
  event Mint(address indexed to, uint256 amount);
 
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    return true;
  }
  
  function burn(uint256 _value) public returns (bool) {

    require(_value <= balances[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    totalSupply = totalSupply.sub(_value);
    balances[msg.sender] = balances[msg.sender].sub(_value); 
    balances[address(0)] = balances[address(0)].add(_value); 
    emit Burn(msg.sender, _value); 
    return true; 
  }
 
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
 
  
}
 
contract HondaCivic is MintableToken{
    
    string public constant name = "Honda Civic";
    
    string public constant symbol = "HCV";
    
    uint32 public constant decimals = 18;
    
    IERC20 token = IERC20(address(0x6b175474e89094c44da98b954eedeac495271d0f));
    
    
    function create(uint256 daiAmount) public returns (bool) {
        
        mint(msg.sender, daiAmount/21000);
        
        require(token.transferFrom(msg.sender, address(this), daiAmount));
        
        return true;
    }
    
    function sell(uint256 civics) public returns (bool) {
        
        token.transfer(msg.sender, civics*21000);
        
        require(burn(civics));
        
        return true;
        
    }

}






interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}