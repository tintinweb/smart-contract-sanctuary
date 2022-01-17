// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


import "../interfaces/IController.sol";
import "../interfaces/IDYToken.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IUSDOracle.sol";

import "./DepositVaultBase.sol";

// LpFarmingVault only for deposit
contract LpFarmingVault is DepositVaultBase {

  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public pair;
  address public token0;
  uint internal decimal0Scale;
  address public token1;
  uint internal decimal1Scale;

  function initialize(
    address _controller,
    address _feeConf,
    address _underlying) external initializer {
    DepositVaultBase.init(_controller, _feeConf, _underlying);
    pair = IDYToken(_underlying).underlying(); 
    
    token0 = IPair(pair).token0();
    uint decimal0 = IERC20Metadata(token0).decimals();
    decimal0Scale = 10 ** decimal0;

    token1 = IPair(pair).token1();
    uint decimal1 = IERC20Metadata(token1).decimals();
    decimal1Scale = 10 ** decimal1;
  }


  function underlyingTransferIn(address sender, uint256 amount) internal virtual override {
    IERC20Upgradeable(underlying).safeTransferFrom(sender, address(this), amount);
  }

  function underlyingTransferOut(address receipt, uint256 amount, bool) internal virtual override {
    //  skip transfer to myself
    if (receipt == address(this)) {
        return;
    }

    require(receipt != address(0), "receipt is empty");
    IERC20Upgradeable(underlying).safeTransfer(receipt, amount);
  }

  function deposit(address dtoken, uint256 amount) external virtual override {
    require(dtoken == address(underlying), "TOKEN_UNMATCH");
    underlyingTransferIn(msg.sender, amount);
    _deposit(msg.sender, amount);
  }

  function depositTo(address dtoken, address to, uint256 amount) external {
    require(dtoken == address(underlying), "TOKEN_UNMATCH");
    underlyingTransferIn(msg.sender, amount);
    _deposit(to, amount);
  }

  // call from dToken
  function syncDeposit(address dtoken, uint256 amount, address user) external virtual override {
    address vault = IController(controller).dyTokenVaults(dtoken);
    require(msg.sender == underlying && dtoken == address(underlying), "TOKEN_UNMATCH");
    require(vault == address(this), "VAULT_UNMATCH");
    _deposit(user, amount);
  }

  function withdraw(uint256 amount, bool unpack) external {
    _withdraw(msg.sender, amount, unpack);
  }

  function withdrawTo(address to, uint256 amount, bool unpack) external {
    _withdraw(to, amount, unpack);
  }

  function liquidate(address liquidator, address borrower, bytes calldata data) external override {
    _liquidate(liquidator, borrower, data);
  }

  function underlyingAmountValue(uint _amount, bool dp) public view returns(uint value) {
    uint lpSupply = IERC20(pair).totalSupply();

    (uint112 reserve0, uint112 reserve1, ) = IPair(pair).getReserves();

    // get lp amount
    uint amount = IDYToken(underlying).underlyingAmount(_amount);

    uint amount0 = reserve0 * amount / lpSupply;
    uint amount1 = reserve1 * amount / lpSupply;

    (address oracle0, uint dr0, ,
     address oracle1, uint dr1,) = IController(controller).getValueConfs(token0, token1);

    uint price0 = IUSDOracle(oracle0).getPrice(token0);
    uint price1 = IUSDOracle(oracle1).getPrice(token1);

    if (dp) { 
      value = (amount0 * price0 * dr0 / PercentBase / decimal0Scale) + (amount1 * price1 * dr1 / PercentBase / decimal1Scale);
    } else {
      value = (amount0 * price0 / decimal0Scale) + (amount1 * price1 / decimal1Scale);
    }
  }

  /**
    @notice 用户 Vault 价值估值
    @param dp Discount 或 Premium
  */
  function userValue(address user, bool dp) external override view returns(uint) {
    if(deposits[user] == 0) {
      return 0;
    }
    return underlyingAmountValue(deposits[user], dp);
  }

  // amount > 0 : deposit
  // amount < 0 : withdraw  
  function pendingValue(address user, int amount) external override view returns(uint) {
    if (amount >= 0) {
      return underlyingAmountValue(deposits[user] + uint(amount), true);
    } else {
      return underlyingAmountValue(deposits[user] - uint(0 - amount), true);
    }
    
  }

}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
pragma solidity >=0.8.0;

