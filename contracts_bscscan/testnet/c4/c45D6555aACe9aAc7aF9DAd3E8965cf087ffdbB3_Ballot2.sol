pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

//大游戏

contract Ballot2 {


	//游戏数据
	uint256 randomSeed;//用于保存上一次随机数，作为种子
	bytes32[] public itemMap;//所有规则64字符数组
	mapping(bytes32 => uint256) public itemInvolved;//所有有参与的规则保存,key是前端转化的64位的那个字母，value则是发送数量
	mapping(bytes32 => uint256) public diceCount;//点数的数量string是英文，uint是数量

	//事件查看
	event GuangBo(uint256, uint256, uint256, uint256,uint256);//最后一个是奖励

	//各个规则映射啥的？？
	bytes32 small  = 0x736d616c6c000000000000000000000000000000000000000000000000000000;
	bytes32 odd    = 0x6f64640000000000000000000000000000000000000000000000000000000000;
	bytes32 triple = 0x747269706c650000000000000000000000000000000000000000000000000000;
	bytes32 even   = 0x6576656e00000000000000000000000000000000000000000000000000000000;
	bytes32 big    = 0x6269670000000000000000000000000000000000000000000000000000000000;
	bytes32 one    = 0x6f6e650000000000000000000000000000000000000000000000000000000000;
	bytes32 two    = 0x74776f0000000000000000000000000000000000000000000000000000000000;
	bytes32 three  = 0x7468726565000000000000000000000000000000000000000000000000000000;
	bytes32 four   = 0x666f757200000000000000000000000000000000000000000000000000000000;
	bytes32 five   = 0x6669766500000000000000000000000000000000000000000000000000000000;
	bytes32 six    = 0x7369780000000000000000000000000000000000000000000000000000000000;


	//构造函数
	constructor() public{
		itemMap.push(0x736d616c6c000000000000000000000000000000000000000000000000000000); //small
		itemMap.push(0x6f64640000000000000000000000000000000000000000000000000000000000); //odd
		itemMap.push(0x747269706c650000000000000000000000000000000000000000000000000000); //triple
		itemMap.push(0x6576656e00000000000000000000000000000000000000000000000000000000); //even
		itemMap.push(0x6269670000000000000000000000000000000000000000000000000000000000); //big
		itemMap.push(0x6f6e650000000000000000000000000000000000000000000000000000000000); // 1
		itemMap.push(0x74776f0000000000000000000000000000000000000000000000000000000000); //2
		itemMap.push(0x7468726565000000000000000000000000000000000000000000000000000000); //3
		itemMap.push(0x666f757200000000000000000000000000000000000000000000000000000000); //4
		itemMap.push(0x6669766500000000000000000000000000000000000000000000000000000000); //5
		itemMap.push(0x7369780000000000000000000000000000000000000000000000000000000000); //6

	}

	//玩
	function play(bytes32[] memory itemData, uint128[] memory amountArr) public returns(uint256,uint256,uint256){
		//数据初始化
		address sender = msg.sender;//触发者
		uint256 totalAmount = 0;//总发送数
		uint256 reward = 0;//总奖励
		uint256 lost = 0 ; //失去的

		//得出三个狗日点数
		uint256 dice1 = getRandomMod(6) + 1;
		uint256 dice2 = getRandomMod(6) + 1;
		uint256 dice3 = getRandomMod(6) + 1;
		uint256 diceSum = dice1 + dice2 + dice3;
		
		//把三个点数，装成一个数组
		uint256[] memory diceArr = new uint256[](3);
		diceArr[0] = dice1;
		diceArr[1] = dice2;
		diceArr[2] = dice3;
		
		//遍历点数进行相关处理(统计各点数的数量)
		for(uint i = 0 ;i < diceArr.length; i++ ){
			if(diceArr[i] == 1){
				diceCount[one] = diceCount[one] + 1;
			}else if(diceArr[i] == 2){
				diceCount[two] = diceCount[two] + 1;
			}else if(diceArr[i] == 3){
				diceCount[three] = diceCount[three] + 1;
			}else if(diceArr[i] == 4){
				diceCount[four] = diceCount[four] + 1;
			}else if(diceArr[i] == 5){
				diceCount[five] = diceCount[five] + 1;
			}else if(diceArr[i] == 6){
				diceCount[six] = diceCount[six] + 1;
			}
		}
		

		//遍历传过来的数据，进行相关处理
		for (uint i = 0; i < itemData.length; i ++) {
			bytes32 _item = itemData[i];
			itemInvolved[_item] = amountArr[i];//放到我参与的规则数据中
			totalAmount         = totalAmount + amountArr[i]; //计算发送总数
		}

		//判断
		if(dice1 == dice2 && dice2 == dice3){//是否三个一样
			if(itemInvolved[triple]  > 0) { //是否有参与
				reward = reward + (itemInvolved[triple] * 33);
				lost = itemInvolved[small] + itemInvolved[big] +itemInvolved[even] + itemInvolved[odd] ;//其它4种就失去了
			}else{//没有参与
				lost = itemInvolved[small] + itemInvolved[big] +itemInvolved[even] + itemInvolved[odd] ; //其它4种也失去
			}
		}else{
			//判断大或小
			if(diceSum >= 10){//大
				if(itemInvolved[big] > 0 ){//有参与
					reward = reward + itemInvolved[big] * 2; //奖励
				}
				lost = lost + itemInvolved[small];//小的数量肯定失去了
			}else{//小
				if(itemInvolved[small] > 0 ){//有参与
					reward = reward + itemInvolved[small] * 2; //奖励
				}
				lost = lost + itemInvolved[big];//大的数量肯定失去了
			}

			//判断奇或偶
			if(diceSum % 2 == 1){ //奇
				if(itemInvolved[odd] > 0){//参与了奇
					reward = reward + itemInvolved[odd] * 2;//奖励
				}
				lost = lost + itemInvolved[even];//偶的数量就没有了
			}else{ // 偶
				if(itemInvolved[even] > 0 ){//参与了偶
					reward = reward + itemInvolved[even] * 2; // 偶奖励
				}
				lost = lost + itemInvolved[odd];//奇就没有了
			}
			
			
			//遍历处理，也不知会不会发瘟
			for(uint k = 0 ;k < itemMap.length; k ++){
				bytes32 key = itemMap[k];
				if(itemInvolved[key] > 0 ){
					if(diceCount[key] > 0){// 有1
						reward = reward + (itemInvolved[key] * (diceCount[key] + 1));//乘以数量的数量，还要+1
					}else{//没有就失去
						lost = lost +  itemInvolved[key];
					}
				}
			}
		
			emit GuangBo(dice1,dice2,dice3,reward,lost);
		}



	}




	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//获得随机数
	function getRandomMod(uint256 residue) private returns (uint256){
		uint256 last_block_number_used = block.number - 1;
		bytes32 last_block_hash_used = blockhash(last_block_number_used);//0xahsjahj
		randomSeed = uint256(keccak256(abi.encodePacked(block.coinbase, block.timestamp, last_block_hash_used, randomSeed)));
		return randomSeed % residue;
	}

}

//加减乘除
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		uint256 c = a - b;
		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {return 0;}
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "SafeMath: division by zero");
		uint256 c = a / b;
		return c;
	}
}