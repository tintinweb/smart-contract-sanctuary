/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

// Global Enums and Structs



struct ElderSpirit {
    bool valid;
    uint256 raceId;
    uint256 classId;
    string affinity;
    int256 affinityPrice;
}
struct MinigamePlayer {
    bool isInGame;

    // Will add more as needed
}
struct Hero {
    bool valid;
    string name;
    string affinity;
    int256 affinityPrice;
    uint256 roundMinted;
    uint256 elderId;
    uint256 raceId;
    uint256 classId;
    uint8 appearance;
    uint8 trait1;
    uint8 trait2;
    uint8 skill1;
    uint8 skill2;
    uint8 alignment;
    uint8 background;
    uint8 hometown;
    uint8 weather;
    uint8 level;
    uint8 hp;
    uint8 mana;
    uint8 stamina;
    uint8 strength;
    uint8 dexterity;
    uint8 constitution;
    uint8 intelligence;
    uint8 wisdom;
    uint8 charisma;
}

// Part: ICryptoChampions

interface ICryptoChampions {
    function createAffinity(string calldata tokenTicker, address feedAddress) external;

    function setElderMintPrice(uint256 price) external;

    function setTokenURI(uint256 id, string calldata uri) external;

    function mintElderSpirit(
        uint256 raceId,
        uint256 classId,
        string calldata affinity
    ) external payable returns (uint256);

    function getElderOwner(uint256 elderId) external view returns (address);

    function mintHero(uint256 elderId, string memory heroName) external payable returns (uint256);

    function getHeroOwner(uint256 heroId) external view returns (address);

    function getElderSpirit(uint256 elderId)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            string memory,
            int256
        );

    function getHeroGameData(uint256 heroId)
        external
        view
        returns (
            bool, // valid
            string memory, // affinity
            int256, // affinity price
            uint256, // round minted
            uint256 // elder id
        );

    function getHeroVisuals(uint256 heroId)
        external
        view
        returns (
            string memory, // name
            uint256, // race id
            uint256, // class id
            uint8 // appearance
        );

    function getHeroTraitsSkills(uint256 heroId)
        external
        view
        returns (
            uint8, // trait 1
            uint8, // trait 2
            uint8, // skill 1
            uint8 // skill 2
        );

    function getHeroLore(uint256 heroId)
        external
        view
        returns (
            uint8, // alignment
            uint8, // background
            uint8, // hometown
            uint8 // weather
        );

    function getHeroVitals(uint256 heroId)
        external
        view
        returns (
            uint8, // level
            uint8, // hp
            uint8, // mana
            uint8 // stamina
        );

    function getHeroStats(uint256 heroId)
        external
        view
        returns (
            uint8, // strength
            uint8, // dexterity
            uint8, // constitution
            uint8, // intelligence
            uint8, // wisdom
            uint8 // charisma
        );

    function getHeroMintPrice(uint256 round, uint256 elderId) external view returns (uint256);

    function getElderSpawnsAmount(uint256 round, uint256 elderId) external view returns (uint256);

    function getAffinityFeedAddress(string calldata affinity) external view returns (address);

    function declareRoundWinner(string calldata winningAffinity) external;

    function claimReward(uint256 heroId) external;

    function getNumEldersInGame() external view returns (uint256);

    function transferInGameTokens(address to, uint256 amount) external;

    function delegatedTransferInGameTokens(
        address from,
        address to,
        uint256 amount
    ) external;

    function refreshPhase() external;
}

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: smartcontractkit/[email protected]/BufferChainlink

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(bytes memory b) internal pure returns(buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint a, uint b) private pure returns(uint) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// Part: smartcontractkit/[email protected]/ChainlinkRequestInterface

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// Part: smartcontractkit/[email protected]/ENSInterface

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external;
  function setResolver(bytes32 node, address _resolver) external;
  function setOwner(bytes32 node, address _owner) external;
  function setTTL(bytes32 node, uint64 _ttl) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);

}

