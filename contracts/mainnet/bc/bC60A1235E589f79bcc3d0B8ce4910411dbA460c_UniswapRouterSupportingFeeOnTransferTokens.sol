// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ITokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IValueLiquidPool {
    function swapExactAmountIn(address tokenIn, uint tokenAmountIn, address tokenOut, uint minAmountOut, uint maxPrice) external returns (uint tokenAmountOut, uint spotPriceAfter);
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// This class implements IValueLiquidPool to support Value Vault's strategies
// Will implement UniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens for some rare cases which takes fee for token transfer (eg. Dego.finance)
contract UniswapRouterSupportingFeeOnTransferTokens is IValueLiquidPool, IUniswapRouter {
    using SafeMath for uint256;

    address public governance;

    IUniswapRouter public unirouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public performanceFee = 0; // 0% at start and can be set by governance decision

    mapping(address => mapping(address => address[])) public uniswapPaths; // [input -> output] => uniswap_path
    mapping(address => bool) public hasTransferFee; // token_address => has_transfer_fee

    constructor(address _tokenHasTransferFee) public {
        hasTransferFee[_tokenHasTransferFee] = true;
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function approveForSpender(ITokenInterface _token, address _spender, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        _token.approve(_spender, _amount);
    }

    function setUnirouter(IUniswapRouter _unirouter) external {
        require(msg.sender == governance, "!governance");
        unirouter = _unirouter;
    }

    function setPerformanceFee(uint256 _performanceFee) public {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function setHasTransferFee(address _token, bool _hasFee) public {
        require(msg.sender == governance, "!governance");
        hasTransferFee[_token] = _hasFee;
    }

    function setUnirouterPath(address _input, address _output, address [] memory _path) public {
        require(msg.sender == governance, "!governance");
        uniswapPaths[_input][_output] = _path;
    }

    function swapExactAmountIn(address _tokenIn, uint _tokenAmountIn, address _tokenOut, uint _minAmountOut, uint) external override returns (uint _tokenAmountOut, uint) {
        address[] memory path = uniswapPaths[_tokenIn][_tokenOut];
        if (path.length == 0) {
            // path: _input -> _output
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }
        ITokenInterface input = ITokenInterface(_tokenIn);
        ITokenInterface output = ITokenInterface(_tokenOut);
        input.transferFrom(msg.sender, address(this), _tokenAmountIn);
        if (performanceFee > 0) {
            uint256 performanceFeeAmount = _tokenAmountIn.mul(performanceFee).div(FEE_DENOMINATOR);
            _tokenAmountIn = _tokenAmountIn.sub(performanceFeeAmount);
            input.transfer(governance, performanceFeeAmount);
        }
        if (hasTransferFee[_tokenIn] || hasTransferFee[_tokenOut]) {
            // swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline)
            unirouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(_tokenAmountIn, _minAmountOut, path, msg.sender, now.add(1800));
        } else {
            // swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline)
            unirouter.swapExactTokensForTokens(_tokenAmountIn, _minAmountOut, path, msg.sender, now.add(1800));
        }
        _tokenAmountOut = output.balanceOf(address(this));
        output.transfer(msg.sender, _tokenAmountOut);
    }

    function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external override returns (uint256[] memory amounts) {
        ITokenInterface input = ITokenInterface(_path[0]);
        input.transferFrom(msg.sender, address(this), _amountIn);
        if (performanceFee > 0) {
            uint256 performanceFeeAmount = _amountIn.mul(performanceFee).div(FEE_DENOMINATOR);
            _amountIn = _amountIn.sub(performanceFeeAmount);
            input.transfer(governance, performanceFeeAmount);
        }
        amounts = unirouter.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _to, _deadline);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external override returns (uint256[] memory amounts) {
        ITokenInterface input = ITokenInterface(_path[0]);
        input.transferFrom(msg.sender, address(this), _amountIn);
        if (performanceFee > 0) {
            uint256 performanceFeeAmount = _amountIn.mul(performanceFee).div(FEE_DENOMINATOR);
            _amountIn = _amountIn.sub(performanceFeeAmount);
            input.transfer(governance, performanceFeeAmount);
        }
        amounts = unirouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, _path, _to, _deadline);
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(ITokenInterface _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}