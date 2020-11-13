// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-curve-base.sol";

contract StrategyCurveRenCRVv2 is StrategyCurveBase {
    // https://www.curve.fi/ren
    // Curve stuff
    address public ren_pool = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address public ren_gauge = 0xB1F2cdeC61db658F091671F5f199635aEF202CAC;
    address public ren_crv = 0x49849C98ae39Fff122806C06791Fa73784FB3675;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCurveBase(
            ren_pool,
            ren_gauge,
            ren_crv,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getMostPremium() public override view returns (address, uint256) {
        // Both 8 decimals, so doesn't matter
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_2(curve).balances(0); // RENBTC
        balances[1] = ICurveFi_2(curve).balances(1); // WBTC

        // renbtc
        if (balances[0] < balances[1]) {
            return (renbtc, 0);
        }

        // WBTC
        if (balances[1] < balances[0]) {
            return (wbtc, 1);
        }

        // If they're somehow equal, we just want RENBTC
        return (renbtc, 0);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyCurveRenCRVv2";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        // Collects crv tokens
        // Don't bother voting in v1
        ICurveMintr(mintr).mint(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }
            _crv = _crv.sub(_keepCRV);
            _swapUniswap(crv, to, _crv);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[2] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_2(curve).add_liquidity(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
