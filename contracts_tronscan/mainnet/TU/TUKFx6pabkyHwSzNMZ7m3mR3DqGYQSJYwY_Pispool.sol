//SourceUnit: newpispool.sol


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


pragma solidity ^0.5.0;

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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
    constructor () internal {
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

// File: @openzeppelin/contracts/token/TRC20/ITRC20.sol

pragma solidity ^0.5.0;

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

   // function burn(uint256 amount) external returns (bool);
    function burn(uint256 amount)  external;

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

pragma solidity ^0.5.4;

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
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address ) {
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
    function sendValue(address  recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/TRC20/SafeTRC20.sol

//pragma solidity ^0.5.0;




/**
 * @title SafeTRC20
 * @dev Wrappers around TRC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeTRC20 for TRC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeTRC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 _tokenAddress, address _to, uint256 _value) internal returns (bool success){
        //callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        bytes memory msg = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
        uint msgSize = msg.length;

        assembly {
            // pre-set scratch space to all bits set
            mstore(0x00, 0xff)

            // note: this requires tangerine whistle compatible EVM
            if iszero(call(gas(), _tokenAddress, 0, add(msg, 0x20), msgSize, 0x00, 0x20)) { revert(0, 0) }

            switch mload(0x00)
            case 0xff {
                // token is not fully ERC20 compatible, didn't return anything, assume it was successful
                success := 1
            }
            case 0x01 {
                success := 1
            }
            case 0x00 {
                success := 0
            }
            default {
                // unexpected value, what could this be?
                revert(0, 0)
            }
        }
        
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeBurn(ITRC20 token, uint256 value) internal {

        callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
    //function burn(uint256 amount) public  ();

    function totalSupply() public view returns (uint256);
}

// File: contracts/IRewardDistributionRecipient.sol

pragma solidity ^0.5.0;



contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}















pragma solidity 0.5.8;
//import "Console.sol";

contract Pispool is IRewardDistributionRecipient {
    using SafeMath for uint256;

    uint256 private totalUsers;

    struct Deposit {  
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct Downline {  
        address downusr;
        uint256 referrerpower;
        uint256 start;
    }

    struct User {
        uint256 superpower;

        uint256 allpower;

        mapping(address => Downline) downlineComm; 
        address []  listdownline; 
        uint256 referrerpower; 
        Downline maxdownlinuser; 

       
        uint256 loanpower;

        address referrer;
        uint256 starttime;//start time 
        uint256 startsuperpower;
        uint256 lastertime; // end change time

        uint256 loantime;

    }


    uint256 constant public INVEST_MIN_AMOUNT =  100000000;//100*1000000 ;//100 usdt
    uint256 constant public REFER_MIN_AMOUNT =  10000;  //10000;//1000000*0.01 ;//
    uint256 constant public COMM_MIN_AMOUNT =  3000000000;    //3000000000

    mapping (address => User) internal Users;


    uint256 top49Commpower; 

    uint256 public allsuperpower; 
    uint256 public allloanpower;

    uint256 public allreferrerpower;
    uint256 public usdtBalances;

    mapping(address => uint256) private _pusdbalances;



    uint256 public constant DURATION = 4*365 days;
    uint256 public constant HALFDOWNPOWER = 180 days;

    uint256 public constant DAYSFOUTITY = 14 days;  //10 minutes;//14 days;
    uint256 public constant ONEDAYS = 1 days;

    uint256 public starttime = 1599310800; //Saturday, 5 September 2020 13:00:00 (UTC)

    uint256 public initreward = 1*1e18;

    uint256 public burnpis;
    
    // 41093A23C8A470ABC3793811CF9AA5A619802D4B39
    ITRC20 public pis = ITRC20(0x41093A23C8A470ABC3793811CF9AA5A619802D4B39);  // Pis token
    
    // 41128AC27C6E9441EB70030F9F85B28993C42EEC8F
    ITRC20 public pusd = ITRC20(0x41128AC27C6E9441EB70030F9F85B28993C42EEC8F);  // PUSD

    ITRC20 public usdt = ITRC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c); // USDT


    mapping(uint256 => bool) private bonuspaieddays;
    mapping(uint256 => mapping(address => bool)) private top49hadbonus;
    mapping(uint256 => mapping(address => bool)) private top200hadbonus;


    uint256 public constant ONEDAYSUPPLY = 68400*1e18;
    uint256 [] DaoPower24 = [
        0x41113519C4DCBFA943A331977E715B825E9A80DDDE,
        0x41805D3E48F61EC6652F08578116B39CD40B54C4B1,
        0x416516C59DDE5DED6ABD6F7DF62CB650E7B28C24BE,
        0x41C0182F1366F1B27F3542E19F9216843B9920128F,
        0x41083BC8F8DE35A6103F521974477F2B3517ED58A3,
        0x41F1DC3FBF7F4B992F70871821147A0373D4CE6526,
        0x4129A715A1E06C21169844C5BAC8B2E15E00F94DC9,
        0x41942ED1F19D60FB5E89E72DCF64AADCB6DE28A18B,
        0x4116F9CC57CD03A30B2A44BDDB235B6541CDCD0210,
        0x4124B72361B77E00EE1D78015DCF0385D266F6ECA8,
        0x4164063548656225B2D61ABFAC49BC141BC79B2DF0,
        0x4166E027A4AA6D32AEA3C6ED5CAC39BBAAC89FDD7D,
        0x412E7ADF6AAAB4561DE6C15C2AB17DDBE35D84ECC9,
        0x41BCDEB9EC1BC22E8904ADDC86904FBDD2CE09E794,
        0x410FCCF17793BE0E9D270F9E2130D88826660A3AC8,
        0x413FF68664CD6F20437DF83C2C6CABA6C2ADB15D38,
        0x41B53A44F5F7D43D1A959B5D722D2DB742E0A816E3,
        0x41C486A6B6AF888D75F8749CF76B22A26F36147593,
        0x41351D945B78EFE9A7CD270589701B2E8C9515E1FB,
        0x4152678DC89D14EC2E4218F7586D4F4D5ADF249CF1,
        0x41AD3606FEBBA76BE0C25412C4CB4B5147996FC545,
        0x414B7499111301639968F29377E9A25A27FE5A1FFE,
        0x418200AC041E08395FEA947BBA71B75956E311F9ED,
        0x41441C45A14104C86B1E15D2B77EDDE5DDBC1EE4BB

      ] ;

    struct Node {
      address next;
      address prev;
    }
    address constant GUARD = address(1);

    mapping(address => uint256) private scores2;

    mapping(address => Node) private Dlist2;
    uint256 private listSize2;
    address private listend2;

    mapping(address => uint256) private scores3;

    mapping(address => Node) private Dlist3;
    uint256 private listSize3;
    address private listend3;  
    uint256 private periodFinish = 0;
    uint256 private rewardRate = 0;
    uint256 private lastUpdateTime;
    uint256 private lastUpdateTimeRefer;

    uint256 private rewardPerTokenStored;
    address public governance;
    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;

    uint256 private rewardRateRefer = 0;
    uint256 private rewardPerTokenStoredRefer;
    mapping(address => uint256) private userRewardPerTokenPaidRefer;
    mapping(address => uint256) private rewardsRefer;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);



    event BuySuperPower(address indexed user, uint256 amount);
    event StakedPusd(address indexed user, uint256 amount);


    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    
    event PisSwapToUsdt(address user, uint256 amount, uint256 usdtchange);
    event DaoPowerBonus(address user, uint256 amount);
    event Top49CommPowerBonus(address user, uint256 amount, uint256 compower);
    event Top200PowerBonus(address user, uint256 amount, uint256 superpower );

    constructor( uint256 _starttime ) public {
        starttime = _starttime;
        //starttime = now;
        governance = msg.sender;


        Dlist2[GUARD].next = GUARD;
        Dlist2[GUARD].prev = GUARD;

        Dlist3[GUARD].next = GUARD;
        Dlist3[GUARD].prev = GUARD;

    }

    function GetUserData(address userAddress) public view returns(address, uint256, uint256, uint256, uint256,address ,uint256 ) {
        User storage user = Users[userAddress];
        return (user.referrer, user.superpower, user.allpower, user.referrerpower, 
        user.loanpower, user.maxdownlinuser.downusr,user.maxdownlinuser.referrerpower);
    }

    function GetUserDatalite(address userAddress) public view returns(uint256, uint256) {
        User storage user = Users[userAddress];
        return (user.superpower.add(user.loanpower.mul(3)),  user.referrerpower);    
    }
    
    function GetUserDatalistdownline(address userAddress) public view returns(address []memory ) {
        User storage user = Users[userAddress];
        return (user.listdownline);
    }
    
    function GetUserDownlinereferrerpower(address userAddress, address downline) public view returns(uint256 ) {
        User storage user = Users[userAddress];
        return (user.downlineComm[downline].referrerpower);
    }


    function UpdateUplineUser(address nowline,address upline, uint256 lever1) internal {
            if (upline != address(0)) {
                Users[upline].referrerpower = Users[upline].referrerpower.add(lever1);
                if (Users[upline].downlineComm[nowline].downusr == address(0)){
                    Users[upline].downlineComm[nowline]=Downline(nowline, lever1, block.timestamp);
                    Users[upline].listdownline.push(nowline);
                } else {
                    Users[upline].downlineComm[nowline].referrerpower =
                     Users[upline].downlineComm[nowline].referrerpower.add(lever1);
                }

                if (Users[upline].superpower>= COMM_MIN_AMOUNT) {//3000u
                    if (Users[upline].maxdownlinuser.referrerpower ==0 ) { 
                         Downline memory temp = Downline(address(0), 0, 0);
                        if (Users[upline].listdownline.length > 0) {
                            if (Users[upline].listdownline.length == 1) {
                                Users[upline].maxdownlinuser = Downline(nowline, lever1, block.timestamp);
                            } else {
                                    temp = Users[upline].downlineComm[Users[upline].listdownline[0]];
                                    for (uint i = 1; i < Users[upline].listdownline.length; i++) {
                                         if (temp.referrerpower<Users[upline].downlineComm[Users[upline].listdownline[i]].referrerpower) {
                                            temp = Users[upline].downlineComm[Users[upline].listdownline[i]];
                                         } else 
                                         if (temp.referrerpower == Users[upline].downlineComm[Users[upline].listdownline[i]].referrerpower) {

                                            if (temp.start>Users[upline].downlineComm[Users[upline].listdownline[i]].start) {
                                                temp = Users[upline].downlineComm[Users[upline].listdownline[i]];
                                            }
                                         }
                                }
                                Users[upline].maxdownlinuser = temp;
                            }

                        }
                    } else {
                        if (Users[upline].maxdownlinuser.downusr != nowline) {
                            if (Users[upline].maxdownlinuser.referrerpower < Users[upline].downlineComm[nowline].referrerpower){
                                Users[upline].maxdownlinuser=Users[upline].downlineComm[nowline];
                            } else if (Users[upline].maxdownlinuser.referrerpower == Users[upline].downlineComm[nowline].referrerpower) {
                                    if (Users[upline].maxdownlinuser.start>Users[upline].downlineComm[nowline].start) {
                                        Users[upline].maxdownlinuser=Users[upline].downlineComm[nowline];
                                    }
                            }
                        } else if (Users[upline].maxdownlinuser.downusr == nowline){
                            Users[upline].maxdownlinuser.referrerpower = 
                            Users[upline].maxdownlinuser.referrerpower.add(lever1);
                        }

                    }


                if (listSize2 < 49 ) {
                    if (Dlist2[upline].next == address(0) ) {
                        addSomenode2(upline, Users[upline].referrerpower);
                    } else {
                        increaseScore2(upline,lever1);
                    }
                } else if (listSize2 >= 49 ) {
                    if (Dlist2[upline].next == address(0) )  {
                        //>49
                        if (scores2[listend2] < Users[upline].referrerpower ) {
                            //
                            removeSomenode2(listend2);
                            addSomenode2(upline, Users[upline].referrerpower);
                        }
                        if (listSize2 >49) {
                            remove49();
                        }

                    } else {    
                        // 
                        increaseScore2(upline,lever1);

                        if (listSize2 > 49) {
                                remove49();
                            }
                    }

                } 
            }

       }
    }
    

    function top49AdressCommpowerBonus(address currentAddress) public onlyRewardDistribution  returns (bool){
        uint256 subnum = block.timestamp.sub(starttime);
        uint256 dayssub = subnum.div(ONEDAYS);
        require(!top49hadbonus[dayssub][currentAddress], "currentAddress this day had paied bonus");
        top49hadbonus[dayssub][currentAddress]=true;
        uint256 alltoppower = gettop49Commpower();
        uint256 pissupply = ONEDAYSUPPLY.div(100).mul(15);
        if (alltoppower > 0) {
            //uint256 uinitpis= pissupply.div(alltoppower);

             uint256 one=(Users[currentAddress].maxdownlinuser.referrerpower).div( 5) +
                (Users[currentAddress].referrerpower - Users[currentAddress].maxdownlinuser.referrerpower).div(10);
                uint256 bonus = one.mul(pissupply).div(alltoppower);

                if (bonus >0) {
                    pis.mint(currentAddress,bonus);
                    emit Top49CommPowerBonus(currentAddress, bonus, one);

                }
        }
         return true;
    }

    function top200powerBonus() public onlyRewardDistribution {
        uint256 top200supply = ONEDAYSUPPLY.div(100).mul(10);

        if (listSize3 <200) {
            pis.mint(address(this), top200supply);
            pis.burn(top200supply);
            burnpis = burnpis.add(top200supply);
        } else {
            uint256 top200supply1 = ONEDAYSUPPLY.div(100).mul(3).div(8);
            uint256 top200supply2 = ONEDAYSUPPLY.div(100).mul(3).div(41);
            uint256 top200supply3 = ONEDAYSUPPLY.div(100).mul(4).div(151);

            address currentAddress = Dlist3[GUARD].next;

            for(uint i=0; i< 200 ;i++ ) { 
                if(i<=7) {
                        pis.mint(currentAddress, top200supply1);
                        emit Top200PowerBonus(currentAddress, top200supply1, scores3[currentAddress]);
                        currentAddress = currentAddress = Dlist3[currentAddress].next;
                    } else if (i>7 && i<=48) {
                        pis.mint(currentAddress,top200supply2);
                        emit Top200PowerBonus(currentAddress, top200supply2, scores3[currentAddress]);

                        currentAddress = currentAddress = Dlist3[currentAddress].next;


                    } else {
                        pis.mint(currentAddress,top200supply3);
                        emit Top200PowerBonus(currentAddress, top200supply3, scores3[currentAddress]);                        
                        currentAddress = currentAddress = Dlist3[currentAddress].next;
                    }
            }

        }
    }

    function top200AddresspowerBonus(address currentAddress, uint256 index) public onlyRewardDistribution returns (bool) {
        uint256 subnum = block.timestamp.sub(starttime);
        uint256 dayssub = subnum.div(ONEDAYS);
        require(!top200hadbonus[dayssub][currentAddress], "currentAddress this day had paied bonus");
        uint256 top200supply = ONEDAYSUPPLY.div(100).mul(10);
        top200hadbonus[dayssub][currentAddress] =true;

        if (listSize3 <200) {
             require(!top200hadbonus[dayssub][address(0)], "currentAddress this day had paied bonus");
             top200hadbonus[dayssub][address(0)] =true;
            pis.mint(address(this), top200supply);
            pis.burn(top200supply);
            burnpis = burnpis.add(top200supply);
        } else {
           
            uint256 top200supply1 = ONEDAYSUPPLY.div(100).mul(3).div(8);
            uint256 top200supply2 = ONEDAYSUPPLY.div(100).mul(3).div(41);
            uint256 top200supply3 = ONEDAYSUPPLY.div(100).mul(4).div(151);


            if(index<=7) {
                    pis.mint(currentAddress, top200supply1);
                    emit Top200PowerBonus(currentAddress, top200supply1, scores3[currentAddress]);
                    //currentAddress = currentAddress = Dlist3[currentAddress].next;
                } else if (index>7 && index<=48) {
                    pis.mint(currentAddress,top200supply2);
                    emit Top200PowerBonus(currentAddress, top200supply2, scores3[currentAddress]);

                    //currentAddress = currentAddress = Dlist3[currentAddress].next;


                } else {
                    pis.mint(currentAddress,top200supply3);
                    emit Top200PowerBonus(currentAddress, top200supply3, scores3[currentAddress]);                        
                    //currentAddress = currentAddress = Dlist3[currentAddress].next;
                }
            

        }
         return true;
    }    

    function daysbonus()  external  onlyRewardDistribution {
        uint256 subnum = block.timestamp.sub(starttime);
        uint256 dayssub = subnum.div(ONEDAYS);
        require(!bonuspaieddays[dayssub], " day had paied bonus");
        uint256 modnum = subnum.mod(ONEDAYS);

        require(modnum>=82800 && modnum<86400, " not time to pay");

        bonuspaieddays[dayssub] = true;

        DaopowerBonus();

    }


 function getTop49() public view returns(address[] memory) {

     address[] memory nodeLists = new address[](listSize2);
     address currentAddress = Dlist2[GUARD].next;
     for(uint256 i = 0; i < listSize2; ++i) {
       nodeLists[i] = currentAddress;
       currentAddress = Dlist2[currentAddress].next;
     }
     return nodeLists;
   }

function getTop200() public view returns(address[] memory) {
 
     address[] memory nodeLists = new address[](listSize3);
     address currentAddress = Dlist3[GUARD].next;
     for(uint256 i = 0; i < listSize3; ++i) {
        nodeLists[i] = currentAddress;
       currentAddress = Dlist3[currentAddress].next;
     }
     return nodeLists;
   }



    function PisTotalSupply() public view returns(uint256) {
            return pis.totalSupply();
            //return 1;
        }
    
    function totalAllUsers() public view returns(uint256) {
            return totalUsers;
        }

    
    function totalBurnPis() public view returns(uint256) {
            return burnpis;
        }

    function totalBurnPisToUsdt() public view returns(uint256) {

            return pisSwapToUsdtformula(burnpis);
        }

  
    function totalPusdStake() public view returns(uint256) {
            return allloanpower;
        }  


    function totalusdtBalances() public view returns(uint256) {
            return usdtBalances;
        }  
      


    function DaopowerBonus() internal returns (bool){
        uint256 Daosupply = ONEDAYSUPPLY.div(100).mul(15);
        pis.mint(address(this), Daosupply);
        
        //uint256 totalsupply = PisTotalSupply();
        
        //uint256 hoursnub = block.timestamp.sub(starttime).div(3600);
        //uint256 rates = hours.mul(27).div(10000).add(5.div(100));

        
        //uint256 pisfel = usdtBalances.div(totalsupply);
        //uint256 usdtchange = Daosupply.mul(usdtBalances).mul(5).div(totalsupply).div(100)+
        //            Daosupply.mul(usdtBalances).mul(27).div(totalsupply).div(10000) ;
        
        uint256 usdtchange = pisSwapToUsdtformula(Daosupply);
        
        burnpis =burnpis.add(Daosupply);

        if (usdtchange >usdtBalances) {
            usdtchange = usdtBalances;
        }
        usdtBalances = usdtBalances.sub(usdtchange);
            
        //uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        //return  random%100;

        require(usdtchange >0, "not enough  usdt");

        if (usdtchange < 24 ) {
            usdt.transfer(address(DaoPower24[0]), usdtchange);
            emit DaoPowerBonus(address(DaoPower24[0]), usdtchange);

        } else {
            uint256 div24 = usdtchange.sub(24).div(24);

            //DaoPower24;
            uint256 hadsend;
            for(uint j=0;j<24 ;j++) {
                if (j== 23) {
                    usdt.transfer(address(DaoPower24[j]), usdtchange.sub(hadsend));
                    emit DaoPowerBonus(address(DaoPower24[j]), usdtchange.sub(hadsend));
                } else {
                    uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now))).mod(div24);
                    usdt.transfer(address(DaoPower24[j]), random.add(1));
                    hadsend.add(random).add(1);
                    emit DaoPowerBonus(address(DaoPower24[j]), random.add(1));
                }

            }

        }
        pis.burn(Daosupply);
        return true;

    }

    function pisSwapToUsdtformula(uint256 mount) public view returns(uint256) {
        uint256 totalsupply = PisTotalSupply();
        //uint256 Daosupply = ONEDAYSUPPLY.div(100).mul(15);
        if (totalsupply == 0) {
            return 0;
        } else {
            uint256 hoursnub = block.timestamp.sub(starttime).div(3600);
            return mount.mul(usdtBalances).mul((hoursnub.mul(26946).div(1000)).add(2000)).div(totalsupply).div(1000000);

            //return mount.mul(usdtBalances).mul(5).div(totalsupply).div(100)+
            //        mount.mul(usdtBalances).mul(27).div(totalsupply).div(10000) ;
        }
    }

    
    function PisSwapToUSDT(uint256 amount) public {
        
        require(amount >0, "not swap 0");
        pis.transferFrom(msg.sender, address(this), amount);
        burnpis =burnpis.add(amount);

        uint256 usdtchange = pisSwapToUsdtformula(amount);
        require(usdtBalances >=usdtchange);
        require(usdtchange >0, "not enough  usdt");
        usdt.transfer(msg.sender, usdtchange);
        usdtBalances = usdtBalances.sub(usdtchange);
        pis.burn(amount);

        emit PisSwapToUsdt(msg.sender, amount, usdtchange);
    }


    function gettop49Commpower()  public view returns(uint256) {
    
        uint256 commsupplypower;
        if (listSize2>0) {
            address currentAddress = Dlist2[GUARD].next;
            for(uint i=0; i< listSize2 ;i++ ) {
                commsupplypower= commsupplypower.add( (Users[currentAddress].maxdownlinuser.referrerpower).div( 5) +
                (Users[currentAddress].referrerpower - Users[currentAddress].maxdownlinuser.referrerpower).div(10)) ;
            }
            return commsupplypower;
        } else {
            return 0;
        }

    }

    function remove49() internal {
        if (listSize2 <=49) {
        } else {
            while (listSize2 > 49) {
                  removeSomenode2(listend2);
            }
        }
    }

    function remove200()  internal {
        if (listSize3 <=200) {
        } else {
            while (listSize3 > 200) {
                  removeSomenode3(listend3);
            }
        }

    }

    function buySuperPower(address referrer, uint256 amount) public updateReward(msg.sender) updateRewardRefer(msg.sender) checkhalve  checkStart {
        require(amount >= INVEST_MIN_AMOUNT);

        //ITRC20  y = ITRC20(0x41fcadae83b37e55293264f2095968990e577e7d63); // USDT
        usdt.transferFrom(msg.sender, address(this), amount);
        usdtBalances = usdtBalances.add(amount);

        User storage user = Users[msg.sender];
        allsuperpower = allsuperpower.add(amount);
        if (user.superpower == 0) { 
            user.starttime = block.timestamp;
            user.lastertime = block.timestamp;
            user.startsuperpower = amount;
            totalUsers = totalUsers.add(1);
        } else { 
            user.lastertime = block.timestamp;
        }
        user.superpower = user.superpower.add(amount);
        user.allpower = user.allpower.add(amount);
        //user.useraddress = msg.sender;


        if (user.referrer == address(0) && Users[referrer].superpower > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }
        
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            uint256 lever1 = amount.div(4);
            address nowline = msg.sender;

            while (lever1 > REFER_MIN_AMOUNT && upline !=address(0) ) {
                allreferrerpower = allreferrerpower.add(lever1);
                UpdateUplineUser (nowline, upline, lever1);
                lever1 = lever1.div(2);
                nowline = upline;
                upline = Users[upline].referrer;
            }

        } 

        
        if (Dlist3[msg.sender].next!= address(0)) { 
            //
            if (listSize3 <= 200) {
                increaseScore3(msg.sender, amount);
            } if (listSize3 > 200) {
                increaseScore3(msg.sender, amount);
                remove200();
            }
        } else {
            if (listSize3<200) {
                addSomenode3(msg.sender, user.superpower);

            } else if (listSize3 >= 200) {
                if(scores3[listend3] < user.superpower){
                    removeSomenode3(listend3);
                    addSomenode3(msg.sender, user.superpower);

                    if (listSize3 > 200) {
                        remove200();
                    }
                }
            }
        }

        emit BuySuperPower(msg.sender, amount);

    }


/////////////////////////////////////

    


    function totalSupply() public view returns (uint256) {
        return allsuperpower.add(allloanpower.mul(3));
    }

    function totalSupplyRefer() public view returns (uint256) {
        return allreferrerpower;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();

        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

   modifier updateRewardRefer(address account) {
        rewardPerTokenStoredRefer = rewardPerTokenRefer();
        lastUpdateTimeRefer = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewardsRefer[account] = earnedRefer(account);
            userRewardPerTokenPaidRefer[account] = rewardPerTokenStoredRefer;
        }
        _;
    }    

    function rewardPerToken() internal view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function rewardPerTokenRefer() internal view returns (uint256) {
        if (totalSupplyRefer() == 0) {
            return rewardPerTokenStoredRefer;
        }
        return
            rewardPerTokenStoredRefer.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTimeRefer)
                    .mul(rewardRateRefer)
                    .mul(1e18)
                    .div(totalSupplyRefer())
            );
    }    

    function userallpower(address account) public view returns (uint256) {
            User storage user = Users[account];
            if (user.superpower >0){
                if (block.timestamp> (user.lastertime.add(HALFDOWNPOWER)) ) {
                    return (user.superpower.sub(user.startsuperpower.div(2)).add(user.loanpower.mul(3)));
                } else {
                    return user.superpower.add(user.loanpower.mul(3));
                }

            } else {
                return 0;
            }
        
    }

    function earned(address account) public view returns (uint256) {
        return
            userallpower(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

     function earnedRefer(address account) public view returns (uint256) {
        return
            Users[account].referrerpower
                .mul(rewardPerTokenRefer().sub(userRewardPerTokenPaidRefer[account]))
                .div(1e18)
                .add(rewardsRefer[account]);
    }   

    function getReward() public updateReward(msg.sender) updateRewardRefer(msg.sender) checkhalve checkStart{
        uint256 reward = earned(msg.sender);
        uint256 rewardRefer = earnedRefer(msg.sender);
        reward = reward.add(rewardRefer);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsRefer[msg.sender] = 0;

            //pis.safeTransfer(msg.sender, reward);

            pis.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkhalve(){
        if (block.timestamp >= periodFinish) {
            initreward = initreward.mul(50).div(100); 

            pis.mint(address(this),initreward.add(initreward.div(2)));

            rewardRate = initreward.div(DURATION);
            rewardRateRefer = initreward.div(DURATION).div(2);
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initreward);
        } 
        _;
    }    

    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    function canWithdraw() public view returns (uint256) {

        //require(block.timestamp > Users[msg.sender].loantime.add(DAYSFOUTITY), "no end time");
        if (block.timestamp > Users[msg.sender].loantime.add(DAYSFOUTITY)) {
            return _pusdbalances[msg.sender];
        } else {
            return 0;
        }
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) updateRewardRefer(msg.sender) checkhalve checkStart{
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= _pusdbalances[msg.sender], "Cannot withdraw big");

        require(block.timestamp > Users[msg.sender].loantime.add(DAYSFOUTITY), "no end time");

        allloanpower = allloanpower.sub(amount);
        _pusdbalances[msg.sender] = _pusdbalances[msg.sender].sub(amount);
        Users[msg.sender].loanpower = Users[msg.sender].loanpower.sub(amount);
        pusd.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(_pusdbalances[msg.sender]);
        getReward();
    }
    

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
            rewardRateRefer = reward.div(2).div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);

            uint256 leftoverRefer = remaining.mul(rewardRateRefer);

            rewardRateRefer = (reward.div(2)).add(leftoverRefer).div(DURATION);

        }

        //pis.mint(address(this),reward+reward.div(2));

        lastUpdateTime = block.timestamp;
        lastUpdateTimeRefer = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward+reward.div(2));
    }

    function getCanStakePusd() public view returns (uint256) {
            if (Users[msg.sender].superpower == 0) {
                return 0;
            } else {
                return Users[msg.sender].superpower.mul(3).sub(Users[msg.sender].loanpower.mul(3));
            }
    }

    function gethadStakePusd() public view returns (uint256) {
            return Users[msg.sender].loanpower;
    }

    function stakePusd(uint256 amount) public updateReward(msg.sender) updateRewardRefer(msg.sender) checkhalve checkStart{ 
        require(amount > 0, "Cannot stake 0");
        //super.stake(amount);
        
        require(Users[msg.sender].superpower>0, "not eaque super power 0");
        
        uint256 bances =  Users[msg.sender].superpower.sub(Users[msg.sender].loanpower);

        require(bances >=amount , "big pusd bances");
        pusd.transferFrom(msg.sender, address(this), amount);

        _pusdbalances[msg.sender] = _pusdbalances[msg.sender].add(amount);

        allloanpower = allloanpower.add(amount);

        Users[msg.sender].loanpower = Users[msg.sender].loanpower.add(amount);
        Users[msg.sender].loantime = block.timestamp;

        emit StakedPusd(msg.sender, amount);
    }







////////////////////////////////////
///////////////////////////////////49

  
  function addSomenode2(address node, uint256 score) internal {
        require(Dlist2[node].next == address(0));
        address index = _findIndex2(score);
        scores2[node] = score;
        
        Dlist2[node].next =  Dlist2[index].next;
        Dlist2[Dlist2[index].next].prev = node;
        
        Dlist2[node].prev = index;
        Dlist2[index].next =node;
        
    
        if (Dlist2[node].next == GUARD) {
            listend2 = node;
        }
        listSize2++;
  }



  function increaseScore2(address node, uint256 score) internal {
    updateScore2(node, scores2[node] + score);
  }

  function reduceScore2(address node, uint256 score) internal {
    updateScore2(node, scores2[node] - score);
  }


  function updateScore2(address node, uint256 newScore) internal {
    require(Dlist2[node].next != address(0));
    
    address prev = Dlist2[node].prev;
    address next =  Dlist2[node].next;
    
      if(_verifyIndex2(prev, newScore, next)){
      scores2[node] = newScore;
    } else {
      removeSomenode2(node);
      addSomenode2(node, newScore);
    }
    
  }
  



  function removeSomenode2(address node) internal {
    require(Dlist2[node].next != address(0));
    
    address prev = Dlist2[node].prev;
    
    Dlist2[prev].next = Dlist2[node].next;
    Dlist2[Dlist2[node].next].prev =prev;
    
    if (Dlist2[node].next == GUARD) {
        listend2 = prev;
    }
    Dlist2[node].next =address(0);
    Dlist2[node].prev =address(0);
    
    scores2[node] = 0;
    listSize2--;
  }


//   function getTop2(uint256 k) public view returns(address[] memory) {
//     require(k <= listSize2);
//     address[] memory nodeLists = new address[](k);
//     address currentAddress = Dlist2[GUARD].next;
//     for(uint256 i = 0; i < k; ++i) {
//       nodeLists[i] = currentAddress;
//       currentAddress = Dlist2[currentAddress].next;
//     }
//     return nodeLists;
//   }

  function _verifyIndex2(address prevSomenode, uint256 newValue, address nextSomenode)
    internal
    view
    returns(bool)
  {
    return (prevSomenode == GUARD || scores2[prevSomenode] >= newValue) && 
           (nextSomenode == GUARD || newValue > scores2[nextSomenode]);
  }

  function _findIndex2(uint256 newValue) internal view returns(address) {
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex2(candidateAddress, newValue, Dlist2[candidateAddress].next))
        return candidateAddress;
      candidateAddress = Dlist2[candidateAddress].next;
    }
  }
///////////////////////////////////
///////////////////////////////////200


  
    function addSomenode3(address node, uint256 score) internal {
        require(Dlist3[node].next == address(0));
        address index = _findIndex3(score);
        scores3[node] = score;
        
        Dlist3[node].next =  Dlist3[index].next;
        Dlist3[Dlist3[index].next].prev = node;
        
        Dlist3[node].prev = index;
        Dlist3[index].next =node;
        
    
        if (Dlist3[node].next == GUARD) {
            listend3 = node;
        }
        listSize3++;
  }



  function increaseScore3(address node, uint256 score) internal {
    updateScore3(node, scores3[node] + score);
  }

  function reduceScore3(address node, uint256 score) internal {
    updateScore3(node, scores3[node] - score);
  }


  function updateScore3(address node, uint256 newScore) internal {
    require(Dlist3[node].next != address(0));
    
    address prev = Dlist3[node].prev;
    address next =  Dlist3[node].next;
    
      if(_verifyIndex3(prev, newScore, next)){
      scores3[node] = newScore;
    } else {
      removeSomenode3(node);
      addSomenode3(node, newScore);
    }
    
  }

  function removeSomenode3(address node) internal {
    require(Dlist3[node].next != address(0));
    
    address prev = Dlist3[node].prev;
    
    Dlist3[prev].next = Dlist3[node].next;
    Dlist3[Dlist3[node].next].prev =prev;
    
    if (Dlist3[node].next == GUARD) {
        listend3 = prev;
    }
    Dlist3[node].next =address(0);
    Dlist3[node].prev =address(0);
    
    scores3[node] = 0;
    listSize3--;
  }


  function _verifyIndex3(address prevSomenode, uint256 newValue, address nextSomenode)
    internal
    view
    returns(bool)
  {
    return (prevSomenode == GUARD || scores3[prevSomenode] >= newValue) && 
           (nextSomenode == GUARD || newValue > scores3[nextSomenode]);
  }

  function _findIndex3(uint256 newValue) internal view returns(address) {
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex3(candidateAddress, newValue, Dlist3[candidateAddress].next))
        return candidateAddress;
      candidateAddress = Dlist3[candidateAddress].next;
    }
  }



    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


}