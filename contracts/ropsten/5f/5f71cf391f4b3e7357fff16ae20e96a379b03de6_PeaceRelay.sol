pragma solidity ^0.4.24;

// File: contracts/RLP.sol

/**
* @title RLPReader
*
* RLPReader is used to read and parse RLP encoded data in memory.
*
* @author Andreas Olofsson (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7918171d0b16151648404149391e14181015571a1614">[email&#160;protected]</a>)
*
* code was taken from https://github.com/androlo/standard-contracts/blob/master/contracts/src/codec/RLP.sol
*
*/
library RLP {

 uint constant DATA_SHORT_START = 0x80;
 uint constant DATA_LONG_START = 0xB8;
 uint constant LIST_SHORT_START = 0xC0;
 uint constant LIST_LONG_START = 0xF8;

 uint constant DATA_LONG_OFFSET = 0xB7;
 uint constant LIST_LONG_OFFSET = 0xF7;


 struct RLPItem {
     uint _unsafe_memPtr;    // Pointer to the RLP-encoded bytes.
     uint _unsafe_length;    // Number of bytes. This is the full length of the string.
 }

 struct Iterator {
     RLPItem _unsafe_item;   // Item that&#39;s being iterated over.
     uint _unsafe_nextPtr;   // Position of the next item in the list.
 }

 /* Iterator */

 function next(Iterator memory self) internal constant returns (RLPItem memory subItem) {
     if(hasNext(self)) {
         var ptr = self._unsafe_nextPtr;
         var itemLength = _itemLength(ptr);
         subItem._unsafe_memPtr = ptr;
         subItem._unsafe_length = itemLength;
         self._unsafe_nextPtr = ptr + itemLength;
     }
     else
         revert();
 }

 function next(Iterator memory self, bool strict) internal constant returns (RLPItem memory subItem) {
     subItem = next(self);
     if(strict && !_validate(subItem))
         revert();
     return;
 }

 function hasNext(Iterator memory self) internal constant returns (bool) {
     var item = self._unsafe_item;
     return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
 }

 /* RLPItem */

 /// @dev Creates an RLPItem from an array of RLP encoded bytes.
 /// @param self The RLP encoded bytes.
 /// @return An RLPItem
 function toRLPItem(bytes memory self) internal constant returns (RLPItem memory) {
     uint len = self.length;
     if (len == 0) {
         return RLPItem(0, 0);
     }
     uint memPtr;
     assembly {
         memPtr := add(self, 0x20)
     }
     return RLPItem(memPtr, len);
 }

 /// @dev Creates an RLPItem from an array of RLP encoded bytes.
 /// @param self The RLP encoded bytes.
 /// @param strict Will revert if the data is not RLP encoded.
 /// @return An RLPItem
 function toRLPItem(bytes memory self, bool strict) internal constant returns (RLPItem memory) {
     var item = toRLPItem(self);
     if(strict) {
         uint len = self.length;
         if(_payloadOffset(item) > len)
             revert();
         if(_itemLength(item._unsafe_memPtr) != len)
             revert();
         if(!_validate(item))
             revert();
     }
     return item;
 }

 /// @dev Check if the RLP item is null.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is null.
 function isNull(RLPItem memory self) internal pure returns (bool ret) {
     return self._unsafe_length == 0;
 }

 /// @dev Check if the RLP item is a list.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is a list.
 function isList(RLPItem memory self) internal pure returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
     }
 }

 /// @dev Check if the RLP item is data.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is data.
 function isData(RLPItem memory self) internal pure returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := lt(byte(0, mload(memPtr)), 0xC0)
     }
 }

 /// @dev Check if the RLP item is empty (string or list).
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is null.
 function isEmpty(RLPItem memory self) internal pure returns (bool ret) {
     if (isNull(self)) {
         return false;
     }
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
 }

 /// @dev Get the number of items in an RLP encoded list.
 /// @param self The RLP item.
 /// @return The number of items.
 function items(RLPItem memory self) internal constant returns (uint) {
     if (!isList(self))
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     uint pos = memPtr + _payloadOffset(self);
     uint last = memPtr + self._unsafe_length - 1;
     uint itms;
     while (pos <= last) {
         pos += _itemLength(pos);
         itms++;
     }
     return itms;
 }

 /// @dev Create an iterator.
 /// @param self The RLP item.
 /// @return An &#39;Iterator&#39; over the item.
 function iterator(RLPItem memory self) internal constant returns (Iterator memory it) {
     if (!isList(self))
         revert();
     uint ptr = self._unsafe_memPtr + _payloadOffset(self);
     it._unsafe_item = self;
     it._unsafe_nextPtr = ptr;
 }

 /// @dev Return the RLP encoded bytes.
 /// @param self The RLPItem.
 /// @return The bytes.
 function toBytes(RLPItem memory self) internal constant returns (bytes memory bts) {
     var len = self._unsafe_length;
     if (len == 0)
         return;
     bts = new bytes(len);
     _copyToBytes(self._unsafe_memPtr, bts, len);
 }

 /// @dev Decode an RLPItem into bytes. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toData(RLPItem memory self) internal constant returns (bytes memory bts) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
 }

 /// @dev Get the list of sub-items from an RLP encoded list.
 /// Warning: This is inefficient, as it requires that the list is read twice.
 /// @param self The RLP item.
 /// @return Array of RLPItems.
 function toList(RLPItem memory self) internal constant returns (RLPItem[] memory list) {
     if(!isList(self))
         revert();
     var numItems = items(self);
     list = new RLPItem[](numItems);
     var it = iterator(self);
     uint idx;
     while(hasNext(it)) {
         list[idx] = next(it);
         idx++;
     }
 }

 /// @dev Decode an RLPItem into an ascii string. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toAscii(RLPItem memory self) internal constant returns (string memory str) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     bytes memory bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
     str = string(bts);
 }

 /// @dev Decode an RLPItem into a uint. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toUint(RLPItem memory self) internal constant returns (uint data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len > 32 || len == 0)
         revert();
     assembly {
         data := div(mload(rStartPos), exp(256, sub(32, len)))
     }
 }

 /// @dev Decode an RLPItem into a boolean. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toBool(RLPItem memory self) internal constant returns (bool data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         revert();
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     if (temp > 1)
         revert();
     return temp == 1 ? true : false;
 }

 /// @dev Decode an RLPItem into a byte. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toByte(RLPItem memory self) internal constant returns (byte data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         revert();
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     return byte(temp);
 }

 /// @dev Decode an RLPItem into an int. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toInt(RLPItem memory self) internal constant returns (int data) {
     return int(toUint(self));
 }

 /// @dev Decode an RLPItem into a bytes32. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toBytes32(RLPItem memory self) internal constant returns (bytes32 data) {
     return bytes32(toUint(self));
 }

 /// @dev Decode an RLPItem into an address. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toAddress(RLPItem memory self) internal constant returns (address data) {
     if(!isData(self))
         revert();
     var (rStartPos, len) = _decode(self);
     if (len != 20)
         revert();
     assembly {
         data := div(mload(rStartPos), exp(256, 12))
     }
 }

 // Get the payload offset.
 function _payloadOffset(RLPItem memory self) private constant returns (uint) {
     if(self._unsafe_length == 0)
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if(b0 < DATA_SHORT_START)
         return 0;
     if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
         return 1;
     if(b0 < LIST_SHORT_START)
         return b0 - DATA_LONG_OFFSET + 1;
     return b0 - LIST_LONG_OFFSET + 1;
 }

 // Get the full length of an RLP item.
 function _itemLength(uint memPtr) private constant returns (uint len) {
     uint b0;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if (b0 < DATA_SHORT_START)
         len = 1;
     else if (b0 < DATA_LONG_START)
         len = b0 - DATA_SHORT_START + 1;
     else if (b0 < LIST_SHORT_START) {
         assembly {
             let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
             len := add(1, add(bLen, dLen)) // total length
         }
     }
     else if (b0 < LIST_LONG_START)
         len = b0 - LIST_SHORT_START + 1;
     else {
         assembly {
             let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
             len := add(1, add(bLen, dLen)) // total length
         }
     }
 }

 // Get start position and length of the data.
 function _decode(RLPItem memory self) private constant returns (uint memPtr, uint len) {
     if(!isData(self))
         revert();
     uint b0;
     uint start = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(start))
     }
     if (b0 < DATA_SHORT_START) {
         memPtr = start;
         len = 1;
         return;
     }
     if (b0 < DATA_LONG_START) {
         len = self._unsafe_length - 1;
         memPtr = start + 1;
     } else {
         uint bLen;
         assembly {
             bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
         }
         len = self._unsafe_length - 1 - bLen;
         memPtr = start + bLen + 1;
     }
     return;
 }

 // Assumes that enough memory has been allocated to store in target.
 function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen) private constant {
     // Exploiting the fact that &#39;tgt&#39; was the last thing to be allocated,
     // we can write entire words, and just overwrite any excess.
     assembly {
         {
                 let i := 0 // Start at arr + 0x20
                 let words := div(add(btsLen, 31), 32)
                 let rOffset := btsPtr
                 let wOffset := add(tgt, 0x20)
             tag_loop:
                 jumpi(end, eq(i, words))
                 {
                     let offset := mul(i, 0x20)
                     mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                     i := add(i, 1)
                 }
                 jump(tag_loop)
             end:
                 mstore(add(tgt, add(0x20, mload(tgt))), 0)
         }
     }
 }

     // Check that an RLP item is valid.
     function _validate(RLPItem memory self) private constant returns (bool ret) {
         // Check that RLP is well-formed.
         uint b0;
         uint b1;
         uint memPtr = self._unsafe_memPtr;
         assembly {
             b0 := byte(0, mload(memPtr))
             b1 := byte(1, mload(memPtr))
         }
         if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
             return false;
         return true;
     }
}

