//SourceUnit: BlueCapitalSmartContract.sol

pragma solidity >=0.4.23 <0.6.0;

contract BlueCapitalMatrix {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;

        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX12Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X12) x12Matrix;
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

    struct X12 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint[] place;
        address[] thirdLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 10;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(address => uint) public balances;

    uint public lastUserId = 1;
    address public owner;
    address public deployer;
    uint256 public contractDeployTime;

    uint public constant TRX = 1e6;
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8  matrix, uint8 level, uint8 place, uint cycle);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event SentDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level, uint amount);


    constructor(address ownerAddress) public {
        deployer = msg.sender;
        owner = ownerAddress;

        User memory root = User({
            id: lastUserId,
            referrer: address(0),
            partnersCount: uint(0)
        });

        users[ownerAddress] = root;
        idToAddress[lastUserId] = ownerAddress;

        lastUserId++;

        emit Registration(ownerAddress, address(0), 1, 0);

        //Set level prices
        levelPrice[1] = 20*TRX;

        uint8 i;
        for (i = 1; i <= LAST_LEVEL; i++) {
            //Set level prices
            if(i > 1) {
                levelPrice[i] = levelPrice[i-1]*2;
            }

            //Initialize levels
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeX12Levels[i] = true;
        }

        contractDeployTime = now;
    }

    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable returns(uint) {
        registration(msg.sender, referrerAddress);
        return users[msg.sender].id;
    }

    function levelCreator(address userAddress, uint8 matrix, uint8 level) external returns(string memory) {
        require(msg.sender==deployer, 'Invalid Donor');
        require(contractDeployTime+86400 > now, 'This function is only available for first 24 hours' );
        buyNewLevelInternal(userAddress, matrix, level);
        return "Level bought successfully";
    }

    function buyNewLevelInternal(address user, uint8 matrix, uint8 level) internal {
        require(isUserExists(user), "user does not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix==3, "invalid matrix");
        if(!(msg.sender==deployer)) require(msg.value == levelPrice[level], "invalid price");
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

            emit Upgrade(user, freeX3Referrer, 1, level);

        } else if (matrix == 2) {
            require(!users[user].activeX6Levels[level], "level already activated");

            if (users[user].x6Matrix[level-1].blocked) {
                users[user].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(user, level);

            users[user].activeX6Levels[level] = true;
            updateX6Referrer(user, freeX6Referrer, level);

            emit Upgrade(user, freeX6Referrer, 2, level);
        } else {
            require(!users[user].activeX12Levels[level], "level already activated");

            if (users[user].x12Matrix[level-1].blocked) {
                users[user].x12Matrix[level-1].blocked = false;
            }

            address freeX12Referrer = findFreeX12Referrer(user, level);

            users[user].activeX12Levels[level] = true;
            updateX12Referrer(user, freeX12Referrer, level);

            emit Upgrade(user, freeX12Referrer, 3, level);
        }
    }

    function registrationCreator(address userAddress, address referrerAddress) external returns(string memory) {
        require(msg.sender==deployer, 'Invalid Donor');
        require(contractDeployTime+86400 > now, 'This function is only available for first 24 hours' );
        registration(userAddress, referrerAddress);
        return "registration successful";
    }

    function registration(address userAddress, address referrerAddress) private {
        if(!(msg.sender==deployer))  require(hasValidRegFee(msg.value), "Invalid registration amount");
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

        users[userAddress].activeX3Levels[1] = true;
        users[userAddress].activeX6Levels[1] = true;
        users[userAddress].activeX12Levels[1] = true;

        lastUserId++;

        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        updateX12Referrer(userAddress, findFreeX12Referrer(userAddress, 1), 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length), users[referrerAddress].x3Matrix[level].reinvestCount);

            if(
                users[referrerAddress].x3Matrix[level].reinvestCount == 1 &&
                referrerAddress != owner &&
                level != LAST_LEVEL &&
                !users[referrerAddress].activeX3Levels[level+1]
            ) {
                // run auto upgrade on 3rd cycle if the next level is not already bought
                // auto upgrade takes two dividend payments
                return autoUpgrade(referrerAddress, 1, level+1, users[referrerAddress].x3Matrix[level].referrals.length);
            }

            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3, users[referrerAddress].x3Matrix[level].reinvestCount);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
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

    function autoUpgrade(address userAddress, uint8 matrix, uint8 level, uint256 refLength) private {
        if(matrix == 1) {
            if(refLength == 2) {
                address freeX3Referrer = findFreeX3Referrer(userAddress, level);
                users[userAddress].x3Matrix[level].currentReferrer = freeX3Referrer;
                users[userAddress].activeX3Levels[level] = true;
                updateX3Referrer(userAddress, freeX3Referrer, level);

                emit Upgrade(userAddress, freeX3Referrer, 1, level);
            }
        }

        if(matrix == 2) {
            if(refLength == 3) {
                address freeX6Referrer = findFreeX6Referrer(userAddress, level);

                users[userAddress].activeX6Levels[level] = true;
                updateX6Referrer(userAddress, freeX6Referrer, level);

                emit Upgrade(userAddress, freeX6Referrer, 2, level);
            }
        }

        if(matrix == 3) {
            if(refLength == 4) {
                address freeX12Referrer = findFreeX12Referrer(userAddress, level);

                users[userAddress].activeX12Levels[level] = true;
                updateX12Referrer(userAddress, freeX12Referrer, level);

                emit Upgrade(userAddress, freeX12Referrer, 3, level);
            }
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(
                userAddress, referrerAddress, 2, level,
                uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length),
                users[referrerAddress].x6Matrix[level].reinvestCount
            );

            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress);

            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;

            if ((len == 2) &&
            (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, users[ref].x6Matrix[level].reinvestCount);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, users[ref].x6Matrix[level].reinvestCount);
                }
            }  else if ((len == 1 || len == 2) &&
                users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3, users[ref].x6Matrix[level].reinvestCount);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4, users[ref].x6Matrix[level].reinvestCount);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, users[ref].x6Matrix[level].reinvestCount);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, users[ref].x6Matrix[level].reinvestCount);
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
            emit NewUserPlace(
                userAddress,
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],
                2,
                level,
                uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),
                users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].reinvestCount
            );
            emit NewUserPlace(
                userAddress, referrerAddress, 2, level,
                2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),
                users[referrerAddress].x6Matrix[level].reinvestCount
            );
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(
                userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level,
                uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),
                users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].reinvestCount
            );
            emit NewUserPlace(
                userAddress, referrerAddress, 2, level,
                4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),
                users[referrerAddress].x6Matrix[level].reinvestCount
            );
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }

    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            // do autoUpgrade
            if(
                users[referrerAddress].x6Matrix[level].reinvestCount == 1 &&
                referrerAddress != owner &&
                level != LAST_LEVEL &&
                !users[referrerAddress].activeX6Levels[level+1] &&
                (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 2 ||
                users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 3)
            ) {
                // run auto upgrade on 3rd cycle if the next level is not already bought
                // auto upgrade takes two dividend payments
                return autoUpgrade(referrerAddress, 2, level+1, users[referrerAddress].x6Matrix[level].secondLevelReferrals.length);
            }

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

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
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

    function usersActiveX12Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX12Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
        users[userAddress].x3Matrix[level].referrals,
        users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
        users[userAddress].x6Matrix[level].firstLevelReferrals,
        users[userAddress].x6Matrix[level].secondLevelReferrals,
        users[userAddress].x6Matrix[level].blocked,
        users[userAddress].x6Matrix[level].closedPart);
    }

    function usersX12Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,address[] memory, bool, address) {
        return (users[userAddress].x12Matrix[level].currentReferrer,
        users[userAddress].x12Matrix[level].firstLevelReferrals,
        users[userAddress].x12Matrix[level].secondLevelReferrals,
        users[userAddress].x12Matrix[level].thirdLevelReferrals,
        users[userAddress].x12Matrix[level].blocked,
        users[userAddress].x12Matrix[level].closedPart);
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
        } else if (matrix == 2){
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else{
            while (true) {
                if (users[receiver].x12Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 3, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x12Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }

    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        if(msg.sender!=deployer) {
            (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

            uint amount = levelPrice[level];

            if (!address(uint160(receiver)).send(amount)) {
                amount = address(this).balance;
                return address(uint160(receiver)).transfer(amount);
            }

            emit SentDividends(_from, receiver, matrix, level, amount);

            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }


    /*  12X */
    function updateX12Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX12Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x12Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(
                userAddress, referrerAddress, 3, level,
                uint8(users[referrerAddress].x12Matrix[level].firstLevelReferrals.length),
                users[referrerAddress].x12Matrix[level].reinvestCount
            );

            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 3, level);
            }

            address ref = users[referrerAddress].x12Matrix[level].currentReferrer;
            users[ref].x12Matrix[level].secondLevelReferrals.push(userAddress);

            address ref1 = users[ref].x12Matrix[level].currentReferrer;
            users[ref1].x12Matrix[level].thirdLevelReferrals.push(userAddress);

            uint len = users[ref].x12Matrix[level].firstLevelReferrals.length;
            uint8 toppos=2;
            if(ref1!=address(0x0)){
                if(ref==users[ref1].x12Matrix[level].firstLevelReferrals[0]){
                    toppos=1;
                }else
                {
                    toppos=2;
                }
            }
            if ((len == 2) &&
            (users[ref].x12Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x12Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x12Matrix[level].place.push(5);
                    emit NewUserPlace(userAddress, ref, 3, level, 5, users[ref].x12Matrix[level].reinvestCount);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5, users[ref1].x12Matrix[level].reinvestCount);
                } else {
                    users[ref].x12Matrix[level].place.push(6);
                    emit NewUserPlace(userAddress, ref, 3, level, 6, users[ref].x12Matrix[level].reinvestCount);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5, users[ref1].x12Matrix[level].reinvestCount);
                }
            }  else
                if ((len == 1 || len == 2) &&
                    users[ref].x12Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length == 1) {
                        users[ref].x12Matrix[level].place.push(3);
                        emit NewUserPlace(userAddress, ref, 3, level, 3, users[ref].x12Matrix[level].reinvestCount);
                        emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+3, users[ref1].x12Matrix[level].reinvestCount);
                    } else {
                        users[ref].x12Matrix[level].place.push(4);
                        emit NewUserPlace(userAddress, ref, 3, level, 4, users[ref].x12Matrix[level].reinvestCount);
                        emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+4, users[ref1].x12Matrix[level].reinvestCount);
                    }
                } else if (len == 2 && users[ref].x12Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                    if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length == 1) {
                        users[ref].x12Matrix[level].place.push(5);
                        emit NewUserPlace(userAddress, ref, 3, level, 5, users[ref].x12Matrix[level].reinvestCount);
                        emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5, users[ref1].x12Matrix[level].reinvestCount);
                    } else {
                        users[ref].x12Matrix[level].place.push(6);
                        emit NewUserPlace(userAddress, ref, 3, level, 6, users[ref].x12Matrix[level].reinvestCount);
                        emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+6, users[ref1].x12Matrix[level].reinvestCount);
                    }
                }

            return updateX12ReferrerSecondLevel(userAddress, ref1, level);
        }
        if (users[referrerAddress].x12Matrix[level].secondLevelReferrals.length < 4) {
            users[referrerAddress].x12Matrix[level].secondLevelReferrals.push(userAddress);
            address secondref = users[referrerAddress].x12Matrix[level].currentReferrer;
            if(secondref==address(0x0))
                secondref=owner;
            if (users[referrerAddress].x12Matrix[level].firstLevelReferrals[1] == userAddress) {
                updateX12(userAddress, referrerAddress, level, false);
                return updateX12ReferrerSecondLevel(userAddress, secondref, level);
            } else if (users[referrerAddress].x12Matrix[level].firstLevelReferrals[0] == userAddress) {
                updateX12(userAddress, referrerAddress, level, true);
                return updateX12ReferrerSecondLevel(userAddress, secondref, level);
            }

            if (users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length <
                2) {
                updateX12(userAddress, referrerAddress, level, false);
            } else {
                updateX12(userAddress, referrerAddress, level, true);
            }

            updateX12ReferrerSecondLevel(userAddress, secondref, level);
        }


        else  if (users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length < 8) {
            users[referrerAddress].x12Matrix[level].thirdLevelReferrals.push(userAddress);

            if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length<2) {
                updateX12Fromsecond(userAddress, referrerAddress, level, 0);
                return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length<2) {
                updateX12Fromsecond(userAddress, referrerAddress, level, 1);
                return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
            }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[2]].x12Matrix[level].firstLevelReferrals.length<2) {
                updateX12Fromsecond(userAddress, referrerAddress, level, 2);
                return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
            }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[3]].x12Matrix[level].firstLevelReferrals.length<2) {
                updateX12Fromsecond(userAddress, referrerAddress, level, 3);
                return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
            }

            //updateX12Fromsecond(userAddress, referrerAddress, level, users[referrerAddress].x12Matrix[level].secondLevelReferrals.length);


            updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    function updateX12(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdLevelReferrals.push(userAddress);

            emit NewUserPlace(
                userAddress, users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], 3, level,
                uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length),
                users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].reinvestCount
            );
            emit NewUserPlace(
                userAddress, referrerAddress, 3, level,
                2 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length),
                users[referrerAddress].x12Matrix[level].reinvestCount
            );

            users[referrerAddress].x12Matrix[level].place.push(2 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length));

            if(referrerAddress!=address(0x0) && referrerAddress!=owner){
                if(users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].firstLevelReferrals[0]==referrerAddress)
                    emit NewUserPlace(
                        userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level,
                        6 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length),
                        users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount
                    );
                else
                    emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level,
                        (10 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length)),
                        users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount
                    );
                //set current level
            }
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[0];

        } else {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdLevelReferrals.push(userAddress);

            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], 3, level,
                uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length),
                users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].reinvestCount
            );
            emit NewUserPlace(
                userAddress, referrerAddress, 3, level,
                4 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length),
                users[referrerAddress].x12Matrix[level].reinvestCount
            );

            users[referrerAddress].x12Matrix[level].place.push(4 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length));

            if(referrerAddress!=address(0x0) && referrerAddress!=owner){
                if(users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].firstLevelReferrals[0]==referrerAddress)
                    emit NewUserPlace(
                        userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level,
                        8 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length),
                        users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount
                    );
                else
                    emit NewUserPlace(
                        userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level,
                        12 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length),
                        users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount
                    );
            }
            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[1];
        }
    }

    function updateX12Fromsecond(address userAddress, address referrerAddress, uint8 level,uint pos) private {
        users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.push(userAddress);
        address currentRef = users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer;

        users[currentRef].x12Matrix[level].secondLevelReferrals.push(userAddress);


        uint8 len=uint8(users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.length);

        uint temppos=users[referrerAddress].x12Matrix[level].place[pos];
        emit NewUserPlace(userAddress, referrerAddress, 3, level,uint8(((temppos)*2)+len), users[referrerAddress].x12Matrix[level].reinvestCount); //third position

        if(temppos<5){
            emit NewUserPlace(
                userAddress, currentRef, 3, level,uint8((((temppos-3)+1)*2)+len),
                users[currentRef].x12Matrix[level].reinvestCount
            );
            users[currentRef].x12Matrix[level].place.push((((temppos-3)+1)*2)+len);
        }else{
            emit NewUserPlace(
                userAddress, currentRef,
                3, level,uint8((((temppos-3)-1)*2)+len),
                users[currentRef].x12Matrix[level].reinvestCount
            );
            users[currentRef].x12Matrix[level].place.push((((temppos-3)-1)*2)+len);
        }
        emit NewUserPlace(
            userAddress, users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], 3, level, len,
            users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].reinvestCount
        ); //first position
        //set current level

        users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos];


    }

    function updateX12ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==address(0x0)){
            return sendETHDividends(owner, userAddress, 3, level);
        }
        if (users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length < 8) {
            // do autoUpgrade
            if(
                users[referrerAddress].x12Matrix[level].reinvestCount == 1 &&
                referrerAddress != owner &&
                level != LAST_LEVEL &&
                !users[referrerAddress].activeX12Levels[level+1] &&
                (users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length == 3 ||
                users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length == 4)
            ) {
                // run auto upgrade on 3rd cycle if the next level is not already bought
                // auto upgrade takes two dividend payments
                return autoUpgrade(referrerAddress, 3, level+1, users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length);
            }

            return sendETHDividends(referrerAddress, userAddress, 3, level);
        }

        address[] memory x12 = users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].firstLevelReferrals;

        if (x12.length == 2) {
            if (x12[0] == referrerAddress ||
                x12[1] == referrerAddress) {
                users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].closedPart = referrerAddress;
            } else if (x12.length == 1) {
                if (x12[0] == referrerAddress) {
                    users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].x12Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].thirdLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].closedPart = address(0);
        users[referrerAddress].x12Matrix[level].place=new uint[](0);

        if (!users[referrerAddress].activeX12Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x12Matrix[level].blocked = true;
        }

        users[referrerAddress].x12Matrix[level].reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX12Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateX12Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 3, level);
            sendETHDividends(owner, userAddress, 3, level);
        }
    }

    function findFreeX12Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX12Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function hasValidRegFee(uint value) public view returns (bool) {
        return value == levelPrice[1]*3;
    }

    function getIdToAddress(uint id) public view returns (address) {
        return address(idToAddress[id]);
    }
}