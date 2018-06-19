/*
-----------------------------------------------------------------
FILE HEADER
-----------------------------------------------------------------

file:       TokenState.sol
version:    1.0
authors:    Anton Jurisevic
            Dominic Romanowski

date:       2018-04-03
checked:    Mike Spain
approved:   Samuel Brooks

repo:       https://github.com/Havven/havven
commit:     fa705dd2feabc9def03bce135f6a153a4b70b111

-----------------------------------------------------------------
*/

pragma solidity ^0.4.21;

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
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

contract Owned {
    address public owner;
    address public nominatedOwner;

    function Owned(address _owner)
        public
    {
        owner = _owner;
    }

    function nominateOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

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
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A contract that holds the state of an ERC20 compliant token.

This contract is used side by side with external state token
contracts, such as Havven and EtherNomin.
It provides an easy way to upgrade contract logic while
maintaining all user balances and allowances. This is designed
to to make the changeover as easy as possible, since mappings
are not so cheap or straightforward to migrate.

The first deployed contract would create this state contract,
using it as its store of balances.
When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/

contract TokenState is Owned {

    // the address of the contract that can modify balances and allowances
    // this can only be changed by the owner of this contract
    address public associatedContract;

    // ERC20 fields.
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function TokenState(address _owner, address _associatedContract)
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

    function setAllowance(address tokenOwner, address spender, uint value)
        external
        onlyAssociatedContract
    {
        allowance[tokenOwner][spender] = value;
    }

    function setBalanceOf(address account, uint value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }


    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract);
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address _associatedContract);
}