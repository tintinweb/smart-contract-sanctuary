/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.2;

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity >=0.6.2 <0.8.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        uint256 c = a % b;

        return c;
    }

}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

pragma solidity >=0.5.0;

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }
}


pragma solidity >=0.6.2 <0.8.0;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}


pragma solidity >=0.6.6 <0.8.0;

contract Flashswap {
    receive() external payable {}

    address payable public immutable owner1 =
        0x70521A8BaDF21eF8A56a8522dFA3895a4b28480f;
    address payable public immutable owner2 =
        0x70521A8BaDF21eF8A56a8522dFA3895a4b28480f;
    modifier onlyOwner() {
        require(msg.sender == owner1 || msg.sender == owner2);
        _;
    }

    function withdraw(address _tokenContract) public onlyOwner returns (bool) {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 withdrawAmount = address(this).balance;
        owner1.transfer(withdrawAmount / 2);
        owner2.transfer(withdrawAmount / 2);
        uint256 withdrawAmountTokens = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner1, withdrawAmountTokens / 2);
        tokenContract.transfer(owner2, withdrawAmountTokens / 2);
        return true;
    }

    function _getAmountOutByPair(
        uint256 _amountWBNB,
        address _pair,
        address _wbnbAddress,
        uint256 _fee
    ) public view returns (uint256) {
        (uint112 token0Reserves, uint112 token1Reserves, ) = IUniswapV2Pair(
            _pair
        ).getReserves();

        address token0 = IUniswapV2Pair(_pair).token0();
        address token1 = IUniswapV2Pair(_pair).token1();
        bool token0isWbnb = token0 == _wbnbAddress;

        uint256 amountOut = UniswapV2Library.getAmountOut(
            _amountWBNB,
            token0isWbnb ? token0Reserves : token1Reserves,
            token0isWbnb ? token1Reserves : token0Reserves,
            _fee
        );
        return amountOut;
    }

    function check(
        address _token,
        uint256 _amountWBNBPay,
        address _WBNB,
        address _sourceRouter,
        address _targetRouter
    )
        public
        view
        returns (
            int256,
            uint256,
            uint256
        )
    {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _WBNB;
        path1[1] = path2[0] = _token;

        uint256 amountOut = IUniswapV2Router(_sourceRouter).getAmountsOut(
            _amountWBNBPay,
            path1
        )[1];
        uint256 amountRepay = IUniswapV2Router(_targetRouter).getAmountsOut(
            amountOut,
            path2
        )[1];

        return (
            int256(amountRepay - _amountWBNBPay), // our profit or loss; example output: BNB amount
            amountOut,
            amountRepay
        );
    }

    function getLiquidity(
        address _pairAddress0,
        address _pairAddress1,
        address _wbnbAddress
    )
        public
        view
        returns (
            uint112,
            uint112,
            uint112,
            uint112
        )
    {
        (uint112 token0Reserves, uint112 token1Reserves, ) = IUniswapV2Pair(
            _pairAddress0
        ).getReserves();

        (uint112 token0Reserves1, uint112 token1Reserves1, ) = IUniswapV2Pair(
            _pairAddress1
        ).getReserves();

        address token0 = IUniswapV2Pair(_pairAddress0).token0();

        bool token0isWbnb = token0 == _wbnbAddress;

        address token2 = IUniswapV2Pair(_pairAddress1).token0();

        bool token2isWbnb = token2 == _wbnbAddress;

        // returns tokens liqudity in the following order: WBNB1, TOKEN1, WBNB2, TOKEN2
        return (
            token0isWbnb ? token0Reserves : token1Reserves,
            token0isWbnb ? token1Reserves : token0Reserves,
            token2isWbnb ? token0Reserves1 : token1Reserves1,
            token2isWbnb ? token1Reserves1 : token0Reserves1
        );
    }

    function execute(
        uint256 amountIn,
        int256 minAllowed,
        address _pairAddress0,
        address _pairAddress1,
        address _wbnbAddress,
        address _sourceRouter,
        address _targetRouter
    ) external {
        address token0 = IUniswapV2Pair(_pairAddress0).token0();
        address token1 = IUniswapV2Pair(_pairAddress0).token1();

        (
            int256 profit,
            uint256 tokenReceivedAmount,
            uint256 finalWBNBAmount
        ) = check(
                _wbnbAddress == token0 ? token1 : token0,
                amountIn,
                _wbnbAddress,
                _sourceRouter,
                _targetRouter
            );

        require(profit > minAllowed, "no profit");

        IERC20 wbnb = IERC20(_wbnbAddress);
        wbnb.transfer(_pairAddress0, amountIn);

        IUniswapV2Pair(_pairAddress0).swap(
            token0 == _wbnbAddress ? 0 : tokenReceivedAmount,
            token0 == _wbnbAddress ? tokenReceivedAmount : 0,
            _pairAddress1,
            new bytes(0)
        );

        address token0p = IUniswapV2Pair(_pairAddress1).token0();

        IUniswapV2Pair(_pairAddress1).swap(
            token0p == _wbnbAddress ? finalWBNBAmount : 0,
            token0p == _wbnbAddress ? 0 : finalWBNBAmount,
            address(this),
            new bytes(0)
        );
    }
}