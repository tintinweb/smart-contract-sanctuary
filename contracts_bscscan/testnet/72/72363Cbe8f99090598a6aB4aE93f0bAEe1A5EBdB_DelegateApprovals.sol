/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       DelegateApprovals.sol
version:    1.0
author:     Jackson Chan
checked:    Clinton Ennis
date:       2019-05-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The approval state contract is designed to allow a wallet to
authorise another address to perform actions, on a contract,
on their behalf. This could be an automated service
that would help a wallet claim fees / rewards on their behalf.

The concept is similar to the ERC20 interface where a wallet can
approve an authorised party to spend on the authorising party's
behalf in the allowance interface.

Withdrawing approval sets the delegate as false instead of
removing from the approvals list for auditability.

This contract inherits state for upgradeability / associated
contract.

-----------------------------------------------------------------
*/
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./State.sol";

contract DelegateApprovals is State {

    // Approvals - [authoriser][delegate]
    // Each authoriser can have multiple delegates
    mapping(address => mapping(address => bool)) public approval;

    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _associatedContract The contract whose approval state this composes.
     */
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
    {}

    function setApproval(address authoriser, address delegate)
        external
        onlyAssociatedContract
    {
        approval[authoriser][delegate] = true;
        emit Approval(authoriser, delegate);
    }

    function withdrawApproval(address authoriser, address delegate)
        external
        onlyAssociatedContract
    {
        delete approval[authoriser][delegate];
        emit WithdrawApproval(authoriser, delegate);
    }

     /* ========== EVENTS ========== */

    event Approval(address indexed authoriser, address delegate);
    event WithdrawApproval(address indexed authoriser, address delegate);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       State.sol
version:    1.1
author:     Dominic Romanowski
            Anton Jurisevic

date:       2018-05-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract is used side by side with external state token
contracts, such as Synthetix and Synth.
It provides an easy way to upgrade contract logic while
maintaining all user balances and allowances. This is designed
to make the changeover as easy as possible, since mappings
are not so cheap or straightforward to migrate.

The first deployed contract would create this state contract,
using it as its store of balances.
When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Owned.sol";


contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;


    constructor(address _owner, address _associatedContract)
        Owned(_owner)
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Owned.sol
version:    1.1
author:     Anton Jurisevic
            Dominic Romanowski

date:       2018-2-26

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

An Owned contract, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /**
     * @dev Owned Constructor
     */
    constructor(address _owner)
    {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     */
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    /**
     * @notice Accept the nomination to be owner.
     */
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}