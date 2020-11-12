// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// File: contracts/interfaces/IEpochUtils.sol

pragma solidity 0.6.6;

interface IEpochUtils {
    function epochPeriodInSeconds() external view returns (uint256);

    function firstEpochStartTimestamp() external view returns (uint256);

    function getCurrentEpochNumber() external view returns (uint256);

    function getEpochNumber(uint256 timestamp) external view returns (uint256);
}

// File: contracts/interfaces/IKyberDao.sol

pragma solidity 0.6.6;


interface IKyberDao is IEpochUtils {
    event Voted(
        address indexed staker,
        uint256 indexed epoch,
        uint256 indexed campaignID,
        uint256 option
    );

    function getLatestNetworkFeeDataWithCache()
        external
        returns (uint256 feeInBps, uint256 expiryTimestamp);

    function getLatestBRRDataWithCache()
        external
        returns (
            uint256 burnInBps,
            uint256 rewardInBps,
            uint256 rebateInBps,
            uint256 epoch,
            uint256 expiryTimestamp
        );

    function handleWithdrawal(address staker, uint256 penaltyAmount) external;

    function vote(uint256 campaignID, uint256 option) external;

    function getLatestNetworkFeeData()
        external
        view
        returns (uint256 feeInBps, uint256 expiryTimestamp);

    function shouldBurnRewardForEpoch(uint256 epoch)
        external
        view
        returns (bool);

    /**
     * @dev  return staker's reward percentage in precision for a past epoch only
     *       fee handler should call this function when a staker wants to claim reward
     *       return 0 if staker has no votes or stakes
     */
    function getPastEpochRewardPercentageInPrecision(
        address staker,
        uint256 epoch
    ) external view returns (uint256);

    /**
     * @dev  return staker's reward percentage in precision for the current epoch
     *       reward percentage is not finalized until the current epoch is ended
     */
    function getCurrentEpochRewardPercentageInPrecision(address staker)
        external
        view
        returns (uint256);
}

// File: contracts/interfaces/IExtendedKyberDao.sol

pragma solidity 0.6.6;


interface IExtendedKyberDao is IKyberDao {
    function kncToken() external view returns (address);

    function staking() external view returns (address);

    function feeHandler() external view returns (address);
}

// File: contracts/interfaces/IKyberFeeHandler.sol

pragma solidity 0.6.6;


interface IKyberFeeHandler {
    event RewardPaid(
        address indexed staker,
        uint256 indexed epoch,
        IERC20 indexed token,
        uint256 amount
    );
    event RebatePaid(
        address indexed rebateWallet,
        IERC20 indexed token,
        uint256 amount
    );
    event PlatformFeePaid(
        address indexed platformWallet,
        IERC20 indexed token,
        uint256 amount
    );
    event KncBurned(uint256 kncTWei, IERC20 indexed token, uint256 amount);

    function handleFees(
        IERC20 token,
        address[] calldata eligibleWallets,
        uint256[] calldata rebatePercentages,
        address platformWallet,
        uint256 platformFee,
        uint256 networkFee
    ) external payable;

    function claimReserveRebate(address rebateWallet)
        external
        returns (uint256);

    function claimPlatformFee(address platformWallet)
        external
        returns (uint256);

    function claimStakerReward(address staker, uint256 epoch)
        external
        returns (uint256 amount);
}

// File: contracts/interfaces/IExtendedKyberFeeHandler.sol

pragma solidity 0.6.6;


interface IExtendedKyberFeeHandler is IKyberFeeHandler {
    function rewardsPerEpoch(uint256) external view returns (uint256);
}

// File: contracts/interfaces/IKyberStaking.sol

pragma solidity 0.6.6;


interface IKyberStaking is IEpochUtils {
    event Delegated(
        address indexed staker,
        address indexed representative,
        uint256 indexed epoch,
        bool isDelegated
    );
    event Deposited(uint256 curEpoch, address indexed staker, uint256 amount);
    event Withdraw(
        uint256 indexed curEpoch,
        address indexed staker,
        uint256 amount
    );

    function initAndReturnStakerDataForCurrentEpoch(address staker)
        external
        returns (
            uint256 stake,
            uint256 delegatedStake,
            address representative
        );

    function deposit(uint256 amount) external;

    function delegate(address dAddr) external;

    function withdraw(uint256 amount) external;

