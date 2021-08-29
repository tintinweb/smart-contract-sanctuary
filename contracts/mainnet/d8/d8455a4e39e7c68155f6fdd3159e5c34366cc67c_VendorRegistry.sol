// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./pausable.sol";
import "./managable.sol";
import "./wrappedasset.sol";
import "./imigratablevendorregistry.sol";



/// Maintains a registry of Ethereum/BSC adrresses of vendors allowed to wrap MRX, & their associated MRX withdrawal addresses.
/// @title  VendorRegistry
/// @dev    Uses solidity mappings to maintain a bi-directional 1-to-1 mapping between ethereum or BSC addresses and MRX addresses.
/// @author loma oopaloopa
contract VendorRegistry is Pausable, Managable, IMigratableVendorRegistry
    {
    address                     private wrappedAssetAddr;
    WrappedAsset                private wrappedAsset;
    mapping(address => address) private vendor2mrx;
    mapping(address => address) private mrx2vendor;

    /// Emitted when a registration is created or updated.
    /// @param mrxAddress    The registration's MRX address.
    /// @param vendorAddress The registration's (ethereum or BSC) vendor address.
    event Registered(address mrxAddress, address vendorAddress);

    /// Emitted when a registration's MRX address is cahnged by setVendorRegistration().
    /// @param mrxAddress    The registration's old MRX address from before the change.
    /// @param vendorAddress The registration's (ethereum or BSC) vendor address.
    event Unregistered(address mrxAddress, address vendorAddress);

    /// Deploy a VendorRegistry and WrappedAssest pair, the parameters are apssed unchanged to the WrappedAsstes's constructor.
    constructor(string memory tokenName, string memory tokenSymbol, uint256 tokenCap, uint256 tokenSnapshotIntervalHours)
        {
        wrappedAsset = new WrappedAsset(tokenName, tokenSymbol, tokenCap, tokenSnapshotIntervalHours);
        wrappedAssetAddr = address(wrappedAsset);
        wrappedAsset.setVendorRegistry(address(this));
        wrappedAsset.changeOwner(getOwner());
        }

    /// An owner only method to change the WrappedAsset this VendorRegistry is associated with, use WrappedAsset.setVendorRegistry() to make the required reciprical change on WrappedAsset.
    /// @param WrappedAssetAddress The address of the new WrappedAsset contract to pair with.
    function setWrappedAsset(address WrappedAssetAddress) public isOwner
        {
        wrappedAssetAddr = WrappedAssetAddress;
        wrappedAsset = WrappedAsset(WrappedAssetAddress);
        }

    /// Look up the (ethereum or BSC) vendor address associated with a given MRX address.
    /// @param  mrxAddress The MRX address for which to look up the vendor address.
    /// @return The vendor address, or address(0) if the MRX address is not registered.
    function findVendorFromMrx(address mrxAddress) public view returns (address)
        {
        return mrx2vendor[mrxAddress];
        }

    /// Look up the MRX addrees for a given (ethereum or BSC) vendor address.
    /// @param  vendorAddress The vendor address address for which to look up the MRX address.
    /// @return The MRX address, or address(0) if the vendor address is not registered.
    function findMrxFromVendor(address vendorAddress) public override view returns (address)
        {
        return vendor2mrx[vendorAddress];
        }

    /// Check whether or not a given MRX address is registered.
    /// @param  mrxAddress The MRX address for which to find the registration status.
    /// @return True if the MRX address is registered and false if it's not.
    function isRegistered(address mrxAddress) public view returns (bool)
        {
        return mrx2vendor[mrxAddress] != address(0);
        }

    /// Get the address of the associated WrappedAsset contract.
    /// @return The address of the associated WrappedAsset contract.
    function getWrappedAsset() public view returns (address)
        {
        return wrappedAssetAddr;
        }

    /// A pausable method to register the caller's (ethereum or BSC) address as a vendor, with the given MRX address. This is the method members of the public use to register.
    /// @param mrxAddress The MRX address to register.
    /// @param signature  A manager of this contract's signature on a premission to register message.
    function registerAsVendor(address mrxAddress, bytes memory signature) public whenNotPaused
        {
        require(mrxAddress != address(0), "VendorRegistry: Registration failed, the MRX address can not be zero.");
        require(mrx2vendor[mrxAddress] == address(0) && vendor2mrx[msg.sender] == address(0), "VendorRegistry: Registration failed, 1 or more addresses have already been registered.");
        bytes memory message = abi.encodePacked(msg.sender, address(this), mrxAddress);
        require(addressIsAManager(recoverSigner(message, signature)), "VendorRegistry: Registration failed, invalid signature.");
        mrx2vendor[mrxAddress] = msg.sender;
        vendor2mrx[msg.sender] = mrxAddress;
        emit Registered(mrxAddress, msg.sender);
        }

    /// A management only method to create a vendor registration, or to update the MRX address for an existing vendor registration.
    /// @param mrxAddress    The new MRX address for the vendor.
    /// @param vendorAddress The vendor's (ethereum or BSC) address.
    function setVendorRegistration(address mrxAddress, address vendorAddress) public isManager
        {
        require(mrxAddress != address(0) && vendorAddress != address(0), "VendorRegistry: Registration failed, the zero address can not be registered.");
        bool registrationHappened = false;
        address existingMrxAddress = vendor2mrx[vendorAddress];
        if (existingMrxAddress != mrxAddress)
            {
            if (existingMrxAddress != address(0))
                {
                emit Unregistered(existingMrxAddress, mrx2vendor[existingMrxAddress]);
                mrx2vendor[existingMrxAddress] = address(0);
                }
            registrationHappened = true;
            vendor2mrx[vendorAddress] = mrxAddress;
            }
        address existingVendorAddress = mrx2vendor[mrxAddress];
        if (existingVendorAddress != vendorAddress)
            {
            require(existingVendorAddress == address(0), "VendorRegistry: Registration failed, the MRX address has already been registered by a different vendor.");
            registrationHappened = true;
            mrx2vendor[mrxAddress] = vendorAddress;
            }
        if (registrationHappened) emit Registered(mrxAddress, vendorAddress);
        }

    /// Only ever called by WrappedAsset.migrateFromPreviousVersion(), this method checks if the vendor address is already registerd, and if not registers it with the given MRX address.
    /// @param mrxAddress    The new MRX address for the vendor (to be used only if the vendor address is not already registered).
    /// @param vendorAddress The vendor's (ethereum or BSC) address.
    function migrateVendorRegistration(address mrxAddress, address vendorAddress) external
        {
        require(msg.sender == wrappedAssetAddr, "VendorRegistry: Access not permitted.");
        require(mrxAddress != address(0) && vendorAddress != address(0), "VendorRegistry: Registration failed, the zero address can not be registered.");
        if (vendor2mrx[vendorAddress] == address(0))
            {
            require(mrx2vendor[mrxAddress] == address(0), "VendorRegistry: Registration failed, the MRX address has already been registered.");
            vendor2mrx[vendorAddress] = mrxAddress;
            mrx2vendor[mrxAddress] = vendorAddress;
            emit Registered(mrxAddress, vendorAddress);
            }
        }

    /// A management only method to pause the public's ability to register, however the (management only) setVendorRegistration() function will continue to work.
    function pause() public isManager
        {
        _pause();
        }

    /// A management only method to restart the public's ability to register.
    function unpause() public isManager
        {
        _unpause();
        }

    function recoverSigner(bytes memory message, bytes memory signature) internal pure returns (address)
        {
        require(signature.length == 65, "VendorRegistry: Action failed due to an invalid signature.");
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly
            {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
            }
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message))), v, r, s);
        }
    }