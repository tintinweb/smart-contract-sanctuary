//SourceUnit: newTronstormComplete.sol

pragma solidity ^0.4.25;

contract TronStormProV3 {
      
    struct UserStruct {
        uint pk;
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
       uint refIncome;
       uint poolRefIncome;
       uint xpoolRefIncome;
       uint creationDate;       
    }
    
    struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
       uint cycle;
       uint oddEvenFlag;
    }

    struct XPoolUser {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X6) x6Matrix;
    }

    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    
    address public ownerWallet;
    address dbOwner;

    uint public lastXPoolId =0;
    address public xPoolOwner;
    uint public LAST_POOL = 19;
    mapping (uint => bool) public pauseXFlag;
    mapping (address => XPoolUser) public xPUsers;
    mapping (uint => address) public xPUserIdByAddress;
    
    address crtr;
    
    uint public currUserID = 0;
    bool public regPausedFlag;
    uint public REGESTRATION_FEES=500 trx;
    mapping(uint => uint) public LEVEL_PRICE;
    uint public unlimited_level_price_reg=0;
    uint public reg_champ_amt = 0;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint => address) public userListSeq;
    mapping (uint => uint[]) public uRefArr;
    
    mapping (uint => uint) public poolCurrId;
    mapping (uint => uint) public poolActId;
    mapping (uint => uint) public pool_price;
    mapping (uint => uint) public poolChampRwrd;
    mapping (uint => mapping(uint => uint)) public LEVEL_PRICE_POOLS;
    mapping (uint => uint) public poolUnltdLvlPrice;
    mapping (uint => bool) public pausePoolFlag;
    mapping (uint => mapping (address => PoolUserStruct)) public poolUsers;
    mapping (uint => mapping(uint => address)) public poolUserList;
    
    TronStormProV2 tsObj;
    mapping(uint => uint) ownerPools;

    mapping (uint => uint) public chmpRwrdId;
    mapping (uint => mapping(uint => mapping(address => uint))) public champions;
    mapping (uint => mapping(uint => mapping(address => uint))) public championsTme;
    mapping (uint => uint) public champPoolBal;
    mapping (uint => bool) public pauseChampRwrd;

    mapping (uint => uint) public chmpMtrxRwrdId;
    mapping (uint => mapping(uint => mapping(address => uint))) public championsMtrx;
    mapping (uint => mapping(uint => mapping(address => uint))) public championsMtrxTme;
    mapping (uint => uint) public champMtrxPoolBal;
    mapping (uint => bool) public pauseMtrxChampRwrd;
    

    event regLevelEvent(address indexed _user, address indexed _referrer,uint amount,uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level,uint amount, uint _time);
    event getMoneyForPoolLevelEvent(address indexed _user, address indexed _referral,uint _level,uint _pool,uint amount,uint _time);
      
    event regPoolEntry(address indexed _user,uint _level,uint amount,uint _time);
   
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level,uint amount,uint _time);

    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
     
    constructor(address contractAddr) public {
        crtr = msg.sender;
        dbOwner = msg.sender;
        tsObj = TronStormProV2(contractAddr);
        ownerWallet = tsObj.ownerWallet();
        currUserID = tsObj.currUserID();
        xPoolOwner = ownerWallet;

        pool_price[1] = 500 trx;
        pool_price[2] = 1000 trx;
        pool_price[3] = 2000 trx;
        pool_price[4] = 3500 trx;
        pool_price[5] = 5000 trx;
        pool_price[6] = 7500 trx;
        pool_price[7] = 10000 trx;
        pool_price[8] = 12500 trx;
        pool_price[9] = 15000 trx;
        pool_price[10] = 17500 trx;
        pool_price[11] = 20000 trx;
        pool_price[12] = 35000 trx;
        pool_price[13] = 50000 trx;
        pool_price[14] = 75000 trx;
        pool_price[15] = 100000 trx;
        pool_price[16] = 200000 trx;
        pool_price[17] = 400000 trx;
        pool_price[18] = 500000 trx;
        pool_price[19] = 1000000 trx;

        for(uint j=0;j<LAST_POOL+1;j++){
            chmpRwrdId[j] = 1;
        }

        for(uint k=1;k<=LAST_POOL;k++){
            chmpMtrxRwrdId[k] = 1;
        }

        LEVEL_PRICE[1] = 100 trx;  // 20
        LEVEL_PRICE[2] = 50 trx; // 10
        LEVEL_PRICE[3] = 25 trx; // 5
        LEVEL_PRICE[4] = 2.5 trx; // 0.5
        unlimited_level_price_reg = 1  trx; // 0.2
        reg_champ_amt = 2.5 trx;
           
           ownerPools[0] = 4;
           ownerPools[1] = 6;
           ownerPools[2] = 8;
           ownerPools[3] = 9;
           ownerPools[4] = 10;
           ownerPools[5] = 12;
           ownerPools[6] = 14;

       PoolUserStruct memory pUStruct;
       for(uint p=0;p<=6;p++){
          uint pl = ownerPools[p];
          poolCurrId[pl] = poolCurrId[pl]+1;
          pUStruct = PoolUserStruct({
                isExist:true,
                id:poolCurrId[pl],
                payment_received:0,
                cycle:0,
                oddEvenFlag:0
          });
          poolUsers[pl][ownerWallet] = pUStruct;
          poolUserList[pl][poolCurrId[pl]]=ownerWallet;
          poolActId[pl] = poolCurrId[pl];
       }

    }

      function increaseChmpRwrdId(uint which) public onlyDb {
          chmpRwrdId[which]++;
      }

      function changeChmpRwrdPause(uint which,uint flagPause) public onlyOwner {
        if(flagPause==1){
          pauseChampRwrd[which] = true;
        }else if(flagPause==0) {
          pauseChampRwrd[which] = false;
        }
      }

      function increaseMtrxChmpRwrdId(uint which) public onlyDb {
          chmpMtrxRwrdId[which]++;
      }

      function changeMtrxChmpRwrdPause(uint which,uint flagPause) public onlyOwner {
        if(flagPause==1){
          pauseMtrxChampRwrd[which] = true;
        }else if(flagPause==0) {
          pauseMtrxChampRwrd[which] = false;
        }
      }

      function subtractChampPoolBal(uint subtAmt,uint fromPl) public onlyDb {
          champPoolBal[fromPl] = champPoolBal[fromPl] - subtAmt;
      }

      function ownerPoolXId() public onlyOwner{
          for(uint p=4;p<=LAST_POOL;p++){
            xPUsers[xPoolOwner].activeX6Levels[uint8(p)] = true;
          }
      }
      
      function firstLevelUsers(uint uid) view public returns(uint[]){
          return uRefArr[uid];
      }

      function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
            return xPUsers[userAddress].activeX6Levels[level];
      }
      
       function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool,uint, address) {
        return (xPUsers[userAddress].x6Matrix[level].currentReferrer,
                xPUsers[userAddress].x6Matrix[level].firstLevelReferrals,
                xPUsers[userAddress].x6Matrix[level].secondLevelReferrals,
                xPUsers[userAddress].x6Matrix[level].blocked,
                xPUsers[userAddress].x6Matrix[level].reinvestCount,
                xPUsers[userAddress].x6Matrix[level].closedPart);
        }

      
      function uRegVal(uint amt, uint l1, uint l2, uint l3, uint l4, uint l5,uint chmpAmt) onlyOwner public returns(bool) {
          if(amt>0 && l1>0 && l2>0 && l3>0 && l4>0 && l5>0){
                REGESTRATION_FEES = amt;
                LEVEL_PRICE[1] = l1;  // 20
                LEVEL_PRICE[2] = l2; // 10
                LEVEL_PRICE[3] = l3; // 5
                LEVEL_PRICE[4] = l4; // 0.5
                unlimited_level_price_reg = l5; // 0.2
                reg_champ_amt = chmpAmt;
          }else{
              revert();
          }
          return true;
      }
      
      function uPoolVal(uint pl, uint amt, uint l1, uint l2, uint l3, uint l4, uint l5, uint plChmpRwrd) onlyOwner public returns(bool) {
          require(pl>=1 && pl<=LAST_POOL,"Pool number is not correct");
          pool_price[pl] = amt;
          LEVEL_PRICE_POOLS[pl][1] = l1;
          LEVEL_PRICE_POOLS[pl][2] = l2;
          LEVEL_PRICE_POOLS[pl][3] = l3;
          LEVEL_PRICE_POOLS[pl][4] = l4;
          poolUnltdLvlPrice[pl] = l5;
          poolChampRwrd[pl] = plChmpRwrd;
          return true;
      }
     
      function regUser(uint _referrerID) public payable {
         require(!regPausedFlag,"Registrations are stopped for while");
         require(!users[msg.sender].isExist, "User Exists");
         require(users[userList[_referrerID]].isExist, 'Incorrect referral ID');
         require(msg.value == REGESTRATION_FEES, 'Incorrect Value');
        
        address uAr = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(uAr)
        }
       
         UserStruct memory userStruct;
         currUserID++;

         userStruct = UserStruct({
             pk:currUserID,
             isExist: true,
             id: block.number+currUserID,
             referrerID: _referrerID,
             referredUsers:0,
             refIncome:0,
             poolRefIncome:0,
             xpoolRefIncome:0,
             creationDate:now
         });
 
        users[msg.sender] = userStruct;
        userList[block.number+currUserID]=msg.sender;
        userListSeq[currUserID]=msg.sender;
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        uRefArr[_referrerID].push(block.number+currUserID);
        
        if(pauseChampRwrd[0]){
          champPoolBal[0] = champPoolBal[0]+reg_champ_amt; 
          champions[0][chmpRwrdId[0]][userList[_referrerID]] = champions[0][chmpRwrdId[0]][userList[_referrerID]] + 1;
          championsTme[0][chmpRwrdId[0]][userList[_referrerID]] = now;
        }

        payReferral(1,msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID],msg.value, now);
    }
    
    function insTrx(uint _referrerID,address _addr) onlyOwner public {
         require(!users[_addr].isExist, "User Exists");
         require(users[userList[_referrerID]].isExist, 'Incorrect referral ID');
       
        address uAr = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(uAr)
        }
       
         UserStruct memory userStruct;
         currUserID++;

         userStruct = UserStruct({
             pk:currUserID,
             isExist: true,
             id: block.number+currUserID,
             referrerID: _referrerID,
             referredUsers:0,
             refIncome:0,
             poolRefIncome:0,
             xpoolRefIncome:0,
             creationDate:now
         });
 
        users[_addr] = userStruct;
        userListSeq[currUserID]=_addr;
        userList[block.number+currUserID]=_addr;
        users[userList[users[_addr].referrerID]].referredUsers=users[userList[users[_addr].referrerID]].referredUsers+1;
        uRefArr[_referrerID].push(block.number+currUserID);
        
        emit regLevelEvent(_addr, userList[_referrerID],REGESTRATION_FEES, now);
    }
   
   
     function payReferral(uint _level, address _user) private {
        address referer;
        referer = userList[users[_user].referrerID];
         bool sent = false;
            uint level_price_local=0;
            if(_level>4){
            level_price_local=unlimited_level_price_reg;
            }
            else{
            level_price_local=LEVEL_PRICE[_level];
            }
            users[referer].refIncome = users[referer].refIncome + level_price_local;
            sent = address(uint160(referer)).send(level_price_local);
            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level,level_price_local, now);
                if(_level < 100 && users[referer].referrerID >= 1){
                    payReferral(_level+1,referer);
                }
                else
                {
                    sendBalance();
                }
            }
        if(!sent) {
          //emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            payReferral(_level, referer);
        }
     }
   
   function payPoolReferral(uint _level, address _user, uint pool, uint amount,uint xflag) private {
        address referer;
        referer = userList[users[_user].referrerID];
         bool sent = false;
            uint level_price_local=0;
            if(_level>4){
                level_price_local = poolUnltdLvlPrice[pool];
            }else{
                level_price_local = LEVEL_PRICE_POOLS[pool][_level];
            }
            if(address(this).balance >= level_price_local){
                if(xflag==1){
                  users[referer].xpoolRefIncome = users[referer].xpoolRefIncome + level_price_local; 
                  }else if(xflag==0){
                      users[referer].poolRefIncome = users[referer].poolRefIncome + level_price_local;
                  }
                sent = address(uint160(referer)).send(level_price_local);
            }
            if (sent) {
                emit getMoneyForPoolLevelEvent(referer, msg.sender,_level,pool,level_price_local,block.timestamp);
                if(_level < 100 && users[referer].referrerID >= 1){
                    payPoolReferral(_level+1,referer, pool, amount,xflag);
                }
                else
                {
                    sendBalance();
                }
            }
        if(!sent) {
            payPoolReferral(_level, referer, pool,amount,xflag);
        }
     }

    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (xPUsers[userList[users[userAddress].referrerID]].activeX6Levels[level]) {
                return userList[users[userAddress].referrerID];
            }
            userAddress = userList[users[userAddress].referrerID];
        }
    }

    function buyPoolx(uint8 pool) payable public returns(bool){
        require(pauseXFlag[pool],"This pool is disabled for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(!xPUsers[msg.sender].activeX6Levels[pool],"this pool is already activated");
        if(pool>1){
          require(xPUsers[msg.sender].activeX6Levels[pool-1],"previous pool is not activated");
        }
        require(msg.value == pool_price[pool], 'Incorrect Value');
        require(pool>=1 && pool<=LAST_POOL,"Pool value sent not correct");

        address refererAddr = userList[users[msg.sender].referrerID];

        if(pool==1){
          XPoolUser memory xPUser;
          lastXPoolId++;
          xPUser.isExist=true;
          xPUser.id = lastXPoolId;
          xPUser.referrer = refererAddr;
          xPUser.partnersCount = uint(0);
          
          xPUsers[msg.sender] = xPUser;
          xPUserIdByAddress[lastXPoolId] = msg.sender;
          xPUsers[msg.sender].activeX6Levels[pool] = true;
        }else{
          xPUsers[msg.sender].activeX6Levels[pool] = true;
        }

        if(pauseMtrxChampRwrd[pool]){
            champMtrxPoolBal[pool] = champMtrxPoolBal[pool]+poolChampRwrd[pool]; 
            championsMtrx[pool][chmpMtrxRwrdId[pool]][refererAddr] = championsMtrx[pool][chmpMtrxRwrdId[pool]][refererAddr] + 1;
            championsMtrxTme[pool][chmpMtrxRwrdId[pool]][refererAddr] = now;            
        }

        address freeReferrer = findFreeX6Referrer(msg.sender,pool);

        updateX6Referrer(msg.sender,freeReferrer,pool);

        payPoolReferral(1, msg.sender, pool, pool_price[pool]/10,1);
        return true;
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(xPUsers[referrerAddress].activeX6Levels[level], "Referrer level is inactive");
        
        if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
             emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            xPUsers[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == xPoolOwner) {
                return sendTRXDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = xPUsers[referrerAddress].x6Matrix[level].currentReferrer;            
            xPUsers[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = xPUsers[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && (xPUsers[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) && 
                (xPUsers[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    xPUsers[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && xPUsers[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        xPUsers[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (xPUsers[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                xPUsers[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                xPUsers[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }
    
     function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            xPUsers[userAddress].x6Matrix[level].currentReferrer = xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(xPUsers[xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            xPUsers[userAddress].x6Matrix[level].currentReferrer = xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (xPUsers[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTRXDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = xPUsers[xPUsers[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                xPUsers[xPUsers[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    xPUsers[xPUsers[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        xPUsers[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        xPUsers[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        xPUsers[referrerAddress].x6Matrix[level].closedPart = address(0);

        // if (!xPUsers[referrerAddress].activeX6Levels[level+1] && level != LAST_POOL) {
        //     xPUsers[referrerAddress].x6Matrix[level].blocked = true;
        // }

        xPUsers[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != xPoolOwner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(xPoolOwner, address(0), userAddress, 2, level);
            sendTRXDividends(xPoolOwner, userAddress, 2, level);
        }
    }

    function sendTRXDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        if (!address(uint160(userAddress)).send((pool_price[level]*90)/100)) {
            return address(uint160(ownerWallet)).transfer(address(this).balance);
        }
    }

    function getCTRAddr() view onlyOwner public returns(address) {
        return crtr;
    }
    
    function getDbOwnerAddr() view onlyOwner public returns(address) {
        return dbOwner;
    }
    
    modifier onlyOwner() {
         require(msg.sender==crtr,"not authorized");
         _;
     }
     
     modifier onlyDb() {
         require(msg.sender==dbOwner || msg.sender==crtr,"not authorized");
         _;
     }
     
     function changeDbOwner(address _addr) onlyOwner public returns(bool) {
         dbOwner = _addr;
         return true;
     }
     
     function changeContractInst(address _addr) onlyOwner public returns(bool) {
         tsObj = TronStormProV2(_addr);
         return true;
     }

     function changePoolXPauseFlag(uint pool,uint flag) onlyOwner public returns(bool){
        if(flag==1){
          pauseXFlag[pool] = true;
        }else if(flag==0){
          pauseXFlag[pool] = false;
        }
     }
     
     function changePauseFlag(uint flag) onlyOwner public returns(bool) {
         if(flag==1){
             regPausedFlag=true;
         }else if(flag==0){
             regPausedFlag=false;
         }
         return true;
     }
     
     function changePoolPauseFlag(uint pool,uint flag) onlyOwner public returns(bool) {
        if(flag==1){
          pausePoolFlag[pool] = true;
        }else if(flag==0){
          pausePoolFlag[pool] = false;
        }
        return true;
     }

    function buyPool(uint pool) public payable {
         require(pausePoolFlag[pool],"Buy Pool is stopped for while");
         require(users[msg.sender].isExist, "User Not Registered");
         require(msg.value == pool_price[pool], 'Incorrect Value');
         
          PoolUserStruct memory userStruct;
          
          address poolCurrUser = poolUserList[pool][poolActId[pool]];

          poolCurrId[pool] = poolCurrId[pool]+1;
  
          if(poolUsers[pool][msg.sender].isExist){
              require(poolUsers[pool][msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
              if(pool<LAST_POOL){
                require(poolUsers[pool+1][msg.sender].isExist,"buy next pool at least once");
              }
              userStruct = poolUsers[pool][msg.sender];
              userStruct.cycle = userStruct.cycle+1;
              userStruct.payment_received = 0;
              userStruct.id = poolCurrId[pool];
              userStruct.oddEvenFlag = 0;
          }else{
              if(pool>1){
                require(poolUsers[pool-1][msg.sender].isExist,"buy previous pool once");  
              }
              userStruct = PoolUserStruct({
                  isExist:true,
                  id:poolCurrId[pool],
                  payment_received:0,
                  cycle:0,
                  oddEvenFlag:0
              });                
          }
     
         poolUsers[pool][msg.sender] = userStruct;
         poolUserList[pool][poolCurrId[pool]]=msg.sender;
         
         address refAddr = userList[users[msg.sender].referrerID];
         if(pauseChampRwrd[pool]){
            champPoolBal[pool] = champPoolBal[pool]+poolChampRwrd[pool]; 
            champions[pool][chmpRwrdId[pool]][refAddr] = champions[pool][chmpRwrdId[pool]][refAddr] + 1;
            championsTme[pool][chmpRwrdId[pool]][refAddr] = now;
         }

         bool sent = false; 
         uint tmp = 0;
         
         if(poolUsers[pool][refAddr].isExist && poolUsers[pool][refAddr].payment_received<3){
              if(poolUsers[pool][refAddr].oddEvenFlag!=0){                    
                  sent = address(uint160(refAddr)).send((pool_price[pool] * 90)/100);
                  if (sent) {
                      payPoolReferral(1, msg.sender, pool, pool_price[pool]/10,0);
                      
                      poolUsers[pool][refAddr].payment_received+=1;
                      poolUsers[pool][refAddr].oddEvenFlag=0;
                      if(poolUsers[pool][poolCurrUser].payment_received>=3)
                      {
                          tmp = poolActId[pool]+1;
                          while(true){
                              if(tmp<=poolCurrId[pool] && poolUsers[pool][poolUserList[pool][tmp]].payment_received>=3){
                                  tmp = tmp+1;
                              }else if(tmp<=poolCurrId[pool]){
                                  poolActId[pool] = tmp;
                                  break;
                              }
                          }
                      }
                      emit getPoolPayment(msg.sender,refAddr, pool,(pool_price[pool] * 90)/100, now);
                  }
              }else{
                  poolUsers[pool][refAddr].oddEvenFlag=1;
                  sent = address(uint160(poolCurrUser)).send((pool_price[pool] * 90)/100);
                  if (sent) {
                      
                      payPoolReferral(1, msg.sender, pool, pool_price[pool]/10,0);
                      
                      poolUsers[pool][poolCurrUser].payment_received+=1;
                      if(poolUsers[pool][poolCurrUser].payment_received>=3)
                      {
                          tmp = poolActId[pool]+1;
                          while(true){
                              if(tmp<=poolCurrId[pool] && poolUsers[pool][poolUserList[pool][tmp]].payment_received>=3){
                                  tmp = tmp+1;
                              }else if(tmp<=poolCurrId[pool]){
                                  poolActId[pool] = tmp;
                                  break;
                              }
                          }
                      }
                      emit getPoolPayment(msg.sender,poolCurrUser, pool,(pool_price[pool] * 90)/100, now);
                  }
              }
          }else{
              sent = address(uint160(poolCurrUser)).send((pool_price[pool] * 90)/100);
              if (sent) {
                  
                  payPoolReferral(1, msg.sender, pool, pool_price[pool]/10,0);
                  
                  poolUsers[pool][poolCurrUser].payment_received+=1;
                  if(poolUsers[pool][poolCurrUser].payment_received>=3)
                  {
                      tmp = poolActId[pool]+1;
                      while(true){
                          if(tmp<=poolCurrId[pool] && poolUsers[pool][poolUserList[pool][tmp]].payment_received>=3){
                              tmp = tmp+1;
                          }else if(tmp<=poolCurrId[pool]){
                              poolActId[pool] = tmp;
                              break;
                          }
                      }
                  }
                  emit getPoolPayment(msg.sender,poolCurrUser, pool,(pool_price[pool] * 90)/100, now);
              }
          }           
         emit regPoolEntry(msg.sender, pool,pool_price[pool], now);
    }
    
    function getTRXBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendBalance() private
    {
        address(uint160(ownerWallet)).transfer(getTRXBalance());
    }
    
    function sendBalanceToOwner() onlyOwner public
    {
        if (!address(uint160(ownerWallet)).send(getTRXBalance()))
         {
             
         } 
         
    }
    
    function saveOldData(uint[] _idarr) public onlyOwner returns(bool){
        for(uint i=0;i<_idarr.length;i++){
            address uAddr = tsObj.userList(_idarr[i]);
            if(!users[uAddr].isExist){
                (uint pk,bool isExist,uint id,uint refId,uint refUCount,uint refInc,uint pRefInc,uint xPInc,uint cTime) = tsObj.users(uAddr);
                if(isExist){
                    UserStruct memory userStruct;
                    userStruct = UserStruct({
                         pk:pk,
                         isExist: true,
                         id: id,
                         referrerID: refId,
                         referredUsers:refUCount,
                         refIncome:refInc,
                         poolRefIncome:pRefInc,
                         xpoolRefIncome:xPInc,
                         creationDate:cTime
                    });
             
                    users[uAddr] = userStruct;
                    userList[id]=uAddr;
                    userListSeq[pk]=uAddr;
                    if(refId>0){
                        uRefArr[refId].push(id);    
                        emit regLevelEvent(uAddr, userList[refId],REGESTRATION_FEES, now); 
                    }else{
                        emit regLevelEvent(uAddr, 0,REGESTRATION_FEES, now); 
                    }
                }  
                saveOldPoolData(11,uAddr);
                saveOldPoolData(12,uAddr);  
                saveOldPoolData(1,uAddr);
                saveOldPoolData(2,uAddr);
                saveOldPoolData(3,uAddr);               
            }
        }
        return true;
    }

    function updateRestPoolData(address uAddr) public onlyOwner {
        saveOldPoolData(4,uAddr);
        saveOldPoolData(5,uAddr); 
        saveOldPoolData(6,uAddr);
        saveOldPoolData(7,uAddr);
        saveOldPoolData(8,uAddr);
        saveOldPoolData(9,uAddr);
        saveOldPoolData(10,uAddr);
    }

    function saveDataPersonal(uint usrId, address usrAddr) public onlyOwner returns(bool){
        address uAddr = tsObj.userList(usrId);
        if(!users[usrAddr].isExist){
            (uint pk,bool isExist,uint id,uint refId,uint refUCount,uint refInc,uint pRefInc,uint xPInc,uint cTime) = tsObj.users(uAddr);
            if(isExist){
                UserStruct memory userStruct;
                userStruct = UserStruct({
                     pk:pk,
                     isExist: true,
                     id: id,
                     referrerID: refId,
                     referredUsers:refUCount,
                     refIncome:refInc,
                     poolRefIncome:pRefInc,
                     xpoolRefIncome:xPInc,
                     creationDate:cTime
                });
         
                users[usrAddr] = userStruct;
                userList[id]=usrAddr;
                userListSeq[pk]=usrAddr;
                if(refId>0){
                    uRefArr[refId].push(id);    
                    emit regLevelEvent(usrAddr, userList[refId],REGESTRATION_FEES, now); 
                }else{
                    emit regLevelEvent(usrAddr, 0,REGESTRATION_FEES, now); 
                }
            }  
            saveOldPoolDataPrsnl(1,uAddr,usrAddr);
            saveOldPoolDataPrsnl(2,uAddr,usrAddr);
            saveOldPoolDataPrsnl(3,uAddr,usrAddr);
            saveOldPoolDataPrsnl(4,uAddr,usrAddr);
            saveOldPoolDataPrsnl(5,uAddr,usrAddr);
            saveOldPoolDataPrsnl(6,uAddr,usrAddr);
            saveOldPoolDataPrsnl(7,uAddr,usrAddr);
            saveOldPoolDataPrsnl(8,uAddr,usrAddr);
            saveOldPoolDataPrsnl(9,uAddr,usrAddr);
            saveOldPoolDataPrsnl(10,uAddr,usrAddr);
            saveOldPoolDataPrsnl(11,uAddr,usrAddr);
            saveOldPoolDataPrsnl(12,uAddr,usrAddr);
        }
        return true;
    }

    function saveMatrixOldData(uint8 pool,uint xpId,address usrAddr,address spnsrAddr) public onlyOwner returns(bool){
        if(pool==11){
          uint8 rPool = 1;
          lastXPoolId = xpId;
          XPoolUser memory xPUser;          
          xPUser.isExist=true;
          xPUser.id = lastXPoolId;
          xPUser.referrer = spnsrAddr;
          xPUser.partnersCount = uint(0);

          xPUsers[usrAddr] = xPUser;
          xPUserIdByAddress[lastXPoolId] = usrAddr;
          xPUsers[usrAddr].activeX6Levels[1] = true;
        }else if(pool==12){
          rPool = 2;
          xPUsers[usrAddr].activeX6Levels[2] = true;
        }
        saveMatrixData(usrAddr,pool,rPool);
        return true;
    }
    
    function saveMatrixData(address usrAddr,uint8 pool,uint8 rPool) private {
        (address curRef,address[] memory fLvlArr,address[] memory scndLvlArr,,uint rInvC,address cPart) = tsObj.usersX6Matrix(usrAddr,pool);
        
        xPUsers[usrAddr].x6Matrix[uint8(rPool)].currentReferrer = curRef;
        xPUsers[usrAddr].x6Matrix[uint8(rPool)].reinvestCount = rInvC;
        xPUsers[usrAddr].x6Matrix[uint8(rPool)].closedPart = cPart;
        for(uint i=0;i<fLvlArr.length;i++){
          xPUsers[usrAddr].x6Matrix[uint8(rPool)].firstLevelReferrals.push(fLvlArr[i]);
        }
        for(uint j=0;j<scndLvlArr.length;j++){
          xPUsers[usrAddr].x6Matrix[uint8(rPool)].secondLevelReferrals.push(scndLvlArr[j]);
        }
    }

    function saveMatrix3xOldData(address usrAddr,address curRef,address[] memory fLvlArr,address[] memory scndLvlArr,uint rInvC,address cPart) public onlyOwner returns(bool){
        if(xPUsers[usrAddr].isExist){
            xPUsers[usrAddr].activeX6Levels[3] = true;
            xPUsers[usrAddr].x6Matrix[3].currentReferrer = curRef;
            xPUsers[usrAddr].x6Matrix[3].reinvestCount = rInvC;
            xPUsers[usrAddr].x6Matrix[3].closedPart = cPart;
            for(uint i=0;i<fLvlArr.length;i++){
              xPUsers[usrAddr].x6Matrix[3].firstLevelReferrals.push(fLvlArr[i]);
            }
            for(uint j=0;j<scndLvlArr.length;j++){
              xPUsers[usrAddr].x6Matrix[3].secondLevelReferrals.push(scndLvlArr[j]);
            }
            return true;
        }else{
          return false;
        }
    }
    
    function saveOldPoolData(uint pool, address addr) public onlyOwner returns(bool){
        if(users[addr].isExist){
            PoolUserStruct memory userStruct;
            (bool isExist,uint pId, uint pymnt,uint cycle,uint oEvnFlag) = (false,0,0,0,0);
            if(pool==1){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool1users(addr);
            }else if(pool==2){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool2users(addr);
            }else if(pool==3){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool3users(addr);
            }else if(pool==4){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool4users(addr);
            }else if(pool==5){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool5users(addr);
            }else if(pool==6){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool6users(addr);
            }else if(pool==7){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool7users(addr);
            }else if(pool==8){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool8users(addr);
            }else if(pool==9){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool9users(addr);
            }else if(pool==10){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool10users(addr);
            }else if(pool==11){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool11users(addr);
            }else if(pool==12){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool12users(addr);
            }        
            if(pool==11){
              pool = 1;
            }else if(pool==12){
              pool = 2;
            }else if(pool==1){
              pool = 3;
            }else if(pool==2){
              pool = 5;
            }else if(pool==3){
              pool = 7;
            }else if(pool==4){
              pool = 11;
            }else if(pool==5){
              pool = 13;
            }else if(pool==6){
              pool = 15;
            }else if(pool==7){
              pool = 16;
            }else if(pool==8){
              pool = 17;
            }else if(pool==9){
              pool = 18;
            }else if(pool==10){
              pool = 19;
            }
            if(isExist && !poolUsers[pool][addr].isExist){
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pId,
                    payment_received:pymnt,
                    cycle:cycle,
                    oddEvenFlag:oEvnFlag
                });
                poolUsers[pool][addr] = userStruct;
                poolUserList[pool][pId]=addr;
                emit regPoolEntry(addr,pool,pool_price[pool],now);
            }    
        }
    }

    function saveOldPoolDataPrsnl(uint pool, address addr, address nUsrAddr) public onlyOwner returns(bool){
        if(users[nUsrAddr].isExist){
            PoolUserStruct memory userStruct;
            (bool isExist,uint pId, uint pymnt,uint cycle,uint oEvnFlag) = (false,0,0,0,0);
            if(pool==1){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool1users(addr);
            }else if(pool==2){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool2users(addr);
            }else if(pool==3){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool3users(addr);
            }else if(pool==4){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool4users(addr);
            }else if(pool==5){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool5users(addr);
            }else if(pool==6){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool6users(addr);
            }else if(pool==7){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool7users(addr);
            }else if(pool==8){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool8users(addr);
            }else if(pool==9){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool9users(addr);
            }else if(pool==10){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool10users(addr);
            }else if(pool==11){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool11users(addr);
            }else if(pool==12){
                (isExist,pId,pymnt,cycle,oEvnFlag) = tsObj.pool12users(addr);
            }        
            if(pool==11){
              pool = 1;
            }else if(pool==12){
              pool = 2;
            }else if(pool==1){
              pool = 3;
            }else if(pool==2){
              pool = 5;
            }else if(pool==3){
              pool = 7;
            }else if(pool==4){
              pool = 11;
            }else if(pool==5){
              pool = 13;
            }else if(pool==6){
              pool = 15;
            }else if(pool==7){
              pool = 16;
            }else if(pool==8){
              pool = 17;
            }else if(pool==9){
              pool = 18;
            }else if(pool==10){
              pool = 19;
            }
            if(isExist && !poolUsers[pool][nUsrAddr].isExist){
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pId,
                    payment_received:pymnt,
                    cycle:cycle,
                    oddEvenFlag:oEvnFlag
                });
                poolUsers[pool][nUsrAddr] = userStruct;
                poolUserList[pool][pId]=nUsrAddr;
                emit regPoolEntry(nUsrAddr,pool,pool_price[pool],now);
            }    
        }
    }

     function poolActiveCurIdSave(uint actId,uint curId,uint pool) public onlyOwner returns(bool){
        if(actId>0 && curId>0){
            poolActId[pool] = actId;
            poolCurrId[pool] = curId;
        }else{
            revert();
        }
    }
    
    function buyPoolUpgrade(uint _pool,address _addr) onlyDb public {
        require(users[_addr].isExist, "User Not Registered");
        require(_pool>=1 && _pool<=LAST_POOL,"Pool Number is not");

        PoolUserStruct memory userStruct;
        if(poolUsers[_pool][_addr].isExist){
            poolCurrId[_pool] = poolCurrId[_pool]+1;            
            require(poolUsers[_pool][_addr].payment_received >= 3,"Your previous cycle for payment is pending");
            if(_pool<LAST_POOL){
              require(poolUsers[_pool+1][_addr].isExist);
            }
            userStruct = poolUsers[_pool][_addr];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = poolCurrId[_pool];
            userStruct.oddEvenFlag = 0;
        }else{
            revert();               
        }
        poolUsers[_pool][_addr] = userStruct;
        poolUserList[_pool][poolCurrId[_pool]]=_addr;
        
        
      emit regPoolEntry(_addr,_pool,pool_price[_pool],now);
    }

}

contract TronStormProV2 {
      address public ownerWallet;
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool2currUserID = 0;
      uint public pool3currUserID = 0;
      uint public pool4currUserID = 0;
      uint public pool5currUserID = 0;
      uint public pool6currUserID = 0;
      uint public pool7currUserID = 0;
      uint public pool8currUserID = 0;
      uint public pool9currUserID = 0;
      uint public pool10currUserID = 0;
      uint public pool11currUserID = 0;
      uint public pool12currUserID = 0;
      
      uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
      uint public pool4activeUserID = 0;
      uint public pool5activeUserID = 0;
      uint public pool6activeUserID = 0;
      uint public pool7activeUserID = 0;
      uint public pool8activeUserID = 0;
      uint public pool9activeUserID = 0;
      uint public pool10activeUserID = 0;
      uint public pool11activeUserID = 0;
      uint public pool12activeUserID = 0;
     
      struct UserStruct {
        uint pk;
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
       uint refIncome;
       uint poolRefIncome;
       uint xpoolRefIncome;
       uint creationDate;
    }
    
    struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
       uint cycle;
       uint oddEvenFlag;
    }

    struct XPoolUser {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X6) x6Matrix;
    }

    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    
    mapping (uint => bool) public pauseXFlag;
    mapping (address => XPoolUser) public xPUsers;
    mapping (uint => address) public xPUserIdByAddress;
    
    mapping(uint => uint[]) public uRefArr;
    
    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
     mapping (uint => address) public userListSeq;
     
     mapping (address => PoolUserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
     
     mapping (address => PoolUserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
     
     mapping (address => PoolUserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
     
     mapping (address => PoolUserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
     
     mapping (address => PoolUserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
     
     mapping (address => PoolUserStruct) public pool6users;
     mapping (uint => address) public pool6userList;
     
     mapping (address => PoolUserStruct) public pool7users;
     mapping (uint => address) public pool7userList;
     
     mapping (address => PoolUserStruct) public pool8users;
     mapping (uint => address) public pool8userList;
     
     mapping (address => PoolUserStruct) public pool9users;
     mapping (uint => address) public pool9userList;
     
     mapping (address => PoolUserStruct) public pool10users;
     mapping (uint => address) public pool10userList;

     mapping (address => PoolUserStruct) public pool11users;
     mapping (uint => address) public pool11userList;

     mapping (address => PoolUserStruct) public pool12users;
     mapping (uint => address) public pool12userList;

     uint public lastXPoolId =0;
     
     function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {}

     function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool,uint, address) {}

}