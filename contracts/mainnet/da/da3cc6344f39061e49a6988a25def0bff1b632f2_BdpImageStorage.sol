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

contract BdpImageStorage is BdpBase {

	using SafeMath for uint256;

	struct Image {
		address owner;
		uint256 regionId;
		uint256 currentRegionId;
		mapping(uint16 => uint256[1000]) data;
		mapping(uint16 => uint16) dataLength;
		uint16 partsCount;
		uint16 width;
		uint16 height;
		uint16 imageDescriptor;
		uint256 blurredAt;
	}

	uint256 public lastImageId = 0;

	mapping(uint256 => Image) public images;


	function getLastImageId() view public returns (uint256) {
		return lastImageId;
	}

	function getNextImageId() public storageAccessControl returns (uint256) {
		lastImageId = lastImageId.add(1);
		return lastImageId;
	}

	function createImage(address _owner, uint256 _regionId, uint16 _width, uint16 _height, uint16 _partsCount, uint16 _imageDescriptor) public storageAccessControl returns (uint256) {
		require(_owner != address(0) && _width > 0 && _height > 0 && _partsCount > 0 && _imageDescriptor > 0);
		uint256 id = getNextImageId();
		images[id].owner = _owner;
		images[id].regionId = _regionId;
		images[id].width = _width;
		images[id].height = _height;
		images[id].partsCount = _partsCount;
		images[id].imageDescriptor = _imageDescriptor;
		return id;
	}

	function imageExists(uint256 _imageId) view public returns (bool) {
		return _imageId > 0 && images[_imageId].owner != address(0);
	}

	function deleteImage(uint256 _imageId) public storageAccessControl {
		require(imageExists(_imageId));
		delete images[_imageId];
	}

	function getImageOwner(uint256 _imageId) public view returns (address) {
		require(imageExists(_imageId));
		return images[_imageId].owner;
	}

	function setImageOwner(uint256 _imageId, address _owner) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].owner = _owner;
	}

	function getImageRegionId(uint256 _imageId) public view returns (uint256) {
		require(imageExists(_imageId));
		return images[_imageId].regionId;
	}

	function setImageRegionId(uint256 _imageId, uint256 _regionId) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].regionId = _regionId;
	}

	function getImageCurrentRegionId(uint256 _imageId) public view returns (uint256) {
		require(imageExists(_imageId));
		return images[_imageId].currentRegionId;
	}

	function setImageCurrentRegionId(uint256 _imageId, uint256 _currentRegionId) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].currentRegionId = _currentRegionId;
	}

	function getImageData(uint256 _imageId, uint16 _part) view public returns (uint256[1000]) {
		require(imageExists(_imageId));
		return images[_imageId].data[_part];
	}

	function setImageData(uint256 _imageId, uint16 _part, uint256[] _data) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].dataLength[_part] = uint16(_data.length);
		for (uint256 i = 0; i < _data.length; i++) {
			images[_imageId].data[_part][i] = _data[i];
		}
	}

	function getImageDataLength(uint256 _imageId, uint16 _part) view public returns (uint16) {
		require(imageExists(_imageId));
		return images[_imageId].dataLength[_part];
	}

	function setImageDataLength(uint256 _imageId, uint16 _part, uint16 _dataLength) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].dataLength[_part] = _dataLength;
	}

	function getImagePartsCount(uint256 _imageId) view public returns (uint16) {
		require(imageExists(_imageId));
		return images[_imageId].partsCount;
	}

	function setImagePartsCount(uint256 _imageId, uint16 _partsCount) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].partsCount = _partsCount;
	}

	function getImageWidth(uint256 _imageId) view public returns (uint16) {
		require(imageExists(_imageId));
		return images[_imageId].width;
	}

	function setImageWidth(uint256 _imageId, uint16 _width) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].width = _width;
	}

	function getImageHeight(uint256 _imageId) view public returns (uint16) {
		require(imageExists(_imageId));
		return images[_imageId].height;
	}

	function setImageHeight(uint256 _imageId, uint16 _height) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].height = _height;
	}

	function getImageDescriptor(uint256 _imageId) view public returns (uint16) {
		require(imageExists(_imageId));
		return images[_imageId].imageDescriptor;
	}

	function setImageDescriptor(uint256 _imageId, uint16 _imageDescriptor) public storageAccessControl {
		require(imageExists(_imageId));
		images[_imageId].imageDescriptor = _imageDescriptor;
	}

	function getImageBlurredAt(uint256 _imageId) view public returns (uint256) {
		return images[_imageId].blurredAt;
	}

	function setImageBlurredAt(uint256 _imageId, uint256 _blurredAt) public storageAccessControl {
		images[_imageId].blurredAt = _blurredAt;
	}

	function imageUploadComplete(uint256 _imageId) view public returns (bool) {
		require(imageExists(_imageId));
		for (uint16 i = 1; i <= images[_imageId].partsCount; i++) {
			if(images[_imageId].data[i].length == 0) {
				return false;
			}
		}
		return true;
	}

	function BdpImageStorage(bytes8 _version) public {
		ownerAddress = msg.sender;
		managerAddress = msg.sender;
		version = _version;
	}

}