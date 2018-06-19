pragma solidity ^0.4.19;

// File: contracts/BdpBaseData.sol

contract BdpBaseData {

	address public ownerAddress;

	address public managerAddress;

	address[16] public contracts;

	bool public paused = false;

	bool public setupCompleted = false;

	bytes8 public version;

}

// File: contracts/libraries/BdpContracts.sol

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

// File: contracts/BdpBase.sol

contract BdpBase is BdpBaseData {

	modifier onlyOwner() {
		require(msg.sender == ownerAddress);
		_;
	}

	modifier onlyAuthorized() {
		require(msg.sender == ownerAddress || msg.sender == managerAddress);
		_;
	}

	modifier whileContractIsActive() {
		require(!paused && setupCompleted);
		_;
	}

	modifier storageAccessControl() {
		require(
			(! setupCompleted && (msg.sender == ownerAddress || msg.sender == managerAddress))
			|| (setupCompleted && !paused && (msg.sender == BdpContracts.getBdpEntryPoint(contracts)))
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

	function setSetupCompleted() external onlyOwner {
		setupCompleted = true;
	}

	function kill() public onlyOwner {
		selfdestruct(ownerAddress);
	}

}

// File: contracts/libraries/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: contracts/storage/BdpDataStorage.sol

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

// File: contracts/storage/BdpImageStorage.sol

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

// File: contracts/storage/BdpPriceStorage.sol

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

// File: contracts/libraries/BdpCalculator.sol

library BdpCalculator {

	using SafeMath for uint256;

	function calculateArea(address[16] _contracts, uint256 _regionId) view public returns (uint256 _area, uint256 _width, uint256 _height) {
		var (x1, y1, x2, y2) = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts)).getRegionCoordinates(_regionId);
		_width = x2 - x1 + 1;
		_height = y2 - y1 + 1;
		_area = _width * _height;
	}

	function countPurchasedPixels(address[16] _contracts) view public returns (uint256 _count) {
		var lastRegionId = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts)).getLastRegionId();
		for (uint256 i = 0; i <= lastRegionId; i++) {
			if(BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts)).getRegionPurchasedAt(i) > 0) { // region is purchased
				var (area,,) = calculateArea(_contracts, i);
				_count += area;
			}
		}
	}

	function calculateCurrentMarketPixelPrice(address[16] _contracts) view public returns(uint) {
		return calculateMarketPixelPrice(_contracts, countPurchasedPixels(_contracts));
	}

	function calculateMarketPixelPrice(address[16] _contracts, uint _pixelsSold) view public returns(uint) {
		var pricePointsLength = BdpPriceStorage(BdpContracts.getBdpPriceStorage(_contracts)).getPricePointsLength();
		uint mod = _pixelsSold % (1000000 / (pricePointsLength - 1));
		uint div = _pixelsSold * (pricePointsLength - 1) / 1000000;
		var divPoint = BdpPriceStorage(BdpContracts.getBdpPriceStorage(_contracts)).getPricePoint(div);
		if(mod == 0) return divPoint;
		return divPoint + mod * (BdpPriceStorage(BdpContracts.getBdpPriceStorage(_contracts)).getPricePoint(div+1) - divPoint) * (pricePointsLength - 1) / 1000000;
	}

	function calculateAveragePixelPrice(address[16] _contracts, uint _a, uint _b) view public returns (uint _price) {
		_price = (calculateMarketPixelPrice(_contracts, _a) + calculateMarketPixelPrice(_contracts, _b)) / 2;
	}

	/** Current market price per pixel for this region if it is the first sale of this region
	  */
	function calculateRegionInitialSalePixelPrice(address[16] _contracts, uint256 _regionId) view public returns (uint256) {
		require(BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts)).getRegionUpdatedAt(_regionId) > 0); // region exists
		var purchasedPixels = countPurchasedPixels(_contracts);
		var (area,,) = calculateArea(_contracts, _regionId);
		return calculateAveragePixelPrice(_contracts, purchasedPixels, purchasedPixels + area);
	}

	/** Current market price or (Current market price)*3 if the region was sold
	  */
	function calculateRegionSalePixelPrice(address[16] _contracts, uint256 _regionId) view public returns (uint256) {
		var pixelPrice = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts)).getRegionCurrentPixelPrice(_regionId);
		if(pixelPrice > 0) {
			return pixelPrice * 3;
		} else {
			return calculateRegionInitialSalePixelPrice(_contracts, _regionId);
		}
	}

	/** Setup is allowed one whithin one day after purchase
	  */
	function calculateSetupAllowedUntil(address[16] _contracts, uint256 _regionId) view public returns (uint256) {
		var (updatedAt, purchasedAt) = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts)).getRegionUpdatedAtPurchasedAt(_regionId);
		if(updatedAt != purchasedAt) {
			return 0;
		} else {
			return purchasedAt + 1 days;
		}
	}

}

