/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity 0.5.16;

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

contract FUNDSZ{
    
    using SafeMath for uint;
    
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint orginalRefID;
        uint placementSponser;
        uint donated;
        uint totalEarnedETH;
        uint teamNetworkEarnETH;
        bool blocked;
        address[] personallyEnrolled;
        address[] referrals;
        uint membershipExpired;
    }
    
    address payable public admin;
    
    uint  REFERRER_1_LEVEL_LIMIT = 4;
    uint public PERIOD_LENGTH = 30 days;
    uint public blockTime = 90 days;
    uint public GRACE_PERIOD = 7 days;
    
    uint MatchingBonusUplineLimit = 5;
    
    uint public usdPrice;
    
    uint public currUserID = 0;
    bool public lockStatus;
    
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint => uint) public MEMBERSHIP_PRICE;
    
    mapping(address => uint) matrixCommissionBreakage;
    mapping(address => uint) commissionsReceivedValue;
    mapping(address => uint) adminBreakageAmount;
    
    event MatrixCommission(
        address indexed _user,
        address _level1,
        address _level2,
        address _level3,
        address _level4,
        address _level5,
        address _level6,
        address _level7,
        address _level8,
        uint _levelValue
    );
    event MatchingCarBonus(
        address indexed _user,
        address _sponser,
        address[] receiver,
        uint _value
    );
    event RefBonus(
        address indexed _user,
        address _sponser,
        uint _value
    );
    event InfinityHouseBonus(
        address _user,
        address _upline9,
        address _upline10,
        address _upline11,
        address _upline12,
        uint _uplineAmount9To12
    );
    event regMemberEvent(
        address indexed _user,
        address indexed _referrer,
        uint _value,
        uint _vipID,
        uint _time
    );
    event BuyMembershipEvent(
        address indexed _user,
        uint _value,
        uint _vipID,
        uint _time
    );
    
    event BreakageEvent(
        address indexed _user,
        uint _value,
        uint _time
    );
    
    constructor() public {
        admin = msg.sender;
        UserStruct memory userStruct;
        currUserID++;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            orginalRefID: 0,
            placementSponser: 0,
            donated:2,
            teamNetworkEarnETH:0,
            totalEarnedETH: 0,
            blocked:false,
            personallyEnrolled : new address[](0),
            referrals: new address[](0),
            membershipExpired:55555555555
        });
        
        users[admin] = userStruct;    
        userList[currUserID] = admin;
    
        MEMBERSHIP_PRICE[1] = 10;
        MEMBERSHIP_PRICE[2] = 50;
    }
    
    modifier contractStatus(){
        require(lockStatus == false,"contract locked");
        _;
    }
    
    modifier OnlyOwner(){
        require(msg.sender == admin,"OnlyOwner");
        _;
    }
    
    function() external payable OnlyOwner{
        
    }
    
    
    function subscription(uint _placementSponser, uint _referrerID, uint _orginalRefID, uint _usdValue) public contractStatus payable returns(bool){
        require(!users[msg.sender].isExist,"User exist");
        require(!isContract(msg.sender),"Invalid address");
        require((_referrerID > 0) && (_referrerID <= currUserID),"Invalid referrerID");
        require((_orginalRefID > 0) && (_orginalRefID <= currUserID),"Invalid referrerID");
        require((_placementSponser > 0) && (_placementSponser <= currUserID),"Invalid referrerID");
        require(_usdValue == 10 || (_usdValue == 50),"Invalid membership");
        require(usdPrice > 0, "usdPrice must be greater than zero");
        require(msg.value == usdPrice.mul(_usdValue),"Invalid value");
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            orginalRefID : _orginalRefID,
            placementSponser : _placementSponser,
            donated:0,
            teamNetworkEarnETH:0,
            // referralTeamNetWorkEarnings : 0,
            totalEarnedETH: 0,
            blocked:false,
            personallyEnrolled : new address[](0),
            referrals: new address[](0),
            membershipExpired: now.add(PERIOD_LENGTH)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;
        
        uint _DonateID;
        
        if(MEMBERSHIP_PRICE[1] == _usdValue)
            _DonateID = 1;
        else
            _DonateID = 2;

        users[msg.sender].donated = _DonateID;
        users[userList[_placementSponser]].personallyEnrolled.push(msg.sender);
        users[userList[_referrerID]].referrals.push(msg.sender);

        address upline_8_address = matrixCommission(msg.sender,msg.value);
        
        referralBonus(msg.sender,msg.value);
        matchingCarBonus(msg.sender);
        infinityHouseBonus(upline_8_address,msg.value); 
        
        uint breakage = msg.value.sub(commissionsReceivedValue[msg.sender]);
        
        require(address(uint160(admin)).send(breakage), "breakage amount transfer failed");
        users[admin].totalEarnedETH = users[admin].totalEarnedETH.add(breakage);

        emit regMemberEvent(msg.sender, userList[_referrerID], msg.value, _DonateID, now);
        emit BreakageEvent(msg.sender, adminBreakageAmount[msg.sender].add(breakage), now);
        
        return true;
    }
    
    function donate(uint _usdValue, uint _days)  public contractStatus payable returns(bool){
        require(_days > 0,"_days must be greater than zero");
        require(users[msg.sender].isExist,"User does not exist"); 
        require(!isContract(msg.sender),"Invalid address");
        require((_usdValue == 10 || _usdValue == 50), "Invalid membership");
        require(usdPrice > 0, "usdPrice must be greater than zero");
        require(msg.value == (usdPrice.mul(_usdValue)).mul(_days),"Invalid value");
        
        uint _DonateID;
        
        if(MEMBERSHIP_PRICE[1] == _usdValue)
            _DonateID = 1;
        else
            _DonateID = 2;
        
        if(users[msg.sender].donated == _DonateID)    
            users[msg.sender].membershipExpired = users[msg.sender].membershipExpired.add(PERIOD_LENGTH.mul(_days));
        else{
            users[msg.sender].membershipExpired = now.add(PERIOD_LENGTH.mul(_days));
            users[msg.sender].donated = _DonateID;
        }
        
        
        address upline_8_address = matrixCommission(msg.sender,msg.value);
        
        matchingCarBonus(msg.sender);
        referralBonus(msg.sender,msg.value);
        infinityHouseBonus(upline_8_address,msg.value);   
        
        uint breakage = msg.value.sub(commissionsReceivedValue[msg.sender]);
        
        require(address(uint160(admin)).send(breakage), "breakage amount transfer failed");
        users[admin].totalEarnedETH = users[admin].totalEarnedETH.add(breakage);
        
        emit BuyMembershipEvent(msg.sender, msg.value, _DonateID, now);
        emit BreakageEvent(msg.sender, adminBreakageAmount[msg.sender].add(breakage), now);
        
        return true;
    }
    
    function updateUSDPrice( uint _usdPrice) public OnlyOwner returns(bool){
        require(_usdPrice > 0, "_usdPrice must be greater than zero");
        usdPrice = _usdPrice;
        return true;
    }
    
    mapping( address => address[]) bonusEligibleUsers;
    
    // Matrix Commission
    function matrixCommission(address _user, uint _amount) internal returns(address){
        matrixCommissionBreakage[msg.sender] = 0;
        commissionsReceivedValue[msg.sender] = 0;
        adminBreakageAmount[msg.sender] = 0;
        bonusEligibleUsers[msg.sender] = new address[](0);
        
        address[8] memory   matrix_commission;
        matrix_commission[0] = rollUp(userList[users[_user].referrerID]);
        matrix_commission[1] = rollUp(userList[users[matrix_commission[0]].referrerID]);
        matrix_commission[2] = rollUp(userList[users[matrix_commission[1]].referrerID]);
        matrix_commission[3] = rollUp(userList[users[matrix_commission[2]].referrerID]);
        matrix_commission[4] = rollUp(userList[users[matrix_commission[3]].referrerID]);
        matrix_commission[5] = rollUp(userList[users[matrix_commission[4]].referrerID]);
        matrix_commission[6] = rollUp(userList[users[matrix_commission[5]].referrerID]);
        matrix_commission[7] = rollUp(userList[users[matrix_commission[6]].referrerID]);
        
        for(uint i = 0; i < matrix_commission.length; i++){
            if(matrix_commission[i] == address(0)){
                matrix_commission[i] = userList[1];
            }
        }

        uint matrix_commission_upline_percentage = (_amount.mul(8 ether).div(10**20));
        
        for(uint i=0; i<matrix_commission.length; i++){
            if(matrix_commission[i] == userList[1]){
                uint commission = matrix_commission_upline_percentage.mul(matrix_commission.length.sub(i));
                require(address(uint160(matrix_commission[i])).send(commission),"transfer failed");
                users[matrix_commission[i]].totalEarnedETH = users[matrix_commission[i]].totalEarnedETH.add(commission);
                users[matrix_commission[i]].teamNetworkEarnETH = users[matrix_commission[i]].teamNetworkEarnETH.add(commission);
                commissionsReceivedValue[msg.sender] = commissionsReceivedValue[msg.sender].add(commission);
                break;
            }
            else{
                require(address(uint160(matrix_commission[i])).send(matrix_commission_upline_percentage),"transfer failed");
                users[matrix_commission[i]].totalEarnedETH = users[matrix_commission[i]].totalEarnedETH.add(matrix_commission_upline_percentage);
                users[matrix_commission[i]].teamNetworkEarnETH = users[matrix_commission[i]].teamNetworkEarnETH.add(matrix_commission_upline_percentage);
                commissionsReceivedValue[msg.sender] = commissionsReceivedValue[msg.sender].add(matrix_commission_upline_percentage);
            }
        }
        
        adminBreakageAmount[msg.sender] = adminBreakageAmount[msg.sender].add(matrix_commission_upline_percentage.mul(matrixCommissionBreakage[msg.sender]));
        
        emit MatrixCommission(
            _user,
            bonusEligibleUsers[msg.sender][0],
            bonusEligibleUsers[msg.sender][1],
            bonusEligibleUsers[msg.sender][2],
            bonusEligibleUsers[msg.sender][3],
            bonusEligibleUsers[msg.sender][4],
            bonusEligibleUsers[msg.sender][5],
            bonusEligibleUsers[msg.sender][6],
            bonusEligibleUsers[msg.sender][7],
            matrix_commission_upline_percentage
        );
        
        return matrix_commission[7];
    }
    
    // roll up - matrix commission
    function rollUp(address _user) internal returns(address) {
        
        if(!users[_user].isExist) {
            matrixCommissionBreakage[msg.sender]++;
            bonusEligibleUsers[msg.sender].push(_user);
            return userList[1];
        }
        

        if((users[_user].membershipExpired.add(GRACE_PERIOD) >= now) && (!users[_user].blocked)){
            bonusEligibleUsers[msg.sender].push(_user);
            return _user;
        }
        else if(
            ((users[_user].membershipExpired).add(blockTime.add(GRACE_PERIOD)) < now) 
            && (!users[_user].blocked))
        {
            users[_user].blocked = true;
        }        
        
        return rollUp(userList[users[_user].referrerID]);
    }
    
    mapping(address => address[]) public _teamNetworkEarnWallet;
    
    // Matching Commission
    function matchingCarBonus(address _user) internal {
        address sponser = userList[users[_user].referrerID];
        
        uint _carBonus;
        
        if(sponser == address(0)) sponser = userList[1];
        
        _teamNetworkEarnWallet[sponser] = new address[](0);
        
        if(((users[sponser].membershipExpired).add(blockTime.add(GRACE_PERIOD)) < now) && (!users[sponser].blocked)){
            users[sponser].blocked = true;
        }
        
        if(sponser != userList[1])
            getAllDirectSponsor( sponser, userList[users[sponser].referrerID], 0);

        if((_teamNetworkEarnWallet[sponser].length > 0) && (users[sponser].teamNetworkEarnETH > 0)){
            _carBonus = (users[sponser].teamNetworkEarnETH.mul(25 ether).div(100 ether)).div(MatchingBonusUplineLimit);
            
            if(_carBonus > 0){
                for(uint j=0; j<_teamNetworkEarnWallet[sponser].length;j++){
                    require(address(uint160(_teamNetworkEarnWallet[sponser][j])).send(_carBonus),"transfer car bonus failed");
                    users[_teamNetworkEarnWallet[sponser][j]].totalEarnedETH = users[_teamNetworkEarnWallet[sponser][j]].totalEarnedETH.add(_carBonus);
                    commissionsReceivedValue[msg.sender] = commissionsReceivedValue[msg.sender].add(_carBonus);
                }
                
                if(_teamNetworkEarnWallet[sponser].length != MatchingBonusUplineLimit){
                    uint breakage = MatchingBonusUplineLimit.sub(_teamNetworkEarnWallet[sponser].length);
                    if(breakage > 0){
                        require(address(uint160(admin)).send(_carBonus.mul(breakage)),"transfer car bonus failed");
                        users[admin].totalEarnedETH = users[admin].totalEarnedETH.add(_carBonus.mul(breakage));
                        adminBreakageAmount[msg.sender] = adminBreakageAmount[msg.sender].add(_carBonus.mul(breakage));
                        commissionsReceivedValue[msg.sender] = commissionsReceivedValue[msg.sender].add(_carBonus.mul(breakage));
                    }
                }    
                    
                
                emit MatchingCarBonus(
                    _user,
                    sponser,
                    _teamNetworkEarnWallet[sponser],
                    _carBonus
                );
            }
        }
    }
    
    // get all qualified direct sponsers.
    function getAllDirectSponsor(address _sponser, address _directSponser, uint _limit) internal returns(bool){
        
        uint referralCount = rollUpD50Enrolled( _directSponser, 0, users[_directSponser].referrals.length-1); 
                    
        if(referralCount >= 1)
          _teamNetworkEarnWallet[_sponser].push(_directSponser);
        
        if(_directSponser == userList[1])
            return true;
        
        _limit++;
        
        if(_limit == MatchingBonusUplineLimit)
            return true;
        
        return getAllDirectSponsor( _sponser, userList[users[_directSponser].referrerID], _limit);
    }
    
    // roll up $50 - Matching bonus 
    function rollUpD50Enrolled(address _user, uint _referralCount, uint _referralIndex) internal  returns(uint){
        
        if(((users[users[_user].referrals[_referralIndex]].membershipExpired).add(GRACE_PERIOD) >= now) && (users[users[_user].referrals[_referralIndex]].donated == 2)){
            _referralCount++;
        }
        
        if(_referralIndex == 0)
            return _referralCount;
            
        _referralIndex--;
        
        return rollUpD50Enrolled( _user, _referralCount, _referralIndex);
    }
    

    // Referral Commission    
    function referralBonus(address _user, uint _value) internal{
        address sponser = userList[users[_user].placementSponser]; 
        uint _refBonus = ((_value).mul(12 ether).div(10**20));
        
        if(sponser == address(0)) sponser = userList[1];
        
        if(((users[sponser].membershipExpired).add(blockTime.add(GRACE_PERIOD)) < now)  && (!users[sponser].blocked))
            users[sponser].blocked = true;              
        
        if(users[sponser].blocked){
            sponser = admin;
        }  
        
        require(address(uint160(sponser)).send(_refBonus),"transfer failed");
        users[sponser].totalEarnedETH = users[sponser].totalEarnedETH.add(_refBonus);
        commissionsReceivedValue[msg.sender] = commissionsReceivedValue[msg.sender].add(_refBonus);
        
        if(sponser != userList[users[_user].placementSponser])
            adminBreakageAmount[msg.sender] = adminBreakageAmount[msg.sender].add(_refBonus);
        else{
            emit RefBonus(
                _user,
                sponser,
                _refBonus
            );
        }
    }

    mapping(address => address[]) _addressList;

    // Infinity Commission    
    function infinityHouseBonus(address _user, uint _amount) internal {
        address[4] memory   house_bonus;
        _addressList[msg.sender] = new address[](0);
        bonusEligibleUsers[msg.sender] = new address[](0);
        
        _addressList[msg.sender].push(userList[1]);
        
        house_bonus[0] = matchingHouseBonusRollUp(userList[users[_user].referrerID],usdPrice.mul(500000), _addressList[msg.sender]); // 2%
        _addressList[msg.sender].push(house_bonus[0]);
        
        house_bonus[1] = matchingHouseBonusRollUp(userList[users[_user].referrerID],usdPrice.mul(200000), _addressList[msg.sender]); // 2%
        if((house_bonus[1] == userList[1]))
            house_bonus[1] = house_bonus[0];
            
        _addressList[msg.sender].push(house_bonus[1]);    
        
        house_bonus[2] = matchingHouseBonusRollUp(userList[users[_user].referrerID],usdPrice.mul(100000), _addressList[msg.sender]); // 2%
        if((house_bonus[2] == userList[1]))
            house_bonus[2] = house_bonus[1];
        
        _addressList[msg.sender].push(house_bonus[2]);    
        
        house_bonus[3] = matchingHouseBonusRollUp(userList[users[_user].referrerID], usdPrice.mul(20000), _addressList[msg.sender]); // 2%
        
        if((house_bonus[3] == userList[1]))
            house_bonus[3] = house_bonus[2];
        
        uint houseUpline_9_12 = (_amount.mul(2 ether).div(10**20));
        
        for(uint i=0; i<house_bonus.length;i++){
            require(address(uint160(house_bonus[i])).send(houseUpline_9_12),"transfer failed");
            users[house_bonus[i]].totalEarnedETH = users[house_bonus[i]].totalEarnedETH.add(houseUpline_9_12);
            commissionsReceivedValue[msg.sender] = commissionsReceivedValue[msg.sender].add(houseUpline_9_12);
        }
        
        emit InfinityHouseBonus(
            msg.sender,
            bonusEligibleUsers[msg.sender][0],
            bonusEligibleUsers[msg.sender][1],
            bonusEligibleUsers[msg.sender][2],
            bonusEligibleUsers[msg.sender][3],
            houseUpline_9_12
        );
    }
    
    // roll up - House bonus
    function matchingHouseBonusRollUp(address _user,uint _usdETHValue, address[] memory __previousAddress) internal  returns(address) {
        
        for(uint i=0;i<__previousAddress.length;i++){
            if((_user == __previousAddress[i]) && (_user != userList[1]))
                matchingHouseBonusRollUp(userList[users[_user].referrerID],_usdETHValue, __previousAddress);
        }
        
        if(!users[_user].isExist) {
            bonusEligibleUsers[msg.sender].push(_user);
            return userList[1];
        }
        
         if(((users[_user].membershipExpired).add(GRACE_PERIOD) >= now) && (users[_user].donated == 2) && (!users[_user].blocked))
        {
            uint referralCount;
            if(users[_user].referrals.length > 0)
                referralCount = rollUpD50FL( _user, 0, users[_user].referrals.length-1);
            
            
            if(referralCount >= 4){
                if(users[_user].totalEarnedETH >= _usdETHValue){
                    bonusEligibleUsers[msg.sender].push(_user);
                    return _user;
                }
            } 
        } 
        
        return matchingHouseBonusRollUp(userList[users[_user].referrerID],_usdETHValue, __previousAddress);
    }

    // roll up $50 - House bonus    
    function rollUpD50FL(address _user, uint _referralCount, uint _referralIndex) internal  returns(uint){
        
        if(((users[users[_user].referrals[_referralIndex]].membershipExpired).add(GRACE_PERIOD) >= now)  && (users[users[_user].referrals[_referralIndex]].donated == 2)){
            _referralCount++;
        }
        
        if(_referralIndex == 0)
            return _referralCount;
            
        _referralIndex--;
        
        return rollUpD50FL( _user, _referralCount, _referralIndex);
    }
    
    function updateGracePeriod(uint _gracePeriod) public OnlyOwner returns(bool) {
        GRACE_PERIOD = _gracePeriod;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) public OnlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
 
    function contractLock(bool _lockStatus) public OnlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function updateBlockTime(uint _newBlockTime) public OnlyOwner returns(bool) {
        blockTime = _newBlockTime;
        return true;
    }
    
    function updateMatchingBonusUplineLimit(uint _MatchingBonusUplineLimit) public OnlyOwner returns(bool) {
        require(_MatchingBonusUplineLimit > 0, "MatchingBonusUplineLimit must be greater than zero");
        MatchingBonusUplineLimit = _MatchingBonusUplineLimit;
        return true;
    }
    
    function updateAdminWallet( address payable _newAdminWallet) public OnlyOwner returns(bool){
        require(_newAdminWallet != address(0), "_newAdminWallet must not be zero wallet");
        
        UserStruct memory userStruct;
        userStruct = UserStruct({
            isExist: true,
            id: 1,
            referrerID: 0,
            orginalRefID: 0,
            placementSponser: 0,
            donated: users[admin].donated,
            teamNetworkEarnETH: users[admin].teamNetworkEarnETH,
            totalEarnedETH: users[admin].totalEarnedETH,
            blocked: users[admin].blocked,
            personallyEnrolled : users[admin].personallyEnrolled,
            referrals: users[admin].referrals,
            membershipExpired:users[admin].membershipExpired
        });
        
        UserStruct memory userStruct_;
        
        users[admin] = userStruct_;
        
        admin = _newAdminWallet;
        
        users[admin] = userStruct;    
        userList[1] = admin;
        
        return true;
    }
    
    function isContract(address account) public view returns (bool) {
        uint32 size;
        assembly {
                size := extcodesize(account)
            }
        if(size != 0)
            return true;
            
        return false;
    }
    
    function viewMembershipExpired(address _user) public view returns(uint) {
        return users[_user].membershipExpired;
    }
    
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].personallyEnrolled;
    } 
    
    function viewUserDirectReferral(address _user) public view returns(address[] memory) {
        return users[_user].referrals;
    } 
    
}