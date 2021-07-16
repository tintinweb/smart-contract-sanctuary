//SourceUnit: trc-pro.sol

pragma solidity 0.5.10;
contract TRONpro {
	struct User { 
		uint256 cycle;
		address upline;
		uint40 deposit_time;
		uint256 deposit_total_amount;
		uint256 curr_deposit_amount;
		uint256 curr_max_amount;
		uint256 curr_reward_amount;

		uint256 match_deposit_total_amount;
		uint256 max_match_amount;
		uint256 match_payout_amount;
		uint256 match_amount;
		uint256 recommend_amount;
		uint256 manager_amount;
		uint256 top_amount;
		uint256 top_payout_amount;

		uint256 total_payout_amount;

		uint256 total_structure;
		uint256 referral_count;
		bool if_queue;
		uint256 up_deposit_amount;
		uint40 withdraw_time;
	}

	struct SysConfig{
		address payable owner ;

		address payable t1 ;
		address payable t2 ;
		address payable t3 ;
		address payable t4 ;
		address payable t5 ;
		address payable t6 ;
		uint32 t1_ratio ;
		uint32 t2_ratio ;
		uint32 t3_ratio ;
		uint32 t4_ratio ;
		uint32 t5_ratio ;
		uint32 t6_ratio ;

		uint256 two_max_deposit_money ;
		uint256 two_min_deposit_money ;
		uint256 three_max_deposit_money ;
		uint256 three_min_deposit_money ;
		uint16 curr_reward_ratio ;
		uint16 multiple;
		uint16 match_multiple ;
		uint16 fund_ratio ;
		uint256 day_max_deposit_amount ;
		uint256 day_add_ratio ;

		uint16 queue_ratio ;

		
		uint256[11] reward_ratio1;
		uint16[11] reward_ratio2;
		uint16[15] deposit_reward_ratio;

		uint16[15] withdrawal_reward_ratio;
		uint16[5] pool_top_ratio;
	}

	SysConfig internal sysConfig;

	
	uint256  start_time ;
	
	uint256  max_deposit_money ;
	uint256  min_deposit_money ;


	mapping(address => User) users;

	uint256  pool_cycle = 1;
	mapping(uint256 => mapping(address => uint256))  pool_users_refs_deposits_sum;
	mapping(uint8 => address)  pool_top;
	
	uint256  day_total_deposit_amount = 0;
	address[] queue_users;
	uint256 queue_users_begin_index = 0;
	uint256 queue_amount_sum = 0;
	uint40  execute_time;
	
	uint256  pool_deposit_amount;
	uint256  pool_payout_amount;
	uint256  total_user = 0;
	uint256  fund_amount = 0;


	//============event============
	event Upline(address indexed addr, address indexed upline);
	event NewDeposit(address indexed addr, uint256 amount); 
	event MatchDeposit(address indexed addr, uint256 amount);
	event DepositRecommendRewardPayout(address indexed up,address indexed  _addr, uint256 bonus);
	event WithdrawalRewardPayout(address indexed up,address indexed  _addr, uint256 bonus);
	event TopRewardPayout(address indexed addr, uint256 amount);
	event Withdraw(address indexed addr, uint256 amount);


	constructor(address payable _owner ,address payable _t1,address payable _t2,address payable _t3,address payable _t4,address payable _t5,address payable _t6) public {
		execute_time =  uint40(block.timestamp) + 1 days;

		sysConfig.owner = _owner;
		sysConfig.t1 = _t1;
		sysConfig.t2 = _t2;
		sysConfig.t3 = _t3;
		sysConfig.t4 = _t4;
		sysConfig.t5 = _t5;
		sysConfig.t6 = _t6;

		max_deposit_money = 2e11;
		min_deposit_money = 2e9;
		
		sysConfig.t1_ratio = 0.01 * 10000;
		sysConfig.t2_ratio = 0.01 * 10000;
		sysConfig.t3_ratio = 0.0075 * 10000;
		sysConfig.t4_ratio = 0.0075 * 10000;
		sysConfig.t5_ratio = 0.0075 * 10000;
		sysConfig.t6_ratio = 0.0075 * 10000;

		start_time =  uint40(block.timestamp);
		sysConfig.two_max_deposit_money = 4e11;
		sysConfig.two_min_deposit_money = 4e9;
		sysConfig.three_max_deposit_money = 8e11;
		sysConfig.three_min_deposit_money = 8e9;
		sysConfig.curr_reward_ratio = 0.005 * 1000;
		sysConfig.multiple=1.8 * 1000;
		sysConfig.match_multiple=3.2 * 1000 ;
		sysConfig.fund_ratio = 0.0075 * 10000;
		sysConfig.day_max_deposit_amount = 1e12;

		sysConfig.day_add_ratio = 1.05 * 1000;
		sysConfig.queue_ratio = 0.5 * 1000 ;
		sysConfig.reward_ratio1=[2e13,4e13,6e13,1e14,2e14,4e14,8e14,16e14,32e14,64e14,64e14];
		sysConfig.reward_ratio2=[0.005* 1000,0.006* 1000,0.007* 1000,0.008* 1000,0.009* 1000,0.10* 1000,0.11* 1000,0.12* 1000,0.13* 1000,0.14* 1000,0.15* 1000];
		sysConfig.deposit_reward_ratio=[0.05* 1000,0.03* 1000,0.02* 1000,0.01* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000];
		sysConfig.withdrawal_reward_ratio=[0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000,0.005* 1000];
		sysConfig.pool_top_ratio=[0.4* 1000,0.3* 1000,0.15* 1000,0.1* 1000,0.05* 1000]; 

		for(uint8 i = 0; i < sysConfig.pool_top_ratio.length; i++) {
			pool_top[i] = address(0);
		}
	}

	
	function() payable external {
		 _deposit(msg.sender, msg.value);
	}


	//=============  payable  external=================================

	
	function deposit(address _upline) payable external{ 
		_setUpline(msg.sender, _upline);
		_deposit(msg.sender, msg.value);
	}


	
	function matchDeposit() payable external{
		
		require(users[msg.sender].deposit_total_amount != 0,"not allow");
		
		require(users[msg.sender].match_amount >= users[msg.sender].max_match_amount,"max match amount was not reached");
		
		require( msg.value > min_deposit_money && msg.value < max_deposit_money,"bad amount");
		
		require(msg.value >= users[msg.sender].up_deposit_amount,"deposit money must >= last deposit");

		
		users[msg.sender].up_deposit_amount = msg.value;
		
		users[msg.sender].match_deposit_total_amount += msg.value;
		
		users[msg.sender].max_match_amount += msg.value * sysConfig.match_multiple / 1000;


		
		_updateCurrRewardRatio();

		
		_pt(msg.value);

		emit MatchDeposit(msg.sender,msg.value);
	}

	function withdraw() external{
		require(users[msg.sender].curr_max_amount > users[msg.sender].curr_reward_amount || users[msg.sender].match_payout_amount > 0 || users[msg.sender].top_payout_amount > 0 ,"no amount withdraw");
		uint256 payoutAmount =  _calPayout(msg.sender);
		
		_withdrawalRewardPayout(msg.sender,payoutAmount);
		
		
		pool_payout_amount += payoutAmount;

		msg.sender.transfer(payoutAmount);
		emit Withdraw(msg.sender, payoutAmount);
	}

	//=============  view external=================================

	function contractInfo() view external returns(uint16 ,uint256,uint256,uint256,uint256,uint256,uint256 , uint256 , uint256 , uint40,uint256,uint256){
		return (sysConfig.curr_reward_ratio ,
			sysConfig.day_max_deposit_amount ,
			min_deposit_money ,
			max_deposit_money ,
			day_total_deposit_amount ,
			pool_deposit_amount ,
			pool_payout_amount ,
			total_user , 
			fund_amount,
			execute_time,
			queue_users.length - queue_users_begin_index,
			queue_amount_sum
			);
	}

	
	function userInfo() view external returns(address,uint40,uint256,uint256,bool,uint256,uint256){
		return (users[msg.sender].upline , 
			users[msg.sender].deposit_time , 
			users[msg.sender].total_structure,
			users[msg.sender].referral_count,
			users[msg.sender].if_queue,
			users[msg.sender].up_deposit_amount,
			users[msg.sender].cycle
			);
	}
	
	
	function userMoneyInfo() view external returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
		uint256 payout =  (uint40(block.timestamp) - users[msg.sender].withdraw_time) / 1 days * users[msg.sender].curr_deposit_amount * sysConfig.curr_reward_ratio / 1000 ;

		if(users[msg.sender].if_queue){
			payout = payout * sysConfig.queue_ratio  / 1000;
		}
		if(users[msg.sender].curr_reward_amount + payout > users[msg.sender].curr_max_amount){
			payout = users[msg.sender].curr_max_amount - users[msg.sender].curr_reward_amount;
		}

		return(users[msg.sender].deposit_total_amount , 
			users[msg.sender].curr_deposit_amount ,
			users[msg.sender].curr_max_amount,
			users[msg.sender].curr_reward_amount,
			users[msg.sender].match_deposit_total_amount,
			users[msg.sender].max_match_amount,
			users[msg.sender].match_payout_amount,
			users[msg.sender].match_amount,
			users[msg.sender].recommend_amount,
			users[msg.sender].manager_amount,
			users[msg.sender].total_payout_amount,
			users[msg.sender].top_amount,
			users[msg.sender].top_payout_amount,
			payout
			);
	}

	
	function topInfo() view external returns(address[5] memory addrs, uint256[5] memory deps){
		for(uint8 i = 0; i < sysConfig.pool_top_ratio.length; i++) {
			    addrs[i] = pool_top[i];
			    deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
		}
	}

	//============================== private =====================================


	
	function _calPayout(address _addr) private returns(uint256 payout) {
		
		payout =  (uint40(block.timestamp) - users[_addr].withdraw_time) / 1 days * sysConfig.curr_reward_ratio * users[_addr].curr_deposit_amount / 1000 ;
		
		if(users[_addr].if_queue){
			payout = payout * sysConfig.queue_ratio  / 1000;
		}
		if(payout > 0){
			users[msg.sender].withdraw_time = uint40(block.timestamp);
		}

		
		if(users[_addr].curr_reward_amount + payout >= users[_addr].curr_max_amount){
			payout = users[_addr].curr_max_amount - users[_addr].curr_reward_amount;

			users[users[_addr].upline].referral_count-- ;
		}



		users[_addr].curr_reward_amount += payout;

		payout += users[_addr].match_payout_amount ;
		users[_addr].match_payout_amount = 0;

		payout += users[_addr].top_payout_amount;
		users[_addr].top_payout_amount = 0;

		users[_addr].total_payout_amount += payout;
	}
	
	
	function _updateCurrRewardRatio() private{
		
		if(address(this).balance >= sysConfig.reward_ratio1[sysConfig.reward_ratio1.length-1]){
			sysConfig.curr_reward_ratio = sysConfig.reward_ratio2[sysConfig.reward_ratio1.length-1];
		}else{
			for(uint16 i=0;i<sysConfig.reward_ratio1.length-1;i++){
				if( address(this).balance < sysConfig.reward_ratio1[i]){
					sysConfig.curr_reward_ratio = sysConfig.reward_ratio2[i];
					break;
				}			
			}
		}
	}

	
	function _setUpline(address _addr, address _upline) private {
		
		require(_addr != _upline ,"_upline error");
		
		if(users[_addr].upline == address(0) && _upline != _addr && _addr != sysConfig.owner) {
			if(users[_upline].cycle == 0 ){
				users[_addr].upline = sysConfig.owner;
			}else{
				users[_addr].upline = _upline; 
			}
			users[_upline].referral_count++;
			
			emit Upline(_addr, _upline);
			
			for(uint8 i = 0; i < sysConfig.deposit_reward_ratio.length; i++) {
				if(_upline == address(0)){
					break;
				}
				
				users[_upline].total_structure++;
				
				_upline = users[_upline].upline;
			}
		}
		
	}

	
	function _pt(uint256 _amount) private{
		uint256 t1_amount = _amount * sysConfig.t1_ratio / 10000;
		uint256 t2_amount = _amount * sysConfig.t2_ratio / 10000;
		uint256 t3_amount = _amount * sysConfig.t3_ratio / 10000;
		uint256 t4_amount = _amount * sysConfig.t4_ratio / 10000;
		uint256 t5_amount = _amount * sysConfig.t5_ratio / 10000;
		uint256 t6_amount = _amount * sysConfig.t6_ratio / 10000;

		uint256 _fund_amount = _amount * sysConfig.fund_ratio / 10000;

		sysConfig.t1.transfer(t1_amount);
		sysConfig.t2.transfer(t2_amount);
		sysConfig.t3.transfer(t3_amount);
		sysConfig.t4.transfer(t4_amount);
		sysConfig.t5.transfer(t5_amount); 
		sysConfig.t6.transfer(t6_amount); 
		
		pool_deposit_amount += _amount;		
		fund_amount += _fund_amount;
	}


	
	function _deposit(address _addr, uint256 _amount) private {
				
		
		if(users[_addr].cycle > 0) {
			require(users[_addr].curr_reward_amount >= users[_addr].curr_max_amount,"does not meet the requirements,  cannot be deposit");
			require(_amount >= users[_addr].up_deposit_amount,"deposit money must >= last deposit");
		}

		
		require(_amount >= min_deposit_money && _amount <= max_deposit_money , "bad amount" );

		users[_addr].cycle++ ;
		users[_addr].deposit_time = uint40(block.timestamp);
		users[_addr].withdraw_time = uint40(block.timestamp);
		users[_addr].deposit_total_amount += _amount;
		users[_addr].curr_deposit_amount = _amount;
		users[_addr].curr_max_amount = _amount * sysConfig.multiple / 1000;
		users[_addr].curr_reward_amount = 0;
		users[_addr].up_deposit_amount = _amount;
		
		if(users[_addr].cycle == 1){
			
			users[_addr].match_deposit_total_amount += _amount;
			
			users[_addr].max_match_amount += _amount * sysConfig.match_multiple / 1000;

			total_user++;
		}
		
		emit NewDeposit(_addr,_amount);

		
		if(block.timestamp >= execute_time){
			_execute();
		}
		
		
		if(day_total_deposit_amount >= sysConfig.day_max_deposit_amount){
			users[_addr].if_queue = true;
			queue_users.push(_addr);
			queue_amount_sum = queue_amount_sum + _amount;
		}
		
		day_total_deposit_amount += _amount ; 
		
		
		
		
		_depositRecommendRewardPayout(_addr,_amount);
		
		_calTop5(_addr,_amount);

		_updateCurrRewardRatio();
		_pt(_amount);

	
		if( (block.timestamp - start_time) > 730 days){
			max_deposit_money = sysConfig.two_max_deposit_money;
			min_deposit_money = sysConfig.two_min_deposit_money;
		}else if(block.timestamp - start_time > 365 days){
			max_deposit_money = sysConfig.three_max_deposit_money;
			min_deposit_money = sysConfig.three_min_deposit_money;
		}
	}



	function _calTop5(address _addr, uint256 _amount) private {
		address upline = users[_addr].upline;
		if(upline == address(0)) return;

		pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

		for(uint8 i = 0; i < sysConfig.pool_top_ratio.length; i++) {
			if(pool_top[i] == upline){
				break;
			}
			if(pool_top[i] == address(0)) {
				pool_top[i] = upline;
				break;
			}
			if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
				for(uint8 j = i + 1; j < sysConfig.pool_top_ratio.length; j++) {
					if(pool_top[j] == upline) {
						for(uint8 k = j; k <= sysConfig.pool_top_ratio.length; k++) {
							pool_top[k] = pool_top[k + 1];
						}
						break;
					}
				}
				for(uint8 j = uint8(sysConfig.pool_top_ratio.length - 1); j > i; j--) {
					pool_top[j] = pool_top[j - 1];
				}
				pool_top[i] = upline;
				break;
			}
		}
	}

	
	function _execute() private {
			
		uint256 draw_amount = fund_amount;
		for(uint8 i = 0; i < sysConfig.pool_top_ratio.length; i++) {
			if(pool_top[i] == address(0)) break;
			uint256 win = draw_amount * sysConfig.pool_top_ratio[i]  / 1000; 

			users[pool_top[i]].top_amount += win;
			users[pool_top[i]].top_payout_amount += win;

			emit TopRewardPayout(pool_top[i], win);
		}

		
	
		for(uint8 j = 0; j < sysConfig.pool_top_ratio.length; j++) {
			pool_top[j] = address(0);
		}

		
		
		execute_time = uint40(block.timestamp + 1 days) ;
		
		pool_cycle++;
		
		sysConfig.day_max_deposit_amount = sysConfig.day_max_deposit_amount * sysConfig.day_add_ratio / 1000;
		day_total_deposit_amount = 0;
		fund_amount = 0;

		for(queue_users_begin_index ; queue_users_begin_index < queue_users.length ;queue_users_begin_index++){
			address user_address = queue_users[queue_users_begin_index];
			users[user_address].if_queue = false;
	
			day_total_deposit_amount += users[user_address].curr_deposit_amount;
			queue_amount_sum =  queue_amount_sum - users[user_address].curr_deposit_amount;
			if(day_total_deposit_amount >= sysConfig.day_max_deposit_amount){
				break;
			}
		}
	}

	function _depositRecommendRewardPayout(address _addr, uint256 _amount) private {
		address up = users[_addr].upline;

		for(uint40 i = 0; i < sysConfig.deposit_reward_ratio.length; i++) {
			if(up == address(0)){
				break;
			}
			if(users[up].referral_count >= i + 1) {
				if(users[up].curr_reward_amount >= users[up].curr_max_amount || users[up].match_amount >= users[up].max_match_amount ){
					continue;
				}

				uint256 bonus = _amount * sysConfig.deposit_reward_ratio[i]  / 1000;
							
				if(users[up].match_amount + bonus > users[up].max_match_amount){
					bonus = users[up].max_match_amount - users[up].match_amount;
				}
				users[up].recommend_amount += bonus; 
				users[up].match_payout_amount += bonus;
				users[up].match_amount += bonus;
				emit DepositRecommendRewardPayout(up, _addr, bonus);
			}
			up = users[up].upline;
		}
	}

	function _withdrawalRewardPayout(address _addr, uint256 _amount) private{
		address up = users[_addr].upline;

		for(uint40 i = 0; i < sysConfig.withdrawal_reward_ratio.length; i++) {
			if(up == address(0)){
				break;
			}
			if(users[up].referral_count >= i + 1) {
				if(users[up].curr_reward_amount >= users[up].curr_max_amount || users[up].match_amount >= users[up].max_match_amount ){
					continue;
				}

				uint256 bonus = _amount * sysConfig.withdrawal_reward_ratio[i]  / 1000;

				if(users[up].match_amount + bonus > users[up].max_match_amount){
					bonus = users[up].max_match_amount - users[up].match_amount;
				}
				users[up].manager_amount += bonus; 
				users[up].match_payout_amount += bonus;
				users[up].match_amount += bonus;

				emit WithdrawalRewardPayout(up, _addr, bonus);
			}
			up = users[up].upline;
		}
	}



}