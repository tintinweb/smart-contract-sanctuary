/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract Gate {
	address payable public owner;

	modifier onlyOwner() {
		require(msg.sender == owner, 'Owner only');
		_;
	}

	function setOwner(address payable _owner) public onlyOwner {
		_setOwner(_owner);
	}

	function _setOwner(address payable _owner) internal {
		require(_owner != address(0));
		owner = _owner;
	}
}

contract Pausable is Gate {

	bool public isPaused = false;

	modifier onlyNotPaused() {
		require(!isPaused, 'Contract is paused');
		_;
	}

	modifier onlyPaused() {
		require(isPaused, 'Contract is not paused');
		_;
	}

	function pause() public onlyOwner onlyNotPaused {
		isPaused = true;
	}

	function unpause() public onlyOwner onlyPaused {
		isPaused = false;
	}
}

contract CryptoAdBoxParameters is Gate {

	uint16 public fee = 30; // 3.333%
	uint public minApprovalTime = 86400;
	uint public minUnitPrice = 100000;

	function setFee(uint16 _fee) public onlyOwner {
		require(_fee > 2, 'Invalid fee');
		fee = _fee;
	}

	function setMinApprovalTime(uint _mat) public onlyOwner {
		minApprovalTime = _mat;
	}

	function setMinUnitPrice(uint _minUnitPrice) public onlyOwner {
		minUnitPrice = _minUnitPrice;
	}
}

