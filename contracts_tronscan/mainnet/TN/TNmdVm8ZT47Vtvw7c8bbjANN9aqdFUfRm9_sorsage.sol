//SourceUnit: singleLeg.sol

pragma solidity ^0.5.9;
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

contract sorsage {
using SafeMath for uint256;
    struct User {
        uint id;
        address payable referrer;
        uint partnersCount;
        bool isReccommended;
        
        mapping(uint256 => bool) legActiveLevels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X3) x3Matrix;
    }
    struct X3 {
        address currentReferrer;
        mapping(uint8=>address [])levelFollowers;
        // address[] firstLevelFollowers;
        // address[] secondLevelFollowers;
        // address[] thirdLevelFollowers;
        // address[] fourthLevelFollowers;
        // address[] fifthLevelFollowers;
        // address[] sixthLevelFollowers;
        // address[] seventLevelFollowers;
        // address[] eighthLevelFollowers;
        // address[] ninthLevelFollowers;
        // address[] tenthLevelFollowers;
        // address[] eleventhLevelFollowers;
        // address[] twelthLevelFollowers;
        
    }
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }
    
   
    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => User) public users;
    mapping(uint => address payable) public idToAddress;
    mapping(uint256 => address) public userIds;
    mapping(address => uint) public balances; 
    mapping(uint256=> uint256)public idLevel1;
    mapping(uint256=> uint256)public idLevel2;
    mapping(uint256=> uint256)public idLevel3;
    mapping(uint256=> uint256)public idLevel4;    
    mapping(uint256=> uint256)public idLevel5;
    mapping(uint256=> uint256)public idLevel6;
    mapping(uint256=> uint256)public idLevel7;
    mapping(uint256=> uint256)public idLevel8;
    mapping(uint256=> uint256)public idLevel9;
    mapping(uint256=> uint256)public idLevel10;
    mapping(uint256=> uint256)public idLevel11;
    mapping(uint256=> uint256)public idLevel12;

   uint256 mapIdL1=1;
   uint256 mapIdL2=1;
   uint256 mapIdL3=1;
   uint256 mapIdL4=1;
   uint256 mapIdL5=1;
   uint256 mapIdL6=1;
   uint256 mapIdL7=1;
   uint256 mapIdL8=1;
   uint256 mapIdL9=1;
   uint256 mapIdL10=1;
   uint256 mapIdL11=1;
   uint256 mapIdL12=1;
    uint public lastUserId ;
    address payable public owner;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public levelPriceLeg;
    mapping(uint256 => uint) public legPercentage;
    mapping(uint256=>uint256)public investedX3;
    mapping(uint256=>uint256)public investedX4;
        
    uint256 legFlagLevel1;
    uint256 legIdLevel1;
    uint256 legFlagLevel2;
    uint256 legIdLevel2;
    uint256 legFlagLevel3;
    uint256 legIdLevel3;
    uint256 legFlagLevel4;
    uint256 legIdLevel4;
    uint256 legFlagLevel5;
    uint256 legIdLevel5;
    uint256 legFlagLevel6;
    uint256 legIdLevel6;
    uint256 legFlagLevel7;
    uint256 legIdLevel7;
    uint256 legFlagLevel8;
    uint256 legIdLevel8;
    uint256 legFlagLevel9;
    uint256 legIdLevel9;
    uint256 legFlagLevel10;
    uint256 legIdLevel10;
    uint256 legFlagLevel11;
    uint256 legIdLevel11;
    uint256 legIdLevel12;
    uint256 legFlagLevel12;
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user,uint indexed userId, address indexed referrer,uint referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedTronReceive(address indexed receiver,uint receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level);
    event SentDividends(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 matrix, uint8 level, bool isExtra);
    
    constructor(address payable ownerAddress) public {
        lastUserId++;
        levelPrice[1] = 250 trx;
        levelPrice[2]=1000 trx;
        for (uint8 i = 3; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        levelPriceLeg[1] = (levelPrice[1].mul(20).div(100));
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPriceLeg[i] = (levelPrice[i].mul(20).div(100));
        }
        legIdLevel1++;
        legIdLevel2++;
        legIdLevel3++;
        legIdLevel4++;
        legIdLevel5++;
        legIdLevel6++;
        legIdLevel7++;
        legIdLevel8++;
        legIdLevel9++;
        legIdLevel10++;
        legIdLevel11++;
        legIdLevel12++;
    idLevel1[legIdLevel1]=1;
    idLevel2[legIdLevel2]=1;
    idLevel3[legIdLevel3]=1;
    idLevel4[legIdLevel4]=1;
    idLevel5[legIdLevel5]=1;
    idLevel6[legIdLevel6]=1;
    idLevel7[legIdLevel7]=1;
    idLevel8[legIdLevel8]=1;
    idLevel9[legIdLevel9]=1;
    idLevel10[legIdLevel10]=1;
    idLevel11[legIdLevel11]=1;
    idLevel12[legIdLevel12]=1;
    
        legPercentage[1]=50;
        legPercentage[2]=20;
        legPercentage[3]=10;
        legPercentage[4]=10;
        legPercentage[5]=10;
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            isReccommended:false
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX6Levels[i] = true;
        }
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].legActiveLevels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    
    function() external payable {
        
        
        
        // registration(payable msg.sender ,payable bytesToAddress(msg.data));
    }

    function registrationExt(address payable referrerAddress) external payable {
        address payable a=referrerAddress;
        if(msg.data.length == 0) {
            a=owner;
        }
        else{
        registration(msg.sender, a);
        }
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            
            require(!users[msg.sender].legActiveLevels[level], "level already activated");
            require(users[msg.sender].legActiveLevels[level - 1], "previous level should be activated");
             if(level==2){
                 legLevel2();
             }
             else if(level==3){
                 legLevel3();
             }
             else if(level==4){
                 legLevel4();
             }
             else if(level==5){
                 legLevel5();
             }
             else if(level==6){
                 legLevel6();
             }
             else if(level==7){
                 legLevel7();
             }else if(level==8){
                 legLevel8();
             }else if(level==9){
                 legLevel9();
             }
             else if(level==10){
                 legLevel10();
             }
             else if(level==11){
                 legLevel11();
             }
             else if(level==12){
                 legLevel12();
             }
        } 
        else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 
            require(users[msg.sender].activeX6Levels[level - 1], "previous level should be activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
               uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,level);
            }
     
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    
    function registration(address payable userAddress, address payable referrerAddress) internal {
        require(msg.value == 500 trx, "registration cost 500");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        lastUserId++;
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            isReccommended:true
        });
        
        // invested[lastUserId]=msg.value;
        users[userAddress] = user;
        
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeX6Levels[1] = true;
        userIds[lastUserId] = userAddress;
        users[userAddress].legActiveLevels[1]=true;
        users[referrerAddress].partnersCount++;
        mapIdL1++;
        idLevel1[mapIdL1]=lastUserId;
            idToAddress[idLevel1[legIdLevel1]].transfer((levelPrice[1].mul(80).div(100)) );
            users[userAddress].x3Matrix[1].currentReferrer=referrerAddress;
        users[idToAddress[idLevel1[legIdLevel1]]].x3Matrix[1].levelFollowers[1].push(userAddress);
        legFlagLevel1++;
        if(legFlagLevel1==3){
            legIdLevel1++;
                legFlagLevel1=0;
            }
            uint256 depth=1;
            if(users[idToAddress[lastUserId]].isReccommended){
            distribution(lastUserId,depth,1);
            }
                 
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
          uint256 depth1=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth1,1);
            }
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function distribution(uint256 _id,uint256 _depth,uint8 _level)internal {
	    if(_depth==6){
	        return;
	    }
	    if(users[idToAddress[_id]].isReccommended){
	            users[idToAddress[_id]].referrer.transfer((levelPriceLeg[_level].mul(legPercentage[_depth]).div(100)));
	            _depth++;
	            distribution(users[users[idToAddress[_id]].referrer].id,_depth,_level);
	    }
	    else{
	     idToAddress[_id].transfer((levelPriceLeg[_level].mul(legPercentage[_depth]).div(100)));
	     _depth++;
	     distribution(_id,_depth,_level);
	    }
	    }
    function legLevel2()internal {
users[msg.sender].legActiveLevels[2]=true;
mapIdL2++;
idLevel2[mapIdL2]=users[msg.sender].id;
idToAddress[idLevel2[legIdLevel2]].transfer((levelPrice[2].mul(80).div(100)));
users[idToAddress[idLevel2[legIdLevel2]]].x3Matrix[2].levelFollowers[2].push(msg.sender);
          legFlagLevel2++;
              
            
        if(legFlagLevel2==3){
            legIdLevel2++;
                legFlagLevel2=0;
            }
            uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,2);
            }
    
    }
    function legLevel3()internal {
        users[msg.sender].legActiveLevels[3]=true;
        mapIdL3++;
        idLevel3[mapIdL3]=users[msg.sender].id;
        idToAddress[idLevel3[legIdLevel3]].transfer((levelPrice[3].mul(80).div(100)));
        users[idToAddress[idLevel3[legIdLevel3]]].x3Matrix[3].levelFollowers[3].push(msg.sender);
          legFlagLevel3++;
        if(legFlagLevel3==3){
                legIdLevel3++;
                legFlagLevel3=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,3);
            }
    }
    function legLevel4()internal {
        users[msg.sender].legActiveLevels[4]=true;
    mapIdL4++;
    idLevel4[mapIdL4]=users[msg.sender].id;
    idToAddress[idLevel4[legIdLevel4]].transfer((levelPrice[4].mul(80).div(100)));
    users[idToAddress[idLevel4[legIdLevel4]]].x3Matrix[4].levelFollowers[4].push(msg.sender);
          legFlagLevel4++;
        if(legFlagLevel4==3){
            legIdLevel4++;
                legFlagLevel4=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,4);
            }
    }

    
    function legLevel5()internal {
        users[msg.sender].legActiveLevels[5]=true;
        mapIdL5++;
        idLevel5[mapIdL5]=users[msg.sender].id;
        idToAddress[idLevel5[legIdLevel5]].transfer((levelPrice[5].mul(80).div(100)) );
        users[idToAddress[idLevel5[legIdLevel5]]].x3Matrix[5].levelFollowers[5].push(msg.sender);
          legFlagLevel5++;
        if(legFlagLevel5==3){
                legIdLevel5++;
                legFlagLevel5=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,5);
            }
    }

    function legLevel6()internal {
        users[msg.sender].legActiveLevels[6]=true;
        mapIdL6++;
        idLevel6[mapIdL6]=users[msg.sender].id;
        idToAddress[idLevel6[legIdLevel6]].transfer((levelPrice[6].mul(80).div(100)) );
        users[idToAddress[idLevel6[legIdLevel6]]].x3Matrix[6].levelFollowers[6].push(msg.sender);
          legFlagLevel6++;
        if(legFlagLevel6==3){
                legIdLevel6++;
                legFlagLevel6=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,6);
            }
    }

    function legLevel7()internal {
        users[msg.sender].legActiveLevels[7]=true;
        mapIdL7++;
        idLevel7[mapIdL7]=users[msg.sender].id;
        idToAddress[idLevel7[legIdLevel7]].transfer((levelPrice[7].mul(80).div(100)));
        users[idToAddress[idLevel7[legIdLevel7]]].x3Matrix[7].levelFollowers[7].push(msg.sender);
          legFlagLevel7++;
        if(legFlagLevel7==3){
            legIdLevel7++;
                legFlagLevel7=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,7);
            }
    }

    
    function legLevel8()internal {
        users[msg.sender].legActiveLevels[8]=true;
        mapIdL8++;
        idLevel8[mapIdL8]=users[msg.sender].id;
        idToAddress[idLevel8[legIdLevel8]].transfer((levelPrice[8].mul(80).div(100)));
        users[idToAddress[idLevel8[legIdLevel8]]].x3Matrix[8].levelFollowers[8].push(msg.sender);
          legFlagLevel8++;
        if(legFlagLevel8==3){
                legIdLevel8++;
                legFlagLevel8=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,8);
            }
    }
    
    function legLevel9()internal {
        users[msg.sender].legActiveLevels[9]=true;
        mapIdL9++;
        idLevel9[mapIdL9]=users[msg.sender].id;
        idToAddress[idLevel9[legIdLevel9]].transfer((levelPrice[9].mul(80).div(100)));
        users[idToAddress[idLevel9[legIdLevel9]]].x3Matrix[9].levelFollowers[9].push(msg.sender);
          legFlagLevel1++;
        if(legFlagLevel9==3){
            legIdLevel9++;
                legFlagLevel9=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,9);
            }
    }
    
    function legLevel10()internal {
        users[msg.sender].legActiveLevels[10]=true;
        mapIdL10++;
        idLevel10[mapIdL10]=users[msg.sender].id;
        idToAddress[idLevel10[legIdLevel10]].transfer((levelPrice[10].mul(80).div(100)));
        users[idToAddress[idLevel10[legIdLevel10]]].x3Matrix[10].levelFollowers[10].push(msg.sender);
          legFlagLevel10++;
        if(legFlagLevel10==3){
                 legIdLevel10++;
                legFlagLevel10=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,10);
            }
    }
    
    function legLevel11()internal {
        users[msg.sender].legActiveLevels[11]=true;
        mapIdL11++;
        idLevel11[mapIdL11]=users[msg.sender].id;
        idToAddress[idLevel11[legIdLevel11]].transfer((levelPrice[11].mul(80).div(100)));
        users[idToAddress[idLevel11[legIdLevel11]]].x3Matrix[11].levelFollowers[11].push(msg.sender);
          legFlagLevel11++;
        if(legFlagLevel11==3){
                legIdLevel11++;
                legFlagLevel11=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,11);
            }
    }
    
    function legLevel12()internal {
        users[msg.sender].legActiveLevels[12]=true;
        mapIdL12++;
        idLevel12[mapIdL12]=users[msg.sender].id;
        idToAddress[idLevel12[legIdLevel12]].transfer((levelPrice[12].mul(80).div(100)));
        users[idToAddress[idLevel12[legIdLevel12]]].x3Matrix[12].levelFollowers[12].push(msg.sender);
          legFlagLevel12++;
        if(legFlagLevel12==3){
            legIdLevel12++;
                legFlagLevel12=0;
            }
        uint256 depth=1;
            if(users[msg.sender].isReccommended){
            distribution(users[msg.sender].id,depth,12);
            }
    }
    

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id,ref,users[ref].id, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
            
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
              
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].id, 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].id, 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTronDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTronDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }
    function getX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount,
                users[userAddress].x6Matrix[level].closedPart);
    }
    function getX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].levelFollowers[level]
                
                );
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTronReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {

        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedTronReceive(receiver,users[receiver].id, _from,users[_from].id, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendTronDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTronReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send((levelPrice[level].mul(80)).div(100)) ) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
        emit SentDividends(_from,users[_from].id, receiver,users[receiver].id, matrix, level, isExtraDividends);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}