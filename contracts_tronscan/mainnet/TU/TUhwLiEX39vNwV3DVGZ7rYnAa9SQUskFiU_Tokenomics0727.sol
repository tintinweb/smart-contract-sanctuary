//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
 */
interface ITRC20 {
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


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: Tokenomics.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./ownable.sol";

contract Tokenomics0727 is ownable {
    using SafeMath for uint;
    
    ITRC20 PraxisPayments;
    uint256 releaseTime = 1816128000; // 21-Jul-27 00:00:00 GMT
    mapping(address => uint256) frozen;
    
    function setPraxisPaymentsAddress(address PraxisPaymentsAddress) public isOwner {
        require(address(PraxisPayments) == address(0),"Praxis Payments contract address is set");
        PraxisPayments = ITRC20(PraxisPaymentsAddress);
    }
    
    function receive() public {
        uint256 amount = PraxisPayments.allowance(msg.sender, address(this));
        require(amount > 0,"Approved amount is zero.");
        PraxisPayments.transferFrom(msg.sender, address(this), amount);
        frozen[msg.sender] = frozen[msg.sender].add(amount);
    }
    
    function release() public {
        uint256 amount = frozen[msg.sender];
        require(amount > 0,"You don't have frozen PraxisPayments.");
        require(now >= releaseTime,"Release time is not reached.");
        frozen[msg.sender] = 0;
        PraxisPayments.transfer(msg.sender, amount);
    }
    
    function getTimeToRelease() public view returns(uint256) {
        if (now >= releaseTime)
            return(0);
        return(releaseTime.sub(now));
    }
    
    function getReleaseTime() public view returns(uint256) {
        return(releaseTime);
    }
    
    function getPraxisPaymentsAddress() public view returns(address) {
        return(address(PraxisPayments));
    }
    
    function getMyFrozenAmount() public view returns(uint256) {
        return(frozen[msg.sender]);
    }
    
    function getAllFrozenAmount() public view returns(uint256) {
        return(PraxisPayments.balanceOf(address(this)));
    }
}

//SourceUnit: ownable.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
contract ownable {
    address payable owner;
    modifier isOwner {
        require(owner == msg.sender,"You should be owner to call this function.");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

/*
    function changeOwner(address payable _owner) public isOwner {
        require(owner != _owner,"You must enter a new value.");
        owner = _owner;
    }

    function getOwner() public view returns(address) {
        return(owner);
    }
    
    function isUserOwner() public view returns(bool) {
        return(msg.sender == owner);
    }
*/    
}