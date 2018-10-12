pragma solidity ^0.4.24;

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/RLP.sol

/**
* @title RLPReader
*
* RLPReader is used to read and parse RLP encoded data in memory.
*
* @author Andreas Olofsson (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0e6f606a7c6162613f37363e4e69636f6762206d6163">[email&#160;protected]</a>)
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
 * @author Sam Mayo (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="92e1f3fffff3ebfdaaaaaad2f5fff3fbfebcf1fdff">[email&#160;protected]</a>)
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

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// File: contracts/ETHToken.sol

contract ETHToken is ERC20, Ownable {
    using SafeMath for uint256;
    using RLP for RLP.RLPItem;
    using RLP for RLP.Iterator;
    using RLP for bytes;
    
    struct Transaction {
        uint nonce;
        uint gasPrice;
        uint gasLimit;
        address to;
        uint value;
        bytes data;
    }
    
    struct ETHLockTxProof {
        bytes value;
        bytes32 blockhash;
        bytes path;
        bytes parentNodes;
    }
    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;    //How many decimals to show.
    string public version = "v0.1";
    uint public totalSupply;
    uint public DEPOSIT_GAS_MINIMUM = 500000; //should be constant
    bytes4 public LOCK_FUNCTION_SIG = 0xf435f5a7;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;
    mapping(bytes32 => bool) rewarded;

    PeaceRelay public ETHRelay;
    address public ETHLockingAddr;
    
    event Burn(address indexed from, address indexed ethAddr, uint indexed value);
    event Mint(address indexed to, uint value);
    
    constructor (address peaceRelayAddr) public {
        totalSupply = 0;
        name = "ETHToken";        // Set the name for display purposes
        symbol = "ETHT";           // Set the symbol for display purposes
        decimals = 9;             // Amount of decimals for display purposes
        ETHRelay = PeaceRelay(peaceRelayAddr);
    }
    
    function changePeaceRelayAddr(address _peaceRelayAddr) onlyOwner public {
        ETHRelay = PeaceRelay(_peaceRelayAddr);
    }
    
    function changeETHLockingAddr(address _ETHLockingAddr) onlyOwner public {
        ETHLockingAddr = _ETHLockingAddr;
    }
    
    function mint(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public returns (bool) {
        if (!rewarded[keccak256(value, bytes32(blockHash), path, parentNodes)] && ETHRelay.checkTxProof(value, blockHash, path, parentNodes)) {
            Transaction memory tx = getTransactionDetails(value);
            bytes4 functionSig = getSignature(tx.data);
          
            require(functionSig == LOCK_FUNCTION_SIG);
            require(tx.to == ETHLockingAddr);
            require(tx.gasLimit <= DEPOSIT_GAS_MINIMUM);

            address newAddress = getAddress(tx.data);

            totalSupply = totalSupply.add(tx.value);
            balances[newAddress] = balances[newAddress].add(tx.value);
            emit Mint(newAddress, tx.value);
            rewarded[keccak256(value, bytes32(blockHash), path, parentNodes)] = true;
            return true;
        }
        return false;
    }
    
    function burn(uint256 _value, address ethAddr) public returns (bool) {
        // safeSub already has throw, so no need to throw
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, ethAddr, _value);
        return true;
    }
    
    function checkIfRewarded(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
        return rewarded[keccak256(value, bytes32(blockHash),path,parentNodes)];
    }
    
    function checkProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
        return ETHRelay.checkTxProof(value, blockHash, path, parentNodes);
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }
    
    /**
     * * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
    **/
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     /**
      * @dev Increase the amount of tokens that an owner allowed to a spender.
      * approve should be called when allowed[_spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * @param _spender The address which will spend the funds.
      * @param _addedValue The amount of tokens to increase the allowance by.
      */
  
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    
    function decreaseApproval(address _spender,uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // HELPER FUNCTIONS
    function getSignature(bytes b) public pure returns (bytes4) {
        require(b.length >= 32);
        uint tmp = 0;
        for (uint i = 0; i < 4; i++) {
            tmp = tmp*(2**8)+uint8(b[i]);
        }
        return bytes4(tmp);
    }

    //grabs the first input from some function data
    //and implies that it is an address
    function getAddress(bytes b) public pure returns (address a) {
        if (b.length < 36) return address(0);
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            a := and(mask, mload(add(b, 36)))
            //36 is the offset of the first param of the data, if encoded properly.
            //4 bytes for the function signature, and 32 for the address.
        }
    }
    
    //txValue is a value at the bottom of the transaction trie.
    function getTransactionDetails(bytes txValue) view internal returns (Transaction memory tx) {
        RLP.RLPItem[] memory list = txValue.toRLPItem().toList();
        tx.gasPrice = list[1].toUint();
        tx.gasLimit = list[2].toUint();
        tx.to = address(list[3].toUint());
        tx.value = list[4].toUint();
    
        //Ugly hard coding for now. Can only parse burn transactions.
        tx.data = new bytes(36);
        for (uint i = 0; i < 36; i++) {
            tx.data[i] = txValue[txValue.length - 103 + i];
        }
        return tx;
    }
}