//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IZkSync.sol";
import "./interfaces/IWstETH.sol";
import "./interfaces/ILido.sol";
import "./interfaces/ICurvePool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ZkSyncBridgeSwapper {

    using SafeMath for uint256;

    // The owner of the contract
    address public owner;

    // The ZkSync bridge contract
    address public immutable zkSync;
    // The L2 market maker account
    address public immutable l2Account;
    // The address of the stEth token
    address public immutable stEth;
    // The address of the wrapped stEth token
    address public immutable wStEth;
    // The address of the stEth/Eth Curve pool
    address public immutable stEthPool;
    // The referal address for Lido
    address public immutable lidoReferal;

    // The max slippage accepted in Curve. Set to 1%.
    uint256 public immutable SLIPPAGE_FACTOR = 99000000;

    address constant internal ETH_TOKEN = address(0);

    event Swapped(address _in, uint256 _amountIn, address _out, uint256 _amountOut);
    event OwnerChanged(address _owner, address _newOwner);

    constructor (
        address _zkSync,
        address _l2Account,
        address _wStEth,
        address _stEthPool,
        address _lidoReferal
    )
    {
        zkSync = _zkSync;
        l2Account = _l2Account;
        wStEth = _wStEth;
        stEth = IWstETH(_wStEth).stETH();
        stEthPool = _stEthPool;
        lidoReferal =_lidoReferal;
        owner = msg.sender;
    }
    
    /**
    * @dev Swaps wrapped stETH for ETH and deposits the resulting ETH to the ZkSync bridge.
    * First withdraws wrapped stETH from the bridge if there is a pending balance.
    * @param _amountIn The amount of wrapped stETH to swap.
    */
    function swapStEthForEth(uint256 _amountIn) external returns (uint256) {
        // check if there is a pending balance to withdraw
        uint128 pendingBalance = IZkSync(zkSync).getPendingBalance(address(this), wStEth);
        if (pendingBalance > 0) {
            // withdraw pending balance
            IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), wStEth, pendingBalance);
        }
        // unwrap to stEth
        uint256 unwrapped = IWstETH(wStEth).unwrap(_amountIn);
        // swap stEth for ETH on Curve
        uint256 amountOut = ICurvePool(stEthPool).exchange(1, 0, unwrapped, getMinAmountOut(unwrapped));
        // deposit Eth to L2 bridge
        IZkSync(zkSync).depositETH{value: amountOut}(l2Account);
        // emit event
        emit Swapped(wStEth, _amountIn, ETH_TOKEN, amountOut);
        // return deposited amount
        return amountOut;
    }

    /**
    * @dev Swaps ETH for wrapped stETH and deposits the resulting wstETH to the ZkSync bridge.
    * First withdraws ETH from the bridge if there is a pending balance.
    * @param _amountIn The amount of ETH to swap.
    */
    function swapEthForStEth(uint256 _amountIn) external returns (uint256) {
        // check if there is a pending balance to withdraw
        uint128 pendingBalance = IZkSync(zkSync).getPendingBalance(address(this), address(0));
        if (pendingBalance > 0) {
            // withdraw Eth from the L2 bridge
            IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), address(0), pendingBalance);
        }
        // swap Eth for stEth on the Lido contract
        ILido(stEth).submit{value: _amountIn}(lidoReferal);
        // approve the wStEth contract to take the stEth
        IERC20(stEth).approve(wStEth, _amountIn);
        // wrap to wStEth
        uint256 amountOut = IWstETH(wStEth).wrap(_amountIn);
        // approve the zkSync bridge to take the wrapped stEth
        IERC20(wStEth).approve(zkSync, amountOut);
        // deposit the wStEth to the L2 bridge
        IZkSync(zkSync).depositERC20(IERC20(wStEth), toUint104(amountOut), l2Account);
        // emit event
        emit Swapped(ETH_TOKEN, _amountIn, wStEth, amountOut);
        // return deposited amount
        return amountOut;
    }

    /**
    * @dev Safety method to recover ETH or ERC20 tokens that are sent to the contract by error.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external returns (uint256 balance) {
        bool success;
        if (_token == ETH_TOKEN) {
            balance = address(this).balance;
            (success, ) = owner.call{value: balance}("");
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            success = IERC20(_token).transfer(owner, balance);
        }
        require(success, "failed to recover");
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner, "unauthorised");
        require(_newOwner != address(0), "invalid input");
        owner = _newOwner;
        emit OwnerChanged(owner, _newOwner);
    }

    /**
     * @dev fallback method to make sure we can receive ETH
     */
    receive() external payable {
        
    }

    /**
     * @dev Returns the minimum accepted out amount.
     */
    function getMinAmountOut(uint256 _amountIn) internal pure returns (uint256) {
        return _amountIn.mul(SLIPPAGE_FACTOR).div(100000000);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IZkSync {
    function getPendingBalance(address _address, address _token) external view returns (uint128);
    function withdrawPendingBalance(address payable _owner, address _token, uint128 _amount) external;
    function depositETH(address _zkSyncAddress) external payable;
    function depositERC20(IERC20 _token, uint104 _amount, address _zkSyncAddress) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWstETH {
    function stETH() external returns (address);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange(int128 _i, int128 _j, uint256 _dx, uint256 _min_dy) external returns (uint256);
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

