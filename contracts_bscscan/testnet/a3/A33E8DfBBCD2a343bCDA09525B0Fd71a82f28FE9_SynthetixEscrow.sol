/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: SynthetixEscrow.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/SynthetixEscrow.sol
* Docs: https://docs.synthetix.io/contracts/SynthetixEscrow
*
* Contract Dependencies: (none)
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
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



pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.synthetix.io/contracts/source/contracts/limitedsetup
contract LimitedSetup {
    uint public setupExpiryTime;

    /**
     * @dev LimitedSetup Constructor.
     * @param setupDuration The time the setup period will last for.
     */
    constructor(uint setupDuration) internal {
        setupExpiryTime = now + setupDuration;
    }

    modifier onlyDuringSetup {
        require(now < setupExpiryTime, "Can only perform this action during setup");
        _;
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/ihasbalance
interface IHasBalance {
    // Views
    function balanceOf(address account) external view returns (uint);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Libraries


// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
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
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
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
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
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
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
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
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
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
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
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
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint);

    function totalIssuedSynthsExcludeEtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableSynthetix(address account) external view returns (uint transferable);

    // Mutative Functions
    function burnSynths(uint amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint amount) external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account, uint cusdAmount) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}


// Inheritance


// Libraires


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/synthetixescrow
contract SynthetixEscrow is Owned, LimitedSetup(8 weeks), IHasBalance {
    using SafeMath for uint;

    /* The corresponding Synthetix contract. */
    ISynthetix public synthetix;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of SNX vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account's total vested synthetix balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining vested balance, for verifying the actual synthetix balance of this contract against. */
    uint public totalVestedBalance;

    uint public constant TIME_INDEX = 0;
    uint public constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules. */
    uint public constant MAX_VESTING_ENTRIES = 20;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, ISynthetix _synthetix) public Owned(_owner) {
        synthetix = _synthetix;
    }

    /* ========== SETTERS ========== */

    function setSynthetix(ISynthetix _synthetix) external onlyOwner {
        synthetix = _synthetix;
        emit SynthetixUpdated(address(_synthetix));
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) public view returns (uint) {
        return totalVestedAccountBalance[account];
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account) public view returns (uint) {
        return vestingSchedules[account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, synthetix quantity).
     */
    function getVestingScheduleEntry(address account, uint index) public view returns (uint[2] memory) {
        return vestingSchedules[account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index) public view returns (uint) {
        return getVestingScheduleEntry(account, index)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of SNX associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index) public view returns (uint) {
        return getVestingScheduleEntry(account, index)[QUANTITY_INDEX];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account) public view returns (uint) {
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
    function getNextVestingEntry(address account) public view returns (uint[2] memory) {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account) external view returns (uint) {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account) external view returns (uint) {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Destroy the vesting information associated with an account.
     */
    function purgeAccount(address account) external onlyOwner onlyDuringSetup {
        delete vestingSchedules[account];
        totalVestedBalance = totalVestedBalance.sub(totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should be accompanied by either enough balance already available
     * in this contract, or a corresponding call to synthetix.endow(), to ensure that when
     * the funds are withdrawn, there is enough balance, as well as correctly calculating
     * the fees.
     * This may only be called by the owner during the contract's setup period.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only in the foundation's command to add to these lists.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of SNX that will vest.
     */
    function appendVestingEntry(
        address account,
        uint time,
        uint quantity
    ) public onlyOwner onlyDuringSetup {
        /* No empty or already-passed vesting entries allowed. */
        require(now < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalVestedBalance = totalVestedBalance.add(quantity);
        require(
            totalVestedBalance <= IERC20(address(synthetix)).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        if (scheduleLength == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
            /* Disallow adding new vested SNX earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(
                getVestingTime(account, numVestingEntries(account) - 1) < time,
                "Cannot add new vested entries earlier than the last one"
            );
            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

    /**
     * @notice Construct a vesting schedule to release a quantities of SNX
     * over a series of intervals.
     * @dev Assumes that the quantities are nonzero
     * and that the sequence of timestamps is strictly increasing.
     * This may only be called by the owner during the contract's setup period.
     */
    function addVestingSchedule(
        address account,
        uint[] calldata times,
        uint[] calldata quantities
    ) external onlyOwner onlyDuringSetup {
        for (uint i = 0; i < times.length; i++) {
            appendVestingEntry(account, times[i], quantities[i]);
        }
    }

    /**
     * @notice Allow a user to withdraw any SNX in their schedule that have vested.
     */
    function vest() external {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty > 0) {
                vestingSchedules[msg.sender][i] = [0, 0];
                total = total.add(qty);
            }
        }

        if (total != 0) {
            totalVestedBalance = totalVestedBalance.sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].sub(total);
            IERC20(address(synthetix)).transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }

    /* ========== EVENTS ========== */

    event SynthetixUpdated(address newSynthetix);

    event Vested(address indexed beneficiary, uint time, uint value);
}