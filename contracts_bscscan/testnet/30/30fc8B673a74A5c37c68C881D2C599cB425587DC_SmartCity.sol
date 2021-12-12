/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

/**
* SmartCity
* https://smartcity.io
* (only for smartcity.io Community)
* Version 1.0.2
* SPDX-License-Identifier: Unlicensed
**/

pragma solidity 0.8.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    /**
    * Also in memory of JPK, miss you Dad.
    */
}

library Datastructs{

    struct Matrix {
        uint refBy;
        uint [] refs1;
        uint [] refs2;
        uint256 earnings;
        uint256 revFunds;
        uint256 lastClaimed;
        uint256 directCount;
        uint256 cashbackCount;
        bool active;
        uint256 activations;
        uint256 created_at;
    }

    struct User {
        uint256 id;
        uint256 sharedId;
        address payable refBy;
        address payable [] refs;
        uint256 refsCount;
        uint256 teamCount;
        uint256 activations;
        bool sharedAcc;
        Finances[1] finances;
        Pioneers[1] pioneers;
        mapping(uint256 => Matrix) CityMatrix;
        mapping(uint256 => bool) activeMember;
    }

    struct Finances{
        uint256 earnings;
        uint256 pool_bonus; // Earned from Weekly Draw
        uint256 revshares;
        uint256 cashback;
        uint256 dreEarnings;
        uint256 matrixEarnings;
        uint256 matchingBonus;
        uint256 missedEarnings;
        uint256 missedBonus;
        uint256 teamvolume; // Resets Weekly
        uint256 fund;
    }

    struct Revusers{
        address payable userId;
        uint256 poolShare;
    }

    struct Revshares{
        Revusers[] revusers;
    }

    struct Pioneers{
        bool isPioneer;
        bool isShared;
        address payable owner;
        address[] members;
        uint256 earnings;
        uint256 tEarnings;
    }

    struct FundApproval{
        uint256 usersCount;
        uint256 votes;
        uint256 opened_at;
        bool open;
    }
}

