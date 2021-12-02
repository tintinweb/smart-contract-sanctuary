//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwapper.sol";
import "./ITokenLibrary.sol";

contract Swapper is ISwapper {
    address private owner;

    /**
        @notice The Polygon network is often undercollateralised. For cheaper swaps,
        we route our swaps through pools that have more liquidity. At the moment,
        we do this with an array of middle tokens through which a swap can be routed.
        @dev This array shouldn't store more than 256 tokens because all for-loops use uint8 indexes.
     */
    string[] public middleTokens;

    /**
        @notice Routers through which we will view prices and swap ERC20 tokens.
     */
    IUniswapV2Router02 public quickSwap;
    IUniswapV2Router02 public sushiSwap;

    /** 
        @notice Library contract of mappings from strings to addresses of ERC20 tokens on Polygon.
     */ 
    ITokenLibrary public tokenLibrary;

    constructor(address _library) {
        owner = msg.sender;

        tokenLibrary = ITokenLibrary(_library);

        // Inlcude two most common intermediary tokens for QuickSwap
        middleTokens.push("WETH");
        middleTokens.push("USDC");

        quickSwap = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); 
        sushiSwap = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Swapper: Only owner can call this function");
        _;
    }

    function addMiddleToken(string memory name) public onlyOwner {
        require(tokenLibrary.getToken(name) != address(0), "Swapper: No such token in token library");
        require(middleTokens.length < 255, "Swapper: Max middleTokens size exceeded");
        for (uint8 i = 0; i < middleTokens.length; i++) {
            require(sameStrings(middleTokens[i], name) == false, "Swapper: Token already included");
        }
        middleTokens.push(name);
    }

    function removeMiddleToken(string memory name) public onlyOwner {
        for (uint8 i = 0; i < middleTokens.length; i++) {
            if (sameStrings(middleTokens[i], name)) {
                for (uint8 j = i; j < middleTokens.length - 1; j++) {
                    middleTokens[j] = middleTokens[j + 1];
                }
                middleTokens.pop();
                break;
            }
        }
    }

    function getOptimalPathTo(
        string memory from,
        string memory to,
        uint256 amountIn
    ) public view override returns (address middleToken, IUniswapV2Router02 router, uint256 bestAmountOut) {
        address fromToken = tokenLibrary.getToken(from);
        address toToken = tokenLibrary.getToken(to);

        // Setting SushiSwap direct default
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        
        uint256[] memory amountsOut = sushiSwap.getAmountsOut(amountIn, path);
        bestAmountOut = amountsOut[amountsOut.length - 1];
        router = sushiSwap;

        // Checking QuickSwap direct
        amountsOut = quickSwap.getAmountsOut(amountIn, path);
        uint256 newAmountOut = amountsOut[amountsOut.length - 1]; 
        if (newAmountOut > bestAmountOut) {
            bestAmountOut = newAmountOut;
            router = quickSwap;
        }
        
        // Checking indirect
        for (uint8 i = 0; i < middleTokens.length; i++) {
            if (sameStrings(middleTokens[i], from) == false && sameStrings(middleTokens[i], to) == false) {
                path = new address[](3);
                path[0] = fromToken;
                path[1] = tokenLibrary.getToken(middleTokens[i]);
                path[2] = toToken;

                amountsOut = sushiSwap.getAmountsOut(amountIn, path);
                newAmountOut = amountsOut[amountsOut.length - 1]; 
                if (newAmountOut > bestAmountOut) {
                    bestAmountOut = newAmountOut;
                    middleToken = tokenLibrary.getToken(middleTokens[i]);
                    router = sushiSwap;
                }

                amountsOut = quickSwap.getAmountsOut(amountIn, path);
                newAmountOut = amountsOut[amountsOut.length - 1]; 
                if (newAmountOut > bestAmountOut) {
                    bestAmountOut = newAmountOut;
                    middleToken = tokenLibrary.getToken(middleTokens[i]);
                    router = quickSwap;
                }
            }
        }
    }

    function swapTo(
        string memory from,
        string memory to,
        uint256 amountIn
    ) public override returns(uint256) {
        address fromToken = tokenLibrary.getToken(from);
        address toToken = tokenLibrary.getToken(to);

        IERC20 inputToken = IERC20(fromToken);
        inputToken.transferFrom(msg.sender, address(this), amountIn);

        (address middleToken, IUniswapV2Router02 router, uint256 bestAmountOut) = getOptimalPathTo(from, to, amountIn);

        if (inputToken.allowance(address(this), address(router)) < amountIn) {
            inputToken.approve(address(router), type(uint256).max);
        }
       
        // Direct swap
        if (middleToken == address(0)) {
            address[] memory path = new address[](2);
            path[0] = fromToken;
            path[1] = toToken;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn, 
                bestAmountOut, 
                path,
                msg.sender,
                block.timestamp
            );
        }
        // Indirect swap
        else {
            address[] memory path = new address[](3);
            path[0] = fromToken;
            path[1] = middleToken;
            path[2] = toToken;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn, 
                bestAmountOut, 
                path,
                msg.sender,
                block.timestamp
            );
        }

        return bestAmountOut;
    }

    /**
        @dev Utility function to perform equality check on storage string and memory string
        Read more about this design choice here:
        https://ethereum.stackexchange.com/questions/4559/operator-not-compatible-with-type-string-storage-ref-and-literal-string
     */
    function sameStrings(string storage stringA, string memory stringB) internal pure returns(bool) {
        return keccak256(abi.encode(stringA)) == keccak256(abi.encode(stringB));
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ISwapper {
    function getOptimalPathTo(
        string memory from, 
        string memory to, 
        uint256 amountIn) 
    external returns (
        address middleToken, 
        IUniswapV2Router02 router, 
        uint256 bestAmountOut
    );
    function swapTo(
        string memory from, 
        string memory to, 
        uint256 amountIn
    ) external returns (uint256 amountOut);
    /* function getOptimalPathFrom(
        address from,
        address to,
        uint256 amountOut
    ) external view returns (string memory bestID, uint256 bestAmountIn); 
    function swapByIndex(address router, address[] memory path, uint256 amountIn) external returns (uint256 amountOut);
    function swapFrom(address from, address to, uint256 amountOut) external returns (uint256 amountIn);
    */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenLibrary {
    function addToken(string memory, address) external;
    function getToken(string memory) external view returns(address);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}