// SPDX-License-Identifier: MIT

//TODO add the possibilty of a pausable contract to avoid abuse during test or simply remove the contract from tax whitelisting...
//TODO test first with tax then whitelist

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";


// AddLiquidityHelper, allows anyone to add or remove Pear liquidity tax free
// Also allows the Pear Token to do buy backs tax free via an external contract. // TODO Needed ? could be interesting...
contract AddLiquidityHelper is ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;

    address public pearAddress;

    IUniswapV2Router02 public immutable pearSwapRouter; // TODO Define to external DEX for test and own PZ DEX after
    // The trading pair
    address public pearSwapPair; 

    // To receive ETH when swapping
    receive() external payable {}

    event SetPearAddresses(address pearAddress, address pearSwapPair);

    /**
     * @notice Constructs the AddLiquidityHelper contract.
     */
    constructor(address _router) public  {
        require(_router != address(0), "_router is the zero address");
        pearSwapRouter = IUniswapV2Router02(_router);
    }

    //TODO Clean up needed because PEAR token can't call this contract
    /*function pearETHLiquidityWithBuyBack(address lpHolder) external payable nonReentrant {
        require(msg.sender == pearAddress, "can only be used by the pear token!");

        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(pearSwapPair).getReserves();

        if (res0 != 0 && res1 != 0) {
            // making weth res0
            if (IUniswapV2Pair(pearSwapPair).token0() == pearAddress)
                (res1, res0) = (res0, res1);

            uint256 contractTokenBalance = ERC20(pearAddress).balanceOf(address(this));

            // calculate how much eth is needed to use all of contractTokenBalance
            // also boost precision a tad.
            uint256 totalETHNeeded = (res0 * contractTokenBalance) / res1;

            uint256 existingETH = address(this).balance;

            uint256 unmatchedPear = 0;

            if (existingETH < totalETHNeeded) {
                // calculate how much pear will match up with our existing eth.
                uint256 matchedPear = (res1 * existingETH) / res0;
                if (contractTokenBalance >= matchedPear)
                    unmatchedPear = contractTokenBalance - matchedPear;
            } else if (existingETH > totalETHNeeded) {
                // use excess eth for pear buy back
                uint256 excessETH = existingETH - totalETHNeeded;

                if (excessETH / 2 > 0) {
                    // swap half of the excess eth for lp to be balanced
                    swapETHForTokens(excessETH / 2, pearAddress);
                }
            }

            uint256 unmatchedPearToSwap = unmatchedPear / 2;

            // swap tokens for ETH
            if (unmatchedPearToSwap > 0)
                swapTokensForEth(pearAddress, unmatchedPearToSwap);

            uint256 pearBalance = ERC20(pearAddress).balanceOf(address(this));

            // approve token transfer to cover all possible scenarios
            ERC20(pearAddress).approve(address(pearSwapRouter), pearBalance);

            // add the liquidity
            pearSwapRouter.addLiquidityETH{value: address(this).balance}(
                pearAddress,
                pearBalance,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                lpHolder,
                block.timestamp
            );

        }

        if (address(this).balance > 0) {
            // not going to require/check return value of this transfer as reverting behaviour is undesirable.
            payable(address(msg.sender)).call{value: address(this).balance}("");
        }

        if (ERC20(pearAddress).balanceOf(address(this)) > 0)
            ERC20(pearAddress).transfer(msg.sender, ERC20(pearAddress).balanceOf(address(this)));
    }*/

    function addPearETHLiquidity(uint256 nativeAmount) external payable nonReentrant {
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
            address(this), //TODO strange... how the user get the lp back to his address ? addLiquidityETH send back only to msg.sender? Need test
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
    function addPearLiquidity(address baseTokenAddress, uint256 baseAmount, uint256 nativeAmount) external nonReentrant {
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

    function removePearLiquidity(address baseTokenAddress, uint256 liquidity) external nonReentrant {
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

/* TODO not needed anymore
    /// @dev Swap tokens for eth
    function swapTokensForEth(address saleTokenAddress, uint256 tokenAmount) internal {
        // generate the pearSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = saleTokenAddress;
        path[1] = pearSwapRouter.WETH();

        ERC20(saleTokenAddress).approve(address(pearSwapRouter), tokenAmount);

        // make the swap
        pearSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapETHForTokens(uint256 ethAmount, address wantedTokenAddress) internal {
        require(address(this).balance >= ethAmount, "insufficient matic provided!");
        require(wantedTokenAddress != address(0), "wanted token address can't be the zero address!");

        // generate the pearSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pearSwapRouter.WETH();
        path[1] = wantedTokenAddress;

        // make the swap
        pearSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            // cannot send tokens to the token contract of the same type as the output token
            address(this),
            block.timestamp
        );
    }*/

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
}