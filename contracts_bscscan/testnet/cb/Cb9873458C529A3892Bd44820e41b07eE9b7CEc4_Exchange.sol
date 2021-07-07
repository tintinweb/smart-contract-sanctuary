/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// File: @pefish/solidity-lib/contracts/contract/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev init function sets the original `owner` of the contract to the sender
     * account.
     */
    function __Ownable_init () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "only owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @pefish/solidity-lib/contracts/interface/IErc165.sol


interface IErc165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @pefish/solidity-lib/contracts/interface/IErc721.sol


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IErc721 is IErc165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of NFTs in `owner`'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   *
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * NFT by either {approve} or {setApprovalForAll}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - If the caller is not `from`, it must be approved to move this NFT by
   * either {approve} or {setApprovalForAll}.
   */
  function transferFrom(address from, address to, uint256 tokenId) external;
  function approve(address to, uint256 tokenId) external;
  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;
  function isApprovedForAll(address owner, address operator) external view returns (bool);


  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

// File: @pefish/solidity-lib/contracts/interface/IErc20.sol

interface IErc20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address guy) external view returns (uint256);
    function allowance(address src, address guy) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(
        address src, address dst, uint256 wad
    ) external returns (bool);

//    function mint(address account, uint256 amount) external returns (bool);
//    function burn(uint256 amount) external returns (bool);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
}

// File: contracts/interface/ITransferProxy.sol

interface ITransferProxy {
  function erc20safeTransferFrom(IErc20 token, address from, address to, uint256 value) external;
  function erc721safeTransferFrom(IErc721 token, address from, address to, uint256 tokenId) external;
  function erc721safeTransferFrom(IErc721 token, address from, address to, uint256 tokenId, bytes memory data) external;
}

// File: contracts/exchange/ExchangeDomain.sol


contract ExchangeDomain {

  enum FeeSide {NONE, SELL, BUY}

  enum AssetType {ETH, ERC20, ERC721}

  struct Asset {
    address token;
    uint tokenId;
    string tokenURI;
    AssetType assetType;
  }

  struct OrderKey {
    /* who signed the order */
    address owner;   // 订单发起者
    /* random number */
    uint salt;  // 随机数

    /* what has owner */
    Asset sellAsset;  // 卖的资产信息

    /* what wants owner */
    Asset buyAsset;  // 买所花的资产信息

    uint256 orderType;  // 订单类型。0 一口价，1 竞价，2 议价

    uint256 auctionDeadTime;  // 拍卖单截止时间。单位秒
  }

  struct Order {
    OrderKey key;   // 对此 hash 就是订单 id
    uint sellPrice;  // 一口价订单中的卖价，需要由卖家签名
  }

  struct BidInfo {
    uint salt;  // 随机数
    address bidder;
    uint256 buyPrice;
    bytes32 orderId;
    uint256 bidTime;  // 出价时间。单位秒
  }

  struct BargainInfo {
    uint salt;  // 随机数
    address buyer;
    uint256 buyPrice;
    bytes32 orderId;
  }

  /* An ECDSA signature. */
  struct Sig {
    /* v parameter */
    uint8 v;
    /* r parameter */
    bytes32 r;
    /* s parameter */
    bytes32 s;
  }
}

// File: contracts/exchange/ExchangeState.sol

