//SourceUnit: LuckyBlocks.sol

/*
 *
 *   Lucky Blocks - Decentralized Lottery Platform Based on TRX Blockchain Smart-Contract Technology. 
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://luckyblocks.net                                    │
 *   │                                                                       │
 *   │   Telegram Public Group: @luckyblocksofficial                         │
 *   │   Telegram News Channel: @lockyblocks                                 │
 *   │                                                                       │
 *   │   E-mail: info@luckyblocks.net                                        │
 *   └───────────────────────────────────────────────────────────────────────┘
 *      Develop & Audit by HazeCrypto Company (https://hazecrypto.net)
 *      S&S8712943
 *
 */


pragma solidity 0.5.10;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract LuckyBlocks is Ownable{
    using SafeMath for uint;

    uint private constant DEVELOPER_RATE = 30; 
    uint private constant MARKETING_RATE = 40;
    uint private constant REFERENCE_RATE = 70;
    uint private constant DRAW_COST_RATE = 120; 
    uint private constant JACKPOT_REFRESH = 3;
    uint private constant GOLDEN_ROUND_REFRESH = 5;
    uint private constant ROUND_STOP_MAX_BALANCE = 10E9;
    uint private constant JACKPOT_RATE = 500;
    uint private constant JACKPOT_WINNER_RATE = 900;
    uint private constant JACKPOT_MAINTENANCE_RATE = 50;
    uint private constant JACKPOT_REFERENCE_RATE = 20;
    uint private constant JACKPOT_TRANSFER_RATE = 30;
    uint private constant SILVERSPOT_RATE = 240;
    uint private constant SILVERSPOT_WINNER5_RATE = 300;
    uint private constant SILVERSPOT_WINNER4_RATE = 125;
    uint private constant SILVERSPOT_WINNER3_RATE = 75;
    uint private constant REFERENCE_LEVEL1_RATE = 40;
    uint private constant REFERENCE_LEVEL2_RATE = 20;
    uint private constant REFERENCE_LEVEL3_RATE = 10;
    uint private constant DIVIDER = 1000;
    uint private constant ROUND_DURATION_NORMAL = 4*60*60;
    uint private constant ROUND_DURATION_GOLDEN = 24*60*60;
    uint private constant LOCK_DURATION = 3*60;
    uint private constant TOTAL_NUMBERS = 31;
    uint private constant TN = 6;
    uint private constant MAX_TICKET_BUY = 10;
    uint private constant ROUND_NORMAL  = 0; 
    uint private constant ROUND_GOLDEN  = 1; 
    uint private constant ROUND_JACKPOT = 2; 
    uint private constant GOLDEN_ROUND_RATE = 300; 
    uint private constant GOLDEN_ROUND_DEFAULT = 1E12; 
    uint private constant GOLDEN_ROUND_RETURN = 10; 
    uint private constant GOLDEN_A_W_JACKPOT = 80;
    uint private constant ROUND_STEP = 20;

    uint[4] private TICKET_PRICES    = [30E6,14E7,8E8,25E8];
    uint[4] private TICKET_ROUNDS = [1,6,42,168];
    uint[7] private COUPON = [0,200,300,400,500,600,500];
    uint[2] private LAUNCH_COUPON = [10,100];
    uint[6] private LUCKY_NUMBERS;

    
    uint private RAND;
    uint public  CONTRACT_LAUNCH_DATE;
    bool public  LOTTERY_STATUS = false;
    uint public  Golden_Round = GOLDEN_ROUND_DEFAULT;
    uint public  RoundStatus = 0; 
    uint public  RoundIndex  = 0; 
    uint public  LastJoG  = 0;

    address payable private Developer;
    address payable private Marketing;
    address payable private DrawCost;

    struct Ticket {
        uint      userId;
        uint      types;
        uint[TN]  numbers;
        uint      startRound;
        uint      endRound;
    }

    struct User {
        address   addr;
        uint      ticketCnt;
        uint[TN]  coupons;
        uint      lastActivity;
        uint      referrer;
        uint[3]   refs;
        uint      totalPaid;
        uint      totalWithdrawn;
        uint      totalReferrals;
        uint      walletBalance;
        string    name;
    }

    struct Round {
        uint      startDate;
        uint      types;
        uint[TN]  numbers;
        uint[TN]  winners;
        uint      jackpot;
        uint      silverspot;
        uint      ticketCnt;
        uint      activeTicketCnt;
        uint[]    tickets;
    }

    struct Win {
        mapping(uint => bool) tickets;
    }

    uint public totalUsers;
    uint public totalTickets;
    uint public totalActiveTickets;
    uint public totalRounds;
    uint public totalJackpots;
    uint public totalGoldenRounds;

    uint private totalSales;
    uint public  totalWithdrawn;

    uint public jackpot;
    uint public silverspot;

    mapping (address => uint) private addrToUserId; 
    mapping (uint => User) private users; 
    mapping (uint => Round) private rounds; 
    mapping (uint => Ticket) private tickets; 
    mapping (uint => uint) private activeTickets; 
    mapping (uint => Win) private wins; 

    event NewUser(address indexed user);
    event BuyTicket(address indexed user,uint amount);
    event Draw(uint round);
    event Withdrawn(address indexed user, uint amount);
    event TakePrize(address indexed user, uint amount);


    constructor(address payable developerAddr, address payable marketingAddr, address payable drawCostAddr,uint _rand,uint _start) public {
        require(!isContract(developerAddr) && !isContract(marketingAddr) && !isContract(drawCostAddr));
        Developer = developerAddr;
        Marketing = marketingAddr;
        DrawCost = drawCostAddr;
        CONTRACT_LAUNCH_DATE = _start;
        LOTTERY_STATUS = true;
        newRAND(_rand);
        _init();
    }

    function _init() private {
        totalUsers = totalUsers.add(1);
        addrToUserId[msg.sender] = totalUsers;
        users[totalUsers].addr = msg.sender;
        users[totalUsers].lastActivity = block.timestamp;
        users[totalUsers].referrer = 0;

        totalRounds = totalRounds.add(1);
        rounds[totalRounds].startDate = CONTRACT_LAUNCH_DATE;
        LUCKY_NUMBERS = generateLuckyNumbers();
    }

    function buyTicket(uint referrerId,uint types, uint coupon,uint cnt,uint[] memory numbers) public payable {
        require(getRoundStatus()," Current Round is locked ");
        require(block.timestamp >= CONTRACT_LAUNCH_DATE, "Tickets Are Not Available Yet");
        require(types < TICKET_PRICES.length && types >= 0," Invalid Ticket Type ");
        require(coupon < COUPON.length.add(1)," Invalid Coupon ");
        require(cnt > 0 ," At least one ticket must be purchased ");
        require(cnt <= MAX_TICKET_BUY ," A maximum of 10 Tickets are allowed per purchase ");
        require(coupon == 0 || cnt == 1," Only one ticket is allowed to buy with coupons ");
        require(numbers.length.mod(TN) == 0 && numbers.length == cnt.mul(TN) && numbers.length > 0 ," Incorrect Ticket  ");
        for(uint i = 0; i < numbers.length; i++) {
            require(numbers[i] > 0 && numbers[i] <= TOTAL_NUMBERS," Incorrect number in the ticket ");
        }
        uint amount = msg.value;
        uint userId = addrToUserId[msg.sender]; 
        //New User
        if(userId == 0){
            userId = _addUser(msg.sender,referrerId);
            emit NewUser(msg.sender);
        }
        else{
            users[userId].lastActivity = block.timestamp;
        }

        if(coupon > 0){
            _buyTicketWithCoupon(userId,amount,types,coupon,numbers);
        }else{
            _buyTicket(userId,amount,types,cnt,numbers);
        }

        totalSales = totalSales.add(amount);
        jackpot = jackpot.add(amount.mul(JACKPOT_RATE).div(DIVIDER));
        silverspot = silverspot.add(amount.mul(SILVERSPOT_RATE).div(DIVIDER));
        Developer.transfer(amount.mul(DEVELOPER_RATE).div(DIVIDER));
        Marketing.transfer(amount.mul(MARKETING_RATE).div(DIVIDER));
        DrawCost.transfer(amount.mul(DRAW_COST_RATE).div(DIVIDER));

        //Referral Commisions
        uint referralAmount = amount.mul(REFERENCE_RATE).div(DIVIDER);
        if(users[userId].referrer > 0){
			uint _ref1 = users[userId].referrer ;
            uint _ref2 = users[_ref1].referrer;
            uint _ref3 = users[_ref2].referrer;

            uint refAmount = amount.mul(REFERENCE_LEVEL1_RATE).div(DIVIDER);
            referralAmount = referralAmount.sub(refAmount);
            users[_ref1].walletBalance = users[_ref1].walletBalance.add(refAmount);
            users[_ref1].totalReferrals = users[_ref1].totalReferrals.add(refAmount);

            if (_ref2 > 0) {
                refAmount = amount.mul(REFERENCE_LEVEL2_RATE).div(DIVIDER);
                referralAmount = referralAmount.sub(refAmount);
                users[_ref2].walletBalance = users[_ref2].walletBalance.add(refAmount);
                users[_ref2].totalReferrals = users[_ref2].totalReferrals.add(refAmount);
            }
            if (_ref3 > 0) {
                refAmount = amount.mul(REFERENCE_LEVEL3_RATE).div(DIVIDER);
                referralAmount = referralAmount.sub(refAmount);
                users[_ref3].walletBalance = users[_ref3].walletBalance.add(refAmount);
                users[_ref3].totalReferrals = users[_ref3].totalReferrals.add(refAmount);
            }
        }
        //Remain Referral Commisions added to Jackpot
        if(referralAmount>0){
            jackpot = jackpot.add(referralAmount);
        }

        if(rounds[totalRounds].types == ROUND_NORMAL){
            if(jackpot >= Golden_Round || (totalRounds-LastJoG) > GOLDEN_A_W_JACKPOT ){
                rounds[totalRounds].types = ROUND_GOLDEN;
            }
        }
        emit BuyTicket(msg.sender,msg.value);
    }

    function _buyTicketWithCoupon(uint userId, uint amount, uint types, uint coupon, uint[] memory numbers) private {
        if(coupon < 7){
            require( users[userId].coupons[coupon.sub(1)] > 0 , " User hasn't a coupon " );
        }
        else{
            uint couponLimit = LAUNCH_COUPON[0];
            if(rounds[totalRounds.sub(1)].types == ROUND_JACKPOT || totalRounds == 1){
                couponLimit = LAUNCH_COUPON[1];
            }
            require( rounds[totalRounds].ticketCnt <= couponLimit , " Round Launch Coupons finished " );
        }
        uint ticketsPrice = TICKET_PRICES[types].sub(TICKET_PRICES[types].mul(COUPON[coupon.sub(1)]).div(DIVIDER));
        require(ticketsPrice == amount," Incorrect tickets price ");
        uint[TN] memory ticketNumbers;
        for(uint j=0; j < TN; j++){
            ticketNumbers[j] = numbers[j];
        }
        _addTicket(userId,types,ticketNumbers);
        if(coupon < 7){
            users[userId].coupons[coupon.sub(1)] = users[userId].coupons[coupon.sub(1)].sub(1);
        }
    }

    function _buyTicket(uint userId, uint amount, uint types, uint cnt, uint[] memory numbers) private {
        uint ticketsPrice = TICKET_PRICES[types].mul(cnt);
        require(ticketsPrice == amount," Incorrect tickets price ");
        for(uint i=0; i < cnt; i++){
            uint[TN] memory ticketNumbers;
            for(uint j=0; j < TN; j++){
                ticketNumbers[j] = numbers[(i*TN)+j];
            }
            if(ticketNumbers.length == TN){
                _addTicket(userId,types,ticketNumbers);
            }
        }
    }

    function _addUser(address addr, uint referrerId) private returns (uint) {
        if (referrerId > 0) {
            if (users[referrerId].ticketCnt == 0) {
                referrerId = 1;
            }
        } else {
            referrerId = 1;
        }

        totalUsers = totalUsers.add(1);
        addrToUserId[addr] = totalUsers;
        users[totalUsers].addr = addr;
        users[totalUsers].lastActivity = block.timestamp;
        users[totalUsers].referrer = referrerId;

        if (referrerId > 0) {
            uint _ref1 = referrerId;
            uint _ref2 = users[_ref1].referrer;
            uint _ref3 = users[_ref2].referrer;
            users[_ref1].refs[0] = users[_ref1].refs[0].add(1);
            if (_ref2 > 0) {
                users[_ref2].refs[1] = users[_ref2].refs[1].add(1);
            }
            if (_ref3 > 0) {
                users[_ref3].refs[2] = users[_ref3].refs[2].add(1);
            }
        }
        return totalUsers;
    }

    function _addTicket(uint userId, uint types, uint[TN] memory numbers) private {
        for(uint i=0; i < numbers.length; i++){
            require(getCntInArray(numbers, numbers[i]) == 1," Duplicate number is not allowed ");
        }

        totalTickets = totalTickets.add(1);
        tickets[totalTickets].userId = userId;
        tickets[totalTickets].types = types;
        tickets[totalTickets].numbers = numbers;
        tickets[totalTickets].startRound = totalRounds;
        tickets[totalTickets].endRound = (totalRounds.add(TICKET_ROUNDS[types])).sub(1);
        totalActiveTickets = totalActiveTickets.add(1);
        activeTickets[totalActiveTickets] = totalTickets;
        users[userId].ticketCnt++;
        rounds[totalRounds].ticketCnt++;
    }

    function drawNumbers() public {
        require(getDrawStatus()," Current Round is not finished yet ");
        require(RoundStatus == 0," Not Available ");
        rounds[totalRounds].numbers = LUCKY_NUMBERS;
        rounds[totalRounds].jackpot = jackpot;
        rounds[totalRounds].silverspot = silverspot;
        RoundStatus = 1;
    }

    function drawTickets() public {
        if(totalActiveTickets > RoundIndex){
            uint[TN] memory lucky = LUCKY_NUMBERS;
            uint matchNumber=0;

            uint end = RoundIndex + ROUND_STEP;
            if(end >= totalActiveTickets){
                end = totalActiveTickets;
                if(RoundStatus == 1){
                    RoundStatus = 2;
                }
            }
            uint ticketId=0;
            for(uint i=RoundIndex+1; i <= end; i++){
                ticketId=activeTickets[i];
                if(ticketId>0){
                    if(tickets[ticketId].startRound <= totalRounds && tickets[ticketId].endRound >= totalRounds){
                        matchNumber = getMatchNumber(lucky,tickets[ticketId].numbers);
                        if(matchNumber > 1){
                            rounds[totalRounds].winners[matchNumber.sub(1)]+= 1;
                        }
                    }
                    else{
                        activeTickets[i] = activeTickets[totalActiveTickets];
                        if(totalActiveTickets <= end){
                            activeTickets[totalActiveTickets]=0;
                        }
                        totalActiveTickets--;
                        ticketId=activeTickets[i];
                        if(tickets[ticketId].startRound <= totalRounds && tickets[ticketId].endRound >= totalRounds){
                            matchNumber = getMatchNumber(lucky,tickets[ticketId].numbers);
                            if(matchNumber > 1){
                                rounds[totalRounds].winners[matchNumber.sub(1)]+= 1;
                            }
                        }
                    }
                }
                else{
                    break;
                }
            }
            if(totalActiveTickets<end){
                RoundIndex = totalActiveTickets;
            }
            else{
                RoundIndex = end;
            }
        }
        else{
            if(RoundStatus == 1){
                    RoundStatus = 2;
                }
        }
    }    

    function drawRound() public {
        require(getDrawStatus()," Current Round is not finished yet ");
        require(RoundStatus == 2," Not Available ");
        rounds[totalRounds].activeTicketCnt = totalActiveTickets;
        uint roundType = rounds[totalRounds].types;


        //Jackpot
        if(rounds[totalRounds].winners[5] > 0 ){
            totalJackpots = totalJackpots.add(1);
            Golden_Round = GOLDEN_ROUND_DEFAULT;
            rounds[totalRounds].types = ROUND_JACKPOT;
            totalActiveTickets = 0;
            totalGoldenRounds = 0;
            LastJoG = totalRounds;
            uint maintenance = jackpot.mul(JACKPOT_MAINTENANCE_RATE).div(DIVIDER);
            if(totalJackpots == JACKPOT_REFRESH){
                maintenance = maintenance.add(jackpot.mul(JACKPOT_TRANSFER_RATE).div(DIVIDER));
                jackpot = 0;
                LOTTERY_STATUS = false;
                totalJackpots=0;
            }
            else{
                jackpot = jackpot.mul(JACKPOT_TRANSFER_RATE).div(DIVIDER);
            }
            DrawCost.transfer(maintenance);
        }
        else{
            if(roundType == ROUND_GOLDEN){
                totalGoldenRounds = totalGoldenRounds.add(1);
                if(totalGoldenRounds == GOLDEN_ROUND_REFRESH){
                    LOTTERY_STATUS = false;
                    totalGoldenRounds=0;
                }
                
                if(jackpot > GOLDEN_ROUND_DEFAULT){
                    Golden_Round = jackpot;
                }
                uint transferAmount = jackpot.mul(GOLDEN_ROUND_RATE).div(DIVIDER);
                jackpot = jackpot.sub(transferAmount);
                silverspot = silverspot.add(transferAmount);
                rounds[totalRounds].jackpot = jackpot;
                rounds[totalRounds].silverspot = silverspot;
                LastJoG = totalRounds;
            }
            else{
                if(Golden_Round > GOLDEN_ROUND_DEFAULT){
                    Golden_Round = Golden_Round.sub(Golden_Round.mul(GOLDEN_ROUND_RETURN).div(DIVIDER));
                    if(Golden_Round < GOLDEN_ROUND_DEFAULT){
                        Golden_Round = GOLDEN_ROUND_DEFAULT;
                    }
                }
            }
        }

        uint silverspotPrize = 1000;
        if(rounds[totalRounds].winners[4] > 0 ){
            silverspotPrize = silverspotPrize.sub(SILVERSPOT_WINNER5_RATE);
        }
        if(rounds[totalRounds].winners[3] > 0 ){
            silverspotPrize = silverspotPrize.sub(SILVERSPOT_WINNER4_RATE);
        }
        if(rounds[totalRounds].winners[2] > 0 ){
            silverspotPrize = silverspotPrize.sub(SILVERSPOT_WINNER3_RATE);
        }

        if(silverspotPrize > 0){
            silverspot = silverspot.mul(silverspotPrize).div(DIVIDER);
        }
        else{
            silverspot =0;
        }

        if(LOTTERY_STATUS){
            uint nextStartDate = rounds[totalRounds].startDate + ROUND_DURATION_NORMAL;
            if(roundType == ROUND_GOLDEN){
                nextStartDate = rounds[totalRounds].startDate + ROUND_DURATION_GOLDEN;
            }
            if(block.timestamp > nextStartDate){
                nextStartDate = block.timestamp;
            }
            totalRounds = totalRounds.add(1);
            rounds[totalRounds].startDate = nextStartDate;
            emit Draw(totalRounds);
            RoundStatus = 0;
            RoundIndex = 0;
            LUCKY_NUMBERS = generateLuckyNumbers();
        }
    }

    function startNewRound() public onlyOwner {
        require(LOTTERY_STATUS == false," Lottery is active ");
        uint nextStartDate = rounds[totalRounds].startDate + ROUND_DURATION_NORMAL;
        if(block.timestamp > nextStartDate){
            nextStartDate = block.timestamp;
        }
        totalRounds = totalRounds.add(1);
        rounds[totalRounds].startDate = nextStartDate;
        RoundStatus = 0;
        RoundIndex = 0;
        LUCKY_NUMBERS = generateLuckyNumbers();
    }

    function updateJackpot() public onlyOwner {
        require(LOTTERY_STATUS == false," Lottery is active ");
        if(address(this).balance > silverspot){
            jackpot = address(this).balance.sub(silverspot);
        }
    }

    function transferContract() public onlyOwner {
        require(LOTTERY_STATUS == false," Lottery is active ");
        require(address(this).balance <= ROUND_STOP_MAX_BALANCE," can not withdraw. balance is greater than 10k TRX ");
        DrawCost.transfer(address(this).balance);
        jackpot=0;
        silverspot=0;
    }

    function takePrize(uint ticketId,uint roundId) public{
        require(roundId < totalRounds,"Wrong round");
        require(tickets[ticketId].startRound <= roundId && tickets[ticketId].endRound >= roundId,"Wrong ticket or round");
        uint userId = tickets[ticketId].userId;
        
        if(wins[roundId].tickets[ticketId] == false){
            (uint matchNumber, uint amount,) = getPrize(ticketId,roundId);

            if(matchNumber > 1 ){
                wins[roundId].tickets[ticketId] = true;
                users[userId].coupons[matchNumber.sub(1)] = users[userId].coupons[matchNumber.sub(1)].add(1);
                if(matchNumber == 6){
                    uint referralAmount = rounds[roundId].jackpot.mul(JACKPOT_REFERENCE_RATE).div(DIVIDER).div(rounds[roundId].winners[5]);
                    uint prizeRef = referralAmount;
                    if(users[userId].referrer > 0){
                        uint _ref1 = users[userId].referrer ;
                        uint _ref2 = users[_ref1].referrer;
                        uint _ref3 = users[_ref2].referrer;

                        uint refAmount = prizeRef.mul(REFERENCE_LEVEL1_RATE).div(REFERENCE_RATE);
                        referralAmount = referralAmount.sub(refAmount);
                        users[_ref1].walletBalance = users[_ref1].walletBalance.add(refAmount);
                        users[_ref1].totalReferrals = users[_ref1].totalReferrals.add(refAmount);
                        if (_ref2 > 0) {
                            refAmount = prizeRef.mul(REFERENCE_LEVEL2_RATE).div(REFERENCE_RATE);
                            referralAmount = referralAmount.sub(refAmount);
                            users[_ref2].walletBalance = users[_ref2].walletBalance.add(refAmount);
                            users[_ref2].totalReferrals = users[_ref2].totalReferrals.add(refAmount);
                        }
                        if (_ref3 > 0) {
                            refAmount = referralAmount;
                            referralAmount = 0;
                            users[_ref3].walletBalance = users[_ref3].walletBalance.add(refAmount);
                            users[_ref3].totalReferrals = users[_ref3].totalReferrals.add(refAmount);
                        }
                    }
                    if(referralAmount > 0){
                        amount = amount.add(referralAmount);
                    }
                }
                if(amount > 0){
                    users[userId].walletBalance = users[userId].walletBalance.add(amount);
                }
                emit TakePrize(users[userId].addr,amount);
            }
        }
    }

    function takeAllPrizes(uint[] memory ticketId,uint[] memory roundId) public{
        require(ticketId.length == roundId.length,"wrong numbers");
        require(ticketId.length <= 10,"wrong numbers");
        for(uint i=0; i<ticketId.length; i++){
            require(roundId[i] < totalRounds,"Wrong round");
            require(tickets[ticketId[i]].startRound <= roundId[i] && tickets[ticketId[i]].endRound >= roundId[i],"Wrong ticket or round");
            
            if(wins[roundId[i]].tickets[ticketId[i]] == false){
            uint userId = tickets[ticketId[i]].userId;
                (uint matchNumber, uint amount,) = getPrize(ticketId[i],roundId[i]);
                if(matchNumber > 1 ){
                    wins[roundId[i]].tickets[ticketId[i]] = true;
                    users[userId].coupons[matchNumber.sub(1)] = users[userId].coupons[matchNumber.sub(1)].add(1);
                    if(matchNumber == 6){
                        uint referralAmount = rounds[roundId[i]].jackpot.mul(JACKPOT_REFERENCE_RATE).div(DIVIDER).div(rounds[roundId[i]].winners[5]);
                        uint prizeRef = referralAmount;
                        if(users[userId].referrer > 0){
                            uint _ref1 = users[userId].referrer ;
                            uint _ref2 = users[_ref1].referrer;
                            uint _ref3 = users[_ref2].referrer;

                            uint refAmount = prizeRef.mul(REFERENCE_LEVEL1_RATE).div(REFERENCE_RATE);
                            referralAmount = referralAmount.sub(refAmount);
                            users[_ref1].walletBalance = users[_ref1].walletBalance.add(refAmount);
                            users[_ref1].totalReferrals = users[_ref1].totalReferrals.add(refAmount);
                            if (_ref2 > 0) {
                                refAmount = prizeRef.mul(REFERENCE_LEVEL2_RATE).div(REFERENCE_RATE);
                                referralAmount = referralAmount.sub(refAmount);
                                users[_ref2].walletBalance = users[_ref2].walletBalance.add(refAmount);
                                users[_ref2].totalReferrals = users[_ref2].totalReferrals.add(refAmount);
                            }
                            if (_ref3 > 0) {
                                refAmount = referralAmount;
                                referralAmount = 0;
                                users[_ref3].walletBalance = users[_ref3].walletBalance.add(refAmount);
                                users[_ref3].totalReferrals = users[_ref3].totalReferrals.add(refAmount);
                            }
                        }
                        if(referralAmount > 0){
                            amount = amount.add(referralAmount);
                        }
                    }
                    if(amount > 0){
                        users[userId].walletBalance = users[userId].walletBalance.add(amount);
                    }
                }
            }
        }
    }

    function getPrize(uint ticketId, uint roundId) public view returns(uint,uint,bool){
        require(roundId < totalRounds,"Wrong round");
        require(tickets[ticketId].startRound <= roundId && tickets[ticketId].endRound >= roundId,"Wrong ticket or round");
        uint amount = 0;
        uint matchNumbers = getMatchNumber(rounds[roundId].numbers,tickets[ticketId].numbers);
        if(matchNumbers == 6){
            amount =  rounds[roundId].jackpot.mul(JACKPOT_WINNER_RATE).div(DIVIDER).div(rounds[roundId].winners[5]);
        }
        if(matchNumbers == 5){
            amount =  rounds[roundId].silverspot.mul(SILVERSPOT_WINNER5_RATE).div(DIVIDER).div(rounds[roundId].winners[4]);
        }
        if(matchNumbers == 4){
            amount =  rounds[roundId].silverspot.mul(SILVERSPOT_WINNER4_RATE).div(DIVIDER).div(rounds[roundId].winners[3]);
        }
        if(matchNumbers == 3){
            amount =  rounds[roundId].silverspot.mul(SILVERSPOT_WINNER3_RATE).div(DIVIDER).div(rounds[roundId].winners[2]);
        }
        return (matchNumbers,amount,wins[roundId].tickets[ticketId]);
    }

    function getMatchNumber(uint[TN] memory arrA, uint[TN] memory arrB) private pure returns(uint){
        uint cnt=0;
        for(uint i=0; i < arrA.length; i++){
            for(uint j=0; j < arrB.length; j++){
                if(arrA[i] == arrB[j]){
                    cnt++;
                }
            }
        }
        return cnt;
    }

    function generateLuckyNumbers() private returns(uint[TN] memory){
        uint[TN] memory lucky;
        for(uint i=0; i < TN; i++){
            while(true){
                RAND = random();
                lucky[i]= (random().mod(TOTAL_NUMBERS)).add(1);
                if(getCntInArray(lucky,lucky[i])==1){
                    break;
                }
            }
        }
        return lucky;
    }

    function withdraw() public {
        uint userId = addrToUserId[msg.sender];
        require(userId > 0, " Invalid User ");
        uint amount = users[userId].walletBalance;
        if(amount > 0){
            if(amount > address(this).balance){
                amount = address(this).balance;
            }
            totalWithdrawn = totalWithdrawn.add(amount);
            users[userId].walletBalance = 0;
            users[userId].totalWithdrawn = users[userId].totalWithdrawn.add(amount);
            users[userId].lastActivity = block.timestamp;
            msg.sender.transfer(amount);
            emit Withdrawn(msg.sender, amount);
        }
    }

    function setName(uint userId,string memory name) public {
        users[userId].name = name;
    }

    function getUserNameById(uint userId) public view returns(string memory,address) {
        return (users[userId].name,users[userId].addr);
    }

    function getRoundStatus() public view returns(bool){
        uint duration = ROUND_DURATION_NORMAL;
        if(rounds[totalRounds].types == ROUND_GOLDEN){
            duration = ROUND_DURATION_GOLDEN;
        }
        if(block.timestamp > (rounds[totalRounds].startDate.add(LOCK_DURATION)) && block.timestamp < (rounds[totalRounds].startDate.add(duration)).sub(LOCK_DURATION) ){
            return true;
        }
        return false;
    }

    function getDrawStatus() public view returns(bool){
        uint duration = ROUND_DURATION_NORMAL;
        if(rounds[totalRounds].types == ROUND_GOLDEN){
            duration = ROUND_DURATION_GOLDEN;
        }
        if( block.timestamp > (rounds[totalRounds].startDate.add(duration)).sub(LOCK_DURATION) ){
            return true;
        }
        return false;
    }

    function getUserInfo(uint userId) public view returns(uint,uint[TN] memory,uint,uint,uint,uint,uint){
        return (
            users[userId].ticketCnt,
            users[userId].coupons,
            users[userId].lastActivity,
            users[userId].totalPaid,
            users[userId].totalWithdrawn,
            users[userId].totalReferrals,
            users[userId].walletBalance
        );
    }

    function getUserInfoRef(uint userId) public view returns(uint,uint[3] memory){
        return (
            users[userId].referrer,
            users[userId].refs
        );
    }

    function getTicketInfo(uint ticketId) public view returns(uint,uint,uint,uint,uint[TN] memory){
        return (
            tickets[ticketId].userId,
            tickets[ticketId].types,
            tickets[ticketId].startRound,
            tickets[ticketId].endRound,
            tickets[ticketId].numbers
        );
    }

    function getRoundInfo(uint roundId) public view returns(uint,uint,uint,uint,uint,uint){
        return (
            rounds[roundId].startDate,
            rounds[roundId].types,
            rounds[roundId].jackpot,
            rounds[roundId].silverspot,
            rounds[roundId].ticketCnt,
            rounds[roundId].activeTicketCnt
        );
    }

    function getRoundWinners(uint roundId) public view returns(uint[TN] memory){
        require(roundId < totalRounds,"Wrong round");
        return (
            rounds[roundId].winners
        );
    }

    function getRoundWinnersCnt(uint roundId) public view returns(uint){
        require(roundId < totalRounds,"Wrong round");
        uint cnt = rounds[roundId].winners[1]+rounds[roundId].winners[2]+
        rounds[roundId].winners[3]+rounds[roundId].winners[4]+rounds[roundId].winners[5];
        return cnt;
    }

    function getRoundNumbers(uint roundId) public view returns(uint[TN] memory){
        return rounds[roundId].numbers;
    }

    function getRoundTicketCnt(uint roundId) public view returns(uint){
        return rounds[roundId].ticketCnt;
    }

    function getUserIdByAddr(address addr) public view returns(uint){
        return addrToUserId[addr];
    }

    function getCntInArray(uint[TN] memory arr, uint num) private pure returns(uint){
        uint cnt=0;
        for(uint i=0; i < arr.length; i++){
            if(arr[i] == num){
                cnt++;
            }
        }
        return cnt;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, RAND)));
    }

    function newRAND(uint _rand) public {
        RAND = uint(keccak256(abi.encodePacked(block.timestamp, RAND,_rand)));
    }

    function isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getTotalSales() public view onlyOwner returns(uint){
        return totalSales;
    }

    function getDeveloper() public view onlyOwner returns(address){
        return Developer;
    }

    function setDeveloper(address payable DeveloperAddr) public onlyOwner {
        require(!isContract(DeveloperAddr),"Address is not valid");
        Developer = DeveloperAddr;
    }

    function getMarketing() public view onlyOwner returns(address){
        return Marketing;
    }

    function setMarketing(address payable MarketingAddr) public onlyOwner {
        require(!isContract(MarketingAddr),"Address is not valid");
        Marketing = MarketingAddr;
    }

    function getDrawCost() public view onlyOwner returns(address){
        return DrawCost;
    }

    function setDrawCost(address payable DrawCostAddr) public onlyOwner {
        require(!isContract(DrawCostAddr),"Address is not valid");
        DrawCost = DrawCostAddr;
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

    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if(b >= a){
            return 0;
        }
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}