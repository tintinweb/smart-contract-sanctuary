//SourceUnit: PeoplesDreams.sol

pragma solidity 0.4.25 - 0.5.9;

contract PeoplesDreams {
     address public ownerWallet;
     address public DreamsownerWallet;
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool2currUserID = 0;
      uint public pool3currUserID = 0;
      uint public pool4currUserID = 0;
      uint public pool5currUserID = 0;
      uint public pool6currUserID = 0;
      
      uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
      uint public pool4activeUserID = 0;
      uint public pool5activeUserID = 0;
      uint public pool6activeUserID = 0;

      
      
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

     
    mapping(uint => uint) public LEVEL_PRICE;
    
   uint REGESTRATION_FESS=1500 trx;
   uint comisionSpo=400 trx;
   uint pool1_price=1500  trx;
   uint pool2_price=1400 trx;
   uint pool3_price=2800 trx;
   uint pool4_price=5600 trx;
   uint pool5_price=11200 trx;
   uint pool6_price=22400 trx;
   uint pool6_dif = 20900 trx;

   
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event regPoolEntry(address indexed _user,uint _level,   uint _time);
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
   
    UserStruct[] public requests;
     
      constructor(address dreaddrOwne) public {
          ownerWallet = msg.sender;
          DreamsownerWallet = dreaddrOwne;

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
       
      }
     
    function regUser(uint _referrerID,address _addrOwner) public payable {
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
        
       payReferral(1,msg.sender,_addrOwner);
       buyPool1(msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
   
   
    function payReferral(uint _level, address _user, address _addrOwner) internal {
        address referer;
       
        referer = userList[users[_user].referrerID];
         bool sent = false;
            bool senduse = false;

            senduse =  address(uint160(_addrOwner)).send(comisionSpo);
       
            sent = address(uint160(referer)).send(comisionSpo);

            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
            }

     }

   

    function buyPool1(address _user) internal {
       require(users[_user].isExist, "User Not Registered");
       require(!pool1users[_user].isExist, "Already in AutoPool");
        
        PoolUserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];
        
        pool1currUserID++;

        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
   
       pool1users[_user] = userStruct;
       pool1userList[pool1currUserID]=_user;
       pool1users[pool1Currentuser].payment_received+=1;
       if(pool1users[pool1Currentuser].payment_received == 1){
            address(uint160(pool1Currentuser)).send(address(this).balance + pool1_price - address(this).balance);
       }
        if(pool1users[pool1Currentuser].payment_received == 3){
            pool1activeUserID+=1;
            buyPool2(_user,1);
             emit getPoolPayment(_user,pool1Currentuser, 1, now);
       }
       emit regPoolEntry(_user, 1, now);
    }

    function buyPool2(address _user,uint8 indenp) internal {
         
        PoolUserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];
        
        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
       pool2users[_user] = userStruct;
       pool2userList[pool2currUserID]=_user;

       pool2users[_user] = userStruct;
       pool2userList[pool2currUserID]=_user;
       pool2users[pool2Currentuser].payment_received+=1;
       if(pool2users[pool2Currentuser].payment_received == 1){
            address(uint160(pool2Currentuser)).send(address(this).balance + pool2_price - address(this).balance);
       }
       if(indenp == 1){
        if(pool2users[pool2Currentuser].payment_received == 3){
            buyPool3(_user,1);
            pool2activeUserID+=1;
            emit getPoolPayment(_user,pool2Currentuser, 2, now);
        }
       }else{
           if(pool2users[pool2Currentuser].payment_received == 2){
                address(uint160(pool2Currentuser)).send(address(this).balance + pool2_price - address(this).balance);
            }
            if(pool2users[pool2Currentuser].payment_received == 3){
                address(uint160(pool2Currentuser)).send(address(this).balance + pool2_price - address(this).balance);
                pool2activeUserID+=1;
                emit getPoolPayment(_user,pool2Currentuser, 2, now);
            }
        }
       
       emit regPoolEntry(_user, 2, now);
       
    }
    function buyPool3(address _user,uint8 indenp) internal {
         require(users[_user].isExist, "User Not Registered");
      require(!pool3users[_user].isExist, "Already in AutoPool");
        require(users[_user].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];
        
        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
       pool3users[_user] = userStruct;
       pool3userList[pool3currUserID]=_user;
       pool3users[pool3Currentuser].payment_received+=1;
        if(pool3users[pool3Currentuser].payment_received == 1){
            address(uint160(pool3Currentuser)).send(address(this).balance + pool3_price - address(this).balance);
       }
        if(indenp == 1){
            if(pool3users[pool3Currentuser].payment_received == 3){
                 buyPool4(_user,1);
                pool3activeUserID+=1;
                emit getPoolPayment(_user,pool3Currentuser, 3, now);
            }
       }else{
           if(pool3users[pool3Currentuser].payment_received == 2){
                address(uint160(pool3Currentuser)).send(address(this).balance + pool3_price - address(this).balance);
            }
            if(pool3users[pool3Currentuser].payment_received == 3){
                address(uint160(pool3Currentuser)).send(address(this).balance + pool3_price - address(this).balance);
                pool3activeUserID+=1;
                emit getPoolPayment(_user,pool3Currentuser,3, now);
            }
        }
            emit regPoolEntry(_user,3,  now);
    }
    function buyPool4(address _user,uint8 indenp) internal {
        require(users[_user].isExist, "User Not Registered");
      require(!pool4users[_user].isExist, "Already in AutoPool");
        require(users[_user].referredUsers>=0, "Must need 0 referral");
      
        PoolUserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];
        
        pool4currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0
        });
       pool4users[_user] = userStruct;
       pool4userList[pool4currUserID]=_user;
       pool4users[pool4Currentuser].payment_received+=1;
       if(pool4users[pool4Currentuser].payment_received == 1){
            address(uint160(pool4Currentuser)).send(address(this).balance + pool4_price - address(this).balance);
       }
        if(indenp == 1){
            if(pool4users[pool4Currentuser].payment_received == 3){
                 buyPool5(_user,1);
                pool4activeUserID+=1;
                emit getPoolPayment(_user,pool4Currentuser, 4, now);
            }
       }else{
           if(pool4users[pool4Currentuser].payment_received == 2){
                address(uint160(pool4Currentuser)).send(address(this).balance + pool4_price - address(this).balance);
            }
            if(pool4users[pool4Currentuser].payment_received == 3){
                address(uint160(pool4Currentuser)).send(address(this).balance + pool4_price - address(this).balance);
                pool4activeUserID+=1;
                emit getPoolPayment(_user,pool4Currentuser, 4, now);
            }
        }
       emit regPoolEntry(_user, 4, now);
    }
    function buyPool5(address _user,uint8 indenp) internal {
        require(users[_user].isExist, "User Not Registered");
      require(!pool5users[_user].isExist, "Already in AutoPool");
        require(users[_user].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];
        
        pool5currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0
        });
       pool5users[_user] = userStruct;
       pool5userList[pool5currUserID]=_user;
       pool5users[pool5Currentuser].payment_received+=1;
       if(pool5users[pool5Currentuser].payment_received == 1){
            address(uint160(pool5Currentuser)).send(address(this).balance + pool5_price - address(this).balance);
       }
          if(indenp == 1){
            if(pool5users[pool5Currentuser].payment_received == 3){
                 buyPool6(_user,1);
                pool5activeUserID+=1;
                emit getPoolPayment(_user,pool5Currentuser, 4, now);
            }
       }else{
           if(pool5users[pool5Currentuser].payment_received == 2){
                address(uint160(pool5Currentuser)).send(address(this).balance + pool5_price - address(this).balance);
            }
            if(pool5users[pool5Currentuser].payment_received == 3){
                address(uint160(pool5Currentuser)).send(address(this).balance + pool5_price - address(this).balance);
                pool5activeUserID+=1;
                emit getPoolPayment(_user,pool5Currentuser, 5, now);
            }
        }
       emit regPoolEntry(_user, 5, now);
    }
    function buyPool6(address _user,uint8 indenp) internal {
      require(!pool6users[_user].isExist, "Already in AutoPool");
        require(msg.value == pool6_price, 'Incorrect Value');
        require(users[_user].referredUsers>=0, "Must need 0 referral");
        
        PoolUserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];
        
        pool6currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0
        });
       pool6users[_user] = userStruct;
       pool6userList[pool6currUserID]=_user;
       if(pool6users[pool6Currentuser].payment_received == 1){
            address(uint160(pool6Currentuser)).send(address(this).balance + pool6_price - address(this).balance);
       }
       if(pool6users[pool6Currentuser].payment_received == 2){
           address(uint160(pool6Currentuser)).send(address(this).balance + pool6_price - address(this).balance);
       }
        if(pool6users[pool6Currentuser].payment_received == 3){
            address(uint160(pool6Currentuser)).send(address(this).balance + pool6_dif - address(this).balance);
            DreamsownerWallet.transfer(comisionSpo);
            buyPool1(_user);
            
            pool6activeUserID+=1;
             emit getPoolPayment(_user,pool6Currentuser, 6, now);
       }
       emit regPoolEntry(_user, 6, now);
    }

    function buyPool2Pay() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool2users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool2_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
         buyPool2(msg.sender,2);
      
    }
    function buyPool3Pay() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool3users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool3_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
         buyPool3(msg.sender,2);
        
       
    }

    function buyPool4Pay() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool4users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool4_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
         buyPool4(msg.sender,2);
      
    }
    
    function buyPool5Pay() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool5users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool5_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
         buyPool5(msg.sender,2);
     
    }
    
    function buyPool6Pay() public payable {
      require(!pool6users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool6_price, 'Incorrect Value');
        require(users[msg.sender].referredUsers>=0, "Must need 0 referral");
        buyPool6(msg.sender,2);
       
    }

}