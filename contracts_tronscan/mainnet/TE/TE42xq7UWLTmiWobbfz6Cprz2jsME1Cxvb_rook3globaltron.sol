//SourceUnit: rookx3globaltron.sol

pragma solidity >=0.5.0 <0.6.1;

contract rook3globaltron {
    struct Queue {
        uint256 first;
        uint256 last;
        mapping(uint256 => address) queue;
    }
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeNoRLevels;
        mapping(uint8 => uint) noRReinvestCount;
    }
    
    struct NoR {
        address currentUser;
        address[] referrals;
        uint reinvestCount;
    }

    uint8 public constant LAST_LEVEL = 15;
    uint Registration_fees;
    
    mapping(uint8 => NoR) public xNoRMatrix;
    mapping(uint8 => Queue) public noRQueue;

    mapping(address => User) public users;
    mapping(address => uint) public addressToId;
    
    mapping (uint => address) public userList;

    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;

    uint public lastUserId = 4;
    address public owner;
    address public deployer;
	address public owner2;
	address public leader;
    
    bool public openPublicRegistration;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerID);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event Reinvest(address indexed user, address indexed currentUser, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Referral(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress, address owner2Address, address leaderAddress) public {
        Registration_fees = 50 trx;
        levelPrice[1] = 50 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        deployer = msg.sender;
		owner2 = owner2Address;
		leader = leaderAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        addressToId[ownerAddress] = 1;
        addressToId[owner2Address] = 2;
        addressToId[leaderAddress] = 3;
        

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeNoRLevels[i] = true;
            users[owner2Address].activeNoRLevels[i] = true;
            
            xNoRMatrix[i] = NoR({
                currentUser: owner,
                referrals: new address[](0),
                reinvestCount: uint(0)
            });
            noRQueue[i] = Queue({
                first: 1,
                last: 0
            });
        }

        userIds[1] = ownerAddress;   
        userIds[2] = owner2Address; 

		for (uint8 i = 1; i <= 8; i++) {
            users[leaderAddress].activeNoRLevels[i] = true;
            
            xNoRMatrix[i] = NoR({
                currentUser: owner,
                referrals: new address[](0),
                reinvestCount: uint(0)
            });
            noRQueue[i] = Queue({
                first: 1,
                last: 0
            });
        }
    
        userIds[3] = leaderAddress;

    }
	
	   
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }
    
    function preRegistrationExt(address userAddress, address referrerAddress) public payable
    {
        require(!openPublicRegistration,"Normal mode started");
        require(msg.sender==deployer);
        registration(userAddress,referrerAddress);
    }

    function registrationExt(address referrerAddress) external payable returns(string memory) {
        registration(msg.sender, referrerAddress);
        return "registration successful";
    }
      
    function setContractFlag() public 
    {
        require(msg.sender == deployer);
        openPublicRegistration=true;
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable returns(string memory) {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeNoRLevels[level], "level already activated");
            require(users[msg.sender].activeNoRLevels[level-1], "You need to activate previous level to buy this one");

            enqueueToNoR(level, msg.sender);
            users[msg.sender].activeNoRLevels[level] = true;

            updateNoReinvestReferrer(msg.sender, level);
            
            emit Upgrade(msg.sender, xNoRMatrix[level].currentUser, 1, level);

        }
        return "Level bought successfully";
    }
    
    function registration(address userAddress, address referrerAddress) private {
        
        require(msg.value == (levelPrice[1] + Registration_fees), "Invalid registration amount");    
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
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeNoRLevels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        
        if (!address(uint160(referrerAddress)).send(50 trx)) {
                 
            }
            else
            {
                emit Referral(msg.sender, referrerAddress, 0, 0);
            }

        enqueueToNoR(1, userAddress);
        updateNoReinvestReferrer(userAddress, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateNoReinvestReferrer(address userAddress, uint8 level) private {
        xNoRMatrix[level].referrals.push(userAddress);
        emit NewUserPlace(userAddress, xNoRMatrix[level].currentUser, 1, level, uint8(xNoRMatrix[level].referrals.length));
        if (xNoRMatrix[level].referrals.length < 3) {
            sendETHDividends(xNoRMatrix[level].currentUser, userAddress, 1, level);
            return;
        }

        address previousUser = xNoRMatrix[level].currentUser;
        users[xNoRMatrix[level].currentUser].noRReinvestCount[level]++;
        
        xNoRMatrix[level].referrals = new address[](0);
        xNoRMatrix[level].currentUser = dequeueToNoR(level);

        emit Reinvest(previousUser, xNoRMatrix[level].currentUser, userAddress, 3, level);

        enqueueToNoR(level, previousUser);
        updateNoReinvestReferrer(previousUser, level);
    }

    function usersActiveNoRLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeNoRLevels[level];
    }
    
    function usersNoRReinvestCount(address userAddress, uint8 level) public view returns(uint) {
        return users[userAddress].noRReinvestCount[level];
    }

    function getXNoRMatrix(uint8 level) public view returns(address, address[] memory) {
        return (xNoRMatrix[level].currentUser,
                xNoRMatrix[level].referrals
            );
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            return (receiver, false);
            }
        }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) { 
            return address(uint160(receiver)).transfer(address(this).balance);
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
    
    function enqueueToNoR(uint8 level, address item) private {
        noRQueue[level].last += 1;
        noRQueue[level].queue[noRQueue[level].last] = item;
    }

    function dequeueToNoR(uint8 level) private
    returns (address data) {
        if(noRQueue[level].last >= noRQueue[level].first) {
            data = noRQueue[level].queue[noRQueue[level].first];
            delete noRQueue[level].queue[noRQueue[level].first];
            noRQueue[level].first += 1;
        }
    }
}