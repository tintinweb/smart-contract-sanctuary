/**
 *Submitted for verification at Etherscan.io on 2021-01-08
*/

pragma solidity >=0.7.5;

// SPDX-License-Identifier: BSD-3-Clause

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
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor()  {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract DFSocial_FarmingTRI is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint amount);
    event RewardsDisbursed(uint amount);
    
    // Uniswap ETH/DFSocial LP token contract address
    address public constant LPtokenAddress = 0x731580e6456353E9508be3Ba28C9b64780efD179;
    //DFSocial token address
    address public constant tokenAddress = 0x54ee01beB60E745329E6a8711Ad2D6cb213e38d7; 
    uint public constant withdrawFeePercentX100 = 50;
    uint public constant disburseAmount = 50e18;
    uint public constant disburseDuration = 30 days;
    
    
    uint public disbursePercentX100 = 10000;
    
    uint public lastDisburseTime;
    
    constructor()  {
        lastDisburseTime = block.timestamp;
    }

    
    uint public totalClaimedRewards = 0;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public depositTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    mapping (address => uint) public lastDivPoints;
    
    uint public totalTokensDisbursed = 0;
    uint public contractBalance = 0;
    
    uint public totalDivPoints = 0;
    uint public totalTokens = 0;

    uint internal pointMultiplier = 1e18;

    function addContractBalance(uint amount) public onlyOwner {
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amount), "Cannot add balance!");
        contractBalance = contractBalance.add(amount);
    }
    
    
    function updateAccount(address account) private {
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(Token(tokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = block.timestamp;
        lastDivPoints[account] = totalDivPoints;
    }
    
    function getPendingDivs(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;
        
        uint newDivPoints = totalDivPoints.sub(lastDivPoints[_holder]);

        uint depositedAmount = depositedTokens[_holder];
        
        uint pendingDivs = depositedAmount.mul(newDivPoints).div(pointMultiplier);
            
        return pendingDivs;
    }
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }
    
    
    function deposit(uint amountToDeposit) public {
        require(amountToDeposit > 0, "Cannot deposit 0 Tokens");
        
        updateAccount(msg.sender);
        
        require(Token(LPtokenAddress).transferFrom(msg.sender, address(this), amountToDeposit), "Insufficient Token Allowance");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToDeposit);
        totalTokens = totalTokens.add(amountToDeposit);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            depositTime[msg.sender] = block.timestamp;
        }
    }
    
    function withdraw(uint amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");

        updateAccount(msg.sender);
        
        uint fee = amountToWithdraw.mul(withdrawFeePercentX100).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(LPtokenAddress).transfer(owner, fee), "Could not transfer fee!");

        require(Token(LPtokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        totalTokens = totalTokens.sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function emergencyWithdraw(uint amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");

        lastClaimedTime[msg.sender] = block.timestamp;
        lastDivPoints[msg.sender] = totalDivPoints;
        
        uint fee = amountToWithdraw.mul(withdrawFeePercentX100).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(LPtokenAddress).transfer(owner, fee), "Could not transfer fee!");

        require(Token(LPtokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        totalTokens = totalTokens.sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claim() public {
        updateAccount(msg.sender);
    }
    
    function distributeDivs(uint amount) private {
        if (totalTokens == 0) return;
        totalDivPoints = totalDivPoints.add(amount.mul(pointMultiplier).div(totalTokens));
        emit RewardsDisbursed(amount);
    }
    
    function disburseTokens() public onlyOwner {
        uint amount = getPendingDisbursement();
        
        // uint contractBalance = Token(tokenAddress).balanceOf(address(this));
        
        if (contractBalance < amount) {
            amount = contractBalance;
        }
        if (amount == 0) return;
        distributeDivs(amount);
        contractBalance = contractBalance.sub(amount);
        lastDisburseTime = block.timestamp;
        
    }
    
    function getPendingDisbursement() public view returns (uint) {
        uint timeDiff = block.timestamp.sub(lastDisburseTime);
        uint pendingDisburse = disburseAmount
                                    .mul(disbursePercentX100)
                                    .mul(timeDiff)
                                    .div(disburseDuration)
                                    .div(10000);
        return pendingDisburse;
    }
    
    

    /* function to allow owner to claim *other* ERC20 tokens sent to this contract.
        Owner cannot recover unclaimed tokens (they are burnt)
    */
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        // require(_tokenAddr != tokenAddress && _tokenAddr != LPtokenAddress, "Cannot send out reward tokens or LP tokens!");
        
        require(_tokenAddr != LPtokenAddress, "Admin cannot transfer out LP tokens from this vault!");
        require(_tokenAddr != tokenAddress , "Admin cannot Transfer out Reward Tokens from this vault!");
        
        Token(_tokenAddr).transfer(_to, _amount);
    }
}