// File: contracts/storage/BdpOwnershipStorage.sol

contract BdpOwnershipStorage is BdpBase {

	using SafeMath for uint256;

	// Mapping from token ID to owner
	mapping (uint256 => address) public tokenOwner;

	// Mapping from token ID to approved address
	mapping (uint256 => address) public tokenApprovals;

	// Mapping from owner to the sum of owned area
	mapping (address => uint256) public ownedArea;

	// Mapping from owner to list of owned token IDs
	mapping (address => uint256[]) public ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) public ownedTokensIndex;

	// All tokens list tokens ids
	uint256[] public tokenIds;

	// Mapping from tokenId to index of the tokens list
	mapping (uint256 => uint256) public tokenIdsIndex;


	function getTokenOwner(uint256 _tokenId) view public returns (address) {
		return tokenOwner[_tokenId];
	}

	function setTokenOwner(uint256 _tokenId, address _owner) public storageAccessControl {
		tokenOwner[_tokenId] = _owner;
	}

	function getTokenApproval(uint256 _tokenId) view public returns (address) {
		return tokenApprovals[_tokenId];
	}

	function setTokenApproval(uint256 _tokenId, address _to) public storageAccessControl {
		tokenApprovals[_tokenId] = _to;
	}

	function getOwnedArea(address _owner) view public returns (uint256) {
		return ownedArea[_owner];
	}

	function setOwnedArea(address _owner, uint256 _area) public storageAccessControl {
		ownedArea[_owner] = _area;
	}

	function incrementOwnedArea(address _owner, uint256 _area) public storageAccessControl returns (uint256) {
		ownedArea[_owner] = ownedArea[_owner].add(_area);
		return ownedArea[_owner];
	}

	function decrementOwnedArea(address _owner, uint256 _area) public storageAccessControl returns (uint256) {
		ownedArea[_owner] = ownedArea[_owner].sub(_area);
		return ownedArea[_owner];
	}

	function getOwnedTokensLength(address _owner) view public returns (uint256) {
		return ownedTokens[_owner].length;
	}

	function getOwnedToken(address _owner, uint256 _index) view public returns (uint256) {
		return ownedTokens[_owner][_index];
	}

	function setOwnedToken(address _owner, uint256 _index, uint256 _tokenId) public storageAccessControl {
		ownedTokens[_owner][_index] = _tokenId;
	}

	function pushOwnedToken(address _owner, uint256 _tokenId) public storageAccessControl returns (uint256) {
		ownedTokens[_owner].push(_tokenId);
		return ownedTokens[_owner].length;
	}

	function decrementOwnedTokensLength(address _owner) public storageAccessControl {
		ownedTokens[_owner].length--;
	}

	function getOwnedTokensIndex(uint256 _tokenId) view public returns (uint256) {
		return ownedTokensIndex[_tokenId];
	}

	function setOwnedTokensIndex(uint256 _tokenId, uint256 _tokenIndex) public storageAccessControl {
		ownedTokensIndex[_tokenId] = _tokenIndex;
	}

	function getTokenIdsLength() view public returns (uint256) {
		return tokenIds.length;
	}

	function getTokenIdByIndex(uint256 _index) view public returns (uint256) {
		return tokenIds[_index];
	}

	function setTokenIdByIndex(uint256 _index, uint256 _tokenId) public storageAccessControl {
		tokenIds[_index] = _tokenId;
	}

	function pushTokenId(uint256 _tokenId) public storageAccessControl returns (uint256) {
		tokenIds.push(_tokenId);
		return tokenIds.length;
	}

	function decrementTokenIdsLength() public storageAccessControl {
		tokenIds.length--;
	}

	function getTokenIdsIndex(uint256 _tokenId) view public returns (uint256) {
		return tokenIdsIndex[_tokenId];
	}

	function setTokenIdsIndex(uint256 _tokenId, uint256 _tokenIdIndex) public storageAccessControl {
		tokenIdsIndex[_tokenId] = _tokenIdIndex;
	}

	function BdpOwnershipStorage(bytes8 _version) public {
		ownerAddress = msg.sender;
		managerAddress = msg.sender;
		version = _version;
	}

}

