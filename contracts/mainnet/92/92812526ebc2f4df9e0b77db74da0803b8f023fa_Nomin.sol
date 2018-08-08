/*
 * Nomin Contract
 *
 * The stable exchange token of the Havven stablecoin system.
 *
 * version: nUSDa.1
 * date: 29 Jun 2018
 * url: https://github.com/Havven/havven/releases/tag/nUSDa.1
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2018 Havven
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
 
 
pragma solidity 0.4.24;
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       SafeDecimalMath.sol
version:    1.0
author:     Anton Jurisevic
 
date:       2018-2-5
 
checked:    Mike Spain
approved:   Samuel Brooks
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
A fixed point decimal library that provides basic mathematical
operations, and checks for unsafe arguments, for example that
would lead to overflows.
 
Exceptions are thrown whenever those unsafe operations
occur.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals (including fiat, ether, and nomin quantities).
 */
contract SafeDecimalMath {
 
    /* Number of decimal places in the representation. */
    uint8 public constant decimals = 18;
 
    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);
 
    /**
     * @return True iff adding x and y will not overflow.
     */
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }
 
    /**
     * @return The result of adding x and y, throwing an exception in case of overflow.
     */
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y);
        return x + y;
    }
 
    /**
     * @return True iff subtracting y from x will not overflow in the negative direction.
     */
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }
 
    /**
     * @return The result of subtracting y from x, throwing an exception in case of overflow.
     */
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x);
        return x - y;
    }
 
    /**
     * @return True iff multiplying x and y would not overflow.
     */
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }
 
    /**
     * @return The result of multiplying x and y, throwing an exception in case of overflow.
     */
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y);
        return p;
    }
 
    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals. Throws an exception in case of overflow.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256.
     * Incidentally, the internal division always rounds down: one could have rounded to the nearest integer,
     * but then one would be spending a significant fraction of a cent (of order a microether
     * at present gas prices) in order to save less than one part in 0.5 * 10^18 per operation, if the operands
     * contain small enough fractional components. It would also marginally diminish the
     * domain this function is defined upon.
     */
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return safeMul(x, y) / UNIT;
 
    }
 
    /**
     * @return True iff the denominator of x/y is nonzero.
     */
    function divIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }
 
    /**
     * @return The result of dividing x by y, throwing an exception if the divisor is zero.
     */
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Although a 0 denominator already throws an exception,
         * it is equivalent to a THROW operation, which consumes all gas.
         * A require statement emits REVERT instead, which remits remaining gas. */
        require(y != 0);
        return x / y;
    }
 
    /**
     * @return The result of dividing x by y, interpreting the operands as fixed point decimal numbers.
     * @dev Throws an exception in case of overflow or zero divisor; x must be less than 2^256 / UNIT.
     * Internal rounding is downward: a similar caveat holds as with safeDecMul().
     */
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return safeDiv(safeMul(x, UNIT), y);
    }
 
    /**
     * @dev Convert an unsigned integer to a unsigned fixed-point decimal.
     * Throw an exception if the result would be out of range.
     */
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
    }
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
 
file:       SelfDestructible.sol
version:    1.2
author:     Anton Jurisevic
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
This contract allows an inheriting contract to be destroyed after
its owner indicates an intention and then waits for a period
without changing their mind. All ether contained in the contract
is forwarded to a nominated beneficiary upon destruction.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title A contract that can be destroyed by its owner after a delay elapses.
 */
contract SelfDestructible is Owned {
     
    uint public initiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;
 
    /**
     * @dev Constructor
     * @param _owner The account which controls this contract.
     */
    constructor(address _owner)
        Owned(_owner)
        public
    {
        require(_owner != address(0));
        selfDestructBeneficiary = _owner;
        emit SelfDestructBeneficiaryUpdated(_owner);
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
        require(_beneficiary != address(0));
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }
 
    /**
     * @notice Begin the self-destruction counter of this contract.
     * Once the delay has elapsed, the contract may be self-destructed.
     * @dev Only the contract owner may call this.
     */
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = now;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }
 
    /**
     * @notice Terminate and reset the self-destruction timer.
     * @dev Only the contract owner may call this.
     */
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = 0;
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
        require(selfDestructInitiated && initiationTime + SELFDESTRUCT_DELAY < now);
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
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       Proxy.sol
version:    1.3
author:     Anton Jurisevic
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
A proxy contract that, if it does not recognise the function
being called on it, passes all value and call data to an
underlying target contract.
 
This proxy has the capacity to toggle between DELEGATECALL
and CALL style proxy functionality.
 
The former executes in the proxy&#39;s context, and so will preserve
msg.sender and store data at the proxy address. The latter will not.
Therefore, any contract the proxy wraps in the CALL style must
implement the Proxyable interface, in order that it can pass msg.sender
into the underlying contract as the state parameter, messageSender.
 
-----------------------------------------------------------------
*/
 
 
contract Proxy is Owned {
 
    Proxyable public target;
    bool public useDELEGATECALL;
 
    constructor(address _owner)
        Owned(_owner)
        public
    {}
 
    function setTarget(Proxyable _target)
        external
        onlyOwner
    {
        target = _target;
        emit TargetUpdated(_target);
    }
 
    function setUseDELEGATECALL(bool value)
        external
        onlyOwner
    {
        useDELEGATECALL = value;
    }
 
    function _emit(bytes callData, uint numTopics,
                   bytes32 topic1, bytes32 topic2,
                   bytes32 topic3, bytes32 topic4)
        external
        onlyTarget
    {
        uint size = callData.length;
        bytes memory _callData = callData;
 
        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            }
            case 1 {
                log1(add(_callData, 32), size, topic1)
            }
            case 2 {
                log2(add(_callData, 32), size, topic1, topic2)
            }
            case 3 {
                log3(add(_callData, 32), size, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
            }
        }
    }
 
    function()
        external
        payable
    {
        if (useDELEGATECALL) {
            assembly {
                /* Copy call data into free memory region. */
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)
 
                /* Forward all gas and call data to the target contract. */
                let result := delegatecall(gas, sload(target_slot), free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)
 
                /* Revert if the call failed, otherwise return the result. */
                if iszero(result) { revert(free_ptr, returndatasize) }
                return(free_ptr, returndatasize)
            }
        } else {
            /* Here we are as above, but must send the messageSender explicitly
             * since we are using CALL rather than DELEGATECALL. */
            target.setMessageSender(msg.sender);
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)
 
                /* We must explicitly forward ether to the underlying contract as well. */
                let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)
 
                if iszero(result) { revert(free_ptr, returndatasize) }
                return(free_ptr, returndatasize)
            }
        }
    }
 
    modifier onlyTarget {
        require(Proxyable(msg.sender) == target);
        _;
    }
 
    event TargetUpdated(Proxyable newTarget);
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       Proxyable.sol
version:    1.1
author:     Anton Jurisevic
 
date:       2018-05-15
 
checked:    Mike Spain
approved:   Samuel Brooks
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
A proxyable contract that works hand in hand with the Proxy contract
to allow for anyone to interact with the underlying contract both
directly and through the proxy.
 
-----------------------------------------------------------------
*/
 
 
// This contract should be treated like an abstract contract
contract Proxyable is Owned {
    /* The proxy this contract exists behind. */
    Proxy public proxy;
 
    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address messageSender;
 
    constructor(address _proxy, address _owner)
        Owned(_owner)
        public
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }
 
    function setProxy(address _proxy)
        external
        onlyOwner
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }
 
    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }
 
    modifier onlyProxy {
        require(Proxy(msg.sender) == proxy);
        _;
    }
 
    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }
 
    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner);
        _;
    }
 
    event ProxyUpdated(address proxyAddress);
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       ExternStateToken.sol
version:    1.3
author:     Anton Jurisevic
            Dominic Romanowski
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
A partial ERC20 token contract, designed to operate with a proxy.
To produce a complete ERC20 token, transfer and transferFrom
tokens must be implemented, using the provided _byProxy internal
functions.
This contract utilises an external state for upgradeability.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title ERC20 Token contract, with detached state and designed to operate behind a proxy.
 */
contract ExternStateToken is SafeDecimalMath, SelfDestructible, Proxyable {
 
    /* ========== STATE VARIABLES ========== */
 
    /* Stores balances and allowances. */
    TokenState public tokenState;
 
    /* Other ERC20 fields.
     * Note that the decimals field is defined in SafeDecimalMath.*/
    string public name;
    string public symbol;
    uint public totalSupply;
 
    /**
     * @dev Constructor.
     * @param _proxy The proxy associated with this contract.
     * @param _name Token&#39;s ERC20 name.
     * @param _symbol Token&#39;s ERC20 symbol.
     * @param _totalSupply The total supply of the token.
     * @param _tokenState The TokenState contract address.
     * @param _owner The owner of this contract.
     */
    constructor(address _proxy, TokenState _tokenState,
                string _name, string _symbol, uint _totalSupply,
                address _owner)
        SelfDestructible(_owner)
        Proxyable(_proxy, _owner)
        public
    {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        tokenState = _tokenState;
   }
 
    /* ========== VIEWS ========== */
 
    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner&#39;s funds.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return tokenState.allowance(owner, spender);
    }
 
    /**
     * @notice Returns the ERC20 token balance of a given account.
     */
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return tokenState.balanceOf(account);
    }
 
    /* ========== MUTATIVE FUNCTIONS ========== */
 
    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(TokenState _tokenState)
        external
        optionalProxy_onlyOwner
    {
        tokenState = _tokenState;
        emitTokenStateUpdated(_tokenState);
    }
 
    function _internalTransfer(address from, address to, uint value)
        internal
        returns (bool)
    {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0));
        require(to != address(this));
        require(to != address(proxy));
 
        /* Insufficient balance will be handled by the safe subtraction. */
        tokenState.setBalanceOf(from, safeSub(tokenState.balanceOf(from), value));
        tokenState.setBalanceOf(to, safeAdd(tokenState.balanceOf(to), value));
 
        emitTransfer(from, to, value);
 
        return true;
    }
 
    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transfer_byProxy(address from, address to, uint value)
        internal
        returns (bool)
    {
        return _internalTransfer(from, to, value);
    }
 
    /**
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(from, sender, safeSub(tokenState.allowance(from, sender), value));
        return _internalTransfer(from, to, value);
    }
 
    /**
     * @notice Approves spender to transfer on the message sender&#39;s behalf.
     */
    function approve(address spender, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
 
        tokenState.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }
 
    /* ========== EVENTS ========== */
 
    event Transfer(address indexed from, address indexed to, uint value);
    bytes32 constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");
    function emitTransfer(address from, address to, uint value) internal {
        proxy._emit(abi.encode(value), 3, TRANSFER_SIG, bytes32(from), bytes32(to), 0);
    }
 
    event Approval(address indexed owner, address indexed spender, uint value);
    bytes32 constant APPROVAL_SIG = keccak256("Approval(address,address,uint256)");
    function emitApproval(address owner, address spender, uint value) internal {
        proxy._emit(abi.encode(value), 3, APPROVAL_SIG, bytes32(owner), bytes32(spender), 0);
    }
 
    event TokenStateUpdated(address newTokenState);
    bytes32 constant TOKENSTATEUPDATED_SIG = keccak256("TokenStateUpdated(address)");
    function emitTokenStateUpdated(address newTokenState) internal {
        proxy._emit(abi.encode(newTokenState), 1, TOKENSTATEUPDATED_SIG, 0, 0, 0);
    }
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       FeeToken.sol
version:    1.3
author:     Anton Jurisevic
            Dominic Romanowski
            Kevin Brown
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
A token which also has a configurable fee rate
charged on its transfers. This is designed to be overridden in
order to produce an ERC20-compliant token.
 
