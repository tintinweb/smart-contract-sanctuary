//SourceUnit: tron.sol

/*
 $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$$\ $$$$$$$\   $$$$$$\  $$\   $$\ 
$$  __$$\ $$  __$$\ $$  _____|\__$$  __|$$  __$$\ $$  __$$\ $$$\  $$ |
$$ /  \__|$$ /  $$ |$$ |         $$ |   $$ |  $$ |$$ /  $$ |$$$$\ $$ |
$$ |      $$ |  $$ |$$$$$\       $$ |   $$$$$$$  |$$ |  $$ |$$ $$\$$ |
$$ |      $$ |  $$ |$$  __|      $$ |   $$  __$$< $$ |  $$ |$$ \$$$$ |
$$ |  $$\ $$ |  $$ |$$ |         $$ |   $$ |  $$ |$$ |  $$ |$$ |\$$$ |
\$$$$$$  | $$$$$$  |$$ |         $$ |   $$ |  $$ | $$$$$$  |$$ | \$$ |
 \______/  \______/ \__|         \__|   \__|  \__| \______/ \__|  \__|                                                                                                                                                                                                                                                            
*/

pragma solidity 0.5.9;

contract ChainOfFavors {
    
    struct User {
        uint id;
        address referrer;
        uint inviteCounts;
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => theMatrix) Matrix;
    }
    
    struct theMatrix {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint256 reinvestCount;
    }


    uint8 public constant LAST_LEVEL = 24;
    
    mapping(address => User) public usersData;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 1;
    address public doner;
    address private owner1;
    address private owner2;
    address private owner3;
    address private owner4;
    address public deployer;
    uint256 public contractDeployTime;
    
    mapping(uint256 => uint256) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint amount);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level, uint amount);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 level);
    
    
    constructor(address donerAddress, address Owner1,  address Owner2,  address Owner3,  address Owner4) public {
        levelPrice[1] = 250 * 1e6;
        uint256 x = 0;
        for (uint256 i = 0; i < 6; i++) {
        for (uint256 j = 0; j < 4; j++) {
            x+=1;
            levelPrice[x] = (levelPrice[1] * uint256(2) ** j) * (uint256(10) ** i);
        }
        }
        uint8 i;
        deployer = msg.sender;
        doner = donerAddress;
        owner1 = Owner1;
        owner2 = Owner2;
        owner3 = Owner3;
        owner4 = Owner4;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            inviteCounts: uint(0)
        });
        
        usersData[donerAddress] = user;
        idToAddress[1] = donerAddress;
        
        for (i = 1; i <= LAST_LEVEL; i++) {
            usersData[donerAddress].activeLevels[i] = true;
        }

        userIds[1] = donerAddress;
        
        contractDeployTime = now;
        
        emit Registration(donerAddress, address(0), 1, 0, 0);
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, doner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable returns(string memory) {
        registration(msg.sender, referrerAddress);
        return "successfully registered";
    }
        
    function buyNewLevel(uint8 level) external payable returns(string memory) {
        buyNewLevelInternal(msg.sender, level);
        return "level bought successfully";
    }
    
    function buyNewLevelInternal(address user, uint8 level) private {
        require(isUserExists(user), "unknown user");
        if(!(msg.sender==deployer)) require(msg.value == levelPrice[level], "incorrect price");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        if (levelPrice[level] % 25 == 0 && level != 1) {
            require(usersData[user].activeLevels[1], "unavailable vertical level");
        } 
            
        if (levelPrice[level] % 25 != 0 && level > 1) {
            require(usersData[user].activeLevels[1], "unavailable horizontal level");
        } 
        

            require(!usersData[user].activeLevels[level], "level already activated");

            if (usersData[user].Matrix[level-1].blocked) {
                usersData[user].Matrix[level-1].blocked = false;
            }
    
            address freeReferrer = findFreeReferrer(user, level);
            usersData[user].Matrix[level].currentReferrer = freeReferrer;
            usersData[user].activeLevels[level] = true;
            updateReferrer(user, freeReferrer, level, msg.value);
            
            emit Upgrade(user, freeReferrer, level, msg.value);

    }    
    
    function registration(address userAddress, address referrerAddress) private {
        if(!(msg.sender==deployer)) require(msg.value == 50 * 1e6, "incorrect registration amount");       
        require(!isUserExists(userAddress), "you are already registered");
        require(isUserExists(referrerAddress), "unknown referrer");
        address(uint160(owner1)).transfer((50 * 1e6) / 4);
        address(uint160(owner2)).transfer((50 * 1e6) / 4);
        address(uint160(owner3)).transfer((50 * 1e6) / 4);
        address(uint160(owner4)).transfer((50 * 1e6) / 4);
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        lastUserId++;
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            inviteCounts: 0
        });
        
        usersData[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        usersData[userAddress].referrer = referrerAddress;
        
        userIds[lastUserId] = userAddress;
        
        
        usersData[referrerAddress].inviteCounts++;

        address freeReferrer = findFreeReferrer(userAddress, 1);
        usersData[userAddress].Matrix[1].currentReferrer = freeReferrer;
        
        emit Registration(userAddress, referrerAddress, usersData[userAddress].id, usersData[referrerAddress].id, msg.value);
    }
    
    function updateReferrer(address userAddress, address referrerAddress, uint8 level, uint256 trxAmount) private {
        usersData[referrerAddress].Matrix[level].referrals.push(userAddress);

        if (usersData[referrerAddress].Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(usersData[referrerAddress].Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, level, trxAmount);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, level, 3);
        usersData[referrerAddress].Matrix[level].referrals = new address[](0);
        if (!usersData[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            usersData[referrerAddress].Matrix[level].blocked = true;
        }

        if (referrerAddress != doner) {
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
            if (usersData[referrerAddress].Matrix[level].currentReferrer != freeReferrerAddress) {
                usersData[referrerAddress].Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            usersData[referrerAddress].Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
            updateReferrer(referrerAddress, freeReferrerAddress, level, trxAmount);
        } else {
            sendETHDividends(doner, userAddress, level, trxAmount);
            usersData[doner].Matrix[level].reinvestCount++;
            emit Reinvest(doner, address(0), userAddress, level);
        }
    }
    
    function findFreeReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (usersData[usersData[userAddress].referrer].activeLevels[level]) {
                return usersData[userAddress].referrer;
            }
            
            userAddress = usersData[userAddress].referrer;
        }
    }

        
    function usersDataActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return usersData[userAddress].activeLevels[level];
    }


    function usersDataMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint256) {
        return (usersData[userAddress].Matrix[level].currentReferrer,
                usersData[userAddress].Matrix[level].referrals,
                usersData[userAddress].Matrix[level].blocked,
                usersData[userAddress].Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (usersData[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
            while (true) {
                if (usersData[receiver].Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, level);
                    isExtraDividends = true;
                    receiver = usersData[receiver].Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
    }

    function sendETHDividends(address userAddress, address _from, uint8 level, uint256 trxAmount) private {
        if(msg.sender!=deployer)
        {
            (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, level);


            if (address(uint160(receiver)) == address(uint160(doner))) {
                address(uint160(owner1)).transfer(trxAmount / 4);
                address(uint160(owner2)).transfer(trxAmount / 4);
                address(uint160(owner3)).transfer(trxAmount / 4);
                return address(uint160(owner4)).transfer(trxAmount / 4);
            }
            
            if (!address(uint160(receiver)).send(levelPrice[level])) {
                return address(uint160(receiver)).transfer(address(this).balance);
            }
        
            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, level);
            }
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function viewLevels(address user) public view returns (bool[12] memory Levels,uint8 LastTrue)
    {
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            Levels[i] = usersData[user].activeLevels[i];
            if(Levels[i]) LastTrue = i;
        }
    }


    

}