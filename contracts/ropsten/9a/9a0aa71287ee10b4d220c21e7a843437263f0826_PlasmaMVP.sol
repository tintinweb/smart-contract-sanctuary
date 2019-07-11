/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity ^0.5.0;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2f4b4e594a6f4e4440424d4e014c4042">[email&#160;protected]</a>
// released under Apache 2.0 licence

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    
    uint8 constant WORD_SIZE = 32;
    
    struct RLPItem {
        uint len;
        uint memPtr;
    }
    
    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }
        
        return RLPItem(item.length, memPtr);
    }
    
    /*
    * @param item RLP encoded bytes
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }
    
    /*
    * @param item RLP encoded bytes
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }
    
    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));
        
        uint items = numItems(item);
        result = new RLPItem[](items);
        
        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }
    
    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;
        
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        
        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }
    
    /** RLPItem conversions into data types **/
    
    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }
        
        copy(item.memPtr, ptr, item.len);
        return result;
    }
    
    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }
        
        return result == 0 ? false : true;
    }
    
    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);
        
        return address(toUint(item));
    }
    
    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);
        
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        
        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)
        
        // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }
        
        return result;
    }
    
    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);
        
        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }
        
        return result;
    }
    
    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);
        
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);
        
        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }
        
        copy(item.memPtr + offset, destPtr, len);
        return result;
    }
    
    /*
    * Private Helpers
    */
    
    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;
        
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }
        
        return count;
    }
    
    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        
        if (byte0 < STRING_SHORT_START)
            return 1;
        
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;
        
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
            
            /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }
        
        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        }
        
        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)
                
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }
    
    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        
        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }
    
    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;
        
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            
            src += WORD_SIZE;
            dest += WORD_SIZE;
        }
        
        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

library BytesUtil {
    uint8 constant WORD_SIZE = 32;

    // @param _bytes raw bytes that needs to be slices
    // @param start  start of the slice relative to `_bytes`
    // @param len    length of the sliced byte array
    function slice(bytes memory _bytes, uint start, uint len)
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length - start >= len);

        if (_bytes.length == len)
            return _bytes;

        bytes memory result;
        uint src;
        uint dest;
        assembly {
            // memory & free memory pointer
            result := mload(0x40)
            mstore(result, len) // store the size in the prefix
            mstore(0x40, add(result, and(add(add(0x20, len), 0x1f), not(0x1f)))) // padding

            // pointers
            src := add(start, add(0x20, _bytes))
            dest := add(0x20, result)
        }

        // copy as many word sizes as possible
        for(; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }

        return result;
    }
}

library SafeMath {
    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    function max(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }
}

library ECDSA {
     /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // prefix the hash with an ethereum signed message
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
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
            return ecrecover(hash, v, r, s);
        }
    }
}

library TMSimpleMerkleTree {
    using BytesUtil for bytes;

    // @param leaf     a leaf of the tree
    // @param index    position of this leaf in the tree that is zero indexed
    // @param rootHash block header of the merkle tree
    // @param proof    sequence of 32-byte hashes from the leaf up to, but excluding, the root
    // @paramt total   total # of leafs in the tree
    function checkMembership(bytes32 leaf, uint256 index, bytes32 rootHash, bytes memory proof, uint256 total)
        internal
        pure
        returns (bool)
    {
        // variable size Merkle tree, but proof must consist of 32-byte hashes
        require(proof.length % 32 == 0); // incorrect proof length

        bytes32 computedHash = computeHashFromAunts(index, total, leaf, proof);
        return computedHash == rootHash;
    }

    // helper function as described in the tendermint docs
    function computeHashFromAunts(uint256 index, uint256 total, bytes32 leaf, bytes memory innerHashes)
        private
        pure
        returns (bytes32)
    {
        require(index < total); // index must be within bound of the # of leave
        require(total > 0); // must have one leaf node

        if (total == 1) {
            require(innerHashes.length == 0); // 1 txn has no proof
            return leaf;
        }
        require(innerHashes.length != 0); // >1 txns should have a proof

        uint256 numLeft = (total + 1) / 2;
        bytes32 proofElement;

        // prepend 0x20 byte literal to hashes
        // tendermint prefixes intermediate hashes with 0x20 bytes literals
        // before hashing them.
        bytes memory b = new bytes(1);
        assembly {
            let memPtr := add(b, 0x20)
            mstore8(memPtr, 0x20)
        }

        uint innerHashesMemOffset = innerHashes.length - 32;
        if (index < numLeft) {
            bytes32 leftHash = computeHashFromAunts(index, numLeft, leaf, innerHashes.slice(0, innerHashes.length - 32));
            assembly {
                // get the last 32-byte hash from innerHashes array
                proofElement := mload(add(add(innerHashes, 0x20), innerHashesMemOffset))
            }

            return sha256(abi.encodePacked(b, leftHash, b, proofElement));
        } else {
            bytes32 rightHash = computeHashFromAunts(index-numLeft, total-numLeft, leaf, innerHashes.slice(0, innerHashes.length - 32));
            assembly {
                    // get the last 32-byte hash from innerHashes array
                    proofElement := mload(add(add(innerHashes, 0x20), innerHashesMemOffset))
            }
            return sha256(abi.encodePacked(b, proofElement, b, rightHash));
        }
    }
}

