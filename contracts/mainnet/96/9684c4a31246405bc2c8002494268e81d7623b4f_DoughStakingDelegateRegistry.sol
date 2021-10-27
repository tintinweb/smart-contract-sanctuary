// SPDX-License-Identifier: LGPL-3.0-only
// Modified version of: https://etherscan.io/address/0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446#code
pragma solidity >=0.7.0 <0.8.0;

contract DoughStakingDelegateRegistry {
    address public owner;

    // The value is the address of the delegate
    mapping(address => address) public delegation;

    // Using these events it is possible to process the events to build up reverse lookups.
    // The indeces allow it to be very partial about how to build this lookup (e.g. only for a specific delegate).
    event SetDelegate(address indexed delegator, address indexed delegate);
    event ClearDelegate(address indexed delegator, address indexed delegate);
    event OwnershipChange(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");

        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @param delegator address of the delegator
    /// @param delegate Address of the delegate
    function setDelegate(address delegator, address delegate) public onlyOwner {
        require(delegate != address(0), "ZERO_ADDRESS");
        address currentDelegate = delegation[delegator];
        require(delegate != currentDelegate, "Already delegated to this address");

        // Update delegation mapping
        delegation[delegator] = delegate;

        emit SetDelegate(delegator, delegate);
    }

    function clearDelegate(address delegator) public onlyOwner {
        address currentDelegate = delegation[delegator];
        require(currentDelegate != address(0), "No delegate set");

        // update delegation mapping
        delegation[delegator] = address(0);

        emit ClearDelegate(delegator, currentDelegate);
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");

        emit OwnershipChange(owner, newOwner);

        owner = newOwner;
    }
}