These fees accrue into a pool, from which a nominated authority
may withdraw.
 
This contract utilises an external state for upgradeability.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title ERC20 Token contract, with detached state.
 * Additionally charges fees on each transfer.
 */
contract FeeToken is ExternStateToken {
 
    /* ========== STATE VARIABLES ========== */
 
    /* ERC20 members are declared in ExternStateToken. */
 
    /* A percentage fee charged on each transfer. */
    uint public transferFeeRate;
    /* Fee may not exceed 10%. */
    uint constant MAX_TRANSFER_FEE_RATE = UNIT / 10;
    /* The address with the authority to distribute fees. */
    address public feeAuthority;
    /* The address that fees will be pooled in. */
    address public constant FEE_ADDRESS = 0xfeefeefeefeefeefeefeefeefeefeefeefeefeef;
 
 
    /* ========== CONSTRUCTOR ========== */
 
    /**
     * @dev Constructor.
     * @param _proxy The proxy associated with this contract.
     * @param _name Token&#39;s ERC20 name.
     * @param _symbol Token&#39;s ERC20 symbol.
     * @param _totalSupply The total supply of the token.
     * @param _transferFeeRate The fee rate to charge on transfers.
     * @param _feeAuthority The address which has the authority to withdraw fees from the accumulated pool.
     * @param _owner The owner of this contract.
     */
    constructor(address _proxy, TokenState _tokenState, string _name, string _symbol, uint _totalSupply,
                uint _transferFeeRate, address _feeAuthority, address _owner)
        ExternStateToken(_proxy, _tokenState,
                         _name, _symbol, _totalSupply,
                         _owner)
        public
    {
        feeAuthority = _feeAuthority;
 
        /* Constructed transfer fee rate should respect the maximum fee rate. */
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE);
        transferFeeRate = _transferFeeRate;
    }
 
    /* ========== SETTERS ========== */
 
    /**
     * @notice Set the transfer fee, anywhere within the range 0-10%.
     * @dev The fee rate is in decimal format, with UNIT being the value of 100%.
     */
    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE);
        transferFeeRate = _transferFeeRate;
        emitTransferFeeRateUpdated(_transferFeeRate);
    }
 
    /**
     * @notice Set the address of the user/contract responsible for collecting or
     * distributing fees.
     */
    function setFeeAuthority(address _feeAuthority)
        public
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;
        emitFeeAuthorityUpdated(_feeAuthority);
    }
 
    /* ========== VIEWS ========== */
 
    /**
     * @notice Calculate the Fee charged on top of a value being sent
     * @return Return the fee charged
     */
    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return safeMul_dec(value, transferFeeRate);
        /* Transfers less than the reciprocal of transferFeeRate should be completely eaten up by fees.
         * This is on the basis that transfers less than this value will result in a nil fee.
         * Probably too insignificant to worry about, but the following code will achieve it.
         *      if (fee == 0 && transferFeeRate != 0) {
         *          return _value;
         *      }
         *      return fee;
         */
    }
 
    /**
     * @notice The value that you would need to send so that the recipient receives
     * a specified value.
     */
    function transferPlusFee(uint value)
        external
        view
        returns (uint)
    {
        return safeAdd(value, transferFeeIncurred(value));
    }
 
    /**
     * @notice The amount the recipient will receive if you send a certain number of tokens.
     */
    function amountReceived(uint value)
        public
        view
        returns (uint)
    {
        return safeDiv_dec(value, safeAdd(UNIT, transferFeeRate));
    }
 
    /**
     * @notice Collected fees sit here until they are distributed.
     * @dev The balance of the nomin contract itself is the fee pool.
     */
    function feePool()
        external
        view
        returns (uint)
    {
        return tokenState.balanceOf(FEE_ADDRESS);
    }
 
    /* ========== MUTATIVE FUNCTIONS ========== */
 
    /**
     * @notice Base of transfer functions
     */
    function _internalTransfer(address from, address to, uint amount, uint fee)
        internal
        returns (bool)
    {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0));
        require(to != address(this));
        require(to != address(proxy));
 
        /* Insufficient balance will be handled by the safe subtraction. */
        tokenState.setBalanceOf(from, safeSub(tokenState.balanceOf(from), safeAdd(amount, fee)));
        tokenState.setBalanceOf(to, safeAdd(tokenState.balanceOf(to), amount));
        tokenState.setBalanceOf(FEE_ADDRESS, safeAdd(tokenState.balanceOf(FEE_ADDRESS), fee));
 
        /* Emit events for both the transfer itself and the fee. */
        emitTransfer(from, to, amount);
        emitTransfer(from, FEE_ADDRESS, fee);
 
        return true;
    }
 
    /**
     * @notice ERC20 friendly transfer function.
     */
    function _transfer_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        uint received = amountReceived(value);
        uint fee = safeSub(value, received);
 
        return _internalTransfer(sender, to, received, fee);
    }
 
    /**
     * @notice ERC20 friendly transferFrom function.
     */
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        /* The fee is deducted from the amount sent. */
        uint received = amountReceived(value);
        uint fee = safeSub(value, received);
 
        /* Reduce the allowance by the amount we&#39;re transferring.
         * The safeSub call will handle an insufficient allowance. */
        tokenState.setAllowance(from, sender, safeSub(tokenState.allowance(from, sender), value));
 
        return _internalTransfer(from, to, received, fee);
    }
 
    /**
     * @notice Ability to transfer where the sender pays the fees (not ERC20)
     */
    function _transferSenderPaysFee_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        /* The fee is added to the amount sent. */
        uint fee = transferFeeIncurred(value);
        return _internalTransfer(sender, to, value, fee);
    }
 
    /**
     * @notice Ability to transferFrom where they sender pays the fees (not ERC20).
     */
    function _transferFromSenderPaysFee_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        /* The fee is added to the amount sent. */
        uint fee = transferFeeIncurred(value);
        uint total = safeAdd(value, fee);
 
        /* Reduce the allowance by the amount we&#39;re transferring. */
        tokenState.setAllowance(from, sender, safeSub(tokenState.allowance(from, sender), total));
 
        return _internalTransfer(from, to, value, fee);
    }
 
    /**
     * @notice Withdraw tokens from the fee pool into a given account.
     * @dev Only the fee authority may call this.
     */
    function withdrawFees(address account, uint value)
        external
        onlyFeeAuthority
        returns (bool)
    {
        require(account != address(0));
 
        /* 0-value withdrawals do nothing. */
        if (value == 0) {
            return false;
        }
 
        /* Safe subtraction ensures an exception is thrown if the balance is insufficient. */
        tokenState.setBalanceOf(FEE_ADDRESS, safeSub(tokenState.balanceOf(FEE_ADDRESS), value));
        tokenState.setBalanceOf(account, safeAdd(tokenState.balanceOf(account), value));
 
        emitFeesWithdrawn(account, value);
        emitTransfer(FEE_ADDRESS, account, value);
 
        return true;
    }
 
    /**
     * @notice Donate tokens from the sender&#39;s balance into the fee pool.
     */
    function donateToFeePool(uint n)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        /* Empty donations are disallowed. */
        uint balance = tokenState.balanceOf(sender);
        require(balance != 0);
 
        /* safeSub ensures the donor has sufficient balance. */
        tokenState.setBalanceOf(sender, safeSub(balance, n));
        tokenState.setBalanceOf(FEE_ADDRESS, safeAdd(tokenState.balanceOf(FEE_ADDRESS), n));
 
        emitFeesDonated(sender, n);
        emitTransfer(sender, FEE_ADDRESS, n);
 
        return true;
    }
 
 
    /* ========== MODIFIERS ========== */
 
    modifier onlyFeeAuthority
    {
        require(msg.sender == feeAuthority);
        _;
    }
 
 
    /* ========== EVENTS ========== */
 
    event TransferFeeRateUpdated(uint newFeeRate);
    bytes32 constant TRANSFERFEERATEUPDATED_SIG = keccak256("TransferFeeRateUpdated(uint256)");
    function emitTransferFeeRateUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, TRANSFERFEERATEUPDATED_SIG, 0, 0, 0);
    }
 
    event FeeAuthorityUpdated(address newFeeAuthority);
    bytes32 constant FEEAUTHORITYUPDATED_SIG = keccak256("FeeAuthorityUpdated(address)");
    function emitFeeAuthorityUpdated(address newFeeAuthority) internal {
        proxy._emit(abi.encode(newFeeAuthority), 1, FEEAUTHORITYUPDATED_SIG, 0, 0, 0);
    }
 
    event FeesWithdrawn(address indexed account, uint value);
    bytes32 constant FEESWITHDRAWN_SIG = keccak256("FeesWithdrawn(address,uint256)");
    function emitFeesWithdrawn(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, FEESWITHDRAWN_SIG, bytes32(account), 0, 0);
    }
 
    event FeesDonated(address indexed donor, uint value);
    bytes32 constant FEESDONATED_SIG = keccak256("FeesDonated(address,uint256)");
    function emitFeesDonated(address donor, uint value) internal {
        proxy._emit(abi.encode(value), 2, FEESDONATED_SIG, bytes32(donor), 0, 0);
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
        public
    {
        setupExpiryTime = now + setupDuration;
    }
 
    modifier onlyDuringSetup
    {
        require(now < setupExpiryTime);
        _;
    }
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       HavvenEscrow.sol
version:    1.1
author:     Anton Jurisevic
            Dominic Romanowski
            Mike Spain
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
This contract allows the foundation to apply unique vesting
schedules to havven funds sold at various discounts in the token
sale. HavvenEscrow gives users the ability to inspect their
vested funds, their quantities and vesting dates, and to withdraw
the fees that accrue on those funds.
 
The fees are handled by withdrawing the entire fee allocation
for all havvens inside the escrow contract, and then allowing
the contract itself to subdivide that pool up proportionally within
itself. Every time the fee period rolls over in the main Havven
contract, the HavvenEscrow fee pool is remitted back into the
main fee pool to be redistributed in the next fee period.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title A contract to hold escrowed havvens and free them at given schedules.
 */
contract HavvenEscrow is SafeDecimalMath, Owned, LimitedSetup(8 weeks) {
    /* The corresponding Havven contract. */
    Havven public havven;
 
    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of havvens vests. */
    mapping(address => uint[2][]) public vestingSchedules;
 
    /* An account&#39;s total vested havven balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalVestedAccountBalance;
 
    /* The total remaining vested balance, for verifying the actual havven balance of this contract against. */
    uint public totalVestedBalance;
 
    uint constant TIME_INDEX = 0;
    uint constant QUANTITY_INDEX = 1;
 
    /* Limit vesting entries to disallow unbounded iteration over vesting schedules. */
    uint constant MAX_VESTING_ENTRIES = 20;
 
 
    /* ========== CONSTRUCTOR ========== */
 
    constructor(address _owner, Havven _havven)
        Owned(_owner)
        public
    {
        havven = _havven;
    }
 
 
    /* ========== SETTERS ========== */
 
    function setHavven(Havven _havven)
        external
        onlyOwner
    {
        havven = _havven;
        emit HavvenUpdated(_havven);
    }
 
 
    /* ========== VIEW FUNCTIONS ========== */
 
    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return totalVestedAccountBalance[account];
    }
 
    /**
     * @notice The number of vesting dates in an account&#39;s schedule.
     */
    function numVestingEntries(address account)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account].length;
    }
 
    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, havven quantity).
     */
    function getVestingScheduleEntry(address account, uint index)
        public
        view
        returns (uint[2])
    {
        return vestingSchedules[account][index];
    }
 
    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index)
        public
        view
        returns (uint)
    {
        return getVestingScheduleEntry(account,index)[TIME_INDEX];
    }
 
    /**
     * @notice Get the quantity of havvens associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index)
        public
        view
        returns (uint)
    {
        return getVestingScheduleEntry(account,index)[QUANTITY_INDEX];
    }
 
    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account)
        public
        view
        returns (uint)
    {
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }
 
    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, havven quantity). */
    function getNextVestingEntry(address account)
        public
        view
        returns (uint[2])
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }
 
    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account)
        external
        view
        returns (uint)
    {
        return getNextVestingEntry(account)[TIME_INDEX];
    }
 
    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account)
        external
        view
        returns (uint)
    {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }
 
 
    /* ========== MUTATIVE FUNCTIONS ========== */
 
    /**
     * @notice Withdraws a quantity of havvens back to the havven contract.
     * @dev This may only be called by the owner during the contract&#39;s setup period.
     */
    function withdrawHavvens(uint quantity)
        external
        onlyOwner
        onlyDuringSetup
    {
        havven.transfer(havven, quantity);
    }
 
    /**
     * @notice Destroy the vesting information associated with an account.
     */
    function purgeAccount(address account)
        external
        onlyOwner
        onlyDuringSetup
    {
        delete vestingSchedules[account];
        totalVestedBalance = safeSub(totalVestedBalance, totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }
 
    /**
     * @notice Add a new vesting entry at a given time and quantity to an account&#39;s schedule.
     * @dev A call to this should be accompanied by either enough balance already available
     * in this contract, or a corresponding call to havven.endow(), to ensure that when
     * the funds are withdrawn, there is enough balance, as well as correctly calculating
     * the fees.
     * This may only be called by the owner during the contract&#39;s setup period.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it&#39;s only in the foundation&#39;s command to add to these lists.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of havvens that will vest.
     */
    function appendVestingEntry(address account, uint time, uint quantity)
        public
        onlyOwner
        onlyDuringSetup
    {
        /* No empty or already-passed vesting entries allowed. */
        require(now < time);
        require(quantity != 0);
 
        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalVestedBalance = safeAdd(totalVestedBalance, quantity);
        require(totalVestedBalance <= havven.balanceOf(this));
 
        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES);
 
        if (scheduleLength == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
            /* Disallow adding new vested havvens earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(getVestingTime(account, numVestingEntries(account) - 1) < time);
            totalVestedAccountBalance[account] = safeAdd(totalVestedAccountBalance[account], quantity);
        }
 
        vestingSchedules[account].push([time, quantity]);
    }
 
    /**
     * @notice Construct a vesting schedule to release a quantities of havvens
     * over a series of intervals.
     * @dev Assumes that the quantities are nonzero
     * and that the sequence of timestamps is strictly increasing.
     * This may only be called by the owner during the contract&#39;s setup period.
     */
    function addVestingSchedule(address account, uint[] times, uint[] quantities)
        external
        onlyOwner
        onlyDuringSetup
    {
        for (uint i = 0; i < times.length; i++) {
            appendVestingEntry(account, times[i], quantities[i]);
        }
 
    }
 
    /**
     * @notice Allow a user to withdraw any havvens in their schedule that have vested.
     */
    function vest()
        external
    {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty == 0) {
                continue;
            }
 
            vestingSchedules[msg.sender][i] = [0, 0];
            total = safeAdd(total, qty);
        }
 
        if (total != 0) {
            totalVestedBalance = safeSub(totalVestedBalance, total);
            totalVestedAccountBalance[msg.sender] = safeSub(totalVestedAccountBalance[msg.sender], total);
            havven.transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }
 
 
    /* ========== EVENTS ========== */
 
    event HavvenUpdated(address newHavven);
 
    event Vested(address indexed beneficiary, uint time, uint value);
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       Havven.sol
version:    1.2
author:     Anton Jurisevic
            Dominic Romanowski
 
date:       2018-05-15
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
Havven token contract. Havvens are transferable ERC20 tokens,
and also give their holders the following privileges.
An owner of havvens may participate in nomin confiscation votes, they
may also have the right to issue nomins at the discretion of the
foundation for this version of the contract.
 
After a fee period terminates, the duration and fees collected for that
period are computed, and the next period begins. Thus an account may only
withdraw the fees owed to them for the previous period, and may only do
so once per period. Any unclaimed fees roll over into the common pot for
the next period.
 
== Average Balance Calculations ==
 
The fee entitlement of a havven holder is proportional to their average
issued nomin balance over the last fee period. This is computed by
measuring the area under the graph of a user&#39;s issued nomin balance over
time, and then when a new fee period begins, dividing through by the
duration of the fee period.
 
We need only update values when the balances of an account is modified.
This occurs when issuing or burning for issued nomin balances,
and when transferring for havven balances. This is for efficiency,
and adds an implicit friction to interacting with havvens.
A havven holder pays for his own recomputation whenever he wants to change
his position, which saves the foundation having to maintain a pot dedicated
to resourcing this.
 
A hypothetical user&#39;s balance history over one fee period, pictorially:
 
      s ____
       |    |
       |    |___ p
       |____|___|___ __ _  _
       f    t   n
 
Here, the balance was s between times f and t, at which time a transfer
occurred, updating the balance to p, until n, when the present transfer occurs.
When a new transfer occurs at time n, the balance being p,
we must:
 
  - Add the area p * (n - t) to the total area recorded so far
  - Update the last transfer time to n
 
So if this graph represents the entire current fee period,
the average havvens held so far is ((t-f)*s + (n-t)*p) / (n-f).
The complementary computations must be performed for both sender and
recipient.
 
Note that a transfer keeps global supply of havvens invariant.
The sum of all balances is constant, and unmodified by any transfer.
So the sum of all balances multiplied by the duration of a fee period is also
constant, and this is equivalent to the sum of the area of every user&#39;s
time/balance graph. Dividing through by that duration yields back the total
havven supply. So, at the end of a fee period, we really do yield a user&#39;s
average share in the havven supply over that period.
 
A slight wrinkle is introduced if we consider the time r when the fee period
rolls over. Then the previous fee period k-1 is before r, and the current fee
period k is afterwards. If the last transfer took place before r,
but the latest transfer occurred afterwards:
 
k-1       |        k
      s __|_
       |  | |
       |  | |____ p
       |__|_|____|___ __ _  _
          |
       f  | t    n
          r
 
In this situation the area (r-f)*s contributes to fee period k-1, while
the area (t-r)*s contributes to fee period k. We will implicitly consider a
zero-value transfer to have occurred at time r. Their fee entitlement for the
previous period will be finalised at the time of their first transfer during the
current fee period, or when they query or withdraw their fee entitlement.
 
In the implementation, the duration of different fee periods may be slightly irregular,
as the check that they have rolled over occurs only when state-changing havven
operations are performed.
 
== Issuance and Burning ==
 
In this version of the havven contract, nomins can only be issued by
those that have been nominated by the havven foundation. Nomins are assumed
to be valued at $1, as they are a stable unit of account.
 
All nomins issued require a proportional value of havvens to be locked,
where the proportion is governed by the current issuance ratio. This
means for every $1 of Havvens locked up, $(issuanceRatio) nomins can be issued.
i.e. to issue 100 nomins, 100/issuanceRatio dollars of havvens need to be locked up.
 
To determine the value of some amount of havvens(H), an oracle is used to push
the price of havvens (P_H) in dollars to the contract. The value of H
would then be: H * P_H.
 
Any havvens that are locked up by this issuance process cannot be transferred.
The amount that is locked floats based on the price of havvens. If the price
of havvens moves up, less havvens are locked, so they can be issued against,
or transferred freely. If the price of havvens moves down, more havvens are locked,
even going above the initial wallet balance.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title Havven ERC20 contract.
 * @notice The Havven contracts does not only facilitate transfers and track balances,
 * but it also computes the quantity of fees each havven holder is entitled to.
 */
contract Havven is ExternStateToken {
 
    /* ========== STATE VARIABLES ========== */
 
    /* A struct for handing values associated with average balance calculations */
    struct IssuanceData {
        /* Sums of balances*duration in the current fee period.
        /* range: decimals; units: havven-seconds */
        uint currentBalanceSum;
        /* The last period&#39;s average balance */
        uint lastAverageBalance;
        /* The last time the data was calculated */
        uint lastModified;
    }
 
    /* Issued nomin balances for individual fee entitlements */
    mapping(address => IssuanceData) public issuanceData;
    /* The total number of issued nomins for determining fee entitlements */
    IssuanceData public totalIssuanceData;
 
    /* The time the current fee period began */
    uint public feePeriodStartTime;
    /* The time the last fee period began */
    uint public lastFeePeriodStartTime;
 
    /* Fee periods will roll over in no shorter a time than this.
     * The fee period cannot actually roll over until a fee-relevant
     * operation such as withdrawal or a fee period duration update occurs,
     * so this is just a target, and the actual duration may be slightly longer. */
    uint public feePeriodDuration = 4 weeks;
    /* ...and must target between 1 day and six months. */
    uint constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint constant MAX_FEE_PERIOD_DURATION = 26 weeks;
 
    /* The quantity of nomins that were in the fee pot at the time */
    /* of the last fee rollover, at feePeriodStartTime. */
    uint public lastFeesCollected;
 
    /* Whether a user has withdrawn their last fees */
    mapping(address => bool) public hasWithdrawnFees;
 
    Nomin public nomin;
    HavvenEscrow public escrow;
 
    /* The address of the oracle which pushes the havven price to this contract */
    address public oracle;
    /* The price of havvens written in UNIT */
    uint public price;
    /* The time the havven price was last updated */
    uint public lastPriceUpdateTime;
    /* How long will the contract assume the price of havvens is correct */
    uint public priceStalePeriod = 3 hours;
 
    /* A quantity of nomins greater than this ratio
     * may not be issued against a given value of havvens. */
    uint public issuanceRatio = UNIT / 5;
    /* No more nomins may be issued than the value of havvens backing them. */
    uint constant MAX_ISSUANCE_RATIO = UNIT;
 
    /* Whether the address can issue nomins or not. */
    mapping(address => bool) public isIssuer;
    /* The number of currently-outstanding nomins the user has issued. */
    mapping(address => uint) public nominsIssued;
 
    uint constant HAVVEN_SUPPLY = 1e8 * UNIT;
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;
    string constant TOKEN_NAME = "Havven";
    string constant TOKEN_SYMBOL = "HAV";
     
    /* ========== CONSTRUCTOR ========== */
 
    /**
     * @dev Constructor
     * @param _tokenState A pre-populated contract containing token balances.
     * If the provided address is 0x0, then a fresh one will be constructed with the contract owning all tokens.
     * @param _owner The owner of this contract.
     */
    constructor(address _proxy, TokenState _tokenState, address _owner, address _oracle,
                uint _price, address[] _issuers, Havven _oldHavven)
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, HAVVEN_SUPPLY, _owner)
        public
    {
        oracle = _oracle;
        price = _price;
        lastPriceUpdateTime = now;
 
        uint i;
        if (_oldHavven == address(0)) {
            feePeriodStartTime = now;
            lastFeePeriodStartTime = now - feePeriodDuration;
            for (i = 0; i < _issuers.length; i++) {
                isIssuer[_issuers[i]] = true;
            }
        } else {
            feePeriodStartTime = _oldHavven.feePeriodStartTime();
            lastFeePeriodStartTime = _oldHavven.lastFeePeriodStartTime();
 
            uint cbs;
            uint lab;
            uint lm;
            (cbs, lab, lm) = _oldHavven.totalIssuanceData();
            totalIssuanceData.currentBalanceSum = cbs;
            totalIssuanceData.lastAverageBalance = lab;
            totalIssuanceData.lastModified = lm;
 
            for (i = 0; i < _issuers.length; i++) {
                address issuer = _issuers[i];
                isIssuer[issuer] = true;
                uint nomins = _oldHavven.nominsIssued(issuer);
                if (nomins == 0) {
                    // It is not valid in general to skip those with no currently-issued nomins.
                    // But for this release, issuers with nonzero issuanceData have current issuance.
                    continue;
                }
                (cbs, lab, lm) = _oldHavven.issuanceData(issuer);
                nominsIssued[issuer] = nomins;
                issuanceData[issuer].currentBalanceSum = cbs;
                issuanceData[issuer].lastAverageBalance = lab;
                issuanceData[issuer].lastModified = lm;
            }
        }
 
    }
 
    /* ========== SETTERS ========== */
 
    /**
     * @notice Set the associated Nomin contract to collect fees from.
     * @dev Only the contract owner may call this.
     */
    function setNomin(Nomin _nomin)
        external
        optionalProxy_onlyOwner
    {
        nomin = _nomin;
        emitNominUpdated(_nomin);
    }
 
    /**
     * @notice Set the associated havven escrow contract.
     * @dev Only the contract owner may call this.
     */
    function setEscrow(HavvenEscrow _escrow)
        external
        optionalProxy_onlyOwner
    {
        escrow = _escrow;
        emitEscrowUpdated(_escrow);
    }
 
    /**
     * @notice Set the targeted fee period duration.
     * @dev Only callable by the contract owner. The duration must fall within
     * acceptable bounds (1 day to 26 weeks). Upon resetting this the fee period
     * may roll over if the target duration was shortened sufficiently.
     */
    function setFeePeriodDuration(uint duration)
        external
        optionalProxy_onlyOwner
    {
        require(MIN_FEE_PERIOD_DURATION <= duration &&
                               duration <= MAX_FEE_PERIOD_DURATION);
        feePeriodDuration = duration;
        emitFeePeriodDurationUpdated(duration);
        rolloverFeePeriodIfElapsed();
    }
 
    /**
     * @notice Set the Oracle that pushes the havven price to this contract
     */
    function setOracle(address _oracle)
        external
        optionalProxy_onlyOwner
    {
        oracle = _oracle;
        emitOracleUpdated(_oracle);
    }
 
    /**
     * @notice Set the stale period on the updated havven price
     * @dev No max/minimum, as changing it wont influence anything but issuance by the foundation
     */
    function setPriceStalePeriod(uint time)
        external
        optionalProxy_onlyOwner
    {
        priceStalePeriod = time;
    }
 
    /**
     * @notice Set the issuanceRatio for issuance calculations.
     * @dev Only callable by the contract owner.
     */
    function setIssuanceRatio(uint _issuanceRatio)
        external
        optionalProxy_onlyOwner
    {
        require(_issuanceRatio <= MAX_ISSUANCE_RATIO);
        issuanceRatio = _issuanceRatio;
        emitIssuanceRatioUpdated(_issuanceRatio);
    }
 
    /**
     * @notice Set whether the specified can issue nomins or not.
     */
    function setIssuer(address account, bool value)
        external
        optionalProxy_onlyOwner
    {
        isIssuer[account] = value;
        emitIssuersUpdated(account, value);
    }
 
    /* ========== VIEWS ========== */
 
    function issuanceCurrentBalanceSum(address account)
        external
        view
        returns (uint)
    {
        return issuanceData[account].currentBalanceSum;
    }
 
    function issuanceLastAverageBalance(address account)
        external
        view
        returns (uint)
    {
        return issuanceData[account].lastAverageBalance;
    }
 
    function issuanceLastModified(address account)
        external
        view
        returns (uint)
    {
        return issuanceData[account].lastModified;
    }
 
    function totalIssuanceCurrentBalanceSum()
        external
        view
        returns (uint)
    {
        return totalIssuanceData.currentBalanceSum;
    }
 
    function totalIssuanceLastAverageBalance()
        external
        view
        returns (uint)
    {
        return totalIssuanceData.lastAverageBalance;
    }
 
    function totalIssuanceLastModified()
        external
        view
        returns (uint)
    {
        return totalIssuanceData.lastModified;
    }
 
    /* ========== MUTATIVE FUNCTIONS ========== */
 
    /**
     * @notice ERC20 transfer function.
     */
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        require(nominsIssued[sender] == 0 || value <= transferableHavvens(sender));
        /* Perform the transfer: if there is a problem,
         * an exception will be thrown in this call. */
        _transfer_byProxy(sender, to, value);
 
        return true;
    }
 
    /**
     * @notice ERC20 transferFrom function.
     */
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        require(nominsIssued[from] == 0 || value <= transferableHavvens(from));
        /* Perform the transfer: if there is a problem,
         * an exception will be thrown in this call. */
        _transferFrom_byProxy(sender, from, to, value);
 
        return true;
    }
 
    /**
     * @notice Compute the last period&#39;s fee entitlement for the message sender
     * and then deposit it into their nomin account.
     */
    function withdrawFees()
        external
        optionalProxy
    {
        address sender = messageSender;
        rolloverFeePeriodIfElapsed();
        /* Do not deposit fees into frozen accounts. */
        require(!nomin.frozen(sender));
 
        /* Check the period has rolled over first. */
        updateIssuanceData(sender, nominsIssued[sender], nomin.totalSupply());
 
        /* Only allow accounts to withdraw fees once per period. */
        require(!hasWithdrawnFees[sender]);
 
        uint feesOwed;
        uint lastTotalIssued = totalIssuanceData.lastAverageBalance;
 
        if (lastTotalIssued > 0) {
            /* Sender receives a share of last period&#39;s collected fees proportional
             * with their average fraction of the last period&#39;s issued nomins. */
            feesOwed = safeDiv_dec(
                safeMul_dec(issuanceData[sender].lastAverageBalance, lastFeesCollected),
                lastTotalIssued
            );
        }
 
        hasWithdrawnFees[sender] = true;
 
        if (feesOwed != 0) {
            nomin.withdrawFees(sender, feesOwed);
        }
        emitFeesWithdrawn(messageSender, feesOwed);
    }
 
    /**
     * @notice Update the havven balance averages since the last transfer
     * or entitlement adjustment.
     * @dev Since this updates the last transfer timestamp, if invoked
     * consecutively, this function will do nothing after the first call.
     * Also, this will adjust the total issuance at the same time.
     */
    function updateIssuanceData(address account, uint preBalance, uint lastTotalSupply)
        internal
    {
        /* update the total balances first */
        totalIssuanceData = computeIssuanceData(lastTotalSupply, totalIssuanceData);
 
        if (issuanceData[account].lastModified < feePeriodStartTime) {
            hasWithdrawnFees[account] = false;
        }
 
        issuanceData[account] = computeIssuanceData(preBalance, issuanceData[account]);
    }
 
 
    /**
     * @notice Compute the new IssuanceData on the old balance
     */
    function computeIssuanceData(uint preBalance, IssuanceData preIssuance)
        internal
        view
        returns (IssuanceData)
    {
 
        uint currentBalanceSum = preIssuance.currentBalanceSum;
        uint lastAverageBalance = preIssuance.lastAverageBalance;
        uint lastModified = preIssuance.lastModified;
 
        if (lastModified < feePeriodStartTime) {
            if (lastModified < lastFeePeriodStartTime) {
                /* The balance was last updated before the previous fee period, so the average
                 * balance in this period is their pre-transfer balance. */
                lastAverageBalance = preBalance;
            } else {
                /* The balance was last updated during the previous fee period. */
                /* No overflow or zero denominator problems, since lastFeePeriodStartTime < feePeriodStartTime < lastModified.
                 * implies these quantities are strictly positive. */
                uint timeUpToRollover = feePeriodStartTime - lastModified;
                uint lastFeePeriodDuration = feePeriodStartTime - lastFeePeriodStartTime;
                uint lastBalanceSum = safeAdd(currentBalanceSum, safeMul(preBalance, timeUpToRollover));
                lastAverageBalance = lastBalanceSum / lastFeePeriodDuration;
            }
            /* Roll over to the next fee period. */
            currentBalanceSum = safeMul(preBalance, now - feePeriodStartTime);
        } else {
            /* The balance was last updated during the current fee period. */
            currentBalanceSum = safeAdd(
                currentBalanceSum,
                safeMul(preBalance, now - lastModified)
            );
        }
 
        return IssuanceData(currentBalanceSum, lastAverageBalance, now);
    }
 
    /**
     * @notice Recompute and return the given account&#39;s last average balance.
     */
    function recomputeLastAverageBalance(address account)
        external
        returns (uint)
    {
        updateIssuanceData(account, nominsIssued[account], nomin.totalSupply());
        return issuanceData[account].lastAverageBalance;
    }
 
    /**
     * @notice Issue nomins against the sender&#39;s havvens.
     * @dev Issuance is only allowed if the havven price isn&#39;t stale and the sender is an issuer.
     */
    function issueNomins(uint amount)
        public
        optionalProxy
        requireIssuer(messageSender)
        /* No need to check if price is stale, as it is checked in issuableNomins. */
    {
        address sender = messageSender;
        require(amount <= remainingIssuableNomins(sender));
        uint lastTot = nomin.totalSupply();
        uint preIssued = nominsIssued[sender];
        nomin.issue(sender, amount);
        nominsIssued[sender] = safeAdd(preIssued, amount);
        updateIssuanceData(sender, preIssued, lastTot);
    }
 
    function issueMaxNomins()
        external
        optionalProxy
    {
        issueNomins(remainingIssuableNomins(messageSender));
    }
 
    /**
     * @notice Burn nomins to clear issued nomins/free havvens.
     */
    function burnNomins(uint amount)
        /* it doesn&#39;t matter if the price is stale or if the user is an issuer, as non-issuers have issued no nomins.*/
        external
        optionalProxy
    {
        address sender = messageSender;
 
        uint lastTot = nomin.totalSupply();
        uint preIssued = nominsIssued[sender];
        /* nomin.burn does a safeSub on balance (so it will revert if there are not enough nomins). */
        nomin.burn(sender, amount);
        /* This safe sub ensures amount <= number issued */
        nominsIssued[sender] = safeSub(preIssued, amount);
        updateIssuanceData(sender, preIssued, lastTot);
    }
 
    /**
     * @notice Check if the fee period has rolled over. If it has, set the new fee period start
     * time, and record the fees collected in the nomin contract.
     */
    function rolloverFeePeriodIfElapsed()
        public
    {
        /* If the fee period has rolled over... */
        if (now >= feePeriodStartTime + feePeriodDuration) {
            lastFeesCollected = nomin.feePool();
            lastFeePeriodStartTime = feePeriodStartTime;
            feePeriodStartTime = now;
            emitFeePeriodRollover(now);
        }
    }
 
    /* ========== Issuance/Burning ========== */
 
    /**
     * @notice The maximum nomins an issuer can issue against their total havven quantity. This ignores any
     * already issued nomins.
     */
    function maxIssuableNomins(address issuer)
        view
        public
        priceNotStale
        returns (uint)
    {
        if (!isIssuer[issuer]) {
            return 0;
        }
        if (escrow != HavvenEscrow(0)) {
            uint totalOwnedHavvens = safeAdd(tokenState.balanceOf(issuer), escrow.balanceOf(issuer));
            return safeMul_dec(HAVtoUSD(totalOwnedHavvens), issuanceRatio);
        } else {
            return safeMul_dec(HAVtoUSD(tokenState.balanceOf(issuer)), issuanceRatio);
        }
    }
 
    /**
     * @notice The remaining nomins an issuer can issue against their total havven quantity.
     */
    function remainingIssuableNomins(address issuer)
        view
        public
        returns (uint)
    {
        uint issued = nominsIssued[issuer];
        uint max = maxIssuableNomins(issuer);
        if (issued > max) {
            return 0;
        } else {
            return safeSub(max, issued);
        }
    }
 
    /**
     * @notice The total havvens owned by this account, both escrowed and unescrowed,
     * against which nomins can be issued.
     * This includes those already being used as collateral (locked), and those
     * available for further issuance (unlocked).
     */
    function collateral(address account)
        public
        view
        returns (uint)
    {
        uint bal = tokenState.balanceOf(account);
        if (escrow != address(0)) {
            bal = safeAdd(bal, escrow.balanceOf(account));
        }
        return bal;
    }
 
    /**
     * @notice The collateral that would be locked by issuance, which can exceed the account&#39;s actual collateral.
     */
    function issuanceDraft(address account)
        public
        view
        returns (uint)
    {
        uint issued = nominsIssued[account];
        if (issued == 0) {
            return 0;
        }
        return USDtoHAV(safeDiv_dec(issued, issuanceRatio));
    }
 
    /**
     * @notice Collateral that has been locked due to issuance, and cannot be
     * transferred to other addresses. This is capped at the account&#39;s total collateral.
     */
    function lockedCollateral(address account)
        public
        view
        returns (uint)
    {
        uint debt = issuanceDraft(account);
        uint collat = collateral(account);
        if (debt > collat) {
            return collat;
        }
        return debt;
    }
 
    /**
     * @notice Collateral that is not locked and available for issuance.
     */
    function unlockedCollateral(address account)
        public
        view
        returns (uint)
    {
        uint locked = lockedCollateral(account);
        uint collat = collateral(account);
        return safeSub(collat, locked);
    }
 
    /**
     * @notice The number of havvens that are free to be transferred by an account.
     * @dev If they have enough available Havvens, it could be that
     * their havvens are escrowed, however the transfer would then
     * fail. This means that escrowed havvens are locked first,
     * and then the actual transferable ones.
     */
    function transferableHavvens(address account)
        public
        view
        returns (uint)
    {
        uint draft = issuanceDraft(account);
        uint collat = collateral(account);
        // In the case where the issuanceDraft exceeds the collateral, nothing is free
        if (draft > collat) {
            return 0;
        }
 
        uint bal = balanceOf(account);
        // In the case where the draft exceeds the escrow, but not the whole collateral
        //   return the fraction of the balance that remains free
        if (draft > safeSub(collat, bal)) {
            return safeSub(collat, draft);
        }
        // In the case where the draft doesn&#39;t exceed the escrow, return the entire balance
        return bal;
    }
 
    /**
     * @notice The value in USD for a given amount of HAV
     */
    function HAVtoUSD(uint hav_dec)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeMul_dec(hav_dec, price);
    }
 
    /**
     * @notice The value in HAV for a given amount of USD
     */
    function USDtoHAV(uint usd_dec)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeDiv_dec(usd_dec, price);
    }
 
    /**
     * @notice Access point for the oracle to update the price of havvens.
     */
    function updatePrice(uint newPrice, uint timeSent)
        external
        onlyOracle  /* Should be callable only by the oracle. */
    {
        /* Must be the most recently sent price, but not too far in the future.
         * (so we can&#39;t lock ourselves out of updating the oracle for longer than this) */
        require(lastPriceUpdateTime < timeSent && timeSent < now + ORACLE_FUTURE_LIMIT);
 
        price = newPrice;
        lastPriceUpdateTime = timeSent;
        emitPriceUpdated(newPrice, timeSent);
 
        /* Check the fee period rollover within this as the price should be pushed every 15min. */
        rolloverFeePeriodIfElapsed();
    }
 
    /**
     * @notice Check if the price of havvens hasn&#39;t been updated for longer than the stale period.
     */
    function priceIsStale()
        public
        view
        returns (bool)
    {
        return safeAdd(lastPriceUpdateTime, priceStalePeriod) < now;
    }
 
    /* ========== MODIFIERS ========== */
 
    modifier requireIssuer(address account)
    {
        require(isIssuer[account]);
        _;
    }
 
    modifier onlyOracle
    {
        require(msg.sender == oracle);
        _;
    }
 
    modifier priceNotStale
    {
        require(!priceIsStale());
        _;
    }
 
    /* ========== EVENTS ========== */
 
    event PriceUpdated(uint newPrice, uint timestamp);
    bytes32 constant PRICEUPDATED_SIG = keccak256("PriceUpdated(uint256,uint256)");
    function emitPriceUpdated(uint newPrice, uint timestamp) internal {
        proxy._emit(abi.encode(newPrice, timestamp), 1, PRICEUPDATED_SIG, 0, 0, 0);
    }
 
    event IssuanceRatioUpdated(uint newRatio);
    bytes32 constant ISSUANCERATIOUPDATED_SIG = keccak256("IssuanceRatioUpdated(uint256)");
    function emitIssuanceRatioUpdated(uint newRatio) internal {
        proxy._emit(abi.encode(newRatio), 1, ISSUANCERATIOUPDATED_SIG, 0, 0, 0);
    }
 
    event FeePeriodRollover(uint timestamp);
    bytes32 constant FEEPERIODROLLOVER_SIG = keccak256("FeePeriodRollover(uint256)");
    function emitFeePeriodRollover(uint timestamp) internal {
        proxy._emit(abi.encode(timestamp), 1, FEEPERIODROLLOVER_SIG, 0, 0, 0);
    }
 
    event FeePeriodDurationUpdated(uint duration);
    bytes32 constant FEEPERIODDURATIONUPDATED_SIG = keccak256("FeePeriodDurationUpdated(uint256)");
    function emitFeePeriodDurationUpdated(uint duration) internal {
        proxy._emit(abi.encode(duration), 1, FEEPERIODDURATIONUPDATED_SIG, 0, 0, 0);
    }
 
    event FeesWithdrawn(address indexed account, uint value);
    bytes32 constant FEESWITHDRAWN_SIG = keccak256("FeesWithdrawn(address,uint256)");
    function emitFeesWithdrawn(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, FEESWITHDRAWN_SIG, bytes32(account), 0, 0);
    }
 
    event OracleUpdated(address newOracle);
    bytes32 constant ORACLEUPDATED_SIG = keccak256("OracleUpdated(address)");
    function emitOracleUpdated(address newOracle) internal {
        proxy._emit(abi.encode(newOracle), 1, ORACLEUPDATED_SIG, 0, 0, 0);
    }
 
    event NominUpdated(address newNomin);
    bytes32 constant NOMINUPDATED_SIG = keccak256("NominUpdated(address)");
    function emitNominUpdated(address newNomin) internal {
        proxy._emit(abi.encode(newNomin), 1, NOMINUPDATED_SIG, 0, 0, 0);
    }
 
    event EscrowUpdated(address newEscrow);
    bytes32 constant ESCROWUPDATED_SIG = keccak256("EscrowUpdated(address)");
    function emitEscrowUpdated(address newEscrow) internal {
        proxy._emit(abi.encode(newEscrow), 1, ESCROWUPDATED_SIG, 0, 0, 0);
    }
 
    event IssuersUpdated(address indexed account, bool indexed value);
    bytes32 constant ISSUERSUPDATED_SIG = keccak256("IssuersUpdated(address,bool)");
    function emitIssuersUpdated(address account, bool value) internal {
        proxy._emit(abi.encode(), 3, ISSUERSUPDATED_SIG, bytes32(account), bytes32(value ? 1 : 0), 0);
    }
 
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       Court.sol
version:    1.2
author:     Anton Jurisevic
            Mike Spain
            Dominic Romanowski
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
This provides the nomin contract with a confiscation
facility, if enough havven owners vote to confiscate a target
account&#39;s nomins.
 
