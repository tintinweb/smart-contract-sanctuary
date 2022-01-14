// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOracle } from "./interfaces/IOracle.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { IDebtToken } from "./interfaces/IDebtToken.sol";
import { IFlashSwap } from "./interfaces/IFlashSwap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * A lending market that only supports a flat borrow fee and no interest rate
 */
contract ZeroInterestMarket is Ownable, Initializable, IMarket {
    using SafeERC20 for IERC20;
    using SafeERC20 for IDebtToken;

    // Events
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);
    event Borrow(address indexed from, address indexed to, uint256 amount);
    event Repay(address indexed from, address indexed to, uint256 amount);
    event Liquidate(address indexed from, address indexed to, uint256 repayDebt, uint256 liquidatedCollateral, uint256 liquidationPrice);
    event TreasuryUpdated(address newTreasury);
    event OracleUpdated(address oracle);
    event LastPriceUpdated(uint price);
    event FeesHarvested(uint fees);

    uint constant internal MAX_INT = 2**256 - 1;

    address public treasury;
    IERC20 public collateralToken;
    IDebtToken public debtToken;

    IOracle public oracle;
    uint public lastPrice;
    uint constant public LAST_PRICE_PRECISION = 1e18;

    uint public feesCollected;

    uint public maxLoanToValue;
    uint constant public LOAN_TO_VALUE_PRECISION = 1e5;
    uint public borrowRate;
    uint constant public BORROW_RATE_PRECISION = 1e5;
    uint public liquidationPenalty;
    uint constant public LIQUIDATION_PENALTY_PRECISION = 1e5;

    mapping(address => uint) public userCollateral;
    mapping(address => uint) public userDebt;
    uint public totalCollateral;
    uint public totalDebt;
 
    function initialize(
        address _owner,
        address _treasury,
        address _collateralToken,
        address _debtToken,
        address _oracle,
        uint256 _maxLoanToValue,
        uint256 _borrowRate,
        uint256 _liquidationPenalty
    ) public initializer {
        require(_owner != address(0), "0x owner address");
        require(_treasury != address(0), "0x treasury address");
        require(_collateralToken != address(0), "0x collateralToken address");
        require(_debtToken != address(0), "0x debtToken address");
        require(_oracle != address(0), "0x oracle address");

        treasury = _treasury;
        collateralToken = IERC20(_collateralToken);
        debtToken = IDebtToken(_debtToken);
        oracle = IOracle(_oracle);
        maxLoanToValue = _maxLoanToValue;
        borrowRate = _borrowRate;
        liquidationPenalty = _liquidationPenalty;
        Ownable._transferOwnership(_owner);

        emit TreasuryUpdated(_treasury);
        emit OracleUpdated(_oracle);
    }

    /**
     * @notice Deposits `_amount` of collateral to the `_to` account.
     * @param _to the account that receives the collateral
     * @param _amount the amount of collateral tokens
     */
    function deposit(address _to, uint _amount) public override {
        userCollateral[_to] = userCollateral[_to] + _amount;
        totalCollateral = totalCollateral + _amount;

        collateralToken.safeTransferFrom(msg.sender, address(this), _amount);

         emit Deposit(msg.sender, _to, _amount);
    }

    /**
     * @notice Withdraws `_amount` of collateral tokens from msg.sender and sends them to the `_to` address.
     * @param _to the account that receives the collateral
     * @param _amount the amount of collateral tokens
     */
    function withdraw(address _to, uint _amount) public override {
        require(_amount <= userCollateral[msg.sender], "Market: amount too large");
        _updatePrice();

        userCollateral[msg.sender] = userCollateral[msg.sender] - _amount;
        totalCollateral = totalCollateral - _amount;

        require(isUserSolvent(msg.sender), "Market: exceeds Loan-to-Value");

        emit Withdraw(msg.sender, _to, _amount);
        collateralToken.safeTransfer(_to, _amount);
    }

    /**
     * @notice Borrows `_amount` of debt tokens against msg.sender's collateral and sends them to the `_to` address
     * Requires that `msg.sender`s account is solvent and will request a price update from the oracle.
     * @param _to the reciever of the debt tokens
     * @param _amount the amount of debt to incur
     */
    function borrow(address _to, uint _amount) public override {
        _updatePrice();

        uint borrowRateFee = _amount * borrowRate / BORROW_RATE_PRECISION;
        totalDebt = totalDebt + _amount + borrowRateFee;
        userDebt[msg.sender] = userDebt[msg.sender] + _amount + borrowRateFee;

        require(isUserSolvent(msg.sender), "Market: exceeds Loan-to-Value");

        feesCollected = feesCollected + borrowRateFee;
        emit Borrow(msg.sender, _to, _amount);
        debtToken.safeTransfer(_to, _amount);
    }

    /**
     * @notice Repays `_amount` of the `_to` user's outstanding loan by transferring debt tokens from msg.sender
     * @param _to the user's account to repay
     * @param _amount the amount of tokens to repay
     */
    function repay(address _to, uint _amount) public override {
        require(_amount <= userDebt[_to], "Market: repay exceeds debt");
        totalDebt = totalDebt - _amount;
        userDebt[_to] = userDebt[_to] - _amount;

        debtToken.safeTransferFrom(msg.sender, address(this), _amount);

         emit Repay(msg.sender, _to, _amount);
    }

    /**
     * @notice Convienence function to deposit collateral and borrow debt tokens to the account of msg.sender
     * @param _depositAmount amount of collateral tokens to deposit
     * @param _borrowAmount amount of debt to incur
     */
    function depositAndBorrow(uint _depositAmount, uint _borrowAmount) external override {
        deposit(msg.sender, _depositAmount);
        borrow(msg.sender, _borrowAmount);
    }

    /**
     * @notice Convenience function to repay debt and withdraw collateral for the account of msg.sender
     * @param _repayAmount amount of debt to repay
     * @param _withdrawAmount amount of collateral to withdraw
     */
    function repayAndWithdraw(uint _repayAmount, uint _withdrawAmount) external override {
        repay(msg.sender, _repayAmount);
        withdraw(msg.sender, _withdrawAmount);
    }

    /**
     * @notice Liquidate `_maxAmount` of a user's collateral who's loan-to-value ratio exceeds limit.
     * Debt tokens provided by `msg.sender` and liquidated collateral sent to `_to`.
     * Reverts if user is solvent.
     * @param _user the account to liquidate
     * @param _maxAmount the maximum amount of debt the liquidator is willing to repay
     * @param _to the address that will receive the liquidated collateral
     * @param _swapper an optional implementation of the IFlashSwap interface to exchange the collateral for debt
     */
    function liquidate(address _user, uint _maxAmount, address _to, IFlashSwap _swapper) external override {
        require(msg.sender != _user, "Market: cannot liquidate self");

        uint price = _updatePrice();

        require(!isUserSolvent(_user), "Market: user solvent");

        uint userCollValue = (userCollateral[_user] * price) /  LAST_PRICE_PRECISION;
        uint discountedCollateralValue = (userCollValue * (LIQUIDATION_PENALTY_PRECISION - liquidationPenalty)) / LIQUIDATION_PENALTY_PRECISION;
        uint repayAmount = userDebt[_user] < _maxAmount ? userDebt[_user] : _maxAmount;
        uint liquidatedCollateral;

        if (discountedCollateralValue < repayAmount) {
            // collateral is worth less than the proposed repayment amount
            // so buy it all
            liquidatedCollateral = userCollateral[_user];
            repayAmount = discountedCollateralValue;
        } else {
            // collateral is worth more than debt, liquidator purchases "repayAmount"
            liquidatedCollateral = (repayAmount * LAST_PRICE_PRECISION) / discountedCollateralValue;
        }

        // bookkeeping
        userCollateral[_user] = userCollateral[_user] - liquidatedCollateral;
        totalCollateral = totalCollateral - liquidatedCollateral;
        userDebt[_user] = userDebt[_user] - repayAmount;
        totalDebt = totalDebt - repayAmount;

        emit Repay(msg.sender, _user, repayAmount);
        emit Withdraw(_user, _to, liquidatedCollateral);
        emit Liquidate(_user, _to, repayAmount, liquidatedCollateral, price);

        collateralToken.safeTransfer(_to, liquidatedCollateral);
        if (_swapper != IFlashSwap(address(0))) {
            _swapper.swap(collateralToken, debtToken, msg.sender, repayAmount, liquidatedCollateral);
        }
        debtToken.safeTransferFrom(msg.sender, address(this), repayAmount);
    }

    /**
     * @notice Harvests fees collected to the treasury
     */
    function harvestFees() external {
        uint fees = feesCollected;
        feesCollected = 0;
        emit FeesHarvested(fees);

        debtToken.safeTransfer(treasury, fees);
    }

    /**
     * @notice updates the current price of the collateral and saves it in `lastPrice`.
     * @return the price
     */
    function updatePrice() external override returns (uint) {
        return _updatePrice();
    }

    function _updatePrice() internal returns (uint) {
        (bool success, uint256 price) = oracle.fetchPrice();
        if (success) {
            lastPrice = price;
            emit LastPriceUpdated(price);
        }
        return lastPrice;
    }

    /**
     * @notice reduces the available supply to be borrowed by transferring debt tokens to owner.
     * @param _amount number of tokens to remove
     */
    function reduceSupply(uint _amount) external onlyOwner {
        debtToken.safeTransfer(this.owner(), _amount);
    }

    /**
     * @notice updates the treasury that receives the fees
     * @param _treasury address of the new treasury
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Market: 0x0 treasury address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @notice updates the price oracle
     * @param _oracle the new oracle
     */
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Market: 0x0 oracle address");
        oracle = IOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    /**
     * @notice recover tokens inadvertantly sent to this contract by transfering them to the owner
     * @param _token the address of the token
     * @param _amount the amount to transfer
     */
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(debtToken), "Cannot recover debt tokens");
        require(_token != address(collateralToken), "Cannot recover collateral tokens");

        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    //////
    /// View Functions
    //////
    function getUserLTV(address _user) public view override returns (uint) {
        if (userDebt[_user] == 0) return 0;
        if (userCollateral[_user] == 0) return MAX_INT;
        return userDebt[_user] * LOAN_TO_VALUE_PRECISION / (userCollateral[_user] * lastPrice / LAST_PRICE_PRECISION);
    }

    function isUserSolvent(address _user) public view override returns (bool) {
        return getUserLTV(_user) <= maxLoanToValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function fetchPrice() external view returns (bool, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IFlashSwap } from "./IFlashSwap.sol";

interface IMarket {
    function deposit(address _to, uint _amount) external;
    function withdraw(address _to, uint _amount) external;
    function borrow(address _to, uint _amount) external;
    function repay(address _to, uint _amount) external;

    function depositAndBorrow(uint _collateralAmount, uint _debtAmount) external;
    function repayAndWithdraw(uint _debtAmount, uint _collateralAmount) external;

    function liquidate(address _user, uint _amount, address _to, IFlashSwap swapper) external;
    function updatePrice() external returns (uint);

    function getUserLTV(address _user) external view returns(uint);
    function isUserSolvent(address _user) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDebtToken is IERC20 {
    function mint(address _to, uint _amount) external;
    function burn(uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashSwap {
    /**
     * @notice A callback for liquidations. The swap method will be called after the collateral tokens
     * have been transfered to the recipient. This function is then responsible for acquiring at least
     * _amountToMin of the debt tokens to pay for the liquidation. The debt tokens will then be transferFrom
     * the recipeient to the market contract, so it is required to approve the market contract for `_amountToMin`.
     * @param _collateralToken the collateral token
     * @param _debtToken the debt token
     * @param _recipient the address who should recieve the swapped debt tokens
     * @param _minRepayAmount the minimum amount of debt tokens needed for the transaction to be successful
     * @param _collateralAmount the number of collateral tokens that have just been transferred to recipient
     */
    function swap(
        IERC20 _collateralToken,
        IERC20 _debtToken,
        address _recipient,
        uint256 _minRepayAmount,
        uint256 _collateralAmount
    ) external;
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