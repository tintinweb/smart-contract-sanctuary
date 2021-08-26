//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IBanker.sol";
import "../interfaces/IERC20Extended.sol";
import "../interfaces/IAddressManager.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IStrategyAssetValue.sol";

/**
 * @notice Treasury Contract
 * @author Maxos
 */
contract Treasury is ITreasury, IStrategyAssetValue, ReentrancyGuardUpgradeable {
  /*** Events ***/

  event AllowToken(address indexed token);
  event DisallowToken(address indexed token);

  /*** Storage Properties ***/

  // Token list allowed in treasury
  address[] public allowedTokens;

  // Returns if token is allowed
  mapping(address => bool) public isAllowedToken;

  // MaxUSD scaled balance
  // userScaledBalance = userBalance / currentInterestIndex
  // This essentially `marks` when a user has deposited in the treasury and can be used to calculate the users current redeemable balance
  mapping(address => uint256) public userScaledBalance;

  // Address manager
  address public addressManager;

  /*** Contract Logic Starts Here */

  modifier onlyManager() {
    require(msg.sender == IAddressManager(addressManager).manager(), "No manager");
    _;
  }

  function initialize(address _addressManager) public initializer {
    __ReentrancyGuard_init();

    addressManager = _addressManager;
  }

  /**
   * @notice Deposit token to the protocol
   * @dev Only allowed token can be deposited
   * @dev Mint MaxUSD and MaxBanker according to mintDepositPercentage
   * @dev Increase user's insurance if mintDepositPercentage is [0, 100)
   * @param _token token address
   * @param _amount token amount
   */
  function buyDeposit(address _token, uint256 _amount) external override onlyManager {
    // TODO: Remove onlyManager modifier later
    require(isAllowedToken[_token], "Invalid token");

    // transfer token
    require(IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _amount));

    // mint MaxUSD/MaxBanker tokens according to the mintDepositPercentage
    // uint256 mintDepositPercentage = IBanker(IAddressManager(addressManager).bankerContract()).mintDepositPercentage();

    // Increase MaxUSDLiabilities
    IBanker(IAddressManager(addressManager).bankerContract()).increaseMaxUSDLiabilities(_amount);
  }

  /**
   * @notice Withdraw token from the protocol
   * @dev Only allowed token can be withdrawn
   * @dev Decrease user's insurance if _token is MaxBanker
   * @param _amount token amount
   */
  function redeemDeposit(uint256 _amount) external override nonReentrant onlyManager {
    // TODO: Remove onlyManager modifier later
    require(_amount <= IBanker(IAddressManager(addressManager).bankerContract()).getUserMaxUSDLiability(msg.sender), "Invalid amount");

    IBanker(IAddressManager(addressManager).bankerContract()).addRedemptionRequest(msg.sender, _amount, block.timestamp);

    // // transfer token 
    // require(IERC20Upgradeable(_token).transfer(msg.sender, _amount));
  }

  /**
   * @notice Add a new token into the allowed token list
   * @param _token Token address
   */
  function allowToken(address _token) external override onlyManager {
    require(!isAllowedToken[_token], "Already allowed");
    isAllowedToken[_token] = true;

    allowedTokens.push(_token);

    // approve infinit amount of tokens to banker contract
    IERC20Upgradeable(_token).approve(IAddressManager(addressManager).bankerContract(), type(uint256).max);

    emit AllowToken(_token);
  }

  /**
   * @notice Remove token from the allowed token list
   * @param _token Token index in the allowed token list
   */
  function disallowToken(address _token) external override onlyManager {
    require(isAllowedToken[_token], "Already disallowed");
    isAllowedToken[_token] = false;

    for (uint256 i; i < allowedTokens.length; i++) {
      if (allowedTokens[i] == _token) {
        allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
        allowedTokens.pop();

        // remove allowance to banker contract
        IERC20Upgradeable(_token).approve(IAddressManager(addressManager).bankerContract(), 0);

        break;
      }
    }

    emit DisallowToken(_token);
  }

  /**
   * @notice Returns asset value of the Treasury
   * @return (uint256) asset value of the Treasury in USD, Ex: 100 USD is represented by 10,000
   */
  function strategyAssetValue() external view override returns (uint256) {
    uint256 assetValue;
    for (uint256 i; i < allowedTokens.length; i++) {
      assetValue += IERC20Upgradeable(allowedTokens[i]).balanceOf(address(this)) * 100 / (10**IERC20Extended(allowedTokens[i]).decimals());
    }

    return assetValue;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBanker {
  // MaxUSD redemption queue to the strategy
  struct RedemptionRequest {
      address requestor; // redemption requestor
      uint256 amount; // MaxUSD amount to redeem
      uint256 requestedAt; // redemption request time
  }

  function mintDepositPercentage() external view returns (uint256);
  function increaseMaxUSDLiabilities(uint256 _amount) external;
  function addRedemptionRequest(address _beneficiary, uint256 _amount, uint256 _reqestedAt) external;
  function getUserMaxUSDLiability(address _maxUSDHolder) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20Extended {
  function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAddressManager {
  function manager() external view returns (address);

  function bankerContract() external view returns (address);

  function treasuryContract() external view returns (address);

  function maxUSD() external view returns (address);

  function maxBanker() external view returns (address);

  function investor() external view returns (address);

  function yearnUSDCStrategy() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITreasury {
  function buyDeposit(address token, uint256 amount) external;

  function redeemDeposit(uint256 amount) external;

  function allowToken(address token) external;

  function disallowToken(address token) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategyAssetValue {
  function strategyAssetValue() external view returns (uint256);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}