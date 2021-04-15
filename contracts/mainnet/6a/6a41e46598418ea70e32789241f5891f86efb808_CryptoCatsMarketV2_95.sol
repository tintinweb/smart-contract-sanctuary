pragma solidity ^0.8.0;

import "AccessControl.sol";
import "SafeMath.sol";
import "Context.sol";
import "ERC165.sol";
import "IERC165.sol";

interface CryptoCats{
	function catIndexToAddress(uint catIndex) external view returns(address);
	function buyCat(uint catIndex) external payable;
	function transfer(address addressto, uint catIndex) external;
}

contract CryptoCatsMarketV2_95 is AccessControl {

	/*
	Marketplace based on the Larvalabs OGs!
	*/

	using SafeMath for uint256;

	string public name = "CryptoCatsMarketV2_95";

	CryptoCats public constant cryptocats = CryptoCats(0x9508008227b6b3391959334604677d60169EF540);

	uint public FEE = 20; //5%
	uint public feesToCollect = 0;

    struct Bid {
        uint catIndex;
		uint amount;
        address bidder;
    }

    // A record of the highest Cryptocat bid
    mapping (uint => Bid) public bids;
	mapping (address => uint) public pendingWithdrawals;

    event CryptoCatsTransfer(uint indexed index, address from, address to);
    event CryptoCatsBidCreated(uint indexed index, uint amount, address bidder);
    event CryptoCatsBidWithdrawn(uint indexed index, uint amount, address bidder);
    event CryptoCatsBought(uint indexed index, uint amount, address seller, address bidder);

    constructor() public {
		_setupRole(DEFAULT_ADMIN_ROLE, 0xaaEa1B588c41dddEa4afDa5105e1C4f0bdB017F5);
    }

	function collectFees() public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
		uint amount = feesToCollect;
		feesToCollect = 0;
		payable(0xaaEa1B588c41dddEa4afDa5105e1C4f0bdB017F5).transfer(amount);
	}

	function changeFee(uint newFee) public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
		FEE = newFee;
	}
	
	
	
	function bid(uint catIndex) public payable {
		require(msg.value > 0, "BID::Value is 0");
		Bid memory bid = bids[catIndex];
		require(msg.value > bid.amount, "BID::New bid too low");
		//refund failing bid
		pendingWithdrawals[bid.bidder] += bid.amount;
		//new bid
		bids[catIndex] = Bid(catIndex, msg.value, msg.sender);
		emit CryptoCatsBidCreated(catIndex, msg.value, msg.sender);
	}

	function withdrawBid(uint catIndex) public {
		Bid memory bid = bids[catIndex];
		require(msg.sender == bid.bidder, "WITHDRAW_BID::Only bidder can withdraw his bid");
		emit CryptoCatsBidWithdrawn(catIndex, bid.amount, msg.sender);
		uint amount = bid.amount;
		bids[catIndex] = Bid(catIndex, 0, address(0x0));
		payable(msg.sender).transfer(amount);
	}


	function acceptBid(uint catIndex, uint minPrice) public {
		require(cryptocats.catIndexToAddress(catIndex) == msg.sender, "ACCEPT_BID::Only owner can accept bid");
        Bid memory bid = bids[catIndex];
		require(bid.amount > 0, "ACCEPT_BID::Bid amount is 0");
		require(bid.amount >= minPrice, "ACCEPT_BID::Min price not respected");
		// With the require getOwner we check already, if it can be assigned, no other checks needed
		cryptocats.buyCat(catIndex);
		cryptocats.transfer(bid.bidder, catIndex);

		//collect fee
		uint fees = bid.amount.div(FEE);
		feesToCollect += fees;

        uint amount = bid.amount.sub(fees);
		bids[catIndex] = Bid(catIndex, 0, address(0x0));
        pendingWithdrawals[msg.sender] += amount;
        emit CryptoCatsBought(catIndex, amount, msg.sender, bid.bidder);
		emit CryptoCatsTransfer(catIndex, msg.sender, bid.bidder);
    }



	function withdraw() public {
		uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
	}
}