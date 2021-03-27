/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity 0.6.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return b - a;
        }
        return a - b;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function decimals() external view returns (uint8);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IFToken is IERC20 {
    function mint(address user, uint256 amount) external returns (bytes memory);

    function borrow(address borrower, uint256 borrowAmount)
        external
        returns (bytes memory);

    function withdraw(
        address payable withdrawer,
        uint256 withdrawTokensIn,
        uint256 withdrawAmountIn
    ) external returns (uint256, bytes memory);

    function underlying() external view returns (address);

    function accrueInterest() external;

    function getAccountState(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function MonitorEventCallback(
        address who,
        bytes32 funcName,
        bytes calldata payload
    ) external;

    function exchangeRateCurrent() external view returns (uint256 exchangeRate);

    function repay(address borrower, uint256 repayAmount)
        external
        returns (uint256, bytes memory);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateStored() external view returns (uint256 exchangeRate);

    function liquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address fTokenCollateral
    ) external returns (bytes memory);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external;

    function _addReservesFresh(uint256 addAmount) external;

    function cancellingOut(address striker)
        external
        returns (bool strikeOk, bytes memory strikeLog);

    function APR() external view returns (uint256);

    function APY() external view returns (uint256);

    function calcBalanceOfUnderlying(address owner)
        external
        view
        returns (uint256);

    function borrowSafeRatio() external view returns (uint256);

    function tokenCash(address token, address account)
        external
        view
        returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function addTotalCash(uint256 _addAmount) external;

    function subTotalCash(uint256 _subAmount) external;

    function totalCash() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalBorrows() external view returns (uint256);
}

interface IBankController {
    function getCashPrior(address underlying) external view returns (uint256);

    function getCashAfter(address underlying, uint256 msgValue)
        external
        view
        returns (uint256);

    function getFTokeAddress(address underlying)
        external
        view
        returns (address);

    function transferToUser(
        address token,
        address payable user,
        uint256 amount
    ) external;

    function transferIn(
        address account,
        address underlying,
        uint256 amount
    ) external payable;

    function borrowCheck(
        address account,
        address underlying,
        address fToken,
        uint256 borrowAmount
    ) external;

    function repayCheck(address underlying) external;

    function liquidateBorrowCheck(
        address fTokenBorrowed,
        address fTokenCollateral,
        address borrower,
        address liquidator,
        uint256 repayAmount
    ) external;

    function liquidateTokens(
        address fTokenBorrowed,
        address fTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256);

    function withdrawCheck(
        address fToken,
        address withdrawer,
        uint256 withdrawTokens
    ) external view returns (uint256);

    function transferCheck(
        address fToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function marketsContains(address fToken) external view returns (bool);

    function seizeCheck(address cTokenCollateral, address cTokenBorrowed)
        external;

    function mintCheck(
        address underlying,
        address minter,
        uint256 amount
    ) external;

    function addReserves(address underlying, uint256 addAmount)
        external
        payable;

    function reduceReserves(
        address underlying,
        address payable account,
        uint256 reduceAmount
    ) external;

    function calcMaxBorrowAmount(address user, address token)
        external
        view
        returns (uint256);

    function calcMaxWithdrawAmount(address user, address token)
        external
        view
        returns (uint256);

    function calcMaxCashOutAmount(address user, address token)
        external
        view
        returns (uint256);

    function calcMaxBorrowAmountWithRatio(address user, address token)
        external
        view
        returns (uint256);

    function transferEthGasCost() external view returns (uint256);

    function isFTokenValid(address fToken) external view returns (bool);

    function balance(address token) external view returns (uint256);

    function flashloanFeeBips() external view returns (uint256);

    function flashloanVault() external view returns (address);

    function transferFlashloanAsset(
        address token,
        address payable user,
        uint256 amount
    ) external;
}

enum RewardType {
    DefaultType,
    Deposit,
    Borrow,
    Withdraw,
    Repay,
    Liquidation,
    TokenIn,
    TokenOut
}

library EthAddressLib {
    /**
     * @dev returns the address used within the protocol to identify ETH
     * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 */
interface IFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external;
}
pragma experimental ABIEncoderV2;

contract Bank is Initializable {
    using SafeMath for uint256;

    bool public paused;

    address public mulSig;

    //monitor event
    event MonitorEvent(bytes32 indexed funcName, bytes payload);
    event FlashLoan(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 fee
    );

    modifier onlyFToken(address fToken) {
        require(
            controller.marketsContains(fToken) ||
                msg.sender == address(controller),
            "only supported ftoken or controller"
        );
        _;
    }

    function MonitorEventCallback(bytes32 funcName, bytes calldata payload)
        external
        onlyFToken(msg.sender)
    {
        emit MonitorEvent(funcName, payload);
    }

    IBankController public controller;

    address public admin;

    address public proposedAdmin;
    address public pauser;

    bool private loaning;
    modifier nonSelfLoan() {
        require(!loaning, "re-loaning");
        loaning = true;
        _;
        loaning = false;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "OnlyAdmin");
        _;
    }

