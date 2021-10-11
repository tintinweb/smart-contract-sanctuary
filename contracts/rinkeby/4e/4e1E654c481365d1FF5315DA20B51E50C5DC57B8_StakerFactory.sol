// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Staker.sol";

interface IMintShopFactory{
  function createShop(address _owner, address _paymentReceiver, uint256 _globalPurchaseLimit ) external returns ( address );
}

/**
  @title A basic smart contract for spawning and tracking the ownership of SuperFarm Stakers.
  @author 0xthrpw;

  This is the governing registry of all SuperFarm Staker assets.
*/
contract StakerFactory is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// A struct used to specify token and pool strengths for adding a pool.
  struct PoolData {
    IERC20 poolToken;
    uint256 tokenStrength;
    uint256 pointStrength;
  }

  address public mintShopFactory;

  address public feeToken;

  uint256 public feeAmount;

  address public feeReceiver;

  /// A version number for this record contract's interface.
  uint256 public version = 2;

  struct Record {
    address staker;
    address mintshop;
  }

  /// A mapping for an array of all Stakers/Shops deployed by a particular address.
  mapping (address => Record[]) public farmRecords;

  /// An event for tracking the creation of a new Staker and MintShop.
  event FarmShopCreated(address indexed farmAddress, address indexed shopAddress, address indexed creator);

  /// An event for tracking the manual addition of a new Staker MintShop pair
  event FarmShopAdded(address indexed farmAddress, address indexed shopAddress, address indexed updater);

  constructor (
    uint256 _feeAmount,
    address _feeToken,
    address _feeReceiver,
    address _mintshopFactory
  ) {
    feeAmount = _feeAmount;
    feeToken = _feeToken;
    feeReceiver = _feeReceiver;
    mintShopFactory = _mintshopFactory;
  }

  /**
    Create a Staker on behalf of the owner calling this function. The Staker
    supports immediate specification of the emission schedule and pool strength.

    @param _name The name of the Staker to create.
    @param _token The Token to reward stakers in the Staker with.
    @param _tokenSchedule An array of EmissionPoints defining the token schedule.
    @param _pointSchedule An array of EmissionPoints defining the point schedule.
    @param _initialPools An array of pools to initially add to the new Staker.
  */
  function createFarm(
    string calldata _name,
    IERC20 _token,
    Staker.EmissionPoint[] memory _tokenSchedule,
    Staker.EmissionPoint[] memory _pointSchedule,
    PoolData[] calldata _initialPools
  ) nonReentrant external returns ( Staker, address ) {
    uint256 userBalance = IERC20(feeToken).balanceOf(msg.sender);
    require(userBalance > feeAmount, "StakerFactory::createFarm: Not enough tokens to pay fee");
    IERC20(feeToken).safeTransferFrom(msg.sender, feeReceiver, feeAmount);

    // Create a new Staker contract
    Staker newStaker = new Staker(_name, _token);

    // Establish the emissions schedule and add the token pools.
    newStaker.setEmissions(_tokenSchedule, _pointSchedule);
    for (uint256 i = 0; i < _initialPools.length; i++) {
      newStaker.addPool(_initialPools[i].poolToken, _initialPools[i].tokenStrength, _initialPools[i].pointStrength);
    }

    // Transfer ownership of the new Staker to the user then store a reference.
    newStaker.transferOwnership(msg.sender);
    address stakerAddress = address(newStaker);

    // Create a new MintShop contract with the msg.sender set as owner and fee receiver
    address newMintshop = IMintShopFactory(mintShopFactory).createShop(msg.sender, msg.sender, uint(10000));

    Record memory newRecord = Record({
      staker: stakerAddress,
      mintshop: newMintshop
    });
    farmRecords[msg.sender].push(newRecord);
    emit FarmShopCreated(stakerAddress, newMintshop, msg.sender);

    return (newStaker, newMintshop);
  }

  /**
    Allow a user to add an existing Staker contract to the registry.

    @param _farmAddress The address of the Staker contract to add for this user.
  */
  function addFarm(address _farmAddress, address _shopAddress) external {
    Record memory newRecord = Record({
      staker: _farmAddress,
      mintshop: _shopAddress
    });
    farmRecords[msg.sender].push(newRecord);
    emit FarmShopAdded(_farmAddress, _shopAddress, msg.sender);
  }

  /**
    Get the number of entries in the Staker records mapping for the given user.

    @param _user The address of the farm deployer
    @return The number of Stakers added for a given address.
  */
  function getFarmCount(address _user) external view returns (uint256) {
    return farmRecords[_user].length;
  }

  /**
    Set the amount of tokens required to deploy a farm

    @param _feeAmount The amount of tokens to pay on deployment
  */
  function updateFeeAmount(uint256 _feeAmount) external onlyOwner {
    feeAmount = _feeAmount;
  }

  /**
    Set the address that will receive fee tokens

    @param _feeReceiver The address that will receive fees
  */
  function updateFeeAmount(address _feeReceiver) external onlyOwner {
    feeReceiver = _feeReceiver;
  }

  /**
    Set the address of the MintShopFactory

    @param _mintShopFactoryAddress The address of the MintShopFactory
  */
  function updateShopFactoryAddress(address _mintShopFactoryAddress) external onlyOwner {
    mintShopFactory = _mintShopFactoryAddress;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
  @title An asset staking contract.
  @author Tim Clancy
  @author Qazawat Zirak

  This staking contract disburses tokens from its internal reservoir according
  to a fixed emission schedule. Assets can be assigned varied staking weights.
  This code is inspired by and modified from Sushi's Master Chef contract.
  https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
*/
contract Staker is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// A user-specified, descriptive name for this Staker.
  string public name;

  /// The token to disburse.
  IERC20 public token;

  /// A flag signalling whether the contract owner can add or set developers.
  bool public canAlterDevelopers;

  /// An array of developer addresses for finding shares in the share mapping.
  address[] public developerAddresses;

  /**
    @dev A mapping of developer addresses to their percent share of emissions.
    Share percentages are represented as 1/1000th of a percent. That is, a 1%
    share of emissions should map an address to 1000.
  */
  mapping (address => uint256) public developerShares;

  /// A flag signalling whether or not the contract owner can alter emissions.
  bool public canAlterTokenEmissionSchedule;
  bool public canAlterPointEmissionSchedule;

  /**
    This emission schedule maps a timestamp to the amount of tokens or points
    that should be disbursed starting at that timestamp.

    @param timeStamp If current time reaches timestamp, the rate is applied.
    @param rate Measure of points/tokens emitted.
  */
  struct EmissionPoint {
    uint256 timeStamp;
    uint256 rate;
  }

  /// Array of emission schedule timestamps for finding emission rate changes.
  uint256 public tokenEmissionEventsCount;
  mapping (uint256 => EmissionPoint) public tokenEmissionEvents;
  uint256 public pointEmissionEventsCount;
  mapping (uint256 => EmissionPoint) public pointEmissionEvents;

  /// Store the very earliest possible timestamp for quick reference.
  uint256 MAX_INT = 2**256 - 1;
  uint256 internal earliestTokenEmissionTime;
  uint256 internal earliestPointEmissionTime;

/**
    A struct containing the pool info tracked in storage.

    @param token address of the ERC20 asset that is being staked in the pool.
    @param tokenStrength the relative token emission strength of this pool.
    @param tokensPerShare accumulated tokens per share times 1e12.
    @param pointStrength the relative point emission strength of this pool.
    @param pointsPerShare accumulated points per share times 1e12.
    @param lastRewardTime record of the time of the last disbursement.
  */
  struct PoolInfo {
    IERC20 token;
    uint256 tokenStrength;
    uint256 tokensPerShare;
    uint256 pointStrength;
    uint256 pointsPerShare;
    uint256 lastRewardTime;
  }

  IERC20[] public poolTokens;

  /// Stored information for each available pool per its token address.
  mapping (IERC20 => PoolInfo) public poolInfo;

  /**
    A struct containing the user info tracked in storage.

    @param amount amount of the pool asset being provided by the user.
    @param tokenPaid value of user's total token earnings paid out.
    pending reward = (user.amount * pool.tokensPerShare) - user.rewardDebt.
    @param pointPaid value of user's total point earnings paid out.
  */
  struct UserInfo {
    uint256 amount;
    uint256 tokenPaid;
    uint256 pointPaid;
  }

  /// Stored information for each user staking in each pool.
  mapping (IERC20 => mapping (address => UserInfo)) public userInfo;

  /// The total sum of the strength of all pools.
  uint256 public totalTokenStrength;
  uint256 public totalPointStrength;

  /// The total amount of the disbursed token ever emitted by this Staker.
  uint256 public totalTokenDisbursed;

  /// Users additionally accrue non-token points for participating via staking.
  mapping (address => uint256) public userPoints;
  mapping (address => uint256) public userSpentPoints;

  /// A map of all external addresses that are permitted to spend user points.
  mapping (address => bool) public approvedPointSpenders;

  /// Events for depositing assets into the Staker and later withdrawing them.
  event Deposit(address indexed user, IERC20 indexed token, uint256 amount);
  event Withdraw(address indexed user, IERC20 indexed token, uint256 amount);

  /// An event for tracking when a user has spent points.
  event SpentPoints(address indexed source, address indexed user, uint256 amount);

  /**
    Construct a new Staker by providing it a name and the token to disburse.
    @param _name The name of the Staker contract.
    @param _token The token to reward stakers in this contract with.
  */
  constructor(string memory _name, IERC20 _token) {
    name = _name;
    token = _token;
    token.approve(address(this), MAX_INT);
    canAlterDevelopers = true;
    canAlterTokenEmissionSchedule = true;
    earliestTokenEmissionTime = MAX_INT;
    canAlterPointEmissionSchedule = true;
    earliestPointEmissionTime = MAX_INT;
  }

  /**
    Add a new developer to the Staker or overwrite an existing one.
    This operation requires that developer address addition is not locked.
    @param _developerAddress The additional developer's address.
    @param _share The share in 1/1000th of a percent of each token emission sent
    to this new developer.
  */
  function addDeveloper(address _developerAddress, uint256 _share) external onlyOwner {
    require(canAlterDevelopers,
      "This Staker has locked the addition of developers; no more may be added.");
    developerAddresses.push(_developerAddress);
    developerShares[_developerAddress] = _share;
  }

  /**
    Permanently forfeits owner ability to alter the state of Staker developers.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the fee structure is now immutable.
  */
  function lockDevelopers() external onlyOwner {
    canAlterDevelopers = false;
  }

  /**
    A developer may at any time update their address or voluntarily reduce their
    share of emissions by calling this function from their current address.
    Note that updating a developer's share to zero effectively removes them.
    @param _newDeveloperAddress An address to update this developer's address.
    @param _newShare The new share in 1/1000th of a percent of each token
    emission sent to this developer.
  */
  function updateDeveloper(address _newDeveloperAddress, uint256 _newShare) external {
    uint256 developerShare = developerShares[msg.sender];
    require(developerShare > 0,
      "You are not a developer of this Staker.");
    require(_newShare <= developerShare,
      "You cannot increase your developer share.");
    developerShares[msg.sender] = 0;
    developerAddresses.push(_newDeveloperAddress);
    developerShares[_newDeveloperAddress] = _newShare;
  }

  /**
    Set new emission details to the Staker or overwrite existing ones.
    This operation requires that emission schedule alteration is not locked.

    @param _tokenSchedule An array of EmissionPoints defining the token schedule.
    @param _pointSchedule An array of EmissionPoints defining the point schedule.
  */
  function setEmissions(EmissionPoint[] memory _tokenSchedule, EmissionPoint[] memory _pointSchedule) external onlyOwner {
    if (_tokenSchedule.length > 0) {
      require(canAlterTokenEmissionSchedule,
        "This Staker has locked the alteration of token emissions.");
      tokenEmissionEventsCount = _tokenSchedule.length;
      for (uint256 i = 0; i < tokenEmissionEventsCount; i++) {
        tokenEmissionEvents[i] = _tokenSchedule[i];
        if (earliestTokenEmissionTime > _tokenSchedule[i].timeStamp) {
          earliestTokenEmissionTime = _tokenSchedule[i].timeStamp;
        }
      }
    }
    require(tokenEmissionEventsCount > 0,
      "You must set the token emission schedule.");

    if (_pointSchedule.length > 0) {
      require(canAlterPointEmissionSchedule,
        "This Staker has locked the alteration of point emissions.");
      pointEmissionEventsCount = _pointSchedule.length;
      for (uint256 i = 0; i < pointEmissionEventsCount; i++) {
        pointEmissionEvents[i] = _pointSchedule[i];
        if (earliestPointEmissionTime > _pointSchedule[i].timeStamp) {
          earliestPointEmissionTime = _pointSchedule[i].timeStamp;
        }
      }
    }
    require(pointEmissionEventsCount > 0,
      "You must set the point emission schedule.");
  }

  /**
    Permanently forfeits owner ability to alter the emission schedule.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the inflation rate is now immutable.
  */
  function lockTokenEmissions() external onlyOwner {
    canAlterTokenEmissionSchedule = false;
  }

  /**
    Permanently forfeits owner ability to alter the emission schedule.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the inflation rate is now immutable.
  */
  function lockPointEmissions() external onlyOwner {
    canAlterPointEmissionSchedule = false;
  }

  /**
    Returns the length of the developer address array.
    @return the length of the developer address array.
  */
  function getDeveloperCount() external view returns (uint256) {
    return developerAddresses.length;
  }

  /**
    Returns the length of the staking pool array.
    @return the length of the staking pool array.
  */
  function getPoolCount() external view returns (uint256) {
    return poolTokens.length;
  }

  /**
    Returns the amount of token that has not been disbursed by the Staker yet.
    @return the amount of token that has not been disbursed by the Staker yet.
  */
  function getRemainingToken() external view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
    Allows the contract owner to add a new asset pool to the Staker or overwrite
    an existing one.
    @param _token The address of the asset to base this staking pool off of.
    @param _tokenStrength The relative strength of the new asset for earning token.
    @param _pointStrength The relative strength of the new asset for earning points.
  */
  function addPool(IERC20 _token, uint256 _tokenStrength, uint256 _pointStrength) external onlyOwner {
    require(tokenEmissionEventsCount > 0 && pointEmissionEventsCount > 0,
      "Staking pools cannot be addded until an emission schedule has been defined.");
    require(address(_token) != address(token),
      "Staking pool token can not be the same as reward token.");
    require(_tokenStrength > 0 && _pointStrength > 0,
      "Staking pool token/point strength must be greater than 0.");

    uint256 lastTokenRewardTime = block.timestamp > earliestTokenEmissionTime ? block.timestamp : earliestTokenEmissionTime;
    uint256 lastPointRewardTime = block.timestamp > earliestPointEmissionTime ? block.timestamp : earliestPointEmissionTime;
    uint256 lastRewardTime = lastTokenRewardTime > lastPointRewardTime ? lastTokenRewardTime : lastPointRewardTime;
    if (address(poolInfo[_token].token) == address(0)) {
      poolTokens.push(_token);
      totalTokenStrength = totalTokenStrength + _tokenStrength;
      totalPointStrength = totalPointStrength + _pointStrength;
      poolInfo[_token] = PoolInfo({
        token: _token,
        tokenStrength: _tokenStrength,
        tokensPerShare: 0,
        pointStrength: _pointStrength,
        pointsPerShare: 0,
        lastRewardTime: lastRewardTime
      });
    } else {
      totalTokenStrength = (totalTokenStrength - poolInfo[_token].tokenStrength) + _tokenStrength;
      poolInfo[_token].tokenStrength = _tokenStrength;
      totalPointStrength = (totalPointStrength - poolInfo[_token].pointStrength) + _pointStrength;
      poolInfo[_token].pointStrength = _pointStrength;
    }
  }

  /**
    Uses the emission schedule to calculate the total amount of staking reward
    token that was emitted between two specified timestamps.

    @param _fromTime The time to begin calculating emissions from.
    @param _toTime The time to calculate total emissions up to.
  */
  function getTotalEmittedTokens(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
    require(_toTime >= _fromTime,
      "Tokens cannot be emitted from a higher timestamp to a lower timestamp.");
    uint256 totalEmittedTokens = 0;
    uint256 workingRate = 0;
    uint256 workingTime = _fromTime;
    for (uint256 i = 0; i < tokenEmissionEventsCount; ++i) {
      uint256 emissionTime = tokenEmissionEvents[i].timeStamp;
      uint256 emissionRate = tokenEmissionEvents[i].rate;
      if (_toTime < emissionTime) {
        totalEmittedTokens = totalEmittedTokens + (((_toTime - workingTime) / 15) * workingRate);
        return totalEmittedTokens;
      } else if (workingTime < emissionTime) {
        totalEmittedTokens = totalEmittedTokens + (((emissionTime - workingTime) / 15) * workingRate);
        workingTime = emissionTime;
      }
      workingRate = emissionRate;
    }
    if (workingTime < _toTime) {
      totalEmittedTokens = totalEmittedTokens + (((_toTime - workingTime) / 15) * workingRate);
    }
    return totalEmittedTokens;
  }

  /**
    Uses the emission schedule to calculate the total amount of points
    emitted between two specified timestamps.

    @param _fromTime The time to begin calculating emissions from.
    @param _toTime The time to calculate total emissions up to.
  */
  function getTotalEmittedPoints(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
    require(_toTime >= _fromTime,
      "Points cannot be emitted from a higher timestsamp to a lower timestamp.");
    uint256 totalEmittedPoints = 0;
    uint256 workingRate = 0;
    uint256 workingTime = _fromTime;
    for (uint256 i = 0; i < pointEmissionEventsCount; ++i) {
      uint256 emissionTime = pointEmissionEvents[i].timeStamp;
      uint256 emissionRate = pointEmissionEvents[i].rate;
      if (_toTime < emissionTime) {
        totalEmittedPoints = totalEmittedPoints + (((_toTime - workingTime) / 15) * workingRate);
        return totalEmittedPoints;
      } else if (workingTime < emissionTime) {
        totalEmittedPoints = totalEmittedPoints + (((emissionTime - workingTime) / 15) * workingRate);
        workingTime = emissionTime;
      }
      workingRate = emissionRate;
    }
    if (workingTime < _toTime) {
      totalEmittedPoints = totalEmittedPoints + (((_toTime - workingTime) / 15) * workingRate);
    }
    return totalEmittedPoints;
  }

  /**
    Update the pool corresponding to the specified token address.
    @param _token The address of the asset to update the corresponding pool for.
  */
  function updatePool(IERC20 _token) internal {
    PoolInfo storage pool = poolInfo[_token];
    if (block.timestamp <= pool.lastRewardTime) {
      return;
    }
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (poolTokenSupply <= 0) {
      pool.lastRewardTime = block.timestamp;
      return;
    }

    // Calculate token and point rewards for this pool.
    uint256 totalEmittedTokens = getTotalEmittedTokens(pool.lastRewardTime, block.timestamp);
    uint256 tokensReward = ((totalEmittedTokens * pool.tokenStrength) / totalTokenStrength) * 1e12;
    uint256 totalEmittedPoints = getTotalEmittedPoints(pool.lastRewardTime, block.timestamp);
    uint256 pointsReward = ((totalEmittedPoints * pool.pointStrength) / totalPointStrength) * 1e30;

    // Directly pay developers their corresponding share of tokens and points.
    for (uint256 i = 0; i < developerAddresses.length; ++i) {
      address developer = developerAddresses[i];
      uint256 share = developerShares[developer];
      uint256 devTokens = (tokensReward * share) / 100000;
      tokensReward = tokensReward - devTokens;
      uint256 devPoints = (pointsReward * share) / 100000;
      pointsReward = pointsReward - devPoints;
      token.safeTransferFrom(address(this), developer, devTokens / 1e12);
      userPoints[developer] = userPoints[developer] + (devPoints / 1e30);
    }

    // Update the pool rewards per share to pay users the amount remaining.
    pool.tokensPerShare = pool.tokensPerShare + (tokensReward / poolTokenSupply);
    pool.pointsPerShare = pool.pointsPerShare + (pointsReward / poolTokenSupply);
    pool.lastRewardTime = block.timestamp;
  }

  /**
    A function to easily see the amount of token rewards pending for a user on a
    given pool. Returns the pending reward token amount.
    @param _token The address of a particular staking pool asset to check for a
    pending reward.
    @param _user The user address to check for a pending reward.
    @return the pending reward token amount.
  */
  function getPendingTokens(IERC20 _token, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][_user];
    uint256 tokensPerShare = pool.tokensPerShare;
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));

    if (block.timestamp > pool.lastRewardTime && poolTokenSupply > 0) {
      uint256 totalEmittedTokens = getTotalEmittedTokens(pool.lastRewardTime, block.timestamp);
      uint256 tokensReward = ((totalEmittedTokens * pool.tokenStrength) / totalTokenStrength) * 1e12;
      tokensPerShare = tokensPerShare + (tokensReward / poolTokenSupply);
    }

    return ((user.amount * tokensPerShare) / 1e12) - user.tokenPaid;
  }

  /**
    A function to easily see the amount of point rewards pending for a user on a
    given pool. Returns the pending reward point amount.

    @param _token The address of a particular staking pool asset to check for a
    pending reward.
    @param _user The user address to check for a pending reward.
    @return the pending reward token amount.
  */
  function getPendingPoints(IERC20 _token, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][_user];
    uint256 pointsPerShare = pool.pointsPerShare;
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));

    if (block.timestamp > pool.lastRewardTime && poolTokenSupply > 0) {
      uint256 totalEmittedPoints = getTotalEmittedPoints(pool.lastRewardTime, block.timestamp);
      uint256 pointsReward = ((totalEmittedPoints * pool.pointStrength) / totalPointStrength) * 1e30;
      pointsPerShare = pointsPerShare + (pointsReward / poolTokenSupply);
    }

    return ((user.amount * pointsPerShare) / 1e30) - user.pointPaid;
  }

  /**
    Return the number of points that the user has available to spend.
    @return the number of points that the user has available to spend.
  */
  function getAvailablePoints(address _user) public view returns (uint256) {
    uint256 concreteTotal = userPoints[_user];
    uint256 pendingTotal = 0;
    for (uint256 i = 0; i < poolTokens.length; ++i) {
      IERC20 poolToken = poolTokens[i];
      uint256 _pendingPoints = getPendingPoints(poolToken, _user);
      pendingTotal = pendingTotal + _pendingPoints;
    }
    uint256 spentTotal = userSpentPoints[_user];
    return (concreteTotal + pendingTotal) - spentTotal;
  }

  /**
    Return the total number of points that the user has ever accrued.
    @return the total number of points that the user has ever accrued.
  */
  function getTotalPoints(address _user) external view returns (uint256) {
    uint256 concreteTotal = userPoints[_user];
    uint256 pendingTotal = 0;
    for (uint256 i = 0; i < poolTokens.length; ++i) {
      IERC20 poolToken = poolTokens[i];
      uint256 _pendingPoints = getPendingPoints(poolToken, _user);
      pendingTotal = pendingTotal + _pendingPoints;
    }
    return concreteTotal + pendingTotal;
  }

  /**
    Return the total number of points that the user has ever spent.
    @return the total number of points that the user has ever spent.
  */
  function getSpentPoints(address _user) external view returns (uint256) {
    return userSpentPoints[_user];
  }

  /**
    Deposit some particular assets to a particular pool on the Staker.
    @param _token The asset to stake into its corresponding pool.
    @param _amount The amount of the provided asset to stake.
  */
  function deposit(IERC20 _token, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_token];
    require(pool.tokenStrength > 0 || pool.pointStrength > 0,
      "You cannot deposit assets into an inactive pool.");
    UserInfo storage user = userInfo[_token][msg.sender];
    updatePool(_token);
    if (user.amount > 0) {
      uint256 pendingTokens = ((user.amount * pool.tokensPerShare) / 1e12) - user.tokenPaid;
      token.safeTransferFrom(address(this), msg.sender, pendingTokens);
      totalTokenDisbursed = totalTokenDisbursed + pendingTokens;
      uint256 pendingPoints = ((user.amount * pool.pointsPerShare) / 1e30) - user.pointPaid;
      userPoints[msg.sender] = userPoints[msg.sender] + pendingPoints;
    }
    pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount +_amount;
    user.tokenPaid = (user.amount * pool.tokensPerShare) / 1e12;
    user.pointPaid = (user.amount * pool.pointsPerShare) / 1e30;
    emit Deposit(msg.sender, _token, _amount);
  }

  /**
    Withdraw some particular assets from a particular pool on the Staker.
    @param _token The asset to withdraw from its corresponding staking pool.
    @param _amount The amount of the provided asset to withdraw.
  */
  function withdraw(IERC20 _token, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][msg.sender];
    require(user.amount >= _amount,
      "You cannot withdraw that much of the specified token; you are not owed it.");
    updatePool(_token);
    uint256 pendingTokens = ((user.amount * pool.tokensPerShare) / 1e12) - user.tokenPaid;
    token.safeTransferFrom(address(this), msg.sender, pendingTokens);
    totalTokenDisbursed = totalTokenDisbursed + pendingTokens;
    uint256 pendingPoints = ((user.amount * pool.pointsPerShare) / 1e30) - user.pointPaid;
    userPoints[msg.sender] = userPoints[msg.sender] + pendingPoints;
    user.amount = user.amount - _amount;
    user.tokenPaid = (user.amount * pool.tokensPerShare) / 1e12;
    user.pointPaid = (user.amount * pool.pointsPerShare) / 1e30;
    pool.token.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _token, _amount);
  }

  /**
    Allows the owner of this Staker to grant or remove approval to an external
    spender of the points that users accrue from staking resources.
    @param _spender The external address allowed to spend user points.
    @param _approval The updated user approval status.
  */
  function approvePointSpender(address _spender, bool _approval) external onlyOwner {
    approvedPointSpenders[_spender] = _approval;
  }

  /**
    Allows an approved spender of points to spend points on behalf of a user.
    @param _user The user whose points are being spent.
    @param _amount The amount of the user's points being spent.
  */
  function spendPoints(address _user, uint256 _amount) external {
    require(approvedPointSpenders[msg.sender],
      "You are not permitted to spend user points.");
    uint256 _userPoints = getAvailablePoints(_user);
    require(_userPoints >= _amount,
      "The user does not have enough points to spend the requested amount.");
    userSpentPoints[_user] = userSpentPoints[_user] + _amount;
    emit SpentPoints(msg.sender, _user, _amount);
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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