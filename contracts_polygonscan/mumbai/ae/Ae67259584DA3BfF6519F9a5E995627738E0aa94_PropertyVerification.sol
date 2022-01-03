//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

interface IBookingNFT {
    function createBooking(
        address propertyOwnerAddress,
        address renterAddress,
        uint256 listingId,
        uint256 checkInTime,
        uint256 checkOutTime,
        uint256 propertyId
    ) external payable returns (uint256);

    function createVerifiedBooking(uint256 propertyId, uint256 listingId)
        external;
}

interface IEscrow {
    function createEscrow(
        uint256 releaseTime,
        uint256 amount,
        uint256 listingId,
        uint256 propertyId
    ) external payable returns (uint256);

    function collectEscrow(uint256 escrowId) external;
}

contract PropertyVerification is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _propertyId;

    IBookingNFT public BnftContract;
    IEscrow public EscrowContract;
    address public marketplaceAddress;

    mapping(address => bool) whitelist;

    mapping(uint256 => propertyData) public properties;

    // listing id => property Id
    mapping(uint256 => uint256) listingIds;

    struct propertyData {
        address propertyOwner;
        bool verified;
        // can the property be shown to the public
        bool isPublic;
        // keep track of the deposit amount in case the deposit amount is changed in the future
        uint256 depositAmount;
    }

    event NewPropertyProfileCreated(
        address propertyOwnerAddress,
        uint256 newPropertyId,
        bool verified,
        bool isPublic
    );
    event NewPublicProperty(
        address propertyOwnerAddress,
        uint256 propertyId,
        bool isPublic
    );
    event newBookingCreated(
        address propertyOwner,
        address initialRenter,
        uint256 newBnftId,
        uint256 listingId,
        uint256 createdTimestamp,
        uint256 escrowId,
        uint256 escrowReleaseTime,
        uint256 escrowAmount
    );

    event PropertyVerified(
        address propertyOwner,
        uint256 propertyId,
        bool propertyVerified
    );

    uint256 public disputeTimeLimit = 86400; // 1 day
    // amount of funds to deposit if a property is unverified
    uint256 public verifyDepositAmount = 50 ether;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'This is not a whitelisted address');
        _;
    }

    modifier propertyOwnerOnly(uint256 propertyId) {
        require(
            msg.sender == properties[propertyId].propertyOwner,
            'Sender is not the owner'
        );
        _;
    }

    constructor(address _bnftAddress, address _escrowAddress) {
        whitelist[_bnftAddress] = true;
        whitelist[_escrowAddress] = true;
        whitelist[owner()] = true;
        BnftContract = IBookingNFT(_bnftAddress);
        EscrowContract = IEscrow(_escrowAddress);
    }

    /**
     * @dev if a previously verified property needs to be
     * unverified for a certain amount of time (or 'paused')
     * @param propertyId property id to be paused
     */
    function pauseVerify(uint256 propertyId) external onlyOwner {
        require(
            properties[propertyId].verified,
            'This property was never verified'
        );
        properties[propertyId].verified = false;
    }

    /**
     * @dev check if a property is verified
     * @param propertyOwner address of the property owner
     * @param propertyId property id to check verification status of
     */
    function isPropertyVerified(address propertyOwner, uint256 propertyId)
        external
        view
        returns (bool)
    {
        return
            properties[propertyId].propertyOwner == propertyOwner &&
            properties[propertyId].verified;
    }

    /**
     * @dev whitelist an address
     * @param newAddress new address to whitelist
     */
    function whitelistAdress(address newAddress) external onlyOwner {
        whitelist[newAddress] = true;
    }

    /**
     * @dev create new property profile
     * @return The new property Id
     */
    function createPropertyProfile() external returns (uint256) {
        _propertyId.increment();
        uint256 newPropertyId = _propertyId.current();

        propertyData memory newProperty;
        newProperty.propertyOwner = msg.sender;
        newProperty.verified = false;
        newProperty.isPublic = false;
        newProperty.depositAmount = 0;

        properties[newPropertyId] = newProperty;

        emit NewPropertyProfileCreated(
            newProperty.propertyOwner,
            newPropertyId,
            newProperty.verified,
            newProperty.isPublic
        );

        return newPropertyId;
    }

    function makePropertyPublic(uint256 propertyId)
        external
        payable
        propertyOwnerOnly(propertyId)
    {
        require(!properties[propertyId].isPublic, 'property is already public');
        // The funds deposited must match the selected deposit amount
        require(
            msg.value == verifyDepositAmount,
            'The amount transfered does not match the deposit value'
        );

        properties[propertyId].isPublic = true;
        properties[propertyId].depositAmount = msg.value;

        emit NewPublicProperty(
            properties[propertyId].propertyOwner,
            propertyId,
            properties[propertyId].isPublic
        );
    }

    function isPropertyOwnedBy(uint256 propertyId, address propertyOwner)
        external
        view
        returns (bool)
    {
        return properties[propertyId].propertyOwner == propertyOwner;
    }

    /**
     * @dev is the property public
     */
    function isPropertyPublic(uint256 propertyId) external view returns (bool) {
        return properties[propertyId].isPublic;
    }

    /**
     * @dev change a property's verified status to true
     * @param propertyOwnerAddress property owners address
     * @param propertyId id of the property
     *
     * NOTE this is only callable from the escrow contract or owner
     */
    function verify(address propertyOwnerAddress, uint256 propertyId)
        external
        returns (uint256)
    {
        // only escrow contract should be verifying properties (after collect)
        require(
            msg.sender == address(EscrowContract) || msg.sender == owner(),
            'not the escrow contract'
        );
        require(
            properties[propertyId].propertyOwner == propertyOwnerAddress,
            'this property owner does not own this property'
        );

        // only need to refund deposit if the property hasn't been verified yet
        if (
            !properties[propertyId].verified &&
            properties[propertyId].depositAmount > 0
        ) {
            // refund the verification deposit to property owner
            (bool success, ) = payable(properties[propertyId].propertyOwner)
                .call{value: properties[propertyId].depositAmount}('');
            require(success, 'Failed to send user the verification deposit');

            // set deposit amount to 0 once the deposit amount has been collected
            properties[propertyId].depositAmount = 0;
        }

        // set verify variable to true
        properties[propertyId].verified = true;

        emit PropertyVerified(
            properties[propertyId].propertyOwner,
            propertyId,
            properties[propertyId].verified
        );

        return propertyId;
    }

    function setDisputeTimeLimit(uint256 newDisputetimeLimit)
        external
        onlyOwner
    {
        disputeTimeLimit = newDisputetimeLimit;
    }

    function setVerifyDepositAmount(uint256 newVerifyDepositAmount)
        external
        onlyOwner
    {
        verifyDepositAmount = newVerifyDepositAmount;
    }

    function unlistProperty(uint256 propertyId) external onlyWhitelisted {
        properties[propertyId].verified = false;
        properties[propertyId].isPublic = false;

        // TODO send verification deposit to marketplace here. don't forget to remove deposit 
    }

    function setEscrowAddress(address newEscrow) external onlyOwner {
        EscrowContract = IEscrow(newEscrow);
    }

    function setMarketplaceAddress(address newMarketplaceAddress)
        external
        onlyOwner
    {
        require(
            newMarketplaceAddress != address(0),
            'marketplace address cannot be 0 address'
        );
        marketplaceAddress = newMarketplaceAddress;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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