pragma solidity 0.4.24;
pragma experimental "v0.5.0";

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/lib/AccessControlledBase.sol

/**
 * @title AccessControlledBase
 * @author dYdX
 *
 * Base functionality for access control. Requires an implementation to
 * provide a way to grant and optionally revoke access
 */
contract AccessControlledBase {
    // ============ State Variables ============

    mapping (address => bool) public authorized;

    // ============ Events ============

    event AccessGranted(
        address who
    );

    event AccessRevoked(
        address who
    );

    // ============ Modifiers ============

    modifier requiresAuthorization() {
        require(
            authorized[msg.sender],
            "AccessControlledBase#requiresAuthorization: Sender not authorized"
        );
        _;
    }
}

// File: contracts/lib/StaticAccessControlled.sol

/**
 * @title StaticAccessControlled
 * @author dYdX
 *
 * Allows for functions to be access controled
 * Permissions cannot be changed after a grace period
 */
contract StaticAccessControlled is AccessControlledBase, Ownable {
    using SafeMath for uint256;

    // ============ State Variables ============

    // Timestamp after which no additional access can be granted
    uint256 public GRACE_PERIOD_EXPIRATION;

    // ============ Constructor ============

    constructor(
        uint256 gracePeriod
    )
        public
        Ownable()
    {
        GRACE_PERIOD_EXPIRATION = block.timestamp.add(gracePeriod);
    }

    // ============ Owner-Only State-Changing Functions ============

    function grantAccess(
        address who
    )
        external
        onlyOwner
    {
        require(
            block.timestamp < GRACE_PERIOD_EXPIRATION,
            "StaticAccessControlled#grantAccess: Cannot grant access after grace period"
        );

        emit AccessGranted(who);
        authorized[who] = true;
    }
}

// File: contracts/lib/GeneralERC20.sol

/**
 * @title GeneralERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we dont automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
interface GeneralERC20 {
    function totalSupply(
    )
        external
        view
        returns (uint256);

    function balanceOf(
        address who
    )
        external
        view
        returns (uint256);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
        external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external;

    function approve(
        address spender,
        uint256 value
    )
        external;
}

// File: contracts/lib/TokenInteract.sol

/**
 * @title TokenInteract
 * @author dYdX
 *
 * This library contains functions for interacting with ERC20 tokens
 */
library TokenInteract {
    function balanceOf(
        address token,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).allowance(owner, spender);
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        GeneralERC20(token).approve(spender, amount);

        require(
            checkSuccess(),
            "TokenInteract#approve: Approval failed"
        );
    }

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        address from = address(this);
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transfer(to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transfer: Transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transferFrom(from, to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transferFrom: TransferFrom failed"
        );
    }

    // ============ Private Helper-Functions ============

    /**
     * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
     * function returned 0 bytes or 32 bytes that are not all-zero.
     */
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
        uint256 returnValue = 0;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            // check number of bytes returned from last function call
            switch returndatasize

            // no bytes returned: assume success
            case 0x0 {
                returnValue := 1
            }

            // 32 bytes returned: check if non-zero
            case 0x20 {
                // copy 32 bytes into scratch space
                returndatacopy(0x0, 0x0, 0x20)

                // load those bytes into returnValue
                returnValue := mload(0x0)
            }

            // not sure what was returned: dont mark as success
            default { }
        }

        return returnValue != 0;
    }
}

// File: contracts/margin/TokenProxy.sol

/**
 * @title TokenProxy
 * @author dYdX
 *
 * Used to transfer tokens between addresses which have set allowance on this contract.
 */
contract TokenProxy is StaticAccessControlled {
    using SafeMath for uint256;

    // ============ Constructor ============

    constructor(
        uint256 gracePeriod
    )
        public
        StaticAccessControlled(gracePeriod)
    {}

    // ============ Authorized-Only State Changing Functions ============

    /**
     * Transfers tokens from an address (that has set allowance on the proxy) to another address.
     *
     * @param  token  The address of the ERC20 token
     * @param  from   The address to transfer token from
     * @param  to     The address to transfer tokens to
     * @param  value  The number of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 value
    )
        external
        requiresAuthorization
    {
        TokenInteract.transferFrom(
            token,
            from,
            to,
            value
        );
    }

    // ============ Public Constant Functions ============

    /**
     * Getter function to get the amount of token that the proxy is able to move for a particular
     * address. The minimum of 1) the balance of that address and 2) the allowance given to proxy.
     *
     * @param  who    The owner of the tokens
     * @param  token  The address of the ERC20 token
     * @return        The number of tokens able to be moved by the proxy from the address specified
     */
    function available(
        address who,
        address token
    )
        external
        view
        returns (uint256)
    {
        return Math.min256(
            TokenInteract.allowance(token, who, address(this)),
            TokenInteract.balanceOf(token, who)
        );
    }
}

// File: contracts/margin/Vault.sol

/**
 * @title Vault
 * @author dYdX
 *
 * Holds and transfers tokens in vaults denominated by id
 *
 * Vault only supports ERC20 tokens, and will not accept any tokens that require
 * a tokenFallback or equivalent function (See ERC223, ERC777, etc.)
 */
contract Vault is StaticAccessControlled
{
    using SafeMath for uint256;

    // ============ Events ============

    event ExcessTokensWithdrawn(
        address indexed token,
        address indexed to,
        address caller
    );

    // ============ State Variables ============

    // Address of the TokenProxy contract. Used for moving tokens.
    address public TOKEN_PROXY;

    // Map from vault ID to map from token address to amount of that token attributed to the
    // particular vault ID.
    mapping (bytes32 => mapping (address => uint256)) public balances;

    // Map from token address to total amount of that token attributed to some account.
    mapping (address => uint256) public totalBalances;

    // ============ Constructor ============

    constructor(
        address proxy,
        uint256 gracePeriod
    )
        public
        StaticAccessControlled(gracePeriod)
    {
        TOKEN_PROXY = proxy;
    }

    // ============ Owner-Only State-Changing Functions ============

    /**
     * Allows the owner to withdraw any excess tokens sent to the vault by unconventional means,
     * including (but not limited-to) token airdrops. Any tokens moved to the vault by TOKEN_PROXY
     * will be accounted for and will not be withdrawable by this function.
     *
     * @param  token  ERC20 token address
     * @param  to     Address to transfer tokens to
     * @return        Amount of tokens withdrawn
     */
    function withdrawExcessToken(
        address token,
        address to
    )
        external
        onlyOwner
        returns (uint256)
    {
        uint256 actualBalance = TokenInteract.balanceOf(token, address(this));
        uint256 accountedBalance = totalBalances[token];
        uint256 withdrawableBalance = actualBalance.sub(accountedBalance);

        require(
            withdrawableBalance != 0,
            "Vault#withdrawExcessToken: Withdrawable token amount must be non-zero"
        );

        TokenInteract.transfer(token, to, withdrawableBalance);

        emit ExcessTokensWithdrawn(token, to, msg.sender);

        return withdrawableBalance;
    }

    // ============ Authorized-Only State-Changing Functions ============

    /**
     * Transfers tokens from an address (that has approved the proxy) to the vault.
     *
     * @param  id      The vault which will receive the tokens
     * @param  token   ERC20 token address
     * @param  from    Address from which the tokens will be taken
     * @param  amount  Number of the token to be sent
     */
    function transferToVault(
        bytes32 id,
        address token,
        address from,
        uint256 amount
    )
        external
        requiresAuthorization
    {
        // First send tokens to this contract
        TokenProxy(TOKEN_PROXY).transferTokens(
            token,
            from,
            address(this),
            amount
        );

        // Then increment balances
        balances[id][token] = balances[id][token].add(amount);
        totalBalances[token] = totalBalances[token].add(amount);

        // This should always be true. If not, something is very wrong
        assert(totalBalances[token] >= balances[id][token]);

        validateBalance(token);
    }

    /**
     * Transfers a certain amount of funds to an address.
     *
     * @param  id      The vault from which to send the tokens
     * @param  token   ERC20 token address
     * @param  to      Address to transfer tokens to
     * @param  amount  Number of the token to be sent
     */
    function transferFromVault(
        bytes32 id,
        address token,
        address to,
        uint256 amount
    )
        external
        requiresAuthorization
    {
        // Next line also asserts that (balances[id][token] >= amount);
        balances[id][token] = balances[id][token].sub(amount);

        // Next line also asserts that (totalBalances[token] >= amount);
        totalBalances[token] = totalBalances[token].sub(amount);

        // This should always be true. If not, something is very wrong
        assert(totalBalances[token] >= balances[id][token]);

        // Do the sending
        TokenInteract.transfer(token, to, amount); // asserts transfer succeeded

        // Final validation
        validateBalance(token);
    }

    // ============ Private Helper-Functions ============

    /**
     * Verifies that this contract is in control of at least as many tokens as accounted for
     *
     * @param  token  Address of ERC20 token
     */
    function validateBalance(
        address token
    )
        private
        view
    {
        // The actual balance could be greater than totalBalances[token] because anyone
        // can send tokens to the contract&#39;s address which cannot be accounted for
        assert(TokenInteract.balanceOf(token, address(this)) >= totalBalances[token]);
    }
}

// File: contracts/lib/ReentrancyGuard.sol

/**
 * @title ReentrancyGuard
 * @author dYdX
 *
 * Optimized version of the well-known ReentrancyGuard contract
 */
