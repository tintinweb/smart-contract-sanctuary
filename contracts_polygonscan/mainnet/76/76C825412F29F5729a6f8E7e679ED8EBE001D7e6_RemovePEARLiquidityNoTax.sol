// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";


// RemoveLiquidityHelper, allows anyone to remove Pear liquidity tax free
contract RemovePEARLiquidityNoTax is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for ERC20;

    address public pearAddress;

    IUniswapV2Router02 public immutable pearSwapRouter; // Router
    address public pearSwapPair; // Main Pair

    // To receive ETH when swapping
    receive() external payable {}

    event SetPearAddresses(address pearAddress, address pearSwapPair);
    event Pause();
    event Unpause();    

    /**
     * @notice Constructs the AddLiquidityHelper contract.
     */
    constructor(address _router) public  {
        require(_router != address(0), "_router is the zero address");
        pearSwapRouter = IUniswapV2Router02(_router);
    }

    function removePearLiquidity(address baseTokenAddress, uint256 liquidity) external nonReentrant whenNotPaused {
        address lpTokenAddress = IUniswapV2Factory(pearSwapRouter.factory()).getPair(baseTokenAddress, pearAddress);
        require(lpTokenAddress != address(0), "pair hasn't been created yet, so can't remove liquidity!");

        ERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), liquidity);
        // approve token transfer to cover all possible scenarios
        ERC20(lpTokenAddress).approve(address(pearSwapRouter), liquidity);

        // remove the liquidity from LP to this contract
        pearSwapRouter.removeLiquidity(
            baseTokenAddress,
            pearAddress,
            liquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        
        if (ERC20(baseTokenAddress).balanceOf(address(this)) > 0)
            ERC20(baseTokenAddress).safeTransfer(msg.sender, ERC20(baseTokenAddress).balanceOf(address(this)));

        if (ERC20(pearAddress).balanceOf(address(this)) > 0)
            ERC20(pearAddress).transfer(msg.sender, ERC20(pearAddress).balanceOf(address(this)));        
        
    }

    /**
     * @dev set the pear address.
     * Can only be called once by the current owner.
     */
    function setPearAddress(address _pearAddress) external onlyOwner {
        require(_pearAddress != address(0), "_pearAddress is the zero address");
        require(pearAddress == address(0), "pearAddress already set!");

        pearAddress = _pearAddress;

        pearSwapPair = IUniswapV2Factory(pearSwapRouter.factory()).getPair(pearAddress, pearSwapRouter.WETH());

        require(address(pearSwapPair) != address(0), "matic pair !exist");

        emit SetPearAddresses(pearAddress, pearSwapPair);
    }
    
    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }    
}