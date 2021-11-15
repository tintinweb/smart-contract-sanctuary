// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./libraries/EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./utils/TransferHelper.sol";

contract LightingPool is Ownable {
    
    using SafeMath for uint256;

  //token attributes
  string public constant NAME = "lightning pool"; // name of the contract
  uint public maxCap; // Max cap in BNB
  uint256 public saleStartTime; // start sale time
  uint256 public saleEndTime; // end sale time
  uint256 public roundOneLength;
  uint256 public tokenPrice;
  uint256 public lockPeriod;
  
  uint256 public liquidityPercent;

  uint256 public totalBnbReceivedInAllTier; // total bnd received
  uint256 public totalBnbInBronzeTier; // total bnb for bronze tier
  uint256 public totalBnbInSilverTier; // total bnb for silver tier
  uint256 public totalBnbInGoldTier; // total bnb for gold tier
  uint256 public totalBnbInDiamondTier; // total bnb for diamond tier
  uint public totalparticipants; // total participants in ido

  uint256 public totalTokensSold;
  uint256 public totalTokensWithdrawn;

  bool public immutable presaleInEth = true;

  uint256 public totalBaseWithdrawn;
  address payable public projectOwner; // project Owner
  

  address public lightToken; // required token to qualify for tiers
  
  // IERC20 public baseToken; // BNB
  IERC20 public presaleToken; // required token to qualify for tiers

  // max cap per tier
  mapping(uint => uint) public requiredLightByTier; 
  mapping(uint => uint) public allocationByTier;  
  mapping(uint => uint) public maxContributionByTier;   
  mapping(uint => uint) public contributedToTierPool; 

 


  // max cap per tier
  uint public bronzeMaxCap;
  uint public silverMaxCap;
  uint public goldMaxCap;
  uint public diamondMaxCap;
  
  //total users per tier
  uint public totalUserInBronzeTier;
  uint public totalUserInSilverTier;
  uint public totalUserInGoldTier;
  uint public totalUserInDiamondTier;
  
  //max allocations per user in a tier
  uint public maxAllocaPerUserBronzeTier;
  uint public maxAllocaPerUserSilverTier; 
  uint public maxAllocaPerUserGoldTier;
  uint public maxAllocaPerUserDiamondTier;
 
  // address array for bronze tier whitelist
  address[] private whitelistBronzeTier; 
  
  // address array for silver tier whitelist
  address[] private whitelistSilverTier; 
  
  // address array for gold tier whitelist
  address[] private whitelistGoldTier; 
  
  // address array for diamond tier whitelist
  address[] private whitelistDiamondTier;
  

  //mapping the user purchase per tier
  mapping(address => uint) public buyInBronzeTier;
  mapping(address => uint) public buyInSilverTier;
  mapping(address => uint) public buyInGoldTier;
  mapping(address => uint) public buyInDiamondTier;
  
  uint256 public bronzeAllocation;
 


  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
  }

  mapping(address => BuyerInfo) public BUYERS;

  // CONSTRUCTOR  
    constructor(
      uint _hardCap,
      uint256 _poolStartTime,
      uint256 _poolEndTime,
      uint256 _roundOneLength,
      address payable _projectOwner,
      uint256[] memory _requiredLight,
      uint256[] memory _tierAllocations,
      uint256[] memory _maxContributions
    ) {

    maxCap = _hardCap;
    saleStartTime = _poolStartTime;
    saleEndTime = _poolEndTime;
    roundOneLength = _roundOneLength;
    projectOwner = _projectOwner;

    allocationByTier[0] = (_tierAllocations[0]);
    allocationByTier[1] = (_tierAllocations[1]);
    allocationByTier[2] = (_tierAllocations[2]);
    allocationByTier[3] = (_tierAllocations[3]);


    requiredLightByTier[0] = (_requiredLight[0]);
    requiredLightByTier[1] = (_requiredLight[1]);
    requiredLightByTier[2] = (_requiredLight[2]);
    requiredLightByTier[3] = (_requiredLight[3]);

    maxContributionByTier[0] = (_maxContributions[0]);
    maxContributionByTier[1] = (_maxContributions[0]);
    maxContributionByTier[2] = (_maxContributions[0]);
    maxContributionByTier[3] = (_maxContributions[0]);

    contributedToTierPool[0] = (0);
    contributedToTierPool[1] = (0);
    contributedToTierPool[2] = (0);
    contributedToTierPool[3] = (0);
  }

     function init (
      address payable _presaleOwner,
      IERC20 _presaleToken,
      // IERC20 _baseToken,
      address _lightToken,
      uint256[4] memory uint_params
      ) public payable onlyOwner() {
        
        // baseToken = _baseToken;
        presaleToken = _presaleToken;
        lightToken = _lightToken;

        tokenPrice = uint_params[0];
        liquidityPercent = uint_params[1];
        lockPeriod = uint_params[2];
        
        if (lockPeriod < 4 weeks) {
            lockPeriod = 4 weeks;
        }
      
        
        uint256 tokensRequiredForPresale = uint_params[2];

        IERC20(_presaleToken).transferFrom(address(msg.sender), address(this), tokensRequiredForPresale);

        // TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(this), tokensRequiredForPresale);
    }


  // function to update the tiers value manually
  function updateTierValues(uint256 _bronzeTierValue, uint256 _silverTierValue, uint256 _goldTierValue, uint256 _diamondTierValue, uint256 _bronzeMaxContr, uint256 _silverMaxContr, uint256 _goldMaxContr, uint256 _diamondMaxContr) external onlyOwner {
    bronzeMaxCap =_bronzeTierValue;
    silverMaxCap = _silverTierValue;
    goldMaxCap = _goldTierValue;
    diamondMaxCap = _diamondTierValue;
    
    maxAllocaPerUserBronzeTier = _bronzeMaxContr;
    maxAllocaPerUserSilverTier = _silverMaxContr;
    maxAllocaPerUserGoldTier = _goldMaxContr;
    maxAllocaPerUserDiamondTier = _diamondMaxContr;
  }

  function whitelistAddressToBronzeTier(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistBronzeTier.push(_address);
  }

  function whitelistAddressToSilverTier(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistSilverTier.push(_address);
  }

  function whitelistAddressToGoldTier(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistGoldTier.push(_address);
  }

  function whitelistAddressToDiamondTier(address _address) external onlyOwner {
      require(_address != address(0), "Invalid address");
      whitelistDiamondTier.push(_address);
  }

  // check the address in whitelist tier one
  function getBronzeTierWhitelist(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistBronzeTier.length;
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistBronzeTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  // check the address in whitelist tier two
  function getSilverTierWhitelist(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistSilverTier.length;
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistSilverTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  // check the address in whitelist tier three
  function getGoldTierWhitelist(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistGoldTier.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistGoldTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  function getDiamondTierWhitelist(address _address) public view returns(bool) {
      uint i;
    uint length = whitelistDiamondTier.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistGoldTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
    function checkUsersTier (address _user) internal view returns (uint256) {
        if (IERC20(lightToken).balanceOf(_user) >= requiredLightByTier[4]) {
            uint256 index = 4;
            return index;
          }

        else if (IERC20(lightToken).balanceOf(_user) >= requiredLightByTier[3]) {
            uint256 index = 3;
            return index;
          }
        else if (IERC20(lightToken).balanceOf(_user) >= requiredLightByTier[2]) {
            uint256 index = 2;
            return index;
          }
        else if (IERC20(lightToken).balanceOf(_user) >= requiredLightByTier[1]) {
            uint256 index = 1;
            return index;
          }
          else { // no tier, in this case user is not allowed to contribute funds to the pool
            uint256 index = 0; 
            return index;
          }
  }


     // send bnb to the contract address
     function userDeposit(uint256 amount) external payable {
     require(block.timestamp >= saleStartTime, "The sale is not started yet "); // solx^hint-disable
     require(block.timestamp <= saleEndTime, "The sale is closed"); // solhint-disable
     require(totalBnbReceivedInAllTier + msg.value <= maxCap, "buyTokens: purchase would exceed max cap");

     uint256 tierIndex = checkUsersTier(msg.sender); 
    
     require(tierIndex != 0);

      BuyerInfo storage buyer = BUYERS[msg.sender];


     // Presale Round 1 - require participant to hold a certain token and balance
    
     
    if (getBronzeTierWhitelist(msg.sender) || tierIndex == 1) { 
      if (block.number < saleStartTime + roundOneLength) { // 276 blocks = 1 hour
        require(totalBnbInBronzeTier + msg.value <= bronzeMaxCap, "buyTokens: purchase would exceed Tier one max cap");
        }
      require(buyInBronzeTier[msg.sender] + msg.value <= maxAllocaPerUserBronzeTier ,"buyTokens:You are investing more than your tier-1 limit!");
      buyInBronzeTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInBronzeTier += msg.value;      
    } else if (getSilverTierWhitelist(msg.sender) || tierIndex == 2) {
      if (block.number < saleStartTime + roundOneLength) { // 276 blocks = 1 hour
      require(totalBnbInSilverTier + msg.value <= silverMaxCap, "buyTokens: purchase would exceed Tier two max cap");
      }
      require(buyInSilverTier[msg.sender] + msg.value <= maxAllocaPerUserSilverTier ,"buyTokens:You are investing more than your tier-2 limit!");
      buyInSilverTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInSilverTier += msg.value;      
    } else if (getGoldTierWhitelist(msg.sender) || tierIndex == 3) { 
      if (block.number < saleStartTime + roundOneLength) { // 276 blocks = 1 hour
      require(totalBnbInGoldTier + msg.value <= goldMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      }
      require(buyInGoldTier[msg.sender] + msg.value <= maxAllocaPerUserGoldTier ,"buyTokens:You are investing more than your tier-3 limit!");
      buyInGoldTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInGoldTier += msg.value;      
    } else if (getDiamondTierWhitelist(msg.sender) || tierIndex == 4) {
      if (block.number < saleStartTime + roundOneLength) { // 276 blocks = 1 hour
      require(totalBnbInGoldTier + msg.value <= goldMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      } 
      require(buyInDiamondTier[msg.sender] + msg.value <= maxAllocaPerUserGoldTier ,"buyTokens:You are investing more than your tier-3 limit!");
      buyInDiamondTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInDiamondTier += msg.value;
    } else {
      revert();
    }

    uint256 amount_in =  msg.value;
    uint256 remaining = maxCap - totalBnbReceivedInAllTier;

    if (remaining < amount_in) {
      amount_in = remaining;
    }
    
    uint256 tokensSold = amount_in.mul(tokenPrice).div(10 ** 18);
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        totalparticipants++;
    }
    buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
    buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
    
    totalBnbReceivedInAllTier = totalBnbReceivedInAllTier.add(amount_in);
    totalTokensSold = totalTokensSold.add(tokensSold);

    // return unused BNB
    if (amount_in < msg.value) {
      msg.sender.transfer(msg.value.sub(amount_in));
    }

  }

  
    // withdraw presale tokens
    // percentile withdrawals allows fee on transfer or rebasing tokens to still work
    function userWithdrawTokens() external {
    require(presaleStatus() == 2, 'to be changed to LP generation');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 tokensRemainingDenominator = totalTokensSold.sub(totalTokensWithdrawn);
    uint256 tokensOwed = presaleToken.balanceOf(address(this)).mul(buyer.tokensOwed).div(tokensRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    totalTokensWithdrawn = totalTokensWithdrawn.add(buyer.tokensOwed);
    buyer.tokensOwed = 0;
    TransferHelper.safeTransfer(address(presaleToken), msg.sender, tokensOwed);
  }
  
  // on presale failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBNB () external {
    require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 baseRemainingDenominator = totalBnbReceivedInAllTier.sub(totalBaseWithdrawn);
    uint256 remainingBaseBalance = address(this).balance;
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    totalBaseWithdrawn = totalBaseWithdrawn.add(buyer.baseDeposited);
    buyer.baseDeposited = 0;
    msg.sender.call{value: tokensOwed}("");
    // TransferHelper.safeTransferBaseToken(address(baseToken), msg.sender, tokensOwed, presaleInEth);
  }
  
  // on presale failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlyOwner {
    require(presaleStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(presaleToken), projectOwner, presaleToken.balanceOf(address(this)));
  }
  
  function getStartBlock () public view returns (uint256) {
      return saleStartTime;
  }
  
  function getEndBlock () public view returns (uint256) {
      return saleEndTime;
  }
  
  function getRoundOneLength() public view returns (uint256) {
      return roundOneLength;
  }


  function presaleStatus () public view returns (uint256) {
    if ((block.number > saleEndTime) && (totalBnbReceivedInAllTier < maxCap)) {
      return 3; // FAILED - hardcap not met by end block
    }
    if (totalBnbReceivedInAllTier >= maxCap) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.number > saleEndTime) && (totalBnbReceivedInAllTier >= maxCap)) {
      return 2; // SUCCESS - endblock and soft cap reached
    }
    if ((block.number >= saleStartTime) && (block.number <= saleEndTime)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
        * @dev The Ownable constructor sets the original `owner` of the contract to the sender
        * account.
        */
    constructor() public {
        owner = msg.sender;
    }

    /**
        * @dev Throws if called by any account other than the owner.
        */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner has the right to perform this action");
        _;
    }

    /**
        * @dev Allows the current owner to transfer control of the contract to a newOwner.
        * @param newOwner The address to transfer ownership to.
        */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: IERC20.sol

pragma solidity >=0.6.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: SafeMath.sol

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

pragma solidity >=0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: EnumerableSet.sol

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
// Subject to the MIT license.

pragma solidity >=0.6.0;

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

    constructor () internal {
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
pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

