/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

pragma solidity 0.5.14;

contract PoolVine {
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

      uint public pool1CurrentLevel=0;
      uint public pool2CurrentLevel=0;
      uint public pool3CurrentLevel=0;
      uint public pool4CurrentLevel=0;
      uint public pool5CurrentLevel=0;
      uint public pool6CurrentLevel=0;
      
      
      uint public unlimited_level_price=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint co_referrerID;
        uint referredUsers;
        uint co_referredUsers;
        address catchAndThrow;
        uint catchAndThrowReceived;
        uint income;
        uint batchPaid;
        uint autoPoolPayReceived;
        uint missedPoolPayment;
        address autopoolPayReciever;
        uint levelIncomeReceived;
        mapping(uint => uint) levelExpired;
      }
    
      
      // MATRIX CONFIG FOR AUTO-POOL FUND
      uint public batchSize;
      uint public height;

      struct Pool1UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool2UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool3UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool4UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool5UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool6UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
      }
    
      // USERS   
      mapping (address => UserStruct) public users;
      mapping (uint => address) public userList;
     



     mapping (address => Pool1UserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
     
     mapping (address => Pool2UserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
     
     mapping (address => Pool3UserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
     
     mapping (address => Pool4UserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
     
     mapping (address => Pool5UserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
     
     mapping (address => Pool6UserStruct) public pool6users;
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
     
    mapping(uint => uint) public LEVEL_PRICE;
    
   uint public REGESTRATION_FESS;
   uint pool1_price;
   uint pool2_price;
   uint pool3_price=7500000000;
   uint pool4_price=12500000000;
   uint pool5_price=20000000000;
   uint pool6_price=35000000000;
   uint pool7_price=60000000000;
   uint pool8_price=100000000000;
   uint pool9_price=150000000000;
   uint pool10_price=200000000000;
   uint pool11_price=300000000000;
   uint pool12_price=500000000000;
   
   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
     event CoReferrerPayment(address indexed _user, address indexed _referral, uint _time);

     event regPoolEntry(address indexed _user,uint _level,   uint _time);
     event regPool2Entry(address indexed _user,uint _level,   uint _time);
     event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
     event getPool2Payment(address indexed _user,address indexed _receiver, uint _level, uint _time);
     event successfulPay(string str, address sender, uint level, address referrer);
     event autoPoolEvent(string str1,address sender, address referrer, uint height, uint time);

    UserStruct[] public requests;
     uint public pay_co_ref;
     uint public pay_evn_odd;
     uint public pay_autopool;

      constructor() public {
          ownerWallet = msg.sender;
          REGESTRATION_FESS = 1000000000;
          batchSize = 2;
          height = 5;

           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 5 / 20;
           pay_co_ref = REGESTRATION_FESS / 5;
           pay_evn_odd = REGESTRATION_FESS / 5;           
           unlimited_level_price=REGESTRATION_FESS / 5 / 20;
           pay_autopool = REGESTRATION_FESS / 5 / height;
           pool1_price = REGESTRATION_FESS * 2;
           pool2_price = REGESTRATION_FESS * 4;
           
           
           
           UserStruct memory userStruct;
           currUserID++;

           userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                referrerID: 0,
                co_referrerID: 0, 
                referredUsers:0,
                co_referredUsers:0,
                catchAndThrow : ownerWallet,
                catchAndThrowReceived : 0,
                income : 0,
                batchPaid : 0,
                autoPoolPayReceived : 0,
                missedPoolPayment : 0,
                autopoolPayReciever : ownerWallet,
                levelIncomeReceived : 0
           });
            
          users[ownerWallet] = userStruct;
          userList[currUserID] = ownerWallet;
         
       
          Pool1UserStruct memory pool1userStruct;
          Pool2UserStruct memory pool2userStruct;
          Pool3UserStruct memory pool3userStruct;
          Pool4UserStruct memory pool4userStruct;
          Pool5UserStruct memory pool5userStruct;
          Pool6UserStruct memory pool6userStruct;
          
          PoolUserStruct memory pooluserStruct;
          
          
              
          pool1currUserID++;

        pool1userStruct = Pool1UserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool1CurrentLevel,
            mostright:true
        });
        pool1CurrentLevel++;
    pool1activeUserID=pool1currUserID;
       pool1users[msg.sender] = pool1userStruct;
       pool1userList[pool1currUserID]=msg.sender;
      
        
        pool2currUserID++;

        pool2userStruct = Pool2UserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool2CurrentLevel,
            mostright:true
        });
        pool2CurrentLevel++;
    pool2activeUserID=pool2currUserID;
       pool2users[msg.sender] = pool2userStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       
         pool3currUserID++;

        pool3userStruct = Pool3UserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool3CurrentLevel,
            mostright:true
        });
        pool3CurrentLevel++;
    pool3activeUserID=pool3currUserID;
       pool3users[msg.sender] = pool3userStruct;
       pool3userList[pool3currUserID]=msg.sender;
       
       
       
         pool4currUserID++;

        pool4userStruct = Pool4UserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool4CurrentLevel,
            mostright:true
        });
        pool4CurrentLevel++;
    pool4activeUserID=pool4currUserID;
       pool4users[msg.sender] = pool4userStruct;
       pool4userList[pool4currUserID]=msg.sender;
       
       
        
     pool5currUserID++;

        pool5userStruct = Pool5UserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool5CurrentLevel,
            mostright:true
        });
        pool5CurrentLevel++;
    pool5activeUserID=pool5currUserID;
       pool5users[msg.sender] = pool5userStruct;
       pool5userList[pool5currUserID]=msg.sender;   
       
         
          pool6currUserID++;

        pool6userStruct = Pool6UserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool6CurrentLevel,
            mostright:true
        });
        pool6CurrentLevel++;
    pool6activeUserID=pool6currUserID;
       pool6users[msg.sender] = pool6userStruct;
       pool6userList[pool6currUserID]=msg.sender;
       
         pool7currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0
        });
    pool7activeUserID=pool7currUserID;
       pool7users[msg.sender] = pooluserStruct;
       pool7userList[pool7currUserID]=msg.sender;
       
       pool8currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0
        });
    pool8activeUserID=pool8currUserID;
       pool8users[msg.sender] = pooluserStruct;
       pool8userList[pool8currUserID]=msg.sender;
       
        pool9currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0
        });
    pool9activeUserID=pool9currUserID;
       pool9users[msg.sender] = pooluserStruct;
       pool9userList[pool9currUserID]=msg.sender;
       
       
        pool10currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0
        });
    pool10activeUserID=pool10currUserID;
       pool10users[msg.sender] = pooluserStruct;
       pool10userList[pool10currUserID]=msg.sender;
       
       
       pool11currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool11currUserID,
            payment_received:0
       
      });
      pool11activeUserID=pool11currUserID;
       pool11users[msg.sender] = pooluserStruct;
       pool11userList[pool11currUserID]=msg.sender;
       
       
       pool12currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool12currUserID,
            payment_received:0
       
      });
      pool12activeUserID=pool12currUserID;
       pool12users[msg.sender] = pooluserStruct;
       pool12userList[pool12currUserID]=msg.sender;
       
       
       
       
      }
     
     modifier onlyOwner(){
         require(msg.sender==ownerWallet,"Only Owner can access this function.");
         _;
     }
     function setRegistrationFess(uint fess) public onlyOwner{
           REGESTRATION_FESS = fess;
           REGESTRATION_FESS = REGESTRATION_FESS * (10 ** 18);
           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 5 / 20;
           pay_co_ref = REGESTRATION_FESS / 5;
           pay_evn_odd = REGESTRATION_FESS / 5; 
           pay_autopool = REGESTRATION_FESS / 5 / height;
           unlimited_level_price=REGESTRATION_FESS / 5 / 20;
           pool1_price = REGESTRATION_FESS * 2;
           pool2_price = REGESTRATION_FESS * 4;
     }

     function setBatchSize(uint _batch) public{
        batchSize = _batch;
     }

     function setHeight(uint _height) public{
        height = _height;
     }

     function getRegistrationFess() public view returns(uint){
         return REGESTRATION_FESS;
     }
       function regUser(uint co_referrer,uint _referrerID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
      require(co_referrer > 0 && co_referrer <= currUserID, 'Incorrect referral ID');
      require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
      
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            co_referrerID: co_referrer,   
            referredUsers:0,
            co_referredUsers:0,
            catchAndThrow : address(0),
            catchAndThrowReceived : 0,
            income : 0,
            batchPaid : 0,
            autoPoolPayReceived : 0,
            missedPoolPayment : 0,
            autopoolPayReciever : address(0),
            levelIncomeReceived : 0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        

        users[userList[users[msg.sender].co_referrerID]].co_referredUsers=users[userList[users[msg.sender].co_referrerID]].co_referredUsers+1;
        

        checkEvenOrOdd(msg.sender);
        payToCoReferrer(3,msg.sender);     
        autoPool(msg.sender);            
        payReferral(1,msg.sender);
        
        
        
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
     
     bool ownerPaid;
     function heightPayment(address _user,uint batch,uint id,uint h) internal{
        bool sent = false;
       
        if((users[userList[id]].autopoolPayReciever != address(0)) && (userList[batch] != users[userList[id]].autopoolPayReciever) && (h <= height && h<=2 && id > 0 && ownerPaid!=true)) {
            
            address nextLevel = userList[id];
            sent = address(uint160(nextLevel)).send(pay_autopool);   
            users[userList[id]].income = users[userList[id]].income + pay_autopool;
            users[userList[id]].autoPoolPayReceived = users[userList[id]].autoPoolPayReceived + 1;
            
            if(id==1){
              ownerPaid = true;
            }            
            if(sent){
                 emit autoPoolEvent("Auto-Pool Payment Successful",_user,nextLevel,h,now);
            }
            id = users[users[userList[id]].autopoolPayReciever].id;
            heightPayment(_user,batch,id,h+1);
            
        }else{
              if((h > 2 && h <= height) && users[userList[id]].co_referredUsers>=1 
              && (id > 0 && ownerPaid!=true)){
                    
                    address nextLevel = userList[id];
                    sent = address(uint160(nextLevel)).send(pay_autopool);   
                    users[userList[id]].income = users[userList[id]].income + pay_autopool;
                    users[userList[id]].autoPoolPayReceived = users[userList[id]].autoPoolPayReceived + 1;
                    

                    if(id==1){
                        ownerPaid = true;
                    }   
                    if(sent){
                      emit autoPoolEvent("Auto-Pool Payment Successful",_user,nextLevel,h,now);
                    }

                    id = users[users[userList[id]].autopoolPayReciever].id;
                    heightPayment(_user,batch,id,h+1);   
              }
              
              else if(id>0 && h<=height && ownerPaid!=true){
                  if(id==1){
                        ownerPaid = true;
                  }
                  users[userList[id]].missedPoolPayment = users[userList[id]].missedPoolPayment +1;
                  id = users[users[userList[id]].autopoolPayReciever].id;
                  heightPayment(_user,batch,id,h+1);
              }
              
        }



     }
     
     function autoPool(address _user) internal {
        bool sent = false;
        ownerPaid = false;
        uint i;  
        for(i = 1; i < currUserID; i++){
            if(users[userList[i]].batchPaid < batchSize){

                sent = address(uint160(userList[i])).send(pay_autopool);   
                users[userList[i]].batchPaid = users[userList[i]].batchPaid + 1;
                users[_user].autopoolPayReciever = userList[i];
                users[userList[i]].income = users[userList[i]].income + pay_autopool;
                users[userList[i]].autoPoolPayReceived = users[userList[i]].autoPoolPayReceived + 1;
                
                if(sent){
                 emit autoPoolEvent("Auto-Pool Payment Successful",_user,userList[i],1,now);
                }
                 
                uint heightCounter = 2;
                uint  temp = users[users[userList[i]].autopoolPayReciever].id;
                heightPayment(_user,i,temp,heightCounter);

                
                i = currUserID;    
            }
        }
      }
     

     function payToCoReferrer(uint _level, address _user) internal{
        address co_referrer;
        co_referrer = userList[users[_user].co_referrerID];
        bool sent = false;
        uint level_price_local=0;
        
        if(_level==3){
             level_price_local = pay_co_ref;
        }
        
        sent = address(uint160(co_referrer)).send(level_price_local);
        users[userList[users[_user].co_referrerID]].income = users[userList[users[_user].co_referrerID]].income + level_price_local;

        
        if(sent){
            emit CoReferrerPayment(co_referrer, msg.sender, now);
        }
  
     }

     

     function checkEvenOrOdd(address _user) internal{
        address referer;
        referer = userList[users[_user].referrerID];
        address first_ref = users[userList[users[_user].referrerID]].catchAndThrow;
        uint number = users[userList[users[_user].referrerID]].referredUsers;
        bool sent;

        if(number%2 == 0){
          
          sent = address(uint160(first_ref)).send(pay_evn_odd);
          users[first_ref].income = users[first_ref].income + pay_evn_odd;
          users[first_ref].catchAndThrowReceived = users[first_ref].catchAndThrowReceived + 1;
          users[_user].catchAndThrow = first_ref;
          
          if(sent){
            emit successfulPay("Successfully pay to the even referrer",_user,users[first_ref].catchAndThrowReceived,first_ref);
          }
        }else{
          sent = address(uint160(referer)).send(pay_evn_odd);
          users[userList[users[_user].referrerID]].income = users[userList[users[_user].referrerID]].income + pay_evn_odd;
          users[userList[users[_user].referrerID]].catchAndThrowReceived = users[userList[users[_user].referrerID]].catchAndThrowReceived + 1;            
          users[_user].catchAndThrow = referer;
        
          if(sent){
           emit successfulPay("Successfully pay to the odd referrer",_user,users[referer].catchAndThrowReceived,referer);
          }
        } 
        

       
     }

    
     function payReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].referrerID];
       
       
         bool sent = false;
       
            uint level_price_local=0;
            if(_level>2){
            level_price_local=unlimited_level_price;
            }
            else{
            level_price_local=LEVEL_PRICE[_level];
            }
            sent = address(uint160(referer)).send(level_price_local);
            users[referer].levelIncomeReceived = users[referer].levelIncomeReceived +1; 
            users[userList[users[_user].referrerID]].income = users[userList[users[_user].referrerID]].income + level_price_local;

        
            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
                if(_level < 20 && users[referer].referrerID >= 1){
                    payReferral(_level+1,referer);
                }
                
                else
                {
                    sendBalance();
                }
               
            }
       
        if(!sent) {
          //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payReferral(_level, referer);
        }

     }
   
   
   
       function buyPool1() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool1users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool1_price, 'Incorrect Value');
        
        Pool1UserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];        
        pool1currUserID++;
        uint currentlevel=pool1CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool1users[pool1Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool1Currentuser)).send(pool1_price);
            pool1users[pool1Currentuser].payment_received+=1;
            userparent=pool1Currentuser;
            level=pool1CurrentLevel-pool1users[pool1Currentuser].level;
            emit getPoolPayment(msg.sender,pool1Currentuser, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool1users[pool1Currentuser].parent)).send(pool1_price);
            pool1users[pool1Currentuser].payment_received+=1;
            userparent=pool1users[pool1Currentuser].parent;
            level=pool1CurrentLevel - pool1users[pool1users[pool1Currentuser].parent].level;
            emit getPoolPayment(msg.sender,pool1users[pool1Currentuser].parent, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        if(pool1users[pool1Currentuser].payment_received>=4 && pool1users[pool1Currentuser].mostright){
             pool1activeUserID+=1;
             mostRight=true;
             pool1CurrentLevel++;
        }
        else if(pool1users[pool1Currentuser].payment_received>=4)
                {
                    pool1activeUserID+=1;
                }

         userStruct = Pool1UserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
    }
    
    
       function buyPool2() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool2users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool2_price, 'Incorrect Value');
        Pool2UserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];        
        pool2currUserID++;
        uint currentlevel=pool2CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool2users[pool2Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool2Currentuser)).send(pool2_price);
            pool2users[pool2Currentuser].payment_received+=1;
            userparent=pool2Currentuser;
            level=pool2CurrentLevel-pool2users[pool2Currentuser].level;
            emit getPool2Payment(msg.sender,pool2Currentuser, level, now);
            emit regPool2Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool2users[pool2Currentuser].parent)).send(pool2_price);
            pool2users[pool2Currentuser].payment_received+=1;
            userparent=pool2users[pool2Currentuser].parent;
            level=pool2CurrentLevel - pool2users[pool1users[pool2Currentuser].parent].level;
            emit getPool2Payment(msg.sender,pool2users[pool2Currentuser].parent, level, now);
            emit regPool2Entry(msg.sender, level, now);
            }
        if(pool2users[pool2Currentuser].payment_received>=4 && pool2users[pool2Currentuser].mostright){
             pool2activeUserID+=1;
             mostRight=true;
             pool2CurrentLevel++;
        }
        else if(pool2users[pool2Currentuser].payment_received>=4)
                {
                    pool2activeUserID+=1;
                }

         userStruct = Pool2UserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool2users[msg.sender] = userStruct;
       pool2userList[pool2currUserID]=msg.sender;
    }
    
    
    
    
     function buyPool3() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool3users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool3_price, 'Incorrect Value');
        Pool3UserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];        
        pool3currUserID++;
        uint currentlevel=pool3CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool3users[pool3Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool3Currentuser)).send(pool3_price);
            pool3users[pool3Currentuser].payment_received+=1;
            userparent=pool3Currentuser;
            level=pool3CurrentLevel-pool3users[pool3Currentuser].level;
            emit getPoolPayment(msg.sender,pool3Currentuser, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool3users[pool3Currentuser].parent)).send(pool3_price);
            pool3users[pool3Currentuser].payment_received+=1;
            userparent=pool3users[pool3Currentuser].parent;
            level=pool3CurrentLevel - pool3users[pool3users[pool3Currentuser].parent].level;
            emit getPoolPayment(msg.sender,pool3users[pool3Currentuser].parent, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        if(pool3users[pool3Currentuser].payment_received>=4 && pool3users[pool3Currentuser].mostright){
             pool3activeUserID+=1;
             mostRight=true;
             pool3CurrentLevel++;
        }
        else if(pool3users[pool3Currentuser].payment_received>=4)
                {
                    pool3activeUserID+=1;
                }

         userStruct = Pool3UserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool3users[msg.sender] = userStruct;
       pool3userList[pool3currUserID]=msg.sender;
    }
    
    
    
    function buyPool4() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool4users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool4_price, 'Incorrect Value');
        Pool4UserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];        
        pool4currUserID++;
        uint currentlevel=pool4CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool4users[pool4Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool4Currentuser)).send(pool4_price);
            pool4users[pool4Currentuser].payment_received+=1;
            userparent=pool4Currentuser;
            level=pool4CurrentLevel-pool4users[pool4Currentuser].level;
            emit getPoolPayment(msg.sender,pool4Currentuser, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool4users[pool4Currentuser].parent)).send(pool4_price);
            pool4users[pool4Currentuser].payment_received+=1;
            userparent=pool4users[pool4Currentuser].parent;
            level=pool4CurrentLevel - pool4users[pool4users[pool4Currentuser].parent].level;
            emit getPoolPayment(msg.sender,pool4users[pool4Currentuser].parent, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        if(pool4users[pool4Currentuser].payment_received>=4 && pool4users[pool4Currentuser].mostright){
             pool4activeUserID+=1;
             mostRight=true;
             pool4CurrentLevel++;
        }
        else if(pool4users[pool4Currentuser].payment_received>=4)
                {
                    pool4activeUserID+=1;
                }

         userStruct = Pool4UserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool4users[msg.sender] = userStruct;
       pool4userList[pool1currUserID]=msg.sender;
    }
    
    
    
    
    function buyPool5() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool5users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool5_price, 'Incorrect Value');
        Pool5UserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];        
        pool5currUserID++;
        uint currentlevel=pool5CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool5users[pool5Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool5Currentuser)).send(pool5_price);
            pool5users[pool5Currentuser].payment_received+=1;
            userparent=pool5Currentuser;
            level=pool5CurrentLevel-pool5users[pool5Currentuser].level;
            emit getPoolPayment(msg.sender,pool5Currentuser, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool5users[pool5Currentuser].parent)).send(pool5_price);
            pool5users[pool5Currentuser].payment_received+=1;
            userparent=pool5users[pool5Currentuser].parent;
            level=pool5CurrentLevel - pool5users[pool5users[pool5Currentuser].parent].level;
            emit getPoolPayment(msg.sender,pool5users[pool5Currentuser].parent, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        if(pool5users[pool5Currentuser].payment_received>=4 && pool5users[pool5Currentuser].mostright){
             pool5activeUserID+=1;
             mostRight=true;
             pool5CurrentLevel++;
        }
        else if(pool5users[pool5Currentuser].payment_received>=4)
                {
                    pool5activeUserID+=1;
                }

         userStruct = Pool5UserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool5users[msg.sender] = userStruct;
       pool5userList[pool5currUserID]=msg.sender;
    }
    
    
    
