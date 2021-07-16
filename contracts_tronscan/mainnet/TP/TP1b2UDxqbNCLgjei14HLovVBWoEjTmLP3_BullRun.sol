//SourceUnit: bullrun.sol


pragma solidity ^0.5.9;

contract BullRun {
      using SafeMath for uint256;
     address payable public ownerWallet;
     address payable public secondowner;
     address payable public thirdOwner;
     address payable public fourthOwner; 
     
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
        address affFrom;
        uint affRewards;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
       uint total;
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
     
    mapping(uint => uint) public LEVEL_PRICE;
    
   uint REGESTRATION_FESS=100000000;
   uint pool1_price=500000000;
   uint pool2_price=1000000000;
   uint pool3_price=2500000000;
   uint pool4_price=5000000000;
   uint pool5_price=10000000000;
   uint pool6_price=25000000000;
   uint pool7_price=50000000000;
   uint pool8_price=100000000000;
   uint pool9_price=250000000000;
   uint pool10_price=500000000000;
   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
      event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
      
     event regPoolEntry(address indexed _user,uint _level,   uint _time);
   
     
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
   
    UserStruct[] public requests;
     
      constructor(address payable _secondOwner,address payable _third,address payable _fourth ) public {
          ownerWallet = msg.sender;
          secondowner = _secondOwner;
          thirdOwner = _third;
          fourthOwner = _fourth;

        LEVEL_PRICE[1] = 250000000;
        LEVEL_PRICE[2] = 100000000;
        LEVEL_PRICE[3] = 75000000;
        LEVEL_PRICE[4] = 75000000;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUsers:0,
            affFrom:address(0),
            affRewards:0
           
        });
        
        users[ownerWallet] = userStruct;
       userList[currUserID] = ownerWallet;
       
       
         PoolUserStruct memory pooluserStruct;
        
        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            total: pool1users[msg.sender].total
        });
    pool1activeUserID=pool1currUserID;
       pool1users[msg.sender] = pooluserStruct;
       pool1userList[pool1currUserID]=msg.sender;
      
        
        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            total: pool2users[msg.sender].total
        });
    pool2activeUserID=pool2currUserID;
       pool2users[msg.sender] = pooluserStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       
        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            total: pool3users[msg.sender].total
        });
    pool3activeUserID=pool3currUserID;
       pool3users[msg.sender] = pooluserStruct;
       pool3userList[pool3currUserID]=msg.sender;
       
       
         pool4currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            total: pool4users[msg.sender].total
        });
    pool4activeUserID=pool4currUserID;
       pool4users[msg.sender] = pooluserStruct;
       pool4userList[pool4currUserID]=msg.sender;

        
          pool5currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            total: pool5users[msg.sender].total
        });
    pool5activeUserID=pool5currUserID;
       pool5users[msg.sender] = pooluserStruct;
       pool5userList[pool5currUserID]=msg.sender;
       
       
         pool6currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            total: pool6users[msg.sender].total
        });
    pool6activeUserID=pool6currUserID;
       pool6users[msg.sender] = pooluserStruct;
       pool6userList[pool6currUserID]=msg.sender;
       
         pool7currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            total: pool7users[msg.sender].total
        });
    pool7activeUserID=pool7currUserID;
       pool7users[msg.sender] = pooluserStruct;
       pool7userList[pool7currUserID]=msg.sender;
       
       pool8currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            total: pool8users[msg.sender].total
        });
    pool8activeUserID=pool8currUserID;
       pool8users[msg.sender] = pooluserStruct;
       pool8userList[pool8currUserID]=msg.sender;
       
        pool9currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            total: pool9users[msg.sender].total
        });
    pool9activeUserID=pool9currUserID;
       pool9users[msg.sender] = pooluserStruct;
       pool9userList[pool9currUserID]=msg.sender;
       
       
        pool10currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            total: pool10users[msg.sender].total
        });
    pool10activeUserID=pool10currUserID;
       pool10users[msg.sender] = pooluserStruct;
       pool10userList[pool10currUserID]=msg.sender;
       
       
      }
     
     function regUser(uint _referrerID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require( _referrerID <= currUserID, 'Incorrect referral ID');
      require(msg.value >= REGESTRATION_FESS, 'Incorrect Value');
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            affFrom : userList[_referrerID],
            affRewards:0,
            referredUsers:0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        distributeRef(100000000,userList[_referrerID]);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
   
  
     
       function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = _trx.sub((_trx.mul(10)).div(100));

        address payable _affAddr1 = address(uint160(_affFrom));
        address payable _affAddr2 = address(uint160(users[_affAddr1].affFrom));
        address payable _affAddr3 = address(uint160(users[_affAddr2].affFrom));
        address payable _affAddr4 = address(uint160(users[_affAddr3].affFrom));
        // address payable _affAddr5 = address(uint160(users[_affAddr4].affFrom));
        // address payable _affAddr6 = address(uint160(users[_affAddr5].affFrom));
        // address payable _affAddr7 = address(uint160(users[_affAddr6].affFrom));
        // address payable _affAddr8 = address(uint160(users[_affAddr7].affFrom));
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(50)).div(100);
            _allaff = _allaff.sub(_affRewards);
            users[_affAddr1].affRewards = _affRewards.add(users[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(20)).div(100);
            _allaff = _allaff.sub(_affRewards);
            users[_affAddr2].affRewards = _affRewards.add(users[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(10)).div(100);
            _allaff = _allaff.sub(_affRewards);
            users[_affAddr3].affRewards = _affRewards.add(users[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(10)).div(100);
            _allaff = _allaff.sub(_affRewards);
            users[_affAddr4].affRewards = _affRewards.add(users[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
        }


        if(_allaff > 0 ){
            uint amount = (_allaff.add((_trx.mul(10)).div(100))).div(4);
            ownerWallet.transfer(amount);
            secondowner.transfer(amount);
            thirdOwner.transfer(amount);
            fourthOwner.transfer(amount);
        }
    }
   
   
   
   
       function buyPool1() public payable {
       require(users[msg.sender].isExist, "User Not Registered");
       require(msg.value == pool1_price, 'Incorrect Value');
        
       
        PoolUserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];
        
        pool1currUserID++;

        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            total : pool1users[msg.sender].total
        });
   
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool1Currentuser)).send(pool1_price.sub((pool1_price.mul(10)).div(100)));

            if (sent) {
                pool1users[pool1Currentuser].payment_received+=1;
                pool1users[pool1Currentuser].total+=1;
                if(pool1users[pool1Currentuser].payment_received>=3)
                {
                    pool1users[pool1Currentuser].isExist = false;
                    pool1activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool1Currentuser, 1, now);
            }
       emit regPoolEntry(msg.sender, 1, now);
    }
    
    
      function buyPool2() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool2_price, 'Incorrect Value');
         
        PoolUserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];
        
        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            total:pool2users[msg.sender].total
        });
        
      pool2users[msg.sender] = userStruct;
      pool2userList[pool2currUserID]=msg.sender;
       
       
       
      bool sent = false;
      sent = address(uint160(pool2Currentuser)).send(pool2_price.sub((pool2_price.mul(10)).div(100)));

            if (sent) {
                pool2users[pool2Currentuser].payment_received+=1;
                pool2users[pool2Currentuser].total+=1;
                if(pool2users[pool2Currentuser].payment_received>=3)
                {
                     pool2users[pool2userList[pool2currUserID]].isExist = false;
                    pool2activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool2Currentuser, 2, now);
            }
            emit regPoolEntry(msg.sender,2,  now);
    }
    
    
     function buyPool3() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool3_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];
        
        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            total:pool3users[msg.sender].total
        });
      pool3users[msg.sender] = userStruct;
      pool3userList[pool3currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool3Currentuser)).send(pool3_price.sub((pool3_price.mul(10)).div(100)));

            if (sent) {
                pool3users[pool3Currentuser].payment_received+=1;
                pool3users[pool3Currentuser].total+=1;
                if(pool3users[pool3Currentuser].payment_received>=3)
                {
                    pool3users[pool3Currentuser].isExist = false;
                    pool3activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool3Currentuser, 3, now);
            }
        emit regPoolEntry(msg.sender,3,  now);
    }
    
    
    function buyPool4() public payable {
      require(users[msg.sender].isExist, "User Not Registered");
      require(msg.value == pool4_price, 'Incorrect Value');
      
        PoolUserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];
        
        pool4currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
             total:pool4users[msg.sender].total
        });
      pool4users[msg.sender] = userStruct;
      pool4userList[pool4currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool4Currentuser)).send(pool4_price.sub((pool4_price.mul(10)).div(100)));

            if (sent) {
                pool4users[pool4Currentuser].payment_received+=1;
                pool4users[pool4Currentuser].total+=1;
                if(pool4users[pool4Currentuser].payment_received>=3)
                {
                     pool4users[pool4Currentuser].isExist=false;
                    pool4activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool4Currentuser, 4, now);
            }
        emit regPoolEntry(msg.sender,4, now);
    }
    
    
    
    function buyPool5() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool5_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];
        
        pool5currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
             total:pool5users[msg.sender].total
        });
      pool5users[msg.sender] = userStruct;
      pool5userList[pool5currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool5Currentuser)).send(pool5_price.sub((pool5_price.mul(10)).div(100)));

            if (sent) {
                pool5users[pool5Currentuser].payment_received+=1;
                pool5users[pool5Currentuser].total+=1;
                if(pool5users[pool5Currentuser].payment_received>=3)
                {
                    pool5users[pool5Currentuser].isExist = false;
                    pool5activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool5Currentuser, 5, now);
            }
        emit regPoolEntry(msg.sender,5,  now);
    }
    
    function buyPool6() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool6_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];
        
        pool6currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            total:pool6users[msg.sender].total
        });
      pool6users[msg.sender] = userStruct;
      pool6userList[pool6currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool6Currentuser)).send(pool6_price.sub((pool6_price.mul(10)).div(100)));

            if (sent) {
                pool6users[pool6Currentuser].payment_received+=1;
                pool6users[pool6Currentuser].total+=1;
                if(pool6users[pool6Currentuser].payment_received>=3)
                {
                     pool6users[pool6Currentuser].isExist = false;
                    pool6activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool6Currentuser, 6, now);
            }
        emit regPoolEntry(msg.sender,6,  now);
    }
    
    function buyPool7() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool7_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address pool7Currentuser=pool7userList[pool7activeUserID];
        
        pool7currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            total:pool7users[msg.sender].total
        });
      pool7users[msg.sender] = userStruct;
      pool7userList[pool7currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool7Currentuser)).send(pool7_price.sub((pool7_price.mul(10)).div(100)));

            if (sent) {
                pool7users[pool7Currentuser].payment_received+=1;
                pool7users[pool7Currentuser].total+=1;
                if(pool7users[pool7Currentuser].payment_received>=3)
                {
                    pool7users[pool7Currentuser].isExist = false;
                    pool7activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool7Currentuser, 7, now);
            }
        emit regPoolEntry(msg.sender,7,  now);
    }
    
    
    function buyPool8() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool8_price, 'Incorrect Value');
       
        PoolUserStruct memory userStruct;
        address pool8Currentuser=pool8userList[pool8activeUserID];
        
        pool8currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            total:pool8users[msg.sender].total
        });
      pool8users[msg.sender] = userStruct;
      pool8userList[pool8currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool8Currentuser)).send(pool8_price.sub((pool8_price.mul(10)).div(100)));

            if (sent) {
                pool8users[pool8Currentuser].payment_received+=1;
                pool8users[pool8Currentuser].total+=1;
                if(pool8users[pool8Currentuser].payment_received>=3)
                {
                    pool8users[pool8Currentuser].isExist = false;
                    pool8activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool8Currentuser, 8, now);
            }
        emit regPoolEntry(msg.sender,8,  now);
    }
    
    
    
    function buyPool9() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool9_price, 'Incorrect Value');
       
        PoolUserStruct memory userStruct;
        address pool9Currentuser=pool9userList[pool9activeUserID];
        
        pool9currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            total:pool9users[msg.sender].total
        });
      pool9users[msg.sender] = userStruct;
      pool9userList[pool9currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool9Currentuser)).send(pool9_price.sub((pool9_price.mul(10)).div(100)));

            if (sent) {
                pool9users[pool9Currentuser].payment_received+=1;
                pool9users[pool9Currentuser].total+=1;
                if(pool9users[pool9Currentuser].payment_received>=3)
                {
                    pool9users[pool9Currentuser].isExist = false;
                    pool9activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool9Currentuser, 9, now);
            }
        emit regPoolEntry(msg.sender,9,  now);
    }
    
    
    function buyPool10() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool10_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address pool10Currentuser=pool10userList[pool10activeUserID];
        
        pool10currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            total:pool10users[msg.sender].total
        });
      pool10users[msg.sender] = userStruct;
      pool10userList[pool10currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool10Currentuser)).send(pool10_price.sub((pool10_price.mul(10)).div(100)));

            if (sent) {
                pool10users[pool10Currentuser].payment_received+=1;
                pool10users[pool10Currentuser].total+=1;
                if(pool10users[pool10Currentuser].payment_received>=3)
                {
                    pool10users[pool10Currentuser].isExist = false;
                    pool10activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool10Currentuser, 10, now);
            }
        emit regPoolEntry(msg.sender, 10, now);
    }
    
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
    
   function transferadminmoney() public {
       require(msg.sender == ownerWallet || msg.sender == secondowner || msg.sender == thirdOwner || msg.sender == fourthOwner);
       uint amount = (address(this).balance).div(4);
            ownerWallet.transfer(amount);
            secondowner.transfer(amount);
            thirdOwner.transfer(amount);
            fourthOwner.transfer(amount);
         
   }
   
   
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}