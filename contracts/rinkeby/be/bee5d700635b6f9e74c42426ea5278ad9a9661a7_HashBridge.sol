// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashBridge is Ownable {
	address public hashAddress;
	uint public reservationTime;
	uint public minVoteWeight;
	uint public votesThreshold;
	uint public arbitratorGuaranteePercent;
	uint public commissionForDeal;
	uint public finalVoteBonusPercent;

	uint public constant RATE_DECIMALS = 18;

	struct Offer {
		address token;
		uint amount;
		address payToken;
		uint rate;
		address ownerAddress;
		address payAddress;
		uint minPurchase;
		bool active;
	}
	struct Order {
		uint offerId;
		uint rate;
		address ownerAddress;
		address withdrawAddress;
		uint amount;
		uint payAmount;
		address payAddress;
		uint reservedUntil;
		bool paid;
		uint votesFor;
		uint votesAgainst;
		bool complete;
		bool declined;
	}
	struct Payment {
		uint orderId;
		uint payAmount;
		address payToken;
		address payAddress;
	}
	struct Vote {
	    uint orderId;
	    address voterAddress;
	    uint voteWeight;
	    uint guarantee;
	    bool success;
	    bool ultimate;
	}

	Offer[] offers;
	Order[] public orders;
	Payment[] payments;
	Vote[] votes;

	event OfferAdd(uint indexed offerId, address indexed token, address indexed payToken, address ownerAddress, address payAddress, uint amount, uint rate, uint minPurchase, bool active);
	event OfferUpdate(uint indexed offerId, address payAddress, uint amount, uint rate, uint minPurchase, bool active);
	event OrderAdd(uint indexed orderId, uint indexed offerId, address indexed ownerAddress, uint rate, address withdrawAddress, uint amount, uint payAmount, address payAddress, uint reservedUntil);
	event OrderPay(uint indexed paymentId, uint indexed orderId, uint payAmount, address payToken, address payAddress);
	event OrderMarkAsPaid(uint indexed orderId, uint payAmount, address payToken, address payAddress);
	event VoteAdd(uint indexed voteId, uint indexed orderId, address indexed voterAddress, uint voteWeight, uint guarantee, bool success, bool ultimate, uint offerAmount);

	constructor(address _hashAddress, uint _reservationTime, uint _minVoteWeight, uint _votesThreshold, uint _arbitratorGuaranteePercent, uint _commissionForDeal, uint _finalVoteBonusPercent) {
        hashAddress = _hashAddress;
		reservationTime = _reservationTime;
		minVoteWeight = _minVoteWeight;
		votesThreshold = _votesThreshold;
		arbitratorGuaranteePercent = _arbitratorGuaranteePercent;
		commissionForDeal = _commissionForDeal;
		finalVoteBonusPercent = _finalVoteBonusPercent;
    }

	function changeHashAddress(address _hashAddress) external onlyOwner {
        hashAddress = _hashAddress;
    }

	function changeReservationTime(uint _reservationTime) external onlyOwner {
		reservationTime = _reservationTime;
	}

	function changeMinVoteWeight(uint _minVoteWeight) external onlyOwner {
		minVoteWeight = _minVoteWeight;
	}

	function changeVotesThreshold(uint _votesThreshold) external onlyOwner {
		votesThreshold = _votesThreshold;
	}

	function changeArbitratorGuaranteePercent(uint _arbitratorGuaranteePercent) external onlyOwner {
		arbitratorGuaranteePercent = _arbitratorGuaranteePercent;
	}

	function changeCommissionForDeal(uint _commissionForDeal) external onlyOwner {
		commissionForDeal = _commissionForDeal;
	}

	function changeFinalVoteBonusPercent(uint _finalVoteBonusPercent) external onlyOwner {
		finalVoteBonusPercent = _finalVoteBonusPercent;
	}

	function addOffer(address _token, uint _amount, address _payToken, uint _rate, address _payAddress, uint _minPurchase) external {
		require(_amount > 0, "Amount must be greater than 0");
		require(_amount >= _minPurchase, "Amount must not be less than the minimum purchase");
		require(_rate > 0, "Rate must be greater than 0");
		_checkExchangerHashBalance(msg.sender);
		TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
		uint offerId = offers.length;
		offers.push(Offer(_token, _amount, _payToken, _rate, msg.sender, _payAddress, _minPurchase, true));
		emit OfferAdd(offerId, _token, _payToken, msg.sender, _payAddress, _amount, _rate, _minPurchase, true);
	}

	function updateOffer(uint _offerId, uint _amount, uint _rate, address _payAddress, uint _minPurchase) external {
		_checkOfferAccess(_offerId);
		require(_rate > 0, "Rate must be greater than 0");
		uint blockedAmount = _getBlockedAmount(_offerId);
		require(_amount >= blockedAmount, "You can not withdraw tokens ordered by customers");
		if (_amount > offers[_offerId].amount) {
			TransferHelper.safeTransferFrom(offers[_offerId].token, msg.sender, address(this), _amount - offers[_offerId].amount);
		} else {
			TransferHelper.safeTransfer(offers[_offerId].token, msg.sender, offers[_offerId].amount - _amount);
		}
		offers[_offerId].amount = _amount;
		offers[_offerId].rate = _rate;
		offers[_offerId].payAddress = _payAddress;
		offers[_offerId].minPurchase = _minPurchase;
		emit OfferUpdate(_offerId, _payAddress, _amount, _rate, _minPurchase, offers[_offerId].active);
	}

	function activateOffer(uint _offerId) external {
		_checkOfferAccess(_offerId);
		require(offers[_offerId].active == false, "Offer is already active");
		offers[_offerId].active = true;
		emit OfferUpdate(_offerId, offers[_offerId].payAddress, offers[_offerId].amount, offers[_offerId].rate, offers[_offerId].minPurchase, true);
	}

	function deactivateOffer(uint _offerId) external {
		_checkOfferAccess(_offerId);
		require(offers[_offerId].active == true, "Offer is already inactive");
		offers[_offerId].active = false;
		emit OfferUpdate(_offerId, offers[_offerId].payAddress, offers[_offerId].amount, offers[_offerId].rate, offers[_offerId].minPurchase, false);
	}

	function addOrder(uint _offerId, address _withdrawAddress, uint _amount, uint _payAmount) external {
		require(_offerId < offers.length, "Incorrect offerId");
		require(offers[_offerId].active == true, "Offer is inactive");
		require(_amount > 0 || _payAmount > 0, "Amount must be greater than 0");
		_checkExchangerHashBalance(offers[_offerId].ownerAddress);
		uint rate = offers[_offerId].rate;
		if (_amount > 0) {
			_payAmount = _amount * rate / (10 ** RATE_DECIMALS);
		} else {
			_amount = _payAmount * (10 ** RATE_DECIMALS) / rate;
		}
		require(_amount >= offers[_offerId].minPurchase, "Amount is less than the minimum purchase");
		uint blockedAmount = _getBlockedAmount(_offerId);
		require(_amount <= offers[_offerId].amount - blockedAmount, "Not enough tokens in the offer");
		address _payAddress = offers[_offerId].payAddress;
		uint reservedUntil = block.timestamp + reservationTime;
		uint orderId = orders.length;
		orders.push(Order(_offerId, rate, msg.sender, _withdrawAddress, _amount, _payAmount, _payAddress, reservedUntil, false, 0, 0, false, false));
		emit OrderAdd(orderId, _offerId, msg.sender, rate, _withdrawAddress, _amount, _payAmount, _payAddress, reservedUntil);
	}

	function payOrder(uint _orderId, uint _payAmount, address _payToken, address _payAddress) external {
		require(_payAmount > 0, "Amount must be greater than 0");
		TransferHelper.safeTransferFrom(_payToken, msg.sender, _payAddress, _payAmount);
		uint paymentId = payments.length;
		payments.push(Payment(_orderId, _payAmount, _payToken, _payAddress));
		emit OrderPay(paymentId, _orderId, _payAmount, _payToken, _payAddress);
	}

	function markOrderAsPaid(uint _orderId) external {
		require(_orderId < orders.length, "Incorrect orderId");
		require(orders[_orderId].ownerAddress == msg.sender, "Forbidden");
		require(orders[_orderId].paid == false, "Order is already marked as paid");
		require(orders[_orderId].complete == false, "Tokens already withdrawn");
		uint offerId = orders[_orderId].offerId;
		require(
		    orders[_orderId].reservedUntil >= block.timestamp ||
		    offers[offerId].amount - _getBlockedAmount(offerId) >= orders[_orderId].amount,
		    "Not enough tokens in the offer"
        );
		orders[_orderId].paid = true;
		emit OrderMarkAsPaid(_orderId, orders[_orderId].payAmount, offers[offerId].payToken, orders[_orderId].payAddress);
	}

	function vote(uint _orderId, bool _success) external {
	    require(_orderId < orders.length, "Incorrect orderId");
	    require(orders[_orderId].paid == true, "Order is not ready for voting");
        require(orders[_orderId].complete == false, "Tokens are already withdrawn");
        require(orders[_orderId].declined == false, "Order is already declined");
        for (uint i = 0; i < votes.length; i++) {
            if (votes[i].orderId == _orderId) {
                require(votes[i].voterAddress != msg.sender, "You've alreay voted for this order");
            }
        }
        uint voteWeight = _getHashBalance(msg.sender);
        uint hashAllowance = _getHashAllowance(msg.sender);
        if (hashAllowance < voteWeight) {
            voteWeight = hashAllowance;
        }
        require(voteWeight >= minVoteWeight, "Not enough HASH tokens");
        uint guarantee = voteWeight * arbitratorGuaranteePercent / 100;
        uint offerId = orders[_orderId].offerId;
		bool ultimate = false;
        if (_success) {
            orders[_orderId].votesFor += voteWeight;
            if (orders[_orderId].votesFor > votesThreshold) {
                TransferHelper.safeTransfer(offers[offerId].token, orders[_orderId].withdrawAddress, orders[_orderId].amount);
                orders[_orderId].complete = true;
		        offers[offerId].amount -= orders[_orderId].amount;
		        ultimate = true;
            }
        } else {
            orders[_orderId].votesAgainst += voteWeight;
            if (orders[_orderId].votesAgainst > votesThreshold) {
                orders[_orderId].declined = true;
                ultimate = true;
            }
        }
        if (ultimate) {
            (uint votesWeight, uint penalties) = _getOrderVotesInfo(_orderId, _success);
            votesWeight += voteWeight;
            uint commissionSent = 0;
            uint penaltiesSent = 0;
            for (uint i = 0; i < votes.length; i++) {
    			if (votes[i].orderId == _orderId && votes[i].success == _success) {
    			    uint commission = votes[i].voteWeight / votesWeight * commissionForDeal * (100 - finalVoteBonusPercent) / 100;
    			    if (commission > 0) {
    			        TransferHelper.safeTransferFrom(hashAddress, offers[offerId].ownerAddress, votes[i].voterAddress, commission);
    				    commissionSent += commission;
    			    }
				    uint penaltyCommission = votes[i].voteWeight / votesWeight * penalties * (100 - finalVoteBonusPercent) / 100;
			        TransferHelper.safeTransfer(hashAddress, votes[i].voterAddress, penaltyCommission + votes[i].guarantee);
			        penaltiesSent += penaltyCommission;
    			}
    		}
    		if (commissionForDeal > commissionSent) {
    		    TransferHelper.safeTransferFrom(hashAddress, offers[offerId].ownerAddress, msg.sender, commissionForDeal - commissionSent);
    		}
    		if (penalties > penaltiesSent) {
    		    TransferHelper.safeTransfer(hashAddress, msg.sender, penalties - penaltiesSent);
    		}
        } else {
            TransferHelper.safeTransferFrom(hashAddress, msg.sender, address(this), guarantee);
        }
        uint voteId = votes.length;
        votes.push(Vote(_orderId, msg.sender, voteWeight, guarantee, _success, ultimate));
        emit VoteAdd(voteId, _orderId, msg.sender, voteWeight, guarantee, _success, ultimate, offers[offerId].amount);
	}

	function getOrderIdForArbitration(address _arbitratorAddress, uint _startId) external view returns(uint, bool) {
	    for (uint i = _startId; i < orders.length; i++) {
			if (orders[i].paid == false || orders[i].complete == true || orders[i].declined == true) {
			    continue;
			}
			bool returnThis = true;
			for (uint j = 0; j < votes.length; j++) {
			    if (votes[j].orderId == i && votes[j].voterAddress == _arbitratorAddress) {
			        returnThis = false;
			        break;
			    }
			}
		    if (returnThis) {
		        return (i, true);
		    }
		}
		return (0, false);
	}

	function checkPayment(uint _orderId, uint _payAmount, address _payToken, address _payAddress) external view returns(bool) {
	    for (uint i = 0; i < payments.length; i++) {
	        if (payments[i].orderId == _orderId && payments[i].payAmount == _payAmount && payments[i].payToken == _payToken && payments[i].payAddress == _payAddress) {
	            return true;
	        }
	    }
	    return false;
	}

	function _checkOfferAccess(uint _offerId) private view {
		require(_offerId < offers.length, "Incorrect offerId");
		require(offers[_offerId].ownerAddress == msg.sender, "Forbidden");
	}

	function _getBlockedAmount(uint _offerId) private view returns(uint blockedAmount) {
		blockedAmount = 0;
		for (uint i = 0; i < orders.length; i++) {
			if (orders[i].offerId == _offerId && orders[i].complete == false && orders[i].declined == false && orders[i].reservedUntil >= block.timestamp) {
				blockedAmount += orders[i].amount;
			}
		}
	}

	function _getHashBalance(address _address) private returns(uint balance) {
	    (bool success, bytes memory data) = hashAddress.call(
	        abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), _address)
        );
        require(success, "Getting HASH balance failed");
        balance = abi.decode(data, (uint));
	}

	function _getHashAllowance(address _address) private returns(uint allowance) {
	    (bool success, bytes memory data) = hashAddress.call(
	        abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), _address, address(this))
        );
        require(success, "Getting HASH allowance failed");
        allowance = abi.decode(data, (uint));
	}

	function _getOrderVotesInfo(uint _orderId, bool _success) private view returns(uint votesWeight, uint penalties) {
	    votesWeight = 0;
	    penalties = 0;
	    for (uint i = 0; i < votes.length; i++) {
			if (votes[i].orderId == _orderId) {
			    votesWeight += votes[i].voteWeight;
    			if (votes[i].success != _success) {
    				penalties += votes[i].guarantee;
    			}
			}
		}
	}

	function _checkExchangerHashBalance(address _address) private {
	    uint balance = _getHashBalance(_address);
	    uint allowance = _getHashAllowance(_address);
	    for (uint i = 0; i < offers.length; i++) {
	        if (offers[i].ownerAddress != _address) {
	            continue;
	        }
	        for (uint j = 0; j < orders.length; j++) {
	            if (orders[j].offerId == i && orders[j].complete == false && orders[j].declined == false && orders[j].reservedUntil >= block.timestamp) {
	                balance -= commissionForDeal;
	                allowance -= commissionForDeal;
	            }
	        }
	    }
	    require(balance >= commissionForDeal && allowance >= commissionForDeal, "Exchanger does not have enough HASH tokens for the deal arbitration");
	}
}