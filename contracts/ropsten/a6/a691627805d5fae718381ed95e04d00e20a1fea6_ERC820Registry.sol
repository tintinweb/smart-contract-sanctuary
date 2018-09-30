pragma solidity 0.4.24;

interface ERC820ImplementerInterface {
    /// @notice Indicates whether the contract implements the interface `interfaceHash` for the address `addr`.
    /// @param addr Address for which the contract will implement the interface
    /// @param interfaceHash keccak256 hash of the name of the interface
    /// @return ERC820_ACCEPT_MAGIC only if the contract implements `&#236;nterfaceHash` for the address `addr`.
    function canImplementInterfaceForAddress(address addr, bytes32 interfaceHash) public view returns(bytes32);
}


contract ERC820Registry {
    bytes4 constant INVALID_ID = 0xffffffff;
    bytes4 constant ERC165ID = 0x01ffc9a7;
    bytes32 constant ERC820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC820_ACCEPT_MAGIC"));

    mapping (address => mapping(bytes32 => address)) interfaces;
    mapping (address => address) managers;
    mapping (address => mapping(bytes4 => bool)) erc165Cached;

    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed addr, address indexed newManager);

    /// @notice Query if an address implements an interface and through which contract.
    /// @param _addr Address being queried for the implementer of an interface.
    ///   (If _addr == 0 them `msg.sender` is assumed.)
    /// @param _interfaceHash keccak256 hash of the name of the interface as a string.
    ///   E.g. `web3.utils.keccak256(abi.encodePacked(&#39;ERC777Token&#39;))`
    /// @return The address of the contract which implements the interface `_interfaceHash` for `_addr`
    ///   or `0x0` if `_addr` did not registeran implemeter for this interface.
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address) {
        address addr = _addr == 0 ? msg.sender : _addr;
        if (isERC165Interface(_interfaceHash)) {
            bytes4 erc165InterfaceHash = bytes4(_interfaceHash);
            return implementsERC165Interface(addr, erc165InterfaceHash) ? addr : 0;
        }
        return interfaces[addr][_interfaceHash];
    }

    /// @notice Sets the contract that will handle a specific interface.
    ///   Only a `manager` defined for that address can set it.
    ///   (Each address is the manager for itself until a new manager is defined)
    /// @param _addr Address to define the interface for (if _addr == 0 them `msg.sender` is assumed)
    /// @param _interfaceHash keccak256 hash of the name of the interface as a string For example,
    ///   `web3.utils.keccak256(abi.encodePacked(&#39;ERC777TokensRecipient&#39;))` for the ERC777TokensRecipient interface.
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external {
        address addr = _addr == 0 ? msg.sender : _addr;
        require(getManager(addr) == msg.sender, "Not the manager");

        require(!isERC165Interface(_interfaceHash), "Must not be a ERC165 hash");
        if (_implementer != 0 && _implementer != msg.sender) {
            require(
                ERC820ImplementerInterface(_implementer)
                    .canImplementInterfaceForAddress(addr, _interfaceHash) == ERC820_ACCEPT_MAGIC,
                "Does not implement the interface"
            );
        }
        interfaces[addr][_interfaceHash] = _implementer;
        emit InterfaceImplementerSet(addr, _interfaceHash, _implementer);
    }

    /// @notice Sets the `_newManager` as manager for the `_addr` address.
    ///   The new manager will be able to call `setInterfaceImplementer` for `_addr`.
    /// @param _addr Address for which to set the new manager. (Pass 0x0 to use msg.sender as the address.)
    /// @param _newManager The address of the new manager for `addr`. (Pass `0x0` to reset the manager to `_addr`.)
    function setManager(address _addr, address _newManager) external {
        address addr = _addr == 0 ? msg.sender : _addr;
        require(getManager(addr) == msg.sender, "Not the manager");
        managers[addr] = _newManager == addr ? 0 : _newManager;
        emit ManagerChanged(addr, _newManager);
    }

    /// @notice Get the manager of an address
    /// @return Address of the manager for a given address.
    function getManager(address _addr) public view returns(address) {
        // By default the manager of an address is the same address
        if (managers[_addr] == 0) {
            return _addr;
        } else {
            return managers[_addr];
        }
    }

    /// @notice Compute the keccak256 hash of an interface given its name
    /// @param interfaceName Name of the interface
    /// @return The keccak256 hash of an interface name
    function interfaceHash(string interfaceName) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(interfaceName));
    }

    // ERC165 Related Functions

    /// @dev This function may modify the state when updating the cache. But since it can also be called from
    ///   `getInterfaceImplementer`, it must be a view function. If called directly, from within a transaction, the
    ///   ERC165 will be updated.
    function implementsERC165Interface(address _contract, bytes4 _interfaceId) public view returns (bool) {
        if (!erc165Cached[_contract][_interfaceId]) {
            updateERC165Cache(_contract, _interfaceId);
        }
        return interfaces[_contract][_interfaceId] != 0;
    }

    function updateERC165Cache(address _contract, bytes4 _interfaceId) public {
        interfaces[_contract][_interfaceId] = implementsERC165InterfaceNoCache(_contract, _interfaceId) ? _contract : 0;
        erc165Cached[_contract][_interfaceId] = true;
    }

    function implementsERC165InterfaceNoCache(address _contract, bytes4 _interfaceId) public view returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, ERC165ID);
        if (success == 0 || result == 0) {
            return false;
        }

        (success, result) = noThrowCall(_contract, INVALID_ID);
        if (success == 0 || result != 0) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if (success == 1 && result == 1) {
            return true;
        }
        return false;
    }

    function isERC165Interface(bytes32 _interfaceHash) internal pure returns (bool) {
        return _interfaceHash & 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0;
    }

    function noThrowCall(address _contract, bytes4 _interfaceId)
        internal view returns (uint256 success, uint256 result)
    {
        bytes4 erc165ID = ERC165ID;

        assembly {
                let x := mload(0x40)               // Find empty storage location using "free memory pointer"
                mstore(x, erc165ID)                // Place signature at begining of empty storage
                mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

                success := staticcall(
                    30000,                         // 30k gas
                    _contract,                     // To addr
                    x,                             // Inputs are stored at location x
                    0x08,                          // Inputs are 8 bytes long
                    x,                             // Store output over input (saves space)
                    0x20                           // Outputs are 32 bytes long
                )

                result := mload(x)                 // Load the result
        }
    }
}