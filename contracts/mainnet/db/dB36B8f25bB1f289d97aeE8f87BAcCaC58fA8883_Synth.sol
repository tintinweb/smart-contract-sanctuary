/* ===============================================
* Flattened with Solidifier by Coinage
* 
* https://solidifier.coina.ge
* ===============================================
*/


pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/*

-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SafeDecimalMath.sol
version:    2.0
author:     Kevin Brown
            Gavin Conway
date:       2018-10-18

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A library providing safe mathematical operations for division and
multiplication with the capability to round or truncate the results
to the nearest increment. Operations can return a standard precision
or high precision decimal. High precision decimals are useful for
example when attempting to calculate percentages or fractions
accurately.

-----------------------------------------------------------------
*/


/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals of a specified precision (either standard
 * or high).
 */
library SafeDecimalMath {

    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

    /** 
     * @return Provides an interface to UNIT.
     */
    function unit()
        external
        pure
        returns (uint)
    {
        return UNIT;
    }

    /** 
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit()
        external
        pure 
        returns (uint)
    {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     * 
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     * 
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
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
        require(_owner != address(0), "Owner must not be the zero address");
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
        require(_beneficiary != address(0), "Beneficiary must not be the zero address");
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
        require(selfDestructInitiated, "Self destruct has not yet been initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < now, "Self destruct delay has not yet elapsed");
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

    function _emit(bytes callData, uint numTopics, bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4)
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
        require(Proxyable(msg.sender) == target, "Must be proxy target");
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
        require(Proxy(msg.sender) == proxy, "Only the proxy can call this function");
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
        require(messageSender == owner, "This action can only be performed by the owner");
        _;
    }

    event ProxyUpdated(address proxyAddress);
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ExternStateToken.sol
version:    1.0
author:     Kevin Brown
date:       2018-08-06

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract offers a modifer that can prevent reentrancy on
particular actions. It will not work if you put it on multiple
functions that can be called from each other. Specifically guard
external entry points to the contract with the modifier only.

-----------------------------------------------------------------
*/


contract ReentrancyPreventer {
    /* ========== MODIFIERS ========== */
    bool isInFunctionBody = false;

    modifier preventReentrancy {
        require(!isInFunctionBody, "Reverted to prevent reentrancy");
        isInFunctionBody = true;
        _;
        isInFunctionBody = false;
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       TokenFallback.sol
version:    1.0
author:     Kevin Brown
date:       2018-08-10

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract provides the logic that&#39;s used to call tokenFallback()
when transfers happen.

It&#39;s pulled out into its own module because it&#39;s needed in two
places, so instead of copy/pasting this logic and maininting it
both in Fee Token and Extern State Token, it&#39;s here and depended
on by both contracts.

-----------------------------------------------------------------
*/


contract TokenFallbackCaller is ReentrancyPreventer {
    function callTokenFallbackIfNeeded(address sender, address recipient, uint amount, bytes data)
        internal
        preventReentrancy
    {
        /*
            If we&#39;re transferring to a contract and it implements the tokenFallback function, call it.
            This isn&#39;t ERC223 compliant because we don&#39;t revert if the contract doesn&#39;t implement tokenFallback.
            This is because many DEXes and other contracts that expect to work with the standard
            approve / transferFrom workflow don&#39;t implement tokenFallback but can still process our tokens as
            usual, so it feels very harsh and likely to cause trouble if we add this restriction after having
            previously gone live with a vanilla ERC20.
        */

        // Is the to address a contract? We can check the code size on that address and know.
        uint length;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Retrieve the size of the code on the recipient address
            length := extcodesize(recipient)
        }

        // If there&#39;s code there, it&#39;s a contract
        if (length > 0) {
            // Now we need to optionally call tokenFallback(address from, uint value).
            // We can&#39;t call it the normal way because that reverts when the recipient doesn&#39;t implement the function.

            // solium-disable-next-line security/no-low-level-calls
            recipient.call(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", sender, amount, data));

            // And yes, we specifically don&#39;t care if this call fails, so we&#39;re not checking the return value.
        }
    }
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ExternStateToken.sol
version:    1.3
author:     Anton Jurisevic
            Dominic Romanowski
            Kevin Brown

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
contract ExternStateToken is SelfDestructible, Proxyable, TokenFallbackCaller {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */

    /* Stores balances and allowances. */
    TokenState public tokenState;

    /* Other ERC20 fields. */
    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;

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
                uint8 _decimals, address _owner)
        SelfDestructible(_owner)
        Proxyable(_proxy, _owner)
        public
    {
        tokenState = _tokenState;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
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

    function _internalTransfer(address from, address to, uint value, bytes data) 
        internal
        returns (bool)
    { 
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0), "Cannot transfer to the 0 address");
        require(to != address(this), "Cannot transfer to the underlying contract");
        require(to != address(proxy), "Cannot transfer to the proxy contract");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

        // If the recipient is a contract, we need to call tokenFallback on it so they can do ERC223
        // actions when receiving our tokens. Unlike the standard, however, we don&#39;t revert if the
        // recipient contract doesn&#39;t implement tokenFallback.
        callTokenFallbackIfNeeded(from, to, value, data);
        
        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transfer_byProxy(address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
        return _internalTransfer(from, to, value, data);
    }

    /**
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFrom_byProxy(address sender, address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value, data);
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
        require(now < setupExpiryTime, "Can only perform this action during setup");
        _;
    }
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SynthetixEscrow.sol
version:    1.1
author:     Anton Jurisevic
            Dominic Romanowski
            Mike Spain

date:       2018-05-29

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract allows the foundation to apply unique vesting
schedules to synthetix funds sold at various discounts in the token
sale. SynthetixEscrow gives users the ability to inspect their
vested funds, their quantities and vesting dates, and to withdraw
the fees that accrue on those funds.

The fees are handled by withdrawing the entire fee allocation
for all SNX inside the escrow contract, and then allowing
the contract itself to subdivide that pool up proportionally within
itself. Every time the fee period rolls over in the main Synthetix
contract, the SynthetixEscrow fee pool is remitted back into the
main fee pool to be redistributed in the next fee period.

-----------------------------------------------------------------
*/


/**
 * @title A contract to hold escrowed SNX and free them at given schedules.
 */
contract SynthetixEscrow is Owned, LimitedSetup(8 weeks) {

    using SafeMath for uint;

    /* The corresponding Synthetix contract. */
    Synthetix public synthetix;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of SNX vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account&#39;s total vested synthetix balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining vested balance, for verifying the actual synthetix balance of this contract against. */
    uint public totalVestedBalance;

    uint constant TIME_INDEX = 0;
    uint constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules. */
    uint constant MAX_VESTING_ENTRIES = 20;


    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, Synthetix _synthetix)
        Owned(_owner)
        public
    {
        synthetix = _synthetix;
    }


    /* ========== SETTERS ========== */

    function setSynthetix(Synthetix _synthetix)
        external
        onlyOwner
    {
        synthetix = _synthetix;
        emit SynthetixUpdated(_synthetix);
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
     * @return A pair of uints: (timestamp, synthetix quantity).
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
     * @notice Get the quantity of SNX associated with a given schedule entry.
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
     * @return A pair of uints: (timestamp, synthetix quantity). */
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
     * @notice Withdraws a quantity of SNX back to the synthetix contract.
     * @dev This may only be called by the owner during the contract&#39;s setup period.
     */
    function withdrawSynthetix(uint quantity)
        external
        onlyOwner
        onlyDuringSetup
    {
        synthetix.transfer(synthetix, quantity);
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
        totalVestedBalance = totalVestedBalance.sub(totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account&#39;s schedule.
     * @dev A call to this should be accompanied by either enough balance already available
     * in this contract, or a corresponding call to synthetix.endow(), to ensure that when
     * the funds are withdrawn, there is enough balance, as well as correctly calculating
     * the fees.
     * This may only be called by the owner during the contract&#39;s setup period.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it&#39;s only in the foundation&#39;s command to add to these lists.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of SNX that will vest.
     */
    function appendVestingEntry(address account, uint time, uint quantity)
        public
        onlyOwner
        onlyDuringSetup
    {
        /* No empty or already-passed vesting entries allowed. */
        require(now < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalVestedBalance = totalVestedBalance.add(quantity);
        require(totalVestedBalance <= synthetix.balanceOf(this), "Must be enough balance in the contract to provide for the vesting entry");

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        if (scheduleLength == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
            /* Disallow adding new vested SNX earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(getVestingTime(account, numVestingEntries(account) - 1) < time, "Cannot add new vested entries earlier than the last one");
            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

    /**
     * @notice Construct a vesting schedule to release a quantities of SNX
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
     * @notice Allow a user to withdraw any SNX in their schedule that have vested.
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
            total = total.add(qty);
        }

        if (total != 0) {
            totalVestedBalance = totalVestedBalance.sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].sub(total);
            synthetix.transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }


    /* ========== EVENTS ========== */

    event SynthetixUpdated(address newSynthetix);

    event Vested(address indexed beneficiary, uint time, uint value);
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SynthetixState.sol
version:    1.0
author:     Kevin Brown
date:       2018-10-19

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract that holds issuance state and preferred currency of
users in the Synthetix system.

This contract is used side by side with the Synthetix contract
to make it easier to upgrade the contract logic while maintaining
issuance state.

The Synthetix contract is also quite large and on the edge of
being beyond the contract size limit without moving this information
out to another contract.

The first deployed contract would create this state contract,
using it as its store of issuance data.

When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/


/**
 * @title Synthetix State
 * @notice Stores issuance information and preferred currency information of the Synthetix contract.
 */
contract SynthetixState is State, LimitedSetup {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    // A struct for handing values associated with an individual user&#39;s debt position
    struct IssuanceData {
        // Percentage of the total debt owned at the time
        // of issuance. This number is modified by the global debt
        // delta array. You can figure out a user&#39;s exit price and
        // collateralisation ratio using a combination of their initial
        // debt and the slice of global debt delta which applies to them.
        uint initialDebtOwnership;
        // This lets us know when (in relative terms) the user entered
        // the debt pool so we can calculate their exit price and
        // collateralistion ratio
        uint debtEntryIndex;
    }

    // Issued synth balances for individual fee entitlements and exit price calculations
    mapping(address => IssuanceData) public issuanceData;

    // The total count of people that have outstanding issued synths in any flavour
    uint public totalIssuerCount;

    // Global debt pool tracking
    uint[] public debtLedger;

    // Import state
    uint public importedXDRAmount;

    // A quantity of synths greater than this ratio
    // may not be issued against a given value of SNX.
    uint public issuanceRatio = SafeDecimalMath.unit() / 5;
    // No more synths may be issued than the value of SNX backing them.
    uint constant MAX_ISSUANCE_RATIO = SafeDecimalMath.unit();

    // Users can specify their preferred currency, in which case all synths they receive
    // will automatically exchange to that preferred currency upon receipt in their wallet
    mapping(address => bytes4) public preferredCurrency;

    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _associatedContract The ERC20 contract whose state this composes.
     */
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        LimitedSetup(1 weeks)
        public
    {}

    /* ========== SETTERS ========== */

    /**
     * @notice Set issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to set the data for.
     * @param initialDebtOwnership The initial debt ownership for this address.
     */
    function setCurrentIssuanceData(address account, uint initialDebtOwnership)
        external
        onlyAssociatedContract
    {
        issuanceData[account].initialDebtOwnership = initialDebtOwnership;
        issuanceData[account].debtEntryIndex = debtLedger.length;
    }

    /**
     * @notice Clear issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to clear the data for.
     */
    function clearIssuanceData(address account)
        external
        onlyAssociatedContract
    {
        delete issuanceData[account];
    }

    /**
     * @notice Increment the total issuer count
     * @dev Only the associated contract may call this.
     */
    function incrementTotalIssuerCount()
        external
        onlyAssociatedContract
    {
        totalIssuerCount = totalIssuerCount.add(1);
    }

    /**
     * @notice Decrement the total issuer count
     * @dev Only the associated contract may call this.
     */
    function decrementTotalIssuerCount()
        external
        onlyAssociatedContract
    {
        totalIssuerCount = totalIssuerCount.sub(1);
    }

    /**
     * @notice Append a value to the debt ledger
     * @dev Only the associated contract may call this.
     * @param value The new value to be added to the debt ledger.
     */
    function appendDebtLedgerValue(uint value)
        external
        onlyAssociatedContract
    {
        debtLedger.push(value);
    }

    /**
     * @notice Set preferred currency for a user
     * @dev Only the associated contract may call this.
     * @param account The account to set the preferred currency for
     * @param currencyKey The new preferred currency
     */
    function setPreferredCurrency(address account, bytes4 currencyKey)
        external
        onlyAssociatedContract
    {
        preferredCurrency[account] = currencyKey;
    }

    /**
     * @notice Set the issuanceRatio for issuance calculations.
     * @dev Only callable by the contract owner.
     */
    function setIssuanceRatio(uint _issuanceRatio)
        external
        onlyOwner
    {
        require(_issuanceRatio <= MAX_ISSUANCE_RATIO, "New issuance ratio cannot exceed MAX_ISSUANCE_RATIO");
        issuanceRatio = _issuanceRatio;
        emit IssuanceRatioUpdated(_issuanceRatio);
    }

    /**
     * @notice Import issuer data from the old Synthetix contract before multicurrency
     * @dev Only callable by the contract owner, and only for 1 week after deployment.
     */
    function importIssuerData(address[] accounts, uint[] sUSDAmounts)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == sUSDAmounts.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            _addToDebtRegister(accounts[i], sUSDAmounts[i]);
        }
    }

    /**
     * @notice Import issuer data from the old Synthetix contract before multicurrency
     * @dev Only used from importIssuerData above, meant to be disposable
     */
    function _addToDebtRegister(address account, uint amount)
        internal
    {
        // This code is duplicated from Synthetix so that we can call it directly here
        // during setup only.
        Synthetix synthetix = Synthetix(associatedContract);

        // What is the value of the requested debt in XDRs?
        uint xdrValue = synthetix.effectiveValue("sUSD", amount, "XDR");

        // What is the value that we&#39;ve previously imported?
        uint totalDebtIssued = importedXDRAmount;

        // What will the new total be including the new value?
        uint newTotalDebtIssued = xdrValue.add(totalDebtIssued);

        // Save that for the next import.
        importedXDRAmount = newTotalDebtIssued;

        // What is their percentage (as a high precision int) of the total debt?
        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);

        // And what effect does this percentage have on the global debt holding of other issuers?
        // The delta specifically needs to not take into account any existing debt as it&#39;s already
        // accounted for in the delta from when they issued previously.
        // The delta is a high precision integer.
        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);

        uint existingDebt = synthetix.debtBalanceOf(account, "XDR");

        // And what does their debt ownership look like including this previous stake?
        if (existingDebt > 0) {
            debtPercentage = xdrValue.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }

        // Are they a new issuer? If so, record them.
        if (issuanceData[account].initialDebtOwnership == 0) {
            totalIssuerCount = totalIssuerCount.add(1);
        }

        // Save the debt entry parameters
        issuanceData[account].initialDebtOwnership = debtPercentage;
        issuanceData[account].debtEntryIndex = debtLedger.length;

        // And if we&#39;re the first, push 1 as there was no effect to any other holders, otherwise push
        // the change for the rest of the debt holders. The debt ledger holds high precision integers.
        if (debtLedger.length > 0) {
            debtLedger.push(
                debtLedger[debtLedger.length - 1].multiplyDecimalRoundPrecise(delta)
            );
        } else {
            debtLedger.push(SafeDecimalMath.preciseUnit());
        }
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieve the length of the debt ledger array
     */
    function debtLedgerLength()
        external
        view
        returns (uint)
    {
        return debtLedger.length;
    }

    /**
     * @notice Retrieve the most recent entry from the debt ledger
     */
    function lastDebtLedgerEntry()
        external
        view
        returns (uint)
    {
        return debtLedger[debtLedger.length - 1];
    }

    /**
     * @notice Query whether an account has issued and has an outstanding debt balance
     * @param account The address to query for
     */
    function hasIssued(address account)
        external
        view
        returns (bool)
    {
        return issuanceData[account].initialDebtOwnership > 0;
    }

    event IssuanceRatioUpdated(uint newRatio);
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ExchangeRates.sol
version:    1.0
author:     Kevin Brown
date:       2018-09-12

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract that any other contract in the Synthetix system can query
for the current market value of various assets, including
crypto assets as well as various fiat assets.

This contract assumes that rate updates will completely update
all rates to their current values. If a rate shock happens
on a single asset, the oracle will still push updated rates
for all other assets.

-----------------------------------------------------------------
*/


/**
 * @title The repository for exchange rates
 */
contract ExchangeRates is SelfDestructible {

    using SafeMath for uint;

    // Exchange rates stored by currency code, e.g. &#39;SNX&#39;, or &#39;sUSD&#39;
    mapping(bytes4 => uint) public rates;

    // Update times stored by currency code, e.g. &#39;SNX&#39;, or &#39;sUSD&#39;
    mapping(bytes4 => uint) public lastRateUpdateTimes;

    // The address of the oracle which pushes rate updates to this contract
    address public oracle;

    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;

    // How long will the contract assume the rate of any asset is correct
    uint public rateStalePeriod = 3 hours;

    // Each participating currency in the XDR basket is represented as a currency key with
    // equal weighting.
    // There are 5 participating currencies, so we&#39;ll declare that clearly.
    bytes4[5] public xdrParticipants;

    //
    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor
     * @param _owner The owner of this contract.
     * @param _oracle The address which is able to update rate information.
     * @param _currencyKeys The initial currency keys to store (in order).
     * @param _newRates The initial currency amounts for each currency (in order).
     */
    constructor(
        // SelfDestructible (Ownable)
        address _owner,

        // Oracle values - Allows for rate updates
        address _oracle,
        bytes4[] _currencyKeys,
        uint[] _newRates
    )
        /* Owned is initialised in SelfDestructible */
        SelfDestructible(_owner)
        public
    {
        require(_currencyKeys.length == _newRates.length, "Currency key length and rate length must match.");

        oracle = _oracle;

        // The sUSD rate is always 1 and is never stale.
        rates["sUSD"] = SafeDecimalMath.unit();
        lastRateUpdateTimes["sUSD"] = now;

        // These are the currencies that make up the XDR basket.
        // These are hard coded because:
        //  - This way users can depend on the calculation and know it won&#39;t change for this deployment of the contract.
        //  - Adding new currencies would likely introduce some kind of weighting factor, which
        //    isn&#39;t worth preemptively adding when all of the currencies in the current basket are weighted at 1.
        //  - The expectation is if this logic needs to be updated, we&#39;ll simply deploy a new version of this contract
        //    then point the system at the new version.
        xdrParticipants = [
            bytes4("sUSD"),
            bytes4("sAUD"),
            bytes4("sCHF"),
            bytes4("sEUR"),
            bytes4("sGBP")
        ];

        internalUpdateRates(_currencyKeys, _newRates, now);
    }

    /* ========== SETTERS ========== */

    /**
     * @notice Set the rates stored in this contract
     * @param currencyKeys The currency keys you wish to update the rates for (in order)
     * @param newRates The rates for each currency (in order)
     * @param timeSent The timestamp of when the update was sent, specified in seconds since epoch (e.g. the same as the now keyword in solidity).contract
     *                 This is useful because transactions can take a while to confirm, so this way we know how old the oracle&#39;s datapoint was exactly even
     *                 if it takes a long time for the transaction to confirm.
     */
    function updateRates(bytes4[] currencyKeys, uint[] newRates, uint timeSent)
        external
        onlyOracle
        returns(bool)
    {
        return internalUpdateRates(currencyKeys, newRates, timeSent);
    }

    /**
     * @notice Internal function which sets the rates stored in this contract
     * @param currencyKeys The currency keys you wish to update the rates for (in order)
     * @param newRates The rates for each currency (in order)
     * @param timeSent The timestamp of when the update was sent, specified in seconds since epoch (e.g. the same as the now keyword in solidity).contract
     *                 This is useful because transactions can take a while to confirm, so this way we know how old the oracle&#39;s datapoint was exactly even
     *                 if it takes a long time for the transaction to confirm.
     */
    function internalUpdateRates(bytes4[] currencyKeys, uint[] newRates, uint timeSent)
        internal
        returns(bool)
    {
        require(currencyKeys.length == newRates.length, "Currency key array length must match rates array length.");
        require(timeSent < (now + ORACLE_FUTURE_LIMIT), "Time is too far into the future");

        // Loop through each key and perform update.
        for (uint i = 0; i < currencyKeys.length; i++) {
            // Should not set any rate to zero ever, as no asset will ever be
            // truely worthless and still valid. In this scenario, we should
            // delete the rate and remove it from the system.
            require(newRates[i] != 0, "Zero is not a valid rate, please call deleteRate instead.");
            require(currencyKeys[i] != "sUSD", "Rate of sUSD cannot be updated, it&#39;s always UNIT.");

            // We should only update the rate if it&#39;s at least the same age as the last rate we&#39;ve got.
            if (timeSent >= lastRateUpdateTimes[currencyKeys[i]]) {
                // Ok, go ahead with the update.
                rates[currencyKeys[i]] = newRates[i];
                lastRateUpdateTimes[currencyKeys[i]] = timeSent;
            }
        }

        emit RatesUpdated(currencyKeys, newRates);

        // Now update our XDR rate.
        updateXDRRate(timeSent);

        return true;
    }

    /**
     * @notice Update the Synthetix Drawing Rights exchange rate based on other rates already updated.
     */
    function updateXDRRate(uint timeSent)
        internal
    {
        uint total = 0;

        for (uint i = 0; i < xdrParticipants.length; i++) {
            total = rates[xdrParticipants[i]].add(total);
        }

        // Set the rate
        rates["XDR"] = total;

        // Record that we updated the XDR rate.
        lastRateUpdateTimes["XDR"] = timeSent;

        // Emit our updated event separate to the others to save
        // moving data around between arrays.
        bytes4[] memory eventCurrencyCode = new bytes4[](1);
        eventCurrencyCode[0] = "XDR";

        uint[] memory eventRate = new uint[](1);
        eventRate[0] = rates["XDR"];

        emit RatesUpdated(eventCurrencyCode, eventRate);
    }

    /**
     * @notice Delete a rate stored in the contract
     * @param currencyKey The currency key you wish to delete the rate for
     */
    function deleteRate(bytes4 currencyKey)
        external
        onlyOracle
    {
        require(rates[currencyKey] > 0, "Rate is zero");

        delete rates[currencyKey];
        delete lastRateUpdateTimes[currencyKey];

        emit RateDeleted(currencyKey);
    }

    /**
     * @notice Set the Oracle that pushes the rate information to this contract
     * @param _oracle The new oracle address
     */
    function setOracle(address _oracle)
        external
        onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

    /**
     * @notice Set the stale period on the updated rate variables
     * @param _time The new rateStalePeriod
     */
    function setRateStalePeriod(uint _time)
        external
        onlyOwner
    {
        rateStalePeriod = _time;
        emit RateStalePeriodUpdated(rateStalePeriod);
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieve the rate for a specific currency
     */
    function rateForCurrency(bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        return rates[currencyKey];
    }

    /**
     * @notice Retrieve the rates for a list of currencies
     */
    function ratesForCurrencies(bytes4[] currencyKeys)
        public
        view
        returns (uint[])
    {
        uint[] memory _rates = new uint[](currencyKeys.length);

        for (uint8 i = 0; i < currencyKeys.length; i++) {
            _rates[i] = rates[currencyKeys[i]];
        }

        return _rates;
    }

    /**
     * @notice Retrieve a list of last update times for specific currencies
     */
    function lastRateUpdateTimeForCurrency(bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        return lastRateUpdateTimes[currencyKey];
    }

    /**
     * @notice Retrieve the last update time for a specific currency
     */
    function lastRateUpdateTimesForCurrencies(bytes4[] currencyKeys)
        public
        view
        returns (uint[])
    {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint8 i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = lastRateUpdateTimes[currencyKeys[i]];
        }

        return lastUpdateTimes;
    }

    /**
     * @notice Check if a specific currency&#39;s rate hasn&#39;t been updated for longer than the stale period.
     */
    function rateIsStale(bytes4 currencyKey)
        external
        view
        returns (bool)
    {
        // sUSD is a special case and is never stale.
        if (currencyKey == "sUSD") return false;

        return lastRateUpdateTimes[currencyKey].add(rateStalePeriod) < now;
    }

    /**
     * @notice Check if any of the currency rates passed in haven&#39;t been updated for longer than the stale period.
     */
    function anyRateIsStale(bytes4[] currencyKeys)
        external
        view
        returns (bool)
    {
        // Loop through each key and check whether the data point is stale.
        uint256 i = 0;

        while (i < currencyKeys.length) {
            // sUSD is a special case and is never false
            if (currencyKeys[i] != "sUSD" && lastRateUpdateTimes[currencyKeys[i]].add(rateStalePeriod) < now) {
                return true;
            }
            i += 1;
        }

        return false;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOracle
    {
        require(msg.sender == oracle, "Only the oracle can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event OracleUpdated(address newOracle);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    event RatesUpdated(bytes4[] currencyKeys, uint[] newRates);
    event RateDeleted(bytes4 currencyKey);
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Synthetix.sol
version:    2.0
author:     Kevin Brown
            Gavin Conway
date:       2018-09-14

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Synthetix token contract. SNX is a transferable ERC20 token,
and also give its holders the following privileges.
An owner of SNX has the right to issue synths in all synth flavours.

After a fee period terminates, the duration and fees collected for that
period are computed, and the next period begins. Thus an account may only
withdraw the fees owed to them for the previous period, and may only do
so once per period. Any unclaimed fees roll over into the common pot for
the next period.

== Average Balance Calculations ==

The fee entitlement of a synthetix holder is proportional to their average
issued synth balance over the last fee period. This is computed by
measuring the area under the graph of a user&#39;s issued synth balance over
time, and then when a new fee period begins, dividing through by the
duration of the fee period.

We need only update values when the balances of an account is modified.
This occurs when issuing or burning for issued synth balances,
and when transferring for synthetix balances. This is for efficiency,
and adds an implicit friction to interacting with SNX.
A synthetix holder pays for his own recomputation whenever he wants to change
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
the average SNX held so far is ((t-f)*s + (n-t)*p) / (n-f).
The complementary computations must be performed for both sender and
recipient.

Note that a transfer keeps global supply of SNX invariant.
The sum of all balances is constant, and unmodified by any transfer.
So the sum of all balances multiplied by the duration of a fee period is also
constant, and this is equivalent to the sum of the area of every user&#39;s
time/balance graph. Dividing through by that duration yields back the total
synthetix supply. So, at the end of a fee period, we really do yield a user&#39;s
average share in the synthetix supply over that period.

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
as the check that they have rolled over occurs only when state-changing synthetix
operations are performed.

== Issuance and Burning ==

In this version of the synthetix contract, synths can only be issued by
those that have been nominated by the synthetix foundation. Synths are assumed
to be valued at $1, as they are a stable unit of account.

All synths issued require a proportional value of SNX to be locked,
where the proportion is governed by the current issuance ratio. This
means for every $1 of SNX locked up, $(issuanceRatio) synths can be issued.
i.e. to issue 100 synths, 100/issuanceRatio dollars of SNX need to be locked up.

To determine the value of some amount of SNX(S), an oracle is used to push
the price of SNX (P_S) in dollars to the contract. The value of S
would then be: S * P_S.

Any SNX that are locked up by this issuance process cannot be transferred.
The amount that is locked floats based on the price of SNX. If the price
of SNX moves up, less SNX are locked, so they can be issued against,
or transferred freely. If the price of SNX moves down, more SNX are locked,
even going above the initial wallet balance.

-----------------------------------------------------------------
*/


/**
 * @title Synthetix ERC20 contract.
 * @notice The Synthetix contracts not only facilitates transfers, exchanges, and tracks balances,
 * but it also computes the quantity of fees each synthetix holder is entitled to.
 */
contract Synthetix is ExternStateToken {

    // ========== STATE VARIABLES ==========

    // Available Synths which can be used with the system
    Synth[] public availableSynths;
    mapping(bytes4 => Synth) public synths;

    FeePool public feePool;
    SynthetixEscrow public escrow;
    ExchangeRates public exchangeRates;
    SynthetixState public synthetixState;

    uint constant SYNTHETIX_SUPPLY = 1e8 * SafeDecimalMath.unit();
    string constant TOKEN_NAME = "Synthetix Network Token";
    string constant TOKEN_SYMBOL = "SNX";
    uint8 constant DECIMALS = 18;

    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor
     * @param _tokenState A pre-populated contract containing token balances.
     * If the provided address is 0x0, then a fresh one will be constructed with the contract owning all tokens.
     * @param _owner The owner of this contract.
     */
    constructor(address _proxy, TokenState _tokenState, SynthetixState _synthetixState,
        address _owner, ExchangeRates _exchangeRates, FeePool _feePool
    )
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, SYNTHETIX_SUPPLY, DECIMALS, _owner)
        public
    {
        synthetixState = _synthetixState;
        exchangeRates = _exchangeRates;
        feePool = _feePool;
    }

    // ========== SETTERS ========== */

    /**
     * @notice Add an associated Synth contract to the Synthetix system
     * @dev Only the contract owner may call this.
     */
    function addSynth(Synth synth)
        external
        optionalProxy_onlyOwner
    {
        bytes4 currencyKey = synth.currencyKey();

        require(synths[currencyKey] == Synth(0), "Synth already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;

        emitSynthAdded(currencyKey, synth);
    }

    /**
     * @notice Remove an associated Synth contract from the Synthetix system
     * @dev Only the contract owner may call this.
     */
    function removeSynth(bytes4 currencyKey)
        external
        optionalProxy_onlyOwner
    {
        require(synths[currencyKey] != address(0), "Synth does not exist");
        require(synths[currencyKey].totalSupply() == 0, "Synth supply exists");
        require(currencyKey != "XDR", "Cannot remove XDR synth");

        // Save the address we&#39;re removing for emitting the event at the end.
        address synthToRemove = synths[currencyKey];

        // Remove the synth from the availableSynths array.
        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == synthToRemove) {
                delete availableSynths[i];

                // Copy the last synth into the place of the one we just deleted
                // If there&#39;s only one synth, this is synths[0] = synths[0].
                // If we&#39;re deleting the last one, it&#39;s also a NOOP in the same way.
                availableSynths[i] = availableSynths[availableSynths.length - 1];

                // Decrease the size of the array by one.
                availableSynths.length--;

                break;
            }
        }

        // And remove it from the synths mapping
        delete synths[currencyKey];

        emitSynthRemoved(currencyKey, synthToRemove);
    }

    /**
     * @notice Set the associated synthetix escrow contract.
     * @dev Only the contract owner may call this.
     */
    function setEscrow(SynthetixEscrow _escrow)
        external
        optionalProxy_onlyOwner
    {
        escrow = _escrow;
        // Note: No event here as our contract exceeds max contract size
        // with these events, and it&#39;s unlikely people will need to
        // track these events specifically.
    }

    /**
     * @notice Set the ExchangeRates contract address where rates are held.
     * @dev Only callable by the contract owner.
     */
    function setExchangeRates(ExchangeRates _exchangeRates)
        external
        optionalProxy_onlyOwner
    {
        exchangeRates = _exchangeRates;
        // Note: No event here as our contract exceeds max contract size
        // with these events, and it&#39;s unlikely people will need to
        // track these events specifically.
    }

    /**
     * @notice Set the synthetixState contract address where issuance data is held.
     * @dev Only callable by the contract owner.
     */
    function setSynthetixState(SynthetixState _synthetixState)
        external
        optionalProxy_onlyOwner
    {
        synthetixState = _synthetixState;

        emitStateContractChanged(_synthetixState);
    }

    /**
     * @notice Set your preferred currency. Note: This does not automatically exchange any balances you&#39;ve held previously in
     * other synth currencies in this address, it will apply for any new payments you receive at this address.
     */
    function setPreferredCurrency(bytes4 currencyKey)
        external
        optionalProxy
    {
        require(currencyKey == 0 || !exchangeRates.rateIsStale(currencyKey), "Currency rate is stale or doesn&#39;t exist.");

        synthetixState.setPreferredCurrency(messageSender, currencyKey);

        emitPreferredCurrencyChanged(messageSender, currencyKey);
    }

    // ========== VIEWS ==========

    /**
     * @notice A function that lets you easily convert an amount in a source currency to an amount in the destination currency
     * @param sourceCurrencyKey The currency the amount is specified in
     * @param sourceAmount The source amount, specified in UNIT base
     * @param destinationCurrencyKey The destination currency
     */
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey)
        public
        view
        rateNotStale(sourceCurrencyKey)
        rateNotStale(destinationCurrencyKey)
        returns (uint)
    {
        // If there&#39;s no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

        // Calculate the effective value by going from source -> USD -> destination
        return sourceAmount.multiplyDecimalRound(exchangeRates.rateForCurrency(sourceCurrencyKey))
            .divideDecimalRound(exchangeRates.rateForCurrency(destinationCurrencyKey));
    }

    /**
     * @notice Total amount of synths issued by the system, priced in currencyKey
     * @param currencyKey The currency to value the synths in
     */
    function totalIssuedSynths(bytes4 currencyKey)
        public
        view
        rateNotStale(currencyKey)
        returns (uint)
    {
        uint total = 0;
        uint currencyRate = exchangeRates.rateForCurrency(currencyKey);

        for (uint8 i = 0; i < availableSynths.length; i++) {
            // Ensure the rate isn&#39;t stale.
            // TODO: Investigate gas cost optimisation of doing a single call with all keys in it vs
            // individual calls like this.
            require(!exchangeRates.rateIsStale(availableSynths[i].currencyKey()), "Rate is stale");

            // What&#39;s the total issued value of that synth in the destination currency?
            // Note: We&#39;re not using our effectiveValue function because we don&#39;t want to go get the
            //       rate for the destination currency and check if it&#39;s stale repeatedly on every
            //       iteration of the loop
            uint synthValue = availableSynths[i].totalSupply()
                .multiplyDecimalRound(exchangeRates.rateForCurrency(availableSynths[i].currencyKey()))
                .divideDecimalRound(currencyRate);
            total = total.add(synthValue);
        }

        return total;
    }

    /**
     * @notice Returns the count of available synths in the system, which you can use to iterate availableSynths
     */
    function availableSynthCount()
        public
        view
        returns (uint)
    {
        return availableSynths.length;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    /**
     * @notice ERC20 transfer function.
     */
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    /**
     * @notice ERC223 transfer function. Does not conform with the ERC223 spec, as:
     *         - Transaction doesn&#39;t revert if the recipient doesn&#39;t implement tokenFallback()
     *         - Emits a standard ERC20 event without the bytes data parameter so as not to confuse
     *           tooling such as Etherscan.
     */
    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
        // Ensure they&#39;re not trying to exceed their locked amount
        require(value <= transferableSynthetix(messageSender), "Insufficient balance");

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transfer_byProxy(messageSender, to, value, data);

        return true;
    }

    /**
     * @notice ERC20 transferFrom function.
     */
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transferFrom(from, to, value, empty);
    }

    /**
     * @notice ERC223 transferFrom function. Does not conform with the ERC223 spec, as:
     *         - Transaction doesn&#39;t revert if the recipient doesn&#39;t implement tokenFallback()
     *         - Emits a standard ERC20 event without the bytes data parameter so as not to confuse
     *           tooling such as Etherscan.
     */
    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
        // Ensure they&#39;re not trying to exceed their locked amount
        require(value <= transferableSynthetix(from), "Insufficient balance");

        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        _transferFrom_byProxy(messageSender, from, to, value, data);

        return true;
    }

    /**
     * @notice Function that allows you to exchange synths you hold in one flavour for another.
     * @param sourceCurrencyKey The source currency you wish to exchange from
     * @param sourceAmount The amount, specified in UNIT of source currency you wish to exchange
     * @param destinationCurrencyKey The destination currency you wish to obtain.
     * @param destinationAddress Where the result should go. If this is address(0) then it sends back to the message sender.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function exchange(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey, address destinationAddress)
        external
        optionalProxy
        // Note: We don&#39;t need to insist on non-stale rates because effectiveValue will do it for us.
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Exchange must use different synths");
        require(sourceAmount > 0, "Zero amount");

        // Pass it along, defaulting to the sender as the recipient.
        return _internalExchange(
            messageSender,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress == address(0) ? messageSender : destinationAddress,
            true // Charge fee on the exchange
        );
    }

    /**
     * @notice Function that allows synth contract to delegate exchanging of a synth that is not the same sourceCurrency
     * @dev Only the synth contract can call this function
     * @param from The address to exchange / burn synth from
     * @param sourceCurrencyKey The source currency you wish to exchange from
     * @param sourceAmount The amount, specified in UNIT of source currency you wish to exchange
     * @param destinationCurrencyKey The destination currency you wish to obtain.
     * @param destinationAddress Where the result should go.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function synthInitiatedExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress
    )
        external
        onlySynth
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can&#39;t be same synth");
        require(sourceAmount > 0, "Zero amount");

        // Pass it along
        return _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress,
            false // Don&#39;t charge fee on the exchange, as they&#39;ve already been charged a transfer fee in the synth contract
        );
    }

    /**
     * @notice Function that allows synth contract to delegate sending fee to the fee Pool.
     * @dev Only the synth contract can call this function.
     * @param from The address fee is coming from.
     * @param sourceCurrencyKey source currency fee from.
     * @param sourceAmount The amount, specified in UNIT of source currency.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function synthInitiatedFeePayment(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount
    )
        external
        onlySynth
        returns (bool)
    {
        require(sourceAmount > 0, "Source can&#39;t be 0");

        // Pass it along, defaulting to the sender as the recipient.
        bool result = _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            "XDR",
            feePool.FEE_ADDRESS(),
            false // Don&#39;t charge a fee on the exchange because this is already a fee
        );

        // Tell the fee pool about this.
        feePool.feePaid(sourceCurrencyKey, sourceAmount);

        return result;
    }

    /**
     * @notice Function that allows synth contract to delegate sending fee to the fee Pool.
     * @dev fee pool contract address is not allowed to call function
     * @param from The address to move synth from
     * @param sourceCurrencyKey source currency from.
     * @param sourceAmount The amount, specified in UNIT of source currency.
     * @param destinationCurrencyKey The destination currency to obtain.
     * @param destinationAddress Where the result should go.
     * @param chargeFee Boolean to charge a fee for transaction.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function _internalExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress,
        bool chargeFee
    )
        internal
        notFeeAddress(from)
        returns (bool)
    {
        require(destinationAddress != address(0), "Zero destination");
        require(destinationAddress != address(this), "Synthetix is invalid destination");
        require(destinationAddress != address(proxy), "Proxy is invalid destination");

        // Note: We don&#39;t need to check their balance as the burn() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.

        // Burn the source amount
        synths[sourceCurrencyKey].burn(from, sourceAmount);

        // How much should they get in the destination currency?
        uint destinationAmount = effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        // What&#39;s the fee on that currency that we should deduct?
        uint amountReceived = destinationAmount;
        uint fee = 0;

        if (chargeFee) {
            amountReceived = feePool.amountReceivedFromExchange(destinationAmount);
            fee = destinationAmount.sub(amountReceived);
        }

        // Issue their new synths
        synths[destinationCurrencyKey].issue(destinationAddress, amountReceived);

        // Remit the fee in XDRs
        if (fee > 0) {
            uint xdrFeeAmount = effectiveValue(destinationCurrencyKey, fee, "XDR");
            synths["XDR"].issue(feePool.FEE_ADDRESS(), xdrFeeAmount);
        }

        // Nothing changes as far as issuance data goes because the total value in the system hasn&#39;t changed.

        // Call the ERC223 transfer callback if needed
        synths[destinationCurrencyKey].triggerTokenFallbackIfNeeded(from, destinationAddress, amountReceived);

        // Gas optimisation:
        // No event emitted as it&#39;s assumed users will be able to track transfers to the zero address, followed
        // by a transfer on another synth from the zero address and ascertain the info required here.

        return true;
    }

    /**
     * @notice Function that registers new synth as they are isseud. Calculate delta to append to synthetixState.
     * @dev Only internal calls from synthetix address.
     * @param currencyKey The currency to register synths in, for example sUSD or sAUD
     * @param amount The amount of synths to register with a base of UNIT
     */
    function _addToDebtRegister(bytes4 currencyKey, uint amount)
        internal
        optionalProxy
    {
        // What is the value of the requested debt in XDRs?
        uint xdrValue = effectiveValue(currencyKey, amount, "XDR");

        // What is the value of all issued synths of the system (priced in XDRs)?
        uint totalDebtIssued = totalIssuedSynths("XDR");

        // What will the new total be including the new value?
        uint newTotalDebtIssued = xdrValue.add(totalDebtIssued);

        // What is their percentage (as a high precision int) of the total debt?
        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);

        // And what effect does this percentage have on the global debt holding of other issuers?
        // The delta specifically needs to not take into account any existing debt as it&#39;s already
        // accounted for in the delta from when they issued previously.
        // The delta is a high precision integer.
        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);

        // How much existing debt do they have?
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

        // And what does their debt ownership look like including this previous stake?
        if (existingDebt > 0) {
            debtPercentage = xdrValue.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }

        // Are they a new issuer? If so, record them.
        if (!synthetixState.hasIssued(messageSender)) {
            synthetixState.incrementTotalIssuerCount();
        }

        // Save the debt entry parameters
        synthetixState.setCurrentIssuanceData(messageSender, debtPercentage);

        // And if we&#39;re the first, push 1 as there was no effect to any other holders, otherwise push
        // the change for the rest of the debt holders. The debt ledger holds high precision integers.
        if (synthetixState.debtLedgerLength() > 0) {
            synthetixState.appendDebtLedgerValue(
                synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
            );
        } else {
            synthetixState.appendDebtLedgerValue(SafeDecimalMath.preciseUnit());
        }
    }

    /**
     * @notice Issue synths against the sender&#39;s SNX.
     * @dev Issuance is only allowed if the synthetix price isn&#39;t stale. Amount should be larger than 0.
     * @param currencyKey The currency you wish to issue synths in, for example sUSD or sAUD
     * @param amount The amount of synths you wish to issue with a base of UNIT
     */
    function issueSynths(bytes4 currencyKey, uint amount)
        public
        optionalProxy
        nonZeroAmount(amount)
        // No need to check if price is stale, as it is checked in issuableSynths.
    {
        require(amount <= remainingIssuableSynths(messageSender, currencyKey), "Amount too large");

        // Keep track of the debt they&#39;re about to create
        _addToDebtRegister(currencyKey, amount);

        // Create their synths
        synths[currencyKey].issue(messageSender, amount);
    }

    /**
     * @notice Issue the maximum amount of Synths possible against the sender&#39;s SNX.
     * @dev Issuance is only allowed if the synthetix price isn&#39;t stale.
     * @param currencyKey The currency you wish to issue synths in, for example sUSD or sAUD
     */
    function issueMaxSynths(bytes4 currencyKey)
        external
        optionalProxy
    {
        // Figure out the maximum we can issue in that currency
        uint maxIssuable = remainingIssuableSynths(messageSender, currencyKey);

        // And issue them
        issueSynths(currencyKey, maxIssuable);
    }

    /**
     * @notice Burn synths to clear issued synths/free SNX.
     * @param currencyKey The currency you&#39;re specifying to burn
     * @param amount The amount (in UNIT base) you wish to burn
     */
    function burnSynths(bytes4 currencyKey, uint amount)
        external
        optionalProxy
        // No need to check for stale rates as _removeFromDebtRegister calls effectiveValue
        // which does this for us
    {
        // How much debt do they have?
        uint debt = debtBalanceOf(messageSender, currencyKey);

        require(debt > 0, "No debt to forgive");

        // If they&#39;re trying to burn more debt than they actually owe, rather than fail the transaction, let&#39;s just
        // clear their debt and leave them be.
        uint amountToBurn = debt < amount ? debt : amount;

        // Remove their debt from the ledger
        _removeFromDebtRegister(currencyKey, amountToBurn);

        // synth.burn does a safe subtraction on balance (so it will revert if there are not enough synths).
        synths[currencyKey].burn(messageSender, amountToBurn);
    }

    /**
     * @notice Remove a debt position from the register
     * @param currencyKey The currency the user is presenting to forgive their debt
     * @param amount The amount (in UNIT base) being presented
     */
    function _removeFromDebtRegister(bytes4 currencyKey, uint amount)
        internal
    {
        // How much debt are they trying to remove in XDRs?
        uint debtToRemove = effectiveValue(currencyKey, amount, "XDR");

        // How much debt do they have?
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

        // What percentage of the total debt are they trying to remove?
        uint totalDebtIssued = totalIssuedSynths("XDR");
        uint debtPercentage = debtToRemove.divideDecimalRoundPrecise(totalDebtIssued);

        // And what effect does this percentage have on the global debt holding of other issuers?
        // The delta specifically needs to not take into account any existing debt as it&#39;s already
        // accounted for in the delta from when they issued previously.
        uint delta = SafeDecimalMath.preciseUnit().add(debtPercentage);

        // Are they exiting the system, or are they just decreasing their debt position?
        if (debtToRemove == existingDebt) {
            synthetixState.clearIssuanceData(messageSender);
            synthetixState.decrementTotalIssuerCount();
        } else {
            // What percentage of the debt will they be left with?
            uint newDebt = existingDebt.sub(debtToRemove);
            uint newTotalDebtIssued = totalDebtIssued.sub(debtToRemove);
            uint newDebtPercentage = newDebt.divideDecimalRoundPrecise(newTotalDebtIssued);

            // Store the debt percentage and debt ledger as high precision integers
            synthetixState.setCurrentIssuanceData(messageSender, newDebtPercentage);
        }

        // Update our cumulative ledger. This is also a high precision integer.
        synthetixState.appendDebtLedgerValue(
            synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
        );
    }

    // ========== Issuance/Burning ==========

    /**
     * @notice The maximum synths an issuer can issue against their total synthetix quantity, priced in XDRs.
     * This ignores any already issued synths, and is purely giving you the maximimum amount the user can issue.
     */
    function maxIssuableSynths(address issuer, bytes4 currencyKey)
        public
        view
        // We don&#39;t need to check stale rates here as effectiveValue will do it for us.
        returns (uint)
    {
        // What is the value of their SNX balance in the destination currency?
        uint destinationValue = effectiveValue("SNX", collateral(issuer), currencyKey);

        // They&#39;re allowed to issue up to issuanceRatio of that value
        return destinationValue.multiplyDecimal(synthetixState.issuanceRatio());
    }

    /**
     * @notice The current collateralisation ratio for a user. Collateralisation ratio varies over time
     * as the value of the underlying Synthetix asset changes, e.g. if a user issues their maximum available
     * synths when they hold $10 worth of Synthetix, they will have issued $2 worth of synths. If the value
     * of Synthetix changes, the ratio returned by this function will adjust accordlingly. Users are
     * incentivised to maintain a collateralisation ratio as close to the issuance ratio as possible by
     * altering the amount of fees they&#39;re able to claim from the system.
     */
    function collateralisationRatio(address issuer)
        public
        view
        returns (uint)
    {
        uint totalOwnedSynthetix = collateral(issuer);
        if (totalOwnedSynthetix == 0) return 0;

        uint debtBalance = debtBalanceOf(issuer, "SNX");
        return debtBalance.divideDecimalRound(totalOwnedSynthetix);
    }

/**
     * @notice If a user issues synths backed by SNX in their wallet, the SNX become locked. This function
     * will tell you how many synths a user has to give back to the system in order to unlock their original
     * debt position. This is priced in whichever synth is passed in as a currency key, e.g. you can price
     * the debt in sUSD, XDR, or any other synth you wish.
     */
    function debtBalanceOf(address issuer, bytes4 currencyKey)
        public
        view
        // Don&#39;t need to check for stale rates here because totalIssuedSynths will do it for us
        returns (uint)
    {
        // What was their initial debt ownership?
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(issuer);

        // If it&#39;s zero, they haven&#39;t issued, and they have no debt.
        if (initialDebtOwnership == 0) return 0;

        // Figure out the global debt percentage delta from when they entered the system.
        // This is a high precision integer.
        uint currentDebtOwnership = synthetixState.lastDebtLedgerEntry()
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(initialDebtOwnership);

        // What&#39;s the total value of the system in their requested currency?
        uint totalSystemValue = totalIssuedSynths(currencyKey);

        // Their debt balance is their portion of the total system value.
        uint highPrecisionBalance = totalSystemValue.decimalToPreciseDecimal()
            .multiplyDecimalRoundPrecise(currentDebtOwnership);

        return highPrecisionBalance.preciseDecimalToDecimal();
    }

    /**
     * @notice The remaining synths an issuer can issue against their total synthetix balance.
     * @param issuer The account that intends to issue
     * @param currencyKey The currency to price issuable value in
     */
    function remainingIssuableSynths(address issuer, bytes4 currencyKey)
        public
        view
        // Don&#39;t need to check for synth existing or stale rates because maxIssuableSynths will do it for us.
        returns (uint)
    {
        uint alreadyIssued = debtBalanceOf(issuer, currencyKey);
        uint max = maxIssuableSynths(issuer, currencyKey);

        if (alreadyIssued >= max) {
            return 0;
        } else {
            return max.sub(alreadyIssued);
        }
    }

    /**
     * @notice The total SNX owned by this account, both escrowed and unescrowed,
     * against which synths can be issued.
     * This includes those already being used as collateral (locked), and those
     * available for further issuance (unlocked).
     */
    function collateral(address account)
        public
        view
        returns (uint)
    {
        uint balance = tokenState.balanceOf(account);

        if (escrow != address(0)) {
            balance = balance.add(escrow.balanceOf(account));
        }

        return balance;
    }

    /**
     * @notice The number of SNX that are free to be transferred by an account.
     * @dev When issuing, escrowed SNX are locked first, then non-escrowed
     * SNX are locked last, but escrowed SNX are not transferable, so they are not included
     * in this calculation.
     */
    function transferableSynthetix(address account)
        public
        view
        rateNotStale("SNX")
        returns (uint)
    {
        // How many SNX do they have, excluding escrow?
        // Note: We&#39;re excluding escrow here because we&#39;re interested in their transferable amount
        // and escrowed SNX are not transferable.
        uint balance = tokenState.balanceOf(account);

        // How many of those will be locked by the amount they&#39;ve issued?
        // Assuming issuance ratio is 20%, then issuing 20 SNX of value would require
        // 100 SNX to be locked in their wallet to maintain their collateralisation ratio
        // The locked synthetix value can exceed their balance.
        uint lockedSynthetixValue = debtBalanceOf(account, "SNX").divideDecimalRound(synthetixState.issuanceRatio());

        // If we exceed the balance, no SNX are transferable, otherwise the difference is.
        if (lockedSynthetixValue >= balance) {
            return 0;
        } else {
            return balance.sub(lockedSynthetixValue);
        }
    }

    // ========== MODIFIERS ==========

    modifier rateNotStale(bytes4 currencyKey) {
        require(!exchangeRates.rateIsStale(currencyKey), "Rate stale or nonexistant currency");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Fee address not allowed");
        _;
    }

    modifier onlySynth() {
        bool isSynth = false;

        // No need to repeatedly call this function either
        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == msg.sender) {
                isSynth = true;
                break;
            }
        }

        require(isSynth, "Only synth allowed");
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount > 0, "Amount needs to be larger than 0");
        _;
    }

    // ========== EVENTS ==========

    event PreferredCurrencyChanged(address indexed account, bytes4 newPreferredCurrency);
    bytes32 constant PREFERREDCURRENCYCHANGED_SIG = keccak256("PreferredCurrencyChanged(address,bytes4)");
    function emitPreferredCurrencyChanged(address account, bytes4 newPreferredCurrency) internal {
        proxy._emit(abi.encode(newPreferredCurrency), 2, PREFERREDCURRENCYCHANGED_SIG, bytes32(account), 0, 0);
    }

    event StateContractChanged(address stateContract);
    bytes32 constant STATECONTRACTCHANGED_SIG = keccak256("StateContractChanged(address)");
    function emitStateContractChanged(address stateContract) internal {
        proxy._emit(abi.encode(stateContract), 1, STATECONTRACTCHANGED_SIG, 0, 0, 0);
    }

    event SynthAdded(bytes4 currencyKey, address newSynth);
    bytes32 constant SYNTHADDED_SIG = keccak256("SynthAdded(bytes4,address)");
    function emitSynthAdded(bytes4 currencyKey, address newSynth) internal {
        proxy._emit(abi.encode(currencyKey, newSynth), 1, SYNTHADDED_SIG, 0, 0, 0);
    }

    event SynthRemoved(bytes4 currencyKey, address removedSynth);
    bytes32 constant SYNTHREMOVED_SIG = keccak256("SynthRemoved(bytes4,address)");
    function emitSynthRemoved(bytes4 currencyKey, address removedSynth) internal {
        proxy._emit(abi.encode(currencyKey, removedSynth), 1, SYNTHREMOVED_SIG, 0, 0, 0);
    }
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       FeePool.sol
version:    1.0
author:     Kevin Brown
date:       2018-10-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The FeePool is a place for users to interact with the fees that
have been generated from the Synthetix system if they&#39;ve helped
to create the economy.

Users stake Synthetix to create Synths. As Synth users transact,
a small fee is deducted from each transaction, which collects
in the fee pool. Fees are immediately converted to XDRs, a type
of reserve currency similar to SDRs used by the IMF:
https://www.imf.org/en/About/Factsheets/Sheets/2016/08/01/14/51/Special-Drawing-Right-SDR

Users are entitled to withdraw fees from periods that they participated
in fully, e.g. they have to stake before the period starts. They
can withdraw fees for the last 6 periods as a single lump sum.
Currently fee periods are 7 days long, meaning it&#39;s assumed
users will withdraw their fees approximately once a month. Fees
which are not withdrawn are redistributed to the whole pool,
enabling these non-claimed fees to go back to the rest of the commmunity.

Fees can be withdrawn in any synth currency.

-----------------------------------------------------------------
*/


contract FeePool is Proxyable, SelfDestructible {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    Synthetix public synthetix;

    // A percentage fee charged on each transfer.
    uint public transferFeeRate;

    // Transfer fee may not exceed 10%.
    uint constant public MAX_TRANSFER_FEE_RATE = SafeDecimalMath.unit() / 10;

    // A percentage fee charged on each exchange between currencies.
    uint public exchangeFeeRate;

    // Exchange fee may not exceed 10%.
    uint constant public MAX_EXCHANGE_FEE_RATE = SafeDecimalMath.unit() / 10;

    // The address with the authority to distribute fees.
    address public feeAuthority;

    // Where fees are pooled in XDRs.
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    // This struct represents the issuance activity that&#39;s happened in a fee period.
    struct FeePeriod {
        uint feePeriodId;
        uint startingDebtIndex;
        uint startTime;
        uint feesToDistribute;
        uint feesClaimed;
    }

    // The last 6 fee periods are all that you can claim from.
    // These are stored and managed from [0], such that [0] is always
    // the most recent fee period, and [5] is always the oldest fee
    // period that users can claim for.
    uint8 constant public FEE_PERIOD_LENGTH = 6;
    FeePeriod[FEE_PERIOD_LENGTH] public recentFeePeriods;

    // The next fee period will have this ID.
    uint public nextFeePeriodId;

    // How long a fee period lasts at a minimum. It is required for the
    // fee authority to roll over the periods, so they are not guaranteed
    // to roll over at exactly this duration, but the contract enforces
    // that they cannot roll over any quicker than this duration.
    uint public feePeriodDuration = 1 weeks;

    // The fee period must be between 1 day and 60 days.
    uint public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint public constant MAX_FEE_PERIOD_DURATION = 60 days;

    // The last period a user has withdrawn their fees in, identified by the feePeriodId
    mapping(address => uint) public lastFeeWithdrawal;

    // Users receive penalties if their collateralisation ratio drifts out of our desired brackets
    // We precompute the brackets and penalties to save gas.
    uint constant TWENTY_PERCENT = (20 * SafeDecimalMath.unit()) / 100;
    uint constant TWENTY_FIVE_PERCENT = (25 * SafeDecimalMath.unit()) / 100;
    uint constant THIRTY_PERCENT = (30 * SafeDecimalMath.unit()) / 100;
    uint constant FOURTY_PERCENT = (40 * SafeDecimalMath.unit()) / 100;
    uint constant FIFTY_PERCENT = (50 * SafeDecimalMath.unit()) / 100;
    uint constant SEVENTY_FIVE_PERCENT = (75 * SafeDecimalMath.unit()) / 100;

    constructor(address _proxy, address _owner, Synthetix _synthetix, address _feeAuthority, uint _transferFeeRate, uint _exchangeFeeRate)
        SelfDestructible(_owner)
        Proxyable(_proxy, _owner)
        public
    {
        // Constructed fee rates should respect the maximum fee rates.
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Constructed transfer fee rate should respect the maximum fee rate");
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "Constructed exchange fee rate should respect the maximum fee rate");

        synthetix = _synthetix;
        feeAuthority = _feeAuthority;
        transferFeeRate = _transferFeeRate;
        exchangeFeeRate = _exchangeFeeRate;

        // Set our initial fee period
        recentFeePeriods[0].feePeriodId = 1;
        recentFeePeriods[0].startTime = now;
        // Gas optimisation: These do not need to be initialised. They start at 0.
        // recentFeePeriods[0].startingDebtIndex = 0;
        // recentFeePeriods[0].feesToDistribute = 0;

        // And the next one starts at 2.
        nextFeePeriodId = 2;
    }

    /**
     * @notice Set the exchange fee, anywhere within the range 0-10%.
     * @dev The fee rate is in decimal format, with UNIT being the value of 100%.
     */
    function setExchangeFeeRate(uint _exchangeFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "Exchange fee rate must be below MAX_EXCHANGE_FEE_RATE");

        exchangeFeeRate = _exchangeFeeRate;

        emitExchangeFeeUpdated(_exchangeFeeRate);
    }

    /**
     * @notice Set the transfer fee, anywhere within the range 0-10%.
     * @dev The fee rate is in decimal format, with UNIT being the value of 100%.
     */
    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Transfer fee rate must be below MAX_TRANSFER_FEE_RATE");

        transferFeeRate = _transferFeeRate;

        emitTransferFeeUpdated(_transferFeeRate);
    }

    /**
     * @notice Set the address of the user/contract responsible for collecting or
     * distributing fees.
     */
    function setFeeAuthority(address _feeAuthority)
        external
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;

        emitFeeAuthorityUpdated(_feeAuthority);
    }

    /**
     * @notice Set the fee period duration
     */
    function setFeePeriodDuration(uint _feePeriodDuration)
        external
        optionalProxy_onlyOwner
    {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "New fee period cannot be less than minimum fee period duration");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "New fee period cannot be greater than maximum fee period duration");

        feePeriodDuration = _feePeriodDuration;

        emitFeePeriodDurationUpdated(_feePeriodDuration);
    }

    /**
     * @notice Set the synthetix contract
     */
    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        require(address(_synthetix) != address(0), "New Synthetix must be non-zero");

        synthetix = _synthetix;

        emitSynthetixUpdated(_synthetix);
    }

    /**
     * @notice The Synthetix contract informs us when fees are paid.
     */
    function feePaid(bytes4 currencyKey, uint amount)
        external
        onlySynthetix
    {
        uint xdrAmount = synthetix.effectiveValue(currencyKey, amount, "XDR");

        // Which we keep track of in XDRs in our fee pool.
        recentFeePeriods[0].feesToDistribute = recentFeePeriods[0].feesToDistribute.add(xdrAmount);
    }

    /**
     * @notice Close the current fee period and start a new one. Only callable by the fee authority.
     */
    function closeCurrentFeePeriod()
        external
        onlyFeeAuthority
    {
        require(recentFeePeriods[0].startTime <= (now - feePeriodDuration), "It is too early to close the current fee period");

        FeePeriod memory secondLastFeePeriod = recentFeePeriods[FEE_PERIOD_LENGTH - 2];
        FeePeriod memory lastFeePeriod = recentFeePeriods[FEE_PERIOD_LENGTH - 1];

        // Any unclaimed fees from the last period in the array roll back one period.
        // Because of the subtraction here, they&#39;re effectively proportionally redistributed to those who
        // have already claimed from the old period, available in the new period.
        // The subtraction is important so we don&#39;t create a ticking time bomb of an ever growing
        // number of fees that can never decrease and will eventually overflow at the end of the fee pool.
        recentFeePeriods[FEE_PERIOD_LENGTH - 2].feesToDistribute = lastFeePeriod.feesToDistribute
            .sub(lastFeePeriod.feesClaimed)
            .add(secondLastFeePeriod.feesToDistribute);

        // Shift the previous fee periods across to make room for the new one.
        // Condition checks for overflow when uint subtracts one from zero
        // Could be written with int instead of uint, but then we have to convert everywhere
        // so it felt better from a gas perspective to just change the condition to check
        // for overflow after subtracting one from zero.
        for (uint i = FEE_PERIOD_LENGTH - 2; i < FEE_PERIOD_LENGTH; i--) {
            uint next = i + 1;

            recentFeePeriods[next].feePeriodId = recentFeePeriods[i].feePeriodId;
            recentFeePeriods[next].startingDebtIndex = recentFeePeriods[i].startingDebtIndex;
            recentFeePeriods[next].startTime = recentFeePeriods[i].startTime;
            recentFeePeriods[next].feesToDistribute = recentFeePeriods[i].feesToDistribute;
            recentFeePeriods[next].feesClaimed = recentFeePeriods[i].feesClaimed;
        }

        // Clear the first element of the array to make sure we don&#39;t have any stale values.
        delete recentFeePeriods[0];

        // Open up the new fee period
        recentFeePeriods[0].feePeriodId = nextFeePeriodId;
        recentFeePeriods[0].startingDebtIndex = synthetix.synthetixState().debtLedgerLength();
        recentFeePeriods[0].startTime = now;

        nextFeePeriodId = nextFeePeriodId.add(1);

        emitFeePeriodClosed(recentFeePeriods[1].feePeriodId);
    }

    /**
    * @notice Claim fees for last period when available or not already withdrawn.
    * @param currencyKey Synth currency you wish to receive the fees in.
    */
    function claimFees(bytes4 currencyKey)
        external
        optionalProxy
        returns (bool)
    {
        uint availableFees = feesAvailable(messageSender, "XDR");

        require(availableFees > 0, "No fees available for period, or fees already claimed");

        lastFeeWithdrawal[messageSender] = recentFeePeriods[1].feePeriodId;

        // Record the fee payment in our recentFeePeriods
        _recordFeePayment(availableFees);

        // Send them their fees
        _payFees(messageSender, availableFees, currencyKey);

        emitFeesClaimed(messageSender, availableFees);

        return true;
    }

    /**
     * @notice Record the fee payment in our recentFeePeriods.
     * @param xdrAmount The amout of fees priced in XDRs.
     */
    function _recordFeePayment(uint xdrAmount)
        internal
    {
        // Don&#39;t assign to the parameter
        uint remainingToAllocate = xdrAmount;

        // Start at the oldest period and record the amount, moving to newer periods
        // until we&#39;ve exhausted the amount.
        // The condition checks for overflow because we&#39;re going to 0 with an unsigned int.
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint delta = recentFeePeriods[i].feesToDistribute.sub(recentFeePeriods[i].feesClaimed);

            if (delta > 0) {
                // Take the smaller of the amount left to claim in the period and the amount we need to allocate
                uint amountInPeriod = delta < remainingToAllocate ? delta : remainingToAllocate;

                recentFeePeriods[i].feesClaimed = recentFeePeriods[i].feesClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);

                // No need to continue iterating if we&#39;ve recorded the whole amount;
                if (remainingToAllocate == 0) return;
            }
        }

        // If we hit this line, we&#39;ve exhausted our fee periods, but still have more to allocate. Wat?
        // If this happens it&#39;s a definite bug in the code, so assert instead of require.
        assert(remainingToAllocate == 0);
    }

    /**
    * @notice Send the fees to claiming address.
    * @param account The address to send the fees to.
    * @param xdrAmount The amount of fees priced in XDRs.
    * @param destinationCurrencyKey The synth currency the user wishes to receive their fees in (convert to this currency).
    */
    function _payFees(address account, uint xdrAmount, bytes4 destinationCurrencyKey)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can&#39;t be 0");
        require(account != address(this), "Can&#39;t send fees to fee pool");
        require(account != address(proxy), "Can&#39;t send fees to proxy");
        require(account != address(synthetix), "Can&#39;t send fees to synthetix");

        Synth xdrSynth = synthetix.synths("XDR");
        Synth destinationSynth = synthetix.synths(destinationCurrencyKey);

        // Note: We don&#39;t need to check the fee pool balance as the burn() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if the balance is not sufficient.

        // Burn the source amount
        xdrSynth.burn(FEE_ADDRESS, xdrAmount);

        // How much should they get in the destination currency?
        uint destinationAmount = synthetix.effectiveValue("XDR", xdrAmount, destinationCurrencyKey);

        // There&#39;s no fee on withdrawing fees, as that&#39;d be way too meta.

        // Mint their new synths
        destinationSynth.issue(account, destinationAmount);

        // Nothing changes as far as issuance data goes because the total value in the system hasn&#39;t changed.

        // Call the ERC223 transfer callback if needed
        destinationSynth.triggerTokenFallbackIfNeeded(FEE_ADDRESS, account, destinationAmount);
    }

    /**
     * @notice Calculate the Fee charged on top of a value being sent
     * @return Return the fee charged
     */
    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(transferFeeRate);

        // Transfers less than the reciprocal of transferFeeRate should be completely eaten up by fees.
        // This is on the basis that transfers less than this value will result in a nil fee.
        // Probably too insignificant to worry about, but the following code will achieve it.
        //      if (fee == 0 && transferFeeRate != 0) {
        //          return _value;
        //      }
        //      return fee;
    }

    /**
     * @notice The value that you would need to send so that the recipient receives
     * a specified value.
     * @param value The value you want the recipient to receive
     */
    function transferredAmountToReceive(uint value)
        external
        view
        returns (uint)
    {
        return value.add(transferFeeIncurred(value));
    }

    /**
     * @notice The amount the recipient will receive if you send a certain number of tokens.
     * @param value The amount of tokens you intend to send.
     */
    function amountReceivedFromTransfer(uint value)
        external
        view
        returns (uint)
    {
        return value.divideDecimal(transferFeeRate.add(SafeDecimalMath.unit()));
    }

    /**
     * @notice Calculate the fee charged on top of a value being sent via an exchange
     * @return Return the fee charged
     */
    function exchangeFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(exchangeFeeRate);

        // Exchanges less than the reciprocal of exchangeFeeRate should be completely eaten up by fees.
        // This is on the basis that exchanges less than this value will result in a nil fee.
        // Probably too insignificant to worry about, but the following code will achieve it.
        //      if (fee == 0 && exchangeFeeRate != 0) {
        //          return _value;
        //      }
        //      return fee;
    }

    /**
     * @notice The value that you would need to get after currency exchange so that the recipient receives
     * a specified value.
     * @param value The value you want the recipient to receive
     */
    function exchangedAmountToReceive(uint value)
        external
        view
        returns (uint)
    {
        return value.add(exchangeFeeIncurred(value));
    }

    /**
     * @notice The amount the recipient will receive if you are performing an exchange and the
     * destination currency will be worth a certain number of tokens.
     * @param value The amount of destination currency tokens they received after the exchange.
     */
    function amountReceivedFromExchange(uint value)
        external
        view
        returns (uint)
    {
        return value.divideDecimal(exchangeFeeRate.add(SafeDecimalMath.unit()));
    }

    /**
     * @notice The total fees available in the system to be withdrawn, priced in currencyKey currency
     * @param currencyKey The currency you want to price the fees in
     */
    function totalFeesAvailable(bytes4 currencyKey)
        external
        view
        returns (uint)
    {
        uint totalFees = 0;

        // Fees in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(recentFeePeriods[i].feesToDistribute);
            totalFees = totalFees.sub(recentFeePeriods[i].feesClaimed);
        }

        return synthetix.effectiveValue("XDR", totalFees, currencyKey);
    }

    /**
     * @notice The fees available to be withdrawn by a specific account, priced in currencyKey currency
     * @param currencyKey The currency you want to price the fees in
     */
    function feesAvailable(address account, bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        // Add up the fees
        uint[FEE_PERIOD_LENGTH] memory userFees = feesByPeriod(account);

        uint totalFees = 0;

        // Fees in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(userFees[i]);
        }

        // And convert them to their desired currency
        return synthetix.effectiveValue("XDR", totalFees, currencyKey);
    }

    /**
     * @notice The penalty a particular address would incur if its fees were withdrawn right now
     * @param account The address you want to query the penalty for
     */
    function currentPenalty(address account)
        public
        view
        returns (uint)
    {
        uint ratio = synthetix.collateralisationRatio(account);

        // Users receive a different amount of fees depending on how their collateralisation ratio looks right now.
        // 0% - 20%: Fee is calculated based on percentage of economy issued.
        // 20% - 30%: 25% reduction in fees
        // 30% - 40%: 50% reduction in fees
        // >40%: 75% reduction in fees
        if (ratio <= TWENTY_PERCENT) {
            return 0;
        } else if (ratio > TWENTY_PERCENT && ratio <= THIRTY_PERCENT) {
            return TWENTY_FIVE_PERCENT;
        } else if (ratio > THIRTY_PERCENT && ratio <= FOURTY_PERCENT) {
            return FIFTY_PERCENT;
        }

        return SEVENTY_FIVE_PERCENT;
    }

    /**
     * @notice Calculates fees by period for an account, priced in XDRs
     * @param account The address you want to query the fees by penalty for
     */
    function feesByPeriod(address account)
        public
        view
        returns (uint[FEE_PERIOD_LENGTH])
    {
        uint[FEE_PERIOD_LENGTH] memory result;

        // What&#39;s the user&#39;s debt entry index and the debt they owe to the system
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetix.synthetixState().issuanceData(account);

        // If they don&#39;t have any debt ownership, they don&#39;t have any fees
        if (initialDebtOwnership == 0) return result;

        // If there are no XDR synths, then they don&#39;t have any fees
        uint totalSynths = synthetix.totalIssuedSynths("XDR");
        if (totalSynths == 0) return result;

        uint debtBalance = synthetix.debtBalanceOf(account, "XDR");
        uint userOwnershipPercentage = debtBalance.divideDecimal(totalSynths);
        uint penalty = currentPenalty(account);
        
        // Go through our fee periods and figure out what we owe them.
        // The [0] fee period is not yet ready to claim, but it is a fee period that they can have
        // fees owing for, so we need to report on it anyway.
        for (uint i = 0; i < FEE_PERIOD_LENGTH; i++) {
            // Were they a part of this period in its entirety?
            // We don&#39;t allow pro-rata participation to reduce the ability to game the system by
            // issuing and burning multiple times in a period or close to the ends of periods.
            if (recentFeePeriods[i].startingDebtIndex > debtEntryIndex &&
                lastFeeWithdrawal[account] < recentFeePeriods[i].feePeriodId) {

                // And since they were, they&#39;re entitled to their percentage of the fees in this period
                uint feesFromPeriodWithoutPenalty = recentFeePeriods[i].feesToDistribute
                    .multiplyDecimal(userOwnershipPercentage);

                // Less their penalty if they have one.
                uint penaltyFromPeriod = feesFromPeriodWithoutPenalty.multiplyDecimal(penalty);
                uint feesFromPeriod = feesFromPeriodWithoutPenalty.sub(penaltyFromPeriod);

                result[i] = feesFromPeriod;
            }
        }

        return result;
    }

    modifier onlyFeeAuthority
    {
        require(msg.sender == feeAuthority, "Only the fee authority can perform this action");
        _;
    }

    modifier onlySynthetix
    {
        require(msg.sender == address(synthetix), "Only the synthetix contract can perform this action");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != FEE_ADDRESS, "Fee address not allowed");
        _;
    }

    event TransferFeeUpdated(uint newFeeRate);
    bytes32 constant TRANSFERFEEUPDATED_SIG = keccak256("TransferFeeUpdated(uint256)");
    function emitTransferFeeUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, TRANSFERFEEUPDATED_SIG, 0, 0, 0);
    }

    event ExchangeFeeUpdated(uint newFeeRate);
    bytes32 constant EXCHANGEFEEUPDATED_SIG = keccak256("ExchangeFeeUpdated(uint256)");
    function emitExchangeFeeUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, EXCHANGEFEEUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodDurationUpdated(uint newFeePeriodDuration);
    bytes32 constant FEEPERIODDURATIONUPDATED_SIG = keccak256("FeePeriodDurationUpdated(uint256)");
    function emitFeePeriodDurationUpdated(uint newFeePeriodDuration) internal {
        proxy._emit(abi.encode(newFeePeriodDuration), 1, FEEPERIODDURATIONUPDATED_SIG, 0, 0, 0);
    }

    event FeeAuthorityUpdated(address newFeeAuthority);
    bytes32 constant FEEAUTHORITYUPDATED_SIG = keccak256("FeeAuthorityUpdated(address)");
    function emitFeeAuthorityUpdated(address newFeeAuthority) internal {
        proxy._emit(abi.encode(newFeeAuthority), 1, FEEAUTHORITYUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodClosed(uint feePeriodId);
    bytes32 constant FEEPERIODCLOSED_SIG = keccak256("FeePeriodClosed(uint256)");
    function emitFeePeriodClosed(uint feePeriodId) internal {
        proxy._emit(abi.encode(feePeriodId), 1, FEEPERIODCLOSED_SIG, 0, 0, 0);
    }

    event FeesClaimed(address account, uint xdrAmount);
    bytes32 constant FEESCLAIMED_SIG = keccak256("FeesClaimed(address,uint256)");
    function emitFeesClaimed(address account, uint xdrAmount) internal {
        proxy._emit(abi.encode(account, xdrAmount), 1, FEESCLAIMED_SIG, 0, 0, 0);
    }

    event SynthetixUpdated(address newSynthetix);
    bytes32 constant SYNTHETIXUPDATED_SIG = keccak256("SynthetixUpdated(address)");
    function emitSynthetixUpdated(address newSynthetix) internal {
        proxy._emit(abi.encode(newSynthetix), 1, SYNTHETIXUPDATED_SIG, 0, 0, 0);
    }
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Synth.sol
version:    2.0
author:     Kevin Brown
date:       2018-09-13

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Synthetix-backed stablecoin contract.

This contract issues synths, which are tokens that mirror various
flavours of fiat currency.

Synths are issuable by Synthetix Network Token (SNX) holders who 
have to lock up some value of their SNX to issue S * Cmax synths. 
Where Cmax issome value less than 1.

A configurable fee is charged on synth transfers and deposited
into a common pot, which Synthetix holders may withdraw from once
per fee period.

-----------------------------------------------------------------
*/


contract Synth is ExternStateToken {

    /* ========== STATE VARIABLES ========== */

    FeePool public feePool;
    Synthetix public synthetix;

    // Currency key which identifies this Synth to the Synthetix system
    bytes4 public currencyKey;

    uint8 constant DECIMALS = 18;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _proxy, TokenState _tokenState, Synthetix _synthetix, FeePool _feePool,
        string _tokenName, string _tokenSymbol, address _owner, bytes4 _currencyKey
    )
        ExternStateToken(_proxy, _tokenState, _tokenName, _tokenSymbol, 0, DECIMALS, _owner)
        public
    {
        require(_proxy != 0, "_proxy cannot be 0");
        require(address(_synthetix) != 0, "_synthetix cannot be 0");
        require(address(_feePool) != 0, "_feePool cannot be 0");
        require(_owner != 0, "_owner cannot be 0");
        require(_synthetix.synths(_currencyKey) == Synth(0), "Currency key is already in use");

        feePool = _feePool;
        synthetix = _synthetix;
        currencyKey = _currencyKey;
    }

    /* ========== SETTERS ========== */

    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        synthetix = _synthetix;
        emitSynthetixUpdated(_synthetix);
    }

    function setFeePool(FeePool _feePool)
        external
        optionalProxy_onlyOwner
    {
        feePool = _feePool;
        emitFeePoolUpdated(_feePool);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Override ERC20 transfer function in order to 
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transfer(address to, uint value)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

        // Send the fee off to the fee pool.
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their result off to the destination address
        bytes memory empty;
        return _internalTransfer(messageSender, to, amountReceived, empty);
    }

    /**
     * @notice Override ERC223 transfer function in order to 
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

        // Send the fee off to the fee pool, which we don&#39;t want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their result off to the destination address
        return _internalTransfer(messageSender, to, amountReceived, data);
    }

    /**
     * @notice Override ERC20 transferFrom function in order to 
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        // The fee is deducted from the amount sent.
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

        // Reduce the allowance by the amount we&#39;re transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));

        // Send the fee off to the fee pool.
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        bytes memory empty;
        return _internalTransfer(from, to, amountReceived, empty);
    }

    /**
     * @notice Override ERC223 transferFrom function in order to 
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        // The fee is deducted from the amount sent.
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

        // Reduce the allowance by the amount we&#39;re transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));

        // Send the fee off to the fee pool, which we don&#39;t want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        return _internalTransfer(from, to, amountReceived, data);
    }

    /* Subtract the transfer fee from the senders account so the 
     * receiver gets the exact amount specified to send. */
    function transferSenderPaysFee(address to, uint value)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Send the fee off to the fee pool, which we don&#39;t want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their transfer amount off to the destination address
        bytes memory empty;
        return _internalTransfer(messageSender, to, value, empty);
    }

    /* Subtract the transfer fee from the senders account so the 
     * receiver gets the exact amount specified to send. */
    function transferSenderPaysFee(address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Send the fee off to the fee pool, which we don&#39;t want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their transfer amount off to the destination address
        return _internalTransfer(messageSender, to, value, data);
    }

    /* Subtract the transfer fee from the senders account so the 
     * to address receives the exact amount specified to send. */
    function transferFromSenderPaysFee(address from, address to, uint value)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Reduce the allowance by the amount we&#39;re transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value.add(fee)));

        // Send the fee off to the fee pool, which we don&#39;t want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        bytes memory empty;
        return _internalTransfer(from, to, value, empty);
    }

    /* Subtract the transfer fee from the senders account so the 
     * to address receives the exact amount specified to send. */
    function transferFromSenderPaysFee(address from, address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Reduce the allowance by the amount we&#39;re transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value.add(fee)));

        // Send the fee off to the fee pool, which we don&#39;t want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        return _internalTransfer(from, to, value, data);
    }

    // Override our internal transfer to inject preferred currency support
    function _internalTransfer(address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
        bytes4 preferredCurrencyKey = synthetix.synthetixState().preferredCurrency(to);

        // Do they have a preferred currency that&#39;s not us? If so we need to exchange
        if (preferredCurrencyKey != 0 && preferredCurrencyKey != currencyKey) {
            return synthetix.synthInitiatedExchange(from, currencyKey, value, preferredCurrencyKey, to);
        } else {
            // Otherwise we just transfer
            return super._internalTransfer(from, to, value, data);
        }
    }

    // Allow synthetix to issue a certain number of synths from an account.
    function issue(address account, uint amount)
        external
        onlySynthetixOrFeePool
    {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

    // Allow synthetix or another synth contract to burn a certain number of synths from an account.
    function burn(address account, uint amount)
        external
        onlySynthetixOrFeePool
    {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
    }

    // Allow owner to set the total supply on import.
    function setTotalSupply(uint amount)
        external
        optionalProxy_onlyOwner
    {
        totalSupply = amount;
    }

    // Allow synthetix to trigger a token fallback call from our synths so users get notified on
    // exchange as well as transfer
    function triggerTokenFallbackIfNeeded(address sender, address recipient, uint amount)
        external
        onlySynthetixOrFeePool
    {
        bytes memory empty;
        callTokenFallbackIfNeeded(sender, recipient, amount, empty);
    }

    /* ========== MODIFIERS ========== */

    modifier onlySynthetixOrFeePool() {
        bool isSynthetix = msg.sender == address(synthetix);
        bool isFeePool = msg.sender == address(feePool);

        require(isSynthetix || isFeePool, "Only the Synthetix or FeePool contracts can perform this action");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Cannot perform this action with the fee address");
        _;
    }

    /* ========== EVENTS ========== */

    event SynthetixUpdated(address newSynthetix);
    bytes32 constant SYNTHETIXUPDATED_SIG = keccak256("SynthetixUpdated(address)");
    function emitSynthetixUpdated(address newSynthetix) internal {
        proxy._emit(abi.encode(newSynthetix), 1, SYNTHETIXUPDATED_SIG, 0, 0, 0);
    }

    event FeePoolUpdated(address newFeePool);
    bytes32 constant FEEPOOLUPDATED_SIG = keccak256("FeePoolUpdated(address)");
    function emitFeePoolUpdated(address newFeePool) internal {
        proxy._emit(abi.encode(newFeePool), 1, FEEPOOLUPDATED_SIG, 0, 0, 0);
    }

    event Issued(address indexed account, uint value);
    bytes32 constant ISSUED_SIG = keccak256("Issued(address,uint256)");
    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, bytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint value);
    bytes32 constant BURNED_SIG = keccak256("Burned(address,uint256)");
    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, bytes32(account), 0, 0);
    }
}