contract ReentrancyGuard {
    uint256 private _guardCounter = 1;

    modifier nonReentrant() {
        uint256 localCounter = _guardCounter + 1;
        _guardCounter = localCounter;
        _;
        require(
            _guardCounter == localCounter,
            "Reentrancy check failure"
        );
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: contracts/lib/Fraction.sol

/**
 * @title Fraction
 * @author dYdX
 *
 * This library contains implementations for fraction structs.
 */
library Fraction {
    struct Fraction128 {
        uint128 num;
        uint128 den;
    }
}

// File: contracts/lib/FractionMath.sol

/**
 * @title FractionMath
 * @author dYdX
 *
 * This library contains safe math functions for manipulating fractions.
 */
library FractionMath {
    using SafeMath for uint256;
    using SafeMath for uint128;

    /**
     * Returns a Fraction128 that is equal to a + b
     *
     * @param  a  The first Fraction128
     * @param  b  The second Fraction128
     * @return    The result (sum)
     */
    function add(
        Fraction.Fraction128 memory a,
        Fraction.Fraction128 memory b
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        uint256 left = a.num.mul(b.den);
        uint256 right = b.num.mul(a.den);
        uint256 denominator = a.den.mul(b.den);

        // if left + right overflows, prevent overflow
        if (left + right < left) {
            left = left.div(2);
            right = right.div(2);
            denominator = denominator.div(2);
        }

        return bound(left.add(right), denominator);
    }

    /**
     * Returns a Fraction128 that is equal to a - (1/2)^d
     *
     * @param  a  The Fraction128
     * @param  d  The power of (1/2)
     * @return    The result
     */
    function sub1Over(
        Fraction.Fraction128 memory a,
        uint128 d
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        if (a.den % d == 0) {
            return bound(
                a.num.sub(a.den.div(d)),
                a.den
            );
        }
        return bound(
            a.num.mul(d).sub(a.den),
            a.den.mul(d)
        );
    }

    /**
     * Returns a Fraction128 that is equal to a / d
     *
     * @param  a  The first Fraction128
     * @param  d  The divisor
     * @return    The result (quotient)
     */
    function div(
        Fraction.Fraction128 memory a,
        uint128 d
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        if (a.num % d == 0) {
            return bound(
                a.num.div(d),
                a.den
            );
        }
        return bound(
            a.num,
            a.den.mul(d)
        );
    }

    /**
     * Returns a Fraction128 that is equal to a * b.
     *
     * @param  a  The first Fraction128
     * @param  b  The second Fraction128
     * @return    The result (product)
     */
    function mul(
        Fraction.Fraction128 memory a,
        Fraction.Fraction128 memory b
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        return bound(
            a.num.mul(b.num),
            a.den.mul(b.den)
        );
    }

    /**
     * Returns a fraction from two uint256&#39;s. Fits them into uint128 if necessary.
     *
     * @param  num  The numerator
     * @param  den  The denominator
     * @return      The Fraction128 that matches num/den most closely
     */
    /* solium-disable-next-line security/no-assign-params */
    function bound(
        uint256 num,
        uint256 den
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        uint256 max = num > den ? num : den;
        uint256 first128Bits = (max >> 128);
        if (first128Bits != 0) {
            first128Bits += 1;
            num /= first128Bits;
            den /= first128Bits;
        }

        assert(den != 0); // coverage-enable-line
        assert(den < 2**128);
        assert(num < 2**128);

        return Fraction.Fraction128({
            num: uint128(num),
            den: uint128(den)
        });
    }

    /**
     * Returns an in-memory copy of a Fraction128
     *
     * @param  a  The Fraction128 to copy
     * @return    A copy of the Fraction128
     */
    function copy(
        Fraction.Fraction128 memory a
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        validate(a);
        return Fraction.Fraction128({ num: a.num, den: a.den });
    }

    // ============ Private Helper-Functions ============

    /**
     * Asserts that a Fraction128 is valid (i.e. the denominator is non-zero)
     *
     * @param  a  The Fraction128 to validate
     */
    function validate(
        Fraction.Fraction128 memory a
    )
        private
        pure
    {
        assert(a.den != 0); // coverage-enable-line
    }
}

// File: contracts/lib/Exponent.sol

/**
 * @title Exponent
 * @author dYdX
 *
 * This library contains an implementation for calculating e^X for arbitrary fraction X
 */
library Exponent {
    using SafeMath for uint256;
    using FractionMath for Fraction.Fraction128;

    // ============ Constants ============

    // 2**128 - 1
    uint128 constant public MAX_NUMERATOR = 340282366920938463463374607431768211455;

    // Number of precomputed integers, X, for E^((1/2)^X)
    uint256 constant public MAX_PRECOMPUTE_PRECISION = 32;

    // Number of precomputed integers, X, for E^X
    uint256 constant public NUM_PRECOMPUTED_INTEGERS = 32;

    // ============ Public Implementation Functions ============

    /**
     * Returns e^X for any fraction X
     *
     * @param  X                    The exponent
     * @param  precomputePrecision  Accuracy of precomputed terms
     * @param  maclaurinPrecision   Accuracy of Maclaurin terms
     * @return                      e^X
     */
    function exp(
        Fraction.Fraction128 memory X,
        uint256 precomputePrecision,
        uint256 maclaurinPrecision
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        require(
            precomputePrecision <= MAX_PRECOMPUTE_PRECISION,
            "Exponent#exp: Precompute precision over maximum"
        );

        Fraction.Fraction128 memory Xcopy = X.copy();
        if (Xcopy.num == 0) { // e^0 = 1
            return ONE();
        }

        // get the integer value of the fraction (example: 9/4 is 2.25 so has integerValue of 2)
        uint256 integerX = uint256(Xcopy.num).div(Xcopy.den);

        // if X is less than 1, then just calculate X
        if (integerX == 0) {
            return expHybrid(Xcopy, precomputePrecision, maclaurinPrecision);
        }

        // get e^integerX
        Fraction.Fraction128 memory expOfInt =
            getPrecomputedEToThe(integerX % NUM_PRECOMPUTED_INTEGERS);
        while (integerX >= NUM_PRECOMPUTED_INTEGERS) {
            expOfInt = expOfInt.mul(getPrecomputedEToThe(NUM_PRECOMPUTED_INTEGERS));
            integerX -= NUM_PRECOMPUTED_INTEGERS;
        }

        // multiply e^integerX by e^decimalX
        Fraction.Fraction128 memory decimalX = Fraction.Fraction128({
            num: Xcopy.num % Xcopy.den,
            den: Xcopy.den
        });
        return expHybrid(decimalX, precomputePrecision, maclaurinPrecision).mul(expOfInt);
    }

    /**
     * Returns e^X for any X < 1. Multiplies precomputed values to get close to the real value, then
     * Maclaurin Series approximation to reduce error.
     *
     * @param  X                    Exponent
     * @param  precomputePrecision  Accuracy of precomputed terms
     * @param  maclaurinPrecision   Accuracy of Maclaurin terms
     * @return                      e^X
     */
    function expHybrid(
        Fraction.Fraction128 memory X,
        uint256 precomputePrecision,
        uint256 maclaurinPrecision
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        assert(precomputePrecision <= MAX_PRECOMPUTE_PRECISION);
        assert(X.num < X.den);
        // will also throw if precomputePrecision is larger than the array length in getDenominator

        Fraction.Fraction128 memory Xtemp = X.copy();
        if (Xtemp.num == 0) { // e^0 = 1
            return ONE();
        }

        Fraction.Fraction128 memory result = ONE();

        uint256 d = 1; // 2^i
        for (uint256 i = 1; i <= precomputePrecision; i++) {
            d *= 2;

            // if Fraction > 1/d, subtract 1/d and multiply result by precomputed e^(1/d)
            if (d.mul(Xtemp.num) >= Xtemp.den) {
                Xtemp = Xtemp.sub1Over(uint128(d));
                result = result.mul(getPrecomputedEToTheHalfToThe(i));
            }
        }
        return result.mul(expMaclaurin(Xtemp, maclaurinPrecision));
    }

    /**
     * Returns e^X for any X, using Maclaurin Series approximation
     *
     * e^X = SUM(X^n / n!) for n >= 0
     * e^X = 1 + X/1! + X^2/2! + X^3/3! ...
     *
     * @param  X           Exponent
     * @param  precision   Accuracy of Maclaurin terms
     * @return             e^X
     */
    function expMaclaurin(
        Fraction.Fraction128 memory X,
        uint256 precision
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        Fraction.Fraction128 memory Xcopy = X.copy();
        if (Xcopy.num == 0) { // e^0 = 1
            return ONE();
        }

        Fraction.Fraction128 memory result = ONE();
        Fraction.Fraction128 memory Xtemp = ONE();
        for (uint256 i = 1; i <= precision; i++) {
            Xtemp = Xtemp.mul(Xcopy.div(uint128(i)));
            result = result.add(Xtemp);
        }
        return result;
    }

    /**
     * Returns a fraction roughly equaling E^((1/2)^x) for integer x
     */
    function getPrecomputedEToTheHalfToThe(
        uint256 x
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        assert(x <= MAX_PRECOMPUTE_PRECISION);

        uint128 denominator = [
            125182886983370532117250726298150828301,
            206391688497133195273760705512282642279,
            265012173823417992016237332255925138361,
            300298134811882980317033350418940119802,
            319665700530617779809390163992561606014,
            329812979126047300897653247035862915816,
            335006777809430963166468914297166288162,
            337634268532609249517744113622081347950,
            338955731696479810470146282672867036734,
            339618401537809365075354109784799900812,
            339950222128463181389559457827561204959,
            340116253979683015278260491021941090650,
            340199300311581465057079429423749235412,
            340240831081268226777032180141478221816,
            340261598367316729254995498374473399540,
            340271982485676106947851156443492415142,
            340277174663693808406010255284800906112,
            340279770782412691177936847400746725466,
            340281068849199706686796915841848278311,
            340281717884450116236033378667952410919,
            340282042402539547492367191008339680733,
            340282204661700319870089970029119685699,
            340282285791309720262481214385569134454,
            340282326356121674011576912006427792656,
            340282346638529464274601981200276914173,
            340282356779733812753265346086924801364,
            340282361850336100329388676752133324799,
            340282364385637272451648746721404212564,
            340282365653287865596328444437856608255,
            340282366287113163939555716675618384724,
            340282366604025813553891209601455838559,
            340282366762482138471739420386372790954,
            340282366841710300958333641874363209044
        ][x];
        return Fraction.Fraction128({
            num: MAX_NUMERATOR,
            den: denominator
        });
    }

    /**
     * Returns a fraction roughly equaling E^(x) for integer x
     */
    function getPrecomputedEToThe(
        uint256 x
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        assert(x <= NUM_PRECOMPUTED_INTEGERS);

        uint128 denominator = [
            340282366920938463463374607431768211455,
            125182886983370532117250726298150828301,
            46052210507670172419625860892627118820,
            16941661466271327126146327822211253888,
            6232488952727653950957829210887653621,
            2292804553036637136093891217529878878,
            843475657686456657683449904934172134,
            310297353591408453462393329342695980,
            114152017036184782947077973323212575,
            41994180235864621538772677139808695,
            15448795557622704876497742989562086,
            5683294276510101335127414470015662,
            2090767122455392675095471286328463,
            769150240628514374138961856925097,
            282954560699298259527814398449860,
            104093165666968799599694528310221,
            38293735615330848145349245349513,
            14087478058534870382224480725096,
            5182493555688763339001418388912,
            1906532833141383353974257736699,
            701374233231058797338605168652,
            258021160973090761055471434334,
            94920680509187392077350434438,
            34919366901332874995585576427,
            12846117181722897538509298435,
            4725822410035083116489797150,
            1738532907279185132707372378,
            639570514388029575350057932,
            235284843422800231081973821,
            86556456714490055457751527,
            31842340925906738090071268,
            11714142585413118080082437,
            4309392228124372433711936
        ][x];
        return Fraction.Fraction128({
            num: MAX_NUMERATOR,
            den: denominator
        });
    }

    // ============ Private Helper-Functions ============

    function ONE()
        private
        pure
        returns (Fraction.Fraction128 memory)
    {
        return Fraction.Fraction128({ num: 1, den: 1 });
    }
}

// File: contracts/lib/MathHelpers.sol

/**
 * @title MathHelpers
 * @author dYdX
 *
 * This library helps with common math functions in Solidity
 */
library MathHelpers {
    using SafeMath for uint256;

    /**
     * Calculates partial value given a numerator and denominator.
     *
     * @param  numerator    Numerator
     * @param  denominator  Denominator
     * @param  target       Value to calculate partial of
     * @return              target * numerator / denominator
     */
    function getPartialAmount(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return numerator.mul(target).div(denominator);
    }

    /**
     * Calculates partial value given a numerator and denominator, rounded up.
     *
     * @param  numerator    Numerator
     * @param  denominator  Denominator
     * @param  target       Value to calculate partial of
     * @return              Rounded-up result of target * numerator / denominator
     */
    function getPartialAmountRoundedUp(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return divisionRoundedUp(numerator.mul(target), denominator);
    }

    /**
     * Calculates division given a numerator and denominator, rounded up.
     *
     * @param  numerator    Numerator.
     * @param  denominator  Denominator.
     * @return              Rounded-up result of numerator / denominator
     */
    function divisionRoundedUp(
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        assert(denominator != 0); // coverage-enable-line
        if (numerator == 0) {
            return 0;
        }
        return numerator.sub(1).div(denominator).add(1);
    }

    /**
     * Calculates and returns the maximum value for a uint256 in solidity
     *
     * @return  The maximum value for uint256
     */
    function maxUint256(
    )
        internal
        pure
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

    /**
     * Calculates and returns the maximum value for a uint256 in solidity
     *
     * @return  The maximum value for uint256
     */
    function maxUint32(
    )
        internal
        pure
        returns (uint32)
    {
        return 2 ** 32 - 1;
    }

    /**
     * Returns the number of bits in a uint256. That is, the lowest number, x, such that n >> x == 0
     *
     * @param  n  The uint256 to get the number of bits in
     * @return    The number of bits in n
     */
    function getNumBits(
        uint256 n
    )
        internal
        pure
        returns (uint256)
    {
        uint256 first = 0;
        uint256 last = 256;
        while (first < last) {
            uint256 check = (first + last) / 2;
            if ((n >> check) == 0) {
                last = check;
            } else {
                first = check + 1;
            }
        }
        assert(first <= 256);
        return first;
    }
}

// File: contracts/margin/impl/InterestImpl.sol

/**
 * @title InterestImpl
 * @author dYdX
 *
 * A library that calculates continuously compounded interest for principal, time period, and
 * interest rate.
 */
library InterestImpl {
    using SafeMath for uint256;
    using FractionMath for Fraction.Fraction128;

    // ============ Constants ============

    uint256 constant DEFAULT_PRECOMPUTE_PRECISION = 11;

    uint256 constant DEFAULT_MACLAURIN_PRECISION = 5;

    uint256 constant MAXIMUM_EXPONENT = 80;

    uint128 constant E_TO_MAXIUMUM_EXPONENT = 55406223843935100525711733958316613;

    // ============ Public Implementation Functions ============

    /**
     * Returns total tokens owed after accruing interest. Continuously compounding and accurate to
     * roughly 10^18 decimal places. Continuously compounding interest follows the formula:
     * I = P * e^(R*T)
     *
     * @param  principal           Principal of the interest calculation
     * @param  interestRate        Annual nominal interest percentage times 10**6.
     *                             (example: 5% = 5e6)
     * @param  secondsOfInterest   Number of seconds that interest has been accruing
     * @return                     Total amount of tokens owed. Greater than tokenAmount.
     */
    function getCompoundedInterest(
        uint256 principal,
        uint256 interestRate,
        uint256 secondsOfInterest
    )
        public
        pure
        returns (uint256)
    {
        uint256 numerator = interestRate.mul(secondsOfInterest);
        uint128 denominator = (10**8) * (365 * 1 days);

        // interestRate and secondsOfInterest should both be uint32
        assert(numerator < 2**128);

        // fraction representing (Rate * Time)
        Fraction.Fraction128 memory rt = Fraction.Fraction128({
            num: uint128(numerator),
            den: denominator
        });

        // calculate e^(RT)
        Fraction.Fraction128 memory eToRT;
        if (numerator.div(denominator) >= MAXIMUM_EXPONENT) {
            // degenerate case: cap calculation
            eToRT = Fraction.Fraction128({
                num: E_TO_MAXIUMUM_EXPONENT,
                den: 1
            });
        } else {
            // normal case: calculate e^(RT)
            eToRT = Exponent.exp(
                rt,
                DEFAULT_PRECOMPUTE_PRECISION,
                DEFAULT_MACLAURIN_PRECISION
            );
        }

        // e^X for positive X should be greater-than or equal to 1
        assert(eToRT.num >= eToRT.den);

        return safeMultiplyUint256ByFraction(principal, eToRT);
    }

    // ============ Private Helper-Functions ============

    /**
     * Returns n * f, trying to prevent overflow as much as possible. Assumes that the numerator
     * and denominator of f are less than 2**128.
     */
    function safeMultiplyUint256ByFraction(
        uint256 n,
        Fraction.Fraction128 memory f
    )
        private
        pure
        returns (uint256)
    {
        uint256 term1 = n.div(2 ** 128); // first 128 bits
        uint256 term2 = n % (2 ** 128); // second 128 bits

        // uncommon scenario, requires n >= 2**128. calculates term1 = term1 * f
        if (term1 > 0) {
            term1 = term1.mul(f.num);
            uint256 numBits = MathHelpers.getNumBits(term1);

            // reduce rounding error by shifting all the way to the left before dividing
            term1 = MathHelpers.divisionRoundedUp(
                term1 << (uint256(256).sub(numBits)),
                f.den);

            // continue shifting or reduce shifting to get the right number
            if (numBits > 128) {
                term1 = term1 << (numBits.sub(128));
            } else if (numBits < 128) {
                term1 = term1 >> (uint256(128).sub(numBits));
            }
        }

        // calculates term2 = term2 * f
        term2 = MathHelpers.getPartialAmountRoundedUp(
            f.num,
            f.den,
            term2
        );

        return term1.add(term2);
    }
}

// File: contracts/margin/impl/MarginState.sol

/**
 * @title MarginState
 * @author dYdX
 *
 * Contains state for the Margin contract. Also used by libraries that implement Margin functions.
 */
library MarginState {
    struct State {
        // Address of the Vault contract
        address VAULT;

        // Address of the TokenProxy contract
        address TOKEN_PROXY;

        // Mapping from loanHash -> amount, which stores the amount of a loan which has
        // already been filled.
        mapping (bytes32 => uint256) loanFills;

        // Mapping from loanHash -> amount, which stores the amount of a loan which has
        // already been canceled.
        mapping (bytes32 => uint256) loanCancels;

        // Mapping from positionId -> Position, which stores all the open margin positions.
        mapping (bytes32 => MarginCommon.Position) positions;

        // Mapping from positionId -> bool, which stores whether the position has previously been
        // open, but is now closed.
        mapping (bytes32 => bool) closedPositions;

        // Mapping from positionId -> uint256, which stores the total amount of owedToken that has
        // ever been repaid to the lender for each position. Does not reset.
        mapping (bytes32 => uint256) totalOwedTokenRepaidToLender;
    }
}

// File: contracts/margin/interfaces/lender/LoanOwner.sol

/**
 * @title LoanOwner
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to own loans on behalf of other accounts.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface LoanOwner {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to receive ownership of a loan sell via the
     * transferLoan function or the atomic-assign to the "owner" field in a loan offering.
     *
     * @param  from        Address of the previous owner
     * @param  positionId  Unique ID of the position
     * @return             This address to keep ownership, a different address to pass-on ownership
     */
    function receiveLoanOwnership(
        address from,
        bytes32 positionId
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/interfaces/owner/PositionOwner.sol

/**
 * @title PositionOwner
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to own position on behalf of other
 * accounts
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface PositionOwner {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to receive ownership of a position via the
     * transferPosition function or the atomic-assign to the "owner" field when opening a position.
     *
     * @param  from        Address of the previous owner
     * @param  positionId  Unique ID of the position
     * @return             This address to keep ownership, a different address to pass-on ownership
     */
    function receivePositionOwnership(
        address from,
        bytes32 positionId
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/impl/TransferInternal.sol

/**
 * @title TransferInternal
 * @author dYdX
 *
 * This library contains the implementation for transferring ownership of loans and positions.
 */
library TransferInternal {

    // ============ Events ============

    /**
     * Ownership of a loan was transferred to a new address
     */
    event LoanTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );

    /**
     * Ownership of a postion was transferred to a new address
     */
    event PositionTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );

    // ============ Internal Implementation Functions ============

    /**
     * Returns either the address of the new loan owner, or the address to which they wish to
     * pass ownership of the loan. This function does not actually set the state of the position
     *
     * @param  positionId  The Unique ID of the position
     * @param  oldOwner    The previous owner of the loan
     * @param  newOwner    The intended owner of the loan
     * @return             The address that the intended owner wishes to assign the loan to (may be
     *                     the same as the intended owner).
     */
    function grantLoanOwnership(
        bytes32 positionId,
        address oldOwner,
        address newOwner
    )
        internal
        returns (address)
    {
        // log event except upon position creation
        if (oldOwner != address(0)) {
            emit LoanTransferred(positionId, oldOwner, newOwner);
        }

        if (AddressUtils.isContract(newOwner)) {
            address nextOwner =
                LoanOwner(newOwner).receiveLoanOwnership(oldOwner, positionId);
            if (nextOwner != newOwner) {
                return grantLoanOwnership(positionId, newOwner, nextOwner);
            }
        }

        require(
            newOwner != address(0),
            "TransferInternal#grantLoanOwnership: New owner did not consent to owning loan"
        );

        return newOwner;
    }

    /**
     * Returns either the address of the new position owner, or the address to which they wish to
     * pass ownership of the position. This function does not actually set the state of the position
     *
     * @param  positionId  The Unique ID of the position
     * @param  oldOwner    The previous owner of the position
     * @param  newOwner    The intended owner of the position
     * @return             The address that the intended owner wishes to assign the position to (may
     *                     be the same as the intended owner).
     */
    function grantPositionOwnership(
        bytes32 positionId,
        address oldOwner,
        address newOwner
    )
        internal
        returns (address)
    {
        // log event except upon position creation
        if (oldOwner != address(0)) {
            emit PositionTransferred(positionId, oldOwner, newOwner);
        }

        if (AddressUtils.isContract(newOwner)) {
            address nextOwner =
                PositionOwner(newOwner).receivePositionOwnership(oldOwner, positionId);
            if (nextOwner != newOwner) {
                return grantPositionOwnership(positionId, newOwner, nextOwner);
            }
        }

        require(
            newOwner != address(0),
            "TransferInternal#grantPositionOwnership: New owner did not consent to owning position"
        );

        return newOwner;
    }
}

// File: contracts/lib/TimestampHelper.sol

/**
 * @title TimestampHelper
 * @author dYdX
 *
 * Helper to get block timestamps in other formats
 */
library TimestampHelper {
    function getBlockTimestamp32()
        internal
        view
        returns (uint32)
    {
        // Should not still be in-use in the year 2106
        assert(uint256(uint32(block.timestamp)) == block.timestamp);

        assert(block.timestamp > 0);

        return uint32(block.timestamp);
    }
}

// File: contracts/margin/impl/MarginCommon.sol

/**
 * @title MarginCommon
 * @author dYdX
 *
 * This library contains common functions for implementations of public facing Margin functions
 */
library MarginCommon {
    using SafeMath for uint256;

    // ============ Structs ============

    struct Position {
        address owedToken;       // Immutable
        address heldToken;       // Immutable
        address lender;
        address owner;
        uint256 principal;
        uint256 requiredDeposit;
        uint32  callTimeLimit;   // Immutable
        uint32  startTimestamp;  // Immutable, cannot be 0
        uint32  callTimestamp;
        uint32  maxDuration;     // Immutable
        uint32  interestRate;    // Immutable
        uint32  interestPeriod;  // Immutable
    }

    struct LoanOffering {
        address   owedToken;
        address   heldToken;
        address   payer;
        address   owner;
        address   taker;
        address   positionOwner;
        address   feeRecipient;
        address   lenderFeeToken;
        address   takerFeeToken;
        LoanRates rates;
        uint256   expirationTimestamp;
        uint32    callTimeLimit;
        uint32    maxDuration;
        uint256   salt;
        bytes32   loanHash;
        bytes     signature;
    }

    struct LoanRates {
        uint256 maxAmount;
        uint256 minAmount;
        uint256 minHeldToken;
        uint256 lenderFee;
        uint256 takerFee;
        uint32  interestRate;
        uint32  interestPeriod;
    }

    // ============ Internal Implementation Functions ============

    function storeNewPosition(
        MarginState.State storage state,
        bytes32 positionId,
        Position memory position,
        address loanPayer
    )
        internal
    {
        assert(!positionHasExisted(state, positionId));
        assert(position.owedToken != address(0));
        assert(position.heldToken != address(0));
        assert(position.owedToken != position.heldToken);
        assert(position.owner != address(0));
        assert(position.lender != address(0));
        assert(position.maxDuration != 0);
        assert(position.interestPeriod <= position.maxDuration);
        assert(position.callTimestamp == 0);
        assert(position.requiredDeposit == 0);

        state.positions[positionId].owedToken = position.owedToken;
        state.positions[positionId].heldToken = position.heldToken;
        state.positions[positionId].principal = position.principal;
        state.positions[positionId].callTimeLimit = position.callTimeLimit;
        state.positions[positionId].startTimestamp = TimestampHelper.getBlockTimestamp32();
        state.positions[positionId].maxDuration = position.maxDuration;
        state.positions[positionId].interestRate = position.interestRate;
        state.positions[positionId].interestPeriod = position.interestPeriod;

        state.positions[positionId].owner = TransferInternal.grantPositionOwnership(
            positionId,
            (position.owner != msg.sender) ? msg.sender : address(0),
            position.owner
        );

        state.positions[positionId].lender = TransferInternal.grantLoanOwnership(
            positionId,
            (position.lender != loanPayer) ? loanPayer : address(0),
            position.lender
        );
    }

    function getPositionIdFromNonce(
        uint256 nonce
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender, nonce));
    }

    function getUnavailableLoanOfferingAmountImpl(
        MarginState.State storage state,
        bytes32 loanHash
    )
        internal
        view
        returns (uint256)
    {
        return state.loanFills[loanHash].add(state.loanCancels[loanHash]);
    }

    function cleanupPosition(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
    {
        delete state.positions[positionId];
        state.closedPositions[positionId] = true;
    }

    function calculateOwedAmount(
        Position storage position,
        uint256 closeAmount,
        uint256 endTimestamp
    )
        internal
        view
        returns (uint256)
    {
        uint256 timeElapsed = calculateEffectiveTimeElapsed(position, endTimestamp);

        return InterestImpl.getCompoundedInterest(
            closeAmount,
            position.interestRate,
            timeElapsed
        );
    }

    /**
     * Calculates time elapsed rounded up to the nearest interestPeriod
     */
    function calculateEffectiveTimeElapsed(
        Position storage position,
        uint256 timestamp
    )
        internal
        view
        returns (uint256)
    {
        uint256 elapsed = timestamp.sub(position.startTimestamp);

        // round up to interestPeriod
        uint256 period = position.interestPeriod;
        if (period > 1) {
            elapsed = MathHelpers.divisionRoundedUp(elapsed, period).mul(period);
        }

        // bound by maxDuration
        return Math.min256(
            elapsed,
            position.maxDuration
        );
    }

    function calculateLenderAmountForIncreasePosition(
        Position storage position,
        uint256 principalToAdd,
        uint256 endTimestamp
    )
        internal
        view
        returns (uint256)
    {
        uint256 timeElapsed = calculateEffectiveTimeElapsedForNewLender(position, endTimestamp);

        return InterestImpl.getCompoundedInterest(
            principalToAdd,
            position.interestRate,
            timeElapsed
        );
    }

    function getLoanOfferingHash(
        LoanOffering loanOffering
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                loanOffering.owedToken,
                loanOffering.heldToken,
                loanOffering.payer,
                loanOffering.owner,
                loanOffering.taker,
                loanOffering.positionOwner,
                loanOffering.feeRecipient,
                loanOffering.lenderFeeToken,
                loanOffering.takerFeeToken,
                getValuesHash(loanOffering)
            )
        );
    }

    function getPositionBalanceImpl(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns(uint256)
    {
        return Vault(state.VAULT).balances(positionId, state.positions[positionId].heldToken);
    }

    function containsPositionImpl(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns (bool)
    {
        return state.positions[positionId].startTimestamp != 0;
    }

    function positionHasExisted(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns (bool)
    {
        return containsPositionImpl(state, positionId) || state.closedPositions[positionId];
    }

    function getPositionFromStorage(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns (Position storage)
    {
        Position storage position = state.positions[positionId];

        require(
            position.startTimestamp != 0,
            "MarginCommon#getPositionFromStorage: The position does not exist"
        );

        return position;
    }

    // ============ Private Helper-Functions ============

    /**
     * Calculates time elapsed rounded down to the nearest interestPeriod
     */
    function calculateEffectiveTimeElapsedForNewLender(
        Position storage position,
        uint256 timestamp
    )
        private
        view
        returns (uint256)
    {
        uint256 elapsed = timestamp.sub(position.startTimestamp);

        // round down to interestPeriod
        uint256 period = position.interestPeriod;
        if (period > 1) {
            elapsed = elapsed.div(period).mul(period);
        }

        // bound by maxDuration
        return Math.min256(
            elapsed,
            position.maxDuration
        );
    }

    function getValuesHash(
        LoanOffering loanOffering
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                loanOffering.rates.maxAmount,
                loanOffering.rates.minAmount,
                loanOffering.rates.minHeldToken,
                loanOffering.rates.lenderFee,
                loanOffering.rates.takerFee,
                loanOffering.expirationTimestamp,
                loanOffering.salt,
                loanOffering.callTimeLimit,
                loanOffering.maxDuration,
                loanOffering.rates.interestRate,
                loanOffering.rates.interestPeriod
            )
        );
    }
}

// File: contracts/margin/interfaces/PayoutRecipient.sol

/**
 * @title PayoutRecipient
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to be the payoutRecipient in a
 * closePosition transaction.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface PayoutRecipient {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to receive payout from being the payoutRecipient
     * in a closePosition transaction. May redistribute any payout as necessary. Throws on error.
     *
     * @param  positionId         Unique ID of the position
     * @param  closeAmount        Amount of the position that was closed
     * @param  closer             Address of the account or contract that closed the position
     * @param  positionOwner      Address of the owner of the position
     * @param  heldToken          Address of the ERC20 heldToken
     * @param  payout             Number of tokens received from the payout
     * @param  totalHeldToken     Total amount of heldToken removed from vault during close
     * @param  payoutInHeldToken  True if payout is in heldToken, false if in owedToken
     * @return                    True if approved by the receiver
     */
    function receiveClosePositionPayout(
        bytes32 positionId,
        uint256 closeAmount,
        address closer,
        address positionOwner,
        address heldToken,
        uint256 payout,
        uint256 totalHeldToken,
        bool    payoutInHeldToken
    )
        external
        /* onlyMargin */
        returns (bool);
}

