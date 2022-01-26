// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// Openzeppelin
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Helpers
import '../helpers/WarpBase.sol';

// Interfaces
import '../interfaces/IBondToken.sol';
import '../interfaces/IBond.sol';
import '../interfaces/IStaking.sol';
import '../interfaces/IStarshipPartsControl.sol';
import '../interfaces/IStarshipParts.sol';
import '../interfaces/IStarship.sol';
import '../interfaces/IStarshipControl.sol';
import '../interfaces/IPlanets.sol';
import '../interfaces/IsWarp.sol';

contract Reader is WarpBase {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    struct SSP {
        PartInfo part;
        uint256 partId;
        string uri;
    }

    struct Bonded {
        BondInfo bondToken;
        Bond bond;
        uint256 bondId;
        string uri;
    }

    struct SS {
        Ship ship;
        Docked dockedInfo;
        uint256 shipId;
        string uri;
    }

    struct P {
        uint256 planetId;
        PlanetInfo info;
    }

    struct All {
        SS[] ships;
        Bonded[] bonds;
        SSP[] parts;
        Tokens[] stakeTokens;
    }

    struct Stake {
        address staking;
        address token;
        uint256 amount;
    }

    struct Pool {
        address staking;
        address token;
    }

    struct Tokens {
        uint256 stakedAt;
        address stakeToken;
        uint256 amount;
    }

    IStarship starship;
    IStarshipControl starshipControls;
    IStarshipPartsControl starshipPartsControls;
    IStarshipParts starshipParts;
    IBondToken bondTokens;
    IPlanets planets;

    EnumerableSetUpgradeable.AddressSet stakeTokens;
    mapping(address => address) stakeTokenStaking;

    /** ===== Initialize ===== */
    function initialize(
        address _starshipPartsControls,
        address _starshipControls,
        address _starship,
        address _parts,
        address _bondTokens,
        address _planets
    ) public initializer {
        __WarpBase_init();

        starshipControls = IStarshipControl(_starshipControls);
        starship = IStarship(_starship);
        starshipParts = IStarshipParts(_parts);
        starshipPartsControls = IStarshipPartsControl(_starshipPartsControls);
        bondTokens = IBondToken(_bondTokens);
        planets = IPlanets(_planets);
    }

    /** @notice add a stake token to be queried */
    function setStakeToken(
        address token,
        address staking,
        bool add
    ) external onlyOwner {
        if (add) {
            require(!stakeTokens.contains(token), 'Already contains');
            stakeTokens.add(token);
            stakeTokenStaking[token] = staking;
        } else {
            require(stakeTokens.contains(token), 'Does not contain');
            stakeTokens.remove(token);
        }
    }

    /** @notice queries Planets contract for all planetary information */
    function getPlanets() public view returns (P[] memory) {
        uint256 count = planets.numberOfPlanets();

        P[] memory _planets = new P[](count);
        for (uint256 i = 0; i < count; i++) {
            _planets[i] = P({info: planets.getPlanetInfo(i), planetId: i});
        }

        return _planets;
    }

    /** @notice Get all owner based NFT's Starships, Bonds, and Parts */
    function getAll(address owner) public view returns (All memory) {
        return
            All({
                ships: getStarships(owner),
                bonds: getBonds(owner),
                parts: getStarshipParts(owner),
                stakeTokens: getStakeTokens(owner)
            });
    }

    /** @notice Get all owner owned Starships */
    function getStarships(address owner) public view returns (SS[] memory) {
        uint256 balance = starship.balanceOf(owner);

        SS[] memory ships = new SS[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 shipId = starship.tokenOfOwnerByIndex(owner, i);
            ships[i] = SS({
                ship: starshipControls.getShip(shipId),
                dockedInfo: planets.getDockedInfo(shipId),
                shipId: shipId,
                uri: starship.tokenURI(shipId)
            });
        }

        return ships;
    }

    /** @notice Get all owner owned parts */
    function getStarshipParts(address owner) public view returns (SSP[] memory) {
        uint256 balance = starshipParts.balanceOf(owner);

        SSP[] memory parts = new SSP[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 partId = starshipParts.tokenOfOwnerByIndex(owner, i);
            parts[i] = SSP({
                part: starshipPartsControls.getPartInfo(partId),
                partId: partId,
                uri: starshipParts.tokenURI(partId)
            });
        }

        return parts;
    }

    /** @notice Get all owner owned bonds */
    function getBonds(address owner) public view returns (Bonded[] memory) {
        uint256 balance = bondTokens.balanceOf(owner);

        Bonded[] memory bonds = new Bonded[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 bondId = bondTokens.tokenOfOwnerByIndex(owner, i);
            BondInfo memory bondToken = bondTokens.getBondInfo(bondId);
            Bond memory bond = IBond(bondToken.bond).getBond(bondId);
            bonds[i] = Bonded({
                bond: bond,
                bondToken: bondToken,
                bondId: bondId,
                uri: bondTokens.tokenURI(bondId)
            });
        }

        return bonds;
    }

    /** @notice get part types */
    function getPartTypeTotals() public view returns (uint256[4] memory _values) {
        _values[0] = IStarshipPartsControl(starshipPartsControls).getPartCount(PartType.BRIDGE);
        _values[1] = IStarshipPartsControl(starshipPartsControls).getPartCount(PartType.HULL);
        _values[2] = IStarshipPartsControl(starshipPartsControls).getPartCount(PartType.ENGINE);
        _values[3] = IStarshipPartsControl(starshipPartsControls).getPartCount(PartType.FUEL);
    }

    /** @notice get a users stake tokens */
    function getStakeTokens(address owner) public view returns (Tokens[] memory) {
        Tokens[] memory tokens = new Tokens[](stakeTokens.length());

        for (uint256 i = 0; i < stakeTokens.length(); i++) {
            tokens[i] = Tokens({
                stakedAt: IStaking(stakeTokenStaking[stakeTokens.at(i)]).getStakedAt(owner),
                stakeToken: stakeTokens.at(i),
                amount: IERC20(stakeTokens.at(i)).balanceOf(owner)
            });
        }

        return tokens;
    }
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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract WarpBase is Initializable {
    bool public paused;
    address public owner;
    mapping(address => bool) public pausers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseChanged(address indexed by, bool indexed paused);

    /** ========  MODIFIERS ========  */

    /** @notice modifier for owner only calls */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /** @notice pause toggler */
    modifier onlyPauseToggler() {
        require(owner == msg.sender || pausers[msg.sender], 'Ownable: caller is not the owner');
        _;
    }

    /** @notice modifier for pausing contracts */
    modifier whenNotPaused() {
        require(!paused || owner == msg.sender || pausers[msg.sender], 'Feature is paused');
        _;
    }

    /** ========  INITALIZE ========  */
    function __WarpBase_init() internal initializer {
        owner = msg.sender;
        paused = true;
    }

    /** ========  OWNERSHIP FUNCTIONS ========  */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** ===== PAUSER FUNCTIONS ========== */

    /** @dev allow owner to add or remove pausers */
    function setPauser(address _pauser, bool _allowed) external onlyOwner {
        pausers[_pauser] = _allowed;
    }

    /** @notice toggle pause on and off */
    function setPause(bool _paused) external onlyPauseToggler {
        paused = _paused;

        emit PauseChanged(msg.sender, _paused);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

/* ======== Structs ======== */
struct BondInfo {
    uint256 value;
    address bond;
    bool repaid;
}

interface IBondToken is IERC721EnumerableUpgradeable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function safeMint(address to, uint256 paid) external returns (uint256);

    function bondRepaid(uint256 tokenId) external;

    function getBondInfo(uint256 _tokenId) external view returns (BondInfo memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

// Info for bond holder
struct Bond {
    uint256 payout; // WARP remaining to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In DAI, for front end viewing
}

interface IBond {
    function redeem(uint256 _recipient, bool _stake) external returns (uint256);

    function getBond(uint256 bondId) external view returns (Bond memory);

    function pendingPayoutFor(uint256 _tokenId) external view returns (uint256 pendingPayout_);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function index() external view returns (uint256);

    function rebase() external;

    function getStakedAt(address account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/* ======== Structs ======== */
enum PartType {
    BRIDGE,
    HULL,
    ENGINE,
    FUEL
}

struct PartInfo {
    uint256 strength;
    PartType typeOf;
}

interface IStarshipPartsControl {
    function buildPart(address _to, uint256 _paid) external returns (uint256);

    function usePart(uint256 _tokenId) external;

    function getPartInfo(uint256 _tokenId) external view returns (PartInfo memory);

    function useFuel(uint256 _tokenId, uint256 _amount) external;

    function getMinimumValue() external view returns (uint256);

    function getStringPartType(PartType typeOf) external view returns (string memory);

    function getCounter() external view returns (uint256);

    function getPartCount(PartType typeOf) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

interface IStarshipParts is IERC721EnumerableUpgradeable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mint(address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function exists(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

interface IStarship is IERC721EnumerableUpgradeable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mint(address _to, uint256 _tokenId) external;

    function exists(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/* ======== Structs ======== */
struct Ship {
    string name;
    string ipfs;
    string archetype;
    string brand;
    uint256 bridgeIntegrity;
    uint256 hullIntegrity;
    uint256 engineIntegrity;
    uint256 fuel;
}

interface IStarshipControl {
    function drainFuel(uint256 shipId) external;

    function getShip(uint256 _shipId) external view returns (Ship memory);

    function getShipPlanet(uint256 _shipId) external view returns (uint256, string memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/* ======== Structs ======== */
struct PlanetInfo {
    string name;
    string ipfs;
    string galaxy;
    address staking;
    address sWarp;
    uint256 shipCount;
    bool exists;
}

struct Docked {
    uint256 arrivalTime;
    uint256 planetId;
    uint256 fuelUsed;
}

interface IPlanets {
    function onPlanet(address _owner, uint256 _planetId) external view returns (bool);

    function numberOfPlanets() external view returns (uint256);

    function getPlanetInfo(uint256 planetId) external view returns (PlanetInfo memory);

    function getDockedInfo(uint256 shipId) external view returns (Docked memory);

    function notifyEarthShipCreated() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IsWarp {
    function rebase(uint256 WARPProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function getStakingContract() external view returns (address);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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