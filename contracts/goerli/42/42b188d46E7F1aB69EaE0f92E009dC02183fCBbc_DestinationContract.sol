// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "AdLibrary.sol";
import "Data.sol";
import "Pausable.sol";
import "SafeERC20.sol";

contract DestinationContract is Pausable, AdLibrary {
    using Data for Data.Edge;
    using Data for Data.Label;
    using Bits for uint256;
    using SafeERC20 for IERC20;

    event AdCreated(uint256 id, Ad data, bytes32 adHash);
    event TokensWithdrawn(address indexed user, uint256 _amount, bytes32 indexed adHash);

    address private ORACLE;
    bytes32 private root;
    mapping(bytes32 => Ad) public allAds;
    uint256 totalAds;
    uint256 public PROTOCOL_FEES = 1; // 1 = 1/10000 =  0.01%

    // a mapping to keep track of if the user has already withdrawn for this key
    // to solve the double withdraw problem
    mapping(bytes => bool) private withdrawn;

    constructor(address _oracle) {
        ORACLE = _oracle;
    }

    modifier onlyOracle() {
        require(msg.sender == ORACLE);
        _;
    }
    

    /// @dev a method to be used by the LP to create a new Ad
    function createAd(
        address _tokenSource,
        address _tokenDest,
        uint256 _amount,
        uint256 _fee
    ) external whenNotPaused {
        
        uint256 protocolFees = (_amount * PROTOCOL_FEES) / 10000;
        uint256 amountMinusFees = _amount - protocolFees;

        // tranfer tokens to contract
        IERC20(_tokenDest).safeTransferFrom(msg.sender, address(this), amountMinusFees);
        // transfer fees to oracle
        IERC20(_tokenDest).safeTransferFrom(msg.sender, ORACLE, protocolFees);

        Ad memory ad = Ad({
            owner: msg.sender,
            tokenSource: _tokenSource,
            tokenDest: _tokenDest,
            amount: amountMinusFees,
            fee: _fee
        });

        bytes32 adHash = getAdHash(ad, totalAds);

        allAds[adHash] = ad;

        emit AdCreated(totalAds, ad, adHash);

        totalAds += 1;
    }

    /// @dev a method used by the user to withdraw the tokens from an ad after he locked them on the source side
    function withdrawTokens(
        bytes32 _adHash,
        uint256 _transferId,
        uint256 _amount,
        uint256 branchMask,
        bytes32[] memory siblings
    ) external whenNotPaused {
        bytes memory key = abi.encodePacked(_adHash, msg.sender, _transferId);
        require(!withdrawn[key], "Already withdrawn");

        bytes memory value = abi.encodePacked(_amount);

        _verifyProof(root, key, value, branchMask, siblings);

        withdrawn[key] = true;

        // transfer tokens to user
        IERC20(allAds[_adHash].tokenDest).safeTransfer(msg.sender, _amount);

        emit TokensWithdrawn(msg.sender, _amount, _adHash);
    }

    // **************************** RESTRICTED METHODS *****************************

    /// @dev method called by the offchain oracle to update the root hash
    function updateRoot(bytes32 _root) external onlyOracle {
        root = _root;
    }

    function pause() external whenNotPaused onlyOracle {
        _pause();
    }

    function unpause() external whenPaused onlyOracle {
        _unpause();
    }

    /// @dev change the oracle address
    function transferOracle(address _oracle) external onlyOracle {
        ORACLE = _oracle;
    }

    /// @dev update the protocol fees
    function updateFees(uint256 _fees) external onlyOracle {
        require(_fees <= 10000, "10000 max");
        PROTOCOL_FEES = _fees;
    }

    // ****************** INTERNAL METHODS ****************************

    function _verifyProof(
        bytes32 rootHash,
        bytes memory key,
        bytes memory value,
        uint256 branchMask,
        bytes32[] memory siblings
    ) internal pure {
        Data.Label memory k = Data.Label(keccak256(key), 256);
        Data.Edge memory e;
        e.node = keccak256(value);
        for (uint256 i = 0; branchMask != 0; i++) {
            uint256 bitSet = branchMask.lowestBitSet();
            branchMask &= ~(uint256(1) << bitSet);
            (k, e.label) = k.splitAt(255 - bitSet);
            uint256 bit;
            (bit, e.label) = e.label.chopFirstBit();
            bytes32[2] memory edgeHashes;
            edgeHashes[bit] = e.edgeHash();
            edgeHashes[1 - bit] = siblings[siblings.length - i - 1];
            e.node = keccak256(abi.encode(edgeHashes));
        }
        e.label = k;
        require(rootHash == e.edgeHash(), "Outdated root");
    }  
}

// Gas for createAd()
// with protocol Fees = 226289
// without protocol Fees = 185929
// difference = 40360

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract AdLibrary {
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