// File: contracts/margin/interfaces/lender/CloseLoanDelegator.sol

/**
 * @title CloseLoanDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to let other addresses close a loan
 * owned by the smart contract.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface CloseLoanDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to let other addresses call
     * closeWithoutCounterparty().
     *
     * NOTE: If not returning zero (or not reverting), this contract must assume that Margin will
     * either revert the entire transaction or that (at most) the specified amount of the loan was
     * successfully closed.
     *
     * @param  closer           Address of the caller of closeWithoutCounterparty()
     * @param  payoutRecipient  Address of the recipient of tokens paid out from closing
     * @param  positionId       Unique ID of the position
     * @param  requestedAmount  Requested principal amount of the loan to close
     * @return                  1) This address to accept, a different address to ask that contract
     *                          2) The maximum amount that this contract is allowing
     */
    function closeLoanOnBehalfOf(
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 requestedAmount
    )
        external
        /* onlyMargin */
        returns (address, uint256);
}

// File: contracts/margin/interfaces/owner/ClosePositionDelegator.sol

/**
 * @title ClosePositionDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to let other addresses close a position
 * owned by the smart contract, allowing more complex logic to control positions.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface ClosePositionDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to let other addresses call closePosition().
     *
     * NOTE: If not returning zero (or not reverting), this contract must assume that Margin will
     * either revert the entire transaction or that (at-most) the specified amount of the position
     * was successfully closed.
     *
     * @param  closer           Address of the caller of the closePosition() function
     * @param  payoutRecipient  Address of the recipient of tokens paid out from closing
     * @param  positionId       Unique ID of the position
     * @param  requestedAmount  Requested principal amount of the position to close
     * @return                  1) This address to accept, a different address to ask that contract
     *                          2) The maximum amount that this contract is allowing
     */
    function closeOnBehalfOf(
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 requestedAmount
    )
        external
        /* onlyMargin */
        returns (address, uint256);
}

// File: contracts/margin/impl/ClosePositionShared.sol

/**
 * @title ClosePositionShared
 * @author dYdX
 *
 * This library contains shared functionality between ClosePositionImpl and
 * CloseWithoutCounterpartyImpl
 */
library ClosePositionShared {
    using SafeMath for uint256;

    // ============ Structs ============

    struct CloseTx {
        bytes32 positionId;
        uint256 originalPrincipal;
        uint256 closeAmount;
        uint256 owedTokenOwed;
        uint256 startingHeldTokenBalance;
        uint256 availableHeldToken;
        address payoutRecipient;
        address owedToken;
        address heldToken;
        address positionOwner;
        address positionLender;
        address exchangeWrapper;
        bool    payoutInHeldToken;
    }

    // ============ Internal Implementation Functions ============

    function closePositionStateUpdate(
        MarginState.State storage state,
        CloseTx memory transaction
    )
        internal
    {
        // Delete the position, or just decrease the principal
        if (transaction.closeAmount == transaction.originalPrincipal) {
            MarginCommon.cleanupPosition(state, transaction.positionId);
        } else {
            assert(
                transaction.originalPrincipal == state.positions[transaction.positionId].principal
            );
            state.positions[transaction.positionId].principal =
                transaction.originalPrincipal.sub(transaction.closeAmount);
        }
    }

    function sendTokensToPayoutRecipient(
        MarginState.State storage state,
        ClosePositionShared.CloseTx memory transaction,
        uint256 buybackCostInHeldToken,
        uint256 receivedOwedToken
    )
        internal
        returns (uint256)
    {
        uint256 payout;

        if (transaction.payoutInHeldToken) {
            // Send remaining heldToken to payoutRecipient
            payout = transaction.availableHeldToken.sub(buybackCostInHeldToken);

            Vault(state.VAULT).transferFromVault(
                transaction.positionId,
                transaction.heldToken,
                transaction.payoutRecipient,
                payout
            );
        } else {
            assert(transaction.exchangeWrapper != address(0));

            payout = receivedOwedToken.sub(transaction.owedTokenOwed);

            TokenProxy(state.TOKEN_PROXY).transferTokens(
                transaction.owedToken,
                transaction.exchangeWrapper,
                transaction.payoutRecipient,
                payout
            );
        }

        if (AddressUtils.isContract(transaction.payoutRecipient)) {
            require(
                PayoutRecipient(transaction.payoutRecipient).receiveClosePositionPayout(
                    transaction.positionId,
                    transaction.closeAmount,
                    msg.sender,
                    transaction.positionOwner,
                    transaction.heldToken,
                    payout,
                    transaction.availableHeldToken,
                    transaction.payoutInHeldToken
                ),
                "ClosePositionShared#sendTokensToPayoutRecipient: Payout recipient does not consent"
            );
        }

        // The ending heldToken balance of the vault should be the starting heldToken balance
        // minus the available heldToken amount
        assert(
            MarginCommon.getPositionBalanceImpl(state, transaction.positionId)
            == transaction.startingHeldTokenBalance.sub(transaction.availableHeldToken)
        );

        return payout;
    }

    function createCloseTx(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requestedAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool payoutInHeldToken,
        bool isWithoutCounterparty
    )
        internal
        returns (CloseTx memory)
    {
        // Validate
        require(
            payoutRecipient != address(0),
            "ClosePositionShared#createCloseTx: Payout recipient cannot be 0"
        );
        require(
            requestedAmount > 0,
            "ClosePositionShared#createCloseTx: Requested close amount cannot be 0"
        );

        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        uint256 closeAmount = getApprovedAmount(
            position,
            positionId,
            requestedAmount,
            payoutRecipient,
            isWithoutCounterparty
        );

        return parseCloseTx(
            state,
            position,
            positionId,
            closeAmount,
            payoutRecipient,
            exchangeWrapper,
            payoutInHeldToken,
            isWithoutCounterparty
        );
    }

    // ============ Private Helper-Functions ============

    function getApprovedAmount(
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 requestedAmount,
        address payoutRecipient,
        bool requireLenderApproval
    )
        private
        returns (uint256)
    {
        // Ensure enough principal
        uint256 allowedAmount = Math.min256(requestedAmount, position.principal);

        // Ensure owner consent
        allowedAmount = closePositionOnBehalfOfRecurse(
            position.owner,
            msg.sender,
            payoutRecipient,
            positionId,
            allowedAmount
        );

        // Ensure lender consent
        if (requireLenderApproval) {
            allowedAmount = closeLoanOnBehalfOfRecurse(
                position.lender,
                msg.sender,
                payoutRecipient,
                positionId,
                allowedAmount
            );
        }

        assert(allowedAmount > 0);
        assert(allowedAmount <= position.principal);
        assert(allowedAmount <= requestedAmount);

        return allowedAmount;
    }

    function closePositionOnBehalfOfRecurse(
        address contractAddr,
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 closeAmount
    )
        private
        returns (uint256)
    {
        // no need to ask for permission
        if (closer == contractAddr) {
            return closeAmount;
        }

        (
            address newContractAddr,
            uint256 newCloseAmount
        ) = ClosePositionDelegator(contractAddr).closeOnBehalfOf(
            closer,
            payoutRecipient,
            positionId,
            closeAmount
        );

        require(
            newCloseAmount <= closeAmount,
            "ClosePositionShared#closePositionRecurse: newCloseAmount is greater than closeAmount"
        );
        require(
            newCloseAmount > 0,
            "ClosePositionShared#closePositionRecurse: newCloseAmount is zero"
        );

        if (newContractAddr != contractAddr) {
            closePositionOnBehalfOfRecurse(
                newContractAddr,
                closer,
                payoutRecipient,
                positionId,
                newCloseAmount
            );
        }

        return newCloseAmount;
    }

    function closeLoanOnBehalfOfRecurse(
        address contractAddr,
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 closeAmount
    )
        private
        returns (uint256)
    {
        // no need to ask for permission
        if (closer == contractAddr) {
            return closeAmount;
        }

        (
            address newContractAddr,
            uint256 newCloseAmount
        ) = CloseLoanDelegator(contractAddr).closeLoanOnBehalfOf(
                closer,
                payoutRecipient,
                positionId,
                closeAmount
            );

        require(
            newCloseAmount <= closeAmount,
            "ClosePositionShared#closeLoanRecurse: newCloseAmount is greater than closeAmount"
        );
        require(
            newCloseAmount > 0,
            "ClosePositionShared#closeLoanRecurse: newCloseAmount is zero"
        );

        if (newContractAddr != contractAddr) {
            closeLoanOnBehalfOfRecurse(
                newContractAddr,
                closer,
                payoutRecipient,
                positionId,
                newCloseAmount
            );
        }

        return newCloseAmount;
    }

    // ============ Parsing Functions ============

    function parseCloseTx(
        MarginState.State storage state,
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 closeAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool payoutInHeldToken,
        bool isWithoutCounterparty
    )
        private
        view
        returns (CloseTx memory)
    {
        uint256 startingHeldTokenBalance = MarginCommon.getPositionBalanceImpl(state, positionId);

        uint256 availableHeldToken = MathHelpers.getPartialAmount(
            closeAmount,
            position.principal,
            startingHeldTokenBalance
        );
        uint256 owedTokenOwed = 0;

        if (!isWithoutCounterparty) {
            owedTokenOwed = MarginCommon.calculateOwedAmount(
                position,
                closeAmount,
                block.timestamp
            );
        }

        return CloseTx({
            positionId: positionId,
            originalPrincipal: position.principal,
            closeAmount: closeAmount,
            owedTokenOwed: owedTokenOwed,
            startingHeldTokenBalance: startingHeldTokenBalance,
            availableHeldToken: availableHeldToken,
            payoutRecipient: payoutRecipient,
            owedToken: position.owedToken,
            heldToken: position.heldToken,
            positionOwner: position.owner,
            positionLender: position.lender,
            exchangeWrapper: exchangeWrapper,
            payoutInHeldToken: payoutInHeldToken
        });
    }
}

// File: contracts/margin/interfaces/ExchangeWrapper.sol

/**
 * @title ExchangeWrapper
 * @author dYdX
 *
 * Contract interface that Exchange Wrapper smart contracts must implement in order to interface
 * with other smart contracts through a common interface.
 */
interface ExchangeWrapper {

    // ============ Public Functions ============

    /**
     * Exchange some amount of takerToken for makerToken.
     *
     * @param  tradeOriginator      Address of the initiator of the trade (however, this value
     *                              cannot always be trusted as it is set at the discretion of the
     *                              msg.sender)
     * @param  receiver             Address to set allowance on once the trade has completed
     * @param  makerToken           Address of makerToken, the token to receive
     * @param  takerToken           Address of takerToken, the token to pay
     * @param  requestedFillAmount  Amount of takerToken being paid
     * @param  orderData            Arbitrary bytes data for any information to pass to the exchange
     * @return                      The amount of makerToken received
     */
    function exchange(
        address tradeOriginator,
        address receiver,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount,
        bytes orderData
    )
        external
        returns (uint256);

    /**
     * Get amount of takerToken required to buy a certain amount of makerToken for a given trade.
     * Should match the takerToken amount used in exchangeForAmount. If the order cannot provide
     * exactly desiredMakerToken, then it must return the price to buy the minimum amount greater
     * than desiredMakerToken
     *
     * @param  makerToken         Address of makerToken, the token to receive
     * @param  takerToken         Address of takerToken, the token to pay
     * @param  desiredMakerToken  Amount of makerToken requested
     * @param  orderData          Arbitrary bytes data for any information to pass to the exchange
     * @return                    Amount of takerToken the needed to complete the transaction
     */
    function getExchangeCost(
        address makerToken,
        address takerToken,
        uint256 desiredMakerToken,
        bytes orderData
    )
        external
        view
        returns (uint256);
}

// File: contracts/margin/impl/ClosePositionImpl.sol

/**
 * @title ClosePositionImpl
 * @author dYdX
 *
 * This library contains the implementation for the closePosition function of Margin
 */
library ClosePositionImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /**
     * A position was closed or partially closed
     */
    event PositionClosed(
        bytes32 indexed positionId,
        address indexed closer,
        address indexed payoutRecipient,
        uint256 closeAmount,
        uint256 remainingAmount,
        uint256 owedTokenPaidToLender,
        uint256 payoutAmount,
        uint256 buybackCostInHeldToken,
        bool    payoutInHeldToken
    );

    // ============ Public Implementation Functions ============

    function closePositionImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool payoutInHeldToken,
        bytes memory orderData
    )
        public
        returns (uint256, uint256, uint256)
    {
        ClosePositionShared.CloseTx memory transaction = ClosePositionShared.createCloseTx(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            exchangeWrapper,
            payoutInHeldToken,
            false
        );

        (
            uint256 buybackCostInHeldToken,
            uint256 receivedOwedToken
        ) = returnOwedTokensToLender(
            state,
            transaction,
            orderData
        );

        uint256 payout = ClosePositionShared.sendTokensToPayoutRecipient(
            state,
            transaction,
            buybackCostInHeldToken,
            receivedOwedToken
        );

        ClosePositionShared.closePositionStateUpdate(state, transaction);

        logEventOnClose(
            transaction,
            buybackCostInHeldToken,
            payout
        );

        return (
            transaction.closeAmount,
            payout,
            transaction.owedTokenOwed
        );
    }

    // ============ Private Helper-Functions ============

    function returnOwedTokensToLender(
        MarginState.State storage state,
        ClosePositionShared.CloseTx memory transaction,
        bytes memory orderData
    )
        private
        returns (uint256, uint256)
    {
        uint256 buybackCostInHeldToken = 0;
        uint256 receivedOwedToken = 0;
        uint256 lenderOwedToken = transaction.owedTokenOwed;

        // Setting exchangeWrapper to 0x000... indicates owedToken should be taken directly
        // from msg.sender
        if (transaction.exchangeWrapper == address(0)) {
            require(
                transaction.payoutInHeldToken,
                "ClosePositionImpl#returnOwedTokensToLender: Cannot payout in owedToken"
            );

            // No DEX Order; send owedTokens directly from the closer to the lender
            TokenProxy(state.TOKEN_PROXY).transferTokens(
                transaction.owedToken,
                msg.sender,
                transaction.positionLender,
                lenderOwedToken
            );
        } else {
            // Buy back owedTokens using DEX Order and send to lender
            (buybackCostInHeldToken, receivedOwedToken) = buyBackOwedToken(
                state,
                transaction,
                orderData
            );

            // If no owedToken needed for payout: give lender all owedToken, even if more than owed
            if (transaction.payoutInHeldToken) {
                assert(receivedOwedToken >= lenderOwedToken);
                lenderOwedToken = receivedOwedToken;
            }

            // Transfer owedToken from the exchange wrapper to the lender
            TokenProxy(state.TOKEN_PROXY).transferTokens(
                transaction.owedToken,
                transaction.exchangeWrapper,
                transaction.positionLender,
                lenderOwedToken
            );
        }

        state.totalOwedTokenRepaidToLender[transaction.positionId] =
            state.totalOwedTokenRepaidToLender[transaction.positionId].add(lenderOwedToken);

        return (buybackCostInHeldToken, receivedOwedToken);
    }

    function buyBackOwedToken(
        MarginState.State storage state,
        ClosePositionShared.CloseTx transaction,
        bytes memory orderData
    )
        private
        returns (uint256, uint256)
    {
        // Ask the exchange wrapper the cost in heldToken to buy back the close
        // amount of owedToken
        uint256 buybackCostInHeldToken;

        if (transaction.payoutInHeldToken) {
            buybackCostInHeldToken = ExchangeWrapper(transaction.exchangeWrapper)
                .getExchangeCost(
                    transaction.owedToken,
                    transaction.heldToken,
                    transaction.owedTokenOwed,
                    orderData
                );

            // Require enough available heldToken to pay for the buyback
            require(
                buybackCostInHeldToken <= transaction.availableHeldToken,
                "ClosePositionImpl#buyBackOwedToken: Not enough available heldToken"
            );
        } else {
            buybackCostInHeldToken = transaction.availableHeldToken;
        }

        // Send the requisite heldToken to do the buyback from vault to exchange wrapper
        Vault(state.VAULT).transferFromVault(
            transaction.positionId,
            transaction.heldToken,
            transaction.exchangeWrapper,
            buybackCostInHeldToken
        );

        // Trade the heldToken for the owedToken
        uint256 receivedOwedToken = ExchangeWrapper(transaction.exchangeWrapper).exchange(
            msg.sender,
            state.TOKEN_PROXY,
            transaction.owedToken,
            transaction.heldToken,
            buybackCostInHeldToken,
            orderData
        );

        require(
            receivedOwedToken >= transaction.owedTokenOwed,
            "ClosePositionImpl#buyBackOwedToken: Did not receive enough owedToken"
        );

        return (buybackCostInHeldToken, receivedOwedToken);
    }

    function logEventOnClose(
        ClosePositionShared.CloseTx transaction,
        uint256 buybackCostInHeldToken,
        uint256 payout
    )
        private
    {
        emit PositionClosed(
            transaction.positionId,
            msg.sender,
            transaction.payoutRecipient,
            transaction.closeAmount,
            transaction.originalPrincipal.sub(transaction.closeAmount),
            transaction.owedTokenOwed,
            payout,
            buybackCostInHeldToken,
            transaction.payoutInHeldToken
        );
    }

}

// File: contracts/margin/impl/CloseWithoutCounterpartyImpl.sol

/**
 * @title CloseWithoutCounterpartyImpl
 * @author dYdX
 *
 * This library contains the implementation for the closeWithoutCounterpartyImpl function of
 * Margin
 */
library CloseWithoutCounterpartyImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /**
     * A position was closed or partially closed
     */
    event PositionClosed(
        bytes32 indexed positionId,
        address indexed closer,
        address indexed payoutRecipient,
        uint256 closeAmount,
        uint256 remainingAmount,
        uint256 owedTokenPaidToLender,
        uint256 payoutAmount,
        uint256 buybackCostInHeldToken,
        bool payoutInHeldToken
    );

    // ============ Public Implementation Functions ============

    function closeWithoutCounterpartyImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient
    )
        public
        returns (uint256, uint256)
    {
        ClosePositionShared.CloseTx memory transaction = ClosePositionShared.createCloseTx(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            address(0),
            true,
            true
        );

        uint256 heldTokenPayout = ClosePositionShared.sendTokensToPayoutRecipient(
            state,
            transaction,
            0, // No buyback cost
            0  // Did not receive any owedToken
        );

        ClosePositionShared.closePositionStateUpdate(state, transaction);

        logEventOnCloseWithoutCounterparty(transaction);

        return (
            transaction.closeAmount,
            heldTokenPayout
        );
    }

    // ============ Private Helper-Functions ============

    function logEventOnCloseWithoutCounterparty(
        ClosePositionShared.CloseTx transaction
    )
        private
    {
        emit PositionClosed(
            transaction.positionId,
            msg.sender,
            transaction.payoutRecipient,
            transaction.closeAmount,
            transaction.originalPrincipal.sub(transaction.closeAmount),
            0,
            transaction.availableHeldToken,
            0,
            true
        );
    }
}

// File: contracts/margin/interfaces/owner/DepositCollateralDelegator.sol

/**
 * @title DepositCollateralDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to let other addresses deposit heldTokens
 * into a position owned by the smart contract.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface DepositCollateralDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to let other addresses call depositCollateral().
     *
     * @param  depositor   Address of the caller of the depositCollateral() function
     * @param  positionId  Unique ID of the position
     * @param  amount      Requested deposit amount
     * @return             This address to accept, a different address to ask that contract
     */
    function depositCollateralOnBehalfOf(
        address depositor,
        bytes32 positionId,
        uint256 amount
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/impl/DepositCollateralImpl.sol

/**
 * @title DepositCollateralImpl
 * @author dYdX
 *
 * This library contains the implementation for the deposit function of Margin
 */
library DepositCollateralImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /**
     * Additional collateral for a position was posted by the owner
     */
    event AdditionalCollateralDeposited(
        bytes32 indexed positionId,
        uint256 amount,
        address depositor
    );

    /**
     * A margin call was canceled
     */
    event MarginCallCanceled(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 depositAmount
    );

    // ============ Public Implementation Functions ============

    function depositCollateralImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 depositAmount
    )
        public
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            depositAmount > 0,
            "DepositCollateralImpl#depositCollateralImpl: Deposit amount cannot be 0"
        );

        // Ensure owner consent
        depositCollateralOnBehalfOfRecurse(
            position.owner,
            msg.sender,
            positionId,
            depositAmount
        );

        Vault(state.VAULT).transferToVault(
            positionId,
            position.heldToken,
            msg.sender,
            depositAmount
        );

        // cancel margin call if applicable
        bool marginCallCanceled = false;
        uint256 requiredDeposit = position.requiredDeposit;
        if (position.callTimestamp > 0 && requiredDeposit > 0) {
            if (depositAmount >= requiredDeposit) {
                position.requiredDeposit = 0;
                position.callTimestamp = 0;
                marginCallCanceled = true;
            } else {
                position.requiredDeposit = position.requiredDeposit.sub(depositAmount);
            }
        }

        emit AdditionalCollateralDeposited(
            positionId,
            depositAmount,
            msg.sender
        );

        if (marginCallCanceled) {
            emit MarginCallCanceled(
                positionId,
                position.lender,
                msg.sender,
                depositAmount
            );
        }
    }

    // ============ Private Helper-Functions ============

    function depositCollateralOnBehalfOfRecurse(
        address contractAddr,
        address depositor,
        bytes32 positionId,
        uint256 amount
    )
        private
    {
        // no need to ask for permission
        if (depositor == contractAddr) {
            return;
        }

        address newContractAddr =
            DepositCollateralDelegator(contractAddr).depositCollateralOnBehalfOf(
                depositor,
                positionId,
                amount
            );

        // if not equal, recurse
        if (newContractAddr != contractAddr) {
            depositCollateralOnBehalfOfRecurse(
                newContractAddr,
                depositor,
                positionId,
                amount
            );
        }
    }
}

// File: contracts/margin/interfaces/lender/ForceRecoverCollateralDelegator.sol

/**
 * @title ForceRecoverCollateralDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to let other addresses
 * forceRecoverCollateral() a loan owned by the smart contract.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface ForceRecoverCollateralDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to let other addresses call
     * forceRecoverCollateral().
     *
     * NOTE: If not returning zero address (or not reverting), this contract must assume that Margin
     * will either revert the entire transaction or that the collateral was forcibly recovered.
     *
     * @param  recoverer   Address of the caller of the forceRecoverCollateral() function
     * @param  positionId  Unique ID of the position
     * @param  recipient   Address to send the recovered tokens to
     * @return             This address to accept, a different address to ask that contract
     */
    function forceRecoverCollateralOnBehalfOf(
        address recoverer,
        bytes32 positionId,
        address recipient
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/impl/ForceRecoverCollateralImpl.sol

/**
 * @title ForceRecoverCollateralImpl
 * @author dYdX
 *
 * This library contains the implementation for the forceRecoverCollateral function of Margin
 */
library ForceRecoverCollateralImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /**
     * Collateral for a position was forcibly recovered
     */
    event CollateralForceRecovered(
        bytes32 indexed positionId,
        address indexed recipient,
        uint256 amount
    );

    // ============ Public Implementation Functions ============

    function forceRecoverCollateralImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address recipient
    )
        public
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        // Can only force recover after either:
        // 1) The loan was called and the call period has elapsed
        // 2) The maxDuration of the position has elapsed
        require( /* solium-disable-next-line */
            (
                position.callTimestamp > 0
                && block.timestamp >= uint256(position.callTimestamp).add(position.callTimeLimit)
            ) || (
                block.timestamp >= uint256(position.startTimestamp).add(position.maxDuration)
            ),
            "ForceRecoverCollateralImpl#forceRecoverCollateralImpl: Cannot recover yet"
        );

        // Ensure lender consent
        forceRecoverCollateralOnBehalfOfRecurse(
            position.lender,
            msg.sender,
            positionId,
            recipient
        );

        // Send the tokens
        uint256 heldTokenRecovered = MarginCommon.getPositionBalanceImpl(state, positionId);
        Vault(state.VAULT).transferFromVault(
            positionId,
            position.heldToken,
            recipient,
            heldTokenRecovered
        );

        // Delete the position
        // NOTE: Since position is a storage pointer, this will also set all fields on
        //       the position variable to 0
        MarginCommon.cleanupPosition(
            state,
            positionId
        );

        // Log an event
        emit CollateralForceRecovered(
            positionId,
            recipient,
            heldTokenRecovered
        );

        return heldTokenRecovered;
    }

    // ============ Private Helper-Functions ============

    function forceRecoverCollateralOnBehalfOfRecurse(
        address contractAddr,
        address recoverer,
        bytes32 positionId,
        address recipient
    )
        private
    {
        // no need to ask for permission
        if (recoverer == contractAddr) {
            return;
        }

        address newContractAddr =
            ForceRecoverCollateralDelegator(contractAddr).forceRecoverCollateralOnBehalfOf(
                recoverer,
                positionId,
                recipient
            );

        if (newContractAddr != contractAddr) {
            forceRecoverCollateralOnBehalfOfRecurse(
                newContractAddr,
                recoverer,
                positionId,
                recipient
            );
        }
    }
}

// File: contracts/lib/TypedSignature.sol

/**
 * @title TypedSignature
 * @author dYdX
 *
 * Allows for ecrecovery of signed hashes with three different prepended messages:
 * 1) ""
 * 2) "\x19Ethereum Signed Message:\n32"
 * 3) "\x19Ethereum Signed Message:\n\x20"
 */
library TypedSignature {

    // Solidity does not offer guarantees about enum values, so we define them explicitly
    uint8 private constant SIGTYPE_INVALID = 0;
    uint8 private constant SIGTYPE_ECRECOVER_DEC = 1;
    uint8 private constant SIGTYPE_ECRECOVER_HEX = 2;
    uint8 private constant SIGTYPE_UNSUPPORTED = 3;

    // prepended message with the length of the signed hash in hexadecimal
    bytes constant private PREPEND_HEX = "\x19Ethereum Signed Message:\n\x20";

    // prepended message with the length of the signed hash in decimal
    bytes constant private PREPEND_DEC = "\x19Ethereum Signed Message:\n32";

    /**
     * Gives the address of the signer of a hash. Allows for three common prepended strings.
     *
     * @param  hash               Hash that was signed (does not include prepended message)
     * @param  signatureWithType  Type and ECDSA signature with structure: {1:type}{1:v}{32:r}{32:s}
     * @return                    address of the signer of the hash
     */
    function recover(
        bytes32 hash,
        bytes signatureWithType
    )
        internal
        pure
        returns (address)
    {
        require(
            signatureWithType.length == 66,
            "SignatureValidator#validateSignature: invalid signature length"
        );

        uint8 sigType = uint8(signatureWithType[0]);

        require(
            sigType > uint8(SIGTYPE_INVALID),
            "SignatureValidator#validateSignature: invalid signature type"
        );
        require(
            sigType < uint8(SIGTYPE_UNSUPPORTED),
            "SignatureValidator#validateSignature: unsupported signature type"
        );

        uint8 v = uint8(signatureWithType[1]);
        bytes32 r;
        bytes32 s;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            r := mload(add(signatureWithType, 34))
            s := mload(add(signatureWithType, 66))
        }

        bytes32 signedHash;
        if (sigType == SIGTYPE_ECRECOVER_DEC) {
            signedHash = keccak256(abi.encodePacked(PREPEND_DEC, hash));
        } else {
            assert(sigType == SIGTYPE_ECRECOVER_HEX);
            signedHash = keccak256(abi.encodePacked(PREPEND_HEX, hash));
        }

        return ecrecover(
            signedHash,
            v,
            r,
            s
        );
    }
}

// File: contracts/margin/interfaces/LoanOfferingVerifier.sol