library MinPriorityQueue {
    using SafeMath for uint256;

    function insert(uint256[] storage heapList, uint256 k)
        internal
    {
        heapList.push(k);
        if (heapList.length > 1)
            percUp(heapList, heapList.length.sub(1));
    }

    function delMin(uint256[] storage heapList)
        internal
        returns (uint256)
    {
        require(heapList.length > 0);

        uint256 min = heapList[0];

        // move the last element to the front
        heapList[0] = heapList[heapList.length.sub(1)];
        delete heapList[heapList.length.sub(1)];
        heapList.length = heapList.length.sub(1);

        if (heapList.length > 1) {
            percDown(heapList, 0);
        }

        return min;
    }

    function minChild(uint256[] storage heapList, uint256 i)
        private
        view
        returns (uint256)
    {
        uint lChild = i.mul(2).add(1);
        uint rChild = i.mul(2).add(2);

        if (rChild > heapList.length.sub(1) || heapList[lChild] < heapList[rChild])
            return lChild;
        else
            return rChild;
    }

    function percUp(uint256[] storage heapList, uint256 i)
        private
    {
        uint256 position = i;
        uint256 value = heapList[i];

        // continue to percolate up while smaller than the parent
        while (i != 0 && value < heapList[i.sub(1).div(2)]) {
            heapList[i] = heapList[i.sub(1).div(2)];
            i = i.sub(1).div(2);
        }

        // place the value in the correct parent
        if (position != i) heapList[i] = value;
    }

    function percDown(uint256[] storage heapList, uint256 i)
        private
    {
        uint position = i;
        uint value = heapList[i];

        // continue to percolate down while larger than the child
        uint child = minChild(heapList, i);
        while(child < heapList.length && value > heapList[child]) {
            heapList[i] = heapList[child];
            i = child;
            child = minChild(heapList, i);
        }

        // place value in the correct child
        if (position != i) heapList[i] = value;
    }
}

