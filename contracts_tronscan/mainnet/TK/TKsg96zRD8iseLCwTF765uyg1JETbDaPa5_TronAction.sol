//SourceUnit: tronAction.sol







pragma solidity >=0.4.24 < 0.8.0;

contract TronAction {
    using SafeMath for uint;
    uint256 constant public ADMIN_FEE = 20;
	uint256 constant public MARKETING_FEE = 40;
	uint256 constant public DEV_FEE = 90;
	uint256 constant public PERCENTS_DIVIDER = 1000;
    uint8[] public REFERRAL_LEVEL = [5, 3, 2, 1, 4];
    uint256 public constant MIN_INVEST = 100 trx;
    uint8 public constant PARTICIPATION_DAYS = 100;
    uint256 public constant WITHDRAWAL_DEADTIME = 1 days;
    uint256 public constant PARTICIPATION_PERCENT = 300;
    address payable owner;     
    
    // contract cost
    address payable public marketingAddress;     
	address payable public adminAddress;        
	address payable public devAddress;    

    uint256 total_investors;
    uint256 total_participation;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;
    uint8[] referral_bonuses;

    struct Invests {
        uint256 amount;
        uint256 total_withdraw;
        uint256 time;
    }

     struct Witdraws{
        uint256 time;
        uint256 amount;
    }

    struct User {
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 last_withdrawal;
        uint256 total_participation;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        Invests[] invests;
        Witdraws[] withdrawals;
        mapping(uint8 => uint256) referrals_per_level;
    }

    mapping(address => User) internal users;
    event Invest(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);    
    
    
    
    
    
	constructor(address payable adminAddr, address payable marketingAddr,  address payable devAddr) public {
	    require(!isContract(marketingAddr) && !isContract(adminAddr) && !isContract(devAddr));

		marketingAddress = marketingAddr;
		adminAddress = adminAddr;
		devAddress = devAddr;
        owner = msg.sender;

        for(uint8 i = 0; i < REFERRAL_LEVEL.length; i++) {
           referral_bonuses.push(10 * REFERRAL_LEVEL[i]);
        }
	}
	    
    
    
    
    
    
	function invest(address _referral) external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isContract(_referral));
        require(msg.value >= 1e8, "Zero amount");
        require(msg.value >= MIN_INVEST, "Deposit is below minimum amount");

        User storage user = users[msg.sender];

        require(user.invests.length < 1500, "Max 1500 deposits per address");
 
        if(users[msg.sender].referral == address(0)) {
            if(users[_referral].total_participation > 0) {
                users[msg.sender].referral = _referral;
            } else {
                users[msg.sender].referral = adminAddress;
            }
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                users[_referral].referrals_per_level[i]++;
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }

        user.invests.push(Invests({
            amount: msg.value,
            total_withdraw: 0,
            time: uint256(block.timestamp)
        }));

        if(user.total_participation == 0x0){
            total_investors += 1;
        }

        user.total_participation += msg.value;
        total_participation += msg.value;

       address ref = users[msg.sender].referral;

        User storage upline_player = users[ref];

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            uint256 bonus = msg.value * referral_bonuses[i] / 1000;

            users[ref].referral_bonus += bonus;
            users[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = users[ref].referral;
        }
        
        if (address(this).balance > fees(msg.value)) {
            marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
            adminAddress.transfer(msg.value.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
            devAddress.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
        }

        emit Invest(msg.sender, msg.value);
    }
        
    
    
    
    
    
    function fees(uint256 _amount) private view returns(uint256 _fees_tot) {
        _fees_tot = _amount.mul(MARKETING_FEE+ADMIN_FEE+DEV_FEE).div(PERCENTS_DIVIDER);

    }
        
    
    
    
    
    
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }    
    
    
    
    
    
     function contributionsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        User storage user = users[_addr];

        uint256[] memory _endTimes = new uint256[](user.invests.length);
        uint256[] memory _amounts = new uint256[](user.invests.length);
        uint256[] memory _totalWithdraws = new uint256[](user.invests.length);

        // Create arrays with deposits info, each index is related to a deposit
        for(uint256 i = 0; i < user.invests.length; i++) {
          Invests storage dep = user.invests[i];
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.total_withdraw;
          _endTimes[i] = dep.time + PARTICIPATION_DAYS * 86400;
        }

        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
        
    
    
    
    
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals, uint256 _last_withdrawal) {
        User storage user = users[_addr];
        uint256 payout;
        for(uint256 i = 0; i < user.invests.length; i++) {
            Invests storage dep = user.invests[i];

            uint256 time_end = dep.time + PARTICIPATION_DAYS * 86400;
            uint256 from = user.last_payout > dep.time ? user.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                payout += dep.amount * (to - from) * PARTICIPATION_PERCENT / PARTICIPATION_DAYS / 8640000;
            }
        }

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = user.referrals_per_level[i];
        }
        return (
            payout + user.dividends + user.referral_bonus,
            user.referral_bonus,
            user.total_participation,
            user.total_withdrawn,
            user.total_referral_bonus,
            referrals,
            user.last_withdrawal
        );
    }
        
    
    
    
    
    
    function withdrawalsOf(address _addrs) view external returns(uint256 _amount) {
        User storage user = users[_addrs];
        // Calculate all the real withdrawn amount (to wallet, not reinvested)
        for(uint256 n = 0; n < user.withdrawals.length; n++){
            _amount += user.withdrawals[n].amount;
        }
        return _amount;
    }
    
    
    
    
    
    
    function contractInfo() view external returns(uint256 _total_contributed, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus) {
        return (total_participation, total_investors, total_withdrawn, total_referral_bonus);
    }
        
    
    
    
    
    
    function withdraw() public {
        User storage user = users[msg.sender];
        Invests storage first_dep = user.invests[0];

        require(uint256(block.timestamp) > (user.last_withdrawal + WITHDRAWAL_DEADTIME) || (user.withdrawals.length <= 0), "You cannot withdraw during deadtime");
        require(address(this).balance > 0, "Cannot withdraw, contract balance is 0");
        require(user.invests.length < 1500, "Max 1500 deposits per address");
        
        uint256 payout;
        for(uint256 i = 0; i < user.invests.length; i++) {
            Invests storage dep = user.invests[i];

            uint256 time_end = dep.time + PARTICIPATION_DAYS * 86400;
            uint256 from = user.last_payout > dep.time ? user.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                payout += dep.amount * (to - from) * PARTICIPATION_PERCENT / PARTICIPATION_DAYS / 8640000;
            }
        }
        user.dividends += payout;

        uint256 amount_withdrawable = user.dividends + user.referral_bonus;
        require(amount_withdrawable > 0, "Zero amount to withdraw");

        if (address(this).balance < amount_withdrawable) {
            user.dividends = amount_withdrawable.sub(address(this).balance);
			amount_withdrawable = address(this).balance;
		} else {
            user.dividends = 0;
        }
        msg.sender.transfer(amount_withdrawable);

        user.referral_bonus = 0;
        user.total_withdrawn += amount_withdrawable;
        total_withdrawn += amount_withdrawable;
        user.last_withdrawal = uint256(block.timestamp);
        
        if(payout > 0) {
            for(uint256 i = 0; i < user.invests.length; i++) {
            Invests storage dep = user.invests[i];

            uint256 time_end = dep.time + PARTICIPATION_DAYS * 86400;
            uint256 from = user.last_payout > dep.time ? user.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                user.invests[i].total_withdraw += dep.amount * (to - from) * PARTICIPATION_PERCENT / PARTICIPATION_DAYS / 8640000;
            }
        }
            user.last_payout = uint256(block.timestamp);
        }
        
        user.withdrawals.push(Witdraws({
            time: uint256(block.timestamp),
            amount: amount_withdrawable
        }));


        emit Withdraw(msg.sender, amount_withdrawable);
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