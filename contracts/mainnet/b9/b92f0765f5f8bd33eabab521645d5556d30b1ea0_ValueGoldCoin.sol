/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

//SPDX-License-Identifier: No License

pragma solidity ^0.8.1;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,"You're not authorized");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0),"New owner cannot be 0 address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
    /// Total amount of tokens
  uint256 public totalSupply;
  
  function balanceOf(address _owner) public view virtual  returns (uint256 balance);
  
  function transfer(address _to, uint256 _amount) public virtual returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public virtual view returns (uint256 remaining);
  
  function transferFrom(address _from, address _to, uint256 _amount) public virtual returns (bool success);
  
  function approve(address _spender, uint256 _amount) public virtual returns (bool success);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  //balance in each address account
  mapping(address => uint256) balances;

  
  /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view virtual override returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {
  using SafeMath for *;
  
  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool success) {
    require(_to != address(0), "New address cannot be 0 address");
    require(balances[_from] >= _amount,"Should have balance");
    require(allowed[_from][msg.sender] >= _amount,"should have allowed the sender");
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to],"amount cannot be 0");

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
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
   * @param _amount The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)  public view virtual override returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
contract MintableToken is StandardToken, Ownable {
    
    uint256 public cap = 100000000000*10**18;
    
    function mint(address _account, uint256 _amount) public onlyOwner returns(bool) {
        _mint(_account, _amount);
        return true;
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    
    function _mint(address account, uint256 amount) internal virtual {
        
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply + amount <= cap, "Maximum token supply exceeded");
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

contract BurnableToken is StandardToken, Ownable {
    
    function burn(uint256 _amount) public onlyOwner returns(bool) {
        _burn(owner, _amount);
        return true;
    }
    
    /** @dev Burn `amount` tokens from the  `owner` accounr, decreasing
     * the total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `totalSupply` should be more than the balance in the owner account.
     * - 'balance' of owner should be more than the amount to be burned
     */
    
    function _burn(address account, uint256 amount) internal virtual {
        
        require(totalSupply >= amount);
        require(balances[account] >= amount);
        totalSupply -= amount;
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }
}

/**
 * @title Value Gold Coin 
 * @dev Token representing VGC.
 */
 contract ValueGoldCoin is  MintableToken, BurnableToken{
     using SafeMath for uint256;
     
     string public name ;
     string public symbol ;
     uint8 public decimals = 18 ;
  
     /**
     * @dev Constructor function to initialize the initial supply of token to the creator of the contract
     * @param tokenName The name of the token
     * @param tokenSymbol The symbol of the token
     */
     constructor (
            string memory tokenName,
            string memory tokenSymbol
         ) {
         name = tokenName;
         symbol = tokenSymbol;
    }
     
     /**
     *@dev helper method to get token details, name, symbol and totalSupply in one go
     */
 
    function getTokenDetail() public view virtual returns (string memory, string memory , uint256) {
	    return (name, symbol, totalSupply);
    }
 }