contract PlasmaMVP {
    using MinPriorityQueue for uint256[];
    using BytesUtil for bytes;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using SafeMath for uint256;
    using TMSimpleMerkleTree for bytes32;
    using ECDSA for bytes32;

    /*
     * Events
     */

    event ChangedOperator(address oldOperator, address newOperator);

    event AddedToBalances(address owner, uint256 amount);
    event BlockSubmitted(bytes32 header, uint256 blockNumber, uint256 numTxns, uint256 feeAmount);
    event Deposit(address depositor, uint256 amount, uint256 depositNonce, uint256 ethBlockNum);

    event StartedTransactionExit(uint256[3] position, address owner, uint256 amount, bytes confirmSignatures, uint256 committedFee);
    event StartedDepositExit(uint256 nonce, address owner, uint256 amount, uint256 committedFee);

    event ChallengedExit(uint256[4] position, address owner, uint256 amount);
    event FinalizedExit(uint256[4] position, address owner, uint256 amount);

    /*
     *  Storage
     */

    address public operator;

    uint256 public lastCommittedBlock;
    uint256 public depositNonce;
    mapping(uint256 => plasmaBlock) public plasmaChain;
    mapping(uint256 => depositStruct) public deposits;
    struct plasmaBlock{
        bytes32 header;
        uint256 numTxns;
        uint256 feeAmount;
        uint256 createdAt;
    }
    struct depositStruct {
        address owner;
        uint256 amount;
        uint256 createdAt;
        uint256 ethBlockNum;
    }

    // exits
    uint256 public minExitBond;
    uint256[] public txExitQueue;
    uint256[] public depositExitQueue;
    mapping(uint256 => exit) public txExits;
    mapping(uint256 => exit) public depositExits;
    enum ExitState { NonExistent, Pending, Challenged, Finalized }
    struct exit {
        uint256 amount;
        uint256 committedFee;
        uint256 createdAt;
        address owner;
        uint256[4] position; // (blkNum, txIndex, outputIndex, depositNonce)
        ExitState state; // default value is `NonExistent`
    }

    // funds
    mapping(address => uint256) public balances;
    uint256 public totalWithdrawBalance;

    // constants
    uint256 constant txIndexFactor = 10;
    uint256 constant blockIndexFactor = 1000000;
    uint256 constant lastBlockNum = 2**109;
    uint256 constant feeIndex = 2**16-1;

    /** Modifiers **/
    modifier isBonded()
    {
        require(msg.value >= minExitBond);
        if (msg.value > minExitBond) {
            uint256 excess = msg.value.sub(minExitBond);
            balances[msg.sender] = balances[msg.sender].add(excess);
            totalWithdrawBalance = totalWithdrawBalance.add(excess);
        }

        _;
    }

    modifier onlyOperator()
    {
        require(msg.sender == operator);
        _;
    }

    function changeOperator(address newOperator)
        public
        onlyOperator
    {
        require(newOperator != address(0));

        emit ChangedOperator(operator, newOperator);
        operator = newOperator;
    }

    constructor() public
    {
        operator = msg.sender;

        lastCommittedBlock = 0;
        depositNonce = 1;
        minExitBond = 200000;
    }

    // @param blocks       32 byte merkle headers appended in ascending order
    // @param txnsPerBlock number of transactions per block
    // @param feesPerBlock amount of fees the validator has collected per block
    // @param blockNum     the block number of the first header
    // @notice each block is capped at 2**16-1 transactions
    function submitBlock(bytes32[] memory headers, uint256[] memory txnsPerBlock, uint256[] memory feePerBlock, uint256 blockNum)
        public
        onlyOperator
    {
        require(blockNum == lastCommittedBlock.add(1));
        require(headers.length == txnsPerBlock.length && txnsPerBlock.length == feePerBlock.length);

        for (uint i = 0; i < headers.length && lastCommittedBlock <= lastBlockNum; i++) {
            require(headers[i] != bytes32(0) && txnsPerBlock[i] > 0 && txnsPerBlock[i] < feeIndex);

            lastCommittedBlock = lastCommittedBlock.add(1);
            plasmaChain[lastCommittedBlock] = plasmaBlock({
                header: headers[i],
                numTxns: txnsPerBlock[i],
                feeAmount: feePerBlock[i],
                createdAt: block.timestamp
            });

            emit BlockSubmitted(headers[i], lastCommittedBlock, txnsPerBlock[i], feePerBlock[i]);
        }
   }

    // @param owner owner of this deposit
    function deposit(address owner)
        public
        payable
    {
        deposits[depositNonce] = depositStruct(owner, msg.value, block.timestamp, block.number);
        emit Deposit(owner, msg.value, depositNonce, block.number);

        depositNonce = depositNonce.add(uint256(1));
    }

    // @param depositNonce the nonce of the specific deposit
    function startDepositExit(uint256 nonce, uint256 committedFee)
        public
        payable
        isBonded
    {
        require(deposits[nonce].owner == msg.sender);
        require(deposits[nonce].amount > committedFee);
        require(depositExits[nonce].state == ExitState.NonExistent);

        address owner = deposits[nonce].owner;
        uint256 amount = deposits[nonce].amount;
        uint256 priority = block.timestamp << 128 | nonce;
        depositExitQueue.insert(priority);
        depositExits[nonce] = exit({
            owner: owner,
            amount: amount,
            committedFee: committedFee,
            createdAt: block.timestamp,
            position: [0,0,0,nonce],
            state: ExitState.Pending
        });

        emit StartedDepositExit(nonce, owner, amount, committedFee);
    }

    // Transaction encoding:
    // [[Blknum1, TxIndex1, Oindex1, DepositNonce1, Input1ConfirmSig,
    //   Blknum2, TxIndex2, Oindex2, DepositNonce2, Input2ConfirmSig,
    //   NewOwner, Denom1, NewOwner, Denom2, Fee],
    //  [Signature1, Signature2]]
    //
    // All integers are padded to 32 bytes. Input&#39;s confirm signatures are 130 bytes for each input.
    // Zero bytes if unapplicable (deposit/fee inputs) Signatures are 65 bytes in length
    //
    // @param txBytes rlp encoded transaction
    // @notice this function will revert if the txBytes are malformed
    function decodeTransaction(bytes memory txBytes)
        internal
        pure
        returns (RLPReader.RLPItem[] memory txList, RLPReader.RLPItem[] memory sigList, bytes32 txHash)
    {
        // entire byte length of the rlp encoded transaction.
        require(txBytes.length == 811);

        RLPReader.RLPItem[] memory spendMsg = txBytes.toRlpItem().toList();
        require(spendMsg.length == 2);

        txList = spendMsg[0].toList();
        require(txList.length == 15);

        sigList = spendMsg[1].toList();
        require(sigList.length == 2);

        // bytes the signatures are over
        txHash = keccak256(spendMsg[0].toRlpBytes());
    }


    // @param txPos             location of the transaction [blkNum, txIndex, outputIndex]
    // @param txBytes           transaction bytes containing the exiting output
    // @param proof             merkle proof of inclusion in the plasma chain
    // @param confSig0          confirm signatures sent by the owners of the first input acknowledging the spend.
    // @param confSig1          confirm signatures sent by the owners of the second input acknowledging the spend (if applicable).
    // @notice `confirmSignatures` and `ConfirmSig0`/`ConfirmSig1` are unrelated to each other.
    // @notice `confirmSignatures` is either 65 or 130 bytes in length dependent on if a second input is present
    // @notice `confirmSignatures` should be empty if the output trying to be exited is a fee output
    function startTransactionExit(uint256[3] memory txPos, bytes memory txBytes, bytes memory proof, bytes memory confirmSignatures, uint256 committedFee)
        public
        payable
        isBonded
    {
        require(txPos[1] < feeIndex);
        uint256 position = calcPosition(txPos);
        require(txExits[position].state == ExitState.NonExistent);

        uint256 amount = startTransactionExitHelper(txPos, txBytes, proof, confirmSignatures);
        require(amount > committedFee);

        // calculate the priority of the transaction taking into account the withdrawal delay attack
        // withdrawal delay attack: https://github.com/FourthState/plasma-mvp-rootchain/issues/42
        uint256 createdAt = plasmaChain[txPos[0]].createdAt;
        txExitQueue.insert(SafeMath.max(createdAt.add(1 weeks), block.timestamp) << 128 | position);

        // write exit to storage
        txExits[position] = exit({
            owner: msg.sender,
            amount: amount,
            committedFee: committedFee,
            createdAt: block.timestamp,
            position: [txPos[0], txPos[1], txPos[2], 0],
            state: ExitState.Pending
        });

        emit StartedTransactionExit(txPos, msg.sender, amount, confirmSignatures, committedFee);
    }

    // @returns amount of the exiting transaction
    // @notice the purpose of this helper was to work around the capped evm stack frame
    function startTransactionExitHelper(uint256[3] memory txPos, bytes memory txBytes, bytes memory proof, bytes memory confirmSignatures)
        private
        view
        returns (uint256)
    {
        bytes32 txHash;
        RLPReader.RLPItem[] memory txList;
        RLPReader.RLPItem[] memory sigList;
        (txList, sigList, txHash) = decodeTransaction(txBytes);

        uint base = txPos[2].mul(2);
        require(msg.sender == txList[base.add(10)].toAddress());

        plasmaBlock memory blk = plasmaChain[txPos[0]];

        // Validation

        bytes32 merkleHash = sha256(txBytes);
        require(merkleHash.checkMembership(txPos[1], blk.header, proof, blk.numTxns));

        address recoveredAddress;
        bytes32 confirmationHash = sha256(abi.encodePacked(merkleHash, blk.header));

        bytes memory sig = sigList[0].toBytes();
        require(sig.length == 65 && confirmSignatures.length % 65 == 0 && confirmSignatures.length > 0 && confirmSignatures.length <= 130);
        recoveredAddress = confirmationHash.recover(confirmSignatures.slice(0, 65));
        require(recoveredAddress != address(0) && recoveredAddress == txHash.recover(sig));
        if (txList[5].toUintStrict() > 0 || txList[8].toUintStrict() > 0) { // existence of a second input
            sig = sigList[1].toBytes();
            require(sig.length == 65 && confirmSignatures.length == 130);
            recoveredAddress = confirmationHash.recover(confirmSignatures.slice(65, 65));
            require(recoveredAddress != address(0) && recoveredAddress == txHash.recover(sig));
        }

        // check that the UTXO&#39;s two direct inputs have not been previously exited
        require(validateTransactionExitInputs(txList));

        return txList[base.add(11)].toUintStrict();
    }

    // For any attempted exit of an UTXO, validate that the UTXO&#39;s two inputs have not
    // been previously exited or are currently pending an exit.
    function validateTransactionExitInputs(RLPReader.RLPItem[] memory txList)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < 2; i++) {
            ExitState state;
            uint256 base = uint256(5).mul(i);
            uint depositNonce_ = txList[base.add(3)].toUintStrict();
            if (depositNonce_ == 0) {
                uint256 blkNum = txList[base].toUintStrict();
                uint256 txIndex = txList[base.add(1)].toUintStrict();
                uint256 outputIndex = txList[base.add(2)].toUintStrict();
                uint256 position = calcPosition([blkNum, txIndex, outputIndex]);
                state = txExits[position].state;
            } else
                state = depositExits[depositNonce_].state;

            if (state != ExitState.NonExistent && state != ExitState.Challenged)
                return false;
        }

        return true;
    }

    // Validator of any block can call this function to exit the fees collected
    // for that particular block. The fee exit is added to exit queue with the lowest priority for that block.
    // In case of the fee UTXO already spent, anyone can challenge the fee exit by providing
    // the spend of the fee UTXO.
    // @param blockNumber the block for which the validator wants to exit fees
    function startFeeExit(uint256 blockNumber, uint256 committedFee)
        public
        payable
        onlyOperator
        isBonded
    {
        plasmaBlock memory blk = plasmaChain[blockNumber];
        require(blk.header != bytes32(0));

        uint256 feeAmount = blk.feeAmount;

        // nonzero fee and prevent and greater than the committed fee if spent.
        // default value for a fee amount is zero. Will revert if a block for
        // this number has not been committed
        require(feeAmount > committedFee);

        // a fee UTXO has explicitly defined position [blockNumber, 2**16 - 1, 0]
        uint256 position = calcPosition([blockNumber, feeIndex, 0]);
        require(txExits[position].state == ExitState.NonExistent);

        txExitQueue.insert(SafeMath.max(blk.createdAt.add(1 weeks), block.timestamp) << 128 | position);

        txExits[position] = exit({
            owner: msg.sender,
            amount: feeAmount,
            committedFee: committedFee,
            createdAt: block.timestamp,
            position: [blockNumber, feeIndex, 0, 0],
            state: ExitState.Pending
        });

        // pass in empty bytes for confirmSignatures for StartedTransactionExit event.
        emit StartedTransactionExit([blockNumber, feeIndex, 0], operator, feeAmount, "", 0);
}

    // @param exitingTxPos     position of the invalid exiting transaction [blkNum, txIndex, outputIndex]
    // @param challengingTxPos position of the challenging transaction [blkNum, txIndex]
    // @param txBytes          raw transaction bytes of the challenging transaction
    // @param proof            proof of inclusion for this merkle hash
    // @param confirmSignature signature used to invalidate the invalid exit. Signature is over (merkleHash, block header)
    // @notice The operator can challenge an exit which commits an invalid fee by simply passing in empty bytes for confirm signature as they are not needed.
    //         The committed fee is checked againt the challenging tx bytes
    function challengeExit(uint256[4] memory exitingTxPos, uint256[2] memory challengingTxPos, bytes memory txBytes, bytes memory proof, bytes memory confirmSignature)
        public
    {
        bytes32 txHash;
        RLPReader.RLPItem[] memory txList;
        RLPReader.RLPItem[] memory sigList;
        (txList, sigList, txHash) = decodeTransaction(txBytes);

        // `challengingTxPos` is sequentially after `exitingTxPos`
        require(exitingTxPos[0] < challengingTxPos[0] || (exitingTxPos[0] == challengingTxPos[0] && exitingTxPos[1] < challengingTxPos[1]));

        // must be a direct spend
        bool firstInput = exitingTxPos[0] == txList[0].toUintStrict() && exitingTxPos[1] == txList[1].toUintStrict() && exitingTxPos[2] == txList[2].toUintStrict() && exitingTxPos[3] == txList[3].toUintStrict();
        require(firstInput || exitingTxPos[0] == txList[5].toUintStrict() && exitingTxPos[1] == txList[6].toUintStrict() && exitingTxPos[2] == txList[7].toUintStrict() && exitingTxPos[3] == txList[8].toUintStrict());

        // transaction to be challenged should have a pending exit
        exit storage exit_ = exitingTxPos[3] == 0 ? 
            txExits[calcPosition([exitingTxPos[0], exitingTxPos[1], exitingTxPos[2]])] : depositExits[exitingTxPos[3]];
        require(exit_.state == ExitState.Pending);

        plasmaBlock memory blk = plasmaChain[challengingTxPos[0]];

        bytes32 merkleHash = sha256(txBytes);
        require(blk.header != bytes32(0) && merkleHash.checkMembership(challengingTxPos[1], blk.header, proof, blk.numTxns));

        address recoveredAddress;
        // we check for confirm signatures if:
        // The exiting tx is a first input and commits the correct fee
        // OR
        // The exiting tx is the second input in the challenging transaction
        //
        // If this challenge was a fee mismatch, then we check the first transaction signature
        // to prevent the operator from forging invalid inclusions
        //
        // For a fee mismatch, the state becomes `NonExistent` so that the exit can be reopened.
        // Otherwise, `Challenged` so that the exit can never be opened.
        if (firstInput && exit_.committedFee != txList[14].toUintStrict()) {
            bytes memory sig = sigList[0].toBytes();
            recoveredAddress = txHash.recover(sig);
            require(sig.length == 65 && recoveredAddress != address(0) && exit_.owner == recoveredAddress);

            exit_.state = ExitState.NonExistent;
        } else {
            bytes32 confirmationHash = sha256(abi.encodePacked(merkleHash, blk.header));
            recoveredAddress = confirmationHash.recover(confirmSignature);
            require(confirmSignature.length == 65 && recoveredAddress != address(0) && exit_.owner == recoveredAddress);

            exit_.state = ExitState.Challenged;
        }

        // exit successfully challenged. Award the sender with the bond
        balances[msg.sender] = balances[msg.sender].add(minExitBond);
        totalWithdrawBalance = totalWithdrawBalance.add(minExitBond);
        emit AddedToBalances(msg.sender, minExitBond);

        emit ChallengedExit(exit_.position, exit_.owner, exit_.amount - exit_.committedFee);
    }

    function finalizeDepositExits() public { finalize(depositExitQueue, true); }
    function finalizeTransactionExits() public { finalize(txExitQueue, false); }

    // Finalizes exits by iterating through either the depositExitQueue or txExitQueue.
    // Users can determine the number of exits they&#39;re willing to process by varying
    // the amount of gas allow finalize*Exits() to process.
    // Each transaction takes < 80000 gas to process.
    function finalize(uint256[] storage queue, bool isDeposits)
        private
    {
        if (queue.length == 0) return;

        // retrieve the lowest priority and the appropriate exit struct
        uint256 priority = queue[0];
        exit memory currentExit;
        uint256 position;
        // retrieve the right 128 bits from the priority to obtain the position
        assembly {
   	        position := and(priority, div(not(0x0), exp(256, 16)))
		}

        currentExit = isDeposits ? depositExits[position] : txExits[position];

        /*
        * Conditions:
        *   1. Exits exist
        *   2. Exits must be a week old
        *   3. Funds must exist for the exit to withdraw
        */
        uint256 amountToAdd;
        uint256 challengePeriod = isDeposits ? 5 days : 1 weeks;
        while (block.timestamp.sub(currentExit.createdAt) > challengePeriod &&
               plasmaChainBalance() > 0 &&
               gasleft() > 80000) {

            // skip currentExit if it is not in &#39;started/pending&#39; state.
            if (currentExit.state != ExitState.Pending) {
                queue.delMin();
            } else {
                // reimburse the bond but remove fee allocated for the operator
                amountToAdd = currentExit.amount.add(minExitBond).sub(currentExit.committedFee);
                
                balances[currentExit.owner] = balances[currentExit.owner].add(amountToAdd);
                totalWithdrawBalance = totalWithdrawBalance.add(amountToAdd);

                if (isDeposits)
                    depositExits[position].state = ExitState.Finalized;
                else
                    txExits[position].state = ExitState.Finalized;

                emit FinalizedExit(currentExit.position, currentExit.owner, amountToAdd);
                emit AddedToBalances(currentExit.owner, amountToAdd);

                // move onto the next oldest exit
                queue.delMin();
            }

            if (queue.length == 0) {
                return;
            }

            // move onto the next oldest exit
            priority = queue[0];
            
            // retrieve the right 128 bits from the priority to obtain the position
            assembly {
   			    position := and(priority, div(not(0x0), exp(256, 16)))
		    }
             
            currentExit = isDeposits ? depositExits[position] : txExits[position];
        }
    }

    // @notice will revert if the output index is out of bounds
    function calcPosition(uint256[3] memory txPos)
        private
        view
        returns (uint256)
    {
        require(validatePostion([txPos[0], txPos[1], txPos[2], 0]));

        uint256 position = txPos[0].mul(blockIndexFactor).add(txPos[1].mul(txIndexFactor)).add(txPos[2]);
        require(position <= 2**128-1); // check for an overflow

        return position;
    }

    function validatePostion(uint256[4] memory position)
        private
        view
        returns (bool)
    {
        uint256 blkNum = position[0];
        uint256 txIndex = position[1];
        uint256 oIndex = position[2];
        uint256 depNonce = position[3];

        if (blkNum > 0) { // utxo input
            // uncommitted block
            if (blkNum > lastCommittedBlock)
                return false;
            // txIndex out of bounds for the block
            if (txIndex >= plasmaChain[blkNum].numTxns && txIndex != feeIndex)
                return false;
            // fee input must have a zero output index
            if (txIndex == feeIndex && oIndex > 0)
                return false;
            // deposit nonce must be zero
            if (depNonce > 0)
                return false;
            // only two outputs
            if (oIndex > 1)
                return false;
        } else { // deposit or fee input
            // deposit input must be zero&#39;d output position
            // `blkNum` is not checked as it will fail above
            if (depNonce > 0 && (txIndex > 0 || oIndex > 0))
                return false;
        }

        return true;
    }

    function withdraw()
        public
        returns (uint256)
    {
        if (balances[msg.sender] == 0) {
            return 0;
        }

        uint256 transferAmount = balances[msg.sender];
        delete balances[msg.sender];
        totalWithdrawBalance = totalWithdrawBalance.sub(transferAmount);

        // will revert the above deletion if it fails
        msg.sender.transfer(transferAmount);
        return transferAmount;
    }

    /*
    * Getters
    */

    function plasmaChainBalance()
        public
        view
        returns (uint)
    {
        // takes into accounts the failed withdrawals
        return address(this).balance - totalWithdrawBalance;
    }

    function balanceOf(address _address)
        public
        view
        returns (uint256)
    {
        return balances[_address];
    }

    function txQueueLength()
        public
        view
        returns (uint)
    {
        return txExitQueue.length;
    }

    function depositQueueLength()
        public 
        view
        returns (uint)
    {   
        return depositExitQueue.length;
    }
}