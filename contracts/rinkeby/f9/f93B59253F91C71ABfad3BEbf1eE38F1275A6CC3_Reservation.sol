// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./interfaces/IOwner.sol";

contract Owned is IOwner {
    address public owner;
    address public remote;

    modifier onlyOwner() {
        require(
            owner == msg.sender ||
                address(this) == msg.sender ||
                remote == msg.sender,
            "NOT_OWNER needed"
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addRemote(address adr) public {
        require(owner == msg.sender, "NOT_OWNER");
        remote = adr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IProvider.sol";
import "./Owned.sol";

contract Provider is IProvider, Owned {
    uint256 counter = 0;

    struct ProviderInternalStruct {
        address owner;
        uint256 providerListPointer; // needed to delete a "Provider"
        bytes32[] unitKeys;
        mapping(bytes32 => uint256) unitKeyPointers;
        //custom data
        string name;
    }

    event LogNewProvider(address sender, IProvider.ProviderStruct provider);
    event LogProviderDeleted(address sender, bytes32 providerId);

    mapping(bytes32 => ProviderInternalStruct) public providerStructs;
    bytes32[] public providerList;

    constructor() public {}

    function getProviderCount() external view returns (uint256) {
        return providerList.length;
    }

    function isProvider(bytes32 providerId) public view returns (bool) {
        if (providerList.length == 0) return false;
        return
            providerList[providerStructs[providerId].providerListPointer] ==
            providerId;
    }

    function isProviderOwner(bytes32 providerId) public view returns (bool) {
        return msg.sender == providerStructs[providerId].owner;
    }

    function isProviderOwner(address sender, bytes32 providerId)
        public
        view
        returns (bool)
    {
        return sender == providerStructs[providerId].owner;
    }

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256)
    {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        return providerStructs[providerId].unitKeys.length;
    }

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32)
    {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        return providerStructs[providerId].unitKeys[row];
    }

    function getAllProviders() external view returns (ProviderStruct[] memory) {
        ProviderStruct[] memory array =
            new ProviderStruct[](providerList.length);

        for (uint256 i = 0; i < array.length; i++) {
            array[i].providerId = providerList[i];
            array[i].name = providerStructs[array[i].providerId].name;
            array[i].unitKeys = providerStructs[array[i].providerId].unitKeys;
            array[i].owner = providerStructs[array[i].providerId].owner;
        }
        return array;
    }

    function createProvider(address sender, string calldata name)
        external
        returns (bool)
    {
        require(remote == msg.sender, "NOT_REMOTE_CALL");
        require(
            createProvider(sender, bytes32(counter++), name),
            "CREATE_PROVIDER_FAILED"
        );
        return true;
    }

    function createProvider(
        address sender,
        bytes32 providerId,
        string memory name
    ) internal returns (bool) {
        require(!isProvider(providerId), "DUPLICATE_PROVIDER_KEY"); // duplicate key prohibited
        providerList.push(providerId);
        providerStructs[providerId].providerListPointer =
            providerList.length -
            1;
        providerStructs[providerId].name = name;
        providerStructs[providerId].owner = sender;

        emit LogNewProvider(
            sender,
            ProviderStruct(
                providerStructs[providerId].owner,
                providerId,
                providerStructs[providerId].unitKeys,
                providerStructs[providerId].name
            )
        );
        return true;
    }

    function deleteProvider(address sender, bytes32 providerId)
        external
        returns (bool)
    {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        require(
            isProviderOwner(sender, providerId),
            "NOT_OWNER_DELETE_PROVIDER"
        );
        // the following would break referential integrity
        require(
            providerStructs[providerId].unitKeys.length <= 0,
            "LENGTH_UNIT_KEYS_GREATER_THAN_ZERO"
        );
        uint256 rowToDelete = providerStructs[providerId].providerListPointer;
        bytes32 keyToMove = providerList[providerList.length - 1];
        providerList[rowToDelete] = keyToMove;
        providerStructs[keyToMove].providerListPointer = rowToDelete;
        providerList.pop();

        emit LogProviderDeleted(sender, providerId);
        return true;
    }

    function addUnit(
        address sender,
        bytes32 providerId,
        bytes32 unitId
    ) public {
        require(isProviderOwner(sender, providerId), "NOT_OWNER_ADD_UNIT");
        providerStructs[providerId].unitKeys.push(unitId);
        providerStructs[providerId].unitKeyPointers[unitId] =
            providerStructs[providerId].unitKeys.length -
            1;
    }

    function removeUnit(
        address sender,
        bytes32 providerId,
        bytes32 unitId
    ) public {
        require(isProviderOwner(sender, providerId), "NOT_OWNER_REMOVE_UNIT");
        uint256 rowToDelete =
            providerStructs[providerId].unitKeyPointers[unitId];
        bytes32 keyToMove =
            providerStructs[providerId].unitKeys[
                providerStructs[providerId].unitKeys.length - 1
            ];
        providerStructs[providerId].unitKeys[rowToDelete] = keyToMove;
        providerStructs[providerId].unitKeyPointers[keyToMove] = rowToDelete;
        providerStructs[providerId].unitKeys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IReservation.sol";
import "./interfaces/unlock/IPublicLock.sol";
import "./interfaces/unlock/IUnlock.sol";

import "./Owned.sol";
import "./Unit.sol";

contract Reservation is IReservation, Owned {
    uint256 counter;

    struct ReservationInternalStruct {
        uint256 reservationListPointer;
        bytes32 unitKey;
        address owner;
        //custom data
        uint256 checkInKey;
    }

    event LogNewReservation(address sender, ReservationStruct reservation);
    event LogReservationDeleted(address sender, bytes32 reservationId);
    event LogPurchaseReservation(address sender, ReservationStruct reservation);
    event LogRefundReservation(address sender, ReservationStruct reservation);

    Unit internal unit;
    IPublicLock internal lock;
    IUnlock internal unlock;

    mapping(bytes32 => ReservationInternalStruct) public reservationStructs;
    bytes32[] public reservationList;

    constructor(address adrUnit) public {
        unit = Unit(adrUnit);
        lock = IPublicLock(0x2D7Fa4dbdF5E7bfBC87523396aFfD6d38c9520fa);
    }

    function initializeUnlock() public {
        unlock.initialize(msg.sender);
    }

    function setUnitAddress(address adr) external onlyOwner {
        unit = Unit(adr);
    }

    function setLockAddress(address payable adr) external onlyOwner {
        lock = IPublicLock(adr);
    }

    function getReservationCount() public view returns (uint256) {
        return reservationList.length;
    }

    function isReservation(bytes32 reservationId) public view returns (bool) {
        if (reservationList.length == 0) return false;
        return
            reservationList[
                reservationStructs[reservationId].reservationListPointer
            ] == reservationId;
    }

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory)
    {
        ReservationStruct[] memory array =
            new ReservationStruct[](getReservationCount());

        for (uint256 i = 0; i < array.length; i++) {
            array[i].reservationId = reservationList[i];
            array[i].unitKey = reservationStructs[array[i].reservationId]
                .unitKey;
            array[i].owner = reservationStructs[array[i].reservationId].owner;
        }
        return array;
    }

    function createReservation(address sender, bytes32 unitId)
        public
        payable
        returns (bool)
    {
        require(createReservation(sender, bytes32(counter++), unitId));
        return true;
    }

    function createReservation(
        address sender,
        bytes32 reservationId,
        bytes32 unitId
    ) public returns (bool) {
        require(unit.isUnit(unitId), "UNIT_DOES_NOT_EXIST");
        require(!isReservation(reservationId), "DUPLICATE_RESERVATION_KEY"); // duplicate key prohibited
        require(purchaseReservation(sender, reservationId), "PURCHASE_FAILED");

        reservationList.push(reservationId);
        reservationStructs[reservationId].reservationListPointer =
            reservationList.length -
            1;
        reservationStructs[reservationId].unitKey = unitId;
        reservationStructs[reservationId].owner = sender;
        reservationStructs[reservationId].checkInKey = generateRandomCheckInKey(
            block.number + uint256(unitId)
        );

        unit.addReservation(unitId, reservationId);

        emit LogNewReservation(
            sender,
            ReservationStruct(
                reservationId,
                reservationStructs[reservationId].unitKey,
                reservationStructs[reservationId].owner
            )
        );
        return true;
    }

    function deleteReservation(address sender, bytes32 reservationId)
        public
        returns (bool)
    {
        require(isReservation(reservationId), "RESERVATION_DOES_NOT_EXIST");

        // delete from table
        uint256 rowToDelete =
            reservationStructs[reservationId].reservationListPointer;
        bytes32 keyToMove = reservationList[reservationList.length - 1];
        reservationList[rowToDelete] = keyToMove;
        reservationStructs[reservationId].reservationListPointer = rowToDelete;
        reservationList.pop();

        bytes32 unitId = reservationStructs[reservationId].unitKey;
        unit.removeReservation(unitId, reservationId);
        emit LogReservationDeleted(sender, reservationId);
        return true;
    }

    function purchaseReservation(address sender, bytes32 reservationId)
        internal
        returns (bool)
    {
        require(msg.value >= lock.keyPrice(), "VALUE_TOO_SMALL");
        lock.purchase.value(msg.value)(
            lock.keyPrice(),
            sender,
            address(0),
            "0x00"
        );
        uint256 tokenId = lock.getTokenIdFor(sender);
        lock.setKeyManagerOf(tokenId, address(this));
        require(
            lock.keyManagerOf(tokenId) == address(this),
            "LOCK_MANAGER_NOT_SET_TO_RESERVATION_CONTRACT"
        );
        emit LogPurchaseReservation(
            sender,
            ReservationStruct(
                reservationId,
                reservationStructs[reservationId].unitKey,
                reservationStructs[reservationId].owner
            )
        );
        return true;
    }

    function refundReservation(
        address sender,
        bytes32 reservationId,
        uint256 checkInKey
    ) external returns (bool) {
        require(
            reservationStructs[reservationId].checkInKey == checkInKey,
            "CHECK_IN_KEY_WRONG"
        );
        uint256 tokenId = lock.getTokenIdFor(sender);
        lock.cancelAndRefund(tokenId);

        deleteReservation(sender, reservationId);

        emit LogRefundReservation(
            sender,
            ReservationStruct(
                reservationId,
                reservationStructs[reservationId].unitKey,
                reservationStructs[reservationId].owner
            )
        );

        return true;
    }

    function generateRandomCheckInKey(uint256 id)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(id))) % 10**8;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUnit.sol";

import "./Owned.sol";
import "./Provider.sol";

contract Unit is IUnit, Owned {
    uint256 counter;

    struct UnitInternalStruct {
        uint256 unitListPointer;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        mapping(bytes32 => uint256) reservationKeyPointers;
        //custom data
        uint16 guestCount;
    }

    event LogNewUnit(address sender, UnitStruct);
    event LogUnitDeleted(address sender, bytes32 unitId);

    Provider internal provider;

    mapping(bytes32 => UnitInternalStruct) public unitStructs;
    bytes32[] public unitList;

    constructor(address adr) public {
        provider = Provider(adr);
    }

    function setProviderAddress(address adr) external onlyOwner {
        provider = Provider(adr);
    }

    function getUnitCount() public view returns (uint256) {
        return unitList.length;
    }

    function isUnit(bytes32 unitId) public view returns (bool) {
        if (unitList.length == 0) return false;
        return unitList[unitStructs[unitId].unitListPointer] == unitId;
    }

    function getAllUnits() external view returns (UnitStruct[] memory) {
        UnitStruct[] memory array = new UnitStruct[](getUnitCount());

        for (uint256 i = 0; i < array.length; i++) {
            array[i].unitId = unitList[i];
            array[i].guestCount = unitStructs[array[i].unitId].guestCount;
            array[i].providerKey = unitStructs[array[i].unitId].providerKey;
            array[i].reservationKeys = unitStructs[array[i].unitId]
                .reservationKeys;
        }
        return array;
    }

    function createUnit(
        address sender,
        bytes32 providerId,
        uint16 guestCount
    ) external returns (bool) {
        require(createUnit(sender, bytes32(counter++), providerId, guestCount));
        return true;
    }

    function createUnit(
        address sender,
        bytes32 unitId,
        bytes32 providerId,
        uint16 guestCount
    ) public returns (bool) {
        require(provider.isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        require(!isUnit(unitId), "DUPLICATE_UNIT_KEY"); // duplicate key prohibited
        require(guestCount > 0, "GUEST_COUNT_IMPLAUSIBLE");
        require(
            provider.isProviderOwner(sender, providerId),
            "NOT_OWNER_CREATE_UNIT"
        );

        unitList.push(unitId);
        unitStructs[unitId].unitListPointer = unitList.length - 1;
        unitStructs[unitId].providerKey = providerId;
        unitStructs[unitId].guestCount = guestCount;

        provider.addUnit(sender, providerId, unitId);

        emit LogNewUnit(
            sender,
            UnitStruct(
                unitId,
                unitStructs[unitId].providerKey,
                unitStructs[unitId].reservationKeys,
                unitStructs[unitId].guestCount
            )
        );
        return true;
    }

    function deleteUnit(address sender, bytes32 unitId)
        external
        returns (bool)
    {
        require(isUnit(unitId), "UNIT_DOES_NOT_EXIST");
        require(
            provider.isProviderOwner(sender, unitStructs[unitId].providerKey),
            "NOT_OWNER_DELETE_UNIT"
        );

        // delete from table
        uint256 rowToDelete = unitStructs[unitId].unitListPointer;
        bytes32 keyToMove = unitList[unitList.length - 1];
        unitList[rowToDelete] = keyToMove;
        unitStructs[unitId].unitListPointer = rowToDelete;
        unitList.pop();

        bytes32 providerId = unitStructs[unitId].providerKey;
        provider.removeUnit(sender, providerId, unitId);
        emit LogUnitDeleted(sender, unitId);
        return true;
    }

    function addReservation(bytes32 unitId, bytes32 reservationId) public {
        unitStructs[unitId].reservationKeys.push(reservationId);
        unitStructs[unitId].reservationKeyPointers[reservationId] =
            unitStructs[unitId].reservationKeys.length -
            1;
    }

    function removeReservation(bytes32 unitId, bytes32 reservationId) public {
        uint256 rowToDelete =
            unitStructs[unitId].reservationKeyPointers[reservationId];
        bytes32 keyToMove =
            unitStructs[unitId].reservationKeys[
                unitStructs[unitId].reservationKeys.length - 1
            ];
        unitStructs[unitId].reservationKeys[rowToDelete] = keyToMove;
        unitStructs[unitId].reservationKeyPointers[keyToMove] = rowToDelete;
        unitStructs[unitId].reservationKeys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

interface IOwner {
    function addRemote(address adr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerId;
        bytes32[] unitKeys;
        string name;
    }

    function getProviderCount() external view returns (uint256);

    function isProvider(bytes32 providerId) external view returns (bool);

    function isProviderOwner(address sender, bytes32 providerId)
        external
        view
        returns (bool);

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256);

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function createProvider(address sender, string calldata name)
        external
        returns (bool);

    function deleteProvider(address sender, bytes32 providerId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IReservation {
    struct ReservationStruct {
        bytes32 reservationId;
        bytes32 unitKey;
        address owner;
    }

    function setUnitAddress(address adr) external;

    function getReservationCount() external view returns (uint256);

    function isReservation(bytes32 reservationId) external view returns (bool);

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory);

    function createReservation(address sender, bytes32 unitId)
        external
        payable
        returns (bool);

    function deleteReservation(address sender, bytes32 reservationId) external returns (bool);

    function refundReservation(
        address sender,
        bytes32 reservationId,
        uint256 checkInKey
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IOwner.sol";

interface IUnit {
    struct UnitStruct {
        bytes32 unitId;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        uint16 guestCount;
    }

    function setProviderAddress(address adr) external;

    function getUnitCount() external view returns (uint256);

    function isUnit(bytes32 unitId) external view returns (bool);

    function getAllUnits() external view returns (UnitStruct[] memory);

    function createUnit(address sender, bytes32 providerId, uint16 guestCount)
        external
        returns (bool);

    function deleteUnit(address sender, bytes32 unitId) external returns (bool);
}

pragma solidity 0.5.17;

/**
 * @title The PublicLock Interface
 * @author Nick Furfaro (unlock-protocol.com)
 */

contract IPublicLock {
    // See indentationissue description here:
    // https://github.com/duaraghav8/Ethlint/issues/268
    // solium-disable indentation

    /// Functions

    function initialize(
        address _lockCreator,
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string calldata _lockName
    ) external;

    /**
     * @notice Allow the contract to accept tips in ETH sent directly to the contract.
     * @dev This is okay to use even if the lock is priced in ERC-20 tokens
     */
    function() external payable;

    /**
     * @dev Never used directly
     */
    function initialize() external;

    /**
     * @notice The version number of the current implementation on this network.
     * @return The current version number.
     */
    function publicLockVersion() public pure returns (uint256);

    /**
     * @notice Gets the current balance of the account provided.
     * @param _tokenAddress The token type to retrieve the balance of.
     * @param _account The account to get the balance of.
     * @return The number of tokens of the given type for the given address, possibly 0.
     */
    function getBalance(address _tokenAddress, address _account)
        external
        view
        returns (uint256);

    /**
     * @notice Used to disable lock before migrating keys and/or destroying contract.
     * @dev Throws if called by other than a lock manager.
     * @dev Throws if lock contract has already been disabled.
     */
    function disableLock() external;

    /**
     * @dev Called by a lock manager or beneficiary to withdraw all funds from the lock and send them to the `beneficiary`.
     * @dev Throws if called by other than a lock manager or beneficiary
     * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
     * the same as `tokenAddress` in MixinFunds.
     * @param _amount specifies the max amount to withdraw, which may be reduced when
     * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
     *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
     * use cases.
     */
    function withdraw(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice An ERC-20 style approval, allowing the spender to transfer funds directly from this lock.
     */
    function approveBeneficiary(address _spender, uint256 _amount)
        external
        returns (bool);

    /**
     * A function which lets a Lock manager of the lock to change the price for future purchases.
     * @dev Throws if called by other than a Lock manager
     * @dev Throws if lock has been disabled
     * @dev Throws if _tokenAddress is not a valid token
     * @param _keyPrice The new price to set for keys
     * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
     * or 0 to use ETH
     */
    function updateKeyPricing(uint256 _keyPrice, address _tokenAddress)
        external;

    /**
     * A function which lets a Lock manager update the beneficiary account,
     * which receives funds on withdrawal.
     * @dev Throws if called by other than a Lock manager or beneficiary
     * @dev Throws if _beneficiary is address(0)
     * @param _beneficiary The new address to set as the beneficiary
     */
    function updateBeneficiary(address _beneficiary) external;

    /**
     * Checks if the user has a non-expired key.
     * @param _user The address of the key owner
     */
    function getHasValidKey(address _user) external view returns (bool);

    /**
     * @notice Find the tokenId for a given user
     * @return The tokenId of the NFT, else returns 0
     * @param _account The address of the key owner
     */
    function getTokenIdFor(address _account) external view returns (uint256);

    /**
     * A function which returns a subset of the keys for this Lock as an array
     * @param _page the page of key owners requested when faceted by page size
     * @param _pageSize the number of Key Owners requested per page
     * @dev Throws if there are no key owners yet
     */
    function getOwnersByPage(uint256 _page, uint256 _pageSize)
        external
        view
        returns (address[] memory);

    /**
     * Checks if the given address owns the given tokenId.
     * @param _tokenId The tokenId of the key to check
     * @param _keyOwner The potential key owners address
     */
    function isKeyOwner(uint256 _tokenId, address _keyOwner)
        external
        view
        returns (bool);

    /**
     * @dev Returns the key's ExpirationTimestamp field for a given owner.
     * @param _keyOwner address of the user for whom we search the key
     * @dev Returns 0 if the owner has never owned a key for this lock
     */
    function keyExpirationTimestampFor(address _keyOwner)
        external
        view
        returns (uint256 timestamp);

    /**
     * Public function which returns the total number of unique owners (both expired
     * and valid).  This may be larger than totalSupply.
     */
    function numberOfOwners() external view returns (uint256);

    /**
     * Allows a Lock manager to assign a descriptive name for this Lock.
     * @param _lockName The new name for the lock
     * @dev Throws if called by other than a Lock manager
     */
    function updateLockName(string calldata _lockName) external;

    /**
     * Allows a Lock manager to assign a Symbol for this Lock.
     * @param _lockSymbol The new Symbol for the lock
     * @dev Throws if called by other than a Lock manager
     */
    function updateLockSymbol(string calldata _lockSymbol) external;

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * Allows a Lock manager to update the baseTokenURI for this Lock.
     * @dev Throws if called by other than a Lock manager
     * @param _baseTokenURI String representing the base of the URI for this lock.
     */
    function setBaseTokenURI(string calldata _baseTokenURI) external;

    /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     * @param _tokenId The tokenID we're inquiring about
     * @return String representing the URI for the requested token
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /**
     * @notice Allows a Lock manager to add or remove an event hook
     */
    function setEventHooks(address _onKeyPurchaseHook, address _onKeyCancelHook)
        external;

    /**
     * Allows a Lock manager to give a collection of users a key with no charge.
     * Each key may be assigned a different expiration date.
     * @dev Throws if called by other than a Lock manager
     * @param _recipients An array of receiving addresses
     * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
     */
    function grantKeys(
        address[] calldata _recipients,
        uint256[] calldata _expirationTimestamps,
        address[] calldata _keyManagers
    ) external;

    /**
     * @dev Purchase function
     * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
     * (_value is ignored when using ETH)
     * @param _recipient address of the recipient of the purchased key
     * @param _referrer address of the user making the referral
     * @param _data arbitrary data populated by the front-end which initiated the sale
     * @dev Throws if lock is disabled. Throws if lock is sold-out. Throws if _recipient == address(0).
     * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if a Lock manager increases the
     * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
     * than keyPrice is approved for spending).
     */
    function purchase(
        uint256 _value,
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external payable;

    /**
     * @notice returns the minimum price paid for a purchase with these params.
     * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
     */
    function purchasePriceFor(
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external view returns (uint256);

    /**
     * Allow a Lock manager to change the transfer fee.
     * @dev Throws if called by other than a Lock manager
     * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
     * Ex: 200 bps = 2%
     */
    function updateTransferFee(uint256 _transferFeeBasisPoints) external;

    /**
     * Determines how much of a fee a key owner would need to pay in order to
     * transfer the key to another account.  This is pro-rated so the fee goes down
     * overtime.
     * @dev Throws if _keyOwner does not have a valid key
     * @param _keyOwner The owner of the key check the transfer fee for.
     * @param _time The amount of time to calculate the fee for.
     * @return The transfer fee in seconds.
     */
    function getTransferFee(address _keyOwner, uint256 _time)
        external
        view
        returns (uint256);

    /**
     * @dev Invoked by a Lock manager to expire the user's key and perform a refund and cancellation of the key
     * @param _keyOwner The key owner to whom we wish to send a refund to
     * @param amount The amount to refund the key-owner
     * @dev Throws if called by other than a Lock manager
     * @dev Throws if _keyOwner does not have a valid key
     */
    function expireAndRefundFor(address _keyOwner, uint256 amount) external;

    /**
     * @dev allows the key manager to expire a given tokenId
     * and send a refund to the keyOwner based on the amount of time remaining.
     * @param _tokenId The id of the key to cancel.
     */
    function cancelAndRefund(uint256 _tokenId) external;

    /**
     * @dev Cancels a key managed by a different user and sends the funds to the keyOwner.
     * @param _keyManager the key managed by this user will be canceled
     * @param _v _r _s getCancelAndRefundApprovalHash signed by the _keyManager
     * @param _tokenId The key to cancel
     */
    function cancelAndRefundFor(
        address _keyManager,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _tokenId
    ) external;

    /**
     * @notice Sets the minimum nonce for a valid off-chain approval message from the
     * senders account.
     * @dev This can be used to invalidate a previously signed message.
     */
    function invalidateOffchainApproval(uint256 _nextAvailableNonce) external;

    /**
     * Allow a Lock manager to change the refund penalty.
     * @dev Throws if called by other than a Lock manager
     * @param _freeTrialLength The new duration of free trials for this lock
     * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
     */
    function updateRefundPenalty(
        uint256 _freeTrialLength,
        uint256 _refundPenaltyBasisPoints
    ) external;

    /**
     * @dev Determines how much of a refund a key owner would receive if they issued
     * @param _keyOwner The key owner to get the refund value for.
     * a cancelAndRefund block.timestamp.
     * Note that due to the time required to mine a tx, the actual refund amount will be lower
     * than what the user reads from this call.
     */
    function getCancelAndRefundValueFor(address _keyOwner)
        external
        view
        returns (uint256 refund);

    function keyManagerToNonce(address) external view returns (uint256);

    /**
     * @notice returns the hash to sign in order to allow another user to cancel on your behalf.
     * @dev this can be computed in JS instead of read from the contract.
     * @param _keyManager The key manager's address (also the message signer)
     * @param _txSender The address cancelling cancel on behalf of the keyOwner
     * @return approvalHash The hash to sign
     */
    function getCancelAndRefundApprovalHash(
        address _keyManager,
        address _txSender
    ) external view returns (bytes32 approvalHash);

    function addKeyGranter(address account) external;

    function addLockManager(address account) external;

    function isKeyGranter(address account) external view returns (bool);

    function isLockManager(address account) external view returns (bool);

    function onKeyPurchaseHook() external view returns (address);

    function onKeyCancelHook() external view returns (address);

    function revokeKeyGranter(address _granter) external;

    function renounceLockManager() external;

    ///===================================================================
    /// Auto-generated getter functions from public state variables

    function beneficiary() external view returns (address);

    function expirationDuration() external view returns (uint256);

    function freeTrialLength() external view returns (uint256);

    function isAlive() external view returns (bool);

    function keyPrice() external view returns (uint256);

    function maxNumberOfKeys() external view returns (uint256);

    function owners(uint256) external view returns (address);

    function refundPenaltyBasisPoints() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function transferFeeBasisPoints() external view returns (uint256);

    function unlockProtocol() external view returns (address);

    function keyManagerOf(uint256) external view returns (address);

    ///===================================================================

    /**
     * @notice Allows the key owner to safely share their key (parent key) by
     * transferring a portion of the remaining time to a new key (child key).
     * @dev Throws if key is not valid.
     * @dev Throws if `_to` is the zero address
     * @param _to The recipient of the shared key
     * @param _tokenId the key to share
     * @param _timeShared The amount of time shared
     * checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
     * @dev Emit Transfer event
     */
    function shareKey(
        address _to,
        uint256 _tokenId,
        uint256 _timeShared
    ) external;

    /**
     * @notice Update transfer and cancel rights for a given key
     * @param _tokenId The id of the key to assign rights for
     * @param _keyManager The address to assign the rights to for the given key
     */
    function setKeyManagerOf(uint256 _tokenId, address _keyManager) external;

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    ///===================================================================

    /// From ERC165.sol
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    ///===================================================================

    /// From ERC-721
    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address _owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address _owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address _owner, address operator)
        public
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;

    function totalSupply() public view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 index)
        public
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);

    /**
     * @notice An ERC-20 style transfer.
     * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
     * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
     * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
     */
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}

pragma solidity 0.5.17;


/**
 * @title The Unlock Interface
 * @author Nick Furfaro (unlock-protocol.com)
**/

interface IUnlock
{
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
  * @dev Create lock
  * This deploys a lock for a creator. It also keeps track of the deployed lock.
  * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
  * @param _salt an identifier for the Lock, which is unique for the user.
  * This may be implemented as a sequence ID or with RNG. It's used with `create2`
  * to know the lock's address before the transaction is mined.
  */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 _salt
  ) external;

    /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  )
    external
    view
    returns(uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI()
    external
    view
    returns(string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol()
    external
    view
    returns(string memory);

  // Function to read the chainId field.
  function chainId()
    external
    view
    returns(uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  )
    external;

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(
    address payable _publicLockAddress
  ) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct() external view returns(uint);

  function totalDiscountGranted() external view returns(uint);

  function locks(address) external view returns(bool deployed, uint totalSales, uint yieldedDiscountTokens);

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress() external view returns(address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(address) external view returns(address);

  // The WETH token address, used for value calculations
  function weth() external view returns(address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns(address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase() external view returns(uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns(uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(
    address _tokenAddress,
    address _oracleAddress
  ) external;

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() external view returns(bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns(address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

