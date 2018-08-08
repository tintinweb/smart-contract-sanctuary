pragma solidity 0.4.24;

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <stefan@gnosis.pm>
contract Proxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    address masterCopy;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != 0, "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }

    function implementation()
        public
        view
        returns (address)
    {
        return masterCopy;
    }

    function proxyType()
        public
        pure
        returns (uint256)
    {
        return 2;
    }
}

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <stefan@gnosis.pm>
contract ProxyFactory {

    event ProxyCreation(Proxy proxy);

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param masterCopy Address of master copy.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address masterCopy, bytes data)
        public
        returns (Proxy proxy)
    {
        proxy = new Proxy(masterCopy);
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas, proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
        emit ProxyCreation(proxy);
    }
}