// File: contracts/libraries/BdpOwnership.sol

/**
 * Ownership manager
 * Does not check if the caller is allowed to call functions
 * State changing methods are not intended to be called from controller
 */
library BdpOwnership {

	using SafeMath for uint256;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	function ownerOf(address[16] _contracts, uint256 _tokenId) public view returns (address) {
		var owner = BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts)).getTokenOwner(_tokenId);
		require(owner != address(0));
		return owner;
	}

	function balanceOf(address[16] _contracts, address _owner) public view returns (uint256) {
		return BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts)).getOwnedTokensLength(_owner);
	}

	function approve(address[16] _contracts, address _to, uint256 _tokenId) public {
		var ownStorage = BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts));

		address owner = ownerOf(_contracts, _tokenId);
		require(_to != owner);
		if (ownStorage.getTokenApproval(_tokenId) != 0 || _to != 0) {
			ownStorage.setTokenApproval(_tokenId, _to);
			Approval(owner, _to, _tokenId);
		}
	}

	/**
	 * @dev Clear current approval of a given token ID
	 * @param _tokenId uint256 ID of the token to be transferred
	 */
	function clearApproval(address[16] _contracts, address _owner, uint256 _tokenId) public {
		var ownStorage = BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts));

		require(ownerOf(_contracts, _tokenId) == _owner);
		if (ownStorage.getTokenApproval(_tokenId) != 0) {
			BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts)).setTokenApproval(_tokenId, 0);
			Approval(_owner, 0, _tokenId);
		}
	}

	/**
	 * @dev Clear current approval and transfer the ownership of a given token ID
	 * @param _from address which you want to send tokens from
	 * @param _to address which you want to transfer the token to
	 * @param _tokenId uint256 ID of the token to be transferred
	 */
	function clearApprovalAndTransfer(address[16] _contracts, address _from, address _to, uint256 _tokenId) public {
		require(_to != address(0));
		require(_to != ownerOf(_contracts, _tokenId));
		require(ownerOf(_contracts, _tokenId) == _from);

		clearApproval(_contracts, _from, _tokenId);
		removeToken(_contracts, _from, _tokenId);
		addToken(_contracts, _to, _tokenId);
		Transfer(_from, _to, _tokenId);
	}

	/**
	 * @dev Internal function to add a token ID to the list of a given address
	 * @param _to address representing the new owner of the given token ID
	 * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
	 */
	function addToken(address[16] _contracts, address _to, uint256 _tokenId) private {
		var ownStorage = BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts));

		require(ownStorage.getTokenOwner(_tokenId) == address(0));

		// Set token owner
		ownStorage.setTokenOwner(_tokenId, _to);

		// Add token to tokenIds list
		var tokenIdsLength = ownStorage.pushTokenId(_tokenId);
		ownStorage.setTokenIdsIndex(_tokenId, tokenIdsLength.sub(1));

		uint256 ownedTokensLength = ownStorage.getOwnedTokensLength(_to);

		// Add token to ownedTokens list
		ownStorage.pushOwnedToken(_to, _tokenId);
		ownStorage.setOwnedTokensIndex(_tokenId, ownedTokensLength);

		// Increment total owned area
		var (area,,) = BdpCalculator.calculateArea(_contracts, _tokenId);
		ownStorage.incrementOwnedArea(_to, area);
	}

	/**
	 * @dev Internal function to remove a token ID from the list of a given address
	 * @param _from address representing the previous owner of the given token ID
	 * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
	 */
	function removeToken(address[16] _contracts, address _from, uint256 _tokenId) private {
		var ownStorage = BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts));

		require(ownerOf(_contracts, _tokenId) == _from);

		// Clear token owner
		ownStorage.setTokenOwner(_tokenId, 0);

		removeFromTokenIds(ownStorage, _tokenId);
		removeFromOwnedToken(ownStorage, _from, _tokenId);

		// Decrement total owned area
		var (area,,) = BdpCalculator.calculateArea(_contracts, _tokenId);
		ownStorage.decrementOwnedArea(_from, area);
	}

	/**
	 * @dev Remove token from ownedTokens list
	 * Note that this will handle single-element arrays. In that case, both ownedTokenIndex and lastOwnedTokenIndex are going to
	 * be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
	 * the lastOwnedToken to the first position, and then dropping the element placed in the last position of the list
	 */
	function removeFromOwnedToken(BdpOwnershipStorage _ownStorage, address _from, uint256 _tokenId) private {
		var ownedTokenIndex = _ownStorage.getOwnedTokensIndex(_tokenId);
		var lastOwnedTokenIndex = _ownStorage.getOwnedTokensLength(_from).sub(1);
		var lastOwnedToken = _ownStorage.getOwnedToken(_from, lastOwnedTokenIndex);
		_ownStorage.setOwnedToken(_from, ownedTokenIndex, lastOwnedToken);
		_ownStorage.setOwnedToken(_from, lastOwnedTokenIndex, 0);
		_ownStorage.decrementOwnedTokensLength(_from);
		_ownStorage.setOwnedTokensIndex(_tokenId, 0);
		_ownStorage.setOwnedTokensIndex(lastOwnedToken, ownedTokenIndex);
	}

	/**
	 * @dev Remove token from tokenIds list
	 */
	function removeFromTokenIds(BdpOwnershipStorage _ownStorage, uint256 _tokenId) private {
		var tokenIndex = _ownStorage.getTokenIdsIndex(_tokenId);
		var lastTokenIdIndex = _ownStorage.getTokenIdsLength().sub(1);
		var lastTokenId = _ownStorage.getTokenIdByIndex(lastTokenIdIndex);
		_ownStorage.setTokenIdByIndex(tokenIndex, lastTokenId);
		_ownStorage.setTokenIdByIndex(lastTokenIdIndex, 0);
		_ownStorage.decrementTokenIdsLength();
		_ownStorage.setTokenIdsIndex(_tokenId, 0);
		_ownStorage.setTokenIdsIndex(lastTokenId, tokenIndex);
	}

	/**
	 * @dev Mint token function
	 * @param _to The address that will own the minted token
	 * @param _tokenId uint256 ID of the token to be minted by the msg.sender
	 */
	function mint(address[16] _contracts, address _to, uint256 _tokenId) public {
		require(_to != address(0));
		addToken(_contracts, _to, _tokenId);
		Transfer(address(0), _to, _tokenId);
	}

	/**
	 * @dev Burns a specific token
	 * @param _tokenId uint256 ID of the token being burned
	 */
	function burn(address[16] _contracts, uint256 _tokenId) public {
		address owner = BdpOwnershipStorage(BdpContracts.getBdpOwnershipStorage(_contracts)).getTokenOwner(_tokenId);
		clearApproval(_contracts, owner, _tokenId);
		removeToken(_contracts, owner, _tokenId);
		Transfer(owner, address(0), _tokenId);
	}

}

