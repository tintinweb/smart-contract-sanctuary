/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

pragma solidity 0.5.11;

contract BullRun {
     address public  ownerWallet;
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
      
      
      uint public unlimited_level_price=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
        mapping(uint => uint) levelExpired;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
    }
    
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

 mapping (address => PoolUserStruct) public pool11users;
     mapping (uint => address) public pool11userList;

 mapping (address => PoolUserStruct) public pool12users;
     mapping (uint => address) public pool12userList;

     
     
    mapping(uint => uint) public LEVEL_PRICE;
    
   uint REGESTRATION_FESS=0.01 ether;
   uint pool1_price=0.01 ether;
   uint pool2_price=0.02 ether ;
   uint pool3_price=0.04 ether;
   uint pool4_price=0.08 ether;
   uint pool5_price=0.16 ether;
   uint pool6_price=0.32 ether;
   uint pool7_price=0.64 ether ;
   uint pool8_price=1.28 ether ;
   uint pool9_price=2.56 ether;
   uint pool10_price=5.12 ether;
   uint pool11_price=10.24 ether;
   uint pool12_price=20.48 ether;
  
   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
     event getMoneyForPoolLevelEvent(address indexed _user,address indexed _referral,uint _level, uint _time);
     event regPoolEntry(address indexed _user,uint _level,   uint _time);
   
     
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
   
    UserStruct[] public requests;
     
      constructor() public {
          ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 0.001 ether;
        LEVEL_PRICE[2] = 0.001 ether;
        LEVEL_PRICE[3] = 0.001 ether;
        LEVEL_PRICE[4] = 0.0001 ether;
      unlimited_level_price=0.0001 ether;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUsers:0
           
        });
        
        users[ownerWallet] = userStruct;
       userList[currUserID] = ownerWallet;
       
       
         PoolUserStruct memory pooluserStruct;
        
        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
    pool1activeUserID=pool1currUserID;
       pool1users[msg.sender] = pooluserStruct;
       pool1userList[pool1currUserID]=msg.sender;
      
        
        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
    pool2activeUserID=pool2currUserID;
       pool2users[msg.sender] = pooluserStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       
        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
    pool3activeUserID=pool3currUserID;
       pool3users[msg.sender] = pooluserStruct;
       pool3userList[pool3currUserID]=msg.sender;
       
       
         pool4currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0
        });
    pool4activeUserID=pool4currUserID;
       pool4users[msg.sender] = pooluserStruct;
       pool4userList[pool4currUserID]=msg.sender;

        
          pool5currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0
        });
    pool5activeUserID=pool5currUserID;
       pool5users[msg.sender] = pooluserStruct;
       pool5userList[pool5currUserID]=msg.sender;
       
       