This is designed to provide a mechanism to respond to abusive
contracts such as nomin wrappers, which would allow users to
trade wrapped nomins without accruing fees on those transactions.
 
In order to prevent tyranny, an account may only be frozen if
users controlling at least 30% of the value of havvens participate,
and a two thirds majority is attained in that vote.
In order to prevent tyranny of the majority or mob justice,
confiscation motions are only approved if the havven foundation
approves the result.
This latter requirement may be lifted in future versions.
 
The foundation, or any user with a sufficient havven balance may
bring a confiscation motion.
A motion lasts for a default period of one week, with a further
confirmation period in which the foundation approves the result.
The latter period may conclude early upon the foundation&#39;s decision
to either veto or approve the mooted confiscation motion.
If the confirmation period elapses without the foundation making
a decision, the motion fails.
 
The weight of a havven holder&#39;s vote is determined by examining
their average balance over the last completed fee period prior to
the beginning of a given motion.
 
Thus, since a fee period can roll over in the middle of a motion,
we must also track a user&#39;s average balance of the last two periods.
This system is designed such that it cannot be attacked by users
transferring funds between themselves, while also not requiring them
to lock their havvens for the duration of the vote. This is possible
since any transfer that increases the average balance in one account
will be reflected by an equivalent reduction in the voting weight in
the other.
 