// File: contracts/libraries/BdpImage.sol

library BdpImage {

	function checkImageInput(address[16] _contracts, uint256 _regionId, uint256 _imageId, uint256[] _imageData, bool _swapImages, bool _clearImage) view public {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		var imageStorage = BdpImageStorage(BdpContracts.getBdpImageStorage(_contracts));

		require( (_imageId == 0 && _imageData.length == 0 && !_swapImages && !_clearImage) // Only one way to change image can be specified
			|| (_imageId != 0 && _imageData.length == 0 && !_swapImages && !_clearImage) // If image has to be changed
			|| (_imageId == 0 && _imageData.length != 0 && !_swapImages && !_clearImage)
			|| (_imageId == 0 && _imageData.length == 0 && _swapImages && !_clearImage)
			|| (_imageId == 0 && _imageData.length == 0 && !_swapImages && _clearImage) );

		require(_imageId == 0 || // Can use only own images not used by other regions
			( (msg.sender == imageStorage.getImageOwner(_imageId)) && (imageStorage.getImageCurrentRegionId(_imageId) == 0) ) );

		var nextImageId = dataStorage.getRegionNextImageId(_regionId);
		require(!_swapImages || imageUploadComplete(_contracts, nextImageId)); // Can swap images if next image upload is complete
	}

	function setNextImagePart(address[16] _contracts, uint256 _regionId, uint16 _part, uint16 _partsCount, uint16 _imageDescriptor, uint256[] _imageData) public {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		var imageStorage = BdpImageStorage(BdpContracts.getBdpImageStorage(_contracts));

		require(BdpOwnership.ownerOf(_contracts, _regionId) == msg.sender);
		require(_imageData.length != 0);
		require(_part > 0);
		require(_part <= _partsCount);

		var nextImageId = dataStorage.getRegionNextImageId(_regionId);
		if(nextImageId == 0 || _imageDescriptor != imageStorage.getImageDescriptor(nextImageId)) {
			var (, width, height) = BdpCalculator.calculateArea(_contracts, _regionId);
			nextImageId = imageStorage.createImage(msg.sender, _regionId, uint16(width), uint16(height), _partsCount, _imageDescriptor);
			dataStorage.setRegionNextImageId(_regionId, nextImageId);
		}

		imageStorage.setImageData(nextImageId, _part, _imageData);
	}

	function setImageOwner(address[16] _contracts, uint256 _imageId, address _owner) public {
		var imageStorage = BdpImageStorage(BdpContracts.getBdpImageStorage(_contracts));
		require(imageStorage.getImageOwner(_imageId) == msg.sender);
		require(_owner != address(0));

		imageStorage.setImageOwner(_imageId, _owner);
	}

	function setImageData(address[16] _contracts, uint256 _imageId, uint16 _part, uint256[] _imageData) public returns (address) {
		var imageStorage = BdpImageStorage(BdpContracts.getBdpImageStorage(_contracts));
		require(imageStorage.getImageOwner(_imageId) == msg.sender);
		require(imageStorage.getImageCurrentRegionId(_imageId) == 0);
		require(_imageData.length != 0);
		require(_part > 0);
		require(_part <= imageStorage.getImagePartsCount(_imageId));

		imageStorage.setImageData(_imageId, _part, _imageData);
	}

	function imageUploadComplete(address[16] _contracts, uint256 _imageId) view public returns (bool) {
		var imageStorage = BdpImageStorage(BdpContracts.getBdpImageStorage(_contracts));
		var partsCount = imageStorage.getImagePartsCount(_imageId);
		for (uint16 i = 1; i <= partsCount; i++) {
			if(imageStorage.getImageDataLength(_imageId, i) == 0) {
				return false;
			}
		}
		return true;
	}

}

