// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../interfaces/targetVaults/protocols/I4Belt.sol";
import "./TargetVaultAutoFarm.sol";

contract TargetVaultAutoFarmBeltStableCompound is TargetVaultAutoFarm {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Token to deposit to Belt
     */
    IERC20 public depositToken;

    /**
     * @dev 4Belt
     */
    I4Belt public beltStables;

    /**
     * @dev Belt Configurations
     */
    uint128 public beltTokenIndex;

    /**
     * @dev Constructor
     */
    constructor(
        address _token,
        address _depositToken,
        address _feedVault,
        uint128 _beltTokenIndex,
        address _autoFarm,
        uint256 _pid,
        address _feesCollector,
        address _swapRouterAddress
    ) public {
        token = IERC20(_token);
        depositToken = IERC20(_depositToken);
        feedVault = _feedVault;
        beltTokenIndex = _beltTokenIndex;
        autoFarm = IAutoFarmV2(_autoFarm);
        pid = _pid;
        feesCollector = _feesCollector;

        harvester = address(msg.sender);
        swapRouterAddress = _swapRouterAddress;
        tokenToBuyBackPath = [_depositToken, wBNB, buyBackToken];
        autoTokenToTokenPath = [AUTOv2, wBNB, _depositToken];
        beltStables = I4Belt(0xF6e65B33370Ee6A49eB0dbCaA9f43839C1AC04d5);
    }

    /**
     * @dev Deposit from target vault to destination
     */
    function _deposit() internal override {
        uint256 _balance = IERC20(token).balanceOf(address(this));

        if (_balance > 0) {
            depositedBalance += _balance;
            IERC20(token).safeIncreaseAllowance(address(autoFarm), _balance);
            IAutoFarmV2(autoFarm).deposit(pid, _balance);

            emit Deposited(_balance);
        }
    }

    /**
     * @dev Withdraw from target vault to target vault
     */
    function withdraw(uint256 _amount) external override onlyVault {
        if (_amount > 0) {
            depositedBalance -= _amount;
            IAutoFarmV2(autoFarm).withdraw(pid, _amount);
            uint256 _balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(feedVault, _balance);

            if (depositedBalance == 0) {
                cachedPricePerShare = 1e18;
            } else {
                cachedPricePerShare = IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this)).mul(1e18).div(depositedBalance);
            }

            emit Withdrawed(_amount);
        }
    }

    /**
     * @dev Collect fees only vault can call this function
     */
    function collectFees() external override onlyVault {}

    /**
     * Collect Fees
     */
    function _collectFees() internal override {
        uint256 _balance = IERC20(token).balanceOf(address(this));
        uint256 _fees = _balance.mul(feesBP).div(10000);

        if (_fees > 0) {
            if (autoBuyBack) {
                uint256 buyBackBefore = IERC20(buyBackToken).balanceOf(address(this));
                uint256[] memory amounts = IPancakeRouter02(swapRouterAddress).getAmountsOut(_fees, tokenToBuyBackPath);
                uint256 amountOut = amounts[amounts.length.sub(1)];
                token.safeIncreaseAllowance(swapRouterAddress, _fees);
                IPancakeRouter02(swapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _fees,
                    amountOut.mul(slippageFactor).div(1000),
                    tokenToBuyBackPath,
                    address(this),
                    block.timestamp + 120
                );
                uint256 buyBackAfter = IERC20(buyBackToken).balanceOf(address(this));
                uint256 buyBackAmount = buyBackAfter.sub(buyBackBefore);
                IERC20(buyBackToken).safeTransfer(feesCollector, buyBackAmount);

                emit FeesCollected(address(feesCollector), address(buyBackToken), _fees);
            } else {
                token.safeTransfer(feesCollector, _fees);

                emit FeesCollected(address(feesCollector), address(token), _fees);
            }
        }
    }

    /**
     * @dev Convert Rewards to BeltToken
     */
    function _addLiquidity() internal virtual {
        uint256 _balance = IERC20(token).balanceOf(address(this));
        depositToken.safeApprove(address(beltStables), 0);
        depositToken.safeApprove(address(beltStables), _balance);
        uint256[4] memory amounts;
        amounts[beltTokenIndex] = _balance;
        beltStables.add_liquidity(amounts, 0);
    }

    /**
     * @dev Harvest and compound token
     */
    function _harvest() internal override {
        IAutoFarmV2(autoFarm).deposit(pid, 0);
        uint256 swapAmt = IERC20(AUTOv2).balanceOf(address(this));
        if (swapAmt > 0) {
            uint256[] memory amounts = IPancakeRouter02(swapRouterAddress).getAmountsOut(swapAmt, autoTokenToTokenPath);
            uint256 amountOut = amounts[amounts.length.sub(1)];
            IERC20(AUTOv2).safeIncreaseAllowance(swapRouterAddress, swapAmt);
            IPancakeRouter02(swapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmt,
                amountOut.mul(slippageFactor).div(1000),
                autoTokenToTokenPath,
                address(this),
                block.timestamp + 120
            );
            _collectFees();
            _addLiquidity();
            _deposit();

            emit Harvested(swapAmt);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface I4Belt {
    function calc_withdraw_one_coin(uint256 amount, int128 i) external view returns (uint256);

    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function underlying_coins(int128) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../interfaces/targetVaults/protocols/IAutoFarmV2.sol";
import "../../../interfaces/targetVaults/protocols/IAutoFarmStrategy.sol";
import "../TargetVault.sol";

contract TargetVaultAutoFarm is TargetVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev autoFarm address
     */
    IAutoFarmV2 public autoFarm;

    /**
     *@dev autoFarm Pool ID
     */
    uint256 public pid;

    /**
     * @dev AUTOV2 Token address
     */
    address public constant AUTOv2 = 0xa184088a740c695E156F91f5cC086a06bb78b827;

    /**
     * @dev Harvester address
     */
    address public harvester;

    /**
     * @dev Cached deposited balance
     */
    uint256 public depositedBalance = 0;

    /**
     * @dev AutoToken to Token Path
     */
    address[] public autoTokenToTokenPath;

    /**
     * @dev Emitted when AUTO is harvested and compounded
     */
    event Harvested(uint256 amount);

    /**
     * @dev Emitted when harvester is changed
     */
    event HarvesterChanged(address harvester);

    /**
     * @dev Deposit from target vault to target vault
     */
    function deposit() external virtual onlyVault {
        _deposit();
        cachedPricePerShare = IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this)).mul(1e18).div(depositedBalance);
    }

    function _deposit() internal virtual {
        uint256 _balance = IERC20(token).balanceOf(address(this));

        if (_balance > 0) {
            depositedBalance += _balance;
            IERC20(token).safeIncreaseAllowance(address(autoFarm), _balance);
            IAutoFarmV2(autoFarm).deposit(pid, _balance);

            emit Deposited(_balance);
        }
    }

    /**
     * @dev Withdraw from target vault to target vault
     */
    function withdraw(uint256 _amount) external virtual onlyVault {
        if (_amount > 0) {
            depositedBalance -= _amount;
            IAutoFarmV2(autoFarm).withdraw(pid, _amount);
            uint256 _balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(feedVault, _balance);

            if (depositedBalance == 0) {
                cachedPricePerShare = 1e18;
            } else {
                cachedPricePerShare = IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this)).mul(1e18).div(depositedBalance);
            }

            emit Withdrawed(_amount);
        }
    }

    /**
     * @dev Collect fees only vault can call this function
     */
    function collectFees() external virtual onlyVault {
        _collectFees();
    }

    /**
     * Collect Fees
     */
    function _collectFees() internal virtual {
        if (depositedBalance > 0) {
            uint256 _newPricePerShare = IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this)).mul(1e18).div(depositedBalance);
            if (cachedPricePerShare > 0 && cachedPricePerShare < _newPricePerShare) {
                uint256 _balance = IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this));
                uint256 _profit = _balance.mul(_newPricePerShare.sub(cachedPricePerShare));
                uint256 _amount = _profit.mul(feesBP).div(10000).div(_newPricePerShare);
                uint256 _before = token.balanceOf(address(this));
                if (_amount > 0) IAutoFarmV2(autoFarm).withdraw(pid, _amount);
                uint256 _after = token.balanceOf(address(this));
                uint256 _fees = _after.sub(_before);
                if (_fees > 0) {
                    if (autoBuyBack) {
                        uint256 buyBackBefore = IERC20(buyBackToken).balanceOf(address(this));
                        uint256[] memory amounts = IPancakeRouter02(swapRouterAddress).getAmountsOut(_fees, tokenToBuyBackPath);
                        uint256 amountOut = amounts[amounts.length.sub(1)];
                        IERC20(token).safeIncreaseAllowance(swapRouterAddress, _fees);
                        IPancakeRouter02(swapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            _fees,
                            amountOut.mul(slippageFactor).div(1000),
                            tokenToBuyBackPath,
                            address(this),
                            block.timestamp + 120
                        );
                        uint256 buyBackAfter = IERC20(buyBackToken).balanceOf(address(this));
                        uint256 buyBackAmount = buyBackAfter.sub(buyBackBefore);
                        IERC20(buyBackToken).safeTransfer(feesCollector, buyBackAmount);
                        emit FeesCollected(address(feesCollector), address(buyBackToken), _fees);
                    } else {
                        IERC20(token).safeTransfer(feesCollector, _fees);
                        emit FeesCollected(address(feesCollector), address(token), _fees);
                    }
                }
            }
            cachedPricePerShare = IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this)).mul(1e18).div(depositedBalance);
        }
    }

    /**
     * @dev Harvest
     */
    function harvest() external virtual {
        require(address(msg.sender) == harvester, "TargetVaultAutoFarm(harvest): sender is not harvester");
        if (autoFarm.pendingAUTO(pid, address(this)) > 0) _harvest();
    }

    /**
     * @dev Harvest and compound token
     */
    function _harvest() internal virtual {
        IAutoFarmV2(autoFarm).deposit(pid, 0);
        uint256 swapAmt = IERC20(AUTOv2).balanceOf(address(this));
        if (swapAmt > 0) {
            IERC20(AUTOv2).safeIncreaseAllowance(swapRouterAddress, swapAmt);
            IPancakeRouter02(swapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                autoTokenToTokenPath,
                address(this),
                block.timestamp + 120
            );
            _deposit();

            emit Harvested(swapAmt);
        }
    }

    /**
     * @dev Withdraw all deposited balance back to target vault
     */
    function emergencyWithdrawAll() external virtual onlyOwner {
        autoFarm.emergencyWithdraw(pid);
        token.safeTransfer(feedVault, token.balanceOf(address(this)));
        cachedPricePerShare = 0;

        emit EmergencyWithdrawed();
    }

    /**
     * @dev Balance of target vault plus deposited balance
     */
    function balanceOf() public view virtual returns (uint256) {
        return availableBalance().add(vaultBalance());
    }

    /**
     * @dev Get target vault price per share
     */
    function targetPricePerShare() public view virtual returns (uint256) {
        return depositedBalance == 0 ? 1e18 : vaultBalance().mul(1e18).div(depositedBalance);
    }

    /**
     * @dev Get total balnace of tokens deposited in the vault
     */
    function balanceOfToken() public view virtual returns (uint256) {
        return availableBalance().add(vaultBalance());
    }

    /**
     * @dev Balance of token in target vault contract
     */
    function availableBalance() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Get balance in target vault
     */
    function vaultBalance() public view virtual returns (uint256) {
        return IAutoFarmV2(autoFarm).stakedWantTokens(pid, address(this));
    }

    /**
     * @dev Get vault token
     */
    function vaultToken() public view virtual returns (address) {
        (IERC20 _want, uint256 _allocPoint, uint256 _lastRewardBlock, uint256 _accAUTOPerShare, IAutoFarmStrategy _strat) =
            IAutoFarmV2(autoFarm).poolInfo(pid);

        return address(_want);
    }

    /**
     * @dev Get vault strategy
     */
    function vaultStrategy() public view virtual returns (address) {
        (IERC20 _want, uint256 _allocPoint, uint256 _lastRewardBlock, uint256 _accAUTOPerShare, IAutoFarmStrategy _strat) =
            IAutoFarmV2(autoFarm).poolInfo(pid);

        return address(_strat);
    }

    /**
     * @dev Set harvester address
     */
    function setHarvester(address _harvester) external virtual onlyOwner {
        require(_harvester != address(0), "TargetVault(setHarvester): harvester cannot be zero address");

        harvester = _harvester;

        emit HarvesterChanged(harvester);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../protocols/IAutoFarmStrategy.sol";

interface IAutoFarmV2 {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            IERC20,
            uint256,
            uint256,
            uint256,
            IAutoFarmStrategy
        );

    function poolLength() external view returns (uint256);

    function getMultiplier() external view returns (uint256);

    function pendingAUTO(uint256 _pid, address _user) external view returns (uint256);

    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IAutoFarmStrategy {
    // Main want token compounding function
    function earn() external;

    function farm() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/IPancakeRouter02.sol";

contract TargetVault is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev ERC20/BEP20 token accept by target vault
     */
    IERC20 public token;

    /**
     * @dev feedVault address
     */
    address public feedVault;

    /**
     * @dev FeesCollector address
     */
    address public feesCollector;

    /**
     * @dev Cached Price per Share
     */
    uint256 public cachedPricePerShare;

    /**
     * @dev Fees basis points
     */
    uint256 public feesBP = 500;

    /**
     * @dev Maximum Fees Basis points
     */
    uint256 public constant MAXIMUM_FEES_BP = 3000;

    /**
     * @dev Minimum Fees Decimal points
     */
    uint256 public minimumFeesDecimal = 10;

    /**
     * @dev Automatically buy back fees into token
     */
    bool public autoBuyBack = true;

    /**
     * @dev Buy back token address
     */
    address public buyBackToken = 0x67d66e8Ec1Fd25d98B3Ccd3B19B7dc4b4b7fC493;

    /**
     * @dev Wrapped BNB
     */
    address public constant wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /**
     * @dev Swap Router Address
     */
    address public swapRouterAddress;

    /**
     * @dev Token to Buy Back Token address path
     */
    address[] public tokenToBuyBackPath;

    /**
     * @dev Slippage factor default at 5% tolerance
     */
    uint256 public slippageFactor = 950;

    /**
     * @dev Maximum slippage factor */
    uint256 public constant slippageFactorMax = 995;

    /**
     * @dev Emitted when target vault is retired
     */
    event TargetVaultRetired();

    /**
     * @dev Emitted when deposited
     */
    event Deposited(uint256 _balance);

    /**
     * @dev Emitted when withdrawed
     */
    event Withdrawed(uint256 _balance);

    /**
     * @dev Emitted when fees collected
     */
    event FeesCollected(address indexed feesCollector, address indexed token, uint256 _amount);

    /**
     * @dev Emitted when emergency withdraw funds
     */
    event EmergencyWithdrawed();

    /**
     * @dev Emitted when auto buy back change status
     */
    event AutoBuyBack(bool _status);

    /**
     * @dev Emitted when buy back token address changed
     */
    event BuyBackTokenChanged(address _buyBackToken);

    /**
     * @dev Emitted when fees basis points changed
     */
    event FeesBPChanged(uint256 _feesBP);

    /**
     * @dev Emitted when fees collector address changed
     */
    event FeesCollectorChanged(address _feesCollector);

    /**
     * @dev Emitted when swap router address changed
     */
    event SwapRouterChanged(address _router);

    /**
     * @dev Emitted when minimum fees decimal points changed
     */
    event MinimumFeesDicimalChanged(uint256 _minimumFeesDecimal);

    /**
     * @dev Emitted when slippage factor changed
     */
    event SlippageFactorChanged(uint256 _slippageFactor);

    /**
     * @dev Throws if caller is not vault
     */
    modifier onlyVault() {
        require(address(msg.sender) == feedVault, "TargetVault: caller is not vault");
        _;
    }

    /**
     * @dev Retire target vault and send all balance back to vault
     */
    function retireTargetVault() public virtual onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(feedVault, balance);

        emit TargetVaultRetired();
    }

    /**
     * @dev Set auto buy back fees on and off
     */
    function setAutoBuyBack(bool _status) public onlyOwner {
        autoBuyBack = _status;

        emit AutoBuyBack(autoBuyBack);
    }

    /**
     * @dev Set fees basis points
     */
    function setFeesBP(uint256 _feesBP) public onlyOwner {
        require(_feesBP <= MAXIMUM_FEES_BP, "TargetVault(setFees): fees basis points exceeds threshold");

        feesBP = _feesBP;

        emit FeesBPChanged(feesBP);
    }

    /**
     * @dev Set fees collector address
     */
    function setFeesCollector(address _feesCollector) public onlyOwner {
        require(_feesCollector != address(0), "TargetVault(setFeesCollector): fees collector cannot be zero address");

        feesCollector = _feesCollector;

        emit FeesCollectorChanged(feesCollector);
    }

    /**
     * @dev Set buy back token address
     */
    function setBuyBackToken(address _buyBackToken) public virtual onlyOwner {
        require(_buyBackToken != address(0), "TargetVault(setBuyBackToken): buy back token cannot be zero address");

        buyBackToken = _buyBackToken;

        tokenToBuyBackPath = [address(token), wBNB, buyBackToken];

        emit BuyBackTokenChanged(buyBackToken);
    }

    /**
     * @dev Set swap router address
     */
    function setSwapRouterAddress(address _router) public onlyOwner {
        require(_router != address(0), "TargetVault(setSwapRouterAddress): swap router cannot be zero address");

        swapRouterAddress = _router;

        emit SwapRouterChanged(swapRouterAddress);
    }

    /**
     * @dev Set minimum fees decimal points
     */
    function setMinimumFeesDecimal(uint256 _minimumFeesDecimal) public onlyOwner {
        minimumFeesDecimal = _minimumFeesDecimal;

        emit MinimumFeesDicimalChanged(minimumFeesDecimal);
    }

    /**
     * @dev Set slippage factor
     */
    function setSlippageFactor(uint256 _slippageFactor) public onlyOwner {
        require(_slippageFactor <= slippageFactorMax, "TargetVault(setSlippageFactor): slippageFactor too high");
        slippageFactor = _slippageFactor;

        emit SlippageFactorChanged(slippageFactor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

