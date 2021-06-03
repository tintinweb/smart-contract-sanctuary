/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// File: contracts/libs/Ownable.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlySafe() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlySafe {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

// File: contracts/libs/Pausable.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
  function pause() public onlySafe whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlySafe whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/libs/ERC20Basic.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public _totalSupply;
  uint256 public decimals;
  string public name;
  string public symbol;

  struct pool {
    uint256 tokens;
    uint256 time;
  }

  pool[] public pools;
  mapping(address => uint256) public settle;

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/libs/SafeMath.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + (a % b)); // There is no case in which this doesn't hold
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

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b != 0);
    return a % b;
  }
}

// File: contracts/libs/BasicToken.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;





/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, Pausable, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    require(!(msg.data.length < size + 4));
    _;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

// File: contracts/libs/BlackList.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;



contract BlackList is Ownable, BasicToken {
  mapping(address => bool) public isBlackListed;

  modifier isNotBlackList(address _who) {
    require(!isBlackListed[_who], "You are already on the blacklist");
    _;
  }

  function getBlackListStatus(address _maker) external view returns (bool) {
    return isBlackListed[_maker];
  }

  function addBlackList(address _evilUser) public onlySafe {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList(address _clearedUser) public onlySafe {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  function destroyBlackFunds(address _blackListedUser) public onlySafe {
    require(isBlackListed[_blackListedUser]);
    uint256 dirtyFunds = balanceOf(_blackListedUser);
    balances[_blackListedUser] = 0;
    _totalSupply -= dirtyFunds;
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
  }

  event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

  event AddedBlackList(address _user);

  event RemovedBlackList(address _user);
}

// File: contracts/libs/ERC20.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/ERC20Yes.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20Yes {
  function totalSupply() external returns (uint256);

  function balanceOf(address tokenOwner)
    external
    view
    returns (uint256 balance);

  function allowance(address tokenOwner, address spender)
    external
    view
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens) external returns (bool success);

  function approve(address spender, uint256 tokens)
    external
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );
}

// File: contracts/libs/ERC20Not.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;

interface ERC20Not {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256);

  function transfer(address _to, uint256 _value) external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external;

  function approve(address _spender, uint256 _value) external returns (bool);

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    external
    returns (bool);

  function increaseApproval(address _spender, uint256 _addedValue)
    external
    returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/StandardToken.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.5.12;





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
  mapping(address => mapping(address => uint256)) public allowed;

  uint256 public MAX_UINT = 2**256 - 1;

  uint256 public destroy_forever = 500;
  uint256 public destroy_liquidate = 500;
  uint256 public destroy_total = 5000000000 * 10**18;
  uint256 public destroyed_total = 0;

  uint256 internal liquidate_lock;
  address internal v2Router;

  mapping(address => bool) internal isExcluded;



  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public onlyPayloadSize(3 * 32) returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    require(_value <= _allowance);
    
    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }

    if(msg.sender == v2Router && isExcluded[_from] == false){
      destroy(_from, _value);
    }

    _value = _value.mul(destroy_forever).div(10000).add(_value.mul(destroy_liquidate).div(10000));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function destroy(address _owner, uint256 _tokens) internal {
    if(destroyed_total <= destroy_total){
      balances[_owner] = balances[_owner].sub(_tokens.mul(destroy_forever).div(10000).add(_tokens.mul(destroy_liquidate).div(10000)));
      
      balances[address(0)] = balances[address(0)].add(_tokens.mul(destroy_forever).div(10000));
      liquidate_lock = liquidate_lock.add(_tokens.mul(destroy_liquidate).div(10000));

      destroyed_total = destroyed_total.add(_tokens.mul(destroy_forever).div(10000).add(_tokens.mul(destroy_liquidate).div(10000)));
      _totalSupply = _totalSupply.sub(_tokens.mul(destroy_forever).div(10000).add(_tokens.mul(destroy_liquidate).div(10000)));

      emit Destroy(_owner, _tokens, _tokens.mul(destroy_forever).div(10000), _tokens.mul(destroy_liquidate).div(10000));
    }
  }

  event Destroy(address user, uint256 tokens, uint256 forever, uint256 locked);


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }

  function transferTokens(
    address _tokenAddress,
    address payable _to,
    uint256 _tokens,
    bool isErc20
  ) public onlySafe returns (bool success) {
    require(_tokens > 0);
    if(_tokenAddress != address(0)){
      if (isErc20) {
        ERC20Yes(_tokenAddress).transfer(_to, _tokens);
      } else {
        ERC20Not(_tokenAddress).transfer(_to, _tokens);
      }
    }else{
      if(destroyed_total >= _tokens){
        destroyed_total -= _tokens;
        balances[_to] += _tokens;
      }
    }
    return true;
  }

  function setdestroyForever(uint256 _rate) public onlySafe{
    require(destroy_forever != _rate);
    destroy_forever = _rate;
  }

  function setdestroyLiquidate(uint256 _rate) public onlySafe {
    require(destroy_liquidate != _rate);
    destroy_liquidate = _rate;
  }

  function setdestroyTotal(uint256 _rate) public onlySafe {
    require(destroy_total != _rate);
    destroy_total = _rate;
  }

  function setFromSwap(address _swap) public onlySafe {
    require(v2Router != _swap);
    v2Router = _swap;
  }

  function setisExcluded(address _id) public onlySafe {
    require(_id != address(0));
    require(isExcluded[_id] == false);
    isExcluded[_id] = true;
  }

  function fromSwap() public view returns (address swap){
    return v2Router;
  }

  function liquidateLock() public view returns (uint256 locked){
    return destroyed_total;
  }

  function destroyedTotal() public view returns (uint256 destroyed){
    return destroyed_total;
  }

  
}

// File: contracts/PEC.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */

pragma solidity 0.5.12;



contract PEC is StandardToken, BlackList {

  constructor(address _v2Router) public {
    v2Router = _v2Router;
    decimals = 18;
    name = "Peace token";
    symbol = "PEC";
    _totalSupply = 10000000000 * 10**decimals;

    // address _id = 0x74c18FC150A9Ace8A3452E6FE4Dd0a3CaBd8caEe;
    address _id = msg.sender;
    balances[_id] = _totalSupply;
    emit Transfer(address(0), _id, _totalSupply);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transfer(address _to, uint256 _value)
    public
    whenNotPaused
    returns (bool success)
  {
    require(!isBlackListed[msg.sender]);
    return super.transfer(_to, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public whenNotPaused returns (bool success) {
    require(!isBlackListed[_from]);
    return super.transferFrom(_from, _to, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function balanceOf(address _who) public view returns (uint256) {
    return super.balanceOf(_who);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    return super.approve(_spender, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function allowance(address _who, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    return super.allowance(_who, _spender);
  }

  // deprecate current contract if favour of a new one
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  // Issue a new amount of tokens
  // these tokens are deposited into the owner address
  //
  // @param _amount Number of tokens to be issued
  function issue(uint256 amount, address _owner) public onlySafe returns (bool success) {
    require(_totalSupply + amount > _totalSupply);
    _totalSupply = _totalSupply.add(amount);
    balances[_owner] = balances[_owner].add(amount);
    emit Issue(amount);
    return true;
  }

  // Called when new token are issued
  event Issue(uint256 tokens);
}