contract ExchangeState {

  struct OrderRecord {
    address buyer;
    uint256 amount;
    uint256 completed;
  }

  struct OrderState {
    OrderRecord[] records;
    bool disable;
  }

  struct BidInfoState {
    bool disable;
  }

  struct BargainInfoState {
    bool disable;
  }

  mapping(bytes32 => OrderState) public orderState;
  mapping(bytes32 => BidInfoState) public bidInfoState;
  mapping(bytes32 => BargainInfoState) public bargainInfoState;

  // Deprecated
  function getCompleted(ExchangeDomain.OrderKey memory key) view public returns (uint256) {
    return getOrderCompletedCount(key);
  }

  function getOrderCompletedCount(ExchangeDomain.OrderKey memory key) view public returns (uint256) {
    OrderRecord[] memory records = orderState[getOrderId(key)].records;
    if (records.length == 0) {
      return 0;
    }
    return records[records.length - 1].completed;
  }

  function getOrderState(ExchangeDomain.OrderKey memory key) view public returns (OrderState memory) {
    return orderState[getOrderId(key)];
  }

  function setRecord(ExchangeDomain.OrderKey memory key, address buyer, uint256 amount, uint256 completed) internal {
    orderState[getOrderId(key)].records.push(OrderRecord(buyer, amount, completed));
  }

  function disableOrder(ExchangeDomain.OrderKey memory key) internal {
    orderState[getOrderId(key)].disable = true;
  }

  function getOrderId(ExchangeDomain.OrderKey memory key) pure public returns (bytes32) {
    return keccak256(abi.encode(key));
  }

  // Deprecated
  function getCompletedKey(ExchangeDomain.OrderKey memory key) pure public returns (bytes32) {
    return getOrderId(key);
  }




  function getBidInfoState(ExchangeDomain.BidInfo memory key) view public returns (BidInfoState memory) {
    return bidInfoState[getBidInfoId(key)];
  }

  function disableBidInfo(ExchangeDomain.BidInfo memory key) internal {
    bidInfoState[getBidInfoId(key)].disable = true;
  }

  function getBidInfoId(ExchangeDomain.BidInfo memory key) pure public returns (bytes32) {
    return keccak256(abi.encode(key));
  }




  function getBargainInfoState(ExchangeDomain.BargainInfo memory key) view public returns (BargainInfoState memory) {
    return bargainInfoState[getBargainInfoId(key)];
  }

  function disableBargainInfo(ExchangeDomain.BargainInfo memory key) internal {
    bargainInfoState[getBargainInfoId(key)].disable = true;
  }

  function getBargainInfoId(ExchangeDomain.BargainInfo memory key) pure public returns (bytes32) {
    return keccak256(abi.encode(key));
  }

}

// File: contracts/interface/IErc721Extend.sol


interface IErc721Extend is IErc721 {
  function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
  function getFeeBps(uint256 id) external view returns (uint[] memory);

}

// File: @pefish/solidity-lib/contracts/contract/Initializable.sol

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly {cs := extcodesize(self)}
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @pefish/solidity-lib/contracts/library/Uint256Util.sol

