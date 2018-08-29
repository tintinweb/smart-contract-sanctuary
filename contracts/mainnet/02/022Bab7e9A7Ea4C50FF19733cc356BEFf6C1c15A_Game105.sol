pragma solidity ^0.4.22;

contract Game105 {
	struct GameInfo {
	    uint funderNum;
		mapping(uint => address) funder;
		mapping(uint => address) winner;
	}

	GameInfo[] public games;
	uint public gameNum = 0;
	mapping(address => uint) public lastGame;
	mapping(address => uint) public funderBalance;
	mapping(address => address) public referrer;

	address public manager;
	uint count = 10000000000000000 * 5;

	constructor() public {
		manager = msg.sender;
		referrer[manager] = manager;
		games.push(GameInfo(0));
	}

	function addIn(address referr) public payable returns (bool){
		require(
			msg.value == 100 * count,
			"ETH count is wrong!"
		);
		if(lastGame[msg.sender] == 0){
			if(referr == msg.sender){
				referrer[msg.sender] = manager;
			}
			else {
				referrer[msg.sender] = referr;
			}
		}
		games[gameNum].funder[games[gameNum].funderNum] = msg.sender;
		games[gameNum].funderNum += 1;
		lastGame[msg.sender] = gameNum;
		if (games[gameNum].funderNum == 10) {
			uint winNum = (now + gameNum)%10;
			games[gameNum].winner[0] = games[gameNum].funder[winNum];
			games[gameNum].winner[1] = games[gameNum].funder[(winNum+3)%10];
			games[gameNum].winner[2] = games[gameNum].funder[(winNum+6)%10];
			funderBalance[games[gameNum].winner[0]] += 450 * count;
			funderBalance[games[gameNum].winner[1]] += 300 * count;
			funderBalance[games[gameNum].winner[2]] += 200 * count;
			funderBalance[manager] += 10 * count;
			for(uint8 i=0;i<10;i++){
				address addr = referrer[games[gameNum].funder[i]];
				funderBalance[addr] += count;
				funderBalance[referrer[addr]] += count;
				funderBalance[referrer[referrer[addr]]] += count / 2;
				funderBalance[referrer[referrer[referrer[addr]]]] += count / 2;
				funderBalance[referrer[referrer[referrer[referrer[addr]]]]] += count / 2;
				funderBalance[referrer[referrer[referrer[referrer[referrer[addr]]]]]] += count / 2;
			}
			gameNum += 1;
			games.push(GameInfo(0));
		}
		return true;
	}

	function withdraw(uint amount) public {
		require(
			funderBalance[msg.sender] >= amount,
			"ETH Out of balance!"
		);
		funderBalance[msg.sender] += -amount;
        msg.sender.transfer(amount);
    }

	function getLastGame() public view returns (uint last, uint num, uint balance, address winer1, address winer2, address winer3){
		last = lastGame[msg.sender];
		GameInfo storage  game = games[lastGame[msg.sender]];
		num = game.funderNum;
		if(game.funderNum == 10){
			winer1 = game.winner[0];
			winer2 = game.winner[1];
			winer3 = game.winner[2];
		}
		balance = funderBalance[msg.sender];
	}

	function getNewGame() public view returns (uint last, uint num, address winer1, address winer2, address winer3){
		last = gameNum;
		GameInfo storage  game = games[gameNum];
		num = game.funderNum;
		if(game.funderNum == 3){
			winer1 = game.winner[0];
			winer2 = game.winner[1];
			winer3 = game.winner[2];
		}
	}
}