/**
 * @title LoanOfferingVerifier
 * @author dYdX
 *
 * Interface that smart contracts must implement to be able to make off-chain generated
 * loan offerings.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface LoanOfferingVerifier {

    /**
     * Function a smart contract must implement to be able to consent to a loan. The loan offering
     * will be generated off-chain. The "loan owner" address will own the loan-side of the resulting
     * position.
     *
     * If true is returned, and no errors are thrown by the Margin contract, the loan will have
     * occurred. This means that verifyLoanOffering can also be used to update internal contract
     * state on a loan.
     *
     * @param  addresses    Array of addresses:
     *
     *  [0] = owedToken
     *  [1] = heldToken
     *  [2] = loan payer
     *  [3] = loan owner
     *  [4] = loan taker
     *  [5] = loan positionOwner
     *  [6] = loan fee recipient
     *  [7] = loan lender fee token
     *  [8] = loan taker fee token
     *
     * @param  values256    Values corresponding to:
     *
     *  [0] = loan maximum amount
     *  [1] = loan minimum amount
     *  [2] = loan minimum heldToken
     *  [3] = loan lender fee
     *  [4] = loan taker fee
     *  [5] = loan expiration timestamp (in seconds)
     *  [6] = loan salt
     *
     * @param  values32     Values corresponding to:
     *
     *  [0] = loan call time limit (in seconds)
     *  [1] = loan maxDuration (in seconds)
     *  [2] = loan interest rate (annual nominal percentage times 10**6)
     *  [3] = loan interest update period (in seconds)
     *
     * @param  positionId   Unique ID of the position
     * @param  signature    Arbitrary bytes; may or may not be an ECDSA signature
     * @return              This address to accept, a different address to ask that contract
     */
    function verifyLoanOffering(
        address[9] addresses,
        uint256[7] values256,
        uint32[4] values32,
        bytes32 positionId,
        bytes signature
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/impl/BorrowShared.sol

/**
 * @title BorrowShared
 * @author dYdX
 *
 * This library contains shared functionality between OpenPositionImpl and IncreasePositionImpl.
 * Both use a Loan Offering and a DEX Order to open or increase a position.
 */
library BorrowShared {
    using SafeMath for uint256;

    // ============ Structs ============

    struct Tx {
        bytes32 positionId;
        address owner;
        uint256 principal;
        uint256 lenderAmount;
        MarginCommon.LoanOffering loanOffering;
        address exchangeWrapper;
        bool depositInHeldToken;
        uint256 depositAmount;
        uint256 collateralAmount;
        uint256 heldTokenFromSell;
    }

    // ============ Internal Implementation Functions ============

    /**
     * Validate the transaction before exchanging heldToken for owedToken
     */
    function validateTxPreSell(
        MarginState.State storage state,
        Tx memory transaction
    )
        internal
    {
        assert(transaction.lenderAmount >= transaction.principal);

        require(
            transaction.principal > 0,
            "BorrowShared#validateTxPreSell: Positions with 0 principal are not allowed"
        );

        // If the taker is 0x0 then any address can take it. Otherwise only the taker can use it.
        if (transaction.loanOffering.taker != address(0)) {
            require(
                msg.sender == transaction.loanOffering.taker,
                "BorrowShared#validateTxPreSell: Invalid loan offering taker"
            );
        }

        // If the positionOwner is 0x0 then any address can be set as the position owner.
        // Otherwise only the specified positionOwner can be set as the position owner.
        if (transaction.loanOffering.positionOwner != address(0)) {
            require(
                transaction.owner == transaction.loanOffering.positionOwner,
                "BorrowShared#validateTxPreSell: Invalid position owner"
            );
        }

        // Require the loan offering to be approved by the payer
        if (AddressUtils.isContract(transaction.loanOffering.payer)) {
            getConsentFromSmartContractLender(transaction);
        } else {
            require(
                transaction.loanOffering.payer == TypedSignature.recover(
                    transaction.loanOffering.loanHash,
                    transaction.loanOffering.signature
                ),
                "BorrowShared#validateTxPreSell: Invalid loan offering signature"
            );
        }

        // Validate the amount is <= than max and >= min
        uint256 unavailable = MarginCommon.getUnavailableLoanOfferingAmountImpl(
            state,
            transaction.loanOffering.loanHash
        );
        require(
            transaction.lenderAmount.add(unavailable) <= transaction.loanOffering.rates.maxAmount,
            "BorrowShared#validateTxPreSell: Loan offering does not have enough available"
        );

        require(
            transaction.lenderAmount >= transaction.loanOffering.rates.minAmount,
            "BorrowShared#validateTxPreSell: Lender amount is below loan offering minimum amount"
        );

        require(
            transaction.loanOffering.owedToken != transaction.loanOffering.heldToken,
            "BorrowShared#validateTxPreSell: owedToken cannot be equal to heldToken"
        );

        require(
            transaction.owner != address(0),
            "BorrowShared#validateTxPreSell: Position owner cannot be 0"
        );

        require(
            transaction.loanOffering.owner != address(0),
            "BorrowShared#validateTxPreSell: Loan owner cannot be 0"
        );

        require(
            transaction.loanOffering.expirationTimestamp > block.timestamp,
            "BorrowShared#validateTxPreSell: Loan offering is expired"
        );

        require(
            transaction.loanOffering.maxDuration > 0,
            "BorrowShared#validateTxPreSell: Loan offering has 0 maximum duration"
        );

        require(
            transaction.loanOffering.rates.interestPeriod <= transaction.loanOffering.maxDuration,
            "BorrowShared#validateTxPreSell: Loan offering interestPeriod > maxDuration"
        );

        // The minimum heldToken is validated after executing the sell
        // Position and loan ownership is validated in TransferInternal
    }

    /**
     * Validate the transaction after exchanging heldToken for owedToken, pay out fees, and store
     * how much of the loan was used.
     */
    function doPostSell(
        MarginState.State storage state,
        Tx memory transaction
    )
        internal
    {
        validateTxPostSell(transaction);

        // Transfer feeTokens from trader and lender
        transferLoanFees(state, transaction);

        // Update global amounts for the loan
        state.loanFills[transaction.loanOffering.loanHash] =
            state.loanFills[transaction.loanOffering.loanHash].add(transaction.lenderAmount);
    }

    /**
     * Sells the owedToken from the lender (and from the deposit if in owedToken) using the
     * exchangeWrapper, then puts the resulting heldToken into the vault. Only trades for
     * maxHeldTokenToBuy of heldTokens at most.
     */
    function doSell(
        MarginState.State storage state,
        Tx transaction,
        bytes orderData,
        uint256 maxHeldTokenToBuy
    )
        internal
        returns (uint256)
    {
        // Move owedTokens from lender to exchange wrapper
        pullOwedTokensFromLender(state, transaction);

        // Sell just the lender&#39;s owedToken (if trader deposit is in heldToken)
        // Otherwise sell both the lender&#39;s owedToken and the trader&#39;s deposit in owedToken
        uint256 sellAmount = transaction.depositInHeldToken ?
            transaction.lenderAmount :
            transaction.lenderAmount.add(transaction.depositAmount);

        // Do the trade, taking only the maxHeldTokenToBuy if more is returned
        uint256 heldTokenFromSell = Math.min256(
            maxHeldTokenToBuy,
            ExchangeWrapper(transaction.exchangeWrapper).exchange(
                msg.sender,
                state.TOKEN_PROXY,
                transaction.loanOffering.heldToken,
                transaction.loanOffering.owedToken,
                sellAmount,
                orderData
            )
        );

        // Move the tokens to the vault
        Vault(state.VAULT).transferToVault(
            transaction.positionId,
            transaction.loanOffering.heldToken,
            transaction.exchangeWrapper,
            heldTokenFromSell
        );

        // Update collateral amount
        transaction.collateralAmount = transaction.collateralAmount.add(heldTokenFromSell);

        return heldTokenFromSell;
    }

    /**
     * Take the owedToken deposit from the trader and give it to the exchange wrapper so that it can
     * be sold for heldToken.
     */
    function doDepositOwedToken(
        MarginState.State storage state,
        Tx transaction
    )
        internal
    {
        TokenProxy(state.TOKEN_PROXY).transferTokens(
            transaction.loanOffering.owedToken,
            msg.sender,
            transaction.exchangeWrapper,
            transaction.depositAmount
        );
    }

    /**
     * Take the heldToken deposit from the trader and move it to the vault.
     */
    function doDepositHeldToken(
        MarginState.State storage state,
        Tx transaction
    )
        internal
    {
        Vault(state.VAULT).transferToVault(
            transaction.positionId,
            transaction.loanOffering.heldToken,
            msg.sender,
            transaction.depositAmount
        );

        // Update collateral amount
        transaction.collateralAmount = transaction.collateralAmount.add(transaction.depositAmount);
    }

    // ============ Private Helper-Functions ============

    function validateTxPostSell(
        Tx transaction
    )
        private
        pure
    {
        uint256 expectedCollateral = transaction.depositInHeldToken ?
            transaction.heldTokenFromSell.add(transaction.depositAmount) :
            transaction.heldTokenFromSell;
        assert(transaction.collateralAmount == expectedCollateral);

        uint256 loanOfferingMinimumHeldToken = MathHelpers.getPartialAmountRoundedUp(
            transaction.lenderAmount,
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.minHeldToken
        );
        require(
            transaction.collateralAmount >= loanOfferingMinimumHeldToken,
            "BorrowShared#validateTxPostSell: Loan offering minimum held token not met"
        );
    }

    function getConsentFromSmartContractLender(
        Tx transaction
    )
        private
    {
        verifyLoanOfferingRecurse(
            transaction.loanOffering.payer,
            getLoanOfferingAddresses(transaction),
            getLoanOfferingValues256(transaction),
            getLoanOfferingValues32(transaction),
            transaction.positionId,
            transaction.loanOffering.signature
        );
    }

    function verifyLoanOfferingRecurse(
        address contractAddr,
        address[9] addresses,
        uint256[7] values256,
        uint32[4] values32,
        bytes32 positionId,
        bytes signature
    )
        private
    {
        address newContractAddr = LoanOfferingVerifier(contractAddr).verifyLoanOffering(
            addresses,
            values256,
            values32,
            positionId,
            signature
        );

        if (newContractAddr != contractAddr) {
            verifyLoanOfferingRecurse(
                newContractAddr,
                addresses,
                values256,
                values32,
                positionId,
                signature
            );
        }
    }

    function pullOwedTokensFromLender(
        MarginState.State storage state,
        Tx transaction
    )
        private
    {
        // Transfer owedToken to the exchange wrapper
        TokenProxy(state.TOKEN_PROXY).transferTokens(
            transaction.loanOffering.owedToken,
            transaction.loanOffering.payer,
            transaction.exchangeWrapper,
            transaction.lenderAmount
        );
    }

    function transferLoanFees(
        MarginState.State storage state,
        Tx transaction
    )
        private
    {
        // 0 fee address indicates no fees
        if (transaction.loanOffering.feeRecipient == address(0)) {
            return;
        }

        TokenProxy proxy = TokenProxy(state.TOKEN_PROXY);

        uint256 lenderFee = MathHelpers.getPartialAmount(
            transaction.lenderAmount,
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.lenderFee
        );
        uint256 takerFee = MathHelpers.getPartialAmount(
            transaction.lenderAmount,
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.takerFee
        );

        if (lenderFee > 0) {
            proxy.transferTokens(
                transaction.loanOffering.lenderFeeToken,
                transaction.loanOffering.payer,
                transaction.loanOffering.feeRecipient,
                lenderFee
            );
        }

        if (takerFee > 0) {
            proxy.transferTokens(
                transaction.loanOffering.takerFeeToken,
                msg.sender,
                transaction.loanOffering.feeRecipient,
                takerFee
            );
        }
    }

    function getLoanOfferingAddresses(
        Tx transaction
    )
        private
        pure
        returns (address[9])
    {
        return [
            transaction.loanOffering.owedToken,
            transaction.loanOffering.heldToken,
            transaction.loanOffering.payer,
            transaction.loanOffering.owner,
            transaction.loanOffering.taker,
            transaction.loanOffering.positionOwner,
            transaction.loanOffering.feeRecipient,
            transaction.loanOffering.lenderFeeToken,
            transaction.loanOffering.takerFeeToken
        ];
    }

    function getLoanOfferingValues256(
        Tx transaction
    )
        private
        pure
        returns (uint256[7])
    {
        return [
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.minAmount,
            transaction.loanOffering.rates.minHeldToken,
            transaction.loanOffering.rates.lenderFee,
            transaction.loanOffering.rates.takerFee,
            transaction.loanOffering.expirationTimestamp,
            transaction.loanOffering.salt
        ];
    }

    function getLoanOfferingValues32(
        Tx transaction
    )
        private
        pure
        returns (uint32[4])
    {
        return [
            transaction.loanOffering.callTimeLimit,
            transaction.loanOffering.maxDuration,
            transaction.loanOffering.rates.interestRate,
            transaction.loanOffering.rates.interestPeriod
        ];
    }
}

// File: contracts/margin/interfaces/lender/IncreaseLoanDelegator.sol

/**
 * @title IncreaseLoanDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to own loans on behalf of other accounts.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface IncreaseLoanDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to allow additional value to be added onto
     * an owned loan. Margin will call this on the owner of a loan during increasePosition().
     *
     * NOTE: If not returning zero (or not reverting), this contract must assume that Margin will
     * either revert the entire transaction or that the loan size was successfully increased.
     *
     * @param  payer           Lender adding additional funds to the position
     * @param  positionId      Unique ID of the position
     * @param  principalAdded  Principal amount to be added to the position
     * @param  lentAmount      Amount of owedToken lent by the lender (principal plus interest, or
     *                         zero if increaseWithoutCounterparty() is used).
     * @return                 This address to accept, a different address to ask that contract
     */
    function increaseLoanOnBehalfOf(
        address payer,
        bytes32 positionId,
        uint256 principalAdded,
        uint256 lentAmount
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/interfaces/owner/IncreasePositionDelegator.sol

/**
 * @title IncreasePositionDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to own position on behalf of other
 * accounts
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface IncreasePositionDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to allow additional value to be added onto
     * an owned position. Margin will call this on the owner of a position during increasePosition()
     *
     * NOTE: If not returning zero (or not reverting), this contract must assume that Margin will
     * either revert the entire transaction or that the position size was successfully increased.
     *
     * @param  trader          Address initiating the addition of funds to the position
     * @param  positionId      Unique ID of the position
     * @param  principalAdded  Amount of principal to be added to the position
     * @return                 This address to accept, a different address to ask that contract
     */
    function increasePositionOnBehalfOf(
        address trader,
        bytes32 positionId,
        uint256 principalAdded
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/impl/IncreasePositionImpl.sol

/**
 * @title IncreasePositionImpl
 * @author dYdX
 *
 * This library contains the implementation for the increasePosition function of Margin
 */
library IncreasePositionImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /*
     * A position was increased
     */
    event PositionIncreased(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        address positionOwner,
        address loanOwner,
        bytes32 loanHash,
        address loanFeeRecipient,
        uint256 amountBorrowed,
        uint256 principalAdded,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        bool    depositInHeldToken
    );

    // ============ Public Implementation Functions ============

    function increasePositionImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address[7] addresses,
        uint256[8] values256,
        uint32[2] values32,
        bool depositInHeldToken,
        bytes signature,
        bytes orderData
    )
        public
        returns (uint256)
    {
        // Also ensures that the position exists
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        BorrowShared.Tx memory transaction = parseIncreasePositionTx(
            position,
            positionId,
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature
        );

        validateIncrease(state, transaction, position);

        doBorrowAndSell(state, transaction, orderData);

        updateState(
            position,
            transaction.positionId,
            transaction.principal,
            transaction.lenderAmount,
            transaction.loanOffering.payer
        );

        // LOG EVENT
        recordPositionIncreased(transaction, position);

        return transaction.lenderAmount;
    }

    function increaseWithoutCounterpartyImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 principalToAdd
    )
        public
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        // Disallow adding 0 principal
        require(
            principalToAdd > 0,
            "IncreasePositionImpl#increaseWithoutCounterpartyImpl: Cannot add 0 principal"
        );

        // Disallow additions after maximum duration
        require(
            block.timestamp < uint256(position.startTimestamp).add(position.maxDuration),
            "IncreasePositionImpl#increaseWithoutCounterpartyImpl: Cannot increase after maxDuration"
        );

        uint256 heldTokenAmount = getCollateralNeededForAddedPrincipal(
            state,
            position,
            positionId,
            principalToAdd
        );

        Vault(state.VAULT).transferToVault(
            positionId,
            position.heldToken,
            msg.sender,
            heldTokenAmount
        );

        updateState(
            position,
            positionId,
            principalToAdd,
            0, // lent amount
            msg.sender
        );

        emit PositionIncreased(
            positionId,
            msg.sender,
            msg.sender,
            position.owner,
            position.lender,
            "",
            address(0),
            0,
            principalToAdd,
            0,
            heldTokenAmount,
            true
        );

        return heldTokenAmount;
    }

    // ============ Private Helper-Functions ============

    function doBorrowAndSell(
        MarginState.State storage state,
        BorrowShared.Tx memory transaction,
        bytes orderData
    )
        private
    {
        // Calculate the number of heldTokens to add
        uint256 collateralToAdd = getCollateralNeededForAddedPrincipal(
            state,
            state.positions[transaction.positionId],
            transaction.positionId,
            transaction.principal
        );

        // Do pre-exchange validations
        BorrowShared.validateTxPreSell(state, transaction);

        // Calculate and deposit owedToken
        uint256 maxHeldTokenFromSell = MathHelpers.maxUint256();
        if (!transaction.depositInHeldToken) {
            transaction.depositAmount =
                getOwedTokenDeposit(transaction, collateralToAdd, orderData);
            BorrowShared.doDepositOwedToken(state, transaction);
            maxHeldTokenFromSell = collateralToAdd;
        }

        // Sell owedToken for heldToken using the exchange wrapper
        transaction.heldTokenFromSell = BorrowShared.doSell(
            state,
            transaction,
            orderData,
            maxHeldTokenFromSell
        );

        // Calculate and deposit heldToken
        if (transaction.depositInHeldToken) {
            require(
                transaction.heldTokenFromSell <= collateralToAdd,
                "IncreasePositionImpl#doBorrowAndSell: DEX order gives too much heldToken"
            );
            transaction.depositAmount = collateralToAdd.sub(transaction.heldTokenFromSell);
            BorrowShared.doDepositHeldToken(state, transaction);
        }

        // Make sure the actual added collateral is what is expected
        assert(transaction.collateralAmount == collateralToAdd);

        // Do post-exchange validations
        BorrowShared.doPostSell(state, transaction);
    }

    function getOwedTokenDeposit(
        BorrowShared.Tx transaction,
        uint256 collateralToAdd,
        bytes orderData
    )
        private
        view
        returns (uint256)
    {
        uint256 totalOwedToken = ExchangeWrapper(transaction.exchangeWrapper).getExchangeCost(
            transaction.loanOffering.heldToken,
            transaction.loanOffering.owedToken,
            collateralToAdd,
            orderData
        );

        require(
            transaction.lenderAmount <= totalOwedToken,
            "IncreasePositionImpl#getOwedTokenDeposit: Lender amount is more than required"
        );

        return totalOwedToken.sub(transaction.lenderAmount);
    }

    function validateIncrease(
        MarginState.State storage state,
        BorrowShared.Tx transaction,
        MarginCommon.Position storage position
    )
        private
        view
    {
        assert(MarginCommon.containsPositionImpl(state, transaction.positionId));

        require(
            position.callTimeLimit <= transaction.loanOffering.callTimeLimit,
            "IncreasePositionImpl#validateIncrease: Loan callTimeLimit is less than the position"
        );

        // require the position to end no later than the loanOffering&#39;s maximum acceptable end time
        uint256 positionEndTimestamp = uint256(position.startTimestamp).add(position.maxDuration);
        uint256 offeringEndTimestamp = block.timestamp.add(transaction.loanOffering.maxDuration);
        require(
            positionEndTimestamp <= offeringEndTimestamp,
            "IncreasePositionImpl#validateIncrease: Loan end timestamp is less than the position"
        );

        require(
            block.timestamp < positionEndTimestamp,
            "IncreasePositionImpl#validateIncrease: Position has passed its maximum duration"
        );
    }

    function getCollateralNeededForAddedPrincipal(
        MarginState.State storage state,
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 principalToAdd
    )
        private
        view
        returns (uint256)
    {
        uint256 heldTokenBalance = MarginCommon.getPositionBalanceImpl(state, positionId);

        return MathHelpers.getPartialAmountRoundedUp(
            principalToAdd,
            position.principal,
            heldTokenBalance
        );
    }

    function updateState(
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 principalAdded,
        uint256 owedTokenLent,
        address loanPayer
    )
        private
    {
        position.principal = position.principal.add(principalAdded);

        address owner = position.owner;
        address lender = position.lender;

        // Ensure owner consent
        increasePositionOnBehalfOfRecurse(
            owner,
            msg.sender,
            positionId,
            principalAdded
        );

        // Ensure lender consent
        increaseLoanOnBehalfOfRecurse(
            lender,
            loanPayer,
            positionId,
            principalAdded,
            owedTokenLent
        );
    }

    function increasePositionOnBehalfOfRecurse(
        address contractAddr,
        address trader,
        bytes32 positionId,
        uint256 principalAdded
    )
        private
    {
        // Assume owner approval if not a smart contract and they increased their own position
        if (trader == contractAddr && !AddressUtils.isContract(contractAddr)) {
            return;
        }

        address newContractAddr =
            IncreasePositionDelegator(contractAddr).increasePositionOnBehalfOf(
                trader,
                positionId,
                principalAdded
            );

        if (newContractAddr != contractAddr) {
            increasePositionOnBehalfOfRecurse(
                newContractAddr,
                trader,
                positionId,
                principalAdded
            );
        }
    }

    function increaseLoanOnBehalfOfRecurse(
        address contractAddr,
        address payer,
        bytes32 positionId,
        uint256 principalAdded,
        uint256 amountLent
    )
        private
    {
        // Assume lender approval if not a smart contract and they increased their own loan
        if (payer == contractAddr && !AddressUtils.isContract(contractAddr)) {
            return;
        }

        address newContractAddr =
            IncreaseLoanDelegator(contractAddr).increaseLoanOnBehalfOf(
                payer,
                positionId,
                principalAdded,
                amountLent
            );

        if (newContractAddr != contractAddr) {
            increaseLoanOnBehalfOfRecurse(
                newContractAddr,
                payer,
                positionId,
                principalAdded,
                amountLent
            );
        }
    }

    function recordPositionIncreased(
        BorrowShared.Tx transaction,
        MarginCommon.Position storage position
    )
        private
    {
        emit PositionIncreased(
            transaction.positionId,
            msg.sender,
            transaction.loanOffering.payer,
            position.owner,
            position.lender,
            transaction.loanOffering.loanHash,
            transaction.loanOffering.feeRecipient,
            transaction.lenderAmount,
            transaction.principal,
            transaction.heldTokenFromSell,
            transaction.depositAmount,
            transaction.depositInHeldToken
        );
    }

    // ============ Parsing Functions ============

    function parseIncreasePositionTx(
        MarginCommon.Position storage position,
        bytes32 positionId,
        address[7] addresses,
        uint256[8] values256,
        uint32[2] values32,
        bool depositInHeldToken,
        bytes signature
    )
        private
        view
        returns (BorrowShared.Tx memory)
    {
        uint256 principal = values256[7];

        uint256 lenderAmount = MarginCommon.calculateLenderAmountForIncreasePosition(
            position,
            principal,
            block.timestamp
        );
        assert(lenderAmount >= principal);

        BorrowShared.Tx memory transaction = BorrowShared.Tx({
            positionId: positionId,
            owner: position.owner,
            principal: principal,
            lenderAmount: lenderAmount,
            loanOffering: parseLoanOfferingFromIncreasePositionTx(
                position,
                addresses,
                values256,
                values32,
                signature
            ),
            exchangeWrapper: addresses[6],
            depositInHeldToken: depositInHeldToken,
            depositAmount: 0, // set later
            collateralAmount: 0, // set later
            heldTokenFromSell: 0 // set later
        });

        return transaction;
    }

    function parseLoanOfferingFromIncreasePositionTx(
        MarginCommon.Position storage position,
        address[7] addresses,
        uint256[8] values256,
        uint32[2] values32,
        bytes signature
    )
        private
        view
        returns (MarginCommon.LoanOffering memory)
    {
        MarginCommon.LoanOffering memory loanOffering = MarginCommon.LoanOffering({
            owedToken: position.owedToken,
            heldToken: position.heldToken,
            payer: addresses[0],
            owner: position.lender,
            taker: addresses[1],
            positionOwner: addresses[2],
            feeRecipient: addresses[3],
            lenderFeeToken: addresses[4],
            takerFeeToken: addresses[5],
            rates: parseLoanOfferingRatesFromIncreasePositionTx(position, values256),
            expirationTimestamp: values256[5],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            salt: values256[6],
            loanHash: 0,
            signature: signature
        });

        loanOffering.loanHash = MarginCommon.getLoanOfferingHash(loanOffering);

        return loanOffering;
    }

    function parseLoanOfferingRatesFromIncreasePositionTx(
        MarginCommon.Position storage position,
        uint256[8] values256
    )
        private
        view
        returns (MarginCommon.LoanRates memory)
    {
        MarginCommon.LoanRates memory rates = MarginCommon.LoanRates({
            maxAmount: values256[0],
            minAmount: values256[1],
            minHeldToken: values256[2],
            lenderFee: values256[3],
            takerFee: values256[4],
            interestRate: position.interestRate,
            interestPeriod: position.interestPeriod
        });

        return rates;
    }
}

