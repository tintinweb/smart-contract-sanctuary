//SourceUnit: NeonNetwork.sol

pragma solidity ^0.5.12;

contract NeonNetwork {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint O3MaxLevel;
        uint O6MaxLevel;
        uint O3Income;
        uint O6Income;

        mapping(uint8 => bool) activeO3Levels;
        mapping(uint8 => bool) activeO6Levels;

        mapping(uint8 => O3) GalaxyIII;
        mapping(uint8 => O6) GalaxyVI;
    }

    struct O3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }

    struct O6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 9;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;

    uint public lastUserId = 2;
    uint256 public totalearnedtrx = 0 trx;
    address public owner;

    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user,uint indexed userId, address indexed referrer,uint referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedTronReceive(address indexed receiver,uint receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level);
    event SentDividends(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 matrix, uint8 level, bool isExtra);

    constructor(address ownerAddress) public {
        levelPrice[1] = 1000 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }

        owner = ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            O3MaxLevel:uint(0),
            O6MaxLevel:uint(0),
            O3Income:uint8(0),
            O6Income:uint8(0)
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for ( uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeO3Levels[i] = true;
            users[ownerAddress].activeO6Levels[i] = true;
        }
        users[ownerAddress].O3MaxLevel = 9;
        users[ownerAddress].O6MaxLevel = 9;
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

    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeO3Levels[level], "level already activated");
            require(users[msg.sender].activeO3Levels[level - 1], "previous level should be activated");

            if (users[msg.sender].GalaxyIII[level-1].blocked) {
                users[msg.sender].GalaxyIII[level-1].blocked = false;
            }

            address freeO3Referrer = findFreeO3Referrer(msg.sender, level);
            users[msg.sender].O3MaxLevel = level;
            users[msg.sender].GalaxyIII[level].currentReferrer = freeO3Referrer;
            users[msg.sender].activeO3Levels[level] = true;
            updateO3Referrer(msg.sender, freeO3Referrer, level);
             totalearnedtrx = totalearnedtrx+levelPrice[level];
            emit Upgrade(msg.sender, freeO3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeO6Levels[level], "level already activated");
            require(users[msg.sender].activeO6Levels[level - 1], "previous level should be activated");

            if (users[msg.sender].GalaxyVI[level-1].blocked) {
                users[msg.sender].GalaxyVI[level-1].blocked = false;
            }

            address freeO6Referrer = findFreeO6Referrer(msg.sender, level);
            users[msg.sender].O6MaxLevel = level;
            users[msg.sender].activeO6Levels[level] = true;
            updateO6Referrer(msg.sender, freeO6Referrer, level);


          totalearnedtrx = totalearnedtrx+levelPrice[level];
            emit Upgrade(msg.sender, freeO6Referrer, 2, level);
        }


    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 2000 trx, "registration cost 2000");
        require(!isUserExists(userAddress), "user exists");
        //require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            O3MaxLevel:1,
            O6MaxLevel:1,
            O3Income:0 trx,
            O6Income:0 trx
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeO3Levels[1] = true;
        users[userAddress].activeO6Levels[1] = true;


        userIds[lastUserId] = userAddress;
        lastUserId++;
         totalearnedtrx = totalearnedtrx+2000 trx;
        users[referrerAddress].partnersCount++;

        address freeO3Referrer = findFreeO3Referrer(userAddress, 1);
        users[userAddress].GalaxyIII[1].currentReferrer = freeO3Referrer;
        updateO3Referrer(userAddress, freeO3Referrer, 1);

        updateO6Referrer(userAddress, findFreeO6Referrer(userAddress, 1), 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateO3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].GalaxyIII[level].referrals.push(userAddress);

        if (users[referrerAddress].GalaxyIII[level].referrals.length < 3) {
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress, users[referrerAddress].id, 1, level, uint8(users[referrerAddress].GalaxyIII[level].referrals.length));
            return sendTronDividends(referrerAddress, userAddress, 1, level);
        }

        emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 1, level, 3);
        //close matrix
        users[referrerAddress].GalaxyIII[level].referrals = new address[](0);
        if (!users[referrerAddress].activeO3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].GalaxyIII[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeO3Referrer(referrerAddress, level);
            if (users[referrerAddress].GalaxyIII[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].GalaxyIII[level].currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].GalaxyIII[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateO3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTronDividends(owner, userAddress, 1, level);
            users[owner].GalaxyIII[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateO6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeO6Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].GalaxyVI[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, uint8(users[referrerAddress].GalaxyVI[level].firstLevelReferrals.length));

            //set current level
            users[userAddress].GalaxyVI[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].GalaxyVI[level].currentReferrer;
            users[ref].GalaxyVI[level].secondLevelReferrals.push(userAddress);

            uint len = users[ref].GalaxyVI[level].firstLevelReferrals.length;

            if ((len == 2) &&
                (users[ref].GalaxyVI[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].GalaxyVI[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id,ref,users[ref].id, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].GalaxyVI[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 4);
                }
            } else if (len == 2 && users[ref].GalaxyVI[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 6);
                }
            }

            return updateO6ReferrerSecondLevel(userAddress, ref, level);
        }

        users[referrerAddress].GalaxyVI[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].GalaxyVI[level].closedPart != address(0)) {
            if ((users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0] ==
                users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0] ==
                users[referrerAddress].GalaxyVI[level].closedPart)) {

                updateO6(userAddress, referrerAddress, level, true);
                return updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0] ==
                users[referrerAddress].GalaxyVI[level].closedPart) {
                updateO6(userAddress, referrerAddress, level, true);
                return updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateO6(userAddress, referrerAddress, level, false);
                return updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1] == userAddress) {
            updateO6(userAddress, referrerAddress, level, false);
            return updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0] == userAddress) {
            updateO6(userAddress, referrerAddress, level, true);
            return updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }

        if (users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0]].GalaxyVI[level].firstLevelReferrals.length <=
            users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1]].GalaxyVI[level].firstLevelReferrals.length) {
            updateO6(userAddress, referrerAddress, level, false);
        } else {
            updateO6(userAddress, referrerAddress, level, true);
        }

        updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateO6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0]].GalaxyVI[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0],users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0]].id, 2, level, uint8(users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0]].GalaxyVI[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 2 + uint8(users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0]].GalaxyVI[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].GalaxyVI[level].currentReferrer = users[referrerAddress].GalaxyVI[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1]].GalaxyVI[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1],users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1]].id, 2, level, uint8(users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1]].GalaxyVI[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 4 + uint8(users[users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1]].GalaxyVI[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].GalaxyVI[level].currentReferrer = users[referrerAddress].GalaxyVI[level].firstLevelReferrals[1];
        }
    }

    function updateO6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].GalaxyVI[level].secondLevelReferrals.length < 4) {
            return sendTronDividends(referrerAddress, userAddress, 2, level);
        }

        address[] memory O6Mat = users[users[referrerAddress].GalaxyVI[level].currentReferrer].GalaxyVI[level].firstLevelReferrals;

        if (O6Mat.length == 2) {
            if (O6Mat[0] == referrerAddress ||
                O6Mat[1] == referrerAddress) {
                users[users[referrerAddress].GalaxyVI[level].currentReferrer].GalaxyVI[level].closedPart = referrerAddress;
            } else if (O6Mat.length == 1) {
                if (O6Mat[0] == referrerAddress) {
                    users[users[referrerAddress].GalaxyVI[level].currentReferrer].GalaxyVI[level].closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].GalaxyVI[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].GalaxyVI[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].GalaxyVI[level].closedPart = address(0);

        if (!users[referrerAddress].activeO6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].GalaxyVI[level].blocked = true;
        }

        users[referrerAddress].GalaxyVI[level].reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeO6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateO6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTronDividends(owner, userAddress, 2, level);
        }
    }

    function findFreeO3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeO3Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeO6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeO6Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function usersActiveO3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeO3Levels[level];
    }

    function usersActiveO6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeO6Levels[level];
    }

    function get3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint, bool) {
        return (users[userAddress].GalaxyIII[level].currentReferrer,
                users[userAddress].GalaxyIII[level].referrals,
                users[userAddress].GalaxyIII[level].reinvestCount,
                users[userAddress].GalaxyIII[level].blocked);
    }

    function getGalaxyVI(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint, address) {
        return (users[userAddress].GalaxyVI[level].currentReferrer,
                users[userAddress].GalaxyVI[level].firstLevelReferrals,
                users[userAddress].GalaxyVI[level].secondLevelReferrals,
                users[userAddress].GalaxyVI[level].blocked,
                users[userAddress].GalaxyVI[level].reinvestCount,
                users[userAddress].GalaxyVI[level].closedPart);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTronReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].GalaxyIII[level].blocked) {
                    emit MissedTronReceive(receiver,users[receiver].id, _from,users[_from].id, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].GalaxyIII[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].GalaxyVI[level].blocked) {
                    emit MissedTronReceive(receiver,users[receiver].id, _from,users[_from].id, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].GalaxyVI[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendTronDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTronReceiver(userAddress, _from, matrix, level);

        if(matrix==1)
        {



                users[userAddress].O3Income +=levelPrice[level] ;
        }
        else if(matrix==2)
        {

                users[userAddress].O6Income +=levelPrice[level] ;
        }

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }

        emit SentDividends(_from,users[_from].id, receiver,users[receiver].id, matrix, level, isExtraDividends);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}