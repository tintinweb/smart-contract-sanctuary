/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity 0.6.12;

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
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
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
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
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

contract TKOStaking is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint amount);
    
    // TKO token contract address
    address public constant tokenAddress = 0xcA1024B60b00bbd8b5c278F3BBD65B40AAB4e837;
    // Fee collect address
    address public constant feeAddress = 0x59BA4C88129D6178657fC039D6f70a8873628826;
    // Fee collect address
    address public constant TKOFoundationWallet = 0x08f3ec531A6817960D5a641bd215459D4EcdDC06;
    
    uint public totalClaimedRewards = 0;
    // reward rate 150% per day
    uint public  rewardRate = 15000;
    uint public constant rewardInterval = 1 days;
    // Staking total time
    uint public stakingTotalTime;
    // transaction fee 0.02 percent
    uint public stakingFeeRate = 2;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    
    constructor(address owner) public {
    stakingTotalTime = now + 180 days;
    transferOwnership(owner);
    }
    
    function stakingPoolStop() public onlyOwner{
        require(now >= stakingTotalTime,"Pool is not over yet!");
            uint256 balance = Token(tokenAddress).balanceOf(address(this));
            require(Token(tokenAddress).transfer(TKOFoundationWallet, balance), "Could not transfer tokens.");
    }
    
    function updateRewardRate(uint _newRewardRate) public onlyOwner{
        rewardRate = _newRewardRate; 
    }
      function updateFeeRate(uint _newFeeRate) public onlyOwner{
        stakingFeeRate = _newFeeRate; 
    }
  
   function updateStakingTime(uint _timeInDays) public onlyOwner{
        stakingTotalTime = now + _timeInDays.mul(86400); 
    }
    
    function updateAccount(address account) private {
        uint pendingRewards = getPendingReward(account);
        if (pendingRewards > 0) {
            require(Token(tokenAddress).transfer(account, pendingRewards), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingRewards);
            totalClaimedRewards = totalClaimedRewards.add(pendingRewards);
            emit RewardsTransferred(account, pendingRewards);
        }
        lastClaimedTime[account] = now;
    }
    
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
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }
    
    function stake(uint amountToStake) public {
        require(now < stakingTotalTime,"Staking pool time is ended");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        
        updateAccount(msg.sender);
        
        uint fee = amountToStake.mul(stakingFeeRate).div(1e4);
        uint amountAfterFee = amountToStake.sub(fee);
        require(Token(tokenAddress).transfer(feeAddress, fee), "Could not transfer deposit fee.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountAfterFee);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
        }
    }
    
    function unstake(uint amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        uint fee = amountToWithdraw.mul(stakingFeeRate).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        require(Token(tokenAddress).transfer(feeAddress, fee), "Could not transfer deposit fee.");
        
        updateAccount(msg.sender);
        
        require(Token(tokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claimReward() public {
        updateAccount(msg.sender);
    }
    
}