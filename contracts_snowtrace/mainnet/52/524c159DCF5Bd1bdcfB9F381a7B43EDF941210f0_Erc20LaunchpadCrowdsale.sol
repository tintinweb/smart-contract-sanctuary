// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./CrowdsaleStorage.sol";

/**
 * @title Erc20LaunchpadCrowdsale
 * @dev Erc20LaunchpadCrowdsale is a contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ERC20.
 */
contract Erc20LaunchpadCrowdsale is AccessControl {
  using SafeERC20 for IERC20;

  struct Collateral {
    bool defined;
    uint256 raised;
  }

  uint256 public constant TOKEN_DECIMALS = 18;
  uint256 public constant PRECISION = 10 ** 6;
  
  // Collateral tokens used as a payment
  mapping(address => Collateral) private _collaterals;

  // Address where funds are collected
  address private _wallet;

  // Crowdsale storage
  CrowdsaleStorage private _crowdsaleStorage;

  // Crowdsale storage
  bool private _paused;

  /**
   * Event for token purchase logging.
   * @param purchaser  who paid for the tokens.
   * @param investment  collateral tokens paid for the purchase.
   * @param tokensSold  amount of tokens purchased.
   * @param round  round of the purchase
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed collateral,
    uint256 investment,
    uint256 tokensSold,
    uint256 round
  );

  /**
   * Event for pause state update.
   * @param paused  new paused value.
   */
  event PausedUpdated(bool paused);

  /**
   * @param crowdsaleStorage_  address where crowdsale state is being store.
   * @param wallet_  address where collected funds will be forwarded to.
   * @param collaterals_  addresses of the collateral tokens.
   */
  constructor(address crowdsaleStorage_, address wallet_, address[] memory collaterals_) {
    require(crowdsaleStorage_ != address(0), "Erc20LaunchpadCrowdsale: crowdsale storage address is zero");
    require(wallet_ != address(0), "Erc20LaunchpadCrowdsale: wallet address is zero");

    for(uint256 i = 0; i < collaterals_.length; i++) {
      require(collaterals_[i] != address(0), "Erc20LaunchpadCrowdsale: collateral token address is zero");
      _collaterals[collaterals_[i]] = Collateral({
        defined: true,
        raised: 0
      });
    }
    _wallet = wallet_;
    _crowdsaleStorage = CrowdsaleStorage(crowdsaleStorage_);

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @return True if token is collateral.
   * @param collateral_  addresses of the collateral token.
   */
  function isCollateral(address collateral_)
    external
    view
    returns (bool)
  {
    return _collaterals[collateral_].defined;
  }

  /**
   * @return Address where funds are collected.
   */
  function getWallet()
    external
    view
    returns (address)
  {
    return _wallet;
  }

  /**
   * @return Address of the crowdsale storage.
   */
  function getCrowdsaleStorage()
    external
    view
    returns (address)
  {
    return address(_crowdsaleStorage);
  }

  /**
   * @return Paused state.
   */
  function isPaused()
    external
    view
    returns (bool)
  {
    return _paused;
  }
  
  /**
   * @return Amount of collateral tokens raised.
   * @param collateral_  addresses of the collateral token.
   */
  function getCollateralRaised(address collateral_)
    external
    view
    returns (uint256)
  {
    return _collaterals[collateral_].raised;
  }

  /**
   * @dev Method allows to purchase the tokens
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   */
  function buyTokens(address collateral_, uint256 investment_)
    external
  {
    address beneficiary = _msgSender();
    _preValidatePurchase(beneficiary, collateral_, investment_);
    _processPurchase(beneficiary, collateral_, investment_);
    // calculates token amount to be sold
    uint256 tokensSold = _getTokenAmount(collateral_, investment_);
    _updatePurchasingState(beneficiary, collateral_, investment_, tokensSold);
    _postPurchase(beneficiary, collateral_, investment_, tokensSold);
  }

  /**
   * @dev Validation of the incoming purchase.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   */
  function _preValidatePurchase(address beneficiary_, address collateral_, uint256 investment_)
    internal
    view
  {
    require(!_paused, "Erc20LaunchpadCrowdsale::_preValidatePurchase: sale is paused");

    require(beneficiary_ != address(0), "Erc20LaunchpadCrowdsale::_preValidatePurchase: beneficiary address is zero");
    require(investment_ != 0, "Erc20LaunchpadCrowdsale::_preValidatePurchase: investment amount is 0");

    // validates if collateral supported
    require(_collaterals[collateral_].defined, "Erc20LaunchpadCrowdsale::_preValidatePurchase: collateral token not defined");
    
    // validates if sale and round is open
    require(_crowdsaleStorage.isOpened(), "Erc20LaunchpadCrowdsale::_preValidatePurchase: sales is not open yet");
    uint256 activeRound = _crowdsaleStorage.getActiveRound();
    CrowdsaleStorage.Round memory round = _crowdsaleStorage.getRound(activeRound);
    require(round.state == CrowdsaleStorage.State.Opened, "Erc20LaunchpadCrowdsale::_preValidatePurchase: sales round is not open yet");
    require(round.totalSupply >= round.tokensSold + _getTokenAmount(collateral_, investment_), "Erc20LaunchpadCrowdsale::_preValidatePurchase: exceeded round total supply");

    // validates investment amount
    uint256 decimals = IERC20Metadata(collateral_).decimals();
    uint256 normalizedAmount = (investment_ * PRECISION) / (10 ** decimals);
    require(_crowdsaleStorage.getMinInvestment() <= normalizedAmount, "Erc20LaunchpadCrowdsale::_preValidatePurchase: investment amount too low");
    require(_crowdsaleStorage.capOf(beneficiary_) >= normalizedAmount, "Erc20LaunchpadCrowdsale::_preValidatePurchase: exceeded cap");
    
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
   * tokens.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   */
  function _processPurchase(address beneficiary_, address collateral_, uint256 investment_)
    internal
  {
    // transfer collateral tokens to crowdsale
    IERC20(collateral_).safeTransferFrom(beneficiary_, address(this), investment_);
    // transfer collateral tokens to the wallet
    IERC20(collateral_).safeTransfer(_wallet, investment_);
  }

  /**
   * @dev Executed in order to update state of the purchase within crowdsale.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param tokensSold_  amount of purchased tokens.
   */
  function _updatePurchasingState(address beneficiary_, address collateral_, uint256 investment_, uint256 tokensSold_)
    internal
  {
    _collaterals[collateral_].raised = _collaterals[collateral_].raised + investment_;
    uint256 decimals = IERC20Metadata(collateral_).decimals();
    uint256 normalizedInvestment = (investment_ * PRECISION) / (10 ** decimals);
    _crowdsaleStorage.setPurchaseState(beneficiary_, normalizedInvestment, tokensSold_);
  }

  /**
   * @dev Executed for the post purchase processing
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param tokensSold_  amount of purchased tokens.
   */
  function _postPurchase(address beneficiary_, address collateral_, uint256 investment_, uint256 tokensSold_)
    internal
  {
    emit TokensPurchased(beneficiary_, collateral_, investment_, tokensSold_, _crowdsaleStorage.getActiveRound());
  }

  /**
   * @return Number of tokens that can be purchased with specified collateral investment.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   */
  function _getTokenAmount(address collateral_, uint256 investment_)
    internal
    view
    returns (uint256)
  {
    uint8 collateralDecimals = IERC20Metadata(collateral_).decimals();
    if(TOKEN_DECIMALS >= collateralDecimals) {
      return (investment_ * PRECISION * (10 ** (TOKEN_DECIMALS - collateralDecimals))) / _crowdsaleStorage.getPrice();
    }
    return (investment_ * PRECISION) / (10 ** (collateralDecimals - TOKEN_DECIMALS)) / _crowdsaleStorage.getPrice();
  }

  /**
   * @dev Sets sale pause state.
   * @param paused_  paused new value.
   */
  function setPaused(bool paused_)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _paused = paused_;

    emit PausedUpdated(paused_);
  }

  /**
   * @dev Allows to recover ERC20 from contract.
   * @param token_  ERC20 token address.
   * @param amount_  ERC20 token amount.
   */
  function recoverERC20(address token_, uint256 amount_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    IERC20(token_).safeTransfer(_wallet, amount_);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CrowdsaleStorage
 * @dev CrowdsaleStorage is a shared contract that stores crowdsale state,
 * allowing to manage rounds and KYC levels.
 */
contract CrowdsaleStorage is AccessControl {
  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

  enum State { None, Opened, Closed }

  struct Round {
    bool defined;
    State state;
    uint256 price;
    uint256 tokensSold;
    uint256 totalSupply;
  }

  enum KycLevel { Low, Medium, High }

  State private _state;
  Round[] private _rounds;
  uint256 private _activeRound;
  uint256 private _totalTokensSold;

  uint256 private _minInvestment;
  mapping(KycLevel => uint256) private _cap;
  mapping(address => uint256) private _investments;
  mapping(address => KycLevel) private _kyc;
  mapping(address => mapping(uint256 => uint256)) private _balances;

  event SaleStateUpdated(State state);
  event RoundOpened(uint256 indexed index);
  event RoundClosed(uint256 indexed index);
  event RoundAdded(uint256 price, uint256 totalSupply);
  event RoundUpdated(uint256 indexed index, uint256 price, uint256 totalSupply);
  event KycLevelUpdated(address indexed beneficiary, KycLevel levels);
  event MinInvestmentUpdated(uint256 minInvestment);
  event CapUpdated(KycLevel indexed level, uint256 cap);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @return Total tokens sold.
   */
  function getTotalTokensSold()
    external
    view
    returns (uint256)
  {
    return _totalTokensSold;
  }

  /**
   * @return Active round index.
   */
  function getActiveRound()
    external
    view
    returns (uint256)
  {
    return _activeRound;
  }

  /**
   * @return Round parameters by index.
   * @param index_  round index.
   */
  function getRound(uint256 index_)
    external
    view 
    returns (Round memory) 
  {
    return _rounds[index_];
  }

  /**
   * @return True if the crowdsale is opened.
   */
  function isOpened()
    public
    view
    returns (bool)
  {
    return _state == State.Opened;
  }

  /**
   * @return True if the crowdsale is closed.
   */
  function isClosed()
    public
    view
    returns (bool)
  {
    return _state == State.Closed;
  }

  /**
   * @dev Opens the crowdsale.
   */
  function openSale()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_state == State.None, "CrowdsaleStorage::openSale: sales is already open or closed");

    _state = State.Opened;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Closes the crowdsale.
   */
  function closeSale()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(isOpened(), "CrowdsaleStorage::closeSale: sales is already closed or not open");

    _state = State.Closed;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Adds new round.
   * @param price_  price per token unit.
   * @param totalSupply_  max amount of tokens available in the round.
   */
  function addRound(uint256 price_, uint256 totalSupply_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!isClosed(), "CrowdsaleStorage::addRound: sales is already closed");

    _rounds.push(
      Round({
        defined: true,
        state: State.None,
        price: price_,
        tokensSold: 0,
        totalSupply: totalSupply_
      })
    );

    emit RoundAdded(price_, totalSupply_);
  }

  /**
   * @dev Updates round parameters.
   * @param index_  round index.
   * @param price_  price per token unit.
   * @param totalSupply_  max amount of tokens available in the round.
   */
  function updateRound(uint256 index_, uint256 price_, uint256 totalSupply_) 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_rounds[index_].defined, "CrowdsaleStorage::updateRound: no round with provided index");
    require(_rounds[index_].state != State.Closed, "CrowdsaleStorage::updateRound: round is already closed");
    require(!isClosed(), "CrowdsaleStorage::updateRound: sales is already closed");

    _rounds[index_].price = price_;
    _rounds[index_].totalSupply = totalSupply_;

    emit RoundUpdated(index_, price_, totalSupply_);
  }

  /**
   * @dev Opens round for investment.
   * @param index_  round index.
   */
  function openRound(uint256 index_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(isOpened(), "CrowdsaleStorage::openRound: sales is not open yet");
    require(_rounds[index_].defined, "CrowdsaleStorage::openRound: no round with provided index");
    require(_rounds[index_].state == State.None, "CrowdsaleStorage::openRound: round is already open or closed");

    if (_rounds[_activeRound].state == State.Opened) {
      _rounds[_activeRound].state = State.Closed;
    }
    _rounds[index_].state = State.Opened;
    _activeRound = index_;

    emit RoundOpened(index_);
  }

  /**
   * @dev Closes round for investment.
   * @param index_  round index.
   */
  function closeRound(uint256 index_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_rounds[index_].defined, "CrowdsaleStorage::closeRound: no round with provided index");
    require(_rounds[index_].state == State.Opened, "CrowdsaleStorage::closeRound: round is not open");

    _rounds[index_].state = State.Closed;

    emit RoundClosed(index_);
  }

  /**
   * @return Price of the token in the active round.
   */
  function getPrice()
    public
    view
    returns (uint256)
  {
    if (_rounds[_activeRound].state == State.Opened) {
      return _rounds[_activeRound].price;
    }
    return 0;
  }

  /**
   * @return Balance of purchased tokens by beneficiary.
   * @param round_  round of sale.
   * @param beneficiary_  address performing the token purchase.
   */
  function balanceOf(uint256 round_, address beneficiary_)
    external
    view
    returns (uint256)
  {
    return _balances[beneficiary_][round_];
  }

  /**
   * @return Beneficiary KYC level.
   * @param beneficiary_  address performing the token purchase.
   */
  function kycLevelOf(address beneficiary_)
    public
    view
    returns (KycLevel)
  {
    return _kyc[beneficiary_];
  }

  /**
   * @dev Sets beneficiary KYC level.
   * @param beneficiary_  address performing the token purchase.
   * @param level_  KYC level.
   */
  function setKyc(address beneficiary_, KycLevel level_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _kyc[beneficiary_] = level_;

    emit KycLevelUpdated(beneficiary_, level_);
  }

  /**
   * @dev Sets KYC levels to the beneficiaries in batches.
   * @param beneficiaries_  beneficiaries array to set the level for.
   * @param levels_  KYC levels.
   */
  function setKycBatches(address[] calldata beneficiaries_, KycLevel[] calldata levels_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(beneficiaries_.length == levels_.length, "CrowdsaleStorage::setKycBatches: mismatch in beneficiaries and levels length");

    uint256 length = beneficiaries_.length;
    for (uint256 index = 0; index < length; index++) {
      _kyc[beneficiaries_[index]] = levels_[index];

      emit KycLevelUpdated(beneficiaries_[index], levels_[index]);
    }
  }

  /**
   * @return Min investment amount.
   */
  function getMinInvestment()
    external
    view
    returns (uint256)
  {
    return _minInvestment;
  }

  /**
   * @dev Sets min investment amount.
   * @param minInvestment_  min investment amount.
   */
  function setMinInvestment(uint256 minInvestment_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _minInvestment = minInvestment_;

    emit MinInvestmentUpdated(_minInvestment);
  }

  /**
   * @return Cap according to KYC level.
   * @param beneficiary_  address performing the token purchase.
   */
  function capOf(address beneficiary_)
    external
    view
    returns (uint256)
  {
    uint256 investments = _investments[beneficiary_];
    if(investments > _cap[kycLevelOf(beneficiary_)]) {
      return 0;
    }
    return _cap[kycLevelOf(beneficiary_)] - investments;
  }

  /**
   * @return KYC level cap.
   * @param level_  KYC level.
   */
  function getCap(KycLevel level_)
    external
    view
    returns (uint256)
  {
    return _cap[level_];
  }

  /**
   * @dev Sets cap per KYC level.
   * @param level_  KYC level.
   * @param cap_  new cap value.
   */
  function setCap(KycLevel level_, uint256 cap_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(level_ == KycLevel.Low) {
      require(_cap[KycLevel.Medium] >= cap_, "CrowdsaleStorage::setCap: cap higher than medium cap");
    }
    if(level_ == KycLevel.Medium) {
      require(_cap[KycLevel.High] >= cap_, "CrowdsaleStorage::setCap: cap higher than high cap");
    }    
    _cap[level_] = cap_;
  
    emit CapUpdated(level_, cap_);
  }

  /**
   * @dev Sets purchase state.
   * @param beneficiary_  address performing the token purchase.
   * @param investment_ normalized investment amount.
   * @param tokensSold_ amount of tokens purchased.
   */
  function setPurchaseState(address beneficiary_, uint256 investment_, uint256 tokensSold_)
    external
    onlyRole(CONTROLLER_ROLE)
  {
    _investments[beneficiary_] = _investments[beneficiary_] + investment_;
    _totalTokensSold = _totalTokensSold + tokensSold_;
    _rounds[_activeRound].tokensSold = _rounds[_activeRound].tokensSold + tokensSold_;
    _balances[beneficiary_][_activeRound] = _balances[beneficiary_][_activeRound] + tokensSold_;    
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}