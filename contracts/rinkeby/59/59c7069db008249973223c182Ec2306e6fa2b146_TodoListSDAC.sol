//
// Example todolist smart data access contract
//
// This is about as basic as it comes.  It specifies a single directory that the owner of the contract has permission
// to read and write.  The directory has the id "0x0000000000000000000000000000000000000001".
//
// An SDAC defines the access permissions for all files in your vault.  When you construct a vault on an off-chain vault
// server you specify the address of the smart contract you want to control it.  The vault service will call the
// getPermissions method of the contract whenever someone tries to read or write to the vault and will accept or
// reject the request depending on the posix-style permission bits it returns.  All files and directories in Datona
// are ethereum addresses for privacy reasons.
//
// An example improvement would be to extend this contract to allow the owner to grant and revoke read access for
// other people.
//

pragma solidity ^0.6.3;

import "./SDAC-v0.0.2.sol";

contract TodoListSDAC is SDAC {

    bool terminated = false;

    function getPermissions( address requester, address file ) public view override returns (byte) {
        if (requester != owner || hasExpired()) return NO_PERMISSIONS;
        if ( file == address(1) ) return NO_PERMISSIONS | DIRECTORY_BIT | READ_BIT | WRITE_BIT | APPEND_BIT;
        return NO_PERMISSIONS;
    }

    function hasExpired() public view override returns (bool) {
        return terminated;
    }

    function terminate() public override {
        require(msg.sender == owner, "permission denied");
        terminated = true;
    }

}

pragma solidity ^0.6.3;

/*
 * Smart Data Access Contract
 *
 * All S-DACs must implement this interface
 */

abstract contract SDAC {

    string public constant DatonaProtocolVersion = "0.0.2";

    // constants describing the permissions-byte structure of the form d----rwa.
    byte public constant NO_PERMISSIONS = 0x00;
    byte public constant ALL_PERMISSIONS = 0x07;
    byte public constant READ_BIT = 0x04;
    byte public constant WRITE_BIT = 0x02;
    byte public constant APPEND_BIT = 0x01;
    byte public constant DIRECTORY_BIT = 0x80;

    address public owner = msg.sender;

    // File based d----rwa permissions.  Assumes the data vault has validated the requester's ID.
    // Address(0) is a special file representing the vault's root
    function getPermissions( address requester, address file ) public virtual view returns (byte);

    // returns true if the contract has expired either automatically or has been manually terminated
    function hasExpired() public virtual view returns (bool);

    // terminates the contract if the sender is permitted and any termination conditions are met
    function terminate() public virtual;

}

