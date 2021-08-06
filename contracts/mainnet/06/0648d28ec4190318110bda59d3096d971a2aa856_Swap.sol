// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";

interface TokenInterface is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract Swap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for TokenInterface;

    uint256 private feePercent;
    TokenInterface private _weth;

    event SetFeePercent(uint256 oldFeePercent, uint256 newFeePercent);
    event OrderSwap(
        uint256 orderId,
        address userAddress,
        address baseToken,
        address quoteToken,
        uint256 swapAmount,
        uint256 outAmount,
        uint256 feeAmount
    );

    struct Pair {
        address pair;
        address tokenIn;
        address tokenOut;
        bool isReserveIn;
    }

    struct Rooter {
        uint256 orderId;
        address userAddress;
        uint256 inputAmount;
        Pair[] pairList;
    }

    constructor() {
        _weth = TokenInterface(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
        feePercent = 250; // 2.5%
    }

    receive() external payable {}

    function getFeePercent() public view returns (uint256) {
        return feePercent;
    }

    function setFeePercent(uint256 newFeePercent) external onlyOwner {
        uint256 oldFeePercent = feePercent;
        feePercent = newFeePercent;

        emit SetFeePercent(oldFeePercent, newFeePercent);
    }

    function getFeeAmount(address tokenAddress) public view returns (uint256) {
        TokenInterface withdrawToken = TokenInterface(tokenAddress);
        uint256 feeAmount = withdrawToken.balanceOf(address(this));

        return feeAmount;
    }

    function adminWithdraw(address tokenAddress, address withdrawAddress) external onlyOwner {
        TokenInterface withdrawToken = TokenInterface(tokenAddress);
        uint256 withdrawAmount = withdrawToken.balanceOf(address(this));

        if (withdrawAmount > 0) {
            if (tokenAddress == address(_weth)) {
                _weth.withdraw(withdrawAmount);
                (bool sent, ) = withdrawAddress.call{value: withdrawAmount}("");
                require(sent, "Invalid withdraw ETH");
            } else {
                withdrawToken.safeTransfer(withdrawAddress, withdrawAmount);
            }            
        }
    }

    function _getAmountOut(
        bool isReserveIn,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        (reserveIn, reserveOut) = 
            isReserveIn ? (reserveIn, reserveOut) : (reserveOut, reserveIn);

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _uniswapV2Swap(
        uint256 inputAmount,    
        Pair memory pairInfo
    ) internal {
        // Get Pair
        IUniswapV2Pair pair = IUniswapV2Pair(pairInfo.pair);
        // Get Reserves
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 reserveInput = pairInfo.isReserveIn ? reserve0 : reserve1;

        // Token Transfer
        TokenInterface(pairInfo.tokenIn).safeTransfer(
            address(pairInfo.pair),
            inputAmount
        );
        inputAmount = TokenInterface(pairInfo.tokenIn).balanceOf(address(pairInfo.pair)).sub(reserveInput);

        // Get Output Amount
        uint256 outputAmount = _getAmountOut(
            pairInfo.isReserveIn,
            inputAmount,
            reserve0,
            reserve1
        );      

        (uint256 amount0Out, uint256 amount1Out) =
            pairInfo.isReserveIn
                ? (uint256(0), outputAmount)
                : (outputAmount, uint256(0));

        // Call Swap
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function _swapTokenToToken(
        uint256 amountIn,
        Pair memory pairInfo
    ) internal returns (uint256 outputAmount) {
        uint256 oldTokenOutAmount = TokenInterface(pairInfo.tokenOut).balanceOf(address(this));
        
        _uniswapV2Swap(amountIn, pairInfo);
        
        uint256 newTokenOutAmount = TokenInterface(pairInfo.tokenOut).balanceOf(address(this));
        outputAmount = newTokenOutAmount.sub(oldTokenOutAmount);
    }

    function orderSwap(
        Rooter memory orderRouter
    ) external {
        uint8 pairLength = uint8(orderRouter.pairList.length);

        TokenInterface baseToken = TokenInterface(orderRouter.pairList[0].tokenIn);
        TokenInterface quoteToken = TokenInterface(orderRouter.pairList[pairLength - 1].tokenOut);

        // Check Approve
        require(
            baseToken.allowance(orderRouter.userAddress, address(this)) >= orderRouter.inputAmount,
            "The approved amount should be more than swap amount"
        );

        uint256 oldBaseAmouont = baseToken.balanceOf(address(this));
        // TransferFrom User Address to Contract
        baseToken.safeTransferFrom(
            orderRouter.userAddress,
            address(this),
            orderRouter.inputAmount
        );
        uint256 newBaseAmount = baseToken.balanceOf(address(this));
        uint256 amountIn = newBaseAmount.sub(oldBaseAmouont);

        for (uint8 i = 0; i < pairLength; i += 1) {
            amountIn = _swapTokenToToken(
                amountIn,
                orderRouter.pairList[i]
            );
        }

        // Check Fee
        uint256 feeAmount = amountIn.mul(feePercent).div(10000);
        uint256 userAmount = amountIn.sub(feeAmount);

        // Transfer To User
        quoteToken.safeTransfer(orderRouter.userAddress, userAmount);

        // Emit the event
        emit OrderSwap(
            orderRouter.orderId,
            orderRouter.userAddress,            
            address(baseToken),
            address(quoteToken),
            orderRouter.inputAmount,
            userAmount,
            feeAmount
        );
    }
}