pool6currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0
        });
    pool6activeUserID=pool6currUserID;
       pool6users[msg.sender] = pooluserStruct;
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
     
       function regUser(uint _referrerID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        
       payReferral(1,msg.sender);
       sendBalance();
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
   
   
     function payReferral(uint _level, address _user) internal {
        address referer;
        uint counter;
        counter = users[_user].referredUsers;
        
        referer = userList[users[_user].referrerID];
       
       
         bool sent = false;
       
            uint level_price_local=0;
            
            if(_level == 1){
                if(counter == 1){
                    level_price_local = 0.001 ether;
                }
                else if(counter == 2){
                    level_price_local = 0.002 ether ;
                }
                else if(counter == 3){
                    level_price_local = 0.003 ether ;
                }
                else if(counter == 4){
                    level_price_local = 0.004 ether ;
                }
                else{
                    level_price_local = 0.005 ether;
                }
            }
            else if(_level >3) {
                level_price_local = unlimited_level_price;
            }
            else{
            level_price_local = LEVEL_PRICE[_level];
            }
            
            
            sent = address(uint160(referer)).send(level_price_local);

            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
                if(_level < 5 && users[referer].referrerID >= 1){
                    payReferral(_level+1,referer);
                }
                             
            }
       
        if(!sent) {
          //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payReferral(_level, referer);
        }
 sendBalance();
     }
   
   
   
   
       function buyPool1() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool1users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool1_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address  pool1Currentuser=pool1userList[pool1activeUserID];
        
        pool1currUserID++;

        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
        
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
       bool sent = false;
       
        
       //for referral
       address  referer = userList[users[msg.sender].referrerID];
      uint for_ref = pool1_price*20;
       uint price_for_ref = for_ref/100;
       address(uint160(referer)).transfer(price_for_ref);
                 
           uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool1userList[i];
                
                  if(pool1users[addr].payment_received < 11){
                      if(addr == msg.sender){
                        for(uint j=1; j<=4-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 1, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool1users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 1, now);
                    }
                    
                    if(pool1users[addr].payment_received >= 10){
                        addr = pool1userList[i+1];
                        inc_id++;
                    }
            }
                    
                            
             if (Payment) {
               
                if(pool1users[pool1Currentuser].payment_received >= 10)
                {
                    pool1activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool1Currentuser, 1, now);
            }
            
                       
       emit regPoolEntry(msg.sender, 1, now);
    }
    
    
      function buyPool2() public payable {
          require(users[msg.sender].isExist, "User Not Registered");
      require(!pool2users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool2_price, 'Incorrect Value');
                 
        PoolUserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];
        
        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
       pool2users[msg.sender] = userStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       
       
        bool sent = false;
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool2_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
 
                
           uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool2userList[i];
                
                  if(pool2users[addr].payment_received < 11){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 2, now);
                            }
                            break;
                        }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool2users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 2, now);
                    }
                    
                    if(pool2users[addr].payment_received >= 10){
                        addr = pool2userList[i+1];
                        inc_id++;
                    }
            }
                    
        
             if (Payment) {
               
                if(pool2users[pool2Currentuser].payment_received >= 10)
                {
                    pool2activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool2Currentuser, 2, now);
            }
            emit regPoolEntry(msg.sender,2,  now);
    }
    
    
     function buyPool3() public payable {
         require(users[msg.sender].isExist, "User Not Registered");
      require(!pool3users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool3_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];
        
        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
       pool3users[msg.sender] = userStruct;
       pool3userList[pool3currUserID]=msg.sender;
       bool sent = false;
       
       //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool3_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
               
           uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool3userList[i];
                
                  if(pool3users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 3, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool3users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 3, now);
                    }
                    
                    if(pool3users[addr].payment_received >= 15){
                        addr = pool3userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
                if(pool3users[pool3Currentuser].payment_received >= 15)
                {
                    pool3activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool3Currentuser, 3, now);
            }
        emit regPoolEntry(msg.sender,3,  now);
    }
    
    
    function buyPool4() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool4users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool4_price, 'Incorrect Value');
         
        PoolUserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];
        
        pool4currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0
        });
       pool4users[msg.sender] = userStruct;
       pool4userList[pool4currUserID]=msg.sender;
       bool sent = false;
       
         //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool4_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool4userList[i];
                
                  if(pool4users[addr].payment_received < 15){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 4, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool4users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 4, now);
                    }
                    
                    if(pool4users[addr].payment_received >= 15){
                        addr = pool4userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
                 if(pool4users[pool4Currentuser].payment_received >= 15)
                {
                    pool4activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool4Currentuser, 4, now);
            }
        emit regPoolEntry(msg.sender,4, now);
    }
    
    
    
    function buyPool5() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool5users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool5_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];
        
        pool5currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0
        });
       pool5users[msg.sender] = userStruct;
       pool5userList[pool5currUserID]=msg.sender;
       bool sent = false;
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool5_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool5userList[i];
                
                  if(pool5users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 5, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool5users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 5, now);
                    }
                    
                    if(pool5users[addr].payment_received >= 15){
                        addr = pool5userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
               
                if(pool5users[pool5Currentuser].payment_received >= 15)
                {
                    pool5activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool5Currentuser, 5, now);
            }
        emit regPoolEntry(msg.sender,5,  now);
    }
    
     function buyPool6() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool6users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool6_price, 'Incorrect Value');
               
        PoolUserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];
        
        pool6currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0
        });
       pool6users[msg.sender] = userStruct;
       pool6userList[pool6currUserID]=msg.sender;
       bool sent = false;
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool6_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool6userList[i];
                
                  if(pool6users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 6, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool6users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 6, now);
                    }
                    
                    if(pool6users[addr].payment_received >= 15){
                        addr = pool6userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
                if(pool6users[pool6Currentuser].payment_received >= 15)
                {
                    pool6activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool6Currentuser, 6, now);
            }
        emit regPoolEntry(msg.sender,6,  now);
    }


 function buyPool7() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool7users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool7_price, 'Incorrect Value');
              
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
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool7_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool7userList[i];
                
                  if(pool7users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 7, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool7users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 7, now);
                    }
                    
                    if(pool7users[addr].payment_received >= 15){
                        addr = pool7userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
                if(pool7users[pool7Currentuser].payment_received >= 15)
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
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool8_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool8userList[i];
                
                  if(pool8users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 8, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool8users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 8, now);
                    }
                    
                    if(pool8users[addr].payment_received >= 15){
                        addr = pool8userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
               
                if(pool8users[pool8Currentuser].payment_received >= 15)
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
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool9_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool9userList[i];
                
                  if(pool9users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 9, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool9users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 9, now);
                    }
                    
                    if(pool9users[addr].payment_received >= 15){
                        addr = pool9userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
               
                if(pool9users[pool9Currentuser].payment_received >= 15)
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
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool10_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool10userList[i];
                
                  if(pool10users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 10, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool10users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 10, now);
                    }
                    
                    if(pool10users[addr].payment_received >= 15){
                        addr = pool10userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
               
                if(pool10users[pool10Currentuser].payment_received >= 15)
                {
                    pool10activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool10Currentuser, 10, now);
            }
        emit regPoolEntry(msg.sender,10,  now);
    }
    

