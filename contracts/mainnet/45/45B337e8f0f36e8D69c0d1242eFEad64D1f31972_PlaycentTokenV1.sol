pragma solidity 0.6.2;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./safety/ILocker.sol";

contract PlaycentTokenV1 is
  Initializable,
  OwnableUpgradeable,
  ERC20PausableUpgradeable,
  ILockerUser
{
  using SafeMathUpgradeable for uint256;
  /**
   * Category 0 - Team
   * Category 1 - Operations
   * Category 2 - Marketing/Partners
   * Category 3 - Advisors
   * Category 4 - Staking/Earn Incentives
   * Category 5 - Play/Mining
   * Category 6 - Reserve
   * Category 7 - Seed Sale
   * Category 8 - Private 1
   * Category 9 - Private 2
   */

  string public releaseSHA;

  struct VestType {
    uint8 indexId;
    uint8 lockPeriod;
    uint8 vestingDuration;
    uint8 tgePercent;
    uint8 monthlyPercent;
    uint256 totalTokenAllocation;
  }

  struct VestAllocation {
    uint8 vestIndexID;
    uint256 totalTokensAllocated;
    uint256 totalTGETokens;
    uint256 monthlyTokens;
    uint8 vestingDuration;
    uint8 lockPeriod;
    uint256 totalVestTokensClaimed;
    bool isVesting;
    bool isTgeTokensClaimed;
  }

  mapping(uint256 => VestType) internal vestTypes;
  mapping(address => mapping(uint8 => VestAllocation))
    public walletToVestAllocations;

  ILocker public override locker;

  function initialize(address _PublicSaleAddress, address _exchangeLiquidityAddress, string memory _hash)
    public
    initializer
  {
    __Ownable_init();
    __ERC20_init("Playcent", "PCNT");
    __ERC20Pausable_init();
    _mint(owner(), 55200000 ether);
    _mint(_PublicSaleAddress, 2400000 ether);
    _mint(_exchangeLiquidityAddress, 2400000 ether);

    releaseSHA = _hash;

    vestTypes[0] = VestType(0, 12, 32, 0, 5, 9000000 ether); // Team
    vestTypes[1] = VestType(1, 3, 13, 0, 10, 4800000 ether); // Operations
    vestTypes[2] = VestType(2, 3, 13, 0, 10, 4800000 ether); // Marketing/Partners
    vestTypes[3] = VestType(3, 1, 11, 0, 10, 2400000 ether); // Advisors
    vestTypes[4] = VestType(4, 1, 6, 0, 20, 4800000 ether); //Staking/Early Incentive Rewards
    vestTypes[5] = VestType(5, 3, 28, 0, 4, 9000000 ether); //Play Mining
    vestTypes[6] = VestType(6, 6, 31, 0, 4, 4200000 ether); //Reserve
    // Sale Vesting Strategies
    vestTypes[7] = VestType(7, 1, 7, 10, 15, 5700000 ether); // Seed Sale
    vestTypes[8] = VestType(8, 1, 5, 15, 20, 5400000 ether); // Private Sale 1
    vestTypes[9] = VestType(9, 1, 4, 20, 20, 5100000 ether); // Private Sale 2
  }

  modifier onlyValidVestingBenifciary(
    address _userAddresses,
    uint8 _vestingIndex
  ) {
    require(_userAddresses != address(0), "Invalid Address");
    require(
      !walletToVestAllocations[_userAddresses][_vestingIndex].isVesting,
      "User Vesting Details Already Added to this Category"
    );
    _;
  }

  modifier checkVestingStatus(address _userAddresses, uint8 _vestingIndex) {
    require(
      walletToVestAllocations[_userAddresses][_vestingIndex].isVesting,
      "User NOT added to the provided vesting Index"
    );
    _;
  }

  modifier onlyValidVestingIndex(uint8 _vestingIndex) {
    require(_vestingIndex >= 0 && _vestingIndex <= 9, "Invalid Vesting Index");
    _;
  }

  modifier onlyAfterTGE() {
    require(
      getCurrentTime() > getTGETime(),
      "Token Generation Event Not Started Yet"
    );
    _;
  }

  function setLocker(address _locker) external onlyOwner() {
    locker = ILocker(_locker);
  }

  // function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
  //     if (address(locker) != address(0)) {
  //         locker.lockOrGetPenalty(sender, recipient);
  //     }
  //     return ERC20._transfer(sender, recipient, amount);
  // }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    if (address(locker) != address(0)) {
      locker.lockOrGetPenalty(sender, recipient);
    }
    return super._transfer(sender, recipient, amount);
  }

  /**
   * @notice Returns current time
   */
  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  /**
   * @notice Returns the total number of seconds in 1 Day
   */
  function daysInSeconds() internal pure returns (uint256) {
    return 86400;
  }

  /**
   * @notice Returns the total number of seconds in 1 month
   */
  function monthInSeconds() internal pure returns (uint256) {
    return 2592000;
  }

  /**
   * @notice Returns the TGE time
   */
  function getTGETime() public pure returns (uint256) {
    return 1615055400; // March 6, 2021 @ 6:30:00 pm
  }

  /**
   * @notice Calculates the amount of tokens on the basis of monthly rate assigned
   */
  function percentage(uint256 _totalAmount, uint256 _rate)
    internal
    pure
    returns (uint256)
  {
    return _totalAmount.mul(_rate).div(100);
  }

  /**
   * @notice Pauses the contract.
   * @dev Can only be called by the owner
   */
  function pauseContract() external onlyOwner {
    _pause();
  }

  /**
   * @notice Pauses the contract.
   * @dev Can only be called by the owner
   */
  function unPauseContract() external onlyOwner {
    _unpause();
  }

  /**
    * @notice - Allows only the Owner to ADD an array of Addresses as well as their Vesting Amount
              - The array of user and amounts should be passed along with the vestingCategory Index. 
              - Thus, a particular batch of addresses shall be added under only one Vesting Category Index 
    * @param _userAddresses array of addresses of the Users
    * @param _vestingAmounts array of amounts to be vested
    * @param _vestingType allows the owner to select the type of vesting category
    * @return - true if Function executes successfully
    */

  function addVestingDetails(
    address[] calldata _userAddresses,
    uint256[] calldata _vestingAmounts,
    uint8 _vestingType
  ) external onlyOwner onlyValidVestingIndex(_vestingType) returns (bool) {
    require(
      _userAddresses.length == _vestingAmounts.length,
      "Unequal arrays passed"
    );

    // Get Vesting Category Details
    VestType memory vestData = vestTypes[_vestingType];
    uint256 arrayLength = _userAddresses.length;

    uint256 providedVestAmount;

    for (uint256 i = 0; i < arrayLength; i++) {
      uint8 vestIndexID = _vestingType;
      address userAddress = _userAddresses[i];
      uint256 totalAllocation = _vestingAmounts[i];
      uint8 lockPeriod = vestData.lockPeriod;
      uint8 vestingDuration = vestData.vestingDuration;
      uint256 tgeAmount = percentage(totalAllocation, vestData.tgePercent);
      uint256 monthlyAmount =
        percentage(totalAllocation, vestData.monthlyPercent);
      providedVestAmount += _vestingAmounts[i];

      addUserVestingDetails(
        userAddress,
        vestIndexID,
        totalAllocation,
        lockPeriod,
        vestingDuration,
        tgeAmount,
        monthlyAmount
      );
    }
    uint256 ownerBalance = balanceOf(owner());
    require(
      ownerBalance >= providedVestAmount,
      "Owner does't have required token balance"
    );
    _transfer(owner(), address(this), providedVestAmount);
    return true;
  }

  /** @notice - Internal functions that is initializes the VestAllocation Struct with the respective arguments passed
   * @param _userAddresses addresses of the User
   * @param _totalAllocation total amount to be lockedUp
   * @param _vestingIndex denotes the type of vesting selected
   * @param _lockPeriod denotes the lock of the vesting category selcted
   * @param _vestingDuration denotes the total duration of the vesting category selcted
   * @param _tgeAmount denotes the total TGE amount to be transferred to the userVestingData
   * @param _monthlyAmount denotes the total Monthly Amount to be transferred to the user
   */

  function addUserVestingDetails(
    address _userAddresses,
    uint8 _vestingIndex,
    uint256 _totalAllocation,
    uint8 _lockPeriod,
    uint8 _vestingDuration,
    uint256 _tgeAmount,
    uint256 _monthlyAmount
  ) internal onlyValidVestingBenifciary(_userAddresses, _vestingIndex) {
    VestAllocation memory userVestingData =
      VestAllocation(
        _vestingIndex,
        _totalAllocation,
        _tgeAmount,
        _monthlyAmount,
        _vestingDuration,
        _lockPeriod,
        0,
        true,
        false
      );
    walletToVestAllocations[_userAddresses][_vestingIndex] = userVestingData;
  }

  /**
   * @notice Calculates the total amount of tokens Claimed by the User in a particular vesting category
   * @param _userAddresses address of the User
   * @param _vestingIndex index number of the vesting type
   */
  function totalTokensClaimed(address _userAddresses, uint8 _vestingIndex)
    public
    view
    returns (uint256)
  {
    // Get Vesting Details
    uint256 totalClaimedTokens;
    VestAllocation memory vestData =
      walletToVestAllocations[_userAddresses][_vestingIndex];

    totalClaimedTokens = totalClaimedTokens.add(
      vestData.totalVestTokensClaimed
    );

    if (vestData.isTgeTokensClaimed) {
      totalClaimedTokens = totalClaimedTokens.add(vestData.totalTGETokens);
    }

    return totalClaimedTokens;
  }

  /**
   * @notice An internal function to calculate the total claimable tokens at any given point
   * @param _userAddresses address of the User
   * @param _vestingIndex index number of the vesting type
   */

  function calculateClaimableVestTokens(
    address _userAddresses,
    uint8 _vestingIndex
  )
    public
    view
    checkVestingStatus(_userAddresses, _vestingIndex)
    returns (uint256)
  {
    // Get Vesting Details
    VestAllocation memory vestData =
      walletToVestAllocations[_userAddresses][_vestingIndex];

    // Get Time Details
    uint256 actualClaimableAmount;
    uint256 tokensAfterElapsedMonths;
    uint256 vestStartTime = getTGETime();
    uint256 currentTime = getCurrentTime();
    uint256 timeElapsed = currentTime.sub(vestStartTime);

    // Get the Elapsed Days and Months
    uint256 totalMonthsElapsed = timeElapsed.div(monthInSeconds());
    uint256 totalDaysElapsed = timeElapsed.div(daysInSeconds());
    uint256 partialDaysElapsed = totalDaysElapsed.mod(30);

    if (partialDaysElapsed > 0 && totalMonthsElapsed > 0) {
      totalMonthsElapsed += 1;
    }

    //Check whether or not the VESTING CLIFF has been reached
    require(
      totalMonthsElapsed > vestData.lockPeriod,
      "Vesting Cliff Not Crossed Yet"
    );

    // If total duration of Vesting already crossed, return pending tokens to claimed
    if (totalMonthsElapsed > vestData.vestingDuration) {
      uint256 _totalTokensClaimed =
        totalTokensClaimed(_userAddresses, _vestingIndex);
      actualClaimableAmount = vestData.totalTokensAllocated.sub(
        _totalTokensClaimed
      );
      // if current time has crossed the Vesting Cliff but not the total Vesting Duration
      // Calculating Actual Months(Excluding the CLIFF) to initiate vesting
    } else {
      uint256 actualMonthElapsed = totalMonthsElapsed.sub(vestData.lockPeriod);
      require(actualMonthElapsed > 0, "Number of months elapsed is ZERO");
      // Calculate the Total Tokens on the basis of Vesting Index and Month elapsed
      if (vestData.vestIndexID == 9) {
        uint256[4] memory monthsToRates;
        monthsToRates[1] = 20;
        monthsToRates[2] = 50;
        monthsToRates[3] = 80;
        tokensAfterElapsedMonths = percentage(
          vestData.totalTokensAllocated,
          monthsToRates[actualMonthElapsed]
        );
      } else {
        tokensAfterElapsedMonths = vestData.monthlyTokens.mul(
          actualMonthElapsed
        );
      }
      require(
        tokensAfterElapsedMonths > vestData.totalVestTokensClaimed,
        "No Claimable Tokens at this Time"
      );
      // Get the actual Claimable Tokens
      actualClaimableAmount = tokensAfterElapsedMonths.sub(
        vestData.totalVestTokensClaimed
      );
    }
    return actualClaimableAmount;
  }

  /**
   * @notice Function to transfer tokens from this contract to the user
   * @param _beneficiary address of the User
   * @param _amountOfTokens number of tokens to be transferred
   */
  function _sendTokens(address _beneficiary, uint256 _amountOfTokens)
    private
    returns (bool)
  {
    _transfer(address(this), _beneficiary, _amountOfTokens);
    return true;
  }

  /**
   * @notice Calculates and Transfer the total tokens to be transferred to the user after Token Generation Event is over
   * @dev The function shall only work for users under Sale Vesting Category(index - 7,8,9).
   * @dev The function can only be called once by the user(only if the isTgeTokensClaimed boolean value is FALSE).
   * Once the tokens have been transferred, isTgeTokensClaimed becomes TRUE for that particular address
   * @param _userAddresses address of the User
   * @param _vestingIndex index of the vesting Type
   */
  function claimTGETokens(address _userAddresses, uint8 _vestingIndex)
    public
    onlyAfterTGE
    whenNotPaused
    checkVestingStatus(_userAddresses, _vestingIndex)
    returns (bool)
  {
    // Get Vesting Details
    VestAllocation memory vestData =
      walletToVestAllocations[_userAddresses][_vestingIndex];

    require(
      vestData.vestIndexID >= 7 && vestData.vestIndexID <= 9,
      "Vesting Category doesn't belong to SALE VEsting"
    );
    require(
      vestData.isTgeTokensClaimed == false,
      "TGE Tokens Have already been claimed for Given Address"
    );

    uint256 tokensToTransfer = vestData.totalTGETokens;

    uint256 contractTokenBalance = balanceOf(address(this));
    require(
      contractTokenBalance >= tokensToTransfer,
      "Not Enough Token Balance in Contract"
    );

    // Updating Contract State
    vestData.isTgeTokensClaimed = true;
    walletToVestAllocations[_userAddresses][_vestingIndex] = vestData;
    _sendTokens(_userAddresses, tokensToTransfer);
  }

  /**
   * @notice Calculates and Transfers the total tokens to be transferred to the user by calculating the Amount of tokens to be transferred at the given time
   * @dev The function shall only work for users under Vesting Category is valid(index - 1 to 9).
   * @dev isVesting becomes false if all allocated tokens have been claimed.
   * @dev User cannot claim more tokens than actually allocated to them by the OWNER
   * @param _userAddresses address of the User
   * @param _vestingIndex index of the vesting Type
   * @param _tokenAmount the amount of tokens user wishes to withdraw
   */
  function claimVestTokens(
    address _userAddresses,
    uint8 _vestingIndex,
    uint256 _tokenAmount
  )
    public
    onlyAfterTGE
    whenNotPaused
    checkVestingStatus(_userAddresses, _vestingIndex)
    returns (bool)
  {
    // Get Vesting Details
    VestAllocation memory vestData =
      walletToVestAllocations[_userAddresses][_vestingIndex];

    // Get total amount of tokens claimed till date
    uint256 _totalTokensClaimed =
      totalTokensClaimed(_userAddresses, _vestingIndex);
    // Get the total claimable token amount at the time of calling this function
    uint256 tokensToTransfer =
      calculateClaimableVestTokens(_userAddresses, _vestingIndex);

    require(
      tokensToTransfer > 0,
      "No tokens to transfer at this point of time"
    );
    require(
      _tokenAmount <= tokensToTransfer,
      "Cannot Claim more than Monthly Vest Amount"
    );
    uint256 contractTokenBalance = balanceOf(address(this));
    require(
      contractTokenBalance >= _tokenAmount,
      "Not Enough Token Balance in Contract"
    );
    require(
      _totalTokensClaimed.add(_tokenAmount) <= vestData.totalTokensAllocated,
      "Cannot Claim more than Allocated"
    );

    vestData.totalVestTokensClaimed += _tokenAmount;
    if (
      _totalTokensClaimed.add(_tokenAmount) == vestData.totalTokensAllocated
    ) {
      vestData.isVesting = false;
    }
    walletToVestAllocations[_userAddresses][_vestingIndex] = vestData;
    _sendTokens(_userAddresses, _tokenAmount);
  }

  // Commented Out the withdraw function
  // function withdrawContractTokens() external onlyOwner returns (bool) {
  //   uint256 remainingTokens = balanceOf(address(this));
  //   _sendTokens(owner(), remainingTokens);
  // }
}

pragma solidity >=0.6.0 <0.8.0;

interface ILiquiditySyncer {
  function syncLiquiditySupply(address pool) external;
}

interface ILocker {
  /**
   * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
   * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
   */
  function lockOrGetPenalty(address source, address dest)
    external
    returns (bool, uint256);
}

interface ILockerUser {
  function locker() external view returns (ILocker);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../utils/PausableUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}