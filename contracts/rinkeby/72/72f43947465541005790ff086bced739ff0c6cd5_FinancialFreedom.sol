/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.5.10;

contract FinancialFreedom {

    uint UPLINE_1_LVL_LIMIT = 5;
    uint PERIOD_LENGTH = 3 days;
    uint OWNER_EXPIRED_DATE = 55555555555;
    uint public currUserID = 0;

    address public ownerWallet;

    mapping (uint => uint) public LVL_COST;
    
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping (uint => uint) levelExpired;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _lvl, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _lvl, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _lvl, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _lvl, uint _time);


    constructor() public {
        ownerWallet = msg.sender;
        LVL_COST[1] = 1 ether;
        LVL_COST[2] = 2 ether;
        LVL_COST[3] = 3 ether;
        LVL_COST[4] = 4 ether;
        LVL_COST[5] = 5 ether;


        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        for (uint i = 1; i < 11; i++) {
            users[ownerWallet].levelExpired[i] = OWNER_EXPIRED_DATE;
        }
    }

    function () external payable {

        uint level;
        bool isCorrectValue = false;
        
        for (uint j = 1; j < 11; j++) {
            if(msg.value == LVL_COST[j]){
                level = j;
                isCorrectValue = true;
                break;
            }
        }
        require(isCorrectValue, 'Incorrect Value send');


        if(users[msg.sender].isExist){
            buyLevel(level);
        } else if(level == 1) {
            uint refId = 0;
            address upline = bytesToAddress(msg.data);

            if (users[upline].isExist){
                refId = users[upline].id;
            } else {
                revert('Incorrect upline');
            }

            regUser(refId);
        } else {
            revert("Please buy first level for 1 trx");
        }
    }

    function regUser(uint _referrerID) public payable {
        require(!users[msg.sender].isExist, 'User exist');

        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect Upline Id');

        require(msg.value==LVL_COST[1], 'Incorrect Value');


        if(users[userList[_referrerID]].referral.length >= UPLINE_1_LVL_LIMIT)
        {
            _referrerID = users[findFreeUpline(userList[_referrerID])].id;
        }

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
        for (uint i = 2; i < 11; i++) {
            users[msg.sender].levelExpired[i] = 0;
        }

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender);

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint _lvl) public payable {
        require(users[msg.sender].isExist, 'User not exist');

        require( _lvl>0 && _lvl<=10, 'Incorrect level');

        if(_lvl == 1){
            require(msg.value==LVL_COST[1], 'Incorrect Value');
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        } else {
            require(msg.value==LVL_COST[_lvl], 'Incorrect Value');

            for(uint l =_lvl-1; l>0; l-- ){
                require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            }

            if(users[msg.sender].levelExpired[_lvl] == 0){
                users[msg.sender].levelExpired[_lvl] = now + PERIOD_LENGTH;
            } else {
                users[msg.sender].levelExpired[_lvl] += PERIOD_LENGTH;
            }
        }
        payForLevel(_lvl, msg.sender);
        emit buyLevelEvent(msg.sender, _lvl, now);
    }

    function payForLevel(uint _lvl, address _user) internal {

        address upline;
        address upline1;
        address upline2;
        address upline3;
        address upline4;

        if(_lvl == 1){
            upline = userList[users[_user].referrerID];
        } else if(_lvl == 2){
            upline1 = userList[users[_user].referrerID];
            upline = userList[users[upline1].referrerID];
        } else if(_lvl == 3){
            upline1 = userList[users[_user].referrerID];
            upline2 = userList[users[upline1].referrerID];
            upline = userList[users[upline2].referrerID];
        } else if(_lvl == 4){
            upline1 = userList[users[_user].referrerID];
            upline2 = userList[users[upline1].referrerID];
            upline3 = userList[users[upline2].referrerID];
            upline = userList[users[upline3].referrerID];
        } else if(_lvl == 5){ 
            upline1 = userList[users[_user].referrerID];
            upline2 = userList[users[upline1].referrerID];
            upline3 = userList[users[upline2].referrerID];
            upline4 = userList[users[upline3].referrerID];
            upline = userList[users[upline4].referrerID];
        }

        if(!users[upline].isExist){
            upline = userList[1];
        }

        if(users[upline].levelExpired[_lvl] >= now ){
            address(uint160(upline)).transfer(LVL_COST[_lvl]);
            emit getMoneyForLevelEvent(upline, msg.sender, _lvl, now);
        } else {
            emit lostMoneyForLevelEvent(upline, msg.sender, _lvl, now);
            payForLevel(_lvl,upline);
        }
    }

    function findFreeUpline(address _user) public view returns(address) {
        if(users[_user].referral.length < UPLINE_1_LVL_LIMIT){
            return _user;
        }

        address[] memory referrals = new address[](62);
        referrals[0] = users[_user].referral[0]; 
        referrals[1] = users[_user].referral[1];

        address FreeUpline;
        bool noFreeUpline = true;

        for(uint i = 0; i<254; i++){
            if(users[referrals[i]].referral.length == UPLINE_1_LVL_LIMIT){
                if(i<126){
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }else{
                noFreeUpline = false;
                FreeUpline = referrals[i];
                break;
            }
        }
        require(!noFreeUpline, 'No Free Upline');
        return FreeUpline;

    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _lvl) public view returns(uint) {
        return users[_user].levelExpired[_lvl];
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address  addr ) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}