contract CryptoAdBox is Gate, Pausable, CryptoAdBoxParameters {

	mapping (uint128 => AdBox) public adBoxes;
	mapping (uint128 => mapping(uint128 => Ad)) public ads;

	struct AdBox {
		bool isEnabled;
		bool isBanned;
		uint64 minQuantity;
		uint64 maxQuantity;
		uint unitPrice;
		uint income;
		address payable publisher;
	}

	struct Ad {
		uint64 quantity;
		uint value;
		uint createdAt;
		AdStatus status;
		address payable advertiser;
	}

	enum AdStatus {
		__,
		waitingForApproval,
		approved,
		rejected,
		rolledBack
	}

	event AdBoxCreated(uint _adBoxId, bool _isEnabled);
	event AdBoxUpdated(uint _adBoxId, bool _isEnabled);
	event AdBoxBanChanged(uint _adBoxId, bool _isBanned);
	event AdCreated(uint _adBoxId, uint _adId);
	event AdApproved(uint _adBoxId, uint _adId);
	event AdRejected(uint _adBoxId, uint _adId);
	event AdRolledBack(uint _adBoxId, uint _adId);
	event Transfered(address _target, uint _value);

	constructor() {
		_setOwner(payable(msg.sender));
	}

	function createAdBox(uint128 _adBoxId, bool _isEnabled, uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice) public onlyNotPaused {
		AdBox storage _adBox = adBoxes[_adBoxId];
		require(_adBox.publisher == address(0), 'adBoxId is already used');
		_requireCorrectValues(_minQuantity, _maxQuantity, _unitPrice);

		_adBox.isEnabled = _isEnabled;
		_adBox.isBanned = false;
		_adBox.minQuantity = _minQuantity;
		_adBox.maxQuantity = _maxQuantity;
		_adBox.unitPrice = _unitPrice;
		_adBox.income = 0;
		_adBox.publisher = payable(msg.sender);
		emit AdBoxCreated(_adBoxId, _isEnabled);
	}

	function updateAdBox(uint128 _adBoxId, bool _isEnabled, uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice) public onlyNotPaused {
		AdBox storage _adBox = adBoxes[_adBoxId];
		_requirePublisher(_adBox);
		_requireCorrectValues(_minQuantity, _maxQuantity, _unitPrice);

		_adBox.isEnabled = _isEnabled;
		_adBox.minQuantity = _minQuantity;
		_adBox.maxQuantity = _maxQuantity;
		_adBox.unitPrice = _unitPrice;

		emit AdBoxUpdated(_adBoxId, _isEnabled);
	}

	function banAdBox(uint128 _adBoxId, bool _isBanned) public onlyNotPaused onlyOwner {
		AdBox storage _adBox = adBoxes[_adBoxId];
		require(_adBox.publisher != address(0), 'AdBox does not exist');

		_adBox.isBanned = _isBanned;
		emit AdBoxBanChanged(_adBoxId, _isBanned);
	}

	function buyAd(uint128 _adBoxId, uint128 _adId, uint64 _quantity) public payable onlyNotPaused {
		AdBox storage _adBox = adBoxes[_adBoxId];
		require(_adBox.publisher != address(0), 'AdBox does not exist');
		require(_adBox.isEnabled, 'AdBox is disabled');
		require(!_adBox.isBanned, 'AdBox is banned');
		require(_quantity >= _adBox.minQuantity, 'Quantity is too low');
		require(_quantity <= _adBox.maxQuantity, 'Quantity is too high');

		uint _value = _quantity * _adBox.unitPrice;
		require(_value == msg.value, 'Invalid value');

		Ad storage _ad = ads[_adBoxId][_adId];
		require(_ad.advertiser == address(0), 'adId is already used');
		_ad.advertiser = payable(msg.sender);
		_ad.quantity = _quantity;
		_ad.value = _value;
		_ad.createdAt = block.timestamp;
		_ad.status = AdStatus.waitingForApproval;

		emit AdCreated(_adBoxId, _adId);
	}

	function rollBackAd(uint128 _adBoxId, uint128 _adId) public onlyNotPaused {
		Ad storage _ad = ads[_adBoxId][_adId];
		_requireAdvertiser(_ad);
		require(_ad.status == AdStatus.waitingForApproval, 'Ad has wrong status');
		require(_ad.createdAt + minApprovalTime < block.timestamp, 'Too early');

		_rollBackAd(_adBoxId, _adId, _ad);
	}

	function approveOrRejectAds(uint128 _adBoxId, uint128[] memory _adIds, bool[] memory _statuses) public onlyNotPaused {
		AdBox storage _adBox = adBoxes[_adBoxId];
		_requirePublisher(_adBox);
		require(_adIds.length > 0, 'Nothing to do');
		require(_adIds.length == _statuses.length, 'Invalid pair');

		uint _n = _adIds.length;
		for (uint _i = 0; _i < _n; _i++) {
			uint128 _adId = _adIds[_i];
			Ad storage _ad = ads[_adBoxId][_adId];
			require(_ad.advertiser != address(0), 'Ad does not exist');
			require(_ad.status == AdStatus.waitingForApproval, 'Ad has wrong status');

			if (_statuses[_i]) {
				_approveAd(_adBoxId, _adBox, _adId, _ad);
			} else {
				_rejectAd(_adBoxId, _adId, _ad);
			}
		}
	}

	function _approveAd(uint128 _adBoxId, AdBox storage _adBox, uint128 _adId, Ad storage _ad) private {
		_ad.status = AdStatus.approved;
		emit AdApproved(_adBoxId, _adId);

		uint _feeValue = _ad.value / uint(fee);
		uint _publisherValue = _ad.value - _feeValue;
		require(_feeValue + _publisherValue == _ad.value, 'Invalid calculation');

		_transfer(owner, _feeValue);
		_transfer(_adBox.publisher, _publisherValue);

		_adBox.income += _ad.value;
	}

	function _rejectAd(uint128 _adBoxId, uint128 _adId, Ad storage _ad) private {
		_ad.status = AdStatus.rejected;
		emit AdRejected(_adBoxId, _adId);

		_transfer(_ad.advertiser, _ad.value);
	}

	function _rollBackAd(uint128 _adBoxId, uint128 _adId, Ad storage _ad) private {
		_ad.status = AdStatus.rolledBack;
		emit AdRolledBack(_adBoxId, _adId);

		_transfer(_ad.advertiser, _ad.value);
	}

	function _transfer(address payable _target, uint _value) private {
		(bool _success, ) = _target.call{ value: _value }('');
		require(_success, 'Transfer failed');
		emit Transfered(_target, _value);
	}

	//

	function _requirePublisher(AdBox storage _adBox) private view {
		require(_adBox.publisher == msg.sender, 'Publisher only');
	}

	function _requireAdvertiser(Ad storage _ad) private view {
		require(_ad.advertiser == msg.sender, 'Advertiser only');
	}

	function _requireCorrectValues(uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice) private view {
		require(_minQuantity > 0, 'Min quantity is to low');
		require(_maxQuantity >= _maxQuantity, 'Max quantity is lower than min quantity');
		require(_unitPrice > minUnitPrice, 'Unit price is to low');
	}
}