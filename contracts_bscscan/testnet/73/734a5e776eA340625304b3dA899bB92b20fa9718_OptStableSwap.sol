// SPDX-License-Identifier: MIT
/**
Optimal Stable Swap Strategy
Ellipsis -> Pancake
https://docs.ellipsis.finance/deployment-links
https://bscscan.com/address/0x160CAed03795365F3A589f10C379FfA7d75d4E76
*/

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ICurveBase.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeRouter02.sol";

contract OptStableSwap {
    using SafeMath for uint256;
    /* ========== STATE VARIABLES ========== */

    address public EPSPool;
    address public DAI;
    address public BUSD;
    address public USDT;
    address public DAIBUSDLP;
    address public DAIUSDTLP;
    address public BUSDUSDTLP;
    IPancakeRouter02 public router;
    address[] public router_path;

    uint256 public A;
    uint256 public FEE_DENOMINATOR;
    uint256 public fee;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _EPSPool,
        address _DAI,
        address _BUSD,
        address _USDT,
        address _DAIBUSDLP,
        address _DAIUSDTLP,
        address _BUSDUSDTLP,
        address _router,
        uint256 _FEE_DENOMINATOR,
        uint256 _fee
    ) external {
        EPSPool = _EPSPool;
        DAI = _DAI;
        BUSD = _BUSD;
        USDT = _USDT;
        DAIBUSDLP = _DAIBUSDLP;
        DAIUSDTLP = _DAIUSDTLP;
        BUSDUSDTLP = _BUSDUSDTLP;

        router = IPancakeRouter02(_router);
        A = ICurveBase(EPSPool).A();
        FEE_DENOMINATOR = _FEE_DENOMINATOR;
        fee = _fee;
    }

    /* ========== View Functions ========== */
    

    /* ========== External Functions ========== */
  

    /* ========== Private Functions ========== */
    
    function get_dx(uint256[] memory curve_balances, uint256 _A, uint256 ic, uint256 jc, uint256[] memory fixed_product_balances, uint256 ifp, uint256 jfp, uint256 xi, uint256 yi, uint256 curve_fee, uint256 curve_fee_denominator) private view returns (uint256 dx, uint256 dy_) {
        /* ========== Hard-coded Parameters (TO REMOVE) ========== */
        dx = 1;
        uint128 i = 1;
        uint128 j = 1;
        uint256 N_COINS = 3;
        /* ========== Hard-coded Parameters (TO REMOVE) ========== */

        ICurveBase stablePool = ICurveBase(EPSPool);
        _A = stablePool.A();
        dy_ = stablePool.get_dy(i, j, dx); 
        uint256 Ann = _A.mul(N_COINS);
        uint256 Xfp = fixed_product_balances[ifp];
        uint256 Yfp = fixed_product_balances[jfp];

        uint256 Xfp_ = Xfp - ( Xfp * curve_fee / curve_fee_denominator );
        uint256 yi_ = (yi * curve_fee_denominator) / (curve_fee_denominator - fee);
        uint256 X0 = curve_balances[ic];
        uint256 Y0 = curve_balances[jc];
       
        uint256 S = 0;
        //D = get_D(curve_balances, A);
        uint256 D = 0;
        uint256 Pr_ = D;

        for(uint256 _i; _i < N_COINS; i++) {
            if(_i != ic && _i != jc) {
                S += curve_balances[_i];
                Pr_ = Pr_ * D / (curve_balances[_i] * N_COINS);
            }
        }

        Pr_ = Pr_ / (A * (N_COINS ** 3));

        // x = X0;
        // y = Y0;

        (uint256 x, uint256 y) = find_intersection_of_l_with_tangent(X0, Y0, Pr_, D, Yfp, Xfp_, yi_, xi);

        /*
        for e in 'x,y'.split(','):
        print(f'{e:15}:{eval(e)}:{float(eval(e)):20}')
        for _i in range(255):
            x_prev, y_prev = x, y
            newton_step_along_line(_i)
            print('looping with no shit (x,y) = ({},{})'.format(x,y))
            for e in 'x,y'.split(','):
                print(f'{e:15}:{eval(e)}:{float(eval(e)):20}')
                    
            if within_distance(y,y_prev):
                print(f"Completed in", _i, "steps")
                break

        print("Total number of operations performed = ", uint256.number_of_operations_performed)
        return x - X0, (Y0-y) - (Y0-y)* curve_fee / curve_fee_denominator
        
        */
        return (x - X0, 0);
    }

    function f_neg(uint256 Xfp_, uint256 xi, uint256 X0, uint256 Yfp, uint256 y) private pure returns (uint256) {
        return  Xfp_ * y + (xi + X0) * Yfp;
    }

    function f_pos(uint256 Yfp, uint256 yi_, uint256 Y0, uint256 Xfp_, uint256 x) private pure returns (uint256) {
        return Yfp * x + (yi_ + Y0) * Xfp_;
    }

    function find_intersection_of_l_with_tangent(uint256 X0, uint256 Y0, uint256 Pr_, uint256 D, uint256 Yfp, uint256 Xfp_, uint256 yi_, uint256 xi) private pure returns (uint256 x, uint256 y) {
        uint256 omega_num = X0 * Y0 + Pr_ * (D ** 2 / Y0);
        uint256 omega_den = X0 * Y0 / D + Pr_ * D / Y0;
        uint256 omega = omega_num / omega_den;
        uint256 fX0Y0_pos = f_pos(Yfp, yi_, Y0, Xfp_, X0);
        uint256 fX0Y0_neg = f_neg(Xfp_, xi, X0, Yfp, Y0);

        uint256 step_x_den = Yfp + (Xfp_ * omega) / D;
        uint256 step_x_pos = fX0Y0_neg / step_x_den;
        uint256 step_x_neg = fX0Y0_pos / step_x_den;
       // assert xi + step_x_neg > step_x_pos  # If this fails, you can't exchange at the curve pool at the current rate to get the correct ratio of the fixed product pool because you do not have enough currency. You really shouldn't be making the trade in this case. I need this condition in the computation to ensure uint256 quantities stay positive

        uint256 step_y_den = (Yfp * D) / omega + Xfp_;
        uint256 step_y_pos = fX0Y0_pos / step_y_den;
        uint256 step_y_neg = fX0Y0_neg / step_y_den;
       // assert Y0 + step_y_pos > step_y_neg  # If this fails, you can't exchange at the curve pool at the current rate to get the correct ratio of the fixed product pool because there is not enough money in the pool. You really shouldn't be making the trade in this case. I need this condition in the computation to ensure uint256 quantities stay positive

        x = X0 + step_x_pos - step_x_neg;
        y = Y0 + step_y_pos - step_y_neg;
    }

    function newton_step_along_line(uint256 X0, uint256 Y0, uint256 Pr_, uint256 D, uint256 Yfp, uint256 Xfp_, uint256 S, uint256 Ann) private pure returns (uint256 x, uint256 y) {
        x = X0;
        y = Y0;
        uint256 xy = x * y;
        uint256 xy_by_D = xy / D;
        uint256 alpha_pos = xy_by_D * (x + y + S + D / Ann);
        uint256 alpha_neg = xy + Pr_ * D;
        uint256 beta = ((xy * 2 + y ** 2 + y * S) / D + y / (Ann) - y) * Xfp_ + ((xy * 2 + x ** 2 + x * S) / D + x / (Ann) - x) * Yfp;
        x = x + alpha_neg / (beta / Xfp_) - alpha_pos / (beta / Xfp_);
        y = y + alpha_neg / (beta / Yfp) - alpha_pos / (beta / Yfp);
    }

    function ver_hor_newton_step(uint256 X0, uint256 Y0, uint256 Pr_, uint256 D, uint256 Yfp, uint256 Xfp_, uint256 xi, uint256 yi_, uint256 S, uint256 Ann) private pure returns (uint256 x, uint256 y) {
        x = X0;
        y = Y0;
        uint256 x1 = x;
        uint256 x2 = (x**2 + ((Pr_ * D) / y) * D) / ( x * 2 + y + S + D/Ann - D);
        uint256 y1 = (y**2 + ((Pr_ * D) / x) * D) / ( y * 2 + x + S + D/Ann - D);
        uint256 y2 = y;
        uint256 temp = 0;

        require(!within_distance(x1, x2, 2) && !within_distance(y1, y2, 2), "within_distance(x1, x2, 2) || within_distance(y1, y2, 2)");
        
        // if (within_distance(x1, x2, 2) || within_distance(y1, y2, 2)) {
        //     return
        // }
        if (y2 > y1) {
            temp = Yfp + (Xfp_ * (y2 -y1))/(x1-x2);
        } else {
            temp = Yfp + (Xfp_ * (y1 -y2))/(x2-x1);
        }

        x = x1 + f_neg(Xfp_, xi, X0, Yfp, y1) / temp - f_pos(Yfp, yi_, Y0, Xfp_, x1)/temp;

        if (y2 > y1) {
            temp = (Yfp * (x1-x2))/(y2-y1)+ Xfp_;
        } else {
            temp = (Yfp * (x2-x1))/(y1-y2)+ Xfp_;
        }

        y = y1 + f_pos(Yfp, yi_, Y0, Xfp_, x1) / temp - f_neg(Xfp_, xi, X0, Yfp, y1)/temp;
    }

    function within_distance(uint256 x1, uint256 x2, uint256 d) private pure returns (bool) {
        if (x1 > x2) {
            if (x1 - x2 <= d) {
                return true;
            }
        }
        else {
            if (x2 - x1 <= d) {
                return  true;
            }
        }
    } 
 
    /* ========== RESTRICTED FUNCTIONS ========== */

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
/**
Optimal Stable Swap Strategy
Ellipsis -> Pancake
https://docs.ellipsis.finance/deployment-links
https://bscscan.com/address/0x160CAed03795365F3A589f10C379FfA7d75d4E76
*/

pragma solidity 0.6.12;

interface ICurveBase {
    /*
    https://github.com/ellipsis-finance/ellipsis/blob/master/contracts/DepositZap3EPS.vy
    */

    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _amount, uint256[4] calldata min_uamounts) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_imbalance(uint256[4] calldata uamounts, uint256 max_burn_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, uint128 i, uint256 min_amount) external view returns (uint256);
    function calc_token_amount() external view returns (uint256);
    function coins(int128 i) external view returns (address);
    function fee() external view returns (uint256);
    function A() external view returns (uint256);
    function get_dy(uint128 i, uint128 j, uint256 dx) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakePair {
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
pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

