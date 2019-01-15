pragma solidity ^0.5.0;

/// @title Provides helper functions to determine the validity of passed signatures.
/// @author Noah Zinsmeister
/// @dev Supports both prefixed and un-prefixed signatures.
contract SignatureVerifier {
    /// @notice Determines whether the passed signature of `messageHash` was made by the private key of `_address`.
    /// @param _address The address that may or may not have signed the passed messageHash.
    /// @param messageHash The messageHash that may or may not have been signed.
    /// @param v The v component of the signature.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @return true if the signature can be verified, false otherwise.
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return _isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s);
    }

    /// @dev Checks unprefixed signatures.
    function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal pure returns (bool)
    {
        return ecrecover(messageHash, v, r, s) == _address;
    }

    /// @dev Checks prefixed signatures.
    function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal pure returns (bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return _isSigned(_address, keccak256(abi.encodePacked(prefix, messageHash)), v, r, s);
    }
}

/// @title An implementation of the set data structure for addresses.
/// @author Noah Zinsmeister
/// @dev O(1) insertion, removal, contains, and length functions.
library AddressSet {
    struct Set {
        address[] members;
        mapping(address => uint) memberIndices;
    }

    /// @dev Inserts an element into a set. If the element already exists in the set, the function is a no-op.
    /// @param self The set to insert into.
    /// @param other The element to insert.
    function insert(Set storage self, address other) internal {
        if (!contains(self, other)) {
            self.memberIndices[other] = self.members.push(other);
        }
    }

    /// @dev Removes an element from a set. If the element does not exist in the set, the function is a no-op.
    /// @param self The set to remove from.
    /// @param other The element to remove.
    function remove(Set storage self, address other) internal {
        if (contains(self, other)) {
            // replace other with the last element
            self.members[self.memberIndices[other] - 1] = self.members[length(self) - 1];
            // reflect this change in the indices
            self.memberIndices[self.members[self.memberIndices[other] - 1]] = self.memberIndices[other];
            delete self.memberIndices[other];
            // remove the last element
            self.members.pop();
        }
    }

    /// @dev Checks set membership.
    /// @param self The set to check membership in.
    /// @param other The element to check membership of.
    /// @return true if the element is in the set, false otherwise.
    function contains(Set storage self, address other) internal view returns (bool) {
        return ( // solium-disable-line operator-whitespace
            self.memberIndices[other] > 0 && 
            self.members.length >= self.memberIndices[other] && 
            self.members[self.memberIndices[other] - 1] == other
        );
    }

    /// @dev Returns the number of elements in a set.
    /// @param self The set to check the length of.
    /// @return The number of elements in the set.
    function length(Set storage self) internal view returns (uint) {
        return self.members.length;
    }
}

