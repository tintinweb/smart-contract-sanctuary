/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.5.12;


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract DPRStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 DPR_UNIT = 10 ** 18;
    IERC20 public dpr;
    uint256 public staking_time = 270 days; // lock for 9 months
    uint256 private total_release_time; // linear release in 3 months
    uint256 public start_time;
    address public owner; 
    mapping (address => uint256) private user_staking_amount;
    mapping (address => uint256) private user_release_time;
    mapping (address => uint256) private user_claimed_map;
    mapping(address => string) private dpr_address_mapping;
    uint256[8] private staking_level = [
        20000 * DPR_UNIT, // 100 credit
        46800 * DPR_UNIT, // 200 credit
        76800 * DPR_UNIT, // 300 credit
        138000 * DPR_UNIT, // 400 credit
        218000 * DPR_UNIT, // 500 credit
        288000 * DPR_UNIT, // 600 credit
        368000 * DPR_UNIT, // 700 credit
        468000 * DPR_UNIT // 800 credit
    ];
    
    //modifiers
    modifier onlyOwner() {
        require(msg.sender==owner, "DPRStaking: Only owner can operate this function");
        _;
    }
    
    //events
    event Stake(address indexed user, string DPRAddress, uint256 indexed amount);
    event StakeChange(address indexed user, uint256 indexed oldAmount, uint256 indexed newAmount);
    event OwnerShipTransfer(address indexed oldOwner, address indexed newOwner);
    event DPRAddressChange(bytes32 oldAddress, bytes32 newAddress);
    event UserInfoChange(address indexed oldUser, address indexed newUser);
    event WithdrawAllFunds(address indexed to);
    event LinearTimeChange(uint256 day);

    constructor(IERC20 _dpr) public {
        dpr = _dpr;
        start_time = block.timestamp;
        total_release_time = 90 days; // for initialize
        owner = msg.sender;
    }

    function stake(string calldata DPRAddress, uint256 level) external returns(bool){
       require(level <= staking_level.length.sub(1), "DPRStaking: Level does not exist");
       require(user_staking_amount[msg.sender] == 0, "DPRStaking: Already stake, use addStaking instead");
       uint256 staking_amount = staking_level[level];
       dpr.safeTransferFrom(msg.sender, address(this), staking_amount);
       user_release_time[msg.sender] = block.timestamp.add(staking_time);
       user_staking_amount[msg.sender] = staking_amount;
       dpr_address_mapping[msg.sender] = DPRAddress;
       emit Stake(msg.sender, DPRAddress, staking_amount);
       return true;
    }

    function addStaking(uint256 level) external returns(bool) {
        // staking period checking
        require(block.timestamp <= start_time.add(staking_time), "DPRStaking: Execced Reward Period");
        require(level <= staking_level.length, "DPRStaking: Level does not exist");
        uint256 newStakingAmount = staking_level[level];
        uint256 oldStakingAmount = user_staking_amount[msg.sender];
        require(oldStakingAmount !=0, "DPRStaking: Please Stake first");
        require(oldStakingAmount < newStakingAmount, "DPRStaking: Can only upgrade your level");
        uint256 difference = newStakingAmount.sub(oldStakingAmount);
        dpr.safeTransferFrom(msg.sender, address(this), difference);
        //update user locking time
        user_staking_amount[msg.sender] = block.timestamp.add(staking_time); 
        //update user staking amount
        user_staking_amount[msg.sender] = staking_level[level];
        emit StakeChange(msg.sender, oldStakingAmount, newStakingAmount);
        return true;
    }

    function claim() external returns(bool){
        require(block.timestamp >= start_time.add(staking_time), "DPRStaking: Not reach the release time");
        // user staking end time checking
        require(block.timestamp >= user_release_time[msg.sender], "DPRStaking: Not release period");
        uint256 staking_amount = user_staking_amount[msg.sender];
        require(staking_amount > 0, "DPRStaking: Must stake first");
        uint256 user_claimed = user_claimed_map[msg.sender];
        uint256 claim_per_period = staking_amount.mul(1 days).div(total_release_time);
        uint256 time_pass = block.timestamp.sub(user_release_time[msg.sender]).div(1 days);
        uint256 total_claim_amount = claim_per_period * time_pass;
        if(total_claim_amount >= user_staking_amount[msg.sender]){
            total_claim_amount = user_staking_amount[msg.sender];
        }
        user_claimed_map[msg.sender] = total_claim_amount;
        uint256 claim_this_time = total_claim_amount.sub(user_claimed);
        dpr.safeTransfer(msg.sender, claim_this_time);
        return true;
    }

    function transferOwnership(address newOwner) onlyOwner external returns(bool){
        require(newOwner != address(0), "DPRStaking: Transfer Ownership to zero address");
        owner = newOwner;
        emit OwnerShipTransfer(msg.sender, newOwner);
    } 
    
    //for emergency case, Deeper Offical can help users to modify their staking info
    function modifyUserAddress(address user,  string calldata DPRAddress) external onlyOwner returns(bool){
        require(user_staking_amount[user] > 0, "DPRStaking: User does not have any record");
        bytes32 oldDPRAddressHash = keccak256(abi.encodePacked(dpr_address_mapping[user]));
        bytes32 newDPRAddressHash = keccak256(abi.encodePacked(DPRAddress));
        require(oldDPRAddressHash != newDPRAddressHash, "DPRStaking: DPRAddress is same"); 
        dpr_address_mapping[user] = DPRAddress;
        emit DPRAddressChange(oldDPRAddressHash, newDPRAddressHash);
        return true;

    }
    //for emergency case(User lost their control of their accounts), Deeper Offical can help users to transfer their staking info to a new address 
    function transferUserInfo(address oldUser, address newUser) external onlyOwner returns(bool){
        require(oldUser != newUser, "DPRStaking: Address are same");
        require(user_staking_amount[oldUser] > 0, "DPRStaking: Old user does not have any record");
        require(user_staking_amount[newUser] == 0, "DPRStaking: New user must a clean address");
        //Transfer Staking Info
        user_staking_amount[newUser] = user_staking_amount[oldUser];
        //Transfer release Info
        user_release_time[newUser] = user_release_time[oldUser];
        //Transfer claim Info
        user_claimed_map[newUser] = user_claimed_map[oldUser];
        //Transfer address mapping info
        dpr_address_mapping[newUser] = dpr_address_mapping[oldUser];
        //clear account
        clearAccount(oldUser);
        emit UserInfoChange(oldUser, newUser);
        
        return true;

    }
    //for emergency case, Deeper Offical have permission to withdraw all fund in the contract
    function withdrawAllFund() external onlyOwner returns(bool){
        dpr.safeTransfer(owner,dpr.balanceOf(address(this)));
        emit WithdrawAllFunds(owner);
        return true;
    }

    //Change the linear time before claim start
    function modifyLinearTime(uint256 newdays) onlyOwner external returns(bool){
        require(block.timestamp <= start_time.add(staking_time), "DPRStaking: Claim period has started");
        total_release_time = newdays * 86400;
        emit LinearTimeChange(newdays);
        return true;
    }

    function clearAccount(address user) private{
        delete user_staking_amount[user];
        delete user_release_time[user];
        delete user_claimed_map[user];
        delete dpr_address_mapping[user];
    }

    function getUserDPRAddress(address user) external view returns(string memory){
        return dpr_address_mapping[user];
    }

    function getReleaseTime(address user) external view returns(uint256){
        return user_release_time[user];
    }

    function getStaking(address user) external view returns(uint256){
        return user_staking_amount[user];
    }

    function getUserReleasePerDay(address user) external view returns(uint256){
        uint256 staking_amount = user_staking_amount[user];
        uint256 release_per_day = staking_amount.mul(1 days).div(total_release_time);
        return release_per_day;
    }

    function getUserClaimInfo(address user) external view returns(uint256){
        return user_claimed_map[user];
    }

    function getReleaseTimeInDays() external view returns(uint256){
        return total_release_time.div(1 days);
    }
}