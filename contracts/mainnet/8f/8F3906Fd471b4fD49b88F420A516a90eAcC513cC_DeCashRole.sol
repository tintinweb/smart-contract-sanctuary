/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.7.6;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

interface DeCashRoleInterface {
    function transferOwnership(address _newOwner) external;

    function addRole(string memory _role, address _address) external;

    function removeRole(string memory _role, address _address) external;
}

interface DeCashStorageInterface {
    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;
}

/// @title Base settings / modifiers for each contract in DeCash Token (Credits David Rugendyke/Rocket Pool)
/// @author Fabrizio Amodio (ZioFabry)

abstract contract DeCashBase {
    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    DeCashStorageInterface internal _decashStorage = DeCashStorageInterface(0);

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
     */
    modifier onlyLatestContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                _getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid or outdated contract"
        );
        _;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Account is not the owner");
        _;
    }
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Account is not an admin");
        _;
    }
    modifier onlySuperUser() {
        require(_isSuperUser(msg.sender), "Account is not a super user");
        _;
    }
    modifier onlyDelegator(address _address) {
        require(_isDelegator(_address), "Account is not a delegator");
        _;
    }
    modifier onlyFeeRecipient(address _address) {
        require(_isFeeRecipient(_address), "Account is not a fee recipient");
        _;
    }
    modifier onlyRole(string memory _role) {
        require(_roleHas(_role, msg.sender), "Account does not match the role");
        _;
    }

    /// @dev Set the main DeCash Storage address
    constructor(address _decashStorageAddress) {
        // Update the contract address
        _decashStorage = DeCashStorageInterface(_decashStorageAddress);
    }

    function isOwner(address _address) external view returns (bool) {
        return _isOwner(_address);
    }

    function isAdmin(address _address) external view returns (bool) {
        return _isAdmin(_address);
    }

    function isSuperUser(address _address) external view returns (bool) {
        return _isSuperUser(_address);
    }

    function isDelegator(address _address) external view returns (bool) {
        return _isDelegator(_address);
    }

    function isFeeRecipient(address _address) external view returns (bool) {
        return _isFeeRecipient(_address);
    }

    function isBlacklisted(address _address) external view returns (bool) {
        return _isBlacklisted(_address);
    }

    /// @dev Get the address of a network contract by name
    function _getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress =
            _getAddress(
                keccak256(abi.encodePacked("contract.address", _contractName))
            );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function _getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName =
            _getString(
                keccak256(abi.encodePacked("contract.name", _contractAddress))
            );
        // Check it
        require(
            keccak256(abi.encodePacked(contractName)) !=
                keccak256(abi.encodePacked("")),
            "Contract not found"
        );
        // Return
        return contractName;
    }

    /// @dev Role Management
    function _roleHas(string memory _role, address _address)
        internal
        view
        returns (bool)
    {
        return
            _getBool(
                keccak256(abi.encodePacked("access.role", _role, _address))
            );
    }

    function _isOwner(address _address) internal view returns (bool) {
        return _roleHas("owner", _address);
    }

    function _isAdmin(address _address) internal view returns (bool) {
        return _roleHas("admin", _address);
    }

    function _isSuperUser(address _address) internal view returns (bool) {
        return _roleHas("admin", _address) || _isOwner(_address);
    }

    function _isDelegator(address _address) internal view returns (bool) {
        return _roleHas("delegator", _address) || _isOwner(_address);
    }

    function _isFeeRecipient(address _address) internal view returns (bool) {
        return _roleHas("fee", _address) || _isOwner(_address);
    }

    function _isBlacklisted(address _address) internal view returns (bool) {
        return _roleHas("blacklisted", _address) && !_isOwner(_address);
    }

    /// @dev Storage get methods
    function _getAddress(bytes32 _key) internal view returns (address) {
        return _decashStorage.getAddress(_key);
    }

    function _getUint(bytes32 _key) internal view returns (uint256) {
        return _decashStorage.getUint(_key);
    }

    function _getString(bytes32 _key) internal view returns (string memory) {
        return _decashStorage.getString(_key);
    }

    function _getBytes(bytes32 _key) internal view returns (bytes memory) {
        return _decashStorage.getBytes(_key);
    }

    function _getBool(bytes32 _key) internal view returns (bool) {
        return _decashStorage.getBool(_key);
    }

    function _getInt(bytes32 _key) internal view returns (int256) {
        return _decashStorage.getInt(_key);
    }

    function _getBytes32(bytes32 _key) internal view returns (bytes32) {
        return _decashStorage.getBytes32(_key);
    }

    function _getAddressS(string memory _key) internal view returns (address) {
        return _decashStorage.getAddress(keccak256(abi.encodePacked(_key)));
    }

    function _getUintS(string memory _key) internal view returns (uint256) {
        return _decashStorage.getUint(keccak256(abi.encodePacked(_key)));
    }

    function _getStringS(string memory _key)
        internal
        view
        returns (string memory)
    {
        return _decashStorage.getString(keccak256(abi.encodePacked(_key)));
    }

    function _getBytesS(string memory _key)
        internal
        view
        returns (bytes memory)
    {
        return _decashStorage.getBytes(keccak256(abi.encodePacked(_key)));
    }

    function _getBoolS(string memory _key) internal view returns (bool) {
        return _decashStorage.getBool(keccak256(abi.encodePacked(_key)));
    }

    function _getIntS(string memory _key) internal view returns (int256) {
        return _decashStorage.getInt(keccak256(abi.encodePacked(_key)));
    }

    function _getBytes32S(string memory _key) internal view returns (bytes32) {
        return _decashStorage.getBytes32(keccak256(abi.encodePacked(_key)));
    }

    /// @dev Storage set methods
    function _setAddress(bytes32 _key, address _value) internal {
        _decashStorage.setAddress(_key, _value);
    }

    function _setUint(bytes32 _key, uint256 _value) internal {
        _decashStorage.setUint(_key, _value);
    }

    function _setString(bytes32 _key, string memory _value) internal {
        _decashStorage.setString(_key, _value);
    }

    function _setBytes(bytes32 _key, bytes memory _value) internal {
        _decashStorage.setBytes(_key, _value);
    }

    function _setBool(bytes32 _key, bool _value) internal {
        _decashStorage.setBool(_key, _value);
    }

    function _setInt(bytes32 _key, int256 _value) internal {
        _decashStorage.setInt(_key, _value);
    }

    function _setBytes32(bytes32 _key, bytes32 _value) internal {
        _decashStorage.setBytes32(_key, _value);
    }

    function _setAddressS(string memory _key, address _value) internal {
        _decashStorage.setAddress(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setUintS(string memory _key, uint256 _value) internal {
        _decashStorage.setUint(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setStringS(string memory _key, string memory _value) internal {
        _decashStorage.setString(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBytesS(string memory _key, bytes memory _value) internal {
        _decashStorage.setBytes(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBoolS(string memory _key, bool _value) internal {
        _decashStorage.setBool(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setIntS(string memory _key, int256 _value) internal {
        _decashStorage.setInt(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBytes32S(string memory _key, bytes32 _value) internal {
        _decashStorage.setBytes32(keccak256(abi.encodePacked(_key)), _value);
    }

    /// @dev Storage delete methods
    function _deleteAddress(bytes32 _key) internal {
        _decashStorage.deleteAddress(_key);
    }

    function _deleteUint(bytes32 _key) internal {
        _decashStorage.deleteUint(_key);
    }

    function _deleteString(bytes32 _key) internal {
        _decashStorage.deleteString(_key);
    }

    function _deleteBytes(bytes32 _key) internal {
        _decashStorage.deleteBytes(_key);
    }

    function _deleteBool(bytes32 _key) internal {
        _decashStorage.deleteBool(_key);
    }

    function _deleteInt(bytes32 _key) internal {
        _decashStorage.deleteInt(_key);
    }

    function _deleteBytes32(bytes32 _key) internal {
        _decashStorage.deleteBytes32(_key);
    }

    function _deleteAddressS(string memory _key) internal {
        _decashStorage.deleteAddress(keccak256(abi.encodePacked(_key)));
    }

    function _deleteUintS(string memory _key) internal {
        _decashStorage.deleteUint(keccak256(abi.encodePacked(_key)));
    }

    function _deleteStringS(string memory _key) internal {
        _decashStorage.deleteString(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBytesS(string memory _key) internal {
        _decashStorage.deleteBytes(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBoolS(string memory _key) internal {
        _decashStorage.deleteBool(keccak256(abi.encodePacked(_key)));
    }

    function _deleteIntS(string memory _key) internal {
        _decashStorage.deleteInt(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBytes32S(string memory _key) internal {
        _decashStorage.deleteBytes32(keccak256(abi.encodePacked(_key)));
    }
}

/// @title Role Based Access Control for DeCash Token (Credits David Rugendyke/Rocket Pool)
/// @author Fabrizio Amodio (ZioFabry)

contract DeCashRole is DeCashBase, DeCashRoleInterface {
    // Events
    event RoleAdded(bytes32 indexed role, address indexed to);
    event RoleRemoved(bytes32 indexed role, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    // Construct
    constructor(address _decashStorageAddress)
        DeCashBase(_decashStorageAddress)
    {
        version = 1;
    }

    /**
     * @dev Allows the current owner to transfer control of the network to a new owner
     * @param _newOwner The address to transfer ownership to
     */
    function transferOwnership(address _newOwner)
        external
        override
        onlyLatestContract("role", address(this))
        onlyOwner
    {
        // Check new owner address
        require(_newOwner != address(0x0), "The new owner address is invalid");
        require(
            _newOwner != msg.sender,
            "The new owner address must not be the existing owner address"
        );
        // Remove current owner
        _deleteBool(
            keccak256(abi.encodePacked("access.role", "owner", msg.sender))
        );
        // Add new owner
        _setBool(
            keccak256(abi.encodePacked("access.role", "owner", _newOwner)),
            true
        );
        // Emit ownership transferred event
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    /**
     * @dev Add a role to an address
     */
    function addRole(string memory _role, address _address)
        external
        override
        onlyLatestContract("role", address(this))
        onlySuperUser
    {
        // Check role
        require(
            keccak256(abi.encodePacked(_role)) !=
                keccak256(abi.encodePacked("owner")),
            "The owner role cannot be added to an address"
        );
        // Check address
        require(_address != address(0x0), "The address is invalid");
        // Check address does not already have role
        require(
            !_getBool(
                keccak256(abi.encodePacked("access.role", _role, _address))
            ),
            "The address already has access to this role"
        );
        // Add role
        _setBool(
            keccak256(abi.encodePacked("access.role", _role, _address)),
            true
        );
        // Emit role added event
        emit RoleAdded(keccak256(abi.encodePacked(_role)), _address);
    }

    /**
     * @dev Remove a role from an address
     */
    function removeRole(string memory _role, address _address)
        external
        override
        onlyLatestContract("role", address(this))
        onlySuperUser
    {
        // Check role is not being removed from owner address
        require(
            !_roleHas("owner", _address),
            "Roles cannot be removed from the owner address"
        );
        // Check address has role
        require(
            _getBool(
                keccak256(abi.encodePacked("access.role", _role, _address))
            ),
            "The address does not have access to this role"
        );
        // Remove role
        _deleteBool(
            keccak256(abi.encodePacked("access.role", _role, _address))
        );
        // Emit role removed event
        emit RoleRemoved(keccak256(abi.encodePacked(_role)), _address);
    }
}

contract GBPDRole is DeCashRole {
    constructor(address _storage) DeCashRole(_storage) {}
}