// File: contracts/MerklePatriciaProof.sol

/*
 * @title MerklePatriciaVerifier
 * @author Sam Mayo (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6615070b0b071f095e5e5e26010b070f0a4805090b">[email&#160;protected]</a>)
 *
 * @dev Library for verifing merkle patricia proofs.
 */
pragma solidity ^0.4.8;


library MerklePatriciaProof {
  /*
   * @dev Verifies a merkle patricia proof.
   * @param value The terminating value in the trie.
   * @param encodedPath The path in the trie leading to value.
   * @param rlpParentNodes The rlp encoded stack of nodes.
   * @param root The root hash of the trie.
   * @return The boolean validity of the proof.
   */
  function verify(bytes value, bytes encodedPath, bytes rlpParentNodes, bytes32 root) internal constant returns (bool) {
    RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
    RLP.RLPItem[] memory parentNodes = RLP.toList(item);

    bytes memory currentNode;
    RLP.RLPItem[] memory currentNodeList;

    bytes32 nodeKey = root;
    uint pathPtr = 0;

    bytes memory path = _getNibbleArray(encodedPath);
    if (path.length == 0) {return false;}

    for (uint i = 0; i < parentNodes.length; i++) {
      if (pathPtr > path.length) {return false;}

      currentNode = RLP.toBytes(parentNodes[i]);
      if (nodeKey != keccak256(currentNode)) {return false;}
      currentNodeList = RLP.toList(parentNodes[i]);

      if (currentNodeList.length == 17) {
        if (pathPtr == path.length) {
          if (keccak256(RLP.toBytes(currentNodeList[16])) == keccak256(value)) {
            return true;
          } else {
            return false;
          }
        }

        uint8 nextPathNibble = uint8(path[pathPtr]);
        if (nextPathNibble > 16) {return false;}
        nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
        pathPtr += 1;
      } else if (currentNodeList.length == 2) {
        pathPtr += _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

        if (pathPtr == path.length) {//leaf node
          if (keccak256(RLP.toData(currentNodeList[1])) == keccak256(value)) {
            return true;
          } else {
            return false;
          }
        }
        //extension node
        if (_nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr) == 0) {
          return false;
        }

        nodeKey = RLP.toBytes32(currentNodeList[1]);
      } else {
        return false;
      }
    }
  }

  function _nibblesToTraverse(bytes encodedPartialPath, bytes path, uint pathPtr) private constant returns (uint) {
    uint len;
    // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
    // and slicedPath have elements that are each one hex character (1 nibble)
    bytes memory partialPath = _getNibbleArray(encodedPartialPath);
    bytes memory slicedPath = new bytes(partialPath.length);

    // pathPtr counts nibbles in path
    // partialPath.length is a number of nibbles
    for (uint i=pathPtr; i<pathPtr+partialPath.length; i++) {
      byte pathNibble = path[i];
      slicedPath[i-pathPtr] = pathNibble;
    }

    if (keccak256(partialPath) == keccak256(slicedPath)) {
      len = partialPath.length;
    } else {
      len = 0;
    }
    return len;
  }

  // bytes b must be hp encoded
  function _getNibbleArray(bytes b) private constant returns (bytes) {
    bytes memory nibbles;
    if (b.length>0) {
      uint8 offset;
      uint8 hpNibble = uint8(_getNthNibbleOfBytes(0,b));
      if (hpNibble == 1 || hpNibble == 3) {
        nibbles = new bytes(b.length*2-1);
        byte oddNibble = _getNthNibbleOfBytes(1,b);
        nibbles[0] = oddNibble;
        offset = 1;
      } else {
        nibbles = new bytes(b.length*2-2);
        offset = 0;
      }

      for (uint i = offset; i < nibbles.length; i++) {
        nibbles[i] = _getNthNibbleOfBytes(i-offset+2,b);
      }
    }
    return nibbles;
  }
  
 /*
  *This function takes in the bytes string (hp encoded) and the value of N, to return Nth Nibble. 
  *@param Value of N
  *@param Bytes String
  *@return ByteString[N]
  */
  function _getNthNibbleOfBytes(uint n, bytes str) private constant returns (byte) {
    return byte(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
  }
}

