// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../derived/OwnableClone.sol';
import '../sales/ISaleable.sol';
import '../sales/RevenueAccounts.sol';

import '../utils/BinaryDecoder.sol';
import '../utils/ChunkedByteStream.sol';

contract VFAuctions is RevenueAccounts, Ownable {
  struct Listing {
    uint16    template;
    uint16    consigner;
    uint16    offeringId;
  }

  struct ListingTemplate {
    uint64    openTime;
    uint16    startOffsetMin;
    uint16    endOffsetMin;
    uint16    closeOffsetMin;
    uint16    startPriceFinnies;
    uint16    priceReductionFinnies;
  }

  address[] internal consigners;
  bytes32[0xFFFF] internal listings;
  bytes32[0xFFFF] internal templates;
  uint256 internal numListings;
  mapping (uint256 => bool) internal listingPurchased;

  string public name;

  event ListingPurchased(uint256 indexed listingId, uint16 index, address buyer, address recipient, uint256 price);

  constructor(string memory _name) {
    name = _name;
  }

  uint256 constant private FINNY_TO_WEI = 1000000000000000;

  function calculateCurrentPrice(ListingTemplate memory template) internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;
    uint256 delta = uint256(template.priceReductionFinnies) * FINNY_TO_WEI;
    uint256 startPrice = uint256(template.startPriceFinnies) * FINNY_TO_WEI;
    uint64 startTime = template.openTime + (uint64(template.startOffsetMin) * 60);
    uint64 endTime = template.openTime + (uint64(template.endOffsetMin) * 60);

    if (currentTime >= endTime) {
      return startPrice - delta;
    } else if (currentTime <= startTime) {
      return startPrice;
    }


    uint256 reduction =
      SafeMath.div(SafeMath.mul(delta, currentTime - startTime ), endTime - startTime);
    return startPrice - reduction;
  }

  function calculateCurrentPrice(uint256 listingId) public view returns (uint256) {
    require(numListings >= listingId, 'No such listing');
    Listing memory listing = decodeListing(uint16(listingId));
    ListingTemplate memory template = decodeTemplate(listing.template);
    return calculateCurrentPrice(template);
  }

  function bid(
    uint256 listingId,
    address _recipient,
    address payable _changeAddress
  ) public payable {
    require(listingPurchased[listingId] == false, 'listing sold out');
    require(numListings >= listingId, 'No such listing');
    Listing memory listing = decodeListing(uint16(listingId));
    ListingTemplate memory template = decodeTemplate(listing.template);

    uint64 closeTime = template.openTime + (uint64(template.closeOffsetMin) * 60);
    // solhint-disable-next-line not-rely-on-time
    require(closeTime > block.timestamp && template.openTime <= block.timestamp, 'not open');

    uint256 currentPrice = calculateCurrentPrice(template);
    require(msg.value >= currentPrice, 'Wrong price');
    ISaleable(consigners[listing.consigner]).processSale(listing.offeringId, _recipient, currentPrice);
    listingPurchased[listingId] = true;

    processRevenue(currentPrice, payable(owner()));

    emit ListingPurchased(listingId, listing.offeringId, msg.sender, _recipient, currentPrice);

    if (currentPrice < msg.value) {
      Address.sendValue(_changeAddress, msg.value - currentPrice);
    }
  }

  function addConsigners( address[] memory newConsigners ) public onlyOwner {
    for (uint idx = 0; idx < newConsigners.length; idx++) {
      consigners.push(newConsigners[idx]);
    }
  }

  function addListings( bytes32[] calldata newListings, uint offset, uint length) public onlyOwner {
    uint idx = 0;
    while(idx < newListings.length) {
      listings[offset + idx] = newListings[idx];
      idx++;
    }
    numListings = length;
  }

  function addListingTemplates( bytes32[] calldata newTemplates, uint offset) public onlyOwner {
    uint idx = 0;
    while(idx < newTemplates.length) {
      templates[offset + idx] = newTemplates[idx];
      idx++;
    }
  }

  function authorizeRevenueChange(address, bool) internal virtual override returns (bool) {
    return msg.sender == owner();
  }

  function authorizeWithdrawFor(address) internal virtual override returns (bool) {
    return msg.sender == owner();
  }

  struct OutputListing {
    uint16   listingId;
    address  consigner;
    uint16[] soldOfferingIds;
    uint16[] availableOfferingIds;
    uint256  startPrice;
    uint256  endPrice;
    uint64   startTime;
    uint64   endTime;
    uint64   openTime;
    uint64   closeTime;
  }

  function getListingsLength() public view returns (uint) {
    return numListings;
  }

  function getListings(uint16 start, uint16 length) public view returns (OutputListing[] memory) {
    require(start < numListings, 'out of range');
    uint256 remaining = numListings - start;
    uint256 actualLength = remaining < length ? remaining : length;
    OutputListing[] memory result = new OutputListing[](actualLength);

    for (uint16 idx = 0; idx < actualLength; idx++) {
      uint16 listingId = start + idx;
      Listing memory listing = decodeListing(listingId);
      ListingTemplate memory template = decodeTemplate(listing.template);
      bool isPurchased = listingPurchased[listingId];

      result[idx].listingId   = listingId;
      result[idx].consigner   = consigners[listing.consigner];

      if (isPurchased) {
        result[idx].soldOfferingIds = new uint16[](1);
        result[idx].availableOfferingIds = new uint16[](0);
        result[idx].soldOfferingIds[0] = listing.offeringId;
      } else {
        result[idx].soldOfferingIds = new uint16[](0);
        result[idx].availableOfferingIds = new uint16[](1);
        result[idx].availableOfferingIds[0] = listing.offeringId;
      }

      uint256 reduction = uint256(template.priceReductionFinnies) * FINNY_TO_WEI;
      uint256 startPrice = uint256(template.startPriceFinnies)  * FINNY_TO_WEI;
      uint64 startTime = template.openTime + (uint64(template.startOffsetMin) * 60);
      uint64 endTime = template.openTime + (uint64(template.endOffsetMin) * 60);
      uint64 closeTime = template.openTime + (uint64(template.closeOffsetMin) * 60);


      result[idx].startPrice  = startPrice;
      result[idx].endPrice    = startPrice - reduction;
      result[idx].startTime   = startTime;
      result[idx].endTime     = endTime;
      result[idx].openTime   = template.openTime;
      result[idx].closeTime   = closeTime;
    }

    return result;
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function decodeListing(uint16 idx) internal view returns (Listing memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 6);
    Listing memory result;

    (result.template,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);
    (result.consigner,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);
    (result.offeringId,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);

    return result;
  }

  function decodeTemplate(uint16 idx) internal view returns (ListingTemplate memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 18);
    ListingTemplate memory result;

    (result.openTime,bufferIndex,offset) = BinaryDecoder.decodeUint64(templates, bufferIndex, offset);
    (result.startOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.endOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.closeOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.startPriceFinnies,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.priceReductionFinnies,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);

    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableClone is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function init(address initialOwner) internal {
    require(_owner == address(0), 'Contract is already initialized');
    _owner = initialOwner;
    emit OwnershipTransferred(address(0), initialOwner);
  }

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    init(msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), 'caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'new owner is null address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaleable {
  function processSale(uint256 offeringId, address buyer, uint256 price) external;

  function getSellersFor(uint256 offeringId) external view returns (address[] memory sellers);

  event SaleProcessed(address indexed seller, uint256 indexed offeringId, address buyer);
  event SellerAdded(address indexed seller, uint256 indexed offeringId);
  event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';

abstract contract RevenueAccounts {
  struct RevenueShare {
    address payable receiver;
    uint256 share;
  }

  uint256 public totalShares;
  RevenueShare[] public receiverInfos;
  mapping(address => uint256) public balanceByAccount;

  function receiverExists(address receiver) internal view returns (bool) {
    for (uint256 idx = 0; idx < receiverInfos.length; idx++) {
      if (receiverInfos[idx].receiver == receiver) {
        return true;
      }
    }

    return false;
  }

  function authorizeRevenueChange(address receiver, bool add) internal virtual returns(bool);

  function addRevenueAccounts(address payable receiver, uint256 share) public {
    require(authorizeRevenueChange(receiver, true), 'not authorized');
    require(!receiverExists(receiver), 'Receiver Already Registered');
    receiverInfos.push();
    uint256 newIndex = receiverInfos.length - 1;

    receiverInfos[newIndex].receiver = receiver;
    receiverInfos[newIndex].share = share;
    totalShares += share;
  }

  function removeRevenueAccounts(address receiver) public {
    require(authorizeRevenueChange(receiver, false), 'not authorized');
    require(receiverExists(receiver), 'Receiver not Registered');

    for (uint256 idx = 0; idx < receiverInfos.length; idx++) {
      if (receiverInfos[idx].receiver == receiver) {
        // subtract this receiver's share
        totalShares -= receiverInfos[idx].share;

        // if this isn't the last entry, copy the last entry to this slot
        // after the loop we will drop the tail
        if (idx < receiverInfos.length - 1) {
          receiverInfos[idx] = receiverInfos[receiverInfos.length - 1];
        }
        break;
      }
    }

    receiverInfos.pop();
  }

  function processRevenue(uint256 totalAmount, address payable defaultRecipient) internal {
    if (totalShares == 0) {
      Address.sendValue(defaultRecipient, totalAmount);
      return;
    }

    uint256 remainingAmount = totalAmount;
    RevenueShare[] memory payments = new RevenueShare[](receiverInfos.length);

    for (uint256 idx = 0; idx < receiverInfos.length; idx++) {
      uint256 thisShare = SafeMath.div(SafeMath.mul(totalAmount, receiverInfos[idx].share), totalShares);
      require(thisShare <= remainingAmount, 'Error splitting revenue');
      remainingAmount = remainingAmount - thisShare;
      payments[idx].receiver = receiverInfos[idx].receiver;
      payments[idx].share = thisShare;
    }

    // round robin any excess
    uint256 nextIdx = 0;
    while (remainingAmount > 0) {
      payments[nextIdx % payments.length].share = payments[nextIdx % payments.length].share + 1;
      remainingAmount = remainingAmount - 1;
      nextIdx = nextIdx + 1;
    }

    // process payouts now that we are done reading state (for re-entrancy safety)
    for (uint256 idx = 0; idx < payments.length; idx++) {
      balanceByAccount[payments[idx].receiver] = balanceByAccount[payments[idx].receiver] + payments[idx].share;
    }
  }

  function withdraw() public {
    require(balanceByAccount[msg.sender] > 0, 'no funds');
    uint256 amount = balanceByAccount[msg.sender];
    balanceByAccount[msg.sender] = 0;

    Address.sendValue(payable(msg.sender), amount);
  }

  function authorizeWithdrawFor(address who) internal virtual returns(bool);

  function withdrawFor( address payable who ) public {
    require(authorizeWithdrawFor(who), 'not authorized');
    require(balanceByAccount[who] > 0, 'no funds');
    uint256 amount = balanceByAccount[who];
    balanceByAccount[who] = 0;

    Address.sendValue(who, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint16, uint, uint) {
      uint result = 0;
      if (offset % 32 < 31) {
        return decodeUint16Aligned(buffers, bufferIdx, offset);
      }

      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint32, uint, uint) {
      if (offset % 32 < 29) {
        return decodeUint32Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint64, uint, uint) {
      if (offset % 32 < 25) {
        return decodeUint64Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 48;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 40;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 32;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint64(result), bufferIdx, offset);
    }

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint64, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 48;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 40;
      result |= uint(uint8(buffers[bufferIdx][offset + 3])) << 32;
      result |= uint(uint8(buffers[bufferIdx][offset + 4])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 5])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 6])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 7]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 8);
      return (uint64(result), bufferIdx, offset);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ChunkedByteStream {

  struct Stream {
    bytes32[] buffers;
  }

  function getBufferAndOffset(Stream storage stream, uint16 index, uint16 elementSize) internal view returns (bytes32, uint) {
    uint byteLength = index * elementSize;
    uint bufferIndex = byteLength / 32;
    uint offset = byteLength % 32;
    return (stream.buffers[bufferIndex], offset);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/home/bart/git/InfinityTokens-contract/contracts/utils/BinaryDecoder.sol": {
      "BinaryDecoder": "0x80Fe515cde4274e4D9076E15CD619aFe62dFf2B2"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}