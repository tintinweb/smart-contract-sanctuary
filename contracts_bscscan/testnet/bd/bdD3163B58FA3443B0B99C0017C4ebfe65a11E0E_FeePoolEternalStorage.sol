/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       FeePoolEternalStorage.sol
version:    1.0
author:     Clinton Ennis
            Jackson Chan
date:       2019-04-05

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The FeePoolEternalStorage is for any state the FeePool contract
needs to persist between upgrades to the FeePool logic.

Please see EternalStorage.sol

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LimitedSetup.sol";
import "./EternalStorage.sol";

contract FeePoolEternalStorage is EternalStorage, LimitedSetup {

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    /**
     * @dev Constructor.
     * @param _owner The owner of this contract.
     */
    constructor(address _owner, address _feePool)
        EternalStorage(_owner, _feePool)
        LimitedSetup(6 weeks)
    {
    }

    /**
     * @notice Import data from FeePool.lastFeeWithdrawal
     * @dev Only callable by the contract owner, and only for 6 weeks after deployment.
     * @param accounts Array of addresses that have claimed
     * @param feePeriodIDs Array feePeriodIDs with the accounts last claim
     */
    function importFeeWithdrawalData(address[] memory accounts, uint[] memory feePeriodIDs)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == feePeriodIDs.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            this.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, accounts[i])), feePeriodIDs[i]);
        }
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       LimitedSetup.sol
version:    1.1
author:     Anton Jurisevic

date:       2018-05-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract with a limited setup period. Any function modified
with the setup modifier will cease to work after the
conclusion of the configurable-length post-construction setup period.

-----------------------------------------------------------------
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Any function decorated with the modifier this contract provides
 * deactivates after a specified setup period.
 */
contract LimitedSetup {

    uint setupExpiryTime;

    /**
     * @dev LimitedSetup Constructor.
     * @param setupDuration The time the setup period will last for.
     */
    constructor(uint setupDuration)
    {
        setupExpiryTime = block.timestamp + setupDuration;
    }

    modifier onlyDuringSetup
    {
        require(block.timestamp < setupExpiryTime, "Can only perform this action during setup");
        _;
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       EternalStorage.sol
version:    1.0
author:     Clinton Ennise
            Jackson Chan

date:       2019-02-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract is used with external state storage contracts for
decoupled data storage.

Implements support for storing a keccak256 key and value pairs. It is
the more flexible and extensible option. This ensures data schema
changes can be implemented without requiring upgrades to the
storage contract

The first deployed storage contract would create this eternal storage.
Favour use of keccak256 key over sha3 as future version of solidity
> 0.5.0 will be deprecated.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./State.sol";

/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
contract EternalStorage is State {

    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
    {
    }

    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) UIntStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => int) IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external
        onlyAssociatedContract
    {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete UIntStorage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string memory value) external
        onlyAssociatedContract
    {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external
        onlyAssociatedContract
    {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete AddressStorage[record];
    }


    // BytesStorage
    function getBytesValue(bytes32 record) external view returns
    (bytes memory){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes memory value) external
        onlyAssociatedContract
    {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32)
    {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external
        onlyAssociatedContract
    {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external
        onlyAssociatedContract
    {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool)
    {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external
        onlyAssociatedContract
    {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external
        onlyAssociatedContract
    {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete IntStorage[record];
    }
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