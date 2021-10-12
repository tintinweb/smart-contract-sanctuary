//SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "SafeMath.sol";
import "IPancakeFactory.sol";
import "IPancakePair.sol";
import "IPancakeRouter.sol";
import "Holdable.sol";

library Utils {
    using SafeMath for uint256;
    
    //Pancake Swap
    function swapTokensForBnb(
        address routerAddress,
        uint256 tokenAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        //Make the swap.
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //Accept any amount of BNB.
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBnbForTokens(
        address routerAddress,
        address pathTo,
        address recipient,
        uint256 bnbAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(pathTo);

        //Make the swap.
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, //Accept any amount of BNB.
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
    function swapTokensForTokens(
        address routerAddress,
        address recipient,
        uint256 bnbAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb.
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        //Make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bnbAmount, //Wbnb input.
            0, //Accept any amount of BNB.
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
    function getAmountsOut(uint256 amount,
        address routerAddress
    ) public view returns(uint256 _amount) {
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb.
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        //Fetch current rate.
        uint[] memory amounts = pancakeRouter.getAmountsOut(amount,path);
        return amounts[1];
    }

    function addLiquidity(
        address routerAddress,
        uint256 tokenAmount,
        uint256 bnbAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Add the liquidity.
        pancakeRouter.addLiquidityETH{value : bnbAmount}(
            address(this),
            tokenAmount,
            0, //Slippage is unavoidable.
            0, //Slippage is unavoidable.
            address(this), // <- The liquidity is send to the contract itself.
            block.timestamp + 360
        );
    }
}