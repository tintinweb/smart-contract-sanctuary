//SourceUnit: tronplus.sol

pragma solidity ^0.5.9;
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



contract TronPlus is Ownable {
    
    using SafeMath for uint256;
    
    struct User {
        
        uint id;
        uint currentLevel;
        address myReferrar;
        
        mapping(uint8 => level) levelData;
        mapping(address => Staking[])  stakingInfo;
    }
    
    struct Staking {
        uint value;
        uint valueToWithdraw;
        address userAddress;
        uint indexId;
        uint stakingTime;
    }
    
    struct level {
        address[] referrals;
        uint reward; 
    }
  
    uint lastUserId = 0;
    address payable admin;    

    mapping(address => User) public users;
    mapping(address => bool) public hasStaked;
    mapping(uint => address) public idToAddress;


    event Register(address _user, uint256 _amount, address _referrar, uint256 _userId, uint256 _levelId);
    event Withdraw(address _user, uint256 _fee, uint256 _rewardValue);
    event Upgraded(address _user, uint256 _amount, address _referrar, uint256 _userId, uint256 _levelId);
    event Reinvest(address _user, uint256 _amount, address _referrar, uint256 _userId, uint256 _levelId, uint256 _fee);
    event Referrars(address _user, address _referrar, address _ref1, address _ref2, address _ref3);
   
   
    constructor() public {
        hasStaked[msg.sender] = true;
        admin = msg.sender;
        
        lastUserId++;
    
            users[msg.sender].id = lastUserId;
            idToAddress[lastUserId] = msg.sender;
            users[msg.sender].myReferrar = msg.sender;
            
            purchaseMechanism(100000 trx, msg.sender, msg.sender);
            
            users[msg.sender].stakingInfo[msg.sender].push(Staking ({
              value: 100000 trx,
              valueToWithdraw: 100000 trx,
              stakingTime : now,
              userAddress: msg.sender,
              indexId: 1
            }));       
            
            
            emit Register(msg.sender, 100000 trx, msg.sender, lastUserId, users[msg.sender].currentLevel);   
        }

    function register( address referrar) public payable {
        uint _amount = msg.value;
        // Require amount greater than 0
        require(_amount >= 500 trx, "amount cannot be less than 500 trx");
        require(hasStaked[referrar],'Invalid referrar');
        
        if(hasStaked[msg.sender] == false) {
            lastUserId++;
    
            users[msg.sender].id = lastUserId;
            idToAddress[lastUserId] = msg.sender;
            users[msg.sender].myReferrar = referrar;
            
            purchaseMechanism(_amount, referrar, msg.sender);
            
            users[msg.sender].stakingInfo[msg.sender].push(Staking ({
              value: _amount,
              valueToWithdraw: _amount,
              stakingTime : now,
              userAddress: msg.sender,
              indexId: 1
            }));       
            
            
            emit Register(msg.sender, _amount, referrar, lastUserId, users[msg.sender].currentLevel);
        } else {
            revert("User already registered");
        }
    }
    
    function purchaseMechanism(uint amountOfTrx, address referrar, address userAddress) internal {
        
        uint256 localAmountTrx;
        
        for(uint8 i = 0; i< users[userAddress].stakingInfo[userAddress].length; i++) {
          localAmountTrx +=  users[userAddress].stakingInfo[userAddress][i].value;
        }
        
        localAmountTrx += amountOfTrx;
        
        if(localAmountTrx >= 50 trx && localAmountTrx < 500 trx) {
          if(!hasStaked[userAddress]) {
             users[referrar].levelData[1].referrals.push(userAddress);   
            }
            users[userAddress].currentLevel = 1;
            
            setReferrars(referrar,amountOfTrx,1);

            
        }  else if(localAmountTrx >= 500 trx && localAmountTrx < 1000 trx) {
            if(!hasStaked[userAddress]) {
             users[referrar].levelData[2].referrals.push(userAddress);   
            }

            users[userAddress].currentLevel = 2;
            
            setReferrars(referrar,amountOfTrx,2);

        } else if(localAmountTrx >= 1000 trx && localAmountTrx < 1500 trx) {
            if(!hasStaked[userAddress]) {
             users[referrar].levelData[3].referrals.push(userAddress);   
            }

            users[userAddress].currentLevel = 3;
            
            setReferrars(referrar,amountOfTrx,3);

        } else if(localAmountTrx >= 1500 trx) {
            if(!hasStaked[userAddress]) {
             users[userAddress].levelData[4].referrals.push(referrar);   
            }

            users[userAddress].currentLevel = 4;
            setReferrars(referrar,amountOfTrx,4);
           
        }
        
        hasStaked[userAddress] = true;

    }
    
    function reinvestMechanism(uint amountOfTrx, address referrar, address userAddress) internal {
        
    
        if(amountOfTrx >= 50 trx && amountOfTrx < 500 trx) {
          if(!hasStaked[userAddress]) {
             users[referrar].levelData[1].referrals.push(userAddress);   
            }
            users[userAddress].currentLevel = 1;
            
            setReferrars(referrar,amountOfTrx,1);

            
        }  else if(amountOfTrx >= 500 trx && amountOfTrx < 1000 trx) {
            if(!hasStaked[userAddress]) {
             users[referrar].levelData[2].referrals.push(userAddress);   
            }

            users[userAddress].currentLevel = 2;
            
            setReferrars(referrar,amountOfTrx,2);

        } else if(amountOfTrx >= 1000 trx && amountOfTrx < 1500 trx) {
            if(!hasStaked[userAddress]) {
             users[referrar].levelData[3].referrals.push(userAddress);   
            }

            users[userAddress].currentLevel = 3;
            
            setReferrars(referrar,amountOfTrx,3);

        } else if(amountOfTrx >= 1500 trx) {
            if(!hasStaked[userAddress]) {
             users[userAddress].levelData[4].referrals.push(referrar);   
            }

            users[userAddress].currentLevel = 4;
            setReferrars(referrar,amountOfTrx,4);
           
        }
        
        hasStaked[userAddress] = true;

    }
    
    function calculatePercentage(uint256 amountOfTrx, uint256 percentage) public pure returns(uint256){
        return (percentage * amountOfTrx) / 100;
    }
    
    function withdrawTrx() public {
        require(hasStaked[msg.sender],'Invalid caller');

        uint256 myReward = getTotalReward(msg.sender);

        for(uint8 i = 1; i<= 4; i++) {
        //   myReward +=  users[msg.sender].levelData[i].reward;
          users[msg.sender].levelData[i].reward = 0;
        }
        
        // myReward += getTotalReward(msg.sender);

        for(uint8 i = 0; i < users[msg.sender].stakingInfo[msg.sender].length ; i++) {
          users[msg.sender].stakingInfo[msg.sender][i].valueToWithdraw = 0;
        }
        
        uint256 feeDeduction = calculatePercentage(myReward,15);
        uint256 trxToSend = myReward - feeDeduction;
       
        msg.sender.transfer(trxToSend);
        admin.transfer(feeDeduction);
        
        emit Withdraw(msg.sender, feeDeduction, trxToSend);
        
    }
    
    function reinvest() public {
        require(hasStaked[msg.sender],'Invalid caller');

        uint256 myReward = getTotalReward(msg.sender);

        for(uint8 i = 1; i<= 5; i++) {
          users[msg.sender].levelData[i].reward = 0;
        }
    
        // myReward += getTotalReward(msg.sender);
        
     
        for(uint8 i = 0; i < users[msg.sender].stakingInfo[msg.sender].length ; i++) {
          users[msg.sender].stakingInfo[msg.sender][i].valueToWithdraw = 0;

        }
        
        uint256 feeDeduction = calculatePercentage(myReward,15);
        uint256 trxToInvest = myReward - feeDeduction;
        
        require(trxToInvest >= 50 trx, "Reward should be more than 50 trx to reinvest");

        reinvestMechanism(trxToInvest, users[msg.sender].myReferrar, msg.sender);
         
        users[msg.sender].stakingInfo[msg.sender].push(Staking ({
          value: trxToInvest,
          valueToWithdraw: trxToInvest,
          stakingTime : now,
          userAddress: msg.sender,
          indexId: 1
        }));  
        
        admin.transfer(feeDeduction);
        
        emit Reinvest(msg.sender, trxToInvest, users[msg.sender].myReferrar, users[msg.sender].id, users[msg.sender].currentLevel, feeDeduction);


    }
    
    function levelUpgrade() public payable {
        uint256 amount = msg.value;

        require(hasStaked[msg.sender],'Invalid caller');
        

        for(uint8 i = 0; i < users[msg.sender].stakingInfo[msg.sender].length ; i++) {
          users[msg.sender].stakingInfo[msg.sender][i].valueToWithdraw = 0;
        }
        
        purchaseMechanism(amount, users[msg.sender].myReferrar, msg.sender);
        
         users[msg.sender].stakingInfo[msg.sender].push(Staking ({
          value: amount,
          valueToWithdraw: amount,
          stakingTime : now,
          userAddress: msg.sender,
          indexId: 1
        })); 
        
        emit Upgraded(msg.sender, amount, users[msg.sender].myReferrar, users[msg.sender].id, users[msg.sender].currentLevel);
        
    }
    
    function setReferrars(address referrar , uint256 amountOfTrx, uint8 _level) internal {
        address ref1 = users[referrar].myReferrar;
        address ref2 = users[ref1].myReferrar;
        address ref3 = users[ref2].myReferrar;
        
        if(lastUserId == 1)
            users[referrar].levelData[_level].reward += calculatePercentage(amountOfTrx, 25);
        else if (lastUserId == 2) {
            
            users[referrar].levelData[_level].reward += calculatePercentage(amountOfTrx, 10);
            users[ref1].levelData[_level].reward += calculatePercentage(amountOfTrx, 15);
        } else if (lastUserId == 3) {
            
            users[referrar].levelData[_level].reward += calculatePercentage(amountOfTrx, 10);
            users[ref1].levelData[_level].reward += calculatePercentage(amountOfTrx, 2);
            users[ref2].levelData[_level].reward += calculatePercentage(amountOfTrx, 13);

        } else {
            users[referrar].levelData[_level].reward += calculatePercentage(amountOfTrx, 10);
            users[ref1].levelData[_level].reward += calculatePercentage(amountOfTrx, 2);
            users[ref2].levelData[_level].reward += calculatePercentage(amountOfTrx, 3);
            users[ref3].levelData[_level].reward += calculatePercentage(amountOfTrx, 10);
        }
        emit Referrars(msg.sender, referrar, ref1, ref2, ref3);
        
    }
  
    
    // GETTERS
    function getTotalCount(address _who) public view returns ( uint lastIndex) {
        for (uint i = 0; i < users[_who].stakingInfo[_who].length; i++) {
            lastIndex =  lastIndex + users[_who].stakingInfo[_who][i].indexId;
        }
        return lastIndex;
      
        
    }   
   
    function getUserReferrals(address _who, uint8 _level) public view returns ( address[] memory) {
        return  users[_who].levelData[_level].referrals;
    }   
    
    function getCoinAge(address _address, uint _index) public view returns (uint _coinAge) {

         uint256  nCoinSeconds = now.sub(uint(users[_address].stakingInfo[_address][_index].stakingTime));
        _coinAge = nCoinSeconds.div(1);
    }

    function getReward(address _address, uint _index) public view returns (uint reward) {
         uint dailyValue;
         
         for(uint8 i = 1; i<= 4; i++) {
            reward +=  users[msg.sender].levelData[i].reward;
          }
            
        if( getCoinAge(_address, _index) <= 2592000) {
            
            if(users[_address].stakingInfo[_address][_index].valueToWithdraw != 0){
                dailyValue =  SafeMath.div(SafeMath.div(SafeMath.mul(users[_address].stakingInfo[_address][_index].valueToWithdraw,150),100), 2592000);
                return reward += (dailyValue * getCoinAge(_address, _index));
            } else {
                dailyValue =  SafeMath.div(SafeMath.div(SafeMath.mul(users[_address].stakingInfo[_address][_index].value,150),100), 2592000);
                return reward += (dailyValue * getCoinAge(_address, _index));
            }
        } else {
            dailyValue =  SafeMath.div(SafeMath.div(SafeMath.mul(users[_address].stakingInfo[_address][_index].valueToWithdraw,150),100), 2592000);
            return reward+= (dailyValue *  2592000);
        }
        
    }
    
     function getReferralReward(address _address) public view returns (uint reward) {

         for(uint8 i = 1; i<= 4; i++) {
            reward +=  users[_address].levelData[i].reward;
          }
        return reward;
       
        
    }
    function getTotalReward(address _who) public view returns (uint totalReward) {
        
        for (uint i = 0; i < users[_who].stakingInfo[_who].length; i++) {
            totalReward = totalReward + getReward(_who, i);
        }
        return totalReward;
        
    }
    
    function getTotalStackedBalance(address _who) public view returns (uint totalStakedValue) {
        
        for (uint i = 0; i < users[_who].stakingInfo[_who].length; i++) {
            totalStakedValue = totalStakedValue + users[_who].stakingInfo[_who][i].value;
        }
        return totalStakedValue;
        
    }

}