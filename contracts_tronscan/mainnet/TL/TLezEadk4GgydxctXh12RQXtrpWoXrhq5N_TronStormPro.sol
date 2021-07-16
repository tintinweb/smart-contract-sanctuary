//SourceUnit: newTStorm.sol

pragma solidity ^0.4.25;

contract TronStormPro {
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
      
      
      uint public unlimited_level_price_reg=0;
      uint public unlimited_level_price_pool1=0;
      uint public unlimited_level_price_pool2=0;
      uint public unlimited_level_price_pool3=0;
      uint public unlimited_level_price_pool4=0;
      uint public unlimited_level_price_pool5=0;
      uint public unlimited_level_price_pool6=0;
      uint public unlimited_level_price_pool7=0;
      uint public unlimited_level_price_pool8=0;
      uint public unlimited_level_price_pool9=0;
      uint public unlimited_level_price_pool10=0;
     
      struct UserStruct {
        uint pk;
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
       uint refIncome;
       uint poolRefIncome;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
       uint cycle;
    }
    
    address crtr;
    
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
     
    mapping(uint => uint) public LEVEL_PRICE;
    mapping(uint => uint) public LEVEL_PRICE_POOL1;
    mapping(uint => uint) public LEVEL_PRICE_POOL2;
    mapping(uint => uint) public LEVEL_PRICE_POOL3;
    mapping(uint => uint) public LEVEL_PRICE_POOL4;
    mapping(uint => uint) public LEVEL_PRICE_POOL5;
    mapping(uint => uint) public LEVEL_PRICE_POOL6;
    mapping(uint => uint) public LEVEL_PRICE_POOL7;
    mapping(uint => uint) public LEVEL_PRICE_POOL8;
    mapping(uint => uint) public LEVEL_PRICE_POOL9;
    mapping(uint => uint) public LEVEL_PRICE_POOL10;
    
   uint public REGESTRATION_FEES=500 trx;
   uint public pool1_price=2000 trx;
   uint public pool2_price=5000 trx;
   uint public pool3_price=10000 trx;
   uint public pool4_price=20000 trx;
   uint public pool5_price=50000 trx;
   uint public pool6_price=100000 trx;
   uint public pool7_price=200000 trx;
   uint public pool8_price=400000 trx;
   uint public pool9_price=500000 trx;
   uint public pool10_price=1000000 trx;
   
    event regLevelEvent(address indexed _user, address indexed _referrer,uint amount,uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level,uint amount, uint _time);
    event getMoneyForPoolLevelEvent(address indexed _user, address indexed _referral,uint _level,uint _pool,uint amount,uint _time);
      
    event regPoolEntry(address indexed _user,uint _level,uint amount,uint _time);
   
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level,uint amount,uint _time);
   
     address dbOwner;
     bool public pausedFlag;
     bool public pool1PauseFlag;
     bool public pool2PauseFlag;
     bool public pool3PauseFlag;
     bool public pool4PauseFlag;
     bool public pool5PauseFlag;
     bool public pool6PauseFlag;
     bool public pool7PauseFlag;
     bool public pool8PauseFlag;
     bool public pool9PauseFlag;
     bool public pool10PauseFlag;
     TronStorm tsObj;
     
      constructor(address contractAddr) public {
        crtr = msg.sender;
        dbOwner = msg.sender;
        tsObj = TronStorm(contractAddr);
        ownerWallet = tsObj.ownerWallet();

        LEVEL_PRICE[1] = 100 trx;  // 20
        LEVEL_PRICE[2] = 50 trx; // 10
        LEVEL_PRICE[3] = 25 trx; // 5
        LEVEL_PRICE[4] = 2.5 trx; // 0.5
        unlimited_level_price_reg = 1  trx; // 0.2
        
        LEVEL_PRICE_POOL1[1] = 40 trx;
        LEVEL_PRICE_POOL1[2] = 20 trx;
        LEVEL_PRICE_POOL1[3] = 10 trx;
        LEVEL_PRICE_POOL1[4] = 1 trx;
        unlimited_level_price_pool1 = 0.4  trx;
        
        LEVEL_PRICE_POOL2[1] = 100 trx;
        LEVEL_PRICE_POOL2[2] = 50 trx;
        LEVEL_PRICE_POOL2[3] = 25 trx;
        LEVEL_PRICE_POOL2[4] = 2.5 trx;
        unlimited_level_price_pool2 = 1  trx;
        
        LEVEL_PRICE_POOL3[1] = 200 trx;
        LEVEL_PRICE_POOL3[2] = 100 trx;
        LEVEL_PRICE_POOL3[3] = 50 trx;
        LEVEL_PRICE_POOL3[4] = 5 trx;
        unlimited_level_price_pool3 = 2  trx;
        
        LEVEL_PRICE_POOL4[1] = 400 trx;
        LEVEL_PRICE_POOL4[2] = 200 trx;
        LEVEL_PRICE_POOL4[3] = 100 trx;
        LEVEL_PRICE_POOL4[4] = 10 trx;
        unlimited_level_price_pool4 = 4  trx;
        
        LEVEL_PRICE_POOL5[1] = 1000 trx;
        LEVEL_PRICE_POOL5[2] = 500 trx;
        LEVEL_PRICE_POOL5[3] = 250 trx;
        LEVEL_PRICE_POOL5[4] = 25 trx;
        unlimited_level_price_pool5 = 10  trx;
        
        LEVEL_PRICE_POOL6[1] = 2000 trx;
        LEVEL_PRICE_POOL6[2] = 1000 trx;
        LEVEL_PRICE_POOL6[3] = 500 trx;
        LEVEL_PRICE_POOL6[4] = 50 trx;
        unlimited_level_price_pool6 = 20  trx;
        
        LEVEL_PRICE_POOL7[1] = 4000 trx;
        LEVEL_PRICE_POOL7[2] = 2000 trx;
        LEVEL_PRICE_POOL7[3] = 1000 trx;
        LEVEL_PRICE_POOL7[4] = 100 trx;
        unlimited_level_price_pool7 = 40  trx;
        
        LEVEL_PRICE_POOL8[1] = 8000 trx;
        LEVEL_PRICE_POOL8[2] = 4000 trx;
        LEVEL_PRICE_POOL8[3] = 2000 trx;
        LEVEL_PRICE_POOL8[4] = 200 trx;
        unlimited_level_price_pool8 = 80  trx;
        
        LEVEL_PRICE_POOL9[1] = 10000 trx;
        LEVEL_PRICE_POOL9[2] = 5000 trx;
        LEVEL_PRICE_POOL9[3] = 2500 trx;
        LEVEL_PRICE_POOL9[4] = 250 trx;
        unlimited_level_price_pool9 = 100  trx;
        
        LEVEL_PRICE_POOL10[1] = 20000 trx;
        LEVEL_PRICE_POOL10[2] = 10000 trx;
        LEVEL_PRICE_POOL10[3] = 5000 trx;
        LEVEL_PRICE_POOL10[4] = 500 trx;
        unlimited_level_price_pool10 = 200  trx;
        
        pool1currUserID = tsObj.pool1currUserID();
        pool2currUserID = tsObj.pool2currUserID();
        pool3currUserID = tsObj.pool3currUserID();
        pool5currUserID = tsObj.pool5currUserID();
        pool6currUserID = tsObj.pool6currUserID();
        pool7currUserID = tsObj.pool7currUserID();
        pool8currUserID = tsObj.pool8currUserID();
        pool9currUserID = tsObj.pool9currUserID();
        pool10currUserID = tsObj.pool10currUserID();
        
        pool1activeUserID = tsObj.pool1activeUserID();
        pool2activeUserID = tsObj.pool2activeUserID();
        pool3activeUserID = tsObj.pool3activeUserID();
        pool5activeUserID = tsObj.pool5activeUserID();
        pool6activeUserID = tsObj.pool6activeUserID();
        pool7activeUserID = tsObj.pool7activeUserID();
        pool8activeUserID = tsObj.pool8activeUserID();
        pool9activeUserID = tsObj.pool9activeUserID();
        pool10activeUserID = tsObj.pool10activeUserID();

      }
      
      function firstLevelUsers(uint uid) view public returns(uint[]){
          return uRefArr[uid];
      }
      
      function uRegVal(uint amt, uint l1, uint l2, uint l3, uint l4, uint l5) onlyOwner public returns(bool) {
          if(amt>0 && l1>0 && l2>0 && l3>0 && l4>0 && l5>0){
                REGESTRATION_FEES = amt;
                LEVEL_PRICE[1] = l1;  // 20
                LEVEL_PRICE[2] = l2; // 10
                LEVEL_PRICE[3] = l3; // 5
                LEVEL_PRICE[4] = l4; // 0.5
                unlimited_level_price_reg = l5; // 0.2
          }else{
              revert();
          }
          return true;
      }
      
      function uPoolVal(uint pl, uint amt, uint l1, uint l2, uint l3, uint l4, uint l5) onlyOwner public returns(bool) {
          if(pl>=1 && pl<=10 && amt>0 && l1>0 && l2>0 && l3>0 && l4>0 && l5>0){
                if(pl==1){
                    pool1_price = amt;
                    LEVEL_PRICE_POOL1[1] = l1;  // 20
                    LEVEL_PRICE_POOL1[2] = l2; // 10
                    LEVEL_PRICE_POOL1[3] = l3; // 5
                    LEVEL_PRICE_POOL1[4] = l4; // 0.5
                    unlimited_level_price_pool1 = l5; // 0.2
                }else if(pl==2){
                    pool2_price = amt;
                    LEVEL_PRICE_POOL2[1] = l1;  // 20
                    LEVEL_PRICE_POOL2[2] = l2; // 10
                    LEVEL_PRICE_POOL2[3] = l3; // 5
                    LEVEL_PRICE_POOL2[4] = l4; // 0.5
                    unlimited_level_price_pool2 = l5; // 0.2
                }else if(pl==3){
                    pool3_price = amt;
                    LEVEL_PRICE_POOL3[1] = l1;  // 20
                    LEVEL_PRICE_POOL3[2] = l2; // 10
                    LEVEL_PRICE_POOL3[3] = l3; // 5
                    LEVEL_PRICE_POOL3[4] = l4; // 0.5
                    unlimited_level_price_pool3 = l5; // 0.2
                }else if(pl==4){
                    pool4_price = amt;
                    LEVEL_PRICE_POOL4[1] = l1;  // 20
                    LEVEL_PRICE_POOL4[2] = l2; // 10
                    LEVEL_PRICE_POOL4[3] = l3; // 5
                    LEVEL_PRICE_POOL4[4] = l4; // 0.5
                    unlimited_level_price_pool4 = l5; // 0.2
                }else if(pl==5){
                    pool5_price = amt;
                    LEVEL_PRICE_POOL5[1] = l1;  // 20
                    LEVEL_PRICE_POOL5[2] = l2; // 10
                    LEVEL_PRICE_POOL5[3] = l3; // 5
                    LEVEL_PRICE_POOL5[4] = l4; // 0.5
                    unlimited_level_price_pool5 = l5; // 0.2
                }else if(pl==6){
                    pool6_price = amt;
                    LEVEL_PRICE_POOL6[1] = l1;  // 20
                    LEVEL_PRICE_POOL6[2] = l2; // 10
                    LEVEL_PRICE_POOL6[3] = l3; // 5
                    LEVEL_PRICE_POOL6[4] = l4; // 0.5
                    unlimited_level_price_pool6 = l5; // 0.2
                }else if(pl==7){
                    pool7_price = amt;
                    LEVEL_PRICE_POOL7[1] = l1;  // 20
                    LEVEL_PRICE_POOL7[2] = l2; // 10
                    LEVEL_PRICE_POOL7[3] = l3; // 5
                    LEVEL_PRICE_POOL7[4] = l4; // 0.5
                    unlimited_level_price_pool7 = l5; // 0.2
                }else if(pl==8){
                    pool8_price = amt;
                    LEVEL_PRICE_POOL8[1] = l1;  // 20
                    LEVEL_PRICE_POOL8[2] = l2; // 10
                    LEVEL_PRICE_POOL8[3] = l3; // 5
                    LEVEL_PRICE_POOL8[4] = l4; // 0.5
                    unlimited_level_price_pool8 = l5; // 0.2
                }else if(pl==9){
                    pool9_price = amt;
                    LEVEL_PRICE_POOL9[1] = l1;  // 20
                    LEVEL_PRICE_POOL9[2] = l2; // 10
                    LEVEL_PRICE_POOL9[3] = l3; // 5
                    LEVEL_PRICE_POOL9[4] = l4; // 0.5
                    unlimited_level_price_pool9 = l5; // 0.2
                }else if(pl==10){
                    pool10_price = amt;
                    LEVEL_PRICE_POOL10[1] = l1;  // 20
                    LEVEL_PRICE_POOL10[2] = l2; // 10
                    LEVEL_PRICE_POOL10[3] = l3; // 5
                    LEVEL_PRICE_POOL10[4] = l4; // 0.5
                    unlimited_level_price_pool10 = l5; // 0.2
                }else{
                    revert();
                }
          }else{
              revert();
          }
          return true;
      }
      
     
      function regUser(uint _referrerID) public payable {
         require(!pausedFlag,"Registrations are stopped for while");
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
             poolRefIncome:0
         });
 
        users[msg.sender] = userStruct;
        userList[block.number+currUserID]=msg.sender;
        userListSeq[currUserID]=msg.sender;
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        uRefArr[_referrerID].push(block.number+currUserID);
        
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
             poolRefIncome:0
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
   
   function payPoolReferral(uint _level, address _user, uint pool, uint amount) private {
        address referer;
        referer = userList[users[_user].referrerID];
         bool sent = false;
            uint level_price_local=0;
            if(_level>4){
                if(pool==1){
                    level_price_local=unlimited_level_price_pool1;
                }else if(pool==2){
                    level_price_local=unlimited_level_price_pool2;
                }else if(pool==3){
                    level_price_local=unlimited_level_price_pool3;
                }else if(pool==4){
                    level_price_local=unlimited_level_price_pool4;
                }else if(pool==5){
                    level_price_local=unlimited_level_price_pool5;
                }else if(pool==6){
                    level_price_local=unlimited_level_price_pool6;
                }else if(pool==7){
                    level_price_local=unlimited_level_price_pool7;
                }else if(pool==8){
                    level_price_local=unlimited_level_price_pool8;
                }else if(pool==9){
                    level_price_local=unlimited_level_price_pool9;
                }else if(pool==10){
                    level_price_local=unlimited_level_price_pool10;
                }
            }
            else{
                if(pool==1){
                    level_price_local=LEVEL_PRICE_POOL1[_level];
                }else if(pool==2){
                    level_price_local=LEVEL_PRICE_POOL2[_level];
                }else if(pool==3){
                    level_price_local=LEVEL_PRICE_POOL3[_level];
                }else if(pool==4){
                    level_price_local=LEVEL_PRICE_POOL4[_level];
                }else if(pool==5){
                    level_price_local=LEVEL_PRICE_POOL5[_level];
                }else if(pool==6){
                    level_price_local=LEVEL_PRICE_POOL6[_level];
                }else if(pool==7){
                    level_price_local=LEVEL_PRICE_POOL7[_level];
                }else if(pool==8){
                    level_price_local=LEVEL_PRICE_POOL8[_level];
                }else if(pool==9){
                    level_price_local=LEVEL_PRICE_POOL9[_level];
                }else if(pool==10){
                    level_price_local=LEVEL_PRICE_POOL10[_level];
                }
            }
            if(address(this).balance > level_price_local) 
                users[referer].poolRefIncome = users[referer].poolRefIncome + level_price_local;
                sent = address(uint160(referer)).send(level_price_local);
            if (sent) {
                emit getMoneyForPoolLevelEvent(referer, msg.sender,_level,pool,level_price_local,block.timestamp);
                if(_level < 100 && users[referer].referrerID >= 1){
                    payPoolReferral(_level+1,referer, pool, amount);
                }
                else
                {
                    sendBalance();
                }
            }
        if(!sent) {
            payPoolReferral(_level, referer, pool,amount);
        }
     }
   
       function buyPool1() public payable {
           require(!pool1PauseFlag,"Buy Pool is stopped for while");
           require(users[msg.sender].isExist, "User Not Registered");
            require(msg.value == pool1_price, 'Incorrect Value');
           
            PoolUserStruct memory userStruct;
            address pool1Currentuser=pool1userList[pool1activeUserID];
            
            pool1currUserID++;
    
            if(pool1users[msg.sender].isExist){
                require(pool1users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool2users[msg.sender].isExist);
                userStruct = pool1users[msg.sender];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool1currUserID;
            }else{
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool1currUserID,
                    payment_received:0,
                    cycle:0
                });                
            }
       
           pool1users[msg.sender] = userStruct;
           pool1userList[pool1currUserID]=msg.sender;
           
           bool sent = false;
           sent = address(uint160(pool1Currentuser)).send((pool1_price * 90)/100);
                if (sent) {
                    
                    payPoolReferral(1, msg.sender, 1, pool1_price/10);
                    
                    pool1users[pool1Currentuser].payment_received+=1;
                    if(pool1users[pool1Currentuser].payment_received>=3)
                    {
                        pool1activeUserID+=1;
                    }
                    emit getPoolPayment(msg.sender,pool1Currentuser, 1,(pool1_price * 90)/100, now);
                }
           emit regPoolEntry(msg.sender, 1,pool1_price, now);
        }
    
    
      function buyPool2() public payable {
        require(!pool2PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool2_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
         
        PoolUserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];
        
        pool2currUserID++;
        
        if(pool2users[msg.sender].isExist){
            require(pool2users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool3users[msg.sender].isExist);
            userStruct = pool2users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool2currUserID;
        }else{
            require(pool1users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool2currUserID,
                payment_received:0,
                cycle:0
            });                
        }
        
      pool2users[msg.sender] = userStruct;
      pool2userList[pool2currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool2Currentuser)).send((pool2_price * 90)/100);

            if (sent) {
                payPoolReferral(1, msg.sender, 2, pool2_price/10);
                
                pool2users[pool2Currentuser].payment_received+=1;
                if(pool2users[pool2Currentuser].payment_received>=3)
                {
                    pool2activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool2Currentuser, 2,(pool2_price * 90)/100, now);
            }
            emit regPoolEntry(msg.sender,2,pool2_price, now);
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
         tsObj = TronStorm(_addr);
         return true;
     }
     
     function changePauseFlag(uint flag) onlyOwner public returns(bool) {
         if(flag==1){
             pausedFlag=true;
         }else if(flag==0){
             pausedFlag=false;
         }
         return true;
     }
     
     function changePoolPauseFlag(uint pool,uint flag) onlyOwner public returns(bool) {
         if(pool==1){
            if(flag==1){
                pool1PauseFlag=true;
            }else if(flag==0){
                pool1PauseFlag=false;
            }             
         }else if(pool==2){
             if(flag==1){
                pool2PauseFlag=true;
            }else if(flag==0){
                pool2PauseFlag=false;
            } 
         }else if(pool==3){
             if(flag==1){
                pool3PauseFlag=true;
            }else if(flag==0){
                pool3PauseFlag=false;
            } 
         }else if(pool==4){
             if(flag==1){
                pool4PauseFlag=true;
            }else if(flag==0){
                pool4PauseFlag=false;
            } 
         }else if(pool==5){
             if(flag==1){
                pool5PauseFlag=true;
            }else if(flag==0){
                pool5PauseFlag=false;
            } 
         }else if(pool==6){
             if(flag==1){
                pool6PauseFlag=true;
            }else if(flag==0){
                pool6PauseFlag=false;
            } 
         }else if(pool==7){
             if(flag==1){
                pool7PauseFlag=true;
            }else if(flag==0){
                pool7PauseFlag=false;
            } 
         }else if(pool==8){
             if(flag==1){
                pool8PauseFlag=true;
            }else if(flag==0){
                pool8PauseFlag=false;
            } 
         }else if(pool==9){
             if(flag==1){
                pool9PauseFlag=true;
            }else if(flag==0){
                pool9PauseFlag=false;
            } 
         }else if(pool==10){
             if(flag==1){
                pool10PauseFlag=true;
            }else if(flag==0){
                pool10PauseFlag=false;
            } 
         }
         return true;
     }
    
    function buyPoolUpgrade(uint _pool,address _addr) onlyDb public {
        require(users[_addr].isExist, "User Not Registered");
        uint poolPrice = 0;
        PoolUserStruct memory userStruct;
        if(_pool==1){
            poolPrice = pool1_price;
            if(pool1users[_addr].isExist){
                pool1currUserID++;
                require(pool1users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool2users[_addr].isExist);
                userStruct = pool1users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool1currUserID;
            }else{
                revert();               
            }
            pool1users[_addr] = userStruct;
            pool1userList[pool1currUserID]=_addr;
        }else if(_pool==2){
            poolPrice = pool2_price;
            if(pool2users[_addr].isExist){
                pool2currUserID++;
                require(pool2users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool3users[_addr].isExist);
                userStruct = pool2users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool2currUserID;
            }else{
                revert();             
            }
            pool2users[_addr] = userStruct;
            pool2userList[pool2currUserID]=_addr;
        }else if(_pool==3){
            poolPrice = pool3_price;
            if(pool3users[_addr].isExist){
                pool3currUserID++;
                require(pool3users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool4users[_addr].isExist);
                userStruct = pool3users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool3currUserID;
            }else{
                revert();             
            }
            pool3users[_addr] = userStruct;
            pool3userList[pool3currUserID]=_addr;
        }else if(_pool==4){
            poolPrice = pool4_price;
            if(pool4users[_addr].isExist){
                pool4currUserID++;
                require(pool4users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool5users[_addr].isExist);
                userStruct = pool4users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool4currUserID;
            }else{
                revert();             
            }
            pool4users[_addr] = userStruct;
            pool4userList[pool4currUserID]=_addr;
        }else if(_pool==5){
            poolPrice = pool5_price;
            if(pool5users[_addr].isExist){
                pool5currUserID++;
                require(pool5users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool6users[_addr].isExist);
                userStruct = pool5users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool5currUserID;
            }else{
                revert();             
            }
            pool5users[_addr] = userStruct;
            pool5userList[pool5currUserID]=_addr;
        }else if(_pool==6){
            poolPrice = pool6_price;
            if(pool6users[_addr].isExist){
                pool6currUserID++;
                require(pool6users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool7users[_addr].isExist);
                userStruct = pool6users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool6currUserID;
            }else{
                revert();             
            }
            pool6users[_addr] = userStruct;
            pool6userList[pool6currUserID]=_addr;
        }else if(_pool==7){
            poolPrice = pool7_price;
            if(pool7users[_addr].isExist){
                pool7currUserID++;
                require(pool7users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool8users[_addr].isExist);
                userStruct = pool7users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool7currUserID;
            }else{
                revert();             
            }
            pool7users[_addr] = userStruct;
            pool7userList[pool7currUserID]=_addr;
        }else if(_pool==8){
            poolPrice = pool8_price;
            if(pool8users[_addr].isExist){
                pool8currUserID++;
                require(pool8users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool9users[_addr].isExist);
                userStruct = pool8users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool8currUserID;
            }else{
                revert();             
            }
            pool8users[_addr] = userStruct;
            pool8userList[pool8currUserID]=_addr;
        }else if(_pool==9){
            poolPrice = pool9_price;
            if(pool9users[_addr].isExist){
                pool9currUserID++;
                require(pool9users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                require(pool10users[_addr].isExist);
                userStruct = pool9users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool9currUserID;
            }else{
                revert();             
            }
            pool9users[_addr] = userStruct;
            pool9userList[pool9currUserID]=_addr;
        }else if(_pool==10){
            poolPrice = pool10_price;
            if(pool10users[_addr].isExist){
                pool10currUserID++;
                require(pool10users[_addr].payment_received >= 3,"Your previous cycle for payment is pending");
                userStruct = pool10users[_addr];
                userStruct.cycle = userStruct.cycle+1;
                userStruct.payment_received = 0;
                userStruct.id = pool10currUserID;
            }else{
                revert();             
            }
            pool10users[_addr] = userStruct;
            pool10userList[pool10currUserID]=_addr;
        }else{
            revert();
        }
      emit regPoolEntry(_addr,_pool,poolPrice,now);
    }
    
    function newPools(uint nPool, address _addr) onlyOwner public {
        if(nPool>0){
            for(uint i=1;i<=nPool;i++){
                buyPools(i,_addr);
            }
        }else{
            revert();
        }
    }
    
    function buyPools(uint _pool,address _addr) onlyOwner public {
        require(users[_addr].isExist, "User Not Registered");
        uint poolPrice = 0;
        PoolUserStruct memory userStruct;
        if(_pool==1){
            poolPrice = pool1_price;
            if(!pool1users[_addr].isExist){
                pool1currUserID++;
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool1currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();               
            }
            pool1users[_addr] = userStruct;
            pool1userList[pool1currUserID]=_addr;
        }else if(_pool==2){
            poolPrice = pool2_price;
            if(!pool2users[_addr].isExist){
                pool2currUserID++;
                require(pool1users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool2currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool2users[_addr] = userStruct;
            pool2userList[pool2currUserID]=_addr;
        }else if(_pool==3){
            poolPrice = pool3_price;
            if(!pool3users[_addr].isExist){
                pool3currUserID++;
                require(pool2users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool3currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool3users[_addr] = userStruct;
            pool3userList[pool3currUserID]=_addr;
        }else if(_pool==4){
            poolPrice = pool4_price;
            if(!pool4users[_addr].isExist){
                pool4currUserID++;
                require(pool3users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool4currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool4users[_addr] = userStruct;
            pool4userList[pool4currUserID]=_addr;
        }else if(_pool==5){
            poolPrice = pool5_price;
            if(!pool5users[_addr].isExist){
                pool5currUserID++;
                require(pool4users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool5currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool5users[_addr] = userStruct;
            pool5userList[pool5currUserID]=_addr;
        }else if(_pool==6){
            poolPrice = pool6_price;
            if(!pool6users[_addr].isExist){
                pool6currUserID++;
                require(pool4users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool6currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool6users[_addr] = userStruct;
            pool6userList[pool6currUserID]=_addr;
        }else if(_pool==7){
            poolPrice = pool7_price;
            if(!pool7users[_addr].isExist){
                pool7currUserID++;
                require(pool6users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool7currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool7users[_addr] = userStruct;
            pool7userList[pool7currUserID]=_addr;
        }else if(_pool==8){
            poolPrice = pool8_price;
            if(!pool8users[_addr].isExist){
                pool8currUserID++;
                require(pool7users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool8currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool8users[_addr] = userStruct;
            pool8userList[pool8currUserID]=_addr;
        }else if(_pool==9){
            poolPrice = pool9_price;
            if(!pool9users[_addr].isExist){
                pool9currUserID++;
                require(pool8users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool9currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool9users[_addr] = userStruct;
            pool9userList[pool9currUserID]=_addr;
        }else if(_pool==10){
            poolPrice = pool10_price;
            if(!pool10users[_addr].isExist){
                pool10currUserID++;
                require(pool9users[_addr].isExist);
                userStruct = PoolUserStruct({
                    isExist:true,
                    id:pool10currUserID,
                    payment_received:0,
                    cycle:0
                });
            }else{
                revert();             
            }
            pool10users[_addr] = userStruct;
            pool10userList[pool10currUserID]=_addr;
        }else{
            revert();
        }
      emit regPoolEntry(_addr,_pool,poolPrice, now);
    }
    
     function buyPool3() public payable {
         require(!pool3PauseFlag,"Buy Pool is stopped for while");
         require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool3_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];
        
        pool3currUserID++;
        
         if(pool3users[msg.sender].isExist){
            require(pool3users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool4users[msg.sender].isExist);
            userStruct = pool3users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool3currUserID;
        }else{
            require(pool2users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool3currUserID,
                payment_received:0,
                cycle:0
            });                
        }
        
      pool3users[msg.sender] = userStruct;
      pool3userList[pool3currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool3Currentuser)).send((pool3_price * 90)/100);

            if (sent) {
                
                 payPoolReferral(1, msg.sender, 3, pool3_price/10);
                
                pool3users[pool3Currentuser].payment_received+=1;
                if(pool3users[pool3Currentuser].payment_received>=3)
                {
                    pool3activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool3Currentuser, 3,(pool3_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,3,pool3_price, now);
    }
    
    
    function buyPool4() public payable {
        require(!pool4PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool4_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
      
        PoolUserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];
        
        pool4currUserID++;
        
        if(pool4users[msg.sender].isExist){
            require(pool4users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool5users[msg.sender].isExist);
            userStruct = pool4users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool4currUserID;
        }else{
            require(pool3users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool4currUserID,
                payment_received:0,
                cycle:0
            });                
        }
        
      pool4users[msg.sender] = userStruct;
      pool4userList[pool4currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool4Currentuser)).send((pool4_price * 90)/100);

            if (sent) {
                
                payPoolReferral(1, msg.sender, 4, pool4_price/10);
                
                pool4users[pool4Currentuser].payment_received+=1;
                if(pool4users[pool4Currentuser].payment_received>=3)
                {
                    pool4activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool4Currentuser, 4,(pool4_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,4,pool4_price, now);
    }
    
    
    
    function buyPool5() public payable {
        require(!pool5PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool5_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];
        
        pool5currUserID++;
        if(pool5users[msg.sender].isExist){
            require(pool5users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool6users[msg.sender].isExist);
            userStruct = pool5users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool5currUserID;
        }else{
            require(pool4users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool5currUserID,
                payment_received:0,
                cycle:0
            });                
        }
        
      pool5users[msg.sender] = userStruct;
      pool5userList[pool5currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool5Currentuser)).send((pool5_price * 90)/100);

            if (sent) {
                
                payPoolReferral(1, msg.sender, 5, pool5_price/10);
                
                pool5users[pool5Currentuser].payment_received+=1;
                if(pool5users[pool5Currentuser].payment_received>=3)
                {
                    pool5activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool5Currentuser, 5,(pool5_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,5,pool5_price,  now);
    }
    
    function buyPool6() public payable {
        require(!pool6PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool6_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];
        
        pool6currUserID++;
        if(pool6users[msg.sender].isExist){
            require(pool6users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool7users[msg.sender].isExist);
            userStruct = pool6users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool6currUserID;
        }else{
            require(pool5users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool6currUserID,
                payment_received:0,
                cycle:0
            });                
        }
      pool6users[msg.sender] = userStruct;
      pool6userList[pool6currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool6Currentuser)).send((pool6_price * 90)/100);

            if (sent) {
                
                payPoolReferral(1, msg.sender, 6, pool6_price/10);
                
                pool6users[pool6Currentuser].payment_received+=1;
                if(pool6users[pool6Currentuser].payment_received>=3)
                {
                    pool6activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool6Currentuser, 6,(pool6_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,6,pool6_price,  now);
    }
    
    function buyPool7() public payable {
        require(!pool7PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool7_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool7Currentuser=pool7userList[pool7activeUserID];
        
        pool7currUserID++;
        if(pool7users[msg.sender].isExist){
            require(pool7users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool8users[msg.sender].isExist);
            userStruct = pool7users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool7currUserID;
        }else{
            require(pool6users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool7currUserID,
                payment_received:0,
                cycle:0
            });                
        }
      pool7users[msg.sender] = userStruct;
      pool7userList[pool7currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool7Currentuser)).send((pool7_price * 90)/100);

            if (sent) {
                
                payPoolReferral(1, msg.sender, 7, pool7_price/10);
                
                pool7users[pool7Currentuser].payment_received+=1;
                if(pool7users[pool7Currentuser].payment_received>=3)
                {
                    pool7activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool7Currentuser, 7,(pool7_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,7,pool7_price,  now);
    }
    
    
    function buyPool8() public payable {
        require(!pool8PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool8_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
       
        PoolUserStruct memory userStruct;
        address pool8Currentuser=pool8userList[pool8activeUserID];
        
        pool8currUserID++;
        if(pool8users[msg.sender].isExist){
            require(pool8users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool9users[msg.sender].isExist);
            userStruct = pool8users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool8currUserID;
        }else{
            require(pool7users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool8currUserID,
                payment_received:0,
                cycle:0
            });                
        }
      pool8users[msg.sender] = userStruct;
      pool8userList[pool8currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool8Currentuser)).send((pool8_price * 90)/100);

            if (sent) {
                
                payPoolReferral(1, msg.sender, 8, pool8_price/10);
                
                pool8users[pool8Currentuser].payment_received+=1;
                if(pool8users[pool8Currentuser].payment_received>=3)
                {
                    pool8activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool8Currentuser, 8,(pool8_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,8,pool8_price,  now);
    }
    
    
    
    function buyPool9() public payable {
        require(!pool9PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool9_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
       
        PoolUserStruct memory userStruct;
        address pool9Currentuser=pool9userList[pool9activeUserID];
        
        pool9currUserID++;
        if(pool9users[msg.sender].isExist){
            require(pool9users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            require(pool10users[msg.sender].isExist);
            userStruct = pool9users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool9currUserID;
        }else{
            require(pool8users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool9currUserID,
                payment_received:0,
                cycle:0
            });                
        }
      pool9users[msg.sender] = userStruct;
      pool9userList[pool9currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool9Currentuser)).send((pool9_price * 90)/100);

            if (sent) {
                
                payPoolReferral(1, msg.sender, 9, pool9_price/10);
                
                pool9users[pool9Currentuser].payment_received+=1;
                if(pool9users[pool9Currentuser].payment_received>=3)
                {
                    pool9activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool9Currentuser, 9,(pool9_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender,9,pool9_price,  now);
    }
    
    
    function buyPool10() public payable {
        require(!pool10PauseFlag,"Buy Pool is stopped for while");
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool10_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool10Currentuser=pool10userList[pool10activeUserID];
        
        pool10currUserID++;
        if(pool10users[msg.sender].isExist){
            require(pool10users[msg.sender].payment_received >= 3,"Your previous cycle for payment is pending");
            userStruct = pool10users[msg.sender];
            userStruct.cycle = userStruct.cycle+1;
            userStruct.payment_received = 0;
            userStruct.id = pool10currUserID;
        }else{
            require(pool9users[msg.sender].isExist);
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool10currUserID,
                payment_received:0,
                cycle:0
            });                
        }
      pool10users[msg.sender] = userStruct;
      pool10userList[pool10currUserID]=msg.sender;
       
      bool sent = false;
      sent = address(uint160(pool10Currentuser)).send((pool10_price * 90)/100);

            if (sent) {
                payPoolReferral(1, msg.sender, 10, pool10_price/10);
                
                pool10users[pool10Currentuser].payment_received+=1;
                if(pool10users[pool10Currentuser].payment_received>=3)
                {
                    pool10activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool10Currentuser, 10,(pool10_price * 90)/100, now);
            }
        emit regPoolEntry(msg.sender, 10,pool10_price, now);
    }
    
    function getTRXBalance() public view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalancePoolRef(uint amount) private {
         if (!address(uint160(ownerWallet)).send(amount))
         {
             
         }
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
                (bool isExist,uint id,uint refId,uint refUCount,uint refInc,uint pRefInc) = tsObj.users(uAddr);
                if(isExist){
                    UserStruct memory userStruct;
                    currUserID++;
                    userStruct = UserStruct({
                         pk:currUserID,
                         isExist: true,
                         id: id,
                         referrerID: refId,
                         referredUsers:refUCount,
                         refIncome:refInc,
                         poolRefIncome:pRefInc
                    });
             
                    users[uAddr] = userStruct;
                    userList[id]=uAddr;
                    userListSeq[currUserID]=uAddr;
                    if(refId>0){
                        uRefArr[refId].push(id);    
                        emit regLevelEvent(uAddr, userList[refId],REGESTRATION_FEES, now); 
                    }else{
                        emit regLevelEvent(uAddr, 0,REGESTRATION_FEES, now); 
                    }
                }  
                saveOldPoolData(1,uAddr);
                saveOldPoolData(2,uAddr);
                saveOldPoolData(3,uAddr);
                saveOldPoolData(5,uAddr);
                saveOldPoolData(6,uAddr);
                saveOldPoolData(7,uAddr);
                saveOldPoolData(8,uAddr);
                saveOldPoolData(9,uAddr);
                saveOldPoolData(10,uAddr);
            }
        }
        return true;
    }
    
    function saveOldPoolData(uint pool, address addr) public onlyOwner returns(bool){
        if(users[addr].isExist){
            PoolUserStruct memory userStruct;
            (bool isExist,uint pId, uint pymnt,uint cycle) = (false,0,0,0);
            if(pool==1){
                (isExist,pId,pymnt,cycle) = tsObj.pool1users(addr);
                if(isExist && !pool1users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool1users[addr] = userStruct;
                    pool1userList[pId]=addr;
                    emit regPoolEntry(addr,1,pool1_price,  now);
                }
            }else if(pool==2){
                (isExist,pId,pymnt,cycle) = tsObj.pool2users(addr);
                if(isExist && !pool2users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool2users[addr] = userStruct;
                    pool2userList[pId]=addr;
                    emit regPoolEntry(addr,2,pool2_price,  now);
                }
            }else if(pool==3){
                (isExist,pId,pymnt,cycle) = tsObj.pool3users(addr);
                if(isExist && !pool3users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool3users[addr] = userStruct;
                    pool3userList[pId]=addr;
                    emit regPoolEntry(addr,3,pool3_price,  now);
                }
            }else if(pool==5){
                (isExist,pId,pymnt,cycle) = tsObj.pool5users(addr);
                if(isExist && !pool5users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool5users[addr] = userStruct;
                    pool5userList[pId]=addr;
                    emit regPoolEntry(addr,5,pool5_price,  now);
                }
            }else if(pool==6){
                (isExist,pId,pymnt,cycle) = tsObj.pool6users(addr);
                if(isExist && !pool6users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool6users[addr] = userStruct;
                    pool6userList[pId]=addr;
                    emit regPoolEntry(addr,6,pool6_price,  now);
                }
            }else if(pool==7){
                (isExist,pId,pymnt,cycle) = tsObj.pool7users(addr);
                if(isExist && !pool7users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool7users[addr] = userStruct;
                    pool7userList[pId]=addr;
                    emit regPoolEntry(addr,7,pool7_price,  now);
                }
            }else if(pool==8){
                (isExist,pId,pymnt,cycle) = tsObj.pool8users(addr);
                if(isExist && !pool8users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool8users[addr] = userStruct;
                    pool8userList[pId]=addr;
                    emit regPoolEntry(addr,8,pool8_price,  now);
                }
            }else if(pool==9){
                (isExist,pId,pymnt,cycle) = tsObj.pool9users(addr);
                if(isExist && !pool9users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool9users[addr] = userStruct;
                    pool9userList[pId]=addr;
                    emit regPoolEntry(addr,9,pool9_price,  now);
                }
            }else if(pool==10){
                (isExist,pId,pymnt,cycle) = tsObj.pool10users(addr);
                if(isExist && !pool10users[addr].isExist){
                    userStruct = PoolUserStruct({
                        isExist:true,
                        id:pId,
                        payment_received:pymnt,
                        cycle:cycle
                    });                
                    pool10users[addr] = userStruct;
                    pool10userList[pId]=addr;
                    emit regPoolEntry(addr,10,pool10_price,  now);
                }
            }            
        }
    }
    
    function pool4ActiveCurIdSave(uint actId,uint curId) public onlyOwner returns(bool){
        if(actId>0 && curId>0){
            pool4activeUserID = actId;
            pool4currUserID = curId;
        }else{
            revert();
        }
    }
    
    function pool4DataSave(uint id, address addr) public onlyOwner returns(bool){
        (bool isExist,,uint pymnt,uint cycle) = tsObj.pool4users(addr);
        if(isExist){
            PoolUserStruct memory userStruct = PoolUserStruct({
                isExist:true,
                id:id,
                payment_received:pymnt,
                cycle:cycle
            });                
            pool4users[addr] = userStruct;
            pool4userList[id]=addr;
            emit regPoolEntry(addr,4,pool4_price,  now);
        }
    }
   
   
}

contract TronStorm {
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
      
      
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint referredUsers;
        uint refIncome;
        uint poolRefIncome;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
       uint cycle;
    }
    
    address crtr;
    
    mapping(uint => uint[]) public uRefArr;
    
    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
     
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
     
     address dbOwner;
     
}