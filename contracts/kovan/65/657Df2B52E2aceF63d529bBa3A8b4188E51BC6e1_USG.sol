/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;


/**
  * @title Careful Math
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

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
contract USG is CarefulMath {
    
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public constant name = "USG";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "USG";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply;
    
    /// @notice Total number of tokens burn on the app
    uint256 public totalBurned = 0;

    address public admin;
    address public pendingAdmin;
        
    event MintUSG(address indexed user, uint256 mintTokens);

    event BurnUSG(address indexed spender, uint burnTokens);

    /// @dev Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) internal allowances;

    /// @dev Official record of token balances for each account
    mapping (address => uint256) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new USG token
     */
    constructor() public {
        admin = msg.sender;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender,  uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "USG::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "USG::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
    }

    /**
     * @notice Admin can mint USG token for user who exchange their credits in the app
     * @param user The Wificion user wallet address
     * @param mintTokens The number of tokens to be minted
     * @return (uint, uint) An error code (0=success, otherwise a failure)
     */
    function mint(address user, uint256 mintTokens) public returns (uint256) {
        // Check caller = admin
        require(msg.sender == admin);
        return mintFrash(user, mintTokens);
    }

    /**
     * @notice Admin can mint USG token for user who exchange their credits in the app
     * @param user The Wificion user wallet address
     * @param mintTokens The number of tokens to be minted
     * @return (uint, uint) An error code (0=success, otherwise a failure)
     */
    function mintFrash(address user, uint256 mintTokens) internal returns (uint256) {
        require(uint128(mintTokens) == mintTokens);
        require(mintTokens > 0, "USG::mintFrash: cannot mint USG with zero amount");

        uint256 totalSupplyNew;
        uint256 accountTokensNew;
        MathError mathErr;

        (mathErr, totalSupplyNew) = addUInt(totalSupply, mintTokens);
        require(mathErr == MathError.NO_ERROR, "USG::mintFrash: adding mint token with totalSupply is failed");

        (mathErr, accountTokensNew) = addUInt(balances[user], mintTokens);
        require(mathErr == MathError.NO_ERROR, "USG::mintFrash: adding mint token to buyer account is failed");

        /* We write previously calculated values into storage */
        totalSupply = totalSupplyNew;
        balances[user] = accountTokensNew;

        /* We emit a Mint event, and a Transfer event */
        emit MintUSG(user, mintTokens);
        emit Transfer(address(this), user, mintTokens);

        return (uint256(MathError.NO_ERROR));
    }

    /**
     * @notice Admin can burn USG token for user who consume their credits in the app
     * @param user The Wificion user wallet address
     * @param burnTokens The number of tokens to be burn
     * @return (uint, uint) An error code (0=success, otherwise a failure)
     */
    function burn(address user, uint256 burnTokens) public returns (uint256) {
        // Check caller = admin
        require(msg.sender == admin);
        return burnFrash(user, burnTokens);
    }

    /**
     * @notice Admin can burn USG token for user who consume their credits in the app
    * @param user The Wificion user wallet address
     * @param burnTokens The number of tokens to be burn
     * @return (uint, uint) An error code (0=success, otherwise a failure)
     */
    function burnFrash(address user, uint256 burnTokens) internal returns (uint256) {
        require(uint128(burnTokens) == burnTokens);
        require(burnTokens > 0, "USG::burnTokens: cannot burn USG with zero amount");

        uint256 totalSupplyNew;
        uint256 accountTokensNew;
        uint256 totalBurnedNew;

        MathError mathErr;

        (mathErr, totalSupplyNew) = subUInt(totalSupply, burnTokens);
        require(mathErr == MathError.NO_ERROR, "USG::burnFrash: subtracting burn token with totalSupply is failed");

        (mathErr, accountTokensNew) = subUInt(balances[user], burnTokens);
        require(mathErr == MathError.NO_ERROR, "USG::burnFrash: subtracting burn token to user account is failed");

        (mathErr, totalBurnedNew) = addUInt(totalBurned, burnTokens);
        require(mathErr == MathError.NO_ERROR, "USG::burnFrash: adding burn token with totalBurned is failed");

        /* We write previously calculated values into storage */
        totalSupply = totalSupplyNew;
        totalBurned = totalBurnedNew;
        balances[user] = accountTokensNew;

        /* We emit a Burn event, and a Transfer event */
        emit BurnUSG(user, burnTokens);
        emit Transfer(user, address(0), burnTokens);

        return (uint256(MathError.NO_ERROR));
    }
    
    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin);

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin);
        require(msg.sender != address(0));

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }

}