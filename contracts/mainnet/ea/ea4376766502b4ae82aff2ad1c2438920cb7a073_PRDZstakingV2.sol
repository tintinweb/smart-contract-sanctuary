/**
 *Submitted for verification at Etherscan.io on 2020-12-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: No License

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
  constructor() public {
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

contract PRDZstakingV2 is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsClaimed(address indexed  holder, uint amount , uint indexed  time);
    event TokenStaked(address indexed  holder, uint amount, uint indexed  time);
    event AllTokenStaked(uint amount, uint indexed  time);
    event OfferStaked(uint amount, uint indexed  time);
    
    event AllTokenUnStaked(uint amount, uint indexed  time);
    event AllTokenClaimed(uint amount, uint indexed  time);
    event TokenUnstaked(address indexed  holder, uint amount, uint indexed  time);
    event TokenBurned(uint amount, uint indexed  time);
    event EthClaimed(address indexed  holder, uint amount, uint indexed  time);
    
    // PRDZ token contract address
    address public constant tokenAddress = 0x4e085036A1b732cBe4FfB1C12ddfDd87E7C3664d;
    address public constant burnAddress = 0x0000000000000000000000000000000000000000;
    
    // reward rate 80.00% per year
    uint public constant rewardRate = 8000;
    uint public constant scoreRate = 1000;
    
    uint public constant rewardInterval = 365 days;
    uint public constant scoreInterval = 3 days;
    

    uint public scoreEth = 1000;
    
      // unstaking fee 2.00 percent
    uint public constant unstakingFeeRate = 250;
    
    // unstaking possible after 72 hours
    uint public constant cliffTime = 72 hours;
    
    uint public totalClaimedRewards = 0;
    uint public totalStakedToken = 0;
    uint public totalUnstakedToken = 0;
    uint public totalEthDeposited = 0;
    uint public totalEthClaimed = 0;
    uint public totalFeeCollected = 0;
    uint public totalOfferRaise = 0;
    
    
    uint public stakingOffer = 1607878800;
    uint public stakingOfferRaise = 250;

    

    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    mapping (address => uint) public totalScore;
    mapping (address => uint) public totalOfferUser;
    mapping (address => uint) public lastScoreTime;
  
    /* Updates Total Reward and transfer User Reward on Stake and Unstake. */

    function updateAccount(address account) private {
        uint pendingDivs = getPendingReward(account);
        if (pendingDivs > 0) {
            require(Token(tokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsClaimed(account, pendingDivs, now);
            emit AllTokenClaimed(totalClaimedRewards, now);
        }
        lastClaimedTime[account] = now;
    }


    /* Updates Last Score Time for Users. */
    
    function updateLastScoreTime(address _holder) private  {
           if(lastScoreTime[_holder] > 0){
               uint timeDiff = 0 ;
               timeDiff = now.sub(lastScoreTime[_holder]).div(2); 
               lastScoreTime[_holder] = now.sub(timeDiff) ;
           }else{
              lastScoreTime[_holder] = now ;
           }         
       
    }


    /* Calculate realtime ETH Reward based on User Score. */


   function getScoreEth(address _holder) public view returns (uint) {
        uint timeDiff = 0 ;
       
        if(lastScoreTime[_holder] > 0){
            timeDiff = now.sub(lastScoreTime[_holder]).div(2);            
           }

        uint stakedAmount = depositedTokens[_holder];
       
       
        uint score = stakedAmount
                            .mul(scoreRate)
                            .mul(timeDiff)
                            .div(scoreInterval)
                            .div(1e4);
       
        uint eth = score.div(scoreEth);
        
        return eth;
        

    }

    /* Calculate realtime  User Score. */


    function getStakingScore(address _holder) public view returns (uint) {
           uint timeDiff = 0 ;
           if(lastScoreTime[_holder] > 0){
            timeDiff = now.sub(lastScoreTime[_holder]).div(2);            
           }

            uint stakedAmount = depositedTokens[_holder];
       
       
            uint score = stakedAmount
                            .mul(scoreRate)
                            .mul(timeDiff)
                            .div(scoreInterval)
                            .div(1e4);
        return score;
    }
    
    /* Calculate realtime User Staking Score. */

    
    function getPendingReward(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint timeDiff = now.sub(lastClaimedTime[_holder]);
        uint stakedAmount = depositedTokens[_holder];
        
        uint pendingDivs = stakedAmount
                            .mul(rewardRate)
                            .mul(timeDiff)
                            .div(rewardInterval)
                            .div(1e4);
            
        return pendingDivs;
    }
    
    
    
    /* Fetch realtime Number of Token Claimed. */


    function getTotalClaimed() public view returns (uint) {
        return totalClaimedRewards;
    }

    /* Fetch realtime Number of User Staked. */


    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }

    /* Fetch realtime Token  User Staked. */

      function getTotalStaked() public view returns (uint) {
        return totalStakedToken;
    }

     /* Fetch realtime Token  User UnStaked. */

      function getTotalUnStaked() public view returns (uint) {
        return totalUnstakedToken;
    }

    
    /* Fetch realtime Token Gain from UnstakeFee. */

      function getTotalFeeCollected() public view returns (uint) {
        return totalFeeCollected;
    }
    
    /* Record Staking with Offer check. */

    
    function stake(uint amountToStake) public {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        emit TokenStaked(msg.sender, amountToStake, now);
        
        updateAccount(msg.sender);
        updateLastScoreTime(msg.sender);
        totalStakedToken = totalStakedToken.add(amountToStake);
        
        if(stakingOffer > now){
            uint offerRaise = amountToStake.mul(stakingOfferRaise).div(1e4);          
            totalOfferRaise = totalOfferRaise.add(offerRaise);
            totalOfferUser[msg.sender] = offerRaise ;
            emit OfferStaked(totalStakedToken, now);

            amountToStake = amountToStake.add(offerRaise);
        }

            emit AllTokenStaked(totalStakedToken, now);


        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToStake);

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
        }
    }
    
     
    /* Record UnStaking. */
     


    function unstake(uint amountToWithdraw) public {

        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");        
         
        updateAccount(msg.sender);
        
        uint fee = amountToWithdraw.mul(unstakingFeeRate).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(tokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        emit TokenUnstaked(msg.sender, amountAfterFee,now);
     
        require(Token(tokenAddress).transfer(burnAddress, fee), "Could not burn fee.");
        emit TokenBurned(fee,now);
       
        totalUnstakedToken = totalUnstakedToken.add(amountAfterFee);
        totalFeeCollected = totalFeeCollected.add(fee);
        emit AllTokenUnStaked(totalUnstakedToken, now);
        
        uint timeDiff = 0 ;
        
        if(lastScoreTime[msg.sender] > 0){
            timeDiff = now.sub(lastScoreTime[msg.sender]).div(2);            
        }
      
        uint score = amountAfterFee
                            .mul(scoreRate)
                            .mul(timeDiff)
                            .div(scoreInterval)
                            .div(1e4);
            
        
         
        uint eth = score.div(scoreEth);     
        totalEthClaimed = totalEthClaimed.add(eth);

        msg.sender.transfer(eth);
        emit EthClaimed(msg.sender ,eth,now);

        lastScoreTime[msg.sender] = now;

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }


    /* Claim Reward. */

    
    function claimReward() public {
        updateAccount(msg.sender);
    }


  
    /* Claim ETH Equivalent to Score. */
  
    function claimScoreEth() public {
        uint timeDiff = 0 ;
        
        if(lastScoreTime[msg.sender] > 0){
            timeDiff = now.sub(lastScoreTime[msg.sender]).div(2);            
        }

        uint stakedAmount = depositedTokens[msg.sender];       
       
        uint score = stakedAmount
                            .mul(scoreRate)
                            .mul(timeDiff)
                            .div(scoreInterval)
                            .div(1e4);                    
         
        uint eth = score.div(scoreEth);     
        totalEthClaimed = totalEthClaimed.add(eth);
        msg.sender.transfer(eth);
        emit EthClaimed(msg.sender , eth,now);
 
        
        lastScoreTime[msg.sender] = now;
    
    }
    

    function deposit() payable public {
        totalEthDeposited = totalEthDeposited.add(msg.value);         
    }
    
    function updateScoreEth(uint _amount) public onlyOwner {
            scoreEth = _amount ;
    }
    

       function updateOffer(uint time, uint raise) public onlyOwner {
            stakingOffer = time ;
            stakingOfferRaise = raise ;
    }
 
}