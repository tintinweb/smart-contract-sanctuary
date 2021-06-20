pragma solidity >=0.4.22 <0.9.0;

import './FarmVault.sol';

contract ListingsMarket is FarmVault {

  // Info on each listing 
  struct ListingInfo {
    address owner;            // Owner of listing
    address holder;           // Current holder of the contract
    uint256 index;            // Index of the listing
    uint256 amount;           // Amount of LP tokens on listing
    uint256 price;            // LP price of listing
    uint256 endTime;          // End time of reward farming duration
    bool onSale;              // Whether this is currently on listing
    //uint256 lstingDuration;     // How long to sell the rewards for
    //uint256 listingEndBlock;     // When the listing ends
    // uint256 prevListingIndex;
    // uint256 nextListingIndex;
  }

  mapping (uint256 => ListingInfo) public indexToListing;
  mapping (address => uint256) public pendingSaleProfits;
  mapping (uint256 => bool) public allowedExpirationTimes;  // A valid expiration timestamp maps to true, set by admin

  event ListingStart(uint256 indexed listingIndex, address indexed seller, uint amount, uint price, uint indexed endTime);
  event ListingAdjust(uint256 indexed listingIndex, address seller, uint price);
  event ListingPause(uint256 indexed listingIndex, address seller, uint price);
  event ListingSold(address seller, address buyer, uint amount, uint price);
  event ListingClose(uint256 listingIndex, address seller, uint amount);

  event ExpirationTimeChange(uint256 _timestamp, bool _isValid);

  modifier isListingOwner(uint _listingIndex) {
    require(indexToListing[_listingIndex].owner == msg.sender, "You are not the owner of this listing");
    _;
  }

  modifier isNotListingOwner(uint _listingIndex) {
    require(indexToListing[_listingIndex].owner != msg.sender, "You are the owner of this listing, cannot perform action");
    _;
  }

  modifier isListingHolder(uint _listingIndex) {
    require(indexToListing[_listingIndex].holder == msg.sender, "You are not the holder of this listing");
    _;
  }

  modifier isNotListingHolder(uint _listingIndex) {
    require(indexToListing[_listingIndex].holder != msg.sender, "You are the holder of this listing, cannot perform action");
    _;
  }

  modifier listingNotExpired(uint _listingIndex) {
    require(indexToListing[_listingIndex].endTime > block.timestamp, "Listing has expired");
    _;
  }

  modifier listingEndTimeValid(uint _listingEndTime) {
    require(allowedExpirationTimes[_listingEndTime], "Not a valid listing end time");
    require(_listingEndTime > block.timestamp, "Can not make a listing in the past");
    _;
  }

  constructor(IBEP20 _farmToken, address _remoteFarm, uint256 _remoteFarmPid) public {
    totalLPsAmount = 0;
    currentListingIndex = 1;
    LPtoken = _farmToken;
    remoteFarm = _remoteFarm;
    remoteFarmPid = _remoteFarmPid;
    lastHarvestBlock = block.number;
    LPxTime = 0;
  }

  /**** LISTING MANAGEMENT FUNCTIONS ****/

  /** 
   *  Initiate a listing for sale
   *  @param _amount The amount of farming LPs to list
   *  @param _price The price per LP of listing
   *  @param _endTime The endTime of listing
   *  
   *  @dev
   *  requires _endTime be valid in allowedExpirationTimes
   *  requires msg.sender holds at least the amount of LPs intended to sell
   */
  function startListing(uint _amount, uint _price, uint _endTime) public listingEndTimeValid(_endTime) {
    require(_amount > 0, "Can't list sale with amount of 0");
    require(userToInfo[msg.sender].LPsAvailableToList >= _amount, "Insufficient tokens to start listing");

    userToInfo[msg.sender].LPsAvailableToList = userToInfo[msg.sender].LPsAvailableToList.sub(_amount);
    indexToListing[currentListingIndex] = ListingInfo(msg.sender, msg.sender, currentListingIndex, _amount, _price, _endTime, true);

    emit ListingStart(currentListingIndex, msg.sender, _amount, _price, _endTime);
    currentListingIndex = currentListingIndex.add(1);
  }

  /**
   *  Adjust a listing's price as owner && holder
   *  @param _listingIndex The listing to adjust
   *  @param _price The new price adjustment
   * 
   *  @dev
   *  requires msg.sender is current owner of listing
   *  requires msg.sender is current holder of listing
   *  requires listing to not have expired
   */
  function adjustListingOwner(uint _listingIndex, uint _price) public listingNotExpired(_listingIndex) isListingOwner(_listingIndex) isListingHolder(_listingIndex) {
    indexToListing[_listingIndex].price = _price;

    emit ListingAdjust(_listingIndex, msg.sender, _price);
  }

  /**
   *  Adjust a purchased listing as holder && not owner
   *  @param _listingIndex The listing to adjust
   *  @param _price The new price adjustment
   * 
   *  @dev
   *  requires msg.sender is not current owner of listing
   *  requires msg.sender is current holder of listing
   *  requires listing to not have expired
   */
  function adjustListingHolder(uint _listingIndex, uint _price) public listingNotExpired(_listingIndex) isNotListingOwner(_listingIndex) isListingHolder(_listingIndex) {
    indexToListing[_listingIndex].price = _price;
    indexToListing[_listingIndex].onSale = true;
    emit ListingAdjust(_listingIndex, msg.sender, _price);
  }

  /**
   *  Pause an exisiting listing as holder && not owner
   *  @param _listingIndex The listing to pause
   * 
   *  @dev
   *  requires msg.sender is not current owner of listing
   *  requires msg.sender is current holder of listing
   *  requires listing to not have expired
   */
  function pauseListing(uint _listingIndex) public isNotListingOwner(_listingIndex) listingNotExpired(_listingIndex) isListingHolder(_listingIndex) {
    indexToListing[currentListingIndex].onSale = false;
    emit ListingPause(_listingIndex, msg.sender, indexToListing[_listingIndex].price);
  }

  /**
   *  Pause an exisiting listing as holder && not owner
   *  @param _listingIndex The listing to buy
   * 
   *  @dev
   *  requires valid _listingIndex
   *  requires buyer to not be holder
   *  requires listing to not have expired
   *  requires buyer has enough funds to purchase listing
   */
  function buyListing(uint _listingIndex) public payable listingNotExpired(_listingIndex) isNotListingHolder(_listingIndex) {
    require(indexToListing[_listingIndex].amount > 0, "Invalid listingIndex with sale amount = 0");
    require(indexToListing[_listingIndex].onSale, "Listing currently not available for sale");
    uint256 saleProfits = indexToListing[_listingIndex].amount.mul(indexToListing[_listingIndex].price);
    require(msg.value >= saleProfits, "Insufficient funds sent for purchase");

    address seller = indexToListing[_listingIndex].holder;

    // Harvest both buyer and seller's pending rewards before recording farmLPs changes
    harvestRewards(msg.sender);
    harvestRewards(seller);
    
    // Update ListingInfo struct
    indexToListing[_listingIndex].onSale = false;
    indexToListing[_listingIndex].holder = msg.sender;

    // Update Seller's UserInfo
    userToInfo[seller].farmLPs = userToInfo[seller].farmLPs.sub(indexToListing[_listingIndex].amount);
    // Update Buyer's UserInfo
    userToInfo[msg.sender].farmLPs = userToInfo[msg.sender].farmLPs.add(indexToListing[_listingIndex].amount);
    // Update Profits
    pendingSaleProfits[seller] = pendingSaleProfits[seller].add(saleProfits);
    emit ListingSold(seller, msg.sender, indexToListing[_listingIndex].amount, indexToListing[_listingIndex].price);
  }

  /**
   *  Close unsold listing or close sold listing after expiration
   *  @param _listingIndex The listing to close
   * 
   *  @dev
   *  requires msg.sender to be owner of listing
   *  requires reward duration to have ended (if not current holder of listing)
   */
  function closeListing(uint256 _listingIndex) public isListingOwner(_listingIndex) {
    // If you don't currently hold this listing
    if (indexToListing[_listingIndex].holder != msg.sender) {
      require(block.timestamp > indexToListing[_listingIndex].endTime, "Listing has not expired"); // Listing must have ended
      // Harvest both buyer and seller's pending rewards before recording farmLPs changes
      harvestRewards(msg.sender);
      harvestRewards(indexToListing[_listingIndex].holder);
      // Update Previous Holder's UserInfo
      userToInfo[indexToListing[_listingIndex].holder].farmLPs = userToInfo[indexToListing[_listingIndex].holder].farmLPs.sub(indexToListing[_listingIndex].amount);
      // Update Owner's farmLPs
      userToInfo[msg.sender].farmLPs = userToInfo[msg.sender].farmLPs.add(indexToListing[_listingIndex].amount);
    } 

    // Update Owner's LPsAvailableToList
    userToInfo[msg.sender].LPsAvailableToList = userToInfo[msg.sender].LPsAvailableToList.add(indexToListing[_listingIndex].amount);
    emit ListingClose(_listingIndex, msg.sender, indexToListing[_listingIndex].amount);
    delete indexToListing[_listingIndex];
  }

  // Collects saleProfits stored in pendingSaleProfits to owner wallet
  function collectSaleProfits() public returns (bool) {
    uint256 amount = pendingSaleProfits[msg.sender];
    if (amount > 0) {
      pendingSaleProfits[msg.sender] = 0;
      if (!payable(msg.sender).send(amount)) {
        pendingSaleProfits[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }


  /**** ADMIN FUNCTIONS ****/

  function setExpirationTimes(uint256 _timestamp, bool _isValid) public onlyOwner {
    allowedExpirationTimes[_timestamp] = _isValid;
    emit ExpirationTimeChange(_timestamp, _isValid);
  }



  /*
  DONE: Custom ending times for listing
  DONE: Auto farmer
  DONE: Harvest at every sale and closeListing
  TODO: Fees on sales
  TODO: Fees on harvest
  */
}

pragma solidity >=0.4.22 <0.9.0;

import './RemoteFarm.sol';

contract FarmVault is RemoteFarm {
  // Info on each user
  struct UserInfo {
    uint256 LPs;                  // Amount of LP tokens owned
    uint256 farmLPs;              // Amount of LP tokens currently farming
    uint256 LPsAvailableToList;   // Amount of LP tokens available to sell
    uint256 lastHarvestBlock;     // Last block that harvest was called for user
  }

  mapping (address => UserInfo) public userToInfo;

  uint256 public currentListingIndex;
  uint256 public totalLPsAmount;
  uint256 internal lastHarvestBlock;
  uint256 internal LPxTime;

  event Deposit(address owner, uint amount);
  event Withdraw(address owner, uint amount);

  // simple deposit 
  function depositToMarket(uint256 _amount) public {
    remoteFarmDeposit(_amount);
    // Always harvest before adjusting user LP values
    harvestRewards(msg.sender);
    
    if (_amount > 0) {
      LPtoken.safeTransferFrom(address(msg.sender), address(this), _amount);

      totalLPsAmount = totalLPsAmount.add(_amount);
      userToInfo[address(msg.sender)].LPs = userToInfo[address(msg.sender)].LPs.add(_amount);
      userToInfo[address(msg.sender)].farmLPs = userToInfo[address(msg.sender)].farmLPs.add(_amount);
      userToInfo[address(msg.sender)].LPsAvailableToList = userToInfo[address(msg.sender)].LPsAvailableToList.add(_amount);
    }
    emit Deposit(msg.sender, _amount);
  }

  // simple withdraw 
  function withdrawFromMarket(uint256 _amount) public {
    require(_amount > 0, "Withdraw must be greater than 0");
    require(userToInfo[address(msg.sender)].LPs >= _amount, "Insufficent funds owned to withdraw");
    require(userToInfo[address(msg.sender)].LPsAvailableToList >= _amount, "Insufficent funds held to withdraw");

    remoteFarmWithdraw(_amount);
    // Always harvest before adjusting user LP values
    harvestRewards(msg.sender);

    userToInfo[address(msg.sender)].LPs = userToInfo[address(msg.sender)].LPs.sub(_amount);
    userToInfo[address(msg.sender)].farmLPs = userToInfo[address(msg.sender)].farmLPs.sub(_amount);
    userToInfo[address(msg.sender)].LPsAvailableToList = userToInfo[address(msg.sender)].LPsAvailableToList.sub(_amount);
    totalLPsAmount = totalLPsAmount.sub(_amount);
    LPtoken.safeTransfer(address(msg.sender), _amount);

    emit Withdraw(msg.sender, _amount);
  }

  // harvest pending user rewards
  function harvestRewards(address userAddress) internal {
    LPxTime = LPxTime.add(totalLPsAmount.mul(block.number.sub(lastHarvestBlock)));

    if (userToInfo[userAddress].farmLPs > 0) {
      uint256 currentRewards = RewardToken.balanceOf(address(this));
      uint256 userBlocksSinceHarvest = block.number.sub(userToInfo[userAddress].lastHarvestBlock);
      uint256 userLPxTime = userToInfo[userAddress].farmLPs.mul(userBlocksSinceHarvest);
      uint256 userRewards = userLPxTime.mul(currentRewards).div(LPxTime);

      // update variables to reflect havested rewards
      lastHarvestBlock = block.number;
      userToInfo[userAddress].lastHarvestBlock = block.number;
      LPxTime = LPxTime.sub(userLPxTime);

      RewardToken.safeTransfer(userAddress, userRewards);
    }
    else { // No need to calculate rewards if user.farmLPs = 0
      // update variables to reflect havested rewards
      lastHarvestBlock = block.number;
      userToInfo[userAddress].lastHarvestBlock = block.number;
    }
  }
}

pragma solidity >=0.4.22 <0.9.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import './PSCFarmInterface.sol';

contract RemoteFarm is Ownable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  address public remoteFarm;
  uint256 public remoteFarmPid;
  IBEP20 public LPtoken;
  IBEP20 public RewardToken;

  function remoteFarmDeposit(uint256 _amount) internal {
    MasterChefInterface farm = MasterChefInterface(remoteFarm);
    farm.deposit(remoteFarmPid, _amount);
  }

  function remoteFarmWithdraw(uint256 _amount) internal {
    MasterChefInterface farm = MasterChefInterface(remoteFarm);
    farm.withdraw(remoteFarmPid, _amount);
  }

  function approveRemoteFarm() public {
    LPtoken.safeApprove(remoteFarm, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
  }

  /*
  function viewPendingRewards() external view returns (uint256) {
    uint256 currentRewards = RewardToken.balanceOf(address(this));
    MasterChefInterface farm = MasterChefInterface(remoteFarm);
    uint256 pendingRewards = farm.pendingCake(remoteFarmPid, address(this));
    return pendingRewards;
  }*/

/*
  function setRemoteFarmAddress(address _farmAddress) public {
    remoteFarm = _farmAddress;
  }
*/
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

pragma solidity >=0.4.22 <0.9.0;

interface MasterChefInterface {
    function poolLength() external view returns (uint256);
    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;
    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;
    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}