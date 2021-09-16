/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

contract DelegateRegistry {
    
    // The first key is the delegator and the second key a id. 
    // The value is the address of the delegate 
    mapping (address => mapping (bytes32 => address)) public delegation;
    
    // Using these events it is possible to process the events to build up reverse lookups.
    // The indeces allow it to be very partial about how to build this lookup (e.g. only for a specific delegate).
    event SetDelegate(address indexed delegator, bytes32 indexed id, address indexed delegate);
    event ClearDelegate(address indexed delegator, bytes32 indexed id, address indexed delegate);
    
    /// @dev Sets a delegate for the msg.sender and a specific id.
    ///      The combination of msg.sender and the id can be seen as a unique key.
    /// @param id Id for which the delegate should be set
    /// @param delegate Address of the delegate
    function setDelegate(bytes32 id, address delegate) public {
        require (delegate != msg.sender, "Can't delegate to self");
        require (delegate != address(0), "Can't delegate to 0x0");
        address currentDelegate = delegation[msg.sender][id];
        require (delegate != currentDelegate, "Already delegated to this address");
        
        // Update delegation mapping
        delegation[msg.sender][id] = delegate;
        
        if (currentDelegate != address(0)) {
            emit ClearDelegate(msg.sender, id, currentDelegate);
        }

        emit SetDelegate(msg.sender, id, delegate);
    }
    
    /// @dev Clears a delegate for the msg.sender and a specific id.
    ///      The combination of msg.sender and the id can be seen as a unique key.
    /// @param id Id for which the delegate should be set
    function clearDelegate(bytes32 id) public {
        address currentDelegate = delegation[msg.sender][id];
        require (currentDelegate != address(0), "No delegate set");
        
        // update delegation mapping
        delegation[msg.sender][id] = address(0);
        
        emit ClearDelegate(msg.sender, id, currentDelegate);
    }
}