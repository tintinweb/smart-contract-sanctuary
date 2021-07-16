//SourceUnit: TronCity.sol

/**
*
* SmartCity
* https://troncity.io
* (only for troncity.io Community)
* Version 1.0.1
*
**/

pragma solidity ^0.5.9;

contract TronCity {
    using SafeMath for uint;

    uint public lastUserId = 1;
    bool public cashBack_;
    bool public initialized_;

    mapping(uint => mapping(address => uint)) internal pool_users_balance;
    mapping(uint => uint) internal levelPrice;
    uint[] internal poolPrizes;
    uint[] internal revshare_;
    uint internal weeklyPool; // WeeklyPoot
    uint internal nexpool = 1;
    uint internal raisedToday;
    uint internal raisedTotal;
    uint internal distEarning;
    uint internal lostEarnings;
    uint internal matrixIncomes;
    uint internal matchIncomes;
    uint internal joinedToday;
    uint internal lastUpdate = uint(block.timestamp);
    uint internal lastshare = uint(block.timestamp);
    uint internal lastDrawn = uint(block.timestamp);
    uint internal startime = 1600362000;

    uint internal constant dre    = 10;
    uint internal constant refs1  = 5;
    uint internal constant refs2  = 30;
    uint internal constant system = 75; // div 1000
    uint internal constant sharePool_ = 15;
    uint internal constant sharePool2_ = 20;
    uint internal constant poolR = 5; // weekly incentives
    uint internal constant divider = 100;

    address payable internal contract_;
    address payable internal admin_;

    mapping(address => Datastructs.User) public users;

    mapping(uint => address payable) public idToAddress;
    mapping(uint => address payable) public pool_lead; // For Weekly Draw

    mapping(uint => Datastructs.Revshares) internal revpool;

    event NewSignup(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event AutoRenewal(address indexed user, address indexed referrer, uint matrix);
    event NewActivation(address indexed user, address indexed referrer, uint matrix);
    event NewDownline(address indexed user, address indexed referrer, uint level, uint generation, uint count);
    event DSearnings(address indexed _from, address indexed _beneficiary, uint matrixId, uint _amount);
    event Mearning(address indexed _from, address indexed _beneficiary, uint matrixId, uint _level, uint _amount);
    event MiEarnings(address indexed _from, address indexed _beneficiary, uint _level, uint _position, uint _amount);
    event Maearnings(address indexed _from, address indexed _beneficiary, uint _level, uint _position, uint _amount);
    event MiMatching(address indexed _from, address indexed _beneficiary, uint _level, uint _position, uint _amount);
    event WeeklyPoolDrawn(address indexed caller, uint poolBalance, uint poolRewards, uint calledTime);
    event ReveshareDistributed(address indexed caller, uint _matrixId, uint _amountShared, uint calledTime);
    event CBearnings(address indexed _ref, address _sponsor, uint _matrixId, uint _amount, uint calledTime);

    constructor() public {
        contract_ = msg.sender;

        levelPrice[1] = 300000000;

        for (uint i = 2; i <= 12; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }

        poolPrizes.push(5);
        poolPrizes.push(4);
        poolPrizes.push(3);
        poolPrizes.push(2);
        poolPrizes.push(1);
    }

    modifier onlyContract(){
        require(msg.sender == contract_, 'Forbiden!');
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin_, 'Forbiden!');
        _;
    }

    modifier after48(){
        require((now.sub(lastshare).div(1 days)) >= 2 days, 'runs _48h');
        _;
    }

    modifier claimWeekly(uint _matrixId){
        require(now.sub(users[msg.sender].CityMatrix[_matrixId].lastClaimed).div(1 days) >= 7 days, 'Weekly');
        _;
    }

    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, contract_);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function Signup(address payable _sponsor) public payable{
        address payable _userId = msg.sender;
        require(msg.value == levelPrice[1], 'Req 300 trx');
        require(!isUserExists(_userId), 'Already Registered');

        if(!isUserExists(_sponsor) || _sponsor == address(0) || _sponsor == _userId){
            _sponsor = contract_;
        }

        registration(_userId, _sponsor);

        emit NewSignup(_userId, _sponsor, users[_userId].id, users[_sponsor].id);
    }

    function registration(address payable _userId, address payable _sponsor) internal{

        Datastructs.User storage user = users[_userId];

        user.id = lastUserId;

        user.refBy = _sponsor;

        idToAddress[lastUserId] = _userId;

        users[_sponsor].refs.push(_userId);
        users[_sponsor].refsCount++;

        joinedToday++;
        lastUserId++;

        getProperty(_userId, 1);

        updateTeamData(_userId);
    }

    function buyNewProperty(uint _matrixId) public payable {
        require(_matrixId > 0 && _matrixId < 13, 'Bad MatrixId');
        address payable _userId = msg.sender;
        require(isUserExists(_userId), 'Not Registered');
        require(msg.value ==  levelPrice[_matrixId], 'Wrong amount');
        uint32 size;
        assembly {
            size := extcodesize(_userId)
        }
        require(size == 0, "Not Allowed");
        bool canJoin = true;
        if(_matrixId > 1){
            for(uint p = _matrixId - 1; p > 0; p--){
                canJoin = users[_userId].CityMatrix[p].active;
            }
        }
        require(canJoin, 'Cannot Jump');

        require(!users[_userId].activeMember[_matrixId], 'Already Active');

        getProperty(_userId, _matrixId);
    }

    function getProperty(address payable _userId, uint _matrixId) internal {

        uint cost = levelPrice[_matrixId];

        uint _level = _matrixId;
        // pdc
        uint _payDre = cost.mul(dre).div(divider);
        users[users[_userId].refBy].finances[0].dreEarnings += _payDre;
        users[users[_userId].refBy].finances[0].earnings += _payDre;
        if(users[users[_userId].refBy].activeMember[_level]){
            users[users[_userId].refBy].CityMatrix[_level].earnings += _payDre;
        }

        dividentDistribution(users[_userId].refBy, _payDre);
        emit DSearnings(msg.sender, users[_userId].refBy, _matrixId, _payDre);
        // spr
        incentivePool(_userId, _level);
        // irp
        uint _rewardPool = cost.mul(poolR).div(divider);
        weeklyPool = weeklyPool.add(_rewardPool);

        if(users[_userId].CityMatrix[_level].activations >= 1){
            // isp
            uint _poolShare = cost.mul(sharePool2_).div(divider);
            revshare_[_matrixId.sub(1)] += _poolShare;
            // Renewal
            address payable _firstUpline = users[_userId].CityMatrix[_level].refBy;
            address payable _secondUpline = users[_firstUpline].refBy;
            processLevel(_firstUpline, _secondUpline, _level);
            users[_userId].CityMatrix[_level].activations++;

            emit AutoRenewal(_userId, users[_userId].refBy, _matrixId);

        }else{
            // isp
            uint _poolShare = cost.mul(sharePool_).div(divider);
            revshare_[_matrixId.sub(1)] += _poolShare;
            users[_userId].activeMember[_level] = true;
            users[_userId].CityMatrix[_level].active = true;
            users[_userId].CityMatrix[_level].activations++;
            users[_userId].CityMatrix[_level].created_at = uint(block.timestamp);
            // update Upline
            updateMatrixUpliner(_userId, getUpline(_userId, users[_userId].refBy, _level, 1), _matrixId);

            emit NewActivation(_userId, users[_userId].refBy, _matrixId);

            if(now.sub(lastUpdate).div(1 days) >= 1 days){
                joinedToday = 0;
                raisedToday = 0;
                lastUpdate = uint(block.timestamp);
            }

            if(now.sub(lastDrawn).div(1 days) >= 7 days){
                drawPool();
            }

            if(now.sub(lastshare).div(1 days) >= 2 days){
                distributeRevShare(_matrixId);
            }

            Datastructs.Revshares storage _revpool = revpool[_matrixId];

            _revpool.revusers.push(Datastructs.Revusers({
                userId: _userId,
                poolShare: cost.mul(2)
                }));

            raisedTotal += cost;
            raisedToday += cost;

            if(users[users[_userId].refBy].activeMember[_matrixId]){
                users[users[_userId].refBy].CityMatrix[_matrixId].directCount++;
            }

            if(cashBack_ && now <= users[users[_userId].refBy].CityMatrix[_matrixId].created_at + 1 days){
                fastTrackBonus(_matrixId, users[_userId].refBy);
            }

        }
        users[_userId].activations++;
        incomeDistribution(cost, 1);
    }

    function getUpline(address payable _self, address payable _userId, uint _level, uint up) internal returns(address payable){
        if(guDownlines(_userId, _level) < 3){
            if(checkActiveStatus(_userId, _level)){
                return _userId;
            }
            else{
                if(up == 1){
                    // Missed Income
                    // missedEarnings(_userId, _level);
                    // next Availble Upline
                    return getUpline(_self, users[_userId].refBy, _level, 2);
                }
                if(up == 2){
                    return getUpline(_self, contract_, _level, 3);
                }
            }
        }
        else{
            uint v = 0;
            while(v < 3){
                address payable downline = users[_userId].CityMatrix[_level].refs1[v];
                if(guDownlines(downline, _level) < 3){
                    if(checkActiveStatus(downline, _level)){
                        return downline;
                    }
                }
                v++;
            }
            uint d = 0;
            for(uint e = 0; e < users[_userId].refs.length; e++){
                address payable ddownline = users[_userId].refs[e];
                if(ddownline != _self){
                    if(guDownlines(ddownline, _level) < 3){
                        if(checkActiveStatus(ddownline, _level)){
                            return ddownline;
                        }
                    }
                    else{
                        while(d < 3){
                            address payable dddownline = users[ddownline].CityMatrix[_level].refs1[d];
                            if(guDownlines(dddownline, _level) < 3){
                                if(checkActiveStatus(dddownline, _level)){
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

    function highestStage(address _userId) public view returns(uint){
        uint p = 12;
        for(p - 1; p > 0; p--){
            if(users[_userId].CityMatrix[p].active){
                break;
            }
        }
        return p;
    }

    function incentivePool(address _userId, uint _level) internal{
        address payable upline = users[_userId].refBy;
        uint _amount = levelPrice[_level];
        if(upline != address(0)){
            users[upline].finances[0].teamvolume += _amount;
            pool_users_balance[nexpool][upline] += _amount;
            for(uint i = 0; i < 5; i++){
                if(pool_lead[i] == upline){
                    break;
                }
                else if(pool_lead[i] == address(0)){
                    pool_lead[i] = upline;
                    break;
                }
                if(pool_users_balance[nexpool][upline] > pool_users_balance[nexpool][pool_lead[i]]){
                    for(uint p = i + 1; p < 5; p++){
                        if(pool_lead[p] == upline){
                            for(uint k = p; k <= 5; k++){
                                pool_lead[k] = pool_lead[k + 1];
                            }
                            break;
                        }
                    }

                    for(uint p = 4; p > i; p--) {
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

    function updateMatrixUpliner(address payable _userId, address payable _upline, uint _level) internal {
        users[_userId].CityMatrix[_level].refBy = _upline;
        users[_upline].CityMatrix[_level].refs1.push(_userId); // Level 1
        address payable _upline2 = users[_upline].CityMatrix[_level].refBy;
        users[_upline2].CityMatrix[_level].refs2.push(_userId); // Level 2
        processLevel(_upline, _upline2, _level);
        emit NewDownline(_userId, _upline, _level, 1, uint(users[_upline].CityMatrix[_level].refs1.length));
        emit NewDownline(_userId, _upline2, _level, 2, uint(users[_upline2].CityMatrix[_level].refs2.length));
    }

    function processLevel(address payable _firstUpline, address payable _secondUpline, uint _level) internal{
        matrixIncome(_firstUpline, levelPrice[_level], _level, 1); // MI1
        if(users[_firstUpline].refBy != address(0)){
            matchIncome(users[_firstUpline].refBy, levelPrice[_level], _level, 1); // MB1
            matrixIncome(_secondUpline, levelPrice[_level], _level, 2); // MI2
            matchIncome(users[_secondUpline].refBy, levelPrice[_level], _level, 2); // MB2
        }
    }

    function matrixIncome(address payable _userId, uint _amount, uint _level, uint _position) internal{
        uint refsc;
        if(_position == 1){
            refsc = refs1;
        }else{
            refsc = refs2;
        }

        uint payLevel = _amount.mul(refsc).div(divider);
        users[_userId].finances[0].matrixEarnings += payLevel;
        users[_userId].CityMatrix[_level].earnings += payLevel;
        users[_userId].finances[0].earnings += payLevel;

        matrixIncomes += payLevel;
        address payable beneficiray;
        if(users[_userId].id > 5){
            beneficiray = checkBeneficiary(_userId, _level, 1, payLevel);
        }
        else{
            beneficiray = _userId;
        }
        dividentDistribution(beneficiray, payLevel);
        // Emit Earnings Received
        emit Mearning(msg.sender, beneficiray, _level, _position, payLevel);

        if(_position != 1 && users[_userId].CityMatrix[_level].refs2.length >= 9){
            // check Auto Renewal
            getProperty(_userId, _level);
        }
    }

    function matchIncome(address payable _userId, uint _amount, uint _level, uint _position) internal{
        uint refsb;
        if(_position == 1){
            refsb = refs1.div(2);
        }else{
            refsb = refs2.div(2);
        }

        uint payMb = _amount.mul(refsb).div(divider);
        users[_userId].finances[0].matchingBonus += payMb;
        users[_userId].CityMatrix[_level].earnings += payMb;
        users[_userId].finances[0].earnings += payMb;
        matchIncomes += payMb;
        address payable _beneficiary = checkBeneficiary(_userId, _level, 2, payMb);
        dividentDistribution(_beneficiary, payMb);
        // Emit Matching bonus Received
        emit Maearnings(msg.sender, _beneficiary, _level, _position, payMb);
    }

    function dividentDistribution(address payable _userId, uint _amount) internal returns(bool){
        if(users[_userId].id == 1){
            incomeDistribution(_amount, 2);
        }
        else{
            _userId.transfer(_amount);
        }
        distEarning += _amount;

        return true;
    }

    function incomeDistribution(uint _amount, uint _type) internal returns(bool){
        uint pay;
        if(_type == 1){
            pay = _amount.mul(system).div(1000).div(4);
        }
        else{
            pay = _amount.div(4);
        }
        for(uint m = 2; m <= 5; m++){
            address payable _admin = idToAddress[m];
            _admin.transfer(pay);

        }
        return true;
    }

    function checkBeneficiary(address payable _userId, uint _level, uint _type, uint _amount) internal returns(address payable _beneficiary){
        if(checkActiveStatus(_userId, _level)){
            _beneficiary = _userId;
        }
        else{
            if(_type == 1){
                emit MiEarnings(msg.sender, _userId, _level, _type, _amount);
                users[_userId].finances[0].missedEarnings += _amount;
            }else{
                emit MiMatching(msg.sender, _userId, _level, _type, _amount);
                users[_userId].finances[0].missedBonus += _amount;
            }
            lostEarnings += _amount;
            _beneficiary = idToAddress[1];
        }
    }

    function checkActiveStatus(address _userId, uint _level) internal returns(bool){
        if(!users[_userId].activeMember[_level]){
            users[_userId].activeMember[_level] = false;
            users[_userId].CityMatrix[_level].active = false;
            return false;
        }

        return true;
    }

    function runRevShare(uint _matrixId) public  after48(){
        distributeRevShare(_matrixId);
    }

    function distributeRevShare(uint _matrixId) internal{
        uint _shares = revshare_[_matrixId.sub(1)];
        require(revpool[_matrixId].revusers.length >= 1 && _shares > 0);
        uint _share = _shares.div(revpool[_matrixId].revusers.length);
        for(uint p = 0; p < revpool[_matrixId].revusers.length; p++){
            Datastructs.User storage user = users[revpool[_matrixId].revusers[p].userId];
            if(revpool[_matrixId].revusers[p].poolShare > 0
            && levelPrice[_matrixId].mul(user.CityMatrix[_matrixId].activations).mul(2)
                > user.CityMatrix[_matrixId].earnings){
                revshare_[_matrixId.sub(1)] -= _share;
                user.CityMatrix[_matrixId].revFunds += _share;
                revpool[_matrixId].revusers[p].poolShare -= _share;
            }
            else{
                delete revpool[_matrixId].revusers[p];
            }
        }
        emit ReveshareDistributed(msg.sender, _matrixId,  _shares, block.timestamp);
    }

    function claimeShare(uint _matrixId) public claimWeekly(_matrixId){
        Datastructs.User storage user = users[msg.sender];
        if(user.CityMatrix[_matrixId].earnings < user.CityMatrix[_matrixId].activations.mul(2).mul(levelPrice[_matrixId])){
            uint _amount = user.CityMatrix[_matrixId].revFunds;
            uint _total = _amount.add(user.CityMatrix[_matrixId].earnings);
            if(_total > user.CityMatrix[_matrixId].activations.mul(2).mul(levelPrice[_matrixId])){
                _amount = user.CityMatrix[_matrixId].activations.mul(2).mul(levelPrice[_matrixId]).sub(user.CityMatrix[_matrixId].earnings);
            }
            distEarning += _amount;
            user.CityMatrix[_matrixId].revFunds = 0;
            user.CityMatrix[_matrixId].earnings += _amount;
            user.finances[0].earnings += _amount;
            user.finances[0].revshares += _amount;
            msg.sender.transfer(_amount);
        }
        else{
            user.CityMatrix[_matrixId].revFunds = 0;
        }
        user.CityMatrix[_matrixId].lastClaimed = uint(block.timestamp);
    }

    function fastTrackBonus(uint _matrixId, address payable _userId) internal{
        require(cashBack_, 'Cashback Off');
        if((users[_userId].CityMatrix[_matrixId].directCount >= 10)
            && (users[_userId].CityMatrix[_matrixId].cashbackCount < users[_userId].CityMatrix[_matrixId].directCount.div(10))
        )
        {
            if(users[_userId].CityMatrix[_matrixId].directCount % 10 == 0){
                uint _amount = levelPrice[_matrixId].div(2);
                distEarning += _amount;
                users[_userId].CityMatrix[_matrixId].cashbackCount++;
                users[_userId].CityMatrix[_matrixId].earnings += _amount;
                _userId.transfer(_amount);
                emit CBearnings(msg.sender, _userId, _matrixId, _amount, now);
            }
            else if(users[_userId].CityMatrix[_matrixId].cashbackCount < 1){
                uint _amount = levelPrice[_matrixId].div(2);
                distEarning += _amount;
                users[_userId].CityMatrix[_matrixId].cashbackCount++;
                users[_userId].CityMatrix[_matrixId].earnings += _amount;
                _userId.transfer(_amount);
                emit CBearnings(msg.sender, _userId, _matrixId,  _amount,  now);
            }
        }
    }

    function drawPool() internal {
        lastDrawn = uint(block.timestamp);
        nexpool++;
        for(uint i = 0; i < 5; i++){
            uint _amount = weeklyPool.mul(poolPrizes[i]).div(divider);
            if(pool_lead[i] != address(0)){
                pool_lead[i].transfer(_amount);
                users[pool_lead[i]].finances[0].pool_bonus += _amount;
            }
        }

        lastDrawn -= weeklyPool.mul(15).div(divider);

        for(uint8 i = 0; i < 5; i++) {
            pool_lead[i] = this.idToAddress(i+1);
        }
    }

    function matrixInitialisation(address payable _ui1,
        address payable _ui2, address payable _ui3,
        address payable _ui4) public onlyContract() returns(bool){
        require(initialized_ == false, 'Not Allowed');

        Datastructs.User storage user1 = users[contract_];

        user1.id = lastUserId;

        idToAddress[lastUserId] = contract_;

        for (uint i = 1; i <= 12; i++) {
            users[contract_].activeMember[i] = true;
            users[contract_].CityMatrix[i].active = true;
            users[contract_].CityMatrix[i].activations = uint(12).mul(1e6);
            revshare_.push(0);
        }

        lastUserId++;
        joinedToday++;

        admin_ = _ui1;

        users[contract_].refs.push(_ui1);

        users[contract_].refs.push(_ui2);

        users[contract_].refs.push(_ui3);

        users[_ui1].refs.push(_ui4);

        for(uint i = 0; i < users[contract_].refs.length; i++){
            address payable _userId = users[contract_].refs[i];
            Datastructs.User storage user = users[_userId];

            user.id = lastUserId;
            user.refBy = contract_;
            idToAddress[lastUserId] = _userId;

            for (uint b = 1; b <= 12; b++) {
                user.CityMatrix[b].refBy = contract_;
                users[contract_].CityMatrix[b].refs1.push(_userId);
                user.activeMember[b] = true;
                user.CityMatrix[b].active = true;
                user.CityMatrix[b].activations = 1e9;

                Datastructs.Revshares storage _revpool = revpool[b];

                _revpool.revusers.push(Datastructs.Revusers({
                    userId: _userId,
                    poolShare: levelPrice[b].mul(1e9)
                    }));
                user.activations++;
            }

            users[contract_].refsCount++;

            lastUserId++;
            joinedToday++;

            updateTeamData(_userId);
        }

        Datastructs.User storage user4 = users[_ui4];

        user4.id = lastUserId;
        user4.refBy = _ui1;
        idToAddress[lastUserId] = _ui4;

        for (uint d = 1; d <= 12; d++) {
            user4.activeMember[d] = true;
            user4.CityMatrix[d].active = true;
            user4.CityMatrix[d].activations = uint(12).mul(1e6);
            user4.CityMatrix[d].refBy = _ui1;
            users[_ui1].CityMatrix[d].refs1.push(_ui4);
            users[contract_].CityMatrix[d].refs2.push(_ui4);

            Datastructs.Revshares storage _revpool = revpool[d];

            _revpool.revusers.push(Datastructs.Revusers({
                userId: _ui4,
                poolShare: levelPrice[d].mul(1e9)
                }));
            user4.activations++;
        }

        lastUserId++;
        joinedToday++;

        updateTeamData(_ui4);

        initialized_ = true;

        return true;
    }

    function aDrawPool() public {
        require(block.timestamp >= lastDrawn + 7 days, 'Weekly Only!');
        drawPool();
    }

    function toggleCashback() public onlyAdmin() returns(bool){
        cashBack_ = !cashBack_ ? true:false;
        return cashBack_;
    }

    function isUserExists(address _userAddress) internal view returns (bool) {
        return (users[_userAddress].id != 0);
    }

    function guDownlines(address _userId, uint _level) internal view returns(uint){
        return users[_userId].CityMatrix[_level].refs1.length;
    }

    function usersMatrix(address _userId, uint _level) public view
    returns(address payable _refBy,  address payable[] memory _refs1,
        address payable[] memory _refs2,  uint _directCount,
        uint _refShare, uint _activations, uint _earnings) {
        _refBy = users[_userId].CityMatrix[_level].refBy;
        _refs1 = users[_userId].CityMatrix[_level].refs1;
        _refs2 = users[_userId].CityMatrix[_level].refs2;
        _directCount = users[_userId].CityMatrix[_level].directCount;
        _refShare = users[_userId].CityMatrix[_level].revFunds;
        _activations = users[_userId].CityMatrix[_level].activations;
        _earnings = users[_userId].CityMatrix[_level].earnings;
        return (_refBy, _refs1, _refs2, _directCount, _refShare, _activations, _earnings);
    }

    function userInfo(address _userId) public view returns(uint _refs, uint _earnings,  uint _dre,
        uint _mxe, uint _highestStage, uint aC, uint _teamVolume, uint _misedEarnings){

        uint p = 12;
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

        return(_refs,  _earnings, _dre, _mxe, _highestStage,  aC,  _teamVolume, _misedEarnings);

    }

    function _getBonuses(address _userId) public view returns(uint _matching, uint _revshare, uint _pool_bonus, uint _cashBack){

        Datastructs.User storage user = users[_userId];

        _revshare = user.finances[0].revshares;
        _cashBack = user.finances[0].cashback;
        _pool_bonus = user.finances[0].pool_bonus;
        _matching = user.finances[0].matchingBonus;

        return(_matching, _revshare, _pool_bonus, _cashBack);
    }

    function _Referrals(address _userId) public view returns(address payable[] memory){
        return users[_userId].refs;
    }

    function stats() public view returns(uint lId, uint rT, uint rTl, uint dE, uint lE, uint mI, uint mCI, uint jT, uint pB, uint cB, uint start){
        return (lastUserId, raisedToday, raisedTotal, distEarning, lostEarnings, matrixIncomes, matchIncomes, joinedToday, weeklyPool, address(this).balance,
        startime);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token) external; }

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }


    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }


    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }


    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * Also in memory of JPK, miss you Dad.
    */
}

library Datastructs{

    struct Matrix {
        address payable refBy;
        address payable [] refs1;
        address payable [] refs2;
        uint earnings;
        uint revFunds;
        uint lastClaimed;
        uint directCount;
        uint cashbackCount;
        bool active;
        uint activations;
        uint created_at;
    }

    struct User {
        uint id;
        address payable refBy;
        address payable [] refs;
        uint refsCount;
        uint teamCount;
        uint activations;
        Finances[1] finances;
        mapping(uint => bool) activeMember;
        mapping(uint => Matrix) CityMatrix;
    }

    struct Finances{
        uint earnings;
        uint pool_bonus; // Earned from Weekly Draw
        uint revshares;
        uint cashback;
        uint dreEarnings;
        uint matrixEarnings;
        uint matchingBonus;
        uint missedEarnings;
        uint missedBonus;
        uint teamvolume; // Resets Weekly
    }

    struct Revusers{
        address payable userId;
        uint poolShare;
    }

    struct Revshares{
        Revusers[] revusers;
    }
}