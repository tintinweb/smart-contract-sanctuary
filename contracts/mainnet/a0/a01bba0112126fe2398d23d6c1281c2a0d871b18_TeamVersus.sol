pragma solidity ^0.4.23;

library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function withdrawAll() public onlyOwner{
        owner.transfer(address(this).balance);
    }

    function withdrawPart(address _to,uint256 _percent) public onlyOwner{
        require(_percent>0&&_percent<=100);
        require(_to != address(0));
        uint256 _amount = address(this).balance - address(this).balance*(100 - _percent)/100;
        if (_amount>0){
            _to.transfer(_amount);
        }
    }
}
contract Pausable is Ownable {

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }


    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused returns(bool) {
        paused = true;
        return true;
    }

    function unpause() public onlyOwner whenPaused returns(bool) {
        paused = false;
        return true;
    }

}
contract WWC is Pausable {
    string[33] public teams = [
        "",
        "Egypt",              // 1
        "Morocco",            // 2
        "Nigeria",            // 3
        "Senegal",            // 4
        "Tunisia",            // 5
        "Australia",          // 6
        "IR Iran",            // 7
        "Japan",              // 8
        "Korea Republic",     // 9
        "Saudi Arabia",       // 10
        "Belgium",            // 11
        "Croatia",            // 12
        "Denmark",            // 13
        "England",            // 14
        "France",             // 15
        "Germany",            // 16
        "Iceland",            // 17
        "Poland",             // 18
        "Portugal",           // 19
        "Russia",             // 20
        "Serbia",             // 21
        "Spain",              // 22
        "Sweden",             // 23
        "Switzerland",        // 24
        "Costa Rica",         // 25
        "Mexico",             // 26
        "Panama",             // 27
        "Argentina",          // 28
        "Brazil",             // 29
        "Colombia",           // 30
        "Peru",               // 31
        "Uruguay"             // 32
    ];
}

contract Champion is WWC {
    event VoteSuccessful(address user,uint256 team, uint256 amount);
    
    using SafeMath for uint256;
    struct Vote {
        mapping(address => uint256) amounts;
        uint256 totalAmount;
        address[] users;
        mapping(address => uint256) weightedAmounts;
        uint256 weightedTotalAmount;
    }
    uint256 public pool;
    Vote[33] votes;
    uint256 public voteCut = 5;
    uint256 public poolCut = 30;
    
    uint256 public teamWon;
    uint256 public voteStopped;
    
    uint256 public minVote = 0.05 ether;
    uint256 public voteWeight = 4;
    
    mapping(address=>uint256) public alreadyWithdraw;

    modifier validTeam(uint256 _teamno) {
        require(_teamno > 0 && _teamno <= 32);
        _;
    }

    function setVoteWeight(uint256 _w) public onlyOwner{
        require(_w>0&& _w<voteWeight);
        voteWeight = _w;
    }
    
    function setMinVote(uint256 _min) public onlyOwner{
        require(_min>=0.01 ether);
        minVote = _min;
    }
    function setVoteCut(uint256 _cut) public onlyOwner{
        require(_cut>=0&&_cut<=100);
        voteCut = _cut;
    }
    
    function setPoolCut(uint256 _cut) public onlyOwner{
        require(_cut>=0&&_cut<=100);
        poolCut = _cut;
    }
    function getVoteOf(uint256 _team) validTeam(_team) public view returns(
        uint256 totalUsers,
        uint256 totalAmount,
        uint256 meAmount,
        uint256 meWeightedAmount
    ) {
        Vote storage _v = votes[_team];
        totalAmount = _v.totalAmount;
        totalUsers = _v.users.length;
        meAmount = _v.amounts[msg.sender];
        meWeightedAmount = _v.weightedAmounts[msg.sender];
    }

    function voteFor(uint256 _team) validTeam(_team) public payable whenNotPaused {
        require(msg.value >= minVote);
        require(voteStopped == 0);
        userVoteFor(msg.sender, _team, msg.value);
    }

    function userVoteFor(address _user, uint256 _team, uint256 _amount) internal{
        Vote storage _v = votes[_team];
        uint256 voteVal = _amount.sub(_amount.mul(voteCut).div(100));
        if (voteVal<_amount){
            owner.transfer(_amount.sub(voteVal));
        }
        if (_v.amounts[_user] == 0) {
            _v.users.push(_user);
        }
        pool = pool.add(voteVal);
        _v.totalAmount = _v.totalAmount.add(voteVal);
        _v.amounts[_user] = _v.amounts[_user].add(voteVal);
        _v.weightedTotalAmount = _v.weightedTotalAmount.add(voteVal.mul(voteWeight));
        _v.weightedAmounts[_user] = _v.weightedAmounts[_user].add(voteVal.mul(voteWeight)); 
        emit VoteSuccessful(_user,_team,_amount);
    }

    function stopVote()  public onlyOwner {
        require(voteStopped == 0);
        voteStopped = 1;
    }
    
    function setWonTeam(uint256 _team) validTeam(_team) public onlyOwner{
        require(voteStopped == 1);
        teamWon = _team;
    }
    
    function myBonus() public view returns(uint256 _bonus,bool _isTaken){
        if (teamWon==0){
            return (0,false);
        }
        _bonus = bonusAmount(teamWon,msg.sender);
        _isTaken = alreadyWithdraw[msg.sender] == 1;
    }

    function bonusAmount(uint256 _team, address _who) internal view returns(uint256) {
        Vote storage _v = votes[_team];
        if (_v.weightedTotalAmount == 0){
            return 0;
        }
        uint256 _poolAmount = pool.mul(100-poolCut).div(100);
        uint256 _amount = _v.weightedAmounts[_who].mul(_poolAmount).div(_v.weightedTotalAmount);
        return _amount;
    }
    
    function withdrawBonus() public whenNotPaused{
        require(teamWon>0);
        require(alreadyWithdraw[msg.sender]==0);
        alreadyWithdraw[msg.sender] = 1;
        uint256 _amount = bonusAmount(teamWon,msg.sender);
        require(_amount<=address(this).balance);
        if(_amount>0){
            msg.sender.transfer(_amount);
        }
    }
}

