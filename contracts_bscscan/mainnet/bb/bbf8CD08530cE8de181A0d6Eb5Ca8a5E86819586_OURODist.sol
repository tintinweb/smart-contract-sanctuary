// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

contract OURODist is IOURODist, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    address public constant usdtContract = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    IOUROToken public constant ouroContract = IOUROToken(0x19D11637a7aaD4bB5D1dA500ec4A31087Ff17628);
    IOGSToken public constant ogsContract = IOGSToken(0x19F521235CaBAb5347B137f9D85e03D023Ccc76E);
    IPancakeRouter02 public constant router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address immutable internal WETH = router.WETH();
    uint256 constant internal swapDelay = 600;
    
    receive() external payable {}
    
    uint256 constant internal MAX_UINT256 = uint256(-1);

    constructor() public {
        // approve USDT
        IERC20(usdtContract).safeIncreaseAllowance(address(router), MAX_UINT256);
        
        // approve OGS
        IERC20(ogsContract).safeIncreaseAllowance(address(router), MAX_UINT256);
    }
     
    /** 
     * @dev reset allowance for special token
     */
    function resetAllowance(address token) external override onlyOwner {
       IERC20(token).safeApprove(address(router), 0); 
       IERC20(token).safeIncreaseAllowance(address(router), MAX_UINT256);
       
       // log
       emit ResetAllowance(token);
    }
    
    /**
     * @dev notify of revenue arrival
     */
    function revenueArrival(address token, uint256 revenueAmount) external override {
        // lazy approve
        if (IERC20(token).allowance(address(this), address(router)) == 0) {
            IERC20(token).safeIncreaseAllowance(address(router), MAX_UINT256);
        }
        
        // 50% - OGS token buy back and burn.
        uint256 revenueToBuyBackOGS = revenueAmount
                                    .mul(50)
                                    .div(100);
        _revenueToBuyBackOGS(token, revenueToBuyBackOGS);
        
        // 50% - Split to form LP tokens for the platform. 
        uint256 revenueToFormLP = revenueAmount.sub(revenueToBuyBackOGS);
        _revenueToFormLP(token, revenueToFormLP);
        
        // log
        emit RevenuArrival(token, revenueAmount);
    }
    
    /**
     * @dev revenue to buy back OGS
     */
    function _revenueToBuyBackOGS(address token, uint256 assetAmount) internal {
       // buy back OGS
       address[] memory path;
       if (token == usdtContract) {
           path = new address[](2);
           path[0] = token;
           path[1] = address(ogsContract);
       } else {
           path = new address[](3);
           path[0] = token;
           path[1] = usdtContract; // use USDT to bridge
           path[2] = address(ogsContract);
       }

        // swap & burn
        if (assetAmount > 0) {
            uint [] memory amounts;
            // the path to swap OGS out
            // path:
            // exact collateral -> USDT -> OGS
            if (token == WETH) {
                // swap OGS out with native assets to THIS contract
                amounts = router.swapExactETHForTokens{value:assetAmount}(
                   0, 
                   path, 
                   address(this), 
                   block.timestamp.add(600)
                );
               
            } else {
               // swap OGS out to THIS contract
                amounts = router.swapExactTokensForTokens(
                   assetAmount, 
                   0,
                   path, 
                   address(this), 
                   block.timestamp.add(600)
               );
            }
    
            // burn OGS the actual swapped out
            ogsContract.burn(amounts[amounts.length - 1]);
           
            // log
            emit OGSBurned(amounts[amounts.length - 1]);
        }
    }

     /**
     * @dev revenue to form LP token
     */
    function _revenueToFormLP(address token, uint256 assetAmount) internal {
       // buy back OGS
       address[] memory path;
       if (token == usdtContract) {
           path = new address[](2);
           path[0] = token;
           path[1] = address(ogsContract);
       } else {
           path = new address[](3);
           path[0] = token;
           path[1] = usdtContract; // use USDT to bridge
           path[2] = address(ogsContract);
       }
       
       // half of the asset to buy OGS
       uint256 assetToBuyOGS = assetAmount.div(2);
  
        // swap & burn
        if (assetToBuyOGS > 0) {         
           // the path to swap OGS out
            if (token == WETH) {
                router.swapExactETHForTokens{value:assetToBuyOGS}(
                   0, 
                   path, 
                   address(this), 
                   block.timestamp.add(swapDelay)
                );
               
            } else {
                router.swapExactTokensForTokens(
                   assetToBuyOGS, 
                   0, 
                   path, 
                   address(this), 
                   block.timestamp.add(swapDelay)
                );
            }
        }

       // the rest revenue will be used to buy USDT
       if (token != usdtContract) {
           path = new address[](2);
           path[0] = token;
           path[1] = usdtContract; 
           
           // half of the asset to buy USDT
           uint256 assetToBuyUSDT = assetAmount.sub(assetToBuyOGS);
           
           if (assetAmount > 0) {
                // the path to swap USDT out
                // path:
                //  collateral -> USDT
                if (token == WETH) {
                    router.swapExactETHForTokens{value:assetToBuyUSDT}(
                       0, 
                       path, 
                       address(this), 
                       block.timestamp.add(swapDelay)
                    );
                   
                } else {
                    router.swapExactTokensForTokens(
                       assetToBuyUSDT, 
                       0, 
                       path, 
                       address(this), 
                       block.timestamp.add(swapDelay)
                    );
                }
           }
        }
        
       // add liquidity to router
       // note we always use the maximum possible 
       uint256 token0Amt = IERC20(ogsContract).balanceOf(address(this));
       uint256 token1Amt = IERC20(usdtContract).balanceOf(address(this));
       
       if (token0Amt > 0 && token1Amt > 0) {
           (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
               address(ogsContract),
               usdtContract,
               token0Amt,
               token1Amt,
               0,
               0,
               address(this),
               block.timestamp.add(swapDelay)
           );
           
           // log
           emit LiquidityAdded(amountA, amountB, liquidity);
       }
    }
    
    /**
     * ======================================================================================
     * 
     * OURO Distribution events
     *
     * ======================================================================================
     */
     event ResetAllowance(address token);
     event RevenuArrival(address token, uint256 amount);
     event OGSBurned(uint ogsAmount);
     event LiquidityAdded(uint ogsAmount, uint usdtAmount, uint liquidity);
}