// File: contracts/PeaceRelay.sol

contract PeaceRelay {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  uint256 public genesisBlock;
  uint256 public highestBlock;
  address public owner;

  mapping (address => bool) authorized;
  mapping (uint256 => BlockHeader) public blocks;

  modifier onlyOwner() {
    if (owner == msg.sender) {
      _;
    }
  }

  modifier onlyAuthorized() {
    if (authorized[msg.sender]) {
      _;
    }
  }

  struct BlockHeader {
    uint      prevBlockHash; // 0
    bytes32   stateRoot;     // 3
    bytes32   txRoot;        // 4
    bytes32   receiptRoot;   // 5
  }

  event SubmitBlock(uint256 blockHash, address submitter);

  constructor (uint256 blockNumber) public {
    genesisBlock = blockNumber;
    highestBlock = blockNumber;
    authorized[msg.sender] = true;
    owner = msg.sender;
  }

  function authorize(address user) onlyOwner public {
    authorized[user] = true;
  }

  function deAuthorize(address user) onlyOwner public {
    authorized[user] = false;
  }

  function resetGenesisBlock(uint256 blockNumber) onlyAuthorized public {
    genesisBlock = blockNumber;
    highestBlock = blockNumber;
  }

  function submitBlock(uint256 blockHash, bytes rlpHeader) onlyAuthorized public {
    BlockHeader memory header = parseBlockHeader(rlpHeader);
    uint256 blockNumber = getBlockNumber(rlpHeader);
    if (blockNumber > highestBlock) {
      highestBlock = blockNumber;
    }
    blocks[blockHash] = header;
    // There is at least one orphan
    emit SubmitBlock(blockHash, msg.sender);
  }

  function checkTxProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) view public returns (bool) {
    // add fee for checking transaction
    bytes32 txRoot = blocks[blockHash].txRoot;
    return trieValue(value, path, parentNodes, txRoot);
  }

  function checkStateProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) view public returns (bool) {
    bytes32 stateRoot = blocks[blockHash].stateRoot;
    return trieValue(value, path, parentNodes, stateRoot);
  }

  function checkReceiptProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) view public returns (bool) {
    bytes32 receiptRoot = blocks[blockHash].receiptRoot;
    return trieValue(value, path, parentNodes, receiptRoot);
  }

  function parseBlockHeader(bytes rlpHeader) view internal returns (BlockHeader) {
    BlockHeader memory header;
    RLP.Iterator memory it = rlpHeader.toRLPItem().iterator();

    uint idx;
    while (it.hasNext()) {
      if (idx == 0) {
        header.prevBlockHash = it.next().toUint();
      } else if (idx == 3) {
        header.stateRoot = bytes32(it.next().toUint());
      } else if (idx == 4) {
        header.txRoot = bytes32(it.next().toUint());
      } else if (idx == 5) {
        header.receiptRoot = bytes32(it.next().toUint());
      } else {
        it.next();
      }
      idx++;
    }
    return header;
  }

  function getBlockNumber(bytes rlpHeader) view internal returns (uint blockNumber) {
    RLP.RLPItem[] memory rlpH = RLP.toList(RLP.toRLPItem(rlpHeader));
    blockNumber = RLP.toUint(rlpH[8]);
  }

  function getStateRoot(uint256 blockHash) view public returns (bytes32) {
    return blocks[blockHash].stateRoot;
  }

  function getTxRoot(uint256 blockHash) view public returns (bytes32) {
    return blocks[blockHash].txRoot;
  }

  function getReceiptRoot(uint256 blockHash) view public returns (bytes32) {
    return blocks[blockHash].receiptRoot;
  }

  function trieValue(bytes value, bytes encodedPath, bytes parentNodes, bytes32 root) view internal returns (bool) {
    return MerklePatriciaProof.verify(value, encodedPath, parentNodes, root);
  }

}