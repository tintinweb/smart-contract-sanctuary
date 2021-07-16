//SourceUnit: dtron_lti.sol

/**************************************************
/***********************************
/****************************

   DTRON - LONG TERM INVESTMENT CONTRACT
   CREATED JANUARY - 2021
   
   300%  ROI IN 30 DAYS (OPTIONAL)
   85%   PLATFORM CIRCULATING BALANCE
   3.5%  GLOBAL REWARDS
   5%    INSURANCE FUND
   3%    MARKETING FEE
   2%    DEVELOPER FEE
   1%    PLATFORM FEE
   0.5%  FOUNDERS CUT

   DTRON COPYRIGHT(C) 2021
   
   https://dtron.cc/

   "FUCK ALL COPYCATS."

***//*************************//**************//**/

pragma solidity 0.5.9;

contract DTRON_LTI {

    address payable private _marketingAddress;
    address payable private _developerAddress;
    address payable private _insuranceAddress;
    address payable private _ownerAddress; /* Platform fee (1%) will also be sent here */
    
    uint256 public total_users;
    uint256 public total_invested;
    uint256 public total_reinvested;
    uint256 public total_withdrawn;
    uint256 public total_referrals;
    uint256 public total_insurance;
    uint8[] public referral_rates;
    uint256 public globalrewards_last_withdraw;
    address payable[] public top_investors;
    address payable[] public top_referrals;
    address payable public top_reinvestor;

    struct User {
        address upline;
        uint256 invested;
        uint256 reinvested;
        uint256 withdrawn;
        uint256 referrals;
        uint256 withdrawn_referrals;
        uint256 last_withdraw;
        Investment[] investments;
        mapping(uint8 => uint256) downlines;
    } 

    struct Investment {
        uint256 amount;
        uint256 time;
    }
    
    uint256 public starting_date;

    mapping(address => User) public users;
    
    constructor(address payable _marketingAddr, address payable _developerAddr, address payable _insuranceAddr) public {

        _ownerAddress = msg.sender;
        
        _marketingAddress = _marketingAddr;
        _developerAddress = _developerAddr;
        _insuranceAddress = _insuranceAddr;
        top_investors.push(_insuranceAddr);
        top_investors.push(_insuranceAddr);
        top_investors.push(_insuranceAddr);
        top_referrals.push(_insuranceAddr);
        top_referrals.push(_insuranceAddr);
        top_referrals.push(_insuranceAddr);
        top_reinvestor = _insuranceAddr;
        
        referral_rates.push(10);
        referral_rates.push(5);
        referral_rates.push(3);
        referral_rates.push(3);
        referral_rates.push(3);
        referral_rates.push(3);
        referral_rates.push(2);
        referral_rates.push(2);
        referral_rates.push(1);
        referral_rates.push(1);
        referral_rates.push(1);
        referral_rates.push(1);
        
        starting_date = 1611576000; // JANUARY 25 @ 12 PM UTC
        globalrewards_last_withdraw = starting_date;
        
    }

    /*
     * fallback function incase someone sends trx direct to contract with no user interface
    **/
	function () external payable {
		invest(address(0));
	}
    
    /*
     * All-in-one invest function
     * @setup user data
     * @setup uplines
     * @credits uplines
     * @payout to administrative accounts
    **/
    function invest(address _upline) public payable {
    
        require(msg.value >= 50 trx);
        
        User storage user = users[msg.sender];
        
        /*
         * @check if new user
        **/
        uint8 new_user = 0;
        if(user.investments.length == 0) {
            if(users[_upline].investments.length == 0) {
                _upline = address(0);
            }
            users[msg.sender].upline = _upline;
            new_user = 1;
            total_users++;
        }
        // uplines are permanent
        _upline = users[msg.sender].upline;
        
        /*
         * Set-up Uplines & Payouts
         * @if upline has reached 300% roi, transfer excess profit to _insuranceAddress
        **/
        uint256 excess = 0;
        for(uint8 i = 0; i < referral_rates.length; i++) {
            uint256 commission = msg.value * referral_rates[i] / 100;
            if(_upline == address(0) || users[_upline].investments.length == 0) {
                excess += commission;
            } else {
                /* check if upline has reached 300% */
                uint256 remaining_income = _calculateRemainingIncome(_upline);
                if(remaining_income < commission) {
                    excess += commission - remaining_income;
                    commission = remaining_income;
                }
                users[_upline].referrals += commission;
                if(new_user == 1) {
                    users[_upline].downlines[i]++;
                }
                total_referrals += commission;
                _upline = users[_upline].upline;
            }
        }
        
        if(excess > 0) {
            _insuranceAddress.transfer(excess);
            total_insurance += excess;
        }
        
        /* Insurance: 5% */
        _insuranceAddress.transfer(msg.value * 50 / 1000);
        /* Marketing: 3% */
        _marketingAddress.transfer(msg.value * 30 / 1000);
        /* Developer: 2% */
        _developerAddress.transfer(msg.value * 20 / 1000);
        /* Platform: 1% | Owner's Cut: 0.5% */
        _ownerAddress.transfer(msg.value * 15 / 1000);
        
        /*
         * Commit investment
        **/
        user.investments.push(Investment({
            amount: msg.value,
            time: (now > starting_date) ? now : starting_date
        }));
        
        user.invested += msg.value;
        total_invested += msg.value;
        
        /*
         * Update Ranking Status
        **/
        _rankUpdate(msg.sender);
    }
    
    
    
    /*
     * All-in-one withdraw function
     * @setup if has reinvestment conditions
    **/
    function withdraw(uint256 _reinvest) public payable {
        require(now >= starting_date);
        User storage user = users[msg.sender];
        require(user.investments.length > 0);
        /*
         * @check if reinvest amount is <= withdrawable
        **/
        uint256 totalIncome = _totalIncome(msg.sender);
        require(totalIncome > 0);
        
        if(_reinvest >= 10 trx) {
            if(_reinvest <= totalIncome) {
                totalIncome -= _reinvest;
                user.investments.push(Investment({
                    amount: _reinvest,
                    time: now
                }));
                user.reinvested += _reinvest;
                total_reinvested += _reinvest;
            }
        }
        /*
         * Commit data
        **/
        if(totalIncome >= address(this).balance) {
            // fallback incase contract gets depleted
            require(address(this).balance > 5 trx);
            totalIncome = address(this).balance - 5 trx;
        }
        if(totalIncome > 0) {
            msg.sender.transfer(totalIncome);
            user.withdrawn += totalIncome;
            total_withdrawn += totalIncome;
        }
        user.withdrawn_referrals = user.referrals;
        user.last_withdraw = now;
        
        /*
         * Update Ranking Status
        **/
        _rankUpdate(msg.sender);
    }
    
    /*
     * Updates data for rank globals
    **/
    function _rankUpdate(address payable _addr) private {
        require(_addr != address(0));
        User storage user = users[_addr];
        if(user.investments.length > 0) {
            /*
             * check against top 3 investors and referrals
            **/
            for(uint8 i=0; i < 3; i++) {
                if(users[top_investors[i]].invested <= user.invested) {
                    if(_addr != top_investors[i]) {
                        // move remaining down
                        for(uint8 j=2; j>i; j--) {
                            top_investors[j] = top_investors[j-1];
                        }
                        top_investors[i] = _addr;
                    }
                    break;
                }
            }
            for(uint8 i=0; i < 3; i++) {
                if(users[top_referrals[i]].referrals <= user.referrals) {
                    if(_addr != top_referrals[i]) {
                        // move remaining down
                        for(uint8 j=2; j>i; j--) {
                            top_referrals[j] = top_referrals[j-1];
                        }
                        top_referrals[i] = _addr;
                    }
                    break;
                }
            }
            /*
             * check against top reinvestor
            **/
            if(users[top_reinvestor].reinvested <= user.reinvested) {
                top_reinvestor = _addr;
            }
            
            /*
             * Payout rewards
            **/
            if(globalrewards_last_withdraw + 1 days < now) {
                uint256 reward = address(this).balance * 5 / 1000; // 0.5% for each of the 7 top globals
                for(uint8 i=0; i<3; i++) {
                    top_investors[i].transfer(reward);
                    top_referrals[i].transfer(reward);
                }
                top_reinvestor.transfer(reward);
                globalrewards_last_withdraw = now;
            }
        }
    }
    
    /*
     * Gets total withdrawable for user
    **/
    function _totalIncome(address _addr) view private returns(uint256 value) {
        
        uint256 max_income = _calculateTotalInvestment(_addr);
        max_income *= 3; // 300%
        uint256 remaining_income = _calculateRemainingIncome(_addr);
        
        value = max_income - remaining_income;

        return value;
    }
    
    /*
     * Gets remaining income available for user
    **/
    function _calculateRemainingIncome(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        uint256 max_income = _calculateTotalInvestment(_addr);
        max_income *= 3; // 300%
        uint256 current_income = 0;
        
        for(uint256 i = 0; i < user.investments.length; i++) {
            Investment storage inv = user.investments[i];

            uint256 time_end = inv.time + 30 days;
            uint256 from = user.last_withdraw > inv.time ? user.last_withdraw : inv.time;
            uint256 to = now < time_end ? now : time_end;

            if(from < to) {
                current_income += inv.amount * (to - from) * 10 / 100 / 30 days;
            }
        }
        
        current_income += user.referrals - user.withdrawn_referrals;
        
        value = (current_income < max_income) ? max_income - current_income : 0;
        
        return value;
    }
    
    /*
     * Calculates users total investments
    **/
    function _calculateTotalInvestment(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        
        for(uint256 i = 0; i < user.investments.length; i++) {
            Investment storage inv = user.investments[i];
            value += inv.amount;
        }
        
        return value;
        
    }
    
    /*
     * @returns contract information
    **/
    function contractInfo() view external
    returns(
        uint256 _invested,
        uint256 _withdrawn,
        uint256 _referrals,
        uint256 _reinvested,
        uint _starting_date,
        uint256 _total_users,
        uint256 _total_insurance
        ) {
        return (
            total_invested,
            total_withdrawn,
            total_referrals,
            total_reinvested,
            starting_date,
            total_users,
            total_insurance
        );
    }
    
    /*
     * @returns top globals information
    **/
    function topGlobalsInfo() view external
    returns(
        address _top1investor,
        uint256 _top1investoramt,
        address _top2investor,
        uint256 _top2investoramt,
        address _top3investor,
        uint256 _top3investoramt,
        address _top1referral,
        uint256 _top1referralamt,
        address _top2referral,
        uint256 _top2referralamt,
        address _top3referral,
        uint256 _top3referralamt,
        address _topreinvestor,
        uint256 _topreinvestoramt
        ) {
        return (
            top_investors[0],
            users[top_investors[0]].invested,
            top_investors[1],
            users[top_investors[1]].invested,
            top_investors[2],
            users[top_investors[2]].invested,
            top_referrals[0],
            users[top_referrals[0]].referrals,
            top_referrals[1],
            users[top_referrals[1]].referrals,
            top_referrals[2],
            users[top_referrals[2]].referrals,
            top_reinvestor,
            users[top_reinvestor].reinvested
        );
    }
    
    /*
     * @returns user information
    **/
    function userInfo(address _addr) view external
    returns(
        uint256 _total_income,
        uint256 _total_invested,
        uint256 _total_withdrawn,
        uint256 _total_reinvested,
        uint256 _total_referrals,
        uint256 _total_withdrawnreferrals,
        uint256 _remaining_income,
        uint256 _last_withdraw,
        address _user_upline,
        uint256[12] memory _downlines,
        uint[3][100] memory _investments
    ) {
        User storage user = users[_addr];
        _total_invested = user.invested;
        _total_withdrawn = user.withdrawn;
        _total_reinvested = user.reinvested;
        _total_referrals = user.referrals;
        _total_withdrawnreferrals = user.withdrawn_referrals;
        _total_income = _totalIncome(_addr);
        _remaining_income = _calculateRemainingIncome(_addr);
        _last_withdraw = user.last_withdraw;
        _user_upline = user.upline;
        
        for(uint8 i = 0; i < referral_rates.length; i++) {
            _downlines[i] = user.downlines[i];
        }
        
        for(uint256 i = 0; i < user.investments.length; i++) {
            Investment storage inv = user.investments[i];
            
            uint256 time_end = inv.time + 30 days;
            uint256 from = user.last_withdraw > inv.time ? user.last_withdraw : inv.time;
            uint256 to = now < time_end ? now : time_end;
            
            _investments[i][0] = inv.amount;
       
            if(from < to) {
                _investments[i][1] = time_end - now;
                _investments[i][2] = inv.amount * (to - from) * 10 / 100 / 30 days;
            } else {
                _investments[i][1] = 0;
                _investments[i][2] = 0;
            }
            if(i == 100) break;
        }

        return (
            _total_income,
            _total_invested,
            _total_withdrawn,
            _total_reinvested,
            _total_referrals,
            _total_withdrawnreferrals,
            _remaining_income,
            _last_withdraw,
            _user_upline,
            _downlines,
            _investments
        );
    }
    
    /*
     * @modifiers for administrative access
    **/
    modifier onlyMarketing() {
        require(msg.sender == _marketingAddress || msg.sender == _ownerAddress);
        _;
    }
    modifier onlyDeveloper() {
        require(msg.sender == _developerAddress || msg.sender == _ownerAddress);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == _ownerAddress);
        _;
    }
    
    /*
     * @setters for administrative accounts
    **/
    function _setMarketing(address payable _addr) public payable onlyMarketing {
        require(_addr != address(0));
        _marketingAddress = _addr;
    }
    function _setDeveloper(address payable _addr) public payable onlyDeveloper {
        require(_addr != address(0));
        _developerAddress = _addr;
    }
    function _setInsurance(address payable _addr) public payable onlyOwner {
        require(_addr != address(0));
        _insuranceAddress = _addr;
    }
    function _transferOwnership(address payable _addr) public payable onlyOwner {
        require(_addr != address(0));
        _ownerAddress = _addr;
    }
    
    /*
     * for outside investors / outside funds for contract
    **/
    function injectFunds() public payable {
        total_invested += msg.value;
    }
    
    /*
     * for outside investors / outside funds for contract
    **/
    function injectInsurance() public payable {
        total_insurance += msg.value;
    }

}