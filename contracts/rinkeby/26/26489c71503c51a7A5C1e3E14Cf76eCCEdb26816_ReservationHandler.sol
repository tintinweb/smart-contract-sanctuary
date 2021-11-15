// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

contract AccessRestriction {
    address public owner;
    address public remote;
    bool internal first = true;

    modifier onlyOwner(){
        require(owner == msg.sender, "NOT_OWNER_CALL");
        _;
    }

    modifier onlyRemote() {
        require(remote == msg.sender, "NOT_REMOTE_CALL");
        _;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setRemote(address adr) public {
        require(owner == msg.sender || first, "NOT_OWNER");
        remote = adr;
        first = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IProvider.sol";
import "./interfaces/IUnit.sol";
import "./interfaces/IReservation.sol";
import "./interfaces/IReservationHandler.sol";

import "./AccessRestriction.sol";

contract ReservationHandler is IReservationHandler, AccessRestriction {
    IProvider internal provider;
    event LogNewProvider(address sender, IProvider.ProviderStruct provider);
    event LogProviderDeleted(address sender, bytes32 providerKey);

    IUnit internal unit;
    event LogNewUnit(address sender, IUnit.UnitStruct unit);
    event LogUnitDeleted(address sender, bytes32 unitKey);

    IReservation internal reservation;
    event LogNewReservation(
        address sender,
        IReservation.ReservationStruct reservation
    );
    event LogReservationDeleted(address sender, bytes32 reservationKey);
    event LogRefundReservation(
        address sender,
        IReservation.ReservationStruct reservation
    );

    constructor(
        address adrProvider,
        address adrUnit,
        address adrReservation
    ) public {
        provider = IProvider(adrProvider);
        unit = IUnit(adrUnit);
        reservation = IReservation(adrReservation);

        provider.setRemote(address(this));
        unit.setRemote(address(this));
        reservation.setRemote(address(this));

        unit.setChild(address(reservation));
        provider.setChild(address(unit));
    }

    //provider methodes
    function setLockAddress(address payable adr, bytes32 key) external{
        provider.setLockAddress(adr, key);
    }

    function isProviderOwner(bytes32 providerKey) public view returns (bool) {
        return provider.isProviderOwner(msg.sender, providerKey);
    }

    function getAllProviders()
        external
        view
        returns (IProvider.ProviderStruct[] memory)
    {
        return provider.getAllProviders();
    }

    function renameProvider(bytes32 providerKey, string calldata newName)
        external
    {
        provider.renameProvider(msg.sender, providerKey, newName);
    }

    function createProvider(string calldata name, uint8 timePerReservation) external {
        emit LogNewProvider(
            msg.sender,
            provider.createProvider(msg.sender, name, timePerReservation)
        );
    }

    function deleteProvider(bytes32 providerKey) external {
        provider.deleteProvider(msg.sender, providerKey);
        emit LogProviderDeleted(msg.sender, providerKey);
    }

    function setBuissnesHours(
        bytes32 key,
        uint8 weekDayType,
        uint8 startHour,
        uint8 endHour
    ) external {
        provider.setBuissnesHours(
            msg.sender,
            key,
            weekDayType,
            startHour,
            endHour
        );
    }

    function getBuissnesHours(bytes32 key, uint8 weekDayType)
        external
        view
        returns (uint8 start, uint8 end)
    {
        return provider.getBuissnesHours(key, weekDayType);
    }

    //unit methodes
    function setProviderAddress(address adr) external {
        require(address(unit) != address(0), "SET_UNIT_FIRST");
        provider = IProvider(adr);
        unit.setProviderAddress(adr);
    }

    function isUnitOwner(bytes32 unitKey) public view returns (bool) {
        return unit.isUnitOwner(msg.sender, unitKey);
    }

    function getAllUnits() external view returns (IUnit.UnitStruct[] memory) {
        return unit.getAllUnits();
    }

    function createUnit(bytes32 providerKey, uint16 guestCount) external {
        emit LogNewUnit(
            msg.sender,
            unit.createUnit(msg.sender, providerKey, guestCount)
        );
    }

    function deleteUnit(bytes32 unitKey) external {
        emit LogUnitDeleted(msg.sender, unit.deleteUnit(msg.sender, unitKey));
    }

    //reservation methodes
    function setUnitAddress(address adr) external {
        require(address(reservation) != address(0), "SET_RESERVATION_FIRST");
        unit = IUnit(adr);
        reservation.setUnitAddress(adr);
    }

    function setReservationAddress(address adr) external onlyOwner {
        reservation = IReservation(adr);
    }

    function getAllReservations()
        external
        view
        returns (IReservation.ReservationStruct[] memory)
    {
        return reservation.getAllReservations();
    }

    function createReservation(bytes32 unitKey, uint256 startTime) external payable {
        emit LogNewReservation(
            msg.sender,
            reservation.createReservation.value(msg.value)(msg.sender, unitKey, startTime)
        );
    }

    function deleteReservation(bytes32 reservationKey) external {
        emit LogReservationDeleted(
            msg.sender,
            reservation.deleteReservation(reservationKey)
        );
    }

    function refundReservation(bytes32 reservationKey, uint256 checkInKey)
        external
    {
        emit LogRefundReservation(
            msg.sender,
            reservation.refundReservation(
                msg.sender,
                reservationKey,
                checkInKey
            )
        );
    }

    function getCheckInKey(bytes32 reservationKey)
        external
        view
        returns (uint256)
    {
        return reservation.getCheckInKey(msg.sender, reservationKey);
    }

    //lockFactory
    function getKeyPrice(bytes32 providerKey) external view returns (uint256) {
        return provider.getKeyPrice(providerKey);
    }

    function updateKeyPrice(bytes32 providerKey, uint256 keyPrice) external {
        provider.updateKeyPrice(providerKey, keyPrice);
    }

    function getLock(bytes32 providerKey) external view returns (IPublicLock) {
        return provider.getLock(providerKey);
    }
}

// SPDX-License-Keyentifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./unlock/IPublicLock.sol";

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerKey;
        bytes32[] unitKeys;
        string name;
        uint8 timePerReservation;
    }

    function setChild(address childAdr) external;
    function setRemote(address adr) external;

    function setLockAddress(address payable adr, bytes32 key) external;

    function isProviderOwner(address sender, bytes32 providerKey)
        external
        view
        returns (bool);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function renameProvider(
        address sender,
        bytes32 providerKey,
        string calldata newName
    ) external;

    function createProvider(
        address sender,
        string calldata name,
        uint8 timePerReservation
    ) external returns (ProviderStruct memory);

    function deleteProvider(address sender, bytes32 providerKey)
        external
        returns (bytes32);

    function getKeyPrice(bytes32 key) external view returns (uint256);

    function updateKeyPrice(bytes32 key, uint256 keyPrice) external;

    function getLock(bytes32 key) external view returns (IPublicLock);

    function setBuissnesHours(
        address sender,
        bytes32 key,
        uint8 weekDayType,
        uint8 startHour,
        uint8 endHour
    ) external;

    function getBuissnesHours(bytes32 key, uint8 weekDayType)
        external
        view
        returns (uint8 start, uint8 end);
}

// SPDX-License-Keyentifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IReservation {
    struct ReservationStruct {
        bytes32 reservationKey;
        bytes32 unitKey;
        address owner;
        uint startTime;
        uint endTime;
    }

    function setUnitAddress(address adr) external;
    function setRemote(address adr) external;

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory);

    function createReservation(address sender, bytes32 unitKey, uint256 startTime)
        external
        payable
        returns (ReservationStruct memory);

    function deleteReservation(bytes32 reservationKey)
        external
        returns (bytes32);

    function refundReservation(
        address sender,
        bytes32 reservationKey,
        uint256 checkInKey
    ) external returns (ReservationStruct memory);

    function getCheckInKey(address sender, bytes32 reservationKey)
        external
        view
        returns (uint256);
}

