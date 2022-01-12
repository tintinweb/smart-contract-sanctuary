// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IKAISHIToken.sol";
import "./interfaces/INFTToken.sol";
import "./management/ManagedUpgradeable.sol";

/// @title NFTFactory
/// @author Applicature
/// @notice This contract allows you to interact with NFTs, calculate the price of the NFT, buy NFTs, get information about the NFTs of a particular user etc
/// @dev This contract allows you to interact with NFTs, calculate the price of the NFT, buy NFTs, get information about the NFTs of a particular user etc
contract NFTFactory is INFTFactory, ManagedUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice A user flag indicating whether or not the nft user has purchased the lowest level
    /// @dev A user flag indicating whether or not the nft user has purchased the lowest level
    mapping(address => bool) public isUserNft;

    /// @notice Gets additional information about NFT at the NFT address
    /// @dev Gets additional information about NFT at the NFT address
    mapping(address => NFTInfo) public nftInfo;

    /// @notice the kaishi token which initializing later
    /// @dev the kaishi token which initializing later
    IKAISHIToken public kaishiToken;

    /// @notice the address of tresuary
    /// @dev the address of tresuary
    address public treasury;

    /// @notice the burn percentage
    /// @dev the burn percentage
    uint256 public burnPercentage;

    EnumerableSet.AddressSet internal _nftMembershipAddress;

    /// @notice Initialize contract after deployment
    /// @dev Initialize contract after deployment
    /// @param management_ the address of management
    function initialize(address management_) external initializer {
        __Managed_init(management_);
        _setDependency();
        burnPercentage = 50 * DECIMALS18;
    }

    /// @notice Gets information about all NFTs such as address, total supply, current price etc
    /// @dev Gets information about all NFTs such as address, total supply, current price etc
    /// @return nftsAddress returns the addresses of NFTs
    /// @return nftsInfo returns additional information for each NFT
    /// @return nftsCurrentPrice returns current price for each NFT
    function getMemberships()
        external
        view
        override
        returns (
            address[] memory nftsAddress,
            NFTInfo[] memory nftsInfo,
            uint256[] memory nftsCurrentPrice
        )
    {
        uint256 length = _nftMembershipAddress.length();
        nftsInfo = new NFTInfo[](length);
        nftsAddress = new address[](length);
        nftsCurrentPrice = new uint256[](length);

        for (uint256 index = 0; index < length; index++) {
            nftsAddress[index] = _nftMembershipAddress.at(index);
            nftsInfo[index] = nftInfo[_nftMembershipAddress.at(index)];
            nftsCurrentPrice[index] = calculatePrice(nftsAddress[index], 1);
        }
    }

    /// @notice Gets information about user NFTs
    /// @dev Gets information about user NFTs
    /// @param _recipient the address of recipient
    /// @return nft returns the addresses of NFTs
    /// @return count returns amount of recipient's NFT at each address
    /// @return highest returns the address with the highest price per NFT among all recipient's NFTs
    function getUserInfo(address _recipient)
        external
        view
        override
        returns (
            address[] memory nft,
            uint256[] memory count,
            address highest
        )
    {
        uint256 length = _nftMembershipAddress.length();
        nft = new address[](length);
        count = new uint256[](length);
        for (uint256 index; index < length; index++) {
            address nftAddress = _nftMembershipAddress.at(index);
            nft[index] = nftAddress;
            count[index] = INFTToken(nftAddress).balanceOf(_recipient);
        }
        highest = _getHighest(_recipient);
    }

    /// @notice Gets the address with the highest price per NFT among all recipient's NFTs
    /// @dev Gets the address with the highest price per NFT among all recipient's NFTs
    /// @param _recipient the address of recipient
    /// @return Returns the address with the highest price per NFT among all recipient's NFTs
    function getHighest(address _recipient)
        external
        view
        override
        returns (address)
    {
        return _getHighest(_recipient);
    }

    /// @notice Gets the addresses of NFTs
    /// @dev Gets the addresses of NFTs
    /// @return nftAddress returns the addresses of NFTs
    function getSupportNFTAddress()
        external
        view
        override
        returns (address[] memory nftAddress)
    {
        uint256 length = _nftMembershipAddress.length();
        nftAddress = new address[](length);
        for (uint256 index = 0; index < length; index++) {
            nftAddress[index] = _nftMembershipAddress.at(index);
        }
    }

    /// @notice Gets current price of NFT by address of NFT
    /// @dev Gets current price of NFT by address of NFT
    /// @param _nftAddress the address of NFT
    /// @return Returns current price of NFT by address of NFT
    function getCurrentPrice(address _nftAddress)
        external
        view
        override
        returns (uint256)
    {
        return calculatePrice(_nftAddress, 1);
    }

    /// @notice Purchases the NFT
    /// @dev Purchases the NFT
    /// @param _nftAddress the address of NFT
    function buy(address _nftAddress) external override {
        uint256 _amount = 1;
        NFTInfo storage info = nftInfo[_nftAddress];
        require(info.totalSupply > 0, ERROR_TOKEN_NOT_SUPPORTED);
        require(_amount <= info.remainingSupply, ERROR_NOT_ENOUGH_NFT_FOR_SALE);
        uint256 price = calculatePrice(_nftAddress, _amount);
        uint256 burnAmount = (price * burnPercentage) / PERCENTAGE_100;
        uint256 transferAmount = price - burnAmount;
        if (burnPercentage > 0) {
            kaishiToken.burnFrom(_msgSender(), burnAmount);
        }
        if (transferAmount > 0) {
            require(
                kaishiToken.transferFrom(
                    _msgSender(),
                    treasury,
                    transferAmount
                ),
                ERROR_ERC20_CALL_ERROR
            );
        }
        if (info.prerequisiteNFT != address(0)) {
            uint256[] memory inIds = INFTToken(info.prerequisiteNFT).getIds(
                _msgSender(),
                0,
                _amount
            );
            require(inIds.length == _amount, ERROR_NOT_ENOUGH_PREVIEUS_NFT);
            INFTToken(info.prerequisiteNFT).transferFrom(
                _msgSender(),
                address(this),
                inIds[0]
            );
            nftInfo[info.prerequisiteNFT].remainingSupply += _amount;
        } else {
            require(
                isUserNft[_msgSender()] == false,
                ERROR_UNPREDICTABLE_MEMBER_ACTION
            );
        }
        uint256[] memory outIds = INFTToken(_nftAddress).getIds(
            address(this),
            0,
            _amount
        );
        if (outIds.length >= _amount) {
            INFTToken(_nftAddress).transferFrom(
                address(this),
                _msgSender(),
                outIds[0]
            );
        } else {
            INFTToken(_nftAddress).mint(_msgSender());
        }
        info.remainingSupply -= _amount;
        isUserNft[_msgSender()] = true;
        emit Buy(_msgSender(), _nftAddress, _amount);
    }

    /// @notice Removing address of NFT from membership
    /// @dev Removing address of NFT from membership by administrator
    /// @param _nftAddress the address of NFT
    function removeTier(address _nftAddress)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        require(_nftMembershipAddress.remove(_nftAddress), ERROR_NOT_FOUND);
        delete nftInfo[_nftAddress];
        emit RemoveTier(_nftAddress);
    }

    /// @notice Adding new NFT to the membership
    /// @dev Adding new NFT to the membership by administrator
    /// @param _nftAddress the address of NFT
    /// @param _basePrice the base price of NFT
    /// @param _prerequisiteNFT the address of prerequisite NFT
    /// @param _priceModifier the price modifier of NFT
    function addNewTier(
        address _nftAddress,
        uint256 _basePrice,
        address _prerequisiteNFT,
        uint256 _priceModifier
    ) external override requirePermission(ROLE_ADMIN) {
        require(_nftAddress != address(0), ERROR_INVALID_ADDRESS);
        require(_basePrice > 0, ERROR_AMOUNT_IS_ZERO);
        require(_nftMembershipAddress.add(_nftAddress), ERROR_IS_EXISTS);
        NFTInfo storage info = nftInfo[_nftAddress];
        uint256 totalSupply = INFTToken(_nftAddress).totalSupply();
        info.remainingSupply = totalSupply;
        info.totalSupply = totalSupply;
        info.prerequisiteNFT = _prerequisiteNFT;
        info.priceModifier = _priceModifier;
        info.basePrice = _basePrice;
        emit AddTier(_nftAddress);
    }

    /// @notice Sets remaining supply for specified NFT
    /// @dev Sets remaining supply for specified NFT by administrator
    /// @param _nftAddress the address of NFT
    /// @param _amount the remaining supply
    function setRemainingSupply(address _nftAddress, uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        nftInfo[_nftAddress].remainingSupply = _amount;
    }

    /// @notice Sets burn percentage for all NFTs
    /// @dev Sets burn percentage for all NFTs by administrator
    /// @param _amount the burn percentage
    function setBurnPercentage(uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        require(_amount <= PERCENTAGE_100, ERROR_MORE_THEN_MAX);
        burnPercentage = _amount;
    }

    /// @notice Sets base price for specified NFT
    /// @dev Sets base price for specified NFT by administrator
    /// @param _nftAddress the address of NFT
    /// @param _amount the base price
    function setBasePrice(address _nftAddress, uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        require(_amount > 0, ERROR_AMOUNT_IS_ZERO);
        nftInfo[_nftAddress].basePrice = _amount;
    }

    /// @notice Sets price modifier for specified NFT
    /// @dev Sets price modifier for specified NFT by administrator
    /// @param _nftAddress the address of NFT
    /// @param _amount the price modifier
    function setPriceModifier(address _nftAddress, uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        nftInfo[_nftAddress].priceModifier = _amount;
    }

    /// @notice Sets the address of prerequisite NFT for specified NFT
    /// @dev Sets the address of prerequisite NFT for specified NFT by administrator
    /// @param _nftAddress the address of NFT
    /// @param _prerequisteNft the address of prerequisite NFT
    function setPrerequisiteNFT(address _nftAddress, address _prerequisteNft)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        nftInfo[_nftAddress].prerequisiteNFT = _prerequisteNft;
    }

    /// @notice Sets dependency such as the address of treasury and initializing kaishi token
    /// @dev Sets dependency such as the address of treasury and initializing kaishi token
    function setDependency()
        external
        override
        requirePermission(GENERAL_CAN_UPDATE_DEPENDENCY)
    {
        _setDependency();
    }

    /// @notice Calculates the price for the given amount of NFTs
    /// @dev Calculates the price for the given amount of NFTs
    /// @param _nftAddress the address of NFT
    /// @param _amount the amount of NFTs
    /// @return Returns the price for the given amount of NFTs
    function calculatePrice(address _nftAddress, uint256 _amount)
        public
        view
        returns (uint256)
    {
        NFTInfo memory info = nftInfo[_nftAddress];
        uint256 sellToken = info.totalSupply - info.remainingSupply;
        uint256 currentPrice = info.basePrice + sellToken * info.priceModifier;
        uint256 newPrice = info.basePrice +
            (sellToken + _amount - 1) *
            info.priceModifier;
        return ((newPrice + currentPrice) * _amount) / 2;
    }

    /// @notice Gets the address with the highest price per NFT among all recipient's NFTs
    /// @dev Gets the address with the highest price per NFT among all recipient's NFTs
    /// @param _recipient the address of recipient
    /// @return Returns the address with the highest price per NFT among all recipient's NFTs
    function _getHighest(address _recipient) internal view returns (address) {
        address highestNFT;
        uint256 maxPrice;
        for (uint256 i; i < _nftMembershipAddress.length(); i++) {
            address _nftAddress = _nftMembershipAddress.at(i);
            if (
                maxPrice < nftInfo[_nftAddress].basePrice &&
                INFTToken(_nftAddress).balanceOf(_recipient) > 0
            ) {
                maxPrice = nftInfo[_nftAddress].basePrice;
                highestNFT = _nftMembershipAddress.at(i);
            }
        }
        return highestNFT;
    }

    /// @notice Sets dependency such as the address of treasury and initializing kaishi token
    /// @dev Sets dependency such as the address of treasury and initializing kaishi token
    function _setDependency() internal {
        kaishiToken = IKAISHIToken(
            management.contractRegistry(CONTRACT_KAISHI_TOKEN)
        );
        treasury = management.contractRegistry(ADDRESS_TREASURY);
    }
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