// File: contracts/libraries/BdpCrud.sol

library BdpCrud {

	function createRegion(address[16] _contracts, address _to, uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) public returns (uint256) {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		require(_x2 < 1000 && _x1 <= _x2);
		require(_y2 < 1000 && _y1 <= _y2);

		var regionId = dataStorage.getNextRegionId();
		dataStorage.setRegionCoordinates(regionId, _x1, _y1, _x2, _y2);
		dataStorage.setRegionBlockUpdatedAt(regionId, block.number);
		dataStorage.setRegionUpdatedAt(regionId, block.timestamp);

		BdpOwnership.mint(_contracts, _to, regionId);

		return regionId;
	}

	function deleteRegion(address[16] _contracts, uint256 _regionId) public {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		var regionPurchasePixelPrice = dataStorage.getRegionPurchasePixelPrice(_regionId);
		require(regionPurchasePixelPrice == 0);
		BdpOwnership.burn(_contracts, _regionId);
		dataStorage.deleteRegionData(_regionId);
	}

	function setupRegion(address[16] _contracts, uint256 _regionId, uint256 _imageId, uint256[] _imageData, bool _swapImages, uint8[128] _url) public {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		require(BdpOwnership.ownerOf(_contracts, _regionId) == msg.sender);
		require(_imageId != 0 || _imageData.length != 0 || _swapImages || _url.length != 0); // Only if image or url is specified
		require(block.timestamp < BdpCalculator.calculateSetupAllowedUntil(_contracts, _regionId)); // Can only execute if setup is allowed
		BdpImage.checkImageInput(_contracts, _regionId, _imageId, _imageData, _swapImages, false);

		_updateRegionImage(_contracts, dataStorage, _regionId, _imageId, _imageData, _swapImages, false);
		_updateRegionUrl(dataStorage, _regionId, _url, false);

		dataStorage.setRegionBlockUpdatedAt(_regionId, block.number);
		dataStorage.setRegionUpdatedAt(_regionId, block.timestamp);
	}

	function updateRegion(address[16] _contracts, uint256 _regionId, uint256 _imageId, uint256[] _imageData, bool _swapImages, bool _clearImage, uint8[128] _url, bool _deleteUrl, address _newOwner) public {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		require(BdpOwnership.ownerOf(_contracts, _regionId) == msg.sender);
		BdpImage.checkImageInput(_contracts, _regionId, _imageId, _imageData, _swapImages, _clearImage);
		var regionCurrentPixelPrice = dataStorage.getRegionCurrentPixelPrice(_regionId);
		require(regionCurrentPixelPrice != 0); // region was purchased

		var marketPixelPrice = BdpCalculator.calculateCurrentMarketPixelPrice(_contracts);

		var (area,,) = BdpCalculator.calculateArea(_contracts, _regionId);
		_processUpdateFee(_contracts, marketPixelPrice * area / 20);

		_updateRegionImage(_contracts, dataStorage, _regionId, _imageId, _imageData, _swapImages, _clearImage);
		_updateRegionUrl(dataStorage, _regionId, _url, _deleteUrl);
		_updateRegionOwner(_contracts, _regionId, _newOwner);
		if(marketPixelPrice > regionCurrentPixelPrice) {
			dataStorage.setRegionCurrentPixelPrice(_regionId, marketPixelPrice);
		}
		dataStorage.setRegionBlockUpdatedAt(_regionId, block.number);
		dataStorage.setRegionUpdatedAt(_regionId, block.timestamp);
	}

	function updateRegionPixelPrice(address[16] _contracts, uint256 _regionId, uint256 _pixelPrice) public {
		var dataStorage = BdpDataStorage(BdpContracts.getBdpDataStorage(_contracts));
		require(BdpOwnership.ownerOf(_contracts, _regionId) == msg.sender);
		var regionCurrentPixelPrice = dataStorage.getRegionCurrentPixelPrice(_regionId);
		require(regionCurrentPixelPrice != 0); // region was purchased

		var marketPixelPrice = BdpCalculator.calculateCurrentMarketPixelPrice(_contracts);
		require(_pixelPrice >= marketPixelPrice);

		var (area,,) = BdpCalculator.calculateArea(_contracts, _regionId);
		_processUpdateFee(_contracts, _pixelPrice * area / 20);

		dataStorage.setRegionCurrentPixelPrice(_regionId, _pixelPrice);
	}

	function _processUpdateFee(address[16] _contracts, uint256 _updateFee) internal {
		require(msg.value >= _updateFee);

		if(msg.value > _updateFee) {
			var change = msg.value - _updateFee;
			msg.sender.transfer(change);
		}

		var forwardUpdateFeesTo = BdpPriceStorage(BdpContracts.getBdpPriceStorage(_contracts)).getForwardUpdateFeesTo();
		if(forwardUpdateFeesTo != address(0)) {
			forwardUpdateFeesTo.transfer(_updateFee);
		}
	}

	function _updateRegionImage(address[16] _contracts, BdpDataStorage _dataStorage, uint256 _regionId, uint256 _imageId, uint256[] _imageData, bool _swapImages, bool _clearImage) internal {
		var imageStorage = BdpImageStorage(BdpContracts.getBdpImageStorage(_contracts));
		var currentImageId = _dataStorage.getRegionCurrentImageId(_regionId);
		if(_imageId != 0) {
			if(currentImageId != 0) {
				imageStorage.setImageCurrentRegionId(currentImageId, 0);
			}
			_dataStorage.setRegionCurrentImageId(_regionId, _imageId);
			imageStorage.setImageCurrentRegionId(_imageId, _regionId);
		}

		if(_imageData.length > 0) {
			if(currentImageId != 0) {
				imageStorage.setImageCurrentRegionId(currentImageId, 0);
			}
			var (, width, height) = BdpCalculator.calculateArea(_contracts, _regionId);
			var imageId = imageStorage.createImage(msg.sender, _regionId, uint16(width), uint16(height), 1, 1);
			imageStorage.setImageData(imageId, 1, _imageData);
			_dataStorage.setRegionCurrentImageId(_regionId, imageId);
			imageStorage.setImageCurrentRegionId(imageId, _regionId);
		}

		if(_swapImages) {
			if(currentImageId != 0) {
				imageStorage.setImageCurrentRegionId(currentImageId, 0);
			}
			var nextImageId = _dataStorage.getRegionNextImageId(_regionId);
			_dataStorage.setRegionCurrentImageId(_regionId, nextImageId);
			imageStorage.setImageCurrentRegionId(nextImageId, _regionId);
			_dataStorage.setRegionNextImageId(_regionId, 0);
		}

		if(_clearImage) {
			if(currentImageId != 0) {
				imageStorage.setImageCurrentRegionId(currentImageId, 0);
			}
			_dataStorage.setRegionCurrentImageId(_regionId, 0);
		}
	}

	function _updateRegionUrl(BdpDataStorage _dataStorage, uint256 _regionId, uint8[128] _url, bool _deleteUrl) internal {
		if(_url[0] != 0) {
			_dataStorage.setRegionUrl(_regionId, _url);
		}
		if(_deleteUrl) {
			uint8[128] memory emptyUrl;
			_dataStorage.setRegionUrl(_regionId, emptyUrl);
		}
	}

	function _updateRegionOwner(address[16] _contracts, uint256 _regionId, address _newOwner) internal {
		if(_newOwner != address(0)) {
			BdpOwnership.clearApprovalAndTransfer(_contracts, msg.sender, _newOwner, _regionId);
		}
	}

}