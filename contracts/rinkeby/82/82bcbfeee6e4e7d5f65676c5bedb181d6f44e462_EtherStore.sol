/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.24;

contract EtherStore{

	//存款合約

	uint256 public withdrawalLimit = 1 ether;
	mapping(address=>uint256)public lastWithdrawTime;
	mapping(address=>uint256)public balances;

	function depositFunds()public payable{
		balances[msg.sender]+=msg.value;
	}

	function withdrawFunds(uint256 _weiToWithdraw)public{

		require(balances[msg.sender]>=_weiToWithdraw);
		
		//limitthewithdrawal
		require(_weiToWithdraw<=withdrawalLimit);

		//limitthetimeallowedtowithdraw
		require(now>=lastWithdrawTime[msg.sender] + 1 weeks);

		require(msg.sender.call.value(_weiToWithdraw)());

		balances[msg.sender]-=_weiToWithdraw;

		lastWithdrawTime[msg.sender]=now;
	}
}