// Part: smartcontractkit/[email protected]/ENSResolver (Alias import as ENSResolver_Chainlink)

abstract contract ENSResolver_Chainlink {
  function addr(bytes32 node) public view virtual returns (address);
}

// Part: smartcontractkit/[email protected]/ENSResolver

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// Part: smartcontractkit/[email protected]/LinkTokenInterface

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/PointerInterface

interface PointerInterface {
  function getAddress() external view returns (address);
}

// Part: smartcontractkit/[email protected]/VRFRequestIDBase

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// Part: Minigame

/// @title Minigame
/// @author cds95
/// @notice This is contract for a minigame
abstract contract Minigame {
    // Possible game phases
    enum MinigamePhase { OPEN, CLOSED }

    // The current game's phase
    MinigamePhase public currentPhase;

    // Map of hero ids to player struct
    mapping(uint256 => MinigamePlayer) public players;

    // List of hero IDs in the game
    uint256[] public heroIds;

    // Number of players currently in the game
    uint256 public numPlayers;

    // Name of the game
    string public gameName;

    // Reference to crypto champions contract
    ICryptoChampions public cryptoChampions;

    // Event to signal that a game has started
    event GameStarted();

    // Event to signal that a game has ended
    event GameEnded();

    // Initializes a new minigame
    /// @param nameOfGame The minigame's name
    /// @param cryptoChampionsAddress The address of the cryptoChampions contract
    constructor(string memory nameOfGame, address cryptoChampionsAddress) public {
        gameName = nameOfGame;
        currentPhase = MinigamePhase.OPEN;
        cryptoChampions = ICryptoChampions(cryptoChampionsAddress);
    }

    /// @notice Joins a game
    /// @param heroId The id of the joining player's hero
    function joinGame(uint256 heroId) public virtual {
        require(currentPhase == MinigamePhase.OPEN);
        MinigamePlayer memory player;
        player.isInGame = true;
        players[heroId] = player;
        heroIds.push(heroId);
        numPlayers++;
    }

    /// @notice Leaves a game
    /// @param heroId The id of the leaving player's hero
    function leaveGame(uint256 heroId) public virtual {
        require(currentPhase == MinigamePhase.OPEN);
        MinigamePlayer storage player = players[heroId];
        player.isInGame = false;
        numPlayers--;
    }

    /// @notice Starts a new game and closes it when it's finished
    function startGame() external {
        require(currentPhase == MinigamePhase.OPEN);
        emit GameStarted();
        play();
        setPhase(MinigamePhase.CLOSED);
        emit GameEnded();
    }

    /// @notice Sets the current game's phase
    /// @param phase The phase the game should be set to
    function setPhase(MinigamePhase phase) internal {
        currentPhase = phase;
    }

    /// @notice Gets the number of players in the game
    function getNumPlayers() public view returns (uint256) {
        return numPlayers;
    }

    /// @notice Handler function to execute game logic.  This should be implemented by the concrete class.
    function play() internal virtual;
}

