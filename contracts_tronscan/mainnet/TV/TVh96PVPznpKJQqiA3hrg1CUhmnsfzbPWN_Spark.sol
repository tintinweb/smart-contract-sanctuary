//SourceUnit: contract_10082021.sol

pragma solidity ^0.5.10;

//         sssssss        ppppppp    aaaa    rrrrrrrr  kkk       kkk
//      ssss     ssss    pp     pp  aa  aa   rrr   rr  kkk     kkk
//      ssss      sss    pp     pp  aa  aa   rrr  rr   kkk   kkk
//      ssss             pp    ppp   aaaaaa   rrr rr    kkk kkkk
//      ssssssss         pppppppp    aaaaaa   rrrrrr    kkkkkkk
//           ssssssss    pppp       aa  aa   rrr rrr   kkk  kkkkk
//             ssssss    pppp        aa  aa   rrr  rrr  kkk   kkkkk
//      sss      ssss    pppp       aa  aa   rrr  rrr  kkk    kkkkk
//      sss       sss    pppp       aa  aa   rrr   rr  kkk     kkkkk
//      sssssssssssss    pppp       aa  aa   rrr   rr  kkk      kkkkk
//      sssssssssssss    pppp       aa  aa   rrr   rr  kkk       kkkk

// Final version until now
contract Spark {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        
        mapping(uint8 => X3) x3Matrix;
        
        string name;
        string city;
        string country;
        string telegramChatId;
		string telegramUserId;
        string badge;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        address[] userReferrals;
        bool blocked;
        uint reinvestCount;
        string referrerStatus;
    }
    
    struct Queue {
        address senderAddress;
    }
    
    mapping (uint => Queue) public queue;
    
    uint queueCount;
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 20;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 30 trx;
        levelPrice[2] = 60 trx;
        levelPrice[3] = 120 trx;
        levelPrice[4] = 240 trx;
        levelPrice[5] = 480 trx;
        levelPrice[6] = 960 trx;
        levelPrice[7] = 1920 trx;
        levelPrice[8] = 3840 trx;
        levelPrice[9] = 7680 trx;
        levelPrice[10] = 15360 trx;
        levelPrice[11] = 30720 trx;
        levelPrice[12] = 61440 trx;
        levelPrice[13] = 122880 trx;
        levelPrice[14] = 245760 trx;
        levelPrice[15] = 491520 trx;
        levelPrice[16] = 983040 trx;
        levelPrice[17] = 1966080 trx;
        levelPrice[18] = 3932160 trx;
        levelPrice[19] = 7864320 trx;
        levelPrice[20] = 15728640 trx;
         
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            
            name:"Spark",
            city:"",
            country:"",
            telegramChatId:"",
			telegramUserId:"",
            badge:"Coach"
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
        }   
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawLostTRXFromBalance() public {
        require(msg.sender == 0xFD8e49202A11235ca51694afb7b42563973694e6, "onlyOwner");
        0xFD8e49202A11235ca51694afb7b42563973694e6.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
            

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } 
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        require(msg.value == levelPrice[currentStartingLevel], "invalid registration cost");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            name:"",
            city:"",
            country:"",
            telegramChatId:"",
			telegramUserId:"",
            badge:"Member"
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true;
        
        if (users[referrerAddress].x3Matrix[1].blocked) {
            users[userAddress].x3Matrix[1].referrerStatus="blocked";
        } else {
            users[userAddress].x3Matrix[1].referrerStatus="active";    
        }
        
        users[userAddress].badge = "Member";
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        
        addToQueue(userAddress);
        if (referrerAddress!=owner) {
            removeFromQueue(referrerAddress);
            bool refActiveLevelsStatus = usersActiveX3Levels(referrerAddress,2);
            if (refActiveLevelsStatus==false) {
                addToQueue(referrerAddress);            
            }
        }

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
        users[referrerAddress].x3Matrix[level].userReferrals.push(userAddress);
        

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
            users[userAddress].x3Matrix[level].referrerStatus="blocked";
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
			
			address referrerAddr = users[userAddress].referrer;
			users[userAddress].referrer = users[referrerAddr].referrer;
			users[referrerAddr].referrer = userAddress;
            
            //userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,address[] memory,string memory ,bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].userReferrals,
                users[userAddress].x3Matrix[level].referrerStatus,
                users[userAddress].x3Matrix[level].blocked);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } 
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            address(uint160(owner)).transfer(address(this).balance);
            return;
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function addToQueue(address anyAddress) public {
        queueCount++;
        queue[queueCount] = Queue(anyAddress);
    }
   
    function retrieveNextInQueue() view public returns(address) {
        if (queueCount<1) {
            // should be changed to owneraddress or msg.sender
            return idToAddress[1];
        }
        else {
            return queue[1].senderAddress;
        }
    }
   
    function removeFromQueue(address searchAddress) public  {
        int queuePos=0;
        for (uint i=1;i<=queueCount;i++) {
            if (queue[i].senderAddress==searchAddress) {
                queuePos=int(i);
                i= i+queueCount;
            }
        }
       
        if (queuePos!=0) {
            for (uint i=uint(queuePos);i<=queueCount;i++) {
                queue[i]=queue[i+1];
            }
            delete queue[queueCount];
            queueCount--;
        }
    }
   
    function removeAddressFromQueue(address _userAddress) public  {
        int queuePos=0;
        for (uint i=1;i<=queueCount;i++) {
            if (queue[i].senderAddress==_userAddress) {
                queuePos=int(i);
                i = queueCount+1;
            }
        }
       
        if (queuePos!=0) {
            for (uint i=uint(queuePos);i<=queueCount;i++) {
                queue[i]=queue[i+1];
            }
            delete queue[queueCount];
            queueCount--;
        }

    }
   
    function getQueueCount() view public returns (uint) {
        return queueCount;
    }
    
    function updateProfileDetails(address userAddress,string memory _name,string memory _city,string memory _country,string memory _telegramChatId,string memory _telegramUserId) public {
        string memory empty = "";
        if (keccak256(bytes(_name)) != keccak256(bytes(empty))) {
            users[userAddress].name = _name;
        }
        
        if (keccak256(bytes(_city)) !=keccak256(bytes(empty))) {
            users[userAddress].city = _city;
        }
        
        if (keccak256(bytes(_country)) !=keccak256(bytes(empty))) {
            users[userAddress].country = _country;
        }
        if (keccak256(bytes(_telegramChatId)) !=keccak256(bytes(empty))) {
            users[userAddress].telegramChatId = _telegramChatId;
        }
		if (keccak256(bytes(_telegramUserId)) !=keccak256(bytes(empty))) {
            users[userAddress].telegramUserId = _telegramUserId;
        }
    }
    
    function upgradeToCoach(address userAddress) public {
        if (users[userAddress].partnersCount>50) {
            users[userAddress].badge="Coach";
        }
    }
}