At present a user may cast a vote only for one motion at a time,
but may cancel their vote at any time except during the confirmation period,
when the vote tallies must remain static until the matter has been settled.
 
A motion to confiscate the balance of a given address composes
a state machine built of the following states:
 
Waiting:
  - A user with standing brings a motion:
    If the target address is not frozen;
    initialise vote tallies to 0;
    transition to the Voting state.
 
  - An account cancels a previous residual vote:
    remain in the Waiting state.
 
Voting:
  - The foundation vetoes the in-progress motion:
    transition to the Waiting state.
 
  - The voting period elapses:
    transition to the Confirmation state.
 
  - An account votes (for or against the motion):
    its weight is added to the appropriate tally;
    remain in the Voting state.
 
  - An account cancels its previous vote:
    its weight is deducted from the appropriate tally (if any);
    remain in the Voting state.
 
Confirmation:
  - The foundation vetoes the completed motion:
    transition to the Waiting state.
 
  - The foundation approves confiscation of the target account:
    freeze the target account, transfer its nomin balance to the fee pool;
    transition to the Waiting state.
 
  - The confirmation period elapses:
    transition to the Waiting state.
 
User votes are not automatically cancelled upon the conclusion of a motion.
Therefore, after a motion comes to a conclusion, if a user wishes to vote
in another motion, they must manually cancel their vote in order to do so.
 