// File: contracts/margin/impl/MarginStorage.sol

/**
 * @title MarginStorage
 * @author dYdX
 *
 * This contract serves as the storage for the entire state of MarginStorage
 */
contract MarginStorage {

    MarginState.State state;

}

// File: contracts/margin/impl/LoanGetters.sol

/**
 * @title LoanGetters
 * @author dYdX
 *
 * A collection of public constant getter functions that allows reading of the state of any loan
 * offering stored in the dYdX protocol.
 */
contract LoanGetters is MarginStorage {

    // ============ Public Constant Functions ============

    /**
     * Gets the principal amount of a loan offering that is no longer available.
     *
     * @param  loanHash  Unique hash of the loan offering
     * @return           The total unavailable amount of the loan offering, which is equal to the
     *                   filled amount plus the canceled amount.
     */
    function getLoanUnavailableAmount(
        bytes32 loanHash
    )
        external
        view
        returns (uint256)
    {
        return MarginCommon.getUnavailableLoanOfferingAmountImpl(state, loanHash);
    }

    /**
     * Gets the total amount of owed token lent for a loan.
     *
     * @param  loanHash  Unique hash of the loan offering
     * @return           The total filled amount of the loan offering.
     */
    function getLoanFilledAmount(
        bytes32 loanHash
    )
        external
        view
        returns (uint256)
    {
        return state.loanFills[loanHash];
    }

    /**
     * Gets the amount of a loan offering that has been canceled.
     *
     * @param  loanHash  Unique hash of the loan offering
     * @return           The total canceled amount of the loan offering.
     */
    function getLoanCanceledAmount(
        bytes32 loanHash
    )
        external
        view
        returns (uint256)
    {
        return state.loanCancels[loanHash];
    }
}

// File: contracts/margin/interfaces/lender/CancelMarginCallDelegator.sol

/**
 * @title CancelMarginCallDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to let other addresses cancel a
 * margin-call for a loan owned by the smart contract.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface CancelMarginCallDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to let other addresses call cancelMarginCall().
     *
     * NOTE: If not returning zero (or not reverting), this contract must assume that Margin will
     * either revert the entire transaction or that the margin-call was successfully canceled.
     *
     * @param  canceler    Address of the caller of the cancelMarginCall function
     * @param  positionId  Unique ID of the position
     * @return             This address to accept, a different address to ask that contract
     */
    function cancelMarginCallOnBehalfOf(
        address canceler,
        bytes32 positionId
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/interfaces/lender/MarginCallDelegator.sol

/**
 * @title MarginCallDelegator
 * @author dYdX
 *
 * Interface that smart contracts must implement in order to let other addresses margin-call a loan
 * owned by the smart contract.
 *
 * NOTE: Any contract implementing this interface should also use OnlyMargin to control access
 *       to these functions
 */
interface MarginCallDelegator {

    // ============ Public Interface functions ============

    /**
     * Function a contract must implement in order to let other addresses call marginCall().
     *
     * NOTE: If not returning zero (or not reverting), this contract must assume that Margin will
     * either revert the entire transaction or that the loan was successfully margin-called.
     *
     * @param  caller         Address of the caller of the marginCall function
     * @param  positionId     Unique ID of the position
     * @param  depositAmount  Amount of heldToken deposit that will be required to cancel the call
     * @return                This address to accept, a different address to ask that contract
     */
    function marginCallOnBehalfOf(
        address caller,
        bytes32 positionId,
        uint256 depositAmount
    )
        external
        /* onlyMargin */
        returns (address);
}

// File: contracts/margin/impl/LoanImpl.sol

/**
 * @title LoanImpl
 * @author dYdX
 *
 * This library contains the implementation for the following functions of Margin:
 *
 *      - marginCall
 *      - cancelMarginCallImpl
 *      - cancelLoanOffering
 */
library LoanImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /**
     * A position was margin-called
     */
    event MarginCallInitiated(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 requiredDeposit
    );

    /**
     * A margin call was canceled
     */
    event MarginCallCanceled(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 depositAmount
    );

    /**
     * A loan offering was canceled before it was used. Any amount less than the
     * total for the loan offering can be canceled.
     */
    event LoanOfferingCanceled(
        bytes32 indexed loanHash,
        address indexed payer,
        address indexed feeRecipient,
        uint256 cancelAmount
    );

    // ============ Public Implementation Functions ============

    function marginCallImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requiredDeposit
    )
        public
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            position.callTimestamp == 0,
            "LoanImpl#marginCallImpl: The position has already been margin-called"
        );

        // Ensure lender consent
        marginCallOnBehalfOfRecurse(
            position.lender,
            msg.sender,
            positionId,
            requiredDeposit
        );

        position.callTimestamp = TimestampHelper.getBlockTimestamp32();
        position.requiredDeposit = requiredDeposit;

        emit MarginCallInitiated(
            positionId,
            position.lender,
            position.owner,
            requiredDeposit
        );
    }

    function cancelMarginCallImpl(
        MarginState.State storage state,
        bytes32 positionId
    )
        public
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            position.callTimestamp > 0,
            "LoanImpl#cancelMarginCallImpl: Position has not been margin-called"
        );

        // Ensure lender consent
        cancelMarginCallOnBehalfOfRecurse(
            position.lender,
            msg.sender,
            positionId
        );

        state.positions[positionId].callTimestamp = 0;
        state.positions[positionId].requiredDeposit = 0;

        emit MarginCallCanceled(
            positionId,
            position.lender,
            position.owner,
            0
        );
    }

    function cancelLoanOfferingImpl(
        MarginState.State storage state,
        address[9] addresses,
        uint256[7] values256,
        uint32[4]  values32,
        uint256    cancelAmount
    )
        public
        returns (uint256)
    {
        MarginCommon.LoanOffering memory loanOffering = parseLoanOffering(
            addresses,
            values256,
            values32
        );

        require(
            msg.sender == loanOffering.payer,
            "LoanImpl#cancelLoanOfferingImpl: Only loan offering payer can cancel"
        );
        require(
            loanOffering.expirationTimestamp > block.timestamp,
            "LoanImpl#cancelLoanOfferingImpl: Loan offering has already expired"
        );

        uint256 remainingAmount = loanOffering.rates.maxAmount.sub(
            MarginCommon.getUnavailableLoanOfferingAmountImpl(state, loanOffering.loanHash)
        );
        uint256 amountToCancel = Math.min256(remainingAmount, cancelAmount);

        // If the loan was already fully canceled, then just return 0 amount was canceled
        if (amountToCancel == 0) {
            return 0;
        }

        state.loanCancels[loanOffering.loanHash] =
            state.loanCancels[loanOffering.loanHash].add(amountToCancel);

        emit LoanOfferingCanceled(
            loanOffering.loanHash,
            loanOffering.payer,
            loanOffering.feeRecipient,
            amountToCancel
        );

        return amountToCancel;
    }

    // ============ Private Helper-Functions ============

    function marginCallOnBehalfOfRecurse(
        address contractAddr,
        address who,
        bytes32 positionId,
        uint256 requiredDeposit
    )
        private
    {
        // no need to ask for permission
        if (who == contractAddr) {
            return;
        }

        address newContractAddr =
            MarginCallDelegator(contractAddr).marginCallOnBehalfOf(
                msg.sender,
                positionId,
                requiredDeposit
            );

        if (newContractAddr != contractAddr) {
            marginCallOnBehalfOfRecurse(
                newContractAddr,
                who,
                positionId,
                requiredDeposit
            );
        }
    }

    function cancelMarginCallOnBehalfOfRecurse(
        address contractAddr,
        address who,
        bytes32 positionId
    )
        private
    {
        // no need to ask for permission
        if (who == contractAddr) {
            return;
        }

        address newContractAddr =
            CancelMarginCallDelegator(contractAddr).cancelMarginCallOnBehalfOf(
                msg.sender,
                positionId
            );

        if (newContractAddr != contractAddr) {
            cancelMarginCallOnBehalfOfRecurse(
                newContractAddr,
                who,
                positionId
            );
        }
    }

    // ============ Parsing Functions ============

    function parseLoanOffering(
        address[9] addresses,
        uint256[7] values256,
        uint32[4]  values32
    )
        private
        view
        returns (MarginCommon.LoanOffering memory)
    {
        MarginCommon.LoanOffering memory loanOffering = MarginCommon.LoanOffering({
            owedToken: addresses[0],
            heldToken: addresses[1],
            payer: addresses[2],
            owner: addresses[3],
            taker: addresses[4],
            positionOwner: addresses[5],
            feeRecipient: addresses[6],
            lenderFeeToken: addresses[7],
            takerFeeToken: addresses[8],
            rates: parseLoanOfferRates(values256, values32),
            expirationTimestamp: values256[5],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            salt: values256[6],
            loanHash: 0,
            signature: new bytes(0)
        });

        loanOffering.loanHash = MarginCommon.getLoanOfferingHash(loanOffering);

        return loanOffering;
    }

    function parseLoanOfferRates(
        uint256[7] values256,
        uint32[4] values32
    )
        private
        pure
        returns (MarginCommon.LoanRates memory)
    {
        MarginCommon.LoanRates memory rates = MarginCommon.LoanRates({
            maxAmount: values256[0],
            minAmount: values256[1],
            minHeldToken: values256[2],
            interestRate: values32[2],
            lenderFee: values256[3],
            takerFee: values256[4],
            interestPeriod: values32[3]
        });

        return rates;
    }
}

// File: contracts/margin/impl/MarginAdmin.sol

/**
 * @title MarginAdmin
 * @author dYdX
 *
 * Contains admin functions for the Margin contract
 * The owner can put Margin into various close-only modes, which will disallow new position creation
 */
contract MarginAdmin is Ownable {
    // ============ Enums ============

    // All functionality enabled
    uint8 private constant OPERATION_STATE_OPERATIONAL = 0;

    // Only closing functions + cancelLoanOffering allowed (marginCall, closePosition,
    // cancelLoanOffering, closePositionDirectly, forceRecoverCollateral)
    uint8 private constant OPERATION_STATE_CLOSE_AND_CANCEL_LOAN_ONLY = 1;

    // Only closing functions allowed (marginCall, closePosition, closePositionDirectly,
    // forceRecoverCollateral)
    uint8 private constant OPERATION_STATE_CLOSE_ONLY = 2;

    // Only closing functions allowed (marginCall, closePositionDirectly, forceRecoverCollateral)
    uint8 private constant OPERATION_STATE_CLOSE_DIRECTLY_ONLY = 3;

    // This operation state (and any higher) is invalid
    uint8 private constant OPERATION_STATE_INVALID = 4;

    // ============ Events ============

    /**
     * Event indicating the operation state has changed
     */
    event OperationStateChanged(
        uint8 from,
        uint8 to
    );

    // ============ State Variables ============

    uint8 public operationState;

    // ============ Constructor ============

    constructor()
        public
        Ownable()
    {
        operationState = OPERATION_STATE_OPERATIONAL;
    }

    // ============ Modifiers ============

    modifier onlyWhileOperational() {
        require(
            operationState == OPERATION_STATE_OPERATIONAL,
            "MarginAdmin#onlyWhileOperational: Can only call while operational"
        );
        _;
    }

    modifier cancelLoanOfferingStateControl() {
        require(
            operationState == OPERATION_STATE_OPERATIONAL
            || operationState == OPERATION_STATE_CLOSE_AND_CANCEL_LOAN_ONLY,
            "MarginAdmin#cancelLoanOfferingStateControl: Invalid operation state"
        );
        _;
    }

    modifier closePositionStateControl() {
        require(
            operationState == OPERATION_STATE_OPERATIONAL
            || operationState == OPERATION_STATE_CLOSE_AND_CANCEL_LOAN_ONLY
            || operationState == OPERATION_STATE_CLOSE_ONLY,
            "MarginAdmin#closePositionStateControl: Invalid operation state"
        );
        _;
    }

    modifier closePositionDirectlyStateControl() {
        _;
    }

    // ============ Owner-Only State-Changing Functions ============

    function setOperationState(
        uint8 newState
    )
        external
        onlyOwner
    {
        require(
            newState < OPERATION_STATE_INVALID,
            "MarginAdmin#setOperationState: newState is not a valid operation state"
        );

        if (newState != operationState) {
            emit OperationStateChanged(
                operationState,
                newState
            );
            operationState = newState;
        }
    }
}

// File: contracts/margin/impl/MarginEvents.sol

/**
 * @title MarginEvents
 * @author dYdX
 *
 * Contains events for the Margin contract.
 *
 * NOTE: Any Margin function libraries that use events will need to both define the event here
 *       and copy the event into the library itself as libraries don&#39;t support sharing events
 */
contract MarginEvents {
    // ============ Events ============

    /**
     * A position was opened
     */
    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        bytes32 loanHash,
        address owedToken,
        address heldToken,
        address loanFeeRecipient,
        uint256 principal,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        uint256 interestRate,
        uint32  callTimeLimit,
        uint32  maxDuration,
        bool    depositInHeldToken
    );

    /*
     * A position was increased
     */
    event PositionIncreased(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        address positionOwner,
        address loanOwner,
        bytes32 loanHash,
        address loanFeeRecipient,
        uint256 amountBorrowed,
        uint256 principalAdded,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        bool    depositInHeldToken
    );

    /**
     * A position was closed or partially closed
     */
    event PositionClosed(
        bytes32 indexed positionId,
        address indexed closer,
        address indexed payoutRecipient,
        uint256 closeAmount,
        uint256 remainingAmount,
        uint256 owedTokenPaidToLender,
        uint256 payoutAmount,
        uint256 buybackCostInHeldToken,
        bool payoutInHeldToken
    );

    /**
     * Collateral for a position was forcibly recovered
     */
    event CollateralForceRecovered(
        bytes32 indexed positionId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * A position was margin-called
     */
    event MarginCallInitiated(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 requiredDeposit
    );

    /**
     * A margin call was canceled
     */
    event MarginCallCanceled(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 depositAmount
    );

    /**
     * A loan offering was canceled before it was used. Any amount less than the
     * total for the loan offering can be canceled.
     */
    event LoanOfferingCanceled(
        bytes32 indexed loanHash,
        address indexed payer,
        address indexed feeRecipient,
        uint256 cancelAmount
    );

    /**
     * Additional collateral for a position was posted by the owner
     */
    event AdditionalCollateralDeposited(
        bytes32 indexed positionId,
        uint256 amount,
        address depositor
    );

    /**
     * Ownership of a loan was transferred to a new address
     */
    event LoanTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );

    /**
     * Ownership of a position was transferred to a new address
     */
    event PositionTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );
}

// File: contracts/margin/impl/OpenPositionImpl.sol

/**
 * @title OpenPositionImpl
 * @author dYdX
 *
 * This library contains the implementation for the openPosition function of Margin
 */
