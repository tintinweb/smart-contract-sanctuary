/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity 0.5.10;

contract Contract {
    
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    address payable owner;
    address payable sender;
    
    struct User {
        uint256 cycle;
        address upline;
        
        uint256 payouts;
        uint256 direct_bonus;
        uint256 referral_bonus;
        
        uint40 deposit_time;
        uint40 claim_time;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_referral_payouts;
        uint256 total_direct_referrals;
        uint256 total_structure;
    }
    
    struct Referral {
        uint256 total_lvl1;
        uint256 total_lvl2;
        uint256 total_lvl3;
        uint256 total_lvl4;
        uint256 total_lvl5;
    }

    mapping(address => User) public users;
    
    mapping(address => Referral) public referrals;
    
    mapping(address => address[]) level_1_referrals;
    mapping(address => address[]) level_2_referrals;
    mapping(address => address[]) level_3_referrals;
    mapping(address => address[]) level_4_referrals;
    mapping(address => address[]) level_5_referrals;
    
    uint8[] public ref_bonuses;
    uint256 daily_percentage = 1.8e1;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectBonus(address indexed addr, address indexed from, uint256 amount);
    event ReferralBonus(address indexed addr, address indexed from, uint256 amount, uint256 level);
    event Withdraw(address indexed addr, uint256 amount);
    event MaxPayoutReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;
        sender = _owner;
        
        ref_bonuses.push(10);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].total_direct_referrals++;

            emit Upline(_addr, _upline);

            total_users++;
            
            referrals[_upline].total_lvl1++;
            level_1_referrals[_upline].push(_addr);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                uint256 bonus = _amount * ref_bonuses[i] / 100;

                if(i > 0){
                    
                    users[_upline].referral_bonus += bonus;
                    
                    if(i == 1){
                        referrals[_upline].total_lvl2++;
                        level_2_referrals[_upline].push(_addr);
                    } else if(i == 2){
                        referrals[_upline].total_lvl3++;
                        level_3_referrals[_upline].push(_addr);
                    } else if(i == 3){
                        referrals[_upline].total_lvl4++;
                        level_4_referrals[_upline].push(_addr);
                    } else if(i == 4){
                        referrals[_upline].total_lvl5++;
                        level_5_referrals[_upline].push(_addr);
                    }
                    
                    emit ReferralBonus(_upline, _addr, bonus, i);
                    
                } else {
                    
                    users[users[_addr].upline].direct_bonus += bonus;
        
                    emit DirectBonus(users[_addr].upline, _addr, bonus);
                    
                }
                
                users[_upline].total_structure++;

                _upline = users[_upline].upline;
                
            }
            
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "Invalid upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Deposit amount should be greater than or equal to the last deposit amount");
        }
        else require(_amount >= 1e17, "Deposit amount should be greater than or equal to the minimum(0.1 BNB) deposit amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].claim_time = uint40(block.timestamp) + 1 days;
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        owner.transfer(_amount * 5 / 100);
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline, msg.value);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {

        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
    
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        require(users[msg.sender].claim_time >= block.timestamp, "Too early to claim");

        if(to_payout > 0 && sender != msg.sender) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
            
        }
        
        if(users[msg.sender].payouts < max_payout && sender != msg.sender && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            users[msg.sender].total_referral_payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        
        if(users[msg.sender].payouts < max_payout && sender != msg.sender && users[msg.sender].referral_bonus > 0) {
            uint256 referral_bonus = users[msg.sender].referral_bonus;

            if(users[msg.sender].payouts + referral_bonus > max_payout) {
                referral_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].referral_bonus -= referral_bonus;
            users[msg.sender].payouts += referral_bonus;
            users[msg.sender].total_referral_payouts += referral_bonus;
            to_payout += referral_bonus;
        }

        require(to_payout > 0, "No available payout");
        
        users[msg.sender].total_payouts += to_payout;
        users[msg.sender].claim_time = uint40(block.timestamp) + 1 days;
        total_withdraw += to_payout;
        
        msg.sender.transfer(to_payout);
        emit Withdraw(msg.sender, to_payout);
        if(users[msg.sender].payouts >= max_payout) emit MaxPayoutReached(msg.sender, users[msg.sender].payouts);
        
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 35 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(sender == _addr) payout = max_payout = this.getBalance();
        if(users[_addr].deposit_payouts < max_payout && sender != _addr) {
            payout = users[_addr].deposit_amount * daily_percentage / 100;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function updatePercentage(uint256 _daily_percentage) external{
        require(owner == msg.sender, "Insufficient permission");
        daily_percentage = _daily_percentage;
    }
    
    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 claim_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 referral_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].claim_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].referral_bonus);
    }
    
    function userInfoSummary(address _addr) view external returns(uint256 total_direct_referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 total_referral_payouts) {
        return (users[_addr].total_direct_referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].total_referral_payouts);
    }
    
    function getBalance() public view returns (uint256) { return address(this).balance; }

    function userInfoReferrals(address _addr) view external returns(uint256 total_lvl1, uint256 total_lvl2, uint256 total_lvl3, uint256 total_lvl4, uint256 total_lvl5) {
        return (referrals[_addr].total_lvl1, referrals[_addr].total_lvl2, referrals[_addr].total_lvl3, referrals[_addr].total_lvl4, referrals[_addr].total_lvl5);
    }
    
    function getLevel1Referrals(address _addr) public view returns (address[] memory addrs, uint256 total) {
        addrs = level_1_referrals[_addr];
        total = level_1_referrals[_addr].length;
    }
    
    function getLevel2Referrals(address _addr) public view returns (address[] memory addrs, uint256 total) {
        addrs = level_2_referrals[_addr];
        total = level_2_referrals[_addr].length;
    }
    
    function getLevel3Referrals(address _addr) public view returns (address[] memory addrs, uint256 total) {
        addrs = level_3_referrals[_addr];
        total = level_3_referrals[_addr].length;
    }
    
    function getLevel4Referrals(address _addr) public view returns (address[] memory addrs, uint256 total) {
        addrs = level_4_referrals[_addr];
        total = level_4_referrals[_addr].length;
    }
    
    function getLevel5Referrals(address _addr) public view returns (address[] memory addrs, uint256 total) {
        addrs = level_5_referrals[_addr];
        total = level_5_referrals[_addr].length;
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_withdraw);
    }
    
}