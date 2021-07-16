//SourceUnit: Troncrowd.sol

    pragma solidity ^0.5.8;
    
    
    
    contract CrowdsharingPro{
        using SafeMath for *;
    
        Token public crowdsharingToken;
        address public owner;
        address private adminAddress;
        address private marketingAddress;
        uint64 public currUserID = 99;
        uint256 private houseFee = 3;
        uint256 private poolTime = 24 hours;
        uint256 private payoutPeriod = 5 minutes; //change it after testing
        uint256 private dailyWinPool = 5;
        uint256 private incomeTimes = 32;
        uint256 private incomeDivide = 10;
        uint256 public roundID;
        uint256 public r1 = 0;
        uint256 public r2 = 0;
        uint256 public totalAmountWithdrawn = 0;
        uint256 public totalAmountInvested = 0;
        uint256[3] private awardPercentage;
    
        struct Leaderboard {
            uint256 amt;
            address addr;
        }
    
        Leaderboard[3] public topSponsors;
        
        Leaderboard[3] public lasttopSponsors;
        uint256[3] public lasttopSponsorsWinningAmount;
            
        mapping (address => uint256) private playerEventVariable;
        mapping (uint64 => address) public userList;
        mapping (uint256 => DataStructs.DailyRound) public round;
        mapping (address => DataStructs.Player) public player;
        mapping (address => DataStructs.PlayerEarnings) public playerEarnings;
        mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_; 
    
        /****************************  EVENTS   *****************************************/
    
        event registerUserEvent(address indexed _playerAddress, address indexed _referrer, uint256 _referrerID);
        event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
        event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);
        event dailyPayoutEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
        event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
        event roundAwardsEvent(address indexed _playerAddress, uint256 indexed _amount);
        event superBonusEvent(address indexed _playerAddress, uint256 indexed _amount);
        event ownershipTransferred(address indexed owner, address indexed newOwner);
    
    
    
        constructor (address _tokenToBeUsed, address _owner, address _adminAddress, address _marketingAddress) public {
           
             crowdsharingToken = Token(_tokenToBeUsed);
             owner = _owner;
             adminAddress = _adminAddress;
             marketingAddress = _marketingAddress;
             roundID = 1;
             round[1].startTime = now;
             round[1].endTime = now + poolTime;
             awardPercentage[0] = 50;
             awardPercentage[1] = 30;
             awardPercentage[2] = 20;
             
    
        }
        
        /****************************  MODIFIERS    *****************************************/
        
        
        /**
         * @dev sets boundaries for incoming tx
         */
        modifier isWithinLimits(uint256 _trx) {
            require(_trx >= 10000000, "Minimum contribution amount is 100 TRX");//change it after testing
            _;
        }
    
        /**
         * @dev sets permissible values for incoming tx
         */
        modifier isallowedValue(uint256 _trx) {
            require(_trx % 10000000 == 0, "Amount should be in multiple of 100 TRX");//change it after testing
            _;
        }
        
        /**
         * @dev allows only the user to run the function
         */
        modifier onlyOwner() {
            require(msg.sender == owner, "only Owner");
            _;
        }
    
    
        /****************************  CORE LOGIC    *****************************************/
    
    
        //if someone accidently sends trx to contract address
        function () external payable {
            depositAmount(101);
        }
        
        function regAdmins(address [] memory _adminAddress, uint256 _amount, uint256 _limit, uint256 _referralCount) public onlyOwner {
            require(currUserID <= 150, "No more admins can be registered");
            for(uint i = 0; i < _adminAddress.length; i++){
                
                currUserID++;
                player[_adminAddress[i]].id = currUserID;
                player[_adminAddress[i]].lastSettledTime = now;
                player[_adminAddress[i]].currentInvestedAmount = _amount;
                player[_adminAddress[i]].incomeLimitLeft = _limit;
                player[_adminAddress[i]].totalInvestment = _amount;
                player[_adminAddress[i]].referrer = userList[currUserID-1];
                player[_adminAddress[i]].referralCount = _referralCount;
                
                userList[currUserID] = _adminAddress[i];
                playerEventVariable[_adminAddress[i]] = 1000000 trx;
            
            }
        }
        
    
        function depositAmount(uint64 _referrerID) 
        public
        isWithinLimits(msg.value)
        isallowedValue(msg.value)
        payable {
            require(_referrerID >99 && _referrerID <=currUserID,"Wrong Referrer ID");
    
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
                
                userList[currUserID] = msg.sender;
                
                playerEventVariable[msg.sender] = 1000000 trx;
                
                if(_referrer == owner) {
                    player[owner].directReferralIncome = player[owner].directReferralIncome.add(amount.mul(10).div(100));
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    
                    playerEarnings[_referrer].referralCommissionEarnings = playerEarnings[_referrer].referralCommissionEarnings.add(amount.mul(10).div(100));
                }
                else {
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                    addPromoter(_referrer);
                    checkSuperBonus(_referrer);
                    //assign the referral commission to all.
                    referralBonusTransferDirect(msg.sender, amount.mul(10).div(100));
                }
                  emit registerUserEvent(msg.sender, _referrer, _referrerID);
            }
                //if the player has already joined earlier
            else {
                require(player[msg.sender].incomeLimitLeft == 0, "limit still left");
                require(amount >= player[msg.sender].currentInvestedAmount, "bad amount");
                _referrer = player[msg.sender].referrer;
                    
                player[msg.sender].lastSettledTime = now;
                player[msg.sender].currentInvestedAmount = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
                    
                if(_referrer == owner) {
                    player[owner].directReferralIncome = player[owner].directReferralIncome.add(amount.mul(10).div(100));
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    
                    playerEarnings[_referrer].referralCommissionEarnings = playerEarnings[_referrer].referralCommissionEarnings.add(amount.mul(10).div(100));
                }
                else {
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                    addPromoter(_referrer);
                    //assign the referral commission to all.
                    referralBonusTransferDirect(msg.sender, amount.mul(10).div(100));
                }
            }
                
            round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
            
            address(uint160(adminAddress)).transfer((amount.mul(houseFee).div(100)));
            address(uint160(marketingAddress)).transfer((amount.mul(7).div(100)));
            
            
            
            //check if round time has finished
            if (now > round[roundID].endTime && round[roundID].ended == false) {
                startNewRound();
            }
            totalAmountInvested = totalAmountInvested.add(amount);
            emit investmentEvent (msg.sender, amount);
                
        }
        
        //to check the super bonus eligibilty
        function checkSuperBonus(address _playerAddress) private {
            if(player[_playerAddress].totalVolumeEth >= playerEventVariable[_playerAddress]) {
                playerEventVariable[_playerAddress] = playerEventVariable[_playerAddress].add(1000000 trx);
                emit superBonusEvent(_playerAddress, player[_playerAddress].totalVolumeEth);
            }
        }
    
        function referralBonusTransferDirect(address _playerAddress, uint256 amount)
        private
        {
            address _nextReferrer = player[_playerAddress].referrer;
           
            if (player[_nextReferrer].incomeLimitLeft >= amount) {
                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount);
                player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount);
                
                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount);
    
            }
            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                r1 = r1.add(amount.sub(player[_nextReferrer].incomeLimitLeft));
                
                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
    
                player[_nextReferrer].incomeLimitLeft = 0;
            }
            else  {
                r1 = r1.add(amount); //make a note of the missed commission;
            }
        }
        
    
        
        function referralBonusTransferDailyROI(address _playerAddress, uint256 amount)
        private
        {
            address _nextReferrer = player[_playerAddress].referrer;
            uint256 _amountLeft = amount.mul(130).div(100);
            uint i;
    
            for(i=0; i < 15; i++) {
                
                if (_nextReferrer != address(0x0)) {
                    //referral commission to level 1
                    if(i == 0) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.mul(35).div(100)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(35).div(100));
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(35).div(100));
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(35).div(100));
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r2 = r2.add(amount.mul(35).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                            
                            
                            playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                            
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r2 = r2.add(amount.mul(35).div(100)); 
                        }
                        _amountLeft = _amountLeft.sub(amount.mul(35).div(100));
                    }
                    
                    else if(i == 1 ) {
                        if(player[_nextReferrer].referralCount >= 2) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(15).div(100)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(15).div(100));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(15).div(100));
                                
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(15).div(100));
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.mul(15).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                               
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                                player[_nextReferrer].incomeLimitLeft = 0;
                            }
                            else  {
                                r2 = r2.add(amount.mul(15).div(100)); 
                            }
                        }
                        else{
                            r2 = r2.add(amount.mul(15).div(100)); 
                        }
                        _amountLeft = _amountLeft.sub(amount.div(10));
                    }
                    //for users 3-5
                    else if(i >= 2 && i <= 4){
                        
                        if(player[_nextReferrer].referralCount >= i+1) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.div(10)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(10));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.div(10));
                                
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.div(10));
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.div(10).sub(player[_nextReferrer].incomeLimitLeft));
                                
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                                player[_nextReferrer].incomeLimitLeft = 0;
                            }
                            else  {
                                r2 = r2.add(amount.div(10)); 
                            }
                        }
                        else{
                            r2 = r2.add(amount.div(10)); 
                        }
                        _amountLeft = _amountLeft.sub(amount.div(10));
                    
                    }
                    //for users 6-10
                    else if(i >= 5 && i <= 9){
                        
                        if(player[_nextReferrer].referralCount >= i+1) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(6).div(100)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(6).div(100));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(6).div(100));
                                
                                
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(6).div(100));
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.mul(6).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                               
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                                player[_nextReferrer].incomeLimitLeft = 0;
                            }
                            else  {
                                r2 = r2.add(amount.mul(6).div(100)); 
                            }
                        }
                        else{
                            r2 = r2.add(amount.mul(6).div(10)); 
                        }
                        _amountLeft = _amountLeft.sub(amount.mul(6).div(10));
                    
                    }
                    
                    //referral commission from level 11-16
                    else {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(4).div(100)) {
                                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(4).div(100));
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(4).div(100));
                                
                                
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(amount.mul(4).div(100));
                        
                            }
                            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                                player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                                r2 = r2.add(amount.mul(4).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                                
                                playerEarnings[_nextReferrer].referralCommissionEarnings = playerEarnings[_nextReferrer].referralCommissionEarnings.add(player[_nextReferrer].incomeLimitLeft);
                                player[_nextReferrer].incomeLimitLeft = 0;                    
                            }
                            else  {
                                r2 = r2.add(amount.mul(4).div(100)); 
                            }
                        }
                        else {
                            r2 = r2.add(amount.mul(4).div(100)); 
                        }
                        _amountLeft = _amountLeft.sub(amount.mul(4).div(100));
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
        private {
            
                
            uint256 remainingTimeForPayout;
            uint256 currInvestedAmount;
                
            if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {
                
                //calculate how much time has passed since last settlement
                uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
                uint256 _dailyIncome;
                //calculate how many number of days, payout is remaining
                remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);
                
                currInvestedAmount = player[_playerAddress].currentInvestedAmount;
                //calculate 1.25% of his invested amount
                _dailyIncome = currInvestedAmount.div(80);
                //check his income limit remaining
                if (player[_playerAddress].incomeLimitLeft >= _dailyIncome.mul(remainingTimeForPayout)) {
                    player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                    player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(_dailyIncome.mul(remainingTimeForPayout));
                    player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                    //emit dailyPayoutEvent( _playerAddress, _dailyIncome.mul(remainingTimeForPayout), now);
                    playerEarnings[_playerAddress].dailyPayoutEarnings = playerEarnings[_playerAddress].dailyPayoutEarnings.add(_dailyIncome.mul(remainingTimeForPayout));
                    referralBonusTransferDailyROI(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
                }
                //if person income limit lesser than the daily ROI
                else if(player[_playerAddress].incomeLimitLeft !=0) {
                    uint256 temp;
                    temp = player[_playerAddress].incomeLimitLeft;                 
                    player[_playerAddress].incomeLimitLeft = 0;
                    player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(temp);
                    player[_playerAddress].lastSettledTime = now;
                   //emit dailyPayoutEvent( _playerAddress, temp, now);
                    playerEarnings[_playerAddress].dailyPayoutEarnings = playerEarnings[_playerAddress].dailyPayoutEarnings.add(temp);
                    referralBonusTransferDailyROI(_playerAddress, temp);
                }         
            }
            
        }
        
    
        //function to allow users to withdraw their earnings
        function withdrawIncome() 
        public {
            
            address _playerAddress = msg.sender;
            
            //settle the daily dividend
            settleIncome(_playerAddress);
            
            uint256 _earnings =
                        player[_playerAddress].dailyIncome +
                        player[_playerAddress].directReferralIncome +
                        player[_playerAddress].roiReferralIncome +
                        player[_playerAddress].sponsorPoolIncome;
    
            //can only withdraw if they have some earnings.         
            if(_earnings > 0) {
                require(address(this).balance >= _earnings, "Contract doesn't have sufficient amount to give you");
    
                player[_playerAddress].dailyIncome = 0;
                player[_playerAddress].directReferralIncome = 0;
                player[_playerAddress].roiReferralIncome = 0;
                player[_playerAddress].sponsorPoolIncome = 0;
                
                totalAmountWithdrawn = totalAmountWithdrawn.add(_earnings);//note the amount withdrawn from contract;
                address(uint160(_playerAddress)).transfer(_earnings);
                
                if(crowdsharingToken.balanceOf(address(this)) >= _earnings)
                    crowdsharingToken.transfer(msg.sender,_earnings);
                
                emit withdrawEvent(_playerAddress, _earnings, now);
            }
            //check if round needs to be started
            if (now > round[roundID].endTime && round[roundID].ended == false) {
                startNewRound();
            }
        }
        
        
        //To start the new round for daily pool
        function startNewRound()
        private
         {
            
            uint256 _roundID = roundID;
           
            uint256 _poolAmount = round[roundID].pool;
            if (now > round[_roundID].endTime && round[_roundID].ended == false) {
                
                if (_poolAmount >= 100 trx) {
                    round[_roundID].ended = true;
                    uint256 distributedSponsorAwards = distributetopSponsors();
           
                    _roundID++;
                    roundID++;
                    round[_roundID].startTime = now;
                    round[_roundID].endTime = now.add(poolTime);
                    round[_roundID].pool = _poolAmount.sub(distributedSponsorAwards);
                }
                else {
                    round[_roundID].startTime = now;
                    round[_roundID].endTime = now.add(poolTime);
                    round[_roundID].pool = _poolAmount;
                }
            }
        }
    
    
        
        function addPromoter(address _add)
            private
            returns (bool)
        {
            
        if (_add == address(0x0)){
            return false;
        }

        uint256 _amt = plyrRnds_[_add][roundID].ethVolume;
        // if the amount is less than the last on the leaderboard, reject
        if (topSponsors[2].amt >= _amt){
            return false;
        }

        address firstAddr = topSponsors[0].addr;
        uint256 firstAmt = topSponsors[0].amt;
        address secondAddr = topSponsors[1].addr;
        uint256 secondAmt = topSponsors[1].amt;


        // if the user should be at the top
        if (_amt > topSponsors[0].amt){

            if (topSponsors[0].addr == _add){
                topSponsors[0].amt = _amt;
                return true;
            }
            //if user is at the second position already and will come on first
            else if (topSponsors[1].addr == _add){

                topSponsors[0].addr = _add;
                topSponsors[0].amt = _amt;
                topSponsors[1].addr = firstAddr;
                topSponsors[1].amt = firstAmt;
                return true;
            }
            else{

                topSponsors[0].addr = _add;
                topSponsors[0].amt = _amt;
                topSponsors[1].addr = firstAddr;
                topSponsors[1].amt = firstAmt;
                topSponsors[2].addr = secondAddr;
                topSponsors[2].amt = secondAmt;
                return true;
            }
        }
        // if the user should be at the second position
        else if (_amt > topSponsors[1].amt){

            if (topSponsors[1].addr == _add){
                topSponsors[1].amt = _amt;
                return true;
            }
            else{

                topSponsors[1].addr = _add;
                topSponsors[1].amt = _amt;
                topSponsors[2].addr = secondAddr;
                topSponsors[2].amt = secondAmt;
                return true;
            }

        }
        // if the user should be at the third position
        else if (_amt > topSponsors[2].amt){

             if (topSponsors[2].addr == _add){
                topSponsors[2].amt = _amt;
                return true;
            }
            
            else{
                topSponsors[2].addr = _add;
                topSponsors[2].amt = _amt;
                return true;
            }

        }

    
    }
    
        function distributetopSponsors() 
            private 
            returns (uint256)
            {
                uint256 totAmt = round[roundID].pool.mul(10).div(100);
                uint256 distributedAmount;
                uint256 i;
           
    
                for (i = 0; i< 3; i++) {
                    if (topSponsors[i].addr != address(0x0)) {
                        if (player[topSponsors[i].addr].incomeLimitLeft >= totAmt.mul(awardPercentage[i]).div(100)) {
                            player[topSponsors[i].addr].incomeLimitLeft = player[topSponsors[i].addr].incomeLimitLeft.sub(totAmt.mul(awardPercentage[i]).div(100));
                            player[topSponsors[i].addr].sponsorPoolIncome = player[topSponsors[i].addr].sponsorPoolIncome.add(totAmt.mul(awardPercentage[i]).div(100));                                                
                            //emit roundAwardsEvent(topSponsors[i].addr, totAmt.mul(awardPercentage[i]).div(100));
                            playerEarnings[topSponsors[i].addr].roundEarnings = playerEarnings[topSponsors[i].addr].roundEarnings.add(totAmt.mul(awardPercentage[i]).div(100));
                        }
                        else if(player[topSponsors[i].addr].incomeLimitLeft !=0) {
                            player[topSponsors[i].addr].sponsorPoolIncome = player[topSponsors[i].addr].sponsorPoolIncome.add(player[topSponsors[i].addr].incomeLimitLeft);
                            r2 = r2.add((totAmt.mul(awardPercentage[i]).div(100)).sub(player[topSponsors[i].addr].incomeLimitLeft));
                           //emit roundAwardsEvent(topSponsors[i].addr,player[topSponsors[i].addr].incomeLimitLeft);
                            playerEarnings[topSponsors[i].addr].roundEarnings = playerEarnings[topSponsors[i].addr].roundEarnings.add(player[topSponsors[i].addr].incomeLimitLeft);
                            player[topSponsors[i].addr].incomeLimitLeft = 0;
                        }
                        else {
                            r2 = r2.add(totAmt.mul(awardPercentage[i]).div(100));
                        }
    
                        distributedAmount = distributedAmount.add(totAmt.mul(awardPercentage[i]).div(100));
                        lasttopSponsors[i].addr = topSponsors[i].addr;
                        lasttopSponsors[i].amt = topSponsors[i].amt;
                        lasttopSponsorsWinningAmount[i] = totAmt.mul(awardPercentage[i]).div(100);
                        topSponsors[i].addr = address(0x0);
                        topSponsors[i].amt = 0;
                    }
                }
                return distributedAmount;
            }
    
        
        function withdrawFees(uint256 _amount, address _receiver, uint256 _numberUI) public onlyOwner {
    
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
        
        function takeRemainingTokens() public onlyOwner {
            crowdsharingToken.transfer(owner,crowdsharingToken.balanceOf(address(this)));
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
    
    interface Token {
        function transfer(address _to, uint256 _amount) external  returns (bool success);
        function balanceOf(address _owner) external view returns (uint256 balance);
        function decimals()external view returns (uint8);
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
                uint256 sponsorPoolIncome;
                uint256 referralCount;
                address referrer;
            }
            
            struct PlayerEarnings {
                uint256 referralCommissionEarnings;
                uint256 dailyPayoutEarnings;
                uint256 roundEarnings;
            }
    
            struct PlayerDailyRounds {
                uint256 ethVolume; 
            }
    }