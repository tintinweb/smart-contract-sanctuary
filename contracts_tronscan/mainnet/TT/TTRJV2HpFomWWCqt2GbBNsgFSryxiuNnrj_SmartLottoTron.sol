//SourceUnit: SmartLottoTron.sol

pragma solidity 0.5.10;

contract CareerPlan {
    function addToBalance() external payable;
    function addUserToLevel(address _user, uint _id, uint8 _level) external;
}

contract Lotto {
    function addUser(address user) external;
    function addToRaffle() external payable;
}

contract SmartLottoTron {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor, uint8 _box, bool _isSmartDirect, uint8 _position);
    event ReinvestBoxEvent(address indexed _user, address indexed currentSponsor, address indexed addrCaller, uint8 _box, bool _isSmartDirect);
    event MissedEvent(address indexed _from, address indexed _to, uint8 _box, bool _isSmartDirect);
    event SentExtraEvent(address indexed _from, address indexed _to, uint8 _box, bool _isSmartDirect);
    event UpgradeStatusEvent(address indexed _user, address indexed _sponsor, uint8 _box, bool _isSmartDirect);

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint8 levelCareerPlan;
        bool activeInLottery;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;

        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }

    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint partnersCount;
    }

    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        uint partnersCount;
        address closedPart;
    }

    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 14;
    uint public lastUserId = 2;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => Distribution) boxDistribution;

    address public owner;
    address externalAddress;
    address externalFeeAddress;
    address rootAddress;

    CareerPlan careerPlan;
    struct PlanRequirements {
        uint purchasedBoxes;
        uint countReferrers;
    }
    mapping(uint8 => PlanRequirements) levelRequirements;
    Lotto lottery;

    struct Distribution {
        uint user;
        uint lotto;
        uint careerPlan;
        uint owner;
        uint fee;
    }


    struct Sender {
        address[] users;
        uint[] usersAmount;
        uint lotto;
        uint careerPlan;
        uint owner;
        uint fee;
    }
    Sender senderBuilder;

    modifier restricted() {
        require(msg.sender == owner, "restricted");
        _;
    }

    constructor(address _externalAddress, address _careerPlanAddress,
        address _lotteryAddress, address _externalFeeAddress, address _rootAddress
    ) public {
        owner = msg.sender;
        externalAddress = _externalAddress;
        externalFeeAddress = _externalFeeAddress;
        rootAddress = _rootAddress;
        lottery = Lotto(_lotteryAddress);
        initializeValues();
        initializeCareerPlan(_careerPlanAddress);

        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[rootAddress].activeX3Levels[i] = true;
            users[rootAddress].activeX6Levels[i] = true;
        }
    }

    function initializeValues() internal {
        levelPrice[1] = 250 trx;
        levelPrice[2] = 500 trx;
        levelPrice[3] = 1000 trx;
        levelPrice[4] = 2000 trx;
        levelPrice[5] = 4000 trx;
        levelPrice[6] = 8000 trx;
        levelPrice[7] = 16000 trx;
        levelPrice[8] = 32000 trx;
        levelPrice[9] = 64000 trx;
        levelPrice[10] = 128000 trx;
        levelPrice[11] = 256000 trx;
        levelPrice[12] = 512000 trx;
        levelPrice[13] = 1024000 trx;
        levelPrice[14] = 2048000 trx;
        boxDistribution[1] = Distribution({user: 175 trx, lotto: 52.5 trx, careerPlan: 13.5 trx, owner: 8.325 trx, fee: 0.675 trx});
        boxDistribution[2] = Distribution({user: 350 trx, lotto: 105 trx, careerPlan: 27 trx, owner: 16.65 trx, fee: 1.35 trx});
        boxDistribution[3] = Distribution({user: 700 trx, lotto: 210 trx, careerPlan: 54 trx, owner: 33.3 trx, fee: 2.7 trx});
        boxDistribution[4] = Distribution({user: 1400 trx, lotto: 420 trx, careerPlan: 108 trx, owner: 66.6 trx, fee: 5.4 trx});
        boxDistribution[5] = Distribution({user: 2800 trx, lotto: 840 trx, careerPlan: 216 trx, owner: 133.2 trx, fee: 10.8 trx});
        boxDistribution[6] = Distribution({user: 5600 trx, lotto: 1680 trx, careerPlan: 432 trx, owner: 266.4 trx, fee: 21.6 trx});
        boxDistribution[7] = Distribution({user: 11200 trx, lotto: 3360 trx, careerPlan: 864 trx, owner: 532.8 trx, fee: 43.2 trx});
        boxDistribution[8] = Distribution({user: 22400 trx, lotto: 6720 trx, careerPlan: 1728 trx, owner: 1065.6 trx, fee: 86.4 trx});
        boxDistribution[9] = Distribution({user: 44800 trx, lotto: 13440 trx, careerPlan: 3456 trx, owner: 2131.2 trx, fee: 172.8 trx});
        boxDistribution[10] = Distribution({user: 89600 trx, lotto: 26880 trx, careerPlan: 6912 trx, owner: 4262.4 trx, fee: 345.6 trx});
        boxDistribution[11] = Distribution({user: 179200 trx, lotto: 53760 trx, careerPlan: 13824 trx, owner: 8524.8 trx, fee: 691.2 trx});
        boxDistribution[12] = Distribution({user: 358400 trx, lotto: 107520 trx, careerPlan: 27648 trx, owner: 17049.6 trx, fee: 1382.4 trx});
        boxDistribution[13] = Distribution({user: 716800 trx, lotto: 215040 trx, careerPlan: 55296 trx, owner: 34099.2 trx, fee: 2764.8 trx});
        boxDistribution[14] = Distribution({user: 1433600 trx, lotto: 430080 trx, careerPlan: 110592 trx, owner: 68198.4 trx, fee: 5529.6 trx});
    }

    function initializeCareerPlan(address _careerPlanAddress) internal {
        careerPlan = CareerPlan(_careerPlanAddress);
        levelRequirements[1].countReferrers = 10;
        levelRequirements[1].purchasedBoxes = 3;
        levelRequirements[2].countReferrers = 20;
        levelRequirements[2].purchasedBoxes = 6;
        levelRequirements[3].countReferrers = 30;
        levelRequirements[3].purchasedBoxes = 9;
        levelRequirements[4].countReferrers = 40;
        levelRequirements[4].purchasedBoxes = 12;
        levelRequirements[5].countReferrers = 60;
        levelRequirements[5].purchasedBoxes = 14;
    }

    function verifyLevelOfUser(address user) internal {
        if (users[user].levelCareerPlan >= 5) return;
        uint8 level = users[user].levelCareerPlan + 1;
        PlanRequirements memory requirements = levelRequirements[level];
        for(uint8 i = 1; i <= requirements.purchasedBoxes; i++) {
            if(!users[user].activeX3Levels[i] || !users[user].activeX6Levels[i]) return;
            if(users[user].x3Matrix[i].partnersCount < requirements.countReferrers
                || users[user].x6Matrix[i].partnersCount < requirements.countReferrers) return;
        }
        users[user].levelCareerPlan = level;
        careerPlan.addUserToLevel(user, users[user].id, level);
    }

    function verifyRequirementsForLottery(address user) internal {
        if (users[user].activeInLottery) return;
        for(uint8 i = 1; i <= 3; i++) {
            if(!users[user].activeX3Levels[i] || !users[user].activeX6Levels[i])
                return;
        }
        users[user].activeInLottery = true;
        lottery.addUser(user);
    }

    function() external payable {
        require(msg.value == levelPrice[currentStartingLevel] * 2, "invalid registration cost");
        if(msg.data.length == 0) {
            return registration(msg.sender, rootAddress);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawLostTRXFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        address(uint160(owner)).transfer(address(this).balance);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        idToAddress[lastUserId] = userAddress;
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeX3Levels[1] = true;
        users[userAddress].activeX6Levels[1] = true;

        lastUserId++;

        users[referrerAddress].partnersCount++;
        users[referrerAddress].x3Matrix[1].partnersCount++;
        users[referrerAddress].x6Matrix[1].partnersCount++;
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
        sendTrx();
    }

    function signUp(address referrerAddress) external payable {
        require(msg.value == levelPrice[currentStartingLevel] * 2, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }

    function signUpAdmin(address _user, address _sponsor) external restricted returns(string memory) {
        registration(_user, _sponsor);
        return "registration successful";
    }

    function buyNewLevel(address _user, uint8 matrix, uint8 level) internal {
        require(isUserExists(_user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(users[_user].activeX3Levels[level-1], "buy previous level first");
            require(!users[_user].activeX3Levels[level], "level already activated");


            if (users[_user].x3Matrix[level-1].blocked) {
                users[_user].x3Matrix[level-1].blocked = false;
            }

            address freeX3Referrer = findFreeX3Referrer(_user, level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_user].activeX3Levels[level] = true;
            updateX3Referrer(_user, freeX3Referrer, level);
            if(users[users[_user].referrer].activeX3Levels[level]) {
                users[users[_user].referrer].x3Matrix[level].partnersCount++;
                verifyLevelOfUser(users[_user].referrer);
            }
            emit UpgradeStatusEvent(_user, freeX3Referrer, level, true);

        } else {
            require(users[_user].activeX6Levels[level-1], "buy previous level first");
            require(!users[_user].activeX6Levels[level], "level already activated");

            if (users[_user].x6Matrix[level-1].blocked) {
                users[_user].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(_user, level);

            users[_user].activeX6Levels[level] = true;
            updateX6Referrer(_user, freeX6Referrer, level);
            if(users[users[_user].referrer].activeX6Levels[level]) {
                users[users[_user].referrer].x6Matrix[level].partnersCount++;
                verifyLevelOfUser(users[_user].referrer);
            }
            emit UpgradeStatusEvent(_user, freeX6Referrer, level, false);
        }
        verifyRequirementsForLottery(_user);
        sendTrx();
    }

    function buyNewBox(uint8 _matrix, uint8 _box) external payable {
        require(msg.value == levelPrice[_box], "invalid price");
        buyNewLevel(msg.sender, _matrix, _box);
    }

    function buyNewBoxAdmin(address _user, uint8 _matrix, uint8 _box) external restricted returns(string memory) {
        buyNewLevel(_user, _matrix, _box);
        return "Level bought successfully";
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserChildEvent(userAddress, referrerAddress, level, true, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        emit NewUserChildEvent(userAddress, referrerAddress, level, true, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != rootAddress) {
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit ReinvestBoxEvent(referrerAddress, freeReferrerAddress, userAddress, level, true);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(rootAddress, userAddress, 1, level);
            users[rootAddress].x3Matrix[level].reinvestCount++;
            emit ReinvestBoxEvent(rootAddress, address(0), userAddress, level, true);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserChildEvent(userAddress, referrerAddress, level, false, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == rootAddress) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress);

            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;

            if ((len == 2) &&
            (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserChildEvent(userAddress, ref, level, false, 5);
                } else {
                    emit NewUserChildEvent(userAddress, ref, level, false, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserChildEvent(userAddress, ref, level, false, 3);
                } else {
                    emit NewUserChildEvent(userAddress, ref, level, false, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserChildEvent(userAddress, ref, level, false, 5);
                } else {
                    emit NewUserChildEvent(userAddress, ref, level, false, 6);
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
            emit NewUserChildEvent(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], level, false, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserChildEvent(userAddress, referrerAddress, level, false, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserChildEvent(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], level, false, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserChildEvent(userAddress, referrerAddress, level, false, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
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

        if (referrerAddress != rootAddress) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit ReinvestBoxEvent(referrerAddress, freeReferrerAddress, userAddress, level, false);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit ReinvestBoxEvent(rootAddress, address(0), userAddress, level, false);
            sendETHDividends(rootAddress, userAddress, 2, level);
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

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEvent(_from, receiver, level, true);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEvent(_from, receiver, level, false);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        if(msg.sender != owner) {
            (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

            senderBuilder.users.push(receiver);
            senderBuilder.usersAmount.push(boxDistribution[level].user);
            senderBuilder.owner += boxDistribution[level].owner;
            senderBuilder.fee += boxDistribution[level].fee;
            senderBuilder.careerPlan += boxDistribution[level].careerPlan;
            senderBuilder.lotto += boxDistribution[level].lotto;
            if (isExtraDividends) {
                emit SentExtraEvent(_from, receiver, level, matrix == 1);
            }
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function sendTrx() internal {
        if(senderBuilder.owner > 0) {
            address(uint160(externalAddress)).transfer(senderBuilder.owner);
            senderBuilder.owner = 0;
        }
        if(senderBuilder.fee > 0) {
            address(uint160(externalFeeAddress)).transfer(senderBuilder.fee);
            senderBuilder.fee = 0;
        }
        if(senderBuilder.careerPlan > 0) {
            careerPlan.addToBalance.value(senderBuilder.careerPlan)();
            senderBuilder.careerPlan = 0;
        }
        if(senderBuilder.lotto > 0) {
            lottery.addToRaffle.value(senderBuilder.lotto)();
            senderBuilder.lotto = 0;
        }
        for(uint i;i < senderBuilder.users.length;i++) {
            address(uint160(senderBuilder.users[i])).transfer(senderBuilder.usersAmount[i]);
        }
        senderBuilder.users = new address[](0);
        senderBuilder.usersAmount = new uint[](0);
    }

}