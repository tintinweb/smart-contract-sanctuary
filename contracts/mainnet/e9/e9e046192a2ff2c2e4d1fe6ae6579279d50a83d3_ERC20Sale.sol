pragma solidity ^0.4.24;

interface ERC20 {
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	function name() external view returns (string);
	function symbol() external view returns (string);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address _owner) external view returns (uint256 balance);
	function transfer(address _to, uint256 _value) external payable returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) external payable returns (bool success);
	function approve(address _spender, uint256 _value) external payable returns (bool success);
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// 숫자 계산 시 오버플로우 문제를 방지하기 위한 라이브러리
library SafeMath {
	
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	function sub(uint256 a, uint256 b) pure internal returns (uint256 c) {
		assert(b <= a);
		return a - b;
	}
	
	function mul(uint256 a, uint256 b) pure internal returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) pure internal returns (uint256 c) {
		return a / b;
	}
}

// ERC20 토큰을 이더로 거래합니다.
contract ERC20Sale {
	using SafeMath for uint256;
	
	// 이벤트들
	event Bid(uint256 bidId);
	event ChangeBidId(uint256 indexed originBidId, uint256 newBidId);
	event RemoveBid(uint256 indexed bidId);
	event CancelBid(uint256 indexed bidId);
	event Sell(uint256 indexed bidId, uint256 amount);
	
	event Offer(uint256 offerId);
	event ChangeOfferId(uint256 indexed originOfferId, uint256 newOfferId);
	event RemoveOffer(uint256 indexed offerId);
	event CancelOffer(uint256 indexed offerId);
	event Buy(uint256 indexed offerId, uint256 amount);
	
	// 구매 정보
	struct BidInfo {
		address bidder;
		address token;
		uint256 amount;
		uint256 price;
	}
	
	// 판매 정보
	struct OfferInfo {
		address offeror;
		address token;
		uint256 amount;
		uint256 price;
	}
	
	// 정보 저장소
	BidInfo[] public bidInfos;
	OfferInfo[] public offerInfos;
	
	function getBidCount() view public returns (uint256) {
		return bidInfos.length;
	}
	
	function getOfferCount() view public returns (uint256) {
		return offerInfos.length;
	}
	
	// 토큰 구매 정보를 거래소에 등록합니다.
	function bid(address token, uint256 amount) payable public {
		
		// 구매 정보 생성
		uint256 bidId = bidInfos.push(BidInfo({
			bidder : msg.sender,
			token : token,
			amount : amount,
			price : msg.value
		})).sub(1);
		
		emit Bid(bidId);
	}
	
	// 토큰 구매 정보를 삭제합니다.
	function removeBid(uint256 bidId) internal {
		
		for (uint256 i = bidId; i < bidInfos.length - 1; i += 1) {
			bidInfos[i] = bidInfos[i + 1];
			
			emit ChangeBidId(i + 1, i);
		}
		
		delete bidInfos[bidInfos.length - 1];
		bidInfos.length -= 1;
		
		emit RemoveBid(bidId);
	}
	
	// 토큰 구매를 취소합니다.
	function cancelBid(uint256 bidId) public {
		
		BidInfo memory bidInfo = bidInfos[bidId];
		
		// 구매자인지 확인합니다.
		require(bidInfo.bidder == msg.sender);
		
		// 구매 정보 삭제
		removeBid(bidId);
		
		// 이더를 환불합니다.
		bidInfo.bidder.transfer(bidInfo.price);
		
		emit CancelBid(bidId);
	}
	
	// 구매 등록된 토큰을 판매합니다.
	function sell(uint256 bidId, uint256 amount) public {
		
		BidInfo storage bidInfo = bidInfos[bidId];
		ERC20 erc20 = ERC20(bidInfo.token);
		
		// 판매자가 가진 토큰의 양이 판매할 양보다 많아야 합니다.
		require(erc20.balanceOf(msg.sender) >= amount);
		
		// 거래소에 인출을 허락한 토큰의 양이 판매할 양보다 많아야 합니다.
		require(erc20.allowance(msg.sender, this) >= amount);
		
		// 구매하는 토큰의 양이 판매할 양보다 많아야 합니다.
		require(bidInfo.amount >= amount);
		
		uint256 realPrice = amount.mul(bidInfo.price).div(bidInfo.amount);
		
		// 가격 계산에 문제가 없어야 합니다.
		require(realPrice.mul(bidInfo.amount) == amount.mul(bidInfo.price));
		
		// 토큰 구매자에게 토큰을 지급합니다.
		erc20.transferFrom(msg.sender, bidInfo.bidder, amount);
		
		// 가격을 내립니다.
		bidInfo.price = bidInfo.price.sub(realPrice);
		
		// 구매할 토큰의 양을 줄입니다.
		bidInfo.amount = bidInfo.amount.sub(amount);
		
		// 토큰을 모두 구매하였으면 구매 정보 삭제
		if (bidInfo.amount == 0) {
			removeBid(bidId);
		}
		
		// 판매자에게 이더를 지급합니다.
		msg.sender.transfer(realPrice);
		
		emit Sell(bidId, amount);
	}
	
	// 주어진 토큰에 해당하는 구매 정보 개수를 반환합니다.
	function getBidCountByToken(address token) view public returns (uint256) {
		
		uint256 bidCount = 0;
		
		for (uint256 i = 0; i < bidInfos.length; i += 1) {
			if (bidInfos[i].token == token) {
				bidCount += 1;
			}
		}
		
		return bidCount;
	}
	
	// 주어진 토큰에 해당하는 구매 정보 ID 목록을 반환합니다.
	function getBidIdsByToken(address token) view public returns (uint256[]) {
		
		uint256[] memory bidIds = new uint256[](getBidCountByToken(token));
		
		for (uint256 i = 0; i < bidInfos.length; i += 1) {
			if (bidInfos[i].token == token) {
				bidIds[bidIds.length - 1] = i;
			}
		}
		
		return bidIds;
	}

	// 토큰 판매 정보를 거래소에 등록합니다.
	function offer(address token, uint256 amount, uint256 price) public {
		ERC20 erc20 = ERC20(token);
		
		// 판매자가 가진 토큰의 양이 판매할 양보다 많아야 합니다.
		require(erc20.balanceOf(msg.sender) >= amount);
		
		// 거래소에 인출을 허락한 토큰의 양이 판매할 양보다 많아야 합니다.
		require(erc20.allowance(msg.sender, this) >= amount);
		
		// 판매 정보 생성
		uint256 offerId = offerInfos.push(OfferInfo({
			offeror : msg.sender,
			token : token,
			amount : amount,
			price : price
		})).sub(1);
		
		emit Offer(offerId);
	}
	
	// 토큰 판매 정보를 삭제합니다.
	function removeOffer(uint256 offerId) internal {
		
		for (uint256 i = offerId; i < offerInfos.length - 1; i += 1) {
			offerInfos[i] = offerInfos[i + 1];
			
			emit ChangeOfferId(i + 1, i);
		}
		
		delete offerInfos[offerInfos.length - 1];
		offerInfos.length -= 1;
		
		emit RemoveOffer(offerId);
	}
	
	// 토큰 판매를 취소합니다.
	function cancelOffer(uint256 offerId) public {
		
		// 판매자인지 확인합니다.
		require(offerInfos[offerId].offeror == msg.sender);
		
		// 판매 정보 삭제
		removeOffer(offerId);
		
		emit CancelOffer(offerId);
	}
	
	// 판매 등록된 토큰을 구매합니다.
	function buy(uint256 offerId, uint256 amount) payable public {
		
		OfferInfo storage offerInfo = offerInfos[offerId];
		ERC20 erc20 = ERC20(offerInfo.token);
		
		// 판매자가 가진 토큰의 양이 판매할 양보다 많아야 합니다.
		require(erc20.balanceOf(offerInfo.offeror) >= amount);
		
		// 거래소에 인출을 허락한 토큰의 양이 판매할 양보다 많아야 합니다.
		require(erc20.allowance(offerInfo.offeror, this) >= amount);
		
		// 판매하는 토큰의 양이 구매할 양보다 많아야 합니다.
		require(offerInfo.amount >= amount);
		
		// 토큰 가격이 제시한 가격과 동일해야합니다.
		require(offerInfo.price.mul(amount) == msg.value.mul(offerInfo.amount));
		
		// 토큰 구매자에게 토큰을 지급합니다.
		erc20.transferFrom(offerInfo.offeror, msg.sender, amount);
		
		// 가격을 내립니다.
		offerInfo.price = offerInfo.price.sub(msg.value);
		
		// 판매 토큰의 양을 줄입니다.
		offerInfo.amount = offerInfo.amount.sub(amount);
		
		// 토큰이 모두 팔렸으면 판매 정보 삭제
		if (offerInfo.amount == 0) {
			removeOffer(offerId);
		}
		
		// 판매자에게 이더를 지급합니다.
		offerInfo.offeror.transfer(msg.value);
		
		emit Buy(offerId, amount);
	}
	
	// 주어진 토큰에 해당하는 판매 정보 개수를 반환합니다.
	function getOfferCountByToken(address token) view public returns (uint256) {
		
		uint256 offerCount = 0;
		
		for (uint256 i = 0; i < offerInfos.length; i += 1) {
			if (offerInfos[i].token == token) {
				offerCount += 1;
			}
		}
		
		return offerCount;
	}
	
	// 주어진 토큰에 해당하는 판매 정보 ID 목록을 반환합니다.
	function getOfferIdsByToken(address token) view public returns (uint256[]) {
		
		uint256[] memory offerIds = new uint256[](getOfferCountByToken(token));
		
		for (uint256 i = 0; i < offerInfos.length; i += 1) {
			if (offerInfos[i].token == token) {
				offerIds[offerIds.length - 1] = i;
			}
		}
		
		return offerIds;
	}
}