interface IController {
  function dyTokens(address) external view returns (address);
  function getValueConf(address _underlying) external view returns (address oracle, uint16 dr, uint16 pr);
  function getValueConfs(address token0, address token1) external view returns (address oracle0, uint16 dr0, uint16 pr0, address oracle1, uint16 dr1, uint16 pr1);

  function strategies(address) external view returns (address);
  function dyTokenVaults(address) external view returns (address);

  function beforeDeposit(address , address _vault, uint) external view;
  function beforeBorrow(address _borrower, address _vault, uint256 _amount) external view;
  function beforeWithdraw(address _redeemer, address _vault, uint256 _amount) external view;
  function beforeRepay(address _repayer , address _vault, uint256 _amount) external view;

  function joinVault(address _user, bool isDeposit) external;
  function exitVault(address _user, bool isDeposit) external;

  function userValues(address _user, bool _dp) external view returns(uint totalDepositValue, uint totalBorrowValue);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


interface IDYToken {
  function deposit(uint _amount, address _toVault) external;
  function depositTo(address _to, uint _amount, address _toVault) external;
  function depositCoin(address to, address _toVault) external payable;

  function withdraw(address _to, uint _shares, bool needWETH) external;

  function underlying() external view returns(address);
  function balanceOfUnderlying(address _user) external view returns (uint);
  function underlyingAmount(uint amount) external view returns (uint);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

// for PancakePair or UniswapPair
interface IPair {

  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function balanceOf(address owner) external view returns (uint);

}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IUSDOracle {
  // Must 8 dec, same as chainlink decimals.
  function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IDYToken.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IDepositVault.sol";
import "../interfaces/IController.sol";
import "../interfaces/IUSDOracle.sol";
import "../interfaces/IFeeConf.sol";
import "../interfaces/IVaultFarm.sol";
import "../interfaces/ILiquidateCallee.sol";
import "../Constants.sol";


abstract contract DepositVaultBase is Constants, IVault, IDepositVault, OwnableUpgradeable, ReentrancyGuardUpgradeable {

  address public override underlying;
  address public controller;
  IFeeConf public feeConf;
  IVaultFarm public farm;

  // 用户存款
  mapping(address => uint ) public deposits;

  /**
    * @notice 存款事件
      @param supplyer 存款人（兑换人）
    */
  event Deposit(address indexed supplyer, uint256 amount);

  /**
    * @notice 取款事件
      @param redeemer 取款人（兑换人）
    */
  event Withdraw(address indexed redeemer, uint256 amount);

  /**
    @notice 借款人抵押品被清算事件
    @param liquidator 清算人
    @param borrower 借款人
    @param supplies  存款
    */
  event Liquidated(address indexed liquidator, address indexed borrower, uint256 supplies);
  
  event FeeConfChanged(address feeconf);
  event ControllerChanged(address controller);
  event FarmChanged(address farm);
  

  /**
    * @notice 初始化
    * @dev  在Vault初始化时设置货币基础信息
    */
  function init(
    address _controller,
    address _feeConf,
    address _underlying) internal {
    
    OwnableUpgradeable.__Ownable_init();
    controller = _controller;
    feeConf = IFeeConf(_feeConf);
    underlying = _underlying;
  }

  function isDuetVault() external override view returns (bool) {
    return true;
  }

  function underlyingTransferIn(address sender, uint256 amount) internal virtual;

  function underlyingTransferOut(
      address receipt,
      uint256 amount,
      bool giveWETH
  ) internal virtual;

  function setFeeConf(address _feeConf) external onlyOwner {
    require(_feeConf != address(0), "INVALID_FEECONF");
    feeConf = IFeeConf(_feeConf);
    emit FeeConfChanged(_feeConf);
  }

  function setAppController(address _controller) external onlyOwner {
    require(_controller != address(0), "INVALID_CONTROLLER");
    controller = _controller;
    emit ControllerChanged(_controller);
  }

  function setVaultFarm(address _farm) external onlyOwner {
    require(_farm != address(0), "INVALID_FARM");
    farm = IVaultFarm(_farm);
    emit FarmChanged(_farm);
  }

  function _deposit(address supplyer, uint256 amount) internal nonReentrant {
    require(amount > 0, "DEPOSITE_IS_ZERO");
    IController(controller).beforeDeposit(supplyer, address(this), amount);

    deposits[supplyer] += amount;
    emit Deposit(supplyer, amount);
    _updateJoinStatus(supplyer);

    if (address(farm) != address(0)) {
      farm.syncDeposit(supplyer, amount, underlying);
    }
  }

  /**
    @notice 取款
    @dev 提现转给指定的接受者 to 
    @param amount 提取数量
    @param unpack 是否解包underlying
    */
  function _withdraw(
      address to,
      uint256 amount,
      bool unpack
  ) internal nonReentrant {
      address redeemer = msg.sender;
      require(deposits[redeemer] >= amount, "INSUFFICIENT_DEPOSIT");
      
      if (unpack) {
        IDYToken(underlying).withdraw(to, amount, true);
      } else {
        underlyingTransferOut(to, amount, false);
      }

      IController(controller).beforeWithdraw(redeemer, address(this), amount);

      deposits[redeemer] -= amount;
      emit Withdraw(redeemer, amount);
      _updateJoinStatus(redeemer);

      if (address(farm) != address(0)) {
        farm.syncWithdraw(redeemer, amount, underlying);
      }
  }

  /**
    * @notice 清算账户资产
    * @param liquidator 清算人
    * @param borrower 借款人
    */
  function _liquidate(address liquidator, address borrower, bytes calldata data) internal nonReentrant{
    require(msg.sender == controller, "LIQUIDATE_INVALID_CALLER");
    require(liquidator != borrower, "LIQUIDATE_DISABLE_YOURSELF");

    uint256 supplies = deposits[borrower];



    //获得抵押品
    if (supplies > 0) {
      uint256 toLiquidatorAmount = supplies;
      (address liqReceiver, uint liqFee) = feeConf.getConfig("liq_fee");
      if (liqFee > 0 && liqReceiver != address(0)) {
        uint fee = supplies * liqFee / PercentBase;
        toLiquidatorAmount = toLiquidatorAmount - fee;
        underlyingTransferOut(liqReceiver, fee, true); 
      }

      underlyingTransferOut(liquidator, toLiquidatorAmount, true); //剩余归清算人
      if (data.length > 0) ILiquidateCallee(liquidator).liquidateDeposit(borrower, underlying, toLiquidatorAmount, data);
    }

    deposits[borrower] = 0;
    emit Liquidated(liquidator, borrower, supplies);
    _updateJoinStatus(borrower);

    if (address(farm) != address(0)) {
      farm.syncLiquidate(borrower, underlying);
    }
  }

  function _updateJoinStatus(address _user) internal {
    bool isDepositVault = true;
    if (deposits[_user] > 0) {
      IController(controller).joinVault(_user, isDepositVault);
    } else {
      IController(controller).exitVault(_user, isDepositVault);
    }
  }

}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity >=0.8.0;

interface IVault {
  // call from controller must impl.
  function underlying() external view returns (address);
  function isDuetVault() external view returns (bool);
  function liquidate(address liquidator, address borrower, bytes calldata data) external;
  function userValue(address user, bool dp) external view returns(uint);
  function pendingValue(address user, int pending) external view returns(uint);
  function underlyingAmountValue(uint amount, bool dp) external view returns(uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IDepositVault {

  function deposits(address user) external view returns(uint amount);
  function deposit(address dtoken, uint256 amount) external;
  function depositTo(address dtoken, address to, uint256 amount) external;
  function syncDeposit(address dtoken, uint256 amount, address user) external;

  function withdraw(uint256 amount, bool unpack) external;
  function withdrawTo(address to, uint256 amount, bool unpack) external;

}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IFeeConf {
  function getConfig(bytes32 _key) external view returns (address, uint); 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultFarm {
  function syncDeposit(address _user, uint256 _amount, address asset) external;
  function syncWithdraw(address _user, uint256 _amount, address asset) external;
  function syncLiquidate(address _user, address asset) external;

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILiquidateCallee {
  function liquidateDeposit(address borrower, address underlying, uint amount, bytes calldata data) external;
  function liquidateBorrow(address borrower, address underlying, uint amount, bytes calldata data) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Constants {
  uint public constant PercentBase = 10000;
}