// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Permissioned.sol";
import "./interfaces/IMemberships.sol";

contract Memberships is IMemberships, Permissioned {

    // primary state: checking if an address belongs to a member of the DAO.
    mapping(address => bool) public override isMember;

    // **BEWARE** This does NOT return only active members — it includes members that have been revoked!!
    // This is just a way to keep track of all historical memberships. You can create a list of active members
    // off chain by querying each item in the list for membership status.
    address[] private _members;
    
    constructor(address[] memory initialMembers_) {
        _members = initialMembers_;

        for (uint16 i = 0; i < _members.length; i++) {
            isMember[ _members[i] ] = true;
        }
    }

    function getMembers() external override view returns (address[] memory) {
        return _members;
    }
    
    function grantMembership(address newMember_) external override onlyApprovedApps {
        isMember[newMember_] = true;
    } 

    function revokeMembership(address newMember_) external override onlyApprovedApps {
        isMember[newMember_] = false;
    } 
    
    function bulkGrantMemberships(address[] calldata newMembers_) external override onlyApprovedApps {
        for (uint16 i = 0; i < newMembers_.length; i++) {
            isMember[newMembers_[i]] = true;
        }
    } 

    function bulkRevokeMemberships(address[] calldata newMembers_) external override onlyApprovedApps {
        for (uint16 i = 0; i < newMembers_.length; i++) {
            isMember[newMembers_[i]] = false;
        }    
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * State Contracts are contracts that restrict certain functions to be accesible only by Application Contracts.
 * This makes it so that only pre-approved contracts managed by the DAO multisig can change/affect state of the DAO
 * e.g. Operator -> memberships + epoch, Treasury Vault -> shares, etc.

 * approveApplication() + revokeApplication() should be part of the dev ops pipeline/contract deployment cycle;
 * when a state contract and application contract are first released, the owner <dev addr> should assign
 * the proper approvals for application contracts to state contracts. If there is an application contract
 * upgrade (V2), the owner <dao multisig> should revoke the old application from modifying state (V1) and then
 * approving the new application to modify state IN THAT ORDER, so that there is no overlap with two contracts managing state.

 * isApproved is a mapping because in the future we may have third party applications/multiple internal applications
 * managing state. 
 */

abstract contract Permissioned is Ownable {
    event ApprovedApplication(address indexed contract_);
    event RevokedApplication(address indexed contract_);

    mapping(address => bool) public isApproved;
    
    // this keeps a list of both actively approved applications and revoked applications that were
    // historically approved. This is to keep a log of all the contracts throughout history that have
    // interacted with the state. To find a list of actively approved applications, verify each item in
    // the list to see if isApproved returns true.
    address[] private _approvedApplications;

    modifier onlyApprovedApps() {
        require(isApproved[msg.sender], "Permissioned onlyApprovedApps(): Application is not approved to call this contract");
        _;
    }

    function approveApplication(address appContract_) external virtual onlyOwner {
        isApproved[appContract_] = true;
        _approvedApplications.push(appContract_);

        emit ApprovedApplication(appContract_);
    }

    function revokeApplication(address appContract_) external virtual onlyOwner {
        isApproved[appContract_] = false;

        // ****************************** NOTE ***********************************
        // if you call this, make sure you also call "approvalRevoked(this address)"
        // on the corresponding application contract.
        // ***********************************************************************

        emit RevokedApplication(appContract_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMemberships {
    // properties (reads)
    function isMember(address) external view returns (bool);
    function getMembers() external view returns (address[] memory);

    // state changes (writes)
    function grantMembership(address) external;
    function revokeMembership(address) external;
    function bulkGrantMemberships(address[] calldata) external;
    function bulkRevokeMemberships(address[] calldata) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}