//SourceUnit: tronmineLive.sol

pragma solidity 0.5.8;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract TronMine {
    
    using SafeMath for uint;
    
    struct UserStruct{ // user struct
        bool isExist;
        uint id;
        uint actualRefID;
        uint referrerID;
        uint package;
        uint totalTopUpInvest;
        uint topupCount;
        uint cellingPackage;
        uint celling;
        uint expiry;
        uint totalEarned;
        uint[] referrals;
        uint8 blocked; // 1- unblock 2- block
        uint created;
        uint8 rewardStatus; // 0- not received 1- received
    }
    
    struct InvestmentStruct{ // user investments
        uint initialInvestment;
        uint directBonusEarned;
        uint binaryInvestment;
        uint binaryEarned;
        uint topUpBinaryEarned;
        uint ROIEarned;
        uint totalInvestments;
        uint investID;
        mapping(uint => InvestmentInfoStruct) investInfo;
    }
    
    struct InvestmentInfoStruct{
        uint investAmount;
        uint time;
        uint8 flag; // 1- reg, 2 - topup, 3- repack
    }
    
    // struct Invest
    
    struct PackageStruct{
        uint packagePrice;
        uint packageExpiry;
        uint celling;
        uint ROI;
    }
    
    address public ownerWallet;
    address public distributor;
    
    uint public currentUserID;
    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint minimumTopUp = 5000 trx;
    uint rewardValue = 5000000 trx;
    
    uint public lockStatus = 1;
    
    mapping(uint => UserStruct) public users; // users mapping;
    mapping(uint => InvestmentStruct) public userInvestments; // investment mapping;
    
    mapping (uint => uint) public dailyPayout;
    mapping (uint => uint) public dailyPayoutTime;
    
    mapping(uint => address) public usersList; // users address by id;
    mapping(address => uint[]) public userIDList; // view user id's by user address
    mapping(uint => PackageStruct) public packages; // packages
    
    
    // Events
    
    event regUserEvent(address indexed _user, uint _userID, address indexed _referrer, uint _referrerID, uint  _initialInvestment, uint _time);
    event rePackageEvent(address indexed _user, uint _userID, uint _package, uint _investment, uint _time);
    event topUpEvent(address indexed _user, uint _userID, uint  _initialInvestment, uint _time);
    event directBonusEvent(address indexed _user, uint _userID, address indexed _referrer, uint _referrerID, uint  _bonus, uint _time);
    event binaryCommissionEvent(address indexed _user, uint _userID, uint _binaryPayout, uint _time);
    event ROIEvent( address indexed _user, uint indexed _userID, uint _amount, uint _time);
    event topUpBinaryEvent(address indexed _user, uint indexed _userID, uint _payout, uint _leftBinaryAmount, uint _righttBinaryAmount, uint _time);
    event rewardEvent(address indexed _user, uint _userID, uint _amount, uint _time);
    
    constructor( address _distributor)public{
        ownerWallet = msg.sender;
        distributor = _distributor;
        
        packages[1].packagePrice =  1000 trx;
        packages[2].packagePrice =  3000 trx;
        packages[3].packagePrice =  15000 trx;
        packages[4].packagePrice =  30000 trx;
        packages[5].packagePrice =  50000 trx;
        
        packages[1].packageExpiry =  100 days;
        packages[2].packageExpiry =  136 days;
        packages[3].packageExpiry =  117 days;
        packages[4].packageExpiry =  102 days;
        packages[5].packageExpiry =  102 days;
        
        packages[1].celling =  1000 trx;
        packages[2].celling =  3000 trx;
        packages[3].celling =  15000 trx;
        packages[4].celling =  30000 trx;
        packages[5].celling =  50000 trx;
        
        packages[1].ROI =  0;
        packages[2].ROI =  1.5 trx;
        packages[3].ROI =  1.75 trx;
        packages[4].ROI =  2 trx;
        packages[5].ROI =  2 trx;
        
        
        currentUserID++;
        
        usersList[currentUserID] = ownerWallet;
        
        UserStruct memory userStruct;
        
        userStruct = UserStruct({
            isExist : true,
            id : currentUserID,
            actualRefID: 0,
            referrerID : 0,
            package : 5,
            totalTopUpInvest: 0,
            topupCount: 0,
            cellingPackage: 5,
            celling : packages[5].celling,
            expiry: 55555555555,
            totalEarned:0,
            blocked:1,
            created: now.add(30 days),
            rewardStatus:0,
            referrals : new uint[](0)
        });
        
        users[currentUserID] = userStruct;
        userIDList[ownerWallet].push(currentUserID);
        dailyPayoutTime[currentUserID] = now;
    }
    
    
    
    function regUser(uint _referrerID, uint _package) public payable {
        require(lockStatus == 1,"Contract Locked");
        require((userIDList[msg.sender].length == 0), "user exist in previous ID");
        require((_referrerID != 0) && (users[_referrerID].isExist), "invalid referrer address");
        require((_package > 0) && (_package <= 5), "invalid package id");
        require( msg.value == packages[_package].packagePrice, "invalid value");
        
        uint orginalID = _referrerID;
        
        if(users[_referrerID].referrals.length >= REFERRER_1_LEVEL_LIMIT)
            _referrerID = users[findFreeReferrer(_referrerID)].id;
        
        
        currentUserID++;
            
        UserStruct memory userStruct;
        InvestmentStruct memory investStruct;
        
        userStruct = UserStruct({
            isExist : true,
            id : currentUserID,
            actualRefID : orginalID,
            referrerID : _referrerID,
            package : _package,
            totalTopUpInvest: packages[_package].celling,
            topupCount: 0,
            cellingPackage: _package,
            celling : packages[_package].celling,
            expiry: now.add(packages[_package].packageExpiry),
            totalEarned:0,
            blocked:1,
            created: now.add(30 days),
            rewardStatus:0,
            referrals : new uint[](0)
        });
        
        investStruct = InvestmentStruct({
            initialInvestment : msg.value,
            directBonusEarned : 0,
            binaryInvestment : msg.value,
            binaryEarned : 0,
            topUpBinaryEarned:0,
            ROIEarned : 0,
            totalInvestments : msg.value,
            investID:1
        });
        
        users[currentUserID] = userStruct;
        usersList[currentUserID] = msg.sender;
        userInvestments[currentUserID] = investStruct;
        
        userInvestments[currentUserID].investInfo[userInvestments[currentUserID].investID].investAmount = msg.value;
        userInvestments[currentUserID].investInfo[userInvestments[currentUserID].investID].time = now;
        userInvestments[currentUserID].investInfo[userInvestments[currentUserID].investID].flag = 1;
        
        userIDList[msg.sender].push(currentUserID);
        
        
        dailyPayoutTime[currentUserID] = now;
        
        users[_referrerID].referrals.push(currentUserID);
        
        directBonus(users[currentUserID].actualRefID, currentUserID); // referral bonus
        
        emit regUserEvent( msg.sender, currentUserID, usersList[_referrerID], _referrerID, userInvestments[currentUserID].initialInvestment, now);
    }
    
    function topUp() external payable{
        require(lockStatus == 1,"Contract Locked");
        require(userIDList[msg.sender].length > 0, "user not exist");
        require(msg.value > 0, "value must be greater than zero");
        require(msg.value >= minimumTopUp, "value must be greater than or equal to minimumTopUp");
        
        uint _TopUpCount = (msg.value.div(minimumTopUp));
        require(msg.value == minimumTopUp.mul(_TopUpCount), "invalid amount");
        
        uint _userID = userIDList[msg.sender][userIDList[msg.sender].length-1];
        
        require(users[_userID].blocked == 1, "user is not in active state");
        
        users[_userID].topupCount++;
        
        userInvestments[_userID].binaryInvestment = userInvestments[_userID].binaryInvestment.add(msg.value);
        userInvestments[_userID].totalInvestments = userInvestments[_userID].totalInvestments.add(msg.value);
        
        userInvestments[_userID].investID++;
        
        userInvestments[_userID].investInfo[userInvestments[_userID].investID].investAmount = msg.value;
        userInvestments[_userID].investInfo[userInvestments[_userID].investID].time = now;
        userInvestments[_userID].investInfo[userInvestments[_userID].investID].flag = 2;
        
        uint _celling = checkCelling( users[_userID].celling);
        
        users[_userID].totalTopUpInvest += msg.value;
        
        if(users[_userID].celling < users[_userID].totalTopUpInvest){
            _celling = checkCelling( users[_userID].totalTopUpInvest);
            users[_userID].celling = packages[_celling].celling;
        }
            
        
        if((users[_userID].topupCount == 1) && (users[_userID].cellingPackage == 1)){
            users[_userID].expiry = now.add(packages[_celling].packageExpiry);
            users[_userID].cellingPackage = _celling;
        }
        else
            users[_userID].expiry = now.add(packages[users[_userID].cellingPackage].packageExpiry);
        
        emit topUpEvent( msg.sender, _userID, msg.value, now);
    }
    
    function rePackage(uint _package) public payable returns(bool){
        require(lockStatus == 1,"Contract Locked");
        require(userIDList[msg.sender].length > 0, "user not exist");
        require( msg.value == packages[_package].packagePrice, "invalid value");
        uint _userID = userIDList[msg.sender][userIDList[msg.sender].length-1];
        
        require(users[_userID].blocked == 2, "user is not in inactive state");
        
        users[_userID].package = _package;
        users[_userID].cellingPackage = _package;
        users[_userID].celling = packages[_package].celling;
        users[_userID].totalTopUpInvest = packages[_package].celling;
        
        userInvestments[_userID].binaryInvestment = userInvestments[_userID].binaryInvestment.add(msg.value);
        userInvestments[_userID].totalInvestments = userInvestments[_userID].totalInvestments.add(msg.value);
        
        userInvestments[_userID].investID++;
        
        userInvestments[_userID].investInfo[userInvestments[_userID].investID].investAmount = msg.value;
        userInvestments[_userID].investInfo[userInvestments[_userID].investID].time = now;
        userInvestments[_userID].investInfo[userInvestments[_userID].investID].flag = 3;
        
        users[_userID].topupCount = 0;
        users[_userID].blocked = 1;
        
        users[_userID].expiry = now.add(packages[users[_userID].cellingPackage].packageExpiry);
        dailyPayoutTime[_userID] = now;
        
        emit rePackageEvent( msg.sender, _userID, _package, msg.value, now);
        
        return true;
    }
    
    function checkCelling(uint _amount) internal view returns( uint){
        if((_amount >= packages[1].celling) && (_amount < packages[2].celling))
            return 1;
        else if((_amount >= packages[2].celling) && (_amount < packages[3].celling))
            return 2;
        else if((_amount >= packages[3].celling) && (_amount < packages[4].celling))
            return 3;
        else if((_amount >= packages[4].celling) && (_amount < packages[5].celling))
            return 4;
        else 
            return 5;
    }       
    
    function injectUsers( address[] memory _users, uint[] memory _refID, uint[] memory _package) public returns(bool){
        require(msg.sender == distributor, "only distributor");
        require(_users.length == _refID.length && _refID.length == _package.length, "invalid length");
        
        uint orginalID;
        
        for(uint i=0;i<_users.length;i++){
            require((_refID[i] != 0) && (users[_refID[i]].isExist), "invalid referrer address");
            require((_package[i] > 0) && (_package[i] <= 5), "invalid package id");
            require(users[_refID[i]].isExist == true, "referrer not exist");
            require((userIDList[_users[i]].length == 0), "user already exist");
            
            orginalID = _refID[i];
            
            if(users[_refID[i]].referrals.length >= REFERRER_1_LEVEL_LIMIT)
                _refID[i] = users[findFreeReferrer(_refID[i])].id;
        
            currentUserID++;
                   
            UserStruct memory userStruct;
            InvestmentStruct memory investStruct;
            
            userStruct = UserStruct({
                isExist : true,
                id : currentUserID,
                actualRefID : orginalID,
                referrerID : _refID[i],
                package : _package[i],
                totalTopUpInvest: packages[_package[i]].celling,
                topupCount: 0,
                cellingPackage : _package[i],
                celling : packages[_package[i]].celling,
                expiry: now.add(packages[_package[i]].packageExpiry),
                totalEarned:0,
                blocked:1,
                created: now.add(30 days),
                rewardStatus:0,
                referrals : new uint[](0)
            });
            
            investStruct = InvestmentStruct({
                initialInvestment : 0,
                directBonusEarned : 0,
                binaryInvestment : 0,
                binaryEarned : 0,
                topUpBinaryEarned:0,
                ROIEarned : 0,
                totalInvestments : 0 ,
                investID:0
            });
            
            users[currentUserID] = userStruct;
            usersList[currentUserID] = _users[i];
            userInvestments[currentUserID] = investStruct;
            userIDList[_users[i]].push(currentUserID);
            
            dailyPayoutTime[currentUserID] = now;
            
            users[_refID[i]].referrals.push(currentUserID);
            
            
            emit regUserEvent( _users[i], currentUserID, usersList[_refID[i]], _refID[i], userInvestments[currentUserID].initialInvestment, now);
            
        }
    }
    
    function updatedPackageExpiry( uint _package, uint _days) public returns(bool){
        require(msg.sender == ownerWallet,"Only ownerWallet");
        packages[_package].packageExpiry = _days;
        return true;
    }
    
    function contractLock(uint _lockStatus) public returns (bool) {
        require(msg.sender == ownerWallet, "Invalid User");
        require(_lockStatus ==1 || _lockStatus == 2);

        lockStatus = _lockStatus;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerWallet, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
    
    function userInvestInfo( uint _userID, uint _investID) public  view returns( uint _invetAmount, uint _investTime, uint _investType){
        return(userInvestments[_userID].investInfo[_investID].investAmount,userInvestments[_userID].investInfo[_investID].time,userInvestments[_userID].investInfo[_investID].flag);
    }
    
    function viewUserReferral(uint _userID) public view returns(uint[] memory) {
        return users[_userID].referrals;
    }
    
    function findFreeReferrer(uint _userID) public view returns(uint) {
        if(users[_userID].referrals.length < REFERRER_1_LEVEL_LIMIT) return _userID;

        uint[] memory referrals = new uint[](126);
        referrals[0] = users[_userID].referrals[0];
        referrals[1] = users[_userID].referrals[1];

        uint freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referrals.length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referrals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referrals[1];
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
    
        // Referral Bounus
    
    function directBonus(uint _ref, uint _usrID) internal{
        
        if(((block.timestamp.sub(dailyPayoutTime[_ref])).div(1 days)) >= 1){
            dailyPayout[_ref] = 0;
            dailyPayoutTime[_ref] = now;
        }
        
        if(users[_ref].blocked == 2) return;
            
        if(users[_ref].expiry < now) {
            users[_ref].blocked = 2;
            return;
        }
        
        uint directBonus_5_percentage = userInvestments[_usrID].initialInvestment*(5 trx)/(100 trx);
        
        if(directBonus_5_percentage > 0){
            address referrer = usersList[_ref];
            
            require(address(uint160(referrer)).send(directBonus_5_percentage*(95 trx)/(100 trx)), "directBonus failed");
            userInvestments[_ref].directBonusEarned +=  directBonus_5_percentage*(95 trx)/(100 trx);
            users[_ref].totalEarned = users[_ref].totalEarned.add(directBonus_5_percentage*(95 trx)/(100 trx));
            
            require(address(uint160(distributor)).send(directBonus_5_percentage*(5 trx)/(100 trx)));
            // users[1].totalEarned = users[1].totalEarned.add(directBonus_5_percentage*(5 trx)/(100 trx));
            
            emit directBonusEvent( usersList[_usrID], _usrID, referrer, users[_ref].id, directBonus_5_percentage*(95 trx)/(100 trx), now);
        }
    }
    
    // binary payout
    function binaryMapping(uint[] memory _userID, uint[] memory _binaryPayout) public {
        require(lockStatus == 1,"Contract Locked");
        require(msg.sender == distributor, "only distributor");
        require(_userID.length == _binaryPayout.length,"invalid arguments length");
        
        for(uint i=0;i<_userID.length;i++){
            
            if(((block.timestamp.sub(dailyPayoutTime[_userID[i]])).div(1 days)) >= 1){
                dailyPayout[_userID[i]] = 0;
                dailyPayoutTime[_userID[i]] = now;
            }
            
            if(users[_userID[i]].blocked == 2) continue;
            
            if(users[_userID[i]].expiry < now) {
                users[_userID[i]].blocked = 2;
                continue;
            }
            
            if((dailyPayout[_userID[i]]+_binaryPayout[i] > users[_userID[i]].celling) && (_userID[i] != 1))
                _binaryPayout[i] = users[_userID[i]].celling - dailyPayout[_userID[i]];
            
            if(_binaryPayout[i] > 0){
                require(address(uint160(usersList[_userID[i]])).send((_binaryPayout[i].mul(95 trx).div(100 trx))),"Binary 95% transfer failed ");
                require(address(uint160(distributor)).send((_binaryPayout[i].mul(5 trx).div(100 trx))),"binary admin commission 5% transfer failed ");
                        
                userInvestments[_userID[i]].binaryEarned = userInvestments[_userID[i]].binaryEarned.add((_binaryPayout[i].mul(95 trx).div(100 trx)));
                users[_userID[i]].totalEarned = users[_userID[i]].totalEarned.add((_binaryPayout[i].mul(95 trx).div(100 trx)));
                
                dailyPayout[_userID[i]] = dailyPayout[_userID[i]].add((_binaryPayout[i].mul(95 trx).div(100 trx)));
                // users[1].totalEarned = users[1].totalEarned.add((_binaryPayout.mul(5 trx).div(100 trx)));
                
                if((userInvestments[_userID[i]].binaryEarned >= rewardValue) && (users[_userID[i]].created >= now) && (users[_userID[i]].rewardStatus == 0)){
                    uint _reward = rewardValue.mul(5 trx).div(100 trx);
                    require(address(uint160(usersList[_userID[i]])).send(_reward.mul(95 trx).div(100 trx)),"reward transfer failed");
                    users[_userID[i]].totalEarned = users[_userID[i]].totalEarned.add(_reward.mul(95 trx).div(100 trx));
    
                    require(address(uint160(distributor)).send((_reward.mul(5 trx).div(100 trx))),"reward admin commission 5% transfer failed ");
                    // users[1].totalEarned = users[1].totalEarned.add((_reward.mul(5 trx).div(100 trx)));
    
                    users[_userID[i]].rewardStatus = 1;
                    emit rewardEvent( usersList[_userID[i]], _userID[i], rewardValue.mul(95 trx).div(100 trx), now);
                }
                
                emit binaryCommissionEvent( usersList[_userID[i]], _userID[i], (_binaryPayout[i].mul(95 trx).div(100 trx)), now);
            }
        }
    }
    
    function ROIDistribution(uint[] memory _userID, uint[] memory _amount) public{ // ROI
    
        require(lockStatus == 1,"Contract Locked");
        require(msg.sender == distributor, "only distributor");
        require(_userID.length == _amount.length,"invalid arguments length");
        
        for(uint i=0;i<_userID.length;i++){
            if(users[_userID[i]].blocked == 2) continue;
            
            if(users[_userID[i]].expiry < now) {
                users[_userID[i]].blocked = 2;
                continue;
            }
            
            if(_amount[i] > 0){
                require(address(uint160(usersList[_userID[i]])).send(_amount[i].mul(95 trx).div(100 trx)), "ROI 95% transfer failed");
                require(address(uint160(distributor)).send((_amount[i].mul(5 trx).div(100 trx))),"ROI admin commission 5% transfer failed ");
                
                userInvestments[_userID[i]].ROIEarned = userInvestments[_userID[i]].ROIEarned.add(_amount[i].mul(95 trx).div(100 trx));
                users[_userID[i]].totalEarned = users[_userID[i]].totalEarned.add(_amount[i].mul(95 trx).div(100 trx));
                // users[1].totalEarned = users[1].totalEarned.add((_amount.mul(5 trx).div(100 trx)));
                
                emit ROIEvent( usersList[_userID[i]], _userID[i], _amount[i].mul(95 trx).div(100 trx), now);
            }
        }
    }
    
}