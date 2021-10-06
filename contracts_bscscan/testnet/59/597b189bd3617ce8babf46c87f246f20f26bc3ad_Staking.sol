/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

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


pragma solidity ^0.8.0;

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



// library for address array 
library AddressArrayLib {
    using AddressArrayLib for addresses;

    struct addresses {
        address[] array;
    }

    function add(addresses storage self, address _address)
        external
    {
        if(! exists(self, _address)){
            self.array.push(_address);
        }
    }

    function getIndexByAddress(
        addresses storage self,
        address _address
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists_;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _address) {
                index = i;
                exists_ = true;

                break;
            }
        }
        return (index, exists_);
    }

    function removeAddress(
        addresses storage self,
        address _address
    ) internal {
       for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                delete self.array[i];
            }
        }
    }


    function exists(
        addresses storage self,
        address _address
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                return true;
            }
        }
        return false;
    }
}

/**
 * @title Staking contract
 * @author Yogesh Singh
 * @notice This contract will store and manage staking at APY defined by owner
 * @dev Store, calculate, collect and transefer stakes and rewards to end user
 */
contract Staking is Ownable{

    using SafeMath for uint;
    
    // Custom lib for managing address[]
    using AddressArrayLib for AddressArrayLib.addresses;

    // Annual Percentage Yeild * 1000
    uint public APY;

    uint private APYTime = 5 minutes; // 365 days;

    // Lock duration in seconds
    uint public unstakeLockPeriod = 10 minutes; //10 days;
 
    // Address for erc20 Token
    address public erc20Token;
    
    // Token to manage ERC20 
    IERC20 private token;

    // Structure to store StakeHoders details
    struct  stackDetails {
        uint stake;
        uint reward;
        uint lastRewardCalculated;
    }

    // mapping to store current status for stackHolder
    mapping(address => stackDetails) public stackHolders;

    // Store all the stakeholders
    AddressArrayLib.addresses stakers;


    // Strcture to store unStake requests for user
    struct unStakeDetails {
        uint amount;
        uint lockingTime;
    }

    // mapping to store current status for stackHolder
    mapping(address => unStakeDetails[]) public unstakeRequests;

    // Manage total reward
    // uint public totalStake; // TODO Remove this and create pubic getter
    // uint public totalReward; // TODO Remove this and create pubic getter

    /**
     * @notice Constructor will set make you Owner of this contract,
     * set APY percentage and also store which Crypto Currency to manage
     * @param _APY Annual Percentage Yield * 1000
     * @param _erc20Token Address of erc20Token
     */
    constructor(uint _APY, address _erc20Token){
        transferOwnership(msg.sender);
        APY = _APY;
        erc20Token = _erc20Token;
        token = IERC20(_erc20Token);
    }

    /**
     * @dev This function is used to calculate current reward for stakeHolder
     * @param _stakeHolder The address of stakeHolder to calculate reward till current block
     * @return reward calculated till current block
     */
    function _calculateReward(address _stakeHolder) internal view returns(uint reward){
        stackDetails memory stackDetail = stackHolders[_stakeHolder];
        
        if (stackDetail.stake > 0){
            // Without safemath formula for explanation
            // reward = (
            //     (stackDetail.stake * APY * (block.timestamp - stackDetail.lastRewardCalculated)) /
            //     (APYTime * 100 * 1000)
            // );
    
            reward = stackDetail.stake.mul(APY).mul(
                block.timestamp.sub(stackDetail.lastRewardCalculated)
            ).div(
                APYTime.mul(100).mul(1000)
            );
        }
        else{
            reward = 0;
        }
    }

    /**
     * @dev This function is used to calculate Total reward for stakeHolder
     * @param _stakeHolder The address of stakeHolder to calculate Total reward 
     * @return reward total reward 
     */
    function calculateReward(address _stakeHolder) public view returns(uint reward){
        stackDetails memory stackDetail = stackHolders[_stakeHolder];
        reward = stackDetail.reward + _calculateReward(_stakeHolder);
    }

    /**
     * @param amount The amount user wants to add into his stake
     */
    function stack(uint amount) public {

        // Check if amount is allowed to spend the token
        require(token.allowance(msg.sender, address(this)) >= amount, "Staking: Must allow Spending");
        
        // Transfer the token to contract
        token.transferFrom(msg.sender, address(this), amount);

        // Calculate the last reward
        uint uncalculatedReward = _calculateReward(msg.sender);

        // Update the stake details
        stackHolders[msg.sender].stake += amount;
        stackHolders[msg.sender].reward += uncalculatedReward;
        stackHolders[msg.sender].lastRewardCalculated = block.timestamp;

        // Add into the array
        stakers.add(msg.sender);
    }

    /**
     * @dev Calculate the current reward, add with previous reward, Transefer
     * it to sender and update reward to 0
     * @notice This function will transfer the reward earned till now.
     */
    function claimReward() public {
        // Calculate the last reward
        uint uncalculatedReward = _calculateReward(msg.sender);

        // transfer the reward to stakeHolder
        // token.transfer(msg.sender, stackHolders[msg.sender].reward + uncalculatedReward);

        // Check for the allowance and transfer from the owners account
        require(
            token.allowance(owner(), address(this)) > stackHolders[msg.sender].reward + uncalculatedReward,
            "Sraking: Insufficient reward allowance from the Admin"
        );

        token.transferFrom(owner(), msg.sender, stackHolders[msg.sender].reward + uncalculatedReward);

        // Update the stake details
        stackHolders[msg.sender].reward = 0;
        stackHolders[msg.sender].lastRewardCalculated = block.timestamp;
    }

    /**
     * @dev calculate and update the reward, substract the unstaking amount and transfer to lock
     * @notice This function will calculate you reward till now and lock you requested 
     * unstake amount to lock state where it can be claimed after lock duration.
     * @param amount amount sender want's to unstake from his current stakings.
     */
    function requestUnstake(uint amount) public{
        // check if user have balance he requested for unstaking
        require(stackHolders[msg.sender].stake >= amount, "Staking: Requested unstaking more than balance");

        // Calculate the last reward
        uint uncalculatedReward = _calculateReward(msg.sender);

        // Update the stake details
        stackHolders[msg.sender].stake -= amount;
        stackHolders[msg.sender].reward += uncalculatedReward;
        stackHolders[msg.sender].lastRewardCalculated = block.timestamp;

        // store unstakable amount details
        unStakeDetails memory _unstakeDetail = unStakeDetails(amount, block.timestamp);

        // update the list of amount requested to unstake till now.
        unstakeRequests[msg.sender].push(_unstakeDetail);
    }

    /**
     * @dev Sum the unstake amounts requested by user before lock date.
     * @notice This function will return the sum of claimable unstake amount.
     * @param _stakeHolder Address of stakeHolder
     * @return availableAmount The amount that have completed lock duration
     */
    function getUnstakableAmount(address _stakeHolder) view public returns (uint availableAmount){
        availableAmount = 0;
        for (uint i=0; i < unstakeRequests[_stakeHolder].length; i++){
            if (unstakeRequests[_stakeHolder][i].lockingTime + unstakeLockPeriod < block.timestamp){
                availableAmount += unstakeRequests[_stakeHolder][i].amount;
            }
        }
    }

    /**
     * @dev Sum the unstakable amount delete and transfer the request to _stakeHolder
     * @notice This function will transfer the unstable amount to your wallet
     */
    function finizeUnstake() public {
        uint availableAmount = 0;
        for (uint i=0; i < unstakeRequests[msg.sender].length; ){

            // Check if the unstake request have passed the lock duration
            if (unstakeRequests[msg.sender][i].lockingTime + unstakeLockPeriod < block.timestamp){

                // Add amount to the sum
                availableAmount += unstakeRequests[msg.sender][i].amount;

                // Delete the detail
                unstakeRequests[msg.sender][i] = unstakeRequests[msg.sender][unstakeRequests[msg.sender].length - 1];
                unstakeRequests[msg.sender].pop();

            }
            else{
                i++; // Increament value only if not delete from the list
            }
        }

        require(availableAmount > 0, "You don't have any unstakeble amount");

        // Send the unstaked amout to stakeHolder
        token.transfer(msg.sender, availableAmount);
    }

    /**
     * @dev Returns array of stakeholder
     * @notice This function will give list of stakers who have staked any amount.
     * @return stakers.array the list os stakeholders
     */
    function getStakers() public view returns(address[] memory) {   
        return stakers.array;
    }

    /**
     * @dev Calculate and return total staked amount till now.
     * @notice This function will give you total of staked amount till now.
     * @return _totalStaked The sum of all staked amount
     */
    function totalStaked() public view returns (uint _totalStaked){
        uint sum = 0;
        for (uint i=0; i<stakers.array.length; i++){
            sum += stackHolders[stakers.array[i]].stake;
        }
        _totalStaked = sum;
    }

    /** 
     * @dev Calculate and return total undelivered rewards till now.
     * @notice This function will give you total of unclaimed rewards till now.
     * @return _totalReward Total ou unclaimed reward till now.
     */
    function totalReward() public view returns (uint _totalReward) {
        uint sum = 0;
        for (uint i=0; i<stakers.array.length; i++){
            sum += stackHolders[stakers.array[i]].reward;
            sum += _calculateReward(stakers.array[i]);
        }
        _totalReward = sum;
    }

    /**
     * @dev Function to check if contract have suffecient reward allowance or not
     * @notice This function will return if it has sufficient fund for paying the reward
     * @return True if have sufficient allowance for paying all the rewards
     */
    function haveSuffecientAllowanceForReward() public view returns(bool) {
        return token.allowance(owner(), address(this)) > totalReward();
    }
}