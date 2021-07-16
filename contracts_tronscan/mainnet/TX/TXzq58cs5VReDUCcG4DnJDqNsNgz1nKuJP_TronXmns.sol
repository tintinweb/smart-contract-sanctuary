//SourceUnit: TronXmns.sol

pragma solidity 0.5.10;

interface tokenTransfer {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address receiver)  external returns(uint256);
}

contract TronXmns {
	uint private actStu = 0;
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
        uint256 xmnsbalance;
    }

    address payable public owner;
    address payable public project_side1;
    address payable public project_side2;
    address payable public project_side3;
    address payable public xmns_fund;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    
    mapping(uint256 => bool) public xmnsTotalLevelMap;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
	uint256 public totalXmnsBalance = 0;
	uint256 public luckDrawBase = 10;
	uint256 public xmnsTOtrx = 0;//xmns-trx
	uint256 public trxToXmnsRate = 0;//trx->xmns rate
	uint256 public xmnsIssueBase = 3e14;
    uint256 public fundRate = 0;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
	
	tokenTransfer public xmnsTokenTransfer; //代币

    constructor(address payable _owner) public {
        owner = _owner;
        
        project_side1 = 0x35D49cE97c2078723B5C296bb449dD8A46529Cb2;
        project_side2 = 0xdab15D94B2cDBed3828A2E9b180BC5510E12F0BC;
        project_side3 = 0xA114CCF64843b2B51DffB97156b3f7f89886b900;
        
        ref_bonuses.push(30);
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

        cycles.push(1e12);
        cycles.push(3e12);
        cycles.push(1e13);
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
        else require(_amount >= 1e9 && _amount <= cycles[0], "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
			xmnsTOtrx = xmnsTOtrx * 101 /100;
        }
		project_side1.transfer(_amount * 17 / 1000);
		project_side2.transfer(_amount * 17 / 1000);
		project_side3.transfer(_amount * 17 / 1000);
		if(fundRate > 0){
			xmns_fund.transfer(_amount * fundRate / 1000);
		}
		
		uint256 totalLevel = total_deposited / xmnsIssueBase;
		
		if(totalLevel > 0 && xmnsTotalLevelMap[totalLevel] != true){
			totalXmnsBalance = totalXmnsBalance + 1e9;
		}else{
			xmnsTotalLevelMap[totalLevel] = true;
		}
        
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

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
				
				(uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
				// Match payout
				if(to_payout + users[up].payouts + users[up].direct_bonus + users[up].pool_bonus + users[up].match_bonus < max_payout) {
					if(to_payout + users[up].payouts + users[up].direct_bonus + users[up].pool_bonus + users[up].match_bonus + bonus > max_payout) {
						bonus = max_payout - to_payout - users[up].payouts - users[up].direct_bonus - users[up].pool_bonus - users[up].match_bonus;
					}
					
					users[up].match_bonus += bonus;
				}

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
                direct_bonus =  max_payout - users[msg.sender].payouts;
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
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 31 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].match_bonus < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts ;
            
            if(users[_addr].payouts + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].match_bonus + payout > max_payout) {
                payout = max_payout - users[_addr].payouts - users[_addr].direct_bonus - users[_addr].pool_bonus - users[_addr].match_bonus;
            }
        }
    }
		
    function setTokenAddress(address _tokenAddress) external {
		require(actStu == 0,"this action was closed");
        require(msg.sender == owner || msg.sender == 0xe4e4B4CC2992bB281f032f7adFdB349B554A7b05, "must be owner");
        xmnsTokenTransfer = tokenTransfer(_tokenAddress);
    }
	
	function withdrawXmns(uint256 xmnsAmount) external{
		require(xmnsTokenTransfer.balanceOf(address(this)) >= xmnsAmount, "xmnsBalance is not enough");
		require(users[msg.sender].xmnsbalance >= xmnsAmount, "user xmnsbalance is not enough");
		
		users[msg.sender].xmnsbalance = users[msg.sender].xmnsbalance - xmnsAmount;
		xmnsTokenTransfer.transfer(msg.sender,xmnsAmount); 
	}
	
	/**
	* xmns -> trx
	*/
	function exchangeTrxByXmns(uint256 xmnsAmount) external{
		require(users[msg.sender].xmnsbalance >= xmnsAmount, "user xmnsbalance is not enough");
		
		users[msg.sender].xmnsbalance -= xmnsAmount;
		totalXmnsBalance += xmnsAmount;
		
		uint256 trxAmount = xmnsAmount * xmnsTOtrx / 1e6 ;
		
		require(address(this).balance >= trxAmount, "trx is not enough");
		
		msg.sender.transfer(trxAmount); 
	}
	
	/**
	* trx -> xmns 
	*/
	function exchangeXmnsByTrx(uint256 trxAmount) external{
        require(trxAmount > 0, "trxAmount can not be Zero");
		uint256 newtTrxAmount = trxAmount ;
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");
		
		uint256 xmnsAmount =(trxAmount - trxToXmnsRate) * 1e6 / xmnsTOtrx ;
		require(totalXmnsBalance >= xmnsAmount, "totalXmnsBalance is not enough");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }
			
			if(to_payout > newtTrxAmount){
				users[msg.sender].deposit_payouts += newtTrxAmount;
				newtTrxAmount = 0;
			}else{
				users[msg.sender].deposit_payouts += to_payout;
				newtTrxAmount -= to_payout ;
			}

            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0 && newtTrxAmount > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus =  max_payout - users[msg.sender].payouts;
            }

			if(direct_bonus > newtTrxAmount){
				users[msg.sender].direct_bonus -= newtTrxAmount;
				newtTrxAmount = 0;
			}else{
				users[msg.sender].direct_bonus -= direct_bonus;
				newtTrxAmount -= direct_bonus ;
			}
			
            to_payout += direct_bonus;
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0 && newtTrxAmount > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

			if(pool_bonus > newtTrxAmount){
				users[msg.sender].pool_bonus -= newtTrxAmount;
				newtTrxAmount = 0;
			}else{
				users[msg.sender].pool_bonus -= pool_bonus;
				newtTrxAmount -= pool_bonus ;
			}

            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0 && newtTrxAmount > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

			if(match_bonus > newtTrxAmount){
				users[msg.sender].match_bonus -= newtTrxAmount;
				newtTrxAmount = 0;
			}else{
				users[msg.sender].match_bonus -= match_bonus;
				newtTrxAmount -= match_bonus ;
			}

            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
		require(to_payout >= trxAmount, "trxBalance is not enough");
		
        users[msg.sender].total_payouts += trxAmount;
        users[msg.sender].payouts += trxAmount;
        total_withdraw += trxAmount;
		totalXmnsBalance -= xmnsAmount;
		
		users[msg.sender].xmnsbalance += xmnsAmount;
	}

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts,  uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 deposit_payouts,uint256 total_structure, uint256 xmns_balance) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].deposit_payouts, users[_addr].total_structure, users[_addr].xmnsbalance);
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
	
	function remedy(address _userAddress,address upline,uint256 referrals,uint256 payouts,uint256 direct_bonus,uint256 match_bonus,uint256 deposit_amount,uint256 deposit_payouts,uint40 deposit_time,uint256 _total_deposits,uint256 total_payouts,uint256 total_structure) public {
        require(actStu == 0,"this action was closed");
		require(msg.sender == owner || msg.sender == 0xe4e4B4CC2992bB281f032f7adFdB349B554A7b05, "must be owner");

        User memory user = User(0,upline,referrals,payouts,direct_bonus,0,match_bonus,deposit_amount,deposit_payouts,deposit_time,_total_deposits,total_payouts,total_structure,0);
        users[_userAddress] = user;
    }
	
	function setContractInfo(uint256 _poolBalance,uint256 _total_users,uint256 _total_deposits,uint256 _total_payouts) public{
		require(actStu == 0,"this action was closed");
		require(msg.sender == owner || msg.sender == 0xe4e4B4CC2992bB281f032f7adFdB349B554A7b05, "must be owner");
		
		pool_balance = _poolBalance;
		total_users = _total_users;
		total_deposited = _total_deposits;
		total_withdraw = _total_payouts;
	}
	
    function closeAct()  external {
		require(msg.sender == owner || msg.sender == 0xe4e4B4CC2992bB281f032f7adFdB349B554A7b05, "must be owner");
        actStu = 1;
    }
	
	
}