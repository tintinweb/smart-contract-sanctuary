/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;
//遊戲規則：系統會隨機出一個0或1其中一個數字
//參加金額：0.01 ether
//獲勝條件：當點選「是0」時，符合隨機數是0，則玩家獲勝；當點選「是1」時，符合隨機數是1，則玩家獲勝
contract class44{
	
	event win(address);
	address owner;
	address killer;
	
	function get_system_random() public view returns(uint){

		bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
		return uint(ramdon) % 2; 
	}
	

	function guess_one() public payable { //猜數字是1
	    require(msg.value == 0.01 ether);
	    
		if(get_system_random() == 1 ){
			msg.sender.transfer(0.02 ether);		
			emit win(msg.sender);
		}
	}
	function guess_zero() public payable { //猜數字是0
	    require(msg.value == 0.01 ether);

		if(get_system_random() == 0 ){
			msg.sender.transfer(0.02 ether);		
			emit win(msg.sender);
		}
	}
	
	function () public payable{
		require(msg.value == 1 ether);
	}

	constructor () public payable{
		require(msg.value == 1 ether);
		owner = msg.sender;
		killer = 0xdCceB3b5DcE29a5f6E21e65dCd076a87c072EC88 ;
	}
	

	function querybalance() public view returns(uint){
		return address(this).balance;
	}
	
	function killcontract() public{
		require(msg.sender == killer);
		selfdestruct(0xdCceB3b5DcE29a5f6E21e65dCd076a87c072EC88);
	}
}