/**
 *Submitted for verification at Etherscan.io on 2021-02-18
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

contract SynthetixAMM  {
    using SafeERC20 for IERC20;
    
    address public governance;
    address public pendingGovernance;
    
    mapping(address => address) synths;
    
    IKeep3rV1Quote public constant exchange = IKeep3rV1Quote(0xDd6eb7F03F8cd9b5C9565172E37C0Bb98D67E078);
    
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
    
    function addSynth(address synth, address token) external {
        require(msg.sender == governance);
        synths[synth] = token;
    }
    
    function quote(address synthIn, uint amountIn, address synthOut) public view returns (uint amountOut) {
        address _tokenOut = synths[synthOut];
        address _tokenIn = synths[synthIn];
        (IKeep3rV1Quote.QuoteParams memory q,) = exchange.assetToAsset(_tokenIn, amountIn * 10 ** IERC20(_tokenIn).decimals() / 10 ** 18, _tokenOut, 2);
        amountOut = q.quoteOut * 10 ** 18 / 10 ** IERC20(_tokenOut).decimals();
        require(amountOut <= IERC20(synthOut).balanceOf(address(this)), "SynthetixAMM: Insufficient liquidity for trade");
        return amountOut;
    }
    
    function swap(address synthIn, uint amountIn, address synthOut, uint minOut, address recipient) external returns (uint) {
        uint quoteOut = quote(synthIn, amountIn, synthOut);
        require(quoteOut >= minOut, "SynthetixAMM: Quote less than mininum output");
        IERC20(synthIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(synthOut).safeTransfer(recipient, quoteOut);
        emit Swap(msg.sender, amountIn, 0, 0, quoteOut, recipient);
        return quoteOut;
    }
}