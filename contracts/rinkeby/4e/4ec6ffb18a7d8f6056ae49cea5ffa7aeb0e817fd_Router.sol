/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

interface IUniswapV3Router {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);


    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function refundETH() external payable;
}
 
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IQuoter {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);
}

contract Router {
    // ETH 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // rinkeby 0xc778417e063141139fce010982780140aa0cd5ab
    // bsc 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address public WETH;

    event ExactInput(address indexed sender, address indexed recipient, bytes indexed customId, uint256 amountIn, uint256 amountOut);
    event ExactOutput(address indexed sender, address indexed recipient, bytes indexed customId, uint256 amountIn, uint256 amountOut);


    constructor(address _WETH) {
        WETH = _WETH;
    }


    function getAmountsInV2(address source, uint amountOut, address[] calldata path) public view returns (uint256 amountIn){
        uint[] memory uniV2Ins = IUniswapV2Router(source).getAmountsIn(amountOut, path);
        return uniV2Ins[0];
    }

    function getAmountsOutV2(address source, uint amountIn, address[] calldata path) public view returns (uint256 amountOut){
        uint[] memory uniV2Outs = IUniswapV2Router(source).getAmountsOut(amountIn, path);
        return uniV2Outs[uniV2Outs.length - 1];
    }

    function getAmountsInV3(address source, uint amountOut, bytes memory path) public returns (uint256 amountIn){
        return IQuoter(source).quoteExactOutput(path, amountOut);
    }

    function getAmountsOutV3(address source, uint amountIn, bytes memory path) public returns (uint256 amountOut){
        return IQuoter(source).quoteExactInput(path, amountIn);
    }

    /**
     * 数据接口 quote
     */
    struct SwapInputParams {
        bytes customId;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;

        /**
         * 如果是 ETH 就直接0x000000..
         */
        address tokenIn;
        address tokenOut;

        address routerV2;
        address routerV3;
        address[] v2Path;
        bytes v3Path;
    }

    struct SwapOutputParams {
        bytes customId;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        
        /**
         * 如果是 ETH 就直接0x000000..
         */
        address tokenIn;
        address tokenOut;


        address routerV2;
        address routerV3;
        address[] v2Path;
        bytes v3Path;
    }


    function exactInput(SwapInputParams calldata params) external payable {
        uint256 amountIn = 0;
        uint256 amountOut = 0;

        // 收取代币 eth -> weth
        if (params.tokenIn == address(0)) {
            IWETH(WETH).deposit{value: msg.value}();
            amountIn = msg.value;
        }
        else {
            TransferHelper.safeTransferFrom(params.tokenIn, msg.sender, address(this), params.amountIn);
            amountIn = params.amountIn;
        }

        // 走v2交易
        if (params.routerV2 != address(0)) {
            IERC20 erc20 = IERC20(params.tokenIn == address(0) ? WETH : params.tokenIn);
            erc20.approve(params.routerV2, params.amountIn); 

            IUniswapV2Router(params.routerV2).swapExactTokensForTokens(params.amountIn, params.amountOutMinimum, params.v2Path, address(this), params.deadline);
        }
        // 走v3交易
        else if (params.routerV3 != address(0)) {
            IERC20 erc20 = IERC20(params.tokenIn == address(0) ? WETH : params.tokenIn);
            erc20.approve(params.routerV3, params.amountIn); 

            IUniswapV3Router.ExactInputParams memory exactInputParams = IUniswapV3Router.ExactInputParams(  
                params.v3Path,
                address(this),
                params.deadline,
                params.amountIn,
                params.amountOutMinimum
            );

            IUniswapV3Router(params.routerV3).exactInput(exactInputParams);
        }

        if (params.tokenOut == address(0)) {
            uint TA = IERC20(WETH).balanceOf(address(this)); 
            if (TA > 0) {
                IWETH(WETH).withdraw(TA);
            }
            TA = address(this).balance;
            if (TA > 0) {
                payable(params.recipient).transfer(TA);
                amountOut = TA;
            }
        }
        else {
            uint TA = IERC20(params.tokenOut).balanceOf(address(this)); 
            if (TA > 0) {
                TransferHelper.safeTransferFrom(params.tokenOut, address(this), params.recipient, TA);
                amountOut = TA;
            }
        }


        emit ExactInput(msg.sender, params.recipient, params.customId, amountIn, amountOut);
    }

    function exactOutput(SwapOutputParams calldata params) external payable {
        uint256 amountIn = 0;
        uint256 amountOut = 0;


        // 收取代币 eth -> weth
        if (params.tokenIn == address(0)) {
            IWETH(WETH).deposit{value: msg.value}();
            amountIn = msg.value;
        }
        else {
            TransferHelper.safeTransferFrom(params.tokenIn, msg.sender, address(this), params.amountInMaximum);
            amountIn = params.amountInMaximum;
        }

        // 走v2交易
        if (params.routerV2 != address(0)) {
            IERC20 erc20 = IERC20(params.tokenIn == address(0) ? WETH : params.tokenIn);
            erc20.approve(params.routerV2, params.amountInMaximum); 

            IUniswapV2Router(params.routerV2).swapTokensForExactTokens(params.amountOut, params.amountInMaximum, params.v2Path, address(this), params.deadline);
        }
        // 走v3交易
        else if (params.routerV3 != address(0)) {
            IERC20 erc20 = IERC20(params.tokenIn == address(0) ? WETH : params.tokenIn);
            erc20.approve(params.routerV3, params.amountInMaximum); 

            IUniswapV3Router.ExactOutputParams memory exactOutputParams = IUniswapV3Router.ExactOutputParams(  
                params.v3Path,
                address(this),
                params.deadline,
                params.amountOut,
                params.amountInMaximum
            );

            IUniswapV3Router(params.routerV3).exactOutput(exactOutputParams);
        } 

        if (params.tokenOut == address(0)) {
            uint TA = IERC20(WETH).balanceOf(address(this)); 
            if (TA > 0) {
                IWETH(WETH).withdraw(TA);
            }
            TA = address(this).balance;
            if (TA > 0) {
                payable(params.recipient).transfer(TA);
                amountOut = TA;
            }
        }
        else {
            uint TA = IERC20(params.tokenOut).balanceOf(address(this)); 
            if (TA > 0) {
                TransferHelper.safeTransferFrom(params.tokenOut, address(this), params.recipient, TA);
                amountOut = TA;
            }
        }

        // 如果有多余的币 要还回去
        if (params.tokenIn == address(0)) {
            uint TA = IERC20(WETH).balanceOf(address(this)); 
            if (TA > 0) {
                IWETH(WETH).withdraw(TA);
            }
            TA = address(this).balance;
            if (TA > 0) {
                payable(params.recipient).transfer(TA);

                amountIn = amountIn - TA;
            }
        }
        else {
            uint TA = IERC20(params.tokenIn).balanceOf(address(this)); 
            if (TA > 0) {
                TransferHelper.safeTransferFrom(params.tokenIn, address(this), params.recipient, TA);

                amountIn = amountIn - TA;
            }
        }

        emit ExactOutput(msg.sender, params.recipient, params.customId, amountIn, amountOut);
    }

    // important to receive ETH
    receive() payable external {
    }
}