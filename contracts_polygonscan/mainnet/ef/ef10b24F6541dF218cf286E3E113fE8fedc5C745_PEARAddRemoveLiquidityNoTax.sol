// SPDX-License-Identifier: MIT

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";


// AddLiquidityHelper, allows anyone to add or remove Pear liquidity tax free
contract PEARAddRemoveLiquidityNoTax is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for ERC20;

    address public pearAddress;

    IUniswapV2Router02 public immutable pearSwapRouter;
    // The trading pair
    address public pearSwapPair; 

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

    function addPearETHLiquidity(uint256 nativeAmount) external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "!sufficient funds");

        ERC20(pearAddress).safeTransferFrom(msg.sender, address(this), nativeAmount);

        // approve token transfer to cover all possible scenarios
        ERC20(pearAddress).approve(address(pearSwapRouter), nativeAmount);

        // add the liquidity
        pearSwapRouter.addLiquidityETH{value: msg.value}(
            pearAddress,
            nativeAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        if (address(this).balance > 0) { //TODO need test with large gas transfer to see if it's returned to user
            // not going to require/check return value of this transfer as reverting behaviour is undesirable.
            payable(address(msg.sender)).call{value: address(this).balance}("");
        }

        if (ERC20(pearAddress).balanceOf(address(this)) > 0) //TODO need test also to see if pear is returned to user
            ERC20(pearAddress).transfer(msg.sender, ERC20(pearAddress).balanceOf(address(this)));
    }

    //TODO need a test with WMATIC
    function addPearLiquidity(address baseTokenAddress, uint256 baseAmount, uint256 nativeAmount) external nonReentrant whenNotPaused {
        ERC20(baseTokenAddress).safeTransferFrom(msg.sender, address(this), baseAmount);
        ERC20(pearAddress).safeTransferFrom(msg.sender, address(this), nativeAmount);

        // approve token transfer to cover all possible scenarios
        ERC20(baseTokenAddress).approve(address(pearSwapRouter), baseAmount);
        ERC20(pearAddress).approve(address(pearSwapRouter), nativeAmount);

        // add the liquidity
        pearSwapRouter.addLiquidity(
            baseTokenAddress,
            pearAddress,
            baseAmount,
            nativeAmount ,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        if (ERC20(baseTokenAddress).balanceOf(address(this)) > 0)
            ERC20(baseTokenAddress).safeTransfer(msg.sender, ERC20(baseTokenAddress).balanceOf(address(this)));

        if (ERC20(pearAddress).balanceOf(address(this)) > 0)
            ERC20(pearAddress).transfer(msg.sender, ERC20(pearAddress).balanceOf(address(this)));
    }

    function removePearLiquidity(address baseTokenAddress, uint256 liquidity) external nonReentrant whenNotPaused {
        address lpTokenAddress = IUniswapV2Factory(pearSwapRouter.factory()).getPair(baseTokenAddress, pearAddress);
        require(lpTokenAddress != address(0), "pair hasn't been created yet, so can't remove liquidity!");

        ERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), liquidity);
        // approve token transfer to cover all possible scenarios
        ERC20(lpTokenAddress).approve(address(pearSwapRouter), liquidity);

        // remove the liquidity
        pearSwapRouter.removeLiquidity(
            baseTokenAddress,
            pearAddress,
            liquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
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