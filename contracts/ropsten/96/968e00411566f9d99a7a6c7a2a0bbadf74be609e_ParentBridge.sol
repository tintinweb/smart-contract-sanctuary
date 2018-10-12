pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ECRecovery.sol

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param _sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 _hash, bytes _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (_sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(_hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/utils/RLP.sol

/**
 * @title RLPReader
 * @dev RLPReader is used to read and parse RLP encoded data in memory.
 * @author Andreas Olofsson (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="55343b31273a393a646c6d65153238343c397b363a38">[email&#160;protected]</a>)
 */
library RLP {
    uint constant DATA_SHORT_START = 0x80;
    uint constant DATA_LONG_START = 0xB8;
    uint constant LIST_SHORT_START = 0xC0;
    uint constant LIST_LONG_START = 0xF8;

    uint constant DATA_LONG_OFFSET = 0xB7;


    struct RLPItem {
        uint _unsafeMemPtr;    // Pointer to the RLP-encoded bytes.
        uint _unsafeLength;    // Number of bytes. This is the full length of the string.
    }

    struct Iterator {
        RLPItem _unsafeItem;   // Item that&#39;s being iterated over.
        uint _unsafeNextPtr;   // Position of the next item in the list.
    }

    /* RLPItem */

    /// @dev Creates an RLPItem from an array of RLP encoded bytes.
    /// @param self The RLP encoded bytes.
    /// @return An RLPItem
    function toRLPItem(bytes memory self) internal pure returns (RLPItem memory) {
        uint len = self.length;
        uint memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }
        return RLPItem(memPtr, len);
    }

    /// @dev Get the list of sub-items from an RLP encoded list.
    /// Warning: This requires passing in the number of items.
    /// @param self The RLP item.
    /// @return Array of RLPItems.
    function toList(RLPItem memory self, uint256 numItems) internal pure returns (RLPItem[] memory list) {
        list = new RLPItem[](numItems);
        Iterator memory it = iterator(self);
        uint idx;
        while (idx < numItems) {
            list[idx] = next(it);
            idx++;
        }
    }

    /// @dev Decode an RLPItem into a uint. This will not work if the
    /// RLPItem is a list.
    /// @param self The RLPItem.
    /// @return The decoded string.
    function toUint(RLPItem memory self) internal pure returns (uint data) {
        (uint rStartPos, uint len) = _decode(self);
        assembly {
            data := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }

    /// @dev Decode an RLPItem into an address. This will not work if the
    /// RLPItem is a list.
    /// @param self The RLPItem.
    /// @return The decoded string.
    function toAddress(RLPItem memory self)
        internal
        pure
        returns (address data)
    {
        (uint rStartPos,) = _decode(self);
        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
    }

    /// @dev Create an iterator.
    /// @param self The RLP item.
    /// @return An &#39;Iterator&#39; over the item.
    function iterator(RLPItem memory self) private pure returns (Iterator memory it) {
        uint ptr = self._unsafeMemPtr + _payloadOffset(self);
        it._unsafeItem = self;
        it._unsafeNextPtr = ptr;
    }

    /* Iterator */
    function next(Iterator memory self) private pure returns (RLPItem memory subItem) {
        uint ptr = self._unsafeNextPtr;
        uint itemLength = _itemLength(ptr);
        subItem._unsafeMemPtr = ptr;
        subItem._unsafeLength = itemLength;
        self._unsafeNextPtr = ptr + itemLength;
    }

    function hasNext(Iterator memory self) private pure returns (bool) {
        RLPItem memory item = self._unsafeItem;
        return self._unsafeNextPtr < item._unsafeMemPtr + item._unsafeLength;
    }

    // Get the payload offset.
    function _payloadOffset(RLPItem memory self)
        private
        pure
        returns (uint)
    {
        uint b0;
        uint memPtr = self._unsafeMemPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START)
            return 0;
        if (b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
            return 1;
    }

    // Get the full length of an RLP item.
    function _itemLength(uint memPtr)
        private
        pure
        returns (uint len)
    {
        uint b0;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START)
            len = 1;
        else if (b0 < DATA_LONG_START)
            len = b0 - DATA_SHORT_START + 1;
    }

    // Get start position and length of the data.
    function _decode(RLPItem memory self)
        private
        pure
        returns (uint memPtr, uint len)
    {
        uint b0;
        uint start = self._unsafeMemPtr;
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr = start;
            len = 1;
            return;
        }
        if (b0 < DATA_LONG_START) {
            len = self._unsafeLength - 1;
            memPtr = start + 1;
        } else {
            uint bLen;
            assembly {
                bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
            }
            len = self._unsafeLength - 1 - bLen;
            memPtr = start + bLen + 1;
        }
        return;
    }

    /// @dev Return the RLP encoded bytes.
    /// @param self The RLPItem.
    /// @return The bytes.
    function toBytes(RLPItem memory self)
        internal
        pure
        returns (bytes memory bts)
    {
        uint len = self._unsafeLength;
        if (len == 0)
            return;
        bts = new bytes(len);
        _copyToBytes(self._unsafeMemPtr, bts, len);
    }

    // Assumes that enough memory has been allocated to store in target.
    function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen)
        private
        pure
    {
        // Exploiting the fact that &#39;tgt&#39; was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        assembly {
            {
                // evm operations on words
                let words := div(add(btsLen, 31), 32)
                let rOffset := btsPtr
                let wOffset := add(tgt, 0x20)
                for
                    { let i := 0 } // start at arr + 0x20 -> first byte corresponds to length
                    lt(i, words)
                    { i := add(i, 1) }
                {
                    let offset := mul(i, 0x20)
                    mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                }
                mstore(add(tgt, add(0x20, mload(tgt))), 0)
            }
        }
    }
}

