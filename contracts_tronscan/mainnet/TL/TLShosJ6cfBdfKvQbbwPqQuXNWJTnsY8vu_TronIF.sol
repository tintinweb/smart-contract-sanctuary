//SourceUnit: tronif-all上线(无注释版).sol

pragma solidity ^ 0.5.9;
contract TronIF {
	using SafeMath for uint128; 

	uint64 private yesterday_top1_playId;

	uint64 private yesterday_top2_playId;

	uint64 private yesterday_top3_playId;

	uint64 private yesterday_top1_round_ref_val;

	uint64 private yesterday_top2_round_ref_val;

	uint64 private yesterday_top3_round_ref_val;

	uint64 private day_top1_playId;

	uint64 private day_top2_playId;

	uint64 private day_top3_playId;

	uint128 private yesterday_top3_pool_val;

	uint128 private total_val;

	uint128 private cur_day_val;

	uint128 private last_day_val;

	uint128 private top3_pool_val;

	uint128 private marketing_pool_val;

	uint32 private round_ver;

 	uint32 private day_tick;

	uint32 constant private DAY_SEC = 86400;

	uint32 constant private TIME_BASE = 1601481600; 

	uint32 constant private SUN = 1000000;

	uint32 constant private SUN4 = 100;

	uint32[2][9]  private  ALLOWANCE = [[uint32(10000),uint32(200000)],[uint32(100000),uint32(400000)],[uint32(200000),uint32(800000)],
	[uint32(400000),uint32(1600000)],[uint32(800000),uint32(3200000)],[uint32(1600000),uint32(6400000)],[uint32(3200000),uint32(12800000)]
	,[uint32(6400000),uint32(12800000)],[uint32(12800000),uint32(12800000)]]; 

	address private owner = 0x7AeB465F7aF545dbC7bE46f3545fCD3fA025a3fb;
	address private ADMIN_ADDR = 0xdf6508971E14Fe592fD6d1EC4DfC60997a74966b;
	address private MARKET_ADDR = 0xC05229759d178a9f4545C1213d152c0ee5747083;
	address private OP_ADDR = 0xeA97d424BEe4C49c39e342F9FE8509681D2D8E0f;

    event ev_join(address indexed addr, address indexed paddr, uint256 _value, uint32 joinNum);
    event ev_static(address indexed addr, uint256 _beforeval, uint256 add_val);
    event ev_player_out(address indexed addr,  uint256 _value, string comment);
    event ev_withdraw(address indexed addr,  uint256 _value, string comment);
	event ev_day_top3(address indexed addr,  uint64 top1, uint64 top2,  uint64 top3, uint128 _value);

	struct Player {

		uint32 join_num;

		uint32 create_timestamp;

		uint32 join_timestamp;

		uint32 last_settle_timestamp;

		uint32 last_settle_timestamp_HIS;

		uint32 gen_num;

		uint32 total_ref_num;

		uint32 play_val;
		
		uint32 round;

		uint64 round_ref_val;

		uint64 total_play_val;

		uint64 paren_id;

		uint64 team20_num;

		uint128 top3_earnings;

		uint128 ref_earnings;

		uint128 static_earnings;

		uint128 manage_earnings;

		uint128 total_out_balance;

		uint128 withdraw_earnings;
	}
 
	Player[] players;
	mapping (address => uint64) public playerIdx;
    mapping (uint64 => address) public idToAddr;

	constructor() public {
		Player memory _player = Player({
			join_num: 1,
			create_timestamp: uint32(block.timestamp-TIME_BASE),
            join_timestamp: uint32(block.timestamp-TIME_BASE),
            last_settle_timestamp:uint32(block.timestamp-TIME_BASE),
            last_settle_timestamp_HIS:0,
  			gen_num: 1,
            total_ref_num: 0,
		  	play_val: 10000,
		  	round: 0,
		  	round_ref_val:0,
		  	total_play_val: 10000,
            paren_id: 0,
            team20_num: 0,
            top3_earnings: 0,
            ref_earnings: 0,
            static_earnings: 0,
		  	manage_earnings: 0,
		  	total_out_balance:uint128(-1),
			withdraw_earnings: 0
        });
		uint32 now_zero_time = _player.last_settle_timestamp - _player.last_settle_timestamp  % DAY_SEC;
		_player.last_settle_timestamp_HIS = _player.last_settle_timestamp - now_zero_time;
		_player.last_settle_timestamp = now_zero_time;
		
		day_tick = _player.last_settle_timestamp;
		cur_day_val += _player.total_play_val;	

		players.push(_player);
		players.push(_player);
		uint64 playerId = uint64(players.length - 1);
		playerIdx[owner] = playerId;
		idToAddr[playerId] = owner;
	}
	
 
	function() payable external{ }
 
	modifier onlyAdmin() {
		require(msg.sender == ADMIN_ADDR);
		_;
	}
	modifier onlyOperator() {
		require(msg.sender == OP_ADDR);
		_;
	}
	modifier onlyMarket() {
		require(msg.sender == MARKET_ADDR);
		_;
	}

	function join(address paddr) public payable 
	returns(uint256){
		require(msg.value == (msg.value/SUN)*SUN, "Bet amount must be an integer");
		uint64 parenId;
		uint64 playerId = playerIdx[msg.sender];
		uint32 val = uint32(msg.value/SUN);
 		uint32 tick = uint32(block.timestamp-TIME_BASE);
 		uint32 zerotick =  tick - tick % DAY_SEC;
		uint32 histick = tick - zerotick;
		bool isOut;
		uint128 fix_earnings;
		if(playerId == 0){
			require(val >= ALLOWANCE[0][0] && val <= ALLOWANCE[0][1], "Your bet amount is invalid");
			parenId = playerIdx[paddr];
			if (parenId == 0) parenId = 1;
			uint32 gen = players[parenId].gen_num+1;
			Player memory _player = Player({
				join_num: 1,
				create_timestamp: tick,
	            join_timestamp: tick,
	            last_settle_timestamp: zerotick,
				last_settle_timestamp_HIS: histick,
	  			gen_num: gen,
	            total_ref_num: 0,
			  	play_val: val,
		  		round: 0,
		  		round_ref_val:0,
	            total_play_val: val,
	            paren_id: parenId,
	            team20_num: 0,
	            top3_earnings: 0,
	            ref_earnings: 0,
	            static_earnings: 0,
			  	manage_earnings: 0,
			  	total_out_balance: val*20000,
				withdraw_earnings: 0
			});
			playerId = uint64(players.length);
			players.push(_player);
			playerIdx[msg.sender] = playerId;
			idToAddr[playerId] = msg.sender;

			players[parenId].total_ref_num++;
			uint64 pId = parenId;
			if(gen > 20) gen = 21;
			for(uint32 i=gen-1; i>0; i--){
			 	players[pId].team20_num++;
 				pId = players[pId].paren_id;
 			}	
		}else{

			require(players[playerId].play_val == 0, "this player is not out, can't join again!");

			Player storage _thisplayer = players[playerId];
			require(val >= ALLOWANCE[_thisplayer.join_num][0] && val <= ALLOWANCE[_thisplayer.join_num][1], "Your bet amount is invalid");

			parenId = _thisplayer.paren_id;
			_thisplayer.join_timestamp = tick;
			_thisplayer.last_settle_timestamp = zerotick;
			_thisplayer.last_settle_timestamp_HIS = histick;
			_thisplayer.join_num++;
			_thisplayer.total_play_val += val;
			_thisplayer.play_val = val;
			_thisplayer.round = round_ver;
			_thisplayer.total_out_balance = _thisplayer.total_out_balance.add(val*20000);
		}

		if(players[parenId].round != round_ver){
			players[parenId].round_ref_val = val;
			players[parenId].round = round_ver;
		}else{
			players[parenId].round_ref_val+=val;
		}

		(isOut, fix_earnings) = check_is_out(players[parenId],uint128(msg.value / 10 / SUN4));
		do_out(players[parenId],isOut,uint128(msg.value / 10 / SUN4),"ref_earnings");
		players[parenId].ref_earnings = players[parenId].ref_earnings.add(uint128(msg.value / 10 / SUN4));

		if(players[day_top1_playId].round_ref_val < players[parenId].round_ref_val){
			day_top3_playId = day_top2_playId;
			day_top2_playId = day_top1_playId;
			day_top1_playId = uint64(parenId);
		}
		else if(players[day_top2_playId].round_ref_val < players[parenId].round_ref_val){
			day_top3_playId = day_top2_playId;
			day_top2_playId = uint64(parenId);
		}
		else if(players[day_top3_playId].round_ref_val < players[parenId].round_ref_val){
			day_top3_playId = uint64(parenId);
		} 

		top3_pool_val = top3_pool_val.add(uint128(msg.value*3/10000));

		uint256 markeyval = uint128(msg.value*5/10000)*SUN4;
		require(markeyval <= address(this).balance, "Not enough balance.");
		address(uint160(MARKET_ADDR)).transfer(markeyval);

		emit ev_withdraw(MARKET_ADDR,markeyval,"market");

		total_val = total_val.add(uint128(val)); 

		if(day_tick != zerotick){
			day_tick = zerotick;
			last_day_val = cur_day_val;
		}
		cur_day_val = cur_day_val.add(uint128(val)); 
		emit ev_join(msg.sender, idToAddr[parenId], msg.value, players[playerId].join_num);
		return playerId;
	}
 
 	function check_is_out(Player storage _player, uint128 earnings) internal view  returns (bool isOut,  uint128 retEarnings){
       retEarnings = _player.top3_earnings.add(_player.ref_earnings).add(_player.static_earnings).add(_player.manage_earnings).add(earnings);
       if(retEarnings >= _player.total_out_balance) {
       		uint128 df = retEarnings - _player.total_out_balance;
       		if (earnings > df) {
       			retEarnings = earnings - df;
       		}else{
       			retEarnings = 0;
       		}
       		//require(retEarnings <= out_val, "check_is_out:invalid parameter with earnings");
       		isOut = true;
       }else{
       		retEarnings = earnings;
			isOut = false;
       }
       return(isOut,retEarnings);
    }

	function do_out(Player storage _player,bool isOut,uint128 earnings,string memory out_type) internal {
		if(isOut && _player.play_val > 0){
			cur_day_val -= _player.play_val;
			_player.play_val = 0;
			emit ev_player_out(msg.sender, earnings, out_type);
		}
	}
	
	function settle() public{
	    uint256 playId = playerIdx[msg.sender];

		require(playId > 0, "You have not join the game!");
		bool isOut;
        Player storage _player = players[playId];
		uint32 no_settle_days;
		uint128 earnings;
		uint128 fix_earnings;
		uint32 nowtick = uint32(block.timestamp-TIME_BASE);
		if(_player.play_val > 0){
		
			uint32 can_settle_time = _player.last_settle_timestamp + _player.last_settle_timestamp_HIS + DAY_SEC;
			if (nowtick > can_settle_time){
				no_settle_days = (nowtick-_player.last_settle_timestamp-_player.last_settle_timestamp_HIS) / DAY_SEC;
			}else{
				no_settle_days = 0;
			}
			require(no_settle_days > 0, "the settle period of time is at least one day!");

			_player.last_settle_timestamp = nowtick - nowtick % DAY_SEC;
			_player.last_settle_timestamp_HIS = nowtick - _player.last_settle_timestamp;
			if(day_tick != _player.last_settle_timestamp){
				day_tick = _player.last_settle_timestamp;
				last_day_val = cur_day_val;
			}
			earnings = no_settle_days * (_player.play_val*200);

			(isOut, fix_earnings) = check_is_out(_player, earnings);
			do_out(_player,isOut,earnings,"static");
			emit ev_static(msg.sender, _player.static_earnings, fix_earnings);
			_player.static_earnings = _player.static_earnings.add(fix_earnings);

			manager_settle(_player, fix_earnings);
		}
	}
 
	function manager_settle(Player storage _player, uint128 earnings) internal{
		//Player storage _player = players[playId];
		//require(_player.create_time > 0, "You have not join the game!");
		bool isOut;
		uint32 gen = _player.gen_num;
		uint32 i;
		uint32 percent;
		uint64 pId = _player.paren_id;
		uint128 add_earnings = earnings / 100;
		uint128 fix_earnings;
		if(gen > 20) gen = 20;
	
		//require(gen <= SETTLE_GEN10, "gen out of range 1-10!");
		for(i = 0;i<gen;i++){
			if(players[pId].total_ref_num > i){
				if(i<3) percent = 10;
				else if( i<6 ) percent = 5;
				else percent = 2;
				(isOut, fix_earnings) = check_is_out(players[pId], add_earnings * percent);
				do_out(players[pId],isOut,add_earnings,"manager");
				//emit ev_dynamic(idToAddr[pId], players[pId].dynamic_earnings, fix_earnings);
				players[pId].manage_earnings = players[pId].manage_earnings.add(add_earnings * percent);
			}
 			pId = players[pId].paren_id;
		} 
	}

	function withdraw() public {
		 
		uint256 playId = playerIdx[msg.sender];

		require(playId > 0, "playId does not exist!");
		Player storage _player = players[playId];

		uint128 total = _player.top3_earnings.add(_player.ref_earnings).add(_player.static_earnings).add(_player.manage_earnings);
 
  		uint128 undrawnEarnings = total.sub(_player.withdraw_earnings);

		uint128 play_val = _player.total_out_balance-_player.withdraw_earnings;

		require(play_val > 0, "No withdrawable balance.");

		if(undrawnEarnings > 0){
			if(undrawnEarnings >= play_val && playId > 1){
				do_out(_player,true,undrawnEarnings,"withdraw");
				undrawnEarnings = play_val;
			}
			undrawnEarnings = undrawnEarnings.mul(SUN4);
			if(undrawnEarnings > address(this).balance){
				undrawnEarnings = uint128(address(this).balance/SUN4);
				_player.withdraw_earnings = _player.withdraw_earnings.add(undrawnEarnings);
				undrawnEarnings = undrawnEarnings.mul(SUN4);
			}else{
				// _player.withdraw_earnings = total;
				_player.withdraw_earnings += undrawnEarnings/SUN4;
			}
			
			require(undrawnEarnings <= address(this).balance, "Not enough balance.");
			msg.sender.transfer(undrawnEarnings);

			emit ev_withdraw(msg.sender, undrawnEarnings, "player");
		}
	}

	function day_top3() public onlyOperator returns(uint){

		uint128 champion_val = top3_pool_val/10;
		uint128 subVal = 0;
		bool isOut;
		uint128 fix_earnings;
		yesterday_top3_pool_val = top3_pool_val;
		round_ver += 1;
 		Player storage _player = players[day_top1_playId];
		if (_player.round_ref_val > 0){
			(isOut, fix_earnings) = check_is_out(_player,champion_val*50/100);
			do_out(_player,isOut,champion_val*50/100,"top3");
			_player.top3_earnings = _player.top3_earnings.add(champion_val*50/100);
			_player.round = round_ver;
			yesterday_top1_round_ref_val = _player.round_ref_val;
			_player.round_ref_val = 0;
			subVal += champion_val*50/100;
			yesterday_top1_playId = day_top1_playId;
		} else {
			yesterday_top1_playId = 0;
			yesterday_top1_round_ref_val = 0;
		}
		_player = players[day_top2_playId];
		if (_player.round_ref_val > 0){
			(isOut, fix_earnings) = check_is_out(_player,champion_val*30/100);
			do_out(_player,isOut,champion_val*30/100,"top3");
			_player.top3_earnings = _player.top3_earnings.add(champion_val*30/100);
			_player.round = round_ver;
			yesterday_top2_round_ref_val = _player.round_ref_val;
			_player.round_ref_val = 0;
			subVal += champion_val*30/100;
			yesterday_top2_playId = day_top2_playId;
		} else {
			yesterday_top2_round_ref_val = 0;
			yesterday_top2_playId = 0;
		}
		_player = players[day_top3_playId];
		if (_player.round_ref_val > 0){
			(isOut, fix_earnings) = check_is_out(_player,champion_val*20/100);
			do_out(_player,isOut,champion_val*20/100,"top3");
			_player.top3_earnings = _player.top3_earnings.add(champion_val*20/100);
			_player.round = round_ver;
			yesterday_top3_round_ref_val = _player.round_ref_val;
			_player.round_ref_val = 0;
			subVal += champion_val*20/100;
			yesterday_top3_playId = day_top3_playId;
		} else {
			yesterday_top3_playId = 0;
			yesterday_top3_round_ref_val = 0;
		}
		top3_pool_val= top3_pool_val.sub(subVal);

		emit ev_day_top3(msg.sender, day_top1_playId, day_top2_playId, day_top3_playId, subVal);

		day_top1_playId = 0;
		day_top2_playId = 0;
		day_top3_playId = 0;
	}

	function withdraw_admin(uint256 val) public payable onlyAdmin{
		val = val * SUN / 100;
		require(val <= address(this).balance, "Not enough balance.");
		address(uint160(ADMIN_ADDR)).transfer(val);
		emit ev_withdraw(ADMIN_ADDR,val,"admin");
	}
 

	function get_info() external view 
	returns(
		uint128 player_count,
		uint128 marketing_pool,
		uint128 top3_pool,
		uint128 total_num,
		uint128 balance,
		uint128 day_static_earnings
	){
		player_count = uint128(players.length - 1);
		marketing_pool = marketing_pool_val;
		top3_pool = top3_pool_val;
		total_num = total_val*10000;
		balance = uint128(address(this).balance / SUN4);
		day_static_earnings = last_day_val * 200;
		return(player_count, marketing_pool, top3_pool, total_num, balance, day_static_earnings);
	}


	function get_player_base_info(address addr) external view 
	returns(
		uint64 playerId,
		uint64 paren_id,
		uint32 join_num,
		uint32 gen_num,
		uint32 total_ref_num,
		uint32 play_val,
		uint64 total_play_val,
		uint64 round_ref_val,
		uint64 team20_num,
		bool  isOut
		){
		uint64 playId = playerIdx[addr];
		require(playId > 0, "The address have not join the game!");
		return (playId, players[playId].paren_id, players[playId].join_num, players[playId].gen_num, players[playId].total_ref_num, players[playId].play_val, 
			  players[playId].total_play_val, players[playId].round_ref_val, players[playId].team20_num, players[playId].play_val == 0);
	}

  	function get_player_time(address addr) external view 
  	returns(
  		uint64 playerId,
  		uint64 nowtimestamp,
		uint64 create_timestamp,
		uint64 join_timestamp,
		uint64 last_settle_timestamp
  		){
			uint64 playId = playerIdx[addr];
			if(playId == 0){
				return(0, 0, 0, 0, 0);
			}
			Player storage _p = players[playId];
 			return(playerId, uint64(block.timestamp), _p.create_timestamp+TIME_BASE, _p.join_timestamp+TIME_BASE, _p.last_settle_timestamp+TIME_BASE+_p.last_settle_timestamp_HIS);
	}

    function get_earnings(address addr) external view
        returns (
    	uint64 playerId,
        uint128 staticEarnings,
        uint128 manageEarnings,
        uint128 top3Earnings,
        uint128 refEarnings,
        uint128 outDiffEarnings,
        uint128 unconfirmedEarnings,
        uint128 noSettleDays,
        uint128 undrawnEarnings,
        uint128 withdrawEarnings,
		uint128 surplusUndrawnQuota
    ) {
        uint64 playId = playerIdx[addr];
		if(playId == 0){
			return(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		}

        Player storage _player = players[playId];

		staticEarnings = _player.static_earnings;

        manageEarnings = _player.manage_earnings;

        top3Earnings = _player.top3_earnings;

        refEarnings = _player.ref_earnings;

		withdrawEarnings= _player.withdraw_earnings;

		uint128 total = _player.top3_earnings.add(_player.ref_earnings).add(_player.static_earnings).add(_player.manage_earnings);
 
 		if ( _player.total_out_balance > total)  outDiffEarnings = _player.total_out_balance - total;
 		else outDiffEarnings = 0;

 		uint32 nowtick = uint32(block.timestamp-TIME_BASE);
		uint32 can_settle_time = _player.last_settle_timestamp + _player.last_settle_timestamp_HIS + DAY_SEC;
 		if (nowtick > can_settle_time){
			noSettleDays = (nowtick-_player.last_settle_timestamp-_player.last_settle_timestamp_HIS) / DAY_SEC;
		}else{
			noSettleDays = 0;
		}
		if (_player.play_val == 0) {
			noSettleDays = 0;
		}
		unconfirmedEarnings = noSettleDays * (_player.play_val*200);

        undrawnEarnings = total.sub(_player.withdraw_earnings);

		surplusUndrawnQuota = _player.total_out_balance-withdrawEarnings;

        return(playId, staticEarnings, manageEarnings, top3Earnings, refEarnings, outDiffEarnings, unconfirmedEarnings, noSettleDays, undrawnEarnings, withdrawEarnings,surplusUndrawnQuota);
    }

    function get_top3_info() external view
    returns (
        	address top1Addr,
        	address top2Addr,
        	address top3Addr,
        	uint128 top1Val,
			uint128 top2Val,
			uint128 top3Val,
			uint64 top1RefVal,
			uint64 top2RefVal,
			uint64 top3RefVal,
			uint128 poolVal
        	){ 
				top1Addr=idToAddr[yesterday_top1_playId];
				top2Addr=idToAddr[yesterday_top2_playId];
				top3Addr=idToAddr[yesterday_top3_playId];
				uint128 champion_val = yesterday_top3_pool_val/10;
				if (yesterday_top1_playId > 0){
					top1Val = champion_val*50/100;
					top1RefVal = yesterday_top1_round_ref_val;
				} else{
					top1Val = 0;
					top1RefVal = 0;
				} 
 				if (yesterday_top2_playId > 0){
					top2Val = champion_val*30/100;
					top2RefVal = yesterday_top2_round_ref_val;
				} else{
					top2Val = 0;
					top2RefVal = 0;
				} 
 				if (yesterday_top3_playId > 0){
					top3Val = champion_val*20/100;
					top3RefVal = yesterday_top3_round_ref_val;
				} else{
					top3Val = 0;
					top3RefVal = 0;
				} 
				poolVal = top3_pool_val;
 				return(top1Addr, top2Addr, top3Addr, top1Val, top2Val, top3Val, top1RefVal, top2RefVal, top3RefVal, poolVal);
    }
}

library SafeMath {
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        require(c / a == b);
        return c;
    }
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a);
        uint128 c = a - b;
        return c;
    }
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a);
        return c;
    }
}