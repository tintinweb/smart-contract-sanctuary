/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SecurityMatrix} from "../secmatrix/SecurityMatrix.sol";
import {Constant} from "../common/Constant.sol";
import {IStakersPoolV2} from "./IStakersPoolV2.sol";
import {IFeePool} from "../pool/IFeePool.sol";
import {ILPToken} from "../token/ILPToken.sol";
import {Math} from "../common/Math.sol";
import {IClaimSettlementPool} from "../pool/IClaimSettlementPool.sol";

contract StakersPoolV2 is IStakersPoolV2, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeStakersPoolV2() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    address public securityMatrix;
    address public insurTokenAddress;
    // _token
    mapping(address => uint256) public stakedAmountPT;
    // _lpToken
    mapping(address => uint256) public poolLastCalcBlock;
    mapping(address => uint256) public poolWeightPT;
    uint256 public totalPoolWeight;
    mapping(address => uint256) public poolRewardPerLPToken;
    uint256 public rewardStartBlock;
    uint256 public rewardEndBlock;
    uint256 public rewardPerBlock;
    // _lpToken -> account -> rewards
    mapping(address => mapping(address => uint256)) public stkRewardsPerAPerLPT;
    mapping(address => mapping(address => uint256)) public harvestedRewardsPerAPerLPT;

    function setup(address _securityMatrix, address _insurTokenAddress) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        securityMatrix = _securityMatrix;
        require(_insurTokenAddress != address(0), "S:2");
        insurTokenAddress = _insurTokenAddress;
    }

    function setPoolWeight(
        address _lpToken,
        uint256 _poolWeightPT,
        address[] memory _lpTokens
    ) external onlyOwner {
        reCalcAllPools(_lpTokens);
        if (poolWeightPT[_lpToken] != 0) {
            totalPoolWeight = totalPoolWeight.sub(poolWeightPT[_lpToken]);
        }
        poolWeightPT[_lpToken] = _poolWeightPT;
        totalPoolWeight = totalPoolWeight.add(_poolWeightPT);
    }

    event SetRewardInfo(uint256 _rewardStartBlock, uint256 _rewardEndBlock, uint256 _rewardPerBlock);

    function setRewardInfo(
        uint256 _rewardStartBlock,
        uint256 _rewardEndBlock,
        uint256 _rewardPerBlock,
        address[] memory _lpTokens
    ) external onlyOwner {
        require(_rewardStartBlock < _rewardEndBlock, "SRI:1");
        require(block.number < _rewardEndBlock, "SRI:2");
        reCalcAllPools(_lpTokens);
        if (block.number <= rewardEndBlock && block.number >= rewardStartBlock) {
            rewardEndBlock = _rewardEndBlock;
            rewardPerBlock = _rewardPerBlock;
        } else {
            rewardStartBlock = _rewardStartBlock;
            rewardEndBlock = _rewardEndBlock;
            rewardPerBlock = _rewardPerBlock;
        }
        emit SetRewardInfo(_rewardStartBlock, _rewardEndBlock, _rewardPerBlock);
    }

    modifier allowedCaller() {
        require((SecurityMatrix(securityMatrix).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    event StakedAmountPTEvent(address indexed _token, uint256 _amount);

    function getPoolReward(
        uint256 _from,
        uint256 _to,
        uint256 _poolWeight
    ) private view returns (uint256) {
        uint256 start = Math.max(_from, rewardStartBlock);
        uint256 end = Math.min(_to, rewardEndBlock);
        if (end <= start) {
            return 0;
        }
        uint256 deltaBlock = end.sub(start);
        uint256 amount = deltaBlock.mul(rewardPerBlock).mul(_poolWeight).div(totalPoolWeight);
        return amount;
    }

    function reCalcAllPools(address[] memory _lpTokens) private {
        for (uint256 i = 0; i < _lpTokens.length; i++) {
            reCalcPoolPT(_lpTokens[i]);
        }
    }

    function reCalcPoolPT(address _lpToken) public override allowedCaller {
        if (block.number <= poolLastCalcBlock[_lpToken]) {
            // require(false, "reCalcPoolPT:1");
            return;
        }
        uint256 lpSupply = IERC20Upgradeable(_lpToken).totalSupply();
        if (lpSupply == 0) {
            poolLastCalcBlock[_lpToken] = block.number;
            return;
        }
        uint256 reward = getPoolReward(poolLastCalcBlock[_lpToken], block.number, poolWeightPT[_lpToken]);
        poolRewardPerLPToken[_lpToken] = poolRewardPerLPToken[_lpToken].add(reward.mul(1e18).div(lpSupply));
        poolLastCalcBlock[_lpToken] = block.number;
    }

    function showPendingRewards(address _account, address _lpToken) external view override returns (uint256) {
        uint256 poolRewardPerLPTokenT = 0;
        uint256 userAmt = IERC20Upgradeable(_lpToken).balanceOf(_account);
        uint256 userRewardDebt = ILPToken(_lpToken).rewardDebtOf(_account);
        uint256 lpSupply = IERC20Upgradeable(_lpToken).totalSupply();
        if (block.number == poolLastCalcBlock[_lpToken]) {
            return 0;
        }
        if (block.number > poolLastCalcBlock[_lpToken] && lpSupply > 0) {
            uint256 reward = getPoolReward(poolLastCalcBlock[_lpToken], block.number, poolWeightPT[_lpToken]);

            poolRewardPerLPTokenT = poolRewardPerLPToken[_lpToken].add(reward.mul(1e18).div(lpSupply));
        }
        require(userAmt.mul(poolRewardPerLPTokenT).div(1e18) >= userRewardDebt, "showPR:1");
        return userAmt.mul(poolRewardPerLPTokenT).div(1e18).sub(userRewardDebt);
    }

    function settlePendingRewards(address _account, address _lpToken) external override allowedCaller {
        uint256 userAmt = IERC20Upgradeable(_lpToken).balanceOf(_account);
        uint256 userRewardDebt = ILPToken(_lpToken).rewardDebtOf(_account);
        if (userAmt > 0) {
            uint256 pendingAmt = userAmt.mul(poolRewardPerLPToken[_lpToken]).div(1e18).sub(userRewardDebt);
            if (pendingAmt > 0) {
                stkRewardsPerAPerLPT[_lpToken][_account] = stkRewardsPerAPerLPT[_lpToken][_account].add(pendingAmt);
            }
        }
    }

    function showHarvestRewards(address _account, address _lpToken) external view override returns (uint256) {
        return stkRewardsPerAPerLPT[_lpToken][_account];
    }

    function harvestRewards(
        address _account,
        address _lpToken,
        address _to
    ) external override allowedCaller returns (uint256) {
        uint256 amtHas = stkRewardsPerAPerLPT[_lpToken][_account];
        harvestedRewardsPerAPerLPT[_lpToken][_account] = harvestedRewardsPerAPerLPT[_lpToken][_account].add(amtHas);
        stkRewardsPerAPerLPT[_lpToken][_account] = 0;
        IERC20Upgradeable(insurTokenAddress).safeTransfer(_to, amtHas);
        return amtHas;
    }

    function getPoolRewardPerLPToken(address _lpToken) external view override returns (uint256) {
        return poolRewardPerLPToken[_lpToken];
    }

    function addStkAmount(address _token, uint256 _amount) external payable override allowedCaller {
        if (_token == Constant.BCNATIVETOKENADDRESS) {
            require(msg.value == _amount, "ASA:1");
        }
        stakedAmountPT[_token] = stakedAmountPT[_token].add(_amount);
        emit StakedAmountPTEvent(_token, stakedAmountPT[_token]);
    }

    function getStakedAmountPT(address _token) external view override returns (uint256) {
        return stakedAmountPT[_token];
    }

    function withdrawTokens(
        address payable _to,
        uint256 _withdrawAmtAfterFee,
        address _token,
        address _feePool,
        uint256 _fee
    ) external override allowedCaller {
        require(_withdrawAmtAfterFee.add(_fee) <= stakedAmountPT[_token], "WDT:1");
        require(_withdrawAmtAfterFee > 0, "WDT:2");

        stakedAmountPT[_token] = stakedAmountPT[_token].sub(_withdrawAmtAfterFee);
        stakedAmountPT[_token] = stakedAmountPT[_token].sub(_fee);

        if (_token == Constant.BCNATIVETOKENADDRESS) {
            _to.transfer(_withdrawAmtAfterFee);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_to, _withdrawAmtAfterFee);
        }

        if (_token == Constant.BCNATIVETOKENADDRESS) {
            IFeePool(_feePool).addUnstkFee{value: _fee}(_token, _fee);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_feePool, _fee);
            IFeePool(_feePool).addUnstkFee(_token, _fee);
        }
        emit StakedAmountPTEvent(_token, stakedAmountPT[_token]);
    }

    event ClaimPayoutEvent(address _fromToken, address _paymentToken, uint256 _settleAmtPT, uint256 _claimId, uint256 _fromRate, uint256 _toRate);

    function claimPayout(
        address _fromToken,
        address _paymentToken,
        uint256 _settleAmtPT,
        address _claimToSettlementPool,
        uint256 _claimId,
        uint256 _fromRate,
        uint256 _toRate
    ) external override allowedCaller {
        if (_settleAmtPT == 0) {
            return;
        }
        uint256 amountIn = _settleAmtPT.mul(_fromRate).mul(10**8).div(_toRate).div(10**8);
        require(stakedAmountPT[_fromToken] >= amountIn, "claimP:1");
        stakedAmountPT[_fromToken] = stakedAmountPT[_fromToken].sub(amountIn);
        _transferTokenTo(_fromToken, amountIn, _claimToSettlementPool);
        emit StakedAmountPTEvent(_fromToken, stakedAmountPT[_fromToken]);
        emit ClaimPayoutEvent(_fromToken, _paymentToken, _settleAmtPT, _claimId, _fromRate, _toRate);
    }

    function _transferTokenTo(
        address _paymentToken,
        uint256 _amt,
        address _claimToSettlementPool
    ) private {
        if (_paymentToken == Constant.BCNATIVETOKENADDRESS) {
            IClaimSettlementPool(_claimToSettlementPool).addSettlementAmount{value: _amt}(_paymentToken, _amt);
        } else {
            IERC20Upgradeable(_paymentToken).safeTransfer(_claimToSettlementPool, _amt);
            IClaimSettlementPool(_claimToSettlementPool).addSettlementAmount(_paymentToken, _amt);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {ISecurityMatrix} from "./ISecurityMatrix.sol";

contract SecurityMatrix is ISecurityMatrix, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeSecurityMatrix() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    // callee -> caller
    mapping(address => mapping(address => uint256)) public allowedCallersMap;
    mapping(address => address[]) public allowedCallersArray;
    address[] public allowedCallees;

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    function addAllowdCallersPerCallee(address _callee, address[] memory _callers) external onlyOwner {
        require(_callers.length != 0, "AACPC:1");
        require(allowedCallersArray[_callee].length != 0, "AACPC:2");

        for (uint256 index = 0; index < _callers.length; index++) {
            allowedCallersArray[_callee].push(_callers[index]);
            allowedCallersMap[_callee][_callers[index]] = 1;
        }
    }

    function setAllowdCallersPerCallee(address _callee, address[] memory _callers) external onlyOwner {
        require(_callers.length != 0, "SACPC:1");
        // check if callee exist
        if (allowedCallersArray[_callee].length == 0) {
            // not exist, so add callee
            allowedCallees.push(_callee);
        } else {
            // if callee exist, then purge data
            for (uint256 i = 0; i < allowedCallersArray[_callee].length; i++) {
                delete allowedCallersMap[_callee][allowedCallersArray[_callee][i]];
            }
            delete allowedCallersArray[_callee];
        }
        // and overwrite
        for (uint256 index = 0; index < _callers.length; index++) {
            allowedCallersArray[_callee].push(_callers[index]);
            allowedCallersMap[_callee][_callers[index]] = 1;
        }
    }

    function isAllowdCaller(address _callee, address _caller) external view override whenNotPaused returns (bool) {
        return allowedCallersMap[_callee][_caller] == 1 ? true : false;
    }

    function getAllowedCallees() external view returns (address[] memory) {
        return allowedCallees;
    }

    function getAllowedCallersPerCallee(address _callee) external view returns (address[] memory) {
        return allowedCallersArray[_callee];
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

library Constant {
    // the standard 10**18 Amount Multiplier
    uint256 public constant MULTIPLIERX10E18 = 10**18;

    // the valid ETH and DAI addresses (Rinkeby, TBD: Mainnet)
    address public constant BCNATIVETOKENADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // product status enumerations
    uint256 public constant PRODUCTSTATUS_ENABLED = 1;
    uint256 public constant PRODUCTSTATUS_DISABLED = 2;

    // the cover status enumerations
    uint256 public constant COVERSTATUS_ACTIVE = 0;
    uint256 public constant COVERSTATUS_EXPIRED = 1;
    uint256 public constant COVERSTATUS_CLAIMINPROGRESS = 2;
    uint256 public constant COVERSTATUS_CLAIMDONE = 3;

    // the claim status enumerations
    uint256 public constant CLAIMSTATUS_SUBMITTED = 0;
    uint256 public constant CLAIMSTATUS_INVESTIGATING = 1;
    uint256 public constant CLAIMSTATUS_PREPAREFORVOTING = 2;
    uint256 public constant CLAIMSTATUS_VOTING = 3;
    uint256 public constant CLAIMSTATUS_VOTINGCOMPLETED = 4;
    uint256 public constant CLAIMSTATUS_ABDISCRETION = 5;
    uint256 public constant CLAIMSTATUS_COMPLAINING = 6;
    uint256 public constant CLAIMSTATUS_COMPLAININGCOMPLETED = 7;
    uint256 public constant CLAIMSTATUS_ACCEPTED = 8;
    uint256 public constant CLAIMSTATUS_REJECTED = 9;
    uint256 public constant CLAIMSTATUS_PAYOUTREADY = 10;
    uint256 public constant CLAIMSTATUS_PAID = 11;

    // the voting outcome status enumerations
    uint256 public constant OUTCOMESTATUS_NONE = 0;
    uint256 public constant OUTCOMESTATUS_ACCEPTED = 1;
    uint256 public constant OUTCOMESTATUS_REJECTED = 2;

    // 1inch
    address public constant ONEINCH_OPEN_SPLIT_ADDRESS = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);

    // uniswap
    address public constant UNISWAPV2_ROUTER_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IStakersPoolV2 {
    function addStkAmount(address _token, uint256 _amount) external payable;

    function withdrawTokens(
        address payable _to,
        uint256 _amount,
        address _token,
        address _feePool,
        uint256 _fee
    ) external;

    function reCalcPoolPT(address _lpToken) external;

    function settlePendingRewards(address _account, address _lpToken) external;

    function harvestRewards(
        address _account,
        address _lpToken,
        address _to
    ) external returns (uint256);

    function getPoolRewardPerLPToken(address _lpToken) external view returns (uint256);

    function getStakedAmountPT(address _token) external view returns (uint256);

    function showPendingRewards(address _account, address _lpToken) external view returns (uint256);

    function showHarvestRewards(address _account, address _lpToken) external view returns (uint256);

    function claimPayout(
        address _fromToken,
        address _paymentToken,
        uint256 _settleAmtPT,
        address _claimToSettlementPool,
        uint256 _claimId,
        uint256 _fromRate,
        uint256 _toRate
    ) external;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IFeePool {
    function addUnstkFee(address _token, uint256 _fee) external payable;

    function addClaimFee(address _token, uint256 _fee) external payable;

    function addComplainFee(address _token, uint256 _fee) external payable;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ILPToken {
    function proposeToBurn(
        address _account,
        uint256 _amount,
        uint256 _blockWeight
    ) external;

    function mint(
        address _account,
        uint256 _amount,
        uint256 _poolRewardPerLPToken
    ) external;

    function rewardDebtOf(address _account) external view returns (uint256);

    function burnableAmtOf(address _account) external view returns (uint256);

    function burn(
        address _account,
        uint256 _amount,
        uint256 _poolRewardPerLPToken
    ) external;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// a library for performing various math operations
library Math {
    using SafeMathUpgradeable for uint256;

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? y : x;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y.div(2).add(1);
            while (x < z) {
                z = x;
                x = (y.div(x).add(x)).div(2);
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // power private function
    function pow(uint256 _base, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return 1;
        } else if (_exponent == 1) {
            return _base;
        } else if (_base == 0 && _exponent != 0) {
            return 0;
        } else {
            uint256 z = _base;
            for (uint256 i = 1; i < _exponent; i++) {
                z = z.mul(_base);
            }
            return z;
        }
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IClaimSettlementPool {
    function addSettlementAmount(address _token, uint256 _fee) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ISecurityMatrix {
    function isAllowdCaller(address _callee, address _caller) external view returns (bool);
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