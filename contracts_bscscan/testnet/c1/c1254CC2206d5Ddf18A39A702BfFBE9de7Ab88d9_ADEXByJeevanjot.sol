/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol



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

// File: contracts/dex.sol

pragma solidity ^0.6.7;



contract ADEXByJeevanjot {
    using SafeMath for uint256;

    string public purpose = "Swapping BLXM";
    IERC20 blxm;
    IERC20 stables;

    constructor(address tokenAddress_blxm, address tokenAddress_stable) public {
        blxm = IERC20(tokenAddress_blxm);
        stables = IERC20(tokenAddress_stable);
    }

    uint256 public totalLiquidity_blxm;
    uint256 public totalLiquidity_stables;

    mapping(address => uint256) public liquidity_blxm;
    mapping(address => uint256) public liquidity_stables;

    function init(uint256 tokens_blxm, uint256 tokens_stables)
        public
        returns (uint256, uint256)
    {
        require(
            totalLiquidity_blxm == 0 && totalLiquidity_stables == 0,
            "DEX:init - already has liquidity"
        );
        totalLiquidity_blxm = blxm.balanceOf(address(this));
        totalLiquidity_stables = stables.balanceOf(address(this));
        liquidity_blxm[msg.sender] = totalLiquidity_blxm;
        liquidity_stables[msg.sender] = totalLiquidity_stables;
        require(blxm.transferFrom(msg.sender, address(this), tokens_blxm));
        require(
            stables.transferFrom(msg.sender, address(this), tokens_stables)
        );
        return (totalLiquidity_blxm, totalLiquidity_stables);
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public pure returns (uint256) {
        uint256 input_amount_with_fee = input_amount.mul(997);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(
            input_amount_with_fee
        );
        return numerator / denominator;
    }

    function stablesToToken(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = blxm.balanceOf(address(this));
        uint256 tokens_bought = price(
            tokens,
            stables.balanceOf(address(this)).sub(tokens),
            token_reserve
        );
        require(blxm.transfer(msg.sender, tokens_bought));
        require(stables.transferFrom(msg.sender, address(this), tokens));
        return tokens_bought;
    }

    function tokenToStables(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = blxm.balanceOf(address(this));
        uint256 stables_bought = price(
            tokens,
            token_reserve,
            stables.balanceOf(address(this))
        );
        require(stables.transfer(msg.sender, stables_bought));
        require(blxm.transferFrom(msg.sender, address(this), tokens));
        return stables_bought;
    }

    function deposit(uint256 token_stables) public payable returns (uint256) {
        uint256 stables_reserve = stables.balanceOf(address(this)).sub(
            token_stables
        );
        uint256 token_reserve = blxm.balanceOf(address(this));
        uint256 token_amount = (token_stables.mul(token_reserve) /
            stables_reserve).add(1);
        uint256 liquidity_minted = token_stables.mul(totalLiquidity_stables) /
            stables_reserve;
        liquidity_stables[msg.sender] = liquidity_stables[msg.sender].add(
            liquidity_minted
        );
        totalLiquidity_stables = totalLiquidity_stables.add(liquidity_minted);
        require(stables.transferFrom(msg.sender, address(this), token_stables));
        require(blxm.transferFrom(msg.sender, address(this), token_amount));
        return liquidity_minted;
    }

    function withdraw(uint256 amount) public returns (uint256, uint256) {
        uint256 token_reserve = blxm.balanceOf(address(this));
        uint256 stables_amount = amount.mul(stables.balanceOf(address(this))) /
            totalLiquidity_stables;
        uint256 token_amount = amount.mul(token_reserve) /
            totalLiquidity_stables;
        liquidity_stables[msg.sender] = liquidity_stables[msg.sender].sub(
            stables_amount
        );
        totalLiquidity_stables = totalLiquidity_stables.sub(stables_amount);
        require(stables.transfer(msg.sender, stables_amount));
        require(blxm.transfer(msg.sender, token_amount));
        return (stables_amount, token_amount);
    }
}