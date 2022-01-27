// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./IBEP20.sol";

contract StakingPool is OwnableUpgradeable, PausableUpgradeable  {
    IBEP20 public bplus;
    using MathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public totalStakingInfo;
    uint16 public totalPoolConfig;
    struct PoolConfig {
        uint32 id;
        uint32 totalDay;
        uint256 limit;
        uint256 staking;
        uint256 startTime;
        uint256 endTime;
        uint16 apr; //
        uint16 aprDecimal; // enum [1 10 100 10000]
        bool isActive;
    }

    struct StakingInfo {
      uint32 id;
      address sender;
      uint32 poolConfig;
      uint256 staked;
      uint256 createdAt;
      bool isReceived;
    }
    mapping(uint32 => PoolConfig) public poolConfigs;
    mapping(uint256 => StakingInfo) public stakingInfos;
    uint256 public minStaking;
    
    function initialize() public initializer {
      poolConfigs[1].id=1;  
      poolConfigs[1].totalDay=180;  
      poolConfigs[1].limit = 1000000000;
      poolConfigs[1].staking = 0;
      poolConfigs[1].startTime = 1643043600;//1643302800;
      poolConfigs[1].endTime = 1674838800;
      poolConfigs[1].apr=16;
      poolConfigs[1].aprDecimal=10; // 1.6
      poolConfigs[1].isActive=true;

      poolConfigs[2].id=2;  
      poolConfigs[2].totalDay=90;  
      poolConfigs[2].limit = 1000000000;
      poolConfigs[2].staking = 0;
      poolConfigs[2].startTime = 1643043600;//1643302800;
      poolConfigs[2].endTime = 1674838800;
      poolConfigs[2].apr=7;
      poolConfigs[2].aprDecimal=10; // 0.7
      poolConfigs[2].isActive=true;
      totalPoolConfig=2;
      minStaking=100;
        __Ownable_init();
    }

    /**
     * @dev _startTime, _endTime, _startflashSaleTime are unix time
     * _startflashSaleTime should be equal _startTime - 300(s) [5 min]
     */
    function initByOwner(IBEP20 _bplus) public onlyOwner {
        bplus=_bplus;
    }


  function stake(uint256 _amount, uint32 _poolConfigId) external  whenNotPaused returns (uint256) {
        require(poolConfigs[_poolConfigId].id > 0,'Pool not found');
        require(poolConfigs[_poolConfigId].isActive == true ,'Pool not active');
        require(minStaking <= _amount,'Amount must be greater than min Staking');
        uint256 current = block.timestamp;
        require(poolConfigs[_poolConfigId].startTime <= current ,'Pool not start');
        require(current <= poolConfigs[_poolConfigId].endTime,'Pool ended');
        require(_amount + poolConfigs[_poolConfigId].staking <= poolConfigs[_poolConfigId].limit,'Not greater than limit Pool');
        totalStakingInfo.increment();
        uint32 id = uint32(totalStakingInfo.current());
        stakingInfos[id].id=id;
        stakingInfos[id].sender= msg.sender;
        stakingInfos[id].poolConfig=_poolConfigId;
        stakingInfos[id].staked=_amount;
        stakingInfos[id].createdAt= current;
        stakingInfos[id].isReceived=false;
        bplus.approve(address(this), _amount*10**18);
        bplus.transferFrom(msg.sender, address(this), _amount*10**18);
        poolConfigs[_poolConfigId].staking=poolConfigs[_poolConfigId].staking+_amount;
        return id;
    }   

function claim(uint32 _stakingInfoId) external whenNotPaused  {
        require(stakingInfos[_stakingInfoId].id > 0,'Staking Info not found');
        require(stakingInfos[_stakingInfoId].sender == msg.sender,'Staking Info not found');
        require(stakingInfos[_stakingInfoId].isReceived == false,'Staking Info is received');
        uint256 current = block.timestamp;
        uint256 day=(current - stakingInfos[_stakingInfoId].createdAt)/86400;
        uint32 poolConfigId = stakingInfos[_stakingInfoId].poolConfig;
        require(day >= poolConfigs[poolConfigId].totalDay,'Not enough time to claim');
        uint256 total =  stakingInfos[_stakingInfoId].staked 
         + (stakingInfos[_stakingInfoId].staked
         * poolConfigs[poolConfigId].totalDay 
         * poolConfigs[poolConfigId].apr 
         / poolConfigs[poolConfigId].aprDecimal
         / 100);
        
        stakingInfos[_stakingInfoId].isReceived = true;
        bplus.approve(address(this), total*10**18);
        bplus.transferFrom(address(this), msg.sender, total*10**18);
    }

  function getPoolConfig (uint32 _poolConfigId) public view returns(
    uint32 _id, 
    uint32 _totalDay, 
    uint256 _limit,
    uint256 _staking,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _apr,
    uint16 _aprDecimal,
    bool _isActive
    
    ){
      _id = poolConfigs[_poolConfigId].id;  
      _totalDay = poolConfigs[_poolConfigId].totalDay;  
      _limit = poolConfigs[_poolConfigId].limit;
      _staking = poolConfigs[_poolConfigId].staking;
      _startTime = poolConfigs[_poolConfigId].startTime;
      _endTime = poolConfigs[_poolConfigId].endTime;
      _apr = poolConfigs[_poolConfigId].apr;
      _aprDecimal = poolConfigs[_poolConfigId].aprDecimal; // 1.6
      _isActive = poolConfigs[_poolConfigId].isActive;
  }

function setPoolConfig(
    uint32 _id, 
    uint32 _totalDay, 
    uint256 _limit,
    uint256 _staking,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _apr,
    uint16 _aprDecimal,
    bool _isActive ) public onlyOwner{
      poolConfigs[_id].totalDay=_totalDay;  
      poolConfigs[_id].limit=_limit;
      poolConfigs[_id].staking=_staking;
      poolConfigs[_id].startTime=_startTime;
      poolConfigs[_id].endTime=_endTime;
      poolConfigs[_id].apr=_apr;
      poolConfigs[_id].aprDecimal=_aprDecimal; 
      poolConfigs[_id].isActive=_isActive;
  }


  function getStakingInfo (uint32 _stakingInfoId) public view returns(
      uint32 _id,
      address _sender,
      uint32 _poolConfig,
      uint256 _staked,
      uint256 _createdAt,
      bool _isReceived
    ){
      _id = stakingInfos[_stakingInfoId].id;  
      _sender = stakingInfos[_stakingInfoId].sender;  
      _poolConfig = stakingInfos[_stakingInfoId].poolConfig;
      _staked = stakingInfos[_stakingInfoId].staked;
      _createdAt = stakingInfos[_stakingInfoId].createdAt;
      _isReceived = stakingInfos[_stakingInfoId].isReceived;
  }


  function getStakingInfos(uint32 _poolConfigId) external view returns (StakingInfo[] memory ) {
        uint range=totalStakingInfo.current();
        uint i=1;
        uint index=0;
        uint x=0;
        for(i; i <= range; i++){
          if(stakingInfos[i].sender==msg.sender){
            if(stakingInfos[i].poolConfig==_poolConfigId){
            index++;
            }
          }
        }
        StakingInfo[] memory result = new StakingInfo[](index);
        i=1;
        for(i; i <= range; i++){
          if(stakingInfos[i].sender==msg.sender){
            if(stakingInfos[i].poolConfig == _poolConfigId){
            result[x] = stakingInfos[i];
            x++;
            }
          }
        }
        return result;
  }

   function getAllStakingInfos(uint32 _poolConfigId) external view returns (StakingInfo[] memory ) {
        uint range=totalStakingInfo.current();
        uint i=1;
        uint index=0;
        uint x=0;
        for(i; i <= range; i++){
          if(stakingInfos[i].poolConfig==_poolConfigId){
            index++;
          }
        }
        StakingInfo[] memory result = new StakingInfo[](index);
        i=1;
        for(i; i <= range; i++){
          if(stakingInfos[i].poolConfig == _poolConfigId){
            result[x] = stakingInfos[i];
            x++;
          }
        }
        return result;
  }

  function getPoolConfigs() external view returns (PoolConfig[] memory ) {
        uint32 range= totalPoolConfig;
        PoolConfig[] memory result = new PoolConfig[](range);
        uint32 i=1;
        uint32 index=0;
        for(i; i <= range; i++){
          result[index]= poolConfigs[i];
          index++;
        }
        return result;
  }

  function setStakingInfo(
      uint32 _id, 
      uint256 _staked,
      uint256 _createdAt,
      bool _isReceived ) public onlyOwner{
      stakingInfos[_id].staked=_staked;  
      stakingInfos[_id].createdAt=_createdAt;
      stakingInfos[_id].isReceived=_isReceived;
  }

  function setTotalPoolConfig(uint16 _totalPoolConfig) public onlyOwner{
    totalPoolConfig = _totalPoolConfig;
  } 

  function getTotalPoolConfig() public view returns(uint16){
    return totalPoolConfig;
  } 
  
  function setMinStaking(uint16 _minStaking) public onlyOwner{
    minStaking = _minStaking;
  } 

  function getMinStaking() public view returns(uint256){
    return minStaking;
  }

  function withdraw(uint amount) public onlyOwner {
        require(amount <= bplus.balanceOf(address(this)) );
        bplus.approve(address(this), amount);
        bplus.transferFrom(address(this),msg.sender, amount);
    }
  /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
       _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
       _unpause();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}