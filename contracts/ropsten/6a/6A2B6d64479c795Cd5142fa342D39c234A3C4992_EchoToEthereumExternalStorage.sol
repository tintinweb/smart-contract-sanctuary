// SPDX-License-Identifier: MIT
pragma solidity >0.8.5 <0.9.0;

import "openzeppelin-solidity/contracts/utils/math/Math.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";

contract Committee {
    function recoverSigner(
        bytes32 data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual pure returns (address) {
        return ecrecover(data, v, r, s);
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MIN_COMMITTEE_SIZE = 8;
    uint256 public constant MAX_COMMITTEE_SIZE = 50;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Action {
        bool addition;
        address address_;
    }

    struct NodeProps {
        bool applied;
        bool verified;
        bytes32 parentHash;
        Action action;
    }

    struct Node {
        uint256 version;
        NodeProps props;
        EnumerableSet.AddressSet signers;
        mapping(address => Signature) signatures;
    }

    bytes32 public immutable rootHash;

    bytes32 private _headHash;
    bytes32[] private _hashes;
    EnumerableSet.AddressSet private _members;
    mapping(bytes32 => Node) private _nodes;

    function committeeSize() public view returns (uint256) {
        return _members.length();
    }

    function requiredSignaturesCount() public virtual view returns (uint256) {
        return (_members.length() * 2) / 3 + 1;
    }

    function version() public view returns (uint256) {
        return _hashes.length - 1;
    }

    function headHash() public view returns (bytes32) {
        return _headHash;
    }

    function snapshot() public view returns (bytes32 root, address[] memory members) {
        return (_headHash, getCommitteeMembers(0, type(uint256).max));
    }

    function isCommitteeMember(address address_) public view returns (bool) {
        return _members.contains(address_);
    }

    function getNodeSignersCount(bytes32 nodeHash) public view returns (uint256) {
        return _nodes[nodeHash].signers.length();
    }

    function getCommitteeMembers(uint256 fromIndex, uint256 limit) public view returns (address[] memory) {
        uint256 committeeSize_ = committeeSize();
        if (fromIndex >= committeeSize_) return new address[](0);
        uint256 length = Math.min(limit, committeeSize_ - fromIndex);
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) result[i] = _members.at(fromIndex + i);
        return result;
    }

    function getNodeSigners(
        bytes32 nodeHash,
        uint256 fromIndex,
        uint256 limit
    ) public view returns (address[] memory) {
        Node storage node_ = _nodes[nodeHash];
        uint256 signersCount_ = node_.signers.length();
        if (fromIndex >= signersCount_) return new address[](0);
        uint256 length = Math.min(limit, signersCount_ - fromIndex);
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) result[i] = node_.signers.at(fromIndex + i);
        return result;
    }

    function getAppliedNodesHashes(uint256 fromVersion, uint256 limit) public view returns (bytes32[] memory) {
        uint256 hashesCount = _hashes.length;
        if (fromVersion >= hashesCount) return new bytes32[](0);
        uint256 length = Math.min(limit, hashesCount - fromVersion);
        bytes32[] memory result = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) result[i] = _hashes[fromVersion + i];
        return result;
    }

    function getAppliedNodes(uint256 fromVersion, uint256 limit) public view returns (NodeProps[] memory) {
        bytes32[] memory hashes = getAppliedNodesHashes(fromVersion, limit);
        uint256 length = hashes.length;
        NodeProps[] memory result = new NodeProps[](length);
        for (uint256 i = 0; i < length; i++) result[i] = _nodes[hashes[i]].props;
        return result;
    }

    function getNode(bytes32 hash_) public view returns (uint256 version_, NodeProps memory props) {
        Node storage node_ = _nodes[hash_];
        return (node_.version, node_.props);
    }

    function getNodeSignatures(
        bytes32 nodeHash,
        uint256 fromIndex,
        uint256 limit
    ) public view returns (Signature[] memory signatures_, address[] memory signers_) {
        Node storage node_ = _nodes[nodeHash];
        uint256 signersCount_ = node_.signers.length();
        if (fromIndex >= signersCount_) return (signatures_, signers_);
        uint256 length = Math.min(limit, signersCount_ - fromIndex);
        signatures_ = new Signature[](length);
        signers_ = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address signer = node_.signers.at(fromIndex + i);
            signatures_[i] = node_.signatures[signer];
            signers_[i] = signer;
        }
    }

    event MemberAdded(address indexed address_);
    event MemberRemoved(address indexed address_);
    event NodeSigned(bytes32 indexed nodeHash, address indexed signer, bytes32 r, bytes32 s, uint8 v);
    event NodeVerified(bytes32 indexed nodeHash, bytes32 indexed parentHash, address indexed address_, bool addition);
    event NodeApplied(bytes32 indexed hash_);
    event SignerRemoved(bytes32 indexed nodeHash, address indexed signer);

    constructor(address[] memory members, bytes32 rootHash_) {
        rootHash = rootHash_;
        _headHash = rootHash_;
        _hashes.push(rootHash_);
        uint256 membersCount = members.length;
        require(membersCount >= MIN_COMMITTEE_SIZE, "Members count lt required");
        require(membersCount <= MAX_COMMITTEE_SIZE, "Members count gt allowed");
        for (uint256 i = 0; i < membersCount; i++) _addMember(members[i]);
    }

    function sign(bytes32 hash_, Signature[] memory signatures_) public returns (bool success) {
        Node storage node_ = _nodes[hash_];
        uint256 signaturesCount = signatures_.length;
        for (uint256 i = 0; i < signaturesCount; i++) {
            Signature memory signature = signatures_[i];
            address signer = recoverSigner(_getPrefixedHash(hash_), signature.v, signature.r, signature.s);
            node_.signers.add(signer);
            node_.signatures[signer] = signature;
            emit NodeSigned(hash_, signer, signature.r, signature.s, signature.v);
        }
        return true;
    }

    function verify(bytes32 parentHash, Action memory action) public returns (bool success) {
        _verify(parentHash, action);
        return true;
    }

    function removeExcessSignatures(bytes32 nodeHash_, address[] memory signers) public returns (bool success) {
        Node storage node_ = _nodes[nodeHash_];
        require(node_.props.verified, "Node not verified");
        require(node_.props.parentHash == _headHash, "Not incomming node");
        uint256 signersCount = signers.length;
        for (uint256 i = 0; i < signersCount; i++) {
            address signer = signers[i];
            require(!isCommitteeMember(signer), "Signer is committee member");
            node_.signers.remove(signer);
            emit SignerRemoved(nodeHash_, signer);
        }
        return true;
    }

    function commit(Action memory action) public returns (bool success) {
        bytes32 newHeadHash;
        Node storage node_;
        (newHeadHash, node_) = _verify(_headHash, action);
        uint256 validSignaturesCount = 0;
        for (uint256 i = 0; i < node_.signers.length(); i++) {
            address signer = node_.signers.at(i);
            if (_members.contains(signer)) validSignaturesCount += 1;
        }
        require(validSignaturesCount >= requiredSignaturesCount(), "Not enough signatures");
        if (action.addition) {
            require(!_members.contains(action.address_), "Already committee member");
            require(_members.length() < MAX_COMMITTEE_SIZE, "Members count gt allowed");
            _addMember(action.address_);
        } else {
            require(_members.contains(action.address_), "Not committee member");
            require(_members.length() > MIN_COMMITTEE_SIZE, "Members count lt required");
            _members.remove(action.address_);
            emit MemberRemoved(action.address_);
        }
        _hashes.push(newHeadHash);
        _headHash = newHeadHash;
        node_.props.applied = true;
        emit NodeApplied(newHeadHash);
        return true;
    }

    function _getPrefixedHash(bytes32 hash_) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hash_));
    }

    function _addMember(address address_) private {
        _members.add(address_);
        emit MemberAdded(address_);
    }

    function _verify(bytes32 parentHash, Action memory action) private returns (bytes32 hash_, Node storage node_) {
        hash_ = keccak256(abi.encodePacked(parentHash, action.addition, action.address_));
        node_ = _nodes[hash_];
        Node storage parent = _nodes[parentHash];
        require(parentHash == rootHash || parent.props.verified, "Parent node not verified");
        node_.version = parent.version + 1;
        node_.props.parentHash = parentHash;
        node_.props.action = action;
        node_.props.verified = true;
        emit NodeVerified(hash_, parentHash, action.address_, action.addition);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.5 <0.9.0;

import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";

import "./Committee.sol";

contract ExternalStorage is ReentrancyGuard {
    function recoverSigner(
        bytes32 dataToSign,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual pure returns (address) {
        return ecrecover(dataToSign, v, r, s);
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct KeyValuePair {
        bytes32 key;
        bytes32 value;
    }

    struct HistoryNodeProps {
        bool confirmed;
        bool verified;
        uint256 version;
        bytes32 prevNodeHash;
        bytes32 treeHash;
        bytes32 key;
        bytes32 value;
    }

    struct HistoryNode {
        HistoryNodeProps props;
        EnumerableSet.AddressSet signers;
    }

    bytes32 public immutable genesisHash;
    Committee public committee;
    mapping(bytes32 => bytes32) public data;

    bytes32 private _headHash;
    mapping(bytes32 => HistoryNode) private _nodes;

    function headHash() public view returns (bytes32) {
        return _headHash;
    }

    function getNode(bytes32 treeHash) public view returns (HistoryNodeProps memory) {
        return _nodes[treeHash].props;
    }

    function getNodeSigners(
        bytes32 treeHash,
        uint256 skip,
        uint256 limit
    ) public view returns (address[] memory) {
        HistoryNode storage node = _nodes[treeHash];
        uint256 signersCount = node.signers.length();
        if (skip >= signersCount) return new address[](0);
        uint256 length = Math.min(signersCount - skip, limit);
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) result[i] = node.signers.at(i + skip);
        return result;
    }

    function isNodeSigner(bytes32 treeHash, address address_) public view returns (bool) {
        return _nodes[treeHash].signers.contains(address_);
    }

    function requiredSignaturesCount() public virtual view returns (uint256) {
        return committee.requiredSignaturesCount();
    }

    event HistoryNodeAdded(uint256 indexed version, bytes32 indexed key, bytes32 value, bytes32 treeHash);
    event HistoryNodeConfirmed(uint256 indexed version, bytes32 indexed treeHash);
    event HistoryNodeSigned(bytes32 indexed treeHash, address indexed signer, bytes32 r, bytes32 s, uint8 v);
    event SignerRemoved(bytes32 indexed treeHash, address indexed signer);
    event StorageUpdated(bytes32 indexed key, bytes32 value);

    constructor(bytes32 genesisHash_, Committee committee_) {
        genesisHash = genesisHash_;
        committee = committee_;
        _headHash = genesisHash_;
        HistoryNode storage node = _nodes[genesisHash_];
        node.props.verified = true;
        node.props.treeHash = genesisHash_;
        emit HistoryNodeAdded(0, 0x0, 0x0, genesisHash_);
        node.props.confirmed = true;
        emit HistoryNodeConfirmed(0, genesisHash_);
    }

    function addHistory(bytes32 from, KeyValuePair[] memory actions) public returns (bool success) {
        HistoryNode storage node = _nodes[from];
        require(node.props.verified, "Node props not verified");
        uint256 actionsCount = actions.length;
        for (uint256 i = 0; i < actionsCount; i++) {
            KeyValuePair memory action = actions[i];
            bytes32 newNodeHash = keccak256(abi.encodePacked(node.props.treeHash, action.key, action.value));
            HistoryNode storage newNode = _nodes[newNodeHash];
            if (!newNode.props.verified) {
                uint256 version = node.props.version + 1;
                newNode.props.verified = true;
                newNode.props.version = version;
                newNode.props.prevNodeHash = node.props.treeHash;
                newNode.props.treeHash = newNodeHash;
                newNode.props.key = action.key;
                newNode.props.value = action.value;
                emit HistoryNodeAdded(version, action.key, action.value, newNodeHash);
            }
            node = newNode;
        }
        return true;
    }

    function sign(bytes32 hash_, Signature[] memory signatures) public returns (bool success) {
        HistoryNode storage node = _nodes[hash_];
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 dataToSign = keccak256(abi.encodePacked(prefix, hash_));
        uint256 signaturesCount = signatures.length;
        for (uint256 i = 0; i < signaturesCount; i++) {
            Signature memory signature = signatures[i];
            address signer = recoverSigner(dataToSign, signature.v, signature.r, signature.s);
            node.signers.add(signer);
            emit HistoryNodeSigned(hash_, signer, signature.r, signature.s, signature.v);
        }
        return true;
    }

    function removeExcessSigners(bytes32 nodeHash, address[] memory signers) public returns (bool success) {
        HistoryNode storage node = _nodes[nodeHash];
        uint256 signersCount = signers.length;
        for (uint256 i = 0; i < signersCount; i++) {
            address signer = signers[i];
            require(!committee.isCommitteeMember(signer), "Signer is committee member");
            node.signers.remove(signer);
            emit SignerRemoved(nodeHash, signer);
        }
        return true;
    }

    function applyHistory(bytes32 nodeHash) public nonReentrant returns (bool success) {
        HistoryNode storage node = _nodes[nodeHash];
        require(node.props.verified, "Node not verified");
        require(!node.props.confirmed, "Node not confirmed");
        uint256 headVersion = _nodes[_headHash].props.version;
        require(node.props.version > headVersion, "Version already confirmed");
        // require(false, "qwe");
        require(node.signers.length() >= requiredSignaturesCount(), "Not enough signatures");
        // require(false, "qwe");
        uint256 actionsCount = node.props.version - headVersion;
        // require(false, "zxc");
        KeyValuePair[] memory reversedActions = new KeyValuePair[](actionsCount);
        // require(false, "asd");
        for (uint256 i = 0; i < actionsCount; i++) {
            reversedActions[i] = KeyValuePair(node.props.key, node.props.value);
            node.props.confirmed = true;
            emit HistoryNodeConfirmed(node.props.version, node.props.treeHash);
            node = _nodes[node.props.prevNodeHash];
        }
        require(node.props.treeHash == _headHash, "Tree collision");
        _headHash = nodeHash;
        for (uint256 i = 0; i < actionsCount; i++) {
            KeyValuePair memory action = reversedActions[actionsCount - i - 1];
            data[action.key] = action.value;
            _onStorageUpdated(action.key, action.value);
        }
        _onHistoryUpdated();
        return true;
    }

    function _onHistoryUpdated() internal virtual {
        return;
    }

    function _onStorageUpdated(bytes32 key, bytes32 value) internal virtual {
        emit StorageUpdated(key, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.5 <0.9.0;

import "openzeppelin-solidity/contracts/utils/math/Math.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";

abstract contract InternalStorage {
    function recoverSigner(
        bytes32 dataToSign,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual pure returns (address) {
        return ecrecover(dataToSign, v, r, s);
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct HistoryNodeProps {
        uint256 version;
        bytes32 treeHash;
        bytes32 key;
        bytes32 value;
        uint256 blockNumber;
    }

    struct HistoryNode {
        HistoryNodeProps props;
        EnumerableSet.AddressSet signers;
        mapping(address => Signature) signatures;
    }

    bytes32 public immutable genesisHash;

    HistoryNode[] private history;
    mapping(bytes32 => uint256) internal versions;
    mapping(bytes32 => bytes32) private data;

    function getNode(uint256 version) public view returns (HistoryNodeProps memory) {
        require(version < history.length, "Version not found");
        return history[version].props;
    }

    function getNodeVersion(bytes32 nodeHash) public view returns (uint256 version) {
        version = versions[nodeHash];
        if (version == 0) require(nodeHash == genesisHash, "Node not found");
    }

    function getNodeByHash(bytes32 nodeHash) public view returns (HistoryNodeProps memory) {
        return getNode(getNodeVersion(nodeHash));
    }

    function getValue(bytes32 key) public view returns (bytes32) {
        return data[key];
    }

    function getNodes(uint256 fromVersion, uint256 limit) public view returns (HistoryNodeProps[] memory nodes) {
        uint256 nodesCount = history.length;
        if (fromVersion >= nodesCount) return new HistoryNodeProps[](0);
        uint256 length = Math.min(limit, nodesCount - fromVersion);
        nodes = new HistoryNodeProps[](length);
        for (uint256 i = 0; i < length; i++) nodes[i] = history[fromVersion + i].props;
    }

    function isNodeSigner(bytes32 nodeHash, address address_) public view returns (bool) {
        return history[getNodeVersion(nodeHash)].signers.contains(address_);
    }

    function getNodesDescending(uint256 fromVersion, uint256 limit)
        public
        view
        returns (HistoryNodeProps[] memory nodes)
    {
        uint256 nodesCount = history.length;
        if (fromVersion >= nodesCount) return new HistoryNodeProps[](0);
        uint256 length = Math.min(limit, fromVersion + 1);
        nodes = new HistoryNodeProps[](length);
        for (uint256 i = 0; i < length; i++) nodes[i] = history[fromVersion - i].props;
    }

    function readAscending(bytes32 from, uint256 limit) public view returns (HistoryNodeProps[] memory) {
        return getNodes(getNodeVersion(from), limit);
    }

    function readDescending(bytes32 from, uint256 limit) public view returns (HistoryNodeProps[] memory) {
        return getNodesDescending(getNodeVersion(from), limit);
    }

    function readDescendingFromHead(uint256 limit) public view returns (HistoryNodeProps[] memory) {
        return getNodesDescending(history.length - 1, limit);
    }

    function getNodeSignatures(
        bytes32 nodeHash,
        uint256 skip,
        uint256 limit
    ) public view returns (address[] memory signers, Signature[] memory signatures) {
        HistoryNode storage node = history[getNodeVersion(nodeHash)];
        uint256 signersCount = node.signers.length();
        uint256 length = Math.min(limit, signersCount - skip);
        signers = new address[](length);
        signatures = new Signature[](length);
        for (uint256 i = 0; i < length; i++) {
            address signer = node.signers.at(i + skip);
            signers[i] = signer;
            signatures[i] = node.signatures[signer];
        }
    }

    event NewHistoryNodeAdded(
        bytes32 indexed key,
        bytes32 indexed value,
        uint256 indexed blockNumber,
        uint256 version,
        bytes32 treeHash
    );

    event HistoryNodeSigned(
        uint256 indexed version,
        bytes32 indexed treeHash,
        address indexed signer,
        bytes32 r,
        bytes32 s,
        uint8 v
    );

    constructor(bytes32 genesisHash_) {
        genesisHash = genesisHash_;
        history.push();
        HistoryNode storage genesisNode = history[0];
        genesisNode.props = HistoryNodeProps(0, genesisHash_, 0x0, 0x0, block.number);
    }

    function signHistoryNode(bytes32 treeHash, Signature[] memory signatures) public returns (bool success) {
        uint256 version = versions[treeHash];
        require(version != 0, "Node not found");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 dataToSign = keccak256(abi.encodePacked(prefix, treeHash));
        HistoryNode storage node = history[version];
        for (uint256 i = 0; i < signatures.length; i++) {
            Signature memory signature = signatures[i];
            address signer = recoverSigner(dataToSign, uint8(signature.v), signature.r, signature.s);
            require(signer != address(0), "Invalid signature");
            node.signers.add(signer);
            node.signatures[signer] = signature;
            emit HistoryNodeSigned(version, treeHash, signer, signature.r, signature.s, signature.v);
        }
        return true;
    }

    function _setValue(bytes32 key, bytes32 value) internal {
        data[key] = value;
        uint256 version = history.length;
        HistoryNodeProps storage prevNode = history[version - 1].props;
        bytes32 treeHash = keccak256(abi.encodePacked(prevNode.treeHash, key, value));
        uint256 currentBlock = block.number;
        history.push();
        HistoryNode storage node = history[version];
        node.props = HistoryNodeProps(version, treeHash, key, value, currentBlock);
        versions[treeHash] = version;
        emit NewHistoryNodeAdded(key, value, currentBlock, version, treeHash);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.5 <0.9.0;

import "echo-rollup-contracts/contracts/ExternalStorage.sol";

import "./WrappedECHO.sol";

contract EchoToEthereumExternalStorage is ExternalStorage {
    WrappedECHO public token;

    uint256 private _transfersCount;

    function transfersCount() public view returns (uint256) {
        return _transfersCount;
    }

    constructor(
        bytes32 genesisHash_,
        Committee committee_,
        WrappedECHO token_
    ) ExternalStorage(genesisHash_, committee_) {
        token = token_;
    }

    function _onHistoryUpdated() internal override(ExternalStorage) {
        uint256 transfersCount_ = _transfersCount;
        while (true) {
            uint256 offset = 2 * transfersCount_;
            uint256 value = uint256(data[bytes32(offset + 1)]);
            if (value == 0) break;
            address receiver = address(uint160(uint256(data[bytes32(offset)])));
            token.mint(receiver, value);
            transfersCount_ += 1;
        }
        _transfersCount = transfersCount_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.5 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "echo-rollup-contracts/contracts/InternalStorage.sol";

contract WrappedECHO is ERC20, InternalStorage {
    uint256 public constant MIN_VALUE = 1e5;

    function decimals() public override(ERC20) pure returns (uint8) {
        return 8;
    }

    address public minter;

    uint256 private _transfersCount;

    function transfersCount() public view returns (uint256) {
        return _transfersCount;
    }

    event Unwrapped(address indexed payer, uint152 indexed receiver, uint256 amount);

    constructor(bytes32 genesisHash_) ERC20("Wrapped ECHO", "wECHO") InternalStorage(genesisHash_) {
        return;
    }

    function setMinter(address minter_) external returns (bool success) {
        require(minter == address(0), "Minter already set");
        minter = minter_;
        return true;
    }

    function mint(address receiver, uint256 amount) external returns (bool success) {
        require(msg.sender == minter, "Not allowed");
        _mint(receiver, amount);
        return true;
    }

    function unwrap(uint152 receiver, uint256 amount) external returns (bool success) {
        require(amount >= MIN_VALUE, "Amount underflow");
        uint256 offset = 2 * _transfersCount;
        _setValue(bytes32(offset), bytes32(uint256(uint160(receiver))));
        _setValue(bytes32(offset + 1), bytes32(amount));
        _transfersCount += 1;
        address payer = msg.sender;
        _burn(payer, amount);
        emit Unwrapped(payer, receiver, amount);
        return true;
    }
}