/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.4.11;

contract Auction {
	address public highestBidder;	// 최고 입찰자 어드레스
	uint public highestBid;	// 최고 입찰액
	
	/// 생성자
	function Auction() payable {
		highestBidder = msg.sender;
		highestBid = 0;
	}
	
	/// 입찰 처리 함수
	function bid() public payable {
		// 현재 입찰액이 최고 입찰액보다 높은지 확인
		require(msg.value > highestBid);
		
		// 기존 최고 입찰자에게 반환할 액수 설정
		uint refundAmount = highestBid;
		
		// 최고입찰자 어드레스 업데이트
		address currentHighestBidder = highestBidder;
		
		// 스테이트 값 업데이트
		highestBid = msg.value;
		highestBidder = msg.sender;
		
		// 이전 최고액 입찰자에게 입찰금 반환
		if(!currentHighestBidder.send(refundAmount)) {
			throw;
		}
	}
}