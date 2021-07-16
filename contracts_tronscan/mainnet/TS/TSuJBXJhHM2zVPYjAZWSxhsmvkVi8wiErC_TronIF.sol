//SourceUnit: tronif-all上线.sol

/**!
* @mainpage
* @brief    TRONIF合约文件
* @details  TRONIF合约逻辑实现文件
* @author     Jason
* @date       2020-10-25
* @version     V1.0
* @copyright    Copyright (c) 2019-2020   
**********************************************************************************
* @attention
* 编译工具: http://www.tronide.io
* 编译参数: Enable optimization\n
* 编译器版本：solidity   0.5.12 以上版本
* @par 修改日志:
* <table>
* <tr><th>Date        <th>Version  <th>Author    <th>Description
* <tr><td>2020-10-25  <td>1.0      <td>Jason  <td>创建初始版本
* </table>
*
**********************************************************************************
*/
pragma solidity ^ 0.5.9;
contract TronIF {
	using SafeMath for uint128; 
	//上一次玩家推荐TOP3 No.1
	uint64 private yesterday_top1_playId;
	//上一次玩家推荐TOP3 No.2
	uint64 private yesterday_top2_playId;
	//上一次玩家推荐TOP3 No.3
	uint64 private yesterday_top3_playId;
	//上一次玩家推荐TOP3 No.1 的推荐总额
	uint64 private yesterday_top1_round_ref_val;
	//上一次玩家推荐TOP3 No.2 的推荐总额
	uint64 private yesterday_top2_round_ref_val;
	//上一次玩家推荐TOP3 No.3 的推荐总额
	uint64 private yesterday_top3_round_ref_val;
	//上一次结算时的top3池
	uint128 private yesterday_top3_pool_val;
	//当天玩家推荐TOP3 No.1
	uint64 private day_top1_playId;
	//当天玩家推荐TOP3 No.2
	uint64 private day_top2_playId;
	//当天玩家推荐TOP3 No.3
	uint64 private day_top3_playId;
	//全网投资总额 单位：TRX
	uint128 private total_val;
	//当天静态收益统计基数 单位：TRX
	uint128 private cur_day_val;
	//前一天静态收益统计基数 单位：TRX
	uint128 private last_day_val;
	//玩家TOP3池 单位：TRX*10^4, 保留小数点后4位
	uint128 private top3_pool_val;
 	//市场营销费用池 单位：TRX*10^4, 保留小数点后4位
	uint128 private marketing_pool_val;
	//本轮数据版本，作用：本轮结算完成后，部分数据需要重置清零，为了减少修改数据的gas花费，我们直接设置个数据版本，当修改数据发现版本不一致时，再重置
	uint32 private round_ver;
 	//当天零点时间截，用于计算日期切换
 	uint32 private day_tick;
	//常量定义
	//天转换
	uint32 constant private DAY_SEC = 86400; //一天86400秒

	//基准时间 2020-10-01 00:00:00
	uint32 constant private TIME_BASE = 1601481600; 

	//SUN 转换
	uint32 constant private SUN = 1000000;

	//SUN4 转换
	uint32 constant private SUN4 = 100;

	//投资限额
	uint32[2][9]  private  ALLOWANCE = [[uint32(10000),uint32(200000)],[uint32(100000),uint32(400000)],[uint32(200000),uint32(800000)],
	[uint32(400000),uint32(1600000)],[uint32(800000),uint32(3200000)],[uint32(1600000),uint32(6400000)],[uint32(3200000),uint32(12800000)]
	,[uint32(6400000),uint32(12800000)],[uint32(12800000),uint32(12800000)]]; 
	//私网测试地址
	address private owner = 0x8919A1F7f6208Ff3c64868BB05C81bCdc3b09f6b;
	address private ADMIN_ADDR = 0x9a550f65eCF99AD3981840B8F357673557Ec9ED2;
	address private MARKET_ADDR = 0x227a18128Dd105593192e129c9D3bF6A3bE71a3e;
	address private OP_ADDR = 0xA4bf8a3de8D08fFe7844a612D66a088f52375333;

	// 定义事件
    event ev_join(address indexed addr, address indexed paddr, uint256 _value, uint32 joinNum); //玩家参与游戏事件
    event ev_static(address indexed addr, uint256 _beforeval, uint256 add_val); //静态收益结算事件
    event ev_player_out(address indexed addr,  uint256 _value, string comment); //玩家出局事件
    event ev_withdraw(address indexed addr,  uint256 _value, string comment); //提现
	event ev_day_top3(address indexed addr,  uint64 top1, uint64 top2,  uint64 top3, uint128 _value); //日结算TOP3事件
	//定义玩家结构体
	struct Player {
		//玩家投注次数
		uint32 join_num;
		//玩家创建时间，相对于基准时间 2020-10-01 00:00:00 经过的秒数
		uint32 create_timestamp;
		//玩家参与游戏时间，为了节省存储空间，这个值定义为相对于基准时间 2020-10-01 00:00:00经过的秒数
		uint32 join_timestamp;
		//玩家上次结算时间
		uint32 last_settle_timestamp;
		//玩家上次结算时间的时分秒
		uint32 last_settle_timestamp_HIS;
		//玩家代数，从1开始
		uint32 gen_num;
		//玩家总推荐人数
		uint32 total_ref_num;
		//玩家投注金额 单位：TRX，特别地当play_val=0时，表示该玩家出局
		uint32 play_val;
		//玩家所在轮数
		uint32 round;
		//玩家本轮推荐总额 单位：TRX
		uint64 round_ref_val;
		//玩家总投注金额 单位：TRX
		uint64 total_play_val;
 		//玩家推荐ID
		uint64 paren_id;
		//团队合作伙伴，20代内的团队人数
		uint64 team20_num;
 		//玩家本轮TOP3收益 单位：TRX*10^4, 保留小数点后4位
		uint128 top3_earnings;
		//玩家本轮直推收益 单位：TRX*10^4, 保留小数点后4位
		uint128 ref_earnings;
		//玩家本轮静态收益 单位：TRX*10^4, 保留小数点后4位
		uint128 static_earnings;
		//玩家本轮管理收益 单位：TRX*10^4, 保留小数点后4位
		uint128 manage_earnings;
		//玩家出局总额 单位：TRX*10^4, 保留小数点后4位
		uint128 total_out_balance;
		//玩家已提现收益 单位：TRX*10^4, 保留小数点后4位
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
		  	total_out_balance:uint128(-1), //永不出局
			withdraw_earnings: 0
        });
		uint32 now_zero_time = _player.last_settle_timestamp - _player.last_settle_timestamp  % DAY_SEC;
		_player.last_settle_timestamp_HIS = _player.last_settle_timestamp - now_zero_time;//当天的时分秒
		_player.last_settle_timestamp = now_zero_time;//当天0时0分
		
		day_tick = _player.last_settle_timestamp;
		cur_day_val += _player.total_play_val;	
		//加入根节点
		players.push(_player);
		players.push(_player); //多复制一次，目的是使第一个元素的数组下标为1，ID也为1，方便后面的逻辑判断
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

	/**
	* 参与游戏
	* paddr：推荐人地址
	*/
	function join(address paddr) public payable 
	returns(uint256){
		//TRX金额必须为整数
		require(msg.value == (msg.value/SUN)*SUN, "Bet amount must be an integer");
		uint64 parenId;
		uint64 playerId = playerIdx[msg.sender];
		uint32 val = uint32(msg.value/SUN);
 		uint32 tick = uint32(block.timestamp-TIME_BASE);
 		uint32 zerotick =  tick - tick % DAY_SEC; //当天0时0分
		uint32 histick = tick - zerotick;
		bool isOut;
		uint128 fix_earnings;
		if(playerId == 0){ //第一次参与游戏
			require(val >= ALLOWANCE[0][0] && val <= ALLOWANCE[0][1], "Your bet amount is invalid");//第一次可投 1 万-20 万 TRX
			parenId = playerIdx[paddr]; //如果paddr没参与游戏，那么parenId自动为0，
			if (parenId == 0) parenId = 1; //指定的推荐人没有参与，则默认为根节点
			uint32 gen = players[parenId].gen_num+1;
			Player memory _player = Player({
				join_num: 1,
				create_timestamp: tick,
	            join_timestamp: tick,
	            last_settle_timestamp: zerotick, //当天0时0分
				last_settle_timestamp_HIS: histick, //当天的时分秒 
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
			  	total_out_balance: val*20000, //2倍出局, 单位：TRX*10^4, 保留小数点后4位
				withdraw_earnings: 0
			});
			playerId = uint64(players.length);
			players.push(_player);
			playerIdx[msg.sender] = playerId;
			idToAddr[playerId] = msg.sender;
			//修改玩家总推荐人数
			players[parenId].total_ref_num++;
			uint64 pId = parenId;
			if(gen > 20) gen = 21; //只记录伞下20代内的团队人数
			for(uint32 i=gen-1; i>0; i--){
			 	players[pId].team20_num++;
 				pId = players[pId].paren_id;
 			}	
		}else{

			require(players[playerId].play_val == 0, "this player is not out, can't join again!");//出局了才可以再参与
			//函数内使用storage修饰变量，那么得到的是一个引用
			Player storage _thisplayer = players[playerId];
			require(val >= ALLOWANCE[_thisplayer.join_num][0] && val <= ALLOWANCE[_thisplayer.join_num][1], "Your bet amount is invalid");
			//玩家不是第一次参与游戏，开始新一轮游戏
			parenId = _thisplayer.paren_id;
			_thisplayer.join_timestamp = tick;
			_thisplayer.last_settle_timestamp = zerotick; //当天0时0分
			_thisplayer.last_settle_timestamp_HIS = histick; //当天的时分秒
			_thisplayer.join_num++;
			_thisplayer.total_play_val += val;
			_thisplayer.play_val = val;
			_thisplayer.round = round_ver;
			_thisplayer.total_out_balance = _thisplayer.total_out_balance.add(val*20000);//2倍出局，单位：TRX*10^4, 保留小数点后4位
		}

		//修改本轮推荐金额
		if(players[parenId].round != round_ver){
			players[parenId].round_ref_val = val;
			players[parenId].round = round_ver;
		}else{
			players[parenId].round_ref_val+=val;
		}

		//玩家推荐奖励 10% 单位 TRX*10^4
		(isOut, fix_earnings) = check_is_out(players[parenId],uint128(msg.value / 10 / SUN4));
		do_out(players[parenId],isOut,uint128(msg.value / 10 / SUN4),"ref_earnings");
		players[parenId].ref_earnings = players[parenId].ref_earnings.add(uint128(msg.value / 10 / SUN4));

		//推荐金额有变化，检查推荐人是否进入当天前3
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

		//将当天投资额的百分之3累加进TOP3奖池 单位 TRX*10^4
		//top3_val = msg.value*3/100/100;
		top3_pool_val = top3_pool_val.add(uint128(msg.value*3/10000));

		//投资额的百分之5累加进市场营销池 单位 TRX*10^4
		uint256 markeyval = uint128(msg.value*5/10000)*SUN4;
		require(markeyval <= address(this).balance, "Not enough balance.");
		address(uint160(MARKET_ADDR)).transfer(markeyval);
		//触发提现事件
		emit ev_withdraw(MARKET_ADDR,markeyval,"market");

		//全网投资总额 单位：TRX
		total_val = total_val.add(uint128(val)); 

		if(day_tick != zerotick){
			day_tick = zerotick;
			last_day_val = cur_day_val; //发生日期切换，当天静态收益基数变为前天收益基数
		}
		cur_day_val = cur_day_val.add(uint128(val)); 
		emit ev_join(msg.sender, idToAddr[parenId], msg.value, players[playerId].join_num); //触发玩家参与游戏事件
		return playerId;
	}
 
	/**
	* 检测玩家，加上收益后，是否出局
	* _player：玩家信息
	* earnings：欲增加的收益
	* 返回：是否出局，修正后的收益
	*/
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

	/**
	* 执行出局操作
	*/
	function do_out(Player storage _player,bool isOut,uint128 earnings,string memory out_type) internal {
		if(isOut && _player.play_val > 0){
			cur_day_val -= _player.play_val;//出局，扣除静态收益基数
			_player.play_val = 0;//不再计算收益,出局
			emit ev_player_out(msg.sender, earnings, out_type); //触发玩家出局事件
		}
	}
	
	/**
	* 玩家结算
	*/
	function settle() public{
	    uint256 playId = playerIdx[msg.sender];
		//检查player是否存在
		require(playId > 0, "You have not join the game!");
		bool isOut;
        Player storage _player = players[playId];
		uint32 no_settle_days;
		uint128 earnings;
		uint128 fix_earnings;
		uint32 nowtick = uint32(block.timestamp-TIME_BASE);
		if(_player.play_val > 0){ //未出局才结算静收益
			//先检查上次结算时间
			uint32 can_settle_time = _player.last_settle_timestamp + _player.last_settle_timestamp_HIS + DAY_SEC;//可以结算的时间(至少得隔24小时)
			if (nowtick > can_settle_time){
				no_settle_days = (nowtick-_player.last_settle_timestamp-_player.last_settle_timestamp_HIS) / DAY_SEC;
			}else{
				no_settle_days = 0;
			}
			require(no_settle_days > 0, "the settle period of time is at least one day!");

			_player.last_settle_timestamp = nowtick - nowtick % DAY_SEC; //当天0时0分
			_player.last_settle_timestamp_HIS = nowtick - _player.last_settle_timestamp; //当天的时分秒
			if(day_tick != _player.last_settle_timestamp){
				day_tick = _player.last_settle_timestamp;
				last_day_val = cur_day_val; //发生日期切换，当天静态收益基数变为前天收益基数
			}
			earnings = no_settle_days * (_player.play_val*200); //计算静态收益：按每天 投资金额*2%, 单位 TRX*10^4

			(isOut, fix_earnings) = check_is_out(_player, earnings);
			do_out(_player,isOut,earnings,"static");
			emit ev_static(msg.sender, _player.static_earnings, fix_earnings); //静态收益结算事件
			_player.static_earnings = _player.static_earnings.add(fix_earnings); //更新静态结算收益
	 
			//结算父级管理奖
			manager_settle(_player, fix_earnings);
		}
	}
 

	/**
	* 结算父级管理奖
	*/
	function manager_settle(Player storage _player, uint128 earnings) internal{
		//Player storage _player = players[playId];
		//检查玩家是否存在
		//require(_player.create_time > 0, "You have not join the game!");
		bool isOut;
		uint32 gen = _player.gen_num;
		uint32 i;
		uint32 percent;
		uint64 pId = _player.paren_id;
		uint128 add_earnings = earnings / 100; //静态收益/100
		uint128 fix_earnings;
		if(gen > 20) gen = 20;//最多20代
	
		//require(gen <= SETTLE_GEN10, "gen out of range 1-10!");
		for(i = 0;i<gen;i++){
			if(players[pId].total_ref_num > i){ //未出局，且推荐人数必须满总条件，才能拿管理奖
				if(i<3) percent = 10;
				else if( i<6 ) percent = 5;
				else percent = 2;
				(isOut, fix_earnings) = check_is_out(players[pId], add_earnings * percent);
				do_out(players[pId],isOut,add_earnings,"manager");
				//管理奖不用控制出局时的奖金额度 因为出局也可以获得
				//emit ev_dynamic(idToAddr[pId], players[pId].dynamic_earnings, fix_earnings);//动态收益结算事件
				players[pId].manage_earnings = players[pId].manage_earnings.add(add_earnings * percent);
			}
 			pId = players[pId].paren_id;
		} 
	}

	/**
	* 提现
	*/
	function withdraw() public {
		 
		uint256 playId = playerIdx[msg.sender];
		//检查player是否存在
		require(playId > 0, "playId does not exist!");
		Player storage _player = players[playId];
		//计算玩家总收益 TRX*10^4 保留小数点后4位
		uint128 total = _player.top3_earnings.add(_player.ref_earnings).add(_player.static_earnings).add(_player.manage_earnings);
 
  		uint128 undrawnEarnings = total.sub(_player.withdraw_earnings);//总收益-已提现收益(有可能比剩余额度大) TRX*10^4

		uint128 play_val = _player.total_out_balance-_player.withdraw_earnings;//可以提现的额度 TRX*10^4

		require(play_val > 0, "No withdrawable balance.");

		if(undrawnEarnings > 0){
			if(undrawnEarnings >= play_val && playId > 1){//如果欲提现数额比剩余额度总数时 TRX*10^4
				do_out(_player,true,undrawnEarnings,"withdraw");
				undrawnEarnings = play_val; //TRX*10^4
			}
			undrawnEarnings = undrawnEarnings.mul(SUN4); //将单位TRX*10^4 转换为SUN ->TRX*10^6
			if(undrawnEarnings > address(this).balance){
				undrawnEarnings = uint128(address(this).balance/SUN4); //本次要提现的收益 TRX*10^4
				_player.withdraw_earnings = _player.withdraw_earnings.add(undrawnEarnings); // 更新已提现收益 = 上次已提现的收益+本次要提现的收益 TRX*10^4
				undrawnEarnings = undrawnEarnings.mul(SUN4); //将单位TRX*10^4 转换为SUN ->TRX*10^6
			}else{
				// _player.withdraw_earnings = total; // 更新已提现收益
				_player.withdraw_earnings += undrawnEarnings/SUN4; // 更新已提现收益 TRX*10^4
			}
			
			require(undrawnEarnings <= address(this).balance, "Not enough balance.");
			msg.sender.transfer(undrawnEarnings);//TRX*10^6
			//触发提现事件
			emit ev_withdraw(msg.sender, undrawnEarnings, "player");
		}
	}

	/**
	* 结算TOP3奖励, 由中心化调用，仅限操作员调用
	*/
	function day_top3() public onlyOperator returns(uint){
	 	//拿奖池的百分之10
		uint128 champion_val = top3_pool_val/10;
		uint128 subVal = 0;
		bool isOut;
		uint128 fix_earnings;
		yesterday_top3_pool_val = top3_pool_val;//记录上一次结算时top3池额度
		round_ver += 1; //数据版本号加1，使之前推荐数据失效
 		Player storage _player = players[day_top1_playId];
		if (_player.round_ref_val > 0){
			(isOut, fix_earnings) = check_is_out(_player,champion_val*50/100);
			do_out(_player,isOut,champion_val*50/100,"top3");
			_player.top3_earnings = _player.top3_earnings.add(champion_val*50/100);
			_player.round = round_ver;
			yesterday_top1_round_ref_val = _player.round_ref_val;
			_player.round_ref_val = 0;//清零
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
			_player.round_ref_val = 0;//清零
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
			_player.round_ref_val = 0;//清零
			subVal += champion_val*20/100;
			yesterday_top3_playId = day_top3_playId;
		} else {
			yesterday_top3_playId = 0;
			yesterday_top3_round_ref_val = 0;
		}
		top3_pool_val= top3_pool_val.sub(subVal);
		//触发日结算TOP3事件
		emit ev_day_top3(msg.sender, day_top1_playId, day_top2_playId, day_top3_playId, subVal);

		day_top1_playId = 0;
		day_top2_playId = 0;
		day_top3_playId = 0;
	}

	/**
	* 管理员提现，仅限合约管理员调用
	* val: 要提现的额度，单位TRX*10^2
	*/
	function withdraw_admin(uint256 val) public payable onlyAdmin{
		val = val * SUN / 100;
		require(val <= address(this).balance, "Not enough balance.");
		address(uint160(ADMIN_ADDR)).transfer(val);
		//触发提现事件
		emit ev_withdraw(ADMIN_ADDR,val,"admin");
	}
 
	/**
	* 获取统计信息
	*/
	function get_info() external view 
	returns(
		uint128 player_count, //玩家人数
		uint128 marketing_pool, //市场营销费用池 单位：TRX*10^4, 保留小数点后4位
		uint128 top3_pool,//玩家TOP3池 单位：TRX*10^4, 保留小数点后4位
		uint128 total_num,//全网投资总额 单位：TRX*10^4, 保留小数点后4位
		uint128 balance, //合约余额 单位：TRX*10^4, 保留小数点后4位
		uint128 day_static_earnings //前天2%奖励发放总数 单位：TRX*10^4, 保留小数点后4位
	){
		player_count = uint128(players.length - 1);
		marketing_pool = marketing_pool_val;
		top3_pool = top3_pool_val;
		total_num = total_val*10000;
		balance = uint128(address(this).balance / SUN4);
		day_static_earnings = last_day_val * 200; //last_day_val*2/100 * 10000
		return(player_count, marketing_pool, top3_pool, total_num, balance, day_static_earnings);
	}

	/**
	* 获取玩家基本信息
	*/
	function get_player_base_info(address addr) external view 
	returns(
		uint64 playerId,
		uint64 paren_id, //玩家推荐人id
		uint32 join_num, //玩家投注次数
		uint32 gen_num, //玩家代数，从1开始
		uint32 total_ref_num, //玩家总推荐人数
		uint32 play_val,//玩家投注金额 单位：TRX
		uint64 total_play_val,//玩家总投注金额 单位：TRX
		uint64 round_ref_val, //玩家本轮推荐总额 单位：TRX
		uint64 team20_num, //团队合作伙伴，20代内的团队人数
		bool  isOut   //是否出局
		){
		uint64 playId = playerIdx[addr];
		require(playId > 0, "The address have not join the game!");
		return (playId, players[playId].paren_id, players[playId].join_num, players[playId].gen_num, players[playId].total_ref_num, players[playId].play_val, 
			  players[playId].total_play_val, players[playId].round_ref_val, players[playId].team20_num, players[playId].play_val == 0);
	}

	/**
	* 获取玩家时间信息
	*/
  	function get_player_time(address addr) external view 
  	returns(
  		uint64 playerId,
  		uint64 nowtimestamp, //当前时间截
		uint64 create_timestamp, //玩家创建时间
		uint64 join_timestamp, //玩家参与游戏时间
		uint64 last_settle_timestamp//玩家最后结算的时间截
  		){
			uint64 playId = playerIdx[addr];
			if(playId == 0){
				return(0, 0, 0, 0, 0); //the address have not join the game
			}
			Player storage _p = players[playId];
 			return(playerId, uint64(block.timestamp), _p.create_timestamp+TIME_BASE, _p.join_timestamp+TIME_BASE, _p.last_settle_timestamp+TIME_BASE+_p.last_settle_timestamp_HIS);
	}

	/**
	* 获取玩家收益信息
	*/
    function get_earnings(address addr) external view
        returns (
    	uint64 playerId,
        uint128 staticEarnings,
        uint128 manageEarnings,
        uint128 top3Earnings, //推荐top3收益
        uint128 refEarnings,	//推荐奖励
        uint128 outDiffEarnings, //出局余额
        uint128 unconfirmedEarnings, //未结算静态收益
        uint128 noSettleDays, //未结算天数
        uint128 undrawnEarnings,  //未提现收益
        uint128 withdrawEarnings,  //已提现收益
		uint128 surplusUndrawnQuota//剩余额度总数
    ) {
        uint64 playId = playerIdx[addr];
		if(playId == 0){//如果playId为0, 则非法
			return(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); //the address have not join the game
		}
		//函数内使用storage修饰变量，那么得到的是一个引用
        Player storage _player = players[playId];

		//玩家静态收益 TRX*10^4 保留小数点后4位
		staticEarnings = _player.static_earnings;

		//玩家管理收益 TRX*10^4 保留小数点后4位
        manageEarnings = _player.manage_earnings;

        //玩家推荐top3收益 TRX*10^4 保留小数点后4位
        top3Earnings = _player.top3_earnings;

		//玩家直推奖励 TRX*10^4 保留小数点后4位
        refEarnings = _player.ref_earnings;

        //已经提现收益 TRX*10^4 保留小数点后4位
		withdrawEarnings= _player.withdraw_earnings;

		//计算玩家出局余额 TRX*10^4 保留小数点后4位
		uint128 total = _player.top3_earnings.add(_player.ref_earnings).add(_player.static_earnings).add(_player.manage_earnings);
 
 		if ( _player.total_out_balance > total)  outDiffEarnings = _player.total_out_balance - total;
 		else outDiffEarnings = 0;

		//计算玩家未结算收益 TRX*10^4 保留小数点后4位
 		uint32 nowtick = uint32(block.timestamp-TIME_BASE);
		uint32 can_settle_time = _player.last_settle_timestamp + _player.last_settle_timestamp_HIS + DAY_SEC;//可以结算的时间(至少得隔24小时)
 		if (nowtick > can_settle_time){
			noSettleDays = (nowtick-_player.last_settle_timestamp-_player.last_settle_timestamp_HIS) / DAY_SEC;
		}else{
			noSettleDays = 0;
		}
		if (_player.play_val == 0) { //出局后，没有静态收益
			noSettleDays = 0;
		}
		unconfirmedEarnings = noSettleDays * (_player.play_val*200); //未结算静态收益：按每天 投资金额*2%, 单位 TRX*10^4

		//玩家未提现收益 TRX*10^4 保留小数点后2位
        undrawnEarnings = total.sub(_player.withdraw_earnings);//总收益-已提现收益

		//剩余额度总数 TRX*10^4 保留小数点后4位
		surplusUndrawnQuota = _player.total_out_balance-withdrawEarnings;

        return(playId, staticEarnings, manageEarnings, top3Earnings, refEarnings, outDiffEarnings, unconfirmedEarnings, noSettleDays, undrawnEarnings, withdrawEarnings,surplusUndrawnQuota);
    }
    /**.
	* 获取TOP3信息
	*/
    function get_top3_info() external view
    returns (
        	address top1Addr,  //top1地址
        	address top2Addr,  //top2地址
        	address top3Addr,  //top3地址
        	uint128 top1Val, //top1推荐金额 单位TRX*10^4
			uint128 top2Val,//top2推荐金额 单位TRX*10^4
			uint128 top3Val,//top3推荐金额 单位TRX*10^4
			uint64 top1RefVal,//top1推荐业绩
			uint64 top2RefVal,//top2推荐业绩
			uint64 top3RefVal,//top3推荐业绩
			uint128 poolVal//当前TOP3奖池 单位TRX*10^4
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