library OpenPositionImpl {
    using SafeMath for uint256;

    // ============ Events ============

    /**
     * A position was opened
     */
    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        bytes32 loanHash,
        address owedToken,
        address heldToken,
        address loanFeeRecipient,
        uint256 principal,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        uint256 interestRate,
        uint32  callTimeLimit,
        uint32  maxDuration,
        bool    depositInHeldToken
    );

    // ============ Public Implementation Functions ============

    function openPositionImpl(
        MarginState.State storage state,
        address[11] addresses,
        uint256[10] values256,
        uint32[4] values32,
        bool depositInHeldToken,
        bytes signature,
        bytes orderData
    )
        public
        returns (bytes32)
    {
        BorrowShared.Tx memory transaction = parseOpenTx(
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature
        );

        require(
            !MarginCommon.positionHasExisted(state, transaction.positionId),
            "OpenPositionImpl#openPositionImpl: positionId already exists"
        );

        doBorrowAndSell(state, transaction, orderData);

        // Before doStoreNewPosition() so that PositionOpened event is before Transferred events
        recordPositionOpened(
            transaction
        );

        doStoreNewPosition(
            state,
            transaction
        );

        return transaction.positionId;
    }

    // ============ Private Helper-Functions ============

    function doBorrowAndSell(
        MarginState.State storage state,
        BorrowShared.Tx memory transaction,
        bytes orderData
    )
        private
    {
        BorrowShared.validateTxPreSell(state, transaction);

        if (transaction.depositInHeldToken) {
            BorrowShared.doDepositHeldToken(state, transaction);
        } else {
            BorrowShared.doDepositOwedToken(state, transaction);
        }

        transaction.heldTokenFromSell = BorrowShared.doSell(
            state,
            transaction,
            orderData,
            MathHelpers.maxUint256()
        );

        BorrowShared.doPostSell(state, transaction);
    }

    function doStoreNewPosition(
        MarginState.State storage state,
        BorrowShared.Tx memory transaction
    )
        private
    {
        MarginCommon.storeNewPosition(
            state,
            transaction.positionId,
            MarginCommon.Position({
                owedToken: transaction.loanOffering.owedToken,
                heldToken: transaction.loanOffering.heldToken,
                lender: transaction.loanOffering.owner,
                owner: transaction.owner,
                principal: transaction.principal,
                requiredDeposit: 0,
                callTimeLimit: transaction.loanOffering.callTimeLimit,
                startTimestamp: 0,
                callTimestamp: 0,
                maxDuration: transaction.loanOffering.maxDuration,
                interestRate: transaction.loanOffering.rates.interestRate,
                interestPeriod: transaction.loanOffering.rates.interestPeriod
            }),
            transaction.loanOffering.payer
        );
    }

    function recordPositionOpened(
        BorrowShared.Tx transaction
    )
        private
    {
        emit PositionOpened(
            transaction.positionId,
            msg.sender,
            transaction.loanOffering.payer,
            transaction.loanOffering.loanHash,
            transaction.loanOffering.owedToken,
            transaction.loanOffering.heldToken,
            transaction.loanOffering.feeRecipient,
            transaction.principal,
            transaction.heldTokenFromSell,
            transaction.depositAmount,
            transaction.loanOffering.rates.interestRate,
            transaction.loanOffering.callTimeLimit,
            transaction.loanOffering.maxDuration,
            transaction.depositInHeldToken
        );
    }

    // ============ Parsing Functions ============

    function parseOpenTx(
        address[11] addresses,
        uint256[10] values256,
        uint32[4] values32,
        bool depositInHeldToken,
        bytes signature
    )
        private
        view
        returns (BorrowShared.Tx memory)
    {
        BorrowShared.Tx memory transaction = BorrowShared.Tx({
            positionId: MarginCommon.getPositionIdFromNonce(values256[9]),
            owner: addresses[0],
            principal: values256[7],
            lenderAmount: values256[7],
            loanOffering: parseLoanOffering(
                addresses,
                values256,
                values32,
                signature
            ),
            exchangeWrapper: addresses[10],
            depositInHeldToken: depositInHeldToken,
            depositAmount: values256[8],
            collateralAmount: 0, // set later
            heldTokenFromSell: 0 // set later
        });

        return transaction;
    }

    function parseLoanOffering(
        address[11] addresses,
        uint256[10] values256,
        uint32[4]   values32,
        bytes       signature
    )
        private
        view
        returns (MarginCommon.LoanOffering memory)
    {
        MarginCommon.LoanOffering memory loanOffering = MarginCommon.LoanOffering({
            owedToken: addresses[1],
            heldToken: addresses[2],
            payer: addresses[3],
            owner: addresses[4],
            taker: addresses[5],
            positionOwner: addresses[6],
            feeRecipient: addresses[7],
            lenderFeeToken: addresses[8],
            takerFeeToken: addresses[9],
            rates: parseLoanOfferRates(values256, values32),
            expirationTimestamp: values256[5],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            salt: values256[6],
            loanHash: 0,
            signature: signature
        });

        loanOffering.loanHash = MarginCommon.getLoanOfferingHash(loanOffering);

        return loanOffering;
    }

    function parseLoanOfferRates(
        uint256[10] values256,
        uint32[4] values32
    )
        private
        pure
        returns (MarginCommon.LoanRates memory)
    {
        MarginCommon.LoanRates memory rates = MarginCommon.LoanRates({
            maxAmount: values256[0],
            minAmount: values256[1],
            minHeldToken: values256[2],
            lenderFee: values256[3],
            takerFee: values256[4],
            interestRate: values32[2],
            interestPeriod: values32[3]
        });

        return rates;
    }
}

// File: contracts/margin/impl/OpenWithoutCounterpartyImpl.sol

/**
 * @title OpenWithoutCounterpartyImpl
 * @author dYdX
 *
 * This library contains the implementation for the openWithoutCounterparty
 * function of Margin
 */
library OpenWithoutCounterpartyImpl {

    // ============ Structs ============

    struct Tx {
        bytes32 positionId;
        address positionOwner;
        address owedToken;
        address heldToken;
        address loanOwner;
        uint256 principal;
        uint256 deposit;
        uint32 callTimeLimit;
        uint32 maxDuration;
        uint32 interestRate;
        uint32 interestPeriod;
    }

    // ============ Events ============

    /**
     * A position was opened
     */
    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        bytes32 loanHash,
        address owedToken,
        address heldToken,
        address loanFeeRecipient,
        uint256 principal,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        uint256 interestRate,
        uint32  callTimeLimit,
        uint32  maxDuration,
        bool    depositInHeldToken
    );

    // ============ Public Implementation Functions ============

    function openWithoutCounterpartyImpl(
        MarginState.State storage state,
        address[4] addresses,
        uint256[3] values256,
        uint32[4]  values32
    )
        public
        returns (bytes32)
    {
        Tx memory openTx = parseTx(
            addresses,
            values256,
            values32
        );

        validate(
            state,
            openTx
        );

        Vault(state.VAULT).transferToVault(
            openTx.positionId,
            openTx.heldToken,
            msg.sender,
            openTx.deposit
        );

        recordPositionOpened(
            openTx
        );

        doStoreNewPosition(
            state,
            openTx
        );

        return openTx.positionId;
    }

    // ============ Private Helper-Functions ============

    function doStoreNewPosition(
        MarginState.State storage state,
        Tx memory openTx
    )
        private
    {
        MarginCommon.storeNewPosition(
            state,
            openTx.positionId,
            MarginCommon.Position({
                owedToken: openTx.owedToken,
                heldToken: openTx.heldToken,
                lender: openTx.loanOwner,
                owner: openTx.positionOwner,
                principal: openTx.principal,
                requiredDeposit: 0,
                callTimeLimit: openTx.callTimeLimit,
                startTimestamp: 0,
                callTimestamp: 0,
                maxDuration: openTx.maxDuration,
                interestRate: openTx.interestRate,
                interestPeriod: openTx.interestPeriod
            }),
            msg.sender
        );
    }

    function validate(
        MarginState.State storage state,
        Tx memory openTx
    )
        private
        view
    {
        require(
            !MarginCommon.positionHasExisted(state, openTx.positionId),
            "openWithoutCounterpartyImpl#validate: positionId already exists"
        );

        require(
            openTx.principal > 0,
            "openWithoutCounterpartyImpl#validate: principal cannot be 0"
        );

        require(
            openTx.owedToken != address(0),
            "openWithoutCounterpartyImpl#validate: owedToken cannot be 0"
        );

        require(
            openTx.owedToken != openTx.heldToken,
            "openWithoutCounterpartyImpl#validate: owedToken cannot be equal to heldToken"
        );

        require(
            openTx.positionOwner != address(0),
            "openWithoutCounterpartyImpl#validate: positionOwner cannot be 0"
        );

        require(
            openTx.loanOwner != address(0),
            "openWithoutCounterpartyImpl#validate: loanOwner cannot be 0"
        );

        require(
            openTx.maxDuration > 0,
            "openWithoutCounterpartyImpl#validate: maxDuration cannot be 0"
        );

        require(
            openTx.interestPeriod <= openTx.maxDuration,
            "openWithoutCounterpartyImpl#validate: interestPeriod must be <= maxDuration"
        );
    }

    function recordPositionOpened(
        Tx memory openTx
    )
        private
    {
        emit PositionOpened(
            openTx.positionId,
            msg.sender,
            msg.sender,
            bytes32(0),
            openTx.owedToken,
            openTx.heldToken,
            address(0),
            openTx.principal,
            0,
            openTx.deposit,
            openTx.interestRate,
            openTx.callTimeLimit,
            openTx.maxDuration,
            true
        );
    }

    // ============ Parsing Functions ============

    function parseTx(
        address[4] addresses,
        uint256[3] values256,
        uint32[4]  values32
    )
        private
        view
        returns (Tx memory)
    {
        Tx memory openTx = Tx({
            positionId: MarginCommon.getPositionIdFromNonce(values256[2]),
            positionOwner: addresses[0],
            owedToken: addresses[1],
            heldToken: addresses[2],
            loanOwner: addresses[3],
            principal: values256[0],
            deposit: values256[1],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            interestRate: values32[2],
            interestPeriod: values32[3]
        });

        return openTx;
    }
}

// File: contracts/margin/impl/PositionGetters.sol

/**
 * @title PositionGetters
 * @author dYdX
 *
 * A collection of public constant getter functions that allows reading of the state of any position
 * stored in the dYdX protocol.
 */
contract PositionGetters is MarginStorage {
    using SafeMath for uint256;

    // ============ Public Constant Functions ============

    /**
     * Gets if a position is currently open.
     *
     * @param  positionId  Unique ID of the position
     * @return             True if the position is exists and is open
     */
    function containsPosition(
        bytes32 positionId
    )
        external
        view
        returns (bool)
    {
        return MarginCommon.containsPositionImpl(state, positionId);
    }

    /**
     * Gets if a position is currently margin-called.
     *
     * @param  positionId  Unique ID of the position
     * @return             True if the position is margin-called
     */
    function isPositionCalled(
        bytes32 positionId
    )
        external
        view
        returns (bool)
    {
        return (state.positions[positionId].callTimestamp > 0);
    }

    /**
     * Gets if a position was previously open and is now closed.
     *
     * @param  positionId  Unique ID of the position
     * @return             True if the position is now closed
     */
    function isPositionClosed(
        bytes32 positionId
    )
        external
        view
        returns (bool)
    {
        return state.closedPositions[positionId];
    }

    /**
     * Gets the total amount of owedToken ever repaid to the lender for a position.
     *
     * @param  positionId  Unique ID of the position
     * @return             Total amount of owedToken ever repaid
     */
    function getTotalOwedTokenRepaidToLender(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.totalOwedTokenRepaidToLender[positionId];
    }

    /**
     * Gets the amount of heldToken currently locked up in Vault for a particular position.
     *
     * @param  positionId  Unique ID of the position
     * @return             The amount of heldToken
     */
    function getPositionBalance(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return MarginCommon.getPositionBalanceImpl(state, positionId);
    }

    /**
     * Gets the time until the interest fee charged for the position will increase.
     * Returns 1 if the interest fee increases every second.
     * Returns 0 if the interest fee will never increase again.
     *
     * @param  positionId  Unique ID of the position
     * @return             The number of seconds until the interest fee will increase
     */
    function getTimeUntilInterestIncrease(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        uint256 effectiveTimeElapsed = MarginCommon.calculateEffectiveTimeElapsed(
            position,
            block.timestamp
        );

        uint256 absoluteTimeElapsed = block.timestamp.sub(position.startTimestamp);
        if (absoluteTimeElapsed > effectiveTimeElapsed) { // past maxDuration
            return 0;
        } else {
            // nextStep is the final second at which the calculated interest fee is the same as it
            // is currently, so add 1 to get the correct value
            return effectiveTimeElapsed.add(1).sub(absoluteTimeElapsed);
        }
    }

    /**
     * Gets the amount of owedTokens currently needed to close the position completely, including
     * interest fees.
     *
     * @param  positionId  Unique ID of the position
     * @return             The number of owedTokens
     */
    function getPositionOwedAmount(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        return MarginCommon.calculateOwedAmount(
            position,
            position.principal,
            block.timestamp
        );
    }

    /**
     * Gets the amount of owedTokens needed to close a given principal amount of the position at a
     * given time, including interest fees.
     *
     * @param  positionId         Unique ID of the position
     * @param  principalToClose   Amount of principal being closed
     * @param  timestamp          Block timestamp in seconds of close
     * @return                    The number of owedTokens owed
     */
    function getPositionOwedAmountAtTime(
        bytes32 positionId,
        uint256 principalToClose,
        uint32  timestamp
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            timestamp >= position.startTimestamp,
            "PositionGetters#getPositionOwedAmountAtTime: Requested time before position started"
        );

        return MarginCommon.calculateOwedAmount(
            position,
            principalToClose,
            timestamp
        );
    }

    /**
     * Gets the amount of owedTokens that can be borrowed from a lender to add a given principal
     * amount to the position at a given time.
     *
     * @param  positionId      Unique ID of the position
     * @param  principalToAdd  Amount being added to principal
     * @param  timestamp       Block timestamp in seconds of addition
     * @return                 The number of owedTokens that will be borrowed
     */
    function getLenderAmountForIncreasePositionAtTime(
        bytes32 positionId,
        uint256 principalToAdd,
        uint32  timestamp
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            timestamp >= position.startTimestamp,
            "PositionGetters#getLenderAmountForIncreasePositionAtTime: timestamp < position start"
        );

        return MarginCommon.calculateLenderAmountForIncreasePosition(
            position,
            principalToAdd,
            timestamp
        );
    }

    // ============ All Properties ============

    /**
     * Get a Position by id. This does not validate the position exists. If the position does not
     * exist, all 0&#39;s will be returned.
     *
     * @param  positionId  Unique ID of the position
     * @return             Addresses corresponding to:
     *
     *                     [0] = owedToken
     *                     [1] = heldToken
     *                     [2] = lender
     *                     [3] = owner
     *
     *                     Values corresponding to:
     *
     *                     [0] = principal
     *                     [1] = requiredDeposit
     *
     *                     Values corresponding to:
     *
     *                     [0] = callTimeLimit
     *                     [1] = startTimestamp
     *                     [2] = callTimestamp
     *                     [3] = maxDuration
     *                     [4] = interestRate
     *                     [5] = interestPeriod
     */
    function getPosition(
        bytes32 positionId
    )
        external
        view
        returns (
            address[4],
            uint256[2],
            uint32[6]
        )
    {
        MarginCommon.Position storage position = state.positions[positionId];

        return (
            [
                position.owedToken,
                position.heldToken,
                position.lender,
                position.owner
            ],
            [
                position.principal,
                position.requiredDeposit
            ],
            [
                position.callTimeLimit,
                position.startTimestamp,
                position.callTimestamp,
                position.maxDuration,
                position.interestRate,
                position.interestPeriod
            ]
        );
    }

    // ============ Individual Properties ============

    function getPositionLender(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].lender;
    }

    function getPositionOwner(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].owner;
    }

    function getPositionHeldToken(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].heldToken;
    }

    function getPositionOwedToken(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].owedToken;
    }

    function getPositionPrincipal(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.positions[positionId].principal;
    }

    function getPositionInterestRate(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.positions[positionId].interestRate;
    }

    function getPositionRequiredDeposit(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.positions[positionId].requiredDeposit;
    }

    function getPositionStartTimestamp(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].startTimestamp;
    }

    function getPositionCallTimestamp(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].callTimestamp;
    }

    function getPositionCallTimeLimit(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].callTimeLimit;
    }

    function getPositionMaxDuration(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].maxDuration;
    }

    function getPositioninterestPeriod(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].interestPeriod;
    }
}

// File: contracts/margin/impl/TransferImpl.sol

/**
 * @title TransferImpl
 * @author dYdX
 *
 * This library contains the implementation for the transferPosition and transferLoan functions of
 * Margin
 */
library TransferImpl {

    // ============ Public Implementation Functions ============

    function transferLoanImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address newLender
    )
        public
    {
        require(
            MarginCommon.containsPositionImpl(state, positionId),
            "TransferImpl#transferLoanImpl: Position does not exist"
        );

        address originalLender = state.positions[positionId].lender;

        require(
            msg.sender == originalLender,
            "TransferImpl#transferLoanImpl: Only lender can transfer ownership"
        );
        require(
            newLender != originalLender,
            "TransferImpl#transferLoanImpl: Cannot transfer ownership to self"
        );

        // Doesn&#39;t change the state of positionId; figures out the final owner of loan.
        // That is, newLender may pass ownership to a different address.
        address finalLender = TransferInternal.grantLoanOwnership(
            positionId,
            originalLender,
            newLender);

        require(
            finalLender != originalLender,
            "TransferImpl#transferLoanImpl: Cannot ultimately transfer ownership to self"
        );

        // Set state only after resolving the new owner (to reduce the number of storage calls)
        state.positions[positionId].lender = finalLender;
    }

    function transferPositionImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address newOwner
    )
        public
    {
        require(
            MarginCommon.containsPositionImpl(state, positionId),
            "TransferImpl#transferPositionImpl: Position does not exist"
        );

        address originalOwner = state.positions[positionId].owner;

        require(
            msg.sender == originalOwner,
            "TransferImpl#transferPositionImpl: Only position owner can transfer ownership"
        );
        require(
            newOwner != originalOwner,
            "TransferImpl#transferPositionImpl: Cannot transfer ownership to self"
        );

        // Doesn&#39;t change the state of positionId; figures out the final owner of position.
        // That is, newOwner may pass ownership to a different address.
        address finalOwner = TransferInternal.grantPositionOwnership(
            positionId,
            originalOwner,
            newOwner);

        require(
            finalOwner != originalOwner,
            "TransferImpl#transferPositionImpl: Cannot ultimately transfer ownership to self"
        );

        // Set state only after resolving the new owner (to reduce the number of storage calls)
        state.positions[positionId].owner = finalOwner;
    }
}

// File: contracts/margin/Margin.sol

/**
 * @title Margin
 * @author dYdX
 *
 * This contract is used to facilitate margin trading as per the dYdX protocol
 */
