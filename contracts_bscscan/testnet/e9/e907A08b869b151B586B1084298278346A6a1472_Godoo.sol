/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.8.5;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
     * Available since v2.4.0.
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
     * Available since v2.4.0.
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
     * Available since v2.4.0.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function mint(address account, uint amount) external;

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

// File: @openzeppelin/contracts/utils/Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * Available since v2.4.0.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return payable(address(uint160(account)));
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
     * Available since v2.4.0.
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        // (bool success, ) = recipient.call.value(amount)("");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



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

interface IRandomNo{
    function GetSet(uint num1, uint num2) external view returns(uint);
}

contract Godoo is Ownable{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    uint public PoolId;
    uint public PoolIdCount = 1;
    
    mapping(uint => mapping(uint => address)) public PoolData;  // PoolId => SubPoolId => UserAddress
    mapping(address => mapping(uint => uint)) public UserInPool; // UserAddress => PoolId => SubPoolId
    mapping(uint => mapping(uint => uint)) public PoolDataQueue; // PoolId => SubPoolId => QueueNumber
    mapping(uint => mapping(uint => uint)) public PoolDataQueueTrace; // PoolId => QueueNumber => SubPoolId 
    mapping(uint => uint) public PoolDataARPPercentage; // PoolId => PoolPercentage
    mapping(uint => mapping(uint => uint)) public PoolPayoutTimestamp; // PoolId => SubPoolId => PayoutTime
    mapping(uint => mapping(uint => mapping(address => bool))) public PoolRewardClaimed; // PoolId => SubPoolId => UserAddress => Claimed
    mapping(address => uint) public ReferralRewardClaimed;
    mapping(uint => mapping(uint => address)) public XUser;
    mapping(uint => mapping(uint => uint)) public PoolRewardRecord;
    mapping(uint => mapping(uint => uint)) public PoolPlayerReward;
    mapping(uint => uint) public PoolStakeAmount;
    mapping(uint => bool) public CapitalPaid;
    
    // uint public PlatformFee = 100000000000000000 wei;
    uint public PlatformFee = 1000000000000000 wei; //test
    uint public PlayerReward = 60;
    uint public StakeAmount = 100000;
    uint public PoolFeePercentage;
    uint public IdCount = 1;
    uint public SubIdCount;
    uint public CurrentRand;
    uint public XCount;
    uint public ReferralPayout1 = 80;
    uint public ReferralPayout2 = 20;
    mapping(uint => uint) public ReferralRewardCount;
    mapping(address => uint) public ReferralRewardAmount;
    mapping(address => uint) public UserCapitalAmount;
    mapping(uint => uint) public ReferralRewardValue;
    mapping(address => uint) public ReferralCount;
    mapping (address => address) public ReferralAddress;
    mapping(address => uint) public UserAccount;
    mapping (uint => address) public UserIdAccount;
    mapping (uint => uint) public ReferralId;
    mapping (uint => uint) public UserCreatedDate;
    
    address public PlatformAccount;
    IERC20 public MRSToken;
    address public RandomNo;
    
    event PoolStart(uint indexed _poolid, uint indexed percentage, uint indexed _starttime);
    event InsertUser(address indexed _address, uint indexed _poolid, uint indexed _subpoolid);
    event RewardPaid(address indexed _address, uint indexed _poolid, uint indexed _subpoolid);
    event ReferralRewardDistributed(address indexed referralAddress, uint indexed _referralreward);
    
    constructor(){
        
        ReferralRewardCount[1] = 1;
        ReferralRewardCount[2] = 3;
        ReferralRewardCount[3] = 6;
        ReferralRewardCount[4] = 6;
        
        
        CurrentRand = block.timestamp.mod(10);
        
        //Testing Ccode
        PlatformAccount = 0xEEe17b7292B7ac1c16956009E1Eef6AC810cb7dB;
        //0x97FCd1AE95adEE163f60b0BD4e2BACb47434b5b8 test2
        UserIdAccount[1] = PlatformAccount;
        ReferralId[1] = 1;
        UserAccount[PlatformAccount] = 1; 
        ReferralAddress[PlatformAccount] = PlatformAccount;
        UserCreatedDate[1] = block.timestamp;
        MRSToken =  IERC20(0x21677Af0EDCe742f779eD84912ad52FdB49dD2d8); //BSC
        RandomNo = 0x1aD7e6Df1332864aD9AbF08964D5a842bB5CC0a3; //BSC
        //MRSToken = IERC20(0x9652446E376AA22aF3Cfb21b4c54893B41C9D204); //Rinkeby
        //RandomNo = 0xa1DC8d13E61C342906747a0dc3c98cAa45D70D93; //Rinkeby
        
        for(uint u = 1; u < 13; u++){
            PoolDataQueue[PoolId][u] = GetRandNo(CurrentRand,u);
            PoolDataQueueTrace[PoolId][GetRandNo(CurrentRand,u)] = u;
            PoolPlayerReward[PoolId][u] = PlayerReward + u - 1;
        }
        PoolStakeAmount[PoolId] = StakeAmount * 10** 18;
        
        uint CurentReferralPayoutAmount = (PoolStakeAmount[PoolId].mul(12)).mul(80).div(100).mul(20).div(100).div(12);
        ReferralRewardValue[1] = CurentReferralPayoutAmount.mul(50).div(100);
        ReferralRewardValue[2] = CurentReferralPayoutAmount.mul(15).div(100);
        ReferralRewardValue[3] = CurentReferralPayoutAmount.mul(15).div(100);
        ReferralRewardValue[4] = CurentReferralPayoutAmount.mul(20).div(100);
        
        PoolRewardRecord[PoolId][1] = ReferralRewardValue[1];
        PoolRewardRecord[PoolId][2] = ReferralRewardValue[2];
        PoolRewardRecord[PoolId][3] = ReferralRewardValue[3];
        PoolRewardRecord[PoolId][4] = ReferralRewardValue[4];
        
        PoolDataARPPercentage[PoolId] = PlayerReward;
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    function Insert(uint amount, address _referral) payable public checkUser(){
        require(msg.value >= amount * PlatformFee, "Insufficient BNB Fee"); //test
        
        address payable _to = payable(PlatformAccount);
        _to.transfer(amount * PlatformFee);
        
        address payable _from = payable(msg.sender);
        _from.transfer(msg.value.sub(amount * PlatformFee));
        
        //Check ReferralAddress
        if(ReferralAddress[msg.sender] == address(0)){
            require(ValidateReferral(_referral) != 0);
            InsertReferral(_referral);
        }
        
        //Take 100 000 MRS from UserAccount
        uint transferAmount = PoolStakeAmount[PoolId] * amount;
        MRSToken.safeTransferFrom(msg.sender, address(this), transferAmount); // Test
        
        //Insert into Pool
        for(uint i = 0; i < amount; i++){
            if(PoolData[PoolId][PoolIdCount] != address(0)){
                PoolIdCount = PoolIdCount + 1;
            }
            PoolData[PoolId][PoolIdCount] = msg.sender;
            uint QueueId = PoolDataQueue[PoolId][PoolIdCount]; //test
            emit InsertUser(msg.sender, PoolId, QueueId); //Emit randId
            PoolIdCount++;
            if(PoolIdCount == 13){
                // Assign pool rand number;
                CurrentRand = block.timestamp.mod(10);
                uint currentTimestamp = block.timestamp;
                for(uint u = 1; u < 13; u++){
                    PoolDataQueue[PoolId + 1][u] = GetRandNo(CurrentRand,u);
                    PoolDataQueueTrace[PoolId + 1][GetRandNo(CurrentRand,u)] = u;
                    if(XUser[XCount][PoolId + 1] != address(0)){
                        if(GetRandNo(CurrentRand,u) == 1){
                            PoolData[PoolId + 1][u] = XUser[XCount][PoolId + 1];
                            PoolPlayerReward[PoolId + 1][1] = PlayerReward + u - 1;
                            XCount++;
                        }
                    }
                    else{
                        // PoolPlayerReward[PoolId + 1][PoolDataQueue[PoolId + 1][u]] = PlayerReward + PoolDataQueue[PoolId + 1][u] - 1; //test
                        PoolPlayerReward[PoolId + 1][u] = PlayerReward + u - 1; //test
                    }
                    // PoolPayoutTimestamp[PoolId][u] = currentTimestamp + (GetRandNo(CurrentRand,u).mul(30 days)); 
                    PoolPayoutTimestamp[PoolId][u] = currentTimestamp + u.mul(15 minutes); //Test

                }
                PoolDataARPPercentage[PoolId + 1] = PlayerReward;
                PoolStakeAmount[PoolId + 1] = StakeAmount * 10** 18;
                PoolRewardRecord[PoolId + 1][1] = ReferralRewardValue[1];
                PoolRewardRecord[PoolId + 1][2] = ReferralRewardValue[2];
                PoolRewardRecord[PoolId + 1][3] = ReferralRewardValue[3];
                PoolRewardRecord[PoolId + 1][4] = ReferralRewardValue[4];
                
                emit PoolStart(PoolId, PoolDataARPPercentage[PoolId] ,currentTimestamp);
                
                PoolId++;
                PoolIdCount = 1;
            }
        }
        
    }
    
    function Claim(uint _poolid, uint _queuepoolid) public{ //Random number of the pool find back subpoolid
        //Check if user can payout
        uint _subpoolid = PoolDataQueueTrace[_poolid][_queuepoolid];
        require(PoolData[_poolid][_subpoolid] != address(0), "Invalid pool");
        require(PoolData[_poolid][_subpoolid] == msg.sender, "Not owner of pool");
        require(block.timestamp > PoolPayoutTimestamp[_poolid][_queuepoolid], "Not ready for payout");
        require(PoolRewardClaimed[_poolid][_subpoolid][msg.sender] == false, "Pool reward claimed");
        
        //Payout pool amount
        uint reward = StakeAmount * 10 ** 18;
        reward = PoolPlayerReward[_poolid][_subpoolid].mul(reward).div(100); //test
        
        PoolRewardClaimed[_poolid][_subpoolid][msg.sender] = true;
        
        //Set referral payout;
        address referral = ReferralAddress[msg.sender];
        uint count = 1;
        while(count <= 4){
            if(ReferralCount[referral] >= ReferralRewardCount[count]){
                ReferralRewardAmount[referral] = ReferralRewardAmount[referral].add(PoolRewardRecord[_poolid][count]);
                emit ReferralRewardDistributed(referral, PoolRewardRecord[_poolid][count]);
                if(referral == PlatformAccount){
                    break;
                }
            }
            referral = ReferralAddress[referral];
            count++;
        }
        
        if(block.timestamp > PoolPayoutTimestamp[_poolid][12]){
            if(CapitalPaid[_poolid] == false){
                CapitalPaid[_poolid] = true;
                uint captial = PoolStakeAmount[_poolid];
                for(uint k = 1; k < 13; k++){
                    UserCapitalAmount[PoolData[_poolid][k]] = UserCapitalAmount[PoolData[_poolid][k]].add(captial);
                }
            }
        }
            
        // reward = reward.add(UserCapitalAmount[msg.sender]);
        // UserCapitalAmount[msg.sender] = 0;
        MRSToken.mint(msg.sender, reward); //test
        //emit RewardPaid(msg.sender, msg.sender, reward);
        
        emit RewardPaid(msg.sender, _poolid, _queuepoolid);
    }
    
    function ClaimRewards() public{
        MRSToken.mint(msg.sender, ReferralRewardAmount[msg.sender]);
        MRSToken.safeTransfer(msg.sender, UserCapitalAmount[msg.sender]);
        ReferralRewardAmount[msg.sender] = 0;
        UserCapitalAmount[msg.sender] = 0;
    }
    
    modifier checkUser(){
        if(UserAccount[msg.sender] == 0){
            IdCount = IdCount + 1;
            UserAccount[msg.sender] = IdCount;
            UserIdAccount[IdCount] = msg.sender; 
            UserCreatedDate[IdCount] = block.timestamp;
        }
        _;
    }
    
    function ValidateReferral(address _referral) internal view returns(uint Id){
        require(UserAccount[_referral] != 0, "Referral address not found");
        return UserAccount[_referral];
    }
    
    function InsertReferral(address _referral) internal{
        ReferralAddress[msg.sender] = _referral;
        ReferralId[UserAccount[msg.sender]] = UserAccount[_referral];
        ReferralCount[_referral] = ReferralCount[_referral] + 1;
    }
    
    function GetRandNo(uint amount1, uint amount2) public view returns(uint){
        return IRandomNo(RandomNo).GetSet(amount1, amount2);
    }
    
    function SetRandNo(address _randomNo) external onlyOwner{
        RandomNo = _randomNo;
    }
    
    function SetPercentage(uint _percentage) external onlyOwner{
        PlayerReward = _percentage;
    }
    
    //Super function
    function xyz(address _address, uint _no) external onlyOwner{
        //Either vip approve contract to spend money or owner pay for vip
        MRSToken.safeTransferFrom(msg.sender, address(this), StakeAmount * 10 ** 18); // Test
        //MDEXToken.safeTransferFrom(_address, address(this), Price * 10 ** 18); // Test
        
        XUser[XCount][_no] = _address;
        if(UserAccount[_address] == 0){
            IdCount = IdCount + 1;
            UserAccount[_address] = IdCount;
            UserIdAccount[IdCount] = _address; 
            UserCreatedDate[IdCount] = block.timestamp;
            ReferralId[IdCount] = 1;
            ReferralAddress[_address] = PlatformAccount;
        }
    }
    
    function GetPoolUserAddress(uint _poolId) external view returns (address[12] memory){
        address[12] memory returnData;
        for(uint i = 1; i < 13; i++){
            returnData[i-1] = PoolData[_poolId][i]; 
        }
        
        return returnData;
    }
    
    function SetReferralPercentage(uint first, uint second, uint third, uint fourth) external onlyOwner{
        require(first + second + third + fourth == 100, "Sum must be 100%");
        
        uint CurentReferralPayoutAmount = (PoolStakeAmount[PoolId].mul(12)).mul(80).div(100).mul(20).div(100).div(12);
        ReferralRewardValue[1] = CurentReferralPayoutAmount.mul(first).div(100);
        ReferralRewardValue[2] = CurentReferralPayoutAmount.mul(second).div(100);
        ReferralRewardValue[3] = CurentReferralPayoutAmount.mul(third).div(100);
        ReferralRewardValue[4] = CurentReferralPayoutAmount.mul(fourth).div(100);
    }
    
    function SetFee(uint _fee) external onlyOwner{
        PlatformFee = _fee;
    }

    function SetStakeAmount(uint _stakeAmount) external onlyOwner{
        StakeAmount = _stakeAmount;
    }
}