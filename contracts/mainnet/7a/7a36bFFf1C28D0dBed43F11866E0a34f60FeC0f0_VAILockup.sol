/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: interfaces/IVAILockup.sol

pragma solidity >=0.4.24;

interface IVAILockup {

    function beneficiaryCurrentAmount(address beneficiary) external view returns (uint256);

    function stake(address beneficiary, uint256 stakeAmount) external;

    function unstake(address beneficiary, uint256 stakeAmount, uint256 rewardsAmount) external;
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: contracts/VAILockup.sol

pragma solidity ^0.5.0;





contract VAILockup is IVAILockup, Ownable {

    // EVENTS
    event TokensLocked(address indexed account, uint256 amount);
    event TokensUnlocked(address indexed account, uint256 amount);
    event TokensStaked(address indexed account, uint256 stakeAmount);
    event TokensUnstaked(address indexed account, uint256 stakeAmount, uint256 rewardsAmount);
    event StakingAddressSet(address indexed account);
    event StartTimeSet(uint256 startTime);

    using Address for address;

    IERC20 private _token;

    struct Lockup {
        address beneficiary;
        uint256 initialAmount;
        uint256 currentAmount;
        uint256 rewardsAmount;
        uint256 partsLeft;
        bool stake;
    }

    uint256 public interval;
    uint256 public startTime;
    uint256 public numberOfParts; 

    Lockup[] private _lockups;

    mapping (address => uint) private _beneficiaryToLockup;

    address private _excessRecipient;

    address private _stakingAddress;

    constructor (address token_, uint256 interval_, uint256 numberOfParts_)
    onlyContract(token_)
    Ownable()
    public {
        _token = IERC20(token_);
        interval = interval_;
        numberOfParts = numberOfParts_;
        _lockups.push(Lockup(address(0), 0, 0, 0, 0, false));
    }

    modifier onlyStaking() {
        require(msg.sender == _stakingAddress, "[Validation] This address is not staking address");
        _;
    }

     modifier onlyContract(address account)
    {
        require(account.isContract(), "[Validation] The address does not contain a contract");
        _;
    }

    modifier onlyAfterSettingStakingAddress() {
        require(_stakingAddress != address(0), "[Validation] The staking address is not set");
        _;
    }

    modifier onlyWhenStartTimeIsNotSet() {
        require(startTime == 0, "[Validation] Start time has been set already");
        _;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the the lockup amount for the beneficiary.
     */
    function beneficiaryCurrentAmount(address beneficiary) public view returns (uint256) {
        return _lockups[_beneficiaryToLockup[beneficiary]].currentAmount;
    }

    function lock(address beneficiary, uint256 amount) public {
        require((amount % numberOfParts) == uint256(0), "The amount must be divisible by the number of parts");
       
        uint lockupIndex = _lockups.push(Lockup(beneficiary, amount, amount, 0, numberOfParts, false)) - 1;
        _beneficiaryToLockup[beneficiary] = lockupIndex;

        require(token().transferFrom(msg.sender, address(this), amount), "Something went wrong during the token transfer");
        emit TokensLocked(beneficiary, amount);
    }

    function unlock(address beneficiary) public {
        Lockup storage lockup = _lockups[_beneficiaryToLockup[beneficiary]];

        require(lockup.stake == false, "Lockup amount is staked");
        require(lockup.partsLeft > 0, "Lockup already unlocked");
        require(now >= (startTime + (interval * 1 days * (numberOfParts - lockup.partsLeft + 1))), "Not enough days passed");
        uint256 tokensToUnlock = lockup.initialAmount / numberOfParts + lockup.rewardsAmount;
        require(token().transfer(beneficiary, tokensToUnlock), "Something went wrong during the token transfer");
        
        lockup.partsLeft -= 1;
        lockup.rewardsAmount = 0;
        lockup.currentAmount -= lockup.initialAmount / numberOfParts;
        emit TokensUnlocked(beneficiary, tokensToUnlock);
    }

    function setStakingAddress(address staking) 
    onlyOwner
    public {
        _stakingAddress = staking;
        token().approve(staking, token().totalSupply());
        emit StakingAddressSet(staking);
    }

    function setStartTime(uint256 startTime_)
    onlyOwner
    onlyWhenStartTimeIsNotSet
    public {
        startTime = startTime_;
        emit StartTimeSet(startTime);
    }

    function stake(address beneficiary, uint256 stakeAmount)
    public
    onlyAfterSettingStakingAddress
    onlyStaking
    {
        Lockup storage lockup = _lockups[_beneficiaryToLockup[beneficiary]];
        lockup.stake = true;
        lockup.currentAmount -= stakeAmount;
        emit TokensStaked(beneficiary, stakeAmount);
    }

    function unstake(address beneficiary, uint256 stakeAmount, uint256 rewardsAmount)
    public
    onlyAfterSettingStakingAddress
    onlyStaking
    {
        Lockup storage lockup = _lockups[_beneficiaryToLockup[beneficiary]];
        lockup.stake = false;
        lockup.currentAmount += stakeAmount;
        lockup.rewardsAmount += rewardsAmount;
        emit TokensUnstaked(beneficiary, stakeAmount, rewardsAmount);
    }
}