/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/ExpirableLib.sol

pragma solidity >=0.4.21 <0.6.0;



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
        return (self.expiryTime > 0 && self.expiryTime < now);
    }

    /// @notice Set expiry time for `self` TimeAndExpiry struct to now plus `duration`.
    /// @dev Call this method to set the creationTime and expiryTime in the TimeAndExpiry struct.
    /// @param self TimeAndExpiry struct
    /// @param duration Time from current time till expiry
    function setExpiry(TimeAndExpiry storage self, uint256 duration) internal {
        self.creationTime = now;
        self.expiryTime = now.add(duration);
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Evidencable.sol

pragma solidity >=0.4.21 <0.6.0;




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
    function addEvidence(string memory hash) public onlyEvidenceProvider {
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
    function isUnevidenced(string memory hash) internal view returns(bool) {
        return (evidenceCounts[hash] == 0);
    }
}

// File: contracts/Manifestations.sol

pragma solidity >=0.4.21 <0.6.0;




/// @title Contract for copyright authorship registration through creations manifestations
/// @author Roberto García (http://rhizomik.net/~roberto/)
contract Manifestations is Pausable, Evidencable {

    using ExpirableLib for ExpirableLib.TimeAndExpiry;

    struct Manifestation {
        string title;
        address[] authors;
        ExpirableLib.TimeAndExpiry time;
    }

    uint32 public timeToExpiry;
    mapping(string => Manifestation) private manifestations;

    event ManifestEvent(string hash, string title, address indexed manifester);
    event AddedEvidence(uint8 evidenceCount);

    constructor(uint32 _timeToExpiry) public {
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
                (manifestations[hash].time.isExpired() && isUnevidenced(hash)),
            "Already registered and not expired or with evidence");
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
    function addEvidence(string memory hash) public {
        require(bytes(manifestations[hash].title).length > 0, "The manifestation evidenced should exist");
        super.addEvidence(hash);
    }
}