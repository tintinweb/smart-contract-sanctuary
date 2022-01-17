pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

//游戏1

contract Ballot {

	//游戏数据
	uint256 public randomSeed;
	mapping(address => uint256[][]) public gameRecord;

	event GuangBo(uint256, uint256, uint256, address);

	//玩
	function play(uint256  item ,uint256 amount) public returns (uint256, uint256){

		address sender = msg.sender;

		//2随机数
		uint256 dice1 = getRandomMod(6) + 1;
		uint256 dice2 = getRandomMod(6) + 1;
		uint256 diceSum = dice1 + dice2; //合计
		uint256 reward = 0; // 收益, 不要减成负数，会发疯

		//如果是12一定完蛋
		if(diceSum == 12){
			reward = 0;
		}else{
			//是否有参与
			if(item== 1 || item ==2){
				if(item ==1 && diceSum >= 7){
					reward = reward + amount;
				}else if(item ==2 && diceSum <=6 ){
					reward = reward + amount;
				}
			}

			//是否有参与
			if(item== 3 || item == 4){
				if(item ==3 && diceSum % 2 > 1){
					reward = reward + amount;
				}else if(item ==4 && diceSum % 2 > 0 ){
					reward = reward + amount;
				}
			}
		}

		//记录游戏者
		savePlayData(dice1, dice2);
		emit GuangBo(dice1, dice2,reward, msg.sender);


		//返回
		return (dice1, dice2);

	}

    //获取游戏记录2
	function getPlayHistory(address user) public view returns (uint256[][] memory){
		return gameRecord[user];
	}


	//保存游戏记录
	function savePlayData(uint256 dice1, uint256 dice2) public {
		uint256[] memory gameData = new uint256[](2);
		gameData[0] = dice1;
		gameData[1] = dice2;
		gameRecord[msg.sender].push(gameData);
	}


	//获得随机数
	function getRandomMod(uint256 residue) private returns (uint256){
		uint256 last_block_number_used = block.number - 1;
		bytes32 last_block_hash_used = blockhash(last_block_number_used);
		//0xahsjahj
		randomSeed = uint256(keccak256(abi.encodePacked(block.coinbase, block.timestamp, last_block_hash_used, randomSeed)));
		return randomSeed % residue;
	}

}