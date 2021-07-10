/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// File: IERC20.sol

pragma solidity >=0.7.0 <0.9.0;

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
// File: IUniswapV2Router02.sol

pragma solidity >=0.7.0 <0.9.0;

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

// File: IUniswapV2Factory.sol

pragma solidity >=0.7.0 <0.9.0;

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
// File: SafeMath.sol

pragma solidity >=0.7.0 <0.9.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: ISwap.sol

pragma solidity >=0.7.0 <0.9.0;

interface ISwap {
    function swapExtractOut(
        address tokenIn, 
        address tokenOut, 
        address recipient, 
        uint256 amountIn, 
        uint256 slippage, 
        uint256 deadline
    ) external returns (uint256);

    // function swapExtractIn(
    //     address tokenIn, 
    //     address tokenOut, 
    //     address recipient, 
    //     uint256 amountOut, 
    //     uint256 slippage, 
    //     uint256 deadline
    // ) external returns (uint256);

    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);

    function swapEstimateIn(address tokenIn, address tokenOut, uint256 amountOut) external view returns (uint256);
}
// File: Ownerable.sol

pragma solidity >=0.7.0 <0.9.0;

abstract contract Ownerable {

    address private _owner;

    event OwnershipTransferred(address indexed preOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: UniswapV2Handler.sol

pragma solidity >=0.7.0 <0.9.0;







contract UniswapV2Handler is Ownerable, ISwap {
    using SafeMath for uint256;

    event BaseTokenAdded(address indexed token);
    event FactoryChanged(address indexed oldFactory, address indexed newFactory);
    event RouterChanged(address indexed oldRouter, address indexed newRouter);

    address[] public baseTokens;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;

    constructor(IUniswapV2Factory factory_, IUniswapV2Router02 router_) {
        factory = factory_;
        router = router_;
        emit FactoryChanged(address(0), address(factory));
        emit RouterChanged(address(0), address(router));
    }

    function supportBaseTokens(address[] memory tokens) external onlyOwner {
        require(tokens.length > 0, "UniswapV2Handler: tokens length is zero");
        for (uint256 i = 0; i < tokens.length; i++) {
            _addBaseToken(tokens[i]);
        }
    }

    function _addBaseToken(address token) internal {
        for (uint256 i = 0; i < baseTokens.length; i++) {
            if (baseTokens[i] == token) {
                return;
            }
        }
        baseTokens.push(token);
        emit BaseTokenAdded(token);
    }

    function updateFactory(IUniswapV2Factory factory_) external onlyOwner {
        require(address(factory_) != address(0), "UniswapV2Handler: factory_ is the zero address");
        require(address(factory) != address(factory_), "UniswapV2Handler: factory_ is the same as factory");
        emit FactoryChanged(address(factory), address(factory_));
        factory = factory_;
    }

    function updateRouter(IUniswapV2Router02 router_) external onlyOwner {
        require(address(router_) != address(0), "UniswapV2Handler: router_ is the zero address");
        require(address(router) != address(router_), "UniswapV2Handler: router_ is the same as router");
        emit RouterChanged(address(factory), address(router_));
        router = router_;
    }

    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view override returns (uint256) {
        (uint256 resultAmount,) = _getBestOut(tokenIn, tokenOut, amountIn);
        return resultAmount;
    }

    function swapEstimateIn(address tokenIn, address tokenOut, uint256 amountOut) external view override returns (uint256) {
        (uint256 resultAmount,) = _getBestIn(tokenIn, tokenOut, amountOut);
        return resultAmount;
    }

    function swapExtractOut(
        address tokenIn, 
        address tokenOut, 
        address recipient, 
        uint256 amountIn, 
        uint256 slippage, 
        uint256 deadline
    ) external override returns (uint256) {
        require(recipient != address(0), "UniswapV2Handler: recipient is the zero address");
        (uint256 amountEst, address[] memory path) = _getBestOut(tokenIn, tokenOut, amountIn);
        require(amountEst > 0, "UniswapV2Handler: Estimate amountOut is zero");
        uint256 amountOutMin = amountEst.sub(amountEst.mul(slippage).div(10000));
        IERC20(tokenIn).approve(address(router), amountIn);
        uint256[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, recipient, deadline);
        return amounts[amounts.length - 1];
    }

    function _getBestOut(address tokenIn, address tokenOut, uint256 amountIn) internal view returns (uint256, address[] memory) {
        require(tokenIn != address(0), "UniswapV2Handler: tokenIn is the zero address");
        require(tokenOut != address(0), "UniswapV2Handler: tokenOut is the zero address");
        require(tokenIn != tokenOut, "UniswapV2Handler: tokenIn and tokenOut is the same");
        require(amountIn > 0, "UniswapV2Handler: amountIn must be greater than zero");
        
        uint256 resultAmount = 0;
        address[] memory resultPath;

        address pair = factory.getPair(tokenIn, tokenOut);
        if (pair != address(0)) {
            resultPath = new address[](2);
            resultPath[0] = tokenIn;
            resultPath[1] = tokenOut;
            uint256[] memory amounts = _getAmountsOut(amountIn, resultPath);
            resultAmount = amounts[amounts.length - 1];
        }

        for (uint256 i = 0; i < baseTokens.length; i++) {
            if (baseTokens[i] == tokenIn || baseTokens[i] == tokenOut) {
                continue;
            }
            if (factory.getPair(tokenIn, baseTokens[i]) == address(0)) {
                continue;
            }
            if (factory.getPair(baseTokens[i], tokenOut) != address(0)) {
                address[] memory tempPath = new address[](3);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = tokenOut;
                uint256[] memory amounts = _getAmountsOut(amountIn, tempPath);
                if (resultAmount < amounts[amounts.length - 1]) {
                    resultAmount = amounts[amounts.length - 1];
                    resultPath = tempPath;
                }
            }

            for (uint256 j = 0; j < baseTokens.length; j++) {
                if (baseTokens[i] == baseTokens[j]) {
                    continue;
                }
                if (baseTokens[j] == tokenIn || baseTokens[j] == tokenOut) {
                    continue;
                }
                if (factory.getPair(baseTokens[i], baseTokens[j]) == address(0)) {
                    continue;
                }
                if (factory.getPair(baseTokens[j], tokenOut) == address(0)) {
                    continue;
                }
                address[] memory tempPath = new address[](4);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = baseTokens[j];
                tempPath[3] = tokenOut;
                uint256[] memory amounts = _getAmountsOut(amountIn, tempPath);
                if (resultAmount < amounts[amounts.length - 1]) {
                    resultAmount = amounts[amounts.length - 1];
                    resultPath = tempPath;
                }
            }
        }

        return (resultAmount, resultPath);
    }

    function _getBestIn(address tokenIn, address tokenOut, uint256 amountOut) internal view returns (uint256, address[] memory) {
        require(tokenIn != address(0), "UniswapV2Handler: tokenIn is the zero address");
        require(tokenOut != address(0), "UniswapV2Handler: tokenOut is the zero address");
        require(tokenIn != tokenOut, "UniswapV2Handler: tokenIn and tokenOut is the same");
        require(amountOut > 0, "UniswapV2Handler: amountOut must be greater than zero");
        
        uint256 resultAmount = 0;
        address[] memory resultPath;

        address pair = factory.getPair(tokenIn, tokenOut);
        if (pair != address(0)) {
            resultPath = new address[](2);
            resultPath[0] = tokenIn;
            resultPath[1] = tokenOut;
            uint256[] memory amounts = _getAmountsIn(amountOut, resultPath);
            resultAmount = amounts[0];
        }

        for (uint256 i = 0; i < baseTokens.length; i++) {
            if (baseTokens[i] == tokenIn || baseTokens[i] == tokenOut) {
                continue;
            }
            if (factory.getPair(tokenIn, baseTokens[i]) == address(0)) {
                continue;
            }
            if (factory.getPair(baseTokens[i], tokenOut) != address(0)) {
                address[] memory tempPath = new address[](3);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = tokenOut;
                uint256[] memory amounts = _getAmountsIn(amountOut, tempPath);
                if (resultAmount > amounts[0]) {
                    resultAmount = amounts[0];
                    resultPath = tempPath;
                } else if (resultAmount == 0) {
                    resultAmount = amounts[0];
                    resultPath = tempPath;
                }
            }

            for (uint256 j = 0; j < baseTokens.length; j++) {
                if (baseTokens[i] == baseTokens[j]) {
                    continue;
                }
                if (baseTokens[j] == tokenIn || baseTokens[j] == tokenOut) {
                    continue;
                }
                if (factory.getPair(baseTokens[i], baseTokens[j]) == address(0)) {
                    continue;
                }
                if (factory.getPair(baseTokens[j], tokenOut) == address(0)) {
                    continue;
                }
                address[] memory tempPath = new address[](4);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = baseTokens[j];
                tempPath[3] = tokenOut;
                uint256[] memory amounts = _getAmountsIn(amountOut, tempPath);
                if (resultAmount > amounts[0]) {
                    resultAmount = amounts[0];
                    resultPath = tempPath;
                } else if (resultAmount == 0) {
                    resultAmount = amounts[0];
                    resultPath = tempPath;
                }
            }
        }

        return (resultAmount, resultPath);
    }

    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory) {
        bytes memory data = abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, path);
        (bool success, bytes memory returnData) = address(router).staticcall(data);
        if (success) {
            return abi.decode(returnData, (uint256[]));
        } else {
            uint256[] memory result = new uint256[](1);
            result[0] = 0;
            return result;
        }
    }

    function _getAmountsIn(uint256 amountOut, address[] memory path) internal view returns (uint256[] memory) {
        bytes memory data = abi.encodeWithSignature("getAmountsIn(uint256,address[])", amountOut, path);
        (bool success, bytes memory returnData) = address(router).staticcall(data);
        if (success) {
            return abi.decode(returnData, (uint256[]));
        } else {
            uint256[] memory result = new uint256[](1);
            result[0] = 0;
            return result;
        }
    }

}