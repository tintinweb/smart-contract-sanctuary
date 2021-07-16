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
        uint referrerID;
        uint package;
        uint celling;
        uint expiry;
        uint totalEarned;
        uint[] referrals;
        uint8 blocked; // 1- unblock 2- block
        uint created;
        uint8 rewardStatus; // 0- not received 1- received
        mapping(uint => uint) referralsTopup;
        mapping(uint => uint) downlineBinaryCarryforward;
        mapping(uint => uint) downlineBinaryInvestment;
        
    }
    
    struct InvestmentStruct{ // user investments
        uint initialInvestment;
        uint directBonusEarned;
        uint binaryInvestment;
        uint binaryEarned;
        uint topUpBinaryEarned;
        uint[] investments;
        uint[] investROI;
        uint ROIEarned;
        uint totalInvestments;
    }
    
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
    // mapping(uint => uint) public packagesExpiry; // package expiry
    
    
    // Events
    
    event regUserEvent(address indexed _user, uint _userID, address indexed _referrer, uint _referrerID, uint  _initialInvestment, uint _time);
    event topUpEvent(address indexed _user, uint _userID, uint  _initialInvestment, uint _time);
    event directBonusEvent(address indexed _user, uint _userID, address indexed _referrer, uint _referrerID, uint  _bonus, uint _time);
    event binaryCommissionEvent(address indexed _user, uint _userID, uint _binaryPayout, uint _leftBinaryAmount, uint _righttBinaryAmount, uint _time);
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
        packages[2].packageExpiry =  115 days;
        packages[3].packageExpiry =  115 days;
        packages[4].packageExpiry =  100 days;
        packages[5].packageExpiry =  100 days;
        
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
            referrerID : 0,
            package : 5,
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
        require((userIDList[msg.sender].length == 0) || (users[userIDList[msg.sender][userIDList[msg.sender].length-1]].blocked == 2), "user exist in previous ID");
        require((_referrerID != 0) && (users[_referrerID].isExist), "invalid referrer address");
        require((_package > 0) && (_package <= 5), "invalid package id");
        require( msg.value == packages[_package].packagePrice, "invalid value");
        
        if(users[_referrerID].referrals.length >= REFERRER_1_LEVEL_LIMIT)
            _referrerID = users[findFreeReferrer(_referrerID)].id;
        
        currentUserID++;
            
        UserStruct memory userStruct;
        InvestmentStruct memory investStruct;
        
        userStruct = UserStruct({
            isExist : true,
            id : currentUserID,
            referrerID : _referrerID,
            package : _package,
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
            investments : new uint[] (0),
            investROI  : new uint[] (0),
            ROIEarned : 0,
            totalInvestments : msg.value 
        });
        
        users[currentUserID] = userStruct;
        usersList[currentUserID] = msg.sender;
        userInvestments[currentUserID] = investStruct;
        userIDList[msg.sender].push(currentUserID);
        
        userInvestments[currentUserID].investments.push(msg.value);
        userInvestments[currentUserID].investROI.push(packages[_package].ROI);
        
        dailyPayoutTime[currentUserID] = now;
        
        
        address referrerAddress = usersList[_referrerID];
        
        users[_referrerID].referrals.push(currentUserID);
        
        directBonus(_referrerID, currentUserID); // referral bonus
        
        emit regUserEvent( msg.sender, currentUserID, referrerAddress, _referrerID, userInvestments[currentUserID].initialInvestment, now);
    }
    
    function topUp() external payable{
        require(lockStatus == 1,"Contract Locked");
        require(userIDList[msg.sender].length > 0, "user not exist");
        require(msg.value > 0, "value must be greater than zero");
        require(msg.value >= minimumTopUp, "value must be greater than or equal to minimumTopUp");
        
        uint _TopUpCount = (msg.value.div(minimumTopUp));
        require(msg.value == minimumTopUp.mul(_TopUpCount), "invalid amount");
        
        uint _userID = userIDList[msg.sender][userIDList[msg.sender].length-1];
        
        require(users[_userID].blocked !=2,"user current ID blocked");
        
        userInvestments[_userID].investments.push(msg.value);
        
        userInvestments[_userID].binaryInvestment = userInvestments[_userID].binaryInvestment.add(msg.value);
        userInvestments[_userID].totalInvestments = userInvestments[_userID].totalInvestments.add(msg.value);
        
        uint _celling = checkCelling( users[_userID].celling);
        
        if(users[_userID].celling < msg.value){
            _celling = checkCelling( msg.value);
            users[_userID].celling = packages[_celling].celling;
        }
            
        userInvestments[_userID].investROI.push(packages[_celling].ROI);
        users[_userID].expiry = users[_userID].expiry.add(packages[users[_userID].package].packageExpiry);
        
        uint refID = users[_userID].referrerID;
        
        if(users[refID].referrals.length == 1)
            users[refID].referralsTopup[0] = users[refID].referralsTopup[0].add(msg.value);
        else{
            if(users[refID].referrals[0] == _userID)
                users[refID].referralsTopup[0] = users[refID].referralsTopup[0].add(msg.value);
            else
                users[refID].referralsTopup[1] = users[refID].referralsTopup[1].add(msg.value);
        }
        
        emit topUpEvent( msg.sender, _userID, msg.value, now);
    }
    
    function checkCelling(uint _amount) internal view returns( uint){
        if((_amount >= packages[2].celling) && (_amount < packages[3].celling))
            return 2;
        else if((_amount >= packages[3].celling) && (_amount < packages[4].celling))
            return 3;
        else if((_amount >= packages[4].celling) && (_amount < packages[5].celling))
            return 4;
        else 
            return 5;
    }       
    
    
    function binaryROIDistribution(uint[] calldata _usersID, uint[] calldata _amount) external returns(bool){
        require(lockStatus == 1,"Contract Locked");
        require(msg.sender == distributor, "only distributor");
        require(_usersID.length == _amount.length,"invalid arguments length");
        
        for(uint i=0; i<_usersID.length;i++){
            require(_amount[i] <= address(this).balance, "insufficient contract banalce");
            
            topUpBinaryMapping( _usersID[i]); // topup binary payout
            binaryMapping( _usersID[i]); // binary payout
            ROIDistribution( _usersID[i], _amount[i]); // ROI
        }
        
        return true;
    }
    
    function injectUsers( address[] memory _users, uint[] memory _refID, uint[] memory _package) public returns(bool){
        require(msg.sender == distributor, "only distributor");
        require(_users.length == _refID.length && _refID.length == _package.length, "invalid length");
        
        for(uint i=0;i<_users.length;i++){
            require((_refID[i] != 0) && (users[_refID[i]].isExist), "invalid referrer address");
            require((_package[i] > 0) && (_package[i] <= 5), "invalid package id");
            require(users[_refID[i]].isExist == true, "referrer not exist");
            require((userIDList[_users[i]].length == 0), "user already exist");
            
            if(users[_refID[i]].referrals.length >= REFERRER_1_LEVEL_LIMIT)
                _refID[i] = users[findFreeReferrer(_refID[i])].id;
        
            currentUserID++;
                   
            UserStruct memory userStruct;
            InvestmentStruct memory investStruct;
            
            userStruct = UserStruct({
                isExist : true,
                id : currentUserID,
                referrerID : _refID[i],
                package : _package[i],
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
                investments : new uint[] (0),
                investROI : new uint[] (0),
                ROIEarned : 0,
                totalInvestments : 0 
            });
            
            users[currentUserID] = userStruct;
            usersList[currentUserID] = _users[i];
            userInvestments[currentUserID] = investStruct;
            userIDList[_users[i]].push(currentUserID);
            
            dailyPayoutTime[currentUserID] = now;
            
            address referrerAddress = usersList[_refID[i]];
            
            users[_refID[i]].referrals.push(currentUserID);
            
            emit regUserEvent( _users[i], currentUserID, referrerAddress, _refID[i], userInvestments[currentUserID].initialInvestment, now);
            
        }
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
    
    function userInvestInfo( uint _userID, uint _investID) public  view returns( uint _invetAmount, uint investROI){
        return(userInvestments[_userID].investments[_investID],userInvestments[_userID].investROI[_investID]);
    }
    
    function viewUserReferral(uint _userID) public view returns(uint[] memory) {
        return users[_userID].referrals;
    }
    
    function viewUserSlRefCarryForward(uint _userID) public view returns(uint leftDownCarryout, uint rightDownCarryout, uint downLeftTotalBinaryInvest, uint downLRightTotalBinaryInvest) {
        return(users[_userID].downlineBinaryCarryforward[0],users[_userID].downlineBinaryCarryforward[1],users[_userID].downlineBinaryInvestment[0],users[_userID].downlineBinaryInvestment[1]);
    }
    
    function topUpBinaryReferrals(uint _userID) public view returns(uint leftTopUpReferral,uint rightTopUpReferral){
        return(users[_userID].referralsTopup[0],users[_userID].referralsTopup[1]);
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
        
        uint directBonus_5_percentage = userInvestments[_usrID].initialInvestment*(5 trx)/(100 trx);
        
        // if((dailyPayout[_ref]+directBonus_5_percentage > users[_ref].celling) && (_ref != 1))
        //     directBonus_5_percentage = users[_ref].celling - dailyPayout[_ref];
        
        if(directBonus_5_percentage > 0){
            address referrer = usersList[_ref];
            
            require(address(uint160(referrer)).send(directBonus_5_percentage*(95 trx)/(100 trx)), "directBonus failed");
            userInvestments[_ref].directBonusEarned +=  directBonus_5_percentage*(95 trx)/(100 trx);
            users[_ref].totalEarned = users[_ref].totalEarned.add(directBonus_5_percentage*(95 trx)/(100 trx));
            
            require(address(uint160(ownerWallet)).send(directBonus_5_percentage*(5 trx)/(100 trx)));
            users[1].totalEarned = users[1].totalEarned.add(directBonus_5_percentage*(5 trx)/(100 trx));
            
            emit directBonusEvent( usersList[_usrID], _usrID, referrer, users[_ref].id, directBonus_5_percentage*(95 trx)/(100 trx), now);
        }
    }
    
    // binary payout
    function binaryMapping(uint _userID) internal {
        
        if(((block.timestamp.sub(dailyPayoutTime[_userID])).div(1 days)) >= 1){
            dailyPayout[_userID] = 0;
            dailyPayoutTime[_userID] = now;
        }
        
        if(users[_userID].referrals.length < REFERRER_1_LEVEL_LIMIT) return;
        
        if(users[_userID].blocked == 2) return;
        
        if(users[_userID].expiry < now) {
            users[_userID].blocked = 2;
            return;
        }
        
        uint _ref_1 = users[_userID].referrals[0];
        uint _ref_2 = users[_userID].referrals[1];
        
        if((users[_ref_1].referrals.length == 0) 
        || (users[_ref_2].referrals.length == 0)){
            return;
        }
        
        uint _ref_1_binary;
        uint _ref_2_binary;
        
        if(users[_ref_1].referrals.length == 0)
            return;
        else if(users[_ref_1].referrals.length == 2){
            if(users[users[_ref_1].referrals[0]].blocked == 1)
                _ref_1_binary = _ref_1_binary.add(userInvestments[users[_ref_1].referrals[0]].binaryInvestment);

            if(users[users[_ref_1].referrals[1]].blocked == 1)
                _ref_1_binary = _ref_1_binary.add(userInvestments[users[_ref_1].referrals[1]].binaryInvestment);
        }
        else{
            if(users[users[_ref_1].referrals[0]].blocked == 1)
                _ref_1_binary = _ref_1_binary.add(userInvestments[users[_ref_1].referrals[0]].binaryInvestment);
        }
            
        users[_userID].downlineBinaryCarryforward[0] = users[_userID].downlineBinaryCarryforward[0].add(_ref_1_binary.sub(users[_userID].downlineBinaryInvestment[0]));
        users[_userID].downlineBinaryInvestment[0] = users[_userID].downlineBinaryInvestment[0].add(_ref_1_binary.sub(users[_userID].downlineBinaryInvestment[0]));
        
        if(users[_ref_2].referrals.length == 0)
            return;
        else if(users[_ref_2].referrals.length == 2){
            if(users[users[_ref_2].referrals[0]].blocked == 1)
                _ref_2_binary = _ref_2_binary.add(userInvestments[users[_ref_2].referrals[0]].binaryInvestment);

            if(users[users[_ref_2].referrals[1]].blocked == 1)
                _ref_2_binary = _ref_2_binary.add(userInvestments[users[_ref_2].referrals[1]].binaryInvestment);
        }
        else{
            if(users[users[_ref_2].referrals[0]].blocked == 1)
                _ref_2_binary = _ref_2_binary.add(userInvestments[users[_ref_2].referrals[0]].binaryInvestment);
        }
        
        users[_userID].downlineBinaryCarryforward[1] = users[_userID].downlineBinaryCarryforward[1].add(_ref_2_binary.sub(users[_userID].downlineBinaryInvestment[1]));
        users[_userID].downlineBinaryInvestment[1] = users[_userID].downlineBinaryInvestment[1].add(_ref_2_binary.sub(users[_userID].downlineBinaryInvestment[1]));

        uint binary_payout;
            
        if(users[_userID].downlineBinaryCarryforward[0] < users[_userID].downlineBinaryCarryforward[1])    
            binary_payout = users[_userID].downlineBinaryCarryforward[0];
        else
            binary_payout = users[_userID].downlineBinaryCarryforward[1];
        
        uint binary_upline_payout;
        
        if(binary_payout > 0)
            binary_upline_payout = (binary_payout.mul(10 trx)).div(100 trx);
        else
            return;
        
        if((dailyPayout[_userID]+binary_upline_payout > users[_userID].celling) && (_userID != 1))
            binary_upline_payout = users[_userID].celling - dailyPayout[_userID];
        
        if(binary_upline_payout > 0){
            require(address(uint160(usersList[_userID])).send((binary_upline_payout.mul(95 trx).div(100 trx))),"Binary 95% transfer failed ");
            require(address(uint160(ownerWallet)).send((binary_upline_payout.mul(5 trx).div(100 trx))),"binary admin commission 5% transfer failed ");
                    
            userInvestments[_userID].binaryEarned = userInvestments[_userID].binaryEarned.add((binary_upline_payout.mul(95 trx).div(100 trx)));
            users[_userID].totalEarned = users[_userID].totalEarned.add((binary_upline_payout.mul(95 trx).div(100 trx)));
            dailyPayout[_userID] = dailyPayout[_userID].add((binary_upline_payout.mul(95 trx).div(100 trx)));
            users[1].totalEarned = users[1].totalEarned.add((binary_upline_payout.mul(5 trx).div(100 trx)));
            
            users[_userID].downlineBinaryCarryforward[0] = users[_userID].downlineBinaryCarryforward[0].sub(binary_payout);
            users[_userID].downlineBinaryCarryforward[1] = users[_userID].downlineBinaryCarryforward[1].sub(binary_payout);
            
            if((userInvestments[_userID].binaryEarned >= rewardValue) && (users[_userID].created >= now) && (users[_userID].rewardStatus == 0)){
                uint _reward = rewardValue.mul(5 trx).div(100 trx);
                require(address(uint160(usersList[_userID])).send(_reward.mul(95 trx).div(100 trx)),"reward transfer failed");
                users[_userID].totalEarned = users[_userID].totalEarned.add(_reward.mul(95 trx).div(100 trx));

                require(address(uint160(ownerWallet)).send((_reward.mul(5 trx).div(100 trx))),"reward admin commission 5% transfer failed ");
                users[1].totalEarned = users[1].totalEarned.add((_reward.mul(5 trx).div(100 trx)));

                users[_userID].rewardStatus = 1;
                emit rewardEvent( usersList[_userID], _userID, rewardValue.mul(95 trx).div(100 trx), now);
            }
            
            emit binaryCommissionEvent( usersList[_userID], _userID, binary_upline_payout, users[_userID].downlineBinaryCarryforward[0], users[_userID].downlineBinaryCarryforward[1], now);
        }
    }
    
    // TopUp binary payout
    function topUpBinaryMapping(uint _userID) internal {
        
        if(((block.timestamp.sub(dailyPayoutTime[_userID])).div(1 days)) >= 1){
            dailyPayout[_userID] = 0;
            dailyPayoutTime[_userID] = now;
        }
        
        if(users[_userID].referrals.length < REFERRER_1_LEVEL_LIMIT) return;
        if(users[_userID].blocked == 2) return;
        
        if((users[_userID].referralsTopup[0] == 0) || (users[_userID].referralsTopup[1] ==0))
            return;
            
        uint topUpBinaryPayout;
            
        if(users[_userID].referralsTopup[0] < users[_userID].referralsTopup[1])
            topUpBinaryPayout = users[_userID].referralsTopup[0];
        else
            topUpBinaryPayout = users[_userID].referralsTopup[1];
        
        uint _payout = topUpBinaryPayout.mul(1e19).div(1e20); // 10% payout;
        
        if((dailyPayout[_userID]+_payout > users[_userID].celling) && (_userID != 1))
            _payout = users[_userID].celling - dailyPayout[_userID];
        
        if(_payout > 0){
            require(address(uint160(usersList[_userID])).send(_payout.mul(95 trx).div(100 trx)),"TopUp 95% binary payout failed");
            require(address(uint160(ownerWallet)).send((_payout.mul(5 trx).div(100 trx))),"top up admin commission 5% transfer failed ");
            userInvestments[_userID].topUpBinaryEarned =  userInvestments[_userID].topUpBinaryEarned.add(_payout.mul(95 trx).div(100 trx));
            users[_userID].totalEarned = users[_userID].totalEarned.add(_payout.mul(95 trx).div(100 trx));
            users[1].totalEarned = users[1].totalEarned.add((_payout.mul(5 trx).div(100 trx)));
            dailyPayout[_userID] = dailyPayout[_userID].add(_payout.mul(95 trx).div(100 trx));
            
            users[_userID].referralsTopup[0] = users[_userID].referralsTopup[0].sub(topUpBinaryPayout);
            users[_userID].referralsTopup[1] = users[_userID].referralsTopup[1].sub(topUpBinaryPayout);
            
            emit topUpBinaryEvent( usersList[_userID], _userID, _payout, users[_userID].referralsTopup[0], users[_userID].referralsTopup[1], now);    
        }
    }
    
    function ROIDistribution(uint _userID, uint _amount) internal{ // ROI
        if(_amount <= 0) return;
        
        require(address(uint160(usersList[_userID])).send(_amount.mul(95e18).div(1e20)), "ROI 95% transfer failed");
        require(address(uint160(ownerWallet)).send((_amount.mul(5e18).div(1e20))),"ROI admin commission 5% transfer failed ");
        
        userInvestments[_userID].ROIEarned = userInvestments[_userID].ROIEarned.add(_amount.mul(95e18).div(1e20));
        users[_userID].totalEarned = users[_userID].totalEarned.add(_amount.mul(95e18).div(1e20));
        users[1].totalEarned = users[1].totalEarned.add((_amount.mul(5e18).div(1e20)));
        
        emit ROIEvent( usersList[_userID], _userID, _amount.mul(95e18).div(1e20), now);
    }
    
}