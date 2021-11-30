// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwapper.sol";
import "./../RLib/Admin.sol";

contract Swapper is ISwapper, Admin{

    struct SwapPath {
        string ID;
        address router;
        address[] path;
        bool active;
    }

    mapping(address => mapping(address => string[])) public SwapPathIDs;
    mapping(string => SwapPath) public SwapPathVariants;
    
    constructor() Admin(msg.sender) {}

    function addPath(string memory id, address[] memory path, address routerAddress) public override onlyOwner {
        SwapPathVariants[id] = SwapPath(
            id, 
            routerAddress, 
            path, 
            true
        );
        SwapPathIDs[path[0]][path[path.length - 1]].push(id);
    }

    function deletePath(address from, address to, string memory id) public override onlyOwner {
        for (uint256 i = 0; i < SwapPathIDs[from][to].length; i++) {
            if (keccak256(abi.encode(SwapPathIDs[from][to][i])) == keccak256(abi.encode(id))) {
                for (uint256 j = i; j < SwapPathIDs[from][to].length - 1; j++) {
                    SwapPathIDs[from][to][j] = SwapPathIDs[from][to][j + 1];
                }
                SwapPathIDs[from][to].pop();
                SwapPathVariants[id].active = false;
                break;
            }
        }
    }

    function updatePath(string memory id, address[] memory newPath) external override onlyOwner {
        SwapPath storage oldSwapPath = SwapPathVariants[id];
        address oldFrom = oldSwapPath.path[0];
        address oldTo = oldSwapPath.path[oldSwapPath.path.length - 1];
        address newFrom = newPath[0];
        address newTo = newPath[newPath.length - 1];
        if (oldFrom != newFrom || oldTo != newTo) {
            deletePath(oldFrom, oldTo, id);
            addPath(id, newPath, oldSwapPath.router);
        } else {
            SwapPathVariants[id] = SwapPath(
                id, oldSwapPath.router, newPath, oldSwapPath.active
            );
        }
    }

    function getOptimalPathTo(
        address from, 
        address to, 
        uint256 amountIn
    ) public view override returns (string memory bestID, uint256 bestAmountOut) {
        for (uint256 i = 0; i < SwapPathIDs[from][to].length; i++) {
            IUniswapV2Router02 router = IUniswapV2Router02(SwapPathVariants[SwapPathIDs[from][to][i]].router);

            (uint256 reserveIn, uint256 reserveOut) = getReserves(router.factory(), from, to);
            uint256 possibleAmount = router.getAmountOut(amountIn, reserveIn, reserveOut);

            if (possibleAmount > bestAmountOut) {
                bestAmountOut = possibleAmount;
                bestID = SwapPathIDs[from][to][i];
            }
        }
    }

    function getOptimalPathFrom(
        address from,
        address to,
        uint256 amountOut
    ) public view override returns (string memory bestID, uint256 bestAmountIn) {
        bestAmountIn = type(uint256).max;
        for (uint256 i = 0; i < SwapPathIDs[from][to].length; i++) {
            IUniswapV2Router02 router = IUniswapV2Router02(SwapPathVariants[SwapPathIDs[from][to][i]].router);

            (uint256 reserveIn, uint256 reserveOut) = getReserves(router.factory(), from, to);
            uint possibleAmount = router.getAmountIn(amountOut, reserveIn, reserveOut);

            if (possibleAmount < bestAmountIn) {
                bestAmountIn = possibleAmount;
                bestID = SwapPathIDs[from][to][i];
            }
        } 
    }

    function swapByIndex(
        address routerAddress, 
        address[] memory path, 
        uint256 amountIn
    ) public override returns (uint256 amountOut) {
        require(path.length >= 2, "Swapper: path must have at least 2 tokens");
        IERC20 fromToken = IERC20(path[0]);
        fromToken.transferFrom(msg.sender, address(this), amountIn);
        
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        (uint256 reserveIn, uint256 reserveOut) = getReserves(router.factory(), path[0], path[path.length - 1]);
        amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);

        if (fromToken.allowance(address(this), address(router)) < amountIn) {
            fromToken.approve(address(router), type(uint256).max);
        } 
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 
            amountOut, 
            path,
            msg.sender,
            block.timestamp
        );
    }

    function swapTo(
        address from, 
        address to, 
        uint256 amountIn
    ) external override returns (uint256) {
        (string memory id, uint256 amountOut) = getOptimalPathTo(from, to, amountIn);
        uint256 actualAmountOut = swapByIndex(SwapPathVariants[id].router, SwapPathVariants[id].path, amountIn);
        require(actualAmountOut == amountOut, "Swapper: Different amounts out");
        return amountOut;
    }
    
    function swapFrom(
        address from, 
        address to, 
        uint256 amountOut
    ) external override returns (uint256) {
        (string memory id, uint256 amountIn) = getOptimalPathFrom(from, to, amountOut);
        uint256 actualAmountOut = swapByIndex(SwapPathVariants[id].router, SwapPathVariants[id].path, amountIn);
        require(amountOut == actualAmountOut, "Swapper: Different amounts out");
        return amountIn; 
    }

    function priceOut(
        address from, 
        address to, 
        uint256 amountIn
    ) external override returns (uint256 amountOut) {
        (string memory id, uint256 amountIn) = getOptimalPathFrom(from, to, amountOut);
        uint256[] memory _amountOut = IUniswapV2Router02(SwapPathVariants[id].router)
            .getAmountsOut(amountIn, SwapPathVariants[id].path);
        amountOut = _amountOut[_amountOut.length - 1];
    }

    function priceIn(
        address from, 
        address to, 
        uint256 amountOut
    ) external override returns (uint256 amountIn) {
        (string memory id, uint256 amountOut) = getOptimalPathTo(from, to, amountOut);
        uint256[] memory _amountIn = IUniswapV2Router02(SwapPathVariants[id].router)
            .getAmountsOut(amountIn, SwapPathVariants[id].path);
        amountIn = _amountIn[_amountIn.length - 1];
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factoryAddress, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(tokenA, tokenB));
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISwapper {
    function addPath(string memory id, address[] memory path, address routerAddress) external;
    function deletePath(address from, address to, string memory id) external;
    function updatePath(string memory id, address[] memory newPath) external;
    function getOptimalPathTo(
        address from, 
        address to, 
        uint256 amountIn
    ) external returns (string memory bestID, uint256 bestAmountOut);
    function getOptimalPathFrom(
        address from,
        address to,
        uint256 amountOut
    ) external view returns (string memory bestID, uint256 bestAmountIn);
    function swapByIndex(address router, address[] memory path, uint256 amountIn) external returns (uint256 amountOut);
    function swapTo(address from, address to, uint256 amountIn) external returns (uint256 amountOut);
    function swapFrom(address from, address to, uint256 amountOut) external returns (uint256 amountIn);

    function priceOut(address from, address to, uint256 amountIn) external returns (uint256 amountOut);
    function priceIn(address from, address to, uint256 amountOut) external returns (uint256 amountIn);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Admin {

    constructor (address _owner) {
        owner = _owner;
    }
    
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    address public receiver;
    modifier onlyReceiver() {
        require(receiver == msg.sender, "Receiver: caller is not the receiver");
        require(receiver != address(0), "Receiver: caller is not the receiver");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner() {
        address oldOwner = owner;
        require(newOwner != oldOwner, "changeOwner: the owner must be different from the current one");
        require(newOwner != address(0), "changeOwner: owner need to be different from zero address");
        receiver = newOwner;
        // emit OwnershipTransferred(oldOwner, newOwner);
    }

    function acceptOwner() public onlyReceiver() {
        address oldOwner = owner;
        address receiverOwner = receiver;
        require(receiverOwner != oldOwner, "changeOwner: the owner must be different from the current one");
        owner = receiverOwner;
        receiver = address(0);
        emit OwnershipTransferred(oldOwner, receiverOwner);
    }

    function renounceOwnership() public onlyOwner() {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipRenounced(oldOwner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);
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