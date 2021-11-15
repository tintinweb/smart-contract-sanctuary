//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ISafuPool.sol";
import "./interfaces/ICreatorPool.sol";
import "./interfaces/IBEP20.sol";

contract Launchpad is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  mapping(uint256 => ProjectConfig) private projects_;
  mapping(uint256 => mapping(address => bool)) private claim_;
  mapping(uint256 => bool) private isClaimable_;
  uint256 private projectCount_;

  address private vault_;
  address private safuPool_;
  address private creatorPool_;

  address public BUSD;

  struct ProjectConfig {
    address token;
    uint256 startTime;
    uint256 endTime;
    uint256 tokenAmount;
    uint256 price;
    address creator;
    uint256 creatorAlloc;
    ProjectStatus status;
    bool isStable;
    bool claimRequired;
  }

  enum ProjectStatus {
    None,
    Register,
    Pending,
    Active,
    Complete,
    Cancel
  }

  event ProjectUpdated(
    uint256 indexed id, 
    uint256 indexed startTime, 
    uint256 indexed endTime, 
    address token, 
    address creator, 
    uint256 tokenAmount, 
    uint256 price, 
    bool stable,
    bool claimRequired
  );
  event TokenBuy(uint256 indexed id, address indexed user, uint256 amount, bool indexed fromCreator);
  event StatusUpdated(uint256 indexed id, ProjectStatus indexed status);
  event VaultUpdated(address indexed vault);
  event CreatorPoolUpdated(address indexed creatorPool);
  event SafuPoolUpdated(address indexed safuPool);
  event ClaimStatusUpdated(uint256 indexed id, bool indexed status);

  function initialize(address _busd) external virtual initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    BUSD = _busd;
  }

  function setBUSD(address _busd) external onlyOwner {
    BUSD = _busd;
  }

  function getVault() external view returns(address) {
    return vault_;
  }

  function getCreatorPool() external view returns(address) {
    return creatorPool_;
  }

  function getSafuPool() external view returns(address) {
    return safuPool_;
  }

  function setVault(address _vault) external onlyOwner {
    vault_ = _vault;
    emit VaultUpdated(_vault);
  }

  function setCreatorPool(address _creatorPool) external onlyOwner {
    creatorPool_ = _creatorPool;
    emit CreatorPoolUpdated(_creatorPool);
  }

  function setSafuPool(address _safuPool) external onlyOwner {
    safuPool_ = _safuPool;
    emit SafuPoolUpdated(_safuPool);
  }

  /**
  * @dev Function to register/update a project for IDO, only available for the owner to call
  * @param _id unique project id to update a project, 0 when a project is created
  * @param _token address of token applied for IDO
  * @param _creator address of creator applied for IDO, where locked LP will be transferred to
  * @param _tokenAmount amount of token used for IDO
  * @param _price swap ratio for token, multiplied 10**9
  *   For exmple;
  *     In case BNB:X => 1:3, _price is 3,000,000,000
  *     In case BNB:X => 10:1, _price is 100,000,000
  * @param _creatorAlloc allocation in percentage for creator pool, normally 100 (10%)
  * @param _startTime starting time of IDO
  * @param _endTime ending time of IDO 
  * @param _isStable indicates whether the project fundraising is stable or not - BNB or BUSD
  * @param _claimRequired indicates whether the project requires claim at the end of IDO or transfer tokens when user buys.
  * @return id - Unique number indicating the newly registered IDO project
   */
  function register(
    uint256 _id,
    address _token,
    address _creator,
    uint256 _tokenAmount,
    uint256 _price,
    uint256 _creatorAlloc,
    uint256 _startTime,
    uint256 _endTime,
    bool _isStable,
    bool _claimRequired
  ) external onlyOwner returns(uint256) {
    if (_id == 0) {
      /// Make sure that there is enough amount of token in Vault for this IDO
      require(IVault(vault_).getAssetAmount(_token, _creator) == _tokenAmount, "Insufficient supplied cap");
      _id = ++projectCount_;
    } else {
      require(projects_[_id].status == ProjectStatus.Register, "Invalid project id");      
    }

    require(_creatorAlloc < 1000, "Creator Alloc should be between 0 - 1000");
    require(_token != address(0), "Wrong token address");
    require(_startTime > block.timestamp, "Wrong startTime");
    require(_endTime > _startTime, "Wrong endTime");
    require(_endTime < 10000000000, "Unix timestamp in seconds required");
    
    projects_[_id].token = _token;
    projects_[_id].creator = _creator;
    projects_[_id].tokenAmount = _tokenAmount;
    projects_[_id].price = _price;
    projects_[_id].creatorAlloc = _creatorAlloc;
    projects_[_id].startTime = _startTime;
    projects_[_id].endTime = _endTime;
    projects_[_id].status = ProjectStatus.Register;
    projects_[_id].isStable = _isStable;
    projects_[_id].claimRequired = _claimRequired;

    uint256 creatorPoolCap = _tokenAmount * _creatorAlloc / 1000;
    uint256 safuPoolCap = _tokenAmount - creatorPoolCap;
    ICreatorPool(creatorPool_).registerPool(_id, _token, _creator, creatorPoolCap);
    ISafuPool(safuPool_).registerPool(_id, _token, safuPoolCap);
    
    emit ProjectUpdated(_id, _startTime, _endTime, _token, _creator, _tokenAmount, _price, _isStable, _claimRequired);
    emit StatusUpdated(_id, ProjectStatus.Register);
    return _id;
  }

  function setCreatorPoolConfig(
    uint256 _id,
    uint256 _maxCapPerUser,
    bool _whitelistRequired
  ) external onlyOwner {
    /// Make sure that IDO is registered and not started yet
    require(projects_[_id].status == ProjectStatus.Register, "Not able to configure");

    ICreatorPool(creatorPool_).setConfig(_id, _maxCapPerUser, _whitelistRequired);
  }

  function setSafuPoolConfig(
    uint256 _id,
    uint256[] memory _maxCapPerUsers,
    uint256[] memory _safuRequires,
    uint256[] memory _totalCapLimits
  ) external onlyOwner {
    /// Make sure that IDO is registered and not started yet
    require(projects_[_id].status == ProjectStatus.Register, "Not able to configure");
    require(
      _maxCapPerUsers.length == _safuRequires.length && 
      _maxCapPerUsers.length == _totalCapLimits.length, "Wrong match");
    require(_maxCapPerUsers.length < 10, "Max length overflow");

    ISafuPool(safuPool_).setConfig(_id, _maxCapPerUsers, _safuRequires, _totalCapLimits);
  }

  function getProjectById(uint256 _id) external view returns(ProjectConfig memory) {
    require(projects_[_id].status != ProjectStatus.None, "Invalid project ID");
    return projects_[_id];
  }

  /**
  * @dev Function to purchase tokens with BNB
  * @param _id unique project id
  * @param _withCreatorPool indicates whether a user purchases token in CreatorPool; 
  true - wants to purchase from creator pool
  false - wants to purchase from safu pool
   */
  function buy(uint256 _id, bool _withCreatorPool) external nonReentrant payable returns(bool) {
    require(
      projects_[_id].status == ProjectStatus.Pending || 
      projects_[_id].status == ProjectStatus.Active, "Invalid project id");
    /// Make sure that correct purchase mode is being used
    require(!projects_[_id].isStable, "Wrong backed token");
    require(msg.value > 0, "Value must be greater than zero");

    if (!_isPurchaseAvailable(_id)) {
      _updateProjectStatus(_id, false);
      (bool backpay,) = msg.sender.call{value: msg.value}("");
      require(backpay, "Payback failed");
      return false;
    }

    uint256 payLimitToken;
    uint256 payLimit;

    /// TODO: check appropriate pool
    if (_withCreatorPool) {
      payLimitToken = ICreatorPool(creatorPool_).getAvailablePurchase(_id, msg.sender);
      payLimit = _getPaidAmountByTokens(_id, payLimitToken);
      if (payLimit < msg.value) {
        (bool backpay,) = msg.sender.call{value: msg.value - payLimit}("");
        require(backpay, "Payback failed");
      } else {
        payLimit = msg.value;
        payLimitToken = _getTokensByPaidTokens(_id, payLimit);
      }
      (bool receivepay,) = payable(vault_).call{value: payLimit}("");
      require(receivepay, "Receive failed");
      ICreatorPool(creatorPool_).buy(_id, msg.sender, payLimitToken);
      emit TokenBuy(_id, msg.sender, payLimitToken, true);
    } else {
      uint256 tierInd;
      (payLimitToken, tierInd) = ISafuPool(safuPool_).getAvailablePurchase(_id, msg.sender);
      payLimit = _getPaidAmountByTokens(_id, payLimitToken);
      if (payLimit < msg.value) {
        (bool backpay,) = msg.sender.call{value: msg.value - payLimit}("");
        require(backpay, "Payback failed");
      } else {
        payLimit = msg.value;
        payLimitToken = _getTokensByPaidTokens(_id, payLimit);
      }
      (bool receivepay,) = payable(vault_).call{value: payLimit}("");
      require(receivepay, "Receive failed");
      ISafuPool(safuPool_).buy(_id, msg.sender, payLimitToken, tierInd);
      emit TokenBuy(_id, msg.sender, payLimitToken, false);
    }

    if (!projects_[_id].claimRequired) {
      require(IVault(vault_).claimAsset(projects_[_id].token, projects_[_id].creator, msg.sender, payLimitToken), "Claim failed");
    }

    _updateProjectStatus(_id, true);
    return true;
  }

  /**
  * @dev Function to purchase tokens with BUSD
  * @param _id unique project id
  * @param _amount amount to be used for token purchase
  * @param _withCreatorPool indicates whether a user purchases token in CreatorPool
   */
  function buyStable(uint256 _id, uint256 _amount, bool _withCreatorPool) external nonReentrant returns(bool) {
    require(
      projects_[_id].status == ProjectStatus.Pending || 
      projects_[_id].status == ProjectStatus.Active, "Invalid project id");
    /// Make sure that correct purchase mode is being used
    require(projects_[_id].isStable, "Wrong backed token");
    require(_amount > 0, "Value must be greater than zero");

    if (!_isPurchaseAvailable(_id)) {
      _updateProjectStatus(_id, false);
      return false;
    }

    uint256 payLimitToken;
    uint256 payLimit;

    /// TODO: check appropriate pool
    if (_withCreatorPool) {
      payLimitToken = ICreatorPool(creatorPool_).getAvailablePurchase(_id, msg.sender);
      payLimit = _getPaidAmountByTokens(_id, payLimitToken);
      if (payLimit < _amount) {
        _amount = payLimit;
      } else {
        payLimitToken = _getTokensByPaidTokens(_id, _amount);
      }
      require(IBEP20(BUSD).transferFrom(msg.sender, vault_, _amount), "Receive failed");
      ICreatorPool(creatorPool_).buy(_id, msg.sender, payLimitToken);
      emit TokenBuy(_id, msg.sender, payLimitToken, true);
    } else {
      uint256 tierInd;
      (payLimitToken, tierInd) = ISafuPool(safuPool_).getAvailablePurchase(_id, msg.sender);
      payLimit = _getPaidAmountByTokens(_id, payLimitToken);
      if (payLimit < _amount) {
        _amount = payLimit;
      } else {
        payLimitToken = _getTokensByPaidTokens(_id, _amount);
      }
      require(IBEP20(BUSD).transferFrom(msg.sender, vault_, _amount), "Receive failed");
      ISafuPool(safuPool_).buy(_id, msg.sender, payLimitToken, tierInd);
      emit TokenBuy(_id, msg.sender, payLimitToken, false);
    }

    if (!projects_[_id].claimRequired) {
      require(IVault(vault_).claimAsset(projects_[_id].token, projects_[_id].creator, msg.sender, payLimitToken), "Claim failed");
    }

    _updateProjectStatus(_id, true);
    return true;
  }

  function getPaidAmountByTokens(uint256 _id, uint256 _tokenAmount) external view returns(uint256) {
    require(projects_[_id].token != address(0), "Invalid project id");

    return _getPaidAmountByTokens(_id, _tokenAmount);
  }

  function _getPaidAmountByTokens(uint256 _id, uint256 _tokenAmount) internal view returns(uint256 _paidAmount) {
    _paidAmount = _tokenAmount * 1e18 / (10 ** IBEP20(projects_[_id].token).decimals());
    _paidAmount = _paidAmount * 1e9 / projects_[_id].price;
  }

  function getTokensByPaidTokens(uint256 _id, uint256 _paidAmount) external view returns(uint256) {
    require(projects_[_id].token != address(0), "Invalid project id");

    return _getTokensByPaidTokens(_id, _paidAmount);
  }

  function _getTokensByPaidTokens(uint256 _id, uint256 _paidAmount) internal view returns(uint256 _tokenAmount) {
    _tokenAmount = _paidAmount * (10**IBEP20(projects_[_id].token).decimals()) / 1e18;
    _tokenAmount = _tokenAmount * projects_[_id].price / 1e9;
  }

  /**
  * @dev Function to get total number of registered projects
   */
  function getProjectsCount() external view returns(uint256) {
    return projectCount_;
  }

  function _isPurchaseAvailable(uint256 _id) internal view returns(bool) {
    if (
      projects_[_id].startTime <= block.timestamp && 
      projects_[_id].endTime >= block.timestamp
    ) {
      return true;
    }
    return false;
  }

  function _updateProjectStatus(uint256 _id, bool _purchaseAvailable) internal {
    if (_purchaseAvailable) {
      uint256 remainToken = IVault(vault_).getAssetAmount(projects_[_id].token, projects_[_id].creator);

      if (remainToken == 0) {
        projects_[_id].status = ProjectStatus.Complete;
        emit StatusUpdated(_id, ProjectStatus.Complete);
      } else if (projects_[_id].status == ProjectStatus.Pending) {
        projects_[_id].status = ProjectStatus.Active;
        emit StatusUpdated(_id, ProjectStatus.Active);
      }
    } else {
      projects_[_id].status = ProjectStatus.Complete;
      emit StatusUpdated(_id, ProjectStatus.Complete);
    }
  }

  function updateProjectStatus(uint256 _id, ProjectStatus _status) external onlyOwner {
    require(projects_[_id].status != ProjectStatus.None, "Invalid project id");

    projects_[_id].status = _status;
    emit StatusUpdated(_id, _status);
  }

  function setProjectClaimable(uint256 _id, bool _claimable) external onlyOwner {
    require(projects_[_id].status == ProjectStatus.Complete, "Project not completed");

    isClaimable_[_id] = _claimable;
    emit ClaimStatusUpdated(_id, _claimable);
  }

  function claim(uint256 _id) external returns(bool) {
    if (
      projects_[_id].status == ProjectStatus.Active && 
      projects_[_id].endTime <= block.timestamp
    ) {
      projects_[_id].status = ProjectStatus.Complete;
      emit StatusUpdated(_id, ProjectStatus.Complete);
    }

    if (
      projects_[_id].status == ProjectStatus.Complete &&
      !claim_[_id][msg.sender] &&
      projects_[_id].claimRequired && 
      isClaimable_[_id]
    ) {
      uint256 total = ISafuPool(safuPool_).getUserPurchase(_id, msg.sender);
      total += ICreatorPool(creatorPool_).getUserPurchase(_id, msg.sender);
      require(IVault(vault_).claimAsset(projects_[_id].token, projects_[_id].creator, msg.sender, total), "Claim failed");

      return true;
    }
    return false;
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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
  function getAssetAmount(address _token, address _creator) external view returns(uint256);
  function claimAsset(address _token, address _creator, address _to, uint256 _amount) external returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafuPool {
  function registerPool(uint256 _id, address _token, uint256 _tokenAmount) external;
  function setConfig(
    uint256 _id, 
    uint256[] memory _maxCapPerUsers,
    uint256[] memory _safuRequires,
    uint256[] memory _totalCapLimits) external;
  function getAvailablePurchase(uint256 _id, address _user) external view returns(uint256, uint256);
  function getUserPurchase(uint256 _id, address _user) external view returns(uint256);
  function buy(uint256 _id, address _user, uint256 _amount, uint256 _tierIndex) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICreatorPool {
  function registerPool(uint256 _id, address _token, address _creator, uint256 _tokenAmount) external;
  function setConfig(uint256 _id, uint256 _maxCapPerUser, bool _whitelistRequired) external;
  function getAvailablePurchase(uint256 _id, address _user) external view returns(uint256);
  function getUserPurchase(uint256 _id, address _user) external view returns(uint256);
  function buy(uint256 _id, address _user, uint256 _amount) external;
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

