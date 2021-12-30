// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IMagicElpisGem.sol";
import "./interfaces/IElpisHeroRecruiter.sol";
import "./interfaces/IElpisMetaverseHeroes.sol";
import "./interfaces/IElpisCurrencyManager.sol";

contract ElpisHeroRecruiter is
    IElpisHeroRecruiter,
    ContextUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    IElpisMetaverseHeroes public EMH;
    IERC20 public EBA;
    IMagicElpisGem public MEG;
    address public treasury;
    IElpisCurrencyManager public currencyManager;

    bytes32 public eStone;
    uint256 public recruitmentLimit;
    uint256 public recruitmentCountdown;
    uint256 public maximumNumberOfPermits;

    mapping(uint256 => uint256) private _recruitedCounts;

    mapping(uint256 => uint256) private _countdowns;

    mapping(uint256 => uint256) private _eStoneFees;

    mapping(uint256 => mapping(address => uint256))
        private _recruitmentTokenFees;

    // Mapping from `owner` to `account` to their permits `tokenIds` granted to `account` by `owner`
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private _tokenPermits;

    modifier recruitable(uint256 tokenId0, uint256 tokenId1) {
        require(
            _recruitedCounts[tokenId0] < recruitmentLimit,
            "The tokenId0 has reached the recruitment limit"
        );
        require(
            _recruitedCounts[tokenId1] < recruitmentLimit,
            "The tokenId1 has reached the recruitment limit"
        );
        require(
            block.timestamp >= _countdowns[tokenId0],
            "Recruitment on countdown"
        );
        require(
            block.timestamp >= _countdowns[tokenId1],
            "Recruitment on countdown"
        );
        _;
    }

    modifier notIdentical(uint256 tokenId0, uint256 tokenId1) {
        require(tokenId0 != tokenId1, "Identical token");
        _;
    }

    constructor() {}

    function initialize(
        IElpisMetaverseHeroes _EMH,
        IERC20 _EBA,
        IMagicElpisGem _MEG,
        IElpisCurrencyManager _currencyManager,
        bytes32 _eStone,
        address _treasury
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        EMH = _EMH;
        EBA = _EBA;
        MEG = _MEG;
        currencyManager = _currencyManager;
        eStone = _eStone;
        treasury = _treasury;
    }

    function _getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpasue() external onlyOwner {
        _unpause();
    }

    function recruitedCountOf(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _recruitedCounts[tokenId];
    }

    function countdownOf(uint256 tokenId) external view returns (uint256) {
        return _countdowns[tokenId];
    }

    function permits(address owner, address operator)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _tokenPermits[owner][operator].values();
    }

    function updateMaxPermit(uint256 newMaximumNumberOfPermits)
        external
        onlyOwner
    {
        require(
            newMaximumNumberOfPermits > maximumNumberOfPermits,
            "The newMaximumNumberOfPermits must be greater than current max permit"
        );
        maximumNumberOfPermits = newMaximumNumberOfPermits;
    }

    function _grantPermit(address operator, uint256 tokenId) internal {
        require(_msgSender() != operator, "Grant to current owner");
        require(
            !_tokenPermits[_msgSender()][operator].contains(tokenId),
            "Permit granted"
        );
        _tokenPermits[_msgSender()][operator].add(tokenId);
    }

    function grantPermits(address operator, uint256[] calldata tokenIds)
        external
        override
    {
        uint256 length = tokenIds.length;
        require(
            _tokenPermits[_msgSender()][operator].length() + length <=
                maximumNumberOfPermits,
            "The number of permits exceeds maximum"
        );
        for (uint256 i = 0; i < length; ++i) {
            _grantPermit(operator, tokenIds[i]);
        }
        emit PermitsGranted(_msgSender(), operator, tokenIds);
    }

    function _revokePermit(address operator, uint256 tokenId) internal {
        require(
            _tokenPermits[_msgSender()][operator].contains(tokenId),
            "Permit not granted"
        );
        _tokenPermits[_msgSender()][operator].remove(tokenId);
    }

    function revokePermits(address operator, uint256[] calldata tokenIds)
        external
        override
    {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _revokePermit(operator, tokenIds[i]);
        }
        emit PermitsRevoked(_msgSender(), operator, tokenIds);
    }

    function _getRecruitmentFees(uint256 _tokenId0, uint256 _tokenId1)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _index0 = _recruitedCounts[_tokenId0] + 1;
        uint256 _index1 = _recruitedCounts[_tokenId1] + 1;
        uint256 ebaFee =
            _recruitmentTokenFees[_index0][
                address(EBA)
            ] +
                _recruitmentTokenFees[_index1][
                    address(EBA)
                ];
        uint256 megFee =
            _recruitmentTokenFees[_index0][
                address(MEG)
            ] +
                _recruitmentTokenFees[_index1][
                    address(MEG)
                ];
        uint256 eStoneFee =
            _eStoneFees[_index0] +
                _eStoneFees[_index1];

        return (ebaFee, megFee, eStoneFee);
    }

    function getRecruitmentFees(uint256 tokenId0, uint256 tokenId1)
        external
        view
        override
        notIdentical(tokenId0, tokenId1)
        recruitable(tokenId0, tokenId1)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return _getRecruitmentFees(tokenId0, tokenId1);
    }

    function updateRecruitmentCountdown(uint256 newRecruitmentCountdown)
        external
        override
        onlyOwner
    {
        recruitmentCountdown = newRecruitmentCountdown;
        emit RecruitmentCountdownChanged(_msgSender(), newRecruitmentCountdown);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function updateCurrencyManager(
        IElpisCurrencyManager newCurrencyManager
    ) external onlyOwner {
        require(
            address(newCurrencyManager) != address(0),
            "newCurrencyManager is the zero address"
        );
        currencyManager = newCurrencyManager;
    }

    function updateEStone(bytes32 newEStone) external onlyOwner {
        eStone = newEStone;
    }

    function _setRecruitmentFee(
        uint256 _recruitCount,
        uint256 _ebaFee,
        uint256 _megFee,
        uint256 _eStoneFee
    ) internal {
        require(
            _ebaFee + _megFee + _eStoneFee > 0,
            "The total fee must be greater than 0"
        );

        _recruitmentTokenFees[_recruitCount][address(EBA)] = _ebaFee;
        _recruitmentTokenFees[_recruitCount][address(MEG)] = _megFee;
        _eStoneFees[_recruitCount] = _eStoneFee;
    }

    function setRecruitmentFees(
        uint256[] calldata recruitCounts,
        uint256[] calldata ebaFees,
        uint256[] calldata megFees,
        uint256[] calldata eStoneFees
    ) external override onlyOwner {
        require(
            recruitCounts.length == ebaFees.length &&
                recruitCounts.length == megFees.length &&
                recruitCounts.length == eStoneFees.length,
            "RecruitCounts, ebaFees, megFees and eStoneFees length mismatch"
        );
        for (uint256 i = 0; i < recruitCounts.length; ++i) {
            _setRecruitmentFee(
                recruitCounts[i],
                ebaFees[i],
                megFees[i],
                eStoneFees[i]
            );
        }
        emit RecruitmentFeesSet(
            _msgSender(),
            recruitCounts,
            ebaFees,
            megFees,
            eStoneFees
        );
    }

    function updateRecruitmentLimit(uint256 newRecruitmentLimit)
        external
        onlyOwner
    {
        require(
            newRecruitmentLimit > recruitmentLimit,
            "The newRecruitmentLimit must be greater than current recruitment limit"
        );
        recruitmentLimit = newRecruitmentLimit;
        emit RecuitmentLimitChanged(_msgSender(), newRecruitmentLimit);
    }

    /**
     * @dev Returns whether `operator` is allowed to recruit `tokenId0` and `tokenId1`.
     *
     * Requirements:
     *
     * - `tokenId0` must exist.
     * - `tokenId1` must exist.
     */
    function _isPermitHolderOrOwner(
        address operator,
        uint256 tokenId0,
        uint256 tokenId1
    ) internal view returns (bool) {
        address owner0 = EMH.ownerOf(tokenId0);
        address owner1 = EMH.ownerOf(tokenId1);
        return ((owner0 == operator && owner1 == operator) ||
            (owner0 == owner1 &&
                _tokenPermits[owner0][operator].contains(tokenId0) &&
                _tokenPermits[owner1][operator].contains(tokenId1)));
    }

    function _recruit(uint256 tokenId0, uint256 tokenId1) internal {
        (uint256 _ebaFee, uint256 _megFee, uint256 _eStoneFee) =
            _getRecruitmentFees(tokenId0, tokenId1);
        if (_ebaFee > 0) {
            EBA.transferFrom(_msgSender(), treasury, _ebaFee);
        }
        if (_megFee > 0) {
            MEG.transferFrom(_msgSender(), address(this), _megFee);
            MEG.burn(_megFee);
        }
        if (_eStoneFee > 0) {
            currencyManager.decrease(eStone, _msgSender(), _eStoneFee);
        }
        _countdowns[tokenId0] = block.timestamp + recruitmentCountdown;
        _countdowns[tokenId1] = block.timestamp + recruitmentCountdown;
        _recruitedCounts[tokenId0] = _recruitedCounts[tokenId0] + 1;
        _recruitedCounts[tokenId1] = _recruitedCounts[tokenId1] + 1;

        EMH.mint(EMH.ownerOf(tokenId0));
        emit Recruited(EMH.ownerOf(tokenId0), tokenId0, tokenId1);
    }

    function recruit(uint256 tokenId0, uint256 tokenId1)
        external
        override
        whenNotPaused
        notIdentical(tokenId0, tokenId1)
        recruitable(tokenId0, tokenId1)
    {
        require(
            _isPermitHolderOrOwner(_msgSender(), tokenId0, tokenId1),
            "Recruit caller is not owner nor permit holder"
        );
        _recruit(tokenId0, tokenId1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMagicElpisGem is IERC20 {
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IElpisHeroRecruiter {
    /**
     * @dev Emitted when new hero is recruited from `tokenId0` and `tokenId1`
     */
    event Recruited(address indexed owner, uint256 tokenId0, uint256 tokenId1);

    /**
     * @dev Emitted when `fees` is set for a recruitCount
     */
    event RecruitmentFeesSet(
        address account,
        uint256[] recruitCount,
        uint256[] ebaFees,
        uint256[] megFees,
        uint256[] eStoneFees
    );

    /**
     * @dev Emitted when recruitment countdown is changed.
     */
    event RecruitmentCountdownChanged(
        address account,
        uint256 newRecruitmentCountdown
    );

    /**
     * @dev Emitted when recruitment limit is changed.
     */
    event RecuitmentLimitChanged(address account, uint256 newRecruitmentLimit);

    /**
     * @dev Emitted when `owner` grants permits `tokenIds` to `operator`.
     */
    event PermitsGranted(
        address indexed owner,
        address indexed operator,
        uint256[] tokenIds
    );

    /**
     * @dev Emitted when `owner` revokes permits `tokenIds` from `operator`.
     */
    event PermitsRevoked(
        address indexed owner,
        address indexed operator,
        uint256[] tokenIds
    );

    /**
     * @dev Returns the number recruited of `tokenId` token.
     */
    function recruitedCountOf(uint256 tokenId) external returns (uint256);

    /**
     * @dev Returns permits `tokenIds` token grated for `operator` by `owner`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function permits(address owner, address operator)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants permission to `operator` to recruit `tokenIds` token to another account.
     *
     *
     * Requirements:
     *
     * - Each `tokenId` token of `tokenIds`  must exist.
     * - Each `permit` tokenId of `tokenIds` is not granted.
     *
     * Emits an {PermitsGranted} event.
     */
    function grantPermits(address operator, uint256[] calldata tokenIds)
        external;

    /**
     * @dev Revokes permission from `to`.
     *
     *
     * Requirements:
     *
     * - Each `tokenId` token of `tokenIds`  must exist.
     * - Each `permit` tokenId of `tokenIds` is granted.
     *
     * Emits an {PermitsRevoked} event.
     */
    function revokePermits(address operator, uint256[] calldata tokenIds)
        external;

    /**
     * @dev Returns the recruitment fees of `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId0` token is recruitable.
     * - `tokenId1` token is recruitable.
     */
    function getRecruitmentFees(uint256 tokenId0, uint256 token1)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Set the recruitment countdown.
     *
     * Requirements:
     *
     * - the caller is the owner.
     *
     * Emits a {RecruitmentCountdownChanged} event.
     */
    function updateRecruitmentCountdown(uint256 newRecruitmentCountdown)
        external;

    /**
     * @dev Set the recruitment fees for `recruitCounts` array.
     *
     * Requirements:
     *
     * - the caller is the owner.
     * - total fee of each recruitment must be greater than 0.
     *
     * Emits multi {RecruitmentFeeSet} event.
     */
    function setRecruitmentFees(
        uint256[] calldata recruitCounts,
        uint256[] calldata ebaFees,
        uint256[] calldata megFees,
        uint256[] calldata eStoneFees
    ) external;

    /**
     * @dev Recruit new hero.
     *
     * Requirements:
     *
     * - `tokenId0` token must exist and be owned by caller.
     * - `tokenId1` token must exist and be owned by caller.
     *
     * Emits a {Recruited} event.
     */
    function recruit(uint256 tokenId0, uint256 tokenId1) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IElpisMetaverseHeroes is IERC721 {
    function mint(address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IElpisCurrencyManager {
    function increase(
        bytes32 currency,
        address account,
        uint256 amount
    ) external;

    function decrease(
        bytes32 currency,
        address account,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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