contract Margin is
    ReentrancyGuard,
    MarginStorage,
    MarginEvents,
    MarginAdmin,
    LoanGetters,
    PositionGetters
{

    using SafeMath for uint256;

    // ============ Constructor ============

    constructor(
        address vault,
        address proxy
    )
        public
        MarginAdmin()
    {
        state = MarginState.State({
            VAULT: vault,
            TOKEN_PROXY: proxy
        });
    }

    // ============ Public State Changing Functions ============

    /**
     * Open a margin position. Called by the margin trader who must provide both a
     * signed loan offering as well as a DEX Order with which to sell the owedToken.
     *
     * @param  addresses           Addresses corresponding to:
     *
     *  [0]  = position owner
     *  [1]  = owedToken
     *  [2]  = heldToken
     *  [3]  = loan payer
     *  [4]  = loan owner
     *  [5]  = loan taker
     *  [6]  = loan position owner
     *  [7]  = loan fee recipient
     *  [8]  = loan lender fee token
     *  [9]  = loan taker fee token
     *  [10]  = exchange wrapper address
     *
     * @param  values256           Values corresponding to:
     *
     *  [0]  = loan maximum amount
     *  [1]  = loan minimum amount
     *  [2]  = loan minimum heldToken
     *  [3]  = loan lender fee
     *  [4]  = loan taker fee
     *  [5]  = loan expiration timestamp (in seconds)
     *  [6]  = loan salt
     *  [7]  = position amount of principal
     *  [8]  = deposit amount
     *  [9]  = nonce (used to calculate positionId)
     *
     * @param  values32            Values corresponding to:
     *
     *  [0] = loan call time limit (in seconds)
     *  [1] = loan maxDuration (in seconds)
     *  [2] = loan interest rate (annual nominal percentage times 10**6)
     *  [3] = loan interest update period (in seconds)
     *
     * @param  depositInHeldToken  True if the trader wishes to pay the margin deposit in heldToken.
     *                             False if the margin deposit will be in owedToken
     *                             and then sold along with the owedToken borrowed from the lender
     * @param  signature           If loan payer is an account, then this must be the tightly-packed
     *                             ECDSA V/R/S parameters from signing the loan hash. If loan payer
     *                             is a smart contract, these are arbitrary bytes that the contract
     *                             will recieve when choosing whether to approve the loan.
     * @param  order               Order object to be passed to the exchange wrapper
     * @return                     Unique ID for the new position
     */
    function openPosition(
        address[11] addresses,
        uint256[10] values256,
        uint32[4]   values32,
        bool        depositInHeldToken,
        bytes       signature,
        bytes       order
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (bytes32)
    {
        return OpenPositionImpl.openPositionImpl(
            state,
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature,
            order
        );
    }

    /**
     * Open a margin position without a counterparty. The caller will serve as both the
     * lender and the position owner
     *
     * @param  addresses    Addresses corresponding to:
     *
     *  [0]  = position owner
     *  [1]  = owedToken
     *  [2]  = heldToken
     *  [3]  = loan owner
     *
     * @param  values256    Values corresponding to:
     *
     *  [0]  = principal
     *  [1]  = deposit amount
     *  [2]  = nonce (used to calculate positionId)
     *
     * @param  values32     Values corresponding to:
     *
     *  [0] = call time limit (in seconds)
     *  [1] = maxDuration (in seconds)
     *  [2] = interest rate (annual nominal percentage times 10**6)
     *  [3] = interest update period (in seconds)
     *
     * @return              Unique ID for the new position
     */
    function openWithoutCounterparty(
        address[4] addresses,
        uint256[3] values256,
        uint32[4]  values32
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (bytes32)
    {
        return OpenWithoutCounterpartyImpl.openWithoutCounterpartyImpl(
            state,
            addresses,
            values256,
            values32
        );
    }

    /**
     * Increase the size of a position. Funds will be borrowed from the loan payer and sold as per
     * the position. The amount of owedToken borrowed from the lender will be >= the amount of
     * principal added, as it will incorporate interest already earned by the position so far.
     *
     * @param  positionId          Unique ID of the position
     * @param  addresses           Addresses corresponding to:
     *
     *  [0]  = loan payer
     *  [1]  = loan taker
     *  [2]  = loan position owner
     *  [3]  = loan fee recipient
     *  [4]  = loan lender fee token
     *  [5]  = loan taker fee token
     *  [6]  = exchange wrapper address
     *
     * @param  values256           Values corresponding to:
     *
     *  [0]  = loan maximum amount
     *  [1]  = loan minimum amount
     *  [2]  = loan minimum heldToken
     *  [3]  = loan lender fee
     *  [4]  = loan taker fee
     *  [5]  = loan expiration timestamp (in seconds)
     *  [6]  = loan salt
     *  [7]  = amount of principal to add to the position (NOTE: the amount pulled from the lender
     *                                                           will be >= this amount)
     *
     * @param  values32            Values corresponding to:
     *
     *  [0] = loan call time limit (in seconds)
     *  [1] = loan maxDuration (in seconds)
     *
     * @param  depositInHeldToken  True if the trader wishes to pay the margin deposit in heldToken.
     *                             False if the margin deposit will be pulled in owedToken
     *                             and then sold along with the owedToken borrowed from the lender
     * @param  signature           If loan payer is an account, then this must be the tightly-packed
     *                             ECDSA V/R/S parameters from signing the loan hash. If loan payer
     *                             is a smart contract, these are arbitrary bytes that the contract
     *                             will recieve when choosing whether to approve the loan.
     * @param  order               Order object to be passed to the exchange wrapper
     * @return                     Amount of owedTokens pulled from the lender
     */
    function increasePosition(
        bytes32    positionId,
        address[7] addresses,
        uint256[8] values256,
        uint32[2]  values32,
        bool       depositInHeldToken,
        bytes      signature,
        bytes      order
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (uint256)
    {
        return IncreasePositionImpl.increasePositionImpl(
            state,
            positionId,
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature,
            order
        );
    }

    /**
     * Increase a position directly by putting up heldToken. The caller will serve as both the
     * lender and the position owner
     *
     * @param  positionId      Unique ID of the position
     * @param  principalToAdd  Principal amount to add to the position
     * @return                 Amount of heldToken pulled from the msg.sender
     */
    function increaseWithoutCounterparty(
        bytes32 positionId,
        uint256 principalToAdd
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (uint256)
    {
        return IncreasePositionImpl.increaseWithoutCounterpartyImpl(
            state,
            positionId,
            principalToAdd
        );
    }

    /**
     * Close a position. May be called by the owner or with the approval of the owner. May provide
     * an order and exchangeWrapper to facilitate the closing of the position. The payoutRecipient
     * is sent the resulting payout.
     *
     * @param  positionId            Unique ID of the position
     * @param  requestedCloseAmount  Principal amount of the position to close. The actual amount
     *                               closed is also bounded by:
     *                               1) The principal of the position
     *                               2) The amount allowed by the owner if closer != owner
     * @param  payoutRecipient       Address of the recipient of tokens paid out from closing
     * @param  exchangeWrapper       Address of the exchange wrapper
     * @param  payoutInHeldToken     True to pay out the payoutRecipient in heldToken,
     *                               False to pay out the payoutRecipient in owedToken
     * @param  order                 Order object to be passed to the exchange wrapper
     * @return                       Values corresponding to:
     *                               1) Principal of position closed
     *                               2) Amount of tokens (heldToken if payoutInHeldtoken is true,
     *                                  owedToken otherwise) received by the payoutRecipient
     *                               3) Amount of owedToken paid (incl. interest fee) to the lender
     */
    function closePosition(
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool    payoutInHeldToken,
        bytes   order
    )
        external
        closePositionStateControl
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        return ClosePositionImpl.closePositionImpl(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            exchangeWrapper,
            payoutInHeldToken,
            order
        );
    }

    /**
     * Helper to close a position by paying owedToken directly rather than using an exchangeWrapper.
     *
     * @param  positionId            Unique ID of the position
     * @param  requestedCloseAmount  Principal amount of the position to close. The actual amount
     *                               closed is also bounded by:
     *                               1) The principal of the position
     *                               2) The amount allowed by the owner if closer != owner
     * @param  payoutRecipient       Address of the recipient of tokens paid out from closing
     * @return                       Values corresponding to:
     *                               1) Principal amount of position closed
     *                               2) Amount of heldToken received by the payoutRecipient
     *                               3) Amount of owedToken paid (incl. interest fee) to the lender
     */
    function closePositionDirectly(
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient
    )
        external
        closePositionDirectlyStateControl
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        return ClosePositionImpl.closePositionImpl(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            address(0),
            true,
            new bytes(0)
        );
    }

    /**
     * Reduce the size of a position and withdraw a proportional amount of heldToken from the vault.
     * Must be approved by both the position owner and lender.
     *
     * @param  positionId            Unique ID of the position
     * @param  requestedCloseAmount  Principal amount of the position to close. The actual amount
     *                               closed is also bounded by:
     *                               1) The principal of the position
     *                               2) The amount allowed by the owner if closer != owner
     *                               3) The amount allowed by the lender if closer != lender
     * @return                       Values corresponding to:
     *                               1) Principal amount of position closed
     *                               2) Amount of heldToken received by the msg.sender
     */
    function closeWithoutCounterparty(
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient
    )
        external
        closePositionStateControl
        nonReentrant
        returns (uint256, uint256)
    {
        return CloseWithoutCounterpartyImpl.closeWithoutCounterpartyImpl(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient
        );
    }

    /**
     * Margin-call a position. Only callable with the approval of the position lender. After the
     * call, the position owner will have time equal to the callTimeLimit of the position to close
     * the position. If the owner does not close the position, the lender can recover the collateral
     * in the position.
     *
     * @param  positionId       Unique ID of the position
     * @param  requiredDeposit  Amount of deposit the position owner will have to put up to cancel
     *                          the margin-call. Passing in 0 means the margin call cannot be
     *                          canceled by depositing
     */
    function marginCall(
        bytes32 positionId,
        uint256 requiredDeposit
    )
        external
        nonReentrant
    {
        LoanImpl.marginCallImpl(
            state,
            positionId,
            requiredDeposit
        );
    }

    /**
     * Cancel a margin-call. Only callable with the approval of the position lender.
     *
     * @param  positionId  Unique ID of the position
     */
    function cancelMarginCall(
        bytes32 positionId
    )
        external
        onlyWhileOperational
        nonReentrant
    {
        LoanImpl.cancelMarginCallImpl(state, positionId);
    }

    /**
     * Used to recover the heldTokens held as collateral. Is callable after the maximum duration of
     * the loan has expired or the loan has been margin-called for the duration of the callTimeLimit
     * but remains unclosed. Only callable with the approval of the position lender.
     *
     * @param  positionId  Unique ID of the position
     * @param  recipient   Address to send the recovered tokens to
     * @return             Amount of heldToken recovered
     */
    function forceRecoverCollateral(
        bytes32 positionId,
        address recipient
    )
        external
        nonReentrant
        returns (uint256)
    {
        return ForceRecoverCollateralImpl.forceRecoverCollateralImpl(
            state,
            positionId,
            recipient
        );
    }

    /**
     * Deposit additional heldToken as collateral for a position. Cancels margin-call if:
     * 0 < position.requiredDeposit < depositAmount. Only callable by the position owner.
     *
     * @param  positionId       Unique ID of the position
     * @param  depositAmount    Additional amount in heldToken to deposit
     */
    function depositCollateral(
        bytes32 positionId,
        uint256 depositAmount
    )
        external
        onlyWhileOperational
        nonReentrant
    {
        DepositCollateralImpl.depositCollateralImpl(
            state,
            positionId,
            depositAmount
        );
    }

    /**
     * Cancel an amount of a loan offering. Only callable by the loan offering&#39;s payer.
     *
     * @param  addresses     Array of addresses:
     *
     *  [0] = owedToken
     *  [1] = heldToken
     *  [2] = loan payer
     *  [3] = loan owner
     *  [4] = loan taker
     *  [5] = loan position owner
     *  [6] = loan fee recipient
     *  [7] = loan lender fee token
     *  [8] = loan taker fee token
     *
     * @param  values256     Values corresponding to:
     *
     *  [0] = loan maximum amount
     *  [1] = loan minimum amount
     *  [2] = loan minimum heldToken
     *  [3] = loan lender fee
     *  [4] = loan taker fee
     *  [5] = loan expiration timestamp (in seconds)
     *  [6] = loan salt
     *
     * @param  values32      Values corresponding to:
     *
     *  [0] = loan call time limit (in seconds)
     *  [1] = loan maxDuration (in seconds)
     *  [2] = loan interest rate (annual nominal percentage times 10**6)
     *  [3] = loan interest update period (in seconds)
     *
     * @param  cancelAmount  Amount to cancel
     * @return               Amount that was canceled
     */
    function cancelLoanOffering(
        address[9] addresses,
        uint256[7]  values256,
        uint32[4]   values32,
        uint256     cancelAmount
    )
        external
        cancelLoanOfferingStateControl
        nonReentrant
        returns (uint256)
    {
        return LoanImpl.cancelLoanOfferingImpl(
            state,
            addresses,
            values256,
            values32,
            cancelAmount
        );
    }

    /**
     * Transfer ownership of a loan to a new address. This new address will be entitled to all
     * payouts for this loan. Only callable by the lender for a position. If "who" is a contract, it
     * must implement the LoanOwner interface.
     *
     * @param  positionId  Unique ID of the position
     * @param  who         New owner of the loan
     */
    function transferLoan(
        bytes32 positionId,
        address who
    )
        external
        nonReentrant
    {
        TransferImpl.transferLoanImpl(
            state,
            positionId,
            who);
    }

    /**
     * Transfer ownership of a position to a new address. This new address will be entitled to all
     * payouts. Only callable by the owner of a position. If "who" is a contract, it must implement
     * the PositionOwner interface.
     *
     * @param  positionId  Unique ID of the position
     * @param  who         New owner of the position
     */
    function transferPosition(
        bytes32 positionId,
        address who
    )
        external
        nonReentrant
    {
        TransferImpl.transferPositionImpl(
            state,
            positionId,
            who);
    }

    // ============ Public Constant Functions ============

    /**
     * Gets the address of the Vault contract that holds and accounts for tokens.
     *
     * @return  The address of the Vault contract
     */
    function getVaultAddress()
        external
        view
        returns (address)
    {
        return state.VAULT;
    }

    /**
     * Gets the address of the TokenProxy contract that accounts must set allowance on in order to
     * make loans or open/close positions.
     *
     * @return  The address of the TokenProxy contract
     */
    function getTokenProxyAddress()
        external
        view
        returns (address)
    {
        return state.TOKEN_PROXY;
    }
}

// File: contracts/margin/interfaces/ExchangeReader.sol

/**
 * @title ExchangeReader
 * @author dYdX
 *
 * Contract interface that wraps an exchange and provides information about the current state of the
 * exchange or particular orders
 */
interface ExchangeReader {

    // ============ Public Functions ============

    /**
     * Get the maxmimum amount of makerToken for some order
     *
     * @param  makerToken           Address of makerToken, the token to receive
     * @param  takerToken           Address of takerToken, the token to pay
     * @param  orderData            Arbitrary bytes data for any information to pass to the exchange
     * @return                      Maximum amount of makerToken
     */
    function getMaxMakerAmount(
        address makerToken,
        address takerToken,
        bytes orderData
    )
        external
        view
        returns (uint256);
}

// File: contracts/margin/external/AuctionProxy.sol

/**
 * @title AuctionProxy
 * @author dYdX
 *
 * Contract that automatically sets the close amount for bidding in a Dutch Auction
 */
contract AuctionProxy
{
    using TokenInteract for address;
    using SafeMath for uint256;

    // ============ Structs ============

    struct Position {
        address heldToken;
        address owedToken;
        address owner;
        uint256 principal;
        uint256 owedTokenOwed;
    }

    // ============ State Variables ============

    address public DYDX_MARGIN;

    // ============ Constructor ============

    constructor(
        address margin
    )
        public
    {
        DYDX_MARGIN = margin;
    }

    // ============ Public Functions ============

    /**
     * Using the Dutch Auction mechanism, bids on a position that is currently closing.
     * Calculates the maximum close amount for a position, exchange, and order.
     *
     * @param  positionId       Unique ID of the position
     * @param  minCloseAmount   The minimum acceptable close amount
     * @param  dutchAuction     The address of the Dutch Auction contract to use
     * @param  exchangeWrapper  The address of the Exchange Wrapper (and Exchange Reader) to use
     * @param  orderData        The order data to pass to the Exchange Wrapper
     * @return                  The principal amount of the position that was closed
     */
    function closePosition(
        bytes32 positionId,
        uint256 minCloseAmount,
        address dutchAuction,
        address exchangeWrapper,
        bytes   orderData
    )
        external
        returns (uint256)
    {
        Margin margin = Margin(DYDX_MARGIN);

        if (!margin.containsPosition(positionId)) {
            return 0; // if position is closed, return zero instead of throwing
        }

        Position memory position = parsePosition(margin, positionId);
        uint256 maxCloseAmount = getMaxCloseAmount(position, exchangeWrapper, orderData);

        if (maxCloseAmount == 0) {
            return 0; // if order cannot be used, return zero instead of throwing
        }

        if (maxCloseAmount < minCloseAmount) {
            return 0; // if order is already taken, return zero instead of throwing
        }

        margin.closePosition(
            positionId,
            maxCloseAmount,
            dutchAuction,
            exchangeWrapper,
            true, // payoutInHeldToken
            orderData
        );

        // give all tokens to the owner
        uint256 heldTokenAmount = position.heldToken.balanceOf(address(this));
        position.heldToken.transfer(position.owner, heldTokenAmount);

        return maxCloseAmount;
    }

    // ============ Private Functions ============

    function parsePosition (
        Margin margin,
        bytes32 positionId
    )
        private
        view
        returns (Position memory)
    {
        Position memory position;
        position.heldToken = margin.getPositionHeldToken(positionId);
        position.owedToken = margin.getPositionOwedToken(positionId);
        position.owner = margin.getPositionOwner(positionId);
        position.principal = margin.getPositionPrincipal(positionId);
        position.owedTokenOwed = margin.getPositionOwedAmount(positionId);
        return position;
    }

    function getMaxCloseAmount(
        Position memory position,
        address exchangeWrapper,
        bytes orderData
    )
        private
        view
        returns (uint256)
    {
        uint256 makerTokenAmount = ExchangeReader(exchangeWrapper).getMaxMakerAmount(
            position.owedToken,
            position.heldToken,
            orderData
        );

        // get maximum close amount
        uint256 closeAmount = MathHelpers.getPartialAmount(
            position.principal,
            position.owedTokenOwed,
            makerTokenAmount
        );

        return closeAmount;
    }
}