/** @title string util */
library Uint256Util {
    /**
     * @dev uint256 -> string
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (true) {
            buffer[index] = bytes1(uint8(48 + temp % 10));
            if (index > 0) {
                index = index - 1;
                temp /= 10;
            } else {
                break;
            }
        }
        return string(buffer);
    }

}

// File: @pefish/solidity-lib/contracts/library/BytesUtil.sol


library BytesUtil {
  using BytesUtil for bytes;
  /// @dev Gets the memory address for a byte array.
  /// @param input Byte array to lookup.
  /// @return memoryAddress Memory address of byte array. This
  ///         points to the header of the byte array which contains
  ///         the length.
  function pointAddress(bytes memory input)
  internal
  pure
  returns (uint256 memoryAddress)
  {
    assembly {
      memoryAddress := input
    }
    return memoryAddress;
  }

  /// @dev Gets the memory address for the contents of a byte array.
  /// @param input Byte array to lookup.
  /// @return memoryAddress Memory address of the contents of the byte array.
  function contentPointAddress(bytes memory input)
  internal
  pure
  returns (uint256 memoryAddress)
  {
    assembly {
      memoryAddress := add(input, 32)
    }
    return memoryAddress;
  }

  /// @dev Copies `length` bytes from memory location `source` to `dest`.
  /// @param dest memory address to copy bytes to.
  /// @param source memory address to copy bytes from.
  /// @param length number of bytes to copy.
  function memCopy(
    uint256 dest,
    uint256 source,
    uint256 length
  )
  internal
  pure
  {
    if (length < 32) {
      // Handle a partial word by reading destination and masking
      // off the bits we are interested in.
      // This correctly handles overlap, zero lengths and source == dest
      assembly {
        let mask := sub(exp(256, sub(32, length)), 1)
        let s := and(mload(source), not(mask))
        let d := and(mload(dest), mask)
        mstore(dest, or(s, d))
      }
    } else {
      // Skip the O(length) loop when source == dest.
      if (source == dest) {
        return;
      }

      // For large copies we copy whole words at a time. The final
      // word is aligned to the end of the range (instead of after the
      // previous) to handle partial words. So a copy will look like this:
      //
      //  ####
      //      ####
      //          ####
      //            ####
      //
      // We handle overlap in the source and destination range by
      // changing the copying direction. This prevents us from
      // overwriting parts of source that we still need to copy.
      //
      // This correctly handles source == dest
      //
      if (source > dest) {
        assembly {
        // We subtract 32 from `sEnd` and `dEnd` because it
        // is easier to compare with in the loop, and these
        // are also the addresses we need for copying the
        // last bytes.
          length := sub(length, 32)
          let sEnd := add(source, length)
          let dEnd := add(dest, length)

        // Remember the last 32 bytes of source
        // This needs to be done here and not after the loop
        // because we may have overwritten the last bytes in
        // source already due to overlap.
          let last := mload(sEnd)

        // Copy whole words front to back
        // Note: the first check is always true,
        // this could have been a do-while loop.
        // solhint-disable-next-line no-empty-blocks
          for {} lt(source, sEnd) {} {
            mstore(dest, mload(source))
            source := add(source, 32)
            dest := add(dest, 32)
          }

        // Write the last 32 bytes
          mstore(dEnd, last)
        }
      } else {
        assembly {
        // We subtract 32 from `sEnd` and `dEnd` because those
        // are the starting points when copying a word at the end.
          length := sub(length, 32)
          let sEnd := add(source, length)
          let dEnd := add(dest, length)

        // Remember the first 32 bytes of source
        // This needs to be done here and not after the loop
        // because we may have overwritten the first bytes in
        // source already due to overlap.
          let first := mload(source)

        // Copy whole words back to front
        // We use a signed comparisson here to allow dEnd to become
        // negative (happens when source and dest < 32). Valid
        // addresses in local memory will never be larger than
        // 2**255, so they can be safely re-interpreted as signed.
        // Note: the first check is always true,
        // this could have been a do-while loop.
        // solhint-disable-next-line no-empty-blocks
          for {} slt(dest, dEnd) {} {
            mstore(dEnd, mload(sEnd))
            sEnd := sub(sEnd, 32)
            dEnd := sub(dEnd, 32)
          }

        // Write the first 32 bytes
          mstore(dest, first)
        }
      }
    }
  }

  /// @dev Returns a slices from a byte array.
  /// @param b The byte array to take a slice from.
  /// @param from The starting index for the slice (inclusive).
  /// @param to The final index for the slice (exclusive).
  /// @return result The slice containing bytes at indices [from, to)
  function slice(
    bytes memory b,
    uint256 from,
    uint256 to
  )
  internal
  pure
  returns (bytes memory result)
  {
    // Ensure that the from and to positions are valid positions for a slice within
    // the byte array that is being used.
    require(from <= to, "FromLessThanOrEqualsToRequired");
    require(to <= b.length, "ToLessThanOrEqualsLengthRequired");

    // Create a new bytes structure and copy contents
    result = new bytes(to - from);
    memCopy(
      result.contentPointAddress(),
      b.contentPointAddress() + from,
      result.length
    );
    return result;
  }

  /// @dev Returns a slice from a byte array without preserving the input.
  ///      When `from == 0`, the original array will match the slice.
  ///      In other cases its state will be corrupted.
  /// @param b The byte array to take a slice from. Will be destroyed in the process.
  /// @param from The starting index for the slice (inclusive).
  /// @param to The final index for the slice (exclusive).
  /// @return result The slice containing bytes at indices [from, to)
  function sliceDestructive(
    bytes memory b,
    uint256 from,
    uint256 to
  )
  internal
  pure
  returns (bytes memory result)
  {
    // Ensure that the from and to positions are valid positions for a slice within
    // the byte array that is being used.
    require(from <= to, "FromLessThanOrEqualsToRequired");
    require(to <= b.length, "ToLessThanOrEqualsLengthRequired");

    // Create a new bytes structure around [from, to) in-place.
    assembly {
      result := add(b, from)
      mstore(result, sub(to, from))
    }
    return result;
  }

  /// @dev Pops the last byte off of a byte array by modifying its length.
  /// @param b Byte array that will be modified.
  /// @return result The byte that was popped off.
  function popLastByte(bytes memory b)
  internal
  pure
  returns (bytes1 result)
  {
    require(b.length != 0, "LengthGreaterThanZeroRequired");

    // Store last byte.
    result = b[b.length - 1];

    assembly {
    // Decrement length of byte array.
      let newLen := sub(mload(b), 1)
      mstore(b, newLen)
    }
    return result;
  }

  /// @dev Tests equality of two byte arrays.
  /// @param lhs First byte array to compare.
  /// @param rhs Second byte array to compare.
  /// @return equal True if arrays are the same. False otherwise.
  function equals(
    bytes memory lhs,
    bytes memory rhs
  )
  internal
  pure
  returns (bool equal)
  {
    // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
    // We early exit on unequal lengths, but keccak would also correctly
    // handle this.
    return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
  }

  /// @dev Reads an address from a position in a byte array.
  /// @param b Byte array containing an address.
  /// @param index Index in byte array of address.
  /// @return result address from byte array.
  function readAddress(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (address result)
  {
    require(b.length >= index + 20, "LengthGreaterThanOrEqualsTwentyRequired");

    // Add offset to index:
    // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
    // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
    index += 20;

    // Read address from array memory
    assembly {
    // 1. Add index to address of bytes array
    // 2. Load 32-byte word from memory
    // 3. Apply 20-byte mask to obtain address
      result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
    }
    return result;
  }

  /// @dev Writes an address into a specific position in a byte array.
  /// @param b Byte array to insert address into.
  /// @param index Index in byte array of address.
  /// @param input Address to put into byte array.
  function writeAddress(
    bytes memory b,
    uint256 index,
    address input
  )
  internal
  pure
  {
    require(b.length >= index + 20, "LengthGreaterThanOrEqualsTwentyRequired");

    // Add offset to index:
    // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
    // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
    index += 20;

    // Store address into array memory
    assembly {
    // The address occupies 20 bytes and mstore stores 32 bytes.
    // First fetch the 32-byte word where we'll be storing the address, then
    // apply a mask so we have only the bytes in the word that the address will not occupy.
    // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

    // 1. Add index to address of bytes array
    // 2. Load 32-byte word from memory
    // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
      let neighbors := and(
      mload(add(b, index)),
      0xffffffffffffffffffffffff0000000000000000000000000000000000000000
      )

    // Make sure input address is clean.
    // (Solidity does not guarantee this)
      input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

    // Store the neighbors and address into memory
      mstore(add(b, index), xor(input, neighbors))
    }
  }

  /// @dev Reads a bytes32 value from a position in a byte array.
  /// @param b Byte array containing a bytes32 value.
  /// @param index Index in byte array of bytes32 value.
  /// @return result bytes32 value from byte array.
  function readBytes32(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (bytes32 result)
  {
    require(b.length >= index + 32, "LengthGreaterThanOrEqualsThirtyTwoRequired");

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }

  /// @dev Writes a bytes32 into a specific position in a byte array.
  /// @param b Byte array to insert <input> into.
  /// @param index Index in byte array of <input>.
  /// @param input bytes32 to put into byte array.
  function writeBytes32(
    bytes memory b,
    uint256 index,
    bytes32 input
  )
  internal
  pure
  {
    require(b.length >= index + 32, "LengthGreaterThanOrEqualsThirtyTwoRequired");

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      mstore(add(b, index), input)
    }
  }

  /// @dev Reads a uint256 value from a position in a byte array.
  /// @param b Byte array containing a uint256 value.
  /// @param index Index in byte array of uint256 value.
  /// @return result uint256 value from byte array.
  function readUint256(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (uint256 result)
  {
    result = uint256(readBytes32(b, index));
    return result;
  }

  /// @dev Writes a uint256 into a specific position in a byte array.
  /// @param b Byte array to insert <input> into.
  /// @param index Index in byte array of <input>.
  /// @param input uint256 to put into byte array.
  function writeUint256(
    bytes memory b,
    uint256 index,
    uint256 input
  )
  internal
  pure
  {
    writeBytes32(b, index, bytes32(input));
  }

  /// @dev Reads an unpadded bytes4 value from a position in a byte array.
  /// @param b Byte array containing a bytes4 value.
  /// @param index Index in byte array of bytes4 value.
  /// @return result bytes4 value from byte array.
  function readBytes4(
    bytes memory b,
    uint256 index
  )
  internal
  pure
  returns (bytes4 result)
  {
    require(b.length >= index + 4, "LengthGreaterThanOrEqualsFourRequired");

    // Arrays are prefixed by a 32 byte length field
    index += 32;

    // Read the bytes4 from array memory
    assembly {
      result := mload(add(b, index))
    // Solidity does not require us to clean the trailing bytes.
    // We do it anyway
      result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
    }
    return result;
  }

  /// @dev Writes a new length to a byte array.
  ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
  ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
  /// @param b Bytes array to write new length to.
  /// @param length New length of byte array.
  function writeLength(bytes memory b, uint256 length)
  internal
  pure
  {
    assembly {
      mstore(b, length)
    }
  }

  function recover(bytes memory _msgBytes, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
    bytes memory fullMessage = concat(
      bytes("\x19Ethereum Signed Message:\n"),
      bytes(Uint256Util.toString(_msgBytes.length)),
      _msgBytes,
      new bytes(0), new bytes(0), new bytes(0), new bytes(0)
    );
    return ecrecover(keccak256(fullMessage), _v, _r, _s);
  }


  function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
    bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
    uint k = 0;
    for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
    for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
    for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
    for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
    for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
    for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
    for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
    return resultBytes;
  }

  function toHexString(bytes memory _value) internal pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(64);
    for (uint256 i = 0; i < _value.length; i++) {
      str[i*2] = alphabet[uint8(_value[i] >> 4)];
      str[1+i*2] = alphabet[uint8(_value[i] & 0x0f)];
    }
    return string(str);
  }
}

// File: @pefish/solidity-lib/contracts/library/StringUtil.sol


/** @title string util */
library StringUtil {

    function isEqual(string memory _v1, string memory _v2) internal pure returns (bool) {
        return uint(keccak256(abi.encodePacked(_v1))) == uint(keccak256(abi.encodePacked(_v2)));
    }

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory _msg, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        return BytesUtil.recover(bytes(_msg), _v, _r, _s);
    }
}