This procedure is designed to be relatively simple.
There are some things that can be added to enhance the functionality
at the expense of simplicity and efficiency:
 
  - Democratic unfreezing of nomin accounts (induces multiple categories of vote)
  - Configurable per-vote durations;
  - Vote standing denominated in a fiat quantity rather than a quantity of havvens;
  - Confiscate from multiple addresses in a single vote;
 
We might consider updating the contract with any of these features at a later date if necessary.
 
-----------------------------------------------------------------
*/
 
 
/**
 * @title A court contract allowing a democratic mechanism to dissuade token wrappers.
 */
contract Court is SafeDecimalMath, Owned {
 
    /* ========== STATE VARIABLES ========== */
 
    /* The addresses of the token contracts this confiscation court interacts with. */
    Havven public havven;
    Nomin public nomin;
 
    /* The minimum issued nomin balance required to be considered to have
     * standing to begin confiscation proceedings. */
    uint public minStandingBalance = 100 * UNIT;
 
    /* The voting period lasts for this duration,
     * and if set, must fall within the given bounds. */
    uint public votingPeriod = 1 weeks;
    uint constant MIN_VOTING_PERIOD = 3 days;
    uint constant MAX_VOTING_PERIOD = 4 weeks;
 
    /* Duration of the period during which the foundation may confirm
     * or veto a motion that has concluded.
     * If set, the confirmation duration must fall within the given bounds. */
    uint public confirmationPeriod = 1 weeks;
    uint constant MIN_CONFIRMATION_PERIOD = 1 days;
    uint constant MAX_CONFIRMATION_PERIOD = 2 weeks;
 
    /* No fewer than this fraction of total available voting power must
     * participate in a motion in order for a quorum to be reached.
     * The participation fraction required may be set no lower than 10%.
     * As a fraction, it is expressed in terms of UNIT, not as an absolute quantity. */
    uint public requiredParticipation = 3 * UNIT / 10;
    uint constant MIN_REQUIRED_PARTICIPATION = UNIT / 10;
 
    /* At least this fraction of participating votes must be in favour of
     * confiscation for the motion to pass.
     * The required majority may be no lower than 50%.
     * As a fraction, it is expressed in terms of UNIT, not as an absolute quantity. */
    uint public requiredMajority = (2 * UNIT) / 3;
    uint constant MIN_REQUIRED_MAJORITY = UNIT / 2;
 
    /* The next ID to use for opening a motion.
     * The 0 motion ID corresponds to no motion,
     * and is used as a null value for later comparison. */
    uint nextMotionID = 1;
 
    /* Mapping from motion IDs to target addresses. */
    mapping(uint => address) public motionTarget;
 
    /* The ID a motion on an address is currently operating at.
     * Zero if no such motion is running. */
    mapping(address => uint) public targetMotionID;
 
    /* The timestamp at which a motion began. This is used to determine
     * whether a motion is: running, in the confirmation period,
     * or has concluded.
     * A motion runs from its start time t until (t + votingPeriod),
     * and then the confirmation period terminates no later than
     * (t + votingPeriod + confirmationPeriod). */
    mapping(uint => uint) public motionStartTime;
 
    /* The tallies for and against confiscation of a given balance.
     * These are set to zero at the start of a motion, and also on conclusion,
     * just to keep the state clean. */
    mapping(uint => uint) public votesFor;
    mapping(uint => uint) public votesAgainst;
 
    /* The last average balance of a user at the time they voted
     * in a particular motion.
     * If we did not save this information then we would have to
     * disallow transfers into an account lest it cancel a vote
     * with greater weight than that with which it originally voted,
     * and the fee period rolled over in between. */
    // TODO: This may be unnecessary now that votes are forced to be
    // within a fee period. Likely possible to delete this.
    mapping(address => mapping(uint => uint)) voteWeight;
 
    /* The possible vote types.
     * Abstention: not participating in a motion; This is the default value.
     * Yea: voting in favour of a motion.
     * Nay: voting against a motion. */
    enum Vote {Abstention, Yea, Nay}
 
    /* A given account&#39;s vote in some confiscation motion.
     * This requires the default value of the Vote enum to correspond to an abstention. */
    mapping(address => mapping(uint => Vote)) public vote;
 
 
    /* ========== CONSTRUCTOR ========== */
 
    /**
     * @dev Court Constructor.
     */
    constructor(Havven _havven, Nomin _nomin, address _owner)
        Owned(_owner)
        public
    {
        havven = _havven;
        nomin = _nomin;
    }
 
 
    /* ========== SETTERS ========== */
 
    /**
     * @notice Set the minimum required havven balance to have standing to bring a motion.
     * @dev Only the contract owner may call this.
     */
    function setMinStandingBalance(uint balance)
        external
        onlyOwner
    {
        /* No requirement on the standing threshold here;
         * the foundation can set this value such that
         * anyone or no one can actually start a motion. */
        minStandingBalance = balance;
    }
 
    /**
     * @notice Set the length of time a vote runs for.
     * @dev Only the contract owner may call this. The proposed duration must fall
     * within sensible bounds (3 days to 4 weeks), and must be no longer than a single fee period.
     */
    function setVotingPeriod(uint duration)
        external
        onlyOwner
    {
        require(MIN_VOTING_PERIOD <= duration &&
                duration <= MAX_VOTING_PERIOD);
        /* Require that the voting period is no longer than a single fee period,
         * So that a single vote can span at most two fee periods. */
        require(duration <= havven.feePeriodDuration());
        votingPeriod = duration;
    }
 
    /**
     * @notice Set the confirmation period after a vote has concluded.
     * @dev Only the contract owner may call this. The proposed duration must fall
     * within sensible bounds (1 day to 2 weeks).
     */
    function setConfirmationPeriod(uint duration)
        external
        onlyOwner
    {
        require(MIN_CONFIRMATION_PERIOD <= duration &&
                duration <= MAX_CONFIRMATION_PERIOD);
        confirmationPeriod = duration;
    }
 
    /**
     * @notice Set the required fraction of all Havvens that need to be part of
     * a vote for it to pass.
     */
    function setRequiredParticipation(uint fraction)
        external
        onlyOwner
    {
        require(MIN_REQUIRED_PARTICIPATION <= fraction);
        requiredParticipation = fraction;
    }
 
    /**
     * @notice Set what portion of voting havvens need to be in the affirmative
     * to allow it to pass.
     */
    function setRequiredMajority(uint fraction)
        external
        onlyOwner
    {
        require(MIN_REQUIRED_MAJORITY <= fraction);
        requiredMajority = fraction;
    }
 
 
    /* ========== VIEW FUNCTIONS ========== */
 
    /**
     * @notice There is a motion in progress on the specified
     * account, and votes are being accepted in that motion.
     */
    function motionVoting(uint motionID)
        public
        view
        returns (bool)
    {
        return motionStartTime[motionID] < now && now < motionStartTime[motionID] + votingPeriod;
    }
 
    /**
     * @notice A vote on the target account has concluded, but the motion
     * has not yet been approved, vetoed, or closed. */
    function motionConfirming(uint motionID)
        public
        view
        returns (bool)
    {
        /* These values are timestamps, they will not overflow
         * as they can only ever be initialised to relatively small values.
         */
        uint startTime = motionStartTime[motionID];
        return startTime + votingPeriod <= now &&
               now < startTime + votingPeriod + confirmationPeriod;
    }
 
    /**
     * @notice A vote motion either not begun, or it has completely terminated.
     */
    function motionWaiting(uint motionID)
        public
        view
        returns (bool)
    {
        /* These values are timestamps, they will not overflow
         * as they can only ever be initialised to relatively small values. */
        return motionStartTime[motionID] + votingPeriod + confirmationPeriod <= now;
    }
 
    /**
     * @notice If the motion was to terminate at this instant, it would pass.
     * That is: there was sufficient participation and a sizeable enough majority.
     */
    function motionPasses(uint motionID)
        public
        view
        returns (bool)
    {
        uint yeas = votesFor[motionID];
        uint nays = votesAgainst[motionID];
        uint totalVotes = safeAdd(yeas, nays);
 
        if (totalVotes == 0) {
            return false;
        }
 
        uint participation = safeDiv_dec(totalVotes, havven.totalIssuanceLastAverageBalance());
        uint fractionInFavour = safeDiv_dec(yeas, totalVotes);
 
        /* We require the result to be strictly greater than the requirement
         * to enforce a majority being "50% + 1", and so on. */
        return participation > requiredParticipation &&
               fractionInFavour > requiredMajority;
    }
 
    /**
     * @notice Return if the specified account has voted on the specified motion
     */
    function hasVoted(address account, uint motionID)
        public
        view
        returns (bool)
    {
        return vote[account][motionID] != Vote.Abstention;
    }
 
 
    /* ========== MUTATIVE FUNCTIONS ========== */
 
    /**
     * @notice Begin a motion to confiscate the funds in a given nomin account.
     * @dev Only the foundation, or accounts with sufficient havven balances
     * may elect to start such a motion.
     * @return Returns the ID of the motion that was begun.
     */
    function beginMotion(address target)
        external
        returns (uint)
    {
        /* A confiscation motion must be mooted by someone with standing. */
        require((havven.issuanceLastAverageBalance(msg.sender) >= minStandingBalance) ||
                msg.sender == owner);
 
        /* Require that the voting period is longer than a single fee period,
         * So that a single vote can span at most two fee periods. */
        require(votingPeriod <= havven.feePeriodDuration());
 
        /* There must be no confiscation motion already running for this account. */
        require(targetMotionID[target] == 0);
 
        /* Disallow votes on accounts that are currently frozen. */
        require(!nomin.frozen(target));
 
        /* It is necessary to roll over the fee period if it has elapsed, or else
         * the vote might be initialised having begun in the past. */
        havven.rolloverFeePeriodIfElapsed();
 
        uint motionID = nextMotionID++;
        motionTarget[motionID] = target;
        targetMotionID[target] = motionID;
 
        /* Start the vote at the start of the next fee period */
        uint startTime = havven.feePeriodStartTime() + havven.feePeriodDuration();
        motionStartTime[motionID] = startTime;
        emit MotionBegun(msg.sender, target, motionID, startTime);
 
        return motionID;
    }
 
    /**
     * @notice Shared vote setup function between voteFor and voteAgainst.
     * @return Returns the voter&#39;s vote weight. */
    function setupVote(uint motionID)
        internal
        returns (uint)
    {
        /* There must be an active vote for this target running.
         * Vote totals must only change during the voting phase. */
        require(motionVoting(motionID));
 
        /* The voter must not have an active vote this motion. */
        require(!hasVoted(msg.sender, motionID));
 
        /* The voter may not cast votes on themselves. */
        require(msg.sender != motionTarget[motionID]);
 
        uint weight = havven.recomputeLastAverageBalance(msg.sender);
 
        /* Users must have a nonzero voting weight to vote. */
        require(weight > 0);
 
        voteWeight[msg.sender][motionID] = weight;
 
        return weight;
    }
 
    /**
     * @notice The sender casts a vote in favour of confiscation of the
     * target account&#39;s nomin balance.
     */
    function voteFor(uint motionID)
        external
    {
        uint weight = setupVote(motionID);
        vote[msg.sender][motionID] = Vote.Yea;
        votesFor[motionID] = safeAdd(votesFor[motionID], weight);
        emit VotedFor(msg.sender, motionID, weight);
    }
 
    /**
     * @notice The sender casts a vote against confiscation of the
     * target account&#39;s nomin balance.
     */
    function voteAgainst(uint motionID)
        external
    {
        uint weight = setupVote(motionID);
        vote[msg.sender][motionID] = Vote.Nay;
        votesAgainst[motionID] = safeAdd(votesAgainst[motionID], weight);
        emit VotedAgainst(msg.sender, motionID, weight);
    }
 
    /**
     * @notice Cancel an existing vote by the sender on a motion
     * to confiscate the target balance.
     */
    function cancelVote(uint motionID)
        external
    {
        /* An account may cancel its vote either before the confirmation phase
         * when the motion is still open, or after the confirmation phase,
         * when the motion has concluded.
         * But the totals must not change during the confirmation phase itself. */
        require(!motionConfirming(motionID));
 
        Vote senderVote = vote[msg.sender][motionID];
 
        /* If the sender has not voted then there is no need to update anything. */
        require(senderVote != Vote.Abstention);
 
        /* If we are not voting, there is no reason to update the vote totals. */
        if (motionVoting(motionID)) {
            if (senderVote == Vote.Yea) {
                votesFor[motionID] = safeSub(votesFor[motionID], voteWeight[msg.sender][motionID]);
            } else {
                /* Since we already ensured that the vote is not an abstention,
                 * the only option remaining is Vote.Nay. */
                votesAgainst[motionID] = safeSub(votesAgainst[motionID], voteWeight[msg.sender][motionID]);
            }
            /* A cancelled vote is only meaningful if a vote is running. */
            emit VoteCancelled(msg.sender, motionID);
        }
 
        delete voteWeight[msg.sender][motionID];
        delete vote[msg.sender][motionID];
    }
 
    /**
     * @notice clear all data associated with a motionID for hygiene purposes.
     */
    function _closeMotion(uint motionID)
        internal
    {
        delete targetMotionID[motionTarget[motionID]];
        delete motionTarget[motionID];
        delete motionStartTime[motionID];
        delete votesFor[motionID];
        delete votesAgainst[motionID];
        emit MotionClosed(motionID);
    }
 
    /**
     * @notice If a motion has concluded, or if it lasted its full duration but not passed,
     * then anyone may close it.
     */
    function closeMotion(uint motionID)
        external
    {
        require((motionConfirming(motionID) && !motionPasses(motionID)) || motionWaiting(motionID));
        _closeMotion(motionID);
    }
 
    /**
     * @notice The foundation may only confiscate a balance during the confirmation
     * period after a motion has passed.
     */
    function approveMotion(uint motionID)
        external
        onlyOwner
    {
        require(motionConfirming(motionID) && motionPasses(motionID));
        address target = motionTarget[motionID];
        nomin.freezeAndConfiscate(target);
        _closeMotion(motionID);
        emit MotionApproved(motionID);
    }
 
    /* @notice The foundation may veto a motion at any time. */
    function vetoMotion(uint motionID)
        external
        onlyOwner
    {
        require(!motionWaiting(motionID));
        _closeMotion(motionID);
        emit MotionVetoed(motionID);
    }
 
 
    /* ========== EVENTS ========== */
 
    event MotionBegun(address indexed initiator, address indexed target, uint indexed motionID, uint startTime);
 
    event VotedFor(address indexed voter, uint indexed motionID, uint weight);
 
    event VotedAgainst(address indexed voter, uint indexed motionID, uint weight);
 
    event VoteCancelled(address indexed voter, uint indexed motionID);
 
    event MotionClosed(uint indexed motionID);
 
    event MotionVetoed(uint indexed motionID);
 
    event MotionApproved(uint indexed motionID);
}
 
 
/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
 