    modifier whenUnpaused {
        require(!paused, "System paused");
        _;
    }

    modifier onlyMulSig {
        require(msg.sender == mulSig, "require mulsig");
        _;
    }

    modifier onlySelf {
        require(msg.sender == address(this), "require self");
        _;
    }

    modifier onlyPauser {
        require(msg.sender == pauser, "require pauser");
        _;
    }

    function initialize(address _controller, address _mulSig)
        public
        initializer
    {
        controller = IBankController(_controller);
        mulSig = _mulSig;
        paused = false;
        admin = msg.sender;
    }

    function setController(address _controller) public onlyAdmin {
        controller = IBankController(_controller);
    }

    function setPaused() public onlyPauser {
        paused = true;
    }

    function setUnpaused() public onlyPauser {
        paused = false;
    }

    function setPauser(address _pauser) public onlyAdmin {
        pauser = _pauser;
    }

    function proposeNewAdmin(address admin_) external onlyMulSig {
        proposedAdmin = admin_;
    }

    function claimAdministration() external {
        require(msg.sender == proposedAdmin, "Not proposed admin.");
        admin = proposedAdmin;
        proposedAdmin = address(0);
    }

    function deposit(address token, uint256 amount)
        public
        payable
        whenUnpaused
    {
        return this._deposit{value: msg.value}(token, amount, msg.sender);
    }

    function _deposit(
        address token,
        uint256 amount,
        address account
    ) external payable whenUnpaused onlySelf nonSelfLoan {
        IFToken fToken = IFToken(controller.getFTokeAddress(token));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        bytes memory flog = fToken.mint(account, amount);
        controller.transferIn{value: msg.value}(account, token, amount);

        fToken.addTotalCash(amount);

        emit MonitorEvent("Deposit", flog);
    }

    function borrow(address underlying, uint256 borrowAmount)
        public
        whenUnpaused
        nonSelfLoan
    {
        IFToken fToken = IFToken(controller.getFTokeAddress(underlying));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        bytes memory flog = fToken.borrow(msg.sender, borrowAmount);
        emit MonitorEvent("Borrow", flog);
    }

    function withdraw(address underlying, uint256 withdrawTokens)
        public
        whenUnpaused
        nonSelfLoan
        returns (uint256)
    {
        IFToken fToken = IFToken(controller.getFTokeAddress(underlying));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        (uint256 amount, bytes memory flog) =
            fToken.withdraw(msg.sender, withdrawTokens, 0);
        emit MonitorEvent("Withdraw", flog);
        return amount;
    }

    function withdrawUnderlying(address underlying, uint256 withdrawAmount)
        public
        whenUnpaused
        nonSelfLoan
        returns (uint256)
    {
        IFToken fToken = IFToken(controller.getFTokeAddress(underlying));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        (uint256 amount, bytes memory flog) =
            fToken.withdraw(msg.sender, 0, withdrawAmount);
        emit MonitorEvent("WithdrawUnderlying", flog);
        return amount;
    }

    function repay(address token, uint256 repayAmount)
        public
        payable
        whenUnpaused
        returns (uint256)
    {
        return this._repay{value: msg.value}(token, repayAmount, msg.sender);
    }

    function _repay(
        address token,
        uint256 repayAmount,
        address account
    ) public payable whenUnpaused onlySelf nonSelfLoan returns (uint256) {
        IFToken fToken = IFToken(controller.getFTokeAddress(token));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        (uint256 actualRepayAmount, bytes memory flog) =
            fToken.repay(account, repayAmount);
        controller.transferIn{value: msg.value}(
            account,
            token,
            actualRepayAmount
        );

        fToken.addTotalCash(actualRepayAmount);

        emit MonitorEvent("Repay", flog);
        return actualRepayAmount;
    }

    function liquidateBorrow(
        address borrower,
        address underlyingBorrow,
        address underlyingCollateral,
        uint256 repayAmount
    ) public payable whenUnpaused nonSelfLoan {
        require(msg.sender != borrower, "Liquidator cannot be borrower");
        require(repayAmount > 0, "Liquidate amount not valid");

        IFToken fTokenBorrow =
            IFToken(controller.getFTokeAddress(underlyingBorrow));
        IFToken fTokenCollateral =
            IFToken(controller.getFTokeAddress(underlyingCollateral));
        bytes memory flog =
            fTokenBorrow.liquidateBorrow(
                msg.sender,
                borrower,
                repayAmount,
                address(fTokenCollateral)
            );
        controller.transferIn{value: msg.value}(
            msg.sender,
            underlyingBorrow,
            repayAmount
        );

        fTokenBorrow.addTotalCash(repayAmount);

        emit MonitorEvent("LiquidateBorrow", flog);
    }

