/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/access/Ownable.sol
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
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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

contract stakeBEBOP {
    using SafeMath for uint256;

    address public bebopAddress = 0x92077D8Ab2A229EcfDEF68F0Ad3E1A36fb841752;
    bebopContract bebopContr = bebopContract(bebopAddress);
    address public ownerAddress = 0x492b277A2EcEF7bC743Ac01E4fEd800263A4fA59;
    address public feeReceiver = 0x44140Eee349977c52C7b160A7D91ad5d97485f75;
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public mask;
    mapping(address => uint256) public stakedBlock;
    uint256 public totalStaked;
    uint256 public transferFee = 5;
    bool public unlockedBetweenXY = false;
    bool public unlockedAfterX = false;
    bool public timeLockActivated = false;
    uint256 public xBlock = 1;
    uint256 public yBlock = 2;
    uint256 public distributedAmount;
    uint256 MULTIPLIER = 1000000000000000000 ;

    receive() external payable {
        distribute();
    }

    function setMultiplier(uint256 newMultiplier) public {
        require(msg.sender == ownerAddress);
        MULTIPLIER = newMultiplier;
    }
    function setTransferFee(uint256 newFee) public {
        require(msg.sender == ownerAddress);
        transferFee = newFee;
    }

    function setFeeReceiver(address newFeeReceiver) public {
        require(msg.sender == ownerAddress);
        feeReceiver = newFeeReceiver;
    }

    function activateTimeLock(bool isActivated) public {
        require(msg.sender == ownerAddress);
        timeLockActivated = isActivated;
    }

    function activateTimeLockBetweenXY(bool isActivated) public {
        require(msg.sender == ownerAddress);
        unlockedBetweenXY = isActivated;
    }

    function activateTimeLockAfterX(bool isActivated) public {
        require(msg.sender == ownerAddress);
        unlockedAfterX = isActivated;
    }

    function setUnlockedAfterX(uint256 timeX, uint256 timeY) public {
        require(msg.sender == ownerAddress);
        xBlock = timeX;
        yBlock = timeY;
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
        bebopContr.transferFrom(msg.sender, address(this), amount);

        // 10% tax is applied and burned.
        uint256 unstakeTax = amount.div(transferFee);
        bebopContr.transfer(feeReceiver, unstakeTax);

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
        if(isLocked == false || timeLockActivated == false){
            
            withdrawEarnings();

            // Update stats
            totalStaked = totalStaked.sub(amount);
            stakedAmount[msg.sender] = stakedAmount[msg.sender].sub(amount);

            // Transfer tokens to user
            bebopContr.transfer(msg.sender, amount);
        }
    }

    function checkLock(address user) public returns (bool) {
        // Calculate how many blocks have been mined since user's stake block.
        uint256 passedBlocks = block.number.sub(stakedBlock[user]);
        if (unlockedBetweenXY == true) {
            if(passedBlocks >= xBlock && passedBlocks <= yBlock) { // If more than X days and less than Y days have passed, the tokens are unlocked.
                return false;
            }
            else if (passedBlocks > yBlock) {
                 // If more than X days have passed, user has lost the right to unstake. Reset timer to X days.
                stakedBlock[user] = block.number;
                return true;
            }
            else {
                return true;
            }
        }
        else if (unlockedAfterX == true) {
            if(passedBlocks >= xBlock) { // If more than 7 days and less than 8 days have passed, the tokens are unlocked.
                return false;
            }
            else {
                return true;
            }
        }

        else { 
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



// BEBOP Token contract functions
contract bebopContract {
    mapping (address => uint256) public _balances;
    function transfer(address recipient, uint256 amount) public  returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool){}
}