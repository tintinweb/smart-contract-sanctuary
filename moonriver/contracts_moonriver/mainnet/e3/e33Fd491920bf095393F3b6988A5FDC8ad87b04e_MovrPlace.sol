pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MovrPlace is ReentrancyGuard {

  address private immutable owner;

  mapping (uint256 => uint16[16]) private buckets;

  mapping (string => uint256) private totalByCommunity;

  mapping (string => uint256) private totalByCharity;

  mapping (string => uint256) private amtDisbursedToCharity;

  //There should be a 1:1 mapping of totalByCharity to disbursementAddr
  mapping (string => address) private disbursementAddr;

  string[] private communities;
  string[] private charities;

  bool private lock;

  uint128 private constant wrapBucketAtIndex_ = 128;
  uint128 private constant bucketInternalWrapping_ = 4;
  uint128 private constant bucketSize = 16;
  uint128 private constant sizeX = 512;
  uint128 private constant sizeY = 512;
  uint128 private constant totalBuckets = sizeX*sizeY/bucketSize;

  uint256 private _pixelPrice = 1*10**14;

  event pixelsCommitted(pixelInput[]);

  struct pixelInput {
    uint256 bucket;
    uint256 posInBucket;
    uint16 color;
  }

  modifier onlyOwner {
     require(msg.sender == owner, "MOVRPlace: not owner");
     _;
  }

  constructor () {
    owner = msg.sender;
    lock = true;
  }

  function getLock() public view returns(bool) {
    return lock;
  }

  function setLock(bool state) external onlyOwner {
    lock = state;
  }

  function addCommunity(string calldata _id) external onlyOwner {
    communities.push(_id);
  }

  function addCharity(string calldata _id, address _disbursementAddr) external onlyOwner {
    charities.push(_id);
    disbursementAddr[_id] = _disbursementAddr;
  }

  function disburseRaised(string calldata _id) external onlyOwner nonReentrant {
    address _disbursementAddr = disbursementAddr[_id];

    require(_disbursementAddr != address(0), "not official community");

    uint256 _disbursementAmt = totalByCharity[_id] - amtDisbursedToCharity[_id];

    amtDisbursedToCharity[_id] += _disbursementAmt;

    _withdraw(_disbursementAddr, _disbursementAmt);
  }

  function setPixelPrice(uint256 newPrice) external onlyOwner {
    _pixelPrice = newPrice;
  }

  function pixelPrice() public view returns (uint256) {
    return _pixelPrice;
  }

  function getPriceOfPixels(uint256 numPixels) public view returns (uint256) {
    return _pixelPrice * numPixels;
  }

  function getAllCommunities() public view returns (string[] memory) {
    return(communities);
  }

  function getAllCharities() public view returns (string[] memory) {
    return(charities);
  }

  function storePixels(pixelInput[] calldata pixelInputs, string calldata _communityId, string calldata _charityId) external payable {
    require(!lock, "MOVRPlace: contract is locked");
    uint256 length = pixelInputs.length;
    require(length > 0, "No inputs");
    require(disbursementAddr[_charityId] != address(0), "Not a valid charity");
    require(msg.value >= getPriceOfPixels(pixelInputs.length), "Transaction underpriced");

    totalByCommunity[_communityId] += msg.value;
    totalByCharity[_charityId] += msg.value;

    uint bucketId;
    uint prevBucket;
    uint16[16] memory loadBucket;

    for (uint i = 0; i<length; i = u_inc(i)) {
      bucketId = pixelInputs[i].bucket;
      pixelInput memory currPixelInput = pixelInputs[i];

      if (i==0) { //Init loop
        loadBucket = buckets[bucketId];
        prevBucket = bucketId;
      }

      if (prevBucket == bucketId) {
        loadBucket[currPixelInput.posInBucket] = currPixelInput.color;
      }

      else if (prevBucket != bucketId) {
        _storeBucket(prevBucket, loadBucket);
        loadBucket = buckets[bucketId];
        loadBucket[currPixelInput.posInBucket] = currPixelInput.color;
        prevBucket = bucketId;
      }
    }
    _storeBucket(prevBucket, loadBucket);
  }

  function _storeBucket(uint256 _bucket, uint16[16] memory _arr) internal {
    buckets[_bucket] = _arr;
  }

  function getBucket(uint index) public view returns (uint16[16] memory) {
    return buckets[index];
  }

  function findBucketFromPixelIndex(uint index) public pure returns(uint) {
    return (index / bucketSize);
  }

  function findPosInBucket(uint index) public pure returns(uint) {
    return (index % bucketSize);
  }

  function getFlatBuckets1024(uint256 fromBucket) public view returns(uint16[16384] memory) {
    uint16[16384] memory bucketRange;
    uint i = fromBucket;
    uint j;
    while (i < 1024) {
      uint16[16] memory thisBucket = buckets[i];
      uint256 baseIndex = (i-fromBucket)*16;
      while (j < 16) {
        bucketRange[baseIndex + j] = thisBucket[j];
        j = u_inc(j);
      }
      j=0;
      i = u_inc(i);
    }
    return bucketRange;
  }

  function getFlatBuckets768(uint256 fromBucket) public view returns(uint16[12288] memory) {
    uint16[12288] memory bucketRange;
    uint i = fromBucket;
    uint j;
    while (i < 768) {
      uint16[16] memory thisBucket = buckets[i];
      uint256 baseIndex = (i-fromBucket)*16;
      while (j < 16) {
        bucketRange[baseIndex + j] = thisBucket[j];
        j = u_inc(j);
      }
      j=0;
      i = u_inc(i);
    }
    return bucketRange;
  }

  function getFlatBuckets512(uint256 fromBucket) public view returns(uint16[8192] memory) {
    uint16[8192] memory bucketRange;
    uint i = fromBucket;
    uint j;
    while (i < 512) {
      uint16[16] memory thisBucket = buckets[i];
      uint256 baseIndex = (i-fromBucket)*16;
      while (j < 16) {
        bucketRange[baseIndex + j] = thisBucket[j];
        j = u_inc(j);
      }
      j=0;
      i = u_inc(i);
    }
    return bucketRange;
  }

  function getFlatBuckets256(uint256 fromBucket) public view returns(uint16[4096] memory) {
    uint16[4096] memory bucketRange;
    uint i = fromBucket;
    uint j;
    while (i < 256) {
      uint16[16] memory thisBucket = buckets[i];
      uint256 baseIndex = (i-fromBucket)*16;
      while (j < 16) {
        bucketRange[baseIndex + j] = thisBucket[j];
        j = u_inc(j);
      }
      j=0;
      i = u_inc(i);
    }
    return bucketRange;
  }

  function bucketWrapping() public pure returns (uint) {
    return wrapBucketAtIndex_;
  }

  function bucketInternalWrapping() public pure returns (uint) {
    return bucketInternalWrapping_;
  }

  function getCommunityTotal(string calldata _id) public view returns(uint) {
    return totalByCommunity[_id];
  }

  function getCharityTotal(string calldata _id) public view returns(uint) {
    return totalByCharity[_id];
  }

  //Withdrawls

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  function emergencyWithdraw() external onlyOwner {
      _withdraw(owner, address(this).balance);
  }

  //Helpers

  function u_inc(uint i) private pure returns (uint) {
    unchecked {
        return i + 1;
    }
  }

  receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}