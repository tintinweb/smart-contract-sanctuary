/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: NONE


pragma solidity ^0.8.0;


interface IRandom{
    function calculate() external view returns (uint256);
    
}

contract CoinFlip {
    address payable owner;
    uint payPercentage = 90;
	
	
	IRandom public RandomNumber;
	
	struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
		uint prize;
        bool winner;
    }
	
	Game[] lastPlayedGames;
	
	Game newGame;
    
    event Status(
		string _msg, 
		address user, 
		uint amount,
		bool winner
	);
    
    constructor (address generator)  {
        owner = payable (msg.sender);
        RandomNumber = IRandom(generator) ;
    }
    
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert();
        } else {
            _;
        }
    }
    
    function Play(uint _HT) public payable {
		address payable user = payable (msg.sender);
            uint no = RandomNumber.calculate();
// 			if ((block.timestamp % 2) == _HT ) {
			if ((no % 2) == _HT ) {	
				if ((address(this)).balance < (msg.value * ((100 + payPercentage) / 100))) {
					// No tenemos suficientes fondos para pagar el premio, así que transferimos todo lo que tenemos
					(user).transfer((address(this)).balance);
					emit Status('Congratulations, you win! Sorry, we didn"t have enought money, we will deposit everything we have!', msg.sender, msg.value, true);
					
					newGame = Game({
						addr: msg.sender,
						blocknumber: block.number,
						blocktimestamp: block.timestamp,
						bet: msg.value,
						prize: (address(this)).balance,
						winner: true
					});
					lastPlayedGames.push(newGame);
					
				} else {
					uint _prize = msg.value * (100 + payPercentage) / 100;
					emit Status('Congratulations, you win!', msg.sender, _prize, true);
					user.transfer(_prize);
					
					newGame = Game({
						addr: msg.sender,
						blocknumber: block.number,
						blocktimestamp: block.timestamp,
						bet: msg.value,
						prize: _prize,
						winner: true
					});
					lastPlayedGames.push(newGame);
					
				}
			} else {
				emit Status('Sorry, you loose!', msg.sender, msg.value, false);
				
				newGame = Game({
					addr: msg.sender,
					blocknumber: block.number,
					blocktimestamp: block.timestamp,
					bet: msg.value,
					prize: 0,
					winner: false
				});
				lastPlayedGames.push(newGame);
				
			}
		}


	function getGameCount() public view returns(uint) {
		return lastPlayedGames.length;
	}

	function getGameEntry(uint index) public view returns(address addr, uint blocknumber, uint blocktimestamp, uint bet, uint prize, bool winner) {
		return (lastPlayedGames[index].addr, lastPlayedGames[index].blocknumber, lastPlayedGames[index].blocktimestamp, lastPlayedGames[index].bet, lastPlayedGames[index].prize, lastPlayedGames[index].winner);
	}
	
	
	function depositFunds(uint amount) public onlyOwner payable {
        if (owner.send(amount)) {
        emit Status('User has deposit some money!', msg.sender, msg.value, true);
        }
    }
    
	function withdrawFunds(uint amount) public  onlyOwner {
        if (owner.send(amount)) {
        emit Status('User withdraw some money!', msg.sender, amount, true);
        }
    }
	
    function ContractBalance() public view onlyOwner returns(uint){
        uint balance = (address(this)).balance;
        return (balance);
    }
	
    
    function Kill() public onlyOwner {
        emit Status('Contract was killed, contract balance will be send to the owner!', msg.sender, (address(this)).balance, true);
        selfdestruct(owner);
    }
}