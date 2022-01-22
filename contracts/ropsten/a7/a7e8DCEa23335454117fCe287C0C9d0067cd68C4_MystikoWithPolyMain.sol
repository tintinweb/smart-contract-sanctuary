// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "./MystikoWithPoly.sol";
import "../../pool/MainAssetPool.sol";

contract MystikoWithPolyMain is MystikoWithPoly, MainAssetPool {
  event Received(address, uint256);

  constructor(
    address _eccmp,
    uint64 _peerChainId,
    address _verifier,
    address _hasher,
    uint32 _merkleTreeHeight
  ) public MystikoWithPoly(_eccmp, _peerChainId, _verifier, _hasher, _merkleTreeHeight) {}

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "./AssetPool.sol";

abstract contract MainAssetPool is AssetPool {
  function _processDepositTransfer(uint256 amount) internal override {
    require(msg.value == amount, "insufficient token");
  }

  function _processWithdrawTransfer(address recipient, uint256 amount) internal override {
    require(msg.value == 0, "no mainnet token allowed");
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "withdraw failed");
  }

  function assetType() public view override returns (string memory) {
    return "main";
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

abstract contract AssetPool {
  function _processDepositTransfer(uint256 amount) internal virtual;

  function _processWithdrawTransfer(address recipient, uint256 amount) internal virtual;

  function assetType() public view virtual returns (string memory);
}

// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

interface IHasher {
  function MiMCSponge(
    uint256 in_xL,
    uint256 in_xR,
    uint256 k
  ) external pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE =
    21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE
  IHasher public immutable hasher;

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code

  // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
  // it removes index range check on every interaction
  mapping(uint256 => bytes32) public filledSubtrees;
  mapping(uint256 => bytes32) public roots;
  uint32 public constant ROOT_HISTORY_SIZE = 30;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;

  constructor(uint32 _levels, address _hasher) public {
    require(_levels > 0, "_levels should be greater than zero");
    require(_levels < 32, "_levels should be less than 32");
    levels = _levels;
    hasher = IHasher(_hasher);

    for (uint32 i = 0; i < _levels; i++) {
      filledSubtrees[i] = zeros(i);
    }

    roots[0] = zeros(_levels - 1);
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(
    IHasher _hasher,
    bytes32 _left,
    bytes32 _right
  ) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    (R, C) = _hasher.MiMCSponge(R, C, 0);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = _hasher.MiMCSponge(R, C, 0);
    return bytes32(R);
  }

  function getLevels() public view returns (uint32) {
    return levels;
  }

  function _insert(bytes32 _leaf) internal returns (uint32 index) {
    uint32 _nextIndex = nextIndex;
    require(_nextIndex != uint32(2)**levels, "Merkle tree is full. No more leaves can be added");
    uint32 currentIndex = _nextIndex;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros(i);
        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }
      currentLevelHash = hashLeftRight(hasher, left, right);
      currentIndex /= 2;
    }

    uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    currentRootIndex = newRootIndex;
    roots[newRootIndex] = currentLevelHash;
    nextIndex = _nextIndex + 1;
    return _nextIndex;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns (bool) {
    if (_root == 0) {
      return false;
    }
    uint32 _currentRootIndex = currentRootIndex;
    uint32 i = _currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != _currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns (bytes32) {
    return roots[currentRootIndex];
  }

  /// @dev provides Zero (Empty) elements for a MiMC MerkleTree. Up to 32 levels
  function zeros(uint256 i) public pure returns (bytes32) {
    if (i == 0) return bytes32(0x2fe54c60d3acabf3343a35b6eba15db4821b340f76e741e2249685ed4899af6c);
    else if (i == 1) return bytes32(0x256a6135777eee2fd26f54b8b7037a25439d5235caee224154186d2b8a52e31d);
    else if (i == 2) return bytes32(0x1151949895e82ab19924de92c40a3d6f7bcb60d92b00504b8199613683f0c200);
    else if (i == 3) return bytes32(0x20121ee811489ff8d61f09fb89e313f14959a0f28bb428a20dba6b0b068b3bdb);
    else if (i == 4) return bytes32(0x0a89ca6ffa14cc462cfedb842c30ed221a50a3d6bf022a6a57dc82ab24c157c9);
    else if (i == 5) return bytes32(0x24ca05c2b5cd42e890d6be94c68d0689f4f21c9cec9c0f13fe41d566dfb54959);
    else if (i == 6) return bytes32(0x1ccb97c932565a92c60156bdba2d08f3bf1377464e025cee765679e604a7315c);
    else if (i == 7) return bytes32(0x19156fbd7d1a8bf5cba8909367de1b624534ebab4f0f79e003bccdd1b182bdb4);
    else if (i == 8) return bytes32(0x261af8c1f0912e465744641409f622d466c3920ac6e5ff37e36604cb11dfff80);
    else if (i == 9) return bytes32(0x0058459724ff6ca5a1652fcbc3e82b93895cf08e975b19beab3f54c217d1c007);
    else if (i == 10) return bytes32(0x1f04ef20dee48d39984d8eabe768a70eafa6310ad20849d4573c3c40c2ad1e30);
    else if (i == 11) return bytes32(0x1bea3dec5dab51567ce7e200a30f7ba6d4276aeaa53e2686f962a46c66d511e5);
    else if (i == 12) return bytes32(0x0ee0f941e2da4b9e31c3ca97a40d8fa9ce68d97c084177071b3cb46cd3372f0f);
    else if (i == 13) return bytes32(0x1ca9503e8935884501bbaf20be14eb4c46b89772c97b96e3b2ebf3a36a948bbd);
    else if (i == 14) return bytes32(0x133a80e30697cd55d8f7d4b0965b7be24057ba5dc3da898ee2187232446cb108);
    else if (i == 15) return bytes32(0x13e6d8fc88839ed76e182c2a779af5b2c0da9dd18c90427a644f7e148a6253b6);
    else if (i == 16) return bytes32(0x1eb16b057a477f4bc8f572ea6bee39561098f78f15bfb3699dcbb7bd8db61854);
    else if (i == 17) return bytes32(0x0da2cb16a1ceaabf1c16b838f7a9e3f2a3a3088d9e0a6debaa748114620696ea);
    else if (i == 18) return bytes32(0x24a3b3d822420b14b5d8cb6c28a574f01e98ea9e940551d2ebd75cee12649f9d);
    else if (i == 19) return bytes32(0x198622acbd783d1b0d9064105b1fc8e4d8889de95c4c519b3f635809fe6afc05);
    else if (i == 20) return bytes32(0x29d7ed391256ccc3ea596c86e933b89ff339d25ea8ddced975ae2fe30b5296d4);
    else if (i == 21) return bytes32(0x19be59f2f0413ce78c0c3703a3a5451b1d7f39629fa33abd11548a76065b2967);
    else if (i == 22) return bytes32(0x1ff3f61797e538b70e619310d33f2a063e7eb59104e112e95738da1254dc3453);
    else if (i == 23) return bytes32(0x10c16ae9959cf8358980d9dd9616e48228737310a10e2b6b731c1a548f036c48);
    else if (i == 24) return bytes32(0x0ba433a63174a90ac20992e75e3095496812b652685b5e1a2eae0b1bf4e8fcd1);
    else if (i == 25) return bytes32(0x019ddb9df2bc98d987d0dfeca9d2b643deafab8f7036562e627c3667266a044c);
    else if (i == 26) return bytes32(0x2d3c88b23175c5a5565db928414c66d1912b11acf974b2e644caaac04739ce99);
    else if (i == 27) return bytes32(0x2eab55f6ae4e66e32c5189eed5c470840863445760f5ed7e7b69b2a62600f354);
    else if (i == 28) return bytes32(0x002df37a2642621802383cf952bf4dd1f32e05433beeb1fd41031fb7eace979d);
    else if (i == 29) return bytes32(0x104aeb41435db66c3e62feccc1d6f5d98d0a0ed75d1374db457cf462e3a1f427);
    else if (i == 30) return bytes32(0x1f3c6fd858e9a7d4b0d1f38e256a09d81d5a5e3c963987e2d4b814cfab7c6ebb);
    else if (i == 31) return bytes32(0x2c7a07d20dff79d01fecedc1134284a8d08436606c93693b67e333f671bf69cc);
    else revert("Index out of bounds");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

library Utils {
  /* @notice      Convert the bytes array to bytes32 type, the bytes array length must be 32
   *  @param _bs   Source bytes array
   *  @return      bytes32
   */
  function bytesToBytes32(bytes memory _bs) internal pure returns (bytes32 value) {
    require(_bs.length == 32, "bytes length is not 32.");
    assembly {
      // load 32 bytes from memory starting from position _bs + 0x20 since the first 0x20 bytes stores _bs length
      value := mload(add(_bs, 0x20))
    }
  }

  /* @notice      Convert bytes to uint256
   *  @param _b    Source bytes should have length of 32
   *  @return      uint256
   */
  function bytesToUint256(bytes memory _bs) internal pure returns (uint256 value) {
    require(_bs.length == 32, "bytes length is not 32.");
    assembly {
      // load 32 bytes from memory starting from position _bs + 32
      value := mload(add(_bs, 0x20))
    }
    require(
      value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
      "Value exceeds the range"
    );
  }

  /* @notice      Convert uint256 to bytes
   *  @param _b    uint256 that needs to be converted
   *  @return      bytes
   */
  function uint256ToBytes(uint256 _value) internal pure returns (bytes memory bs) {
    require(
      _value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
      "Value exceeds the range"
    );
    assembly {
      // Get a location of some free memory and store it in result as
      // Solidity does for memory variables.
      bs := mload(0x40)
      // Put 0x20 at the first word, the length of bytes for uint256 value
      mstore(bs, 0x20)
      //In the next word, put value in bytes format to the next 32 bytes
      mstore(add(bs, 0x20), _value)
      // Update the free-memory pointer by padding our last write location to 32 bytes
      mstore(0x40, add(bs, 0x40))
    }
  }

  /* @notice      Convert bytes to address
   *  @param _bs   Source bytes: bytes length must be 20
   *  @return      Converted address from source bytes
   */
  function bytesToAddress(bytes memory _bs) internal pure returns (address addr) {
    require(_bs.length == 20, "bytes length does not match address");
    assembly {
      // for _bs, first word store _bs.length, second word store _bs.value
      // load 32 bytes from mem[_bs+20], convert it into Uint160, meaning we take last 20 bytes as addr (address).
      addr := mload(add(_bs, 0x14))
    }
  }

  /* @notice      Convert address to bytes
   *  @param _addr Address need to be converted
   *  @return      Converted bytes from address
   */
  function addressToBytes(address _addr) internal pure returns (bytes memory bs) {
    assembly {
      // Get a location of some free memory and store it in result as
      // Solidity does for memory variables.
      bs := mload(0x40)
      // Put 20 (address byte length) at the first word, the length of bytes for uint256 value
      mstore(bs, 0x14)
      // logical shift left _a by 12 bytes, change _a from right-aligned to left-aligned
      mstore(add(bs, 0x20), shl(96, _addr))
      // Update the free-memory pointer by padding our last write location to 32 bytes
      mstore(0x40, add(bs, 0x40))
    }
  }

  /* @notice          Do hash leaf as the multi-chain does
   *  @param _data     Data in bytes format
   *  @return          Hashed value in bytes32 format
   */
  function hashLeaf(bytes memory _data) internal pure returns (bytes32 result) {
    result = sha256(abi.encodePacked(bytes1(0x0), _data));
  }

  /* @notice          Do hash children as the multi-chain does
   *  @param _l        Left node
   *  @param _r        Right node
   *  @return          Hashed value in bytes32 format
   */
  function hashChildren(bytes32 _l, bytes32 _r) internal pure returns (bytes32 result) {
    result = sha256(abi.encodePacked(bytes1(0x01), _l, _r));
  }

  /* @notice              Compare if two bytes are equal, which are in storage and memory, seperately
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L368
    *  @param _preBytes     The bytes stored in storage
    *  @param _postBytes    The bytes stored in memory
    *  @return              Bool type indicating if they are equal
    */
  function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
    bool success = true;

    assembly {
      // we know _preBytes_offset is 0
      let fslot := sload(_preBytes_slot)
      // Arrays of 31 bytes or less have an even value in their slot,
      // while longer arrays have an odd value. The actual length is
      // the slot divided by two for odd values, and the lowest order
      // byte divided by two for even values.
      // If the slot is even, bitwise and the slot with 255 and divide by
      // two to get the length. If the slot is odd, bitwise and the slot
      // with -1 and divide by two.
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)

      // if lengths don't match the arrays are not equal
      switch eq(slength, mlength)
      case 1 {
        // fslot can contain both the length and contents of the array
        // if slength < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
        // slength != 0
        if iszero(iszero(slength)) {
          switch lt(slength, 32)
          case 1 {
            // blank the last byte which is the length
            fslot := mul(div(fslot, 0x100), 0x100)

            if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
              // unsuccess:
              success := 0
            }
          }
          default {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
            let cb := 1

            // get the keccak hash to get the contents of the array
            mstore(0x0, _preBytes_slot)
            let sc := keccak256(0x0, 0x20)

            let mc := add(_postBytes, 0x20)
            let end := add(mc, mlength)

            // the next line is the loop condition:
            // while(uint(mc < end) + cb == 2)
            for {

            } eq(add(lt(mc, end), cb), 2) {
              sc := add(sc, 1)
              mc := add(mc, 0x20)
            } {
              if iszero(eq(sload(sc), mload(mc))) {
                // unsuccess:
                success := 0
                cb := 0
              }
            }
          }
        }
      }
      default {
        // unsuccess:
        success := 0
      }
    }

    return success;
  }

  /* @notice              Slice the _bytes from _start index till the result has length of _length
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L246
    *  @param _bytes        The original bytes needs to be sliced
    *  @param _start        The index of _bytes for the start of sliced bytes
    *  @param _length       The index of _bytes for the end of sliced bytes
    *  @return              The sliced bytes
    */
  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    require(_bytes.length >= (_start + _length));

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        // lengthmod <= _length % 32
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  /* @notice              Check if the elements number of _signers within _keepers array is no less than _m
   *  @param _keepers      The array consists of serveral address
   *  @param _signers      Some specific addresses to be looked into
   *  @param _m            The number requirement paramter
   *  @return              True means containment, false meansdo do not contain.
   */
  function containMAddresses(
    address[] memory _keepers,
    address[] memory _signers,
    uint256 _m
  ) internal pure returns (bool) {
    uint256 m = 0;
    for (uint256 i = 0; i < _signers.length; i++) {
      for (uint256 j = 0; j < _keepers.length; j++) {
        if (_signers[i] == _keepers[j]) {
          m++;
          delete _keepers[j];
        }
      }
    }
    return m >= _m;
  }

  /* @notice              TODO
   *  @param key
   *  @return
   */
  function compressMCPubKey(bytes memory key) internal pure returns (bytes memory newkey) {
    require(key.length >= 67, "key lenggh is too short");
    newkey = slice(key, 0, 35);
    if (uint8(key[66]) % 2 == 0) {
      newkey[2] = bytes1(0x02);
    } else {
      newkey[2] = bytes1(0x03);
    }
    return newkey;
  }

  /**
   * @dev Returns true if `account` is a contract.
   *      Refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L18
   *
   * This test is non-exhaustive, and there may be false-negatives: during the
   * execution of a contract's constructor, its address will be reported as
   * not containing a contract.
   *
   * IMPORTANT: It is unsafe to assume that an address for which this
   * function returns false is an externally-owned account (EOA) and not a
   * contract.
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != 0x0 && codehash != accountHash);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

/**
 * @dev Wrappers over decoding and deserialization operation from bytes into bassic types in Solidity for PolyNetwork cross chain utility.
 *
 * Decode into basic types in Solidity from bytes easily. It's designed to be used
 * for PolyNetwork cross chain application, and the decoding rules on Ethereum chain
 * and the encoding rule on other chains should be consistent, and . Here we
 * follow the underlying deserialization rule with implementation found here:
 * https://github.com/polynetwork/poly/blob/master/common/zero_copy_source.go
 *
 * Using this library instead of the unchecked serialization method can help reduce
 * the risk of serious bugs and handfule, so it's recommended to use it.
 *
 * Please note that risk can be minimized, yet not eliminated.
 */
library ZeroCopySource {
  /* @notice              Read next byte as boolean type starting at offset from buff
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the boolean value
   *  @return              The the read boolean value and new offset
   */
  function NextBool(bytes memory buff, uint256 offset) internal pure returns (bool, uint256) {
    require(offset + 1 <= buff.length && offset < offset + 1, "Offset exceeds limit");
    // byte === bytes1
    bytes1 v;
    assembly {
      v := mload(add(add(buff, 0x20), offset))
    }
    bool value;
    if (v == 0x01) {
      value = true;
    } else if (v == 0x00) {
      value = false;
    } else {
      revert("NextBool value error");
    }
    return (value, offset + 1);
  }

  /* @notice              Read next byte starting at offset from buff
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the byte value
   *  @return              The read byte value and new offset
   */
  function NextByte(bytes memory buff, uint256 offset) internal pure returns (bytes1, uint256) {
    require(offset + 1 <= buff.length && offset < offset + 1, "NextByte, Offset exceeds maximum");
    bytes1 v;
    assembly {
      v := mload(add(add(buff, 0x20), offset))
    }
    return (v, offset + 1);
  }

  /* @notice              Read next byte as uint8 starting at offset from buff
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the byte value
   *  @return              The read uint8 value and new offset
   */
  function NextUint8(bytes memory buff, uint256 offset) internal pure returns (uint8, uint256) {
    require(offset + 1 <= buff.length && offset < offset + 1, "NextUint8, Offset exceeds maximum");
    uint8 v;
    assembly {
      let tmpbytes := mload(0x40)
      let bvalue := mload(add(add(buff, 0x20), offset))
      mstore8(tmpbytes, byte(0, bvalue))
      mstore(0x40, add(tmpbytes, 0x01))
      v := mload(sub(tmpbytes, 0x1f))
    }
    return (v, offset + 1);
  }

  /* @notice              Read next two bytes as uint16 type starting from offset
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the uint16 value
   *  @return              The read uint16 value and updated offset
   */
  function NextUint16(bytes memory buff, uint256 offset) internal pure returns (uint16, uint256) {
    require(offset + 2 <= buff.length && offset < offset + 2, "NextUint16, offset exceeds maximum");

    uint16 v;
    assembly {
      let tmpbytes := mload(0x40)
      let bvalue := mload(add(add(buff, 0x20), offset))
      mstore8(tmpbytes, byte(0x01, bvalue))
      mstore8(add(tmpbytes, 0x01), byte(0, bvalue))
      mstore(0x40, add(tmpbytes, 0x02))
      v := mload(sub(tmpbytes, 0x1e))
    }
    return (v, offset + 2);
  }

  /* @notice              Read next four bytes as uint32 type starting from offset
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the uint32 value
   *  @return              The read uint32 value and updated offset
   */
  function NextUint32(bytes memory buff, uint256 offset) internal pure returns (uint32, uint256) {
    require(offset + 4 <= buff.length && offset < offset + 4, "NextUint32, offset exceeds maximum");
    uint32 v;
    assembly {
      let tmpbytes := mload(0x40)
      let byteLen := 0x04
      for {
        let tindex := 0x00
        let bindex := sub(byteLen, 0x01)
        let bvalue := mload(add(add(buff, 0x20), offset))
      } lt(tindex, byteLen) {
        tindex := add(tindex, 0x01)
        bindex := sub(bindex, 0x01)
      } {
        mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
      }
      mstore(0x40, add(tmpbytes, byteLen))
      v := mload(sub(tmpbytes, sub(0x20, byteLen)))
    }
    return (v, offset + 4);
  }

  /* @notice              Read next eight bytes as uint64 type starting from offset
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the uint64 value
   *  @return              The read uint64 value and updated offset
   */
  function NextUint64(bytes memory buff, uint256 offset) internal pure returns (uint64, uint256) {
    require(offset + 8 <= buff.length && offset < offset + 8, "NextUint64, offset exceeds maximum");
    uint64 v;
    assembly {
      let tmpbytes := mload(0x40)
      let byteLen := 0x08
      for {
        let tindex := 0x00
        let bindex := sub(byteLen, 0x01)
        let bvalue := mload(add(add(buff, 0x20), offset))
      } lt(tindex, byteLen) {
        tindex := add(tindex, 0x01)
        bindex := sub(bindex, 0x01)
      } {
        mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
      }
      mstore(0x40, add(tmpbytes, byteLen))
      v := mload(sub(tmpbytes, sub(0x20, byteLen)))
    }
    return (v, offset + 8);
  }

  /* @notice              Read next 32 bytes as uint256 type starting from offset,
                            there are limits considering the numerical limits in multi-chain
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the uint256 value
    *  @return              The read uint256 value and updated offset
    */
  function NextUint255(bytes memory buff, uint256 offset) internal pure returns (uint256, uint256) {
    require(offset + 32 <= buff.length && offset < offset + 32, "NextUint255, offset exceeds maximum");
    uint256 v;
    assembly {
      let tmpbytes := mload(0x40)
      let byteLen := 0x20
      for {
        let tindex := 0x00
        let bindex := sub(byteLen, 0x01)
        let bvalue := mload(add(add(buff, 0x20), offset))
      } lt(tindex, byteLen) {
        tindex := add(tindex, 0x01)
        bindex := sub(bindex, 0x01)
      } {
        mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
      }
      mstore(0x40, add(tmpbytes, byteLen))
      v := mload(tmpbytes)
    }
    require(
      v <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
      "Value exceeds the range"
    );
    return (v, offset + 32);
  }

  /* @notice              Read next variable bytes starting from offset,
                            the decoding rule coming from multi-chain
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the bytes value
    *  @return              The read variable bytes array value and updated offset
    */
  function NextVarBytes(bytes memory buff, uint256 offset) internal pure returns (bytes memory, uint256) {
    uint256 len;
    (len, offset) = NextVarUint(buff, offset);
    require(offset + len <= buff.length && offset < offset + len, "NextVarBytes, offset exceeds maximum");
    bytes memory tempBytes;
    assembly {
      switch iszero(len)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(len, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, len)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(buff, lengthmod), mul(0x20, iszero(lengthmod))), offset)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, len)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return (tempBytes, offset + len);
  }

  /* @notice              Read next 32 bytes starting from offset,
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the bytes value
   *  @return              The read bytes32 value and updated offset
   */
  function NextHash(bytes memory buff, uint256 offset) internal pure returns (bytes32, uint256) {
    require(offset + 32 <= buff.length && offset < offset + 32, "NextHash, offset exceeds maximum");
    bytes32 v;
    assembly {
      v := mload(add(buff, add(offset, 0x20)))
    }
    return (v, offset + 32);
  }

  /* @notice              Read next 20 bytes starting from offset,
   *  @param buff          Source bytes array
   *  @param offset        The position from where we read the bytes value
   *  @return              The read bytes20 value and updated offset
   */
  function NextBytes20(bytes memory buff, uint256 offset) internal pure returns (bytes20, uint256) {
    require(offset + 20 <= buff.length && offset < offset + 20, "NextBytes20, offset exceeds maximum");
    bytes20 v;
    assembly {
      v := mload(add(buff, add(offset, 0x20)))
    }
    return (v, offset + 20);
  }

  function NextVarUint(bytes memory buff, uint256 offset) internal pure returns (uint256, uint256) {
    bytes1 v;
    (v, offset) = NextByte(buff, offset);

    uint256 value;
    if (v == 0xFD) {
      // return NextUint16(buff, offset);
      (value, offset) = NextUint16(buff, offset);
      require(value >= 0xFD && value <= 0xFFFF, "NextUint16, value outside range");
      return (value, offset);
    } else if (v == 0xFE) {
      // return NextUint32(buff, offset);
      (value, offset) = NextUint32(buff, offset);
      require(value > 0xFFFF && value <= 0xFFFFFFFF, "NextVarUint, value outside range");
      return (value, offset);
    } else if (v == 0xFF) {
      // return NextUint64(buff, offset);
      (value, offset) = NextUint64(buff, offset);
      require(value > 0xFFFFFFFF, "NextVarUint, value outside range");
      return (value, offset);
    } else {
      // return (uint8(v), offset);
      value = uint8(v);
      require(value < 0xFD, "NextVarUint, value outside range");
      return (value, offset);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

/**
 * @dev Wrappers over encoding and serialization operation into bytes from bassic types in Solidity for PolyNetwork cross chain utility.
 *
 * Encode basic types in Solidity into bytes easily. It's designed to be used
 * for PolyNetwork cross chain application, and the encoding rules on Ethereum chain
 * and the decoding rules on other chains should be consistent. Here we
 * follow the underlying serialization rule with implementation found here:
 * https://github.com/polynetwork/poly/blob/master/common/zero_copy_sink.go
 *
 * Using this library instead of the unchecked serialization method can help reduce
 * the risk of serious bugs and handfule, so it's recommended to use it.
 *
 * Please note that risk can be minimized, yet not eliminated.
 */
library ZeroCopySink {
  /* @notice          Convert boolean value into bytes
   *  @param b         The boolean value
   *  @return          Converted bytes array
   */
  function WriteBool(bool b) internal pure returns (bytes memory) {
    bytes memory buff;
    assembly {
      buff := mload(0x40)
      mstore(buff, 1)
      switch iszero(b)
      case 1 {
        mstore(add(buff, 0x20), shl(248, 0x00))
        // mstore8(add(buff, 0x20), 0x00)
      }
      default {
        mstore(add(buff, 0x20), shl(248, 0x01))
        // mstore8(add(buff, 0x20), 0x01)
      }
      mstore(0x40, add(buff, 0x21))
    }
    return buff;
  }

  /* @notice          Convert byte value into bytes
   *  @param b         The byte value
   *  @return          Converted bytes array
   */
  function WriteByte(bytes1 b) internal pure returns (bytes memory) {
    return WriteUint8(uint8(b));
  }

  /* @notice          Convert uint8 value into bytes
   *  @param v         The uint8 value
   *  @return          Converted bytes array
   */
  function WriteUint8(uint8 v) internal pure returns (bytes memory) {
    bytes memory buff;
    assembly {
      buff := mload(0x40)
      mstore(buff, 1)
      mstore(add(buff, 0x20), shl(248, v))
      // mstore(add(buff, 0x20), byte(0x1f, v))
      mstore(0x40, add(buff, 0x21))
    }
    return buff;
  }

  /* @notice          Convert uint16 value into bytes
   *  @param v         The uint16 value
   *  @return          Converted bytes array
   */
  function WriteUint16(uint16 v) internal pure returns (bytes memory) {
    bytes memory buff;

    assembly {
      buff := mload(0x40)
      let byteLen := 0x02
      mstore(buff, byteLen)
      for {
        let mindex := 0x00
        let vindex := 0x1f
      } lt(mindex, byteLen) {
        mindex := add(mindex, 0x01)
        vindex := sub(vindex, 0x01)
      } {
        mstore8(add(add(buff, 0x20), mindex), byte(vindex, v))
      }
      mstore(0x40, add(buff, 0x22))
    }
    return buff;
  }

  /* @notice          Convert uint32 value into bytes
   *  @param v         The uint32 value
   *  @return          Converted bytes array
   */
  function WriteUint32(uint32 v) internal pure returns (bytes memory) {
    bytes memory buff;
    assembly {
      buff := mload(0x40)
      let byteLen := 0x04
      mstore(buff, byteLen)
      for {
        let mindex := 0x00
        let vindex := 0x1f
      } lt(mindex, byteLen) {
        mindex := add(mindex, 0x01)
        vindex := sub(vindex, 0x01)
      } {
        mstore8(add(add(buff, 0x20), mindex), byte(vindex, v))
      }
      mstore(0x40, add(buff, 0x24))
    }
    return buff;
  }

  /* @notice          Convert uint64 value into bytes
   *  @param v         The uint64 value
   *  @return          Converted bytes array
   */
  function WriteUint64(uint64 v) internal pure returns (bytes memory) {
    bytes memory buff;

    assembly {
      buff := mload(0x40)
      let byteLen := 0x08
      mstore(buff, byteLen)
      for {
        let mindex := 0x00
        let vindex := 0x1f
      } lt(mindex, byteLen) {
        mindex := add(mindex, 0x01)
        vindex := sub(vindex, 0x01)
      } {
        mstore8(add(add(buff, 0x20), mindex), byte(vindex, v))
      }
      mstore(0x40, add(buff, 0x28))
    }
    return buff;
  }

  /* @notice          Convert limited uint256 value into bytes
   *  @param v         The uint256 value
   *  @return          Converted bytes array
   */
  function WriteUint255(uint256 v) internal pure returns (bytes memory) {
    require(
      v <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
      "Value exceeds uint255 range"
    );
    bytes memory buff;

    assembly {
      buff := mload(0x40)
      let byteLen := 0x20
      mstore(buff, byteLen)
      for {
        let mindex := 0x00
        let vindex := 0x1f
      } lt(mindex, byteLen) {
        mindex := add(mindex, 0x01)
        vindex := sub(vindex, 0x01)
      } {
        mstore8(add(add(buff, 0x20), mindex), byte(vindex, v))
      }
      mstore(0x40, add(buff, 0x40))
    }
    return buff;
  }

  /* @notice          Encode bytes format data into bytes
   *  @param data      The bytes array data
   *  @return          Encoded bytes array
   */
  function WriteVarBytes(bytes memory data) internal pure returns (bytes memory) {
    uint64 l = uint64(data.length);
    return abi.encodePacked(WriteVarUint(l), data);
  }

  function WriteVarUint(uint64 v) internal pure returns (bytes memory) {
    if (v < 0xFD) {
      return WriteUint8(uint8(v));
    } else if (v <= 0xFFFF) {
      return abi.encodePacked(WriteByte(0xFD), WriteUint16(uint16(v)));
    } else if (v <= 0xFFFFFFFF) {
      return abi.encodePacked(WriteByte(0xFE), WriteUint32(uint32(v)));
    } else {
      return abi.encodePacked(WriteByte(0xFF), WriteUint64(uint64(v)));
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.11;

/**
 * @dev Interface of the EthCrossChainManagerProxy for business contract like LockProxy to obtain the reliable EthCrossChainManager contract hash.
 */
interface IEthCrossChainManagerProxy {
  function getEthCrossChainManager() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.11;

/**
 * @dev Interface of the EthCrossChainManager contract for business contract like LockProxy to request cross chain transaction
 */
interface IEthCrossChainManager {
  function crossChain(
    uint64 _toChainId,
    bytes calldata _toContract,
    bytes calldata _method,
    bytes calldata _txData
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "../../Mystiko.sol";
import "./cross_chain_manager/interface/IEthCrossChainManager.sol";
import "./cross_chain_manager/interface/IEthCrossChainManagerProxy.sol";
import "../../libs/common/ZeroCopySink.sol";
import "../../libs/common/ZeroCopySource.sol";
import "../../libs/utils/Utils.sol";

abstract contract MystikoWithPoly is Mystiko {
  IEthCrossChainManagerProxy public eccmp;
  uint64 public peerChainId;
  address public peerContractAddress;

  struct CrossChainData {
    uint256 amount;
    bytes32 commitmentHash;
  }

  constructor(
    address _eccmp,
    uint64 _peerChainId,
    address _verifier,
    address _hasher,
    uint32 _merkleTreeHeight
  ) public Mystiko(_verifier, _hasher, _merkleTreeHeight) {
    eccmp = IEthCrossChainManagerProxy(_eccmp);
    peerChainId = _peerChainId;
    peerContractAddress = address(0);
  }

  modifier onlyManagerContract() {
    require(msg.sender == eccmp.getEthCrossChainManager(), "msgSender is not EthCrossChainManagerContract");
    _;
  }

  function syncTx(
    bytes memory txDataBytes,
    bytes memory fromContractAddr,
    uint64 fromChainId
  ) public onlyManagerContract returns (bool) {
    CrossChainData memory txData = _deserializeTxData(txDataBytes);
    require(fromContractAddr.length != 0, "from proxy contract address cannot be empty");
    require(Utils.bytesToAddress(fromContractAddr) == peerContractAddress, "from proxy address not matched");
    require(fromChainId == peerChainId, "from chain id not matched");
    require(txData.amount > 0, "amount shouuld be greater than 0");
    uint32 leafIndex = _insert(txData.commitmentHash);
    emit MerkleTreeInsert(txData.commitmentHash, leafIndex, txData.amount);
    return true;
  }

  function _processCrossChain(uint256 amount, bytes32 commitmentHash) internal override {
    CrossChainData memory txData = CrossChainData({amount: amount, commitmentHash: commitmentHash});
    bytes memory txDataBytes = _serializeTxData(txData);
    IEthCrossChainManager eccm = IEthCrossChainManager(eccmp.getEthCrossChainManager());
    require(
      eccm.crossChain(peerChainId, Utils.addressToBytes(peerContractAddress), "syncTx", txDataBytes),
      "eccm returns error"
    );
  }

  function bridgeType() public view override returns (string memory) {
    return "poly";
  }

  function _serializeTxData(CrossChainData memory data) internal pure returns (bytes memory) {
    bytes memory buff;
    buff = abi.encodePacked(
      ZeroCopySink.WriteUint255(data.amount),
      ZeroCopySink.WriteVarBytes(abi.encodePacked(data.commitmentHash))
    );
    return buff;
  }

  function _deserializeTxData(bytes memory rawData) internal pure returns (CrossChainData memory) {
    CrossChainData memory data;
    uint256 off = 0;
    (data.amount, off) = ZeroCopySource.NextUint255(rawData, off);
    bytes memory tempBytes;
    (tempBytes, off) = ZeroCopySource.NextVarBytes(rawData, off);
    data.commitmentHash = Utils.bytesToBytes32(tempBytes);
    return data;
  }

  function setECCMProxy(address _eccmp) external onlyOperator {
    eccmp = IEthCrossChainManagerProxy(_eccmp);
  }

  function setPeerContractAddress(address _peerContractAddress) external onlyOperator {
    peerContractAddress = _peerContractAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "./merkle/MerkleTreeWithHistory.sol";
import "./pool/AssetPool.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVerifier {
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[3] memory input
  ) external returns (bool);
}

abstract contract Mystiko is MerkleTreeWithHistory, AssetPool, ReentrancyGuard {
  IVerifier public verifier;
  mapping(bytes32 => bool) public depositedCommitments;
  mapping(uint256 => bool) public withdrewSerialNumbers;

  address public operator;
  bool public isDepositsDisabled;
  bool public isVerifierUpdateDisabled;

  modifier onlyOperator() {
    require(msg.sender == operator, "Only operator can call this function.");
    _;
  }

  event Deposit(uint256 amount, bytes32 indexed commitmentHash, bytes encryptedNote);
  event MerkleTreeInsert(bytes32 indexed leaf, uint32 leafIndex, uint256 amount);
  event Withdraw(address recipient, uint256 indexed rootHash, uint256 indexed serialNumber);

  constructor(
    address _verifier,
    address _hasher,
    uint32 _merkleTreeHeight
  ) public MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
    verifier = IVerifier(_verifier);
    operator = msg.sender;
  }

  function deposit(
    uint256 amount,
    bytes32 commitmentHash,
    bytes32 hashK,
    bytes32 randomS,
    bytes memory encryptedNote
  ) public payable {
    require(!isDepositsDisabled, "deposits are disabled");
    require(!depositedCommitments[commitmentHash], "The commitment has been submitted");
    bytes32 cHash = hashLeftRight(hasher, hashK, bytes32(amount));
    cHash = hashLeftRight(hasher, cHash, randomS);
    require(cHash == commitmentHash, "commitment hash incorrect");
    _processDepositTransfer(amount);
    depositedCommitments[commitmentHash] = true;
    _processCrossChain(amount, commitmentHash);
    emit Deposit(amount, commitmentHash, encryptedNote);
  }

  function withdraw(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256 rootHash,
    uint256 serialNumber,
    uint256 amount,
    address recipient
  ) public payable nonReentrant {
    require(!withdrewSerialNumbers[serialNumber], "The note has been already spent");
    require(isKnownRoot(bytes32(rootHash)), "Cannot find your merkle root");
    require(verifier.verifyProof(a, b, c, [rootHash, serialNumber, amount]), "Invalid withdraw proof");
    withdrewSerialNumbers[serialNumber] = true;
    _processWithdrawTransfer(recipient, amount);
    emit Withdraw(recipient, rootHash, serialNumber);
  }

  function _processCrossChain(uint256 amount, bytes32 commitmentHash) internal virtual;

  function bridgeType() public view virtual returns (string memory);

  function isSpent(uint256 serialNumber) public view returns (bool) {
    return withdrewSerialNumbers[serialNumber];
  }

  function getVerifierAddress() public view returns (address) {
    return address(verifier);
  }

  function getHasherAddress() public view returns (address) {
    return address(hasher);
  }

  function toggleDeposits(bool _state) external onlyOperator {
    isDepositsDisabled = _state;
  }

  function updateVerifier(address _newVerifier) external onlyOperator {
    require(!isVerifierUpdateDisabled, "Verifier updates have been disabled.");
    verifier = IVerifier(_newVerifier);
  }

  function disableVerifierUpdate() external onlyOperator {
    isVerifierUpdateDisabled = true;
  }

  function changeOperator(address _newOperator) external onlyOperator {
    operator = _newOperator;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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