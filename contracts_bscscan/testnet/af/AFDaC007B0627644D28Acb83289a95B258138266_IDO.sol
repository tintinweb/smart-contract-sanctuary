// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @author TokenX Team
/// @title IDO
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract IDO {
    //Admin address for handling tokens
    address public adminAddress = address(0x8B50fDfE2d329B59AeF4EB967e8F9488d0aD8699);
    // BUSD address.
    IERC20 public purchaseToken = IERC20(address(0xfDCaf555d0A83345DfE14603067e6C229A8a6919));
    // Token M address.
    IERC20 public offerToken = IERC20(address(0x7D0faFF1a061f2fbeE7c67eDAC579D102C8186B9));
    // Owner address.
    address payable public owner;
    // The block number when IDO starts
    uint256 public startBlock;
    // The block number when IDO ends
    uint256 public endBlock;
    // Total tokens purchase
    uint256 public totalTokens;
    // Event for new start & end blocks
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    // Withdraw
    event FinalWithdraw(uint256 amount, uint256 amountOfferingToken);
    // Purchase
    event Purchase(address sender, uint256 amount);
    using SafeMath for uint256;
    constructor(uint256 _startBlock, uint256 _endBlock){
        owner = payable(msg.sender);
        startBlock = _startBlock;
        endBlock = _endBlock;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }
    /**
     * @dev It allows the admin to update start and end blocks
     * @param _startBlock: the new start block
     * @param _endBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) public onlyOwner {
        require(_endBlock < block.number, "EndBlock too far");
        require(block.number < startBlock, "IDO has started");
        require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");
        startBlock = _startBlock;
        endBlock = _endBlock;
        emit NewStartAndEndBlocks(_startBlock, _endBlock);
    }
    /**
     * @dev It allows the admin to withdraw funds
     * @param _purchaseAmount: the number of purchase token to withdraw (18 decimals)
     * @param _offerAmount: the number of offering amount to withdraw (18 decimals)
     */
    function finalWithdraw(uint256 _purchaseAmount, uint256 _offerAmount) public onlyOwner {
        if (_purchaseAmount > 0){
            require(_purchaseAmount <= purchaseToken.balanceOf(address(this)), "Not enough purchase tokens");
            purchaseToken.transferFrom(address(this), adminAddress, _purchaseAmount);
        }
        if (_offerAmount > 0){
            require(_offerAmount <= offerToken.balanceOf(address(this)), "Not enough offering tokens");
            offerToken.transferFrom(address(this), adminAddress, _offerAmount);
        }
        emit FinalWithdraw(_purchaseAmount, _offerAmount);
    }
    /**
     * @dev It allows users to purchase tokens 
     * @param _amount: the number of token M (18 decimals)
     */
    function purchase(uint256 _amount) public {
        // Checks whether the block number is not too early
        require(block.number > startBlock, "Too early");

        // Checks whether the block number is not too late
        require(block.number < endBlock, "Too late");

        // Checks that the amount purchase is not inferior to 0
        require(_amount > 0, "Amount must be > 0");

        // Check offerToken balance
        require(offerToken.balanceOf(address(this)) >= _amount, "Tokens insufficient balance");

        // Transfers purchase token to this contract
        _safeTransferFrom(_amount);

        // Transfers offer token to user
        offerToken.transferFrom(address(this), msg.sender,  _amount);
       
        // Updates the totalAmount
        totalTokens = totalTokens.add(_amount);

        emit Purchase(msg.sender, _amount);
    }

    /**
     * @dev purchase tokens balance
     */
    function purchaseTokenBalance() public view returns (uint256){
         return purchaseToken.balanceOf(address(this));
    }

    /**
     * @dev offer tokens balance
     */
    function offerTokenBalance() public view returns (uint256){
         return offerToken.balanceOf(address(this));
    }

    /**
     * @dev Transfer tokens from one address to dev.
     * @param amount  The amount of tokens to be transferred.
     */
    function _safeTransferFrom(uint amount) private {
        bool sent = purchaseToken.transfer(msg.sender, amount);
        require(sent, "Insufficient balance");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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