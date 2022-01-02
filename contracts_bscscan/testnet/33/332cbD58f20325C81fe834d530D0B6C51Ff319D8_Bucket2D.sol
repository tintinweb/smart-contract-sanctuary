pragma solidity ^0.8.9;

contract Bucket2D {

  constructor () {

  }

  mapping (uint256 => bytes2[16]) private buckets;

  uint8 private constant wrapBucketAtIndex_ = 128;
  uint8 private constant bucketInternalWrapping_ = 4;
  uint8 private constant bucketSize = 16;
  uint16 private constant sizeX = 512;
  uint16 private constant sizeY = 512;
  uint16 private constant rows = sizeX/bucketSize;
  uint16 private constant columns = sizeY/bucketSize;
  uint128 private constant size = sizeX*sizeY;
  uint128 private constant totalBuckets = rows*columns;
  uint256 private constant _pixelPrice = 1*10**16;

  struct pixelInput {
    uint256 bucket;
    uint256 posInBucket;
    bytes2 color;
  }

  function pixelPrice() public pure returns (uint256) {
    return _pixelPrice;
  }

  function getPriceOfPixels(uint256 numPixels) public pure returns (uint256) {
    return _pixelPrice * numPixels;
  }

  function storePixels(pixelInput[] memory pixelInputs) external payable {
    require(pixelInputs.length > 0, "No inputs");
    //require(msg.value >= getPriceOfPixels(pixelInputs.length), "Transaction underpriced");
    uint bucketId;
    uint prevBucket;
    bytes2[16] memory loadBucket;
    for (uint i = 0; i<pixelInputs.length; i++) {
      bucketId = pixelInputs[i].bucket;
      pixelInput memory currPixelInput = pixelInputs[i];
      if (i==0) { //Init loop
        loadBucket = buckets[bucketId];
        prevBucket = bucketId;
      }
      if (prevBucket == bucketId && i<pixelInputs.length) {
        loadBucket[currPixelInput.posInBucket] = currPixelInput.color;
      }
      else if (prevBucket != bucketId && i<pixelInputs.length) {
        _storeBucket(prevBucket, loadBucket);
        loadBucket = buckets[bucketId];
        loadBucket[currPixelInput.posInBucket] = currPixelInput.color;
        prevBucket = bucketId;
      }
      else {
        _storeBucket(prevBucket, loadBucket);
      }
    }
  }

/* V1
  function storePixels(uint[] calldata pixels, bytes2[] calldata colors) public {
    require(pixels.length == colors.length, "Pixel color arr mismatch");
    uint[] memory intPosArr;
    bytes2[] memory intColArr;
    //uint bucket;
    uint prevBucket;

    for (uint i=0; i<pixels.length; i++) {
      uint posInBucket = findPosInBucket(i);
      uint bucketId = findBucketFromPixelIndex(i);
      if (i==0) {
        prevBucket = bucketId;
      }
      //loop exits on new bucketId or end of list
      if (bucketId == prevBucket && i != pixels.length) {
        uint buff = intPosArr.length + i;
        intPosArr[i] = posInBucket;
        intColArr[i] = colors[i];
      }
      else {
        //Load whole bucket
        bytes2[16] memory newBucket = bucket[bucketId];
        for (uint j=0; j<intPosArr.length; j++){
          newBucket[intPosArr[j]] = intColArr[j];
        }
        _storeBucket(bucketId, newBucket);
        //write new values into intArray
        delete(intPosArr);
        delete(intColArr);
        intPosArr[0] = posInBucket;
        intColArr[0] = colors[i];
        prevBucket = bucketId;
      }

    }
  } */

  function _storeBucket(uint256 _bucket, bytes2[16] memory _arr) internal {
    buckets[_bucket] = _arr;
  }

  function getBucket(uint index) public view returns (bytes2[16] memory) {
    return buckets[index];
  }

  function findBucketFromPixelIndex(uint index) public pure returns(uint) {
    return (index / bucketSize);
  }

  function findPosInBucket(uint index) public pure returns(uint) {
    return (index % bucketSize);
  }

  function getAllBuckets() public view returns (bytes2[totalBuckets][16] memory) {
    bytes2[totalBuckets][16] memory allBuckets;
    uint i = 0;
    uint j = 0;
    while (i < totalBuckets) {
      bytes2[16] memory thisBucket = buckets[i];
      while (j < 16) {
        allBuckets[i][j] = thisBucket[j];
        j++;
      }
      j=0;
      i++;
    }
    return allBuckets;
  }

  function bucketWrapping() public pure returns (uint) {
    return wrapBucketAtIndex_;
  }

  function bucketInternalWrapping() public pure returns (uint) {
    return bucketInternalWrapping_;
  }

  receive() external payable {}

}