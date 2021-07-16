//SourceUnit: Tronadz.sol

pragma solidity 0.5.4;

contract Tronadz {
  using SafeMath for *;

        address public owner;
        address public masterAccount;
        uint256 private houseFee = 5;
        uint256 private poolTime = 24 hours;
        uint256 private dailyWinPool = 5;
        uint256 private whalepoolPercentage = 25;
        uint256 private incomeTimes = 30;
        uint256 private incomeDivide = 10;
        uint256 public total_withdraw;
        uint256 public roundID;
        uint256 public currUserID;
        uint256[4] private awardPercentage;

        struct Leaderboard {
            uint256 amt;
            address addr;
        }

        Leaderboard[4] public topSponsors;

        Leaderboard[4] public lastTopSponsors;
        uint256[4] public lastTopSponsorsWinningAmount;

        address[] public whales;


        mapping (uint => uint) public CYCLE_LIMIT;
        mapping (address => bool) public isWhale;
        mapping (uint => address) public userList;
        mapping (uint256 => DataStructs.DailyRound) public round;
        mapping (address => DataStructs.User) public player;
        mapping (address => uint256) public playerTotEarnings;
        mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_;

        /****************************  EVENTS   *****************************************/

        event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
        event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
        event premiumInvestmentEvent(address indexed _playerAddress, uint256 indexed _amount, uint256 _investedAmount);
        event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 _type);
        event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
        event roundAwardsEvent(address indexed _playerAddress, uint256 indexed _amount);
        event whaleAwardEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
        event premiumReferralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);


        constructor (
          address _owner,
          address _masterAccount
        )
        public {
             owner = _owner;
             masterAccount = _masterAccount;
             roundID = 1;
             round[1].startTime = now;
             round[1].endTime = now + poolTime;
             awardPercentage[0] = 40;
             awardPercentage[1] = 30;
             awardPercentage[2] = 20;
             awardPercentage[3] = 10;
             currUserID = 0;

             CYCLE_LIMIT[1]=100000000000;
             CYCLE_LIMIT[2]=250000000000;
             CYCLE_LIMIT[3]=1000000000000;
             CYCLE_LIMIT[4]=2500000000000;

             currUserID++;
             player[masterAccount].id = currUserID;
             userList[currUserID] = masterAccount;

        }

        function isUser(address _addr)
        public view returns (bool) {
            return player[_addr].id > 0;
        }

        /****************************  MODIFIERS    *****************************************/


        /**
         * @dev sets boundaries for incoming tx
         */
        modifier isMinimumAmount(uint256 _eth) {
            require(_eth >= 100000000, "Minimum contribution amount is 100 TRX");
            _;
        }

        /**
         * @dev sets permissible values for incoming tx
         */
        modifier isallowedValue(uint256 _eth) {
            require(_eth % 100000000 == 0, "multiples of 100 TRX please");
            _;
        }

        /**
         * @dev allows only the user to run the function
         */
        modifier onlyOwner() {
            require(msg.sender == owner, "only Owner");
            _;
        }

        modifier requireUser() { require(isUser(msg.sender)); _; }


        /****************************  MAIN LOGIC    *****************************************/

        //function to maintain the business logic
        function registerUser(uint256 _referrerID)
        public
        isMinimumAmount(msg.value)
        isallowedValue(msg.value)
        payable {

            require(_referrerID > 0 && _referrerID <= currUserID, "Incorrect Referrer ID");
            address _referrer = userList[_referrerID];

            uint256 amount = msg.value;
            if (player[msg.sender].id <= 0) { //if player is a new joinee
            require(amount <= CYCLE_LIMIT[1], "Can't send more than the limit");

                currUserID++;
                player[msg.sender].id = currUserID;
                player[msg.sender].depositTime = now;
                player[msg.sender].currInvestment = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                player[msg.sender].totalInvestment = amount;
                player[msg.sender].referrer = _referrer;
                player[msg.sender].cycle = 1;
                userList[currUserID] = msg.sender;

                player[_referrer].referralCount = player[_referrer].referralCount.add(1);

                plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                addSponsorToPool(_referrer);
                directsReferralBonus(msg.sender, amount);


                  emit registerUserEvent(msg.sender, _referrer);
            }
                //if the user is old
            else {

                player[msg.sender].cycle = player[msg.sender].cycle.add(1);

                require(player[msg.sender].incomeLimitLeft == 0, "limit is still remaining");

                require(amount >= (player[msg.sender].currInvestment.mul(2) >= 2500000000000 ? 2500000000000 : player[msg.sender].currInvestment.mul(2)));
                require(amount <= CYCLE_LIMIT[player[msg.sender].cycle > 4 ? 4 : player[msg.sender].cycle], "Please send correct amount");

                _referrer = player[msg.sender].referrer;

                if(amount == 2500000000000) {
                    if(isWhale[msg.sender] == false){
                        isWhale[msg.sender] == true;
                        whales.push(msg.sender);
                    }
                    player[msg.sender].incomeLimitLeft = amount.mul(20).div(incomeDivide);
                }
                else {
                    player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                }

                player[msg.sender].depositTime = now;
                player[msg.sender].dailyIncome = 0;
                player[msg.sender].currInvestment = amount;
                player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);

                plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                addSponsorToPool(_referrer);
                directsReferralBonus(msg.sender, amount);

            }

                round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
                round[roundID].whalepool = round[roundID].whalepool.add(amount.mul(whalepoolPercentage).div(incomeDivide).div(100));

                address payable ownerAddr = address(uint160(owner));
                ownerAddr.transfer(amount.mul(houseFee).div(100));

                if (now > round[roundID].endTime && round[roundID].ended == false) {
                    startNextRound();
                }

                emit investmentEvent (msg.sender, amount);
        }


        function directsReferralBonus(address _playerAddress, uint256 amount)
        private
        {
            address _nextReferrer = player[_playerAddress].referrer;
            uint i;

            for(i=0; i < 5; i++) {

                if (_nextReferrer != address(0x0)) {
                    //referral commission to level 1
                    if(i == 0) {
                            player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(10).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(10).div(100), 1);
                        }
                    else if(i == 1 ) {
                        if(player[_nextReferrer].referralCount >= 2) {
                            player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(2).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(2).div(100), 1);
                        }
                    }
                    //referral commission from level 3-5
                    else {
                        if(player[_nextReferrer].referralCount >= i+1) {
                           player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(1).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(1).div(100), 1);
                        }
                    }
                }
                else {
                    break;
                }
                _nextReferrer = player[_nextReferrer].referrer;
            }
        }


        //function to manage the referral commission from the daily ROI
        function roiReferralBonus(address _playerAddress, uint256 amount)
        private
        {
            address _nextReferrer = player[_playerAddress].referrer;
            uint i;

            for(i=0; i < 20; i++) {

                if (_nextReferrer != address(0x0)) {
                    if(i == 0) {
                       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(30).div(100));
                       emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(30).div(100), 2);
                    }
                    //for user 2-5
                    else if(i > 0 && i < 5) {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(10).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(10).div(100), 2);
                        }
                    }
                    //for users 6-10
                    else if(i > 4 && i < 10) {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(8).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(8).div(100), 2);
                        }
                    }
                    //for user 11-15
                    else if(i > 9 && i < 15) {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(5).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(5).div(100), 2);
                        }
                    }
                    else { // for users 16-20
                        if(player[_nextReferrer].referralCount >= i+1) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(1).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(1).div(100), 2);
                        }
                    }
                }
                else {
                        break;
                    }
                _nextReferrer = player[_nextReferrer].referrer;
            }
        }



        //function to allow users to withdraw their earnings
        function withdrawEarnings()
        requireUser
        public {
            (uint256 to_payout) = this.payoutOf(msg.sender);

            require(player[msg.sender].incomeLimitLeft > 0, "Limit not available");

            // Deposit payout
            if(to_payout > 0) {
                if(to_payout > player[msg.sender].incomeLimitLeft) {
                    to_payout = player[msg.sender].incomeLimitLeft;
                }

                player[msg.sender].dailyIncome += to_payout;
                player[msg.sender].incomeLimitLeft -= to_payout;

                roiReferralBonus(msg.sender, to_payout);
            }

            // Direct sponsor bonus
            if(player[msg.sender].incomeLimitLeft > 0 && player[msg.sender].directsIncome > 0) {
                uint256 direct_bonus = player[msg.sender].directsIncome;

                if(direct_bonus > player[msg.sender].incomeLimitLeft) {
                    direct_bonus = player[msg.sender].incomeLimitLeft;
                }

                player[msg.sender].directsIncome -= direct_bonus;
                player[msg.sender].incomeLimitLeft -= direct_bonus;
                to_payout += direct_bonus;
            }

            // // Pool payout
            if(player[msg.sender].incomeLimitLeft > 0 && player[msg.sender].sponsorPoolIncome > 0) {
                uint256 pool_bonus = player[msg.sender].sponsorPoolIncome;

                if(pool_bonus > player[msg.sender].incomeLimitLeft) {
                    pool_bonus = player[msg.sender].incomeLimitLeft;
                }

                player[msg.sender].sponsorPoolIncome -= pool_bonus;
                player[msg.sender].incomeLimitLeft -= pool_bonus;
                to_payout += pool_bonus;
            }

            // Match payout
            if(player[msg.sender].incomeLimitLeft > 0  && player[msg.sender].roiReferralIncome > 0) {
                uint256 match_bonus = player[msg.sender].roiReferralIncome;

                if(match_bonus > player[msg.sender].incomeLimitLeft) {
                    match_bonus = player[msg.sender].incomeLimitLeft;
                }

                player[msg.sender].roiReferralIncome -= match_bonus;
                player[msg.sender].incomeLimitLeft -= match_bonus;
                to_payout += match_bonus;
            }

            //Whale pool Payout
            if(player[msg.sender].incomeLimitLeft > 0  && player[msg.sender].whalepoolAward > 0) {
                uint256 whale_bonus = player[msg.sender].whalepoolAward;

                if(whale_bonus > player[msg.sender].incomeLimitLeft) {
                    whale_bonus = player[msg.sender].incomeLimitLeft;
                }

                player[msg.sender].whalepoolAward -= whale_bonus;
                player[msg.sender].incomeLimitLeft -= whale_bonus;
                to_payout += whale_bonus;
            }

            //Premium Adz Referral incomeLimitLeft
            if(player[msg.sender].incomeLimitLeft > 0  && player[msg.sender].premiumReferralIncome > 0) {
                uint256 premium_bonus = player[msg.sender].premiumReferralIncome;

                if(premium_bonus > player[msg.sender].incomeLimitLeft) {
                    premium_bonus = player[msg.sender].incomeLimitLeft;
                }

                player[msg.sender].premiumReferralIncome -= premium_bonus;
                player[msg.sender].incomeLimitLeft -= premium_bonus;
                to_payout += premium_bonus;
            }

            require(to_payout > 0, "Zero payout");

            playerTotEarnings[msg.sender] += to_payout;
            total_withdraw += to_payout;

            address payable senderAddr = address(uint160(msg.sender));
            senderAddr.transfer(to_payout);

             emit withdrawEvent(msg.sender, to_payout, now);

        }

        function payoutOf(address _addr) view external returns(uint256 payout) {
            uint256  earningsLimitLeft = player[_addr].incomeLimitLeft;

            if(player[_addr].incomeLimitLeft > 0 ) {
                payout = (player[_addr].currInvestment * ((block.timestamp - player[_addr].depositTime) / 1 days) / 100) - player[_addr].dailyIncome;

                if(player[_addr].dailyIncome + payout > earningsLimitLeft) {
                    payout = earningsLimitLeft;
                }
            }
        }


        //To start the new round for daily pool
        function startNextRound()
        private
         {

            uint256 _roundID = roundID;

            uint256 _poolAmount = round[roundID].pool;

                if (_poolAmount >= 100000000000) {
                    round[_roundID].ended = true;
                    uint256 distributedSponsorAwards = awardTopPromoters();


                    if(whales.length > 0)
                        awardWhales();

                    uint256 _whalePoolAmount = round[roundID].whalepool;

                    _roundID++;
                    roundID++;
                    round[_roundID].startTime = now;
                    round[_roundID].endTime = now.add(poolTime);
                    round[_roundID].pool = _poolAmount.sub(distributedSponsorAwards);
                    round[_roundID].whalepool = _whalePoolAmount;
                }
                else {
                    round[_roundID].startTime = now;
                    round[_roundID].endTime = now.add(poolTime);
                    round[_roundID].pool = _poolAmount;
                }
        }


        function addSponsorToPool(address _add)
            private
            returns (bool)
        {
            if (_add == address(0x0)){
                return false;
            }

            uint256 _amt = plyrRnds_[_add][roundID].ethVolume;
            // if the amount is less than the last on the leaderboard pool, reject
            if (topSponsors[3].amt >= _amt){
                return false;
            }

            address firstAddr = topSponsors[0].addr;
            uint256 firstAmt = topSponsors[0].amt;

            address secondAddr = topSponsors[1].addr;
            uint256 secondAmt = topSponsors[1].amt;

            address thirdAddr = topSponsors[2].addr;
            uint256 thirdAmt = topSponsors[2].amt;



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
                //if user is at the third position and will come on first
                else if (topSponsors[2].addr == _add) {
                    topSponsors[0].addr = _add;
                    topSponsors[0].amt = _amt;
                    topSponsors[1].addr = firstAddr;
                    topSponsors[1].amt = firstAmt;
                    topSponsors[2].addr = secondAddr;
                    topSponsors[2].amt = secondAmt;
                    return true;
                }
                else{

                    topSponsors[0].addr = _add;
                    topSponsors[0].amt = _amt;
                    topSponsors[1].addr = firstAddr;
                    topSponsors[1].amt = firstAmt;
                    topSponsors[2].addr = secondAddr;
                    topSponsors[2].amt = secondAmt;
                    topSponsors[3].addr = thirdAddr;
                    topSponsors[3].amt = thirdAmt;
                    return true;
                }
            }
            // if the user should be at the second position
            else if (_amt > topSponsors[1].amt){

                if (topSponsors[1].addr == _add){
                    topSponsors[1].amt = _amt;
                    return true;
                }
                //if user is at the third position, move it to second
                else if(topSponsors[2].addr == _add) {
                    topSponsors[1].addr = _add;
                    topSponsors[1].amt = _amt;
                    topSponsors[2].addr = secondAddr;
                    topSponsors[2].amt = secondAmt;
                    return true;
                }
                else{
                    topSponsors[1].addr = _add;
                    topSponsors[1].amt = _amt;
                    topSponsors[2].addr = secondAddr;
                    topSponsors[2].amt = secondAmt;
                    topSponsors[3].addr = thirdAddr;
                    topSponsors[3].amt = thirdAmt;
                    return true;
                }
            }
            //if the user should be at third position
            else if(_amt > topSponsors[2].amt){
                if(topSponsors[2].addr == _add) {
                    topSponsors[2].amt = _amt;
                    return true;
                }
                else {
                    topSponsors[2].addr = _add;
                    topSponsors[2].amt = _amt;
                    topSponsors[3].addr = thirdAddr;
                    topSponsors[3].amt = thirdAmt;
                }
            }
            // if the user should be at the fourth position
            else if (_amt > topSponsors[3].amt){

                 if (topSponsors[3].addr == _add){
                    topSponsors[3].amt = _amt;
                    return true;
                }

                else{
                    topSponsors[3].addr = _add;
                    topSponsors[3].amt = _amt;
                    return true;
                }
            }
        }

        function awardTopPromoters()
            private
            returns (uint256)
            {
                uint256 totAmt = round[roundID].pool.mul(10).div(100);
                uint256 distributedAmount;
                uint256 i;


                for (i = 0; i< 4; i++) {
                    if (topSponsors[i].addr != address(0x0)) {
                        player[topSponsors[i].addr].sponsorPoolIncome = player[topSponsors[i].addr].sponsorPoolIncome.add(totAmt.mul(awardPercentage[i]).div(100));
                        distributedAmount = distributedAmount.add(totAmt.mul(awardPercentage[i]).div(100));
                        emit roundAwardsEvent(topSponsors[i].addr, totAmt.mul(awardPercentage[i]).div(100));

                        lastTopSponsors[i].addr = topSponsors[i].addr;
                        lastTopSponsors[i].amt = topSponsors[i].amt;
                        lastTopSponsorsWinningAmount[i] = totAmt.mul(awardPercentage[i]).div(100);
                        topSponsors[i].addr = address(0x0);
                        topSponsors[i].amt = 0;
                    }
                    else {
                        break;
                    }
                }

                return distributedAmount;
            }

        function awardWhales()
        private
        {
            uint256 totalWhales = whales.length;

            uint256 toPayout = round[roundID].whalepool.div(totalWhales);
            for(uint256 i = 0; i < totalWhales; i++) {
                player[whales[i]].whalepoolAward = player[whales[i]].whalepoolAward.add(toPayout);
                emit whaleAwardEvent(whales[i], toPayout, now);
            }
            round[roundID].whalepool = 0;
        }

        function premiumInvestment()
        public
        payable {

            uint256 amount = msg.value;

            premiumReferralIncomeDistribution(msg.sender, amount);

            address payable ownerAddr = address(uint160(owner));
            ownerAddr.transfer(amount.mul(5).div(100));
            emit premiumInvestmentEvent(msg.sender, amount, player[msg.sender].currInvestment);
        }

        function premiumReferralIncomeDistribution(address _playerAddress, uint256 amount)
        private {
            address _nextReferrer = player[_playerAddress].referrer;
            uint i;

            for(i=0; i < 5; i++) {

                if (_nextReferrer != address(0x0)) {
                    //referral commission to level 1
                    if(i == 0) {
                        player[_nextReferrer].premiumReferralIncome = player[_nextReferrer].premiumReferralIncome.add(amount.mul(20).div(100));
                        emit premiumReferralCommissionEvent(_playerAddress, _nextReferrer, amount.mul(20).div(100), now);
                    }

                    else if(i == 1 ) {
                        if(player[_nextReferrer].referralCount >= 2) {
                            player[_nextReferrer].premiumReferralIncome = player[_nextReferrer].premiumReferralIncome.add(amount.mul(10).div(100));
                            emit premiumReferralCommissionEvent(_playerAddress, _nextReferrer, amount.mul(10).div(100), now);
                        }
                    }

                    //referral commission from level 3-5
                    else {
                        if(player[_nextReferrer].referralCount >= i+1) {
                            player[_nextReferrer].premiumReferralIncome = player[_nextReferrer].premiumReferralIncome.add(amount.mul(5).div(100));
                            emit premiumReferralCommissionEvent(_playerAddress, _nextReferrer, amount.mul(5).div(100), now);
                        }
                    }
                }
                else {
                    break;
                }
                _nextReferrer = player[_nextReferrer].referrer;
            }
        }


        function drawPool() external onlyOwner {
            startNextRound();
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
                uint256 pool; //amount in the pool
                uint256 whalepool; //deposits for whalepool
            }

            struct User {
                uint256 id;
                uint256 totalInvestment;
                uint256 directsIncome;
                uint256 roiReferralIncome;
                uint256 currInvestment;
                uint256 dailyIncome;
                uint256 depositTime;
                uint256 incomeLimitLeft;
                uint256 sponsorPoolIncome;
                uint256 referralCount;
                address referrer;
                uint256 cycle;
                uint256 whalepoolAward;
                uint256 premiumReferralIncome;
            }

            struct PlayerDailyRounds {
                uint256 ethVolume;
            }
    }