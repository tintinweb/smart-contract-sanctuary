/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.4.11;

contract AuctionGetmoney {
	address public highestBidder;	// 최고 입찰자 어드레스
	uint public highestBid;	// 최고 입찰액
	mapping(address => uint) public userBalances;	// 반환할 액수를 관리하는 매핑
	
	/// 생성자
	function AuctionWithdraw() payable {
		highestBidder = msg.sender;
		highestBid = 0;
	}
	
	/// 입찰 처리 함수
	function bid() public payable {
		// 입찰액이 현재 최고 입찰액보다 큰지 확인
		require(msg.value > highestBid);

		// 최고 입찰자 어드레스에 대한 반환액수 업데이트
		userBalances[highestBidder] += highestBid;
				
		// 스테이트 업데이트
		highestBid = msg.value;
		highestBidder = msg.sender;
	}
	
	function withdraw() public{
		// 반환할 액수가 0보다 큰지 확인
		require(userBalances[msg.sender] > 0);
		
		// 반환할 액수를 구함
		uint refundAmount = userBalances[msg.sender];
		
		// 반환액 업데이트
		userBalances[msg.sender] = 0;
		
		// 입찰금 반환 처리
		if(!msg.sender.send(refundAmount)) {
			throw;
		}
	}
}