pragma solidity ^0.8.9;

interface INFTFactory {
    struct NFTInfo {
        uint256 totalSupply;
        uint256 remainingSupply;
        uint256 basePrice;
        uint256 priceModifier;
        address prerequisiteNFT;
    }

    event AddTier(address _nftAddress);
    event RemoveTier(address _nftAddress);
    event Buy(address indexed sender, address nft, uint256 amount);

    function getMemberships()
        external
        view
        returns (
            address[] memory nftAddress,
            NFTInfo[] memory nftsInfo,
            uint256[] memory nftsCurrentPrice
        );

    function getUserInfo(address _recipient)
        external
        view
        returns (
            address[] memory nft,
            uint256[] memory count,
            address highest
        );

    function getHighest(address _recipient) external view returns (address);

    function getSupportNFTAddress() external view returns (address[] memory);

    function getCurrentPrice(address _nftAddress)
        external
        view
        returns (uint256);

    function removeTier(address _nftAddress) external;

    function addNewTier(
        address _nftAddress,
        uint256 _basePrice,
        address _prerequisiteNFT,
        uint256 _priceModifier
    ) external;

    function buy(address _nftAddress) external;

    function setPrerequisiteNFT(address _nftAddress, address _prerequisteNft)
        external;

    function setRemainingSupply(address _nftAddress, uint256 _amount) external;