// Part: OpenZeppelin/[email protected]/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// Part: OpenZeppelin/[email protected]/IERC1155Receiver

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// Part: VRFConsumerBase

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMath for uint256;

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    /* keyHash */
    /* nonce */
    mapping(bytes32 => uint256) private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) public {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// Part: smartcontractkit/[email protected]/CBORChainlink

library CBORChainlink {
    using BufferChainlink for BufferChainlink.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    function encodeType(BufferChainlink.buffer memory buf, uint8 major, uint value) private pure {
        if(value <= 23) {
            buf.appendUint8(uint8((major << 5) | value));
        } else if(value <= 0xFF) {
            buf.appendUint8(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.appendUint8(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
        buf.appendUint8(uint8((major << 5) | 31));
    }

    function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
        if(value < -0x10000000000000000) {
            encodeSignedBigNum(buf, value);
        } else if(value > 0xFFFFFFFFFFFFFFFF) {
            encodeBigNum(buf, value);
        } else if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeBigNum(BufferChainlink.buffer memory buf, int value) internal pure {
      buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
      encodeBytes(buf, abi.encode(uint(value)));
    }

    function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
      buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
      encodeBytes(buf, abi.encode(uint(-1 - input)));
    }

    function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

// Part: OpenZeppelin/[email protected]/ERC1155Receiver

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// Part: WeatherWarsRandomizer

/// @title WeatherWarsRandomizer
/// @author Oozyx
/// @notice Provides VRF needs to the WeatherWars contract
contract WeatherWarsRandomizer is VRFConsumerBase {
    // The maximum number of cities
    uint8 private constant MAX_CITIES = 24;

    // The contract owner
    address private _owner;

    // The key hash for the VRF
    bytes32 private _keyHash;

    // The fee in link for the VRF
    uint256 private _linkFee;

    // The seed for the VRF
    uint256 private _seed;

    // The request id used for the VRF
    bytes32 private _requestId;

    // The city id which is the result of the VRF
    uint256 private _cityId;

    // Set to true once random number has been generated
    bool private _isInitialized;

    // Creates the WeatherWarsRandomizer contract
    constructor(
        bytes32 keyHash,
        address vrfCoordinateAddress,
        address linkTokenAddress,
        uint256 linkFee,
        uint256 seed
    ) public VRFConsumerBase(vrfCoordinateAddress, linkTokenAddress) {
        // Owner of contract is deployer
        _owner = msg.sender;

        _keyHash = keyHash;
        _linkFee = linkFee;
        _seed = seed;

        _isInitialized = false;
    }

    // Limits to only the owner
    modifier onlyOwner {
        require(msg.sender == _owner); // dev: Not contract owner.
        _;
    }

    /// @notice Request randomness from the VRF
    /// @dev Limited to only the owner, or in this case the contract deployer
    function requestRandomness() external onlyOwner {
        require(LINK.balanceOf(address(this)) >= _linkFee); // dev: Not enough LINK.
        requestRandomness(_keyHash, _linkFee, _seed);
    }

    /// @notice Callback function for the VRF
    /// @param requestId The request id
    /// @param randomNum The random number result from the VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomNum) internal override {
        _requestId = requestId;
        _cityId = randomNum % MAX_CITIES;
        _isInitialized = true;
    }

    /// @notice Gets the city id
    /// @dev Requires the randomness to be fulfilled
    /// @return The city id
    function getCityId() public view returns (uint256) {
        require(_isInitialized); // dev: Not initialized.
        return _cityId;
    }

    /// @notice Checks to see if the randomizer is initialized which happens once the random number is generated
    /// @return True if the randomizer has been initialized, false otherwise
    function isInitialized() public view returns (bool) {
        return _isInitialized;
    }
}

// Part: smartcontractkit/[email protected]/Chainlink

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param _id The Job Specification ID
   * @param _callbackAddress The callback address
   * @param _callbackFunction The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 _id,
    address _callbackAddress,
    bytes4 _callbackFunction
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = _id;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = _callbackFunction;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param _data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory _data)
    internal pure
  {
    BufferChainlink.init(self.buf, _data.length);
    BufferChainlink.append(self.buf, _data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The string value to add
   */
  function add(Request memory self, string memory _key, string memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The bytes value to add
   */
  function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The int256 value to add
   */
  function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The uint256 value to add
   */
  function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _values The array of string values to add
   */
  function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }
}

// Part: smartcontractkit/[email protected]/ChainlinkClient

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ARGS_VERSION = 1;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  ChainlinkRequestInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param _specId The Job Specification ID that the request will be created for
   * @param _callbackAddress The callback address that the response will be sent to
   * @param _callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
  {
    return sendChainlinkRequestTo(address(oracle), _req, _payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param _oracle The address of the oracle for the request
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    _req.nonce = requestCount;
    pendingRequests[requestId] = _oracle;
    emit ChainlinkRequested(requestId);
    require(link.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
    requestCount += 1;

    return requestId;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param _requestId The request ID
   * @param _payment The amount of LINK sent for the request
   * @param _callbackFunc The callback function specified for the request
   * @param _expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    internal
  {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
    delete pendingRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param _oracle The address of the oracle contract
   */
  function setChainlinkOracle(address _oracle) internal {
    oracle = ChainlinkRequestInterface(_oracle);
  }

  /**
   * @notice Sets the LINK token address
   * @param _link The address of the LINK token contract
   */
  function setChainlinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (address)
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (address)
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param _oracle The address of the oracle contract that will fulfill the request
   * @param _requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
  {
    pendingRequests[_requestId] = _oracle;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param _ens The address of the ENS contract
   * @param _node The ENS node hash
   */
  function useChainlinkWithENS(address _ens, bytes32 _node)
    internal
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Encodes the request to be sent to the oracle contract
   * @dev The Chainlink node expects values to be in order for the request to be picked up. Order of types
   * will be validated in the oracle contract.
   * @param _req The initialized Chainlink Request
   * @return The bytes payload for the `transferAndCall` method
   */
  function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      _req.id,
      _req.callbackAddress,
      _req.callbackFunctionId,
      _req.nonce,
      ARGS_VERSION,
      _req.buf.buf);
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param _requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param _requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param _requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 _requestId) {
    require(pendingRequests[_requestId] == address(0), "Request is already pending");
    _;
  }
}

// Part: WeatherWars

contract WeatherWars is Minigame, ChainlinkClient, ERC1155Receiver {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 private constant MAX_PLAYERS = 2;

    mapping(uint256 => string) private CITIES;

    mapping(string => uint256) private WEATHERS;

    address private _cryptoChampionsAddress;
    address private _linkTokenAddress;
    address private _oracleAddress;
    bytes32 private _jobId; // The job ID to make a GET call and retrieve a bytes32 result
    uint256 private _oracleFee;
    uint256 private _buyin;
    string private _gameName;
    string private _weatherApiKey; // API key to make call to get weather
    WeatherWarsRandomizer private _randomizer;
    uint256 private cityWeatherId;

    mapping(address => uint256) public balances;

    mapping(address => uint256) public playerHero;

    address public initiator;

    address public opponent;

    address public winner;

    uint256 public initiatorScore;

    uint256 public opponentScore;

    bool public isDuelAccepted;

    bool public hasBeenPlayed;

    bool public isFetchingWeather;

    string public city;

    string public cityWeather;

    constructor(
        address cryptoChampionsAddress,
        address linkTokenAddress,
        address oracleAddress,
        address randomizerAddress,
        bytes32 jobId,
        uint256 oracleFee,
        uint256 buyin,
        string memory gameName,
        string memory weatherApiKey
    ) public Minigame(gameName, cryptoChampionsAddress) {
        _cryptoChampionsAddress = cryptoChampionsAddress;
        _linkTokenAddress = linkTokenAddress;
        _oracleAddress = oracleAddress;
        _jobId = jobId;
        _oracleFee = oracleFee;
        _buyin = buyin;
        _gameName = gameName;
        _weatherApiKey = weatherApiKey;
        _randomizer = WeatherWarsRandomizer(randomizerAddress);

        CITIES[0] = "6173331";
        CITIES[1] = "4671654";
        CITIES[2] = "4887398";
        CITIES[3] = "4164138";
        CITIES[4] = "5128581";
        CITIES[5] = "5391811";
        CITIES[6] = "5391959";
        CITIES[7] = "5809844";
        CITIES[8] = "3530597";
        CITIES[9] = "3435907";
        CITIES[10] = "993800";
        CITIES[11] = "360630";
        CITIES[12] = "2643743";
        CITIES[13] = "524894";
        CITIES[14] = "2950158";
        CITIES[15] = "2968815";
        CITIES[16] = "2759794";
        CITIES[17] = "2673722";
        CITIES[18] = "1850147";
        CITIES[19] = "1275339";
        CITIES[20] = "1796236";
        CITIES[21] = "1835847";
        CITIES[22] = "1880252";
        CITIES[23] = "2158177";

        WEATHERS["Clouds"] = 0;
        WEATHERS["Clear"] = 1;
        WEATHERS["Atmosphere"] = 2;
        WEATHERS["Snow"] = 3;
        WEATHERS["Rain"] = 4;
        WEATHERS["Drizzle"] = 5;
        WEATHERS["Thunderstorm"] = 6;

        setChainlinkToken(linkTokenAddress);
    }

    function setPlayerInformation(
        address duelInitiator,
        uint256 duelInitiatorHeroId,
        address duelOpponent,
        uint256 duelOpponentHeroId
    ) external {
        initiator = duelInitiator;
        opponent = duelOpponent;
        playerHero[initiator] = duelInitiatorHeroId;
        playerHero[opponent] = duelOpponentHeroId;
    }

    function play() internal override {
        require(_randomizer.isInitialized()); // dev: Randomizer not initialized.
        city = CITIES[_randomizer.getCityId()];
        mockGameplay();
    }

    // Hardcoding for now so we can test on Rinkeby.  Make sure to replace with call to requestWeatherData().  The issue is that we
    // can't find a reliable oracle in Rinkeby and the Kovan faucet isn't working.
    function mockGameplay() internal {
        cityWeather = "Clear";
        hasBeenPlayed = true;
    }

    function requestWeatherData() internal {
        Chainlink.Request memory request = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);

        // Build URL
        string memory reqUrlWithCity = concatenate("http://api.openweathermap.org/data/2.5/weather?id=", city);
        reqUrlWithCity = concatenate(reqUrlWithCity, "&appid=");
        reqUrlWithCity = concatenate(reqUrlWithCity, _weatherApiKey);

        // Send Request
        request.add("get", reqUrlWithCity);
        request.add("path", "weather.0.main");

        isFetchingWeather = true;
        sendChainlinkRequestTo(_oracleAddress, request, _oracleFee);
    }

    // TODO:  Move to it's own library
    function concatenate(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function fulfill(bytes32 _requestId, bytes32 _weather) public recordChainlinkFulfillment(_requestId) {
        cityWeather = string(abi.encodePacked(_weather));
        hasBeenPlayed = true;
        isFetchingWeather = false;
    }

    function leaveGame(uint256 heroId) public override {
        require(msg.sender == initiator || msg.sender == opponent); // dev: Address not part of the game
        require(currentPhase == MinigamePhase.OPEN); // dev: Game already closed
        require(bytes(cityWeather).length == 0); // dev: City weather data already fetched

        super.leaveGame(heroId);
        uint256 addressBalance = balances[msg.sender];
        balances[msg.sender] = 0;
        cryptoChampions.transferInGameTokens(msg.sender, addressBalance);
    }

    function determineWinner() external returns (address, uint256) {
        require(msg.sender == initiator || msg.sender == opponent); // dev: Address not part of the game
        require(currentPhase == MinigamePhase.CLOSED); // dev: Game not yet over
        require(bytes(cityWeather).length != 0); // dev: City weather data has not been fetched yet
        require(isDuelAccepted); // dev:  Opponent has not accepted the duel

        uint256 initiatorHeroId = playerHero[initiator];
        uint256 opponentHeroId = playerHero[opponent];
        initiatorScore = getHeroScore(initiatorHeroId);
        opponentScore = getHeroScore(opponentHeroId);

        // Handle Draw
        if (initiatorScore == opponentScore) {
            address playerOne = cryptoChampions.getHeroOwner(initiatorHeroId);
            address playerTwo = cryptoChampions.getHeroOwner(opponentHeroId);
            uint256 balancePlayerOne = balances[playerOne];
            uint256 balancePlayerTwo = balances[playerTwo];
            balances[playerOne] = 0;
            balances[playerTwo] = 0;
            cryptoChampions.transferInGameTokens(playerOne, balancePlayerOne);
            cryptoChampions.transferInGameTokens(playerTwo, balancePlayerTwo);
            return (address(0), 0);
        }

        // Handle winner and loser
        uint256 winnerHeroId;
        uint256 loserHeroId;
        address winnerAddress;
        address loserAddress;
        if (initiatorScore < opponentScore) {
            winnerHeroId = opponentHeroId;
            loserHeroId = initiatorHeroId;
            winnerAddress = opponent;
            loserAddress = initiator;
        } else if (initiatorScore > opponentScore) {
            winnerHeroId = initiatorHeroId;
            loserHeroId = opponentHeroId;
            winnerAddress = initiator;
            loserAddress = opponent;
        }
        uint256 winnerBalance = balances[winnerAddress];
        uint256 loserBalance = balances[loserAddress];
        balances[winnerAddress] = 0;
        balances[loserAddress] = 0;
        cryptoChampions.transferInGameTokens(winnerAddress, winnerBalance + loserBalance);
        winner = winnerAddress;
        setPhase(MinigamePhase.CLOSED);
        return (winner, winnerHeroId);
    }

    function getHeroScore(uint256 heroId) internal view returns (uint256) {
        (, , uint8 hometown, uint8 weather) = cryptoChampions.getHeroLore(heroId);
        uint256 score = 1;

        // Weather and hometown are 1 based in the crypto champions contract and 0 based in weather factory
        if (hometown - 1 == _randomizer.getCityId()) {
            score = score.mul(2); // Multiply by 2
        }
        if (weather - 1 == WEATHERS[cityWeather]) {
            score = score.mul(2); // Multiply by 2
        }
        uint256 classStatScore = getClassStatScore(heroId);
        uint256 weightedClassStatScore = classStatScore.mul(3); // Multiple by 3
        uint256 highestNonClassStat = getHighestNonClassStat(heroId);
        uint256 adjustedStatScore = weightedClassStatScore.add(highestNonClassStat);
        score = score.mul(adjustedStatScore);
        return score;
    }

    function getHighestNonClassStat(uint256 heroId) private view returns (uint256) {
        (uint8 traitOne, uint8 traitTwo, uint8 skillOne, uint8 skillTwo) = cryptoChampions.getHeroTraitsSkills(heroId);
        uint256 highest = traitOne;
        if (traitTwo > highest) {
            highest = traitTwo;
        }
        if (skillOne > highest) {
            highest = skillOne;
        }
        if (skillTwo > highest) {
            highest = skillTwo;
        }
        return highest;
    }

    function getClassStatScore(uint256 heroId) private view returns (uint256) {
        (uint8 strength, uint8 dexterity, uint8 constitution, uint8 intelligence, uint8 wisdom, uint8 charisma) =
            cryptoChampions.getHeroStats(heroId);
        (, , uint256 classId, ) = cryptoChampions.getHeroVisuals(heroId);
        // Warrior
        if (classId == 0) {
            return strength;
        }
        // Mage
        if (classId == 1) {
            return intelligence;
        }
        // Druid
        if (classId == 2) {
            return wisdom;
        }
        // Paladin
        if (classId == 3) {
            return constitution;
        }
        // Bard
        if (classId == 4) {
            return charisma;
        }
        if (classId == 5) {
            return intelligence;
        }
        if (classId == 6) {
            return wisdom;
        }
        // Rogue
        return dexterity;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(value >= _buyin); // dev: Must at least send the buyin amount
        if (from == opponent) {
            isDuelAccepted = true;
        }
        balances[from] = value;
        if (value > _buyin) {
            uint256 refundAmount = value.sub(_buyin);
            cryptoChampions.transferInGameTokens(from, refundAmount);
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function getMetaInformation()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            MinigamePhase,
            address,
            bool,
            uint256,
            bool,
            bool
        )
    {
        return (
            initiator,
            opponent,
            playerHero[initiator],
            playerHero[opponent],
            currentPhase,
            winner,
            isDuelAccepted,
            _buyin,
            hasBeenPlayed,
            isFetchingWeather
        );
    }
}

// File: WeatherWarsFactory.sol

contract WeatherWarsFactory {
    using SafeMath for uint256;

    string internal constant GAME_NAME = "weather-wars";

    address private _cryptoChampionsAddress;
    address private _linkTokenAddress;
    address private _oracleAddress;
    address private _vrfCoordinateAddress;
    bytes32 private _jobId;
    bytes32 private _keyHash;
    uint256 private _vrfFee;
    uint256 private _vrfSeed;
    uint256 private _oracleFee;
    uint256 private _buyin;
    string private _weatherApiKey;

    // All the games this factory has created
    WeatherWars[] public games;

    /// @notice Emit when a game has been created
    /// @param gameName The name of the game
    event GameCreated(string gameName);

    // Creates the WeatherWarsFactory contract
    constructor(
        address cryptoChampionsAddress,
        address linkTokenAddress,
        address oracleAddress,
        address vrfCoordinatorAddress,
        bytes32 jobId,
        bytes32 keyHash,
        uint256 vrfFee,
        uint256 vrfSeed,
        uint256 oracleFee,
        string memory weatherApiKey
    ) public {
        _cryptoChampionsAddress = cryptoChampionsAddress;
        _linkTokenAddress = linkTokenAddress;
        _oracleAddress = oracleAddress;
        _vrfCoordinateAddress = vrfCoordinatorAddress;
        _jobId = jobId;
        _keyHash = keyHash;
        _vrfFee = vrfFee;
        _vrfSeed = vrfSeed;
        _oracleFee = oracleFee;
        _weatherApiKey = weatherApiKey;
    }

    /// @notice Creates the weather wars contract
    /// @param buyinAmount The buyinAmount
    /// @param initiatorHeroId The initiator hero id
    /// @param opponent The opponent address
    /// @param opponentHeroId The opponent hero id
    function createWeatherWars(
        uint256 buyinAmount,
        uint256 initiatorHeroId,
        address opponent,
        uint256 opponentHeroId
    ) external {
        // Create the WeatherWarsRandomizer contract
        WeatherWarsRandomizer randomizer =
            new WeatherWarsRandomizer(_keyHash, _vrfCoordinateAddress, _linkTokenAddress, _vrfFee, _vrfSeed);

        // Send link amount to randomizer
        LinkTokenInterface(_linkTokenAddress).transfer(address(randomizer), _vrfFee);

        // Request the randomness from the randomizer
        randomizer.requestRandomness();

        // Create the WeatherWars contract
        WeatherWars newGame =
            new WeatherWars(
                _cryptoChampionsAddress,
                _linkTokenAddress,
                _oracleAddress,
                address(randomizer),
                _jobId,
                _oracleFee,
                buyinAmount,
                GAME_NAME,
                _weatherApiKey
            );

        // Delegate player tokens to WeatherWars
        ICryptoChampions cc = ICryptoChampions(_cryptoChampionsAddress);
        cc.delegatedTransferInGameTokens(msg.sender, address(newGame), buyinAmount);

        // Set the player information
        newGame.setPlayerInformation(msg.sender, initiatorHeroId, opponent, opponentHeroId);

        // Transfer some link to the newly created game so that it can interact with Chainlink
        LinkTokenInterface(_linkTokenAddress).transfer(address(newGame), _oracleFee.add(_vrfFee));

        games.push(newGame);

        emit GameCreated(GAME_NAME);
    }

    /// @notice Gets the number of games
    /// @return The number of games
    function getNumGames() external view returns (uint256) {
        return games.length;
    }
}