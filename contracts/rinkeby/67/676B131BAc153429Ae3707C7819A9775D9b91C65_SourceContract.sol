// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "AdUtils.sol";
import "PatriciaTree.sol";
import "Pausable.sol";
import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";

contract SourceContract is PatriciaTree, Pausable, Ownable, AdUtils {
    using SafeERC20 for IERC20;

    address public DESTINATION_CONTRACT;
    // a mapping to keep track of how many tokens of ad are sold (adHash => tokensSold)
    mapping(bytes32 => uint256) public tokensSold;
    uint256 public totalTransfers;

    event TokensBought(
        bytes32 indexed adHash,
        uint256 amount,
        address indexed user,
        uint256 transferId
    );

    constructor(address _destination) {
        DESTINATION_CONTRACT = _destination;
    }

    /// @dev method to be used by users to lock tokens for a particular adHash so
    /// that they can then claim those tokens on the dest Side
    /// @notice if msg.sender is the ad owner then this method will act as a liquidty withdrawal for the owner
    /// @param _adId unique id of the ad
    function buy(
        Ad memory _ad,
        uint256 _amount,
        uint256 _adId
    ) external whenNotPaused {
        bytes32 adHash = getAdHash(_ad, _adId);

        uint256 tokensLeft = _ad.amount - tokensSold[adHash];

        require(tokensLeft >= _amount, "Ad has insufficient tokens");

        if (msg.sender != _ad.owner) {
            // transfer the tokens to the ad owner
            // user transfers the amount to buy plus the lpFees number of tokens
            IERC20(_ad.tokenSource).safeTransferFrom(
                msg.sender,
                _ad.owner,
                _amount + ((_amount * _ad.fee) / 10000)
            );
        }

        // update tokensSold
        tokensSold[adHash] += _amount;

        // calculate transaction hash
        bytes memory key = abi.encodePacked(adHash, msg.sender, totalTransfers);
        bytes memory value = abi.encodePacked(_amount);

        // add this transaction to the merkle tree
        _insert(key, value);

        emit TokensBought(adHash, _amount, msg.sender, totalTransfers);

        totalTransfers += 1;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }


    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

}

