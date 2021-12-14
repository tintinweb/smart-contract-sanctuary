/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-30
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-11
*/

pragma solidity ^0.4.24;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  uint256 public totalStake;
  function balanceOf(address who) public view returns (uint256);
  function stakeOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => bool) tokenBlacklist;
  event Blacklist(address indexed blackListed, bool value);


  mapping(address => uint256) balances;
  mapping(address => uint256) locked;
  
  event Stake(address indexed from, uint256 value);
  event UnStake(address indexed from, uint256 value);
  
  function stake(uint256 _value) public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_value <= balances[msg.sender] - locked[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    locked[msg.sender] = locked[msg.sender].add(_value);
    totalStake = totalStake.add(_value);
    
    emit Stake(msg.sender, _value);
    return true;
  }
  
  
  function unStake(uint256 _value) public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_value <= locked[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    locked[msg.sender] = locked[msg.sender].sub(_value);
    totalStake = totalStake.sub(_value);
    emit UnStake(msg.sender, _value);
    return true;
  }
  

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[msg.sender] - locked[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev See {BEP20-balanceOf}.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
   * @dev See {BEP20-stakeOf}.
  */
  function stakeOf(address _owner) public view returns (uint256 balance) {
    return locked[_owner];
  }
    
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[_from] - locked[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  /**
   * @dev See {BEP20-allowance}.
  */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  


  function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
	require(tokenBlacklist[_address] != _isBlackListed);
	tokenBlacklist[_address] = _isBlackListed;
	emit Blacklist(_address, _isBlackListed);
	return true;
  }



}

contract PausableToken is StandardToken, Pausable {

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `_to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }
  
  
  function stake(uint256 _value) public whenNotPaused returns (bool) {
    return super.stake(_value);
  }
  
  function unStake(uint256 _value) public whenNotPaused returns (bool) {
    return super.unStake(_value);
  }
    
  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `_from` and `_to` cannot be the zero address.
   * - `_from` must have a balance of at least `amount`.
   * - the caller must have allowance for `_from`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   */
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   */
  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   * - `_spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
  function blackListAddress(address listAddress,  bool isBlackListed) public whenNotPaused onlyOwner  returns (bool success) {
	return super._blackList(listAddress, isBlackListed);
  }
  
}

contract CoinToken is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

	
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address tokenOwner,address service) public payable{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        totalStake = 0;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        service.transfer(msg.value);
        emit Transfer(address(0), tokenOwner, totalSupply);
    }
	
	function burn(uint256 _value) public {
		_burn(msg.sender, _value);
	}

    /**
       * @dev Destroys `amount` tokens from `account`, reducing the
       * total supply.
       *
       * Emits a {Transfer} event with `to` set to the zero address.
       *
       * Requirements
       *
       * - `account` cannot be the zero address.
       * - `account` must have at least `amount` tokens.
   */
	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		balances[_who] = balances[_who].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
       * the total supply.
       *
       * Emits a {Transfer} event with `from` set to the zero address.
       *
       * Requirements
       *
       * - `to` cannot be the zero address.
   */
    function mint(address account, uint256 amount) onlyOwner public {

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }

    
}