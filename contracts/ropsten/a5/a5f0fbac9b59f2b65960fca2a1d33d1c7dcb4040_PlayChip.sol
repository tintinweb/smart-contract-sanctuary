/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       PlayChip.sol
version:    0.8
date:       2018-10-4
authors:    Joel Aquilina
            Anton Jurisevic

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A simple ERC20 token with additional functionality to send
batched transfers and approvals. This way transactions can be
made in bulk, saving time and gas.

The contract can be paused by the owner so that transfers are
disabled until it is unpaused. The contract begins paused
so that during this initialisation phase, all tokens are to
be distributed by the deployer of the contract.

The contract can also be self-destructed by the owner after a
four week delay after announcing the self-destruction. Note
that pausing the contract will do nothing during the
self-destruction period.

-----------------------------------------------------------------
*/


pragma solidity 0.4.25;
pragma experimental "v0.5.0";


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ERC20Token.sol
version:    1.0

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Standard ERC20 token interface.

-----------------------------------------------------------------
*/




/**
 * @title A basic ERC20 token interface.
 * @dev To use this, be sure to implement the `approve`, `transfer`, and `transferFrom`
 *      abstract functions, and to initialise `name`, `symbol`, `decimals`, and `totalSupply`.
 */
contract ERC20Token {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function approve(address spender, uint quantity) public returns (bool);
    function transfer(address to, uint quantity) public returns (bool);
    function transferFrom(address from, address to, uint quantity) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint quantity);
    event Approval(address indexed owner, address indexed spender, uint quantity);

}
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Owned.sol
version:    1.1
date:       2018-2-26
author:     Anton Jurisevic
            Dominic Romanowski

auditors: Sigma Prime, https://github.com/sigp/havven-audit
          BlocTrax, https://havven.io/uploads/havven_bloctrax_security_audit_june-6th.pdf

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract with an owner, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

If the ownership is to be relinquished, then it can be handed
to a smart contract whose only function is to accept that
ownership, which guarantees no owner-only functionality can
ever be invoked.

-----------------------------------------------------------------
*/


/**
 * @title A contract with an owner.
 * @notice Contract ownership is transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /**
     * @dev Owned Constructor
     * @param _owner The initial owner of the contract.
     */
    constructor(address _owner)
        public
    {
        require(_owner != address(0), "Null owner address.");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     * @param _owner The new owner to be nominated.
     */
    function nominateNewOwner(address _owner)
        public
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
        require(msg.sender == nominatedOwner, "Not nominated.");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

/*
-----------------------------------------------------------------------------
MIT License

Copyright (c) 2018 Havven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-----------------------------------------------------------------------------
*/
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Pausable.sol
version:    0.8
date:       2018-10-5
author:     Anton Jurisevic

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract allows inheritors to be paused and unpaused by
itself or its owner. It offers modifiers allowing decorated functions
to operate only if the contract is paused or unpaused as
according to need.

The inheriting contract must itself inherit from Owned,
and initialise it.

-----------------------------------------------------------------
*/






/**
 * @title A pausable contract.
 * @dev The inheriting contract must itself inherit from Owned, and initialise it.
 */
contract Pausable is Owned {

    bool public paused;
    
    /**
     * @dev Internal `pause()` with no owner-only constraint.
     */
    function _pause()
        internal
    {
        if (!paused) {
            paused = true;
            emit Paused();
        }
    }

    /**
     * @notice Pause operations of the contract.
     * @dev Functions modified with `onlyUnpaused` will cease to operate,
     *      while functions with `onlyPaused` will start operating.
     *      If this is called while the contract is paused, nothing will happen. 
     */
    function pause() 
        public
        onlyOwner
    {
        _pause();
    }

    /**
     * @dev Internal `unpause()` with no owner-only constraint.
     */
    function _unpause()
        internal
    {
        if (paused) {
            paused = false;
            emit Unpaused();
        }
    }

    /**
     * @notice Unpause operations of the contract.
     * @dev Functions modified with `onlyPaused` will cease to operate,
     *      while functions with `onlyUnpaused` will start operating.
     *      If this is called while the contract is unpaused, nothing will happen. 
     */
    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }

    modifier onlyPaused {
        require(paused, "Contract must be paused.");
        _;
    }

    modifier pausable {
        require(!paused, "Contract must not be paused.");
        _;
    }

    event Paused();
    event Unpaused();

}
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SelfDestructible.sol
version:    1.2
date:       2018-05-29
author:     Anton Jurisevic