contract SmartCity {
    using SafeMath for uint256;

    uint256 public lastUserId = 1;
    bool public cashBack_;
    bool public initialized_;

    mapping(uint256 => mapping(address => uint256)) internal pool_users_balance;
    mapping(uint256 => uint256) internal levelPrice;

    // uint256 internal levelPrice = 0.05 ether;
    uint256[] internal poolPrizes;
    uint256[] internal revshare_;
    uint256 internal weeklyPool; // WeeklyPool [Gets Points to claim as tokens]
    uint256 internal nexpool = 1;
    uint256 internal raisedToday;
    uint256 internal raisedTotal;
    uint256 internal distEarning;
    uint256 internal lostEarnings;
    uint256 internal matrixIncomes;
    uint256 internal matchIncomes;
    uint256 internal joinedToday;
    uint256 internal lastUpdate = uint256(block.timestamp);
    uint256[] internal lastshare;
    uint256 internal lastDrawn = uint256(block.timestamp);
    uint256 internal startime = 1600362000;

    uint256 internal constant dre    = 10; // Direct Referral Bonus
    uint256 internal constant refs  = 40; // Level 2 (3x2 matrix) earnings
    uint256 internal constant matchb  = 20; // Matching Bonus 
    uint256 internal constant system = 6; // Maintenance Fees
    uint256 internal constant poolShare = 12; // User's 200% ROI cap/activation
    uint256 internal constant reserved = 9; // for AutoRenewal
    uint256 internal constant divider = 100;
    uint256 internal constant poolR = 10; // Only for Points

    address payable internal contract_;
    address payable internal admin_;

    uint256 public pioneerValue = 0.001 ether;

    mapping(address => Datastructs.User) public users;

    mapping(uint256 => address payable) public idToAddress;
    mapping(uint256 => address payable) public pool_lead; // For Weekly Draw

    mapping(uint256 => address payable) public pioneersHolders;

    mapping(uint256 => Datastructs.Revshares) internal revpool;

    mapping(address => uint256) public paidShared;

    bool public openPioneer = true;

    event NewSignup(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId);
    event AutoRenewal(address indexed user, address indexed referrer, uint256 matrix);
    event NewActivation(address indexed user, address indexed referrer, uint256 matrix);
    event NewDownline(address indexed user, address indexed referrer, uint256 level, uint256 generation, uint256 count);
    event DSearnings(address indexed _from, address indexed _beneficiary, uint256 matrixId, uint256 _amount);
    event Mearning(address indexed _from, address indexed _beneficiary, uint256 matrixId, uint256 _level, uint256 _amount);
    event Maearnings(address indexed _from, address indexed _beneficiary, uint256 _level, uint256 _amount);
    event WeeklyPoolDrawn(address indexed caller, uint256 poolBalance, uint256 poolRewards, uint256 calledTime);
    event ReveshareDistributed(address indexed caller, uint256 _matrixId, uint256 _amountShared, uint256 calledTime);
    event CBearnings(address indexed _ref, address _sponsor, uint256 _matrixId, uint256 _amount, uint256 calledTime);

    constructor() {
        contract_ = payable(msg.sender);
        levelPrice[1] = 0.05 ether;
        for (uint256 i = 2; i <= 12; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
            lastshare.push(uint256(block.timestamp));
        }

        Datastructs.User storage user1 = users[contract_];

        user1.id = lastUserId;

        idToAddress[lastUserId] = contract_;

        for (uint256 i = 1; i <= 12; i++) {
            users[contract_].activeMember[i] = true;
            users[contract_].CityMatrix[i].active = true;
            users[contract_].CityMatrix[i].activations = uint256(12).mul(1e6);
            revshare_.push(0);
            if(i < 5){
                pool_lead[i-1] = contract_;
            }
        }

        poolPrizes.push(5);
        poolPrizes.push(4);
        poolPrizes.push(3);
        poolPrizes.push(2);
        poolPrizes.push(1);

        pioneersHolders[1]= payable(0xD09C4566AC2331F5b5e4524dC81E6E3AE72f079E);
        pioneersHolders[2]= payable(0x73fC096c83eBC466aC7881827F0b92E974ad974d);
        pioneersHolders[3]= payable(0x077B0A2B96802584863d208b5A67c7Fed20e90fA);
        pioneersHolders[4]= payable(0x5B5762CC687f708476a594dA723a1a2D014913b3);
        pioneersHolders[5]= payable(0x067F3dFc87B7D010a36C2f198b0B359C80d01F21);
        pioneersHolders[6]= payable(0x244B125639f10e64f535cCD1dD2509d25556474c);
        pioneersHolders[7]= payable(0xe57344514230454aEc487df0df1Ee5607b43b28f);
        pioneersHolders[8]= payable(0x034dd9e5b92598A08734f2B47de78c4D35388cc7);

        lastUserId++;
        joinedToday++;
    }

    modifier onlyContract(){
        require(msg.sender == contract_, 'Forbiden!');
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin_, 'Forbiden!');
        _;
    }

    modifier onlyPioneer(){
        require(users[payable(msg.sender)].sharedAcc, 'Forbidend');
        _;
    }

    function Signup(address payable _sponsor) public payable{
        address payable _userId = payable(msg.sender);
        require(msg.value == levelPrice[1], 'Req 0.05 BNB');
        require(!isUserExists(_userId), 'Already Registered');

        if(!isUserExists(_sponsor) || _sponsor == address(0) || _sponsor == _userId){
            _sponsor = contract_;
        }

        registration(_userId, _sponsor, false);

        emit NewSignup(_userId, _sponsor, users[_userId].id, users[_sponsor].id);
    }

    function registration(address payable _userId, address payable _sponsor, bool _isPioneer) internal{

        Datastructs.User storage user = users[_userId];

        user.id = lastUserId;

        user.refBy = _sponsor;

        idToAddress[lastUserId] = _userId;

        users[_sponsor].refs.push(_userId);
        users[_sponsor].refsCount++;

        if(!_isPioneer){
            getProperty(_userId, 1);
            updateTeamData(_userId);
        }

        joinedToday++;
        lastUserId++;
    }

    function buyNewProperty(uint256 _matrixId) public payable {
        require(_matrixId > 0 && _matrixId < 13, 'Bad MatrixId');
        address payable _userId = payable(msg.sender);
        require(isUserExists(_userId), 'Not Registered');
        require(msg.value ==  levelPrice[_matrixId], 'Wrong amount');
        uint32 size;
        assembly {
            size := extcodesize(_userId)
        }
        require(size == 0, "Not Allowed");

        uint256 p = 12;
        for(p - 1; p > 0; p--){
            if(users[_userId].CityMatrix[p].active){
                break;
            }
        }

        require(p.add(1) == _matrixId, 'Cannot Jump');

        require(!users[_userId].CityMatrix[_matrixId].active, 'Already Active');

        getProperty(_userId, _matrixId);
    }

    function getProperty(address payable _userId, uint256 _matrixId) internal {

        uint256 cost = levelPrice[_matrixId];

        uint256 _level = _matrixId;
        // pdc
        uint256 _payDre = cost.mul(dre).div(divider);

        users[users[_userId].refBy].finances[0].dreEarnings += _payDre;
        users[users[_userId].refBy].finances[0].earnings += _payDre;
        // if(users[users[_userId].refBy].activeMember[_level]){
        users[users[_userId].refBy].CityMatrix[_level].earnings += _payDre;
        // }

        emit DSearnings(msg.sender, users[_userId].refBy, _matrixId, _payDre);

        dividentDistribution(users[_userId].refBy, _payDre);
        // spr
        incentivePool(_userId, _level);
        // irp
        uint256 _rewardPool = cost.mul(poolR).mul(divider);
        weeklyPool = weeklyPool.add(_rewardPool);
        // 200% guaranteed ROI
        uint256 _poolShare = cost.mul(poolShare).div(divider);
        revshare_[_matrixId.sub(1)] += _poolShare;

        if(users[_userId].CityMatrix[_level].activations >= 1){
            // Renewal
            uint _firstUpline = users[_userId].CityMatrix[_level].refBy;
            uint _secondUpline = users[users[idToAddress[_firstUpline]].refBy].id;
            processLevel(idToAddress[_secondUpline], _level);
            users[_userId].CityMatrix[_level].activations++;

            emit AutoRenewal(_userId, users[_userId].refBy, _matrixId);

        }else{
            users[_userId].activeMember[_level] = true;
            users[_userId].CityMatrix[_level].active = true;
            users[_userId].CityMatrix[_level].activations++;
            users[_userId].CityMatrix[_level].created_at = uint256(block.timestamp);
            // update Upline
            updateMatrixUpliner(_userId, getUpline(_userId, users[_userId].refBy, _level, 1), _matrixId);

            emit NewActivation(_userId, users[_userId].refBy, _matrixId);

            if(block.timestamp >= lastUpdate.add(1 days)){
                joinedToday = 0;
                raisedToday = 0;
                lastUpdate = uint256(block.timestamp);
            }

            if(block.timestamp >= lastDrawn.add(7 days)){
                drawPool();
            }

            if(block.timestamp >= lastshare[_matrixId.sub(1)].add(2 minutes)){
                distributeRevShare(_matrixId);
            }

            Datastructs.Revshares storage _revpool = revpool[_matrixId];

            _revpool.revusers.push(Datastructs.Revusers({
                userId: _userId,
                poolShare: cost.mul(2)
            }));

            if(users[users[_userId].refBy].activeMember[_matrixId]){
                users[users[_userId].refBy].CityMatrix[_matrixId].directCount++;
            }

            if(cashBack_ && block.timestamp <= users[users[_userId].refBy].CityMatrix[_matrixId].created_at + 1 days){
                fastTrackBonus(_matrixId, users[_userId].refBy);
            }
        }
        
        incomeDistribution(cost, 1);
        
        users[_userId].activations++;
        raisedTotal += cost;
        raisedToday += cost;
    }

    function getUpline(address payable _self, address payable _userId, uint256 _level, uint256 up) internal returns(uint _downline){
        if(users[_userId].sharedAcc){
            _userId = idToAddress[users[_userId].sharedId];
        }
        if(guDownlines(_userId, _level) < 3){
            if(checkActiveStatus(_userId, _level)){
                return users[_userId].id;
            }
            else{
                if(up == 1){
                    // next Availble Upline
                    return getUpline(_self, users[_userId].refBy, _level, 2);
                }
                if(up == 2){
                    return getUpline(_self, contract_, _level, 3);
                }
            }
        }
        else{
            uint256 v = 0;
            while(v < 3){
                uint downline = users[_userId].CityMatrix[_level].refs1[v];
                if(guDownlines(idToAddress[downline], _level) < 3){
                    if(checkActiveStatus(idToAddress[downline], _level)){
                        return downline;
                    }
                }
                v++;
            }
            uint256 d = 0;
            for(uint256 e = 0; e < users[_userId].refs.length; e++){
                uint ddownline = users[users[_userId].refs[e]].id;
                if(ddownline != users[_self].id){
                    if(guDownlines(idToAddress[ddownline], _level) < 3){
                        if(checkActiveStatus(idToAddress[ddownline], _level)){
                            return ddownline;
                        }
                    }
                    else{
                        while(d < 3){
                            uint dddownline = users[idToAddress[ddownline]].CityMatrix[_level].refs1[d];
                            if(guDownlines(idToAddress[dddownline], _level) < 3){
                                if(checkActiveStatus(idToAddress[dddownline], _level)){
                                    return dddownline;
                                }
                            }
                            d++;
                        }
                    }
                }
            }
        }
    }

    function incentivePool(address _userId, uint256 _level) internal{
        address payable upline = users[_userId].refBy;
        uint256 _amount = levelPrice[_level];
        if(upline != address(0)){
            users[upline].finances[0].teamvolume += _amount;
            pool_users_balance[nexpool][upline] += _amount;
            for(uint256 i = 0; i < 5; i++){
                if(pool_lead[i] == upline){
                    break;
                }
                else if(pool_lead[i] == address(0)){
                    pool_lead[i] = upline;
                    break;
                }
                if(pool_users_balance[nexpool][upline] > pool_users_balance[nexpool][pool_lead[i]]){
                    for(uint256 p = i + 1; p < 5; p++){
                        if(pool_lead[p] == upline){
                            for(uint256 k = p; k <= 5; k++){
                                pool_lead[k] = pool_lead[k + 1];
                            }
                            break;
                        }
                    }

                    for(uint256 p = 4; p > i; p--) {
                        pool_lead[p] = pool_lead[p - 1];
                    }

                    pool_lead[i] = upline;

                    break;
                }
            }
        }
    }

    function updateTeamData(address _userId) internal {
        while(users[_userId].refBy != address(0)){
            users[users[_userId].refBy].teamCount++;
            _userId = users[_userId].refBy;
        }
    }

    function updateMatrixUpliner(address payable _userId, uint _upline, uint256 _level) internal {
        users[_userId].CityMatrix[_level].refBy = _upline;
        users[idToAddress[_upline]].CityMatrix[_level].refs1.push(users[_userId].id); // Level 1
        uint _upline2 = users[idToAddress[_upline]].CityMatrix[_level].refBy;
        users[idToAddress[_upline2]].CityMatrix[_level].refs2.push(users[_userId].id); // Level 2
        processLevel(idToAddress[_upline2], _level);
        emit NewDownline(_userId, idToAddress[_upline], _level, 1, uint256(users[idToAddress[_upline]].CityMatrix[_level].refs1.length));
        emit NewDownline(_userId, idToAddress[_upline2], _level, 2, uint256(users[idToAddress[_upline2]].CityMatrix[_level].refs2.length));
    }

    function processLevel(address payable _upline, uint256 _level) internal{
        // matrixIncome(_firstUpline, levelPrice ** _level, _level, 1); // MI1
        // if(users[_firstUpline].refBy != address(0)){
            // matchIncome(users[_firstUpline].refBy, levelPrice ** _level, _level, 1); // MB1
            matrixIncome(_upline, levelPrice[_level], _level); // MI2
            matchIncome(users[_upline].refBy, levelPrice[_level], _level); // MB2
        // }
    }

    function matrixIncome(address payable _userId, uint256 _amount, uint256 _level) internal{
        
        uint256 payLevel = _amount.mul(refs).div(divider);
        users[_userId].finances[0].matrixEarnings += payLevel;
        users[_userId].CityMatrix[_level].earnings += payLevel;
        users[_userId].finances[0].earnings += payLevel;

        matrixIncomes += payLevel;
        address payable beneficiray;
        if(users[_userId].id > 13){
            beneficiray = checkBeneficiary(_userId, _level, 1, payLevel);
        }
        else{
            beneficiray = _userId;
        }
        
        dividentDistribution(beneficiray, payLevel);
        // Emit Earnings Received
        emit Mearning(msg.sender, beneficiray, _level, 2, payLevel);

        if(users[_userId].CityMatrix[_level].refs2.length >= 9){
            // check Auto Renewal
            getProperty(_userId, _level);
        }
    }

    function matchIncome(address payable _userId, uint256 _amount, uint256 _level) internal{
        uint256 payMb = _amount.mul(matchb).div(divider);
        users[_userId].finances[0].matchingBonus += payMb;
        users[_userId].CityMatrix[_level].earnings += payMb;
        users[_userId].finances[0].earnings += payMb;
        matchIncomes += payMb;
        address payable _beneficiary = checkBeneficiary(_userId, _level, 2, payMb);
        dividentDistribution(_beneficiary, payMb);
        // Emit Matching bonus Received
        emit Maearnings(msg.sender, _beneficiary, _level, payMb);
    }

    function dividentDistribution(address payable _userId, uint256 _amount) internal returns(bool){
        if(users[_userId].id == 1 || users[_userId].id == 0 || _userId == address(0)){
            incomeDistribution(_amount, 2);
        }
        else{
            // if user is pioneed full || shared
            if(users[_userId].pioneers[0].isPioneer){
                if(users[_userId].pioneers[0].isShared){
                    // creadit balance
                    users[_userId].pioneers[0].earnings += _amount;
                    users[_userId].pioneers[0].tEarnings += _amount;
                    for(uint mb = 0; mb < users[_userId].pioneers[0].members.length; mb++){
                        users[users[_userId].pioneers[0].members[mb]].finances[0].fund += _amount.div(10);
                    }
                }else{
                    payable(users[_userId].pioneers[0].owner).transfer(_amount);
                }
            }
            else{
                _userId.transfer(_amount);
            }
        }

        distEarning += _amount;

        return true;
    }

    function incomeDistribution(uint256 _amount, uint256 _type) internal returns(bool){
        uint256 pay;
        uint256 pay_0;
        if(_type == 1){
            pay_0 = _amount.mul(15).div(1000);
            pay = _amount.mul(system).div(100).div(6);
        }
        else{
            pay = _amount.div(2);
        }
        for(uint256 m = 2; m <= 5; m++){
            address payable _admin = idToAddress[m];
            if(_type == 1){
                if(m < 4){
                    users[_admin].finances[0].fund += pay.mul(2).add(pay_0);
                }else{
                    users[_admin].finances[0].fund += pay;
                }
            }
            else{
                if(m < 4){
                    users[_admin].finances[0].fund += pay;
                }
            }
        }
        return true;
    }

    function checkBeneficiary(address payable _userId, uint256 _level, uint256 _type, uint256 _amount) internal returns(address payable _beneficiary){
        if(checkActiveStatus(_userId, _level) || users[_userId].sharedAcc){
            _beneficiary = _userId;
        }
        else{
            if(_type == 1){
                users[_userId].finances[0].missedEarnings += _amount;
            }else{
                users[_userId].finances[0].missedBonus += _amount;
            }
            lostEarnings += _amount;
            _beneficiary = idToAddress[1];
        }
    }

    // Buy Pioneer Position
    function buyPioneer(address payable _sponsor) public payable{
        require(msg.value >= pioneerValue && msg.value.mod(pioneerValue) == 0, 'IncorrectAmount');
        require(!isUserExists(payable(msg.sender)), 'Already Registered');
        require(openPioneer, 'OfferClosed');
        registration(payable(msg.sender), _sponsor, true);
        users[payable(msg.sender)].sharedAcc = true;
        bool _shared = true;
        if(msg.value > pioneerValue){
            require(msg.value == pioneerValue.mul(10), 'WrongMultiple');
            _shared = false;
        }
        address _user = msg.sender;
        uint _available = checkAvailable(_shared);
        require(_available >= 6 && _available <= 13, 'NotAvailable');
        // if shared
        if(_shared){
            users[idToAddress[_available]].pioneers[0].members.push(_user);
        }
        else{// else
            users[idToAddress[_available]].pioneers[0].owner = payable(msg.sender);
            users[idToAddress[_available]].pioneers[0].isShared = false;
            // users[idToAddress[_available]].pioneers[0].members.push(_user);
        }

        users[payable(msg.sender)].sharedId = _available;
        // Pay Affiliate 

        uint256 _payDre = msg.value.mul(dre).div(divider);

        users[users[payable(msg.sender)].refBy].finances[0].dreEarnings += _payDre;
        users[users[payable(msg.sender)].refBy].finances[0].earnings += _payDre;

        emit DSearnings(msg.sender, users[payable(msg.sender)].refBy, 0, _payDre);

        dividentDistribution(users[payable(msg.sender)].refBy, _payDre);
        // Validate if anyOpen Space is left
        uint _openShare = checkAvailable(true);
        uint _openFull = checkAvailable(false);

        if(_openShare == 0  && _openFull == 0){
            openPioneer = false;
        }
    }

    function checkAvailable(bool _shared) private view returns(uint _available){
        // FirstAvailable Pioneer Slot
        for(uint pn = 6; pn <= 13; pn++){
            address _slot = idToAddress[pn];
            if(_shared && users[_slot].pioneers[0].members.length < 2 && users[_slot].pioneers[0].isShared == true){
                return pn;
            }
            else if(!_shared && users[_slot].pioneers[0].members.length == 0 && users[_slot].pioneers[0].owner == payable(0)){
                return pn;
            }
        }
        return 0;
    }

    function highestStage(address _userId) public view returns(uint256){
        uint256 p = 12;
        for(p - 1; p > 0; p--){
            if(users[_userId].CityMatrix[p].active){
                break;
            }
        }
        return p;
    }

    function checkActiveStatus(address _userId, uint256 _level) internal view returns(bool){
        return users[_userId].CityMatrix[_level].active;
    }

    function runRevShare(uint256 _matrixId) public {
        require(block.timestamp >= lastshare[_matrixId.sub(1)].add(2 minutes), 'rund_after_48hrs');
        distributeRevShare(_matrixId);
    }

    function distributeRevShare(uint256 _matrixId) internal{
        lastshare[_matrixId.sub(1)] = block.timestamp;
        uint256 _shares = revshare_[_matrixId.sub(1)];
        require(revpool[_matrixId].revusers.length >= 1 && _shares > 0);
        uint256 _share = _shares.div(revpool[_matrixId].revusers.length);
        for(uint256 p = 0; p < revpool[_matrixId].revusers.length; p++){
            Datastructs.User storage user = users[revpool[_matrixId].revusers[p].userId];
            if(revpool[_matrixId].revusers[p].poolShare > 0
                && levelPrice[_matrixId].mul(user.CityMatrix[_matrixId].activations).mul(2)
                    > user.CityMatrix[_matrixId].earnings){
                    revshare_[_matrixId.sub(1)] -= _share;
                    revpool[_matrixId].revusers[p].poolShare -= _share;

                if(user.pioneers[0].isPioneer){
                    // creadit balance
                    user.pioneers[0].earnings += _share;
                    user.pioneers[0].tEarnings += _share;
                    if(user.pioneers[0].isShared){
                        for(uint mb = 0; mb < user.pioneers[0].members.length; mb++){
                            users[user.pioneers[0].members[mb]].finances[0].fund += _share.div(10);
                        }
                    }
                    else{
                        users[user.pioneers[0].owner].finances[0].fund += _share;
                    }
                }else{
                    user.CityMatrix[_matrixId].revFunds += _share;
                }
            }
            else{
                delete revpool[_matrixId].revusers[p];
            }
        }
        emit ReveshareDistributed(msg.sender, _matrixId,  _shares, block.timestamp);
    }

    function claimeShare(uint256 _matrixId) public {
        address payable _userId = payable(msg.sender);
        Datastructs.User storage user = users[_userId];
        uint256 _amount;
        if(user.CityMatrix[_matrixId].earnings < user.CityMatrix[_matrixId].activations.mul(2).mul(levelPrice[_matrixId])){
            _amount = user.CityMatrix[_matrixId].revFunds;
            uint256 _total = _amount.add(user.CityMatrix[_matrixId].earnings);
            if(_total > user.CityMatrix[_matrixId].activations.mul(2).mul(levelPrice[_matrixId])){
                _amount = user.CityMatrix[_matrixId].activations.mul(2).mul(levelPrice[_matrixId]).sub(user.CityMatrix[_matrixId].earnings);
            }
            distEarning += _amount;
            user.CityMatrix[_matrixId].revFunds = 0;
            user.CityMatrix[_matrixId].earnings += _amount;
            user.finances[0].earnings += _amount;
            user.finances[0].revshares += _amount;
        }
        else{
            user.CityMatrix[_matrixId].revFunds = 0;
        }
        if(user.finances[0].fund > 0){
            _amount = _amount.add(user.finances[0].fund);
        }
        if(_amount > 0){
            _userId.transfer(_amount);
            // _userId.transfer(user.finances[0].fund);
            user.finances[0].fund = 0;
        }
        user.CityMatrix[_matrixId].lastClaimed = uint256(block.timestamp);
    }

    function pioneerIncome() public onlyPioneer{
        Datastructs.User storage user = users[payable(msg.sender)];
        uint _amount = user.finances[0].fund;
        require(_amount > 0, 'No funds');
        user.finances[0].fund = 0;
        payable(msg.sender).transfer(_amount);
    }

    function fastTrackBonus(uint256 _matrixId, address payable _userId) internal{
        require(cashBack_, 'Cashback Off');
        if((users[_userId].CityMatrix[_matrixId].directCount >= 10)
            && (users[_userId].CityMatrix[_matrixId].cashbackCount < users[_userId].CityMatrix[_matrixId].directCount.div(10))
        )
        {
            if(users[_userId].CityMatrix[_matrixId].directCount % 10 == 0){
                uint256 _amount = levelPrice[_matrixId].div(2);
                distEarning += _amount;
                users[_userId].CityMatrix[_matrixId].cashbackCount++;
                users[_userId].CityMatrix[_matrixId].earnings += _amount;
                _userId.transfer(_amount);
                emit CBearnings(msg.sender, _userId, _matrixId, _amount, block.timestamp);
            }
            else if(users[_userId].CityMatrix[_matrixId].cashbackCount < 1){
                uint256 _amount = levelPrice[_matrixId].div(2);
                distEarning += _amount;
                users[_userId].CityMatrix[_matrixId].cashbackCount++;
                users[_userId].CityMatrix[_matrixId].earnings += _amount;
                _userId.transfer(_amount);
                emit CBearnings(msg.sender, _userId, _matrixId,  _amount,  block.timestamp);
            }
        }
    }

    function drawPool() internal {
        lastDrawn = uint256(block.timestamp);
        nexpool++;
        uint256 _poolAmount = 0;
        for(uint256 i = 0; i < 5; i++){
            uint256 _amount = weeklyPool.mul(poolPrizes[i]).div(divider);
            if(pool_lead[i] != address(0)){
                // Credit Pool Bonus Here. 
                users[pool_lead[i]].finances[0].pool_bonus += _amount;
                _poolAmount += _amount;
                // pool_lead[i].transfer(_amount);
                // dividentDistribution(pool_lead[i], _amount);
            }
        }

        weeklyPool -= weeklyPool.mul(15).div(divider);

        for(uint256 i = 0; i < 5; i++) {

            pool_lead[i] = contract_;

        }

        emit WeeklyPoolDrawn(msg.sender, weeklyPool, _poolAmount, block.timestamp);
    }

    function matrixInitialisation(address payable _userId) public onlyContract() returns(bool){

        require(initialized_ == false, 'Not Allowed');
        
        if(lastUserId == 2){
            admin_ = _userId;
        }

        uint count = 1;
        
        address payable _sponsor;
        
        if(lastUserId == 5){
            _sponsor = idToAddress[2];
        }
        else{
            _sponsor = contract_;
        }
        
        Datastructs.User storage _seed = users[_sponsor];
        _seed.refs.push(_userId);
        
        if(lastUserId > 5){
            count = 8;
        }

        for(uint ce = 1; ce <= count; ce++){
            if(lastUserId > 5){
                _userId = pioneersHolders[lastUserId.sub(5)];
            }
        
            Datastructs.User storage user = users[_userId];
            user.id = lastUserId;
            idToAddress[lastUserId] = _userId;
            user.refBy = _sponsor;
            if(count == 8){
                user.pioneers[0].isPioneer = true;
                user.pioneers[0].isShared = true;
            }

            for (uint256 b = 1; b < 13; b++) {
                user.CityMatrix[b].refBy = users[_sponsor].id;

                if(lastUserId < 5){
                    users[_sponsor].CityMatrix[b].refs1.push(users[_userId].id);
                }
                else if(lastUserId >= 5 && lastUserId < 8){
                    users[idToAddress[2]].CityMatrix[b].refs1.push(users[_userId].id);
                    users[idToAddress[1]].CityMatrix[b].refs2.push(users[_userId].id);
                }
                else if(lastUserId >= 8 && lastUserId < 11){
                    users[idToAddress[3]].CityMatrix[b].refs1.push(users[_userId].id);
                    users[idToAddress[1]].CityMatrix[b].refs2.push(users[_userId].id);
                }
                else if(lastUserId >= 11 && lastUserId < 14){
                    users[idToAddress[4]].CityMatrix[b].refs1.push(users[_userId].id);
                    users[idToAddress[1]].CityMatrix[b].refs2.push(users[_userId].id);
                }
                user.activeMember[b] = true;
                user.CityMatrix[b].active = true;
                user.CityMatrix[b].activations = 1e6;
                uint256 matrPrice = levelPrice[b];
                Datastructs.Revshares storage _revpool = revpool[b];

                _revpool.revusers.push(Datastructs.Revusers({
                    userId: _userId,
                    poolShare: matrPrice.mul(1e6)
                }));
                user.activations++;
            }

            users[_sponsor].refsCount++;

            lastUserId++;
            joinedToday++;

            if(lastUserId == 14){
                initialized_ = true;
            }
        }

        updateTeamData(_userId);

        return initialized_;
    }

    function aDrawPool() public {
        require(block.timestamp >= lastDrawn.add(7 days), 'Weekly Only!');
        drawPool();
    }

    function toggleCashback() public onlyAdmin() returns(bool){
        cashBack_ = !cashBack_ ? true:false;
        return cashBack_;
    }

    function setPioneerValue(uint256 _value) public onlyAdmin returns(bool){
        pioneerValue = _value.mul(1e18); // Unit
        return true;
    }

    function refShareTop(uint256 _matrixId) public payable returns(bool){
        require(msg.value > 0, 'Wrong amount');
        revshare_[_matrixId.sub(1)] += msg.value;
        return true;
    }

    function isUserExists(address _userAddress) internal view returns (bool) {
        return (users[_userAddress].id != 0);
    }

    function guDownlines(address _userId, uint256 _level) internal view returns(uint256){
        return users[_userId].CityMatrix[_level].refs1.length;
    }

    function usersMatrix(address _userId, uint256 _level) public view
        returns(address payable _refBy,  uint[] memory _refs1,
        uint[] memory _refs2,  uint256 _directCount,
        uint256 _refShare, uint256 _activations, uint256 _earnings) {
        _refBy = idToAddress[users[_userId].CityMatrix[_level].refBy];
        _refs1 = users[_userId].CityMatrix[_level].refs1;
        _refs2 = users[_userId].CityMatrix[_level].refs2;
        _directCount = users[_userId].CityMatrix[_level].directCount;
        _refShare = users[_userId].CityMatrix[_level].revFunds;
        _activations = users[_userId].CityMatrix[_level].activations;
        _earnings = users[_userId].CityMatrix[_level].earnings;
        return (_refBy, _refs1, _refs2, _directCount, _refShare, _activations, _earnings);
    }

    function getPioneers(uint _userId) public view returns(bool _isPioneer, bool _isShared, address _owner, address[] memory _members, uint256 _earnings, uint256 _tEarnings){
        _isPioneer = users[idToAddress[_userId]].pioneers[0].isPioneer;
        _isShared = users[idToAddress[_userId]].pioneers[0].isShared;
        _earnings = users[idToAddress[_userId]].pioneers[0].earnings;
        _tEarnings = users[idToAddress[_userId]].pioneers[0].tEarnings;
        _members = users[idToAddress[_userId]].pioneers[0].members;
        _owner = users[idToAddress[_userId]].pioneers[0].owner;
    }

    function userInfo(address _userId) public view returns(uint256 _refs, uint256 _earnings,  uint256 _dre,
        uint256 _mxe, uint256 _highestStage, uint256 aC, uint256 _teamVolume, uint256 _misedEarnings){

        uint256 p = 12;
        for(p - 1; p > 0; p--){
            if(users[_userId].CityMatrix[p].active){
                break;
            }
        }

        Datastructs.User storage user = users[_userId];

        _refs = user.refsCount;
        _earnings = user.finances[0].earnings;
        _dre = user.finances[0].dreEarnings;
        _mxe = user.finances[0].matrixEarnings;
        _highestStage = p;
        aC = user.activations;
        _teamVolume = user.finances[0].teamvolume;
        _misedEarnings = user.finances[0].missedEarnings.add(user.finances[0].missedBonus);

        return(_refs, _earnings, _dre, _mxe, _highestStage, aC, _teamVolume, _misedEarnings);
    }

    function _getBonuses(address _userId) public view returns(uint256 _matching, uint256 _revshare, uint256 _pool_bonus, uint256 _cashBack){

        Datastructs.User storage user = users[_userId];

        _revshare = user.finances[0].revshares;
        _cashBack = user.finances[0].cashback;
        _pool_bonus = user.finances[0].pool_bonus;
        _matching = user.finances[0].matchingBonus;

        return(_matching, _revshare, _pool_bonus, _cashBack);
    }

    function _Referrals(address _userId) public view returns(address payable[] memory){
        return(users[_userId].refs);
    }

    function stats() public view returns(uint256 lId, uint256 rT, uint256 rTl, uint256 dE, uint256 lE, uint256 mI, uint256 mCI, uint256 jT, uint256 pB, uint256 cB, uint256 start){
        return (lastUserId, raisedToday, raisedTotal, distEarning, lostEarnings, matrixIncomes, matchIncomes, joinedToday, weeklyPool, address(this).balance,
        startime);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    receive() external payable {}
}