//SourceUnit: forsageLifeLive.sol

pragma solidity 0.5.8;

contract ForsageLife{
    
    struct UserStruct{
        bool Exist;
        uint id;
        address referrer;
        uint totalCycle;
        uint investID;
        uint holdID;
        uint totalDeposit;
        uint levelBounus;
        uint totalEarning;
        uint levelEarned;
        address[] referrals;
        mapping(uint => InvestStruct) investment;
        mapping(uint => holdStruct) hold;
        bool promoBonusStatus;
        uint promoBonusEarned;
        uint created;
    }
    
    struct InvestStruct{
        bool IsReTopUp;
        uint cycleID;
        uint investAmount;
        uint payouts;
        uint deposit_payout;
        uint affiliatePayout;
        uint invest_time;
        uint withdrawalLimit;
        bool reTopUpStatus;
        bool completedStatus;
    }
    
    struct holdStruct{
        uint holdAmount;
        uint holdEarned;
        uint hold_time;
        bool completedStatus;
    }
    
    struct CycleStruct{
        uint cycle;
        uint ROI;
        uint returnLimit;
    }
    
    struct PromoBonusStruct{
        uint eligibleAmount;
        uint bonus;
    }
    
    address public  ownerWallet;
    
    uint public maxHoldDays = 3 days;
    uint public holdingROI = 500000;
    uint public currUserID;
    
    mapping(uint => CycleStruct) public cycles;
    mapping(uint => address) public userList;
    
    mapping(address => UserStruct) public users;
    mapping(uint => uint) public levelPrice;
    mapping(uint => PromoBonusStruct) public promoBonus;
    mapping (address => mapping(uint => uint)) public dailyPayout;
    mapping (address => mapping(uint => uint)) public dailyPayoutTime;
    
    //Event 
    event regEvent( address indexed _user, uint _userID, address _upline, uint _time);
    event Upline(address indexed addr, address indexed upline, uint _level, uint level_bonus, uint _time);
    event NewDeposit(address indexed addr, uint256 amount, uint _time);
    event HoldEvent(address indexed addr, uint256 amount, uint _time);
    event Withdraw(address indexed addr, uint256 amount, uint _time);
    event WithdrawHold(address indexed addr, uint256 amount, uint256 reward, uint _time);
    
    constructor()public {
        ownerWallet = msg.sender;
        
        currUserID++;
        
        UserStruct memory _userStruct;
        
        _userStruct = UserStruct({
            Exist: true,
            id: currUserID, 
            referrer : address(0),
            totalCycle:0,
            investID : 0,
            holdID : 0,
            totalDeposit : 0,
            levelBounus : 0,
            totalEarning : 0,
            levelEarned:0,
            referrals : new address[](0),
            promoBonusEarned:0,
            promoBonusStatus: false,
            created : now+100 days
        });
        
        users[ownerWallet] = _userStruct;
        userList[currUserID] = ownerWallet;
        
        CycleStruct memory _cycleStruct;
        
        _cycleStruct = CycleStruct({
            cycle: 200e6,
            ROI : 1e6,
            returnLimit : 30
        });
        
        cycles[1] = _cycleStruct;
        
        _cycleStruct = CycleStruct({
            cycle: 2000e6,
            ROI : 2e6,
            returnLimit : 20
        });
        
        cycles[2] = _cycleStruct;
        
        _cycleStruct = CycleStruct({
            cycle: 10000e6,
            ROI : 3e6,
            returnLimit : 15
        });
        
        cycles[3] = _cycleStruct;
        
        _cycleStruct = CycleStruct({
            cycle: 50000e6,
            ROI : 4e6,
            returnLimit : 12
        });
        
        cycles[4] = _cycleStruct;
        
        levelPrice[1] = 5e6;
        levelPrice[2] = 3e6;
        levelPrice[3] = 2e6;
        levelPrice[4] = 1e6;
        levelPrice[5] = 1e6;
        levelPrice[6] = 1e6;
        levelPrice[7] = 1e6;
        levelPrice[8] = 1e6;
        levelPrice[9] = 2e6;
        levelPrice[10] = 3e6;
        
        promoBonus[1].eligibleAmount = 100000e6;
        promoBonus[2].eligibleAmount = 500000e6;
        promoBonus[3].eligibleAmount = 2500000e6;
        promoBonus[4].eligibleAmount = 10000000e6;
        
        promoBonus[1].bonus = 25000e6;
        promoBonus[2].bonus = 200000e6;
        promoBonus[3].bonus = 1500000e6;
        promoBonus[4].bonus = 10000000e6;
    }
    
    function deposit( address _upline, uint _cycle) public payable returns(bool){
        require(_cycle > 0 && _cycle <=4, "Invalid cycle");
        require(users[_upline].Exist, "upline user is not exist");
        
        if(_cycle == 1)
            require(msg.value >= cycles[1].cycle, "In cycle 1, min is 1 trx");
            
        else if(_cycle == 2)
            require(msg.value >= cycles[2].cycle, "In cycle 2, min is 2 trx");
            
        else if(_cycle == 3)
            require(msg.value >= cycles[3].cycle, "In cycle 3, min is 3 trx");
            
        else if(_cycle == 4)
            require(msg.value >= cycles[4].cycle, "In cycle 4, min is 4 trx");
        
        if(!users[msg.sender].Exist)
          userReg( _upline);
        
        users[msg.sender].investID++;
        users[msg.sender].investment[users[msg.sender].investID].cycleID = _cycle;
        users[msg.sender].investment[users[msg.sender].investID].investAmount = msg.value;
        users[msg.sender].investment[users[msg.sender].investID].withdrawalLimit = msg.value;
        users[msg.sender].investment[users[msg.sender].investID].invest_time = now;
        users[msg.sender].totalDeposit += msg.value;
        users[msg.sender].totalCycle++;
        dailyPayoutTime[msg.sender][users[msg.sender].investID] = now;
        
        
        payforLevels( msg.sender, 1, msg.value);
        
        require(address(uint160(ownerWallet)).send(((msg.value*1e7)/1e8)), "admin commission transfer failed");
        users[ownerWallet].totalEarning += ((msg.value*1e7)/1e8);
        
        emit NewDeposit(msg.sender, msg.value, now);
        
        return true;
    }
    
    function reTopUp( uint _investID, uint _cycle, uint _investAmount, uint8 _flag) public returns(bool){
        require(users[msg.sender].Exist, "user not exist");
        require(_cycle > 0 && _cycle <=4, "Invalid cycle");
        require(_investAmount > 0,"_investAmount must be greater than zero");
        require(_flag == 1 || _flag == 2, "_flag must be 1 or 2");
        require(_investAmount >= cycles[_cycle].cycle, "Invalid cycle amount");
        
        uint256 to_payout;
        
        if(_flag == 1){
            require(_investID > 0 && _investID<= users[msg.sender].investID, "Invalid investID");
            require(!users[msg.sender].investment[_investID].completedStatus, "deposit cycle completed");
            require(users[msg.sender].investment[_investID].payouts < maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount), "Full payouts");
            
             uint256 max_payout;
            (to_payout, max_payout) = this.payoutOf(msg.sender, _investID);
               
            if(to_payout > 0) {
                // if(users[msg.sender].investment[_investID].payouts + to_payout > max_payout){ 
                    
                //     to_payout = max_payout - users[msg.sender].investment[_investID].payouts;
                // }
                
                if(to_payout > _investAmount){
                    to_payout = _investAmount;
                }
                    
                users[msg.sender].investment[_investID].payouts += to_payout;
                users[msg.sender].investment[_investID].deposit_payout += to_payout;
            }
            
            // Direct payout
            if(users[msg.sender].investment[_investID].payouts < maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount) && (users[msg.sender].levelBounus > 0) && (to_payout < _investAmount)) {
                uint256 level_bonus = users[msg.sender].levelBounus;
    
                if(users[msg.sender].investment[_investID].payouts + level_bonus > maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount))
                    level_bonus = maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount) - users[msg.sender].investment[_investID].payouts;
                
                if(to_payout+level_bonus >= _investAmount)
                    level_bonus = _investAmount -to_payout;
                else
                    revert("insufficient fund");
                    
                users[msg.sender].investment[_investID].payouts += level_bonus;
                users[msg.sender].levelBounus -=  level_bonus;
                users[msg.sender].investment[_investID].affiliatePayout += level_bonus;
                to_payout += level_bonus;
            }                
            
            
            if(to_payout < _investAmount)
                revert("insufficient investment payout");
            
                
        }
        else{ // promoBonus
            // if(users[msg.sender].created < now && !users[msg.sender].promoBonusStatus)
            //     promoBonusDistribution( msg.sender);
            
            require(_investAmount <= users[msg.sender].promoBonusEarned, "user has insufficient promo bonus");
            
            to_payout = _investAmount;
            users[msg.sender].promoBonusEarned -= to_payout;
        }
        
    
        users[msg.sender].investID++;
        users[msg.sender].investment[users[msg.sender].investID].IsReTopUp = true;
        users[msg.sender].investment[users[msg.sender].investID].cycleID = _cycle;
        dailyPayoutTime[msg.sender][users[msg.sender].investID] = now;
        
        
        users[msg.sender].investment[users[msg.sender].investID].investAmount = to_payout+(to_payout*1e7/1e8);
        users[msg.sender].investment[users[msg.sender].investID].withdrawalLimit = to_payout;
        users[msg.sender].investment[users[msg.sender].investID].invest_time = now;
        users[msg.sender].totalDeposit += to_payout;
        
        
        payforLevels( msg.sender, 1, to_payout);
        
        require(address(uint160(ownerWallet)).send(((users[msg.sender].investment[users[msg.sender].investID].investAmount*1e7)/1e8)), "admin commission transfer failed");
        users[ownerWallet].totalEarning += ((users[msg.sender].investment[users[msg.sender].investID].investAmount*1e7)/1e8);
        
        emit NewDeposit(msg.sender, to_payout, now);
        
        return true;
    }
    
    
    function hold( uint _investID, uint _investAmount, uint8 _flag) public returns(bool){
        require(users[msg.sender].Exist, "user not exist");
        require(_flag == 1 || _flag == 2, "_flag must be 1 or 2");
        require(_investAmount > 0,"_investAmount must be greater than zero");
        
        uint256 to_payout;
        
        if(_flag == 1){
        
            require(_investID > 0 && _investID<= users[msg.sender].investID, "Invalid investID");
            require(!users[msg.sender].investment[_investID].completedStatus, "deposit cycle completed");
            require(users[msg.sender].investment[_investID].payouts < maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount), "Full payouts");
            
            uint256 max_payout;
            
            ( to_payout, max_payout) = this.payoutOf(msg.sender, _investID);
            
            if(to_payout > 0) {
                // if(users[msg.sender].investment[_investID].payouts + to_payout > max_payout) 
                //     to_payout = max_payout - users[msg.sender].investment[_investID].payouts;
                
                if(to_payout > _investAmount){
                    to_payout = _investAmount;
                }
                    
                users[msg.sender].investment[_investID].payouts += to_payout;
                users[msg.sender].investment[_investID].deposit_payout += to_payout;
            }
            
            // Direct payout
            if(users[msg.sender].investment[_investID].payouts < maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount) && (users[msg.sender].levelBounus > 0) && (to_payout < _investAmount)) {
                uint256 level_bonus = users[msg.sender].levelBounus;
    
                if(users[msg.sender].investment[_investID].payouts + level_bonus > maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount))
                    level_bonus = maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount) - users[msg.sender].investment[_investID].payouts;
                
                if(to_payout+level_bonus >= _investAmount)
                    level_bonus = _investAmount -to_payout;
                else
                    revert("insufficient payout");
                    
                users[msg.sender].investment[_investID].payouts += level_bonus;
                users[msg.sender].levelBounus -=  level_bonus;
                users[msg.sender].investment[_investID].affiliatePayout += level_bonus;
                to_payout += level_bonus;
            }                
            
            
            if(to_payout < _investAmount)
                revert("insufficient investment payout");
        
        }
        else{ // promoBonus
            // if(users[msg.sender].created < now && !users[msg.sender].promoBonusStatus)
            //     promoBonusDistribution( msg.sender);
            
            require(_investAmount <= users[msg.sender].promoBonusEarned, "user has insufficient promo bonus");
            
            to_payout = _investAmount;
            users[msg.sender].promoBonusEarned -= to_payout;
        }
        
        users[msg.sender].holdID++;
        users[msg.sender].hold[users[msg.sender].holdID].holdAmount = to_payout;
        users[msg.sender].hold[users[msg.sender].holdID].hold_time = now;
        
        require(address(uint160(ownerWallet)).send(((users[msg.sender].hold[users[msg.sender].holdID].holdAmount*1e7)/1e8)), "admin commission transfer failed");
        users[ownerWallet].totalEarning += ((users[msg.sender].hold[users[msg.sender].holdID].holdAmount*1e7)/1e8);
        
        emit HoldEvent( msg.sender, to_payout, now);
        return true;
    }
    
    function withdrawHoldTrx( uint _holdID) public returns(bool){
        require(users[msg.sender].Exist, "user not exist");
        require(_holdID > 0 && _holdID<= users[msg.sender].holdID, "Invalid investID");
        require(users[msg.sender].hold[_holdID].hold_time+maxHoldDays < now, "user can withdraw after completion of 3 days from hold");
        require(!users[msg.sender].hold[_holdID].completedStatus, " Trx holding completed");
        
        uint maximum_days = block.timestamp;
        
        uint _days = (maximum_days - users[msg.sender].hold[_holdID].hold_time)/ 86400;
        
        uint ROI_Payout = (users[msg.sender].hold[_holdID].holdAmount * (holdingROI * _days))/1e8;
        
        uint total_holding_payout = users[msg.sender].hold[_holdID].holdAmount+ROI_Payout;
        
        require(msg.sender.send(((total_holding_payout*98e6)/1e8)),"hold transfer failed");
        users[msg.sender].hold[_holdID].holdEarned +=  ((total_holding_payout*98e6)/1e8);
        
        require(address(uint160(ownerWallet)).send(((total_holding_payout*2e6)/1e8)),"hold transfer failed");
        users[ownerWallet].hold[_holdID].holdEarned +=  ((total_holding_payout*2e6)/1e8);
        
        users[msg.sender].hold[_holdID].completedStatus = true;
        
        emit WithdrawHold( msg.sender, users[msg.sender].hold[_holdID].holdAmount, ROI_Payout, now);
        
        return true;
    }
    
    function withdrawDailyPayout( uint _investID, uint _amount) public returns(bool){
        require(_investID > 0 && _investID <= users[msg.sender].investID, "invalid withdraw invest id");
        require(_amount <= users[msg.sender].investment[_investID].withdrawalLimit, "exceeds withdraw limit");
        require(_amount > 0,"Amount must be greater than zero");
        
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender, _investID);
        
        if(((block.timestamp - dailyPayoutTime[msg.sender][_investID])/(1 days)) >= 1){
            dailyPayout[msg.sender][_investID] = 0;
            dailyPayoutTime[msg.sender][_investID] = now;
        }
        
        if(to_payout > 0) {
            // if(users[msg.sender].investment[_investID].payouts + to_payout > max_payout) 
            //     to_payout = max_payout - users[msg.sender].investment[_investID].payouts;
            
             if(to_payout > _amount)
                to_payout = _amount;
                
            if((to_payout+dailyPayout[msg.sender][_investID]) > users[msg.sender].investment[_investID].withdrawalLimit)
                to_payout  = (users[msg.sender].investment[_investID].withdrawalLimit-dailyPayout[msg.sender][_investID]);
                
            users[msg.sender].investment[_investID].payouts += to_payout;
            users[msg.sender].investment[_investID].deposit_payout += to_payout;
        }
        
        // Direct payout
        if((users[msg.sender].investment[_investID].payouts < maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount)) && (users[msg.sender].levelBounus > 0)&& (to_payout < _amount)) {
            uint256 level_bonus = users[msg.sender].levelBounus;

            if(users[msg.sender].investment[_investID].payouts + level_bonus > maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount))
                level_bonus = maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount) - users[msg.sender].investment[_investID].payouts;
            
            if(to_payout+level_bonus > _amount)            
                level_bonus = _amount - to_payout;
                
            if(((to_payout+level_bonus) + dailyPayout[msg.sender][_investID]) > users[msg.sender].investment[_investID].withdrawalLimit)
                level_bonus  = (users[msg.sender].investment[_investID].withdrawalLimit - (dailyPayout[msg.sender][_investID]+to_payout));
                
            users[msg.sender].investment[_investID].payouts += level_bonus;
            users[msg.sender].levelBounus -=  level_bonus;
            users[msg.sender].investment[_investID].affiliatePayout += level_bonus;
            to_payout += level_bonus;
        }                
        
        require(to_payout == _amount, "insufficient earnings");

        
        if((users[msg.sender].investment[_investID].payouts >=maxTotalPayoutOf(users[msg.sender].investment[_investID].investAmount))){
            users[msg.sender].investment[_investID].completedStatus = true; 
        }

        require(address(uint160(ownerWallet)).send(((to_payout*2e6)/1e8)), "admin commission transfer failed");
        users[ownerWallet].totalEarning += ((to_payout*2e6)/1e8);
        
        require(msg.sender.send(((to_payout*98e6)/1e8)), "withdraw transfer failed");
        users[msg.sender].totalEarning += ((to_payout*98e6)/1e8);
        dailyPayout[msg.sender][_investID] += ((to_payout*98e6)/1e8);
        
            
        emit Withdraw( msg.sender, to_payout, now);
            
        return true;
    }
    
    function withdrawPromoBonus( uint _amount) public returns(bool){
        require(_amount > 0, "_amount must be greater than zero");
        require(users[msg.sender].promoBonusEarned >= _amount, "insufficient promobonus");
        
        require(address(uint160(ownerWallet)).send(((_amount*2e6)/1e8)), "admin commission transfer failed");
        users[ownerWallet].totalEarning += ((_amount*2e6)/1e8);
        
        require(msg.sender.send(((_amount*98e6)/1e8)), "withdraw transfer failed");
        users[msg.sender].totalEarning += ((_amount*98e6)/1e8);
        
        users[msg.sender].promoBonusEarned -= _amount;
        
        return true;
    }
    
    function promoBonusDistribution( address _user) internal returns(uint){
        uint promoBonusType;
        
        if((users[_user].levelEarned >= promoBonus[1].eligibleAmount) && (users[_user].levelEarned < promoBonus[2].eligibleAmount))
            promoBonusType = 1;
            
        else if((users[_user].levelEarned >= promoBonus[2].eligibleAmount) && (users[_user].levelEarned < promoBonus[3].eligibleAmount))
            promoBonusType = 2;
        
        else if((users[_user].levelEarned >= promoBonus[3].eligibleAmount) && (users[_user].levelEarned < promoBonus[4].eligibleAmount))
            promoBonusType = 3;
        
        else if(users[_user].levelEarned >= promoBonus[4].eligibleAmount)
            promoBonusType = 4;
            
        if(promoBonusType > 0){
            users[_user].promoBonusEarned = promoBonus[promoBonusType].bonus;
            users[_user].totalEarning += promoBonus[promoBonusType].bonus;
            users[_user].promoBonusStatus = true;
        }
        return promoBonusType;
    }
    
    
    
    function maxTotalPayoutOf( uint _amount) public pure returns(uint) {
        return _amount * 100 / 10;
    }
    
    function maxPayoutOfinvest( uint256 _amount, uint _cycleID) public view returns(uint256) {
        return _amount * (cycles[_cycleID].returnLimit) / 10;
    }
    
    function maxPayoutOf( address _addr, uint256 _amount, uint _investID) view public returns(uint256) {
        uint _cycleID = users[_addr].investment[_investID].cycleID;
        return _amount * (cycles[_cycleID].returnLimit) / 10;
    }

    function payoutOf(address _addr, uint _investID) public view  returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf( _addr, users[_addr].investment[_investID].investAmount, _investID);
    
        uint _cycleID = users[_addr].investment[_investID].cycleID;
    
        if(users[_addr].investment[_investID].payouts < max_payout) {
            payout =  ((((users[_addr].investment[_investID].investAmount*cycles[_cycleID].ROI)/1e8) * ((block.timestamp - users[_addr].investment[_investID].invest_time) / 86400)) - users[_addr].investment[_investID].deposit_payout);
            
            if(users[_addr].investment[_investID].payouts+payout > max_payout){
                if(users[_addr].investment[_investID].payouts < max_payout)
                    payout = max_payout - users[_addr].investment[_investID].payouts;
                else
                    payout = 0;
            }
        }
    }
    
    function userInvestInfo( address _user, uint _investID) public view returns(uint _cycleID,uint _investAmount,uint _payouts, uint deposit_payout, uint _affiliatePayout,uint _invest_time){
        
        return(
            users[_user].investment[_investID].cycleID,
            users[_user].investment[_investID].investAmount,
            users[_user].investment[_investID].payouts,
            users[_user].investment[_investID].deposit_payout,
            users[_user].investment[_investID].affiliatePayout,
            users[_user].investment[_investID].invest_time
            );
    }
    
    function userInvestStatus( address _user, uint _investID) public view returns(bool _IsReTopUp, bool _reTopUpStatus,bool _completedStatus){
        
        return(
            users[_user].investment[_investID].IsReTopUp,
            users[_user].investment[_investID].reTopUpStatus,
            users[_user].investment[_investID].completedStatus
            );
    }


    function userHoldInfo( address _user, uint _holdID) public view returns(uint holdAmount,uint holdTime,uint holdEarned,bool completedStatus){
        
        return(
            users[_user].hold[_holdID].holdAmount,
            users[_user].hold[_holdID].hold_time,
            users[_user].hold[_holdID].holdEarned,
            users[_user].hold[_holdID].completedStatus
            );
    }

    
    function userReg( address _upline) internal returns(bool){
        require(_upline != address(0), " upline must not be zero address");
        
        currUserID++;
        
        UserStruct memory _userStruct;
        
        _userStruct = UserStruct({
            Exist: true,
            id : currUserID,
            referrer : _upline,
            totalCycle:0,
            investID : 0,
            holdID : 0,
            totalDeposit : 0,
            levelBounus : 0,
            totalEarning : 0,
            levelEarned: 0,
            referrals : new address[](0),
            promoBonusEarned:0,
            promoBonusStatus: false,
            created : now+100 days
        });
        
        users[msg.sender] = _userStruct;
        userList[currUserID] = msg.sender;
        
        users[_upline].referrals.push(msg.sender);
        
        emit regEvent( msg.sender, currUserID, _upline, now);
    }
    
    function payforLevels( address _user, uint _level, uint _amount) internal returns(bool){
        address _upline = users[_user].referrer;
        uint level_bonus = _amount*levelPrice[_level]/1e8;
        
        if(!users[_upline].Exist)
            _upline = ownerWallet;
        
        users[_upline].levelBounus += level_bonus;
        users[_upline].levelEarned += level_bonus;
        
        if(users[_upline].created < now && !users[_upline].promoBonusStatus)
            promoBonusDistribution( _upline);
        
        
        emit Upline(msg.sender, _upline, _level, level_bonus, now);
        
        _level++;
        
        if(_level <= 10)
            payforLevels( _upline, _level, _amount);
    }
    
    
}