// SPDX-License-Keyentifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IProvider.sol";
import "./IUnit.sol";
import "./IReservation.sol";

interface IReservationHandler {
    ///provider
    function setLockAddress(address payable adr, bytes32 key) external;

    function isProviderOwner(bytes32 providerKey) external view returns (bool);

    function getAllProviders()
        external
        view
        returns (IProvider.ProviderStruct[] memory);

    function renameProvider(bytes32 providerKey, string calldata newName)
        external;

    function createProvider(string calldata name, uint8 timePerReservation) external;

    function deleteProvider(bytes32 providerKey) external;

    function setBuissnesHours(
        bytes32 key,
        uint8 weekDayType,
        uint8 startHour,
        uint8 endHour
    ) external;

    function getBuissnesHours(bytes32 key, uint8 weekDayType)
        external
        view
        returns (uint8 start, uint8 end);

    ///reservation
    function setUnitAddress(address adr) external;

    function getAllReservations()
        external
        view
        returns (IReservation.ReservationStruct[] memory);

    function createReservation(bytes32 unitKey, uint256 startTime) external payable;

    function deleteReservation(bytes32 reservationKey) external;

    function refundReservation(bytes32 reservationKey, uint256 checkInKey)
        external;

    function getCheckInKey(bytes32 reservationKey)
        external
        view
        returns (uint256);

    ///unit
    function setProviderAddress(address adr) external;

    function isUnitOwner(bytes32 unitKey) external view returns (bool);

    function getAllUnits() external view returns (IUnit.UnitStruct[] memory);

    function createUnit(bytes32 providerKey, uint16 guestCount) external;

    function deleteUnit(bytes32 unitKey) external;

    //lockfactory
    function getKeyPrice(bytes32 providerKey) external view returns (uint256);

    function updateKeyPrice(bytes32 providerKey, uint256 keyPrice) external;

    function getLock(bytes32 providerKey) external view returns (IPublicLock);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IUnit {
    struct UnitStruct {
        bytes32 unitKey;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        uint16 guestCount;
    }

    function setChild(address childAdr) external;
    function setRemote(address adr) external;

    function setProviderAddress(address adr) external;

    function isUnitOwner(address sender, bytes32 unitKey)
        external
        view
        returns (bool);

    function getAllUnits() external view returns (UnitStruct[] memory);

    function createUnit(
        address sender,
        bytes32 providerKey,
        uint16 guestCount
    ) external returns (UnitStruct memory);

    function deleteUnit(address sender, bytes32 unitKey)
        external
        returns (bytes32);
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

