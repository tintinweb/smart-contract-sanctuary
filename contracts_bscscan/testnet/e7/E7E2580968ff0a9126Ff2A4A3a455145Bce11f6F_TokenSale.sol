// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./TokenSaleValidation.sol";

contract TokenSale is Initializable, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Emitted event for new investment
  event NewInvestment(address indexed investor, uint256 amount);

  // Emitted event for token sale finalization (fund is transfered to admin wallet)
  event Finalized(address admin, uint256 amount);

  // Emitted event for emergency withdrawal (fund is transfered to admin wallet, token sale is inactivated)
  event EmergencyWithdrawal(address admin, uint256 amount);

  struct TimeFrame {
    uint64 startTime;
    uint64 endTime;
  }

  // Token sale name
  string public name;

  // Admin
  address public admin;

  // Hardcap
  uint256 public hardcap;

  // Whitelist sale time frame
  TimeFrame public whitelistSaleTimeFrame;

  // Public sale time frame
  TimeFrame public publicSaleTimeFrame;

  // Purchase levels. Level indices start from 0, so index 0 will be level 1 and so on
  uint256[] public purchaseLevels;

  // Public sale purchase cap
  uint256 public publicSalePurchaseCap;

  // The token address used to purchase, e.g. USDT, BUSD, etc.
  address public purchaseToken;

  // The token instance used to purchase, e.g. USDT, BUSD, etc.
  IERC20 private purchaseToken_;

  // Status
  enum Status {
    INACTIVE,
    ACTIVE
  }
  Status public status;

  // Total sale amount
  uint256 public totalSaleAmount;

  // Total whitelist sale amount
  uint256 public totalWhitelistSaleAmount;

  // Total public sale amount
  uint256 public totalPublicSaleAmount;

  // Is hardcap reached?
  bool private hardcapReached;

  // Is finalized?
  bool private finalized;

  // Investor
  struct Investor {
    address investor;
    uint256 totalInvestment;
    uint256 whitelistSaleTotalInvestment;
    uint256 publicSaleTotalInvestment;
    uint8 whitelistPurchaseLevel; // Level starts from 1
    bool whitelistSale; // If true, can participate whitelist sale
  }

  // Mapping investor wallet address to investor instance
  mapping(address => Investor) public investors;

  // Investors' wallet address
  address[] public investorAddresses;

  // Next refund index
  uint256 public nextRefundIdx;

  // Refunded addresses
  mapping(address => bool) public refunded;

  // Only admin
  modifier onlyAdmin() {
    require(msg.sender == admin, "TokenSale: not admin");
    _;
  }

  // If token sale's status is ACTIVE
  modifier activeTokenSale() {
    require(status == Status.ACTIVE && !finalized, "TokenSale: inactive");
    _;
  }

  // Has sold out?
  modifier availableForPurchase() {
    require(!hardcapReached, "TokenSale: sold out");
    _;
  }

  // Check if investor is whitelisted
  modifier whitelisted() {
    require(
      investors[msg.sender].investor != address(0),
      "TokenSale: not whitelisted"
    );
    _;
  }

  /// @notice Create a new token sale
  function initialize(
    address _owner,
    string calldata _name,
    address _admin,
    uint256 _hardcap,
    TimeFrame calldata _whitelistSaleTimeFrame,
    TimeFrame calldata _publicSaleTimeFrame,
    uint256[] calldata _purchaseLevels,
    uint256 _publicSalePurchaseCap,
    address _purchaseToken
  ) public initializer {
    require(_admin != address(0), "TokenSale: admin address is zero");

    require(_hardcap > 0, "TokenSale: hardcap is zero");

    require(
      _whitelistSaleTimeFrame.startTime != 0 &&
        _whitelistSaleTimeFrame.endTime != 0 &&
        _whitelistSaleTimeFrame.startTime < _whitelistSaleTimeFrame.endTime,
      "TokenSale: invalid whitelist time frame"
    );

    require(
      _publicSaleTimeFrame.startTime != 0 &&
        _publicSaleTimeFrame.endTime != 0 &&
        _publicSaleTimeFrame.startTime < _publicSaleTimeFrame.endTime,
      "TokenSale: invalid public sale time frame"
    );

    require(_purchaseLevels.length != 0, "TokenSale: empty purchase levels");

    require(_publicSalePurchaseCap > 0, "TokenSale: public sale cap is zero");

    require(
      _purchaseToken != address(0),
      "TokenSale: purchase token address is zero"
    );

    name = _name;
    admin = _admin;
    hardcap = _hardcap;
    whitelistSaleTimeFrame = _whitelistSaleTimeFrame;
    publicSaleTimeFrame = _publicSaleTimeFrame;
    purchaseLevels = _purchaseLevels;
    publicSalePurchaseCap = _publicSalePurchaseCap;
    purchaseToken = _purchaseToken;
    purchaseToken_ = IERC20(purchaseToken);

    status = Status.ACTIVE;
    totalSaleAmount = 0;
    totalWhitelistSaleAmount = 0;
    totalPublicSaleAmount = 0;
    hardcapReached = false;

    _transferOwnership(_owner);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /// @notice Configure token sale
  function configureTokenSale(
    uint256 _hardcap,
    TimeFrame calldata _whitelistSaleTimeFrame,
    TimeFrame calldata _publicSaleTimeFrame,
    uint256[] calldata _purchaseLevels,
    uint256 _publicSalePurchaseCap,
    address _purchaseToken,
    uint256 _status
  ) external onlyOwner {
    require(_hardcap > 0, "TokenSale: hardcap is zero");

    require(
      _whitelistSaleTimeFrame.startTime != 0 &&
        _whitelistSaleTimeFrame.endTime != 0 &&
        _whitelistSaleTimeFrame.startTime < _whitelistSaleTimeFrame.endTime,
      "TokenSale: invalid whitelist time frame"
    );

    require(
      _publicSaleTimeFrame.startTime != 0 &&
        _publicSaleTimeFrame.endTime != 0 &&
        _publicSaleTimeFrame.startTime < _publicSaleTimeFrame.endTime,
      "TokenSale: invalid public sale time frame"
    );

    require(_purchaseLevels.length != 0, "TokenSale: empty purchase levels");

    require(_publicSalePurchaseCap > 0, "TokenSale: public sale cap is zero");

    require(
      _purchaseToken != address(0),
      "TokenSale: purchase token address is zero"
    );

    require(
      _status == uint256(Status.INACTIVE) || _status == uint256(Status.ACTIVE),
      "TokenSale: invalid status"
    );

    hardcap = _hardcap;
    whitelistSaleTimeFrame = _whitelistSaleTimeFrame;
    publicSaleTimeFrame = _publicSaleTimeFrame;
    purchaseLevels = _purchaseLevels;
    publicSalePurchaseCap = _publicSalePurchaseCap;
    purchaseToken = _purchaseToken;
    purchaseToken_ = IERC20(purchaseToken);
    status = Status(_status);
  }

  /// @notice Query token sale data
  function tokenSaleData()
    external
    view
    returns (
      string memory name_,
      address admin_,
      uint256 hardcap_,
      TimeFrame memory whitelistSaleTimeFrame_,
      TimeFrame memory publicSaleTimeFrame_,
      uint256[] memory purchaseLevels_,
      uint256 publicSalePurchaseCap_,
      address purchaseTokenAddress_,
      Status status_,
      uint256 totalSaleAmount_,
      uint256 totalWhitelistSaleAmount_,
      uint256 totalPublicSaleAmount_
    )
  {
    return (
      name,
      admin,
      hardcap,
      whitelistSaleTimeFrame,
      publicSaleTimeFrame,
      purchaseLevels,
      publicSalePurchaseCap,
      purchaseToken,
      status,
      totalSaleAmount,
      totalWhitelistSaleAmount,
      totalPublicSaleAmount
    );
  }

  /// @notice Register (whitelist) investors
  /// @dev New data will override old ones if existed
  function registerInvestors(
    address[] calldata _investors,
    uint8[] calldata _whitelistPurchaseLevels
  ) external onlyOwner {
    require(
      _investors.length == _whitelistPurchaseLevels.length,
      "TokenSale: lengths do not match"
    );

    require(
      TokenSaleValidation.nonZeroAddresses(_investors),
      "TokenSale: investor address is zero"
    );

    require(
      TokenSaleValidation.validWhitelistPurchaseLevels(
        _whitelistPurchaseLevels,
        purchaseLevels.length
      ),
      "TokenSale: invalid whitelist purchase level"
    );

    for (uint256 i; i < _investors.length; ++i) {
      if (investors[_investors[i]].investor == address(0)) {
        investorAddresses.push(_investors[i]);
      }

      if (_whitelistPurchaseLevels[i] > 0) {
        investors[_investors[i]] = Investor(
          _investors[i],
          0,
          0,
          0,
          _whitelistPurchaseLevels[i],
          true
        );
      } else {
        investors[_investors[i]] = Investor(
          _investors[i],
          0,
          0,
          0,
          _whitelistPurchaseLevels[i],
          false
        );
      }
    }
  }

  function investorCount() public view returns (uint256) {
    return investorAddresses.length;
  }

  /// @notice Purchase token in whitelist sale
  function purchaseTokenWhitelistSale(uint256 amount)
    external
    activeTokenSale
    availableForPurchase
    whitelisted
  {
    require(
      block.timestamp >= whitelistSaleTimeFrame.startTime &&
        block.timestamp <= whitelistSaleTimeFrame.endTime,
      "TokenSale: not in whitelist sale time"
    );

    Investor storage investor = investors[msg.sender];
    uint256 purchaseCap = purchaseLevels[investor.whitelistPurchaseLevel - 1];

    require(
      investor.whitelistSale,
      "TokenSale: not eligible to participate in whitelist sale"
    );

    require(
      TokenSaleValidation.validPurchaseAmount(
        purchaseLevels,
        investor.whitelistPurchaseLevel - 1,
        amount
      ),
      "TokenSale: invalid purchase amount"
    );

    require(
      investor.whitelistSaleTotalInvestment < purchaseCap,
      "TokenSale: exceed maximum investment"
    );

    uint256 investmentAmount = amount;

    if (investmentAmount > hardcap.sub(totalSaleAmount)) {
      investmentAmount = hardcap.sub(totalSaleAmount);
    }

    if (
      investmentAmount > purchaseCap.sub(investor.whitelistSaleTotalInvestment)
    ) {
      investmentAmount = purchaseCap.sub(investor.whitelistSaleTotalInvestment);
    }

    totalSaleAmount = totalSaleAmount.add(investmentAmount);
    totalWhitelistSaleAmount = totalWhitelistSaleAmount.add(investmentAmount);
    investor.totalInvestment = investor.totalInvestment.add(investmentAmount);
    investor.whitelistSaleTotalInvestment = investor
      .whitelistSaleTotalInvestment
      .add(investmentAmount);

    if (totalSaleAmount >= hardcap) {
      hardcapReached = true;
    }

    purchaseToken_.safeTransferFrom(
      msg.sender,
      address(this),
      investmentAmount
    );
    emit NewInvestment(investor.investor, investmentAmount);
  }

  /// @notice Purchase token in public sale
  function purchaseTokenPublicSale(uint256 amount)
    external
    activeTokenSale
    availableForPurchase
    whitelisted
  {
    require(
      block.timestamp >= publicSaleTimeFrame.startTime &&
        block.timestamp <= publicSaleTimeFrame.endTime,
      "TokenSale: not in public sale time"
    );

    Investor storage investor = investors[msg.sender];

    require(
      investor.publicSaleTotalInvestment < publicSalePurchaseCap,
      "TokenSale: exceed maximum investment"
    );

    uint256 investmentAmount = amount;

    if (investmentAmount > hardcap.sub(totalSaleAmount)) {
      investmentAmount = hardcap.sub(totalSaleAmount);
    }

    if (
      investmentAmount >
      publicSalePurchaseCap.sub(investor.publicSaleTotalInvestment)
    ) {
      investmentAmount = publicSalePurchaseCap.sub(
        investor.publicSaleTotalInvestment
      );
    }

    totalSaleAmount = totalSaleAmount.add(investmentAmount);
    totalPublicSaleAmount = totalPublicSaleAmount.add(investmentAmount);
    investor.totalInvestment = investor.totalInvestment.add(investmentAmount);
    investor.publicSaleTotalInvestment = investor.publicSaleTotalInvestment.add(
      investmentAmount
    );

    if (totalSaleAmount >= hardcap) {
      hardcapReached = true;
    }

    purchaseToken_.safeTransferFrom(
      msg.sender,
      address(this),
      investmentAmount
    );
    emit NewInvestment(investor.investor, investmentAmount);
  }

  /// @notice Finalize token sale: send all funds to admin's wallet
  function finalize() external onlyOwner {
    require(
      hardcapReached || block.timestamp > publicSaleTimeFrame.endTime,
      "TokenSale: can not finalize"
    );
    require(!finalized, "TokenSale: finalized");

    finalized = true;

    uint256 balance = purchaseToken_.balanceOf(address(this));
    purchaseToken_.safeTransfer(admin, balance);
    emit Finalized(admin, balance);
  }

  /// @notice Emergency withdrawal
  ///   1. Send all funds to admin's wallet
  ///   2. Inactivate token sale
  function emergencyWithdraw() external onlyAdmin {
    status = Status.INACTIVE;

    uint256 balance = purchaseToken_.balanceOf(address(this));
    purchaseToken_.safeTransfer(admin, balance);
    emit EmergencyWithdrawal(admin, balance);
  }

  /// @notice Change investor wallet address
  function changeInvestorWalletAddress(address _oldAddress, address _newAddress)
    external
    onlyAdmin
  {
    require(!finalized, "TokenSale: finalized");

    require(_oldAddress != address(0), "TokenSale: invalid address");

    require(
      investors[_oldAddress].investor != address(0),
      "TokenSale: address is already taken"
    );

    // Change old mapping to have address(0), i.e. not whitelisted
    Investor storage investor = investors[_oldAddress];
    investor.investor = address(0);

    // Clone old investor data to new one & update new wallet address
    investors[_newAddress] = investor;
    investors[_newAddress].investor = _newAddress;

    // Update investor addresses to replace old with new one
    for (uint256 i; i < investorAddresses.length; ++i) {
      if (investorAddresses[i] == _oldAddress) {
        investorAddresses[i] = _newAddress;
        break;
      }
    }
  }

  /// @notice Refund to all investors
  /// @dev think twice 1: can we stuck at a specific index and can not proceed refund for other remaining investors?
  ///         currently this is impossible because we update the index before doing the transfer
  /// @dev think twice 2: if we should keep track of refunded investor by: 1. reset investor.totalInvestment to 0, or 2. store a mapping
  function refundAll() external onlyAdmin {
    if (status != Status.INACTIVE) {
      status = Status.INACTIVE;
    }

    for (uint256 i = nextRefundIdx; i < investorAddresses.length; ++i) {
      nextRefundIdx++;
      if (!refunded[investorAddresses[i]]) {
        refunded[investorAddresses[i]] = true;
        purchaseToken_.safeTransfer(
          investorAddresses[i],
          investors[investorAddresses[i]].totalInvestment
        );
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library TokenSaleValidation {
  function nonZeroAddresses(address[] memory addresses)
    internal
    pure
    returns (bool)
  {
    for (uint256 i; i < addresses.length; ++i) {
      if (addresses[i] == address(0)) {
        return false;
      }
    }
    return true;
  }

  function validWhitelistPurchaseLevels(
    uint8[] memory whitelistPurchaseLevels,
    uint256 maxLevel
  ) internal pure returns (bool) {
    for (uint256 i; i < whitelistPurchaseLevels.length; ++i) {
      if (whitelistPurchaseLevels[i] > maxLevel) {
        return false;
      }
    }
    return true;
  }

  function validPurchaseAmount(
    uint256[] memory purchaseLevels,
    uint8 levelIndex,
    uint256 amount
  ) internal pure returns (bool) {
    for (uint256 i; i <= levelIndex; ++i) {
      if (amount == purchaseLevels[i]) {
        return true;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}