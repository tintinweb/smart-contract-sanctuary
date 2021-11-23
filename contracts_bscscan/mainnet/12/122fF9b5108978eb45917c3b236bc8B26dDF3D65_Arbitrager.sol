pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IFinsPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Router01 {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IFinsRouter02 {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

contract Arbitrager {
    using SafeMath for uint;

    address constant public PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant public AUTOSHARK_ROUTER_ADDRESS = 0xB0EeB0632bAB15F120735e5838908378936bd484;

    address constant public CAKE_BNB_TOKEN_ADDRESS = 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
    address constant public AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS = 0xCe39f9c2FffE30E093b54DcEa5bf45C727290985;

    address constant public CAKE_TOKEN_ADDRESS = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address constant public BNB_TOKEN_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IUniswapV2Router02 immutable private pancakeRouter;
    IFinsRouter02 immutable private autosharkRouter;
    address payable immutable private owner;

    constructor(address payable _owner) public {
      require(msg.sender == _owner);
      owner = _owner;
      pancakeRouter = IUniswapV2Router02(PANCAKE_ROUTER_ADDRESS);
      autosharkRouter = IFinsRouter02(AUTOSHARK_ROUTER_ADDRESS);
      approveMyselfForTokens();
    }

    function approveMyselfForTokens() private {
      IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
      uint allowance = tokenApi.allowance(address(this), PANCAKE_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000000) {
        tokenApi.approve(PANCAKE_ROUTER_ADDRESS, 1000000000000000000000000000);
      }
      allowance = tokenApi.allowance(address(this), AUTOSHARK_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000000) {
        tokenApi.approve(AUTOSHARK_ROUTER_ADDRESS, 1000000000000000000000000000);
      }
    }

    receive () external payable {}

    function escapeHatch() public {
        require(msg.sender==owner);
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
        uint balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
        tokenApi = IERC20(BNB_TOKEN_ADDRESS);
        balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
    }

    // function appendUintToString(string memory inStr, uint v) view public returns (string memory str) {
    //     uint maxlength = 100;
    //     bytes memory reversed = new bytes(maxlength);
    //     uint i = 0;
    //     while (v != 0) {
    //         uint remainder = v % 10;
    //         v = v / 10;
    //         reversed[i++] = byte(uint8(48 + remainder));
    //     }
    //     bytes memory inStrb = bytes(inStr);
    //     bytes memory s = new bytes(inStrb.length + i);
    //     uint j;
    //     for (j = 0; j < inStrb.length; j++) {
    //         s[j] = inStrb[j];
    //     }
    //     for (j = 0; j < i; j++) {
    //         s[j + inStrb.length] = reversed[i - 1 - j];
    //     }
    //     str = string(s);
    // }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
      require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
      require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
      uint amountInWithFee = amountIn.mul(997);
      uint numerator = amountInWithFee.mul(reserveOut);
      uint denominator = reserveIn.mul(1000).add(amountInWithFee);
      amountOut = numerator / denominator;
    }

    function start(
        uint amount
    ) external {
        address[] memory path = new address[](2);
        path[0] = CAKE_TOKEN_ADDRESS;
        path[1] = BNB_TOKEN_ADDRESS;

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).getReserves();
        uint pancakeAmountOut = getAmountOut(amount, reserve0, reserve1);

        (reserve0, reserve1,) = IFinsPair(AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS).getReserves();
        uint sharkAmountOut = getAmountOut(amount, reserve0, reserve1);

        if (sharkAmountOut == pancakeAmountOut) {
            require(false, "sharkAmountOut == pancakeAmountOut");
        }
    
        if (sharkAmountOut > pancakeAmountOut) {
                
            IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).swap(
                amount, 
                0,
                address(this), 
                bytes('not empty')
            );

        } else {

            IFinsPair(AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS).swap(
                amount, 
                0,
                address(this), 
                bytes('not empty')
            );
        }
    }

    function FinsCall(
        address _sender, 
        uint _amount0, 
        uint _amount1, 
        bytes calldata _data
    ) external {
        require(
            msg.sender == AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS, 
            'Unauthorized'
        ); 
        require(_amount0 > 0 && _amount1 == 0, "FinsCall:_amount0 is not greater than 0 or _amount1 != 0");

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).getReserves();
        uint amountOut = getAmountOut(_amount0, reserve0, reserve1);

        // compute the amount of _tokenPay that needs to be repaid
        uint pairBalanceTokenBorrow = IERC20(CAKE_TOKEN_ADDRESS).balanceOf(AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS);
        uint pairBalanceTokenPay = IERC20(BNB_TOKEN_ADDRESS).balanceOf(AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amount0) / (997 * pairBalanceTokenBorrow)) + 1;

        require(amountOut > amountToRepay, "FinsCall:amountOut is not greater than amountToRepay");

        address[] memory path = new address[](2);
        path[0] = CAKE_TOKEN_ADDRESS;
        path[1] = BNB_TOKEN_ADDRESS;

        uint amountReceived = pancakeRouter.swapExactTokensForETH(
            _amount0, 
            amountOut, 
            path,
            payable(address(this)), 
            block.timestamp + (1000*60*10)
        )[1];

        require(amountReceived > amountToRepay, "FinsCall:amountOut is not greater than amountToRepay");

        IWETH(BNB_TOKEN_ADDRESS).deposit{value: amountToRepay}();
        IERC20(BNB_TOKEN_ADDRESS).transfer(msg.sender, amountToRepay);

        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
    }

    function pancakeCall(
        address _sender, 
        uint _amount0, 
        uint _amount1, 
        bytes calldata _data
    ) external {
        require(
            msg.sender == CAKE_BNB_TOKEN_ADDRESS, 
            'Unauthorized'
        ); 
        require(_amount0 > 0 && _amount1 == 0, "pancakeCall:_amount0 is not greater than 0 or _amount1 != 0");

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS).getReserves();
        uint amountOut = getAmountOut(_amount0, reserve0, reserve1);

        // compute the amount of _tokenPay that needs to be repaid
        uint pairBalanceTokenBorrow = IERC20(CAKE_TOKEN_ADDRESS).balanceOf(CAKE_BNB_TOKEN_ADDRESS);
        uint pairBalanceTokenPay = IERC20(BNB_TOKEN_ADDRESS).balanceOf(CAKE_BNB_TOKEN_ADDRESS);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amount0) / (997 * pairBalanceTokenBorrow)) + 1;

        require(amountOut > amountToRepay, "pancakeCall:amountOut is not greater than amountToRepay");

        address[] memory path = new address[](2);
        path[0] = CAKE_TOKEN_ADDRESS;
        path[1] = BNB_TOKEN_ADDRESS;

        uint amountReceived = autosharkRouter.swapExactTokensForETH(
            _amount0, 
            amountOut, 
            path,
            payable(address(this)), 
            block.timestamp + (1000*60*10)
        )[1];

        require(amountReceived > amountToRepay, "pancakeCall:amountReceived is not greater than amountToRepay");

        IWETH(BNB_TOKEN_ADDRESS).deposit{value: amountToRepay}();
        IERC20(BNB_TOKEN_ADDRESS).transfer(msg.sender, amountToRepay);

        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}