file:       Nomin.sol
version:    1.2
author:     Anton Jurisevic
            Mike Spain
            Dominic Romanowski
            Kevin Brown
 
date:       2018-05-29
 
-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
 
Havven-backed nomin stablecoin contract.
 
This contract issues nomins, which are tokens worth 1 USD each.
 
Nomins are issuable by Havven holders who have to lock up some
value of their havvens to issue H * Cmax nomins. Where Cmax is
some value less than 1.
 
A configurable fee is charged on nomin transfers and deposited
into a common pot, which havven holders may withdraw from once
per fee period.
 
-----------------------------------------------------------------
*/
 
 
contract Nomin is FeeToken {
 
    /* ========== STATE VARIABLES ========== */
 
    // The address of the contract which manages confiscation votes.
    Court public court;
    Havven public havven;
 
    // Accounts which have lost the privilege to transact in nomins.
    mapping(address => bool) public frozen;
 
    // Nomin transfers incur a 15 bp fee by default.
    uint constant TRANSFER_FEE_RATE = 15 * UNIT / 10000;
    string constant TOKEN_NAME = "Nomin USD";
    string constant TOKEN_SYMBOL = "nUSD";
 
    /* ========== CONSTRUCTOR ========== */
 
    constructor(address _proxy, TokenState _tokenState, Havven _havven,
                uint _totalSupply,
                address _owner)
        FeeToken(_proxy, _tokenState,
                 TOKEN_NAME, TOKEN_SYMBOL, _totalSupply,
                 TRANSFER_FEE_RATE,
                 _havven, // The havven contract is the fee authority.
                 _owner)
        public
    {
        require(_proxy != 0 && address(_havven) != 0 && _owner != 0);
        // It should not be possible to transfer to the fee pool directly (or confiscate its balance).
        frozen[FEE_ADDRESS] = true;
        havven = _havven;
    }
 
    /* ========== SETTERS ========== */
 
    function setCourt(Court _court)
        external
        optionalProxy_onlyOwner
    {
        court = _court;
        emitCourtUpdated(_court);
    }
 
    function setHavven(Havven _havven)
        external
        optionalProxy_onlyOwner
    {
        // havven should be set as the feeAuthority after calling this depending on
        // havven&#39;s internal logic
        havven = _havven;
        setFeeAuthority(_havven);
        emitHavvenUpdated(_havven);
    }
 
 
    /* ========== MUTATIVE FUNCTIONS ========== */
 
    /* Override ERC20 transfer function in order to check
     * whether the recipient account is frozen. Note that there is
     * no need to check whether the sender has a frozen account,
     * since their funds have already been confiscated,
     * and no new funds can be transferred to it.*/
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transfer_byProxy(messageSender, to, value);
    }
 
    /* Override ERC20 transferFrom function in order to check
     * whether the recipient account is frozen. */
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transferFrom_byProxy(messageSender, from, to, value);
    }
 
    function transferSenderPaysFee(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transferSenderPaysFee_byProxy(messageSender, to, value);
    }
 
    function transferFromSenderPaysFee(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transferFromSenderPaysFee_byProxy(messageSender, from, to, value);
    }
 
    /* If a confiscation court motion has passed and reached the confirmation
     * state, the court may transfer the target account&#39;s balance to the fee pool
     * and freeze its participation in further transactions. */
    function freezeAndConfiscate(address target)
        external
        onlyCourt
    {
         
        // A motion must actually be underway.
        uint motionID = court.targetMotionID(target);
        require(motionID != 0);
 
        // These checks are strictly unnecessary,
        // since they are already checked in the court contract itself.
        require(court.motionConfirming(motionID));
        require(court.motionPasses(motionID));
        require(!frozen[target]);
 
        // Confiscate the balance in the account and freeze it.
        uint balance = tokenState.balanceOf(target);
        tokenState.setBalanceOf(FEE_ADDRESS, safeAdd(tokenState.balanceOf(FEE_ADDRESS), balance));
        tokenState.setBalanceOf(target, 0);
        frozen[target] = true;
        emitAccountFrozen(target, balance);
        emitTransfer(target, FEE_ADDRESS, balance);
    }
 
    /* The owner may allow a previously-frozen contract to once
     * again accept and transfer nomins. */
    function unfreezeAccount(address target)
        external
        optionalProxy_onlyOwner
    {
        require(frozen[target] && target != FEE_ADDRESS);
        frozen[target] = false;
        emitAccountUnfrozen(target);
    }
 
    /* Allow havven to issue a certain number of
     * nomins from an account. */
    function issue(address account, uint amount)
        external
        onlyHavven
    {
        tokenState.setBalanceOf(account, safeAdd(tokenState.balanceOf(account), amount));
        totalSupply = safeAdd(totalSupply, amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }
 
    /* Allow havven to burn a certain number of
     * nomins from an account. */
    function burn(address account, uint amount)
        external
        onlyHavven
    {
        tokenState.setBalanceOf(account, safeSub(tokenState.balanceOf(account), amount));
        totalSupply = safeSub(totalSupply, amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
    }
 
    /* ========== MODIFIERS ========== */
 
    modifier onlyHavven() {
        require(Havven(msg.sender) == havven);
        _;
    }
 
    modifier onlyCourt() {
        require(Court(msg.sender) == court);
        _;
    }
 
    /* ========== EVENTS ========== */
 
    event CourtUpdated(address newCourt);
    bytes32 constant COURTUPDATED_SIG = keccak256("CourtUpdated(address)");
    function emitCourtUpdated(address newCourt) internal {
        proxy._emit(abi.encode(newCourt), 1, COURTUPDATED_SIG, 0, 0, 0);
    }
 
    event HavvenUpdated(address newHavven);
    bytes32 constant HAVVENUPDATED_SIG = keccak256("HavvenUpdated(address)");
    function emitHavvenUpdated(address newHavven) internal {
        proxy._emit(abi.encode(newHavven), 1, HAVVENUPDATED_SIG, 0, 0, 0);
    }
 
    event AccountFrozen(address indexed target, uint balance);
    bytes32 constant ACCOUNTFROZEN_SIG = keccak256("AccountFrozen(address,uint256)");
    function emitAccountFrozen(address target, uint balance) internal {
        proxy._emit(abi.encode(balance), 2, ACCOUNTFROZEN_SIG, bytes32(target), 0, 0);
    }
 
    event AccountUnfrozen(address indexed target);
    bytes32 constant ACCOUNTUNFROZEN_SIG = keccak256("AccountUnfrozen(address)");
    function emitAccountUnfrozen(address target) internal {
        proxy._emit(abi.encode(), 2, ACCOUNTUNFROZEN_SIG, bytes32(target), 0, 0);
    }
 
    event Issued(address indexed account, uint amount);
    bytes32 constant ISSUED_SIG = keccak256("Issued(address,uint256)");
    function emitIssued(address account, uint amount) internal {
        proxy._emit(abi.encode(amount), 2, ISSUED_SIG, bytes32(account), 0, 0);
    }
 
    event Burned(address indexed account, uint amount);
    bytes32 constant BURNED_SIG = keccak256("Burned(address,uint256)");
    function emitBurned(address account, uint amount) internal {
        proxy._emit(abi.encode(amount), 2, BURNED_SIG, bytes32(account), 0, 0);
    }
}