/// @title The ERC-1484 Identity Registry.
/// @author Noah Zinsmeister
/// @author Andy Chorlian
contract IdentityRegistry is SignatureVerifier {
    using AddressSet for AddressSet.Set;


    // Identity Data Structure and Parameters //////////////////////////////////////////////////////////////////////////

    struct Identity {
        address recoveryAddress;
        AddressSet.Set associatedAddresses;
        AddressSet.Set providers;
        AddressSet.Set resolvers;
    }

    mapping (uint => Identity) private identityDirectory;
    mapping (address => uint) private associatedAddressDirectory;

    uint public nextEIN = 1;
    uint public maxAssociatedAddresses = 50;


    // Signature Timeout ///////////////////////////////////////////////////////////////////////////////////////////////

    uint public signatureTimeout = 1 days;

    /// @dev Enforces that the passed timestamp is within signatureTimeout seconds of now.
    /// @param timestamp The timestamp to check the validity of.
    modifier ensureSignatureTimeValid(uint timestamp) {
        require(
            // solium-disable-next-line security/no-block-members
            block.timestamp >= timestamp && block.timestamp < timestamp + signatureTimeout, "Timestamp is not valid."
        );
        _;
    }


    // Recovery Address Change Logging /////////////////////////////////////////////////////////////////////////////////

    struct RecoveryAddressChange {
        uint timestamp;
        address oldRecoveryAddress;
    }

    mapping (uint => RecoveryAddressChange) private recoveryAddressChangeLogs;


    // Recovery Logging ////////////////////////////////////////////////////////////////////////////////////////////////

    struct Recovery {
        uint timestamp;
        bytes32 hashedOldAssociatedAddresses;
    }

    mapping (uint => Recovery) private recoveryLogs;


    // Recovery Timeout ////////////////////////////////////////////////////////////////////////////////////////////////

    uint public recoveryTimeout = 2 weeks;

    /// @dev Checks if the passed EIN has changed their recovery address within recoveryTimeout seconds of now.
    function canChangeRecoveryAddress(uint ein) private view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > recoveryAddressChangeLogs[ein].timestamp + recoveryTimeout;
    }

    /// @dev Checks if the passed EIN has recovered within recoveryTimeout seconds of now.
    function canRecover(uint ein) private view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > recoveryLogs[ein].timestamp + recoveryTimeout;
    }


    // Identity View Functions /////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Checks if the passed EIN exists.
    /// @dev Does not throw.
    /// @param ein The EIN to check the existence of.
    /// @return true if the passed EIN exists, false otherwise.
    function identityExists(uint ein) public view returns (bool) {
        return ein < nextEIN && ein > 0;
    }

    /// @dev Ensures that the passed EIN exists.
    /// @param ein The EIN to check the existence of.
    modifier _identityExists(uint ein) {
        require(identityExists(ein), "The identity does not exist.");
        _;
    }

    /// @notice Checks if the passed address is associated with an Identity.
    /// @dev Does not throw.
    /// @param _address The address to check.
    /// @return true if the passed address is associated with an Identity, false otherwise.
    function hasIdentity(address _address) public view returns (bool) {
        return identityExists(associatedAddressDirectory[_address]);
    }

    /// @dev Ensures that the passed address is or is not associated with an Identity.
    /// @param _address The address to check.
    /// @param check If true, ensures that the address has an Identity, if false, vice versa.
    /// @return true if the associated status is equal to check, false otherwise.
    modifier _hasIdentity(address _address, bool check) {
        require(
            hasIdentity(_address) == check,
            check ?
                "The passed address does not have an identity but should." :
                "The passed address has an identity but should not."
        );
        _;
    }

    /// @notice Gets the EIN associated with the passed address.
    /// @dev Throws if the address is not associated with an Identity.
    /// @param _address The address to check.
    /// @return The associated EIN.
    function getEIN(address _address) public view _hasIdentity(_address, true) returns (uint ein) {
        return associatedAddressDirectory[_address];
    }

    /// @notice Checks whether the passed EIN is associated with the passed address.
    /// @dev Does not throw.
    /// @param ein The EIN to check.
    /// @param _address The address to check.
    /// @return true if the passed address is associated with the passed EIN, false otherwise.
    function isAssociatedAddressFor(uint ein, address _address) public view returns (bool) {
        return identityDirectory[ein].associatedAddresses.contains(_address);
    }

    /// @notice Checks whether the passed provider is set for the passed EIN.
    /// @dev Does not throw.
    /// @param ein The EIN to check.
    /// @param provider The provider to check.
    /// @return true if the provider is set for the passed EIN, false otherwise.
    function isProviderFor(uint ein, address provider) public view returns (bool) {
        return identityDirectory[ein].providers.contains(provider);
    }

    /// @dev Ensures that the msg.sender is a provider for the passed EIN.
    /// @param ein The EIN to check.
    modifier _isProviderFor(uint ein) {
        require(isProviderFor(ein, msg.sender), "The identity has not set the passed provider.");
        _;
    }

    /// @notice Checks whether the passed resolver is set for the passed EIN.
    /// @dev Does not throw.
    /// @param ein The EIN to check.
    /// @param resolver The resolver to check.
    /// @return true if the resolver is set for the passed EIN, false otherwise.
    function isResolverFor(uint ein, address resolver) public view returns (bool) {
        return identityDirectory[ein].resolvers.contains(resolver);
    }

    /// @notice Gets all identity-related information for the passed EIN.
    /// @dev Throws if the passed EIN does not exist.
    /// @param ein The EIN to get information for.
    /// @return All the information for the Identity denominated by the passed EIN.
    function getIdentity(uint ein) public view _identityExists(ein)
        returns (
            address recoveryAddress,
            address[] memory associatedAddresses, address[] memory providers, address[] memory resolvers
        )
    {
        Identity storage _identity = identityDirectory[ein];

        return (
            _identity.recoveryAddress,
            _identity.associatedAddresses.members,
            _identity.providers.members,
            _identity.resolvers.members
        );
    }


    // Identity Management Functions ///////////////////////////////////////////////////////////////////////////////////

    /// @notice Create an new Identity for the transaction sender.
    /// @dev Sets the msg.sender as the only associatedAddress.
    /// @param recoveryAddress A recovery address to set for the new Identity.
    /// @param providers A list of providers to set for the new Identity.
    /// @param resolvers A list of resolvers to set for the new Identity.
    /// @return The EIN of the new Identity.
    function createIdentity(address recoveryAddress, address[] memory providers, address[] memory resolvers)
        public returns (uint ein)
    {
        return createIdentity(recoveryAddress, msg.sender, providers, resolvers, false);
    }

    /// @notice Allows creation of a new Identity for the passed associatedAddress.
    /// @param recoveryAddress A recovery address to set for the new Identity.
    /// @param associatedAddress An associated address to set for the new Identity (must have produced the signature).
    /// @param providers A list of providers to set for the new Identity.
    /// @param resolvers A list of resolvers to set for the new Identity.
    /// @param v The v component of the signature.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @param timestamp The timestamp of the signature.
    /// @return The EIN of the new Identity.
    function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] memory providers, address[] memory resolvers,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp) returns (uint ein)
    {
        require(
            isSigned(
                associatedAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize the creation of an Identity on my behalf.",
                        recoveryAddress, associatedAddress, providers, resolvers, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        return createIdentity(recoveryAddress, associatedAddress, providers, resolvers, true);
    }

    /// @dev Common logic for all identity creation.
    function createIdentity(
        address recoveryAddress,
        address associatedAddress, address[] memory providers, address[] memory resolvers, bool delegated
    )
        private _hasIdentity(associatedAddress, false) returns (uint)
    {
        uint ein = nextEIN++;
        Identity storage _identity = identityDirectory[ein];

        _identity.recoveryAddress = recoveryAddress;
        addAssociatedAddress(ein, associatedAddress);
        addProviders(ein, providers, delegated);
        addResolvers(ein, resolvers, delegated);

        emit IdentityCreated(msg.sender, ein, recoveryAddress, associatedAddress, providers, resolvers, delegated);

        return ein;
    }


    /// @notice Allows an associated address to add another associated address to its Identity.
    /// @param approvingAddress An associated address for an Identity.
    /// @param addressToAdd A new address to set for the Identity of the sender.
    /// @param v The v component of the signature.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @param timestamp The timestamp of the signature.
    function addAssociatedAddress(
        address approvingAddress, address addressToAdd, uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp)
    {
        bool fromApprovingAddress = msg.sender == approvingAddress;
        require(
            fromApprovingAddress || msg.sender == addressToAdd, "One or both of the passed addresses are malformed."
        );

        uint ein = getEIN(approvingAddress);

        require(
            isSigned(
                fromApprovingAddress ? addressToAdd : approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        fromApprovingAddress ?
                            "I authorize being added to this Identity." :
                            "I authorize adding this address to my Identity.",
                        ein, addressToAdd, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        addAssociatedAddress(ein, addressToAdd);

        emit AssociatedAddressAdded(msg.sender, ein, approvingAddress, addressToAdd, false);
    }

    /// @notice Allows addition of an associated address to an Identity.
    /// @dev The first signature must be that of the approvingAddress.
    /// @param approvingAddress An associated address for an Identity.
    /// @param addressToAdd A new address to set for the Identity of approvingAddress.
    /// @param v The v component of the signatures.
    /// @param r The r component of the signatures.
    /// @param s The s component of the signatures.
    /// @param timestamp The timestamp of the signatures.
    function addAssociatedAddressDelegated(
        address approvingAddress, address addressToAdd,
        uint8[2] memory v, bytes32[2] memory r, bytes32[2] memory s, uint[2] memory timestamp
    )
        public ensureSignatureTimeValid(timestamp[0]) ensureSignatureTimeValid(timestamp[1])
    {
        uint ein = getEIN(approvingAddress);

        require(
            isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize adding this address to my Identity.",
                        ein, addressToAdd, timestamp[0]
                    )
                ),
                v[0], r[0], s[0]
            ),
            "Permission denied from approving address."
        );
        require(
            isSigned(
                addressToAdd,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize being added to this Identity.",
                        ein, addressToAdd, timestamp[1]
                    )
                ),
                v[1], r[1], s[1]
            ),
            "Permission denied from address to add."
        );

        addAssociatedAddress(ein, addressToAdd);

        emit AssociatedAddressAdded(msg.sender, ein, approvingAddress, addressToAdd, true);
    }

    /// @dev Common logic for all address addition.
    function addAssociatedAddress(uint ein, address addressToAdd) private _hasIdentity(addressToAdd, false) {
        require(
            identityDirectory[ein].associatedAddresses.length() < maxAssociatedAddresses, "Too many addresses."
        );

        identityDirectory[ein].associatedAddresses.insert(addressToAdd);
        associatedAddressDirectory[addressToAdd] = ein;
    }

    /// @notice Allows an associated address to remove itself from its Identity.
    function removeAssociatedAddress() public {
        uint ein = getEIN(msg.sender);

        removeAssociatedAddress(ein, msg.sender);

        emit AssociatedAddressRemoved(msg.sender, ein, msg.sender, false);
    }

    /// @notice Allows removal of an associated address from an Identity.
    /// @param addressToRemove An associated address to remove from its Identity.
    /// @param v The v component of the signature.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @param timestamp The timestamp of the signature.
    function removeAssociatedAddressDelegated(address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public ensureSignatureTimeValid(timestamp)
    {
        uint ein = getEIN(addressToRemove);

        require(
            isSigned(
                addressToRemove,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize removing this address from my Identity.",
                        ein, addressToRemove, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        removeAssociatedAddress(ein, addressToRemove);

        emit AssociatedAddressRemoved(msg.sender, ein, addressToRemove, true);
    }

    /// @dev Common logic for all address removal.
    function removeAssociatedAddress(uint ein, address addressToRemove) private {
        identityDirectory[ein].associatedAddresses.remove(addressToRemove);
        delete associatedAddressDirectory[addressToRemove];
    }


    /// @notice Allows an associated address to add providers to its Identity.
    /// @param providers A list of providers.
    function addProviders(address[] memory providers) public {
        addProviders(getEIN(msg.sender), providers, false);
    }

    /// @notice Allows providers to add providers to an Identity.
    /// @param ein The EIN to add providers to.
    /// @param providers A list of providers.
    function addProvidersFor(uint ein, address[] memory providers) public _isProviderFor(ein) {
        addProviders(ein, providers, true);
    }

    /// @dev Common logic for all provider adding.
    function addProviders(uint ein, address[] memory providers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < providers.length; i++) {
            _identity.providers.insert(providers[i]);
            emit ProviderAdded(msg.sender, ein, providers[i], delegated);
        }
    }

    /// @notice Allows an associated address to remove providers from its Identity.
    /// @param providers A list of providers.
    function removeProviders(address[] memory providers) public {
        removeProviders(getEIN(msg.sender), providers, false);
    }

    /// @notice Allows providers to remove providers to an Identity.
    /// @param ein The EIN to remove providers from.
    /// @param providers A list of providers.
    function removeProvidersFor(uint ein, address[] memory providers) public _isProviderFor(ein) {
        removeProviders(ein, providers, true);
    }

    /// @dev Common logic for all provider removal.
    function removeProviders(uint ein, address[] memory providers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < providers.length; i++) {
            _identity.providers.remove(providers[i]);
            emit ProviderRemoved(msg.sender, ein, providers[i], delegated);
        }
    }

    /// @notice Allows an associated address to add resolvers to its Identity.
    /// @param resolvers A list of resolvers.
    function addResolvers(address[] memory resolvers) public {
        addResolvers(getEIN(msg.sender), resolvers, false);
    }

    /// @notice Allows providers to add resolvers to an Identity.
    /// @param ein The EIN to add resolvers to.
    /// @param resolvers A list of resolvers.
    function addResolversFor(uint ein, address[] memory resolvers) public _isProviderFor(ein) {
        addResolvers(ein, resolvers, true);
    }

    /// @dev Common logic for all resolver adding.
    function addResolvers(uint ein, address[] memory resolvers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < resolvers.length; i++) {
            _identity.resolvers.insert(resolvers[i]);
            emit ResolverAdded(msg.sender, ein, resolvers[i], delegated);
        }
    }

    /// @notice Allows an associated address to remove resolvers from its Identity.
    /// @param resolvers A list of resolvers.
    function removeResolvers(address[] memory resolvers) public {
        removeResolvers(getEIN(msg.sender), resolvers, true);
    }

    /// @notice Allows providers to remove resolvers from an Identity.
    /// @param ein The EIN to remove resolvers from.
    /// @param resolvers A list of resolvers.
    function removeResolversFor(uint ein, address[] memory resolvers) public _isProviderFor(ein) {
        removeResolvers(ein, resolvers, true);
    }

    /// @dev Common logic for all resolver removal.
    function removeResolvers(uint ein, address[] memory resolvers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < resolvers.length; i++) {
            _identity.resolvers.remove(resolvers[i]);
            emit ResolverRemoved(msg.sender, ein, resolvers[i], delegated);
        }
    }


    // Recovery Management Functions ///////////////////////////////////////////////////////////////////////////////////

    /// @notice Allows an associated address to change the recovery address for its Identity.
    /// @dev Recovery addresses can be changed at most once every recoveryTimeout seconds.
    /// @param newRecoveryAddress A recovery address to set for the sender&#39;s EIN.
    function triggerRecoveryAddressChange(address newRecoveryAddress) public {
        triggerRecoveryAddressChange(getEIN(msg.sender), newRecoveryAddress, false);
    }

    /// @notice Allows providers to change the recovery address for an Identity.
    /// @dev Recovery addresses can be changed at most once every recoveryTimeout seconds.
    /// @param ein The EIN to set the recovery address of.
    /// @param newRecoveryAddress A recovery address to set for the passed EIN.
    function triggerRecoveryAddressChangeFor(uint ein, address newRecoveryAddress) public _isProviderFor(ein) {
        triggerRecoveryAddressChange(ein, newRecoveryAddress, true);
    }

    /// @dev Common logic for all recovery address changes.
    function triggerRecoveryAddressChange(uint ein, address newRecoveryAddress, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];

        require(canChangeRecoveryAddress(ein), "Cannot trigger a change in recovery address yet.");

         // solium-disable-next-line security/no-block-members
        recoveryAddressChangeLogs[ein] = RecoveryAddressChange(block.timestamp, _identity.recoveryAddress);

        emit RecoveryAddressChangeTriggered(msg.sender, ein, _identity.recoveryAddress, newRecoveryAddress, delegated);

        _identity.recoveryAddress = newRecoveryAddress;
    }

    /// @notice Allows recovery addresses to trigger the recovery process for an Identity.
    /// @dev msg.sender must be current recovery address, or the old one if it was changed recently.
    /// @param ein The EIN to trigger recovery for.
    /// @param newAssociatedAddress A recovery address to set for the passed EIN.
    /// @param v The v component of the signature.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @param timestamp The timestamp of the signature.
    function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public _identityExists(ein) _hasIdentity(newAssociatedAddress, false) ensureSignatureTimeValid(timestamp)
    {
        require(canRecover(ein), "Cannot trigger recovery yet.");
        Identity storage _identity = identityDirectory[ein];

        // ensure the sender is the recovery address/old recovery address if there&#39;s been a recent change
        if (canChangeRecoveryAddress(ein)) {
            require(
                msg.sender == _identity.recoveryAddress, "Only the current recovery address can trigger recovery."
            );
        } else {
            require(
                msg.sender == recoveryAddressChangeLogs[ein].oldRecoveryAddress,
                "Only the recently removed recovery address can trigger recovery."
            );
        }

        require(
            isSigned(
                newAssociatedAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize being added to this Identity via recovery.",
                        ein, newAssociatedAddress, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        // log the old associated addresses to facilitate destruction if necessary
        recoveryLogs[ein] = Recovery(
            block.timestamp, // solium-disable-line security/no-block-members
            keccak256(abi.encodePacked(_identity.associatedAddresses.members))
        );

        emit RecoveryTriggered(msg.sender, ein, _identity.associatedAddresses.members, newAssociatedAddress);

        // remove identity data, and add the new address as the sole associated address
        resetIdentityData(_identity, msg.sender, false);
        addAssociatedAddress(ein, newAssociatedAddress);
    }

    /// @notice Allows associated addresses recently removed via recovery to permanently disable their old Identity.
    /// @param ein The EIN to trigger destruction of.
    /// @param firstChunk The array of addresses before the msg.sender in the pre-recovery associated addresses array.
    /// @param lastChunk The array of addresses after the msg.sender in the pre-recovery associated addresses array.
    /// @param resetResolvers true if the destroyer wants resolvers to be removed, false otherwise.
    function triggerDestruction(uint ein, address[] memory firstChunk, address[] memory lastChunk, bool resetResolvers)
        public _identityExists(ein)
    {
        require(!canRecover(ein), "Recovery has not recently been triggered.");
        Identity storage _identity = identityDirectory[ein];

        // ensure that the msg.sender was an old associated address for the referenced identity
        address payable[1] memory middleChunk = [msg.sender];
        require(
            keccak256(
                abi.encodePacked(firstChunk, middleChunk, lastChunk)
            ) == recoveryLogs[ein].hashedOldAssociatedAddresses,
            "Cannot destroy an EIN from an address that was not recently removed from said EIN via recovery."
        );

        emit IdentityDestroyed(msg.sender, ein, _identity.recoveryAddress, resetResolvers);

        resetIdentityData(_identity, address(0), resetResolvers);
    }

    /// @dev Common logic for clearing the data of an Identity.
    function resetIdentityData(Identity storage identity, address newRecoveryAddress, bool resetResolvers) private {
        for (uint i; i < identity.associatedAddresses.members.length; i++) {
            delete associatedAddressDirectory[identity.associatedAddresses.members[i]];
        }
        delete identity.associatedAddresses;
        delete identity.providers;
        if (resetResolvers) delete identity.resolvers;
        identity.recoveryAddress = newRecoveryAddress;
    }


    // Events //////////////////////////////////////////////////////////////////////////////////////////////////////////

    event IdentityCreated(
        address indexed initiator, uint indexed ein,
        address recoveryAddress, address associatedAddress, address[] providers, address[] resolvers, bool delegated
    );
    event AssociatedAddressAdded(
        address indexed initiator, uint indexed ein, address approvingAddress, address addedAddress, bool delegated
    );
    event AssociatedAddressRemoved(address indexed initiator, uint indexed ein, address removedAddress, bool delegated);
    event ProviderAdded(address indexed initiator, uint indexed ein, address provider, bool delegated);
    event ProviderRemoved(address indexed initiator, uint indexed ein, address provider, bool delegated);
    event ResolverAdded(address indexed initiator, uint indexed ein, address resolvers, bool delegated);
    event ResolverRemoved(address indexed initiator, uint indexed ein, address resolvers, bool delegated);
    event RecoveryAddressChangeTriggered(
        address indexed initiator, uint indexed ein,
        address oldRecoveryAddress, address newRecoveryAddress, bool delegated
    );
    event RecoveryTriggered(
        address indexed initiator, uint indexed ein, address[] oldAssociatedAddresses, address newAssociatedAddress
    );
    event IdentityDestroyed(address indexed initiator, uint indexed ein, address recoveryAddress, bool resolversReset);
}