// File: contracts/Transaction.sol

/**
 * @title Transaction
 * @dev Child chain transaction, represented in RLP.
 * From Loom Network Plasma Cash implementation, with a modification for Plasma Debit support.
 */
library Transaction {
    using RLP for bytes;
    using RLP for RLP.RLPItem;

    struct Tx {
        uint64 slotId;
        uint256 prevBlock;
        address newOwner;
        bytes32 hash;
    }

    function getTx(bytes memory txBytes) internal pure returns (Tx memory) {
        RLP.RLPItem[] memory rlpTx = txBytes.toRLPItem().toList(3);
        Tx memory transaction;

        transaction.slotId = uint64(rlpTx[0].toUint());
        transaction.prevBlock = rlpTx[1].toUint();
        transaction.newOwner = rlpTx[2].toAddress();
        transaction.hash = keccak256(txBytes);
        return transaction;
    }

    function getHash(bytes memory txBytes) internal pure returns (bytes32) {
        return keccak256(txBytes);
    }

    function getOwner(bytes memory txBytes) internal pure returns (address) {
        RLP.RLPItem[] memory rlpTx = txBytes.toRLPItem().toList(3);
        return rlpTx[2].toAddress();
    }
}

// File: contracts/parent/SparseMerkleTree.sol

// Based on https://rinkeby.etherscan.io/address/0x881544e0b2e02a79ad10b01eca51660889d5452b#code
contract SparseMerkleTree {

    uint8 constant DEPTH = 64;
    bytes32[DEPTH + 1] public defaultHashes;

    constructor() public {
        // defaultHash[0] is being set to keccak256(uint256(0));
        defaultHashes[0] = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
        setDefaultHashes(1, DEPTH);
    }

    function checkMembership(
        bytes32 leaf,
        bytes32 root,
        uint64 tokenID,
        bytes proof) public view returns (bool)
    {
        bytes32 computedHash = getRoot(leaf, tokenID, proof);
        return (computedHash == root);
    }

    // first 64 bits of the proof are the 0/1 bits
    function getRoot(bytes32 leaf, uint64 index, bytes proof) public view returns (bytes32) {
        require((proof.length - 8) % 32 == 0 && proof.length <= 2056);
        bytes32 proofElement;
        bytes32 computedHash = leaf;
        uint16 p = 8;
        uint64 proofBits;
        assembly {proofBits := div(mload(add(proof, 32)), exp(256, 24))}

        for (uint d = 0; d < DEPTH; d++ ) {
            if (proofBits % 2 == 0) { // check if last bit of proofBits is 0
                proofElement = defaultHashes[d];
            } else {
                p += 32;
                require(proof.length >= p);
                assembly { proofElement := mload(add(proof, p)) }
            }
            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            proofBits = proofBits / 2; // shift it right for next bit
            index = index / 2;
        }
        return computedHash;
    }

    function setDefaultHashes(uint8 startIndex, uint8 endIndex) private {
        for (uint8 i = startIndex; i <= endIndex; i ++) {
            defaultHashes[i] = keccak256(abi.encodePacked(defaultHashes[i-1], defaultHashes[i-1]));
        }
    }
}