contract TeamVersus is WWC {
    event VoteSuccessful(address user,uint256 combatId,uint256 team, uint256 amount);
    using SafeMath for uint256;
    struct Combat{
        uint256 poolOfTeamA;
        uint256 poolOfTeamB;
        uint128 teamAID;         // team id: 1-32
        uint128 teamBID;         // team id: 1-32
        uint128 state;  // 0 not started 1 started 2 ended
        uint128 wonTeamID; // 0 not set
        uint256 errCombat;  // 0 validate 1 errCombat
    }
    mapping (uint256 => bytes32) public comments;
    
    uint256 public voteCut = 5;
    uint256 public poolCut = 20;
    uint256 public minVote = 0.05 ether;
    Combat[] combats;
    mapping(uint256=>mapping(address=>uint256)) forTeamAInCombat;
    mapping(uint256=>mapping(address=>uint256)) forTeamBInCombat;
    mapping(uint256=>address[]) usersForTeamAInCombat;
    mapping(uint256=>address[]) usersForTeamBInCombat;
    
    mapping(uint256=>mapping(address=>uint256)) public alreadyWithdraw;
    
    function init() public onlyOwner{
        addCombat(1,32,"Friday 15 June");
        addCombat(2,7,"Friday 15 June");
        addCombat(19,22,"Friday 15 June");
        addCombat(15,6,"Saturday 16 June");
        addCombat(28,17,"Saturday 16 June");
        addCombat(31,13,"Saturday 16 June");
        addCombat(12,3,"Saturday 16 June");
        addCombat(25,21,"Sunday 17 June");
        addCombat(16,26,"Sunday 17 June");
        addCombat(29,24,"Sunday 17 June");
        addCombat(23,9,"Monday 18 June");
        addCombat(11,27,"Monday 18 June");
        addCombat(5,14,"Monday 18 June");
        addCombat(30,8,"Tuesday 19 June");
        addCombat(18,4,"Tuesday 19 June");
        addCombat(20,1,"Tuesday 19 June");
        addCombat(19,2,"Wednesday 20 June");
        addCombat(32,10,"Wednesday 20 June");
        addCombat(7,22,"Wednesday 20 June");
        addCombat(13,6,"Thursday 21 June");
        addCombat(15,31,"Thursday 21 June");
        addCombat(28,12,"Thursday 21 June");
        addCombat(29,25,"Friday 22 June");
        addCombat(3,17,"Friday 22 June");
        addCombat(21,24,"Friday 22 June");
        addCombat(11,5,"Saturday 23 June");
        addCombat(9,26,"Saturday 23 June");
        addCombat(16,23,"Saturday 23 June");
        addCombat(14,27,"Sunday 24 June");
        addCombat(8,4,"Sunday 24 June");
        addCombat(18,30,"Sunday 24 June");
        addCombat(32,20,"Monday 25 June");
        addCombat(10,1,"Monday 25 June");
        addCombat(22,2,"Monday 25 June");
        addCombat(7,19,"Monday 25 June");
        addCombat(6,31,"Tuesday 26 June");
        addCombat(13,15,"Tuesday 26 June");
        addCombat(3,28,"Tuesday 26 June");
        addCombat(17,12,"Tuesday 26 June");
        addCombat(9,16,"Wednesday 27 June");
        addCombat(26,23,"Wednesday 27 June");
        addCombat(21,29,"Wednesday 27 June");
        addCombat(24,25,"Wednesday 27 June");
        addCombat(8,18,"Thursday 28 June");
        addCombat(4,30,"Thursday 28 June");
        addCombat(27,5,"Thursday 28 June");
        addCombat(14,11,"Thursday 28 June");
    }
    function setMinVote(uint256 _min) public onlyOwner{
        require(_min>=0.01 ether);
        minVote = _min;
    }
    
    function markCombatStarted(uint256 _index) public onlyOwner{
        Combat storage c = combats[_index];
        require(c.errCombat==0 && c.state==0);
        c.state = 1;
    }
    
    function markCombatEnded(uint256 _index) public onlyOwner{
        Combat storage c = combats[_index];
        require(c.errCombat==0 && c.state==1);
        c.state = 2;
    }  
    
    function setCombatWonTeam(uint256 _index,uint128 _won) public onlyOwner{
        Combat storage c = combats[_index];
        require(c.errCombat==0 && c.state==2);
        require(c.teamAID == _won || c.teamBID == _won);
        c.wonTeamID = _won;
    }      

    function withdrawBonus(uint256 _index) public whenNotPaused{
        Combat storage c = combats[_index];
        require(c.errCombat==0 && c.state ==2 && c.wonTeamID>0);
        require(alreadyWithdraw[_index][msg.sender]==0);
        alreadyWithdraw[_index][msg.sender] = 1;
        uint256 _amount = bonusAmount(_index,msg.sender);
        require(_amount<=address(this).balance);
        if(_amount>0){
            msg.sender.transfer(_amount);
        }
    }    
    function myBonus(uint256 _index) public view returns(uint256 _bonus,bool _isTaken){
        Combat storage c = combats[_index];
        if (c.wonTeamID==0){
            return (0,false);
        }
        _bonus = bonusAmount(_index,msg.sender);
        _isTaken = alreadyWithdraw[_index][msg.sender] == 1;
    }    
    
    function bonusAmount(uint256 _index,address _who) internal view returns(uint256){
        Combat storage c = combats[_index];
        uint256 _poolAmount = c.poolOfTeamA.add(c.poolOfTeamB).mul(100-poolCut).div(100);
        uint256 _amount = 0;
        if (c.teamAID ==c.wonTeamID){
            if (c.poolOfTeamA == 0){
                return 0;
            }
            _amount = forTeamAInCombat[_index][_who].mul(_poolAmount).div(c.poolOfTeamA);
        }else if (c.teamBID == c.wonTeamID) {
            if (c.poolOfTeamB == 0){
                return 0;
            }            
            _amount = forTeamBInCombat[_index][_who].mul(_poolAmount).div(c.poolOfTeamB);
        }
        return _amount;        
    }
    
    function addCombat(uint128 _teamA,uint128 _teamB,bytes32 _cmt) public onlyOwner{
        Combat memory c = Combat({
            poolOfTeamA: 0,
            poolOfTeamB: 0,
            teamAID: _teamA,
            teamBID: _teamB,
            state: 0,
            wonTeamID: 0,
            errCombat: 0
        });
        uint256 id = combats.push(c) - 1;
        comments[id] = _cmt;
    }
    
    
    function setVoteCut(uint256 _cut) public onlyOwner{
        require(_cut>=0&&_cut<=100);
        voteCut = _cut;
    }
    
    function setPoolCut(uint256 _cut) public onlyOwner{
        require(_cut>=0&&_cut<=100);
        poolCut = _cut;
    }    
    
    function getCombat(uint256 _index) public view returns(
        uint128 teamAID,
        string teamAName,
        uint128 teamBID,
        string teamBName,
        uint128 wonTeamID,
        uint256 poolOfTeamA,
        uint256 poolOfTeamB,
        uint256 meAmountForTeamA,
        uint256 meAmountForTeamB,
        uint256 state,
        bool isError,
        bytes32 comment
    ){
        Combat storage c = combats[_index];
        teamAID = c.teamAID;
        teamAName = teams[c.teamAID];
        teamBID = c.teamBID;
        teamBName = teams[c.teamBID];
        wonTeamID = c.wonTeamID;
        state = c.state;
        poolOfTeamA = c.poolOfTeamA;
        poolOfTeamB = c.poolOfTeamB;
        meAmountForTeamA = forTeamAInCombat[_index][msg.sender];
        meAmountForTeamB = forTeamBInCombat[_index][msg.sender];
        isError = c.errCombat == 1;
        comment = comments[_index];
    }
    
    function getCombatsCount() public view returns(uint256){
        return combats.length;
    }
    
    function invalidateCombat(uint256 _index) public onlyOwner{
        Combat storage c = combats[_index];
        require(c.errCombat==0);
        c.errCombat = 1;
    }
    
    function voteFor(uint256 _index,uint256 _whichTeam) public payable whenNotPaused{
        require(msg.value>=minVote);
        Combat storage c = combats[_index];
        require(c.errCombat==0 && c.state == 0 && c.wonTeamID==0);
        userVoteFor(msg.sender, _index,_whichTeam, msg.value);
    }

    function userVoteFor(address _standFor, uint256 _index,uint256 _whichTeam, uint256 _amount) internal{
        Combat storage c = combats[_index];
        uint256 voteVal = _amount.sub(_amount.mul(voteCut).div(100));
        if (voteVal<_amount){
            owner.transfer(_amount.sub(voteVal));
        }
        if (_whichTeam == c.teamAID){
            c.poolOfTeamA = c.poolOfTeamA.add(voteVal);
            if (forTeamAInCombat[_index][_standFor]==0){
                usersForTeamAInCombat[_index].push(_standFor);
            }
            forTeamAInCombat[_index][_standFor] = forTeamAInCombat[_index][_standFor].add(voteVal);
        }else {
            c.poolOfTeamB = c.poolOfTeamB.add(voteVal);
            if (forTeamBInCombat[_index][_standFor]==0){
                usersForTeamBInCombat[_index].push(_standFor);
            }
            forTeamBInCombat[_index][_standFor] = forTeamAInCombat[_index][_standFor].add(voteVal);            
        }
        emit VoteSuccessful(_standFor,_index,_whichTeam,_amount);
    }    
    
    function refundErrCombat(uint256 _index) public whenNotPaused{
        Combat storage c = combats[_index];
        require(c.errCombat == 1);
        uint256 _amount = forTeamAInCombat[_index][msg.sender].add(forTeamBInCombat[_index][msg.sender]);
        require(_amount>0);

        forTeamAInCombat[_index][msg.sender] = 0;
        forTeamBInCombat[_index][msg.sender] = 0;
        msg.sender.transfer(_amount);
    }
}