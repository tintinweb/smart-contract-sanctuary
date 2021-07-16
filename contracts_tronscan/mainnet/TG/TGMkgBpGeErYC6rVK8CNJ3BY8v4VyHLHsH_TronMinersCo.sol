//SourceUnit: TronMinersCo.sol

/*
* TronMinersCo Smart Contract
* Tron Cloud Mining Platform
* Earn Up To 200%
* Stop and Unstake Whenever You Want
* Power Up Mining by Multi-Referral System
* Secure Lottery Game Service
*/
pragma solidity ^0.5.4;

contract TronMinersCo {
    
    struct Stake {
        uint64 amount;
        uint64 claimed;
        uint32 start;
        uint32 lastClaimed;
        address referrer;
        bool playGame;
    }
    
    struct User {
        Stake[] stakes;
        uint32 lastClaimed;
        uint64 dailyClaimed;
        uint32 lastUnstake;
        uint64 referrals;
    }
    
    event StakeEvent(address indexed dst, uint amount, address referrer);
    event ClaimEvent(address indexed src, uint claimed);
    event UnstakeEvent(address indexed src, uint toBePaid);
    event Draw(uint indexed round, uint blockNumber, address indexed winner, uint amount);
    event NewRound(uint indexed round, uint blockNumber);
    
    uint public constant MIN_STAKE = 500 trx;
    uint public constant MAX_STAKE = 50000 trx;
    uint public constant MINE_PERCENT = 200;
    uint public constant PERCENT_DIV = 10000;
    uint constant public TIME_STEP = 1 days;
    uint public constant DAILY_LIMIT = 50000 trx; 
    
    address payable public supportTeam;
    uint public totalUsers;
    uint public totalStaked;
    uint public totalClaimed;
    uint public teamShareAcc;
    mapping(address => User) private users;
    
    //----------------------
    //        LOTTERY
    //----------------------
    
    uint public constant LOTTERY_PERCENT = 200;
    uint public constant LOT_DURATION = 2 days;
    
    struct Round {
        uint32 end;
        uint64 drawBlock;
        Entry[] entries;
        uint64 totalQuantity;
        address winner;
    }

    struct Entry {
        address buyer;
        uint64 quantity;
    }

    uint constant public TICKET_PRICE = 1 trx;
    mapping(uint => Round) public rounds;
    mapping(address => uint64) public balances;
    uint32 public round;
    //----------------------
    //   End Of LOTTERY
    //----------------------
    
    constructor(address payable _supportTeam) public {
        require(!isContract(_supportTeam));
        supportTeam = _supportTeam;
        round = 1;
        rounds[round].end = uint32(now + LOT_DURATION);
    }
    
    //----------------------
    //        Views
    //----------------------
    
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }
    
    function getMyAffiliationPercent() public view returns (uint){
        uint refPercent = users[msg.sender].referrals / 500 trx;
        return refPercent > 50 ? 50 : refPercent;
    }
    
    function getMyDailyAvailableClaim() public view returns (uint) {
        if (subtract(now, users[msg.sender].lastClaimed) > TIME_STEP) {
            return DAILY_LIMIT;
        } else {
            return subtract(DAILY_LIMIT, users[msg.sender].dailyClaimed);
        }
    }
    
    function getPoolPercent() public view returns (uint){
        uint balancePercent = (address(this).balance / 200000 trx) * 100;
        return balancePercent > PERCENT_DIV ? PERCENT_DIV : balancePercent;
    }
    
    function getMyDep() public view returns (uint, uint){
        uint userDep;
        uint userWith;
        for (uint i = 0; i < users[msg.sender].stakes.length; i++) {
            userDep += users[msg.sender].stakes[i].amount;
            userWith += users[msg.sender].stakes[i].claimed;
        }
        return (userDep, userWith);
    }
    
    //----------------------
    //    End of Views
    //----------------------
    
    //----------------------
    //   Private Members
    //----------------------
    
    function subtract(uint a, uint b) private pure returns(uint){
        require(b <= a, "subtraction overflow");
        return a - b;
    }
    
    function updateMyDailyClaim(uint _amount) private {
        User storage user = users[msg.sender];
        if (subtract(block.timestamp, user.lastClaimed) > TIME_STEP) {
            user.lastClaimed = uint32(block.timestamp);
            user.dailyClaimed = 0;
        }
        user.dailyClaimed += uint64(_amount);
    }
    
    function freeUpMyFinishedStake(uint _index) private {
        User storage user = users[msg.sender];
        if (_index < user.stakes.length - 1) {
                user.stakes[_index] = user.stakes[user.stakes.length - 1];
            }
            user.stakes.length--;
    }
    
    function playLottery() private {
        uint quantity = msg.value * LOTTERY_PERCENT / PERCENT_DIV / TICKET_PRICE;
        Entry memory entry = Entry(msg.sender, uint64(quantity));
        rounds[round].entries.push(entry);
        rounds[round].totalQuantity += uint64(quantity);
    }
    //----------------------
    //End of Private Members
    //----------------------
    
    function deposit(address _referrer, bool _playGame) external payable {
         
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(users[msg.sender].stakes.length <= 100);
        require(msg.value >= MIN_STAKE && msg.value <= MAX_STAKE, "Wrong amount!");
        
        address referrer = address(0);
        if (users[_referrer].stakes.length > 0 && _referrer != msg.sender) {
            referrer = _referrer;
            users[referrer].referrals += uint64(msg.value);
        }

        Stake memory dep = Stake(uint64(msg.value), uint64(0), uint32(block.timestamp), uint32(block.timestamp), referrer, _playGame);
        users[msg.sender].stakes.push(dep);
        
        endLottery();
        if (_playGame) {
            playLottery();
        }
        if (round > 1) {
            drawWinner(round - 1);
        }
        
        if (users[msg.sender].stakes.length == 1) {
            totalUsers ++;
        }
        totalStaked += msg.value;
        emit StakeEvent(msg.sender, msg.value, dep.referrer);
    }
    
    function claim(uint _index) external {

        require(_index < users[msg.sender].stakes.length);
        
        Stake storage stake = users[msg.sender].stakes[_index];
        
        require(subtract(block.timestamp,stake.lastClaimed) > TIME_STEP, "Wait 24 hours!");
        
        uint available = stake.amount * (MINE_PERCENT + getMyAffiliationPercent()) * subtract(block.timestamp, stake.start) / TIME_STEP / PERCENT_DIV;
        available = available > stake.amount * 2 ? stake.amount * 2 : available;
        available = subtract(available, stake.claimed);
        
        uint dailyLimit = getMyDailyAvailableClaim();
        if(available > dailyLimit){
            available = dailyLimit;
        }
        if(available > address(this).balance){
            available = address(this).balance;
        }
        if((available > 10 trx) || (stake.claimed + available < stake.amount * 2)){
            available = available * getPoolPercent() / PERCENT_DIV;
        }
        uint toBePaid = available;
        if (stake.playGame) {
            toBePaid = subtract(available, available * LOTTERY_PERCENT / PERCENT_DIV);
        }
        require(toBePaid > 0, "Not mined!");
        
        if(toBePaid + stake.claimed == stake.amount * 2){
            if (stake.referrer != address(0)) {
                users[stake.referrer].referrals = uint64(subtract(users[stake.referrer].referrals, stake.amount));
                stake.referrer = address(0);
            }
        }
        
        stake.claimed += uint64(available);
        stake.lastClaimed = uint32(block.timestamp);
        
        updateMyDailyClaim(available);
        totalClaimed += available;
        
        uint teamShare = teamShareAcc + available * 800 / PERCENT_DIV;
        if (teamShare < 10 trx) {
            teamShareAcc = teamShare;
        } else {
            teamShareAcc = 0;
        }
        msg.sender.transfer(toBePaid);
        if(teamShare >= 10 trx){
            if(address(this).balance > 0){
                if(teamShare <= address(this).balance){
                    supportTeam.transfer(teamShare);
                }else{
                    supportTeam.transfer(address(this).balance);
                }
            }
        }
        emit ClaimEvent(msg.sender, available);
    }
    
    function unstake(uint _index) external {

        User storage user = users[msg.sender];
        require(_index < user.stakes.length, "Invalid index");
        require(subtract(block.timestamp, user.lastUnstake) > TIME_STEP, "Wait 24 hours!");
        Stake storage stake = user.stakes[_index];
        require(stake.claimed < stake.amount, "Already earned!");
        require(getPoolPercent() < PERCENT_DIV, "Disabled");
        uint mined = stake.amount * (MINE_PERCENT + getMyAffiliationPercent()) * subtract(block.timestamp, stake.start) / TIME_STEP / PERCENT_DIV;
        require(stake.claimed == 0 || mined >= stake.amount, "Couldn't claim!");
        
        uint available = subtract(stake.amount, stake.claimed);
        (uint userStaked, uint userClaimed) = getMyDep();
        require(userClaimed < userStaked, "Already earned!");
        if(available + userClaimed > userStaked){
            available = subtract(userStaked, userClaimed);
        }
        uint toBePaid = available > address(this).balance ? address(this).balance : available;

        uint cancellationFee = available * 100 / PERCENT_DIV;
        toBePaid = subtract(toBePaid, cancellationFee);
        
        if (stake.playGame) {
            toBePaid = subtract(toBePaid, available * LOTTERY_PERCENT / PERCENT_DIV);
        }
        
        require(toBePaid > 0, "Not available!");

        user.lastUnstake = uint32(block.timestamp);
        if (stake.referrer != address(0)) {
            users[stake.referrer].referrals = uint64(subtract(users[stake.referrer].referrals, stake.amount));
        }
        freeUpMyFinishedStake(_index);
        totalClaimed += available;
        
        uint teamShare = teamShareAcc + cancellationFee;
        if (teamShare < 10 trx) {
            teamShareAcc = teamShare;
        } else {
            teamShareAcc = 0;
        }

        msg.sender.transfer(toBePaid);
        if(teamShare >= 10 trx){
            if(address(this).balance > 0){
                if(teamShare <= address(this).balance){
                    supportTeam.transfer(teamShare);
                }else{
                    supportTeam.transfer(address(this).balance);
                }
            }
        }
        
        emit UnstakeEvent(msg.sender, toBePaid);
    }
    
    function withdrawAward() public {
        uint amount = balances[msg.sender];
        uint teamShare = teamShareAcc + amount * 700 / PERCENT_DIV;
        if (teamShare < 10 trx) {
            teamShareAcc = teamShare;
        } else {
            teamShareAcc = 0;
        }
         balances[msg.sender] = 0;
         
        msg.sender.transfer(subtract(amount, teamShare));
        if(teamShare >= 10 trx){
            if(address(this).balance > 0){
                if(teamShare <= address(this).balance){
                    supportTeam.transfer(teamShare);
                }else{
                    supportTeam.transfer(address(this).balance);
                }
            }
        }
    }
    
    function drawWinner(uint _roundNumber) public returns (bool) {
        Round storage drawing = rounds[_roundNumber];
        if (now <= drawing.end) return false;
        if (_roundNumber >= round) return false;
        if (drawing.winner != address(0)) return false;
        if (block.number <= drawing.drawBlock) return false;
        if (drawing.entries.length == 0) return false;

        bytes32 rand = keccak256(abi.encodePacked(blockhash(drawing.drawBlock)));
        uint counter = uint(rand) % drawing.totalQuantity;
        for (uint i = 0; i < drawing.entries.length; i++) {
            uint quantity = drawing.entries[i].quantity;
            if (quantity > counter) {
                drawing.winner = drawing.entries[i].buyer;
                break;
            }
            else
                counter -= quantity;
        }
        uint prize = TICKET_PRICE * drawing.totalQuantity;
        balances[drawing.winner] += uint64(prize);
        emit Draw(_roundNumber, block.number, drawing.winner, prize);
        return true;
    }
    
    function deleteRound(uint _round) public {
        require(block.number > rounds[_round].drawBlock + 100);
        require(rounds[_round].winner != address(0));
        delete rounds[_round];
    }
    
    function endLottery() public {
        if (now > rounds[round].end) {
            rounds[round].drawBlock = uint64(block.number) + 5;
            round++;
            rounds[round].end = uint32(now + LOT_DURATION);
            emit NewRound(round, block.number);
        }
    }
    
    function getMyStakes() public view returns (
        uint64[] memory stakeAmounts,
        uint64[] memory stakesClaimed,
        uint32[] memory stakeStartTimes,
        uint32[] memory stakeClaimTimes,
        address[] memory stakeReferrals,
        uint lastClaimed,
        uint lastUnstake,
        uint affiliationPower,
        uint dailyClaimCap)
    {
        User storage user = users[msg.sender];
        uint64[] memory values = new uint64[](user.stakes.length);
        uint64[] memory withdrawn = new uint64[](user.stakes.length);
        uint32[] memory times = new uint32[](user.stakes.length);
        uint32[] memory lastClaimTimes = new uint32[](user.stakes.length);
        address[] memory addresses = new address[](user.stakes.length);

        for (uint i = 0; i < user.stakes.length; i++) {
            values[i] = user.stakes[i].amount;
            withdrawn[i] = user.stakes[i].claimed;
            times[i] = user.stakes[i].start;
            lastClaimTimes[i] = user.stakes[i].lastClaimed;
            addresses[i] = user.stakes[i].referrer;
        }
        return (values, withdrawn, times, lastClaimTimes, addresses, user.lastClaimed, user.lastUnstake, getMyAffiliationPercent(), getMyDailyAvailableClaim());
    }

    function getContractStats() public view returns
    (   
        uint vTotalStaked,
        uint vTotalClaimed,
        uint vTotalUsers,
        uint vContractBalance)
    {
        return
        (
        totalStaked,
        totalClaimed,
        totalUsers,
        address(this).balance);
    }
    
    function getLotteryStats() public view returns
    (
        uint32 roundNumber,
        uint64 quantity,
        uint32 end,
        uint64 award)
    {
        return
        (
        round,
        rounds[round].totalQuantity,
        rounds[round].end,
        balances[msg.sender]);
    }
    
    function getRound(uint _round) external view returns (uint endsIn, uint endBlock, uint quantity, address winner){
        Round storage drawing = rounds[_round];
        return (drawing.end, drawing.drawBlock, drawing.totalQuantity, drawing.winner);
    }
}