auditors: Sigma Prime, https://github.com/sigp/havven-audit
          BlocTrax, https://havven.io/uploads/havven_bloctrax_security_audit_june-6th.pdf

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract allows an inheriting contract to be destroyed after
its owner indicates an intention and then waits for a period
without changing their mind. All ether contained in the contract
is forwarded to a nominated beneficiary upon destruction.

The inheriting contract must itself inherit from Owned, and
initialise it.

-----------------------------------------------------------------
*/






/**
 * @title This contract can be destroyed by its owner after a delay elapses.
 * @dev The inheriting contract must itself inherit from Owned, and initialise it.
 */
contract SelfDestructible is Owned {

    uint public selfDestructInitiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;

    /**
     * @dev Constructor
     * @param _beneficiary The account which will receive ether upon self-destruct.
     */
    constructor(address _beneficiary)
        public
    {
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

    /**
     * @notice Set the beneficiary address of this contract.
     * @dev Only the contract owner may call this. The provided beneficiary must be non-null.
     * @param _beneficiary The address to pay any eth contained in this contract to upon self-destruction.
     */
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be the zero address.");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

    /**
     * @notice Begin the self-destruction counter of this contract.
     * Once the delay has elapsed, the contract may be self-destructed.
     * @dev Only the contract owner may call this, and only if self-destruct has not been initiated.
     */
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        require(!selfDestructInitiated, "Self-destruct already initiated.");
        selfDestructInitiationTime = now;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }

    /**
     * @notice Terminate and reset the self-destruction timer.
     * @dev Only the contract owner may call this, and only during self-destruction.
     */
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self-destruct not yet initiated.");
        selfDestructInitiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

    /**
     * @notice If the self-destruction delay has elapsed, destroy this contract and
     * remit any ether it owns to the beneficiary address.
     * @dev Only the contract owner may call this.
     */
    function selfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self-destruct not yet initiated.");
        require(selfDestructInitiationTime + SELFDESTRUCT_DELAY < now, "Self-destruct delay has not yet elapsed.");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}

/*
-----------------------------------------------------------------------------
MIT License

Copyright (c) 2018 Havven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-----------------------------------------------------------------------------
*/


/**
 * @title The PlayChip token contract.
 * @notice This token contract has an owner, who can pause or
 *         self-destruct it after a delay. Transfers will be disabled
 *         except from the contract itself while it is paused, unless it is
 *         self-destructing.
 * @dev The contract starts paused and must be unpaused before it will operate.
 */
