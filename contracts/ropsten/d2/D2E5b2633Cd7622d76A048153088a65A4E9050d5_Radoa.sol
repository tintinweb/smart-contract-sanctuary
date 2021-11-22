// PDX-License-Identifier: UNLICENSED"

pragma solidity >=0.4.22 <=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./UpdateMsgVerifier.sol";
import "./DeviceRegister.sol";

contract Radoa is DeviceRegister, UpdateMsgVerifier {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint64;

    event InitRadoa(address indexed owner);
    event InitDevice(bytes32 indexed deviceId, uint64 indexed timestamp, uint32 indexed index, bytes publicKey);
    event AddUpdateMsg(bytes32 indexed deviceId, uint32 indexed index, bytes32 indexed stateHash);
    event ConfirmUpdateMsg(bytes32 indexed deviceId, uint32 indexed index);

    mapping (bytes32=>bool) isInitializedOfDeviceId;
    mapping (bytes32=>UpdateMsgVerifier.UpdateMsg) lastMsgOfDeviceId;
    mapping (bytes32=>mapping(bytes4=>bytes32)) addedMsgHashAtIndexOfDeviceId;
    mapping (bytes32=>mapping(bytes4=>bytes32[MAX_VDF_NODE_NUMBER])) authorizedRootsAtIndexOfDeviceId;
    mapping (bytes32=>uint32) lastConfirmedIndexOfDeviceId;
    mapping (bytes32=>mapping(bytes32=>bool)) isConfirmedRootForMsgHash;
    address owner;

    modifier onlyInitializedDevice(bytes32 _deviceId) {
        require(_deviceId!=bytes32(0), "invalid device id");
        require(isInitializedOfDeviceId[_deviceId],"not initialized device");
        _;
    }

    constructor(address _timer) UpdateMsgVerifier(_timer) public {
        owner = msg.sender;
        emit InitRadoa(owner);
    }

    function getLastIndex(bytes32 _deviceId) public view onlyInitializedDevice(_deviceId) returns (bytes4) {
        return lastMsgOfDeviceId[_deviceId].index;
    }

    function getStateHash(bytes32 _deviceId) public view onlyInitializedDevice(_deviceId) returns (bytes32) {
        return lastMsgOfDeviceId[_deviceId].stateHash;
    }
    
    function getTimestamp(bytes32 _deviceId) public view onlyInitializedDevice(_deviceId) returns (bytes8) {
        return lastMsgOfDeviceId[_deviceId].timestamp;
    }

    function isHealthDeviceNow(bytes32 _deviceId) public view returns (bool) {
        return isHealthDeviceAtIndex(_deviceId, timer.getLastClosedIndex());
    }

    function isHealthDeviceAtIndex(bytes32 _deviceId, uint64 _index) public view onlyInitializedDevice(_deviceId) returns (bool) {
        uint64 confirmedIndex = lastConfirmedIndexOfDeviceId[_deviceId];
        return confirmedIndex >= _index;
    }

    function getLastClosedIndex() public view returns (uint32) {
        return timer.getLastClosedIndex();
    }

    function getCloseTime(bytes4 _index) public view returns (uint64) {
        return timer.getCloseTime(_index);
    }

    function isOpenedIndex(uint32 _index) public view returns (bool) {
        return timer.isOpenedIndex(_index);
    }

    function computeOpenTime(uint32 _index) public view returns (uint64) {
        return timer.computeOpenTime(_index);
    }

    function computetLastOpenedIndex() public view returns (uint32) {
        return timer.computetLastOpenedIndex();
    }

    function initDevice(bytes8 _timestamp) public {
        bytes32 deviceId  = getDeviceIdOfAddress(msg.sender);
        require(deviceId!=bytes32(0), "invalid device id");
        isInitializedOfDeviceId[deviceId] = true;
        lastMsgOfDeviceId[deviceId].deviceId = deviceId;
        lastMsgOfDeviceId[deviceId].previousHash = bytes32(0);
        lastMsgOfDeviceId[deviceId].stateHash = bytes32(0);
        lastMsgOfDeviceId[deviceId].index = bytes4(timer.computetLastOpenedIndex());
        lastMsgOfDeviceId[deviceId].timestamp = _timestamp;
        lastMsgOfDeviceId[deviceId].publicKey = getInitKeyOfDeviceId(deviceId);
        emit InitDevice(deviceId, uint64(_timestamp), timer.getLastClosedIndex(), getInitKeyOfDeviceId(deviceId));
    }

    function addUpdateMsg(
        bytes32 _newStateHash, 
        bytes8 _newTimestamp, 
        bytes memory _newPublicKey, 
        bytes memory _signature,
        bytes32[MAX_VDF_NODE_NUMBER] calldata _authorizedRoots
    ) public onlyInitializedDevice(getDeviceIdOfAddress(msg.sender)) {
        bytes32 deviceId = getDeviceIdOfAddress(msg.sender);
        require(deviceId!=bytes32(0),"code 0 in registerDevice");
        require(isInitializedOfDeviceId[deviceId],"code 1 in registerDevice");
        //require(isHealthDeviceNow(deviceId),"code 2 in addUpdateMsg");
        UpdateMsgVerifier.UpdateMsg memory lastMsg = lastMsgOfDeviceId[deviceId];
        bytes4 oldIndex = lastMsg.index;
        uint32 newIndex = uint32(uint32(oldIndex).add(1));
        uint limitTime = uint256(timer.computeOpenTime(uint32(newIndex))).add(timer.submissionPeriod());
        require(block.timestamp<=limitTime,"code 2 in addUpdateMsg");
        UpdateMsg memory newMsg;
        newMsg.deviceId = lastMsg.deviceId;
        newMsg.previousHash = hasher(lastMsg);
        newMsg.index = bytes4(newIndex);
        newMsg.stateHash = _newStateHash;
        newMsg.timestamp = _newTimestamp;
        newMsg.publicKey = _newPublicKey;
        newMsg.authorizedRoots = _authorizedRoots;
        Signature memory updateSignature = SignatureVerifier.decodeSignature(_signature);
        attestMsgValidity(lastMsg, newMsg, updateSignature);
        lastMsgOfDeviceId[deviceId].deviceId = newMsg.deviceId;
        lastMsgOfDeviceId[deviceId].previousHash = newMsg.previousHash;
        lastMsgOfDeviceId[deviceId].index = newMsg.index;
        lastMsgOfDeviceId[deviceId].stateHash = newMsg.stateHash;
        lastMsgOfDeviceId[deviceId].timestamp = newMsg.timestamp;
        lastMsgOfDeviceId[deviceId].publicKey = newMsg.publicKey;
        lastMsgOfDeviceId[deviceId].authorizedRoots = newMsg.authorizedRoots;
        addedMsgHashAtIndexOfDeviceId[deviceId][newMsg.index] = hasher(newMsg);
        authorizedRootsAtIndexOfDeviceId[deviceId][oldIndex] = _authorizedRoots;
        emit AddUpdateMsg(deviceId, newIndex, _newStateHash);
    }

    function confirmUpdateMsg(
        bytes32 _deviceId,
        bytes32[][MAX_VDF_NODE_NUMBER] memory _proofArray
    ) public onlyInitializedDevice(_deviceId) {
        bytes32 deviceId = getDeviceIdOfAddress(msg.sender);
        require(deviceId!=bytes32(0),"code 0 in confirmUpdateMsg");
        require(isInitializedOfDeviceId[deviceId],"code 1 in confirmUpdateMsg");
        //require(isHealthDeviceNow(deviceId),"code 2 in addUpdateMsg");
        uint32 lastIndex = uint32(lastConfirmedIndexOfDeviceId[deviceId]);
        uint32 confirmedIndex = uint32(uint256(lastIndex).add(1));
        bytes32 msgHash = addedMsgHashAtIndexOfDeviceId[deviceId][bytes4(confirmedIndex)];
        require(msgHash!=bytes32(0),"code 2 in confirmUpdateMsg");
        bytes32 previousHash = addedMsgHashAtIndexOfDeviceId[deviceId][bytes4(lastIndex)];
        bytes32[MAX_VDF_NODE_NUMBER] memory authorizedRoots;
        for(uint32 i=0;i<MAX_VDF_NODE_NUMBER;i++){
            authorizedRoots[i] = authorizedRootsAtIndexOfDeviceId[deviceId][bytes4(confirmedIndex)][i];
        }
        bytes memory confirmedRootBytes = attestMsgAvailability(msgHash, previousHash, confirmedIndex, authorizedRoots, _proofArray);
        bytes32[] memory confirmedRoots = abi.decode(confirmedRootBytes,(bytes32[]));
        lastConfirmedIndexOfDeviceId[deviceId] = confirmedIndex;
        for(uint32 i=0;i<confirmedRoots.length;i++){
            isConfirmedRootForMsgHash[msgHash][confirmedRoots[i]] = true;
        }
        emit ConfirmUpdateMsg(_deviceId, confirmedIndex);
    }

    function closeAttestation() public {
        timer.closeAttestation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.4.22 <=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./SignatureVerifier.sol";
import "./VDFHashManager.sol";

contract UpdateMsgVerifier is SignatureVerifier, VDFHashManager {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint64;
    using MerkleProof for bytes32[];

    uint constant DEVICE_ID_SIZE = 32;
    uint constant PREVIOUS_HASH_SIZE = 32;
    uint constant STATE_HASH_SIZE = 32;
    uint constant INDEX_SIZE = 4;
    uint constant TIMESTAMP_SIZE = 8;
    uint constant PUBLIC_KEY_SIZE = 64;
    uint constant ROOT_SIZE = 32;
    uint constant MAX_VDF_NODE_NUMBER = 50;
    uint constant UPDATE_MSG_SIZE = DEVICE_ID_SIZE + PREVIOUS_HASH_SIZE + STATE_HASH_SIZE + INDEX_SIZE + TIMESTAMP_SIZE + PUBLIC_KEY_SIZE + MAX_VDF_NODE_NUMBER*ROOT_SIZE;

    uint constant NUM_OF_REQUIRED_VDF = 34;

    struct UpdateMsg {
        bytes32 deviceId;
        bytes32 previousHash;
        bytes32 stateHash;
        bytes4 index;
        bytes8 timestamp;
        bytes publicKey;
        bytes32[MAX_VDF_NODE_NUMBER] authorizedRoots;
    }

    constructor(address _timer) VDFHashManager(_timer) public {}

    function toBytes(UpdateMsg memory _msg) private pure returns (bytes memory) {
        bytes memory msgBytes1 = abi.encodePacked(_msg.deviceId,_msg.previousHash,_msg.stateHash,_msg.index,_msg.timestamp,_msg.publicKey);
        bytes memory msgBytes2 = msgBytes1;
        for(uint16 i=0;i<MAX_VDF_NODE_NUMBER;i++) {
            msgBytes2 = abi.encodePacked(msgBytes2,_msg.authorizedRoots[i]);
        }
        require(msgBytes2.length==UPDATE_MSG_SIZE,"Invalid MsgSize");
        return msgBytes2;
    }

    function hasher(UpdateMsg memory _msg) internal pure returns (bytes32) {
        bytes memory inputBytes = toBytes(_msg);
        bytes32 hashed = sha256(inputBytes);
        return hashed;
    }

    function attestMsgValidity(UpdateMsg memory _oldMsg, UpdateMsg memory _newMsg, Signature memory _updateSignature) internal view {
        require(uint64(_oldMsg.timestamp).add(timer.updatePeriod()) <= uint64(_newMsg.timestamp),"too old timestamp");
        require(uint64(_newMsg.timestamp) <  uint64(_oldMsg.timestamp).add(2*timer.updatePeriod()),"too new timestamp");
        address oldAddress = address(uint160(uint256(keccak256(_oldMsg.publicKey))));//_old_msg.publicKey != _new_msg.publicKey;
        address newAddress = address(uint160(uint256(keccak256(_newMsg.publicKey))));
        require(oldAddress!=newAddress,"invalid publicKey");
        bytes32 updateHash = hasher(_newMsg);
        address validAddress = SignatureVerifier.recover(updateHash,_updateSignature);
        require(oldAddress == validAddress,"invalid signature");
    }

    function attestMsgAvailability(
        bytes32 _oldMsgHash,
        bytes32 _previousHash,
        uint32 _index,
        bytes32[MAX_VDF_NODE_NUMBER] memory _authorizedRoots,
        bytes32[][MAX_VDF_NODE_NUMBER] memory _proofArray
    ) internal view returns (bytes memory) {
        uint numValidVDF = 0;
        bytes32 leaf = _oldMsgHash;
        bytes32 seedHash = _previousHash;
        require(_authorizedRoots.length==MAX_VDF_NODE_NUMBER, "_authorizedRoots.length!=MAX_VDF_NODE_NUMBER");
        bool[] memory notUsedNodeIds;
        for(uint32 i=0;i<MAX_VDF_NODE_NUMBER;i++){
            uint64 nextNodeId = _computeNextNodeId(seedHash,_index);
            notUsedNodeIds[nextNodeId] = true;
            seedHash = sha256(abi.encodePacked(seedHash));
        }
        bytes memory confirmedRoots = abi.encodePacked();
        for(uint32 i=0;i<MAX_VDF_NODE_NUMBER;i++) {
            bytes32 root = _authorizedRoots[i];
            if(!verifiedRootHashes[root]){
                continue;
            }
            bool isNotUsedRoot = notUsedNodeIds[getNodeIdOfRootHash(root)];
            notUsedNodeIds[getNodeIdOfRootHash(root)] = false;
            if(!isNotUsedRoot){
                continue;
            }
            bytes32[] memory proof = _proofArray[i];
            bool isValidProof = proof.verify(root, leaf);
            if(!isValidProof){
                continue;
            }
            numValidVDF = numValidVDF.add(1);
            confirmedRoots = abi.encodePacked(confirmedRoots, root);
        }
        require(numValidVDF >= NUM_OF_REQUIRED_VDF, "numValidVDF < NUM_OF_REQUIRED_VDF");
        return confirmedRoots;
    }

    function _computeNextNodeId(bytes32 _seedHash,uint32 _index) private view returns (uint64) {
        uint64 numNodes = getNumNodesAtIndex(_index);
        uint64 nodeId = uint64(uint256(_seedHash) % uint256(numNodes)+1);
        return nodeId;
    }
}

pragma solidity >=0.4.22 <=0.8.0;
pragma experimental ABIEncoderV2;

contract DeviceRegister {
    event RegisterDevice(address indexed deviceAddress, bytes32 indexed deviceId, bytes indexed publicKey);

    mapping (address=>bytes32) deviceIdOfAddress;
    mapping (bytes32=>address) authorizerOfDeviceId;
    mapping (bytes32=>bytes) initKeyOfDeviceId;

    function getDeviceIdOfAddress(address _address) public view returns (bytes32) {
        return deviceIdOfAddress[_address];
    }

    function getAuthorizerOfDeviceId(bytes32 _deviceId) public view returns (address) {
        return authorizerOfDeviceId[_deviceId];
    }

    function getInitKeyOfDeviceId(bytes32 _deviceId) public view returns (bytes memory) {
        return initKeyOfDeviceId[_deviceId];
    }

    function registerDevice(address _deviceAddress, bytes32 _deviceId, bytes memory _publicKey) public {
        require(deviceIdOfAddress[_deviceAddress]==bytes32(0), "code 0 in registerDevice");
        require(authorizerOfDeviceId[_deviceId]==address(0), "code 1 in registerDevice");
        require(_publicKey.length==64 && keccak256(_publicKey)!=keccak256(abi.encodePacked(bytes32(0),bytes32(0))), "code 2 in registerDevice");
        deviceIdOfAddress[_deviceAddress] = _deviceId;
        authorizerOfDeviceId[_deviceId] = msg.sender;
        initKeyOfDeviceId[_deviceId] = _publicKey;
        emit RegisterDevice(_deviceAddress, _deviceId, _publicKey);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

pragma solidity >=0.4.22 <=0.8.0;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

contract SignatureVerifier {
    using ECDSA for bytes32;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function recover(bytes32 _hash, Signature memory _signature) internal pure returns (address) {
        bytes32 eth_msg = _hash.toEthSignedMessageHash();
        return eth_msg.recover(_signature.v, _signature.r, _signature.s);
    }

    function decodeSignature(bytes memory _bytes) internal pure returns (Signature memory) {
        require(_bytes.length==65, "code 0 in monitored log");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_bytes, 32))
            s := mload(add(_bytes, 64))
            v := byte(0, mload(add(_bytes, 96)))
        }
        Signature memory sig;
        sig.r = r;
        sig.s = s;
        sig.v = v;
        return sig;
    }
}

pragma solidity >=0.4.22 <=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/VerifyVDFForRoot.sol";
import "./VDFNodeManager.sol";

contract VDFHashManager is VerifyVDFForRoot, VDFNodeManager {
    using SafeMath for uint256;

    event AddRoots(uint64 indexed nodeId, uint32 indexed newIndex);
    event LimitTime(uint indexed limitTime, uint indexed blockTime);

    uint constant VDF_SUBMISSION_LATENCY_SEC = 30;

    mapping(bytes32=>bool) verifiedRootHashes;
    mapping(bytes32=>uint64) nodeIdOfRootHash;
    mapping(uint64=>bytes32) lastVDFHashOfNodeId;
    mapping(uint64=>uint32) lastIndexOfNodeId;
    mapping(bytes32=>address) nodeAddressOfRoot;

    constructor(address _timer) VerifyVDFForRoot() VDFNodeManager(_timer) public {}

    function isVerifiedRoot(bytes32 _merkleRoot) public view returns (bool) {
        return verifiedRootHashes[_merkleRoot];
    }

    function getNodeIdOfRootHash(bytes32 _merkleRoot) public view returns (uint64) {
        return nodeIdOfRootHash[_merkleRoot];
    }

    function getLastVDFHashOfNodeId(uint64 _nodeId) public view returns (bytes32) {
        return lastVDFHashOfNodeId[_nodeId];
    }

    function getLastIndexOfNodeId(uint64 _nodeId) public view returns (uint64) {
        return lastIndexOfNodeId[_nodeId];
    }

    function addRoots(uint64 _nodeId, uint32 _newIndex, bytes32[] memory _merkleRoots, bytes[] memory _pi, bytes[] memory _y, bytes[] memory _q, uint256[] memory _nonce) public {
        require(VDFNodeManager.isValidVDFNode(_nodeId), "invalid vdf node");
        uint numProof = _pi.length;
        require(numProof==_merkleRoots.length && numProof==_y.length && numProof==_q.length && numProof==_nonce.length, "invalid proof length");
        attestIndexAndTime(_nodeId, _newIndex, numProof);
        VDFProof memory proof;
        for(uint i=0;i<numProof;i++){
            proof.pi = _pi[i];
            proof.y = _y[i];
            proof.q = _q[i];
            proof.nonce = _nonce[i];
            addSingleRoot(_nodeId, msg.sender, _merkleRoots[i], proof);
        }
        lastIndexOfNodeId[_nodeId] = _newIndex;
        emit AddRoots(_nodeId, _newIndex);
    }

    function attestIndexAndTime(uint64 _nodeId, uint32 _newIndex, uint256 _numProof) private {
        uint lastIndex = uint256(uint32(lastIndexOfNodeId[_nodeId]));
        if(lastIndex==0){
            lastIndex = getJoinedIndexOfNodeId(_nodeId);
        }
        require(uint256(_newIndex).sub(lastIndex)==_numProof, "invalid numProof");
        uint32 limitIndex = uint32(uint256(uint32(lastIndex)).add(_numProof).add(2));
        uint limitTime = uint(timer.computeOpenTime(limitIndex)).add(VDF_SUBMISSION_LATENCY_SEC);
        emit LimitTime(limitTime,timer.getBlockTimestamp());
        //require(timer.getBlockTimestamp()<=limitTime, "over limitTime");
    }
    
    function addSingleRoot(uint64 _nodeId, address _nodeAddress, bytes32 _merkleRoot, VDFProof memory _proof) internal {
        require(_merkleRoot==bytes32(0) || !verifiedRootHashes[_merkleRoot],"already added root");
        bytes32 previousVdfHash = lastVDFHashOfNodeId[_nodeId];
        bool result = VerifyVDFForRoot.verifySingleVDFProof(previousVdfHash, _merkleRoot, _proof);
        require(result, "invalid vdf");
        verifiedRootHashes[_merkleRoot] = true;
        nodeIdOfRootHash[_merkleRoot] = _nodeId;
        lastVDFHashOfNodeId[_nodeId] = sha256(_proof.y);
        nodeAddressOfRoot[_merkleRoot] = _nodeAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity >=0.4.22 <=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../packages/evmvdf/contracts/VerifyVDF.sol";
import "hardhat/console.sol";

contract VerifyVDFForRoot is VerifyVDF {
    using SafeMath for uint256;

    uint constant DELAY = 13;

    struct VDFProof {
        bytes pi;
        bytes y;
        bytes q;
        uint256 nonce;
    }

    function verifySingleVDFProof(bytes32 _previousVdfHash, bytes32 _merkleRoot, VDFProof memory _proof) internal returns (bool) {
        bytes memory hash_input = abi.encodePacked([_previousVdfHash, _merkleRoot]);
        bytes32 zero = bytes32(0);
        bytes32 seed = keccak256(abi.encodePacked(sha256(hash_input)));
        bytes memory g = abi.encodePacked(zero,zero,zero,zero,zero,zero,zero,seed);
        bytes memory dst = abi.encodePacked();
        bool result = VerifyVDF.verify(g, _proof.pi, _proof.y, _proof.q, dst, _proof.nonce, DELAY);
        return result;
    }
}

pragma solidity >=0.4.22 <=0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./RadoaERC20.sol";
import "./Timer.sol";

contract VDFNodeManager is RadoaERC20 {
    using SafeMath for uint256;

    event RegisterVDFNode(address indexed nodeAddress, uint256 indexed blockNumber);
    event AddDBKeys(address indexed nodeAddress);
    event Ready(address indexed nodeAddress);
    event UpdateVDFNodes(uint32 indexed index, uint64 indexed nowMaxNodeId, uint64 indexed nextMaxNodeId);

    uint256 constant requiredStakeAmount = 100;
    uint256 constant requiredWaitBlockNumber = 1;/*10;*/
    uint32 constant idUpdateIndexInterval = 2;/*12;*/

    mapping (address=>bool) registeredVDFNodes;
    mapping (address=>uint) registeredBlockOfVDFNodes;
    mapping (uint64=>address) nowAddressOfNodeId;
    mapping (uint64=>address) nextAddressOfNodeId;
    mapping (address=>uint64) nowNodeIdOfAddress;
    mapping (address=>bool) workingVDFNodes;
    mapping (uint32=>uint64) numNodesAtIndex;
    mapping (uint64=>uint32) joinedIndexOfNodeId;
    mapping (address=>string) logDBKeyOfAddress;
    mapping (address=>string) KVDBKeyOfAddress;
    mapping (address=>string) docsDBKeyOfAddress;
    uint64 nowMaxNodeId;
    uint64 nextMaxNodeId;
    address[] readyNodeAddresses;
    uint32 lastStartedIndex;

    ITimer timer;

    constructor(address _timer) public {
        nowMaxNodeId = 0;
        nextMaxNodeId = 0;
        lastStartedIndex = 0;
        timer = ITimer(_timer);
    }

    function getRequiredStakeAmount() public pure returns (uint256) {
        return requiredStakeAmount;
    }

    function getRegisteredWaitBlockNumber() public pure returns (uint256) {
        return requiredWaitBlockNumber;
    }

    function getIdUpdateIndexInterval() public pure returns (uint32) {
        return idUpdateIndexInterval;
    }

    function isVDFNodeRegistered(address _nodeAddress) public view returns (bool) {
        return registeredVDFNodes[_nodeAddress];
    }

    function isVDFNodeWorking(address _nodeAddress) public view returns (bool) {
        return workingVDFNodes[_nodeAddress];
    }

    function getRegisteredBlockOfVDFNode(address _nodeAddress) public view returns (uint) {
        return registeredBlockOfVDFNodes[_nodeAddress];
    }   

    function getNowAddressOfNodeId(uint64 _nodeId) public view returns (address) {
        return nowAddressOfNodeId[_nodeId];
    }

    function getNextAddressOfNodeId(uint64 _nodeId) public view returns (address) {
        return nextAddressOfNodeId[_nodeId];
    }

    function getNowNodeIdOfAddress(address _address) public view returns (uint64) {
        return nowNodeIdOfAddress[_address];
    }

    function getNumNodesAtIndex(uint32 _index) public view returns (uint64) {
        return numNodesAtIndex[_index];
    }

    function getJoinedIndexOfNodeId(uint64 _nodeId) public view returns (uint32) {
        return joinedIndexOfNodeId[_nodeId];
    }

    function getLogDBKeyOfAddress(address _address) public view returns (string memory) {
        return logDBKeyOfAddress[_address];
    }

    function getKVDBKeyOfAddress(address _address) public view returns (string memory) {
        return KVDBKeyOfAddress[_address];
    }

    function getDocsDBKeyOfAddress(address _address) public view returns (string memory) {
        return docsDBKeyOfAddress[_address];
    }

    function getNowMaxId() public view returns (uint64) {
        return nowMaxNodeId;
    }

    function getNextMaxId() public view returns (uint64) {
        return nextMaxNodeId;
    }

    function getLastStartedIndex() public view returns (uint32) {
        return lastStartedIndex;
    }

    function isValidVDFNode(uint64 _nodeId) public view returns (bool) {
        return msg.sender == nowAddressOfNodeId[_nodeId];
    }

    function registerVDFNode() public {
        address nodeAddress = msg.sender;
        require(!registeredVDFNodes[nodeAddress], "already registered");
        require(allowance(nodeAddress, address(this))>=requiredStakeAmount,"insufficient approvement");
        require(transfer(address(this),requiredStakeAmount), "fail to transfer ERC20");
        registeredVDFNodes[nodeAddress] = true;
        registeredBlockOfVDFNodes[nodeAddress] = timer.getBlockNumber();
        emit RegisterVDFNode(nodeAddress, timer.getBlockNumber());
    }

    function addDBKeys(string calldata _logDBKey, string calldata _KVDBKey, string calldata _docsDBKey) public {
        address nodeAddress = msg.sender;
        require(registeredVDFNodes[nodeAddress], "not registered");
        require(!workingVDFNodes[nodeAddress], "already working");
        logDBKeyOfAddress[nodeAddress] = _logDBKey;
        KVDBKeyOfAddress[nodeAddress] = _KVDBKey;
        docsDBKeyOfAddress[nodeAddress] = _docsDBKey;
        emit AddDBKeys(nodeAddress);
    }
    
    function ready() public {
        address nodeAddress = msg.sender;
        require(registeredVDFNodes[nodeAddress], "not registered");
        require(!workingVDFNodes[nodeAddress], "already working");
        require(timer.getBlockNumber()>=registeredBlockOfVDFNodes[nodeAddress]+requiredWaitBlockNumber, "registeredBlockOfVDFNodes does not passed");
        workingVDFNodes[nodeAddress] = true;
        readyNodeAddresses.push(nodeAddress);
        emit Ready(nodeAddress);
    }

    function updateVDFNodes() public {
        uint32 nowIndex = lastStartedIndex + idUpdateIndexInterval;
        require(timer.isOpenedIndex(nowIndex), "idUpdateIndexInterval does not pass.");
        for(uint64 i=1;i<=nextMaxNodeId;i++){
            nowAddressOfNodeId[i] = nextAddressOfNodeId[i];
            nowNodeIdOfAddress[nextAddressOfNodeId[i]] = i;
            if(i>nowMaxNodeId){
                joinedIndexOfNodeId[i] = nowIndex;
            }
        }
        //TODO: add node remove mechanism
        /*if(nowMaxNodeId>nextMaxNodeId){
            uint64 overNodeId = uint64(uint256(nextMaxNodeId).add(1));
            for(uint64 i=overNodeId;i<=nowMaxNodeId;i++){
                nowAddressOfNodeId[i] = address(0);
            }
        }*/
        nowMaxNodeId = nextMaxNodeId;

        for(uint64 i=1;i<=nowMaxNodeId;i++){
            nextAddressOfNodeId[i] = nowAddressOfNodeId[i];
        }
        uint64 newNodeId = nowMaxNodeId;
        for(uint i=0;i<readyNodeAddresses.length;i++){
            newNodeId = uint32(uint256(newNodeId).add(1));
            nextAddressOfNodeId[newNodeId] = readyNodeAddresses[i];
        }
        nextMaxNodeId = newNodeId;
        numNodesAtIndex[nowIndex] = nowMaxNodeId;
        delete readyNodeAddresses;
        lastStartedIndex = nowIndex;
        emit UpdateVDFNodes(lastStartedIndex, nowMaxNodeId, nextMaxNodeId);
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.3;

contract VerifyVDF {
  uint256 constant RSA_MODULUS_0 = 0x31f55615172866bccc30f95054c824e733a5eb6817f7bc16399d48c6361cc7e5;
  uint256 constant RSA_MODULUS_1 = 0xbc729592642920f24c61dc5b3c3b7923e56b16a4d9d373d8721f24a3fc0f1b31;
  uint256 constant RSA_MODULUS_2 = 0xf6135809f85334b5cb1813addc80cd05609f10ac6a95ad65872c909525bdad32;
  uint256 constant RSA_MODULUS_3 = 0xf7e8daefd26c66fc02c479af89d64d373f442709439de66ceb955f3ea37d5159;
  uint256 constant RSA_MODULUS_4 = 0xb4f14a04b51f7bfd781be4d1673164ba8eb991c2c4d730bbbe35f592bdef524a;
  uint256 constant RSA_MODULUS_5 = 0xa31f5b0b7765ff8b44b4b6ffc93384b646eb09c7cf5e8592d40ea33c80039f35;
  uint256 constant RSA_MODULUS_6 = 0x7ff0db8e1ea1189ec72f93d1650011bd721aeeacc2acde32a04107f0648c2813;
  uint256 constant RSA_MODULUS_7 = 0xc7970ceedcc3b0754490201a7aa613cd73911081c790f5f1a8726f463550bb5b;
  bytes RSA_MODULUS =
    hex"c7970ceedcc3b0754490201a7aa613cd73911081c790f5f1a8726f463550bb5b7ff0db8e1ea1189ec72f93d1650011bd721aeeacc2acde32a04107f0648c2813a31f5b0b7765ff8b44b4b6ffc93384b646eb09c7cf5e8592d40ea33c80039f35b4f14a04b51f7bfd781be4d1673164ba8eb991c2c4d730bbbe35f592bdef524af7e8daefd26c66fc02c479af89d64d373f442709439de66ceb955f3ea37d5159f6135809f85334b5cb1813addc80cd05609f10ac6a95ad65872c909525bdad32bc729592642920f24c61dc5b3c3b7923e56b16a4d9d373d8721f24a3fc0f1b3131f55615172866bccc30f95054c824e733a5eb6817f7bc16399d48c6361cc7e5";

  uint256 constant MILLER_RABIN_ROUNDS = 15;
  uint256 constant MAX_NONCE = 65536;

  constructor() {}

  function verify(
    bytes memory g,
    bytes memory pi,
    bytes memory y,
    bytes memory q,
    bytes memory dst,
    uint256 nonce,
    uint256 delay
  ) public view returns (bool) {
    require(validateNonce(nonce), "invalid nonce");
    require(validateGroupElement(g), "invalid group element: g");
    require(!isZeroGroupElement(g), "zero group element: g");
    require(validateGroupElement(pi), "invalid group element: pi");
    require(!isZeroGroupElement(pi), "zero group element: pi");
    require(validateGroupElement(y), "invalid group element: y");
    require(!isZeroGroupElement(y), "zero group element: y");
    require(validateGroupElement(q), "invalid group element: helper q");

    uint256 l = hashToPrime(g, y, nonce, dst);
    if (l & 1 == 0) {
      l += 1;
    }
    require(millerRabinPrimalityTest(l), "non prime challenge");

    uint256 r = modexp(2, delay, l);
    bytes memory u1 = modexp(pi, l);
    bytes memory u2 = modexp(g, r);

    require(mulModEqual(u1, u2, y, q), "verification failed");
    return true;
  }

  function hashToPrime(
    bytes memory g,
    bytes memory y,
    uint256 nonce,
    bytes memory dst
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(dst, g, y, nonce)));
  }

  // a * b =? N*q + y
  function mulModEqual(
    bytes memory a,
    bytes memory b,
    bytes memory y,
    bytes memory q
  ) internal view returns (bool) {
    bytes memory u1 = mul2048(a, b);
    bytes memory u2 = mul2048(q, RSA_MODULUS);
    add2048to4096(u2, y);
    return equalNumber(u1, u2);
  }

  function equalNumber(bytes memory a, bytes memory b) internal pure returns (bool res) {
    uint256 len = a.length;
    if (len == 0) {
      return false;
    }
    if (len % 32 != 0) {
      return false;
    }
    if (len != b.length) {
      return false;
    }
    uint256 i = 0;
    res = true;
    assembly {
      for {
        let ptr := 32
      } lt(ptr, add(len, 1)) {
        ptr := add(ptr, 32)
      } {
        i := add(i, 1)
        res := and(res, eq(mload(add(a, ptr)), mload(add(b, ptr))))
      }
    }
  }

  function millerRabinPrimalityTest(uint256 n) internal view returns (bool) {
    // miller rabin primality tests code is
    // borrowed from https://github.com/dankrad/rsa-bounty/blob/master/contract/rsa_bounty.sol

    if (n < 4) {
      return false;
    }
    if (n & 1 == 0) {
      return false;
    }
    uint256 d = n - 1;
    uint256 r = 0;
    while (d & 1 == 0) {
      d /= 2;
      r += 1;
    }
    for (uint256 i = 0; i < MILLER_RABIN_ROUNDS; i++) {
      // pick a random integer a in the range [2, n − 2]
      uint256 a = (uint256(keccak256(abi.encodePacked(n, i))) % (n - 3)) + 2;
      uint256 x = modexp(a, d, n);
      if (x == 1 || x == n - 1) {
        continue;
      }
      bool check_passed = false;
      for (uint256 j = 1; j < r; j++) {
        x = mulmod(x, x, n);
        if (x == n - 1) {
          check_passed = true;
          break;
        }
      }
      if (!check_passed) {
        return false;
      }
    }
    return true;
  }

  function modexp(
    uint256 base,
    uint256 exponent,
    uint256 modulus
  ) internal view returns (uint256 res) {
    assembly {
      let mem := mload(0x40)

      mstore(mem, 0x20)
      mstore(add(mem, 0x20), 0x20)
      mstore(add(mem, 0x40), 0x20)
      mstore(add(mem, 0x60), base)
      mstore(add(mem, 0x80), exponent)
      mstore(add(mem, 0xa0), modulus)

      let success := staticcall(sub(gas(), 2000), 5, mem, 0xc0, mem, 32)
      switch success
        case 0 {
          revert(0x0, 0x0)
        }
      res := mload(mem)
    }
  }

  function modexp(bytes memory base, uint256 exponent) internal view returns (bytes memory res) {
    // bytes memory res // = new bytes(256);
    assembly {
      let mem := mload(0x40)

      mstore(mem, 256) // <length_of_BASE> = 256
      mstore(add(mem, 0x20), 0x20) // <length_of_EXPONENT> = 32
      mstore(add(mem, 0x40), 256) // <length_of_MODULUS> = 256

      mstore(add(mem, 0x60), mload(add(base, 0x20)))
      mstore(add(mem, 0x80), mload(add(base, 0x40)))
      mstore(add(mem, 0xa0), mload(add(base, 0x60)))
      mstore(add(mem, 0xc0), mload(add(base, 0x80)))
      mstore(add(mem, 0xe0), mload(add(base, 0xa0)))
      mstore(add(mem, 0x100), mload(add(base, 0xc0)))
      mstore(add(mem, 0x120), mload(add(base, 0xe0)))
      mstore(add(mem, 0x140), mload(add(base, 0x100)))

      mstore(add(mem, 0x160), exponent)

      mstore(add(mem, 0x180), RSA_MODULUS_7)
      mstore(add(mem, 0x1a0), RSA_MODULUS_6)
      mstore(add(mem, 0x1c0), RSA_MODULUS_5)
      mstore(add(mem, 0x1e0), RSA_MODULUS_4)
      mstore(add(mem, 0x200), RSA_MODULUS_3)
      mstore(add(mem, 0x220), RSA_MODULUS_2)
      mstore(add(mem, 0x240), RSA_MODULUS_1)
      mstore(add(mem, 0x260), RSA_MODULUS_0)

      let success := staticcall(sub(gas(), 2000), 5, mem, 0x280, add(mem, 0x20), 256)
      switch success
        case 0 {
          revert(0x0, 0x0)
        }
      // update free mem pointer
      mstore(0x40, add(mem, 0x120))
      res := mem
    }
  }

  function mul2048(bytes memory a, bytes memory b) internal pure returns (bytes memory res) {
    assembly {
      let mem := mload(64)
      mstore(mem, 512)
      mstore(64, add(mem, 576))

      let r := not(0)
      let u1
      let u2
      let u3
      let mm
      let ai

      // a0 * bj
      {
        ai := mload(add(a, 256)) // a0
        u1 := mload(add(b, 256)) // b0

        // a0 * b0
        mm := mulmod(ai, u1, r)
        u1 := mul(ai, u1) // La0b0
        u2 := sub(sub(mm, u1), lt(mm, u1)) // Ha0b0

        // store z0 = La0b0
        mstore(add(mem, 512), u1)
        // u1, u3 free, u2: Ha0b0

        for {
          let ptr := 224
        } gt(ptr, 0) {
          ptr := sub(ptr, 32)
        } {
          // a0 * bj
          u1 := mload(add(b, ptr))
          {
            mm := mulmod(ai, u1, r)
            u1 := mul(ai, u1) // La0bj
            u3 := sub(sub(mm, u1), lt(mm, u1)) // Ha0bj
          }

          u1 := add(u1, u2) // zi = La0bj + Ha0b_(j-1)
          u2 := add(u3, lt(u1, u2)) // Ha0bj = Ha0bj + c
          mstore(add(mem, add(ptr, 256)), u1) // store zi
          // carry u2 to next iter
        }
      }

      mstore(add(256, mem), u2) // store z_(i+8)

      // ai
      // i from 1 to 7
      for {
        let optr := 224
      } gt(optr, 0) {
        optr := sub(optr, 32)
      } {
        mstore(add(add(optr, mem), 32), u2) // store z_(i+8)
        ai := mload(add(a, optr)) // ai
        u1 := mload(add(b, 256)) // b0
        {
          // ai * b0
          mm := mulmod(ai, u1, r)
          u1 := mul(ai, u1) // La1b0
          u2 := sub(sub(mm, u1), lt(mm, u1)) // Haib0
        }

        mm := add(mem, add(optr, 256))
        u3 := mload(mm) // load zi
        u1 := add(u1, u3) // zi = zi + Laib0
        u2 := add(u2, lt(u1, u3)) // Haib0' = Haib0 + c
        mstore(mm, u1) // store zi
        // u1, u3 free, u2: Haib0

        // bj, j from 1 to 7
        for {
          let iptr := 224
        } gt(iptr, 0) {
          iptr := sub(iptr, 32)
        } {
          u1 := mload(add(b, iptr)) // bj
          {
            // ai * bj
            mm := mulmod(ai, u1, r)
            u1 := mul(ai, u1) // Laibj
            u3 := sub(sub(mm, u1), lt(mm, u1)) // Haibj
          }
          u1 := add(u1, u2) // Laibj + Haib0
          u3 := add(u3, lt(u1, u2)) // Haibj' = Haibj + c
          mm := add(mem, add(iptr, optr))
          u2 := mload(mm) // zi
          u1 := add(u1, u2) // zi = zi + (Laibj + Haib0)
          u2 := add(u3, lt(u1, u2)) // Haibj' = Ha1bj + c
          mstore(mm, u1) // store zi
          // carry u2 to next iter
        }
      }
      mstore(add(32, mem), u2) // store z15
      res := mem
    }
  }

  function add2048to4096(bytes memory a, bytes memory b) internal pure {
    assembly {
      let a_ptr := add(a, 0x220)
      let b_ptr := add(b, 0x120)
      let c

      let ai := mload(a_ptr)
      let bi := mload(b_ptr)
      ai := add(ai, bi)
      c := lt(ai, bi)
      mstore(a_ptr, ai)

      for {
        let off := 0x20
      } lt(off, 0x101) {
        off := add(off, 0x20)
      } {
        a_ptr := sub(a_ptr, 0x20)
        b_ptr := sub(b_ptr, 0x20)
        ai := mload(a_ptr)
        bi := mload(b_ptr)

        ai := add(ai, c)
        c := lt(ai, c)
        ai := add(ai, bi)
        c := add(c, lt(ai, bi))
        mstore(a_ptr, ai)
      }

      for {
        let off := 0x0
      } lt(off, 0x20) {
        off := add(off, 0x20)
      } {
        a_ptr := sub(a_ptr, 0x20)
        ai := mload(a_ptr)
        ai := add(ai, c)
        c := lt(ai, c)
        mstore(a_ptr, ai)
      }
    }
  }

  function validateGroupElement(bytes memory e) internal pure returns (bool valid) {
    if (e.length != 256) {
      return false;
    }
    valid = true;
    assembly {
      let ei := mload(add(e, 0x20))
      valid := lt(ei, RSA_MODULUS_7)
      if eq(ei, RSA_MODULUS_7) {
        ei := mload(add(e, 0x40))
        valid := lt(ei, RSA_MODULUS_6)
        if eq(ei, RSA_MODULUS_6) {
          ei := mload(add(e, 0x60))
          valid := lt(ei, RSA_MODULUS_5)
          if eq(ei, RSA_MODULUS_5) {
            ei := mload(add(e, 0x80))
            valid := lt(ei, RSA_MODULUS_4)
            if eq(ei, RSA_MODULUS_4) {
              ei := mload(add(e, 0xa0))
              valid := lt(ei, RSA_MODULUS_3)
              if eq(ei, RSA_MODULUS_3) {
                ei := mload(add(e, 0xc0))
                valid := lt(ei, RSA_MODULUS_2)
                if eq(ei, RSA_MODULUS_2) {
                  ei := mload(add(e, 0xe0))
                  valid := lt(ei, RSA_MODULUS_1)
                  if eq(ei, RSA_MODULUS_1) {
                    ei := mload(add(e, 0x100))
                    valid := lt(ei, RSA_MODULUS_0)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function isZeroGroupElement(bytes memory e) internal pure returns (bool isZero) {
    if (e.length != 256) {
      return false;
    }
    isZero = true;
    assembly {
      for {
        let off := 0x20
      } lt(off, 0x101) {
        off := add(off, 0x20)
      } {
        isZero := and(isZero, eq(mload(add(e, off)), 0))
      }
    }
  }

  function validateNonce(uint256 nonce) internal pure returns (bool) {
    return nonce < MAX_NONCE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity >=0.4.22 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RadoaERC20 is ERC20("RADOAERC20Testv0", "RADOATestv0") {
    constructor() public {
        _mint(msg.sender, 1000000000);
    }
}

pragma solidity >=0.4.22 <=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface ITimer {
    event CloseAttestation(uint32 indexed index);

    function updatePeriod() external view returns (uint64);
    function submissionPeriod() external view returns (uint256);
    function getLastClosedIndex() external view returns (uint32);
    function getDeployedTime() external view returns (uint64);
    function getCloseTimeOfIndex(bytes4 _index) external view returns (uint64);
    function getBlockTimestamp() external view returns (uint256);
    function getBlockNumber() external view returns (uint256);
    function getCloseTime(bytes4 _index) external view returns (uint64);
    function isOpenedIndex(uint32 _index) external view returns (bool);
    function computeOpenTime(uint32 _index) external view returns (uint64);
    function computetLastOpenedIndex() external view returns (uint32);
    function closeAttestation() external;
}

contract Timer is ITimer {
    using SafeMath for uint256;
    using SafeMath for uint64;

    uint64 constant UPDATE_PERIOD = 180;
    uint256 constant SUBMISSION_PERIOD = 10800;

    uint32 lastClosedIndex;
    uint64 deployedTime;
    mapping (bytes4=>uint64) closeTimeOfIndex;

    constructor() public {
        lastClosedIndex = 0;
        deployedTime = uint64(block.timestamp);
        closeTimeOfIndex[bytes4(lastClosedIndex)] = uint64(block.timestamp);
    }

    function updatePeriod() external view override returns (uint64) {
        return UPDATE_PERIOD;
    }

    function submissionPeriod() external view override returns (uint256) {
        return SUBMISSION_PERIOD;
    }

    function getLastClosedIndex() public view override returns (uint32) {
        return lastClosedIndex;
    }

    function getDeployedTime() public view override returns (uint64) {
        return deployedTime;
    }

    function getCloseTimeOfIndex(bytes4 _index) public view override returns (uint64) {
        return closeTimeOfIndex[_index];
    }

    function getBlockTimestamp() public view virtual override returns (uint256) {
        return block.timestamp;
    }

    function getBlockNumber() public view virtual override returns (uint256) {
        return block.number;
    }

    function getCloseTime(bytes4 _index) public view override returns (uint64) {
        return closeTimeOfIndex[_index];
    }

    function isOpenedIndex(uint32 _index) public view override returns (bool) {
        return getBlockTimestamp() >= computeOpenTime(_index);
    }

    function computeOpenTime(uint32 _index) public view override returns (uint64) {
        return uint64(deployedTime.add(UPDATE_PERIOD.mul(uint64(_index))));
    }

    function computetLastOpenedIndex() public view override returns (uint32) {
        uint subTime = uint64(getBlockTimestamp()).sub(deployedTime);
        uint index = uint64(subTime).div(UPDATE_PERIOD);
        return uint32(index);
    }

    function closeAttestation() public override {
        uint64 lastOpenTime = computeOpenTime(lastClosedIndex);
        uint closeLimitTime = uint256(lastOpenTime).add(uint(SUBMISSION_PERIOD));
        require(getBlockTimestamp()==closeLimitTime,"code 0 in closeAttestation");
        emit CloseAttestation(lastClosedIndex);
        lastClosedIndex ++;
        closeTimeOfIndex[bytes4(lastClosedIndex)] = uint64(getBlockTimestamp());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}