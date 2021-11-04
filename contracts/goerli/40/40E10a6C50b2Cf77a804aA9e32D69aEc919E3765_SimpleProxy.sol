// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract SimpleProxy {
    // This contract splits the storage of a contract from its logic, it will
    // call an implementation contract via delegatecall. That implementation
    // changes what is stored in this contract, by changing the implementation
    // address this contract effectively has different logic.

    // NOTE - Functions 'upgradeProxy', 'resetProxyOwner', 'proxyImplementation' and 'proxyGovernance'
    // are occupied namespace and cannot be used in implementation contracts. In a very unlikely
    // edge case a 4 bit hash collision between function selectors could block other function names.

    // The implementation contains the logic for this proxy, it for security reasons
    // should not assume only this contract can call it.
    // NOTE - It's insecure in implementation proxies to use the default storage layout since
    //        it is possible to overwrite this address. Use Storage.sol for storage.
    address public proxyImplementation;
    // The address which can upgrade this contract
    address public proxyGovernance;

    /// @notice Sets up the authorizable library for the proxy
    /// @param _governance An address which will be authorized to change the implementation
    ///                    it will also be set at the owner of this contract.
    /// @param _firstImplementation The first implementation address
    constructor(address _governance, address _firstImplementation) {
        // Set governance
        proxyGovernance = _governance;
        // Set the first implementation
        proxyImplementation = _firstImplementation;
    }

    /// @notice Allows authorized addresses to change the implementation
    /// @param _newImplementation The new implementation address
    function upgradeProxy(address _newImplementation) external {
        require(msg.sender == proxyGovernance, "unauthorized");
        proxyImplementation = _newImplementation;
    }

    /// @notice Sets the address which can upgrade this proxy, only callable
    ///         by the current address which can upgrade this proxy.
    /// @param _newGovernance The new governance address
    function resetProxyOwner(address _newGovernance) external {
        require(msg.sender == proxyGovernance, "unauthorized");
        proxyGovernance = _newGovernance;
    }

    /// @notice The fallback is the routing function for the proxy and uses delegatecall
    ///         to forward any calls which are made to this address to be executed by the
    ///         logic contract.
    /// @dev WARNING - We don't do extcode size checks like high level solidity if the
    ///                implementation has 0 bytecode this will succeed but do nothing.
    fallback() external payable {
        assembly {
            let calldataLength := calldatasize()

            // equivalent to receive() external payable {}
            if iszero(calldataLength) {
                return(0, 0)
            }

            // We load the free memory pointer
            // Note - We technically don't need to do this because the whole call is
            // in assembly but it's good practice to match solidity's memory management
            let ptr := mload(0x40)
            // Copy the calldata into memory
            calldatacopy(
                // The position in memory this copies to
                ptr,
                // The calldata index this copies from
                0,
                // The number of bytes to copy
                calldataLength
            )
            // Move the free memory pointer
            mstore(0x40, add(ptr, calldataLength))
            // Load the implementation address
            let implementation := sload(proxyImplementation.slot)
            // It's very unlikely any extra data got loaded but we clean anyway
            implementation := and(
                implementation,
                0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
            // Now we make the delegatecall
            let success := delegatecall(
                // The gas param
                gas(),
                // The address
                implementation,
                // The memory location of the input data
                ptr,
                // The input size
                calldataLength,
                // The output memory pointer and size, we use the return data instead
                0,
                0
            )
            // Load our new free memory pointer
            ptr := mload(0x40)
            // Load the return data size
            let returndataLength := returndatasize()
            // Copy the return data
            returndatacopy(
                // Memory location of the output
                ptr,
                // Memory location of the input
                0,
                // Length of the input
                returndataLength
            )
            // If the call was not successful we revert
            if iszero(success) {
                revert(ptr, returndataLength)
            }

            // If the call was successful we return
            return(ptr, returndataLength)
        }
    }
}