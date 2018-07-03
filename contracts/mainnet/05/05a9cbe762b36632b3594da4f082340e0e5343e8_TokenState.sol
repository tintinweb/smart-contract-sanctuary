/*
 * Nomin TokenState Contract
 *
 * Stores ERC20 balance and approval information for the
 * nomin component of the Havven stablecoin system.
 *
 * version: nUSDa.1
 * date: 29 Jun 2018
 * url: https://github.com/Havven/havven/releases/tag/nUSDa.1
 */
 
 
pragma solidity 0.4.24;
 
 
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
        public
    {
        require(_owner != address(0));
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
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }
 
    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }
 
    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
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
contracts, such as Havven and Nomin.
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
 
 
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;
 
 
    constructor(address _owner, address _associatedContract)
        Owned(_owner)
        public
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
        require(msg.sender == associatedContract);
        _;
    }
 
    /* ========== EVENTS ========== */
 
    event AssociatedContractUpdated(address associatedContract);
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       TokenState.sol
version:    1.1
author:     Dominic Romanowski
            Anton Jurisevic
 
date:       2018-05-15
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
A contract that holds the state of an ERC20 compliant token.
 
This contract is used side by side with external state token
contracts, such as Havven and Nomin.
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
 
 
/**
 * @title ERC20 Token State
 * @notice Stores balance information of an ERC20 token contract.
 */
contract TokenState is State {
 
    /* ERC20 fields. */
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
 
    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _associatedContract The ERC20 contract whose state this composes.
     */
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        public
    {}
 
    /* ========== SETTERS ========== */
 
    /**
     * @notice Set ERC20 allowance.
     * @dev Only the associated contract may call this.
     * @param tokenOwner The authorising party.
     * @param spender The authorised party.
     * @param value The total value the authorised party may spend on the
     * authorising party&#39;s behalf.
     */
    function setAllowance(address tokenOwner, address spender, uint value)
        external
        onlyAssociatedContract
    {
        allowance[tokenOwner][spender] = value;
    }
 
    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }
}