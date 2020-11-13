// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "@openzeppelin/contracts/access/roles/SignerRole.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../imports/Curve.sol";
import "../../IRewards.sol";

contract CurveLPWithdrawer is SignerRole {
    function curveWithdraw2(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[2] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdraw3(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[3] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdraw4(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[4] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdraw5(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[5] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdrawOneCoin(
        address lpTokenAddress,
        address curvePoolAddress,
        int128 coinIndex,
        uint256 minAmount
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        Zap curvePool = Zap(curvePoolAddress);
        curvePool.remove_liquidity_one_coin(
            lpTokenBalance,
            coinIndex,
            minAmount
        );
    }
}
