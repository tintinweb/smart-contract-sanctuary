/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: none

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
}

contract UKESstaking is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint amount);
    event withdrawalEthBonus(address reward_addr,address to_addr, uint amount);
    
    // my code
    address[] public investors_address_list;
    uint public totalInvested = 0;
    uint public totalRewardAmt = 0;
    // my code
    
   
    address public constant tokenAddress = 0x2E5De8f876AfEfCa5f2FC52485aB246dC6b8c656;
    
   
    uint public constant rewardRate = 3650;             // 3650 รท 100 = 36.5 %
    uint public constant rewardInterval = 365 days;      // APY (Annual Percentage Yield)

    
    uint public constant unstakingFeeRate = 100;        // 100 รท 100 =  1 %
    
   
    uint public constant cliffTime = 24 hours;
    
    uint public totalClaimedRewards = 0;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    
    // my code
    mapping (address => uint) public ethRewardTotal;
    mapping (address => uint) public ethRewardBalance;
    mapping (address => uint) public ethRewardWithdrawn;
    // my code
    
    
    function updateAccount(address account) private {
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
           require(Token(tokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
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
    
    // my code
    function isInvestorExist(address value) public view  returns(uint) {
        uint i = 0;
        
        for(uint k=0;k<investors_address_list.length;k++){
            if(investors_address_list[k] == value){
                i++;
            }
        }
        return i;
    }
    
    function deposit(uint amountToStake) public {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        
        updateAccount(msg.sender);
        
     
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToStake);
        
        // my code
        uint checkInvestor = isInvestorExist(msg.sender);
        if(checkInvestor == 0){
            investors_address_list.push(msg.sender);
        }
        totalInvested = totalInvested.add(amountToStake);
        // my code
        
        
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
        
        // my code
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        totalInvested = totalInvested.sub(amountToWithdraw);
        // my code
        
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claimDivs() public {
        updateAccount(msg.sender);
    }
     // my code
    receive()  external onlyOwner payable   {
        
         totalRewardAmt = totalRewardAmt.add(msg.value);
    }
   
    
  
    
    function distributeReward() public onlyOwner{
        require(totalRewardAmt>0,"Reward Wallet Empty");
        require(totalInvested>0,"No Investment Found");
        bool distribureCheck = false;
        for(uint i = 0; i < investors_address_list.length; i++ ){
            address userAddr = investors_address_list[i];
            uint investedAmt = depositedTokens[userAddr];
            if(investedAmt > 0){
                uint getPercent = investedAmt.mul(100).div(totalInvested);
                uint getBonusAmt = totalRewardAmt.mul(getPercent).div(100);
                ethRewardTotal[userAddr] = ethRewardTotal[userAddr].add(getBonusAmt);
                ethRewardBalance[userAddr] = ethRewardBalance[userAddr].add(getBonusAmt);
                distribureCheck = true;
            }
        }
        if(distribureCheck){
            totalRewardAmt = 0;
        }
    }
    
  
    function withdrawalBonus(address payable addr) public {
        uint bonusAmt = ethRewardBalance[msg.sender];
        require(bonusAmt>0,"No Reward Found");
        addr.transfer(bonusAmt);
        ethRewardBalance[msg.sender] = ethRewardTotal[msg.sender].sub(bonusAmt);
        ethRewardWithdrawn[msg.sender] = ethRewardWithdrawn[msg.sender].add(bonusAmt);
        emit withdrawalEthBonus(msg.sender,addr,bonusAmt);
    }
    
    
    function userReward(address userAddr) public view returns (uint totalBnsAmt,uint totalBnsBal,uint totalBnsWithdrawn) {
        totalBnsAmt  = ethRewardTotal[userAddr];
        totalBnsBal  = ethRewardBalance[userAddr];
        totalBnsWithdrawn = ethRewardWithdrawn[userAddr];
    }
    // my code
    
    uint private constant stakingAndDaoTokens = 10000e18;     
                                                           
    
    function getStakingAndDaoAmount() public view returns (uint) {
        if (totalClaimedRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint remaining = stakingAndDaoTokens.sub(totalClaimedRewards);
        return remaining;
    }
    
   
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        if (_tokenAddr == tokenAddress) {
            if (_amount > getStakingAndDaoAmount()) {
                revert();
            }
            totalClaimedRewards = totalClaimedRewards.add(_amount);
        }
        Token(_tokenAddr).transfer(_to, _amount);
    }
}