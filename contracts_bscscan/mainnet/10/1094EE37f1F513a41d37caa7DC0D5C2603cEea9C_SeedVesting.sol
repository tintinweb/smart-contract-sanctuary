/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// Sources flattened with hardhat v2.8.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// spdxx-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// spdxxx-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]

// spdxx-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/VestingBase.sol

contract MultiLinearVesting is Ownable {
    address public immutable token;
    IERC20 private tokenContract;

    uint256 public interval = 1 * 30 days;  // Delays between each unlock
    uint256 public linearVestingCycles;
    uint256 public tgePercent; // % that unlocks on TGE day
    uint256 public oneMonthAfterTGEPercent; // % that unlocks 1 month after TGE
    uint256 public vestingStartTime;
    uint256 public unlockEnd;
    uint256 PERCENTAGE_FACTOR = 1000;

    mapping(address => VestingTerms) public vestingData;

    event Distribute(address to, uint256 amount);

    struct InitialVestingData {
        address beneficiary;
        uint256 totalVestedTokens;
    }

    struct VestingTerms {
        uint256 totalVestedTokens;
        uint256 totalClaimed;
        uint256 monthlyRelease; // monthly unlock in the linear vesting phase
        uint256 amountOnTGE;
        uint256 amountOneMonthAfterTGE;
        bool paused;
    }

    modifier isValid {
        require(msg.sender == tx.origin);
        require(vestingStartTime > 0, "Vesting start time not set yet");
        require(block.timestamp > vestingStartTime, "Vesting not started yet");
        require(vestingData[msg.sender].totalVestedTokens > 0, "The account does not have any vested tokens.");
        require(vestingData[msg.sender].totalVestedTokens > vestingData[msg.sender].totalClaimed, "Already claimed all tokens");
        require(!vestingData[msg.sender].paused, "paused");
        _;
        require(vestingData[msg.sender].totalVestedTokens >= vestingData[msg.sender].totalClaimed, "Claim more tokens than vested");
    }
    /* token_ - The token that will be distributed */
    /* cycles_ - number of cycles in the linear vesting part */
    /* tgePercent_ - % to be released on TGE */
    /* oneMonthAfterTGEPercent_ - % to be released one month after TGE */
    constructor(
        address token_,
        uint256 cycles_,
        uint256 tgePercent_,
        uint256 oneMonthAfterTGEPercent_) {
        token = token_;
        linearVestingCycles = cycles_;
        tgePercent = tgePercent_;
        tokenContract = IERC20(token_);
        vestingStartTime = 0;
        oneMonthAfterTGEPercent = oneMonthAfterTGEPercent_;
    }

    function addVestingPolicy(InitialVestingData [] memory initialVestingData_) internal {
        for (uint i = 0; i < initialVestingData_.length; i++) {
            uint256 amountOnTGE = (initialVestingData_[i].totalVestedTokens * tgePercent) / PERCENTAGE_FACTOR;
            uint256 amountOneMonthAfterTGE = (initialVestingData_[i].totalVestedTokens * oneMonthAfterTGEPercent) / PERCENTAGE_FACTOR;
            uint256 remainingAmount = initialVestingData_[i].totalVestedTokens - amountOnTGE - amountOneMonthAfterTGE;
            uint256 monthlyRelease = remainingAmount / linearVestingCycles;
            vestingData[initialVestingData_[i].beneficiary] = VestingTerms(
                initialVestingData_[i].totalVestedTokens,
                0,
                monthlyRelease,
                amountOnTGE,
                amountOneMonthAfterTGE,
                false
            );
        }
    }

    // Claims all available tokens up to now
    function claimAAA() public isValid {
        uint256 amountToSend = getClaimableTokens(msg.sender, block.timestamp);
        require(amountToSend > 0, "No tokens to claim");
        vestingData[msg.sender].totalClaimed += amountToSend;

        _safeWithdraw(msg.sender, amountToSend);
    }

    // Safety function to recover any leftover tokens that may be left in the contract (e.g because of rounding errors).
    // @note this function can only be called after the entire vesting period has ended
    function recoverLeftOversAAA() external isValid {
        require(block.timestamp > unlockEnd, "Unlock end have not reached yet");

        uint256 amountToSend = vestingData[msg.sender].totalVestedTokens - vestingData[msg.sender].totalClaimed;
        // effect
        vestingData[msg.sender].totalClaimed = vestingData[msg.sender].totalVestedTokens;

        // interact
        _safeWithdraw(msg.sender, amountToSend);
    }

    function getTotalAllocation(address investor) public view returns (uint256){
        return vestingData[investor].totalVestedTokens;
    }

    function getAmountOfClaimedTokens(address investor) public view returns (uint256){
        return vestingData[investor].totalClaimed;
    }

    // Returns the number of tokens that the investor is able to claim at the given date
    function getUnlockedTokens(address investor, uint256 blockTimestamp) public view returns (uint256) {
        if (blockTimestamp < vestingStartTime || vestingStartTime == 0) {
            return 0;
        }
        if (vestingData[investor].totalVestedTokens == 0) {
            return 0;
        }

        if (blockTimestamp >= unlockEnd) {
            return vestingData[investor].totalVestedTokens;
        }

        uint256 daysSinceTGE = (blockTimestamp - vestingStartTime) / 1 days;
        uint256 unlocksSinceTGE = (blockTimestamp - vestingStartTime) / interval;
        uint256 amount = vestingData[investor].amountOnTGE;
        if (daysSinceTGE >= 30) {
            // give the investor the fisrt month unlock
            amount += vestingData[investor].amountOneMonthAfterTGE;

            // start the calculation of the linear part
            unlocksSinceTGE -= 30 days / interval;
            amount += getReleasePerInterval(investor) * unlocksSinceTGE;
        }

        // sanity check
        if (amount > vestingData[investor].totalVestedTokens) {
            amount = vestingData[investor].totalVestedTokens;
        }

        return amount;
    }

    function getClaimableTokens(address investor, uint256 blockTimestamp) public view returns (uint256) {
        uint256 unlocked = getUnlockedTokens(investor, blockTimestamp);
        if (unlocked > vestingData[investor].totalClaimed) {
            return unlocked - vestingData[investor].totalClaimed;
        }

        return 0;
    }

    function getAmountOfTokensOnTGE(address investor) external view returns (uint256){
        return vestingData[investor].amountOnTGE;
    }

    function getAmountOfTokensOneMonthAfterTGE(address investor) external view returns (uint256){
        return vestingData[investor].amountOneMonthAfterTGE;
    }

    // After this date, all tokens should be unlocked
    function getVestingEndTimestamp() external view returns (uint256){
        return unlockEnd;
    }

    // TGE date
    function getVestingStartTimestamp() external view returns (uint256){
        return vestingStartTime;
    }

    // Number of tokens that are released each month for the investor
    function getReleasePerInterval(address investor) public view returns (uint256){
        return vestingData[investor].monthlyRelease;
    }

    function setVestingStartTimeAAA(uint256 timestamp) external onlyOwner {
        require(vestingStartTime == 0, "Vesting start time is already set");
        vestingStartTime = timestamp;

        // cycles + 1 because linear vesting starts 2 months after TGE (1st month has different, lower, unlock)
        unlockEnd = vestingStartTime + (linearVestingCycles + 1) * 30 days;
    }

    function setPausedAAA(address a, bool paused) external onlyOwner {
        vestingData[a].paused = paused;
    }

    function _safeWithdraw(address to, uint256 amount) internal {
        uint256 initialTokenBalance = tokenContract.balanceOf(to);
        tokenContract.transfer(to, amount);
        uint256 afterTokenBalance = tokenContract.balanceOf(to);
        require(afterTokenBalance - initialTokenBalance > 0, "failed to send tokens");
    }
}


// File contracts/VestingPrivateA.sol

contract SeedVesting is MultiLinearVesting{
    /// Private B vesting:
    /// 10% unlock on TGE
    /// 9% unlock 1 month later
    /// 7 months of linear vesting of what's left after that
    uint256 tgePercent_ = 60;
    uint256 oneMonthAfterTGEPercent_ = 50;
    uint256 cycles_ = 9; // liner vesting over 3 months after unlock ends.
    InitialVestingData [] initialVestingData_;

    constructor(address tokenAddress) MultiLinearVesting(tokenAddress, cycles_,  tgePercent_, oneMonthAfterTGEPercent_){
        InitialVestingData [1] memory tmp = [
        InitialVestingData(0x1b366A1C1912DE0a7C8abEAA7e6DCe70d392eDaD, 1_000_000 ether)
        ];

        for (uint i = 0; i < tmp.length; i++) {
            initialVestingData_.push(tmp[i]);
        }
        addVestingPolicy(initialVestingData_);
    }
}