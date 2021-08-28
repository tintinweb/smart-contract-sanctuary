/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * Created by Murciano207 - August 2021
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

// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

// File: contracts/Lock.sol

pragma solidity 0.5.15;






/**
* @dev This contract will hold user locked funds which will be unlocked after
* lock-up period ends
*/
contract Lock is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum Status { _, OPEN, CLOSED }
    enum TokenStatus {_, ACTIVE, INACTIVE }

    struct Token {
        address tokenAddress;
        uint256 minAmount;
        bool emergencyUnlock;
        TokenStatus status;
        uint256[] tierAmounts;
        uint256[] tierFees;
    }

    Token[] private _tokens;

    IERC20 private _lockToken;

    //Fee per lock in lock token
    uint256 private _lockTokenFee;

    //Keeps track of token index in above array
    mapping(address => uint256) private _tokenVsIndex;

    //Wallet where fees will go
    address payable private _wallet;

    address constant private ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    struct LockedAsset {
        address token;// Token address
        uint256 amount;// Amount locked
        uint256 startDate;// Start date. We can remove this later
        uint256 endDate;
        uint256 lastLocked;
        //Amount threshold after a locked asset can be unlocked
        uint256 amountThreshold;
        address payable beneficiary;// Beneficary who will receive funds
        Status status;
    }

    struct Airdrop {
        address destToken;
        //numerator and denominator will be used to calculate ratio
        //Example 1DAI will get you 4 SAI
        //which means numerator = 4 and denominator = 1
        uint256 numerator;
        uint256 denominator;
        uint256 date;// Date at which time this entry was made
        //Only those locked asset which were locked before this date will be
        //given airdropped tokens
    }

    //Mapping of base token versus airdropped token
    mapping(address => Airdrop[]) private _baseTokenVsAirdrops;

    //Global lockedasset id. Also give total number of lock-ups made so far
    uint256 private _lockId;

    //list of all asset ids for a user/beneficiary
    mapping(address => uint256[]) private _userVsLockIds;

    mapping(uint256 => LockedAsset) private _idVsLockedAsset;

    bool private _paused;

    event TokenAdded(address indexed token);
    event TokenInactivated(address indexed token);
    event TokenActivated(address indexed token);
    event WalletChanged(address indexed wallet);
    event AssetLocked(
        address indexed token,
        address indexed sender,
        address indexed beneficiary,
        uint256 id,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        bool lockTokenFee,
        uint256 fee
    );
    event TokenUpdated(
        uint256 indexed id,
        address indexed token,
        uint256 minAmount,
        bool emergencyUnlock,
        uint256[] tierAmounts,
        uint256[] tierFees
    );
    event Paused();
    event Unpaused();

    event AssetClaimed(
        uint256 indexed id,
        address indexed beneficiary,
        address indexed token
    );

    event AirdropAdded(
        address indexed baseToken,
        address indexed destToken,
        uint256 index,
        uint256 airdropDate,
        uint256 numerator,
        uint256 denominator
    );

    event AirdropUpdated(
        address indexed baseToken,
        address indexed destToken,
        uint256 index,
        uint256 airdropDate,
        uint256 numerator,
        uint256 denominator
    );

    event TokensAirdropped(
        address indexed destToken,
        uint256 amount
    );

    event LockTokenUpdated(address indexed lockTokenAddress);
    event LockTokenFeeUpdated(uint256 fee);

    event AmountAdded(address indexed beneficiary, uint256 id, uint256 amount);

    modifier tokenExist(address token) {
        require(_tokenVsIndex[token] > 0, "Lock: Token does not exist!!");
        _;
    }

    modifier tokenDoesNotExist(address token) {
        require(_tokenVsIndex[token] == 0, "Lock: Token already exist!!");
        _;
    }

    modifier canLockAsset(address token) {
        uint256 index = _tokenVsIndex[token];

        require(index > 0, "Lock: Token does not exist!!");

        require(
            _tokens[index.sub(1)].status == TokenStatus.ACTIVE,
            "Lock: Token not active!!"
        );

        require(
            !_tokens[index.sub(1)].emergencyUnlock,
            "Lock: Token is in emergency unlock state!!"
        );
        _;
    }

    modifier canClaim(uint256 id) {

        require(claimable(id), "Lock: Can't claim asset");

        require(
            _idVsLockedAsset[id].beneficiary == msg.sender,
            "Lock: Unauthorized access!!"
        );
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!_paused, "Lock: paused");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(_paused, "Lock: not paused");
        _;
    }

    /**
    * @dev Constructor
    * @param wallet Wallet address where fees will go
    * @param lockTokenAddress Address of the lock token
    * @param lockTokenFee Fee for each lock in lock token
    */
    constructor(
        address payable wallet,
        address lockTokenAddress,
        uint256 lockTokenFee
    )
        public
    {
        require(
            wallet != address(0),
            "Lock: Please provide valid wallet address!!"
        );
        require(
            lockTokenAddress != address(0),
            "Lock: Invalid lock token address"
        );
        _lockToken = IERC20(lockTokenAddress);
        _wallet = wallet;
        _lockTokenFee = lockTokenFee;
    }

    /**
    * @dev Returns true if the contract is paused, and false otherwise.
    */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
    * @dev returns the fee receiver wallet address
    */
    function getWallet() external view returns(address) {
        return _wallet;
    }

    /**
    * @dev Returns total token count
    */
    function getTokenCount() external view returns(uint256) {
        return _tokens.length;
    }

    /**
    * @dev Returns lock token address
    */
    function getLockToken() external view returns(address) {
        return address(_lockToken);
    }

    /**
    * @dev Returns fee per lock in lock token
    */
    function getLockTokenFee() external view returns(uint256) {
        return _lockTokenFee;
    }

    /**
    * @dev Returns list of supported tokens
    * This will be a paginated method which will only send 15 tokens in one request
    * This is done to prevent infinite loops and overflow of gas limits
    * @param start start index for pagination
    * @param length Amount of tokens to fetch
    */
    function getTokens(uint256 start, uint256 length) external view returns(
        address[] memory tokenAddresses,
        uint256[] memory minAmounts,
        bool[] memory emergencyUnlocks,
        TokenStatus[] memory statuses
    )
    {
        tokenAddresses = new address[](length);
        minAmounts = new uint256[](length);
        emergencyUnlocks = new bool[](length);
        statuses = new TokenStatus[](length);

        require(start.add(length) <= _tokens.length, "Lock: Invalid input");
        require(length > 0 && length <= 15, "Lock: Invalid length");
        uint256 count = 0;
        for(uint256 i = start; i < start.add(length); i++) {
            tokenAddresses[count] = _tokens[i].tokenAddress;
            minAmounts[count] = _tokens[i].minAmount;
            emergencyUnlocks[count] = _tokens[i].emergencyUnlock;
            statuses[count] = _tokens[i].status;
            count = count.add(1);
        }

        return(
            tokenAddresses,
            minAmounts,
            emergencyUnlocks,
            statuses
        );
    }

    /**
    * @dev Returns information about specific token
    * @dev tokenAddress Address of the token
    */
    function getTokenInfo(address tokenAddress) external view returns(
        uint256 minAmount,
        bool emergencyUnlock,
        TokenStatus status,
        uint256[] memory tierAmounts,
        uint256[] memory tierFees
    )
    {
        uint256 index = _tokenVsIndex[tokenAddress];

        if(index > 0){
            index = index.sub(1);
            Token memory token = _tokens[index];
            return (
                token.minAmount,
                token.emergencyUnlock,
                token.status,
                token.tierAmounts,
                token.tierFees
            );
        }
    }

    /**
    * @dev Returns information about a locked asset
    * @param id Asset id
    */
    function getLockedAsset(uint256 id) external view returns(
        address token,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 lastLocked,
        address beneficiary,
        Status status,
        uint256 amountThreshold
    )
    {
        LockedAsset memory asset = _idVsLockedAsset[id];
        token = asset.token;
        amount = asset.amount;
        startDate = asset.startDate;
        endDate = asset.endDate;
        beneficiary = asset.beneficiary;
        status = asset.status;
        amountThreshold = asset.amountThreshold;
        lastLocked = asset.lastLocked;

        return(
            token,
            amount,
            startDate,
            endDate,
            lastLocked,
            beneficiary,
            status,
            amountThreshold
        );
    }

    /**
    * @dev Returns all asset ids for a user
    * @param user Address of the user
    */
    function getAssetIds(
        address user
    )
        external
        view
        returns (uint256[] memory ids)
    {
        return _userVsLockIds[user];
    }

    /**
    * @dev Returns airdrop info for a given token
    * @param token Token address
    */
    function getAirdrops(address token) external view returns(
        address[] memory destTokens,
        uint256[] memory numerators,
        uint256[] memory denominators,
        uint256[] memory dates
    )
    {
        uint256 length = _baseTokenVsAirdrops[token].length;

        destTokens = new address[](length);
        numerators = new uint256[](length);
        denominators = new uint256[](length);
        dates = new uint256[](length);

        //This loop can be very costly if there are very large number of airdrops for a token.
        //Which we presume will not be the case
        for(uint256 i = 0; i < length; i++){

            Airdrop memory airdrop = _baseTokenVsAirdrops[token][i];
            destTokens[i] = airdrop.destToken;
            numerators[i] = airdrop.numerator;
            denominators[i] = airdrop.denominator;
            dates[i] = airdrop.date;
        }

        return (
            destTokens,
            numerators,
            denominators,
            dates
        );
    }

    /**
    * @dev Returns specific airdrop for a base token
    * @param token Base token address
    * @param index Index at which this airdrop is in array
    */
    function getAirdrop(address token, uint256 index) external view returns(
        address destToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date
    )
    {
        return (
            _baseTokenVsAirdrops[token][index].destToken,
            _baseTokenVsAirdrops[token][index].numerator,
            _baseTokenVsAirdrops[token][index].denominator,
            _baseTokenVsAirdrops[token][index].date
        );
    }

    /**
    * @dev Called by an admin to pause, triggers stopped state.
    */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
    * @dev Called by an admin to unpause, returns to normal state.
    */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }

    /**
    * @dev Allows admin to set airdrop token for a given base token
    * @param baseToken Address of the base token
    * @param destToken Address of the airdropped token
    * @param numerator Numerator to calculate ratio
    * @param denominator Denominator to calculate ratio
    * @param date Date at which airdrop happened or will happen
    */
    function setAirdrop(
        address baseToken,
        address destToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date
    )
        external
        onlyOwner
        tokenExist(baseToken)
    {
        require(destToken != address(0), "Lock: Invalid destination token!!");
        require(numerator > 0, "Lock: Invalid numerator!!");
        require(denominator > 0, "Lock: Invalid denominator!!");
        require(isActive(baseToken), "Lock: Base token is not active!!");

        _baseTokenVsAirdrops[baseToken].push(Airdrop({
            destToken: destToken,
            numerator: numerator,
            denominator: denominator,
            date: date
        }));

        emit AirdropAdded(
            baseToken,
            destToken,
            _baseTokenVsAirdrops[baseToken].length.sub(1),
            date,
            numerator,
            denominator
        );
    }

    /**
    * @dev Update lock token address
    * @param lockTokenAddress New lock token address
    */
    function updateLockToken(address lockTokenAddress) external onlyOwner {
        require(
            lockTokenAddress != address(0),
            "Lock: Invalid lock token address"
        );
        _lockToken = IERC20(lockTokenAddress);
        emit LockTokenUpdated(lockTokenAddress);
    }

    /**
    * @dev Update fee in lock token
    * @param lockTokenFee Fee per lock in lock token
    */
    function updateLockTokenFee(uint256 lockTokenFee) external onlyOwner {
        _lockTokenFee = lockTokenFee;
        emit LockTokenFeeUpdated(lockTokenFee);
    }

    /**
    * @dev Allows admin to update airdrop at given index
    * @param baseToken Base token address for which airdrop has to be updated
    * @param numerator New numerator
    * @param denominator New denominator
    * @param date New airdrop date
    * @param index Index at which this airdrop resides for the basetoken
    */
    function updateAirdrop(
        address baseToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date,
        uint256 index
    )
        external
        onlyOwner
    {
        require(
            _baseTokenVsAirdrops[baseToken].length > index,
            "Lock: Invalid index value!!"
        );
        require(numerator > 0, "Lock: Invalid numerator!!");
        require(denominator > 0, "Lock: Invalid denominator!!");

        Airdrop storage airdrop = _baseTokenVsAirdrops[baseToken][index];
        airdrop.numerator = numerator;
        airdrop.denominator = denominator;
        airdrop.date = date;

        emit AirdropUpdated(
            baseToken,
            airdrop.destToken,
            index,
            date,
            numerator,
            denominator
        );
    }

    /**
    * @dev Allows admin to set fee receiver wallet
    * @param wallet New wallet address
    */
    function setWallet(address payable wallet) external onlyOwner {
        require(
            wallet != address(0),
            "Lock: Please provider valid wallet address!!"
        );
        _wallet = wallet;

        emit WalletChanged(wallet);
    }

    /**
    * @dev Allows admin to update token info
    * @param tokenAddress Address of the token to be updated
    * @param minAmount Min amount of tokens required to lock
    * @param emergencyUnlock If token is in emergency unlock state
    * @param tierAmounts Threshold amount for chargin fee
    * @param tierFees Fees for each tier
    */
    function updateToken(
        address tokenAddress,
        uint256 minAmount,
        bool emergencyUnlock,
        uint256[] calldata tierAmounts,
        uint256[] calldata tierFees
    )
        external
        onlyOwner
        tokenExist(tokenAddress)
    {
        require(
            tierAmounts.length == tierFees.length,
            "Lock: Tiers does not match"
        );

        uint256 index = _tokenVsIndex[tokenAddress].sub(1);
        Token storage token = _tokens[index];
        token.minAmount = minAmount;
        token.emergencyUnlock = emergencyUnlock;
        token.tierAmounts = tierAmounts;
        token.tierFees = tierFees;
        emit TokenUpdated(
            index,
            tokenAddress,
            minAmount,
            emergencyUnlock,
            tierAmounts,
            tierFees
        );
    }

    /**
    * @dev Allows admin to add new token to the list
    * @param token Address of the token
    * @param minAmount Minimum amount of tokens to lock for this token
    * @param tierAmounts Threshold amount for chargin fee
    * @param tierFees Fees for each tier
    */
    function addToken(
        address token,
        uint256 minAmount,
        uint256[] calldata tierAmounts,
        uint256[] calldata tierFees
    )
        external
        onlyOwner
        tokenDoesNotExist(token)
    {
        require(
            tierAmounts.length == tierFees.length,
            "Lock: Tiers does not match"
        );

        _tokens.push(Token({
            tokenAddress: token,
            minAmount: minAmount,
            emergencyUnlock: false,
            status: TokenStatus.ACTIVE,
            tierAmounts: tierAmounts,
            tierFees: tierFees
        }));
        _tokenVsIndex[token] = _tokens.length;

        emit TokenAdded(token);
    }


    /**
    * @dev Allows admin to inactivate token
    * @param token Address of the token to be inactivated
    */
    function inactivateToken(
        address token
    )
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);

        require(
            _tokens[index].status == TokenStatus.ACTIVE,
            "Lock: Token already inactive!!"
        );

        _tokens[index].status = TokenStatus.INACTIVE;

        emit TokenInactivated(token);
    }

    /**
    * @dev Allows admin to activate any existing token
    * @param token Address of the token to be activated
    */
    function activateToken(
        address token
    )
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);

        require(
            _tokens[index].status == TokenStatus.INACTIVE,
            "Lock: Token already active!!"
        );

        _tokens[index].status = TokenStatus.ACTIVE;

        emit TokenActivated(token);
    }

    /**
    * @dev Allows user to lock asset. In case of ERC-20 token the user will
    * first have to approve the contract to spend on his/her behalf
    * @param tokenAddress Address of the token to be locked
    * @param amount Amount of tokens to lock
    * @param duration Duration for which tokens to be locked. In seconds
    * @param beneficiary Address of the beneficiary
    * @param amountThreshold Threshold amount which is when locked in a single lock will make that lock claimable
    * @param lockFee Bool to check if fee to be paid in lock token or not
    */
    function lock(
        address tokenAddress,
        uint256 amount,
        uint256 duration,
        address payable beneficiary,
        uint256 amountThreshold,
        bool lockFee
    )
        external
        payable
        whenNotPaused
        canLockAsset(tokenAddress)
    {
        uint256 remValue = _lock(
            tokenAddress,
            amount,
            duration,
            beneficiary,
            amountThreshold,
            msg.value,
            lockFee
        );

        require(
            remValue < 10000000000,
            "Lock: Sent more ethers then required"
        );

    }

    /**
    * @dev Allows user to lock asset. In case of ERC-20 token the user will
    * first have to approve the contract to spend on his/her behalf
    * @param tokenAddress Address of the token to be locked
    * @param amounts List of amount of tokens to lock
    * @param durations List of duration for which tokens to be locked. In seconds
    * @param beneficiaries List of addresses of the beneficiaries
    * @param amountThresholds List of threshold amounts which is when locked in a single lock will make that lock claimable
    * @param lockFee Bool to check if fee to be paid in lock token or not
    */
    function bulkLock(
        address tokenAddress,
        uint256[] calldata amounts,
        uint256[] calldata durations,
        address payable[] calldata beneficiaries,
        uint256[] calldata amountThresholds,
        bool lockFee
    )
        external
        payable
        whenNotPaused
        canLockAsset(tokenAddress)
    {
        uint256 remValue = msg.value;
        require(amounts.length == durations.length, "Lock: Invalid input");
        require(amounts.length == beneficiaries.length, "Lock: Invalid input");
        require(
            amounts.length == amountThresholds.length,
            "Lock: Invalid input"
        );

        for(uint256 i = 0; i < amounts.length; i++){
            remValue = _lock(
                tokenAddress,
                amounts[i],
                durations[i],
                beneficiaries[i],
                amountThresholds[i],
                remValue,
                lockFee
            );
        }

        require(
            remValue < 10000000000,
            "Lock: Sent more ethers then required"
        );

    }

    /**
    * @dev Allows beneficiary of locked asset to claim asset after lock-up period ends
    * @param id Id of the locked asset
    */
    function claim(uint256 id) external canClaim(id) {
        LockedAsset memory lockedAsset = _idVsLockedAsset[id];
        if(ETH_ADDRESS == lockedAsset.token) {
            _claimETH(
                id
            );
        }

        else {
            _claimERC20(
                id
            );
        }

        emit AssetClaimed(
            id,
            lockedAsset.beneficiary,
            lockedAsset.token
        );
    }

    /**
    * @dev Allows anyone to add more tokens in the existing lock
    * @param id id of the locked asset
    * @param amount Amount to be added
    * @param lockFee Bool to check if fee to be paid in lock token or not
    */
    function addAmount(
        uint256 id,
        uint256 amount,
        bool lockFee
    )
        external
        payable
        whenNotPaused
    {
        LockedAsset storage lockedAsset = _idVsLockedAsset[id];

        require(lockedAsset.status == Status.OPEN, "Lock: Lock is not open");
        
        Token memory token = _tokens[_tokenVsIndex[lockedAsset.token].sub(1)];

        //At the time of addition of tokens previous aridrops will be claimed
        _claimAirdroppedTokens(
            lockedAsset.token,
            lockedAsset.lastLocked,
            lockedAsset.amount
        );


        uint256 fee = 0;
        uint256 newAmount = 0;
        (fee, newAmount) = _calculateFee(amount, lockFee, token);

        if(lockFee) {
            _lockToken.safeTransferFrom(msg.sender, _wallet, _lockTokenFee);
        }
        if(ETH_ADDRESS == lockedAsset.token) {
            require(amount == msg.value, "Lock: Insufficient value sent");

            if(!lockFee) {
                (bool success,) = _wallet.call.value(fee)("");
                require(success, "Lock: Transfer of fee failed");
            }
        }
        else {
            if(!lockFee){
                IERC20(lockedAsset.token).safeTransferFrom(msg.sender, _wallet, fee);
            }

            IERC20(lockedAsset.token).safeTransferFrom(msg.sender, address(this), newAmount);
        }

        lockedAsset.amount = lockedAsset.amount.add(newAmount);
        lockedAsset.lastLocked = block.timestamp;

        emit AmountAdded(lockedAsset.beneficiary, id, newAmount);

    }


    /**
    * @dev Returns whether given asset can be claimed or not
    * @param id id of an asset
    */
    function claimable(uint256 id) public view returns(bool){

        LockedAsset memory asset = _idVsLockedAsset[id];
        if(
            asset.status == Status.OPEN &&
            (
                asset.endDate <= block.timestamp ||
                _tokens[_tokenVsIndex[asset.token].sub(1)].emergencyUnlock ||
                (asset.amountThreshold > 0 && asset.amount >= asset.amountThreshold)
            )
        )
        {
            return true;
        }
        return false;
    }

    /**
    * @dev Returns whether provided token is active or not
    * @param token Address of the token to be checked
    */
    function isActive(address token) public view returns(bool) {
        uint256 index = _tokenVsIndex[token];

        if(index > 0){
            return (_tokens[index.sub(1)].status == TokenStatus.ACTIVE);
        }
        return false;
    }

    /**
    * @dev Helper method to lock asset
    */
    function _lock(
        address tokenAddress,
        uint256 amount,
        uint256 duration,
        address payable beneficiary,
        uint256 amountThreshold,
        uint256 value,
        bool lockFee
    )
        private
        returns(uint256)
    {
        require(
            beneficiary != address(0),
            "Lock: Provide valid beneficiary address!!"
        );

        Token memory token = _tokens[_tokenVsIndex[tokenAddress].sub(1)];

        require(
            amount >= token.minAmount,
            "Lock: Please provide minimum amount of tokens!!"
        );

        uint256 endDate = block.timestamp.add(duration);
        uint256 fee = 0;
        uint256 newAmount = 0;

        (fee, newAmount) = _calculateFee(amount, lockFee, token);

        uint256 remValue = value;

        if(ETH_ADDRESS == tokenAddress) {
            _lockETH(
                newAmount,
                fee,
                endDate,
                beneficiary,
                amountThreshold,
                value,
                lockFee
            );

            remValue = remValue.sub(amount);
        }

        else {
            _lockERC20(
                tokenAddress,
                newAmount,
                fee,
                endDate,
                beneficiary,
                amountThreshold,
                lockFee
            );
        }

        emit AssetLocked(
            tokenAddress,
            msg.sender,
            beneficiary,
            _lockId,
            newAmount,
            block.timestamp,
            endDate,
            lockFee,
            fee
        );

        return remValue;
    }

    /**
    * @dev Helper method to lock ETH
    */
    function _lockETH(
        uint256 amount,
        uint256 fee,
        uint256 endDate,
        address payable beneficiary,
        uint256 amountThreshold,
        uint256 value,
        bool lockFee
    )
        private
    {

        //Transferring fee to the wallet

        if(lockFee){
	    require(value >= amount, "Lock: Enough ETH not sent!!");
            _lockToken.safeTransferFrom(msg.sender, _wallet, fee);
        }
        else {
            require(value >= amount.add(fee), "Lock: Enough ETH not sent!!");
            (bool success,) = _wallet.call.value(fee)("");
            require(success, "Lock: Transfer of fee failed");
        }
        

        _lockId = _lockId.add(1);

        _idVsLockedAsset[_lockId] = LockedAsset({
            token: ETH_ADDRESS,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            lastLocked: block.timestamp,
            beneficiary: beneficiary,
            status: Status.OPEN,
            amountThreshold: amountThreshold
        });
        _userVsLockIds[beneficiary].push(_lockId);
    }

    /**
    * @dev Helper method to lock ERC-20 tokens
    */
    function _lockERC20(
        address token,
        uint256 amount,
        uint256 fee,
        uint256 endDate,
        address payable beneficiary,
        uint256 amountThreshold,
        bool lockFee
    )
        private
    {

        //Transfer fee to the wallet
        if(lockFee){
            _lockToken.safeTransferFrom(msg.sender, _wallet, fee);
        }
        else {
            IERC20(token).safeTransferFrom(msg.sender, _wallet, fee);
        }
        
        //Transfer required amount of tokens to the contract from user balance
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        _lockId = _lockId.add(1);

        _idVsLockedAsset[_lockId] = LockedAsset({
            token: token,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            lastLocked: block.timestamp,
            beneficiary: beneficiary,
            status: Status.OPEN,
            amountThreshold: amountThreshold
        });
        _userVsLockIds[beneficiary].push(_lockId);
    }

    /**
    * @dev Helper method to claim ETH
    */
    function _claimETH(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        (bool success,) = msg.sender.call.value(asset.amount)("");
        require(success, "Lock: Failed to transfer eth!!");

        _claimAirdroppedTokens(
            asset.token,
            asset.lastLocked,
            asset.amount
        );
    }

    /**
    * @dev Helper method to claim ERC-20
    */
    function _claimERC20(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        IERC20(asset.token).safeTransfer(msg.sender, asset.amount);
        _claimAirdroppedTokens(
            asset.token,
            asset.lastLocked,
            asset.amount
        );
    }

    /**
    * @dev Helper method to claim airdropped tokens
    * @param baseToken Base Token address
    * @param lastLocked Date when base tokens were last locked
    * @param amount Amount of base tokens locked
    */
    function _claimAirdroppedTokens(
        address baseToken,
        uint256 lastLocked,
        uint256 amount
    )
        private
    {
        //This loop can be very costly if number of airdropped tokens
        //for base token is very large. But we assume that it is not going to be the case
        for(uint256 i = 0; i < _baseTokenVsAirdrops[baseToken].length; i++) {

            Airdrop memory airdrop = _baseTokenVsAirdrops[baseToken][i];

            if(airdrop.date > lastLocked && airdrop.date < block.timestamp) {
                uint256 airdropAmount = amount.mul(airdrop.numerator).div(airdrop.denominator);
                IERC20(airdrop.destToken).safeTransfer(msg.sender, airdropAmount);
                emit TokensAirdropped(airdrop.destToken, airdropAmount);
            }
        }

    }

    //Helper method to calculate fee
    function _calculateFee(
        uint256 amount,
        bool lockFee,
        Token memory token
    )
        private
        view
        returns(uint256 fee, uint256 newAmount)
    {
        newAmount = amount;

        if(lockFee){
            fee = _lockTokenFee;
        }
        else{
            uint256 tempAmount = amount;
            for(
            uint256 i = 0; (i < token.tierAmounts.length - 1 && tempAmount > 0); i++
            )
            {
                if(tempAmount >= token.tierAmounts[i]){
                    tempAmount = tempAmount.sub(token.tierAmounts[i]);
                    fee = fee.add(token.tierAmounts[i].mul(token.tierFees[i]).div(10000));
                }
                else{
                    fee = fee.add(tempAmount.mul(token.tierFees[i]).div(10000));
                    tempAmount = 0;
                }
            }
            //All remaining tokens will be calculated in last tier
            fee = fee.add(
                tempAmount.mul(token.tierFees[token.tierAmounts.length - 1])
                .div(10000)
            );
            newAmount = amount.sub(fee);
        }
        return(fee, newAmount);
    }
}