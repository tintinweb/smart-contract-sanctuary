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

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BdpDataStorage is BdpBase {

	using SafeMath for uint256;

	struct Region {
		uint256 x1;
		uint256 y1;
		uint256 x2;
		uint256 y2;
		uint256 currentImageId;
		uint256 nextImageId;
		uint8[128] url;
		uint256 currentPixelPrice;
		uint256 blockUpdatedAt;
		uint256 updatedAt;
		uint256 purchasedAt;
		uint256 purchasedPixelPrice;
	}

	uint256 public lastRegionId = 0;

	mapping (uint256 => Region) public data;


	function getLastRegionId() view public returns (uint256) {
		return lastRegionId;
	}

	function getNextRegionId() public storageAccessControl returns (uint256) {
		lastRegionId = lastRegionId.add(1);
		return lastRegionId;
	}

	function deleteRegionData(uint256 _id) public storageAccessControl {
		delete data[_id];
	}

	function getRegionCoordinates(uint256 _id) view public returns (uint256, uint256, uint256, uint256) {
		return (data[_id].x1, data[_id].y1, data[_id].x2, data[_id].y2);
	}

	function setRegionCoordinates(uint256 _id, uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) public storageAccessControl {
		data[_id].x1 = _x1;
		data[_id].y1 = _y1;
		data[_id].x2 = _x2;
		data[_id].y2 = _y2;
	}

	function getRegionCurrentImageId(uint256 _id) view public returns (uint256) {
		return data[_id].currentImageId;
	}

	function setRegionCurrentImageId(uint256 _id, uint256 _currentImageId) public storageAccessControl {
		data[_id].currentImageId = _currentImageId;
	}

	function getRegionNextImageId(uint256 _id) view public returns (uint256) {
		return data[_id].nextImageId;
	}

	function setRegionNextImageId(uint256 _id, uint256 _nextImageId) public storageAccessControl {
		data[_id].nextImageId = _nextImageId;
	}

	function getRegionUrl(uint256 _id) view public returns (uint8[128]) {
		return data[_id].url;
	}

	function setRegionUrl(uint256 _id, uint8[128] _url) public storageAccessControl {
		data[_id].url = _url;
	}

	function getRegionCurrentPixelPrice(uint256 _id) view public returns (uint256) {
		return data[_id].currentPixelPrice;
	}

	function setRegionCurrentPixelPrice(uint256 _id, uint256 _currentPixelPrice) public storageAccessControl {
		data[_id].currentPixelPrice = _currentPixelPrice;
	}

	function getRegionBlockUpdatedAt(uint256 _id) view public returns (uint256) {
		return data[_id].blockUpdatedAt;
	}

	function setRegionBlockUpdatedAt(uint256 _id, uint256 _blockUpdatedAt) public storageAccessControl {
		data[_id].blockUpdatedAt = _blockUpdatedAt;
	}

	function getRegionUpdatedAt(uint256 _id) view public returns (uint256) {
		return data[_id].updatedAt;
	}

	function setRegionUpdatedAt(uint256 _id, uint256 _updatedAt) public storageAccessControl {
		data[_id].updatedAt = _updatedAt;
	}

	function getRegionPurchasedAt(uint256 _id) view public returns (uint256) {
		return data[_id].purchasedAt;
	}

	function setRegionPurchasedAt(uint256 _id, uint256 _purchasedAt) public storageAccessControl {
		data[_id].purchasedAt = _purchasedAt;
	}

	function getRegionUpdatedAtPurchasedAt(uint256 _id) view public returns (uint256 _updatedAt, uint256 _purchasedAt) {
		return (data[_id].updatedAt, data[_id].purchasedAt);
	}

	function getRegionPurchasePixelPrice(uint256 _id) view public returns (uint256) {
		return data[_id].purchasedPixelPrice;
	}

	function setRegionPurchasedPixelPrice(uint256 _id, uint256 _purchasedPixelPrice) public storageAccessControl {
		data[_id].purchasedPixelPrice = _purchasedPixelPrice;
	}

	function BdpDataStorage(bytes8 _version) public {
		ownerAddress = msg.sender;
		managerAddress = msg.sender;
		version = _version;
	}

}