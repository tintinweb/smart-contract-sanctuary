// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";


/// @title Library to implement items that can accumulate evidence
/// @author Roberto García (http://rhizomik.net/~roberto/)
contract Evidencable is Ownable {
    using SafeMath for uint8;

    mapping(address => bool) private evidenceProviders;
    mapping(string => uint8) private evidenceCounts;

    /// @dev Modifier controlling that only registered evidence providers are allowed
    modifier onlyEvidenceProvider() {
        require(evidenceProviders[msg.sender], "Only registered evidence providers allowed");
        _;
    }

    /// @notice Get the evidence count for the manifestation with `hash`.
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    function getEvidenceCount(string memory hash) public view returns (uint8) {
        return evidenceCounts[hash];
    }

    /// @notice Adds one to the evidence count for the manifestation with `hash`.
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    function addEvidence(string memory hash) virtual public onlyEvidenceProvider {
        evidenceCounts[hash] = uint8(evidenceCounts[hash].add(1));
    }

    /// @notice Adds an evidence provider `provider` contract that can then call addEvidence(...)
    /// to add evidence.
    /// @param provider The address of a contract providing evidence
    function addEvidenceProvider(address provider) public onlyOwner {
        evidenceProviders[provider] = true;
    }

    /// @notice Check if the evidencable `hash` has no evidence yet.
    /// @dev Used to check if the corresponding item evidence count is 0.
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    function isUnevidenced(string memory hash) public view returns(bool) {
        return (evidenceCounts[hash] == 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


/// @title Library to implement expirable items
/// @author Roberto García (http://rhizomik.net/~roberto/)
library ExpirableLib {
    using SafeMath for uint;

    struct TimeAndExpiry {
        uint256 creationTime;
        uint256 expiryTime;
    }

    /// @notice Check if `self` TimeAndExpiry struct expiry time has arrived.
    /// @dev This method checks if there is a expiry time and if it is expired.
    /// @param self TimeAndExpiry struct
    function isExpired(TimeAndExpiry storage self) internal view returns(bool) {
        return (self.expiryTime > 0 && self.expiryTime < block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /// @notice Set expiry time for `self` TimeAndExpiry struct to now plus `duration`.
    /// @dev Call this method to set the creationTime and expiryTime in the TimeAndExpiry struct.
    /// @param self TimeAndExpiry struct
    /// @param duration Time from current time till expiry
    function setExpiry(TimeAndExpiry storage self, uint256 duration) internal {
        self.creationTime = block.timestamp;                              // solhint-disable-line not-rely-on-time
        self.expiryTime = block.timestamp.add(duration);                  // solhint-disable-line not-rely-on-time
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "./ExpirableLib.sol";
import "./Evidencable.sol";
import "./Stakable.sol";

/// @title Contract for copyright authorship registration through creations manifestations
/// @author Roberto García (http://rhizomik.net/~roberto/)
contract Manifestations is Ownable, Pausable, Evidencable, Stakable {

    using ExpirableLib for ExpirableLib.TimeAndExpiry;

    struct Manifestation {
        string title;
        address[] authors;
        ExpirableLib.TimeAndExpiry time;
    }

    uint32 public timeToExpiry;
    mapping(string => Manifestation) private manifestations;

    event ManifestEvent(string hash, string title, address indexed manifester);

    constructor(uint32 _timeToExpiry) {
        timeToExpiry = _timeToExpiry;
    }

    /// @dev Modifier implementing the common logic for single and joint authorship.
    /// Checks title and that hash not registered or expired. Then stores title and sets expiry.
    /// Finally, emits ManifestEvent
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    /// @param title The title of the manifestation
    modifier registerIfAvailable(string memory hash, string memory title) {
        require(bytes(title).length > 0, "A title is required");
        require(manifestations[hash].authors.length == 0 ||
                (manifestations[hash].time.isExpired() && !isStaked(hash)),
            "Already registered and not expired or with stake");
        _;
        manifestations[hash].title = title;
        manifestations[hash].time.setExpiry(timeToExpiry);
        emit ManifestEvent(hash, title, msg.sender);
    }

    /// @notice Register single authorship for `msg.sender` of the manifestation with title `title`
    /// and hash `hash`. Requires hash not previously registered or expired.
    /// @dev To be used when there is just one author, which is considered to be the message sender
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    /// @param title The title of the manifestation
    function manifestAuthorship(string memory hash, string memory title)
    public registerIfAvailable(hash, title) whenNotPaused() {
        address[] memory authors = new address[](1);
        authors[0] = msg.sender;
        manifestations[hash].authors = authors;
    }

    /// @notice Register joint authorship for `msg.sender` plus additional authors
    /// `additionalAuthors` of the manifestation with title `title` and hash `hash`.
    /// Requires hash not previously registered or expired and at most 64 authors,
    /// including the one registering.
    /// @dev To be used when there are multiple authors
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    /// @param title The title of the manifestation
    /// @param additionalAuthors The additional authors,
    /// including the one registering that becomes the first author
    function manifestJointAuthorship(string memory hash, string memory title, address[] memory additionalAuthors)
    public registerIfAvailable(hash, title) whenNotPaused() {
        require(additionalAuthors.length < 64, "Joint authorship limited to 64 authors");
        address[] memory authors = new address[](additionalAuthors.length + 1);
        authors[0] = msg.sender;
        for (uint8 i = 0; i < additionalAuthors.length; i++)
            authors[i+1] = additionalAuthors[i];
        manifestations[hash].authors = authors;
    }

    /// @notice Retrieve the title and authors of the manifestation with content hash `hash`.
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    /// @return The title and authors of the manifestation
    function getManifestation(string memory hash) public view
    returns (string memory, address[] memory, uint256, uint256) {
        return (manifestations[hash].title,
                manifestations[hash].authors,
                manifestations[hash].time.creationTime,
                manifestations[hash].time.expiryTime);
    }

    /// @notice Adds an evidence if there is already a manifestation for `hash`.
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    function addEvidence(string memory hash) public override {
        require(bytes(manifestations[hash].title).length > 0, "The manifestation evidenced should exist");
        super.addEvidence(hash);
    }

    /// @notice Checks if a manifestation for `hash` exists and thus can get stake.
    /// @param hash Hash of the manifestation content, for instance IPFS Base58 Hash
    function isStakable(string memory hash) public view override {
        require(bytes(manifestations[hash].title).length > 0, "The manifestation should exist to accept stake");
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @title Library to implement items that can accumulate stake
/// @author Roberto García (http://rhizomik.net/~roberto/)
contract Stakable is Ownable {
  using SafeMath for uint256;

  address authorisedToken;
  mapping(string => uint256) public staked;

  /// @dev Modifier controlling that only the registered token can add stake
  modifier onlyAllowedToken() {
    require(authorisedToken == msg.sender, "Only registered token can add stake");
    _;
  }

  /// @notice Sets the `token` address authorised to add and remove stake.
  /// @param token The address of the authorised token contract
  function setToken(address token) public onlyOwner {
    authorisedToken = token;
  }

  /// @notice Checks if the item with `hash` can have stake, depending on implementation.
  /// For instance, the item is already registered.
  /// @param hash Hash identifying the item, for instance IPFS Base58 Hash
  function isStakable(string memory hash) virtual public {}

  /// @notice Check if the stakable `hash` has some stake.
  /// @dev Used to check if the corresponding item has a current stake bigger than 0.
  /// @param hash Hash identifying the item to get stake, for instance IPFS Base58 Hash
  function isStaked(string memory hash) public view returns(bool) {
    return (staked[hash] > 0);
  }

  /// @notice Adds `amount` stake on the registered token to the item with `hash`.
  /// @param amount Amount of stake on the registered token to add
  /// @param hash Hash identifying the item to get stake, for instance IPFS Base58 Hash
  function addStake(uint256 amount, string memory hash) public onlyAllowedToken {
    staked[hash] += amount;
  }

  /// @notice Removes `amount` of stake on the registered token from the item with `hash`.
  /// @param amount Amount of stake on the registered token to remove
  /// @param hash Hash identifying the item to loose stake, for instance IPFS Base58 Hash
  function removeStake(uint256 amount, string memory hash) public onlyAllowedToken {
    require(amount <= staked[hash], 'No more than the amount currently staked can be removed');
    staked[hash] -= amount;
  }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

