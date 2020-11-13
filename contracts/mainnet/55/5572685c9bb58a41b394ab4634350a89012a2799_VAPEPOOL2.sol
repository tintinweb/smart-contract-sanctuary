pragma solidity 0.6.12;

// SPDX-License-Identifier: BSD-3-Clause
//BSD Zero Clause License: "SPDX-License-Identifier: <SPDX-License>"

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
 * 
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * 
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public admin;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    admin = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(admin, newOwner);
    admin = newOwner;
  }
}


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract VAPEPOOL2 is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint amount);
    
    //token contract addresses
    address public VAPEAddress;
    address public LPTokenAddress;
    
    // reward rate % per year
    uint public rewardRate = 119880;
    uint public rewardInterval = 365 days;
    
    //farming fee in percentage
    uint public farmingFeeRate = 0;
    
    //unfarming fee in percentage
    uint public unfarmingFeeRate = 0;
    
    //unfarming possible Time
    uint public PossibleUnfarmTime = 48 hours;
    
    uint public totalClaimedRewards = 0;
    uint private ToBeFarmedTokens;
    
    
    bool public farmingStatus = false;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public farmingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    
/*=============================ADMINISTRATIVE FUNCTIONS ==================================*/

    function setTokenAddresses(address _tokenAddr, address _liquidityAddr) public onlyOwner returns(bool){
     require(_tokenAddr != address(0) && _liquidityAddr != address(0), "Invalid addresses format are not supported");
     VAPEAddress = _tokenAddr;
     LPTokenAddress = _liquidityAddr;
        
    }
    
    function farmingFeeRateSet(uint _farmingFeeRate, uint _unfarmingFeeRate) public onlyOwner returns(bool){
     farmingFeeRate = _farmingFeeRate;
     unfarmingFeeRate = _unfarmingFeeRate;
    
     }
     
     function rewardRateSet(uint _rewardRate) public onlyOwner returns(bool){
     rewardRate = _rewardRate;
    
     }
     
     function StakingReturnsAmountSet(uint _poolreward) public onlyOwner returns(bool){
     ToBeFarmedTokens = _poolreward;
    
     }
     
     
    function possibleUnfarmTimeSet(uint _possibleUnfarmTime) public onlyOwner returns(bool){
        
     PossibleUnfarmTime = _possibleUnfarmTime;
    
     }
     
    function rewardIntervalSet(uint _rewardInterval) public onlyOwner returns(bool){
        
     rewardInterval = _rewardInterval;
    
     }
     
     
    function allowFarming(bool _status) public onlyOwner returns(bool){
        require(VAPEAddress != address(0) && LPTokenAddress != address(0), "Interracting token addresses are not yet configured");
        farmingStatus = _status;
    }
    
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        if (_tokenAddr == VAPEAddress) {
            if (_amount > getFundedTokens()) {
                revert();
            }
            totalClaimedRewards = totalClaimedRewards.add(_amount);
        }
        Token(_tokenAddr).transfer(_to, _amount);
    }
    
    
    function updateAccount(address account) private {
        uint unclaimedDivs = getUnclaimedDivs(account);
        if (unclaimedDivs > 0) {
            require(Token(VAPEAddress).transfer(account, unclaimedDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(unclaimedDivs);
            totalClaimedRewards = totalClaimedRewards.add(unclaimedDivs);
            emit RewardsTransferred(account, unclaimedDivs);
        }
        lastClaimedTime[account] = now;
    }
    
    function getUnclaimedDivs(address _holder) public view returns (uint) {
        
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint timeDiff = now.sub(lastClaimedTime[_holder]);
        
        uint stakedAmount = depositedTokens[_holder];
        
        uint unclaimedDivs = stakedAmount
                            .mul(rewardRate)
                            .mul(timeDiff)
                            .div(rewardInterval)
                            .div(1e4);
            
        return unclaimedDivs;
    }
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }
    
    function farm(uint amountToFarm) public {
        require(farmingStatus == true, "Staking is not yet initialized");
        require(amountToFarm > 0, "Cannot deposit 0 Tokens");
        require(Token(LPTokenAddress).transferFrom(msg.sender, address(this), amountToFarm), "Insufficient Token Allowance");
        
        updateAccount(msg.sender);
        
        uint fee = amountToFarm.mul(farmingFeeRate).div(1e4);
        uint amountAfterFee = amountToFarm.sub(fee);
        require(Token(LPTokenAddress).transfer(admin, fee), "Could not transfer deposit fee.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountAfterFee);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            farmingTime[msg.sender] = now;
        }
    }
    
    function unfarm(uint amountToWithdraw) public {
        
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        require(now.sub(farmingTime[msg.sender]) > PossibleUnfarmTime, "You have not staked for a while yet, kindly wait a bit more");
        
        updateAccount(msg.sender);
        
        uint fee = amountToWithdraw.mul(unfarmingFeeRate).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(LPTokenAddress).transfer(admin, fee), "Could not transfer withdraw fee.");
        require(Token(LPTokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claimRewards() public {
        updateAccount(msg.sender);
    }
    
    function getFundedTokens() public view returns (uint) {
        if (totalClaimedRewards >= ToBeFarmedTokens) {
            return 0;
        }
        uint remaining = ToBeFarmedTokens.sub(totalClaimedRewards);
        return remaining;
    }
    
   
}