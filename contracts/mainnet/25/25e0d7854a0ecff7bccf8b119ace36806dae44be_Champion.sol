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