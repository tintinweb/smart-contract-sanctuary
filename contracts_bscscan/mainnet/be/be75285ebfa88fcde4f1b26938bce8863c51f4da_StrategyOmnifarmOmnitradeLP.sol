// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IUniswap.sol";
import "./StratManager.sol";
import "./FeeManager.sol";
import "./GasThrottler.sol";
import "./IOmnitradeCurve.sol";
import "./IOmnifarmFarm.sol";

contract StrategyOmnifarmOmnitradeLP is StratManager, FeeManager, GasThrottler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public native;
    address public output;
    address public want;
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public pool;

    bool public harvestOnDeposit;
    uint256 public lastHarvest;

    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester);

    constructor(
        address _want,
        address _pool,
        address _vault,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _platformFeeRecipient,
        address _gasPrice,
        address[] memory _outputToNativeRoute,
        address[] memory _outputToLp0Route,
        address[] memory _outputToLp1Route
    ) public StratManager(_keeper, _strategist, _unirouter, _vault, _platformFeeRecipient) GasThrottler(_gasPrice) {
        want = _want;
        pool = _pool;

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        // lpToken0 = IUniswapV2Pair(want).token0();
        lpToken0 = IOmnitradeCurve(want).numeraires(0);
        require(_outputToLp0Route[0] == output, "outputToLp0Route[0] != output");
        require(_outputToLp0Route[_outputToLp0Route.length - 1] == lpToken0, "outputToLp0Route[last] != lpToken0");
        outputToLp0Route = _outputToLp0Route;

        // lpToken1 = IUniswapV2Pair(want).token1();
        lpToken1 = IOmnitradeCurve(want).numeraires(1);
        require(_outputToLp1Route[0] == output, "outputToLp1Route[0] != output");
        require(_outputToLp1Route[_outputToLp1Route.length - 1] == lpToken1, "outputToLp1Route[last] != lpToken1");
        outputToLp1Route = _outputToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IOmnifarmFarm(pool).deposit(wantBal);
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IOmnifarmFarm(pool).withdraw(_amount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        // solhint-disable-next-line
        if (tx.origin == owner() || paused()) {
            IERC20(want).safeTransfer(vault, wantBal);
        } else {
            uint256 withdrawalFeeAmount = wantBal.mul(withdrawalFee).div(MAX_FEE);
            IERC20(want).safeTransfer(vault, wantBal.sub(withdrawalFeeAmount));
        }
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest();
        }
    }

    function harvest() external virtual whenNotPaused onlyEOA gasThrottle {
        _harvest();
    }

    function managerHarvest() external onlyManager {
        _harvest();
    }

    // compounds earnings and charges performance fee
    function _harvest() internal {
        IOmnifarmFarm(pool).deposit(0);
        chargeFees();
        addLiquidity();
        deposit();

        lastHarvest = block.timestamp;
        emit StratHarvest(msg.sender);
    }

    // performance fees
    function chargeFees() internal {
        uint256 toNative = IERC20(output).balanceOf(address(this)).mul(totalHarvestFee).div(MAX_FEE);
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(toNative, 0, outputToNativeRoute, address(this), now);

        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        uint256 callFeeAmount = nativeBal.mul(callFee).div(MAX_FEE);
        // solhint-disable-next-line
        IERC20(native).safeTransfer(tx.origin, callFeeAmount);

        uint256 platformFeeAmount = nativeBal.mul(platformFee()).div(MAX_FEE);
        IERC20(native).safeTransfer(platformFeeRecipient, platformFeeAmount);

        uint256 strategistFeeAmount = nativeBal.mul(strategistFee).div(MAX_FEE);
        IERC20(native).safeTransfer(strategist, strategistFeeAmount);
    }

    // // Adds liquidity to AMM and gets more LP tokens.
    // function addLiquidity() internal {
    //     uint256 outputHalf = IERC20(output).balanceOf(address(this)).div(2);

    //     if (lpToken0 != output) {
    //         IUniswapRouterETH(unirouter).swapExactTokensForTokens(outputHalf, 0, outputToLp0Route, address(this), now);
    //     }

    //     if (lpToken1 != output) {
    //         IUniswapRouterETH(unirouter).swapExactTokensForTokens(outputHalf, 0, outputToLp1Route, address(this), now);
    //     }

    //     uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
    //     uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
    //     IUniswapRouterETH(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), now);
    // }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputBalance = IERC20(output).balanceOf(address(this));
        uint256 maxDeposit = 1e36;
        (, uint256[] memory shares) = IOmnitradeCurve(want).viewDeposit(maxDeposit);
        uint256 output0share = (outputBalance * shares[0]) / (shares[0] + shares[1]);
        uint256 output1share = (outputBalance * shares[1]) / (shares[0] + shares[1]);
        if (lpToken0 != output) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                output0share,
                0,
                outputToLp0Route,
                address(this),
                now
            );
        }
        if (lpToken1 != output) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                output1share,
                0,
                outputToLp1Route,
                address(this),
                now
            );
        }
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        uint256 deposit0 = (lp0Bal * maxDeposit) / shares[0];
        uint256 deposit1 = (lp1Bal * maxDeposit) / shares[1];
        uint256 _deposit = deposit0 < deposit1 ? deposit0 : deposit1;
        IOmnitradeCurve(want).deposit(_deposit, now + 1);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IOmnifarmFarm(pool).userInfo(address(this));
        return _amount;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;

        if (harvestOnDeposit == true) {
            super.setWithdrawalFee(0);
        } else {
            super.setWithdrawalFee(10);
        }
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        IOmnifarmFarm(pool).emergencyWithdraw();

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IOmnifarmFarm(pool).emergencyWithdraw();
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(pool, uint256(-1));
        IERC20(output).safeApprove(unirouter, uint256(-1));
        IERC20(lpToken0).safeApprove(want, 0);
        IERC20(lpToken0).safeApprove(want, uint256(-1));
        IERC20(lpToken1).safeApprove(want, 0);
        IERC20(lpToken1).safeApprove(want, uint256(-1));
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(pool, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(want, 0);
        IERC20(lpToken1).safeApprove(want, 0);
    }

    function outputToNative() external view returns (address[] memory) {
        return outputToNativeRoute;
    }

    function outputToLp0() external view returns (address[] memory) {
        return outputToLp0Route;
    }

    function outputToLp1() external view returns (address[] memory) {
        return outputToLp1Route;
    }
}