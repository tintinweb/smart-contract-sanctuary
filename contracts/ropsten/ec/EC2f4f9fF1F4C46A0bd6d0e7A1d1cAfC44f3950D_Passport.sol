pragma solidity ^0.4.24;

// File: contracts/ownership/OwnableProxy.sol

/**
 * @title OwnableProxy
 */
contract OwnableProxy {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Storage slot with the owner of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.owner", and is
     * validated in the constructor.
     */
    bytes32 private constant OWNER_SLOT = 0x3ca57e4b51fc2e18497b219410298879868edada7e6fe5132c8feceb0a080d22;

    /**
     * @dev The OwnableProxy constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        assert(OWNER_SLOT == keccak256("org.monetha.proxy.owner"));

        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _getOwner());
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_getOwner());
        _setOwner(address(0));
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(_getOwner(), _newOwner);
        _setOwner(_newOwner);
    }

    /**
     * @return The owner address.
     */
    function owner() public view returns (address) {
        return _getOwner();
    }

    /**
     * @return The owner address.
     */
    function _getOwner() internal view returns (address own) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            own := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy owner.
     * @param _newOwner Address of the new proxy owner.
     */
    function _setOwner(address _newOwner) internal {
        bytes32 slot = OWNER_SLOT;

        assembly {
            sstore(slot, _newOwner)
        }
    }
}

// File: contracts/ownership/ClaimableProxy.sol

/**
 * @title ClaimableProxy
 * @dev Extension for the OwnableProxy contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract ClaimableProxy is OwnableProxy {
    /**
     * @dev Storage slot with the pending owner of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.pendingOwner", and is
     * validated in the constructor.
     */
    bytes32 private constant PENDING_OWNER_SLOT = 0xcfd0c6ea5352192d7d4c5d4e7a73c5da12c871730cb60ff57879cbe7b403bb52;

    /**
     * @dev The ClaimableProxy constructor validates PENDING_OWNER_SLOT constant.
     */
    constructor() public {
        assert(PENDING_OWNER_SLOT == keccak256("org.monetha.proxy.pendingOwner"));
    }

    function pendingOwner() public view returns (address) {
        return _getPendingOwner();
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _getPendingOwner());
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _setPendingOwner(newOwner);
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_getOwner(), _getPendingOwner());
        _setOwner(_getPendingOwner());
        _setPendingOwner(address(0));
    }

    /**
     * @return The pending owner address.
     */
    function _getPendingOwner() internal view returns (address penOwn) {
        bytes32 slot = PENDING_OWNER_SLOT;
        assembly {
            penOwn := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the pending owner.
     * @param _newPendingOwner Address of the new pending owner.
     */
    function _setPendingOwner(address _newPendingOwner) internal {
        bytes32 slot = PENDING_OWNER_SLOT;

        assembly {
            sstore(slot, _newPendingOwner)
        }
    }
}

// File: contracts/lifecycle/DestructibleProxy.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract DestructibleProxy is OwnableProxy {
    /**
     * @dev Transfers the current balance to the owner and terminates the contract.
     */
    function destroy() public onlyOwner {
        selfdestruct(_getOwner());
    }

    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }
}

// File: contracts/IPassportLogicRegistry.sol

interface IPassportLogicRegistry {
    /**
     * @dev This event will be emitted every time a new passport logic implementation is registered
     * @param version representing the version name of the registered passport logic implementation
     * @param implementation representing the address of the registered passport logic implementation
     */
    event PassportLogicAdded(string version, address implementation);

    /**
     * @dev This event will be emitted every time a new passport logic implementation is set as current one
     * @param version representing the version name of the current passport logic implementation
     * @param implementation representing the address of the current passport logic implementation
     */
    event CurrentPassportLogicSet(string version, address implementation);

    /**
     * @dev Tells the address of the passport logic implementation for a given version
     * @param _version to query the implementation of
     * @return address of the passport logic implementation registered for the given version
     */
    function getPassportLogic(string _version) external view returns (address);

    /**
     * @dev Tells the version of the current passport logic implementation
     * @return version of the current passport logic implementation
     */
    function getCurrentPassportLogicVersion() external view returns (string);

    /**
     * @dev Tells the address of the current passport logic implementation
     * @return address of the current passport logic implementation
     */
    function getCurrentPassportLogic() external view returns (address);
}

// File: contracts/upgradeability/Proxy.sol

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    function () payable external {
        _delegate(_implementation());
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal view returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn&#39;t return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

        // Call the implementation.
        // out and outsize are 0 because we don&#39;t know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }
}

// File: contracts/Passport.sol

/**
 * @title Passport
 */
contract Passport is Proxy, ClaimableProxy, DestructibleProxy {

    event PassportLogicRegistryChanged(
        address indexed previousRegistry,
        address indexed newRegistry
    );

    /**
     * @dev Storage slot with the address of the current registry of the passport implementations.
     * This is the keccak-256 hash of "org.monetha.passport.proxy.registry", and is
     * validated in the constructor.
     */
    bytes32 private constant REGISTRY_SLOT = 0xa04bab69e45aeb4c94a78ba5bc1be67ef28977c4fdf815a30b829a794eb67a4a;

    /**
     * @dev Contract constructor.
     * @param _registry Address of the passport implementations registry.
     */
    constructor(IPassportLogicRegistry _registry) public {
        assert(REGISTRY_SLOT == keccak256("org.monetha.passport.proxy.registry"));

        _setRegistry(_registry);
    }

    /**
     * @dev Changes the passport logic registry.
     * @param _registry Address of the new passport implementations registry.
     */
    function changePassportLogicRegistry(IPassportLogicRegistry _registry) public onlyOwner {
        emit PassportLogicRegistryChanged(address(_getRegistry()), address(_registry));
        _setRegistry(_registry);
    }

    /**
     * @return the address of passport logic registry.
     */
    function getPassportLogicRegistry() public view returns (address) {
        return _getRegistry();
    }

    /**
     * @dev Returns the current passport logic implementation (used in Proxy fallback function to delegate call
     * to passport logic implementation).
     * @return Address of the current passport implementation
     */
    function _implementation() internal view returns (address) {
        return _getRegistry().getCurrentPassportLogic();
    }

    /**
     * @dev Returns the current passport implementations registry.
     * @return Address of the current implementation
     */
    function _getRegistry() internal view returns (IPassportLogicRegistry reg) {
        bytes32 slot = REGISTRY_SLOT;
        assembly {
            reg := sload(slot)
        }
    }

    function _setRegistry(IPassportLogicRegistry _registry) internal {
        require(address(_registry) != 0x0, "Cannot set registry to a zero address");

        bytes32 slot = REGISTRY_SLOT;
        assembly {
            sstore(slot, _registry)
        }
    }
}