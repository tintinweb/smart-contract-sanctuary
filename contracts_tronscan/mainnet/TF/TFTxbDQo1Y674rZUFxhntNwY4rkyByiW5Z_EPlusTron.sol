//SourceUnit: eplustron.sol



/*

.########.........########..##.......##.....##..######.
.##...............##.....##.##.......##.....##.##....##
.##...............##.....##.##.......##.....##.##......
.######...#######.########..##.......##.....##..######.
.##...............##........##.......##.....##.......##
.##...............##........##.......##.....##.##....##
.########.........##........########..#######...######.

*/

pragma solidity 0.5.9;

contract EPlusTron {
    address public ownerWallet;
    uint public currUserID = 0;
    uint public pool1currUserID = 0;
    uint public pool2currUserID = 0;
    uint public pool3currUserID = 0;
    uint public pool4currUserID = 0;
    uint public pool5currUserID = 0;
    uint public pool6currUserID = 0;
    uint public pool7currUserID = 0;
    uint public pool8currUserID = 0;
    uint public pool9currUserID = 0;

    uint public pool1activeUserID = 0;
    uint public pool2activeUserID = 0;
    uint public pool3activeUserID = 0;
    uint public pool4activeUserID = 0;
    uint public pool5activeUserID = 0;
    uint public pool6activeUserID = 0;
    uint public pool7activeUserID = 0;
    uint public pool8activeUserID = 0;
    uint public pool9activeUserID = 0;



    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint referredUsers;
        uint earnedSplBonus;
        mapping(uint => uint) levelExpired;
    }

    struct PoolUserStruct {
        bool isExist;
        uint id;
        uint payment_received;
    }

    mapping(address => UserStruct) public users;
    mapping(uint => address) public userList;

    mapping(address => PoolUserStruct) public pool1users;
    mapping(uint => address) public pool1userList;

    mapping(address => PoolUserStruct) public pool2users;
    mapping(uint => address) public pool2userList;

    mapping(address => PoolUserStruct) public pool3users;
    mapping(uint => address) public pool3userList;

    mapping(address => PoolUserStruct) public pool4users;
    mapping(uint => address) public pool4userList;

    mapping(address => PoolUserStruct) public pool5users;
    mapping(uint => address) public pool5userList;

    mapping(address => PoolUserStruct) public pool6users;
    mapping(uint => address) public pool6userList;

    mapping(address => PoolUserStruct) public pool7users;
    mapping(uint => address) public pool7userList;

    mapping(address => PoolUserStruct) public pool8users;
    mapping(uint => address) public pool8userList;

    mapping(address => PoolUserStruct) public pool9users;
    mapping(uint => address) public pool9userList;

    mapping(uint => uint) public LEVEL_PRICE;

    uint REGESTRATION_FESS = 210 trx;
    uint pool1_price = 70 trx;
    uint pool2_price = 200 trx;
    uint pool3_price = 400 trx;
    uint pool4_price = 800 trx;
    uint pool5_price = 1600 trx;
    uint pool6_price = 3200 trx;
    uint pool7_price = 6400 trx;
    uint pool8_price = 12800 trx;
    uint pool9_price = 25600 trx;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint _price);
    event getMoneyForBoosterEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint _price);
    event regPoolEntry(address indexed _user, uint _level, uint _time);
    event getMoneyForSplEvent(address indexed _from, address indexed _receiver, uint _time, uint _price);
    event getPoolPayment(address indexed _user, address indexed _receiver, uint _level, uint _time, uint _price);
    event getPoolSponsorPayment(address indexed _user, address indexed _receiver, uint _level, uint _time, uint _price);
    event getReInvestPoolPayment(address indexed _user, uint _level, uint _time, uint _price);

    UserStruct[] public requests;
    uint public totalEarned = 0;

    constructor() public {
        ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 70 trx;
        LEVEL_PRICE[2] = 200 trx;
        LEVEL_PRICE[3] = 400 trx;
        LEVEL_PRICE[4] = 800 trx;
        LEVEL_PRICE[5] = 1600 trx;
        LEVEL_PRICE[6] = 3200 trx;
        LEVEL_PRICE[7] = 6400 trx;
        LEVEL_PRICE[8] = 12800 trx;
        LEVEL_PRICE[9] = 25600 trx;


        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            earnedSplBonus: 0,
            referredUsers: 0
        });

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        PoolUserStruct memory pooluserStruct;

        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool1currUserID,
            payment_received: 0
        });
        pool1activeUserID = pool1currUserID;
        pool1users[msg.sender] = pooluserStruct;
        pool1userList[pool1currUserID] = msg.sender;

        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool2currUserID,
            payment_received: 0
        });
        pool2activeUserID = pool2currUserID;
        pool2users[msg.sender] = pooluserStruct;
        pool2userList[pool2currUserID] = msg.sender;

        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool3currUserID,
            payment_received: 0
        });
        pool3activeUserID = pool3currUserID;
        pool3users[msg.sender] = pooluserStruct;
        pool3userList[pool3currUserID] = msg.sender;

        pool4currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool4currUserID,
            payment_received: 0
        });
        pool4activeUserID = pool4currUserID;
        pool4users[msg.sender] = pooluserStruct;
        pool4userList[pool4currUserID] = msg.sender;

        pool5currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool5currUserID,
            payment_received: 0
        });
        pool5activeUserID = pool5currUserID;
        pool5users[msg.sender] = pooluserStruct;
        pool5userList[pool5currUserID] = msg.sender;

        pool6currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool6currUserID,
            payment_received: 0
        });
        pool6activeUserID = pool6currUserID;
        pool6users[msg.sender] = pooluserStruct;
        pool6userList[pool6currUserID] = msg.sender;

        pool7currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool7currUserID,
            payment_received: 0
        });
        pool7activeUserID = pool7currUserID;
        pool7users[msg.sender] = pooluserStruct;
        pool7userList[pool7currUserID] = msg.sender;

        pool8currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool8currUserID,
            payment_received: 0
        });
        pool8activeUserID = pool8currUserID;
        pool8users[msg.sender] = pooluserStruct;
        pool8userList[pool8currUserID] = msg.sender;

        pool9currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist: true,
            id: pool9currUserID,
            payment_received: 0
        });
        pool9activeUserID = pool9currUserID;
        pool9users[msg.sender] = pooluserStruct;
        pool9userList[pool9currUserID] = msg.sender;
    }



    function reInvest(address _user, uint _level) internal {
        if (_level == 1) {
            PoolUserStruct memory userStruct;
            address pool1Currentuser = pool1userList[pool1activeUserID];
            pool1currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool1currUserID,
                payment_received: 0
            });
            pool1users[_user] = userStruct;
            pool1userList[pool1currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool1_price);
        }
        else if (_level == 2) {
            PoolUserStruct memory userStruct;
            address pool2Currentuser = pool2userList[pool2activeUserID];
            pool2currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool2currUserID,
                payment_received: 0
            });
            pool2users[_user] = userStruct;
            pool2userList[pool2currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool2_price);
        }
        else if (_level == 3) {
            PoolUserStruct memory userStruct;
            address pool3Currentuser = pool3userList[pool3activeUserID];
            pool3currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool3currUserID,
                payment_received: 0
            });
            pool3users[_user] = userStruct;
            pool3userList[pool3currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool3_price);
        }
        else if (_level == 4) {
            PoolUserStruct memory userStruct;
            address pool4Currentuser = pool4userList[pool4activeUserID];
            pool4currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool4currUserID,
                payment_received: 0
            });
            pool4users[_user] = userStruct;
            pool4userList[pool4currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool4_price);
        }
        else if (_level == 5) {
            PoolUserStruct memory userStruct;
            address pool5Currentuser = pool5userList[pool5activeUserID];
            pool5currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool5currUserID,
                payment_received: 0
            });
            pool5users[_user] = userStruct;
            pool5userList[pool5currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool5_price);
        }

        else if (_level == 6) {
            PoolUserStruct memory userStruct;
            address pool6Currentuser = pool6userList[pool6activeUserID];
            pool6currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool6currUserID,
                payment_received: 0
            });
            pool6users[_user] = userStruct;
            pool6userList[pool6currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool6_price);
        }

        else if (_level == 7) {
            PoolUserStruct memory userStruct;
            address pool7Currentuser = pool7userList[pool7activeUserID];
            pool7currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool7currUserID,
                payment_received: 0
            });
            pool7users[_user] = userStruct;
            pool7userList[pool7currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool7_price);
        }

        else if (_level == 8) {
            PoolUserStruct memory userStruct;
            address pool8Currentuser = pool8userList[pool8activeUserID];
            pool8currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool8currUserID,
                payment_received: 0
            });
            pool8users[_user] = userStruct;
            pool8userList[pool8currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool8_price);
        }

        else if (_level == 9) {
            PoolUserStruct memory userStruct;
            address pool9Currentuser = pool9userList[pool9activeUserID];
            pool9currUserID++;
            userStruct = PoolUserStruct({
                isExist: true,
                id: pool9currUserID,
                payment_received: 0
            });
            pool9users[_user] = userStruct;
            pool9userList[pool9currUserID] = _user;
            emit getReInvestPoolPayment(_user, _level, now, pool9_price);
        }
    }

    

    function buyPool1(uint _referrerID) public payable {

        require(!users[msg.sender].isExist, "User Exists");
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
        require(!pool1users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == (pool1_price * 3), 'Incorrect Value');

        UserStruct memory userStruct;
        currUserID++;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            earnedSplBonus: 0,
            referredUsers: 0
        });
        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;
        users[userList[users[msg.sender].referrerID]].referredUsers = users[userList[users[msg.sender].referrerID]].referredUsers + 1;
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
        
        PoolUserStruct memory userStructPool;
        address pool1Currentuser = pool1userList[pool1activeUserID];
        pool1currUserID++;
        userStructPool = PoolUserStruct({
            isExist: true,
            id: pool1currUserID,
            payment_received: 0
        });
        pool1users[msg.sender] = userStructPool;
        pool1userList[pool1currUserID] = msg.sender;
        bool sent = false;

        sent = address(uint160(pool1Currentuser)).send(pool1_price);
        if (sent) {
            totalEarned += pool1_price * 3;
            pool1users[pool1Currentuser].payment_received += 1;
            if (pool1users[pool1Currentuser].payment_received >= 3) {
                pool1activeUserID += 1;
                reInvest(pool1Currentuser, 1);
            }
            emit getPoolPayment(msg.sender, pool1Currentuser, 1, now, pool1_price);
        }
        else {
            sendBalance();
        }
        address spreferer = userList[_referrerID];
        sent = address(uint160(spreferer)).send(pool1_price);
        if (sent) {
            emit getMoneyForLevelEvent(msg.sender, spreferer, 1, now, pool1_price);
        }
        else {
            sendBalance();
        }
        if(users[userList[_referrerID]].referredUsers % 4 == 0) {
            sent = address(uint160(userList[_referrerID])).send(pool1_price);
            if (sent) {
                users[userList[_referrerID]].earnedSplBonus += pool1_price;
                emit getMoneyForSplEvent(msg.sender,userList[_referrerID],now,pool1_price);
            }
            else {
                sendBalance();
            }
        }else{
            sent = address(uint160(ownerWallet)).send(pool1_price);
            if (sent) {
                emit getPoolSponsorPayment(msg.sender, ownerWallet, 1, now, pool1_price);
            }
            else {
                sendBalance();
            }
        }
        
        emit regPoolEntry(msg.sender, 1, now);
    }

    function buyPools(uint _level) public payable{
        require(_level > 1 && _level < 10, "Invalid Level");
        if(_level == 2){
            buyPool2(msg.sender,msg.value);
        } else if(_level == 3){
            buyPool3(msg.sender,msg.value);
        } else if(_level == 4){
            buyPool4(msg.sender,msg.value);
        }else if(_level == 5){
            buyPool5(msg.sender,msg.value);
        }else if(_level == 6){
            buyPool6(msg.sender,msg.value);
        }else if(_level == 7){
            buyPool7(msg.sender,msg.value);
        }else if(_level == 8){
            buyPool8(msg.sender,msg.value);
        }else if(_level == 9){
            buyPool9(msg.sender,msg.value);
        }
    }

    function buyPool2(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool2users[sender].isExist, "Already in AutoPool");
        require(pool1users[sender].isExist, "Purchase pool 1 First");
        require(value == pool2_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool2Currentuser = pool2userList[pool2activeUserID];

        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool2currUserID,
            payment_received: 0
        });
        pool2users[sender] = userStruct;
        pool2userList[pool2currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool2Currentuser)).send(pool2_price);
        if (sent) {
            totalEarned += pool2_price;
            pool2users[pool2Currentuser].payment_received += 1;
            if (pool2users[pool2Currentuser].payment_received >= 3) {
                pool2activeUserID += 1;
                reInvest(pool2Currentuser, 2);
            }
            emit getPoolPayment(sender, pool2Currentuser, 2, now, pool2_price);

        }
        else {
            sendBalance();
        }

        emit regPoolEntry(sender, 2, now);
        //payReferral(2, pool2_price, sender);
    }

    function buyPool3(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool3users[sender].isExist, "Already in AutoPool");
        require(pool2users[sender].isExist, "Purchase pool 2 First");
        require(value == pool3_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool3Currentuser = pool3userList[pool3activeUserID];

        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool3currUserID,
            payment_received: 0
        });
        pool3users[sender] = userStruct;
        pool3userList[pool3currUserID] = sender;
        bool sent = false;
        sent = address(uint160(pool3Currentuser)).send(pool3_price);
        if (sent) {
            totalEarned += pool3_price;
            pool3users[pool3Currentuser].payment_received += 1;
            if (pool3users[pool3Currentuser].payment_received >= 3) {
                pool3activeUserID += 1;
                reInvest(pool3Currentuser, 3);
            }
            emit getPoolPayment(sender, pool3Currentuser, 3, now, pool3_price);
        }
        else {
            sendBalance();
        }
        emit regPoolEntry(sender, 3, now);
        //payReferral(3, pool3_price, sender);
    }

    function buyPool4(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool4users[sender].isExist, "Already in AutoPool");
        require(pool3users[sender].isExist, "Purchase pool 3 First");
        require(value == pool4_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool4Currentuser = pool4userList[pool4activeUserID];

        pool4currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool4currUserID,
            payment_received: 0
        });
        pool4users[sender] = userStruct;
        pool4userList[pool4currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool4Currentuser)).send(pool4_price);
        if (sent) {
            totalEarned += pool4_price;
            pool4users[pool4Currentuser].payment_received += 1;
            if (pool4users[pool4Currentuser].payment_received >= 3) {
                pool4activeUserID += 1;
                reInvest(pool4Currentuser, 4);

            }
            emit getPoolPayment(sender, pool4Currentuser, 4, now, pool4_price);

        }
        else {
            sendBalance();
        }

        emit regPoolEntry(sender, 4, now);
        //payReferral(4, pool4_price, sender);
    }

    function buyPool5(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool5users[sender].isExist, "Already in AutoPool");
        require(pool4users[sender].isExist, "Purchase pool 4 First");
        require(value == pool5_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool5Currentuser = pool5userList[pool5activeUserID];

        pool5currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool5currUserID,
            payment_received: 0
        });
        pool5users[sender] = userStruct;
        pool5userList[pool5currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool5Currentuser)).send(pool5_price);
        if (sent) {
            totalEarned += pool5_price;
            pool5users[pool5Currentuser].payment_received += 1;
            if (pool5users[pool5Currentuser].payment_received >= 3) {
                pool5activeUserID += 1;
                reInvest(pool5Currentuser, 5);

            }
            emit getPoolPayment(sender, pool5Currentuser, 5, now, pool5_price);

        }
        else {
            sendBalance();
        }

        emit regPoolEntry(sender, 5, now);
        //payReferral(5, pool5_price, sender);
    }

    function buyPool6(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool6users[sender].isExist, "Already in AutoPool");
        require(pool5users[sender].isExist, "Purchase pool 5 First");
        require(value == pool6_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool6Currentuser = pool6userList[pool6activeUserID];

        pool6currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool6currUserID,
            payment_received: 0
        });
        pool6users[sender] = userStruct;
        pool6userList[pool6currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool6Currentuser)).send(pool6_price);
        if (sent) {
            totalEarned += pool6_price;
            pool6users[pool6Currentuser].payment_received += 1;
            if (pool6users[pool6Currentuser].payment_received >= 3) {
                pool6activeUserID += 1;
                reInvest(pool6Currentuser, 6);

            }
            emit getPoolPayment(sender, pool6Currentuser, 6, now, pool6_price);

        }
        else {
            sendBalance();
        }

        emit regPoolEntry(sender, 6, now);
        //payReferral(6, pool6_price, sender);
    }


    function buyPool7(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool7users[sender].isExist, "Already in AutoPool");
        require(pool6users[sender].isExist, "Purchase pool 6 First");
        require(value == pool7_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool7Currentuser = pool7userList[pool7activeUserID];

        pool7currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool7currUserID,
            payment_received: 0
        });
        pool7users[sender] = userStruct;
        pool7userList[pool7currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool7Currentuser)).send(pool7_price);
        if (sent) {
            totalEarned += pool7_price;
            pool7users[pool7Currentuser].payment_received += 1;
            if (pool7users[pool7Currentuser].payment_received >= 3) {
                pool7activeUserID += 1;
                reInvest(pool7Currentuser, 7);

            }
            emit getPoolPayment(sender, pool7Currentuser, 7, now, pool7_price);

        }
        else {
            sendBalance();
        }


        emit regPoolEntry(sender, 7, now);
        //payReferral(7, pool7_price, sender);
    }


    function buyPool8(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool8users[sender].isExist, "Already in AutoPool");
        require(pool7users[sender].isExist, "Purchase pool 7 First");
        require(value == pool8_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool8Currentuser = pool8userList[pool8activeUserID];

        pool8currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool8currUserID,
            payment_received: 0
        });
        pool8users[sender] = userStruct;
        pool8userList[pool8currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool8Currentuser)).send(pool8_price);
        if (sent) {
            totalEarned += pool8_price;
            pool8users[pool8Currentuser].payment_received += 1;
            if (pool8users[pool8Currentuser].payment_received >= 3) {
                pool8activeUserID += 1;
                reInvest(pool8Currentuser, 8);
            }
            emit getPoolPayment(sender, pool8Currentuser, 8, now, pool8_price);

        }
        else {
            sendBalance();
        }

        emit regPoolEntry(sender, 8, now);
        //payReferral(8, pool8_price, sender);
    }

    function buyPool9(address sender,uint value) internal {
        require(users[sender].isExist, "User Not Registered");
        require(!pool9users[sender].isExist, "Already in AutoPool");
        require(pool8users[sender].isExist, "Purchase pool 8 First");
        require(value == pool9_price, 'Incorrect Value');

        PoolUserStruct memory userStruct;
        address pool9Currentuser = pool9userList[pool9activeUserID];

        pool9currUserID++;
        userStruct = PoolUserStruct({
            isExist: true,
            id: pool9currUserID,
            payment_received: 0
        });
        pool9users[sender] = userStruct;
        pool9userList[pool9currUserID] = sender;
        bool sent = false;

        sent = address(uint160(pool9Currentuser)).send(pool9_price);
        if (sent) {
            totalEarned += pool9_price;
            pool9users[pool9Currentuser].payment_received += 1;
            if (pool9users[pool9Currentuser].payment_received >= 3) {
                pool9activeUserID += 1;
                reInvest(pool9Currentuser, 9);

            }
            emit getPoolPayment(sender, pool9Currentuser, 9, now, pool9_price);

        }
        else {
            sendBalance();
        }
        emit regPoolEntry(sender, 9, now);
        //payReferral(9, pool9_price, sender);
    }

    function getTrxBalance() public view returns(uint) {
        return address(this).balance;
    }

    function sendBalance() private
    {
        if (!address(uint160(ownerWallet)).send(getTrxBalance())) {

        }
    }

    function withdrawSafe(uint _amount) external {
        require(msg.sender == ownerWallet, 'Permission denied');
        if (_amount > 0) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }

}