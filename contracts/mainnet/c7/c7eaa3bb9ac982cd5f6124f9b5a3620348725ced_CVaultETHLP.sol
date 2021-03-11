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
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./OwnableUpgradeable.sol";

import "./IUniswapV2Pair.sol";
import "./ICVaultETHLP.sol";
import "./ICVaultRelayer.sol";
import "./IZap.sol";
import "./Whitelist.sol";
import "./CVaultETHLPState.sol";
import "./CVaultETHLPStorage.sol";


contract CVaultETHLP is ICVaultETHLP, CVaultETHLPStorage, Whitelist {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint8 private constant SIG_DEPOSIT = 10;
    uint8 private constant SIG_LEVERAGE = 20;
    uint8 private constant SIG_WITHDRAW = 30;
    uint8 private constant SIG_LIQUIDATE = 40;
    uint8 private constant SIG_EMERGENCY = 50;
    uint8 private constant SIG_CLEAR = 63;          // only owner can execute if state is idle but the BSC position remains.

    /* ========== STATE VARIABLES ========== */

    IZap public zap;
    address public treasury;

    uint public relayerCost;
    uint public minimumDepositValue;
    uint public liquidationCollateralRatio;

    /* ========== EVENTS ========== */

    // Relay Request Events
    event DepositRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, uint leverage);
    event UpdateLeverageRequested(address indexed lp, address indexed account, uint indexed eventId, uint leverage, uint collateral);
    event WithdrawRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount);
    event WithdrawAllRequested(address indexed lp, address indexed account, uint indexed eventId);
    event LiquidateRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, address liquidator);
    event EmergencyExitRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount);

    // Impossible Situation: only owner can execute if state is idle but the BSC position remains.
    event ClearBSCState(address indexed lp, address indexed account, uint indexed eventId);

    // Relay Response Events
    event NotifyDeposited(address indexed lp, address indexed account, uint indexed eventId, uint bscBNBDebtShare, uint bscFlipBalance);
    event NotifyUpdatedLeverage(address indexed lp, address indexed account, uint indexed eventId, uint bscBNBDebtShare, uint bscFlipBalance);
    event NotifyWithdrawnAll(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, uint ethProfit, uint ethLoss);
    event NotifyLiquidated(address indexed lp, address indexed account, uint indexed eventId, uint ethProfit, uint ethLoss, uint penaltyLPAmount, address liquidator);
    event NotifyResolvedEmergency(address indexed lp, address indexed account, uint indexed eventId);

    // User Events
    event CollateralAdded(address indexed lp, address indexed account, uint lpAmount);
    event CollateralRemoved(address indexed lp, address indexed account, uint lpAmount);
    event UnpaidProfitClaimed(address indexed account, uint ethValue);
    event LossRealized(address indexed lp, address indexed account, uint indexed eventId, uint soldLPAmount, uint ethValue);

    /* ========== MODIFIERS ========== */

    modifier onlyCVaultRelayer() {
        require(address(relayer) != address(0) && msg.sender == address(relayer), "CVaultETHLP: caller is not the relayer");
        _;
    }

    modifier canRemoveCollateral(address lp, address _account, uint amount) {
        Account memory account = accountOf(lp, msg.sender);
        uint ratio = relayer.collateralRatioOnETH(lp, account.collateral.sub(amount), bscFlipOf(lp), account.bscFlipBalance, account.bscBNBDebt);
        require(ratio >= COLLATERAL_RATIO_MIN, "CVaultETHLP: can withdraw only up to 180% of the collateral ratio");
        _;
    }

    modifier hasEnoughBalance(uint value) {
        require(address(this).balance >= value, "CVaultETHLP: not enough balance, please try after UTC 00:00");
        _;
    }

    modifier costs {
        uint txFee = relayerCost;
        require(msg.value >= txFee, "CVaultETHLP: Not enough ether provided");
        _;
        if (msg.value > txFee) {
            msg.sender.transfer(msg.value.sub(txFee));
        }
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __CVaultETHLPStorage_init();
        __Whitelist_init();

        relayerCost = 0.015 ether;
        minimumDepositValue = 100e18;
        liquidationCollateralRatio = 125e16;        // 125% == debt ratio 80%
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setZap(address newZap) external onlyOwner {
        zap = IZap(newZap);
    }

    function setPool(address lp, address bscFlip) external onlyOwner {
        _setPool(lp, bscFlip);
        IERC20(lp).safeApprove(address(zap), uint(- 1));
    }

    function recoverToken(address token, uint amount) external onlyOwner {
        require(bscFlipOf(token) == address(0), "CVaultETHLP: lp token can't be recovered");
        IERC20(token).safeTransfer(owner(), amount);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "CVaultETHLP: invalid treasury address");
        treasury = newTreasury;
    }

    function setRelayerCost(uint newValue) external onlyOwner {
        relayerCost = newValue;
    }

    function setMinimumDepositValue(uint newValue) external onlyOwner {
        require(newValue > 0, "CVaultETHLP: minimum deposit value is zero");
        minimumDepositValue = newValue;
    }

    function updateLiquidationCollateralRatio(uint newCollateralRatio) external onlyOwner {
        require(newCollateralRatio < COLLATERAL_RATIO_MIN, "CVaultETHLP: liquidation collateral ratio must be lower than COLLATERAL_RATIO_MIN");
        liquidationCollateralRatio = newCollateralRatio;
    }

    function clearBSCState(address lp, address _account) external onlyOwner {
        require(stateOf(lp, _account) == State.Idle, "CVaultETHLP: account should be idle state");

        uint eventId = relayer.requestRelayOnETH(lp, _account, SIG_CLEAR, 0, 0, 0);
        emit ClearBSCState(lp, _account, eventId);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function validateRequest(uint8 signature, address _lp, address _account, uint128 _leverage, uint _collateral) external override view returns (uint8 validation, uint112 nonce) {
        Account memory account = accountOf(_lp, _account);
        bool isValid = false;
        if (signature == SIG_DEPOSIT) {
            isValid =
            account.state == State.Depositing
            && account.collateral > 0
            && account.collateral == _collateral
            && account.leverage == _leverage
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_LEVERAGE) {
            isValid =
            account.state == State.UpdatingLeverage
            && account.collateral > 0
            && account.collateral == _collateral
            && account.leverage == _leverage
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_WITHDRAW) {
            isValid =
            account.state == State.Withdrawing
            && account.collateral > 0
            && account.leverage == 0
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_EMERGENCY) {
            isValid =
            account.state == State.EmergencyExited
            && account.collateral == 0
            && account.leverage == 0;
        }
        else if (signature == SIG_LIQUIDATE) {
            isValid =
            account.state == State.Liquidating
            && account.liquidator != address(0);
        }
        else if (signature == SIG_CLEAR) {
            isValid = account.state == State.Idle && account.collateral == 0;
        }

        validation = isValid ? uint8(1) : uint8(0);
        nonce = account.nonce;
    }

    function canLiquidate(address lp, address _account) public override view returns (bool) {
        Account memory account = accountOf(lp, _account);
        return account.state == State.Farming && collateralRatioOf(lp, _account) < liquidationCollateralRatio;
    }

    function collateralRatioOf(address lp, address _account) public view returns (uint) {
        Account memory account = accountOf(lp, _account);
        return relayer.collateralRatioOnETH(lp, account.collateral, bscFlipOf(lp), account.bscFlipBalance, account.bscBNBDebt);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(address lp, uint amount, uint128 leverage) external notPaused notPausedPool(lp) validLeverage(leverage) onlyWhitelisted payable costs {
        require(relayer.isUtilizable(lp, amount, leverage), "CVaultETHLP: not enough balance to loan in the bank");
        require(relayer.valueOfAsset(lp, amount) >= minimumDepositValue, "CVaultETHLP: less than minimum deposit");

        convertState(lp, msg.sender, State.Depositing);

        uint collateral = _addCollateral(lp, msg.sender, amount);
        setLeverage(lp, msg.sender, leverage);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_DEPOSIT, leverage, collateral, amount);
        emit DepositRequested(lp, msg.sender, eventId, amount, leverage);
    }

    function updateLeverage(address lp, uint128 leverage) external notPaused notPausedPool(lp) validLeverage(leverage) payable costs {
        convertState(lp, msg.sender, State.UpdatingLeverage);
        Account memory account = accountOf(lp, msg.sender);
        uint leverageDiff = Math.max(account.leverage, leverage).sub(Math.min(account.leverage, leverage));

        setLeverage(lp, msg.sender, leverage);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_LEVERAGE, leverage, account.collateral, account.collateral.mul(leverageDiff).div(UNIT));
        emit UpdateLeverageRequested(lp, msg.sender, eventId, leverage, accountOf(lp, msg.sender).collateral);
    }

    function withdraw(address lp, uint amount) external payable costs {
        convertState(lp, msg.sender, State.UpdatingLeverage);

        Account memory account = accountOf(lp, msg.sender);
        uint targetCollateral = account.collateral.sub(amount);
        uint leverage = uint(account.leverage).mul(targetCollateral).div(account.collateral);
        require(LEVERAGE_MIN <= leverage && leverage <= LEVERAGE_MAX, "CVaultETHLP: leverage range should be [10%-150%]");

        setLeverage(lp, msg.sender, uint128(leverage));
        setWithdrawalRequestAmount(lp, msg.sender, amount);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_LEVERAGE, uint128(leverage), account.collateral, amount);
        emit UpdateLeverageRequested(lp, msg.sender, eventId, leverage, accountOf(lp, msg.sender).collateral);
        emit WithdrawRequested(lp, msg.sender, eventId, amount);
    }

    function withdrawAll(address lp) external payable costs {
        convertState(lp, msg.sender, State.Withdrawing);
        setLeverage(lp, msg.sender, 0);

        Account memory account = accountOf(lp, msg.sender);
        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_WITHDRAW, account.leverage, account.collateral, account.collateral);
        emit WithdrawAllRequested(lp, msg.sender, eventId);
    }

    function claimUnpaidETH(uint value) external hasEnoughBalance(value) {
        decreaseUnpaidETHValue(msg.sender, value);
        payable(msg.sender).transfer(value);
        emit UnpaidProfitClaimed(msg.sender, value);
    }

    function emergencyExit(address lp) external {
        convertState(lp, msg.sender, State.EmergencyExited);
        setLeverage(lp, msg.sender, 0);

        Account memory account = accountOf(lp, msg.sender);
        _removeCollateral(lp, msg.sender, account.collateral);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_EMERGENCY, 0, account.collateral, account.collateral);
        emit EmergencyExitRequested(lp, msg.sender, eventId, account.collateral);
    }

    function addCollateral(address lp, uint amount) external onlyStateFarming(lp) {
        _addCollateral(lp, msg.sender, amount);
        emit CollateralAdded(lp, msg.sender, amount);
    }

    function removeCollateral(address lp, uint amount) external onlyStateFarming(lp) canRemoveCollateral(lp, msg.sender, amount) {
        _removeCollateral(lp, msg.sender, amount);
        emit CollateralRemoved(lp, msg.sender, amount);
    }

    function askLiquidation(address lp, address account) external payable costs {
        relayer.askLiquidationFromCVaultETH(lp, account, msg.sender);
    }

    function executeLiquidation(address lp, address _account, address _liquidator) external override onlyCVaultRelayer {
        if (!canLiquidate(lp, _account)) return;

        setLiquidator(lp, _account, _liquidator);
        convertState(lp, _account, State.Liquidating);

        Account memory account = accountOf(lp, _account);
        uint eventId = relayer.requestRelayOnETH(lp, _account, SIG_LIQUIDATE, account.leverage, account.collateral, account.collateral);
        emit LiquidateRequested(lp, _account, eventId, account.collateral, _liquidator);
    }

    /* ========== RELAYER FUNCTIONS ========== */

    function notifyDeposited(address lp, address _account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        _notifyDeposited(lp, _account, bscBNBDebt, bscFlipBalance);
        emit NotifyDeposited(lp, _account, eventId, bscBNBDebt, bscFlipBalance);
    }

    function notifyUpdatedLeverage(address lp, address _account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        _notifyDeposited(lp, _account, bscBNBDebt, bscFlipBalance);
        emit NotifyUpdatedLeverage(lp, _account, eventId, bscBNBDebt, bscFlipBalance);

        uint withdrawalRequestAmount = accountOf(lp, _account).withdrawalRequestAmount;
        if (withdrawalRequestAmount > 0) {
            setWithdrawalRequestAmount(lp, _account, 0);
            _removeCollateral(lp, _account, withdrawalRequestAmount);
            emit CollateralRemoved(lp, _account, withdrawalRequestAmount);
        }
    }

    function notifyWithdrawnAll(address lp, address _account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.Withdrawing, "CVaultETHLP: state not Withdrawing");
        if (ethLoss > 0) {
            _repayLoss(lp, _account, eventId, ethLoss);
        }

        uint lpAmount = accountOf(lp, _account).collateral;
        _removeCollateral(lp, _account, lpAmount);

        if (ethProfit > 0) {
            _payProfit(_account, ethProfit);
        }

        convertState(lp, _account, State.Idle);
        emit NotifyWithdrawnAll(lp, _account, eventId, lpAmount, ethProfit, ethLoss);
    }

    function notifyLiquidated(address lp, address _account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.Liquidating, "CVaultETHLP: state not Liquidating");
        if (ethLoss > 0) {
            _repayLoss(lp, _account, eventId, ethLoss);
        }

        Account memory account = accountOf(lp, _account);
        address liquidator = account.liquidator;

        uint penalty = account.collateral.mul(LIQUIDATION_PENALTY).div(UNIT);
        _payLiquidationPenalty(lp, _account, penalty, account.liquidator);
        _removeCollateral(lp, _account, account.collateral.sub(penalty));

        if (ethProfit > 0) {
            _payProfit(_account, ethProfit);
        }
        convertState(lp, _account, State.Idle);
        emit NotifyLiquidated(lp, _account, eventId, ethProfit, ethLoss, penalty, liquidator);
    }

    function notifyResolvedEmergency(address lp, address _account, uint128 eventId, uint112 nonce) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.EmergencyExited, "CVaultETHLP: state not EmergencyExited");
        convertState(lp, _account, State.Idle);

        emit NotifyResolvedEmergency(lp, _account, eventId);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addCollateral(address lp, address _account, uint amount) private returns (uint collateral) {
        IERC20(lp).transferFrom(_account, address(this), amount);
        collateral = increaseCollateral(lp, _account, amount);
    }

    function _removeCollateral(address lp, address _account, uint amount) private returns (uint collateral) {
        collateral = decreaseCollateral(lp, _account, amount);

        uint _fee = withdrawalFee(lp, _account, amount);
        if (_fee > 0) {
            _zapOutAll(lp, _fee);
        }
        IERC20(lp).safeTransfer(_account, amount.sub(_fee));
    }

    function _notifyDeposited(address lp, address _account, uint bscBNBDebt, uint bscFlipBalance) private {
        convertState(lp, _account, State.Farming);

        setBSCBNBDebt(lp, _account, bscBNBDebt);
        setBSCFlipBalance(lp, _account, bscFlipBalance);
    }

    function _payProfit(address _account, uint value) private {
        uint transfer;
        uint balance = address(this).balance;
        if (balance >= value) {
            transfer = value;
        } else {
            transfer = balance;
            increaseUnpaidETHValue(_account, value.sub(balance));
        }

        if (transfer > 0) {
            payable(_account).transfer(transfer);
        }
    }

    function _repayLoss(address lp, address _account, uint128 eventId, uint value) private {
        if (unpaidETH(_account) >= value) {
            decreaseUnpaidETHValue(_account, value);
            return;
        }

        Account memory account = accountOf(lp, _account);
        uint price = relayer.priceOf(lp);
        uint amount = Math.min(value.mul(1e18).div(price).mul(1000).div(997), account.collateral);
        uint before = address(this).balance;
        _zapOutAll(lp, amount);
        uint soldValue = address(this).balance.sub(before);
        decreaseCollateral(lp, _account, amount);

        emit LossRealized(lp, _account, eventId, amount, soldValue);
    }

    function _payLiquidationPenalty(address lp, address _account, uint penalty, address liquidator) private {
        require(liquidator != address(0), "CVaultETHLP: liquidator should not be zero");
        decreaseCollateral(lp, _account, penalty);

        uint fee = penalty.mul(LIQUIDATION_FEE).div(UNIT);
        IERC20(lp).safeTransfer(treasury, fee);
        IERC20(lp).safeTransfer(liquidator, penalty.sub(fee));
    }

    function _zapOutAll(address lp, uint amount) private {
        zap.zapOut(lp, amount);

        address token0 = IUniswapV2Pair(lp).token0();
        address token1 = IUniswapV2Pair(lp).token1();
        if (token0 != WETH) {
            _approveZap(token0);
            zap.zapOut(token0, IERC20(token0).balanceOf(address(this)));
        }
        if (token1 != WETH) {
            _approveZap(token1);
            zap.zapOut(token1, IERC20(token1).balanceOf(address(this)));
        }
    }

    function _approveZap(address token) private {
        if (IERC20(token).allowance(address(this), address(zap)) == 0) {
            IERC20(token).safeApprove(address(zap), uint(-1));
        }
    }
}