function buyPool6() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool6users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool6_price, 'Incorrect Value');
        Pool6UserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];        
        pool6currUserID++;
        uint currentlevel=pool6CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool6users[pool6Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool6Currentuser)).send(pool6_price);
            pool6users[pool6Currentuser].payment_received+=1;
            userparent=pool6Currentuser;
            level=pool6CurrentLevel-pool6users[pool6Currentuser].level;
            emit getPoolPayment(msg.sender,pool6Currentuser, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool6users[pool6Currentuser].parent)).send(pool6_price);
            pool6users[pool6Currentuser].payment_received+=1;
            userparent=pool6users[pool6Currentuser].parent;
            level=pool6CurrentLevel - pool6users[pool6users[pool6Currentuser].parent].level;
            emit getPoolPayment(msg.sender,pool6users[pool6Currentuser].parent, level, now);
            emit regPoolEntry(msg.sender, level, now);
            }
        if(pool6users[pool6Currentuser].payment_received>=4 && pool6users[pool6Currentuser].mostright){
             pool6activeUserID+=1;
             mostRight=true;
             pool6CurrentLevel++;
        }
        else if(pool6users[pool6Currentuser].payment_received>=4)
                {
                    pool6activeUserID+=1;
                }

         userStruct = Pool6UserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool6users[msg.sender] = userStruct;
       pool6userList[pool6currUserID]=msg.sender;
    }
        
    function buyPool7() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool7users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool7_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=1, "Must need 1 referral");
        
        PoolUserStruct memory userStruct;
        address pool7Currentuser=pool7userList[pool7activeUserID];
        
        pool7currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0
        });
       pool7users[msg.sender] = userStruct;
       pool7userList[pool7currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool7Currentuser)).send(pool7_price);

            if (sent) {
                pool7users[pool7Currentuser].payment_received+=1;
                if(pool7users[pool7Currentuser].payment_received>=2)
                {
                    pool7activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool7Currentuser, 7, now);
            }
        emit regPoolEntry(msg.sender,7,  now);
    }
    
    
    function buyPool8() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool8users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool8_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=2, "Must need 2 referral");
       
        PoolUserStruct memory userStruct;
        address pool8Currentuser=pool8userList[pool8activeUserID];
        
        pool8currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0
        });
       pool8users[msg.sender] = userStruct;
       pool8userList[pool8currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool8Currentuser)).send(pool8_price);

            if (sent) {
                pool8users[pool8Currentuser].payment_received+=1;
                if(pool8users[pool8Currentuser].payment_received>=2)
                {
                    pool8activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool8Currentuser, 8, now);
            }
        emit regPoolEntry(msg.sender,8,  now);
    }
    
    
    
    function buyPool9() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool9users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool9_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=3, "Must need 3 referral");
       
        PoolUserStruct memory userStruct;
        address pool9Currentuser=pool9userList[pool9activeUserID];
        
        pool9currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0
        });
       pool9users[msg.sender] = userStruct;
       pool9userList[pool9currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool9Currentuser)).send(pool9_price);

            if (sent) {
                pool9users[pool9Currentuser].payment_received+=1;
                if(pool9users[pool9Currentuser].payment_received>=2)
                {
                    pool9activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool9Currentuser, 9, now);
            }
        emit regPoolEntry(msg.sender,9,  now);
    }
    
    
    function buyPool10() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool10users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool10_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=4, "Must need 4 referral");
        
        PoolUserStruct memory userStruct;
        address pool10Currentuser=pool10userList[pool10activeUserID];
        
        pool10currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0
        });
       pool10users[msg.sender] = userStruct;
       pool10userList[pool10currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool10Currentuser)).send(pool10_price);

            if (sent) {
                pool10users[pool10Currentuser].payment_received+=1;
                if(pool10users[pool10Currentuser].payment_received>=2)
                {
                    pool10activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool10Currentuser, 10, now);
            }
        emit regPoolEntry(msg.sender, 10, now);
    }
    
    function buyPool11() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool11users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool11_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=5, "Must need 5 referral");
        
        PoolUserStruct memory userStruct;
        address pool11Currentuser=pool11userList[pool11activeUserID];
        
        pool11currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool11currUserID,
            payment_received:0
        });
       pool11users[msg.sender] = userStruct;
       pool11userList[pool11currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool11Currentuser)).send(pool11_price);

            if (sent) {
                pool11users[pool11Currentuser].payment_received+=1;
                if(pool11users[pool11Currentuser].payment_received>=2)
                {
                    pool11activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool11Currentuser, 11, now);
            }
        emit regPoolEntry(msg.sender, 11, now);
    }
    
    function buyPool12() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool12users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool12_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=6, "Must need 6 referral");
        
        PoolUserStruct memory userStruct;
        address pool12Currentuser=pool12userList[pool12activeUserID];
        
        pool12currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool12currUserID,
            payment_received:0
        });
       pool12users[msg.sender] = userStruct;
       pool12userList[pool12currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool12Currentuser)).send(pool12_price);

            if (sent) {
                pool12users[pool12Currentuser].payment_received+=1;
                if(pool12users[pool12Currentuser].payment_received>=2)
                {
                    pool12activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool12Currentuser, 12, now);
            }
        emit regPoolEntry(msg.sender, 12, now);
    }
    function gettrxBalance() public view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalance() private
    {
         users[ownerWallet].income = users[ownerWallet].income + gettrxBalance();
         if (!address(uint160(ownerWallet)).send(gettrxBalance()))
         {
             
         }
    }
   
   
}