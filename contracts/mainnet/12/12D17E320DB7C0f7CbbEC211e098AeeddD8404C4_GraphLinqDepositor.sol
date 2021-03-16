// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./interfaces/IERC20.sol";
import "./maths/SafeMath.sol";

contract GraphLinqDepositor {
    using SafeMath for uint256;

    address private _graphLinkContract;
    mapping (address => uint256) _balances;
    address private _engineManager;

    constructor(address engineManager, address graphLinqContract) {
        _engineManager = engineManager;
        _graphLinkContract = graphLinqContract;
    }

    /* Parameters: Amount of GLQ Token to burn
    ** Desc: Burn a specific amount of token by calling the GLQ Token Contract for All Wallets
    ** Return: void
    */
    function burnAmount(uint256 amount) public {
        IERC20 graphLinqToken = IERC20(address(_graphLinkContract));
         require (
            msg.sender == _engineManager,
            "Only the GraphLinq engine manager can decide which funds should be burned for graph costs."
        );
        require(
            graphLinqToken.balanceOf(address(this)) >= amount, 
            "Invalid fund in the depositor contract, cant reach the contract balance amount."
        );
        graphLinqToken.burnFuel(amount);
    }

    /* Parameters: Amount of GLQ Token to burn
    ** Desc: Burn a specific amount of token by calling the GLQ Token Contract for a specific wallet
    */
    function burnBalance(address fromWallet, uint256 amount) public {
        IERC20 graphLinqToken = IERC20(address(_graphLinkContract));
        require (
            msg.sender == _engineManager,
            "Only the GraphLinq engine manager can decide which funds should be burned for graph costs."
        );

        require (_balances[fromWallet] >= amount,
            "Invalid amount to withdraw, amount is higher then current wallet balance."
        );

        require(
            graphLinqToken.balanceOf(address(this)) >= amount, 
            "Invalid fund in the depositor contract, cant reach the contract balance amount."
        );

        graphLinqToken.burnFuel(amount);
        _balances[fromWallet] -= amount;
    }

    /* Parameters: wallet owner address, amount asked to withdraw, fees to pay for graphs execs
    ** Desc: Withdraw funds from this contract to the base wallet depositor, applying fees if necessary
    */
    function withdrawWalletBalance(address walletOwner, uint256 amount,
     uint256 removeFees) public {
        IERC20 graphLinqToken = IERC20(address(_graphLinkContract));

        require (
            msg.sender == _engineManager,
            "Only the GraphLinq engine manager can decide which funds are withdrawable or not."
        );

        uint256 summedAmount = amount.add(removeFees);
        require (_balances[walletOwner] >= summedAmount,
            "Invalid amount to withdraw, amount is higher then current wallet balance."
        );

        require(
            graphLinqToken.balanceOf(address(this)) >= summedAmount, 
            "Invalid fund in the depositor contract, cant reach the wallet balance amount."
        );

        _balances[walletOwner] -= amount;
        require(
            graphLinqToken.transfer(walletOwner, amount),
            "Error transfering balance back to his owner from the depositor contract."
        );
        
        // in case the wallet runned some graph on the engine and have fees to pay
        if (removeFees > 0) {
            graphLinqToken.burnFuel(removeFees);
            _balances[walletOwner] -= removeFees;
        }
    }

    /* Parameters: Amount to add into the contract
    ** Desc: Deposit GLQ token in the contract to pay for graphs fees executions
    */
    function addBalance(uint256 amount) public {
         IERC20 graphLinqToken = IERC20(address(_graphLinkContract));

         require(
             graphLinqToken.balanceOf(msg.sender) >= amount,
             "Invalid balance to add in your credits"
         );

         require(
             graphLinqToken.transferFrom(msg.sender, address(this), amount) == true,
             "Error while trying to add credit to your balance, please check allowance."
         );

         _balances[msg.sender] += amount;
    }

    function getBalance(address from) public view returns(uint256) {
        return _balances[from];
    }
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

     // Allow deployer to burn his own wallet funds (which is the amount from depositor contract)
    function burnFuel(uint256 amount) external;

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