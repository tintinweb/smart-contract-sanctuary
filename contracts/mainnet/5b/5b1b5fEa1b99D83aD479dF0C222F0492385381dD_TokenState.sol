/*
-----------------------------------------------------------------
FILE HEADER
-----------------------------------------------------------------

file:       TokenState.sol
version:    1.0
author:     Dominic Romanowski
            Anton Jurisevic

date:       2018-2-24
checked:    Anton Jurisevic
approved:   Samuel Brooks

repo:       https://github.com/Havven/havven
commit:     34e66009b98aa18976226c139270970d105045e3

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

pragma solidity ^0.4.20;

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
    mapping(address => mapping(address => uint256)) public allowance;

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

/*
MIT License

Copyright (c) 2018 Havven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/