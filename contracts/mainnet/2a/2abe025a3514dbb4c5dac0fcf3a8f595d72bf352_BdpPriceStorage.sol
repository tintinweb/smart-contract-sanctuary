pragma solidity ^0.4.19;

contract BdpBaseData {

	address public ownerAddress;

	address public managerAddress;

	address[16] public contracts;

	bool public paused = false;

	bool public setupComplete = false;

	bytes8 public version;

}
library BdpContracts {

	function getBdpEntryPoint(address[16] _contracts) pure internal returns (address) {
		return _contracts[0];
	}

	function getBdpController(address[16] _contracts) pure internal returns (address) {
		return _contracts[1];
	}

	function getBdpControllerHelper(address[16] _contracts) pure internal returns (address) {
		return _contracts[3];
	}

	function getBdpDataStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[4];
	}

	function getBdpImageStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[5];
	}

	function getBdpOwnershipStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[6];
	}

	function getBdpPriceStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[7];
	}

}

contract BdpBase is BdpBaseData {

	modifier onlyOwner() {
		require(msg.sender == ownerAddress);
		_;
	}

	modifier onlyAuthorized() {
		require(msg.sender == ownerAddress || msg.sender == managerAddress);
		_;
	}

	modifier whenContractActive() {
		require(!paused && setupComplete);
		_;
	}

	modifier storageAccessControl() {
		require(
			(! setupComplete && (msg.sender == ownerAddress || msg.sender == managerAddress))
			|| (setupComplete && !paused && (msg.sender == BdpContracts.getBdpEntryPoint(contracts)))
		);
		_;
	}

	function setOwner(address _newOwner) external onlyOwner {
		require(_newOwner != address(0));
		ownerAddress = _newOwner;
	}

	function setManager(address _newManager) external onlyOwner {
		require(_newManager != address(0));
		managerAddress = _newManager;
	}

	function setContracts(address[16] _contracts) external onlyOwner {
		contracts = _contracts;
	}

	function pause() external onlyAuthorized {
		paused = true;
	}

	function unpause() external onlyOwner {
		paused = false;
	}

	function setSetupComplete() external onlyOwner {
		setupComplete = true;
	}

	function kill() public onlyOwner {
		selfdestruct(ownerAddress);
	}

}

contract BdpPriceStorage is BdpBase {

	uint64[1001] public pricePoints;

	uint256 public pricePointsLength = 0;

	address public forwardPurchaseFeesTo = address(0);

	address public forwardUpdateFeesTo = address(0);


	function getPricePointsLength() view public returns (uint256) {
		return pricePointsLength;
	}

	function getPricePoint(uint256 _i) view public returns (uint256) {
		return pricePoints[_i];
	}

	function setPricePoints(uint64[] _pricePoints) public storageAccessControl {
		pricePointsLength = 0;
		appendPricePoints(_pricePoints);
	}

	function appendPricePoints(uint64[] _pricePoints) public storageAccessControl {
		for (uint i = 0; i < _pricePoints.length; i++) {
			pricePoints[pricePointsLength++] = _pricePoints[i];
		}
	}

	function getForwardPurchaseFeesTo() view public returns (address) {
		return forwardPurchaseFeesTo;
	}

	function setForwardPurchaseFeesTo(address _forwardPurchaseFeesTo) public storageAccessControl {
		forwardPurchaseFeesTo = _forwardPurchaseFeesTo;
	}

	function getForwardUpdateFeesTo() view public returns (address) {
		return forwardUpdateFeesTo;
	}

	function setForwardUpdateFeesTo(address _forwardUpdateFeesTo) public storageAccessControl {
		forwardUpdateFeesTo = _forwardUpdateFeesTo;
	}

	function BdpPriceStorage(bytes8 _version) public {
		ownerAddress = msg.sender;
		managerAddress = msg.sender;
		version = _version;
	}

}