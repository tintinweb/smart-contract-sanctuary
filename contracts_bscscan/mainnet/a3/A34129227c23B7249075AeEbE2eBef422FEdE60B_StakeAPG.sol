/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.2;
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.6.2;

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

/// Angel Pig (APG) Bank  - Savings contract for APG token holders
/// dev A savings account that holds APG tokens. 
/// Deposits are received by sending funds directly to the contract address. 
/// Withdraws are triggered by calling Withdraws from the same address that made the deposit.
/// 1% value of network transactions go to APG Bank as rewards
/// 3% fees are collected upon Withdrawal to reward remainders of savings account.

contract StakeAPG is Ownable{
    using SafeMath for uint256;
    
    uint256 numClients=0;
    
    uint private unlocked = 1;
    
    uint256 constant internal magnitude = 10**12;                 // With `magnitude`, we can properly assign div of reward_Rtotal and reward_Rinitial      

    mapping(address => uint256) reward_Rinitial;                  // Reward_Rtotal when depositor changed its state
    
    uint256 reward_Rtotal;                                        // Accumulated bank reward
    
    address public APGContractAddress;                            // APG contract address
    
    uint256 constant Thd = 1000000 * (10**6);                    // 1mil minimum deposit

    /// @notice Withdrawal fee, in parts per billion.
    uint256 FEE_RATIO_PPB = 3;                                    // 3% collection ratio

    mapping(address => uint256) principal;                        // Active savings for each account

    uint256 principal_total;                                    // Total Active savings of APG Bank (should always be equal or greater than 1 APG)


   

    /// @notice Stores the value of reward_Rtotal at deposit time.
    /// @dev Reward is computed at withdrawal time as a difference between current
    ///  total reward and total reward at deposit time, PER eligible unit.
    
    

    receive () external payable {}

    /// Initialize the contract.
    constructor() public {
        principal_total = 1;
        reward_Rtotal = 0;
    }
    
    function updateFee(uint256 _rate) external onlyOwner lock{
        FEE_RATIO_PPB = _rate;
    }
    
    function setContract(address _address) external onlyOwner lock{
        APGContractAddress = _address;
    }

    function APGContract() internal view returns (IERC20) {
        return IERC20(APGContractAddress);
    }
    
    function PMinRequired(uint256 principalT) internal pure returns (uint256){
        return principalT > 0 ? principalT : 1;
    }
    
    function computeCurrentReward(address _address) private view returns (uint256) {//called by core function deposit and withdraw, protected by lock
        return reward_Rtotal.sub(reward_Rinitial[_address]).mul(principal[_address]).div(magnitude);
    }


    /// @notice Deposit funds into contract.
    function deposit(address depositor, uint256 tokens) external onlyAPG lock  {
        require(tokens >= Thd,'APG Bank: Amount should be greater than 1 million');
        
        
        uint256 reward = computeCurrentReward(depositor);
        uint256 old_principal = principal[depositor];
        numClients = old_principal == 0 ? numClients.add(1) : numClients;
        uint256 new_principal = old_principal.add(tokens).add(reward);

        principal[depositor] = new_principal;
        principal_total = principal_total.add(new_principal).sub(old_principal);
        principal_total = PMinRequired(principal_total);
        // mark starting term in reward series
        reward_Rinitial[depositor] = reward_Rtotal;

        emit DepositMade(depositor, tokens);
    }


    /// @notice Withdraw funds associated with the sender address,
    ///  deducting fee and adding reward.
    function withdraw(address withdrawer) external onlyAPG lock {
        require(principal[withdrawer] > 0, 'APG Bank: Nothing to withdraw');
        // init
        uint256 original_principal = principal[withdrawer];
        uint256 fee = original_principal.mul(FEE_RATIO_PPB).div(100);  // all integer
        uint256 reward = computeCurrentReward(withdrawer);
        numClients = numClients.sub(1);
        // clear user account
        principal[withdrawer] = 0;
        reward_Rinitial[withdrawer] = 0;
        principal_total = principal_total.sub(original_principal);
        principal_total = PMinRequired(principal_total);
        addRewardInternal(fee);
        uint256 send_amount = original_principal.sub(fee).add(reward);
        APGContract().transfer(withdrawer, send_amount);

        emit WithdrawalMade(withdrawer, send_amount);
    }
    
    function addReward(uint256 newReward) external onlyAPG lock{
        uint256 RnewReward = newReward.mul(magnitude).div(principal_total);
        reward_Rtotal=reward_Rtotal.add(RnewReward);
    }
    
    function addRewardInternal(uint256 newReward) private {
        uint256 RnewReward = newReward.mul(magnitude).div(principal_total);
        reward_Rtotal=reward_Rtotal.add(RnewReward);
    }
    
    ///some public functions for frontend query
    function numTokensDeposited() external view returns (uint256){
        return principal_total;
    }
    
    function numClinetsLookup() external view returns (uint256){
        return numClients;
    }
    
    function numTokensforAddress(address _address) external view returns (uint256){
        return principal[_address];
    }
    
    
    /// @notice Returns the amount that would be sent by a real withdrawal.
    function simulateWithdrawal(address _address) external view returns (uint256) {
        uint256 original_principal = principal[_address];
        uint256 fee = original_principal.mul(FEE_RATIO_PPB).div(100);  
        uint256 reward = computeCurrentReward(_address);
        return original_principal.sub(fee).add(reward);
    }
    
    modifier lock() {
        require(unlocked == 1, 'APG Bank: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    modifier onlyAPG() {
        require(APGContractAddress == msg.sender, 'APG Bank: Only APG Contract can call');
        _;
    }
    event DepositMade(address _from, uint value);
    event WithdrawalMade(address _to, uint value);
    
}