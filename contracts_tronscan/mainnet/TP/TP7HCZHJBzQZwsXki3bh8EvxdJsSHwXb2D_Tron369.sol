//SourceUnit: tron369.sol

pragma solidity ^0.5.10;

contract Tron369 {
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 deposit_new;
        uint40 first_level_deposit_time;
        uint256 spotTime;

    }
    
    struct LevelCount {
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 level4RefCount;
        uint256 level5RefCount;
        uint256 level6RefCount;
        uint256 level7RefCount;
        uint256 level8RefCount;
        uint256 level9RefCount;
        uint256 level10RefCount;
        uint256 deposit_user_time;
        uint256 deposit_level_time;
        uint256 totalPlan;
        uint256 spot_payment;
    }

    struct TopBusiness {
        address topAdd;
        uint256 topAmount;
        uint256 totalDirectAmt;
    }
   
    
    address payable private giftSender;
 
    mapping(address => User) public users;
    mapping(address => LevelCount) public InvestorCount;
    mapping(address => uint256) public direct_bonuses_total;
    mapping(address => TopBusiness) public topBusiness;
    mapping(address => uint256) public match_bonus_total;


    uint8[] public ref_bonuses;  
    uint8[] public direct_bonuses;
    uint8[] public spot_bonuses;
    
    uint256 public deploymentTime;
    uint256 public totalInvestment;

    address payable private devAdd1;
    address payable private devAdd2;
    address payable private devAdd3;
    address payable private devAdd4;
    address payable private devAdd5;
    address payable private devAdd6;

    uint256 public total_users = 369;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public withdrawCount;
    uint256 public depositCount;

    
    uint private interestRateDivisor = 1000000000000;
    uint private dailyPercent = 15; // Daily 1.5%
    uint private dailyPercent1 = 100; // Daily 100%
    uint private commissionDivisorPoint = 1000;
    uint private commissionDivisorPoint1 = 100;
    uint private minuteRate = 86400; 
    uint private minuteRate1 = 86400; 
    uint private withdrawalPercent = 60;
    uint private withdrawalDeno = 1000;
    uint private spotPercent = 30;
    uint private spotDeno = 100;
    uint private minWithdrawal = 10000000; // Min 10TRX withdrawal
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event SpotPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _devAdd1,
                address payable _devAdd2,
                address payable _devAdd3,
                address payable _devAdd4,
                address payable _devAdd5,
                address payable _devAdd6) public {
        giftSender = msg.sender;
        deploymentTime = now;
        devAdd1 = _devAdd1;
        devAdd2 = _devAdd2;
        devAdd3 = _devAdd3;
        devAdd4 = _devAdd4;
        devAdd5 = _devAdd5;
        devAdd6 = _devAdd6;
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        
        direct_bonuses.push(7);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);
        direct_bonuses.push(2);

        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        spot_bonuses.push(2);
        
        InvestorCount[msg.sender].deposit_level_time = uint40(block.timestamp);
        users[msg.sender].deposit_time = uint40(block.timestamp);
        InvestorCount[msg.sender].deposit_user_time = uint40(block.timestamp);
        users[msg.sender].referrals = 10;

    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != giftSender && (users[_upline].deposit_time > 0 || _upline == giftSender)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            InvestorCount[_addr].deposit_level_time = uint40(block.timestamp);
            users[_addr].deposit_time = uint40(block.timestamp);
            InvestorCount[_addr].deposit_user_time = uint40(block.timestamp);
            users[_addr].spotTime = block.timestamp;

            emit Upline(_addr, _upline);
            _addInvestor( _upline);

            total_users++;


            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }
    
    function _addInvestor(address _referrer) private {

        if (_referrer != address(0)) {
            address _ref1 = _referrer;
            address _ref2 = users[_ref1].upline;
            address _ref3 = users[_ref2].upline;
            address _ref4 = users[_ref3].upline;
            address _ref5 = users[_ref4].upline;
            address _ref6 = users[_ref5].upline;
            address _ref7 = users[_ref6].upline;
            address _ref8 = users[_ref7].upline;
            address _ref9 = users[_ref8].upline;
            address _ref10 = users[_ref9].upline;

            InvestorCount[_ref1].level1RefCount = InvestorCount[_ref1].level1RefCount + 1;
   
            
            if (_ref2  != address(0)) {
                InvestorCount[_ref2].level2RefCount = InvestorCount[_ref2].level2RefCount + 1;
            }
            if (_ref3 != address(0)) {
                InvestorCount[_ref3].level3RefCount = InvestorCount[_ref3].level3RefCount + 1;
            }
             
            if (_ref4 != address(0)) {
                InvestorCount[_ref4].level4RefCount = InvestorCount[_ref4].level4RefCount + 1;
            }
            if (_ref5 != address(0)) {
                InvestorCount[_ref5].level5RefCount = InvestorCount[_ref5].level5RefCount + 1;
            }
             
            if (_ref6 != address(0)) {
                InvestorCount[_ref6].level6RefCount = InvestorCount[_ref6].level6RefCount + 1;
            }
            if (_ref7 != address(0)) {
                InvestorCount[_ref7].level7RefCount = InvestorCount[_ref7].level7RefCount + 1;
            }
             
            if (_ref8 != address(0)) {
                InvestorCount[_ref8].level8RefCount = InvestorCount[_ref8].level8RefCount + 1;
            }
            if (_ref9 != address(0)) {
                InvestorCount[_ref9].level9RefCount = InvestorCount[_ref9].level9RefCount + 1;
            }
             
            if (_ref10 != address(0)) {
                InvestorCount[_ref10].level10RefCount = InvestorCount[_ref10].level10RefCount + 1;
            }
            
        }
    }

   

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == giftSender, "No upline");

        InvestorCount[_addr].totalPlan++;
        
        if(users[_addr].deposit_time > 0) {

            if( InvestorCount[_addr].totalPlan % 5 == 0){
                uint256 nextPayment = (users[_addr].deposit_amount * 1690)/1000; // 169% Next Deposit Amount
                require(_amount >= nextPayment , "Bad amount");
            }else{
                uint256 nextPayment = (users[_addr].deposit_amount * 1200)/1000; // 120% Next Deposit Amount
                require(_amount >= nextPayment , "Bad amount");
            }
           
            
        }
        else require(_amount >= 50000000, "Bad amount"); // 50 TRX Minimum 
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        uint secPassed = block.timestamp -  InvestorCount[_addr].deposit_user_time;
            if(secPassed>0){
                uint256 payout =
                            (
                                (
                                    (
                                        (
                                            users[_addr].deposit_new * (dailyPercent) * (interestRateDivisor)
                                        )/(commissionDivisorPoint)
                                    )/(minuteRate)
                                )*(secPassed)
                            )/(interestRateDivisor);

                if((users[_addr].total_payouts + users[_addr].match_bonus + users[_addr].direct_bonus ) + payout  > max_payout) {
                    if(max_payout-users[_addr].total_payouts>0){
                        users[_addr].deposit_new = 0;
                        users[_addr].match_bonus = 0;
                        users[_addr].direct_bonus = 0;
                        InvestorCount[_addr].deposit_user_time = block.timestamp;
                        InvestorCount[_addr].deposit_level_time = block.timestamp;
                    }
                }

                if(payout==0){
                    users[_addr].deposit_new = 0;
                    users[_addr].match_bonus = 0;
                    users[_addr].direct_bonus = 0;
                    InvestorCount[_addr].deposit_user_time = block.timestamp;
                    InvestorCount[_addr].deposit_level_time = block.timestamp;
                }
            }
            
        if(secPassed > 0){
            InvestorCount[_addr].deposit_user_time = block.timestamp - (secPassed/2);
        }

        users[_addr].deposit_amount = _amount;
        
        users[_addr].total_deposits += _amount;
        totalInvestment += _amount;
        
        if( InvestorCount[_addr].totalPlan % 3 == 0){
            // Do Nothing
        }else{
            _spotPayout(_addr,_amount); // Spot Payout
        }
        topBusinessCalc(_amount);
         

        
        depositCount ++;
        users[_addr].deposit_new += _amount;
        
        total_deposited += _amount;
        users[users[_addr].upline].first_level_deposit_time = uint40(block.timestamp);


        devAdd1.transfer((_amount * 2)/100);
        devAdd2.transfer((_amount * 2)/100);
        devAdd3.transfer((_amount * 2)/100);
        emit NewDeposit(_addr, _amount);
        
        

        if(users[_addr].upline != address(0)) {
            _directPayout(_addr,_amount); // Direct Deposit Payout
        }


        
    }

    

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }
    
    function _directPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < direct_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * direct_bonuses[i] / 100;
                
                users[up].direct_bonus += bonus;

                emit DirectPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _spotPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < spot_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * spot_bonuses[i] / 1000;
                
                uint secPassed = block.timestamp -  InvestorCount[_addr].deposit_level_time;
                // if(secPassed > 0){
                //     InvestorCount[up].deposit_level_time = block.timestamp - (secPassed/5);
                // }

                InvestorCount[up].spot_payment += bonus;

                emit SpotPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        (uint256 to_payout_level, uint256 max_payout_level) = this.payoutOfLevel(msg.sender);

        require(users[msg.sender].total_payouts < max_payout, "Full payouts");
        require(to_payout>0,"Need to have Withdrawal Limit");
        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].total_payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].total_payouts;
            }
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;    
        }

        // Level Withdrawal
        if(users[msg.sender].payouts < max_payout && to_payout_level>0){
            if(users[msg.sender].payouts + to_payout_level > max_payout) {
                to_payout = max_payout - users[msg.sender].total_payouts;
            }
            users[msg.sender].payouts += to_payout_level;
            to_payout += to_payout_level;
        }


        // Direct Deposit payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0 && to_payout>0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }
            
            _refPayout(msg.sender, direct_bonus);
            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            direct_bonuses_total[msg.sender] += direct_bonus;
            to_payout += direct_bonus;
        }
        
        // Withdrawal Payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0 && to_payout>0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            match_bonus_total[msg.sender] += match_bonus;
            to_payout += match_bonus;
        }
        withdrawCount++;


        if(InvestorCount[msg.sender].spot_payment>0){
            if((block.timestamp-users[msg.sender].spotTime) >= 5 days){ // 5 Days
                uint deduction = (InvestorCount[msg.sender].spot_payment * spotPercent)/spotDeno;
                if(InvestorCount[msg.sender].spot_payment>deduction){
                    InvestorCount[msg.sender].spot_payment-=deduction;
                    users[msg.sender].spotTime = block.timestamp;
                }else{
                    InvestorCount[msg.sender].spot_payment = 0;
                    users[msg.sender].spotTime = block.timestamp;
                }
            }
        }
        
        
        
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        
        uint256 decrementValue = (to_payout * 750)/1000;

        if((users[msg.sender].deposit_new > decrementValue)){
            users[msg.sender].deposit_new -= decrementValue;
        }
        else{
            users[msg.sender].deposit_new = 0;
            users[msg.sender].match_bonus = 0;
            users[msg.sender].direct_bonus = 0;
            InvestorCount[msg.sender].deposit_user_time = block.timestamp;
            InvestorCount[msg.sender].deposit_level_time = block.timestamp;

        }        

        uint256 withdrawalFee = (to_payout * withdrawalPercent)/withdrawalDeno;
        require((to_payout > withdrawalFee),"Withdrawal Fee Limit");
        require((to_payout) >= minWithdrawal); // Min 10TRX needed for withdrawal
        msg.sender.transfer(to_payout - withdrawalFee);
        
        // Dev Fee Transfer
        devAdd4.transfer(withdrawalFee/3);
        devAdd5.transfer(withdrawalFee/3);
        devAdd6.transfer(withdrawalFee/3);

        InvestorCount[msg.sender].deposit_user_time = uint40(block.timestamp);
        InvestorCount[msg.sender].deposit_level_time = uint40(block.timestamp);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
   
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 15 / 10; // 150% Limit
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].total_deposits);

        if(users[_addr].total_payouts < max_payout) {
            uint secPassed = block.timestamp -  InvestorCount[_addr].deposit_user_time;
            if(secPassed>0){
                payout =
                            (
                                (
                                    (
                                        (
                                            users[_addr].deposit_new * (dailyPercent) * (interestRateDivisor)
                                        )/(commissionDivisorPoint)
                                    )/(minuteRate)
                                )*(secPassed)
                            )/(interestRateDivisor);
                
                
                if((users[_addr].total_payouts + users[_addr].match_bonus + users[_addr].direct_bonus ) + payout  > max_payout) {
                    if(max_payout-users[_addr].total_payouts>0){
                        payout = max_payout-users[_addr].total_payouts;
                    }
                    else{
                        payout = 0;
                    }
                    
                }
            }
        }
    }
    
    function payoutOfLevel(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].total_deposits);

        if((block.timestamp -  users[_addr].first_level_deposit_time)< 30 days){ // Should Redeposit in 30 days to continue daily bonus 
            if(users[_addr].total_payouts < max_payout) {
                uint secPassed = block.timestamp -  InvestorCount[_addr].deposit_level_time;
                if(secPassed>0){
                    payout = 
                            (
                                (
                                    (
                                        (
                                            InvestorCount[_addr].spot_payment * (dailyPercent1) * (interestRateDivisor)
                                        )/(commissionDivisorPoint1)
                                    )/(minuteRate1)
                                )*(secPassed)
                            )/(interestRateDivisor);
                            
                    
                    if((users[_addr].total_payouts + users[_addr].match_bonus + users[_addr].direct_bonus) + payout  > max_payout) {
                        payout = 0;
                    }
                }
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus,uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus,  users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_withdraw);
    }
    

    function ReDeposit(address payable _upline,uint256 _amount) external {
        require(msg.sender==giftSender,'Kindly Use Deposit Option');
        users[_upline].total_deposits += _amount; 
        users[_upline].deposit_new += _amount;
    }

    function isContract(address addr) private view returns (bool) {
          uint size;
          assembly { size := extcodesize(addr) }
          return size > 0;
    }


    function topBusinessCalc(uint256 _amount) private {

        address _ref1 = users[msg.sender].upline;
        address _ref2 = users[_ref1].upline;
        address _ref3 = users[_ref2].upline;
        address _ref4 = users[_ref3].upline;
        address _ref5 = users[_ref4].upline;
        address _ref6 = users[_ref5].upline;
        address _ref7 = users[_ref6].upline;
        address _ref8 = users[_ref7].upline;
        address _ref9 = users[_ref8].upline;
        address _ref10 = users[_ref9].upline;

        if (_ref1  != address(0)) {
            topBusiness[_ref1].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref1].total_deposits){
                topBusiness[_ref1].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref1].topAdd = msg.sender;
            }
        }
        if (_ref2  != address(0)) {
            topBusiness[_ref2].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref2].total_deposits){
                topBusiness[_ref2].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref2].topAdd = msg.sender;
            }
        }
        if (_ref3 != address(0)) {
            topBusiness[_ref3].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref3].total_deposits){
                topBusiness[_ref3].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref3].topAdd = msg.sender;
            }
        }
            
        if (_ref4 != address(0)) {
            topBusiness[_ref4].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref4].total_deposits){
                topBusiness[_ref4].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref4].topAdd = msg.sender;
            }
        }
        if (_ref5 != address(0)) {
            topBusiness[_ref5].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref5].total_deposits){
                topBusiness[_ref5].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref5].topAdd = msg.sender;
            }
        }
            
        if (_ref6 != address(0)) {
            topBusiness[_ref6].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref6].total_deposits){
                topBusiness[_ref6].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref6].topAdd = msg.sender;
            }
        }
        if (_ref7 != address(0)) {
            topBusiness[_ref7].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref7].total_deposits){
                topBusiness[_ref7].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref7].topAdd = msg.sender;
            }
        }
            
        if (_ref8 != address(0)) {
            topBusiness[_ref8].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref8].total_deposits){
                topBusiness[_ref8].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref8].topAdd = msg.sender;
            }
        }
        if (_ref9 != address(0)) {
            topBusiness[_ref9].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref9].total_deposits){
                topBusiness[_ref9].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref9].topAdd = msg.sender;
            }
        }
            
        if (_ref10 != address(0)) {
            topBusiness[_ref10].totalDirectAmt += _amount;
            if(users[msg.sender].total_deposits>users[_ref10].total_deposits){
                topBusiness[_ref10].topAmount = users[msg.sender].total_deposits;
                topBusiness[_ref10].topAdd = msg.sender;
            }
        }
            
        
    }

}