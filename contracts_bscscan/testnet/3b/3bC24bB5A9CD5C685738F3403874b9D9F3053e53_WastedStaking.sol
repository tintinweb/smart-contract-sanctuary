//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IWastedWarrior.sol";
import "./interfaces/IWastedStaking.sol";
import "./utils/PermissionGroup.sol";

contract WastedStaking is PermissionGroup, IWastedStaking, IERC721Receiver {
    using SafeMath for uint256;

    struct Staker {
        uint256 timeStartLock;
        uint256 timeClaim;
        uint256[] warriorIds;
    }

    WastedPool[] public _pools;

    IWastedWarrior public warriorContract;
    mapping(address => mapping(uint256 => Staker)) public _stakers;
    uint256 public feeClaim;
    uint256[] private helper;

    constructor (IWastedWarrior warriorAddress, uint256 feeClaim_) {
        warriorContract = warriorAddress;
        feeClaim = feeClaim_;
    }

    function setWastedWarriorContract(IWastedWarrior warriorAddress)
        external
        onlyOwner
    {
        require(address(warriorAddress) != address(0));
        warriorContract = warriorAddress;
    }

    function setFeeClaim(uint256 feeClaim_) external onlyOwner {
        feeClaim = feeClaim_;
    }

    function addPool(
        string memory name,
        uint256 lockedMonths,
        uint256 totalRewards,
        uint256 maxWarriorPerAddress
    ) external onlyOwner {
        require(lockedMonths > 0 && totalRewards > 0, "WS: invalid info");
        _pools.push(
            WastedPool(
                name,
                lockedMonths,
                totalRewards,
                0,
                maxWarriorPerAddress
            )
        );
        uint256 poolId = _pools.length.sub(1);
        emit Pool(
            poolId,
            name,
            lockedMonths,
            totalRewards,
            maxWarriorPerAddress
        );
    }

    function udpatePool(
        uint256 poolId,
        string memory name,
        uint256 lockedMonths,
        uint256 totalRewards,
        uint256 maxWarriorPerAddress
    ) external onlyOwner {
        WastedPool storage pool = _pools[poolId];
        require(
            lockedMonths > 0 && totalRewards >= pool.staked,
            "WS: invalid info"
        );

        pool.name = name;
        pool.lockedMonths = lockedMonths;
        pool.totalRewards = totalRewards;
        pool.maxWarriorPerAddress = maxWarriorPerAddress;

        emit Pool(
            poolId,
            name,
            lockedMonths,
            totalRewards,
            maxWarriorPerAddress
        );
    }

    function stake(uint256[] memory warriorIds, uint256 poolId)
        external
        override
    {
        Staker storage staker = _stakers[msg.sender][poolId];
        WastedPool storage pool = _pools[poolId];

        require(
            warriorIds.length <= pool.maxWarriorPerAddress,
            "WS: out of range"
        );
        require(
            staker.timeStartLock == 0 && staker.timeClaim == 0,
            "WS: address used"
        );
        require(pool.staked <= pool.totalRewards, "WS: full");

        staker.timeStartLock = block.timestamp;
        staker.timeClaim = block.timestamp.add(pool.lockedMonths);
        for (uint256 i = 0; i < warriorIds.length; i++) {
            uint256 _isListing = warriorContract.getWarriorListing(
                warriorIds[i]
            );
            bool _isBlacklisted = warriorContract.getWarriorInBlacklist(
                warriorIds[i]
            );
            require(_isListing == 0, "WS: delist first");
            require(!_isBlacklisted, "WS: warrior blacklisted");
            warriorContract.safeTransferFrom(
                msg.sender,
                address(this),
                warriorIds[i]
            );
            staker.warriorIds.push(warriorIds[i]);
            pool.staked = pool.staked.add(1);
        }

        emit Staked(warriorIds, poolId, msg.sender);
    }

    function unstake(uint256 poolId) external override {
        Staker storage staker = _stakers[msg.sender][poolId];
        WastedPool storage pool = _pools[poolId];
        uint256[] memory warriorIds = staker.warriorIds;

        require(
            staker.timeStartLock != 0 && staker.timeClaim != 0,
            "WS: address used"
        );
        require(staker.timeClaim > block.timestamp, "WS: Claim func");

        staker.timeStartLock = 0;
        staker.timeClaim = 0;

        for (uint256 i = 0; i < staker.warriorIds.length; i++) {
            bool _isBlacklisted = warriorContract.getWarriorInBlacklist(
                staker.warriorIds[i]
            );
            require(!_isBlacklisted, "WS: warrior blacklisted");
            warriorContract.transferFrom(
                address(this),
                msg.sender,
                staker.warriorIds[i]
            );
            pool.staked = pool.staked.sub(1);
        }
        staker.warriorIds = helper;
        
        emit Unstaked(warriorIds, poolId, msg.sender);
    }

    function claim(uint256 poolId) external payable override {
        require(msg.value == feeClaim, "WS: not enough");
        Staker storage staker = _stakers[msg.sender][poolId];
        uint256[] memory warriorIds = staker.warriorIds;

        require(
            staker.timeStartLock != 0 && staker.timeClaim != 0,
            "WS: address used"
        );
        require(staker.timeClaim < block.timestamp, "WS: Unstake func");

        staker.timeStartLock = 0;
        staker.timeClaim = 0;

        for (uint256 i = 0; i < staker.warriorIds.length; i++) {
            bool _isBlacklisted = warriorContract.getWarriorInBlacklist(
                staker.warriorIds[i]
            );
            require(!_isBlacklisted, "WS: warrior blacklisted");
            warriorContract.transferFrom(
                address(this),
                msg.sender,
                staker.warriorIds[i]
            );
        }
        staker.warriorIds = helper;

        (bool isTransferToOwner, ) = owner().call{value: msg.value}("");
        require(isTransferToOwner);

        emit Claimed( msg.sender, poolId, warriorIds);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     *
     * Requirements:
     * - only Owner of contract.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    /**
     * @notice Removes an address as operator.
     *
     * Requirements:
     * - only Owner of contract.
     */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWastedWarrior is IERC721 {
    enum PackageRarity {
        NONE,
        PLASTIC,
        STEEL,
        GOLD,
        PLATINUM
    }

    event WarriorCreated(
        uint256 indexed warriorId,
        bool isBreed,
        bool isFusion,
        uint256 indexed packageType,
        address indexed buyer
    );
    event WarriorListed(uint256 indexed warriorId, uint256 price);
    event WarriorDelisted(uint256 indexed warriorId);
    event WarriorBought(
        uint256 indexed warriorId,
        address buyer,
        address seller,
        uint256 price
    );
    event WarriorOffered(
        uint256 indexed warriorId,
        address buyer,
        uint256 price
    );
    event WarriorOfferCanceled(uint256 indexed warriorId, address buyer);
    event NameChanged(uint256 indexed warriorId, string newName);
    event PetAdopted(uint256 indexed warriorId, uint256 indexed petId);
    event PetReleased(uint256 indexed warriorId, uint256 indexed petId);
    event ItemsEquipped(uint256 indexed warriorId, uint256[] itemIds);
    event ItemsRemoved(uint256 indexed warriorId, uint256[] itemIds);
    event WarriorLeveledUp(
        uint256 indexed warriorId,
        uint256 level,
        uint256 amount
    );
    event BreedingWarrior(
        uint256 indexed fatherId,
        uint256 indexed motherId,
        uint256 newId,
        address owner
    );
    event FusionWarrior(
        uint256 indexed firstWarriorId,
        uint256 indexed secondWarriorId,
        uint256 newId,
        address owner
    );
    event AddWarriorToBlacklist(uint256 warriorId);
    event RemoveWarriorFromBlacklist(uint256 warriorId);

    struct Collaborator {
        uint256 totalSupplyPlasticPackages;
        uint256 totalSupplySteelPackages;
        uint256 totalSupplyGoldPackages;
        uint256 totalSupplyPlatinumPackages;
        uint256 mintedPlasticPackages;
        uint256 mintedSteelPackages;
        uint256 mintedGoldPackages;
        uint256 mintedPlatinumPackages;
    }

    struct Warrior {
        string name;
        uint256 level;
        uint256 weapon;
        uint256 armor;
        uint256 accessory;
        bool isBreed;
        bool isFusion;
    }

    /**
     * @notice add collaborator info.
     *
     */
    function addCollaborator(
        address collaborator,
        uint256 totalSupplyPlasticPackages,
        uint256 totalSupplySteelPackages,
        uint256 totalSupplyGoldPackages,
        uint256 totalSupplyPlatinumPackages
    ) external;

    /**
     * @notice get collaborator info.
     *
     */
    function getInfoCollaborator(address addressCollab)
        external
        view
        returns (Collaborator memory);

    /**
     * @notice Gets warrior information.
     *
     * @dev Prep function for staking.
     */
    function getWarrior(uint256 warriorId)
        external
        view
        returns (
            string memory name,
            bool isBreed,
            bool isFusion,
            uint256 level,
            uint256 pet,
            uint256[3] memory equipment
        );

    /**
     * @notice warrior listing.
     */
    function getWarriorListing(uint256 warriorId)
        external
        view
        returns (uint256);

    /**
     * @notice warrior listing.
     */
    function getWarriorInBlacklist(uint256 warriorId)
        external
        view
        returns (bool);

    /**
     * @notice get plastic package fee.
     */
    function getPlasticPackageFee() external view returns (uint256);

    /**
     * @notice get steel package fee.
     */
    function getSteelPackageFee() external view returns (uint256);

    /**
     * @notice get gold package fee.
     */
    function getGoldPackageFee() external view returns (uint256);

    /**
     * @notice get platinum package fee.
     */
    function getPlatinumPackageFee() external view returns (uint256);

    /**
     * @notice Function can level up a Warrior.
     *
     * @dev Prep function for staking.
     */
    function levelUp(uint256 warriorId, uint256 amount) external;

    /**
     * @notice Get current level of given warrior.
     *
     * @dev Prep function for staking.
     */
    function getWarriorLevel(uint256 warriorId) external view returns (uint256);

    /**
     * @notice mint warrior for specific address.
     *
     * @dev Function take 3 arguments are address of buyer, amount, rarityPackage.
     *
     * Requirements:
     * - onlyCollaborator
     */
    function mintFor(
        address buyer,
        uint256 amount,
        uint256 rarityPackage
    ) external;

    /**
     * @notice Function to change Warrior's name.
     *
     * @dev Function take 2 arguments are warriorId, new name of warrior.
     *
     * Requirements:
     * - `replaceName` must be a valid string.
     * - `replaceName` is not duplicated.
     * - You have to pay `serviceFeeToken` to change warrior's name.
     */
    function rename(uint256 warriorId, string memory replaceName) external;

    /**
     * @notice Owner equips items to their warrior by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the warrior.
     */
    function equipItems(uint256 warriorId, uint256[] memory itemIds) external;

    /**
     * @notice Owner removes items from their warrior. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - Caller must be owner of the warrior.
     */
    function removeItems(uint256 warriorId, uint256[] memory itemIds) external;

    /**
     * @notice Lists a warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     */
    function listing(uint256 warriorId, uint256 price) external;

    /**
     * @notice Remove from a list on sale.
     */
    function delist(uint256 warriorId) external;

    /**
     * @notice Instant buy a specific warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     * - Target warrior must be currently on sale time.
     * - Sent value must be exact the same as current listing price.
     * - Owner cannot buy.
     */
    function buy(uint256 warriorId, uint256 expectedPrice) external payable;

    /**
     * @notice Gives offer for a warrior.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint256 warriorId, uint256 offerPrice) external payable;

    /**
     * @notice Owner accept an offer to sell their warrior.
     */
    function acceptOffer(
        uint256 warriorId,
        address buyer,
        uint256 expectedPrice
    ) external;

    /**
     * @notice Abort an offer for a specific warrior.
     */
    function abortOffer(uint256 warriorId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint256 warriorId, uint256 petId) external;

    /**
     * @notice Abandons a Pet attached to a warrior.
     */
    function abandonPet(uint256 warriorId) external;

    /**
     * @notice Burn two warriors to create one new warrior.
     *
     * @dev Prep function for fusion
     *
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function fusionWarrior(
        uint256 firstWarriorId,
        uint256 secondWarriorId,
        address owner
    ) external;

    /**
     * @notice Breed based on two warriors.
     *
     * @dev Prep function for breed
     *
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function breedingWarrior(
        uint256 fatherId,
        uint256 motherId,
        address owner
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWastedStaking {
    event Pool(
        uint256 poolId,
        string name,
        uint256 lockedMonths,
        uint256 totalRewards,
        uint256 maxWarriorPerAddress
    );
    event Staked(
        uint256[] indexed warriorIds,
        uint256 indexed poolId,
        address staker
    );
    event Unstaked(
        uint256[] indexed warriorIds,
        uint256 indexed poolId,
        address staker
    );
    event Claimed(
        address staker,
        uint256 poolId,
        uint256[] warriorIds
    );

    struct WastedPool {
        string name;
        uint256 lockedMonths;
        uint256 totalRewards;
        uint256 staked;
        uint256 maxWarriorPerAddress;
    }

    /**
     * @notice Stake warrior earn nfts.
     */
    function stake(uint256[] memory warriorIds, uint256 poolId) external;

    /**
     * @notice Unstake warrior before finish.
     */
    function unstake(uint256 poolId) external;

    /**
     * @notice claim warrior and rewards.
     */
    function claim(uint256 poolId) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}