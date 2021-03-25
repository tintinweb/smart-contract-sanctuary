// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashBridge is Ownable {
	address public signer;
	uint public reservationTime;
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
		address withdrawAddress;
		uint amount;
		uint payAmount;
		address payAddress;
		uint createdAt;
		bool complete;
	}
	struct Payment {
		uint orderId;
		uint payAmount;
		address payToken;
		address payAddress;
	}
	
	Offer[] offers;
	Order[] orders;
	Payment[] payments;
	
	event OfferAdd(uint indexed offerId, address indexed token, address indexed payToken, address ownerAddress, address payAddress, uint amount, uint rate, uint minPurchase, bool active);
	event OfferUpdate(uint indexed offerId, address payAddress, uint amount, uint rate, uint minPurchase, bool active);
	event OrderAdd(uint indexed orderId, uint indexed offerId, uint rate, address withdrawAddress, uint amount, uint payAmount, address payAddress, uint createdAt);
	event OrderPay(uint indexed paymentId, uint indexed orderId, uint payAmount, address payToken, address payAddress);
	event OrderComplete(uint indexed orderId);
	
	constructor(address _signer, uint _reservationTime) {
        signer = _signer;
		reservationTime = _reservationTime;
    }
	
	function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }
	
	function changeReservationTime(uint _reservationTime) public onlyOwner {
		reservationTime = _reservationTime;
	}
	
	function addOffer(address _token, uint _amount, address _payToken, uint _rate, address _payAddress, uint _minPurchase) public {
		require(_amount > 0, "Amount must be greater than 0");
		require(_amount >= _minPurchase, "Amount must not be less than the minimum purchase");
		require(_rate > 0, "Rate must be greater than 0");
		TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
		uint offerId = offers.length;
		offers.push(Offer(_token, _amount, _payToken, _rate, msg.sender, _payAddress, _minPurchase, true));
		emit OfferAdd(offerId, _token, _payToken, msg.sender, _payAddress, _amount, _rate, _minPurchase, true);
	}
	
	function updateOffer(uint _offerId, uint _amount, uint _rate, address _payAddress, uint _minPurchase) public {
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
	
	function activateOffer(uint _offerId) public {
		_checkOfferAccess(_offerId);
		require(offers[_offerId].active == false, "Offer is already active");
		offers[_offerId].active = true;
		emit OfferUpdate(_offerId, offers[_offerId].payAddress, offers[_offerId].amount, offers[_offerId].rate, offers[_offerId].minPurchase, true);
	}
	
	function deactivateOffer(uint _offerId) public {
		_checkOfferAccess(_offerId);
		require(offers[_offerId].active == true, "Offer is already inactive");
		offers[_offerId].active = false;
		emit OfferUpdate(_offerId, offers[_offerId].payAddress, offers[_offerId].amount, offers[_offerId].rate, offers[_offerId].minPurchase, false);
	}
	
	function addOrder(uint _offerId, address _withdrawAddress, uint _amount, uint _payAmount) public {
		require(_offerId < offers.length, "Incorrect offerId");
		require(offers[_offerId].active == true, "Offer is inactive");
		require(_amount > 0 || _payAmount > 0, "Amount must be greater than 0");
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
		uint createdAt = block.timestamp;
		uint orderId = orders.length;
		orders.push(Order(_offerId, rate, _withdrawAddress, _amount, _payAmount, _payAddress, createdAt, false));
		emit OrderAdd(orderId, _offerId, rate, _withdrawAddress, _amount, _payAmount, _payAddress, createdAt);
	}
	
	function payOrder(uint _orderId, uint _payAmount, address _payToken, address _payAddress) public {
		require(_payAmount > 0, "Amount must be greater than 0");
		TransferHelper.safeTransferFrom(_payToken, msg.sender, _payAddress, _payAmount);
		uint paymentId = payments.length;
		payments.push(Payment(_orderId, _payAmount, _payToken, _payAddress));
		emit OrderPay(paymentId, _orderId, _payAmount, _payToken, _payAddress);
	}
	
	function withdrawTokens(uint _orderId, bytes calldata _sign) public {
		require(_orderId < orders.length, "Incorrect orderId");
		require(orders[_orderId].complete == false, "Tokens already withdrawn");
		uint offerId = orders[_orderId].offerId;
		uint amount = orders[_orderId].amount;
		uint payAmount = orders[_orderId].payAmount;
		address payToken = offers[offerId].payToken;
		address payAddress = orders[_orderId].payAddress;
		require(_isOrderNotExpired(_orderId) || offers[offerId].amount - _getBlockedAmount(offerId) >= amount, "Not enough tokens in the offer");
		
		bytes32 data = keccak256(abi.encodePacked(_orderId, payAmount, payToken, payAddress));
		require(_verifySign(data, _sign), "Incorrect signature");
		
		TransferHelper.safeTransfer(offers[offerId].token, orders[_orderId].withdrawAddress, amount);
		orders[_orderId].complete = true;
		offers[offerId].amount -= amount;
		emit OrderComplete(_orderId);
	}
	
	function _checkOfferAccess(uint _offerId) private view {
		require(_offerId < offers.length, "Incorrect offerId");
		require(offers[_offerId].ownerAddress == msg.sender, "Forbidden");
	}
	
	function _getBlockedAmount(uint _offerId) private view returns(uint blockedAmount) {
		blockedAmount = 0;
		for (uint i = 0; i < orders.length; i++) {
			if (orders[i].offerId == _offerId && orders[i].complete == false && _isOrderNotExpired(i)) {
				blockedAmount += orders[i].amount;
			}
		}
	}
	
	function _isOrderNotExpired(uint _orderId) private view returns (bool) {
		return orders[_orderId].createdAt + reservationTime >= block.timestamp;
	}
	
	function _verifySign(bytes32 _data, bytes memory _sign) private view returns (bool) {
        bytes32 hash = _toEthBytes32SignedMessageHash(_data);
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == signer;
    }
	
	function _toEthBytes32SignedMessageHash (bytes32 _data) pure private returns (bytes32 signHash) {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _data));
    }
	
	function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure private returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }
	
	function _parseSignature(bytes memory _signatures, uint _pos) pure private returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28);
    }
    
    function _countSignatures(bytes memory _signatures) pure private returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}