    function setPriceModifier(address _nftAddress, uint256 _amount) external;

    function setBasePrice(address _nftAddress, uint256 _amount) external;

    function setBurnPercentage(uint256 _amount) external;

    function setDependency() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKAISHIToken is IERC20 {
    function burn(uint256 _amount) external;

    function burnFrom(address _account, uint256 _amount) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTToken is IERC721 {
    function getIds(
        address _owner,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256[] memory result);

    function mint(address _recipient) external;

    function setOpenTransfer(bool _isOpen) external;

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IManagement.sol";
import "./Constants.sol";

/// @title ManagedUpgradeable
/// @author Applicature
/// @notice This contract is an upgradable version of Managed
/// @dev This contract is an upgradable version of Managed
contract ManagedUpgradeable is OwnableUpgradeable {
    /// @notice The state variable of IManagement interface
    /// @dev The state variable of IManagement interface
    IManagement public management;

    /// @notice Checks whether the sender has permission prior to executing the function
    /// @dev Checks whether the sender has permission prior to executing the function
    /// @param _permission the permission for sender
    modifier requirePermission(uint256 _permission) {
        require(_hasPermission(_msgSender(), _permission), ERROR_ACCESS_DENIED);
        _;
    }

    /// @notice Initializes the address of management after deployment
    /// @dev Initializes the address of management after deployment by owner of smart contract
    /// @param _management the address of management
    function setManagementContract(address _management) external onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);
        management = IManagement(_management);
    }

    /// @notice Checks whether the sender has permission
    /// @dev Checks whether the sender has permission
    /// @param _subject the address of sender
    /// @param _permission the permission for sender
    /// @return Returns whether the sender has permission
    function _hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }

