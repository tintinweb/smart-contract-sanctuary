/**
 *Submitted for verification at Etherscan.io on 2020-01-31
*/

/**
*
*   ,d8888b                                                    
*   88P'                                                       
*d888888P                                                      
*  ?88'     d8888b   88bd88b .d888b, d888b8b   d888b8b   d8888b
*  88P     d8P' ?88  88P'  ` ?8b,   d8P' ?88  d8P' ?88  d8b_,dP
* d88      88b  d88 d88        `?8b 88b  ,88b 88b  ,88b 88b    
*d88'      `?8888P'd88'     `?888P' `?88P'`88b`?88P'`88b`?888P'
*                                                    )88       
*                                                   ,88P       
*                                               `?8888P        
*
* 
* SmartWay Forsage
* https://forsage.smartway.run
* (only for SmartWay.run members)
* 
**/


pragma solidity >=0.4.23 <0.6.0;

contract SmartMatrixForsage {

    struct User {
        uint id;
        address referrer; //推荐人
        uint partnersCount; //合作伙伴数量

        mapping(uint8 => bool) activeX3Levels; //X3等级
        mapping(uint8 => bool) activeX6Levels; //X6等级

        mapping(uint8 => X3) x3Matrix; //X3矩阵--等级1-12
        mapping(uint8 => X6) x6Matrix; //X6矩阵--等级1-12
    }

    struct X3 {
        address currentReferrer; //当前推荐人
        address[] referrals; //下线
        bool blocked; //冻结
        uint reinvestCount; //复投次数
    }

    struct X6 {
        address currentReferrer;  //当前推荐人
        address[] firstLevelReferrals; //第一等级下线
        address[] secondLevelReferrals; //第二等级下线
        bool blocked;//冻结
        uint reinvestCount; //复投次数

        address closedPart; //TODO 封闭角色？
    }

    uint8 public constant LAST_LEVEL = 12; //最大等级

    mapping(address => User) public users; //用户
    mapping(uint => address) public idToAddress; //id -》地址
    mapping(uint => address) public userIds; //TODO 区别
    mapping(address => uint) public balances; //地址的余额

    uint public lastUserId = 2; //起始id
    address public owner; //合约所有人

    mapping(uint8 => uint) public levelPrice; //等级价格

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint256 reinvestCount);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);


    constructor(address ownerAddress) public {
        levelPrice[1] = 0.001 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2; //0.001 0.01 0.02 0.04 0.08 0.16 0.32 0.64 1.28 2.56 5.12 10.24
        }

        owner = ownerAddress; //合约所有人

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
            });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress; //合约第一人

        for (uint8 j = 1; j <= LAST_LEVEL; j++) {
            users[ownerAddress].activeX3Levels[j] = true;
            users[ownerAddress].activeX6Levels[j] = true;
        }

        userIds[1] = ownerAddress; //TODO 和 IdToAddress 有什么区别
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
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            } //关闭冻结，购买了下个等级

            address freeX3Referrer = findFreeX3Referrer(msg.sender, level); //找到上个推荐人的等级
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer; //X3当前等级的推荐人
            users[msg.sender].activeX3Levels[level] = true; //激活对应等级
            updateX3Referrer(msg.sender, freeX3Referrer, level);

            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated");

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);

            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);

            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.002 ether, "registration cost 0.002");
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


        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1); //找到上线X3的1层推荐人
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer; //保存X3现在1层的推荐人
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    //更新X3推荐人---买等级
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress); //推荐人的X3对应的等级的下线

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length), uint256(users[referrerAddress].x3Matrix[level].reinvestCount));
            return sendETHDividends(referrerAddress, userAddress, 1, level); //发送以太坊分红
        } //下线小于3个人

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3, uint256(users[referrerAddress].x3Matrix[level].reinvestCount));
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0); //下线等于三个人，重新清空地址
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        } //TODO 冻结 超过三个，但是没有启动下个等级

        //create new one by recursion
        if (referrerAddress != owner) { //推荐人不是合约所有人
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level); //超过3人数，送给上线推荐人
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            } //TODO 替换推荐人？

            users[referrerAddress].x3Matrix[level].reinvestCount++; //开启新的一轮
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else { //推荐人是合约所有人
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length), uint256(users[referrerAddress].x6Matrix[level].reinvestCount));

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
                    emit NewUserPlace(userAddress, ref, 2, level, 5, uint256(users[referrerAddress].x6Matrix[level].reinvestCount));
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, uint256(users[referrerAddress].x6Matrix[level].reinvestCount));
                }
            }  else if ((len == 1 || len == 2) &&
            users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3, uint256(users[referrerAddress].x6Matrix[level].reinvestCount));
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4, uint256(users[referrerAddress].x6Matrix[level].reinvestCount));
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, uint256(users[referrerAddress].x6Matrix[level].reinvestCount));
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, uint256(users[referrerAddress].x6Matrix[level].reinvestCount));
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].reinvestCount));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].reinvestCount));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].reinvestCount));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].reinvestCount));
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

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }

    //推荐人的等级
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            } //X3推荐人的等级是否存在

            userAddress = users[userAddress].referrer; //往推荐人的推荐人找---找到对应等级的推荐人
        }
    }

    //推荐人的等级
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer; //往推荐人的推荐人找---找到对应等级的推荐人
        }
    }

    //用户等级是否存在
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    //用户等级是否存在
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    //对应等级的推荐人、下线、冻结状态
    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
        users[userAddress].x3Matrix[level].referrals,
        users[userAddress].x3Matrix[level].blocked);
    }

    //对应等级的推荐人、下线、冻结状态、闭环
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

    //转账
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
}