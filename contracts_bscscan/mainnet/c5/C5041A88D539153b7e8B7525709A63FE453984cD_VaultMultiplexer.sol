// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {PoolConstant} from "../../library/PoolConstant.sol";
import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IVaultMultiplexer.sol";
import "../../library/SafeToken.sol";
import "../VaultController.sol";

import "../../interfaces/multiplexer/IQMultiplexer.sol";
import "../../interfaces/multiplexer/IQPositionManager.sol";
import "../../interfaces/IPriceCalculator.sol";

contract VaultMultiplexer is VaultController, IVaultMultiplexer, ReentrancyGuardUpgradeable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 private constant BUNNY = IBEP20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);
    PoolConstant.PoolTypes public constant poolType = PoolConstant.PoolTypes.Multiplexer;

    uint private constant MAX_ITER = 100;
    uint private constant DUST = 1000;
    uint public constant MAX_POSITION_COUNT = 10;
    IPriceCalculator private constant priceCalculator = IPriceCalculator(0xF5BF8A9249e3cc4cB684E3f23db9669323d4FB7d);

    /* ========== STATE VARIABLES ========== */

    address private _token0;
    address private _token1;

    mapping(uint => PositionInfo) private positions;    // id -> positionInfo
    mapping(address => UserInfo) private users;   // account -> userInfo

    IQMultiplexer private qMultiplexer;
    IQPositionManager private positionManager;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize(address _token) external initializer {
        __ReentrancyGuard_init();
        __VaultController_init(IBEP20(_token));

        _token0 = IPancakePair(_token).token0();
        _token1 = IPancakePair(_token).token1();
    }

    /* ========== MODIFIER ========== */

    modifier onlyPositionOwner(uint id) {
        require(getPositionOwner(id) == msg.sender, "VaultMultiplexer: permission denied");
        _;
    }

    modifier onlyEOACaller() {
        require(msg.sender == tx.origin, "VaultMultiplexer: only EOA can be caller");
        _;
    }

    /* ========== VIEW FUNCTION ========== */

    function balance() public override view returns (uint) {
        return positionManager.positionBalanceOfUser(address(this), address(_stakingToken));
    }

    function balanceOf(uint id) public override view returns (uint) {
        return positionManager.balanceOf(address(_stakingToken), id);
    }

    function principalOf(uint id) public override view returns (uint) {
        return positionManager.principalOf(address(_stakingToken), id);
    }

    function earned(uint id) public override view returns (uint) {
        return positionManager.earned(address(_stakingToken), id);
    }

    function debtRatioLimit() public view returns (uint) {
        return positionManager.debtRatioLimit(address(_stakingToken));
    }

    function debtRatioOf(uint id) external override view returns (uint) {
        return positionManager.debtRatioOf(address(_stakingToken), id);
    }

    function debtValOfPosition(uint id) public override view returns (uint[] memory) {
        return positionManager.debtValOfPosition(address(_stakingToken), id);
    }

    function debtShareOfPosition(uint id, address token) public view returns (uint) {
        return positionManager.debtShareOfPosition(address(_stakingToken), id, token);
    }

    function debtValToShare(uint amount, address token) external view returns (uint) {
        uint totalDebt = positionManager.debtValOfUser(address(this), token);
        return totalDebt == 0 ? amount : amount.mul(positionManager.debtShareOfUser(address(this), token)).div(totalDebt);
    }

    function getPositions(address account) public view returns (uint[] memory) {
        return users[account].positionList;
    }

    function getPositionOwner(uint id) public override view returns (address) {
        return positions[id].account;
    }

    function token0() external override view returns (address) {
        return _token0;
    }

    function token1() external override view returns (address) {
        return _token1;
    }

    function getQubitMultiplexer() external view returns (address) {
        return address(qMultiplexer);
    }

    function getQubitPositionManager() external view returns (address) {
        return address(positionManager);
    }

    function getPositionInfoByAccount(address account) external view returns (PositionState[] memory){
        uint[] memory positionList = getPositions(account);
        PositionState[] memory info;
        if (positionList.length > 0) {
            info = new PositionState[](positionList.length) ;
            for (uint i=0; i<positionList.length; i++){
                uint id = positionList[i];
                IQPositionManager.PositionState memory positionInfo = positionManager.getPositionInfo(address(_stakingToken), id);
                (,uint[] memory liquidationRefund) = positionManager.getLiquidationInfo(address(_stakingToken), id);
                info[i].account = account;
                info[i].liquidated = positionInfo.liquidated;
                info[i].balance = positionInfo.balance;
                info[i].principal = positionInfo.principal;
                info[i].earned = positionInfo.earned;
                info[i].debtRatio = positionInfo.debtRatio;
                info[i].debtToken0 = positionInfo.debtToken0;
                info[i].debtToken1 = positionInfo.debtToken1;
                info[i].token0Value = positionInfo.token0Value;
                info[i].token1Value = positionInfo.token1Value;
                info[i].token0Refund = liquidationRefund[0];
                info[i].token1Refund = liquidationRefund[1];
                info[i].debtRatioLimit = debtRatioLimit();
                info[i].depositedAt = positions[id].depositedAt;
            }
        }
        return info;
    }

    function getVaultState() external view returns (VaultState memory) {
        VaultState memory state;
        (,uint tvlInUSD) = priceCalculator.valueOfAsset(address(_stakingToken), balance());
        state.debtRatioLimit = debtRatioLimit();
        state.balance = balance();
        state.tvl = tvlInUSD;

        return state;
    }

    /* ========== MUTATIVE FUNCTION ========== */

    function openPosition(uint[] memory depositAmount, uint[] memory borrowAmount) external payable onlyEOACaller nonReentrant {
        require(depositAmount.length == 3, "VaultMultiplexer: invalid length of depositAmount");
        require(borrowAmount.length == 2, "VaultMultiplexer: invalid length of borrowAmount");
        if (depositAmount[0] > 0) require(depositAmount[0] == _transferIn(_token0, msg.sender, depositAmount[0]), "VaultMultiplexer: insufficient token0");
        if (depositAmount[1] > 0) require(depositAmount[1] == _transferIn(_token1, msg.sender, depositAmount[1]), "VaultMultiplexer: insufficient token1");
        if (depositAmount[2] > 0) require(depositAmount[2] == _transferIn(address(_stakingToken), msg.sender, depositAmount[2]), "VaultMultiplexer: insufficient stakingToken");

        uint id = positionManager.getLastPositionID(address(_stakingToken));
        PositionInfo storage positionInfo = positions[id];
        UserInfo storage userInfo = users[msg.sender];

        if (_token0 == WBNB || _token1 == WBNB) {
            qMultiplexer.createPosition{value: _token0 == WBNB ? depositAmount[0] : depositAmount[1]}(address(_stakingToken), depositAmount, borrowAmount);
        } else {
            qMultiplexer.createPosition(address(_stakingToken), depositAmount, borrowAmount);
        }

        positionInfo.account = msg.sender;
        positionInfo.depositedAt = block.timestamp;
        userInfo.debtShare[_token0] = userInfo.debtShare[_token0].add(debtShareOfPosition(id, _token0));
        userInfo.debtShare[_token1] = userInfo.debtShare[_token1].add(debtShareOfPosition(id, _token1));
        _appendPosition(msg.sender, id);

        emit OpenPosition(msg.sender, id);
        emit Deposited(msg.sender, id, depositAmount[0], depositAmount[1], depositAmount[2]);
        if (borrowAmount[0] > 0 || borrowAmount[1] > 0) emit Borrow(msg.sender, id, borrowAmount[0], borrowAmount[1]);
    }

    function closePosition(uint id) external onlyEOACaller onlyPositionOwner(id) nonReentrant {
        uint _balance = balanceOf(id);
        UserInfo storage userInfo = users[msg.sender];
        userInfo.debtShare[_token0] = userInfo.debtShare[_token0].sub(debtShareOfPosition(id, _token0));
        userInfo.debtShare[_token1] = userInfo.debtShare[_token1].sub(debtShareOfPosition(id, _token1));

        uint beforeToken0 = _token0 == WBNB ? address(this).balance : IBEP20(_token0).balanceOf(address(this));
        uint beforeToken1 = _token1 == WBNB ? address(this).balance : IBEP20(_token1).balanceOf(address(this));

        qMultiplexer.closePosition(address(_stakingToken), id);

        uint token0Refund = _token0 == WBNB ? address(this).balance.sub(beforeToken0) : IBEP20(_token0).balanceOf(address(this)).sub(beforeToken0);
        uint token1Refund = _token1 == WBNB ? address(this).balance.sub(beforeToken1) : IBEP20(_token1).balanceOf(address(this)).sub(beforeToken1);
        token0Refund = _calcWithdrawalFee(_token0, token0Refund, positions[id].depositedAt);
        token1Refund = _calcWithdrawalFee(_token1, token1Refund, positions[id].depositedAt);

        _removePosition(msg.sender, id);
        delete positions[id];

        _transferOut(_token0, msg.sender, token0Refund);
        _transferOut(_token1, msg.sender, token1Refund);
        emit ClosePosition(msg.sender, id);
        emit Withdrawn(msg.sender, id, _balance, token0Refund, token1Refund);
    }

    function increasePosition(uint id, uint[] memory depositAmount, uint[] memory borrowAmount) external payable onlyEOACaller onlyPositionOwner(id) nonReentrant {
        require(depositAmount.length == 3, "VaultMultiplexer: invalid length of depositAmount");
        require(borrowAmount.length == 2, "VaultMultiplexer: invalid length of borrowAmount");

        UserInfo storage userInfo = users[msg.sender];
        userInfo.debtShare[_token0] = userInfo.debtShare[_token0].sub(debtShareOfPosition(id, _token0));
        userInfo.debtShare[_token1] = userInfo.debtShare[_token1].sub(debtShareOfPosition(id, _token1));

        if (depositAmount[0] > 0) require(depositAmount[0] == _transferIn(_token0, msg.sender, depositAmount[0]), "VaultMultiplexer: insufficient token0");
        if (depositAmount[1] > 0) require(depositAmount[1] == _transferIn(_token1, msg.sender, depositAmount[1]), "VaultMultiplexer: insufficient token1");
        if (depositAmount[2] > 0) require(depositAmount[2] == _transferIn(address(_stakingToken), msg.sender, depositAmount[2]), "VaultMultiplexer: insufficient stakingToken");

        if (_token0 == WBNB || _token1 == WBNB){
            qMultiplexer.increasePosition{value: _token0 == WBNB ? depositAmount[0] : depositAmount[1]}(address(_stakingToken), id, depositAmount, borrowAmount);
        } else {
            qMultiplexer.increasePosition(address(_stakingToken), id, depositAmount, borrowAmount);
        }

        positions[id].depositedAt = block.timestamp;
        userInfo.debtShare[_token0] = userInfo.debtShare[_token0].add(debtShareOfPosition(id, _token0));
        userInfo.debtShare[_token1] = userInfo.debtShare[_token1].add(debtShareOfPosition(id, _token1));

        emit Deposited(msg.sender, id, depositAmount[0], depositAmount[1], depositAmount[2]);
        if (borrowAmount[0] > 0 || borrowAmount[1] > 0) emit Borrow(msg.sender, id, borrowAmount[0], borrowAmount[1]);
    }

    function reducePosition(uint id, uint amount, uint[] memory repayAmount) external onlyEOACaller onlyPositionOwner(id) nonReentrant {
        require(repayAmount.length == 2, "VaultMultiplexer: invalid length of repayAmount");

        {
            uint[] memory debtValue = debtValOfPosition(id);
            require(amount <= principalOf(id), "VaultMultiplexer: VaultMultiplexer: invalid withdrawAmount");
            require(repayAmount[0] <= debtValue[0], "VaultMultiplexer: invalid token0RepayAmount");
            require(repayAmount[1] <= debtValue[1], "VaultMultiplexer: invalid token1RepayAmount");
        }

        uint _depositTimestamp = positions[id].depositedAt;
        UserInfo storage userInfo = users[msg.sender];
        userInfo.debtShare[_token0] = userInfo.debtShare[_token0].sub(debtShareOfPosition(id, _token0));
        userInfo.debtShare[_token1] = userInfo.debtShare[_token1].sub(debtShareOfPosition(id, _token1));

        uint beforeToken0 = _token0 == WBNB ? address(this).balance : IBEP20(_token0).balanceOf(address(this));
        uint beforeToken1 = _token1 == WBNB ? address(this).balance : IBEP20(_token1).balanceOf(address(this));
        qMultiplexer.reducePosition(address(_stakingToken), id, amount, repayAmount);

        userInfo.debtShare[_token0] = userInfo.debtShare[_token0].add(debtShareOfPosition(id, _token0));
        userInfo.debtShare[_token1] = userInfo.debtShare[_token1].add(debtShareOfPosition(id, _token1));

        uint token0Refund = _token0 == WBNB ? address(this).balance.sub(beforeToken0) : IBEP20(_token0).balanceOf(address(this)).sub(beforeToken0);
        uint token1Refund = _token1 == WBNB ? address(this).balance.sub(beforeToken1) : IBEP20(_token1).balanceOf(address(this)).sub(beforeToken1);

        token0Refund = _calcWithdrawalFee(_token0, token0Refund, _depositTimestamp);
        token1Refund = _calcWithdrawalFee(_token1, token1Refund, _depositTimestamp);

        _transferOut(_token0, msg.sender, token0Refund);
        _transferOut(_token1, msg.sender, token1Refund);

        emit Withdrawn(msg.sender, id, amount, token0Refund, token1Refund);
        if (repayAmount[0] > 0 || repayAmount[1] > 0) emit Repay(msg.sender, id, repayAmount[0], repayAmount[1]);
    }

    function refundLiquidation(uint id) external onlyPositionOwner(id) nonReentrant {
        (bool liquidated, uint[] memory refundAmount) = positionManager.getLiquidationInfo(address(_stakingToken), id);
        require(liquidated, "VaultMultiplexer:: not liquidated yet!");

        delete positions[id];
        _removePosition(msg.sender, id);
        qMultiplexer.liquidationRefund(address(_stakingToken), id);
        _transferOut(_token0, msg.sender, refundAmount[0]);
        _transferOut(_token1, msg.sender, refundAmount[1]);
    }

    function getReward(uint id) external onlyPositionOwner(id) nonReentrant {
        uint reward = earned(id);
        if (reward > 0) {
            uint _before = _stakingToken.balanceOf(address(this));
            qMultiplexer.getReward(address(_stakingToken), id);
            reward = _stakingToken.balanceOf(address(this)).sub(_before);

            _transferOut(address(_stakingToken), msg.sender, reward);

            emit ClaimReward(msg.sender, id, reward);
        }
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setMultiplexer(address _multiplexer) external onlyOwner {
        qMultiplexer = IQMultiplexer(_multiplexer);

        IBEP20(address(_stakingToken)).safeApprove(_multiplexer, uint(-1));
        IBEP20(_token0).safeApprove(_multiplexer, uint(-1));
        IBEP20(_token1).safeApprove(_multiplexer, uint(-1));
    }

    function setPositionManager(address _positionManager) external onlyOwner {
        positionManager = IQPositionManager(_positionManager);
    }

    function setMinter(address newMinter) public override onlyOwner {
        if (newMinter != address(0)) {
            require(newMinter == BUNNY.getOwner(), "VaultMultiplexer: not bunny minter");
            IBEP20(_token0).safeApprove(newMinter, 0);
            IBEP20(_token0).safeApprove(newMinter, uint(-1));
            IBEP20(_token1).safeApprove(newMinter, 0);
            IBEP20(_token1).safeApprove(newMinter, uint(-1));
        }
        if (address(_minter) != address(0)) IBEP20(_token0).safeApprove(address(_minter), 0);
        if (address(_minter) != address(0)) IBEP20(_token1).safeApprove(address(_minter), 0);
        _minter = IBunnyMinterV2(newMinter);
    }

    /* ========== PRIVATE FUNCTION ========== */

    function _transferIn(address token, address from, uint amount) private returns (uint amountIn) {
        if (token == WBNB) return msg.value;
        uint _before = IBEP20(token).balanceOf(address(this));
        IBEP20(token).safeTransferFrom(from, address(this), amount);
        amountIn = IBEP20(token).balanceOf(address(this)).sub(_before);
    }

    function _transferOut(address token, address to, uint amount) private {
        if (amount > 0){
            token == WBNB ? SafeToken.safeTransferETH(to, amount) : IBEP20(token).safeTransfer(to, amount);
        }
    }

    function _appendPosition(address account, uint id) private {
        UserInfo storage user = users[account];
        require(user.positionList.length + 1 <= MAX_POSITION_COUNT, "VaultMultiplexer: MAX_POSITION_COUNT");
        user.positionList.push(id);
    }

    function _removePosition(address account, uint id) private {
        require(users[account].positionList.length > 0, "VaultMultiplexer: empty position list");
        UserInfo storage user = users[account];

        if (id != user.positionList[user.positionList.length - 1]) {
            uint idx = _findIdx(user.positionList, id);
            for (uint i=idx; i<user.positionList.length - 1; i++) {
                user.positionList[i] = user.positionList[i+1];
            }
        }
        user.positionList.pop();
    }

    function _calcWithdrawalFee(address _token, uint _amount, uint _depositTimestamp) private returns (uint) {
        if (canMint()) {
            uint _withdrawalFee = _minter.withdrawalFee(_amount, _depositTimestamp);
            if (_withdrawalFee > DUST) {
                _token == WBNB ?
                _minter.mintForV2{value: _withdrawalFee}(address(0), _withdrawalFee, 0, msg.sender, _depositTimestamp) :
                _minter.mintForV2(_token, _withdrawalFee, 0, msg.sender, _depositTimestamp);
            }
            _amount = _amount.sub(_withdrawalFee);
        }
        return _amount;
    }

    // suppose array sorted by ascending order
    function _findIdx(uint[] memory arr, uint value) private pure returns (uint) {
        uint arrayLen = arr.length;
        uint iter = 0;
        uint start = 0;
        uint end = arrayLen - 1;
        uint i = arrayLen.div(2);

        while (true) {
            require(iter < MAX_ITER, "VaultMultiplexer: MAX_ITER");
            uint v = arr[i];
            if (v == value) {
                return i;
            }
            else if (v > value) {
                end = i;
                i = i.add(start).div(2);
            }
            else {
                start = i;
                i = i.add(end).div(2);
            }
            iter++;
        }

        return i;
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
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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


library PoolConstant {

    enum PoolTypes {
        BunnyStake_deprecated, // no perf fee
        BunnyFlip_deprecated, // deprecated
        CakeStake, FlipToFlip, FlipToCake,
        Bunny, // no perf fee
        BunnyBNB,
        Venus,
        Collateral,
        BunnyToBunny,
        FlipToReward,
        BunnyV2,
        Qubit,
        bQBT, flipToQBT,
        Multiplexer
    }

    struct PoolInfo {
        address pool;
        uint balance;
        uint principal;
        uint available;
        uint tvl;
        uint utilized;
        uint liquidity;
        uint pBASE;
        uint pBUNNY;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
        uint portfolio;
    }

    struct RelayInfo {
        address pool;
        uint balanceInUSD;
        uint debtInUSD;
        uint earnedInUSD;
    }

    struct RelayWithdrawn {
        address pool;
        address account;
        uint profitInETH;
        uint lossInETH;
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
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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


interface IVaultMultiplexer {
    struct PositionInfo {
        address account;
        uint depositedAt;
    }

    struct UserInfo {
        uint[] positionList;
        mapping(address => uint) debtShare;
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
        uint token0Refund;
        uint token1Refund;
        uint debtRatioLimit;
        uint depositedAt;
    }

    struct VaultState {
        uint balance;
        uint tvl;
        uint debtRatioLimit;
    }

    // view function
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getPositionOwner(uint id) external view  returns (address);

    // view function
    function balance() external view returns(uint);
    function balanceOf(uint id) external view returns(uint);
    function principalOf(uint id) external view returns(uint);
    function earned(uint id) external view returns(uint);
    function debtValOfPosition(uint id) external view returns (uint[] memory);
    function debtRatioOf(uint id) external view returns (uint);

    // events
    event OpenPosition(address indexed account, uint indexed id);
    event ClosePosition(address indexed account, uint indexed id);

    event Deposited(address indexed account, uint indexed id, uint token0Amount, uint token1Amount, uint lpAmount);
    event Withdrawn(address indexed account, uint indexed id, uint amount, uint token0Amount, uint token1Amount);
    event Borrow(address indexed account, uint indexed id, uint token0Borrow, uint token1Borrow);
    event Repay(address indexed account, uint indexed id, uint token0Repay, uint token1Repay);

    event RewardAdded(address indexed token, uint reward);
    event ClaimReward(address indexed account, uint indexed id, uint reward);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinterV2.sol";
import "../interfaces/IBunnyChef.sol";
import "../library/PausableUpgradeable.sol";
import "../library/WhitelistUpgradeable.sol";


abstract contract VaultController is IVaultController, PausableUpgradeable, WhitelistUpgradeable {
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */
    BEP20 private constant BUNNY = BEP20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    IBEP20 internal _stakingToken;
    IBunnyMinterV2 internal _minter;
    IBunnyChef internal _bunnyChef;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== Event ========== */

    event Recovered(address token, uint amount);


    /* ========== MODIFIERS ========== */

    modifier onlyKeeper {
        require(msg.sender == keeper || msg.sender == owner(), 'VaultController: caller is not the owner or keeper');
        _;
    }

    /* ========== INITIALIZER ========== */

    function __VaultController_init(IBEP20 token) internal initializer {
        __PausableUpgradeable_init();
        __WhitelistUpgradeable_init();

        keeper = 0x793074D9799DC3c6039F8056F1Ba884a73462051;
        _stakingToken = token;
    }

    /* ========== VIEWS FUNCTIONS ========== */

    function minter() external view override returns (address) {
        return canMint() ? address(_minter) : address(0);
    }

    function canMint() internal view returns (bool) {
        return address(_minter) != address(0) && _minter.isMinter(address(this));
    }

    function bunnyChef() external view override returns (address) {
        return address(_bunnyChef);
    }

    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), 'VaultController: invalid keeper address');
        keeper = _keeper;
    }

    function setMinter(address newMinter) virtual public onlyOwner {
        // can zero
        if (newMinter != address(0)) {
            require(newMinter == BUNNY.getOwner(), 'VaultController: not bunny minter');
            _stakingToken.safeApprove(newMinter, 0);
            _stakingToken.safeApprove(newMinter, uint(- 1));
        }
        if (address(_minter) != address(0)) _stakingToken.safeApprove(address(_minter), 0);
        _minter = IBunnyMinterV2(newMinter);
    }

    function setBunnyChef(IBunnyChef newBunnyChef) virtual public onlyOwner {
        require(address(_bunnyChef) == address(0), 'VaultController: setBunnyChef only once');
        _bunnyChef = newBunnyChef;
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address _token, uint amount) virtual external onlyOwner {
        require(_token != address(_stakingToken), 'VaultController: cannot recover underlying token');
        IBEP20(_token).safeTransfer(owner(), amount);

        emit Recovered(_token, amount);
    }
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
    function createPosition(address pool, uint[] memory depositAmount, uint[] memory borrowAmount) external payable;
    function closePosition(address pool, uint id) external;
    function increasePosition(address pool, uint id, uint[] memory depositAmount, uint[] memory borrowAmount) external payable;
    function reducePosition(address lpToken, uint id, uint reduceAmount, uint[] memory repayAmount) external;
    function getReward(address pool, uint id) external;
    function liquidationRefund(address pool, uint id) external;

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
    function pushPosition(address pool, address account, uint id) external;
    function removePosition(address pool, address account, uint id) external;
    function notifyLiquidated(address pool, uint id, uint token0Refund, uint token1Refund) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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


interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }

    function pricesInUSD(address[] memory assets) external view returns (uint[] memory);
    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
    function priceOfBunny() view external returns (uint);
    function priceOfBNB() view external returns (uint);
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

pragma solidity >=0.4.0;

import '../../access/Ownable.sol';
import '../../GSN/Context.sol';
import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "./IStrategyCompact.sol";

interface IStrategy is IStrategyCompact {

    // rewardsToken
    function sharesOf(address account) external view returns (uint);
    function deposit(uint _amount) external;
    function withdraw(uint _amount) external;

    /* ========== Interface ========== */

    function depositAll() external;
    function withdrawAll() external;
    function getReward() external;
    function harvest() external;
    function pid() external view returns (uint);
    function totalSupply() external view returns (uint);
    function poolType() external view returns (PoolConstant.PoolTypes);

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint withdrawalFee);
    event ProfitPaid(address indexed user, uint profit, uint performanceFee);
    event BunnyPaid(address indexed user, uint profit, uint performanceFee);
    event Harvested(uint profit);
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

interface IBunnyMinterV2 {
    function isMinter(address) view external returns(bool);
    function amountBunnyToMint(uint bnbProfit) view external returns(uint);
    function amountBunnyToMintForBunnyBNB(uint amount, uint duration) view external returns(uint);
    function withdrawalFee(uint amount, uint depositedAt) view external returns(uint);
    function performanceFee(uint profit) view external returns(uint);
    function mintFor(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint depositedAt) external payable;
    function mintForV2(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint depositedAt) external payable;

    function WITHDRAWAL_FEE_FREE_PERIOD() view external returns(uint);
    function WITHDRAWAL_FEE() view external returns(uint);

    function setMinter(address minter, bool canMint) external;

    // V2 functions
    function mint(uint amount) external;
    function safeBunnyTransfer(address to, uint256 amount) external;
    function mintGov(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

interface IBunnyChef {

    struct UserInfo {
        uint balance;
        uint pending;
        uint rewardPaid;
    }

    struct VaultInfo {
        address token;
        uint allocPoint;       // How many allocation points assigned to this pool. BUNNYs to distribute per block.
        uint lastRewardBlock;  // Last block number that BUNNYs distribution occurs.
        uint accBunnyPerShare; // Accumulated BUNNYs per share, times 1e12. See below.
    }

    function bunnyPerBlock() external view returns (uint);
    function totalAllocPoint() external view returns (uint);

    function vaultInfoOf(address vault) external view returns (VaultInfo memory);
    function vaultUserInfoOf(address vault, address user) external view returns (UserInfo memory);
    function pendingBunny(address vault, address user) external view returns (uint);

    function notifyDeposited(address user, uint amount) external;
    function notifyWithdrawn(address user, uint amount) external;
    function safeBunnyTransfer(address user) external returns (uint);

    function updateRewardsOf(address vault) external;
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

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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
    mapping (address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns(bool) {
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

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "../library/PoolConstant.sol";
import "./IVaultController.sol";

interface IStrategyCompact is IVaultController {

    /* ========== Dashboard ========== */

    function balance() external view returns (uint);
    function balanceOf(address account) external view returns(uint);
    function principalOf(address account) external view returns (uint);
    function withdrawableBalanceOf(address account) external view returns (uint);
    function earned(address account) external view returns (uint);
    function priceShare() external view returns (uint);
    function depositedAt(address account) external view returns (uint);
    function rewardsToken() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

interface IVaultController {
    function minter() external view returns (address);
    function bunnyChef() external view returns (address);
    function stakingToken() external view returns (address);
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