    /// @notice Initializes the address of management and initial owner
    /// @dev Initializes the address of management, initial owner and protect from being invoked twice
    /// @param _managementAddress the address of management
    function __Managed_init(address _managementAddress) internal initializer {
        management = IManagement(_managementAddress);
        __Ownable_init();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

pragma solidity ^0.8.9;

interface IManagement {
    event PoolOwnerSet(address indexed owner, address indexed pool, bool value);

    event PermissionsSet(
        address indexed subject,
        uint256[] indexed permissions,
        bool value
    );

    event UsersPermissionsSet(
        address[] indexed subject,
        uint256 indexed permissions,
        bool value
    );

    event PermissionSet(
        address indexed subject,
        uint256 indexed permission,
        bool value
    );

    event ContractRegistered(
        uint256 indexed key,
        address indexed source,
        address target
    );

    function isKYCPassed(
        address _address,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (bool);

    function requireAccess(address _address, address _pool)
        external
        view
        returns (bool);

    function contractRegistry(uint256 _key)
        external
        view
        returns (address payable);

    function permissions(address _address, uint256 _permission)
        external
        view
        returns (bool);

    function kycSigner() external view returns (address);

    function setPoolOwner(
        address _pool,
        address _owner,
        bool _value
    ) external;

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external;

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external;

    function registerContract(uint256 _key, address payable _target) external;

    function setKycWhitelists(address[] calldata _address, bool _value)
        external;

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 100 * DECIMALS18;
uint256 constant PERCENTAGE_1 = DECIMALS18;
uint256 constant MAX_FEE_PERCENTAGE = 99 * DECIMALS18;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "0x1";
string constant ERROR_NO_CONTRACT = "0x2";
string constant ERROR_NOT_AVAILABLE = "0x3";
string constant ERROR_KYC_MISSING = "0x4";
string constant ERROR_INVALID_ADDRESS = "0x5";
string constant ERROR_INCORRECT_CALL_METHOD = "0x6";
string constant ERROR_AMOUNT_IS_ZERO = "0x7";
string constant ERROR_HAVENT_ALLOCATION = "0x8";
string constant ERROR_AMOUNT_IS_MORE_TS = "0x9";
string constant ERROR_ERC20_CALL_ERROR = "0xa";
string constant ERROR_DIFF_ARR_LENGTH = "0xb";
string constant ERROR_METHOD_DISABLE = "0xc";
string constant ERROR_SEND_VALUE = "0xd";
string constant ERROR_NOT_ENOUGH_NFT_IDS = "0xe";
string constant ERROR_INCORRECT_FEE = "0xf";
string constant ERROR_WRONG_IMPLEMENT_ADDRESS = "0x10";
string constant ERROR_INVALID_SIGNER = "0x11";
string constant ERROR_NOT_FOUND = "0x12";
string constant ERROR_IS_EXISTS = "0x13";
string constant ERROR_IS_NOT_EXISTS = "0x14";
string constant ERROR_TIME_OUT = "0x15";
string constant ERROR_NFT_NOT_EXISTS = "0x16";
string constant ERROR_MINTING_COMPLETED = "0x17";
string constant ERROR_TOKEN_NOT_SUPPORTED = "0x18";
string constant ERROR_NOT_ENOUGH_NFT_FOR_SALE = "0x19";
string constant ERROR_NOT_ENOUGH_PREVIEUS_NFT = "0x1a";
string constant ERROR_FAIL = "0x1b";
string constant ERROR_MORE_THEN_MAX = "0x1c";
string constant ERROR_VESTING_NOT_START = "0x1d";
string constant ERROR_VESTING_IS_STARTED = "0x1e";
string constant ERROR_IS_SET = "0x1f";
string constant ERROR_ALREADY_CALL_METHOD = "0x20";
string constant ERROR_INCORRECT_DATE = "0x21";
string constant ERROR_IS_NOT_SALE = "0x22";
string constant ERROR_UNPREDICTABLE_MEMBER_ACTION = "0x23";

bytes32 constant KYC_CONTAINER_TYPEHASE = keccak256(
    "Container(address sender,uint256 deadline)"
);

bytes32 constant _GENESIS_CONTAINER_TYPEHASE = keccak256(
    "Container(string stakingName,bool isETHStake,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
);
bytes32 constant _LIQUIDITY_MINING_CONTAINER_TYPEHASE = keccak256(
    "Container(string stakingName,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
);

address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 2;

uint256 constant MANAGEMENT_CAN_SET_KYC_WHITELISTED = 3;
uint256 constant MANAGEMENT_CAN_SET_PRIVATE_WHITELISTED = 4;
uint256 constant MANAGEMENT_WHITELISTED_KYC = 5;
uint256 constant MANAGEMENT_WHITELISTED_PRIVATE = 6;
uint256 constant MANAGEMENT_CAN_SET_POOL_OWNER = 7;

uint256 constant REGISTER_CAN_ADD_STAKING = 21;
uint256 constant REGISTER_CAN_REMOVE_STAKING = 22;
uint256 constant REGISTER_CAN_ADD_POOL = 30;
uint256 constant REGISTER_CAN_REMOVE_POOL = 31;

uint256 constant GENERAL_CAN_UPDATE_DEPENDENCY = 100;
uint256 constant NFT_CAN_TRANSFER_NFT = 101;
uint256 constant NFT_CAN_MINT_NFT = 102;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKING_REGISTER = 2;
uint256 constant CONTRACT_POOL_REGISTER = 3;
uint256 constant CONTRACT_NFT_FACTORY = 4;
uint256 constant ADDRESS_TREASURY = 5;
uint256 constant ADDRESS_FACTORY_SIGNER = 6;
uint256 constant ADDRESS_PROXY_OWNER = 7;
uint256 constant ADDRESS_MANAGED_OWNER = 8;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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