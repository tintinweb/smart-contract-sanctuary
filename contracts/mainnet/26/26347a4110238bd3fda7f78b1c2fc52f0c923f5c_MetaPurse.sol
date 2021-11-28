// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg (@divergencearran / @divergence_art)
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/random/PRNG.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MetaPurse is Ownable {
    using PRNG for PRNG.Source;

    /// @notice The primary GB contract that deployed this one.
    IERC721 public immutable glitchyBitches;

    constructor() {
        glitchyBitches = IERC721(msg.sender);
    }

    /// @notice Requires that the message sender is the primary GB contract.
    modifier onlyGlitchyBitches() {
        require(
            msg.sender == address(glitchyBitches),
            "Only GlitchyBitches contract"
        );
        _;
    }

    /// @notice Total number of versions for each token.
    uint8 private constant NUM_VERSIONS = 6;

    /// @notice Carries per-token metadata.
    struct Token {
        uint8 version;
        uint8 highestRevealed;
        // Changing a token to a different version requires an allowance,
        // increasing by 1 per day. This is calculated as the difference in time
        // since the token's allowance started incrementing, less the amount
        // spent. See allowanceOf().
        uint64 changeAllowanceStartTime;
        int64 spent;
        uint8 glitched;
    }

    /// @notice All token metadata.
    /// @dev Tokens are minted incrementally to correspond to array index.
    Token[] public tokens;

    /// @notice Adds metadata for a new set of tokens.
    function newTokens(uint256 num, bool extraAllowance)
        public
        onlyGlitchyBitches
    {
        int64 initialSpent = extraAllowance ? int64(-30) : int64(0);
        for (uint256 i = 0; i < num; i++) {
            tokens.push(
                Token({
                    version: 0,
                    highestRevealed: 0,
                    changeAllowanceStartTime: uint64(block.timestamp),
                    spent: initialSpent,
                    glitched: 0
                })
            );
        }
    }

    /// @notice Returns tokens[tokenId].version, for use by GB tokenURI().
    function tokenVersion(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (uint8)
    {
        return tokens[tokenId].version;
    }

    /// @notice Tokens that have a higher rate of increasing allowance.
    mapping(uint256 => uint64) private _allowanceRate;

    /// @notice Sets the higher allowance rate for the specified tokens.
    /// @dev These are only set after minting because that stops people from
    /// waiting to mint a specific valuable piece. The off-chain data makes it
    /// clear that they're different, so we can't arbitrarily set these at whim.
    function setHigherAllowanceRates(uint64 rate, uint256[] memory tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _allowanceRate[tokenIds[i]] = rate;
        }
    }

    /// @notice Requires that a token exists.
    function _requireTokenExists(uint256 tokenId) private view {
        require(tokenId < tokens.length, "Token doesn't exist");
    }

    /// @notice Modifier equivalent of _requireTokenExists.
    modifier tokenExists(uint256 tokenId) {
        _requireTokenExists(tokenId);
        _;
    }

    /**
    @notice Requires that the message sender either owns or is approved for the
    token.
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _requireTokenExists(tokenId);
        require(
            glitchyBitches.ownerOf(tokenId) == msg.sender ||
                glitchyBitches.getApproved(tokenId) == msg.sender,
            "Not approved nor owner"
        );
        _;
    }

    /// @notice Returns the version-change allowance of the token.
    function allowanceOf(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (uint32)
    {
        Token storage token = tokens[tokenId];
        uint64 higherRate = _allowanceRate[tokenId];
        uint64 rate = uint64(higherRate > 0 ? higherRate : 1);
        uint64 allowance = ((uint64(block.timestamp) -
            token.changeAllowanceStartTime) / 86400) * rate;
        return uint32(uint64(int64(allowance) - token.spent));
    }

    /// @notice Reduces the version-change allowance of the token by amount.
    /// @dev Enforces a non-negative allowanceOf().
    /// @param amount The amount by which allowanceOf() will be reduced.
    function _spend(uint256 tokenId, uint32 amount)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        require(allowanceOf(tokenId) >= amount, "Insufficient allowance");
        tokens[tokenId].spent += int64(int32(amount));
    }

    /// @notice Costs for version-changing actions. See allowanceOf().
    uint32 public REVEAL_COST = 30;
    uint32 public CHANGE_COST = 10;

    event VersionRevealed(uint256 indexed tokenId, uint8 version);

    /// @notice Reveals the next version for the token, if one exists, and sets
    /// the token metadata to show this version.
    /// @dev The use of _spend() limits this to owners / approved.
    function revealVersion(uint256 tokenId) external tokenExists(tokenId) {
        Token storage token = tokens[tokenId];
        token.highestRevealed++;
        require(token.highestRevealed < NUM_VERSIONS, "All revealed");
        _spend(tokenId, REVEAL_COST);

        token.version = token.highestRevealed;
        emit VersionRevealed(tokenId, token.highestRevealed);
    }

    event VersionChanged(uint256 indexed tokenId, uint8 version);

    /// @notice Changes to an already-revealed version of the token.
    /// @dev The use of _spend() limits this to owners / approved.
    function changeToVersion(uint256 tokenId, uint8 version)
        external
        tokenExists(tokenId)
    {
        Token storage token = tokens[tokenId];

        // There's a 1-in-8 chance that she glitches. See the comment re
        // randomness in changeToRandomVersion(); TL;DR doesn't need to be
        // secure.
        if (token.highestRevealed == NUM_VERSIONS - 1) {
            bytes32 rand = keccak256(abi.encodePacked(tokenId, block.number));
            if (uint256(rand) & 7 == 0) {
                return _changeToRandomVersion(tokenId, true, version);
            }
        }

        require(version <= token.highestRevealed, "Version not revealed");
        require(version != token.version, "Already on version");
        _spend(tokenId, CHANGE_COST);

        token.version = version;
        token.glitched = 0;
        emit VersionChanged(tokenId, version);
    }

    /// @notice Randomly changes to an already-revealed version of the token.
    /// @dev The use of _spend() limits this to owners / approved.
    function changeToRandomVersion(uint256 tokenId)
        external
        tokenExists(tokenId)
    {
        _changeToRandomVersion(tokenId, false, 255);
    }

    /// @notice Randomly changes to an already-revealed version of the token.
    /// @dev The use of _spend() limits this to owners / approved.
    /// @param glitched Whether this function was called due to a "glitch".
    /// @param wanted The version number actually requested; used to avoid
    /// glitching to the same value.
    function _changeToRandomVersion(
        uint256 tokenId,
        bool glitched,
        uint8 wanted
    ) internal {
        Token storage token = tokens[tokenId];
        require(token.highestRevealed > 0, "Insufficient reveals");
        _spend(tokenId, CHANGE_COST);

        // This function only requires randomness for "fun" to allow collectors
        // to change to an unexpected version. We don't need to protect against
        // bad actors, so it's safe to assume that a specific token won't be
        // changed more than once per block.
        PRNG.Source src = PRNG.newSource(
            keccak256(abi.encodePacked(tokenId, block.number))
        );

        uint256 version;
        for (
            version = NUM_VERSIONS; // guarantee at least one read from src
            version >= NUM_VERSIONS || // unbiased
                version == token.version ||
                version == wanted;
            version = src.read(3)
        ) {}
        token.version = uint8(version);
        token.glitched = glitched ? 1 : 0;
        emit VersionChanged(tokenId, uint8(version));
    }

    /// @notice Donate version-changing allowance to a different token.
    /// @dev The use of _spend() limits this to owners / approved of fromId.
    function donate(
        uint256 fromId,
        uint256 toId,
        uint32 amount
    ) external tokenExists(fromId) tokenExists(toId) {
        _spend(fromId, amount);
        tokens[toId].spent -= int64(int32(amount));
    }

    /// @notice Input parameter for increaseAllowance(), coupling a tokenId with
    /// the amount of version-changing allowance it will receive.
    struct Allocation {
        uint256 tokenId;
        uint32 amount;
    }

    /// @notice Allocate version-changing allowance to a set of tokens.
    function increaseAllowance(Allocation[] memory allocs) external onlyOwner {
        for (uint256 i = 0; i < allocs.length; i++) {
            _requireTokenExists(allocs[i].tokenId);
            tokens[allocs[i].tokenId].spent -= int64(int32(allocs[i].amount));
        }
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 Divergent Technologies Ltd (github.com/divergencetech)
pragma solidity >=0.8.9 <0.9.0;

library PRNG {
    /**
    @notice A source of random numbers.
    @dev Pointer to a 4-word buffer of {seed, counter, entropy, remaining unread
    bits}. however, note that this is abstracted away by the API and SHOULD NOT
    be used. This layout MUST NOT be considered part of the public API and
    therefore not relied upon even within stable versions
     */
    type Source is uint256;

    /// @notice Layout within the buffer. 0x00 is the seed.
    uint256 private constant COUNTER = 0x20;
    uint256 private constant ENTROPY = 0x40;
    uint256 private constant REMAIN = 0x60;

    /**
    @notice Returns a new deterministic Source, differentiated only by the seed.
    @dev Use of PRNG.Source does NOT provide any unpredictability as generated
    numbers are entirely deterministic. Either a verifiable source of randomness
    such as Chainlink VRF, or a commit-and-reveal protocol MUST be used if
    unpredictability is required. The latter is only appropriate if the contract
    owner can be trusted within the specified threat model.
     */
    function newSource(bytes32 seed) internal pure returns (Source src) {
        assembly {
            src := mload(0x40)
            mstore(0x40, add(src, 0x80))
            mstore(src, seed)
        }
        _refill(src);
    }

    /**
    @dev Hashes seed||counter, placing it in the entropy word, and resets the
    remaining bits to 256. Increments the counter ready for the next refill.
     */
    function _refill(Source src) private pure {
        assembly {
            mstore(add(src, ENTROPY), keccak256(src, 0x40))
            mstore(add(src, REMAIN), 256)
            let ctr := add(src, COUNTER)
            mstore(ctr, add(1, mload(ctr)))
        }
    }

    /**
    @notice Returns the specified number of bits <= 256 from the Source.
    @dev It is safe to cast the returned value to a uint<bits>.
     */
    function read(Source src, uint256 bits)
        internal
        pure
        returns (uint256 sample)
    {
        require(bits <= 256, "PRNG: max 256 bits");

        uint256 remain;
        assembly {
            remain := mload(add(src, REMAIN))
        }
        if (remain > bits) {
            return readWithSufficient(src, bits);
        }

        uint256 extra = bits - remain;
        sample = readWithSufficient(src, remain);
        assembly {
            sample := shl(extra, sample)
        }

        _refill(src);
        sample = sample | readWithSufficient(src, extra);
    }

    /**
    @notice Returns the specified number of bits, assuming that there is
    sufficient entropy remaining. See read() for usage.
     */
    function readWithSufficient(Source src, uint256 bits)
        private
        pure
        returns (uint256 sample)
    {
        assembly {
            let pool := add(src, ENTROPY)
            let ent := mload(pool)
            sample := and(ent, sub(shl(bits, 1), 1))

            mstore(pool, shr(bits, ent))
            let rem := add(src, REMAIN)
            mstore(rem, sub(mload(rem), bits))
        }
    }

    /// @notice Returns a random boolean.
    function readBool(Source src) internal pure returns (bool) {
        return read(src, 1) == 1;
    }

    /**
    @notice Returns the number of bits needed to encode n.
    @dev Useful for calling readLessThan() multiple times with the same upper
    bound.
     */
    function bitLength(uint256 n) internal pure returns (uint16 bits) {
        assembly {
            for {
                let _n := n
            } gt(_n, 0) {
                _n := shr(1, _n)
            } {
                bits := add(bits, 1)
            }
        }
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling.
    @dev If the size of n is known, prefer readLessThan(Source, uint, uint16) as
    it skips the bit counting performed by this version; see bitLength().
     */
    function readLessThan(Source src, uint256 n)
        internal
        pure
        returns (uint256)
    {
        return readLessThan(src, n, bitLength(n));
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling
    from the range [0,2^bits).
    @dev For greatest efficiency, the value of bits should be the smallest
    number of bits required to capture n; if this is not known, use
    readLessThan(Source, uint) or bitLength(). Although rejections are reduced
    by using twice the number of bits, this increases the rate at which the
    entropy pool must be refreshed with a call to keccak256().

    TODO: benchmark higher number of bits for rejection vs hashing gas cost.
     */
    function readLessThan(
        Source src,
        uint256 n,
        uint16 bits
    ) internal pure returns (uint256 result) {
        // Discard results >= n and try again because using % will bias towards
        // lower values; e.g. if n = 13 and we read 4 bits then {13, 14, 15}%13
        // will select {0, 1, 2} twice as often as the other values.
        for (result = n; result >= n; result = read(src, bits)) {}
    }

    /**
    @notice Returns the internal state of the Source.
    @dev MUST NOT be considered part of the API and is subject to change without
    deprecation nor warning. Only exposed for testing.
     */
    function state(Source src)
        internal
        pure
        returns (
            uint256 seed,
            uint256 counter,
            uint256 entropy,
            uint256 remain
        )
    {
        assembly {
            seed := mload(src)
            counter := mload(add(src, COUNTER))
            entropy := mload(add(src, ENTROPY))
            remain := mload(add(src, REMAIN))
        }
    }
}