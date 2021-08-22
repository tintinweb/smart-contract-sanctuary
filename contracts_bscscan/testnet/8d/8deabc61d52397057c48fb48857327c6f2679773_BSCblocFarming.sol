/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT

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

library EnumerableSet {

    struct Set {
        bytes32[] _values;

        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);

            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
        
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;


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

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

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

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BSCblocFarming is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint amount);
    
        
    // constructor(address _rewardTokenAddress, uint _rewardRate, uint _stakingFeeRate, uint _unstakingFeeRate, uint _cliffTime ) public {
   
    //     rewardTokenAddress = _rewardTokenAddress;
    //     rewardRate = _rewardRate;
    //     stakingFeeRate = _stakingFeeRate;
    //     unstakingFeeRate = _unstakingFeeRate;
    //     cliffTime = _cliffTime;

    // }
    
    // BSCbloc Token Contract Address
    address public constant tokenAddress = 0x8c026ba2e3363bcE6506A48237894D13be3B67Ae;
    
    address public  rewardTokenAddress = 0x8c026ba2e3363bcE6506A48237894D13be3B67Ae;
    
    // reward rate 17.00% per year
    uint public  rewardRate = 1700;
    uint public  rewardInterval = 365 days;     
    
    //   staking fee 0.5 %
    uint public  stakingFeeRate = 50;
    
    // unstaking fee 0.5 %
    uint public  unstakingFeeRate = 50;
    
    // unstaking possible after 1 Days
    uint public  cliffTime = 1 days;
    
    uint public totalClaimedRewards = 0;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    
    function updateAccount(address account) private {
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(Token(rewardTokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = now;
    }
    
    function getPendingDivs(address _holder) public view returns (uint) {
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
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }

   

    function setRewardRate(uint _rewardRate)public onlyOwner {
        rewardRate = _rewardRate;
    }
     function setRewardInterval(uint _rewardInterval) public onlyOwner{
        rewardInterval = _rewardInterval;
    }

    function setStakingFeeRate(uint _stakingFeeRate)public onlyOwner {
        stakingFeeRate = _stakingFeeRate;
    }

    function setUnstakingFeeRate(uint _unstakingFeeRate)public onlyOwner {
        unstakingFeeRate = _unstakingFeeRate;
    }

     function setCliffTime(uint _cliffTime) public onlyOwner{
        cliffTime = _cliffTime;
    }
    
    
    function deposit(uint amountToStake) public {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        
        updateAccount(msg.sender);
        
        uint fee = amountToStake.mul(stakingFeeRate).div(1e4);
        uint amountAfterFee = amountToStake.sub(fee);
        require(Token(tokenAddress).transfer(owner, fee), "Could not transfer deposit fee.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountAfterFee);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
        }
    }
    
    function withdraw(uint amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        require(now.sub(stakingTime[msg.sender]) > cliffTime, "You recently staked, please wait before withdrawing.");
        
        updateAccount(msg.sender);
        
        uint fee = amountToWithdraw.mul(unstakingFeeRate).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        
        require(Token(tokenAddress).transfer(owner, fee), "Could not transfer withdraw fee.");
        require(Token(tokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claimDivs() public {
        updateAccount(msg.sender);
    }
    
        
    // ------------------------------------------------------------------------
    // Collect Unsold Tokens Function
    // ------------------------------------------------------------------------
    function collectRewardTokens() public onlyOwner  {
        uint256 rewardTokensBalance;
        rewardTokensBalance = Token(rewardTokenAddress).balanceOf(address(this));
        Token(rewardTokenAddress).transfer(msg.sender, rewardTokensBalance);
    }
    
    
    // ------------------------------------------------------------------------
    // function to allow owner to claim *other* IBEP20 tokens sent to this contract (by mistake)
    // ------------------------------------------------------------------------
    function transferAnyIBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner{
         Token(_tokenAddr).transfer(_to, _amount);
    }
    

}