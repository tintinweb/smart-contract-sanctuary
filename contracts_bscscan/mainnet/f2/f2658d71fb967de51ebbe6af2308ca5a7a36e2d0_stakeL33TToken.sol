/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
        ██╗  ██╗██╗  ██╗██╗  ██╗ ██████╗ ██████╗    ██╗    ██╗██╗███╗   ██╗
        ██║  ██║██║  ██║╚██╗██╔╝██╔═══██╗██╔══██╗   ██║    ██║██║████╗  ██║
        ███████║███████║ ╚███╔╝ ██║   ██║██████╔╝   ██║ █╗ ██║██║██╔██╗ ██║
        ██╔══██║╚════██║ ██╔██╗ ██║   ██║██╔══██╗   ██║███╗██║██║██║╚██╗██║
        ██║  ██║     ██║██╔╝ ██╗╚██████╔╝██║  ██║██╗╚███╔███╔╝██║██║ ╚████║
        ╚═╝  ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝                                                                                
*/

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

contract stakeL33TToken {
    using SafeMath for uint256;

    address L33TAddr = 0x06614c4e0A9eA44C57552111b9658c6ac956041e;
    L33TContract l33tContr = L33TContract(L33TAddr);

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public mask;
    mapping(address => uint256) public stakedBlock;
    uint256 public totalStaked;
    uint256 public distributedAmount;
    uint256 MULTIPLIER = 1000000000000000000;

    receive() external payable {
        distribute();
    }

    function distribute() public payable {
        require(totalStaked > 0);
        distributedAmount = distributedAmount.add(msg.value.mul(MULTIPLIER).div(totalStaked));
    }

    function calculateEarnings(address user) public view returns(uint256) {
        return distributedAmount.sub(mask[user]).mul(stakedAmount[user]).div(MULTIPLIER);
    }

    function stakeTokens(uint256 amount) public{
        // Make sure user withdraws funds and the mask is reset.
        withdrawEarnings();

        // Staking contracts transfers tokens from user to itself.
        l33tContr.transferFrom(msg.sender, address(this), amount);

        // 10% tax is applied and burned.
        uint256 unstakeTax = amount.div(10);
        l33tContr.transfer(0x000000000000000000000000000000000000dEaD, unstakeTax);

        // Subtract 10 percent from amount and add to statistics.
        uint256 addToStaking = amount.sub(unstakeTax);
        totalStaked = totalStaked.add(addToStaking);
        stakedAmount[msg.sender] = stakedAmount[msg.sender].add(addToStaking);

        // Initiate locking
        stakedBlock[msg.sender] = block.number;
    }

    function unstakeTokens(uint256 amount) public {
        // Make sure user has tokens staked equal or greater than the amount.
        require(stakedAmount[msg.sender] >= amount);

        // Calculate unlock time in seconds. If more than 8 days passed, reset lock to 7 days.
        bool isLocked = checkLock(msg.sender);
        if(isLocked == false){
            withdrawEarnings();

            // Update stats
            totalStaked = totalStaked.sub(amount);
            stakedAmount[msg.sender] = stakedAmount[msg.sender].sub(amount);

            // Transfer tokens to user
            l33tContr.transfer(msg.sender, amount);
        }
    }

    function checkLock(address user) public returns (bool){
        // Calculate how many blocks have been mined since user's stake block.
        uint256 passedBlocks = block.number.sub(stakedBlock[user]);

        if(passedBlocks >= 201600 && passedBlocks <= 230400) { // If more than 7 days and less than 8 days have passed, the tokens are unlocked.
            return false;
        } else if(passedBlocks > 230400) { // If more than 8 days have passed, user has lost the right to unstake. Reset timer to 7 days.
            stakedBlock[user] = block.number;
            return true;
        } else { 
            return true;
        }
    }

    function withdrawEarnings() public {
        // Calculate earnings and reset mask
        uint256 unclaimed = calculateEarnings(msg.sender);
        mask[msg.sender] = distributedAmount;
        if(unclaimed > 0){
            (bool success,) = payable(msg.sender).call{value: unclaimed}("");
            require(success);
        }
    }
}

// L33T Token contract functions
contract L33TContract {
    mapping (address => uint256) public _balances;
    function transfer(address recipient, uint256 amount) public  returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool){}
}