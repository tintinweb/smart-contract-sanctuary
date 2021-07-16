//SourceUnit: SkrepitMatrix.sol

pragma solidity 0.5.10;

/*
 ____  _  ______  _____ ____ ___ _____   __  __    _  _____ ____  _____  __
/ ___|| |/ /  _ \| ____|  _ \_ _|_   _| |  \/  |  / \|_   _|  _ \|_ _\ \/ /
\___ \| ' /| |_) |  _| | |_) | |  | |   | |\/| | / _ \ | | | |_) || | \  / 
 ___) | . \|  _ <| |___|  __/| |  | |   | |  | |/ ___ \| | |  _ < | | /  \ 
|____/|_|\_\_| \_\_____|_|  |___| |_|   |_|  |_/_/   \_\_| |_| \_\___/_/\_\
                                                                           
*/

contract TRC20{
  function transfer(address _to, uint _value) public returns (bool) {
  }
}

contract SkrepitMatrix {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;

        uint x3Income;
        uint x6Income;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;

        mapping(uint8 => bool) x3CoinPaidLevels;
        mapping(uint8 => bool) x6CoinPaidLevels;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 10;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 0;
    address public doner;
    address public operator;
    
    uint256 public contractDeployTime;
    uint256 public launchTime;
    
    mapping(uint8 => uint) public levelPrice;

    uint public firstLevelPrice = 500 * 1e6;

    uint public x3CoinsPerLevel = 100 * 1e6;
    uint public x6CoinsPerLevel = 50 * 1e6;

    uint public registrationCoins = 1000 * 1e6;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint amount);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint amount);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    address public SKRTTokenContract;


    uint public totalTRX = 0;
    uint public totalSKRT = 0;

    modifier isOperator(){
        require(msg.sender == operator, "OperatorOnly function");
        _;
    }
    
    constructor() public {
        levelPrice[1] = firstLevelPrice;
        uint8 i;
        for (i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        operator = msg.sender;
        address donerAddress = msg.sender;

        doner = donerAddress;
        
        contractDeployTime = now;
        launchTime = now;    
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, doner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable returns(string memory) {
        require(now > launchTime, "Not started yet");
        registration(msg.sender, referrerAddress);
        return "registration successful";
    }
    
    function registrationCreator(address userAddress, address referrerAddress) external isOperator returns(string memory) {
        require(contractDeployTime+86400 > now, 'This function is only available for first 24 hours' );
        registration(userAddress, referrerAddress);
        return "registration successful";
    }
    
    function buyLevelCreator(address userAddress, uint8 matrix, uint8 level) external isOperator returns(string memory) {
        require(contractDeployTime+86400 > now, 'This function is only available for first 24 hours' );
        buyNewLevelInternal(userAddress, matrix, level);
        return "Level bought successfully";
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable returns(string memory) {
        buyNewLevelInternal(msg.sender, matrix, level);
        return "Level bought successfully";
    }
    
    function buyNewLevelInternal(address user, uint8 matrix, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if(!(msg.sender==operator)) require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[user].activeX3Levels[level], "level already activated");

            if (users[user].x3Matrix[level-1].blocked) {
                users[user].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(user, level);
            users[user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[user].activeX3Levels[level] = true;
            updateX3Referrer(user, freeX3Referrer, level);
            
            emit Upgrade(user, freeX3Referrer, 1, level, msg.value);

        } else {
            require(!users[user].activeX6Levels[level], "level already activated"); 

            if (users[user].x6Matrix[level-1].blocked) {
                users[user].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(user, level);
            
            users[user].activeX6Levels[level] = true;
            updateX6Referrer(user, freeX6Referrer, level);
            
            emit Upgrade(user, freeX6Referrer, 2, level, msg.value);
        }
        totalTRX += msg.value;
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        if(!(msg.sender==operator)) require(msg.value == (levelPrice[1]*2), "Invalid registration amount");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        lastUserId++;
    
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            x3Income: 0,
            x6Income: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
        sendToken(userAddress, registrationCoins);

        totalTRX += msg.value;
        totalSKRT += registrationCoins;

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, msg.value);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != doner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;

            if(!users[referrerAddress].x3CoinPaidLevels[level]){
              sendToken(referrerAddress, level*x3CoinsPerLevel);
              totalSKRT += level*x3CoinsPerLevel;
              users[referrerAddress].x3CoinPaidLevels[level] = true;
            }

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(doner, userAddress, 1, level);
            users[doner].x3Matrix[level].reinvestCount++;
            emit Reinvest(doner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == doner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;

        if (referrerAddress != doner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            if(!users[referrerAddress].x6CoinPaidLevels[level]){
              sendToken(referrerAddress, level*x6CoinsPerLevel);
              users[referrerAddress].x6CoinPaidLevels[level] = true;
            }

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(doner, address(0), userAddress, 2, level);
            sendETHDividends(doner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount
        );
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x3Matrix[level].reinvestCount
                );
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
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendToken(address toAddress, uint amount) private{
      TRC20(SKRTTokenContract).transfer(toAddress, amount);
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        if(msg.sender!=operator)
        {
            (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

            if(receiver == address(0)){
                receiver = operator;
            }

            if (!address(uint160(receiver)).send(levelPrice[level])) {
                return address(uint160(receiver)).transfer(address(this).balance);
            }
        
            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }

            if(matrix == 1){
                users[receiver].x3Income += levelPrice[level];
            }else{
                users[receiver].x6Income += levelPrice[level];
            }

        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function viewInfo(address user) public view returns (
        bool[10] memory x3Levels, 
        bool[10] memory x6Levels, 
        uint[10] memory x3Count,
        uint[10] memory x6Count,
        uint[4] memory userInfo,
        uint[4] memory SCInfo,
        address[3][10] memory x3Referrals,
        address[3][10] memory x6ReferralsL1,
        address[6][10] memory x6ReferralsL2
    )
    {
        for (uint i = 0; i < LAST_LEVEL; i++) {
            x3Levels[i] = users[user].activeX3Levels[uint8(i)+1];
            x6Levels[i] = users[user].activeX6Levels[uint8(i)+1];

            x3Count[i] = users[user].x3Matrix[uint8(i)+1].reinvestCount;
            x6Count[i] = users[user].x3Matrix[uint8(i)+1].reinvestCount;

            for(uint j=0; j < users[user].x3Matrix[uint8(i)+1].referrals.length; j++){
                x3Referrals[i][j] = users[user].x3Matrix[uint8(i)+1].referrals[j];
            }

            for(uint j=0; j < users[user].x6Matrix[uint8(i)+1].firstLevelReferrals.length; j++){
                x6ReferralsL1[i][j] = users[user].x6Matrix[uint8(i)+1].firstLevelReferrals[j];
            }

            for(uint j=0; j < users[user].x6Matrix[uint8(i)+1].secondLevelReferrals.length; j++){
                x6ReferralsL2[i][j] = users[user].x6Matrix[uint8(i)+1].secondLevelReferrals[j];
            }
            
        }
        userInfo[0] = users[user].id;
        userInfo[1] = users[user].partnersCount;
        userInfo[2] = users[user].x3Income;
        userInfo[3] = users[user].x6Income;

        SCInfo[0] = totalTRX;
        SCInfo[1] = totalSKRT;
        SCInfo[2] = address(this).balance;
        SCInfo[3] = lastUserId;
    }

    function updateOperator(address addr) external isOperator returns (bool) {
        require(addr != address(0));
        if(users[addr].id > 0){
            operator = addr;
            return true;
        }
        lastUserId ++;
        User memory user = User({
            id: lastUserId,
            referrer: address(0),
            partnersCount: uint(0),
            x3Income: uint(0),
            x6Income: uint(0)
        });
        
        users[addr] = user;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[addr].activeX3Levels[i] = true;
            users[addr].activeX6Levels[i] = true;
        }

        userIds[lastUserId] = addr;
        idToAddress[lastUserId] = addr;

        emit Registration(addr, address(0), users[addr].id, 0, 0);

        operator = addr;
        doner = addr;
        return true;
    }

    function updateLaunchTime(uint256 epoch) external isOperator returns (bool) {
        launchTime = epoch;
        return true;
    }

    function setSKRTTokenContract(address addr) external isOperator returns (bool) {
      require(addr != address(0));
      SKRTTokenContract = addr;
      return true;
    }

    function withdrawTokens(uint256 amount) external isOperator{
        TRC20(SKRTTokenContract).transfer(msg.sender, amount);
    }
}