//SourceUnit: quicktro.sol

pragma solidity ^0.5.15;

contract Quicktro {
    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        uint256 maxIncome;
        mapping(uint256 => referreres) levelUser;
        
        mapping(uint256 => bool) activeLevels;
        uint256 currentPlan;
    }
    
    struct referreres {
        address currentReferrer;
        address[] Matrix;
    }
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    
    address poolAddress;
    
    uint256 public constant LAST_LEVEL = 8;
    
    uint256 public lastUserId = 15488;
    address public owner;
    
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;
    
    mapping(uint256 => uint256) public levelPrice;
    mapping(uint256 => uint256) public affiliatePer;
    uint256 public constant levelIncome = 10;
    
    event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId);
    event Upgrade(address indexed user, uint256 amount, uint256 level);
    event NewUserPlace(address indexed user,uint256 indexed userId, address indexed referrer,uint256 referrerId, uint256 place, uint256 level);
    event MissedTRONReceive(address indexed receiver,uint256 receiverId, address indexed from, uint256 indexed fromId, uint256 amount);
    event MissedLevelIncome(address indexed receiver,uint256  receiverId, address indexed from,uint256 indexed fromId, uint256 networklevel);
    event SentDividends(address indexed from,uint256 indexed fromId, address receiver,uint256 indexed receiverId, uint256 amount);
    event SentLevelincome(address indexed from,uint256 indexed fromId, address receiver,uint256 indexed receiverId, uint256 level, uint256 matrixLevel, uint256 amount, bool isExtraLevel);
    event SentPoolIncome(address user, uint256 amount);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] =  200 trx;
        levelPrice[2] =  500 trx;
        levelPrice[3] =  1000 trx;
        levelPrice[4] =  2000 trx;
        levelPrice[5] =  3000 trx;
        levelPrice[6] =  4000 trx;
        levelPrice[7] =  5000 trx;
        levelPrice[8] =  10000 trx;
        
        affiliatePer[1] =  50;
        affiliatePer[2] =  10;
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 15487,
            referrer: address(0),
            partnersCount: uint256(0),
            maxIncome: 0,
            currentPlan: 10000
        });
        
        for (uint256 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;
            users[ownerAddress].levelUser[i].currentReferrer= owner;
            users[ownerAddress].levelUser[i].Matrix= new address[](0);
        }
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        userIds[1] = ownerAddress;
        
        poolAddress = 0x26f087D95D77228f89b97A34d898ff588BB2E4Bc;
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
    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 200 trx, "registration cost 200 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        address freePlace = findFreePlace(referrerAddress, 1);
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            maxIncome: levelPrice[1]*10,
            currentPlan: msg.value
        });
        
        users[userAddress].activeLevels[1] = true;
         
        users[userAddress].levelUser[1].currentReferrer= freePlace;
        users[userAddress].levelUser[1].Matrix = new address[](0);
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
    
        sendTRONDividends(userAddress, referrerAddress, msg.value, 1);
       
        updatePlace(userAddress, freePlace, 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    
    function findFreePlace(address referrerAddress, uint256 level) public view returns(address) {
       if ( users[referrerAddress].levelUser[level].Matrix.length < 2) {
            return referrerAddress;
        }
        
        bool noReferrer = true;
        address referrer;
        address[] memory referrals = new address[](2046);
        referrals[0] = users[referrerAddress].levelUser[level].Matrix[0];
        referrals[1] = users[referrerAddress].levelUser[level].Matrix[1];

        for(uint256 i = 0; i < 2046; i++) {
            if(users[referrals[i]].levelUser[level].Matrix.length == 2) {
                if( i < 1022) {
                    referrals[(i+1)*2] = users[referrals[i]].levelUser[level].Matrix[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].levelUser[level].Matrix[1];
                }
            } 
            else {
                noReferrer = false;
                referrer = referrals[i];
                break;
            }
        }

        require(!noReferrer, "No Free Referrer");
        return referrer;
    }
    
    
    function updatePlace(address userAddress, address referrerAddress, uint256 level) private {
        users[referrerAddress].levelUser[level].Matrix.push(userAddress);
        users[userAddress].levelUser[level].currentReferrer= referrerAddress;
        emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id, uint256(users[referrerAddress].levelUser[level].Matrix.length), level);
        return distributeLevelIncome(userAddress, msg.value, level);
    }
    
    
    function distributeLevelIncome(address userAddress, uint256 amount, uint256 level) private {
        uint256 percentage = 80;
        if(level==1){ percentage = 50; }
        uint256 mainAmount =  (amount * percentage)/100;
        uint256 principal =  (mainAmount * 10)/100;
        address from_address = userAddress;
        bool owner_flag = false;
        bool isExtraLevel;
        address receiver;

        for (uint256 i = 1; i <= 10 ; i++) {
            isExtraLevel = false;

            if(owner_flag == false){
                userAddress = users[userAddress].levelUser[level].currentReferrer;
                if(userAddress == owner || userAddress == address(0)){
                    owner_flag = true;
                }
            }else{
                userAddress = owner;
            }
            receiver = userAddress;
            if(userAddress != owner){
                (receiver, isExtraLevel)  = findLevelReceiver(receiver, from_address, amount, i);
                if(receiver == owner){
                    owner_flag = true;
                }
                userAddress = receiver;
            }
            
            if(isExtraLevel){
                 if(!address(uint256(owner)).send(principal)){
                    return address(uint256(owner)).transfer(principal);
                }   
            }else{
                sendtrx(receiver, from_address, principal, false);
            }
            emit SentLevelincome(from_address,users[from_address].id, receiver,users[receiver].id, i, level, principal, isExtraLevel);
        }
    }
    
    
    function upgradeAccount(uint256 level) public payable returns(bool){
        require(isUserExists(msg.sender), "user Not exists");
        require(msg.value == levelPrice[level], "Incorrect invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeLevels[level], "level already activated");
       
       users[msg.sender].maxIncome= levelPrice[level]*10;
       
       users[msg.sender].currentPlan=msg.value;
       
       address freeReferrer = findFreeReferrer(msg.sender, level-1, level);
       users[msg.sender].levelUser[level].currentReferrer = freeReferrer;
       users[msg.sender].activeLevels[level] = true;
       address freePlace = findFreePlace(freeReferrer, level);
       updatePlace(msg.sender, freePlace, level);
      
       sendTRONDividends(msg.sender, users[msg.sender].referrer, msg.value, 2);
       
       depositPoolBalance(msg.sender, msg.value);
       
       emit Upgrade(msg.sender, msg.value, level);
       
        return true;
    }
    
    function findFreeReferrer(address userAddress, uint256 fromlevel, uint256 uplevel) public view returns(address) {
        while (true) {
            if (users[users[userAddress].levelUser[fromlevel].currentReferrer].activeLevels[uplevel]) {
                return users[userAddress].levelUser[fromlevel].currentReferrer;
            }
            
             if(users[userAddress].levelUser[uplevel].currentReferrer == address(0)){
                return owner;
            }
            
            userAddress = users[userAddress].levelUser[fromlevel].currentReferrer;
        }
    }
    
    
    function depositPoolBalance(address userAddress, uint256 amount) private {
        uint256 distribute = amount*10/100;
        if(!address(uint256(poolAddress)).send(distribute)){
                return address(uint256(poolAddress)).transfer(distribute);
            } 
            
        emit SentPoolIncome(userAddress, distribute);
    }
    
    
    function findLevelReceiver(address userAddress, address _from, uint256 amount, uint256 networklevel) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends = false;
                if (users[receiver].currentPlan >= amount || users[receiver].currentPlan == levelPrice[7]) {
                    return (receiver, isExtraDividends);
                } else {
                     emit MissedLevelIncome(receiver,users[receiver].id, _from,users[_from].id, networklevel);
                     isExtraDividends = true;
                     return (receiver, isExtraDividends);
                }
       
    }
    
    function findUpgradeAmount(address userAddress) public view returns(uint256){
       for (uint256 i = 1; i <= 7; i++) {
            if(users[userAddress].currentPlan==levelPrice[i]){
                return levelPrice[i+1];
            }
       }
       return levelPrice[8];
    }
    
    function sendTRONDividends(address userAddress, address refer, uint256 amount, uint256 level) private {
        uint256 distribute = amount*affiliatePer[level]/100;
        
        if(users[refer].currentPlan >= levelPrice[7]){
            emit SentDividends(userAddress,users[userAddress].id, refer,users[refer].id, distribute);
           if(!address(uint256(refer)).send(distribute)){
                return address(uint256(refer)).transfer(distribute);
            }
        }else{
            if(users[refer].activeLevels[level]){
                sendtrx(refer, userAddress, distribute, true);   
            }else{
                emit SentDividends(userAddress,users[userAddress].id, owner,users[owner].id, distribute);
                 if(!address(uint256(owner)).send(distribute)){
                    address(uint256(owner)).transfer(distribute);
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
    
    function changePoolWallet(address newAddress) public payable onlyOwner{
        poolAddress = newAddress;
    }
    
    function poolWallet() public view returns (address) {
        return poolAddress;
    }
    
    function getUserDetails(address _addr, uint256 level) public view returns (uint256, address, address[] memory) {
        User storage account = users[_addr];
        return(
            account.id,
            account.levelUser[level].currentReferrer,
            account.levelUser[level].Matrix
        );
    }
    
    
    function sendtrx(address userAddress, address _from, uint256 amount, bool emitnoti) private returns(bool){
        if(userAddress == address(0)){
            userAddress = owner;
        }
        
        if((users[userAddress].maxIncome - amount) > 0){
            if(emitnoti){  emit SentDividends(_from,users[_from].id, userAddress,users[userAddress].id, amount); }
            if(!address(uint256(userAddress)).send(amount)){
                address(uint256(userAddress)).transfer(amount);
            }
        }else{
            if(!address(uint256(owner)).send(amount)){
                address(uint256(owner)).transfer(amount);
            }
            
            emit MissedTRONReceive(userAddress,users[userAddress].id, _from, users[_from].id, amount);
        }
        
        users[userAddress].maxIncome = users[userAddress].maxIncome-amount;
    }
}