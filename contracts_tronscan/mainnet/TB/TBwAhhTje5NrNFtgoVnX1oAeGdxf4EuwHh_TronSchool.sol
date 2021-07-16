//SourceUnit: TronSchoolts.sol

pragma solidity 0.5.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(address account, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TronSchool {
    struct User {
        uint256 cycle;
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
    }

    address payable public owner;
    address payable public admin_fee;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                    

    
    address[] public last_100_users;
    
    uint256 public ins_reward;
    
    address[] public current_ins_last_100_users;
    
    uint40 public ins_pool_last_draw = uint40(block.timestamp);
    
    uint40 public last_user_deposit_time;
     
    uint256 public ins_pool_cycle;
    uint256 public ins_pool_balance;
    
    uint256 public vote_cycle;

    mapping(uint256 => uint256) public vote_cycle_sum;
    uint256 public vote_pool_balance;
    uint8 public vote_rank_num = 100;
    
    uint8 public last_user_num = 0;
    
    mapping(uint256 => mapping(address => uint256)) public vote_pool_sum;
    mapping(uint8 => address) public vote_top;


    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    IERC20 public usdt = IERC20(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);
    
    IERC20 public tstoken = IERC20(0x410B82FAB5A296CBEABA7FC7A1CDBD46912A1DB6DD);
    
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;
        
        admin_fee = 0x9C18B4A74D78a067Ad11834472F7b6A0fe46d5Ab;
        
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);


        cycles.push(3e9);
        cycles.push(6e9);
        cycles.push(12e9);
        cycles.push(24e9);
        
         for(uint8 i = 0; i < 100; i++) {
            current_ins_last_100_users.push(address(0));
         }
    }


    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
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
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e7 && _amount <= cycles[0], "Bad amount");
        
        usdt.transferFrom(address(msg.sender), address(this), _amount);
        
        safeTSTransfer(msg.sender, _amount);
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        last_user_deposit_time = uint40(block.timestamp);
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pushLastUsers(_addr, _amount);
        
        vote_pool_balance += _amount * 5 / 100;

        if(ins_pool_last_draw + 3 days < block.timestamp) {
            _drawInsPool();
        }

        
        safeTransfer(admin_fee,_amount * 10/ 100);
        
        ins_pool_last_draw = uint40(block.timestamp);
        
    }

    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = usdt.balanceOf(address(this));
        if(tokenBal > 0) {
            if (_amount > tokenBal) {
                usdt.transfer(_to, tokenBal);
            } else {
                usdt.transfer(_to, _amount);
            }
        }
    }
    
    function safeTSTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = tstoken.balanceOf(address(this));
        if(tokenBal > 0) {
            if (_amount > tokenBal) {
                tstoken.transfer(_to, tokenBal);
            } else {
                tstoken.transfer(_to, _amount);
            }
        }
    }
    
    function _pushLastUsers(address _addr, uint256 _amount) private {
        
        ins_pool_balance += _amount * 5 / 100;
        
        if(last_100_users.length <100) {
            last_100_users.push(_addr);
            last_user_num ++;
        } else {
            
            for(uint8 i=0; i<99; i++) {
                last_100_users[i] = last_100_users[i+1];
            }
            last_100_users[99] = _addr;
            
            last_user_num = 100;
        }
    }
    
    

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].total_structure >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawInsPool() private {
        
        
        ins_pool_cycle++;
        
        ins_reward = ins_pool_balance / last_user_num;

        for(uint8 i = 0; i < last_user_num; i++) {
            
            if(users[last_100_users[i]].deposit_amount > 0) {

                current_ins_last_100_users[i] = last_100_users[i];
                
                safeTransfer(last_100_users[i], ins_reward);
                ins_pool_balance -= ins_reward;
            }

        }
    }
    
    function drawInsPool() public {
        require(msg.sender == owner);
        _drawInsPool();
    }
    
    function setOwner(address payable _addr) public {
        require(msg.sender == owner);
        owner = _addr;
    }
    

    function deposit(address _upline, uint256 _amount) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, _amount);
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
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        
        uint256 contractBalance = usdt.balanceOf(address(this));
		if (contractBalance < to_payout) {
			to_payout = contractBalance;
		}

        safeTransfer(msg.sender, to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

   
    function vote(address _addr, uint256 _amount) public {
        
        require(_amount > 0, "vote num must > 0");
        
        tstoken.transferFrom(address(msg.sender), address(this), _amount);
        
        vote_cycle_sum[vote_cycle] += _amount;
        
        vote_pool_sum[vote_cycle][_addr] += _amount;

        for(uint8 i = 0; i < vote_rank_num; i++) {
            
            if(vote_top[i] == _addr) break;

            if(vote_top[i] == address(0)) {
                vote_top[i] = _addr;
                break;
            }

            if(vote_pool_sum[vote_cycle][_addr] > vote_pool_sum[vote_cycle][vote_top[i]]) {
                for(uint8 j = i + 1; j < vote_rank_num; j++) {
                    if(vote_top[j] == _addr) {
                        for(uint8 k = j; k <= vote_rank_num; k++) {
                            vote_top[k] = vote_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(vote_rank_num - 1); j > i; j--) {
                    vote_top[j] = vote_top[j - 1];
                }

                vote_top[i] = _addr;

                break;
            }
        }
    }
    

    function rewardVotePool() public {
        
        require(msg.sender == owner);
        
        uint256 vote_amount = vote_pool_balance;


        for(uint8 i = 0; i < vote_rank_num; i++) {
            if(vote_top[i] == address(0)) break;

            uint256 win = vote_amount * vote_pool_sum[vote_cycle][vote_top[i]]/vote_cycle_sum[vote_cycle];

            safeTransfer(vote_top[i], win);
            
            vote_pool_balance -= win;

        }
        
        for(uint8 i = 0; i < vote_rank_num; i++) {
            vote_top[i] = address(0);
        }

        vote_cycle++;
    }


    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 3;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 hours)*208/10000/100) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus,  uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus,  users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _ins_pool_last_draw, uint256 _ins_pool_balance, uint256 _vote_pool_balance, uint256 _last_user_deposit_time) {
        return (total_users, total_deposited, total_withdraw, ins_pool_last_draw, ins_pool_balance, vote_pool_balance, last_user_deposit_time);
    }

    function lastUsersRewardInfo() view external returns(address[100] memory lastusers, uint256[100] memory deposit_amount, uint256 _ins_reward) {
        
        _ins_reward = ins_reward;
        
        for(uint8 i = 0; i < current_ins_last_100_users.length; i++) {
            
            if(users[current_ins_last_100_users[i]].deposit_amount > 0) {
                lastusers[i] = current_ins_last_100_users[i];
                deposit_amount[i] = users[current_ins_last_100_users[i]].deposit_amount;
            }
        }
    }
    
    function lastUsersInfo() view external returns(address[100] memory lastusers, uint256[100] memory deposit_amount) {
        
        for(uint8 i = 0; i < last_100_users.length; i++) {
            
            if(users[last_100_users[i]].deposit_amount > 0) {
                lastusers[i] = last_100_users[i];
                deposit_amount[i] = users[last_100_users[i]].deposit_amount;
            }
        }
    }
    
    function voteTopInfo() view external returns(address[100] memory addrs, uint256[100] memory deps) {
        for(uint8 i = 0; i < vote_rank_num; i++) {
            if(vote_top[i] == address(0)) break;

            addrs[i] = vote_top[i];
            deps[i] = vote_pool_sum[vote_cycle][vote_top[i]];
        }
    }
}