// File: contracts/parent/ParentBridge.sol

/**
 * @title ParentChain
 * @dev A gateway contract on the parent chain, bridging parent chain with the child chain.
 */
contract ParentBridge is Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Transaction for bytes;
    using ECRecovery for bytes32;

    event Deposit(uint64 indexed slotId, address indexed owner, uint256 indexed blockNumber);
    event BlockSubmit(uint256 blockNumber, bytes32 root, uint256 timestamp);
    event ExitStarted(uint64 indexed slotId, address indexed owner);
    event ExitRejected(uint64 indexed slotId, address indexed claimer);
    event ExitFinalized(uint64 indexed slotId, address indexed owner);

    enum Type {
        ERC20,
        ERC721
    }

    enum State {
        DEPOSITED,
        EXITING,
        EXITED
    }

    struct Exit {
        address owner;
        uint256 exitBlock;
        address prevOwner; // previous owner of coin
        uint256 prevBlock;
        uint256 createdAt;
    }

    struct Coin {
        Type typ;
        address owner;
        address token;
        uint256 uid;
        uint256 depositBlock;
        uint256 value;
        State state;
        Exit exit;
    }

    struct ChildBlock {
        bytes32 root;
        uint256 timestamp;
    }

    // Track owners of txs that are pending a response
    struct Challenge {
        address owner;
        uint256 blockNumber;
    }

    // constraints from Plasma MVP by OmiseGO
    uint256 public constant CHILD_BLOCK_INTERVAL = 1000;
    uint256 public constant CHALLENGE_PERIOD = 200; // no timestamp. no.
    uint256 public constant MAX_ITERATION = 100;

    SparseMerkleTree merkleTree;

    uint256 public currentChildBlock;
    uint256 public currentDepositBlock;
    uint64 public coinCount = 0;

    mapping (uint256 => ChildBlock) public childBlocks;
    mapping (uint64 => uint64) coinRef;
    mapping (uint64 => Coin) coins;

    constructor() public {
        merkleTree = new SparseMerkleTree();
    }

    // User-side actions
    // TODO: check approved balance
    /**
     * @dev Deposit non-fungible token (ERC721) into the child chain.
     */
    function depositNonFungible(
        ERC721 token,
        address from,
        uint256 tokenId
    ) public {
        token.safeTransferFrom(from, address(this), tokenId);
        deposit(Type.ERC721, token, from, tokenId, 1);
    }

    /**
     * @dev Deposit fungible token (ERC20) into the child chain.
     */
    function depositFungible(
        ERC20 token,
        address from,
        uint256 value
    ) public {
        token.safeTransferFrom(from, address(this), value);
        deposit(Type.ERC20, token, from, 0, value);
    }

    function deposit(
        Type typ,
        address token,
        address from,
        uint256 tokenId,
        uint256 amount
    ) private {
        require(
            currentDepositBlock < CHILD_BLOCK_INTERVAL,
            "Only allow up to 1000 deposits per child block.");

        bytes32 depositId = keccak256(abi.encodePacked(from, address(token), tokenId));
        uint64 slotId = uint64(bytes8(depositId));

        // generate deposit block
        uint256 depositBlock = getNextDepositBlockIndex();
        childBlocks[depositBlock] = ChildBlock({
            root: depositId,
            timestamp: block.timestamp
        });
        currentDepositBlock = currentDepositBlock.add(1);

        // create coin. we use slot like Loom Network implementation
        Coin storage coin = coins[slotId];
        coin.typ = typ;
        coin.owner = from;
        coin.token = token;
        coin.uid = tokenId;
        coin.depositBlock = depositBlock;
        coin.value = amount;
        coin.state = State.DEPOSITED;

        coinRef[coinCount] = slotId;
        coinCount += 1;
        emit Deposit(slotId, coin.owner, coin.depositBlock);
    }

    function exit(
        bytes exitTxData, bytes exitProof, uint256 exitBlock,
        bytes prevTxData, bytes prevProof, uint256 prevBlock,
        bytes sign
    ) public {
        if(exitBlock % CHILD_BLOCK_INTERVAL != 0) {
            depositExit(
                exitBlock,
                exitTxData
            );
        } else {
            defaultExit(
                exitBlock,
                exitTxData, childBlocks[exitBlock].root, exitProof,
                prevTxData, childBlocks[prevBlock].root, prevProof,
                sign
            );
        }
    }

    // TODO: fix coin.uid hash collision
    function depositExit(
        uint256 blockNumber,
        bytes exitTxData
    ) private {
        Transaction.Tx memory exitTx = exitTxData.getTx();
        Coin storage coin = coins[exitTx.slotId];

        require(exitTx.newOwner == msg.sender, "only owner can exit");
        require(
            childBlocks[blockNumber].root ==
            keccak256(abi.encodePacked(msg.sender, coin.token, coin.uid)),
            "membership check failed");

        submitExit(
            exitTx.slotId,
            exitTx.newOwner, blockNumber,
            address(0), 0);
    }

    function defaultExit(
        uint256 blockNumber,
        bytes exitTxData, bytes32 exitRoot, bytes exitProof,
        bytes prevTxData, bytes32 prevRoot, bytes prevProof,
        bytes sign
    ) private {
        Transaction.Tx memory exitTx = exitTxData.getTx();
        Transaction.Tx memory prevTx = prevTxData.getTx();

        require(exitTx.newOwner == msg.sender, "invalid owner");
        require(prevTx.slotId == exitTx.slotId, "invalid slotId");
        require(prevTx.newOwner == exitTx.hash.recover(sign), "invalid sig");
        require(prevRoot == childBlocks[exitTx.prevBlock].root, "invalid tx data");
        require(inclusionCheck(exitTx, exitRoot, exitProof), "inclusion check failed");
        require(inclusionCheck(prevTx, prevRoot, prevProof), "inclusion check failed");

        submitExit(
            exitTx.slotId,
            exitTx.newOwner, blockNumber,
            prevTx.newOwner, exitTx.prevBlock);
    }

    function submitExit(
        uint64 slotId,
        address exitOwner, uint256 exitBlock,
        address prevOwner, uint256 prevBlock
    ) private {
        Coin storage coin = coins[slotId];
        coin.exit = Exit({
            owner: exitOwner,
            exitBlock: exitBlock,
            prevOwner: prevOwner,
            prevBlock: prevBlock,
            createdAt: block.number
        });
        coin.state = State.EXITING;
        emit ExitStarted(slotId, coin.exit.owner);
    }

    // TODO list
    // before  : x
    // between : v
    // after   : v
    function challenge(
        uint64 slotId,
        uint256 blockNumber,
        bytes claimTxData,
        bytes proof,
        bytes sign
    ) public {
        require(
            coins[slotId].state == State.EXITING,
            "only exiting coin can challenge");

        Transaction.Tx memory txn = claimTxData.getTx();
        Coin storage coin = coins[slotId];
        require(txn.slotId == slotId, "invalid slot");
        require(txn.hash.recover(sign) == coin.exit.prevOwner, "invalid sig");

        if(getChallengeType(slotId, blockNumber)) {
            // between

        } else {
            // after
            require(txn.prevBlock == coin.exit.exitBlock, "invalid reference");
        }

        require(
            inclusionCheck(txn, childBlocks[blockNumber].root, proof),
            "inclusion check failed");

        // reject exit
        coin.state = State.DEPOSITED;
        delete coins[slotId].exit;
        emit ExitRejected(slotId, msg.sender);
    }

    function getChallengeType(uint64 slotId, uint256 blockNumber)
        private
        view
        returns (bool)
    {
        return (
            coins[slotId].exit.exitBlock > blockNumber &&
            coins[slotId].exit.prevBlock < blockNumber
        );
    }

    function inclusionCheck(
        Transaction.Tx memory Tx,
        bytes32 root,
        bytes proof
    ) private view returns (bool) {
        return merkleTree.checkMembership(Tx.hash, root, Tx.slotId, proof);
    }

    function finalize(uint64 slotId) public {
        Coin storage coin = coins[slotId];

        if (coin.state != State.EXITING) return;
        if (block.number.sub(coin.exit.createdAt) <= CHALLENGE_PERIOD) return;

        coin.state = State.EXITED;
        coin.owner = coin.exit.owner;

        address owner;
        uint256 data;

        if(coin.typ == Type.ERC20) {
            ERC20 token20 = ERC20(coin.token);
            owner = coin.owner;
            data = coin.value;
            delete coins[slotId];

            token20.safeTransfer(owner, data);
        } else {
            ERC721 token721 = ERC721(coin.token);
            owner = coin.owner;
            data = coin.uid; // reentrancy
            delete coins[slotId];

            token721.safeTransferFrom(this, owner, data);
        }
        emit ExitFinalized(slotId, coin.owner);
    }

    function finalizeMany(uint64[] slotIds) public {
        require(slotIds.length <= MAX_ITERATION, "gas limit");
        for(uint i = 0; i < slotIds.length; i++) {
            finalize(slotIds[i]);
        }
    }

    // Operator-side actions

    /**
     * @dev Submit a merkle root of child chain blocks, by the operator.
     */
    function submitBlock(bytes32 _root) external onlyOwner {
        childBlocks[currentChildBlock] = ChildBlock({
            root: _root,
            timestamp: block.timestamp
        });
        emit BlockSubmit(currentChildBlock, _root, block.timestamp);

        // update index
        currentChildBlock = currentChildBlock.add(CHILD_BLOCK_INTERVAL);
        currentDepositBlock = 1;
    }

    function isDepositBlock(uint256 _blockNumber) internal pure returns (bool) {
        return (_blockNumber % CHILD_BLOCK_INTERVAL == 0);
    }

    function getNextDepositBlockIndex()
        public
        view
        returns (uint256)
    {
        return currentChildBlock.sub(CHILD_BLOCK_INTERVAL).add(currentDepositBlock);
    }

    /**
     * @dev Get block of the child chain.
     */
    function getChildBlock(uint256 _blockNumber) 
        public 
        view
        returns (bytes32, uint256) {
        return (childBlocks[_blockNumber].root, childBlocks[_blockNumber].timestamp);
    }

    function getCoinBySlotId(uint64 slotId) public view returns (
        Type,
        address,
        uint256,
        uint256,
        uint256,
        State
    ) {
        Coin storage coin = coins[slotId];
        return (
            coin.typ,
            coin.owner,
            coin.value,
            coin.depositBlock,
            childBlocks[coin.depositBlock].timestamp,
            coin.state
        );
    }

    function getExitBySlotId(uint64 slotId) public view returns (
        address,
        uint256,
        address,
        uint256,
        uint256
    ) {
        Exit storage exitData = coins[slotId].exit;
        return (
            exitData.owner,
            exitData.exitBlock,
            exitData.prevOwner,
            exitData.prevBlock,
            exitData.createdAt
        );
    }

    function getCoinByCount(uint64 count) external view returns (
        Type,
        address,
        uint256,
        uint256,
        uint256,
        State
    ) {
        return getCoinBySlotId(coinRef[count]);
    }

}