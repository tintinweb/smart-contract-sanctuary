//SourceUnit: New.sol

pragma solidity >=0.4.23 <0.6.0;

contract WeTron {
    struct KK {
        uint totalEarned;
        uint totalPartners;
        bool isActive;
    }

    // USER STRUCTURE
    struct Users {
        uint userId;
        uint referrerId;
        uint totalDownline;
        address activeUpline;
        address activeDownline;
        
        mapping (uint8 => bool) activeLevelsKK;
        
        mapping (uint8 => KK) levelKK;
    }
    
    uint8 constant MAX_LEVEL = 12;// For All Levels
    
    uint public idGenerator = 1;// Owner ID = 1
    address public owner;
    address public wallet_one;
    address public wallet_two;
    address public wallet_three;
    address public first_id;
    uint time;
    uint totalEarned;
    
    mapping (address => Users) public users;
    mapping (uint8 => uint) public levelPrices;
    mapping (uint => address) public usersList;
    mapping (uint8 => uint64) public totalUsers;
    address public lastId;
    
    event Registration(address indexed userAddress, address indexed referrerAddress, uint indexed userId, uint referrerId);
    event Upgrade(address indexed userAddress, address indexed referrerAddress, uint8 package, uint8 levelNumber);
    event NewUserPlace(address indexed userAddress, address indexed referrerAddress, uint8 package, uint8 levelNumber, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint price);
    event SendETHEvent(address indexed from, address indexed receiver, uint8 levelNumber);
    event OwnershipTransferred(address indexed newOwner, uint8 indexed accountNumber);
    
    constructor (address topAddress, address walletOne, address walletTwo, address walletThree, address firstId) public {
        owner = topAddress;
        wallet_one = walletOne;
        wallet_two = walletTwo;
        wallet_three = walletThree;
        first_id = firstId;
        time = now;
        
        //Setting Level Prices
        initLevelPrices();
        
        //Creating temprary user
        Users memory user = Users ({
           userId: idGenerator,
           referrerId: 1,
           totalDownline: uint(0),
           activeUpline: first_id,
           activeDownline: address(0)
        });
        users[firstId] = user;
        usersList[1] = firstId;
        idGenerator++;
        
        for (uint8 i = 1; i < 13; i++) {
            users[firstId].activeLevelsKK[i] = true;
            users[firstId].levelKK[i].isActive = true;
            
            totalUsers[i] = 1;
        }
        
        lastId = firstId;
        totalEarned = 0;
    }
    
    /*****************************************
     *        REGISTERING A NEW USER        *
    *****************************************/
    function registerUser (address userAddress, address referrer) external payable {
        uint32 check;
        assembly {
            check := extcodesize(userAddress)
        }
        
        require (check == 0, "Invalid Address! Cannot Register a Contract!");
        require (!userExists(userAddress), "User Already Exists!");
        require (userExists(referrer), "Referrer Does not Exist!");
        require (msg.value == 500 trx, "Invalid Level Pice!");
        
        // Creating user
        Users memory user = Users({
           userId: idGenerator,
           referrerId: users[referrer].userId,
           totalDownline: uint(0),
           activeUpline: lastId,
           activeDownline: address(0)
           
        });
        
        users[userAddress] = user;
        usersList[idGenerator] = userAddress;
        idGenerator++;
        
        users[userAddress].activeLevelsKK[1] = true;

        // Updating Referrer Details
        users[referrer].totalDownline++;
        
        // FOR KK
        users[lastId].activeDownline = userAddress;
        users[userAddress].levelKK[1].isActive = true;
        lastId = userAddress;
        
        totalUsers[1]++;
        totalEarned += 500;
        KKHandler (userAddress, referrer, 1/*levelNumber*/);
    }
    
    /*****************************************
     *          BUYING A NEW LEVEL          *
    *****************************************/
    function buyLevel (uint8 levelNumber) external payable {
        require (userExists(msg.sender), "User Does Not Exist!");
        require (levelNumber >= 1 && levelNumber <= MAX_LEVEL, "Invalid Level Selected!");
        
        require (!users[msg.sender].activeLevelsKK[levelNumber], "Level Already Activated!");
        require (msg.value == levelPrices[levelNumber], "Invalid level Price!");
        if (levelNumber > 1)
            require (users[msg.sender].activeLevelsKK[levelNumber - 1], "Previous Level Not Activated!");
            
        totalEarned += (levelPrices[levelNumber] / 1000000);
        
        users[msg.sender].levelKK[levelNumber].isActive = true;
        totalUsers[(levelNumber - 1)] = totalUsers[(levelNumber - 1)] - 1;
        totalUsers[levelNumber] = totalUsers[levelNumber] + 1;
        
        users[lastId].activeDownline = msg.sender;
        
        // Managing Previous Referrer & Gap
        address previous = users[msg.sender].activeUpline;
        users[previous].activeDownline = users[msg.sender].activeDownline;
        users[users[msg.sender].activeDownline].activeUpline = previous;
        
        users[msg.sender].activeLevelsKK[levelNumber] = true;
        
        users[msg.sender].activeDownline = address(0);
        if (msg.sender != lastId)
            users[msg.sender].activeUpline = lastId;
        
        lastId = msg.sender;
        KKHandler (msg.sender, usersList[users[msg.sender].referrerId], levelNumber);
        
        // EVENT CALL FOR UPGRADEING PACKAGE
        emit Upgrade (msg.sender, users[msg.sender].activeUpline, 2, levelNumber);
    }
    
    function KKHandler (address userAddress, address referrerAddress, uint8 levelNumber) private {
        address referrer = referrerAddress;
        uint8 level = levelNumber;
        
        users[referrerAddress].levelKK[levelNumber].totalPartners++;
        
        // Sending TRX
        sendETHKK (referrerAddress, userAddress, levelNumber, 50);
        sendETHKK (owner, userAddress, levelNumber, 20);
        
        // 1
        referrer = users[userAddress].activeUpline;
        for (uint8 i = 0; i < levelNumber; i++) {
            if (users[referrer].activeLevelsKK[level] == true)
                break;
            level--;
        }
        sendETHKK (referrer, userAddress, level, 5);
        if (level < levelNumber) {
            uint price = levelPrices[levelNumber] - levelPrices[level];
            sendMissedTrx (first_id, userAddress, ((price * 5) / 100));
        }
        level = levelNumber;
        // 2
        referrer = users[referrer].activeUpline;
        for (uint8 i = 0; i < levelNumber; i++) {
            if (users[referrer].activeLevelsKK[level] == true)
                break;
            level--;
        }
        sendETHKK (referrer, userAddress, level, 5);
        if (level < levelNumber) {
            uint price = levelPrices[levelNumber] - levelPrices[level];
            sendMissedTrx (first_id, userAddress, ((price * 5) / 100));
        }
        level = levelNumber;
        // 3
        referrer = users[referrer].activeUpline;
        for (uint8 i = 0; i < levelNumber; i++) {
            if (users[referrer].activeLevelsKK[level] == true)
                break;
            level--;
        }
        sendETHKK (referrer, userAddress, level, 5);
        if (level < levelNumber) {
            uint price = levelPrices[levelNumber] - levelPrices[level];
            sendMissedTrx (first_id, userAddress, ((price * 5) / 100));
        }
        level = levelNumber;
        // 4
        referrer = users[referrer].activeUpline;
        for (uint8 i = 0; i < levelNumber; i++) {
            if (users[referrer].activeLevelsKK[level] == true)
                break;
            level--;
        }
        sendETHKK (referrer, userAddress, level, 3);
        if (level < levelNumber) {
            uint price = levelPrices[levelNumber] - levelPrices[level];
            sendMissedTrx (first_id, userAddress, ((price * 3) / 100));
        }
        level = levelNumber;
        // 5
        referrer = users[referrer].activeUpline;
        for (uint8 i = 0; i < levelNumber; i++) {
            if (users[referrer].activeLevelsKK[level] == true)
                break;
            level--;
        }
        sendETHKK (referrer, userAddress, level, 2);
        if (level < levelNumber) {
            uint price = levelPrices[levelNumber] - levelPrices[level];
            sendMissedTrx (first_id, userAddress, ((price * 2) / 100));
        }
        level = levelNumber;
        // 6 - 10
        for (int i = 0; i < 5; i++) {
            referrer = users[referrer].activeUpline;
            for (uint8 j = 0; j < levelNumber; j++) {
                if (users[referrer].activeLevelsKK[level] == true)
                    break;
                level--;
            }
            sendETHKK (referrer, userAddress, level, 1);
            if (level < levelNumber) {
                uint price = levelPrices[levelNumber] - levelPrices[level];
                sendMissedTrx (first_id, userAddress, ((price * 1) / 100));
            }
            level = levelNumber;
        }
        // sendGlobalPool (userAddress, levelNumber);
    }
    
    /*****************************************
     *           SENDING TRON           *
    *****************************************/
    function sendETHKK (address userAddress, address _from, uint8 levelNumber, uint8 percentage) private {
        if (userAddress == owner) {
            address(uint160(owner)).transfer((levelPrices[levelNumber] * percentage / 4) / 100);
            address(uint160(wallet_one)).transfer((levelPrices[levelNumber] * percentage / 4) / 100);
            address(uint160(wallet_two)).transfer((levelPrices[levelNumber] * percentage / 4) / 100);
            address(uint160(wallet_three)).transfer((levelPrices[levelNumber] * percentage / 4) / 100);
            
            users[userAddress].levelKK[levelNumber].totalEarned += ((levelPrices[levelNumber] * 20) / 100);
            
            emit SendETHEvent (_from, userAddress, levelNumber);
            return;
        }
        
        users[userAddress].levelKK[levelNumber].totalEarned += ((levelPrices[levelNumber] * percentage) / 100);
        
        address(uint160(userAddress)).transfer((levelPrices[levelNumber] * percentage) / 100);
    }
    function sendMissedTrx (address userAddress, address _from, uint price) private {
        address(uint160(userAddress)).transfer(price);
        
        emit MissedEthReceive (userAddress, _from, price);
    }
     function sendGlobalPool () external {
         require(msg.sender == owner || msg.sender == wallet_one || msg.sender == wallet_two || msg.sender == wallet_three, "Authorization Error!");
         require (now >= time + 24 hours, "Smart Contract is only called once in 24 hours");
         
        uint price = (address(this).balance);
        uint8 j;
         
        uint categoryOne = totalUsers[1]+totalUsers[2]+totalUsers[3]+totalUsers[4]+totalUsers[5];
        uint categoryTwo = totalUsers[6]+totalUsers[7]+totalUsers[8]+totalUsers[9];
        uint categoryThree = totalUsers[10]+totalUsers[11]+totalUsers[12];
        
        for (uint i = 1; i < idGenerator; i++) {
            if (address(this).balance > 10 trx) {
                for (j = 1; j <= MAX_LEVEL; j++)
                    if (!users[usersList[i]].activeLevelsKK[j])
                       break;
                
                if (j < MAX_LEVEL)
                   j--;
               
                if (j >= 1 && j <= 5)
                   address(uint160(usersList[i])).transfer(((price * 20) / 100) / categoryOne);
                else if (j > 5 && j <= 9)
                   address(uint160(usersList[i])).transfer(((price * 30) / 100) / categoryTwo);
                else if (j > 9 && j <= 12)
                   address(uint160(usersList[i])).transfer(((price * 50) / 100) / categoryThree);
            }
        }
        
        time = now;
     }
    
    /*****************************************
     *       CHECKING IF A USER EXISTS      *
    *****************************************/
    function userExists (address check) public view returns (bool) {
        return (users[check].userId != 0);
    }
    function idToAddress (uint userId) public view returns (address) {
        return usersList[userId];
    }
    function addressToId (address userAddress) public view returns (uint) {
        return users[userAddress].userId;
    }
    
    function initLevelPrices () private {
        levelPrices[1] = 500 trx;
        levelPrices[2] = 1000 trx;
        levelPrices[3] = 2500 trx;
        levelPrices[4] = 5000 trx;
        levelPrices[5] = 10000 trx;
        levelPrices[6] = 25000 trx;
        levelPrices[7] = 50000 trx;
        levelPrices[8] = 100000 trx;
        levelPrices[9] = 250000 trx;
        levelPrices[10] = 500000 trx;
        levelPrices[11] = 1000000 trx;
        levelPrices[12] = 2500000 trx;
    }
    
    /*****************************************
     *                GETTERS               *
    *****************************************/
    function getDetails () public view returns (uint, uint, uint) {
        return (idGenerator,
                totalEarned,
                (address(this).balance));
    }
    function getUserDetails (address userAddress) public view returns (uint, uint, uint, address, address) {
        return (users[userAddress].userId,
                users[userAddress].referrerId,
                users[userAddress].totalDownline,
                users[userAddress].activeUpline,
                users[userAddress].activeDownline);
    }
    function getPackageDetails (address userAddress, uint8 levelNumber) public view returns (uint, uint, bool) {
        return (users[userAddress].levelKK[levelNumber].totalEarned,
                users[userAddress].levelKK[levelNumber].totalPartners,
                users[userAddress].levelKK[levelNumber].isActive);
    }
    
    function bytesToAddress (bytes memory check) private pure returns (address val) {
        assembly {
            val := mload (add (check, 20))
        }
    }
}