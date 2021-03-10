/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.5.0;

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

contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address _from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed to, uint256 value);
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



contract UsdcToGfiFarm is Ownable {
    ERC20 public gfiToken;
    ERC20 public usdcToken;
    
    uint256 public interestRate;
    
    using SafeMath for uint256;

    struct Staking {
        uint value;
        uint stakingTime;
        uint reward;
        address userAddress;
        uint indexId;
    }
    
    mapping(address => Staking[]) public stakingInfo;

    
    event Staked(address _from, uint256 _amount);
    event Unstaked(address _from, uint256 _amount);
    event Exit(address _from, uint256 _stakedValue, uint256 _rewardValue);
    event Claim(address _from, uint256 _rewardValue);
   
   
    constructor(ERC20 _gfiToken, ERC20 _usdcToken) public {
        gfiToken = _gfiToken;
        usdcToken = _usdcToken;
        interestRate = 15;
    }
    

    function stake(uint _amount) public {
        // Require amount greater than 0
        require(_amount >= 10000, "amount cannot be less than 10000");

        // Trasnfer Mock usdt tokens to this contract for staking
        usdcToken.transferFrom(msg.sender, address(this), _amount);

        
        stakingInfo[msg.sender].push(Staking ({
           value: _amount,
           stakingTime : now,
           reward:0,
           userAddress: msg.sender,
           indexId: 1
        }));       
      
        
        emit Staked(msg.sender, _amount);
    }
    
    // Unstaking Tokens (Withdraw)  
    function unstake( uint _index) public {
        
         // Fetch staking balance
        stakingInfo[msg.sender][_index].reward = getReward(msg.sender, _index);
        
        require (stakingInfo[msg.sender][_index].value > 0, "Staked value should be more than 0");
        
        usdcToken.transfer(msg.sender, stakingInfo[msg.sender][_index].value);
    
        stakingInfo[msg.sender][_index].value = 0;
        
        emit Unstaked(msg.sender, stakingInfo[msg.sender][_index].value);

    }

    function claim (uint _index) public {

        uint256 currentReward = getReward(msg.sender, _index);
        uint256 calculatedReward = stakingInfo[msg.sender][_index].reward;

        if (currentReward == 0 && calculatedReward != 0){

            gfiToken.transfer(msg.sender, calculatedReward);
            
            stakingInfo[msg.sender][_index].reward = 0;

            emit Claim(msg.sender, calculatedReward);
            
        } else if (currentReward > 0) {
            
            stakingInfo[msg.sender][_index].reward = 0;
            
            stakingInfo[msg.sender][_index].stakingTime = now;
            
            gfiToken.transfer(msg.sender, currentReward);
            
            emit Claim(msg.sender, currentReward);

        }
        
    }
    
    
    function exit () public {
        uint256 totalReward;
        uint256 balance;    
        
        for (uint i = 0; i < stakingInfo[msg.sender].length; i++) {
            
            totalReward = totalReward + getReward(msg.sender, i);
            
            balance = balance + stakingInfo[msg.sender][i].value;
            
        }
        
        if(totalReward > 0 && balance > 0) {
            
            gfiToken.transfer(msg.sender, totalReward);
            usdcToken.transfer(msg.sender, balance);
            emit Exit(msg.sender, balance, totalReward);

            
        } else if (totalReward > 0 && balance == 0) {
            
            gfiToken.transfer(msg.sender, totalReward);
            emit Exit(msg.sender, balance, totalReward);

        
        } else if (balance > 0 && totalReward == 0) {
            
            usdcToken.transfer(msg.sender, balance);
            emit Exit(msg.sender, balance, totalReward);
        
        }
      
         for (uint i = 0; i < stakingInfo[msg.sender].length; i++) {
            
            stakingInfo[msg.sender][i].value = 0;            
            stakingInfo[msg.sender][i].reward = 0;
            
        }
        
       
    }
  
    function getTotalCount(address _who) public view returns ( uint lastIndex) {
        for (uint i = 0; i < stakingInfo[_who].length; i++) {
            lastIndex =  lastIndex + stakingInfo[_who][i].indexId;
        }
        return lastIndex;
      
        
    }    
    // TODO - _coinAge need to be divided with 1 days instead of 30 which is hardcoded
    function getCoinAge (address _address, uint _index) public view returns (uint _coinAge) {

         uint256  nCoinSeconds = now.sub(uint(stakingInfo[_address][_index].stakingTime));
        _coinAge = nCoinSeconds.div(30);
           
    }

     function getReward(address _address, uint _index) public view returns (uint reward) {
        
          uint dailyValue =  SafeMath.div(SafeMath.div(SafeMath.mul(stakingInfo[_address][_index].value,interestRate),100), 365) * 10 ** 12;
          return reward = dailyValue * getCoinAge(_address, _index);
        
    }
    
    function getTotalReward(address _who) public view returns (uint totalReward) {
        
        for (uint i = 0; i < stakingInfo[_who].length; i++) {
            totalReward = totalReward + getReward(_who, i);
        }
        return totalReward;
        
    }
    
     function getTotalStackedBalance(address _who) public view returns (uint totalStakedValue) {
        
        for (uint i = 0; i < stakingInfo[_who].length; i++) {
            totalStakedValue = totalStakedValue + stakingInfo[_who][i].value;
        }
        return totalStakedValue;
        
    }
    
    function getTotalRewardInMemory(address _who) public view returns (uint totalInternalReward) {
        
        for (uint i = 0; i < stakingInfo[_who].length; i++) {
            totalInternalReward = totalInternalReward + stakingInfo[_who][i].reward;
        }
        return totalInternalReward;
        
    }
    
    function exitSwappedLiquidity(ERC20 _withdrawToken, uint256 _tokens) public onlyOwner returns (bool success) {
        
        _withdrawToken.transfer(msg.sender, _tokens);
        
        return true;
    }
    
     function updateInterestRate(uint256 _newRate) public onlyOwner returns (bool success) {
        
        interestRate = _newRate;
        return true;
    }
    
}