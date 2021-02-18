/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

interface IKeep3rV1Quote {
    struct LiquidityParams {
        uint sReserveA;
        uint sReserveB;
        uint uReserveA;
        uint uReserveB;
        uint sLiquidity;
        uint uLiquidity;
    }
    
    struct QuoteParams {
        uint quoteOut;
        uint amountOut;
        uint currentOut;
        uint sTWAP;
        uint uTWAP;
        uint sCUR;
        uint uCUR;
    }
    
    function assetToUsd(address tokenIn, uint amountIn, uint granularity) external returns (QuoteParams memory q, LiquidityParams memory l);
    function assetToEth(address tokenIn, uint amountIn, uint granularity) external view returns (QuoteParams memory q, LiquidityParams memory l);
    function ethToUsd(uint amountIn, uint granularity) external view returns (QuoteParams memory q, LiquidityParams memory l);
    function pairFor(address tokenA, address tokenB) external pure returns (address sPair, address uPair);
    function sPairFor(address tokenA, address tokenB) external pure returns (address sPair);
    function uPairFor(address tokenA, address tokenB) external pure returns (address uPair);
    function getLiquidity(address tokenA, address tokenB) external view returns (LiquidityParams memory l);
    function assetToAsset(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (QuoteParams memory q, LiquidityParams memory l);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract SynthetixExchange  {
    using SafeERC20 for IERC20;
    
    address public governance;
    address public pendingGovernance;
    
    mapping(address => address) synths;
    
    IKeep3rV1Quote public constant exchange = IKeep3rV1Quote(0xAa1D14BE4b3Fa42CbBF3C3f61c6F2c57fAF559DF);
    
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    
    constructor() {
        governance = msg.sender;
    }
    
    function setGovernance(address _gov) external {
        require(msg.sender == governance);
        pendingGovernance = _gov;
    } 
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }
    
    function withdraw(address token, uint amount) external {
        require(msg.sender == governance);
        IERC20(token).safeTransfer(governance, amount);
    }
    
    function withdrawAll(address token) external {
        require(msg.sender == governance);
        IERC20(token).safeTransfer(governance, IERC20(token).balanceOf(address(this)));
    }
    
    function addSynth(address token, address synth) external {
        require(msg.sender == governance);
        synths[token] = synth;
    }
    
    function quote(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        (IKeep3rV1Quote.QuoteParams memory q,) = exchange.assetToAsset(tokenIn, amountIn, tokenOut, 2);
        return q.quoteOut * 10 ** 18 / 10 ** IERC20(tokenOut).decimals();
    }
    
    function swap(address tokenIn, uint amountIn, address tokenOut, address recipient) external returns (uint) {
        (IKeep3rV1Quote.QuoteParams memory q,) = exchange.assetToAsset(tokenIn, amountIn, tokenOut, 2);
        IERC20(synths[tokenIn]).safeTransferFrom(msg.sender, address(this), amountIn * 10 ** 18 / 10 ** IERC20(tokenOut).decimals());
        IERC20(synths[tokenOut]).safeTransfer(recipient, q.quoteOut * 10 ** 18 / 10 ** IERC20(tokenOut).decimals());
        emit Swap(msg.sender, amountIn, 0, 0, q.quoteOut, recipient);
        return q.quoteOut;
    }
}