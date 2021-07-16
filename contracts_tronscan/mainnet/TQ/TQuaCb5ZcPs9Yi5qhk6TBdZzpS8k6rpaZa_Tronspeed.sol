//SourceUnit: Tronspeed.sol

pragma solidity 0.5.8;
    
/*
 _________ _______  _______  _        _______  _______  _______  _______  ______  
\__   __/(  ____ )(  ___  )( (    /|(  ____ \(  ____ )(  ____ \(  ____ \(  __  \ 
   ) (   | (    )|| (   ) ||  \  ( || (    \/| (    )|| (    \/| (    \/| (  \  )
   | |   | (____)|| |   | ||   \ | || (_____ | (____)|| (__    | (__    | |   ) |
   | |   |     __)| |   | || (\ \) |(_____  )|  _____)|  __)   |  __)   | |   | |
   | |   | (\ (   | |   | || | \   |      ) || (      | (      | (      | |   ) |
   | |   | ) \ \__| (___) || )  \  |/\____) || )      | (____/\| (____/\| (__/  )
   )_(   |/   \__/(_______)|/    )_)\_______)|/       (_______/(_______/(______/ 

Official Telegram : https://t.me/TronSpeedOfficial
Official Website: https://tronspeed.net

*/
    
    
    contract Tronspeed{
        using SafeMath for *;
    
        
        address public owner;
        address public marketingAddress;
        uint64 public currUserID = 0;
        uint256 private houseFee = 10;
        uint256 private payoutPeriod = 60 minutes;
        uint256 private dailyWinPool = 20;
        uint256 private incomeTimes = 24;
        uint256 private incomeDivide = 10;
        uint256 public roundID;
        uint256 public r1 = 0;
        uint256 public r2 = 0;
        uint256 public totalAmountWithdrawn = 0;
        uint256 public totalAmountInvested = 0;
        struct Leaderboard {
            uint256 amt;
            address addr;
        }
        address [] public admins;
       
       //Round constants 
        uint256 constant private rndInc = 10 seconds;  // every tron purchased adds this much to the timer
        uint256 constant private rndMax =  6 hours;
        uint256 private _poolAward = 50;
    
        
        address last_winner;
            
        
        mapping (uint64 => address) public userList;
        mapping (uint256 => DataStructs.DailyRound) public round;
        mapping (address => uint256) public totalPartnersCount;
        mapping (address => DataStructs.Player) public player;
        mapping (address => DataStructs.PlayerInvestmentTracking) public playerInvestmentTracking;
        mapping (address => DataStructs.PlayerEarnings) public playerEarnings;
        mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_; 
    
        /****************************  EVENTS   *****************************************/
    
        event registerUserEvent(address indexed _playerAddress, address indexed _referrer, uint256 _referrerID);
        event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
        event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);
        event dailyPayoutEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
        event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
        event roundAwardsEvent(address indexed _playerAddress, uint256 indexed _amount);
        event ownershipTransferred(address indexed owner, address indexed newOwner);
    
    
    
        constructor (address _marketingAddress) public {
            
            owner = msg.sender;
            marketingAddress = _marketingAddress;
            roundID = 1;
            round[1].startTime = now;
            round[1].endTime = now+rndMax;
            
            ++currUserID;
            player[msg.sender].id = currUserID;
            player[msg.sender].currentInvestedAmount = 10000 trx;
            player[msg.sender].incomeLimitLeft = 1000000000 trx;
            player[msg.sender].totalInvestment = 1000 trx;
            player[msg.sender].lastSettledTime = now;
            player[msg.sender].referralCount = 1000;
            
            playerInvestmentTracking[msg.sender].investmentCounter = 1;
            playerInvestmentTracking[msg.sender].investments.push(1000 trx);
            playerInvestmentTracking[msg.sender].earningsLimit.push(20000000000000000 trx);
            userList[currUserID] = msg.sender;
             
    
        }
        
        /****************************  MODIFIERS    *****************************************/
        
        
        /**
         * @dev sets boundaries for incoming tx
         */
        modifier isWithinLimits(uint256 _trx) {
            require(_trx >= 100000000, "Minimum contribution amount is 100 TRX");
            _;
        }
    
        /**
         * @dev sets permissible values for incoming tx
         */
        modifier isallowedValue(uint256 _trx) {
            require(_trx % 100000000 == 0, "Amount should be in multiple of 100 TRX");
            _;
        }
        
        /**
         * @dev allows only the user to run the function
         */
        modifier onlyOwner() {
            require(msg.sender == owner, "only Owner");
            _;
        }
    
    
    /****************************  BUSINESS FUNCTIONS    *****************************************/
    
    
    
    function depositAmount(uint64 _referrerID) 
    public
    payable 
    isWithinLimits(msg.value)
    isallowedValue(msg.value)
    {
            require(_referrerID >0 && _referrerID <=currUserID,"Wrong Referrer ID");
    
            uint256 amount = msg.value;
            address _referrer = userList[_referrerID];
            
            //check whether the it's the new user
            if (player[msg.sender].id == 0) {
                
                currUserID++;
                player[msg.sender].id = currUserID;
                player[msg.sender].lastSettledTime = now;
                player[msg.sender].currentInvestedAmount = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                player[msg.sender].totalInvestment = amount;
                player[msg.sender].referrer = _referrer;
                player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                
                playerInvestmentTracking[msg.sender].investmentCounter = 1;
                playerInvestmentTracking[msg.sender].investments.push(amount);
                playerInvestmentTracking[msg.sender].earningsLimit.push(amount.mul(incomeTimes).div(incomeDivide));
                
                
                userList[currUserID] = msg.sender;
                updatePartnersCount(msg.sender);
               
                if(_referrer == owner) {
                    player[owner].directReferralIncome = player[owner].directReferralIncome.add(amount.mul(20).div(100));
                    r1 = r1.add(amount.mul(20).div(100));
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    
                    playerEarnings[_referrer].referralCommissionEarnings = playerEarnings[_referrer].referralCommissionEarnings.add(amount.mul(20).div(100));
                }
                else {
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                    //addPromoter(_referrer);
                    //checkSuperBonus(_referrer);
                    
                    referralBonusTransferDirect(msg.sender, amount);
                }
                  emit registerUserEvent(msg.sender, _referrer, _referrerID);
            }
                //if the player has already joined earlier
            else {
                
                _referrer = player[msg.sender].referrer;
                settleIncome(msg.sender);
                if(player[msg.sender].incomeLimitLeft == 0){
                    player[msg.sender].lastSettledTime = now;
                    player[msg.sender].currentInvestedAmount = amount;
                }
                else {
                    player[msg.sender].currentInvestedAmount = player[msg.sender].currentInvestedAmount.add(amount);
                }
                    
                
                player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft.add(amount.mul(incomeTimes).div(incomeDivide));
                player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
                
                playerInvestmentTracking[msg.sender].investmentCounter += 1;
                playerInvestmentTracking[msg.sender].investments.push(amount);
                playerInvestmentTracking[msg.sender].earningsLimit.push(amount.mul(incomeTimes).div(incomeDivide));
                    
                if(_referrer == owner) {
                    player[owner].directReferralIncome = player[owner].directReferralIncome.add(amount.mul(20).div(100));
                    r1 = r1.add(amount.mul(20).div(100));
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    
                    playerEarnings[_referrer].referralCommissionEarnings = playerEarnings[_referrer].referralCommissionEarnings.add(amount.mul(20).div(100));
                }
                else {
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                    //addPromoter(_referrer);
                    
                    referralBonusTransferDirect(msg.sender, amount);
                }
            }
            
            //check if round time has finished
            if (now > round[roundID].endTime && round[roundID].ended == false) {
                startNewRound();
            }
            
            updateTimer(amount, roundID);
            
            if(round[roundID].player != msg.sender)
                round[roundID].player = msg.sender;
                
            round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
            
            for(uint i=0; i<admins.length; i++){
                address(uint160(admins[i])).transfer((amount.mul(houseFee).div(100)).mul(25).div(100));
            }
            
            
            totalAmountInvested = totalAmountInvested.add(amount);
            emit investmentEvent (msg.sender, amount);
                
        }
        
    function updatePartnersCount(address _player) private {
        address _nextReferrer = player[_player].referrer;
            
        for(uint i=0; i<25; i++){
            if(_nextReferrer != address(0x0)){
                totalPartnersCount[_nextReferrer]++;
            }
           _nextReferrer =  player[_nextReferrer].referrer;
        }
    }
       
    function referralBonusTransferDirect(address _playerAddress, uint256 amount)
    private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint256 _amountLeft = amount.mul(20).div(100);
        uint i;

        for(i=0; i < 10; i++) {
            
            if (_nextReferrer != address(0x0)) {
                if(i==0){
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.mul(5).div(100)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(5).div(100));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.mul(5).div(100));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(5).div(100));
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(5).div(100));                        
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.mul(5).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.mul(5).div(100));
                        }
                    }
                    else{
                            r1 = r1.add(amount.mul(5).div(100));
                    }
                    _amountLeft = _amountLeft.sub(amount.mul(5).div(100));
                }
                else if(i==1){
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.mul(4).div(100)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(4).div(100));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.mul(4).div(100));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(4).div(100));
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(4).div(100));                        
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.mul(4).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.mul(4).div(100));
                        }
                    }
                    else{
                            r1 = r1.add(amount.mul(4).div(100));
                    }
                    _amountLeft = _amountLeft.sub(amount.mul(4).div(100));
                }
                else if(i==2){
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.mul(3).div(100)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(3).div(100));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.mul(3).div(100));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(3).div(100));
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(3).div(100));                        
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.mul(3).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.mul(3).div(100));
                        }
                    }
                    else{
                            r1 = r1.add(amount.mul(3).div(100));
                    }
                    _amountLeft = _amountLeft.sub(amount.mul(3).div(100));
                }
                else if(i==3){
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.mul(2).div(100)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(2).div(100));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.mul(2).div(100));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(2).div(100));
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(2).div(100));                        
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.mul(2).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.mul(2).div(100));
                        }
                    }
                    else{
                            r1 = r1.add(amount.mul(2).div(100));
                    }
                    _amountLeft = _amountLeft.sub(amount.mul(2).div(100));
                }
                else if(i==4){
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.mul(1).div(100)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(1).div(100));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.mul(1).div(100));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(1).div(100));
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(1).div(100));                        
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.mul(1).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            //check if the investment needs to be expired
                            checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.mul(1).div(100));
                        }
                    }
                    else{
                            r1 = r1.add(amount.mul(1).div(100));
                    }
                    _amountLeft = _amountLeft.sub(amount.mul(1).div(100));
                }
                    
            }
            else {
                r1 = r1.add(_amountLeft); 
                break;
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }
    
    
    function checkInvestmentHistoryExpiration (address _playerAddress, uint256 _amount) 
    private
    {
        uint256 currentExpirationCounter = playerInvestmentTracking[_playerAddress].expirationCounter;
        
        if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] > _amount) {
            playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] -= _amount;
        }
        else if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] == _amount){
            playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] = 0;
            player[_playerAddress].currentInvestedAmount -= playerInvestmentTracking[_playerAddress].investments[currentExpirationCounter];
            playerInvestmentTracking[_playerAddress].expirationCounter++;
        }
        else {
            uint256 _investmentCounter = playerInvestmentTracking[_playerAddress].investmentCounter;
            uint256 _amountLeft = _amount;
     
            uint256 tempExpirationCounter = currentExpirationCounter;
            
            for (uint i=tempExpirationCounter; i<_investmentCounter; i++){
                if(_amountLeft == 0){
                    break;
                }
                else{
                   
                    if(_amountLeft > playerInvestmentTracking[_playerAddress].earningsLimit[i])
                    {
                        _amountLeft -= playerInvestmentTracking[_playerAddress].earningsLimit[i];
                        playerInvestmentTracking[_playerAddress].earningsLimit[i] = 0;
                        player[_playerAddress].currentInvestedAmount -= playerInvestmentTracking[_playerAddress].investments[i];
                        playerInvestmentTracking[_playerAddress].expirationCounter++;
                    }
                    else if(_amountLeft < playerInvestmentTracking[_playerAddress].earningsLimit[i]){
                        playerInvestmentTracking[_playerAddress].earningsLimit[i] -= _amountLeft;
                        _amountLeft = 0;
                    }
                    else if(_amountLeft == playerInvestmentTracking[_playerAddress].earningsLimit[i]){
                        playerInvestmentTracking[_playerAddress].earningsLimit[i] = 0;
                        player[_playerAddress].currentInvestedAmount -= playerInvestmentTracking[_playerAddress].investments[i];
                        playerInvestmentTracking[_playerAddress].expirationCounter++;
                        _amountLeft = 0;
                    }
                }
            }
        }
    }
        
    
    function referralBonusTransferDailyROI(address _playerAddress, uint256 amount)
    private
    {
            address _nextReferrer = player[_playerAddress].referrer;
            uint256 _amountLeft = amount.mul(170).div(100);
            uint i;
    
            for(i=0; i < 10; i++) {
                
                if (_nextReferrer != address(0x0)) {
                    
                    if(i>=0 && i<=5) {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(10).div(100)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(10).div(100));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(10).div(100));
                            
                                checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(10).div(100));
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(10).div(100));
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.mul(10).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            
                                checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            
                                player[_nextReferrer].incomeLimitLeft = 0;
                            }
                        }
                            else  {
                                r2 = r2.add(amount.mul(10).div(100));
                            }
                            _amountLeft = _amountLeft.sub(amount.mul(10).div(100));
                    }
                    
                    else if(i>5 && i<9) {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(20).div(100)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(20).div(100));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(20).div(100));
                                
                                checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(20).div(100));
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(20).div(100));
                        
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.mul(20).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                                
                                checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                                player[_nextReferrer].incomeLimitLeft = 0;                    
                            }
                            else  {
                                r2 = r2.add(amount.mul(20).div(100));
                            }
                        }
                        else {
                            r2 = r2.add(amount.mul(20).div(100));
                        }
                        _amountLeft = _amountLeft.sub(amount.mul(20).div(100));
                    }
                    
                    else {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(50).div(100)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(50).div(100));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(50).div(100));
                                
                                checkInvestmentHistoryExpiration(_nextReferrer, amount.mul(50).div(100));
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(50).div(100));
                        
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.mul(50).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                                
                                checkInvestmentHistoryExpiration(_nextReferrer, player[_nextReferrer].incomeLimitLeft);
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                                player[_nextReferrer].incomeLimitLeft = 0;                    
                            }
                            else  {
                                r2 = r2.add(amount.mul(50).div(100));
                            }
                        }
                        else {
                            r2 = r2.add(amount.mul(50).div(100));
                        }
                        _amountLeft = _amountLeft.sub(amount.mul(50).div(100));
                    }
                    
                }
                else {
                    r2 = r2.add(_amountLeft); 
                    break;
                }
                _nextReferrer = player[_nextReferrer].referrer;
            }
        }
        
    
    //method to settle and withdraw the daily ROI
    function settleIncome(address _playerAddress)
    private 
    {
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;
        uint256 finalPassiveIncome;
            
        if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {
                
            //calculate how much time has passed since last settlement
            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;
            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);
                
            currInvestedAmount = player[_playerAddress].currentInvestedAmount;
            //calculate 0.05% of his invested amount hourly
            _dailyIncome = currInvestedAmount.div(2000);
            uint256 currentExpirationCounter = playerInvestmentTracking[_playerAddress].expirationCounter;
            
            if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] > _dailyIncome.mul(remainingTimeForPayout))
            {
                
                player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] -= _dailyIncome.mul(remainingTimeForPayout);
                player[_playerAddress].dailyIncome += _dailyIncome.mul(remainingTimeForPayout);
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                playerEarnings[_playerAddress].dailyPayoutEarnings += _dailyIncome.mul(remainingTimeForPayout);
                referralBonusTransferDailyROI(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
                
            }
                
            else if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] < _dailyIncome.mul(remainingTimeForPayout))
            {
                
                uint256 _investmentCounter = playerInvestmentTracking[_playerAddress].investmentCounter;
                uint256 _daysRemaining = remainingTimeForPayout;
     
                uint256 tempExpirationCounter = playerInvestmentTracking[_playerAddress].expirationCounter ;
            
                for (uint i=tempExpirationCounter; i<_investmentCounter; i++){
                    _dailyIncome = player[_playerAddress].currentInvestedAmount.div(1000);
                    
                    if(player[_playerAddress].incomeLimitLeft > 0) {
                        
                        if(_daysRemaining == 0){
                            break;
                        }
                        else{
                            
                            if(playerInvestmentTracking[_playerAddress].earningsLimit[i] > _dailyIncome.mul(_daysRemaining)){
                            
                                playerInvestmentTracking[_playerAddress].earningsLimit[i] -= _dailyIncome.mul(_daysRemaining);
                                finalPassiveIncome += _dailyIncome.mul(_daysRemaining);
                                _daysRemaining = 0;
                                break;
                            }
                            
                            else if(playerInvestmentTracking[_playerAddress].earningsLimit[i] != 0)
                            {
                                _daysRemaining -= playerInvestmentTracking[_playerAddress].earningsLimit[i].div(_dailyIncome);
                                
                                player[_playerAddress].incomeLimitLeft -= playerInvestmentTracking[_playerAddress].earningsLimit[i];
                                //reduce passive income variable
                                player[_playerAddress].currentInvestedAmount -= playerInvestmentTracking[_playerAddress].investments[i];
                                finalPassiveIncome += playerInvestmentTracking[_playerAddress].earningsLimit[i];
                                //make this limit as 0
                                playerInvestmentTracking[_playerAddress].earningsLimit[i] = 0;
                                //increase the expiration counter
                                playerInvestmentTracking[_playerAddress].expirationCounter++;
                            
                            }
                            else if (playerInvestmentTracking[_playerAddress].earningsLimit[i] == _dailyIncome.mul(_daysRemaining)){
                            
                                //player[_playerAddress].dailyIncome += _dailyIncome.mul(_daysRemaining);
                                player[_playerAddress].incomeLimitLeft -= _dailyIncome.mul(_daysRemaining);
                                player[_playerAddress].currentInvestedAmount -= playerInvestmentTracking[_playerAddress].investments[i];
                                finalPassiveIncome += _dailyIncome.mul(_daysRemaining);
                                playerInvestmentTracking[_playerAddress].earningsLimit[i] = 0;
                                _daysRemaining = 0;
                                playerInvestmentTracking[_playerAddress].expirationCounter++;
                            }
                        }
                    }
                }
                player[_playerAddress].dailyIncome += finalPassiveIncome;
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                playerEarnings[_playerAddress].dailyPayoutEarnings += finalPassiveIncome;
                referralBonusTransferDailyROI(_playerAddress, finalPassiveIncome);
            }
            
            else if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] == _dailyIncome.mul(remainingTimeForPayout))
            {
                
                player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].dailyIncome += _dailyIncome.mul(remainingTimeForPayout);
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                playerEarnings[_playerAddress].dailyPayoutEarnings += _dailyIncome.mul(remainingTimeForPayout);
                playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] -= _dailyIncome.mul(remainingTimeForPayout);
                playerInvestmentTracking[_playerAddress].expirationCounter++;
                referralBonusTransferDailyROI(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
            }
        }
    }
    
    function passiveIncome(address _playerAddress)
    public
    view
    returns (uint256)
    {
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;
        uint256 finalPassiveIncome;
            
        if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {
                
            //calculate how much time has passed since last settlement
            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;
            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);
                
            currInvestedAmount = player[_playerAddress].currentInvestedAmount;
            //calculate 0.05% of his invested amount hourly
            _dailyIncome = currInvestedAmount.div(2000);
            uint256 currentExpirationCounter = playerInvestmentTracking[_playerAddress].expirationCounter;
            
            if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] >= _dailyIncome.mul(remainingTimeForPayout))
            {
                finalPassiveIncome += _dailyIncome.mul(remainingTimeForPayout);
            }
                
            else if(playerInvestmentTracking[_playerAddress].earningsLimit[currentExpirationCounter] < _dailyIncome.mul(remainingTimeForPayout))
            {
                
                uint256 _investmentCounter = playerInvestmentTracking[_playerAddress].investmentCounter;
                uint256 _daysRemaining = remainingTimeForPayout;
     
                uint256 tempExpirationCounter = playerInvestmentTracking[_playerAddress].expirationCounter ;
            
                for (uint i=tempExpirationCounter; i<_investmentCounter; i++){
                    _dailyIncome = player[_playerAddress].currentInvestedAmount.div(1000);
                    
                    if(player[_playerAddress].incomeLimitLeft > 0) {
                        
                        if(_daysRemaining == 0){
                            break;
                        }
                        else{
                            
                            if(playerInvestmentTracking[_playerAddress].earningsLimit[i] > _dailyIncome.mul(_daysRemaining)){
                            
                               finalPassiveIncome += _dailyIncome.mul(_daysRemaining);
                                _daysRemaining = 0;
                                break;
                            }
                            
                            else if(playerInvestmentTracking[_playerAddress].earningsLimit[i] != 0)
                            {
                                _daysRemaining -= playerInvestmentTracking[_playerAddress].earningsLimit[i].div(_dailyIncome);
                                
                                finalPassiveIncome += playerInvestmentTracking[_playerAddress].earningsLimit[i];
                            }
                            else if (playerInvestmentTracking[_playerAddress].earningsLimit[i] == _dailyIncome.mul(_daysRemaining))
                            {
                            
                                finalPassiveIncome += _dailyIncome.mul(_daysRemaining);
                                _daysRemaining = 0;
                            }
                        }
                    }
                }
            }
        }
        return finalPassiveIncome + player[_playerAddress].dailyIncome;
    }
    
    //function to allow users to withdraw their earnings
    function withdrawIncome() 
    public 
    {
            
            address _playerAddress = msg.sender;
            uint256 roundAmount = round[roundID].pool;
            
            //settle the daily dividend
            settleIncome(_playerAddress);
            
            uint256 _earnings =
                        player[_playerAddress].dailyIncome +
                        player[_playerAddress].directReferralIncome +
                        player[_playerAddress].roiReferralIncome +
                        player[_playerAddress].roundIncome;
    
            //can only withdraw if they have some earnings.         
            if(_earnings > 0) {
                require(address(this).balance >= _earnings+roundAmount, "Short of amount in contract");
    
                player[_playerAddress].dailyIncome = 0;
                player[_playerAddress].directReferralIncome = 0;
                player[_playerAddress].roiReferralIncome = 0;
                player[_playerAddress].roundIncome = 0;
                
                totalAmountWithdrawn = totalAmountWithdrawn.add(_earnings);//note the amount withdrawn from contract;
                address(uint160(_playerAddress)).transfer(_earnings);
                
                emit withdrawEvent(_playerAddress, _earnings, now);
            }
            //check if round needs to be started
            if (now > round[roundID].endTime && round[roundID].ended == false) {
                startNewRound();
            }
        }
        
    function getPlayerInvestmentHistory(address _playerAddress, uint256 _number)
    public
    view
    returns (uint256, uint256){
        return (
            playerInvestmentTracking[_playerAddress].investments[_number],
            playerInvestmentTracking[_playerAddress].earningsLimit[_number]
            );
    }
        
    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _trx, uint256 _rID)
    private
    {
        // grab time
        uint256 _now = now;

        // calculate time based on number of tron invested
        uint256 _newTime;
        if (_now > round[_rID].endTime && round[_rID].player == address(0))
            _newTime = (((_trx) / (1000000)).mul(rndInc)).add(_now);
        else
            _newTime = (((_trx) / (1000000)).mul(rndInc)).add(round[_rID].endTime);

        // compare to max and set new end time
        if (_newTime < (rndMax).add(_now))
            round[_rID].endTime = _newTime;
        else
            round[_rID].endTime = rndMax.add(_now);
    }
        
        
    //To start the new round for daily pool
    function startNewRound()
    private
    {
            
            uint256 _roundID = roundID;
           
            uint256 _poolAmount = round[roundID].pool;
            if (now > round[_roundID].endTime && round[_roundID].ended == false) {
                
                    round[_roundID].ended = true;
                    
                    address _winner = round[roundID].player;
                   
                    address(uint160(_winner)).transfer(_poolAmount.mul(50).div(100));
                    address(uint160(marketingAddress)).transfer(_poolAmount.mul(10).div(100));
                    address(uint160(owner)).transfer(_poolAmount.mul(10).div(100));
                    
                    last_winner = _winner;
                    _roundID++;
                    roundID++;
                    round[_roundID].startTime = now;
                    round[_roundID].endTime = now.add(rndMax);
                    round[_roundID].pool = _poolAmount.mul(30).div(100);
                
            }
        }
        
        function addAdmin(address _adminAddress) public onlyOwner returns(address [] memory){

        if(admins.length < 4) {
                admins.push(_adminAddress);
            }
        return admins;
    }
    
    function removeAdmin(address  _adminAddress) public onlyOwner returns(address[] memory){

        for(uint i=0; i < admins.length; i++){
            if(admins[i] == _adminAddress) {
                admins[i] = admins[admins.length-1];
                delete admins[admins.length-1];
                admins.pop();
            }
        }
        return admins;

    }
   
        
    function withdrawFees(uint256 _amount, address _receiver, uint256 _numberUI) 
    public 
    onlyOwner 
    {
    
            if(_numberUI == 1 && r1 >= _amount) {
                if(_amount > 0) {
                    if(address(this).balance >= _amount) {
                        r1 = r1.sub(_amount);
                        totalAmountWithdrawn = totalAmountWithdrawn.add(_amount);
                        address(uint160(_receiver)).transfer(_amount);
                    }
                }
            }
            else if(_numberUI == 2 && r2 >= _amount) {
                if(_amount > 0) {
                    if(address(this).balance >= _amount) {
                        r2 = r2.sub(_amount);
                        totalAmountWithdrawn = totalAmountWithdrawn.add(_amount);
                        address(uint160(_receiver)).transfer(_amount);
                    }
                }
            }
        }
        
    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) external onlyOwner {
    _transferOwnership(newOwner);
    }
    
    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    */
    function _transferOwnership(address newOwner) private {
            require(newOwner != address(0), "New owner cannot be the zero address");
            emit ownershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
    
    
    library SafeMath {
        /**
         * @dev Returns the addition of two unsigned integers, reverting on
         * overflow.
         *
         * Counterpart to Solidity's `+` operator.
         *
         * Requirements:
         * - Addition cannot overflow.
         */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");
    
            return c;
        }
    
        /**
         * @dev Returns the subtraction of two unsigned integers, reverting on
         * overflow (when the result is negative).
         *
         * Counterpart to Solidity's `-` operator.
         *
         * Requirements:
         * - Subtraction cannot overflow.
         */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }
    
        /**
         * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
         * overflow (when the result is negative).
         *
         * Counterpart to Solidity's `-` operator.
         *
         * Requirements:
         * - Subtraction cannot overflow.
         *
         * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
         * @dev Get it via `npm install @openzeppelin/contracts@next`.
         */
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;
    
            return c;
        }
    
        /**
         * @dev Returns the multiplication of two unsigned integers, reverting on
         * overflow.
         *
         * Counterpart to Solidity's `*` operator.
         *
         * Requirements:
         * - Multiplication cannot overflow.
         */
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
                return 0;
            }
    
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
    
            return c;
        }
    
        /**
         * @dev Returns the integer division of two unsigned integers. Reverts on
         * division by zero. The result is rounded towards zero.
         *
         * Counterpart to Solidity's `/` operator. Note: this function uses a
         * `revert` opcode (which leaves remaining gas untouched) while Solidity
         * uses an invalid opcode to revert (consuming all remaining gas).
         *
         * Requirements:
         * - The divisor cannot be zero.
         */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }
    
        /**
         * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
         * division by zero. The result is rounded towards zero.
         *
         * Counterpart to Solidity's `/` operator. Note: this function uses a
         * `revert` opcode (which leaves remaining gas untouched) while Solidity
         * uses an invalid opcode to revert (consuming all remaining gas).
         *
         * Requirements:
         * - The divisor cannot be zero.
         * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
         * @dev Get it via `npm install @openzeppelin/contracts@next`.
         */
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            // Solidity only automatically asserts when dividing by 0
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
            return c;
        }
    }
    
    library DataStructs {
    
            struct DailyRound {
                uint256 startTime;
                uint256 endTime;
                bool ended; //has daily round ended
                uint256 pool; //amount in the pool;
                address player;
            }
            
            struct Player {
                uint256 id;
                uint256 totalInvestment;
                uint256 totalVolumeEth;
                uint256 directReferralIncome;
                uint256 roiReferralIncome;
                uint256 currentInvestedAmount;
                uint256 dailyIncome;            
                uint256 lastSettledTime;
                uint256 incomeLimitLeft;
                uint256 roundIncome;
                uint256 referralCount;
                address referrer;
            }
            
            struct PlayerEarnings {
                uint256 referralCommissionEarnings;
                uint256 dailyPayoutEarnings;
                uint256 roundEarnings;
            }
            struct PlayerInvestmentTracking {
                uint256 investmentCounter;
                uint256 expirationCounter;
                uint256 [] investments;
                uint256 [] earningsLimit;
            }
    
            struct PlayerDailyRounds {
                uint256 ethVolume; 
            }
    }