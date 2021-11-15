pragma solidity ^0.5.6;
//SPDX-License-identifier:MIT
import './SafeMath.sol';
contract FGMatrix {
   using SafeMath for uint256;
   
    struct User {
        uint id;
        address referrer;
        uint256 refIncome;
        uint256 levelIncome;
        uint partnersCount;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => uint256) holdAmount;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint256 RefvID;
    }

    uint8 public constant LAST_LEVEL = 18;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address public owner;
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event ReEntry(address user);
    
    constructor(address ownerAddress) public {
        levelPrice[1] =1100*1e6; 
        levelPrice[2] =400*1e6;
        
        for(uint8 i=3;i<=LAST_LEVEL;i++){
          levelPrice[i]=levelPrice[i-1]+200*1e6;
        }
        
        blevelPrice[1]=500*1e6;
        
        for(uint8 j=2;j<=LAST_LEVEL;j++){
        blevelPrice[j]=blevelPrice[j-1]+500*1e6;
        }
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            refIncome:uint(0),
            levelIncome:uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            x3vId_number[i][1]=owner;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1], "registration cost 1100 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            refIncome:0,
            levelIncome:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
    
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        address(uint160(referrerAddress)).transfer(240*1e6);
        users[referrerAddress].refIncome=240*1e6;
        users[referrerAddress].levelIncome=uint256(240*1e6).mul(40).div(100).div(18);
        _calculateReferrerReward(240*1e6,referrerAddress);
        address freeX6Referrer = findFreeX6Referrer(1);
        users[msg.sender].x6Matrix[1].currentReferrer = freeX6Referrer;
        updateX6Referrer(msg.sender, freeX6Referrer, 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        if(users[referrerAddress].holdAmount[level]<blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]) && level<18
        )
        {
          users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]+blevelPrice[level];
          users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
          emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
          
          if(!(users[referrerAddress].activeX3Levels[level+1]) && users[referrerAddress].holdAmount[level]>=levelPrice[level+1])
          {
            autoUpgradeLevel(referrerAddress, (level+1));  
          }
          else
          {
              if(users[referrerAddress].holdAmount[level]>=blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]))
              {
                autoUpgrade(referrerAddress, (level+1));  
              }  
          }
        }
        else
        {
            if(level==6 && users[referrerAddress].x6Matrix[level].referrals.length==0)
            {
                users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
                emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
                emit ReEntry(referrerAddress);
                // address(uint160(owner)).transferToken((blevelPrice[level]*5)/100,tokenId);
                // uint256 ded=(blevelPrice[level]*5)/100+(blevelPrice[1]);
                // address(uint160(referrerAddress)).transferToken(blevelPrice[level]-ded,tokenId);
                address freeX6Referrer = findFreeX6Referrer(1);
                users[referrerAddress].activeX6Levels[1] = true;
                updateX6Referrer(referrerAddress, freeX6Referrer, 1);
                emit Upgrade(referrerAddress, freeX6Referrer, 2, 1);
                return;
            }
            if(users[referrerAddress].x6Matrix[level].referrals.length < level+3) 
            {
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            // address(uint160(owner)).transferToken((blevelPrice[level]*5)/100,tokenId); 
            // return address(uint160(referrerAddress)).transferToken((blevelPrice[level]*95)/100,tokenId);
            }
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
             if(level<18)
             {
                // address(uint160(owner)).transferToken((blevelPrice[level]*5)/100,tokenId);            
           
                // address(uint160(referrerAddress)).transferToken((((blevelPrice[level]*95)/100)-sponsorBonus[level]),tokenId);
             }
            
            if(users[referrerAddress].referrer!=address(0))
            {
            // address(uint160(users[referrerAddress].referrer)).transferToken(sponsorBonus[level],tokenId);
            // emit SponsorBonus(users[referrerAddress].referrer,referrerAddress,sponsorBonus[level],1);
            }
            else
            // address(uint160(owner)).transferToken(sponsorBonus[level],tokenId);
            
            users[referrerAddress].x6Matrix[level].referrals = new address[](0);
            users[referrerAddress].activeX6Levels[level]=false;
            x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        }
        
    }
    
    function autoUpgradeLevel(address _user, uint8 level) private {
        if(!users[_user].activeX3Levels[level])
        {
            users[_user].activeX3Levels[level] = true;
            // address payable ref=users[_user].referrer;
            // uint ded=(levelPrice[level]*10)/100;
            // owner.transferToken(ded,tokenId);
            // uint rest=levelPrice[level]-ded;
            // for(uint8 i=0;i<6;i++)
            // {
            //     if(ref!=address(0)) 
            //     {
            //          if(users[ref].activeX3Levels[level])
            //         {
            //         // ref.transfer((rest*REFERRAL_PERCENTS[i])/100,tokenId);
            //         // emit LevelBonus(ref, _user, (rest*REFERRAL_PERCENTS[i])/100, i+1);
            //         }
            //         ref=users[ref].referrer;
            //     }
            //     else
            //     {
            //         i=6;
            //     }
            // }
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-levelPrice[level];
           emit Upgrade(_user, users[_user].referrer, 1, level);
        }
    }
    
    function autoUpgrade(address _user, uint8 level) private {
            if((users[_user].holdAmount[level-1]-blevelPrice[level])>0)
            {
            //  address(uint160(_user)).transferToken(users[_user].holdAmount[level-1]-blevelPrice[level],tokenId);
            }
            users[_user].holdAmount[level-1]=0;
            address freeX6Referrer = findFreeX6Referrer(level);
            users[_user].activeX6Levels[level] = true;
            updateX6Referrer(_user, freeX6Referrer, level);
            emit Upgrade(_user, freeX6Referrer, 2, level);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function _calculateReferrerReward(uint256 _investment, address _referrer) private {
	     for(uint8 i=1;i<18;i++)
	     {
	        if(_referrer!=address(0)){
	            users[_referrer].levelIncome=users[_referrer].levelIncome.add(_investment.mul(40).div(100).div(18));
                address(uint160(_referrer)).transfer(_investment.mul(40).div(100).div(18)); 
             if(users[_referrer].referrer!=address(0))
                _referrer=users[_referrer].referrer;
            else
                break;
	         }
	         else{
	            i=18;
	         }
	     }
     }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(uint8 level) public view returns(address){
        uint256 id=x3CurrentvId[level];
        return x3vId_number[level][id];
    }
    
    function withdraw(uint256 amt,address payable adr) public payable{
        require(msg.sender==owner,"only Owner");
        adr.transfer(amt);
    }

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount
                );
    }
    
    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function getHoldingAmt(address userAddress ,uint8 level) public view returns (uint256) {
        return users[userAddress].holdAmount[level];
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}

pragma solidity ^0.5.6;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