function buyPool11() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool11users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool11_price, 'Incorrect Value');
       
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
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool11_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool11userList[i];
                
                  if(pool11users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 11, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool11users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 11, now);
                    }
                    
                    if(pool11users[addr].payment_received >= 15){
                        addr = pool11userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
               
                if(pool11users[pool11Currentuser].payment_received >= 15)
                {
                    pool11activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool11Currentuser, 11, now);
            }
        emit regPoolEntry(msg.sender,11,  now);
    }

function buyPool12() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool12users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool12_price, 'Incorrect Value');
                
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
        //for referral 
        address  referer = userList[users[msg.sender].referrerID];
       uint for_ref = pool12_price*20;
       uint price_for_ref = for_ref*100;
       address(uint160(referer)).send(price_for_ref);
       
       uint  temp = msg.value/5;
           bool Payment;
           uint inc_id = 5;
           
            for(uint i=1; i<=inc_id; i++){
                address  addr = pool12userList[i];
                
                  if(pool12users[addr].payment_received < 16){
                      if(addr == msg.sender){
                        for(uint j=1; j<=5-i; j++){
                              sent  = address(uint160(ownerWallet)).send(temp);
                              emit getMoneyForPoolLevelEvent(msg.sender,ownerWallet, 12, now);
                            }
                            break;
                     }
                       
                    Payment = address(uint160(addr)).send(temp);
                    if(Payment){
                        pool12users[addr].payment_received += 1;
                     }
                      emit getMoneyForPoolLevelEvent(msg.sender,addr, 12, now);
                    }
                    
                    if(pool12users[addr].payment_received >= 15){
                        addr = pool12userList[i+1];
                        inc_id++;
                    }
            }
                    
            if (Payment) {
               
                if(pool12users[pool12Currentuser].payment_received >= 15)
                {
                    pool12activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool12Currentuser, 12, now);
            }
        emit regPoolEntry(msg.sender,12,  now);
    }

    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
    
     function sendBalance() public {
         if (!address(uint160(ownerWallet)).send(getEthBalance()))
         {
            address(uint160(ownerWallet)).transfer(getEthBalance());  
         }
        
     }
    
   
   
}