// PROCESS
// An user will look for ads on the destination side
// Then the user will come here and lock tokens for that ad on the source side
// The contract will add this transaction to a merkle tree
// Then an oracle controlled by our team will take the merkle root hash and update it on the destination side
// Once done, the user will take his transaction, the merkle proof and prove on the
// destination side, his source transaction. If successful he will be able to withdraw
// the tokens on the destination side.
// Then the LP will be able to withdraw the tokens on the source side

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract AdUtils {
    struct Ad {
        address owner; // Lp/owner for this ad
        address tokenSource; // token address on the source side
        address tokenDest; // token address here (on the destination side)
        uint256 amount; // total amount of tokens
        uint256 fee; // fee in percentage basis points
    }

    function getAdHash(Ad memory _ad, uint256 _adId)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _ad.owner,
                    _ad.tokenSource,
                    _ad.tokenDest,
                    _ad.amount,
                    _ad.fee,
                    _adId
                )
            );
    }

    function getKey(bytes32 _adHash, address _user, uint _transferId) public pure returns(bytes memory) {
        return abi.encodePacked(_adHash, _user, _transferId);
    }

    function getValue(uint _amount) public pure returns (bytes memory) {
        return abi.encodePacked(_amount);
    }

    function keyHash(bytes memory _key) public pure returns (bytes32) {
        return keccak256(_key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Data} from "Data.sol";
import {Bits} from "Bits.sol";

/*
 * Patricia tree implementation.
 *
 * More info at: https://github.com/chriseth/patricia-trie
 */
contract PatriciaTree {
    using Data for Data.Tree;
    using Data for Data.Node;
    using Data for Data.Edge;
    using Data for Data.Label;
    using Bits for uint256;

    Data.Tree internal tree;

    // Get the root hash.
    function getRootHash() public view returns (bytes32) {
        return tree.root;
    }

    // Get the root edge.
    function getRootEdge() public view returns (Data.Edge memory e) {
        e = tree.rootEdge;
    }

    // Get the node with the given key. The key needs to be
    // the keccak256 hash of the actual key.
    function getNode(bytes32 hash) public view returns (Data.Node memory n) {
        n = tree.nodes[hash];
    }

    // Returns the Merkle-proof for the given key
    // Proof format should be:
    //  - uint branchMask - bitmask with high bits at the positions in the key
    //                    where we have branch nodes (bit in key denotes direction)
    //  - bytes32[] _siblings - hashes of sibling edges
    function getProof(bytes memory key)
        public
        view
        returns (uint256 branchMask, bytes32[] memory _siblings)
    {
        require(tree.root != 0);
        Data.Label memory k = Data.Label(keccak256(key), 256);
        Data.Edge memory e = tree.rootEdge;
        bytes32[256] memory siblings;
        uint256 length;
        uint256 numSiblings;
        Data.Label memory prefix;
        Data.Label memory suffix;
        Data.Label memory tail;
        uint256 head;
        while (true) {
            (prefix,  suffix) = k
                .splitCommonPrefix(e.label);
            assert(prefix.length == e.label.length);
            if (suffix.length == 0) {
                // Found it
                break;
            }
            length += prefix.length;
            branchMask |= uint256(1) << (255 - length);
            length += 1;
            (head, tail) = suffix.chopFirstBit();
            siblings[numSiblings++] = tree
                .nodes[e.node]
                .children[1 - head]
                .edgeHash();
            e = tree.nodes[e.node].children[head];
            k = tail;
        }
        if (numSiblings > 0) {
            _siblings = new bytes32[](numSiblings);
            for (uint256 i = 0; i < numSiblings; i++) {
                _siblings[i] = siblings[i];
            }
        }
    }

    function _insert(bytes memory key, bytes memory value) internal {
        tree.insert(key, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Bits} from "Bits.sol";

/*
 * Data structures and utilities used in the Patricia Tree.
 *
 * More info at: https://github.com/chriseth/patricia-trie
 */
library Data {
    struct Label {
        bytes32 data;
        uint256 length;
    }

    struct Edge {
        bytes32 node;
        Label label;
    }

    struct Node {
        Edge[2] children;
    }

    struct Tree {
        bytes32 root;
        Data.Edge rootEdge;
        mapping(bytes32 => Data.Node) nodes;
    }

    // Returns a label containing the longest common prefix of `self` and `label`,
    // and a label consisting of the remaining part of `label`.
    function splitCommonPrefix(Label memory self, Label memory other)
        internal
        pure
        returns (Label memory prefix, Label memory labelSuffix)
    {
        return splitAt(self, commonPrefix(self, other));
    }

    // Splits the label at the given position and returns prefix and suffix,
    // i.e. 'prefix.length == pos' and 'prefix.data . suffix.data == l.data'.
    function splitAt(Label memory self, uint256 pos)
        internal
        pure
        returns (Label memory prefix, Label memory suffix)
    {
        assert(pos <= self.length && pos <= 256);
        prefix.length = pos;
        if (pos == 0) {
            prefix.data = bytes32(0);
        } else {
            prefix.data = bytes32(
                uint256(self.data) & (~uint256(1) << (255 - pos))
            );
        }
        suffix.length = self.length - pos;
        suffix.data = self.data << pos;
    }

    // Returns the length of the longest common prefix of the two labels.
    /*
    function commonPrefix(Label memory self, Label memory other) internal pure returns (uint prefix) {
        uint length = self.length < other.length ? self.length : other.length;
        // TODO: This could actually use a "highestBitSet" helper
        uint diff = uint(self.data ^ other.data);
        uint mask = uint(1) << 255;
        for (; prefix < length; prefix++) {
            if ((mask & diff) != 0) {
                break;
            }
            diff += diff;
        }
    }
    */

    function commonPrefix(Label memory self, Label memory other)
        internal
        pure
        returns (uint256 prefix)
    {
        uint256 length = self.length < other.length
            ? self.length
            : other.length;
        if (length == 0) {
            return 0;
        }
        uint256 diff = uint256(self.data ^ other.data) &
            (~uint256(0) << (256 - length)); // TODO Mask should not be needed.
        if (diff == 0) {
            return length;
        }
        return 255 - Bits.highestBitSet(diff);
    }

    // Returns the result of removing a prefix of length `prefix` bits from the
    // given label (shifting its data to the left).
    function removePrefix(Label memory self, uint256 prefix)
        internal
        pure
        returns (Label memory r)
    {
        require(prefix <= self.length);
        r.length = self.length - prefix;
        r.data = self.data << prefix;
    }

    // Removes the first bit from a label and returns the bit and a
    // label containing the rest of the label (shifted to the left).
    function chopFirstBit(Label memory self)
        internal
        pure
        returns (uint256 firstBit, Label memory tail)
    {
        require(self.length > 0);
        return (
            uint256(self.data >> 255),
            Label(self.data << 1, self.length - 1)
        );
    }

    function edgeHash(Data.Edge memory self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(self.node, self.label.length, self.label.data)
            );
    }

    // Returns the hash of the encoding of a node.
    function hash(Data.Node memory self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    edgeHash(self.children[0]),
                    edgeHash(self.children[1])
                )
            );
    }

    function insertNode(Data.Tree storage tree, Data.Node memory n)
        internal
        returns (bytes32 newHash)
    {
        bytes32 h = hash(n);
        tree.nodes[h].children[0] = n.children[0];
        tree.nodes[h].children[1] = n.children[1];
        return h;
    }

    function replaceNode(
        Data.Tree storage self,
        bytes32 oldHash,
        Data.Node memory n
    ) internal returns (bytes32 newHash) {
        delete self.nodes[oldHash];
        return insertNode(self, n);
    }

    function insertAtEdge(
        Tree storage self,
        Edge memory e,
        Label memory key,
        bytes32 value
    ) internal returns (Edge memory) {
        assert(key.length >= e.label.length);
        (
            Data.Label memory prefix,
            Data.Label memory suffix
        ) = splitCommonPrefix(key, e.label);
        bytes32 newNodeHash;
        if (suffix.length == 0) {
            // Full match with the key, update operation
            newNodeHash = value;
        } else if (prefix.length >= e.label.length) {
            // Partial match, just follow the path
            assert(suffix.length > 1);
            Node memory n = self.nodes[e.node];
            (uint256 head, Data.Label memory tail) = chopFirstBit(suffix);
            n.children[head] = insertAtEdge(
                self,
                n.children[head],
                tail,
                value
            );
            delete self.nodes[e.node];
            newNodeHash = insertNode(self, n);
        } else {
            // Mismatch, so let us create a new branch node.
            (uint256 head, Data.Label memory tail) = chopFirstBit(suffix);
            Node memory branchNode;
            branchNode.children[head] = Edge(value, tail);
            branchNode.children[1 - head] = Edge(
                e.node,
                removePrefix(e.label, prefix.length + 1)
            );
            newNodeHash = insertNode(self, branchNode);
        }
        return Edge(newNodeHash, prefix);
    }

    function insert(
        Tree storage self,
        bytes memory key,
        bytes memory value
    ) internal {
        Label memory k = Label(keccak256(key), 256);
        bytes32 valueHash = keccak256(value);
        Edge memory e;
        if (self.root == 0) {
            // Empty Trie
            e.label = k;
            e.node = valueHash;
        } else {
            e = insertAtEdge(self, self.rootEdge, k, valueHash);
        }
        self.root = edgeHash(e);
        self.rootEdge = e;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Bits {
    uint256 internal constant ONE = uint256(1);

    // uint256 internal constant ONES = uint256(~0);

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self ^ other) >> index) & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    // function bits(
    //     uint256 self,
    //     uint8 startIndex,
    //     uint16 numBits
    // ) internal pure returns (uint256) {
    //     require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
    //     return (self >> startIndex) & (ONES >> (256 - numBits));
    // }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.11;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable  {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.11;

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
abstract contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.11;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.11;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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