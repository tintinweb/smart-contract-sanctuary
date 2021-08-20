// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SwapInterfaces.sol";
import "./MinorityShared.sol";


/**
 * Manages the process of swapping and adding liquidity for the Minority token
 * Owner is the token contract 
 */
contract MinorityLiquidityManager is Ownable, MinorityShared {
    using SafeMath for uint256;
    
    IERC20 public immutable minorityToken;
    IERC20 public immutable usdcToken;
    ISwapRouter02 public immutable swapRouter;
    
    bool private inSwapAndLiquify;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        minorityToken = IERC20(msg.sender);
        usdcToken = IERC20(USDC);
        swapRouter = ISwapRouter02 (ROUTER);
    }
    
    function getInSwapAndLiquify() external view onlyOwner returns (bool) {
        return inSwapAndLiquify;
    }

    function swapAndLiquify (uint256 contractTokenBalance) external lockTheSwap onlyOwner returns (uint256, uint256, uint256) {
        require (contractTokenBalance > 0, "MinorityLiquidityManager: No tokens to swap");
        // split the contract balance into halves, swap half for USDC then add liquidity
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 usdcCreated = swapTokensForUSDC(half); 
        (uint256 tokensAdded, uint256 usdcAdded, uint256 lpTokensCreated) = addLiquidity (otherHalf, usdcCreated);
        return (tokensAdded, usdcAdded, lpTokensCreated);
    }

    function swapTokensForUSDC (uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = IERC20(USDC).balanceOf(address(this));
        
        // generate the swap pair path of Minority -> USDC
        address[] memory path = new address[](2);
        path[0] = address(minorityToken);
        path[1] = USDC;

        minorityToken.approve(address(swapRouter), tokenAmount);

        // make the swap
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDC
            path,
            address(this),
            block.timestamp
        );
        
        
        // Return how much USDC we created
        return usdcToken.balanceOf(address(this)).sub(initialBalance);
    }

    function addLiquidity (uint256 tokenAmount, uint256 usdcAmount) private returns (uint256, uint256, uint256) {
        // Approve transfer of Minority and USDC to router
        minorityToken.approve(address(swapRouter), tokenAmount);
        usdcToken.approve(address(swapRouter), usdcAmount);

        // add the liquidity
        (uint256 minorityTokenFromLiquidity, uint256 usdcFromLiquidity, uint256 liquidityAmount) = swapRouter.addLiquidity(
            address(minorityToken),
            USDC,
            tokenAmount,
            usdcAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
        return (minorityTokenFromLiquidity, usdcFromLiquidity, liquidityAmount);
    }
    
}