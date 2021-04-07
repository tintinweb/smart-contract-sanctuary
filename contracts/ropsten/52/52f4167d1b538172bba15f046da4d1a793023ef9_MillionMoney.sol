/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity 0.5.11;

contract MillionMoney {
    address public ownerWallet;

    MillionMoney public oldSC = MillionMoney(0x4Dcf60F0cb42c22Df36994CCBebd0b281C57003A);
    uint oldSCUserId = 1;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint PERIOD_LENGTH = 100 days;

    mapping(uint => uint) public LEVEL_PRICE;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);

    constructor() public {
        ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 0.03 ether;
        LEVEL_PRICE[2] = 0.05 ether;
        LEVEL_PRICE[3] = 0.1 ether;
        LEVEL_PRICE[4] = 0.4 ether;
        LEVEL_PRICE[5] = 1 ether;
        LEVEL_PRICE[6] = 2.5 ether;
        LEVEL_PRICE[7] = 5 ether;
        LEVEL_PRICE[8] = 10 ether;
        LEVEL_PRICE[9] = 20 ether;
        LEVEL_PRICE[10] = 40 ether;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referral: new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        for(uint i = 1; i <= 10; i++) {
            users[ownerWallet].levelExpired[i] = 55555555555;
        }
    }

    function () external payable {
        uint level;

        if(msg.value == LEVEL_PRICE[1]) level = 1;
        else if(msg.value == LEVEL_PRICE[2]) level = 2;
        else if(msg.value == LEVEL_PRICE[3]) level = 3;
        else if(msg.value == LEVEL_PRICE[4]) level = 4;
        else if(msg.value == LEVEL_PRICE[5]) level = 5;
        else if(msg.value == LEVEL_PRICE[6]) level = 6;
        else if(msg.value == LEVEL_PRICE[7]) level = 7;
        else if(msg.value == LEVEL_PRICE[8]) level = 8;
        else if(msg.value == LEVEL_PRICE[9]) level = 9;
        else if(msg.value == LEVEL_PRICE[10]) level = 10;
        else revert('Incorrect Value send');

        if(users[msg.sender].isExist) buyLevel(level);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(users[referrer].isExist) refId = users[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level for 0.03 ETH');
    }

    function regUser(uint _referrerID) public payable {
        
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');

        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender);

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist'); 
        require(_level > 0 && _level <= 10, 'Incorrect level');

        if(_level == 1) {
            require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        }
        else {
            require(msg.value == LEVEL_PRICE[_level], 'Incorrect Value');

            for(uint l =_level - 1; l > 0; l--) require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');

            if(users[msg.sender].levelExpired[_level] == 0) users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        }

        payForLevel(_level, msg.sender);

        emit buyLevelEvent(msg.sender, _level, now);
    }
    
    function syncWithOldSC(uint limit) public {
        require(address(oldSC) != address(0), 'Initialize closed');
        require(msg.sender == ownerWallet, 'Access denied');

        for(uint i = 0; i < limit; i++) {
            address user = oldSC.userList(oldSCUserId);
            (bool isExist,, uint referrerID) = oldSC.users(user);

            if(isExist) {
                oldSCUserId++;
                
                address ref = oldSC.userList(referrerID);

                if(!users[user].isExist && users[ref].isExist) {
                    users[user].isExist = true;
                    users[user].id = ++currUserID;
                    users[user].referrerID = users[ref].id;

                    userList[currUserID] = user;
                    users[ref].referral.push(user);

                    for(uint j = 1; j <= 8; j++) {
                        users[user].levelExpired[j] = oldSC.viewUserLevelExpired(user, j);
                    }

                    emit regLevelEvent(user, ref, block.timestamp);
                }
            }
            else break;
        }
    }

    function syncClose() external {
        require(address(oldSC) != address(0), 'Initialize already closed');
        require(msg.sender == ownerWallet, 'Access denied');

        oldSC = MillionMoney(0);
    }

    function payForLevel(uint _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;

        if(_level == 1 || _level == 6) {
            referer = userList[users[_user].referrerID];
        }
        else if(_level == 2 || _level == 7) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        }
        else if(_level == 3 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        }
        else if(_level == 4 || _level == 9) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }
        else if(_level == 5 || _level == 10) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer4 = userList[users[referer3].referrerID];
            referer = userList[users[referer4].referrerID];
        }

        if(!users[referer].isExist) referer = userList[1];

        bool sent = false;
        if(users[referer].levelExpired[_level] >= now) {
            sent = address(uint160(referer)).send(LEVEL_PRICE[_level]);

            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
            }
        }
        if(!sent) {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payForLevel(_level, referer);
        }
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}