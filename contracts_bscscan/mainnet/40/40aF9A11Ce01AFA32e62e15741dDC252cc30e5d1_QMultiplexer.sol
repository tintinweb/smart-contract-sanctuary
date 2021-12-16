// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "./QMultiplexerHelper.sol";

contract QMultiplexer is QMultiplexerHelper {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== STATE VARIABLES ========== */

    uint public incentiveBp;
    uint public performanceBp;

    /* ========== EVENTS ========== */

    event Recovered(address token, uint amount);

    /* ========== MODIFIER ========== */

    modifier onlyPositionOwner(address pool, uint id) {
        require(msg.sender == positionManager.getPositionOwner(pool, id), "QMultiplexer: permission denied");
        _;
    }

    modifier checkDebtRatio(address pool, uint id) {
        _;
        require(positionManager.debtRatioOf(pool, id) <= positionManager.debtRatioLimit(pool), "QMultiplexer: Exceed debtRatioLimit");
    }

    modifier checkLiquidated(address pool, uint id) {
        require(!positionManager.isLiquidated(pool, id), "QMultiplexer: liquidated");
        _;
    }

    modifier onlyEOAOrWhitelist() {
        require(msg.sender == tx.origin || isWhitelist(msg.sender), "QMultiplexer: only EOA or whitelist");
        _;
    }

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __MultiplexerHelper_init();

        incentiveBp = 500;
        performanceBp = 300;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createPosition(
        address pool,
        uint[] memory depositAmount,    // token0, token1, lp
        uint[] memory borrowAmount
    ) external payable override onlyEOAOrWhitelist nonReentrant returns (uint id){
        require(depositAmount[0] > 0 || depositAmount[1] > 0 || depositAmount[2] > 0, "QMultiplexer: Zero depositAmount");

        id = positionManager.getLastPositionID(pool);
        uint amount = _borrowAndSwap(id, pool, depositAmount, borrowAmount);

        _deposit(pool, amount);
        positionManager.pushPosition(pool, msg.sender, id, isWhitelist(msg.sender));
        require(positionManager.debtRatioOf(pool, id) <= positionManager.debtRatioLimit(pool), "QMultiplexer: Exceed debtRatioLimit");
        emit OpenPosition(msg.sender, pool, id);
        emit Deposited(msg.sender, pool, id, depositAmount[0], depositAmount[1], depositAmount[2]);
    }

    function increasePosition(
        address pool,
        uint id,
        uint[] memory depositAmount,
        uint[] memory borrowAmount
    ) external override payable onlyEOAOrWhitelist onlyPositionOwner(pool, id) checkDebtRatio(pool, id) checkLiquidated(pool, id) nonReentrant {
        uint amount = _borrowAndSwap(id, pool, depositAmount, borrowAmount);

        _deposit(pool, amount);
        emit Deposited(msg.sender, pool, id, depositAmount[0], depositAmount[1], depositAmount[2]);
    }

    function closePosition(
        address pool,
        uint id)
    external override onlyEOAOrWhitelist onlyPositionOwner(pool, id) checkLiquidated(pool, id) nonReentrant {
        uint _balance = positionManager.balanceOf(pool, id);
        (uint token0Refund, uint token1Refund) = _withdrawAndRepay(pool, id, _balance, positionManager.debtValOfPosition(pool, id));

        positionManager.removePosition(pool, msg.sender, id);

        _transferOut(IPancakePair(pool).token0(), msg.sender, token0Refund);
        _transferOut(IPancakePair(pool).token1(), msg.sender, token1Refund);
        emit ClosePosition(msg.sender, pool, id);
        emit Withdrawn(msg.sender, pool, id, _balance, token0Refund, token1Refund);
    }

    function reducePosition(
        address pool,
        uint id,
        uint reduceAmount,
        uint[] memory repayAmount
    ) external override onlyEOAOrWhitelist onlyPositionOwner(pool, id) checkDebtRatio(pool, id) checkLiquidated(pool, id) nonReentrant {
        require(reduceAmount <= positionManager.principalOf(pool, id), "QMultiplexer: invalid reduceAmount");

        (uint token0Refund, uint token1Refund) = _withdrawAndRepay(pool, id, reduceAmount, repayAmount);

        _transferOut(IPancakePair(pool).token0(), msg.sender, token0Refund);
        _transferOut(IPancakePair(pool).token1(), msg.sender, token1Refund);
        emit Withdrawn(msg.sender, pool, id, reduceAmount, token0Refund, token1Refund);
    }

    function getReward(address pool, uint id) public override onlyEOAOrWhitelist onlyPositionOwner(pool, id) checkLiquidated(pool, id) nonReentrant returns (uint reward) {
        reward = positionManager.earned(pool, id);
        if (reward > 0) {
            positionManager.updatePositionInfo(pool, id, msg.sender, 0, reward, false);
            reward = _withdraw(pool, reward);

            _transferOut(pool, msg.sender, reward);
            emit ClaimReward(msg.sender, pool, id, reward);
        }
    }

    function liquidationRefund(address pool, uint id) public onlyPositionOwner(pool, id) nonReentrant {
        (bool isLiquidated, uint[] memory refundAmount) = positionManager.getLiquidationInfo(pool, id);
        require(isLiquidated, "QMultiplexer: not liquidated yet");

        address positionOwner = positionManager.getPositionOwner(pool, id);
        positionManager.removePosition(pool, msg.sender, id);

        _transferOut(IPancakePair(pool).token0(), positionOwner, refundAmount[0]);
        _transferOut(IPancakePair(pool).token1(), positionOwner, refundAmount[1]);
        emit Withdrawn(msg.sender, pool, id, 0, refundAmount[0], refundAmount[1]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setIncentiveBp(uint _incentiveBp) external onlyOwner {
        require(_incentiveBp <= 10000, "QMultiplexer: invalid value");
        incentiveBp = _incentiveBp;
    }

    function setPerformanceBp(uint _performanceBp) external onlyOwner {
        require(_performanceBp <= 10000, "QMultiplexer: invalid value");
        performanceBp = _performanceBp;
    }

    function harvest(address pool) external onlyKeeper {
        _harvest(pool);
    }

    function claimQBT() external onlyKeeper {
        address[] memory markets = qore.allMarkets();
        for (uint i=0; i<markets.length; i++){
            address token = IQToken(markets[i]).underlying();
            address market = qore.getQToken(token);
            if (market != address(0)) {
                uint _before = IBEP20(QBT).balanceOf(address(this));
                qore.claimQubit(market);
                uint claimedQBT = IBEP20(QBT).balanceOf(address(this)).sub(_before);
                qRewardBox.notifyRewardAmount(token, claimedQBT);
            }
        }
    }

    function kill(address pool, uint id) external onlyWhitelisted nonReentrant {
        require(positionManager.debtRatioOf(pool, id) > positionManager.debtRatioLimit(pool), "QMultiplexer: Not yet to liquidate");

        (uint token0Refund, uint token1Refund) = _withdrawAndRepay(pool, id, positionManager.balanceOf(pool, id), positionManager.debtValOfPosition(pool, id));

        uint token0Incentive = token0Refund.mul(incentiveBp).div(10000);
        uint token1Incentive = token1Refund.mul(incentiveBp).div(10000);

        positionManager.notifyLiquidated(pool, id, token0Refund.sub(token0Incentive), token1Refund.sub(token1Incentive));

        _transferOut(IPancakePair(pool).token0(), msg.sender, token0Incentive);
        _transferOut(IPancakePair(pool).token1(), msg.sender, token1Incentive);
        emit KillPosition(pool, id, token0Incentive, token1Incentive);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _harvest(address pool) private {
        _withdraw(pool, 0);

        uint claimedQBT = qRewardBox.getReward(pool);
        if (claimedQBT > 0) {
            _compound(pool, QBT, claimedQBT);
        }

        if (pendingCake[pool] > 0) {
            uint performanceFee = pendingCake[pool].mul(performanceBp).div(10000);
            _compound(pool, address(CAKE), pendingCake[pool].sub(performanceFee));

            performanceFee = qZap.swapExactTokenForToken(address(CAKE), QBT, performanceFee);
            pendingCake[pool] = 0;

            _transferOut(QBT, DEV_TREASURY, performanceFee);
            emit PerformanceFee(pool, performanceFee);
        }
    }

    function _compound(address pool, address tokenFrom, uint _amount) private {
        (address _token0, address _token1) = positionManager.getBaseTokens(pool);
        address token = _token0 == WBNB ? _token1 : _token0;
        uint tokenOut = qZap.swapExactTokenForToken(tokenFrom, token, _amount);
        uint compoundAmount = token == _token0 ?
                        _addOptimalLiquidity(pool, tokenOut, 0) :
                        _addOptimalLiquidity(pool, 0, tokenOut);
        _deposit(pool, compoundAmount);
        emit Harvested(pool, compoundAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/WhitelistUpgradeable.sol";
import "../library/PausableUpgradeable.sol";
import "../library/SafeToken.sol";

import "../interfaces/IPancakePair.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/multiplexer/IQMultiplexer.sol";
import "../interfaces/multiplexer/IQPositionManager.sol";
import "../interfaces/multiplexer/IQZap.sol";
import "../interfaces/multiplexer/IQRewardBox.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQToken.sol";

abstract contract QMultiplexerHelper is WhitelistUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IQMultiplexer {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address public constant DEV_TREASURY = 0xc7939B1Fa2E7662592b4d11dbE3C331bEE18FC85;

    IBEP20 public constant CAKE = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IMasterChef public constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);

    /* ========== STATE VARIABLES ========== */

    IQPositionManager public positionManager;
    IQZap public qZap;
    IQore public qore;
    IQRewardBox public qRewardBox;

    mapping(address => uint) public pendingCake;
    address public keeper;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== MODIFIER ========== */

    modifier updateCakeHarvested(address pool) {
        uint before = CAKE.balanceOf(address(this));
        _;
        uint _after = CAKE.balanceOf(address(this));
        pendingCake[pool] = pendingCake[pool].add(_after).sub(before);
    }

    modifier onlyKeeper() {
        require(msg.sender == owner() || msg.sender == keeper, "QMultiplexer: only keeper");
        _;
    }

    /* ========== INITIALIZER ========== */

    function __MultiplexerHelper_init() internal initializer {
        __WhitelistUpgradeable_init();
        __PausableUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setPositionManager(address _address) external onlyOwner {
        positionManager = IQPositionManager(_address);
    }

    function setQore(address _qore) external onlyOwner {
        qore = IQore(_qore);
    }

    function setQZap(address _qZap) external onlyOwner {
        qZap = IQZap(_qZap);
        CAKE.safeApprove(_qZap, uint(- 1));
        IBEP20(QBT).safeApprove(_qZap, uint(- 1));
    }

    function setRewardBox(address _qRewardBox) external onlyOwner {
        qRewardBox = IQRewardBox(_qRewardBox);
        IBEP20(QBT).safeApprove(_qRewardBox, uint(- 1));
    }

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    /* ========== INTERNAL FUNCTION ========== */

    function _borrowAndSwap(
        uint id,
        address pool,
        uint[] memory depositAmount,
        uint[] memory borrowAmount
    ) internal returns (uint){
        (address _token0, address _token1) = positionManager.getBaseTokens(pool);
        uint amount;

        if (depositAmount[0] > 0) {
            require(depositAmount[0] == _transferIn(_token0, msg.sender, depositAmount[0]), "QMultiplexer: insufficient token0");
        }
        if (depositAmount[1] > 0) {
            require(depositAmount[1] == _transferIn(_token1, msg.sender, depositAmount[1]), "QMultiplexer: insufficient token1");
        }
        if (depositAmount[2] > 0) {
            require(depositAmount[2] == _transferIn(pool, msg.sender, depositAmount[2]), "QMultiplexer: insufficient LP token");
            amount = amount.add(depositAmount[2]);
        }

        if (borrowAmount[0] > 0) {
            _callQore(pool, id, _token0, borrowAmount[0], 0);
            emit Borrow(msg.sender, pool, id, borrowAmount[0], 0);
        }
        if (borrowAmount[1] > 0) {
            _callQore(pool, id, _token1, borrowAmount[1], 0);
            emit Borrow(msg.sender, pool, id, 0, borrowAmount[1]);
        }

        amount = amount.add(_addOptimalLiquidity(pool, depositAmount[0].add(borrowAmount[0]), depositAmount[1].add(borrowAmount[1])));

        positionManager.updatePositionInfo(pool, id, msg.sender, amount, 0, true);
        return amount;
    }

    function _withdrawAndRepay(
        address pool,
        uint id,
        uint withdrawAmount,
        uint[] memory repayAmount
    ) internal returns (uint token0Refund, uint token1Refund){
        (address _token0, address _token1) = positionManager.getBaseTokens(pool);
        address positionOwner = positionManager.getPositionOwner(pool, id);

        positionManager.updatePositionInfo(pool, id, positionOwner, 0, withdrawAmount, true);
        withdrawAmount = _withdraw(pool, withdrawAmount);

        _approveIfNeeded(pool, address(qZap));
        (token0Refund, token1Refund) = qZap.removeLiquidityWithDesired(pool, withdrawAmount, repayAmount[0], repayAmount[1]);

        if (repayAmount[0] > 0) {
            _callQore(pool, id, _token0, 0, repayAmount[0]);
            token0Refund = token0Refund.sub(repayAmount[0]);
            emit Repay(positionOwner, pool, id, repayAmount[0], 0);
        }
        if (repayAmount[1] > 0) {
            _callQore(pool, id, _token1, 0, repayAmount[1]);
            token1Refund = token1Refund.sub(repayAmount[1]);
            emit Repay(positionOwner, pool, id, 0, repayAmount[1]);
        }
    }

    function _callQore(address pool, uint id, address token, uint borrowAmount, uint repayAmount) private returns (uint) {
        address positionOwner = positionManager.getPositionOwner(pool, id);
        qRewardBox.updateReward(pool, token);

        if (borrowAmount > 0) {
            positionManager.updateDebt(pool, id, msg.sender, token, borrowAmount, 0);
            return qore.borrowMultiplexer(token, borrowAmount);
        }
        else if (repayAmount > 0) {
            _approveIfNeeded(token, qore.getQToken(token));
            positionManager.updateDebt(pool, id, positionOwner, token, 0, repayAmount);
            return token == WBNB ? qore.repayMultiplexer{value : repayAmount}(token, repayAmount) : qore.repayMultiplexer(token, repayAmount);
        }
        return 0;
    }

    function _addOptimalLiquidity(address lpToken, uint token0In, uint token1In) internal returns (uint liquidity) {
        if (token0In == 0 && token1In == 0) return 0;
        (address _token0, address _token1) = positionManager.getBaseTokens(lpToken);

        _approveIfNeeded(_token0, address(qZap));
        _approveIfNeeded(_token1, address(qZap));

        if (_token0 == WBNB) {
            liquidity = qZap.addOptimalLiquidity{value : token0In}(lpToken, token0In, token1In);
        } else if (_token1 == WBNB) {
            liquidity = qZap.addOptimalLiquidity{value : token1In}(lpToken, token0In, token1In);
        } else {
            liquidity = qZap.addOptimalLiquidity(lpToken, token0In, token1In);
        }
    }

    function _approveIfNeeded(address token, address to) internal {
        if (IBEP20(token).allowance(address(this), to) == 0) {
            IBEP20(token).safeApprove(to, uint(- 1));
        }
    }

    function _deposit(address pool, uint amount) internal updateCakeHarvested(pool) {
        uint pid = positionManager.pidOf(pool);
        require(pid != 0, "QMultiplexer: invalid staking token");

        _approveIfNeeded(pool, address(CAKE_MASTER_CHEF));
        CAKE_MASTER_CHEF.deposit(pid, amount);
    }

    function _withdraw(address pool, uint amount) internal updateCakeHarvested(pool) returns (uint amountOut) {
        uint pid = positionManager.pidOf(pool);
        require(pid != 0, "QMultiplexer: invalid staking token");

        uint _before = IBEP20(pool).balanceOf(address(this));
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        amountOut = IBEP20(pool).balanceOf(address(this)).sub(_before);
    }

    function _transferIn(address token, address from, uint amount) internal returns (uint amountIn) {
        if (token == WBNB) return msg.value;
        uint _before = IBEP20(token).balanceOf(address(this));
        IBEP20(token).safeTransferFrom(from, address(this), amount);
        amountIn = IBEP20(token).balanceOf(address(this)).sub(_before);
    }

    function _transferOut(address token, address to, uint amount) internal {
        if (amount > 0) {
            token == WBNB ? SafeToken.safeTransferETH(to, amount) : IBEP20(token).safeTransfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _whitelist;
    bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted() {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint[49] private __gap;
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "PausableUpgradeable: cannot be performed while the contract is paused");
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), "PausableUpgradeable: owner must be set");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {
    function cakePerBlock() view external returns(uint);
    function totalAllocPoint() view external returns(uint);

    function poolInfo(uint _pid) view external returns(address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint _pid, address _account) view external returns(uint amount, uint rewardDebt);
    function poolLength() view external returns(uint);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


interface IQMultiplexer{
    // position management
    function createPosition(address pool, uint[] memory depositAmount, uint[] memory borrowAmount) external payable returns (uint id);
    function closePosition(address pool, uint id) external;
    function increasePosition(address pool, uint id, uint[] memory depositAmount, uint[] memory borrowAmount) external payable;
    function reducePosition(address lpToken, uint id, uint reduceAmount, uint[] memory repayAmount) external;
    function getReward(address pool, uint id) external returns (uint reward);

    // events
    event OpenPosition(address indexed account, address indexed pool, uint id);
    event ClosePosition(address indexed account, address indexed pool, uint id);
    event KillPosition(address indexed pool, uint id, uint token0Incentive, uint token1Incentive);

    event Deposited(address indexed account, address indexed pool, uint id, uint token0Amount, uint token1Amount, uint lpAmount);
    event Withdrawn(address indexed account, address indexed pool, uint id, uint withdrawnAmount, uint token0Refund, uint token1Refund);
    event Borrow(address indexed account, address indexed pool, uint id, uint token0Borrow, uint token1Borrow);
    event Repay(address indexed account, address indexed pool, uint id, uint token0Repay, uint token1Repay);

    event ClaimReward(address indexed account, address indexed pool, uint id, uint reward);
    event Harvested(address indexed pool, uint harvested);
    event PerformanceFee(address indexed pool, uint performanceFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


interface IQPositionManager {
    // Pool Info
    struct PoolInfo {
        uint pid;
        uint lastPositionID;
        uint totalPositionShare;
        uint debtRatioLimit; // debtRatioLimit of pool
        mapping(address => uint) totalDebtShares;   // token -> debtShare
        mapping(uint => PositionInfo) positions;
    }

    // Position Info
    struct PositionInfo {
        bool isLiquidated;
        address positionOwner;
        uint principal;
        uint positionShare;
        mapping(address => uint) debtShare; // debtShare of each tokens
        mapping(address => uint) liquidateAmount;
    }

    struct UserInfo {
        mapping(address => uint) positionShare; // pool(LP) -> positionShare
        mapping(address => uint) debtShare; // token -> debtShare
        mapping (address => uint[]) positionList; // <poolAddress> => <uint array> position id list
    }

    struct PositionState {
        address account;
        bool liquidated;
        uint balance;
        uint principal;
        uint earned;
        uint debtRatio;
        uint debtToken0;
        uint debtToken1;
        uint token0Value;
        uint token1Value;
    }

    // view function
    function totalDebtValue(address token) external view returns (uint);
    function totalDebtShares(address token) external view returns (uint);

    function balance(address pool) external view returns (uint);
    function balanceOf(address pool, uint id) external view returns (uint);
    function principalOf(address pool, uint id) external view returns (uint);
    function earned(address pool, uint id) external view returns(uint);
    function debtShareOfPosition(address pool, uint id, address token) external view returns (uint);
    function debtValOfPosition(address pool, uint id) external view returns (uint[] memory);

    function pidOf(address pool) external view returns (uint);
    function getLastPositionID(address pool) external view returns (uint);
    function getPositionOwner(address pool, uint id) external view returns (address);
    function totalDebtShareOfPool(address pool, address token) external view returns (uint);

    function debtRatioOf(address pool, uint id) external view returns (uint);
    function debtRatioLimit(address pool) external view returns (uint);
    function debtShareOfUser(address account, address token) external view returns (uint);
    function debtValOfUser(address account, address token) external view returns (uint);
    function getPositionList(address pool, address account) external view returns (uint[] memory);
    function positionBalanceOfUser(address account, address pool) external view returns (uint);

    function estimateTokenValue(address lpToken, uint amount) external view returns (uint token0value, uint token1value);
    function estimateAddLiquidity(address lpToken, uint token0Amount, uint token1Amount) external view returns(uint token0Value, uint token1Value, uint token0Swap, uint token1Swap);
    function isLiquidated(address pool, uint id) external view returns (bool);
    function getLiquidationInfo(address pool, uint id) external view returns (bool, uint[] memory);
    function getBaseTokens(address lpToken) external view returns (address, address);
    function getPositionInfo(address pool, uint id) external view returns (PositionState memory);

    // state update function
    function updateDebt(address pool, uint id, address account, address token, uint borrowAmount, uint repayAmount) external;
    function updatePositionInfo(address pool, uint id, address account, uint depositAmount, uint withdrawAmount, bool updatePrincipal) external;

    // handle position state
    function pushPosition(address pool, address account, uint id, bool isWhitelist) external;
    function removePosition(address pool, address account, uint id) external;
    function notifyLiquidated(address pool, uint id, uint token0Refund, uint token1Refund) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


interface IQZap{
    function addOptimalLiquidity(address lpToken, uint token0Amount, uint token1Amount) external payable returns (uint liquidity);
    function removeLiquidityWithDesired(address lpToken, uint lpAmount, uint token0MinOut, uint token1MinOut) external returns (uint token0Refund, uint token1Refund);
    function swapExactTokenForToken(address _from, address _to, uint amountIn) external payable returns (uint amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


interface IQRewardBox{

    // reward
    function earned(address pool, address token) external view returns (uint);
    function updateReward(address pool, address token) external;
    function notifyRewardAmount(address token, uint reward) external;
    function getReward(address pool) external returns (uint);
    function getReward(address pool, address token) external returns (uint);

    // events
    event RewardAdded(address indexed token, uint reward);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


import "../library/QConstant.sol";
import "./IQoreMultiplexer.sol";

interface IQore is IQoreMultiplexer{
    function qValidator() external view returns (address);

    function allMarkets() external view returns (address[] memory);
    function marketListOf(address account) external view returns (address[] memory);
    function marketInfoOf(address qToken) external view returns (QConstant.MarketInfo memory);
    function checkMembership(address account, address qToken) external view returns (bool);
    function accountLiquidityOf(address account) external view returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD);

    function distributionInfoOf(address market) external view returns (QConstant.DistributionInfo memory);
    function accountDistributionInfoOf(address market, address account) external view returns (QConstant.DistributionAccountInfo memory);
    function apyDistributionOf(address market, address account) external view returns (QConstant.DistributionAPY memory);
    function distributionSpeedOf(address qToken) external view returns (uint supplySpeed, uint borrowSpeed);
    function boostedRatioOf(address market, address account) external view returns (uint boostedSupplyRatio, uint boostedBorrowRatio);

    function closeFactor() external view returns (uint);
    function liquidationIncentive() external view returns (uint);

    function accruedQubit(address account) external view returns (uint);
    function accruedQubit(address market, address account) external view returns (uint);

    function enterMarkets(address[] memory qTokens) external;
    function exitMarket(address qToken) external;

    function supply(address qToken, uint underlyingAmount) external payable returns (uint);
    function redeemToken(address qToken, uint qTokenAmount) external returns (uint redeemed);
    function redeemUnderlying(address qToken, uint underlyingAmount) external returns (uint redeemed);
    function borrow(address qToken, uint amount) external;
    function repayBorrow(address qToken, uint amount) external payable;
    function repayBorrowBehalf(address qToken, address borrower, uint amount) external payable;
    function liquidateBorrow(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) external payable;

    function claimQubit() external;
    function claimQubit(address market) external;

    function transferTokens(address spender, address src, address dst, uint amount) external;

    function supplyAndBorrowBNB(address account, address supplyToken, uint supplyAmount, uint borrowAmount) external payable returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/QConstant.sol";

interface IQToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint);

    function accountSnapshot(address account) external view returns (QConstant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint);

    function borrowBalanceOf(address account) external view returns (uint);

    function borrowRatePerSec() external view returns (uint);

    function supplyRatePerSec() external view returns (uint);

    function totalBorrow() external view returns (uint);

    function totalReserve() external view returns (uint);

    function reserveFactor() external view returns (uint);

    function exchangeRate() external view returns (uint);

    function getCash() external view returns (uint);

    function getAccInterestIndex() external view returns (uint);

    function accruedAccountSnapshot(address account) external returns (QConstant.AccountSnapshot memory);

    function accruedUnderlyingBalanceOf(address account) external returns (uint);

    function accruedBorrowBalanceOf(address account) external returns (uint);

    function accruedTotalBorrow() external returns (uint);

    function accruedExchangeRate() external returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function supply(address account, uint underlyingAmount) external payable returns (uint);

    function redeemToken(address account, uint qTokenAmount) external returns (uint);

    function redeemUnderlying(address account, uint underlyingAmount) external returns (uint);

    function borrow(address account, uint amount) external returns (uint);

    function repayBorrow(address account, uint amount) external payable returns (uint);

    function repayBorrowBehalf(address payer, address borrower, uint amount) external payable returns (uint);

    function liquidateBorrow(address qTokenCollateral, address liquidator, address borrower, uint amount) external payable returns (uint qAmountToSeize);

    function seize(address liquidator, address borrower, uint qTokenAmount) external;

    function transferTokensInternal(address spender, address src, address dst, uint amount) external;

    function supplyBehalf(address sender, address supplier, uint uAmount) external payable returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

library QConstant {
    uint public constant CLOSE_FACTOR_MIN = 5e16;
    uint public constant CLOSE_FACTOR_MAX = 9e17;
    uint public constant COLLATERAL_FACTOR_MAX = 9e17;

    struct MarketInfo {
        bool isListed;
        uint borrowCap;
        uint collateralFactor;
    }

    struct BorrowInfo {
        uint borrow;
        uint interestIndex;
    }

    struct AccountSnapshot {
        uint qTokenBalance;
        uint borrowBalance;
        uint exchangeRate;
    }

    struct AccrueSnapshot {
        uint totalBorrow;
        uint totalReserve;
        uint accInterestIndex;
    }

    struct DistributionInfo {
        uint supplySpeed;
        uint borrowSpeed;
        uint totalBoostedSupply;
        uint totalBoostedBorrow;
        uint accPerShareSupply;
        uint accPerShareBorrow;
        uint accruedAt;
    }

    struct DistributionAccountInfo {
        uint accruedQubit;
        uint boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint accPerShareSupply; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint accPerShareBorrow; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint apySupplyQBT;
        uint apyBorrowQBT;
        uint apyAccountSupplyQBT;
        uint apyAccountBorrowQBT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/


interface IQoreMultiplexer {
    // view function
    function getQToken(address underlying) external view returns (address);

    // multiplexer function
    function borrowMultiplexer(address underlying, uint amount) external returns (uint borrowAmount);
    function repayMultiplexer(address underlying, uint amount) external payable returns (uint repayAmount);
}