    /**
     * @notice return combine data (stake, delegatedStake, representative) of a staker
     * @dev allow to get staker data up to current epoch + 1
     */
    function getStakerData(address staker, uint256 epoch)
        external
        view
        returns (
            uint256 stake,
            uint256 delegatedStake,
            address representative
        );

    function getLatestStakerData(address staker)
        external
        view
        returns (
            uint256 stake,
            uint256 delegatedStake,
            address representative
        );

    /**
     * @notice return raw data of a staker for an epoch
     *         WARN: should be used only for initialized data
     *          if data has not been initialized, it will return all 0
     *          pool master shouldn't use this function to compute/distribute rewards of pool members
     */
    function getStakerRawData(address staker, uint256 epoch)
        external
        view
        returns (
            uint256 stake,
            uint256 delegatedStake,
            address representative
        );
}

// File: contracts/KyberPoolMaster.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;








/**
 * @title Kyber PoolMaster contract
 * @author Protofire
 * @dev Contract that allows pool masters to let pool members claim their designated rewards trustlessly and update fees
 *      with sufficient notice times while maintaining full trustlessness.
 */
contract KyberPoolMaster is Ownable {
    using SafeMath for uint256;

    uint256 internal constant MINIMUM_EPOCH_NOTICE = 1;
    uint256 internal constant MAX_DELEGATION_FEE = 10000;
    uint256 internal constant PRECISION = (10**18);
    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    // Number of epochs after which a change on delegationFee will be applied
    uint256 public immutable epochNotice;

    // Mapping of if staker has claimed reward for Epoch in a feeHandler
    // epoch -> member -> feeHandler -> true | false
    mapping(uint256 => mapping(address => mapping(address => bool)))
        public claimedDelegateReward;

    struct Claim {
        bool claimedByPool;
        uint256 totalRewards;
        uint256 totalStaked;
    }
    //epoch -> feeHandler -> Claim
    mapping(uint256 => mapping(address => Claim)) public epochFeeHandlerClaims;

    // Fee charged by poolMasters to poolMembers for services
    // Denominated in 1e4 units
    // 100 = 1%
    struct DFeeData {
        uint256 fromEpoch;
        uint256 fee;
        bool applied;
    }

    DFeeData[] public delegationFees;

    IERC20 public immutable kncToken;
    IExtendedKyberDao public immutable kyberDao;
    IKyberStaking public immutable kyberStaking;

    address[] public feeHandlersList;
    mapping(address => IERC20) public rewardTokenByFeeHandler;

    uint256 public immutable firstEpoch;

    mapping(address => bool) public successfulClaimByFeeHandler;

    struct RewardInfo {
        IExtendedKyberFeeHandler kyberFeeHandler;
        IERC20 rewardToken;
        uint256 totalRewards;
        uint256 totalFee;
        uint256 rewardsAfterFee;
        uint256 poolMembersShare;
        uint256 poolMasterShare;
    }

    struct UnclaimedRewardData {
        uint256 epoch;
        address feeHandler;
        uint256 rewards;
        IERC20 rewardToken;
    }

    /*** Events ***/
    event CommitNewFees(uint256 deadline, uint256 feeRate);
    event NewFees(uint256 fromEpoch, uint256 feeRate);

    event MemberClaimReward(
        uint256 indexed epoch,
        address indexed poolMember,
        address indexed feeHandler,
        IERC20 rewardToken,
        uint256 reward
    );

    event MasterClaimReward(
        uint256 indexed epoch,
        address indexed feeHandler,
        address indexed poolMaster,
        IERC20 rewardToken,
        uint256 totalRewards,
        uint256 feeApplied,
        uint256 feeAmount,
        uint256 poolMasterShare
    );

    event AddFeeHandler(address indexed feeHandler, IERC20 indexed rewardToken);

    event RemoveFeeHandler(address indexed feeHandler);

    /**
     * @notice Address deploying this contract should be able to receive ETH, owner can be changed using transferOwnership method
     * @param _kyberDao KyberDao contract address
     * @param _epochNotice Number of epochs after which a change on deledatioFee is will be applied
     * @param _delegationFee Fee charged by poolMasters to poolMembers for services - Denominated in 1e4 units - 100 = 1%
     * @param _kyberFeeHandlers Array of FeeHandlers
     * @param _rewardTokens Array of ERC20 tokens used by FeeHandlers to pay reward. Use zero address if FeeHandler pays ETH
     */
    constructor(
        address _kyberDao,
        uint256 _epochNotice,
        uint256 _delegationFee,
        address[] memory _kyberFeeHandlers,
        IERC20[] memory _rewardTokens
    ) public {
        require(_kyberDao != address(0), "ctor: kyberDao is missing");
        require(
            _epochNotice >= MINIMUM_EPOCH_NOTICE,
            "ctor: Epoch Notice too low"
        );
        require(
            _delegationFee <= MAX_DELEGATION_FEE,
            "ctor: Delegation Fee greater than 100%"
        );
        require(
            _kyberFeeHandlers.length > 0,
            "ctor: at least one _kyberFeeHandlers required"
        );
        require(
            _kyberFeeHandlers.length == _rewardTokens.length,
            "ctor: _kyberFeeHandlers and _rewardTokens uneven"
        );

        IExtendedKyberDao _kyberDaoContract = IExtendedKyberDao(_kyberDao);
        kyberDao = _kyberDaoContract;

        kncToken = IERC20(_kyberDaoContract.kncToken());
        kyberStaking = IKyberStaking(_kyberDaoContract.staking());

        epochNotice = _epochNotice;

        uint256 _firstEpoch = _kyberDaoContract.getCurrentEpochNumber();
        firstEpoch = _firstEpoch;

        delegationFees.push(DFeeData(_firstEpoch, _delegationFee, true));

        for (uint256 i = 0; i < _kyberFeeHandlers.length; i++) {
            require(
                _kyberFeeHandlers[i] != address(0),
                "ctor: feeHandler is missing"
            );
            require(
                rewardTokenByFeeHandler[_kyberFeeHandlers[i]] ==
                    IERC20(address(0)),
                "ctor: repeated feeHandler"
            );

            feeHandlersList.push(_kyberFeeHandlers[i]);
            rewardTokenByFeeHandler[_kyberFeeHandlers[i]] = _rewardTokens[i];

            emit AddFeeHandler(
                _kyberFeeHandlers[i],
                rewardTokenByFeeHandler[_kyberFeeHandlers[i]]
            );
        }

        emit CommitNewFees(_firstEpoch, _delegationFee);
        emit NewFees(_firstEpoch, _delegationFee);
    }

    /**
     * @dev adds a new FeeHandler
     * @param _feeHandler FeeHandler address
     * @param _rewardToken Rewards Token address
     */
    function addFeeHandler(address _feeHandler, IERC20 _rewardToken)
        external
        onlyOwner
    {
        require(
            _feeHandler != address(0),
            "addFeeHandler: _feeHandler is missing"
        );
        require(
            rewardTokenByFeeHandler[_feeHandler] == IERC20(address(0)),
            "addFeeHandler: already added"
        );

        feeHandlersList.push(_feeHandler);
        rewardTokenByFeeHandler[_feeHandler] = _rewardToken;

        emit AddFeeHandler(_feeHandler, rewardTokenByFeeHandler[_feeHandler]);
    }

    /**
     * @dev removes a FeeHandler
     * @param _feeHandler FeeHandler address
     */
    function removeFeeHandler(address _feeHandler) external onlyOwner {
        require(
            rewardTokenByFeeHandler[_feeHandler] != IERC20(address(0)),
            "removeFeeHandler: not added"
        );
        require(
            !successfulClaimByFeeHandler[_feeHandler],
            "removeFeeHandler: can not remove FeeHandler successfully claimed"
        );

        if (feeHandlersList[feeHandlersList.length - 1] != _feeHandler) {
            for (uint256 i = 0; i < feeHandlersList.length; i++) {
                if (feeHandlersList[i] == _feeHandler) {
                    feeHandlersList[i] = feeHandlersList[feeHandlersList
                        .length - 1];
                    break;
                }
            }
        }

        feeHandlersList.pop();
        delete rewardTokenByFeeHandler[_feeHandler];

        emit RemoveFeeHandler(_feeHandler);
    }

    /**
     * @dev call to stake more KNC for poolMaster
     * @param amount amount of KNC to stake
     */
    function masterDeposit(uint256 amount) external onlyOwner {
        require(
            amount > 0,
            "masterDeposit: amount to deposit should be positive"
        );

        require(
            kncToken.transferFrom(msg.sender, address(this), amount),
            "masterDeposit: can not get token"
        );

        // approve
        kncToken.approve(address(kyberStaking), amount);

        // deposit in KyberStaking
        kyberStaking.deposit(amount);
    }

    /**
     * @dev call to withdraw KNC from staking
     * @param amount amount of KNC to withdraw
     */
    function masterWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "masterWithdraw: amount is 0");

        // withdraw from KyberStaking
        kyberStaking.withdraw(amount);

        // transfer KNC back to pool master
        require(
            kncToken.transfer(msg.sender, amount),
            "masterWithdraw: can not transfer knc to the pool master"
        );
    }

    /**
     * @dev  vote for an option of a campaign
     *       options are indexed from 1 to number of options
     * @param campaignID id of campaign to vote for
     * @param option id of options to vote for
     */
    function vote(uint256 campaignID, uint256 option) external onlyOwner {
        kyberDao.vote(campaignID, option);
    }

    /**
     * @dev  set a new delegation fee to be applied in current epoch + epochNotice
     * @param _fee new fee
     */
    function commitNewFee(uint256 _fee) external onlyOwner {
        require(
            _fee <= MAX_DELEGATION_FEE,
            "commitNewFee: Delegation Fee greater than 100%"
        );

        uint256 curEpoch = kyberDao.getCurrentEpochNumber();
        uint256 fromEpoch = curEpoch.add(epochNotice);

        DFeeData storage lastFee = delegationFees[delegationFees.length - 1];

        if (lastFee.fromEpoch > curEpoch) {
            lastFee.fromEpoch = fromEpoch;
            lastFee.fee = _fee;
        } else {
            if (!lastFee.applied) {
                applyFee(lastFee);
            }

            delegationFees.push(DFeeData(fromEpoch, _fee, false));
        }
        emit CommitNewFees(fromEpoch.sub(1), _fee);
    }

    /**
     * @dev Applies the pending new fee
     */
    function applyPendingFee() public {
        DFeeData storage lastFee = delegationFees[delegationFees.length - 1];
        uint256 curEpoch = kyberDao.getCurrentEpochNumber();

        if (lastFee.fromEpoch <= curEpoch && !lastFee.applied) {
            applyFee(lastFee);
        }
    }

    /**
     * @dev Applies a pending fee
     * @param fee to be applied
     */
    function applyFee(DFeeData storage fee) internal {
        fee.applied = true;
        emit NewFees(fee.fromEpoch, fee.fee);
    }

    /**
     * @dev Gets the id of the delegation fee corresponding to the given epoch
     * @param _epoch for which epoch is querying delegation fee
     * @param _from delegationFees starting index
     */
    function getEpochDFeeDataId(uint256 _epoch, uint256 _from)
        internal
        view
        returns (uint256)
    {
        if (delegationFees[_from].fromEpoch > _epoch) {
            return _from;
        }

        uint256 left = _from;
        uint256 right = delegationFees.length;

        while (left < right) {
            uint256 m = (left + right).div(2);
            if (delegationFees[m].fromEpoch > _epoch) {
                right = m;
            } else {
                left = m + 1;
            }
        }

        return right - 1;
    }

    /**
     * @dev Gets the the delegation fee data corresponding to the given epoch
     * @param epoch for which epoch is querying delegation fee
     */
    function getEpochDFeeData(uint256 epoch)
        public
        view
        returns (DFeeData memory epochDFee)
    {
        epochDFee = delegationFees[getEpochDFeeDataId(epoch, 0)];
    }

    /**
     * @dev Gets the the delegation fee data corresponding to the current epoch
     */
    function delegationFee() public view returns (DFeeData memory) {
        uint256 curEpoch = kyberDao.getCurrentEpochNumber();
        return getEpochDFeeData(curEpoch);
    }

    /**
     * @dev  Queries the amount of unclaimed rewards for the pool in a given epoch and feeHandler
     *       return 0 if PoolMaster has calledRewardMaster
     *       return 0 if staker's reward percentage in precision for the epoch is 0
     *       return 0 if total reward for the epoch is 0
     * @param _epoch for which epoch is querying unclaimed reward
     * @param _feeHandler FeeHandler address
     */
    function getUnclaimedRewards(
        uint256 _epoch,
        IExtendedKyberFeeHandler _feeHandler
    ) public view returns (uint256) {
        if (epochFeeHandlerClaims[_epoch][address(_feeHandler)].claimedByPool) {
            return 0;
        }

        uint256 perInPrecision = kyberDao
            .getPastEpochRewardPercentageInPrecision(address(this), _epoch);
        if (perInPrecision == 0) {
            return 0;
        }

        uint256 rewardsPerEpoch = _feeHandler.rewardsPerEpoch(_epoch);
        if (rewardsPerEpoch == 0) {
            return 0;
        }

        return rewardsPerEpoch.mul(perInPrecision).div(PRECISION);
    }

    /**
     * @dev Returns data related to all epochs and feeHandlers with unclaimed rewards, for the pool.
     */
    function getUnclaimedRewardsData()
        external
        view
        returns (UnclaimedRewardData[] memory)
    {
        uint256 currentEpoch = kyberDao.getCurrentEpochNumber();
        uint256 maxEpochNumber = currentEpoch.sub(firstEpoch);
        uint256[] memory epochGroup = new uint256[](maxEpochNumber);
        uint256 e = 0;
        for (uint256 epoch = firstEpoch; epoch < currentEpoch; epoch++) {
            epochGroup[e] = epoch;
            e++;
        }

        return _getUnclaimedRewardsData(epochGroup, feeHandlersList);
    }

    /**
     * @dev Returns data related to all epochs and feeHandlers, from the given groups, with unclaimed rewards, for the pool.
     */
    function getUnclaimedRewardsData(
        uint256[] calldata _epochGroup,
        address[] calldata _feeHandlerGroup
    ) external view returns (UnclaimedRewardData[] memory) {
        return _getUnclaimedRewardsData(_epochGroup, _feeHandlerGroup);
    }

    function _getUnclaimedRewardsData(
        uint256[] memory _epochGroup,
        address[] memory _feeHandlerGroup
    ) internal view returns (UnclaimedRewardData[] memory) {

            UnclaimedRewardData[] memory epochFeeHanlderRewards
         = new UnclaimedRewardData[](
            _epochGroup.length.mul(_feeHandlerGroup.length)
        );
        uint256 rewardsCounter = 0;
        for (uint256 e = 0; e < _epochGroup.length; e++) {
            for (uint256 f = 0; f < _feeHandlerGroup.length; f++) {
                uint256 unclaimed = getUnclaimedRewards(
                    _epochGroup[e],
                    IExtendedKyberFeeHandler(_feeHandlerGroup[f])
                );

                if (unclaimed > 0) {
                    epochFeeHanlderRewards[rewardsCounter] = UnclaimedRewardData(
                        _epochGroup[e],
                        _feeHandlerGroup[f],
                        unclaimed,
                        rewardTokenByFeeHandler[_feeHandlerGroup[f]]
                    );
                    rewardsCounter++;
                }
            }
        }

        UnclaimedRewardData[] memory result = new UnclaimedRewardData[](
            rewardsCounter
        );
        for (uint256 i = 0; i < (rewardsCounter); i++) {
            result[i] = epochFeeHanlderRewards[i];
        }

        return result;
    }

    /**
     * @dev  Claims rewards for a given group of epochs in all feeHandlers, distribute fees and its share to poolMaster
     * @param _epochGroup An array of epochs for which rewards are being claimed. Asc order and uniqueness is required.
     */
    function claimRewardsMaster(uint256[] memory _epochGroup) public {
        claimRewardsMaster(_epochGroup, feeHandlersList);
    }

    /**
     * @dev  Claims rewards for a given group of epochs and a given group of feeHandlers, distribute fees and its share to poolMaster
     * @param _epochGroup An array of epochs for which rewards are being claimed. Asc order and uniqueness is required.
     * @param _feeHandlerGroup An array of FeeHandlers for which rewards are being claimed.
     */
    function claimRewardsMaster(
        uint256[] memory _epochGroup,
        address[] memory _feeHandlerGroup
    ) public {
        require(_epochGroup.length > 0, "cRMaster: _epochGroup required");
        require(
            isOrderedSet(_epochGroup),
            "cRMaster: order and uniqueness required"
        );
        require(
            _feeHandlerGroup.length > 0,
            "cRMaster: _feeHandlerGroup required"
        );

        uint256[] memory accruedByFeeHandler = new uint256[](
            _feeHandlerGroup.length
        );

        uint256 feeId = 0;

        for (uint256 j = 0; j < _epochGroup.length; j++) {
            uint256 _epoch = _epochGroup[j];
            feeId = getEpochDFeeDataId(_epoch, feeId);
            DFeeData storage epochDFee = delegationFees[feeId];

            if (!epochDFee.applied) {
                applyFee(epochDFee);
            }

            (uint256 stake, uint256 delegatedStake, ) = kyberStaking
                .getStakerRawData(address(this), _epoch);

            for (uint256 i = 0; i < _feeHandlerGroup.length; i++) {
                RewardInfo memory rewardInfo = _claimRewardsFromKyber(
                    _epoch,
                    _feeHandlerGroup[i],
                    epochDFee,
                    stake,
                    delegatedStake
                );

                if (rewardInfo.totalRewards == 0) {
                    continue;
                }

                accruedByFeeHandler[i] = accruedByFeeHandler[i].add(
                    rewardInfo.poolMasterShare
                );

                if (!successfulClaimByFeeHandler[_feeHandlerGroup[i]]) {
                    successfulClaimByFeeHandler[_feeHandlerGroup[i]] = true;
                }
            }
        }

        address poolMaster = owner();
        for (uint256 k = 0; k < accruedByFeeHandler.length; k++) {
            _sendTokens(
                rewardTokenByFeeHandler[_feeHandlerGroup[k]],
                poolMaster,
                accruedByFeeHandler[k],
                "cRMaster: poolMaster share transfer failed"
            );
        }
    }

    function _claimRewardsFromKyber(
        uint256 _epoch,
        address _feeHandlerAddress,
        DFeeData memory epochDFee,
        uint256 stake,
        uint256 delegatedStake
    ) internal returns (RewardInfo memory rewardInfo) {
        rewardInfo.kyberFeeHandler = IExtendedKyberFeeHandler(
            _feeHandlerAddress
        );
        uint256 unclaimed = getUnclaimedRewards(
            _epoch,
            rewardInfo.kyberFeeHandler
        );

        if (unclaimed > 0) {
            rewardInfo
                .rewardToken = rewardTokenByFeeHandler[_feeHandlerAddress];

            rewardInfo.kyberFeeHandler.claimStakerReward(address(this), _epoch);

            rewardInfo.totalRewards = unclaimed;

            rewardInfo.totalFee = rewardInfo
                .totalRewards
                .mul(epochDFee.fee)
                .div(MAX_DELEGATION_FEE);
            rewardInfo.rewardsAfterFee = rewardInfo.totalRewards.sub(
                rewardInfo.totalFee
            );

            rewardInfo.poolMembersShare = calculateRewardsShare(
                delegatedStake,
                stake.add(delegatedStake),
                rewardInfo.rewardsAfterFee
            );
            rewardInfo.poolMasterShare = rewardInfo.totalRewards.sub(
                rewardInfo.poolMembersShare
            ); // fee + poolMaster stake share

            epochFeeHandlerClaims[_epoch][_feeHandlerAddress] = Claim(
                true,
                rewardInfo.poolMembersShare,
                delegatedStake
            );

            emit MasterClaimReward(
                _epoch,
                _feeHandlerAddress,
                payable(owner()),
                rewardInfo.rewardToken,
                rewardInfo.totalRewards,
                epochDFee.fee,
                rewardInfo.totalFee,
                rewardInfo.poolMasterShare.sub(rewardInfo.totalFee)
            );
        }
    }

    /**
     * @dev  Helper method to transfer tokens
     * @param _token address of the token
     * @param _receiver account that will receive the transfer
     * @param _value the amount of tokens to transfer
     * @param _errorMsg error msg in case transfer of native tokens fails
     */
    function _sendTokens(
        IERC20 _token,
        address _receiver,
        uint256 _value,
        string memory _errorMsg
    ) internal {
        if (_value == 0) {
            return;
        }

        if (_token == ETH_TOKEN_ADDRESS) {
            (bool success, ) = _receiver.call{value: _value}("");
            require(success, _errorMsg);
        } else {
            SafeERC20.safeTransfer(_token, _receiver, _value);
        }
    }

    /**
     * @dev  Queries the amount of unclaimed rewards for the pool member in a given epoch and feeHandler
     *       return 0 if PoolMaster has not called claimRewardMaster
     *       return 0 if PoolMember has previously claimed reward for the epoch
     *       return 0 if PoolMember has not stake for the epoch
     *       return 0 if PoolMember has not delegated it stake to this contract for the epoch
     * @param _poolMember address of pool member
     * @param _epoch for which epoch the member is querying unclaimed reward
     * @param _feeHandler FeeHandler address
     */
    function getUnclaimedRewardsMember(
        address _poolMember,
        uint256 _epoch,
        address _feeHandler
    ) public view returns (uint256) {
        if (
            !epochFeeHandlerClaims[_epoch][address(_feeHandler)].claimedByPool
        ) {
            return 0;
        }

        if (claimedDelegateReward[_epoch][_poolMember][_feeHandler]) {
            return 0;
        }

        (uint256 stake, , address representative) = kyberStaking.getStakerData(
            _poolMember,
            _epoch
        );

        if (stake == 0) {
            return 0;
        }

        if (representative != address(this)) {
            return 0;
        }


            Claim memory rewardForEpoch
         = epochFeeHandlerClaims[_epoch][_feeHandler];

        return
            calculateRewardsShare(
                stake,
                rewardForEpoch.totalStaked,
                rewardForEpoch.totalRewards
            );
    }

    /**
     * @dev  Returns data related to all epochs and feeHandlers with unclaimed rewards, for a the poolMember. From initial to current epoch.
     * @param _poolMember address of pool member
     */
    function getAllUnclaimedRewardsDataMember(address _poolMember)
        external
        view
        returns (UnclaimedRewardData[] memory)
    {
        uint256 currentEpoch = kyberDao.getCurrentEpochNumber();
        return
            _getAllUnclaimedRewardsDataMember(
                _poolMember,
                firstEpoch,
                currentEpoch
            );
    }

    /**
     * @dev Returns data related to all epochs and feeHandlers with unclaimed rewards, for a the poolMember.
     * @param _poolMember address of pool member
     * @param _fromEpoch initial epoch parameter
     * @param _toEpoch end epoch parameter
     */
    function getAllUnclaimedRewardsDataMember(
        address _poolMember,
        uint256 _fromEpoch,
        uint256 _toEpoch
    ) external view returns (UnclaimedRewardData[] memory) {
        return
            _getAllUnclaimedRewardsDataMember(
                _poolMember,
                _fromEpoch,
                _toEpoch
            );
    }

    /**
     * @dev Queries data related to epochs and feeHandlers with unclaimed rewards, for a the poolMember
     * @param _poolMember address of pool member
     * @param _fromEpoch initial epoch parameter
     * @param _toEpoch end epoch parameter
     */
    function _getAllUnclaimedRewardsDataMember(
        address _poolMember,
        uint256 _fromEpoch,
        uint256 _toEpoch
    ) internal view returns (UnclaimedRewardData[] memory) {
        uint256 maxEpochNumber = _toEpoch.sub(_fromEpoch).add(1);
        uint256[] memory epochGroup = new uint256[](maxEpochNumber);
        uint256 e = 0;
        for (uint256 epoch = _fromEpoch; epoch <= _toEpoch; epoch++) {
            epochGroup[e] = epoch;
            e++;
        }

        return
            _getUnclaimedRewardsDataMember(
                _poolMember,
                epochGroup,
                feeHandlersList
            );
    }

    function _getUnclaimedRewardsDataMember(
        address _poolMember,
        uint256[] memory _epochGroup,
        address[] memory _feeHandlerGroup
    ) internal view returns (UnclaimedRewardData[] memory) {

            UnclaimedRewardData[] memory epochFeeHanlderRewards
         = new UnclaimedRewardData[](
            _epochGroup.length.mul(_feeHandlerGroup.length)
        );

        uint256 rewardsCounter = 0;
        for (uint256 e = 0; e < _epochGroup.length; e++) {
            for (uint256 f = 0; f < _feeHandlerGroup.length; f++) {
                uint256 unclaimed = getUnclaimedRewardsMember(
                    _poolMember,
                    _epochGroup[e],
                    _feeHandlerGroup[f]
                );

                if (unclaimed > 0) {
                    epochFeeHanlderRewards[rewardsCounter] = UnclaimedRewardData(
                        _epochGroup[e],
                        _feeHandlerGroup[f],
                        unclaimed,
                        rewardTokenByFeeHandler[_feeHandlerGroup[f]]
                    );
                    rewardsCounter++;
                }
            }
        }

        UnclaimedRewardData[] memory result = new UnclaimedRewardData[](
            rewardsCounter
        );
        for (uint256 i = 0; i < (rewardsCounter); i++) {
            result[i] = epochFeeHanlderRewards[i];
        }

        return result;
    }

    /**
     * @dev Someone claims rewards for a PoolMember in a given group of epochs in all feeHandlers.
     *      It will transfer rewards where epoch->feeHandler has been claimed by the pool and not yet by the member.
     *      This contract will keep locked remainings from rounding at a wei level.
     * @param _epochGroup An array of epochs for which rewards are being claimed
     * @param _poolMember PoolMember address to claim rewards for
     */
    function claimRewardsMember(
        address _poolMember,
        uint256[] memory _epochGroup
    ) public {
        _claimRewardsMember(_poolMember, _epochGroup, feeHandlersList);
    }

    /**
     * @dev Someone claims rewards for a PoolMember in a given group of epochs in a given group of feeHandlers.
     *      It will transfer rewards where epoch->feeHandler has been claimed by the pool and not yet by the member.
     *      This contract will keep locked remainings from rounding at a wei level.
     * @param _epochGroup An array of epochs for which rewards are being claimed
     * @param _feeHandlerGroup An array of FeeHandlers for which rewards are being claimed
     * @param _poolMember PoolMember address to claim rewards for
     */
    function claimRewardsMember(
        address _poolMember,
        uint256[] memory _epochGroup,
        address[] memory _feeHandlerGroup
    ) public {
        _claimRewardsMember(_poolMember, _epochGroup, _feeHandlerGroup);
    }

    function _claimRewardsMember(
        address _poolMember,
        uint256[] memory _epochGroup,
        address[] memory _feeHandlerGroup
    ) internal {
        require(_epochGroup.length > 0, "cRMember: _epochGroup required");
        require(
            _feeHandlerGroup.length > 0,
            "cRMember: _feeHandlerGroup required"
        );

        uint256[] memory accruedByFeeHandler = new uint256[](
            _feeHandlerGroup.length
        );

        for (uint256 j = 0; j < _epochGroup.length; j++) {
            uint256 _epoch = _epochGroup[j];

            for (uint256 i = 0; i < _feeHandlerGroup.length; i++) {
                uint256 poolMemberShare = getUnclaimedRewardsMember(
                    _poolMember,
                    _epoch,
                    _feeHandlerGroup[i]
                );


                    IERC20 rewardToken
                 = rewardTokenByFeeHandler[_feeHandlerGroup[i]];

                if (poolMemberShare == 0) {
                    continue;
                }

                accruedByFeeHandler[i] = accruedByFeeHandler[i].add(
                    poolMemberShare
                );

                claimedDelegateReward[_epoch][_poolMember][_feeHandlerGroup[i]] = true;

                emit MemberClaimReward(
                    _epoch,
                    _poolMember,
                    _feeHandlerGroup[i],
                    rewardToken,
                    poolMemberShare
                );
            }
        }

        // distribute _poolMember rewards share
        for (uint256 k = 0; k < accruedByFeeHandler.length; k++) {
            _sendTokens(
                rewardTokenByFeeHandler[_feeHandlerGroup[k]],
                _poolMember,
                accruedByFeeHandler[k],
                "cRMember: poolMember share transfer failed"
            );
        }
    }

    // Utils

    /**
     * @dev Calculates rewards share based on the stake over the total stake
     */
    function calculateRewardsShare(
        uint256 stake,
        uint256 totalStake,
        uint256 rewards
    ) internal pure returns (uint256) {
        return stake.mul(rewards).div(totalStake);
    }

    /**
     * @dev Queries the number of elements in delegationFees
     */
    function delegationFeesLength() public view returns (uint256) {
        return delegationFees.length;
    }

    /**
     * @dev Queries the number of elements in feeHandlersList
     */
    function feeHandlersListLength() public view returns (uint256) {
        return feeHandlersList.length;
    }

    /**
     * @dev Checks if elements in array are ordered and unique
     */
    function isOrderedSet(uint256[] memory numbers)
        internal
        pure
        returns (bool)
    {
        bool isOrdered = true;

        if (numbers.length > 1) {
            for (uint256 i = 0; i < numbers.length - 1; i++) {
                // strict inequality ensures both ordering and uniqueness
                if (numbers[i] >= numbers[i + 1]) {
                    isOrdered = false;
                    break;
                }
            }
        }

        return isOrdered;
    }

    /**
     * @dev Enables the contract to receive ETH
     */
    receive() external payable {
        require(
            rewardTokenByFeeHandler[msg.sender] == ETH_TOKEN_ADDRESS,
            "only accept ETH from a KyberFeeHandler"
        );
    }
}