    function tokenIn(address token, uint256 amountIn)
        public
        payable
        whenUnpaused
    {
        IFToken fToken = IFToken(controller.getFTokeAddress(token));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        cancellingOut(token);
        uint256 curBorrowBalance = fToken.borrowBalanceCurrent(msg.sender);
        uint256 actualRepayAmount;

        if (amountIn == uint256(-1)) {
            require(curBorrowBalance > 0, "no debt to repay");
            if (token != EthAddressLib.ethAddress()) {
                require(
                    msg.value == 0,
                    "msg.value should be 0 for ERC20 repay"
                );
                actualRepayAmount = this._repay{value: 0}(
                    token,
                    amountIn,
                    msg.sender
                );
            } else {
                require(
                    msg.value >= curBorrowBalance,
                    "msg.value need great or equal than current debt"
                );
                actualRepayAmount = this._repay{value: curBorrowBalance}(
                    token,
                    amountIn,
                    msg.sender
                );
                if (msg.value > actualRepayAmount) {
                    (bool result, ) =
                        msg.sender.call{
                            value: msg.value.sub(actualRepayAmount),
                            gas: controller.transferEthGasCost()
                        }("");
                    require(result, "Transfer of exceed ETH failed");
                }
            }

            emit MonitorEvent("TokenIn", abi.encode(token, actualRepayAmount));
        } else {
            if (curBorrowBalance > 0) {
                uint256 repayEthValue =
                    SafeMath.min(curBorrowBalance, amountIn);
                if (token != EthAddressLib.ethAddress()) {
                    repayEthValue = 0;
                }
                actualRepayAmount = this._repay{value: repayEthValue}(
                    token,
                    SafeMath.min(curBorrowBalance, amountIn),
                    msg.sender
                );
            }

            if (actualRepayAmount < amountIn) {
                uint256 exceedAmout = SafeMath.sub(amountIn, actualRepayAmount);
                if (token != EthAddressLib.ethAddress()) {
                    exceedAmout = 0;
                }
                this._deposit{value: exceedAmout}(
                    token,
                    SafeMath.sub(amountIn, actualRepayAmount),
                    msg.sender
                );
            }

            emit MonitorEvent("TokenIn", abi.encode(token, amountIn));
        }
    }

    function tokenOut(address token, uint256 amountOut) external whenUnpaused {
        IFToken fToken = IFToken(controller.getFTokeAddress(token));
        require(
            controller.marketsContains(address(fToken)),
            "unsupported token"
        );

        cancellingOut(token);

        uint256 supplyAmount = 0;
        if (amountOut == uint256(-1)) {
            uint256 fBalance = fToken.balanceOf(msg.sender);
            require(fBalance > 0, "no asset to withdraw");
            supplyAmount = withdraw(token, fBalance);

            emit MonitorEvent("TokenOut", abi.encode(token, supplyAmount));
        } else {
            uint256 userSupplyBalance =
                fToken.calcBalanceOfUnderlying(msg.sender);
            if (userSupplyBalance > 0) {
                if (userSupplyBalance < amountOut) {
                    supplyAmount = withdraw(
                        token,
                        fToken.balanceOf(msg.sender)
                    );
                } else {
                    supplyAmount = withdrawUnderlying(token, amountOut);
                }
            }

            if (supplyAmount < amountOut) {
                borrow(token, amountOut.sub(supplyAmount));
            }

            emit MonitorEvent("TokenOut", abi.encode(token, amountOut));
        }
    }

    function cancellingOut(address token) public whenUnpaused nonSelfLoan {
        IFToken fToken = IFToken(controller.getFTokeAddress(token));
        (bool strikeOk, bytes memory strikeLog) =
            fToken.cancellingOut(msg.sender);
        if (strikeOk) {
            emit MonitorEvent("CancellingOut", strikeLog);
        }
    }

    function flashloan(
        address receiver,
        address token,
        uint256 amount,
        bytes memory params
    ) public whenUnpaused nonSelfLoan {
        uint256 balanceBefore = controller.balance(token);
        require(
            amount > 0 && amount <= balanceBefore,
            "insufficient flashloan liquidity"
        );

        uint256 fee = amount.mul(controller.flashloanFeeBips()).div(10000);
        address payable _receiver = address(uint160(receiver));

        controller.transferFlashloanAsset(token, _receiver, amount);
        IFlashLoanReceiver(_receiver).executeOperation(
            token,
            amount,
            fee,
            params
        );

        uint256 balanceAfter = controller.balance(token);
        require(
            balanceAfter >= balanceBefore.add(fee),
            "invalid flashloan payback amount"
        );

        address payable vault = address(uint160(controller.flashloanVault()));
        controller.transferFlashloanAsset(token, vault, fee);

        emit FlashLoan(receiver, token, amount, fee);
    }
}