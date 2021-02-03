/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity ^0.4.17;

contract Ownable  {
    function viewManager() public view returns(address);
}


contract BrightFund {
    
    address public ownerWallet;
    Ownable ownable = Ownable(0x31C3739b6029944eDd828fad742379513d8d0B63);

   
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping(uint => uint) levelExpired;
        mapping(uint => uint) levelExpiredPro;
        mapping(uint => uint) levelExpiredLegendary;
    }
    
    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint PERIOD_LENGTH_STANDARD = 64 days;
    uint PERIOD_LENGTH_PRO = 128 days;
    uint PERIOD_LENGTH_LEGENDARY = 256 days;

    mapping(uint => uint) public LEVEL_PRICE;

    mapping(address => UserStruct) public users;
    mapping(uint => address) public userList;
    uint public currUserID = 0;
    
    uint public l1l1users = 0;
    uint public l1l2users = 0;
    uint public l1l3users = 0;
    uint public l1l4users = 0;
    uint public l1l5users = 0;
    uint public l1l6users = 0;
    uint public l1l7users = 0;
    uint public l1l8users = 0;
    
    uint public l2l1users = 0;
    uint public l2l2users = 0;
    uint public l2l3users = 0;
    uint public l2l4users = 0;
    uint public l2l5users = 0;
    uint public l2l6users = 0;
    uint public l2l7users = 0;
    uint public l2l8users = 0;

    uint public l3l1users = 0;
    uint public l3l2users = 0;
    uint public l3l3users = 0;
    uint public l3l4users = 0;
    uint public l3l5users = 0;
    uint public l3l6users = 0;
    uint public l3l7users = 0;
    uint public l3l8users = 0;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _league, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _league, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _league, uint _time);

    constructor() public {
        ownerWallet = msg.sender;
        LEVEL_PRICE[1] = 0.04 ether;
        LEVEL_PRICE[2] = 0.08 ether;
        LEVEL_PRICE[3] = 0.16 ether;
        LEVEL_PRICE[4] = 0.32 ether;
        LEVEL_PRICE[5] = 0.64 ether;
        LEVEL_PRICE[6] = 1.28 ether;
        LEVEL_PRICE[7] = 2.56 ether;
        LEVEL_PRICE[8] = 5.12 ether;




        LEVEL_PRICE[9] = 2.0 ether;
        LEVEL_PRICE[10] = 4.0 ether;
        LEVEL_PRICE[11] = 8.0 ether;
        LEVEL_PRICE[12] = 16.0 ether;
        LEVEL_PRICE[13] = 32.0 ether;
        LEVEL_PRICE[14] = 64.0 ether;
        LEVEL_PRICE[15] = 128.0 ether;
        LEVEL_PRICE[16] = 256.0 ether;




        LEVEL_PRICE[17] = 16.0 ether;
        LEVEL_PRICE[18] = 32.0 ether;
        LEVEL_PRICE[19] = 64.0 ether;
        LEVEL_PRICE[20] = 128.0 ether;
        LEVEL_PRICE[21] = 256.0 ether;
        LEVEL_PRICE[22] = 512.0 ether;
        LEVEL_PRICE[23] = 1024.0 ether;
        LEVEL_PRICE[24] = 2048.0 ether;

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

        for (uint i = 1; i <= 8; i++) {
            users[ownerWallet].levelExpired[i] = 55555555555;
            users[ownerWallet].levelExpiredPro[i] = 55555555555;
            users[ownerWallet].levelExpiredLegendary[i] = 55555555555;
        }
    }

    function () external payable {
        uint level;
        uint league;

        if (msg.value == LEVEL_PRICE[1]) { level = 1; league = 1;}
        else if (msg.value == LEVEL_PRICE[2]) { level = 2; league = 1;}
        else if (msg.value == LEVEL_PRICE[3]) { level = 3; league = 1;}
        else if (msg.value == LEVEL_PRICE[4]) { level = 4; league = 1;}
        else if (msg.value == LEVEL_PRICE[5]) { level = 5; league = 1;}
        else if (msg.value == LEVEL_PRICE[6]) { level = 6; league = 1;}
        else if (msg.value == LEVEL_PRICE[7]) { level = 7; league = 1;}
        else if (msg.value == LEVEL_PRICE[8]) { level = 8; league = 1;}
        else if (msg.value == LEVEL_PRICE[9]) { level = 1; league = 2;}
        else if (msg.value == LEVEL_PRICE[10]) { level = 2; league = 2;}
        else if (msg.value == LEVEL_PRICE[11]) { level = 3; league = 2;}
        else if (msg.value == LEVEL_PRICE[12]) { level = 4; league = 2;}
        else if (msg.value == LEVEL_PRICE[13]) { level = 5; league = 2;}
        else if (msg.value == LEVEL_PRICE[14]) { level = 6; league = 2;}
        else if (msg.value == LEVEL_PRICE[15]) { level = 7; league = 2;}
        else if (msg.value == LEVEL_PRICE[16]) { level = 8; league = 2;}
        else if (msg.value == LEVEL_PRICE[17]) { level = 1; league = 3;}
        else if (msg.value == LEVEL_PRICE[18]) { level = 2; league = 3;}
        else if (msg.value == LEVEL_PRICE[19]) { level = 3; league = 3;}
        else if (msg.value == LEVEL_PRICE[20]) { level = 4; league = 3;}
        else if (msg.value == LEVEL_PRICE[21]) { level = 5; league = 3;}
        else if (msg.value == LEVEL_PRICE[22]) { level = 6; league = 3;}
        else if (msg.value == LEVEL_PRICE[23]) { level = 7; league = 3;}
        else if (msg.value == LEVEL_PRICE[24]) { level = 8; league = 3;}
        else revert('Incorrect Value send');

        if (users[msg.sender].isExist) buyLevel(level, league);
        else if (level == 1 && !users[msg.sender].isExist && league == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);
            if (users[referrer].isExist) refId = users[referrer].id;
            else revert('Incorrect referrer');
            regUser(refId);
        } else revert('Please buy first level for 0.04 ETH');
    }

    function regUser(uint _referrerID) public payable {
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');

        if (users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT && userList[_referrerID] != ownerWallet) _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID++;
        l1l1users++;


        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH_STANDARD;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender, 1);

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint _level, uint _league) public payable {
        
        require(users[msg.sender].isExist, 'User not exist');
        require(_level > 0 && _level <= 8, 'Incorrect level');
        uint l;
        
         if (_league == 2) for (l = 5; l > 0; l--) require(users[msg.sender].levelExpired[l] >= PERIOD_LENGTH_PRO, 'Buy the previous league 1 level 5');
         else if (_league == 3) {
            for (l = 5; l > 0; l--) require(users[msg.sender].levelExpired[l] >= PERIOD_LENGTH_LEGENDARY, 'Buy the previous league 1 level 5');
            for (l = 5; l > 0; l--) require(users[msg.sender].levelExpiredPro[l] >= PERIOD_LENGTH_LEGENDARY, 'Buy the previous league 2 level 5');
         }

        
        if (_level == 1) {
            if (_league == 1) require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');
            else if (_league == 2) require(msg.value == LEVEL_PRICE[9], 'Incorrect Value');
            else if (_league == 3) require(msg.value == LEVEL_PRICE[17], 'Incorrect Value');

            if (_league == 1) {
                l1l1users++;
                users[msg.sender].levelExpired[1] += PERIOD_LENGTH_STANDARD;
            } else if (_league == 2) {
                if (users[msg.sender].levelExpiredPro[1] == 0) {
                    l2l1users++;
                    users[msg.sender].levelExpiredPro[1] = now + PERIOD_LENGTH_PRO;
                } else users[msg.sender].levelExpiredPro[1] += PERIOD_LENGTH_PRO;
             } else if (_league == 3) {
                if (users[msg.sender].levelExpiredLegendary[1] == 0) {
                    users[msg.sender].levelExpiredLegendary[1] = now + PERIOD_LENGTH_LEGENDARY;
                    l3l1users++;
                } else users[msg.sender].levelExpiredLegendary[1] += PERIOD_LENGTH_LEGENDARY;
            }
        } else {
            if (_league == 1) {
                require(msg.value == LEVEL_PRICE[_level], 'Incorrect Value');
                for (l = _level - 1; l > 0; l--) require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
                if (users[msg.sender].levelExpired[_level] == 0) {
                        users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH_STANDARD;
                } else users[msg.sender].levelExpired[_level] += PERIOD_LENGTH_STANDARD;
                if (_level == 1) l1l1users++;
                if (_level == 2) l1l2users++;
                if (_level == 3) l1l3users++;
                if (_level == 4) l1l4users++;
                if (_level == 5) l1l5users++;
                if (_level == 6) l1l6users++;
                if (_level == 7) l1l7users++;
                if (_level == 8) l1l8users++;
            } else if (_league == 2) {
                require(msg.value == LEVEL_PRICE[_level + 8], 'Incorrect Value');
                for (l = _level - 1; l > 0; l--) require(users[msg.sender].levelExpiredPro[l] >= now, 'Buy the previous level');
                if (users[msg.sender].levelExpiredPro[_level] == 0) {
                    users[msg.sender].levelExpiredPro[_level] = now + PERIOD_LENGTH_PRO;
                } else users[msg.sender].levelExpiredPro[_level] += PERIOD_LENGTH_PRO;
                if (_level == 1) l2l1users++;
                if (_level == 2) l2l2users++;
                if (_level == 3) l2l3users++;
                if (_level == 4) l2l4users++;
                if (_level == 5) l2l5users++;
                if (_level == 6) l2l6users++;
                if (_level == 7) l2l7users++;
                if (_level == 8) l2l8users++;
            } else if (_league == 3) {
                require(msg.value == LEVEL_PRICE[_level + 16], 'Incorrect Value');
                for (l = _level - 1; l > 0; l--) require(users[msg.sender].levelExpiredLegendary[l] >= now, 'Buy the previous level');
                if (users[msg.sender].levelExpiredLegendary[_level] == 0) {
                    users[msg.sender].levelExpiredLegendary[_level] = now + PERIOD_LENGTH_LEGENDARY;
                } else users[msg.sender].levelExpiredLegendary[_level] += PERIOD_LENGTH_LEGENDARY;
                if (_level == 1) l3l1users++;
                if (_level == 2) l3l2users++;
                if (_level == 3) l3l3users++;
                if (_level == 4) l3l4users++;
                if (_level == 5) l3l5users++;
                if (_level == 6) l3l6users++;
                if (_level == 7) l3l7users++;
                if (_level == 8) l3l8users++;
            }
        }

        payForLevel(_level, msg.sender, _league);
        emit buyLevelEvent(msg.sender, _level, _league, now);
    }


   
    function payForLevel(uint _level, address _user, uint _league) internal {
        
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if(_level == 1 || _level == 5){
            referer = userList[users[_user].referrerID];
        } else if(_level == 2 || _level == 6){
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if(_level == 3 || _level == 7){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if(_level == 4 || _level == 8){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if (!users[referer].isExist) referer = userList[1];

        bool sent = false;
        bool acceptible = false;
        if (_league == 1) if (users[referer].levelExpired[_level] >= now) acceptible = true;
        if (_league == 2) if (users[referer].levelExpiredPro[_level] >= now) acceptible = true;
        if (_league == 3) if (users[referer].levelExpiredLegendary[_level] >= now) acceptible = true;
        if (acceptible) {
            if (ownable.viewManager() != ownerWallet && referer == userList[1]) {
                if (_league == 1) sent = ownable.viewManager().send(LEVEL_PRICE[_level]);
                if (_league == 2) sent = ownable.viewManager().send(LEVEL_PRICE[_level + 8]);
                if (_league == 3) sent = ownable.viewManager().send(LEVEL_PRICE[_level + 16]);
            } else {
                if (_league == 1) sent = address(uint160(referer)).send(LEVEL_PRICE[_level]);
                if (_league == 2) sent = address(uint160(referer)).send(LEVEL_PRICE[_level + 8]);
                if (_league == 3) sent = address(uint160(referer)).send(LEVEL_PRICE[_level + 16]);
            }
            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, _league, now);
            }
        }
        if (!sent) {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, _league, now);
            payForLevel(_level, referer, _league);
        }
    }


    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;
        address[] memory referrals = new address[](2046);
        referrals[0] = users[_user].referral[0]; 
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i =0; i<2046;i++){
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT){
                if(i<1022){
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }else{
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
    function referralsCountt(address _user, uint _time) public view returns(uint) {
       
        uint referrals = 0;

        referrals += users[_user].referral.length;

        if (users[_user].referral.length > 0) {
            for(uint a = 0; a < users[_user].referral.length; a++){
                address tempUserA = users[_user].referral[a];
                referrals += users[tempUserA].referral.length;
                
                if (users[tempUserA].referral.length > 0) {
                    for(uint b = 0; b < users[tempUserA].referral.length; b++){
                        address tempUserB = users[tempUserA].referral[b];
                        referrals += users[tempUserB].referral.length;
                        
                        if (users[tempUserB].referral.length > 0) {
                            for(uint c = 0; c < users[tempUserB].referral.length; c++){
                                address tempUserC = users[tempUserB].referral[c];
                                referrals += users[tempUserC].referral.length;
                                if (_time < 2) {
                                    referrals += referralsCountt(tempUserC, 2);
                                }
                            } 
                         }
                    } 
                }
            } 
        }
        
        return referrals;
    
    }
     function viewUserLevel(address _user) public view returns(uint[8][]) {
        uint[8][] memory data = new uint[8][](3);
        for(uint i =1;i<=3;i++) for(uint j =1;j<= 8;j++) if(i==1) data[i-1][j-1] = users[_user].levelExpired[j]; else if (i==2) data[i-1][j-1] = users[_user].levelExpiredPro[j]; else if (i==3) data[i-1][j-1] = users[_user].levelExpiredLegendary[j];
        return data;
    }
    
        function liveUsersStatistics() public view returns(uint[27]) {
        uint totalLeague1 = 0;
        uint totalLeague2 = 0;
        uint totalLeague3 = 0;

        for (uint i = 0; i < 8; i++) {
            totalLeague1 = l1l1users + l1l2users + l1l3users + l1l4users + l1l5users + l1l6users + l1l7users + l1l8users;
            totalLeague2 = l2l1users + l2l2users + l2l3users + l2l4users + l2l5users + l2l6users + l2l7users + l2l8users;
            totalLeague3 = l3l1users + l3l2users + l3l3users + l3l4users + l3l5users + l3l6users + l3l7users + l3l8users;
        }

        uint[27] memory data = [l1l1users, l1l2users, l1l3users, l1l4users, l1l5users, l1l6users, l1l7users, l1l8users, l2l1users, l2l2users, l2l3users, l2l4users, l2l5users, l2l6users, l2l7users, l2l8users, l3l1users, l3l2users, l3l3users, l3l4users, l3l5users, l3l6users, l3l7users, l3l8users, totalLeague1 , totalLeague2, totalLeague3];
        return data;
    }
    
    function viewUserLevelExpired(address _user, uint _level, uint _league) public view returns(uint) {
        if (_league == 1) return users[_user].levelExpired[_level];
        else if (_league == 2) return users[_user].levelExpiredPro[_level]; 
        return users[_user].levelExpiredLegendary[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns(address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}