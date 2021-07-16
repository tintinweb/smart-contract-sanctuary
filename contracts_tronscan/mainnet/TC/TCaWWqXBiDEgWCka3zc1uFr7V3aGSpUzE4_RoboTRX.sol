//SourceUnit: robotrx.sol

pragma solidity 0.5.10;
/**
* 
* RoboTRX 
* https://robotrx.io/
*
**/
contract RoboTRX {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 direct_bonus;
        uint256 team_deposit;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_levels;
        uint40  deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
		level_detail[] tranactions;
    }
	struct level_detail {
        
        uint256 level_amount;
        uint40 level_date;
    }
	address payable public owner;
	address payable public platform_fee;
	uint256 public withdraw_fee;
	uint256 public daily_percent;
	uint256 public limit_percent;
	mapping(address => User) public users;
	uint256[] public cycles;
	uint8[] public ref_bonuses; 
	uint8[] public pool_bonuses;
	uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
	uint8[] public direct_condition; 
	uint256[] public deposit_condition; 
	uint256 public total_users = 1;
	uint256 public constant ROI = 6 hours;
	uint32 internal constant decimals = 10**6;
    uint256 public total_deposited;
    uint256 public total_withdraw;
	event Upline(address indexed addr, address indexed upline);
	event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
	constructor() public {
        owner=msg.sender; 
        platform_fee = 0xfc398952cD8bEB5FF5f31406a822368C45d3d8BE;
        withdraw_fee=12;
        daily_percent=2;
        limit_percent=400;
		//ref_bonuses.push(20);//1
        //ref_bonuses.push(15);//2
        //ref_bonuses.push(10);//3
        //ref_bonuses.push(8);//4
		//ref_bonuses.push(8);//5
		//ref_bonuses.push(7);//6
		//ref_bonuses.push(7);//7
		//ref_bonuses.push(5);//8
		//ref_bonuses.push(5);//9
		//ref_bonuses.push(2);//10
		
		//direct_condition.push(2);//1
		//direct_condition.push(4);//2
		//direct_condition.push(7);//3
		//direct_condition.push(10);//4
		//direct_condition.push(12);//5
		//direct_condition.push(14);//6
		//direct_condition.push(16);//7
		//direct_condition.push(18);//8
		//direct_condition.push(20);//9
		//direct_condition.push(25);//10
		
		//deposit_condition.push(4e9);//1
		//deposit_condition.push(15e9);//2
        //deposit_condition.push(5e10);//3
		//deposit_condition.push(1e11);//4
        //deposit_condition.push(3e11);//5
		//deposit_condition.push(1e12);//6
        deposit_condition.push(2e12);//7
        deposit_condition.push(4e12);//8
		deposit_condition.push(1e13);//9
        deposit_condition.push(25e12);//10
        
        //pool_bonuses.push(25);//1
        //pool_bonuses.push(15);//2
        //pool_bonuses.push(10);//3
        //pool_bonuses.push(8);//4
        //pool_bonuses.push(8);//5
        //pool_bonuses.push(8);//6
        //pool_bonuses.push(8);//7
        //pool_bonuses.push(6);//8
        //pool_bonuses.push(6);//9
        //pool_bonuses.push(6);//10
        
        //cycles.push(1e11);
        //cycles.push(3e11);
        //cycles.push(7e11);
        //cycles.push(1e12);
        
        users[owner].deposit_amount=4e9;
        users[owner].deposit_time=uint40(block.timestamp);
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        level_detail memory _node;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            users[up].total_structure++;
            users[up].team_deposit+=_amount;
            if(users[up].referrals >= direct_condition[i] && users[up].team_deposit >= deposit_condition[i]) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                _node.level_amount=bonus;
                _node.level_date=uint40(block.timestamp);
				users[up].tranactions.push(_node);
                emit MatchPayout(up, _addr, bonus);
            }
            up = users[up].upline;
        }
    }
	function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            emit Upline(_addr, _upline);
            total_users++;
        }
    }
	function _deposit(address _addr, uint256 _amount) private {
	    
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");    
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require(users[_addr].payouts >=this.maxPayoutOf(_amount) , "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        } 
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_levels = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);
        
        if(users[_addr].upline != address(0)) {
            uint256 max_payout=this.maxPayoutOf(users[users[_addr].upline].deposit_amount);
            if(users[users[_addr].upline].payouts < max_payout) {
                uint256 _direct=_amount*3 / 25;
                if(users[users[_addr].upline].payouts + _direct > max_payout) {
                   _direct = max_payout - users[users[_addr].upline].payouts;
                }    
                users[users[_addr].upline].direct_bonus += _direct;
                users[users[_addr].upline].payouts+=_direct;
                emit DirectPayout(users[_addr].upline, _addr, _direct);
            }
            
        }
        _refPayout(_addr, _amount);
    }
    
	function deposit() payable external {
		uint256 _amount=msg.value;
		require(_amount >= 1e8);
		emit NewDeposit(msg.sender, _amount);
		total_users++;
		total_deposited +=_amount;
    }
	function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts < max_payout) {
            payout = (users[_addr].deposit_amount*daily_percent * ((block.timestamp - users[_addr].deposit_time) / ROI) / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].payouts + payout > max_payout) {
                payout = max_payout - users[_addr].payouts;
            }
        }
    }
	
	function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        return _amount * limit_percent/100;
    }
    function levelincomeOf(address _addr) view external returns(uint256 levelincome, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        levelincome=0;
        if(users[_addr].payouts < max_payout) {
            for(uint8 i = 0; i < users[_addr].tranactions.length; i++) {
                levelincome += (users[_addr].tranactions[i].level_amount * ((block.timestamp - users[_addr].tranactions[i].level_date) / ROI)) - users[_addr].deposit_levels;
            
                if(users[_addr].payouts + levelincome > max_payout) {
                    levelincome = max_payout - users[_addr].payouts;
                    break;
                }
            } 
        }
    }
    function levelOf(address _addr,uint256 _index) view external returns(uint256 level_amount, uint40 level_date) {
        
		return (users[_addr].tranactions[_index].level_amount,users[_addr].tranactions[_index].level_date);
    }
	function tranactionscount(address _addr) view external returns(uint256) {
        
		return users[_addr].tranactions.length;
    }
    
    function multisendTron(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total-_balances[i];
            _contributors[i].transfer(_balances[i]);
        }
    }
    /*
        Only owner call
    */
    function withdraw(address payable _receiver, uint256 _amount) public {
		if (msg.sender != owner) {revert("Access Denied");}
		_receiver.transfer(_amount);  
    }
    function setDailyPercent(uint256  _daily_percent) public {
        if (msg.sender != owner) {revert("Access Denied");}
		daily_percent=_daily_percent;
    }
    function setWithdrawFee(uint256 _withdraw_fee) public {
        if (msg.sender != owner) {revert("Access Denied");}
		withdraw_fee=_withdraw_fee;
    }
    function setLimitPercent(uint256 _limit_percent) public {
        if (msg.sender != owner) {revert("Access Denied");}
		limit_percent=_limit_percent;
    }
	/*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus);
    }
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
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