contract PlayChip is ERC20Token, Owned, Pausable, SelfDestructible {

    /**
     * @param _totalSupply The initial supply of tokens, which will be given to
     *                     the initial owner of the contract. This quantity is
     *                     a fixed-point integer with 18 decimal places (wei).
     * @param _owner The initial owner of the contract, who must unpause the contract
     *               before it can be used, but may use the `initBatchTransfer` to disburse
     *               funds to initial token holders before unpausing it.
     */
    constructor(uint _totalSupply, address _owner)
        Owned(_owner)
        Pausable()
        SelfDestructible(_owner)
        public
    {
        _pause();
        name = "PlayChip";
        symbol = "PLA";
        decimals = 18;
        totalSupply = _totalSupply;
        balanceOf[this] = totalSupply;
        emit Transfer(address(0), this, totalSupply);
    }


    /* ========== MODIFIERS AND UTILITIES ========== */

    modifier requireSameLength(uint a, uint b) {
        require(a == b, "Input array lengths differ.");
        _;
    }

    /* Although we could have merged SelfDestructible and Pausable, this
     * modifier keeps those contracts decoupled. */
    modifier pausableIfNotSelfDestructing {
        require(!paused || selfDestructInitiated, "Contract must not be paused.");
        _;
    }

    /**
     * @dev Returns the difference of the given arguments. Will throw an exception iff `x < y`.
     * @return `y` subtracted from `x`.
     */
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x, "Safe sub failed.");
        return x - y;
    }


    /* ========== ERC20 FUNCTIONS ========== */

    /**
     * @notice Transfers `quantity` tokens from `from` to `to`.
     * @dev Throws an exception if the balance owned by the `from` address is less than `quantity`, or if
     *      the transfer is to the 0x0 address, in case it was the result of an omitted argument.
     * @param from The spender.
     * @param to The recipient.
     * @param quantity The quantity to transfer, in wei.
     * @return Always returns true if no exception was thrown.
     */
    function _transfer(address from, address to, uint quantity)
        internal
        returns (bool)
    {
        require(to != address(0), "Transfers to 0x0 disallowed.");
        balanceOf[from] = safeSub(balanceOf[from], quantity); // safeSub handles insufficient balance.
        balanceOf[to] += quantity;
        emit Transfer(from, to, quantity);
        return true;

        /* Since balances are only manipulated here, and the sum of all
         * balances is preserved, no balance is greater than
         * totalSupply; the safeSub implies that balanceOf[to] + quantity is
         * no greater than totalSupply.
         * Thus a safeAdd is unnecessary, since overflow is impossible. */
    }

    /**
      * @notice ERC20 transfer function; transfers `quantity` tokens from the message sender to `to`.
      * @param to The recipient.
      * @param quantity The quantity to transfer, in wei.
      * @dev Exceptional conditions:
      *          * The contract is paused if it is not self-destructing.
      *          * The sender&#39;s balance is less than the transfer quantity.
      *          * The `to` parameter is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function transfer(address to, uint quantity)
        public
        pausableIfNotSelfDestructing
        returns (bool)
    {
        return _transfer(msg.sender, to, quantity);
    }

    /**
     * @notice ERC20 approve function; approves `spender` to transfer up to `quantity` tokens on the sender&#39;s behalf.
     * @param spender The approvee.
     * @param quantity The maximum spend quantity in wei; overwrites any existing quantity.
     * @dev Throws an exception if the contract is paused if it is not self-destructing, or if `spender` is 0x0.
     * @return Always returns true.
     */
    function approve(address spender, uint quantity)
        public
        pausableIfNotSelfDestructing
        returns (bool)
    {
        require(spender != address(0), "Approvals for 0x0 disallowed.");
        allowance[msg.sender][spender] = quantity;
        emit Approval(msg.sender, spender, quantity);
        return true;
    }

    /**
      * @notice ERC20 transferFrom function; transfers `quantity` tokens from
      *         `from` to `to` if the sender is approved.
      * @param from The spender; balance is deducted from this account.
      * @param to The recipient.
      * @param quantity The quantity to transfer, in wei.
      * @dev Exceptional conditions:
      *          * The contract is paused if it is not self-destructing.
      *          * The `from` account has approved the sender to spend less than the transfer quantity.
      *          * The `from` account&#39;s balance is less than the transfer quantity.
      *          * The `to` parameter is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function transferFrom(address from, address to, uint quantity)
        public
        pausableIfNotSelfDestructing
        returns (bool)
    {
        // safeSub handles insufficient allowance.
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], quantity);
        return _transfer(from, to, quantity);
    }


    /* ========== BATCHED ERC20 FUNCTIONS ========== */

    /**
      * @notice Performs ERC20 transfers in batches; for each `i`,
      *         transfers `quantity[i]` tokens from the message sender to `to[i]`.
      * @param recipients An array of recipients.
      * @param quantities A corresponding array of transfer quantities, in wei.
      * @dev Exceptional conditions:
      *          * The `recipients` and `quantities` arrays differ in length.
      *          * The sender&#39;s balance is less than the transfer quantity.
      *          * Any recipient is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function _batchTransfer(address sender, address[] recipients, uint[] quantities)
        internal
        requireSameLength(recipients.length, quantities.length)
        returns (bool)
    {
        uint length = recipients.length;
        for (uint i = 0; i < length; i++) {
            _transfer(sender, recipients[i], quantities[i]);
        }
        return true;
    }

    /**
      * @notice Performs ERC20 transfers in batches; for each `i`,
      *         transfers `quantities[i]` tokens from the message sender to `recipients[i]`.
      * @param recipients An array of recipients.
      * @param quantities A corresponding array of transfer quantities, in wei.
      * @dev Exceptional conditions:
      *          * The contract is paused if it is not self-destructing.
      *          * The `recipients` and `quantities` arrays differ in length.
      *          * The sender&#39;s balance is less than the transfer quantity.
      *          * Any recipient is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function batchTransfer(address[] recipients, uint[] quantities)
        external
        pausableIfNotSelfDestructing
        returns (bool)
    {
        return _batchTransfer(msg.sender, recipients, quantities);
    }

    /**
      * @notice Performs ERC20 approvals in batches; for each `i`,
      *         approves `quantities[i]` tokens to be spent by `spenders[i]`
      *         on behalf of the message sender.
      * @param spenders An array of spenders.
      * @param quantities A corresponding array of approval quantities, in wei.
      * @dev Exceptional conditions:
      *          * The contract is paused if it is not self-destructing.
      *          * The `spenders` and `quantities` arrays differ in length.
      *          * Any spender is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function batchApprove(address[] spenders, uint[] quantities)
        external
        pausableIfNotSelfDestructing
        requireSameLength(spenders.length, quantities.length)
        returns (bool)
    {
        uint length = spenders.length;
        for (uint i = 0; i < length; i++) {
            approve(spenders[i], quantities[i]);
        }
        return true;
    }

    /**
      * @notice Performs ERC20 transferFroms in batches; for each `i`,
      *         transfers `quantities[i]` tokens from `spenders[i]` to `recipients[i]`
      *         if the sender is approved.
      * @param spenders An array of spenders.
      * @param recipients An array of recipients.
      * @param quantities A corresponding array of transfer quantities, in wei.
      * @dev For the common use cases of transferring from many spenders to one recipient or vice versa,
      *      the sole spender or recipient must be duplicated in the input array.
      *      Exceptional conditions:
      *          * The contract is paused if it is not self-destructing.
      *          * Any of the `spenders`, `recipients`, or `quantities` arrays differ in length.
      *          * Any spender account has approved the sender to spend less than the transfer quantity.
      *          * Any spender account&#39;s balance is less than its corresponding transfer quantity.
      *          * Any recipient is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function batchTransferFrom(address[] spenders, address[] recipients, uint[] quantities)
        external
        pausableIfNotSelfDestructing
        requireSameLength(spenders.length, recipients.length)
        requireSameLength(recipients.length, quantities.length)
        returns (bool)
    {
        uint length = spenders.length;
        for (uint i = 0; i < length; i++) {
            transferFrom(spenders[i], recipients[i], quantities[i]);
        }
        return true;
    }


    /* ========== ADMINISTRATION FUNCTIONS ========== */

    /**
      * @notice Performs ERC20 transfers from the contract address in batches; for each `i`,
      *         transfers `quantities[i]` tokens from the contract to `recipients[i]`.
      *         Allows the owner to perform transfers while the contract is paused.
      *         Intended mainly to be used to disburse funds immediately after deployment.
      * @param recipients An array of recipients.
      * @param quantities A corresponding array of transfer quantities, in wei.
      * @dev Exceptional conditions:
      *          * The sender is not the contract&#39;s owner.
      *          * The `recipients` and `quantities` arrays differ in length.
      *          * The contract&#39;s balance is less than the transfer quantity.
      *          * Any recipient is 0x0.
      * @return Always returns true if no exception was thrown.
      */
    function contractBatchTransfer(address[] recipients, uint[] quantities)
        external
        onlyOwner
        returns (bool)
    {
        return _batchTransfer(this, recipients, quantities);
    }

}