// File: @pefish/solidity-lib/contracts/library/Bytes32Util.sol

library Bytes32Util {
  function toHexString(bytes32 _value) internal pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(64);
    for (uint256 i = 0; i < 32; i++) {
      str[i*2] = alphabet[uint8(_value[i] >> 4)];
      str[1+i*2] = alphabet[uint8(_value[i] & 0x0f)];
    }
    return string(str);
  }
}

// File: contracts/exchange/Exchange.sol


contract Exchange is Ownable, ExchangeDomain, Initializable, ExchangeState {

  event Buy(
    Order order,
    uint amount,
    address buyer,
    uint256 paying
  );

  event CancelOrder(
    OrderKey key
  );

  event CancelBidInfo(
    BidInfo key
  );

  event CancelBargainInfo(
    BargainInfo key
  );

  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  address payable public beneficiary;  // 接收服务费的账户

  ITransferProxy public transferProxy;

  uint256 public serviceFee = 250;

  function __Exchange_init() external initializer {
    __Ownable_init();
  }

  function initData(
    ITransferProxy _transferProxy,
    address payable _beneficiary
  ) external onlyOwner {
    transferProxy = _transferProxy;
    beneficiary = _beneficiary;
  }

  function setTransferProxy(address _transferProxy) external onlyOwner {
    transferProxy = ITransferProxy(_transferProxy);
  }

  function setBeneficiary(address payable _newBeneficiary) external onlyOwner {
    beneficiary = _newBeneficiary;
  }

  function setServiceFee(uint256 _serviceFee) external onlyOwner {
    serviceFee = _serviceFee;
  }

  function acceptBid(  // 卖家接受买家竞价，由卖家发起调用
    Order calldata order,  // 卖家构造
    uint256 amount,
    BidInfo calldata bidInfo,
    Sig calldata bidSig
  ) payable external {
    require(order.key.orderType == 1, "incorrect order type");
    require(StringUtil.recover(prepareBidInfoMessage(bidInfo), bidSig.v, bidSig.r, bidSig.s) == bidInfo.bidder, "incorrect bidder signature");
    require(bidInfo.orderId == getOrderId(order.key), "bidder not match order");
    require(msg.sender == order.key.owner, "operator must be seller");
//    require(bidInfo.bidTime <= order.key.auctionDeadTime, "bid time is after order");  // 拍卖时间会自动延长，这里不能作限制
    // 要求出价没有被取消
    require(getBidInfoState(bidInfo).disable == false, "bid info is disable");

    uint256 paying = bidInfo.buyPrice * amount;
    address buyer = bidInfo.bidder;

    _exchange(order, amount, buyer, paying);
  }

  function acceptBargain(  // 卖家接受买家议价，由卖家发起调用
    Order calldata order,  // 由买家构造
    uint256 amount,
    BargainInfo calldata bargainInfo,
    Sig calldata bargainSig
  ) payable external {
    require(order.key.orderType == 2, "incorrect order type");
    require(msg.sender == order.key.owner, "operator must be seller");
    require(StringUtil.recover(prepareBargainInfoMessage(bargainInfo), bargainSig.v, bargainSig.r, bargainSig.s) == bargainInfo.buyer, "incorrect bargain signature");
    require(bargainInfo.orderId == getOrderId(order.key), "bargain not match order");

    // 要求出价没有被取消
    require(getBargainInfoState(bargainInfo).disable == false, "bargain info is disable");

    uint256 paying = bargainInfo.buyPrice * amount;
    address buyer = bargainInfo.buyer;

    _exchange(order, amount, buyer, paying);
  }

  function exchange(  // 买家一口价购买 NFT，由买家发起调用
    Order calldata order, // 订单信息
    Sig calldata sig, // 卖家出售前对订单信息的 keccak256 hash 的签名
    uint256 amount, // 买多少数量
    address buyer
  ) payable external {
    require(order.key.orderType == 0, "incorrect order type");
    // 必须是一口价订单
    require(StringUtil.recover(prepareMessage(order), sig.v, sig.r, sig.s) == order.key.owner, "incorrect order signature");
    // 校验订单签名
    uint256 paying = order.sellPrice * amount;
    // 要支付的金额 = 买的数量 * 单价

    if (buyer == address(0x0)) {// 如果卖家没有指定买家，则买家就是交易发送者
      buyer = msg.sender;
    }

    _exchange(order, amount, buyer, paying);
  }

  function _exchange(
    Order calldata order,
    uint256 amount,
    address buyer,
    uint256 paying
  ) private {
    require(getOrderState(order.key).disable == false, "order is disable");
    // 订单已取消
    // 校验超卖
    uint256 completed = getCompleted(order.key);
    // 得到这个单子已经卖出去的数量
    uint256 newCompleted = completed + amount;
    // 加上这次要买的数量
    require(newCompleted <= 1, "not enough stock of order for buying");
    // 必须小于或等于这个单子的总量 1
    setRecord(order.key, buyer, amount, newCompleted);
    // 更新已经卖出的数量

    require(order.key.sellAsset.assetType != AssetType.ETH, "ETH is not supported on sell side");
    if (order.key.buyAsset.assetType == AssetType.ETH) {// 如果买家支付的币种类型是 eth
      require(msg.value == paying, "msg.value is incorrect");
      // 校验资金
    }

    transferWithFeesPossibility(order.key.sellAsset, amount, order.key.owner, buyer, true, order.key.buyAsset);
    // 卖家清算。卖家的资产转给买家。卖出必须给平台 fee
    transferWithFeesPossibility(order.key.buyAsset, paying, msg.sender, order.key.owner, false, order.key.sellAsset);
    // 买家清算。买家的资产转给卖家。买入无需手续费

    emit Buy(order, amount, buyer, paying);
  }

  // Deprecated
  function cancel(OrderKey calldata key) external {// 取消订单　
    cancelOrder(key);
  }

  function cancelOrder(OrderKey calldata order) public {// 取消订单　
    require(order.owner == msg.sender, "not an owner");  // 只能取消自己的单子
    disableOrder(order);
    emit CancelOrder(order);
  }

  function cancelBidInfo(BidInfo calldata bidInfo) external {// 取消出价
    require(bidInfo.bidder == msg.sender, "not an owner");
    disableBidInfo(bidInfo);
    emit CancelBidInfo(bidInfo);
  }

  function cancelBargainInfo(BargainInfo calldata bargainInfo) external {// 取消议价
    require(bargainInfo.buyer == msg.sender, "not an owner");
    disableBargainInfo(bargainInfo);
    emit CancelBargainInfo(bargainInfo);
  }

  // Deprecated
  function prepareMessage(Order memory order) public pure returns (string memory) {
    return prepareOrderMessage(order);
  }

  function prepareOrderMessage(Order memory order) public pure returns (string memory) {
    return Bytes32Util.toHexString(keccak256(abi.encode(order)));
  }

  function prepareBidInfoMessage(BidInfo memory bidInfo) public pure returns (string memory) {
    return Bytes32Util.toHexString(keccak256(abi.encode(bidInfo)));
  }

  function prepareBargainInfoMessage(BargainInfo memory bargainInfo) public pure returns (string memory) {
    return Bytes32Util.toHexString(keccak256(abi.encode(bargainInfo)));
  }

  function transferWithFeesPossibility(Asset memory firstType, uint value, address from, address to, bool hasFee, Asset memory secondType) private {
    if (!hasFee) {// 卖家清算走这里，erc721 转给买家
      transfer(firstType, value, from, to);
    } else {// 买家清算走这里，eth 或 erc20 支付手续费，剩余的转给卖家
      transferWithFees(firstType, value, from, to, secondType);
    }
  }

  function transfer(Asset memory asset, uint value, address from, address to) private {
    if (asset.assetType == AssetType.ETH) {
      payable(to).transfer(value);
    } else if (asset.assetType == AssetType.ERC20) {
      require(asset.tokenId == 0, "tokenId should be 0");
      transferProxy.erc20safeTransferFrom(IErc20(asset.token), from, to, value);
    } else if (asset.assetType == AssetType.ERC721) {
      require(value == 1, "value should be 1 for ERC-721");
      transferProxy.erc721safeTransferFrom(IErc721(asset.token), from, to, asset.tokenId, abi.encode(asset.tokenURI));
    } else {
      require(false, "asset type error");
    }
  }

  function transferWithFees(Asset memory firstType, uint value, address from, address to, Asset memory secondType) private {
    uint restValue = transferFeeToBeneficiary(firstType, from, value);
    // 买卖 fee 转给平台
//    if (secondType.assetType == AssetType.ERC721 && IErc721Extend(secondType.token).supportsInterface(_INTERFACE_ID_FEES)) {// 如果支付资产或者出售资产是 erc721 且支持 fee 特性。通常支付资产不会是 erc721 ，所以买家清算才会走到这里
//      IErc721Extend withFees = IErc721Extend(secondType.token);
//      address payable[] memory recipients = withFees.getFeeRecipients(secondType.tokenId);
//      // 得到这个 token 需要支付 fee 给哪些人
//      uint[] memory fees = withFees.getFeeBps(secondType.tokenId);
//      // 得到这个 token 需要支付这些人哪些 fee 比例
//      require(fees.length == recipients.length);
//      for (uint256 i = 0; i < fees.length; i++) {
//        (uint newRestValue, uint realFee) = _subFee(restValue, value * fees[i] / 10000);
//        restValue = newRestValue;
//        // 更新剩余的要打给卖家的资金，所以实际上是卖家支付的转卖费（就是版权费）
//        transfer(firstType, realFee, from, recipients[i]);
//      }
//    }
    transfer(firstType, restValue, from, payable(to));
    // 剩余的打给卖家
  }

  function transferFeeToBeneficiary(Asset memory asset, address from, uint total) private returns (uint) {
    (uint restValue, uint realFee) = _subFee(total, total * serviceFee / 10000);
    // 得到 减去卖出 fee 剩余的值 和 卖出fee
    if (realFee > 0) {
      transfer(asset, realFee, from, beneficiary);
      // fee 转给 beneficiary
    }
    return restValue;
  }

  function _subFee(uint value, uint fee) private pure returns (uint newValue, uint realFee) {
    if (value > fee) {
      newValue = value - fee;
      realFee = fee;
    } else {
      newValue = 0;
      realFee = value;
    }
  }
}