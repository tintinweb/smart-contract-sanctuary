//SourceUnit: trxcodelive.sol

/**
* https://trxcode.io [Best 2021 TRX Fund Raising Program]
* SPDX-License-Identifier:  MIT License
*/
pragma solidity 0.5.14;

contract TRXcode {

    using SafeMath for uint;

    struct Players{
        uint id;
        address payable refBy;
        uint weeklyrefs_count;
        uint weeklyrefs_lastUpdate;
        bool weeklyrefs_qualified;
        Finance[1] finance;
        Packdata[6] packstat;
        mapping(uint => address payable[]) referrals;
        Summary[1] summary;
    }

    struct Finance{
        uint balance; // Total Avaiable
        uint withdrawn; // Total Payouts
        uint vipShares; // Total VIP shares
    }

    struct Activations{
        Entries[] entries;
    }

    struct Summary{
        uint spent; // Total TRX spent [Direct Input]
        uint earnings; // Total TRX earned + commissions
        uint commissions; // Total commissions Earned
        uint vipShares; // Total Earned from Golbal ProfitSharing Pool
        uint sponsorPool; // Total Earned from Sponsor's Pool Reward
        uint cycles; // Total Cycle Counts [on All packs]
        uint activations; // Total Activations [regardless of plan]
        uint refs; // Total Referrals
        uint team; // Total Team size
    }

    struct Packdata{
        uint activations;
        uint totalcycle;
        uint earnings;
    }

    struct Entries{
        uint amount;
        uint earnings;
        uint dailyPayCounts; // 5 daily [and Unlimited for planId 4 and 5]
        uint totalCycles; // 1000 to 4000 [and Unlimited for planId 4 and 5]
        uint lastUpdate; // Last Update time [Every 24hrs]
        bool active;
    }

    struct myEntries{
        uint amount;
        uint earnings;
        uint dailyPayCounts;
        uint totalCycles;
    }

    struct poolEntries{
        uint planId;
        uint entryId;
        address userId;
    }

    struct Plans{
        uint cost;
        uint dailyCycle;
        uint maxCycle;
        uint activations; // Count Total Activations
        uint poolSize; // Count Total Entries
    }

    struct VIPusers{
        address[] vips; // VIP users
        uint shares; // Total Shares
    }

    address payable public admin; //
    address payable public team1; //
    address payable public team2; //
    address payable internal contract_;

    uint internal purgeBalance = 0; // 5% of Entries
    uint internal vipPool = 0; // 5%, 30% every 48hrs
    uint internal LeadershipPool = 0; // 4%, 30% weekly

    uint internal vipPoolPaid = 0;
    uint internal LeadershipPoolPaid = 0;

    uint internal gobalEarnings = 0;
    uint internal gobalPayouts = 0;

    uint internal gobalBalance = 0;

    uint internal lastUid = 1;

    uint internal joinedToday = 0;

    uint internal lastJoined = block.timestamp;

    uint internal currentWeek = 1;

    uint internal lasWeek = block.timestamp;

    uint internal lastVIPshared = block.timestamp;

    bool internal systemInit = false;

    uint[] public unilevel;

    mapping(uint => mapping(address => Activations)) internal activations;

    mapping(address => Players) public players;

    VIPusers internal vipUsers;

    poolEntries[] public nonstopPool;

    mapping(address => mapping(uint => myEntries[])) public paths;

    mapping(uint => address) public getPlayerbyId;

    Plans[] internal packs;

    mapping(uint => address payable[]) public qualified; // For Weekly Leadership Pool

    // uint openMillionaires = 1610924400; // Sunday, January 17, 2021 11:00:00 PM (GMT)

    modifier onlyContract(){
        require(msg.sender == contract_);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() public{

        contract_ = msg.sender;

        packs.push(Plans(500 trx, 5, 1000, 0, 0)); // Value in trx
        packs.push(Plans(2500 trx, 5, 2000, 0, 0));
        packs.push(Plans(5000 trx, 20, 264e64, 0, 0));

        unilevel.push(5);
        unilevel.push(1);

        Players storage _player = players[contract_];
        _player.id = lastUid;
        getPlayerbyId[lastUid] = contract_;

        qualified[currentWeek].push(contract_);

        lastUid++;

        joinedToday++;
    }

    // ############################### //
    //       Private Functions         //
    // ############################### //

    // Register user
    function _Register(address payable _userId, address payable _affAddr) private{

        address payable _refBy = _affAddr;

        if(_refBy == _userId || _refBy == address(0) || players[_refBy].id == 0){
            _refBy = contract_;
        }

        Players storage _player = players[_userId];

        _player.refBy = _refBy;

        players[_refBy].summary[0].refs++;
        players[_refBy].referrals[0].push(_userId);
        players[_refBy].summary[0].team++;

        updateWeeklyReferrals(_refBy);

        _player.id = lastUid;
        getPlayerbyId[lastUid] = _userId;

        lastUid++;

        if(block.timestamp >= lastJoined.add(1 days)){
            lastJoined = block.timestamp;
            joinedToday = 0;
        }

        address _upline = players[_refBy].refBy;

        for(uint i = 1; i < 10; i++){

            if(_upline == address(0)) break;

            players[_upline].referrals[i].push(_userId);
            players[_upline].summary[0].team++;

            _upline = players[_upline].refBy;
        }

        joinedToday++;
    }

    // Update Weekly Referral Counts
    function updateWeeklyReferrals(address payable _userId) private{
        Players storage _player = players[_userId];

        if(_player.weeklyrefs_lastUpdate == 0){
            _player.weeklyrefs_lastUpdate = block.timestamp;
        }

        if(block.timestamp >= _player.weeklyrefs_lastUpdate.add(7 days)){
            _player.weeklyrefs_count = 0;
            _player.weeklyrefs_lastUpdate = block.timestamp;
            _player.weeklyrefs_qualified = false;
        }

        _player.weeklyrefs_count++;

        if(_player.weeklyrefs_count >= 5 && !_player.weeklyrefs_qualified){
            _player.weeklyrefs_qualified = true;
            qualified[currentWeek].push(_userId);
        }
    }

    // Enter Cycle Pool
    function enterCycle(address _userId, uint _planId, uint _enteryId, uint _amount) private{
        // Internal Reserves 12%
        internalReserves(_amount);

        // pay Commissions [13%]
        unilevelCommission(_userId, _amount.mul(14).div(100), _planId);

        packs[_planId.sub(1)].poolSize++;

        // Positions storage _path = gobalpool[_planId.sub(1)];
        nonstopPool.push(poolEntries({
            planId: _planId,
            entryId: _enteryId,
            userId: _userId
            }));

        // check Cycling Members.
        uint _positions = nonstopPool.length;

        if(_positions.mod(2) == 0){
            uint _positionId = _positions.div(2);
            address _cycler = nonstopPool[_positionId.sub(1)].userId;
            uint entryId_ = nonstopPool[_positionId.sub(1)].entryId;
            uint planId_ = nonstopPool[_positionId.sub(1)].planId;
            // Pay reEntry Reward 10%
            cycleReward(_cycler, _amount, entryId_, planId_);
            // Cycle [Re-enters]
            enterCycle(_cycler, planId_, entryId_, _amount);
        }
    }

    // Activate Path
    function activatePath(address payable _userId, uint _amount, uint _planId) private{
        // Insert Path
        Players storage _player = players[_userId];

        Activations storage _activation = activations[_planId][_userId];

        _activation.entries.push(Entries({
            amount: _amount,
            earnings: 0,
            dailyPayCounts: 0,
            totalCycles: 0,
            lastUpdate: uint(block.timestamp),
            active: true
            }));

        _player.summary[0].activations++;
        packs[_planId.sub(1)].activations++;
        _player.packstat[_planId.sub(1)].activations++;
        _player.summary[0].spent += _amount;

        // Track Individual Entries
        paths[_userId][_planId].push(myEntries({
            amount: _amount,
            earnings: 0,
            dailyPayCounts: 0,
            totalCycles: 0
            }));

        uint _entries = 1;

        if(_planId == 2){
            _entries = 5;
        }

        else if(_planId == 3){
            _entries = 10;
        }

        for(uint i = 1; i <= _entries; i++){
            // Update Team Volume
            enterCycle(_userId, _planId, _activation.entries.length, packs[0].cost);
        }
    }

    // Pay commissions [Unilevel] & Update TeamVolume
    function unilevelCommission(address _userId, uint _amount, uint _planId) private{
        address payable _upline = players[_userId].refBy;
        gobalEarnings += _amount;
        gobalBalance += _amount;
        uint _comm;
        uint _paid;
        for(uint i = 0; i < 10; i++){
            if(_upline == address(0)) break;

            if(i == 0){
                _comm = _amount.mul(unilevel[i]).div(14);
            }
            else if(i >= 1){
                _comm = _amount.mul(unilevel[1]).div(14);
            }

            players[_upline].finance[0].balance += _comm;
            players[_upline].summary[0].earnings += _comm;
            players[_upline].summary[0].commissions += _comm;
            players[_upline].packstat[_planId.sub(1)].earnings += _comm;
            _paid += _comm;
            _upline = players[_upline].refBy;
        }

        uint _commL = _amount.sub(_paid);

        if(_commL > 0){
            players[contract_].finance[0].balance += _commL.div(2);
            players[admin].finance[0].balance += _commL.div(2);
        }
    }

    // Pay Cycle Reward 10% [5 Daily or Unlimited for planId 6]
    function cycleReward(address _userId, uint _amount, uint _enteryId, uint _planId) private{

        bool _credit = false;
        uint _comm = _amount.mul(20).div(100);

        if(_userId == address(0)){
            cyclerRewards(_comm);
        }
        else{
            Players storage _player = players[_userId];

            Activations storage _activation = activations[_planId][_userId];

            if(_activation.entries[_enteryId.sub(1)].dailyPayCounts < packs[_planId.sub(1)].dailyCycle && block.timestamp < _activation.entries[_enteryId.sub(1)].lastUpdate.add(1 days)){
                _activation.entries[_enteryId.sub(1)].dailyPayCounts++;
                paths[_userId][_planId][_enteryId.sub(1)].dailyPayCounts++;
                _credit = true;
            }
            else if(block.timestamp >= _activation.entries[_enteryId.sub(1)].lastUpdate.add(1 days)){
                _activation.entries[_enteryId.sub(1)].lastUpdate = block.timestamp;
                _activation.entries[_enteryId.sub(1)].dailyPayCounts = 1;
                paths[_userId][_planId][_enteryId.sub(1)].dailyPayCounts = 1;
                _credit = true;
            }

            if(_credit || _player.id <= 4){
                _activation.entries[_enteryId.sub(1)].earnings += _comm;
                _player.finance[0].balance += _comm;
                _player.summary[0].earnings += _comm;
                _player.packstat[_planId.sub(1)].earnings += _comm;
                paths[_userId][_planId][_enteryId.sub(1)].earnings += _comm;
                gobalEarnings += _comm;
                gobalBalance += _comm;
            }
            _activation.entries[_enteryId.sub(1)].totalCycles++;
            _player.summary[0].cycles++;
            _player.packstat[_planId.sub(1)].totalcycle++;

            paths[_userId][_planId][_enteryId.sub(1)].totalCycles++;
        }
    }

    function cyclerRewards(uint _amount) private{
        uint _reward = _amount.div(2);

        players[admin].finance[0].balance += _reward;
        players[admin].summary[0].earnings += _reward;

        players[contract_].finance[0].balance += _reward;
        players[contract_].summary[0].earnings += _reward;

        gobalEarnings += _amount;
        gobalBalance += _amount;
    }

    // Share GlobalResource
    function internalReserves(uint _amount) private{

        uint _reserve = _amount.mul(3).div(100);

        players[admin].finance[0].balance += _reserve;
        players[contract_].finance[0].balance += _reserve;
        players[team1].finance[0].balance += _reserve;
        players[team2].finance[0].balance += _reserve;


        vipPool += _amount.mul(5).div(100);
        LeadershipPool += _amount.mul(4).div(100);
        purgeBalance += _amount.mul(5).div(100);

        gobalBalance += _reserve.mul(4);
    }

    // Indentify PathId
    function getPathId(uint _amount) private view returns(uint){
        if(_amount == packs[0].cost){
            return 1;
        }
        else if(_amount == packs[1].cost){
            return 2;
        }
        else if(_amount == packs[2].cost){
            return 3;
        }
    }

    // ############################### //
    //    External Functions CALLS     //
    // ############################### //

    // Activate Path [can Activate as Many as possible]
    function joinPath(address payable _refBy) public payable returns(bool){

        require(systemInit, 'WaitingSystemLaunnch');

        address payable _userId = msg.sender;
        uint _amount = msg.value;

        uint _planId = getPathId(_amount);

        require(_amount >= packs[0].cost && _amount <= packs[2].cost, 'Wrong Amount');
        // Register User

        Players storage _player = players[_userId];

        if(_player.refBy == address(0) || _player.id == 0){
            _Register(_userId, _refBy);
        }

        // Activate Path
        activatePath(_userId, _amount, _planId);

        if(_amount >= 5000 trx){
        if(_player.finance[0].vipShares == 0){
        vipUsers.vips.push(_userId);
        }
        _player.finance[0].vipShares++;
        vipUsers.shares++;
        }

            return true;
    }

    // Withdraw Earnings
    function withdraw(uint _amount) public returns(bool){
        require(systemInit, 'WaitingSystemLaunnch');

        address payable _userId = msg.sender;
        Players storage _player = players[_userId];

        if(_amount > _player.finance[0].balance){
            _amount = _player.finance[0].balance;
        }

        require(_amount > 0, 'NoEarnings');

        require(address(this).balance > _amount, 'NoFunds');

        require(_userId.send(_amount),"Transfer failed");

        _player.finance[0].balance -= _amount;

        _player.finance[0].withdrawn += _amount;

        gobalPayouts += _amount;

        gobalBalance -= _amount;

        return true;
    }

    // Re-invest Earnings
    function reInvest() public returns(bool){
        require(systemInit, 'WaitingSystemLaunnch');

        address payable _userId = msg.sender;

        require(isUserExists(_userId), 'NotAllowed');

        Players storage _player = players[_userId];

        uint _balance = _player.finance[0].balance;

        require(_balance >= 500 trx, 'NoEarnings');

        uint _modBalance = _balance.mod(500 trx);

        uint _amount = _balance.sub(_modBalance);

        uint _planId = 1;
        // Amount must be 500x1, 500x5 or 500x10
        if(_amount >= 500 trx && _amount < 2500 trx){
        _amount = 500 trx;
        }
            else if(_amount >= 2500 trx && _amount < 5000 trx){
            _amount = 2500 trx;
            _planId = 2;
            }
            else if(_amount >= 5000 trx){
            _amount = 5000 trx;
            _planId = 3;
            }

            _player.finance[0].balance -= _amount;
        _player.finance[0].withdrawn += _amount;

        gobalPayouts += _amount;

        gobalBalance -= _amount;

        // Activate Path
        activatePath(_userId, _amount, _planId);
    }

    // Credit Weekly Leadership Reward
    function awardLeadership() public returns(bool){
        require(block.timestamp >= lasWeek.add(7 days), 'Every7days');

        require(qualified[currentWeek].length > 0, 'NoQualified');

        uint _shares = LeadershipPool.mul(30).div(100);

        uint _comm = _shares.div(qualified[currentWeek].length);

        for(uint i = 0; i < qualified[currentWeek].length; i++){
            players[qualified[currentWeek][i]].finance[0].balance += _comm;
            players[qualified[currentWeek][i]].summary[0].earnings += _comm;
            players[qualified[currentWeek][i]].summary[0].sponsorPool += _comm;
            players[qualified[currentWeek][i]].weeklyrefs_qualified = false;
            LeadershipPoolPaid += _comm;
            gobalEarnings += _comm;
            gobalBalance += _comm;
        }

        currentWeek++;
        qualified[currentWeek].push(contract_);

        lasWeek = block.timestamp;
        LeadershipPool = LeadershipPool.sub(_shares);

        return true;
    }

    // VIP Incentive Rewards Runs every 48hrs
    function vipSharesAward() public returns(bool){
        // address payable _userId = msg.sender;
        require(isUserExists(msg.sender), 'NoAllowed');
        require(block.timestamp >= lastVIPshared.add(48 hours), 'Every48hrs');

        uint _shares = vipPool.mul(30).div(100);
        uint _share = _shares.div(vipUsers.shares);
        uint _paid;
        for(uint i = 0; i < vipUsers.vips.length; i++){
            address _userId = vipUsers.vips[i];
            Players storage _player = players[_userId];
            // if(_player.summary[0].vipShares < _player.summary[0].spent.mul(3)){
            if(_player.summary[0].vipShares < _player.summary[0].spent){
                uint _uShare = _share.mul(_player.finance[0].vipShares);
                _player.finance[0].balance += _uShare;
                _player.summary[0].earnings += _uShare;
                _player.summary[0].vipShares += _uShare;
                _paid += _uShare;
            }
        }

        if(_shares.sub(_paid) > 0){
            players[contract_].finance[0].balance += _shares.sub(_paid);
            players[contract_].summary[0].earnings += _shares.sub(_paid);
            players[contract_].summary[0].vipShares += _shares.sub(_paid);
        }

        gobalEarnings += _shares;
        gobalBalance += _shares;
        vipPoolPaid += _shares;
        vipPool = vipPool.sub(_shares);
        lastVIPshared = block.timestamp;
        return true;
    }

    function purgeCycle() public returns(bool){

        require(isUserExists(msg.sender), 'NoAllowed');

        require(purgeBalance >= 2500 trx, 'NoEnough fund');

        for(uint i = 1; i <= 5; i++){
            // Update Team Volume
            enterCycle(address(0), 2, 1, 500 trx);
        }
        // purgeBalance = purgeBalance.sub(2500 trx);
        purgeBalance = purgeBalance.sub(2500 trx);
        return true;
    }

    //###############################//
    //   External Functions View     //
    //###############################//
    // View Global Data
    function globalData() public view returns(uint _players, uint _joinedToday, uint _earnings, uint _payouts,  uint _vipPool, uint _vipPoolPaid,
        uint _leadersPool, uint _leadersPoolPaid, uint _purgeBalance, uint _balance, uint _lastVIP, uint _lastLead){
        _players = lastUid.sub(1);
        _joinedToday = joinedToday;
        _earnings = gobalEarnings;
        _payouts = gobalPayouts;
        _vipPool = vipPool;
        _vipPoolPaid = vipPoolPaid;
        _leadersPool = LeadershipPool;
        _leadersPoolPaid = LeadershipPoolPaid;
        _purgeBalance = purgeBalance;
        _balance = address(this).balance;
        _lastVIP = lastVIPshared;
        _lastLead = lasWeek;
    }

    // view Pool Ranks per packs
    function viewTotalPositions() public view returns(uint _length){
        _length = nonstopPool.length;
    }

    // View Users Data
    function userInfo(address _userId) public view returns(uint _activations, uint _totalTRX, uint _totalEarnings, uint _uniLevelEarnings,
        uint _vipShare, uint _leadershipEarnings,  uint _withdrawan, uint _balance, uint _vipShares, uint _refs, uint _cycles, uint _teamSize){
        Players memory _player = players[_userId];
        _activations = _player.summary[0].activations;
        _totalTRX = _player.summary[0].spent;
        _totalEarnings = _player.summary[0].earnings;
        _uniLevelEarnings = _player.summary[0].commissions;
        _vipShare = _player.summary[0].vipShares;
        _leadershipEarnings = _player.summary[0].sponsorPool;
        _withdrawan = _player.finance[0].withdrawn;
        _balance = _player.finance[0].balance;
        _vipShares = _player.finance[0].vipShares;
        _refs = _player.summary[0].refs;
        _teamSize = _player.summary[0].team;
        _cycles = _player.summary[0].cycles;
    }

    // Using PlanId with 0 Index
    function getUserPathsRecords(address _userId, uint _planId) public view returns(uint _activations, uint _earnings, uint _cycles){
        Players memory _player = players[_userId];
        _activations = _player.packstat[_planId].activations;
        _earnings = _player.packstat[_planId].earnings;
        _cycles = _player.packstat[_planId].totalcycle;
    }

    // View All Referrals
    function myReferrals(address _userId, uint _level) public view returns(address payable[] memory){
        return(
        players[_userId].referrals[_level.sub(1)]
        );
    }

    // View VIP members
    function viewvipUsers() public view returns(address[] memory){
        return vipUsers.vips;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent TRC20 tokens
    // ------------------------------------------------------------------------
    function missedTokens(address _tokenAddress) public onlyContract returns(bool success) {
        uint _value = ITRC20(_tokenAddress).balanceOf(address(this));
        return ITRC20(_tokenAddress).transfer(msg.sender, _value);
    }

    function setTeam(address payable _admin, address payable _team1, address payable _team2) public onlyContract returns(bool){
        admin = _admin;
        team1 = _team1;
        team2 = _team2;
        return true;
    }

    function toggleSystemInit() public onlyContract returns(bool){
        systemInit = !systemInit ? true:false;
        return systemInit;
    }

    function isUserExists(address _userId) internal view returns (bool) {
        return (players[_userId].id != 0);
    }
}


interface ITRC20 {
    function balanceOf(address tokenOwner) external pure returns (uint balance);
    function transfer(address to, uint value) external returns (bool);
}

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }


    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}