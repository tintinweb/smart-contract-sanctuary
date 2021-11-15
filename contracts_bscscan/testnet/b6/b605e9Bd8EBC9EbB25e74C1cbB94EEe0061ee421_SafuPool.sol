//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBEP20.sol";

contract SafuPool is Initializable, OwnableUpgradeable {
  address private register_;
  mapping(uint256 => mapping(address => uint256)) private leaders_;
  mapping(uint256 => SafuConfig) private projects_;
  mapping(uint256 => mapping(uint256 => Tier)) private tiers_;

  address private constant SAFU = 0x36DB129506fE81dA7Ce085648ff9C7a0D5e31ed2;

  event RegisterUpdated(address indexed register);
  event PoolUpdated(uint256 indexed id, address indexed token, uint256 tokenAmount);
  event ConfigUpdated(uint256 indexed id);
  event Purchase(uint256 indexed id, address indexed user, uint256 amount);

  modifier onlyRegister {
    require(
      msg.sender == register_, 
      "Only available for register"
    );
    _;
  }

  struct SafuConfig {
    address token;
    uint256 tokenAmount;
    uint256 totalPurchase;
    uint256 totalUser;
    uint256 totalTiers;
  }

  struct Tier {
    uint256 maxCapPerUser;
    uint256 safuRequire;
    uint256 totalCapLimit;
  }

  function initialize() external virtual initializer {
    __Ownable_init();
  }

  function getRegister() external view returns(address) {
    return register_;
  }

  function setRegister(address _register) external onlyOwner {
    register_ = _register;
    emit RegisterUpdated(_register);
  }

  /**
  * @dev Function to register a new SafuPool
  * @param _id unique project id linked to this SafuPool
  * @param _token address of token applied for IDO
  * @param _tokenAmount maximum amount of token allocated to SafuPool
   */
  function registerPool(
    uint256 _id, 
    address _token, 
    uint256 _tokenAmount
  ) external onlyRegister {
    projects_[_id].token = _token;
    projects_[_id].tokenAmount = _tokenAmount;

    emit PoolUpdated(_id, _token, _tokenAmount);
  }

  /**
  * @dev Function to set pool configuration, only available for the register to call
  * @param _id unique project id
  * @param _maxCapPerUsers max amount of tokens that a user can purchase for each tier
  * @param _safuRequires amount of safu tokens that a user needs to hold for him to be a specific tier holder
  * @param _totalCapLimits max amount of tokens that a group of people with specific tier can purchase totally
   */
  function setConfig(
    uint256 _id,
    uint256[] memory _maxCapPerUsers,
    uint256[] memory _safuRequires,
    uint256[] memory _totalCapLimits
  ) external onlyRegister {
    require(projects_[_id].token != address(0), "Invalid project id");

    uint256 safuRequire = 0;
    for (uint256 i = 0; i < _maxCapPerUsers.length; i ++) {
      if (_safuRequires[i] < safuRequire) revert("Need sort by safuRequire");
      safuRequire = _safuRequires[i];
      tiers_[_id][i] = Tier(_maxCapPerUsers[i], _safuRequires[i], _totalCapLimits[i]);
    }
    projects_[_id].totalTiers = _maxCapPerUsers.length;

    emit ConfigUpdated(_id);
  }

  /**
  * @dev Function to get pool configuration
  * @param _id unique project id
  * @return SafuConfig - configuration info of the selected id of SafuPool
   */
  function getConfig(uint256 _id) external view returns(SafuConfig memory) {
    require(projects_[_id].token != address(0), "Invalid project id");
    
    return projects_[_id];
  }

  function getTier(uint256 _id, uint256 _index) external view returns(Tier memory) {
    require(projects_[_id].token != address(0), "Invalid project id");
    require(_index < projects_[_id].totalTiers, "Invalid tier id");

    return tiers_[_id][_index];
  }

  /**
  * @dev Function to validate a user's purchase, only available for the register to call
  * @param _id unique project id
  * @param _user address of the user
  * @return available - remaining amount of token that the user can purchase
            tierIndex - index of tier that the user has
   */
  function getAvailablePurchase(
    uint256 _id, 
    address _user
  ) external view returns(uint256, uint256) {
    /// Make sure that the pool is registered
    require(projects_[_id].token != address(0), "Invalid project id");

    uint256 remainTotal = 0;
    if(projects_[_id].totalPurchase < projects_[_id].tokenAmount) {
      remainTotal = projects_[_id].tokenAmount - projects_[_id].totalPurchase;
    }
    
    uint256 remainUser = 0;
    uint256 tierInd = getTierType(_id, _user);
    if (leaders_[_id][_user] < tiers_[_id][tierInd].maxCapPerUser) {
      remainUser = tiers_[_id][tierInd].maxCapPerUser - leaders_[_id][_user];
    }

    if (remainUser > tiers_[_id][tierInd].totalCapLimit) {
      remainUser = tiers_[_id][tierInd].totalCapLimit;
    }

    if (remainUser > remainTotal) return (remainTotal, tierInd);
    else return (remainUser, tierInd);
  }

  function getTierType(uint256 _id, address _user) public view returns(uint256 tierIndex) {
    /// Make sure that the pool is registered
    require(projects_[_id].token != address(0), "Invalid project id");
    uint256 safuBalance = IBEP20(SAFU).balanceOf(_user);
    for(uint256 i = 0; i < projects_[_id].totalTiers; i ++) {
      if (tiers_[_id][i].safuRequire <= safuBalance) {
        tierIndex = i;
      } else {
        break;
      }
    }
  }

  /**
  * @dev Function to buy token
  * @param _id unique project id
  * @param _user address of the user
  * @param _amount amount of tokens that user buys
  * @param _tierIndex index of tier that the user purchases with
   */
  function buy(
    uint256 _id, 
    address _user, 
    uint256 _amount,
    uint256 _tierIndex
  ) external onlyRegister {
    require(projects_[_id].token != address(0), "Invalid project id");
    require(_tierIndex < projects_[_id].totalTiers, "Invalid tier index");

    if (leaders_[_id][_user] == 0) {
      projects_[_id].totalUser += 1;
    }

    projects_[_id].totalPurchase = projects_[_id].totalPurchase + _amount;
    leaders_[_id][_user] = leaders_[_id][_user] + _amount;
    tiers_[_id][_tierIndex].totalCapLimit -= _amount;
    emit Purchase(_id, _user, _amount);
  }

  /**
  * @dev Function to view a user's purchased amount
  * @param _id unique project id
  * @param _user address of the user
  * @return amount - total amount of tokens
   */
  function getUserPurchase(
    uint256 _id, 
    address _user
  ) external view returns(uint256) {
    require(projects_[_id].token != address(0), "Invalid project id");

    return leaders_[_id][_user];
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
import "../proxy/utils/Initializable.sol";

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

