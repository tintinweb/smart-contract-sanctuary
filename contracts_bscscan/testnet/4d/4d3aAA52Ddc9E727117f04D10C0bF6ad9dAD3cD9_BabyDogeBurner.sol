// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SwapInterfaces.sol";
import "./Shared.sol";


/**
 * LP locker with claim and burn functionality 
 */
contract BabyDogeBurner is Ownable {
    IERC20 public babyDogeToken;
    
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c CHANGEME
    
    ISwapRouter02 public swapRouter;
    ISwapPair public swapPair;
    
    uint256 public totalBabyDogeBurned;
    
    constructor (address _token, address _lpToken) {
        babyDogeToken = IERC20 (_token);
        swapPair = ISwapPair (_lpToken);
        
        //0x10ED43C718714eb63d5aA57B78B54704E256024E <-- Mainnet PCS address
        //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 <-- Testnet kiemtienonline PCS address
        swapRouter = ISwapRouter02 (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // CHANGEME
    }
    
    receive() external payable {}
    
    function changeLPAndResetCounters (address _token, address _lpToken) external onlyOwner {
        babyDogeToken = IERC20 (_token);
        swapPair = ISwapPair (_lpToken);
        totalBabyDogeBurned = 0;
    }

    function unclaimedLP() public view returns (uint256) {
        return swapPair.balanceOf (address(this));
    }
    
    function unburnedBabyDoge() public view returns (uint256) {
        return babyDogeToken.balanceOf (address(this));
    }
    
    function babyDogeInBurnWallet() public view returns (uint256) {
        return babyDogeToken.balanceOf (address(BURN_ADDRESS));
    }
    
    function burnBabyDogeBurn (uint8 percentOfHoldingsToBurn) external onlyOwner {
        require (percentOfHoldingsToBurn <= 100, "Can't burn > 100% of tokens");
        uint256 babyDogeToBurn = (unburnedBabyDoge() * percentOfHoldingsToBurn) / 100;
        uint256 initialBurned = babyDogeInBurnWallet();
        
        if (babyDogeToken.transfer (BURN_ADDRESS, babyDogeToBurn)) {
            totalBabyDogeBurned += (babyDogeInBurnWallet() - initialBurned); // Track it like this as reflections may impact the totals
        }
    }

    function claim() external onlyOwner {
        // How much LP do we own?
        uint256 liquidityAmount = unclaimedLP();
        
        if (liquidityAmount > 0) {
            // Approve transfer of LP to router
            swapPair.approve (address(swapRouter), liquidityAmount);
            
            // Use removeLiquidity due to bugs with Pancake's removeLiquidityETH - we'll unwrap later
            (, uint256 bnbReturned) = swapRouter.removeLiquidity (
                address(babyDogeToken),
                WBNB,
                liquidityAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(this),
                block.timestamp + 30
            );
            
            if (bnbReturned > 0) {
                IWETH(WBNB).withdraw (bnbReturned); // Unwrap WBNB
                payable(owner()).transfer (bnbReturned); // Send BNB to owner
            }
        }
    }
    
}