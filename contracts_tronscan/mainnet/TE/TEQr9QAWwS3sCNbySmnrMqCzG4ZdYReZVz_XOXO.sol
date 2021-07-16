//SourceUnit: contracts.sol


pragma solidity 0.5.9;

contract XOXO {
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
      
      uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
      uint public pool4activeUserID = 0;
      uint public pool5activeUserID = 0;
      uint public pool6activeUserID = 0; 
      uint public pool7activeUserID = 0; 
      uint public pool8activeUserID = 0;  
      
       
     
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
      
     
    mapping(uint => uint) public LEVEL_PRICE;
    
   uint REGESTRATION_FESS=300 trx;
   uint pool1_price=300 trx;
   uint pool2_price=500 trx ;
   uint pool3_price=1000 trx;
   uint pool4_price=1500 trx;
   uint pool5_price=2000 trx;
   uint pool6_price=4000 trx; 
   uint pool7_price=8000 trx; 
   uint pool8_price=10000 trx;  
   
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint _price); 
    event regPoolEntry(address indexed _user,uint _level,   uint _time);
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getPoolSponsorPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getReInvestPoolPayment(address indexed _user, uint _level, uint _time, uint _price);
   
    UserStruct[] public requests;
    uint public totalEarned = 0;
     
    constructor() public {
        ownerWallet = msg.sender;

 
       

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
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function payReferral(uint _level, address _user) internal {
        address referer;
       
       
        bool sent = false;
        uint level_price_local=0 trx ;
      
           
           
referer = userList[users[_user].referrerID];
           
   for (uint8 i = 1; i <= 4; i++) {       
       if(i==1)
           {
              level_price_local=150 trx; 
           }
           else if(i==2)
           {
              level_price_local=75 trx; 
           }
           else if(i==3)
           {
              level_price_local=40 trx; 
           }
           else if(i==4)
           {
              level_price_local=30 trx; 
           }
           
           if(users[referer].isExist)
           {
sent = address(uint160(referer)).send(level_price_local); 
if (sent) 
{
totalEarned += level_price_local;
emit getMoneyForLevelEvent(referer, msg.sender, i, now, level_price_local);           
}
}
else
{
    sent = address(uint160(ownerWallet)).send(level_price_local); 
    if (sent) 
{        
}
else
{
    sendBalance();
}
}
 
 
referer = userList[users[referer].referrerID];
   }     
       
       
         
     }
     
     function reInvest( address _user, uint _level) internal {
         
if(_level==1)
{
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
emit getReInvestPoolPayment(_user, _level, now,pool1_price);
}
else if(_level==2)
{
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
emit getReInvestPoolPayment(_user, _level, now,pool2_price);
}
else if(_level==3)
{
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
emit getReInvestPoolPayment(_user, _level, now,pool3_price);
}
else if(_level==4)
{
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
emit getReInvestPoolPayment(_user, _level, now,pool4_price);
}
else if(_level==5)
{
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
emit getReInvestPoolPayment(_user, _level, now,pool5_price);
}

else if(_level==6)
{
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
emit getReInvestPoolPayment(_user, _level, now,pool6_price);
}

else if(_level==7)
{
PoolUserStruct memory userStruct;
address pool7Currentuser=pool7userList[pool7activeUserID];
pool7currUserID++;
userStruct = PoolUserStruct({
isExist:true,
id:pool7currUserID,
payment_received:0
});
pool7users[_user] = userStruct;
pool7userList[pool7currUserID]=_user;
emit getReInvestPoolPayment(_user, _level, now,pool7_price);
}
  

else if(_level==8)
{
PoolUserStruct memory userStruct;
address pool8Currentuser=pool8userList[pool8activeUserID];
pool8currUserID++;
userStruct = PoolUserStruct({
isExist:true,
id:pool8currUserID,
payment_received:0
});
pool8users[_user] = userStruct;
pool8userList[pool8currUserID]=_user;
emit getReInvestPoolPayment(_user, _level, now,pool8_price);
}
      
  
      
             
     }

    function buyPool1() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool1users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool1_price, 'Incorrect Value');
        
       
        PoolUserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];
        
        pool1currUserID++;

        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
   
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
       bool sent = false;
       address spreferer;
       uint poolshare = (pool1_price*80)/100;
       uint pool_sp_share = (pool1_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool1Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool1users[pool1Currentuser].payment_received+=1;
            if(pool1users[pool1Currentuser].payment_received>=3)
            {
                pool1activeUserID+=1;
                reInvest(pool1Currentuser,1);

            }
            emit getPoolPayment(msg.sender,pool1Currentuser, 1, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 1, now, pool_sp_share);
        }
       emit regPoolEntry(msg.sender, 1, now);
    }


    function buyPool2() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool2users[msg.sender].isExist, "Already in AutoPool");
        require(pool1users[msg.sender].isExist, "Purchase pool 1 First");
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
       
       address spreferer;
       uint poolshare = (pool2_price*80)/100;
       uint pool_sp_share = (pool2_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool2Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool2users[pool2Currentuser].payment_received+=1;
            if(pool2users[pool2Currentuser].payment_received>=3)
            {
                pool2activeUserID+=1;
                reInvest(pool2Currentuser,2);

            }
            emit getPoolPayment(msg.sender,pool2Currentuser, 2, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 2, now, pool_sp_share);
        }
        
            emit regPoolEntry(msg.sender,2,  now);
    }
    
    function buyPool3() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool3users[msg.sender].isExist, "Already in AutoPool");
        require(pool2users[msg.sender].isExist, "Purchase pool 2 First");
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
        address spreferer;
       uint poolshare = (pool3_price*80)/100;
       uint pool_sp_share = (pool3_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool3Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool3users[pool3Currentuser].payment_received+=1;
            if(pool3users[pool3Currentuser].payment_received>=3)
            {
                pool3activeUserID+=1;
                reInvest(pool3Currentuser,3);

            }
            emit getPoolPayment(msg.sender,pool3Currentuser, 3, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 3, now, pool_sp_share);
        }
        emit regPoolEntry(msg.sender,3,  now);
    }

    function buyPool4() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool4users[msg.sender].isExist, "Already in AutoPool");
        require(pool3users[msg.sender].isExist, "Purchase pool 3 First");
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
      
       address spreferer;
       uint poolshare = (pool4_price*80)/100;
       uint pool_sp_share = (pool4_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool4Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool4users[pool4Currentuser].payment_received+=1;
            if(pool4users[pool4Currentuser].payment_received>=3)
            {
                pool4activeUserID+=1;
                reInvest(pool4Currentuser,4);

            }
            emit getPoolPayment(msg.sender,pool4Currentuser, 4, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 4, now, pool_sp_share);
        }
        emit regPoolEntry(msg.sender,4, now);
    }

    function buyPool5() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool5users[msg.sender].isExist, "Already in AutoPool");
        require(pool4users[msg.sender].isExist, "Purchase pool 4 First");
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
       
        address spreferer;
       uint poolshare = (pool5_price*80)/100;
       uint pool_sp_share = (pool5_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool5Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool5users[pool5Currentuser].payment_received+=1;
            if(pool5users[pool5Currentuser].payment_received>=3)
            {
                pool5activeUserID+=1;
                reInvest(pool5Currentuser,5);

            }
            emit getPoolPayment(msg.sender,pool5Currentuser, 5, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 5, now, pool_sp_share);
        }
        emit regPoolEntry(msg.sender,5,  now);
    }
    
    function buyPool6() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool6users[msg.sender].isExist, "Already in AutoPool");
        require(pool5users[msg.sender].isExist, "Purchase pool 5 First");
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
      
       address spreferer;
       uint poolshare = (pool6_price*80)/100;
       uint pool_sp_share = (pool6_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool6Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool6users[pool6Currentuser].payment_received+=1;
            if(pool6users[pool6Currentuser].payment_received>=3)
            {
                pool6activeUserID+=1;
                reInvest(pool6Currentuser,6);

            }
            emit getPoolPayment(msg.sender,pool6Currentuser, 6, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 6, now, pool_sp_share);
        }
        emit regPoolEntry(msg.sender,6,  now);
    }
    
     
    function buyPool7() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool7users[msg.sender].isExist, "Already in AutoPool");
        require(pool6users[msg.sender].isExist, "Purchase pool 6 First");
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
      
        address spreferer;
       uint poolshare = (pool7_price*80)/100;
       uint pool_sp_share = (pool7_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool7Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool7users[pool7Currentuser].payment_received+=1;
            if(pool7users[pool7Currentuser].payment_received>=3)
            {
                pool7activeUserID+=1;
                reInvest(pool7Currentuser,7);

            }
            emit getPoolPayment(msg.sender,pool7Currentuser, 7, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 7, now, pool_sp_share);
        }
        emit regPoolEntry(msg.sender,7,  now);
    }
    
    
    function buyPool8() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool8users[msg.sender].isExist, "Already in AutoPool");
        require(pool7users[msg.sender].isExist, "Purchase pool 7 First");
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
      
        address spreferer;
       uint poolshare = (pool8_price*80)/100;
       uint pool_sp_share = (pool8_price*20)/100;
        spreferer = userList[users[msg.sender].referrerID];
            sent = address(uint160(pool8Currentuser)).send(poolshare);
            sent = address(uint160(spreferer)).send(pool_sp_share);

        if (sent) {
            totalEarned += poolshare;
            pool8users[pool8Currentuser].payment_received+=1;
            if(pool8users[pool8Currentuser].payment_received>=3)
            {
                pool8activeUserID+=1;
                reInvest(pool8Currentuser,8);

            }
            emit getPoolPayment(msg.sender,pool8Currentuser, 8, now, poolshare);
            emit getPoolSponsorPayment(msg.sender,spreferer, 8, now, pool_sp_share);
        }
        emit regPoolEntry(msg.sender,8,  now);
    }
    
    
   
    
    function getTrxBalance() public view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalance() private
    {
         if (!address(uint160(ownerWallet)).send(getTrxBalance()))
         {
             
         }
    }
   
   
}