/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: EtherCollateral.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/EtherCollateral.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/EtherCollateral
*
* Contract Dependencies: 
*	- IAddressResolver
*	- IEtherCollateral
*	- MixinResolver
*	- Owned
*	- Pausable
*	- ReentrancyGuard
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2021 PeriFinance
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



pragma solidity 0.5.16;

// https://docs.peri.finance/contracts/source/contracts/owned
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


// Inheritance


// https://docs.peri.finance/contracts/source/contracts/pausable
contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    constructor() internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = now;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


// https://docs.peri.finance/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getPynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.peri.finance/contracts/source/interfaces/ipynth
interface IPynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferablePynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to PeriFinance
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.peri.finance/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views
    function anyPynthOrPERIRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availablePynthCount() external view returns (uint);

    function availablePynths(uint index) external view returns (IPynth);

    function canBurnPynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuablePynths(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuablePynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function currentUSDCDebtQuota(address _account) external view returns (uint);

    function pynths(bytes32 currencyKey) external view returns (IPynth);

    function getPynths(bytes32[] calldata currencyKeys) external view returns (IPynth[] memory);

    function pynthsByAddress(address pynthAddress) external view returns (bytes32);

    function totalIssuedPynths(bytes32 currencyKey, bool excludeEtherCollateral) external view returns (uint);

    function transferablePeriFinanceAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    // Restricted: used internally to PeriFinance
    function issuePynthsAndStakeUSDC(
        address _issuer,
        uint _issueAmount,
        uint _usdcStakeAmount
    ) external;

    function issueMaxPynths(address _issuer) external;

    function issuePynthsAndStakeMaxUSDC(address _issuer, uint _issueAmount) external;

    function burnPynthsAndUnstakeUSDC(
        address _from,
        uint _burnAmount,
        uint _unstakeAmount
    ) external;

    function burnPynthsAndUnstakeUSDCToTarget(address _from) external;

    function liquidateDelinquentAccount(
        address account,
        uint pusdAmount,
        address liquidator
    ) external returns (uint totalRedeemed, uint amountToLiquidate);
}


// Inheritance


// Internal references


// https://docs.peri.finance/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getPynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.pynths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// solhint-disable payable-fallback

// https://docs.peri.finance/contracts/source/contracts/readproxy
contract ReadProxy is Owned {
    address public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(address _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(target);
    }

    function() external {
        // The basics of a proxy read call
        // Note that msg.sender in the underlying will always be the address of this contract.
        assembly {
            calldatacopy(0, 0, calldatasize)

            // Use of staticcall - this will revert if the underlying function mutates state
            let result := staticcall(gas, sload(target_slot), 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)

            if iszero(result) {
                revert(0, returndatasize)
            }
            return(0, returndatasize)
        }
    }

    event TargetUpdated(address newTarget);
}


// Inheritance


// Internal references


// https://docs.peri.finance/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// https://docs.peri.finance/contracts/source/interfaces/iethercollateral
interface IEtherCollateral {
    // Views
    function totalIssuedPynths() external view returns (uint256);

    function totalLoansCreated() external view returns (uint256);

    function totalOpenLoanCount() external view returns (uint256);

    // Mutative functions
    function openLoan() external payable returns (uint256 loanID);

    function closeLoan(uint256 loanID) external;

    function liquidateUnclosedLoan(address _loanCreatorsAddress, uint256 _loanID) external;
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


// https://docs.peri.finance/contracts/source/libraries/safedecimalmath
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

    /**
     * @dev Round down the value with given number
     */
    function roundDownDecimal(uint x, uint d) internal pure returns (uint) {
        return x.div(10**d).mul(10**d);
    }
}


// https://docs.peri.finance/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireExchangeBetweenPynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requirePynthActive(bytes32 currencyKey) external view;

    function requirePynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function pynthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function pynthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function getPynthExchangeSuspensions(bytes32[] calldata pynths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getPynthSuspensions(bytes32[] calldata pynths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendPynth(bytes32 currencyKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}


// https://docs.peri.finance/contracts/source/interfaces/ifeepool
interface IFeePool {
    // Views

    // solhint-disable-next-line func-name-mixedcase
    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account) external view returns (uint, uint);

    function feePeriodDuration() external view returns (uint);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint);

    function totalFeesAvailable() external view returns (uint);

    function totalRewardsAvailable() external view returns (uint);

    // Mutative Functions
    function claimFees() external returns (bool);

    function claimOnBehalf(address claimingForAddress) external returns (bool);

    function closeCurrentFeePeriod() external;

    // Restricted: used internally to PeriFinance
    function appendAccountIssuanceRecord(
        address account,
        uint lockedAmount,
        uint debtEntryIndex
    ) external;

    function recordFeePaid(uint pUSDAmount) external;

    function setRewardsToDistribute(uint amount) external;
}


// https://docs.peri.finance/contracts/source/interfaces/ierc20
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


// https://docs.peri.finance/contracts/source/interfaces/idepot
interface IDepot {
    // Views
    function fundsWallet() external view returns (address payable);

    function maxEthPurchase() external view returns (uint);

    function minimumDepositAmount() external view returns (uint);

    function pynthsReceivedForEther(uint amount) external view returns (uint);

    function totalSellableDeposits() external view returns (uint);

    // Mutative functions
    function depositPynths(uint amount) external;

    function exchangeEtherForPynths() external payable returns (uint);

    function exchangeEtherForPynthsAtRate(uint guaranteedRate) external payable returns (uint);

    function withdrawMyDepositedPynths() external;

    // Note: On mainnet no PERI has been deposited. The following functions are kept alive for testnet PERI faucets.
    function exchangeEtherForPERI() external payable returns (uint);

    function exchangeEtherForPERIAtRate(uint guaranteedRate, uint guaranteedPeriFinanceRate) external payable returns (uint);

    function exchangePynthsForPERI(uint pynthAmount) external returns (uint);

    function periFinanceReceivedForEther(uint amount) external view returns (uint);

    function periFinanceReceivedForPynths(uint amount) external view returns (uint);

    function withdrawPeriFinance(uint amount) external;
}


// https://docs.peri.finance/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozenAtUpperLimit;
        bool frozenAtLowerLimit;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function canFreezeRate(bytes32 currencyKey) external view returns (bool);

    function currentRoundForRate(bytes32 currencyKey) external view returns (uint);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external view returns (uint value);

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function inversePricing(bytes32 currencyKey)
        external
        view
        returns (
            uint entryPoint,
            uint upperLimit,
            uint lowerLimit,
            bool frozenAtUpperLimit,
            bool frozenAtLowerLimit
        );

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function oracle() external view returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsFrozen(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(bytes32 currencyKey, uint numRounds)
        external
        view
        returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    // Mutative functions
    function freezeRate(bytes32 currencyKey) external;
}


// Inheritance


// Libraries


// Internal references


// https://docs.peri.finance/contracts/source/contracts/ethercollateral
contract EtherCollateral is Owned, Pausable, ReentrancyGuard, MixinResolver, IEtherCollateral {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    // ========== CONSTANTS ==========
    uint256 internal constant ONE_THOUSAND = 1e18 * 1000;
    uint256 internal constant ONE_HUNDRED = 1e18 * 100;

    uint256 internal constant SECONDS_IN_A_YEAR = 31536000; // Common Year

    // Where fees are pooled in pUSD.
    address internal constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    // ========== SETTER STATE VARIABLES ==========

    // The ratio of Collateral to pynths issued
    uint256 public collateralizationRatio = SafeDecimalMath.unit() * 125; // SCCP-27

    // If updated, all outstanding loans will pay this interest rate in on closure of the loan. Default 5%
    uint256 public interestRate = (5 * SafeDecimalMath.unit()) / 100;
    uint256 public interestPerSecond = interestRate.div(SECONDS_IN_A_YEAR);

    // Minting fee for issuing the pynths. Default 50 bips.
    uint256 public issueFeeRate = (5 * SafeDecimalMath.unit()) / 1000;

    // Maximum amount of pETH that can be issued by the EtherCollateral contract. Default 5000
    uint256 public issueLimit = SafeDecimalMath.unit() * 5000;

    // Minimum amount of ETH to create loan preventing griefing and gas consumption. Min 1ETH = 0.8 pETH
    uint256 public minLoanSize = SafeDecimalMath.unit() * 1;

    // Maximum number of loans an account can create
    uint256 public accountLoanLimit = 50;

    // If true then any wallet addres can close a loan not just the loan creator.
    bool public loanLiquidationOpen = false;

    // Time when remaining loans can be liquidated
    uint256 public liquidationDeadline;

    // ========== STATE VARIABLES ==========

    // The total number of pynths issued by the collateral in this contract
    uint256 public totalIssuedPynths;

    // Total number of loans ever created
    uint256 public totalLoansCreated;

    // Total number of open loans
    uint256 public totalOpenLoanCount;

    // Pynth loan storage struct
    struct PynthLoanStruct {
        //  Acccount that created the loan
        address account;
        //  Amount (in collateral token ) that they deposited
        uint256 collateralAmount;
        //  Amount (in pynths) that they issued to borrow
        uint256 loanAmount;
        // When the loan was created
        uint256 timeCreated;
        // ID for the loan
        uint256 loanID;
        // When the loan was paidback (closed)
        uint256 timeClosed;
    }

    // Users Loans by address
    mapping(address => PynthLoanStruct[]) public accountsPynthLoans;

    // Account Open Loan Counter
    mapping(address => uint256) public accountOpenLoanCounter;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_PYNTHPETH = "PynthpETH";
    bytes32 private constant CONTRACT_PYNTHPUSD = "PynthpUSD";
    bytes32 private constant CONTRACT_DEPOT = "Depot";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    // ========== CONSTRUCTOR ==========
    constructor(address _owner, address _resolver) public Owned(_owner) Pausable() MixinResolver(_resolver) {
        liquidationDeadline = now + 92 days; // Time before loans can be liquidated
    }

    // ========== SETTERS ==========

    function setCollateralizationRatio(uint256 ratio) external onlyOwner {
        require(ratio <= ONE_THOUSAND, "Too high");
        require(ratio >= ONE_HUNDRED, "Too low");
        collateralizationRatio = ratio;
        emit CollateralizationRatioUpdated(ratio);
    }

    function setInterestRate(uint256 _interestRate) external onlyOwner {
        require(_interestRate > SECONDS_IN_A_YEAR, "Interest rate cannot be less that the SECONDS_IN_A_YEAR");
        require(_interestRate <= SafeDecimalMath.unit(), "Interest cannot be more than 100% APR");
        interestRate = _interestRate;
        interestPerSecond = _interestRate.div(SECONDS_IN_A_YEAR);
        emit InterestRateUpdated(interestRate);
    }

    function setIssueFeeRate(uint256 _issueFeeRate) external onlyOwner {
        issueFeeRate = _issueFeeRate;
        emit IssueFeeRateUpdated(issueFeeRate);
    }

    function setIssueLimit(uint256 _issueLimit) external onlyOwner {
        issueLimit = _issueLimit;
        emit IssueLimitUpdated(issueLimit);
    }

    function setMinLoanSize(uint256 _minLoanSize) external onlyOwner {
        minLoanSize = _minLoanSize;
        emit MinLoanSizeUpdated(minLoanSize);
    }

    function setAccountLoanLimit(uint256 _loanLimit) external onlyOwner {
        uint256 HARD_CAP = 1000;
        require(_loanLimit < HARD_CAP, "Owner cannot set higher than HARD_CAP");
        accountLoanLimit = _loanLimit;
        emit AccountLoanLimitUpdated(accountLoanLimit);
    }

    function setLoanLiquidationOpen(bool _loanLiquidationOpen) external onlyOwner {
        require(now > liquidationDeadline, "Before liquidation deadline");
        loanLiquidationOpen = _loanLiquidationOpen;
        emit LoanLiquidationOpenUpdated(loanLiquidationOpen);
    }

    // ========== PUBLIC VIEWS ==========

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](5);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_PYNTHPETH;
        addresses[2] = CONTRACT_PYNTHPUSD;
        addresses[3] = CONTRACT_DEPOT;
        addresses[4] = CONTRACT_EXRATES;
    }

    function getContractInfo()
        external
        view
        returns (
            uint256 _collateralizationRatio,
            uint256 _issuanceRatio,
            uint256 _interestRate,
            uint256 _interestPerSecond,
            uint256 _issueFeeRate,
            uint256 _issueLimit,
            uint256 _minLoanSize,
            uint256 _totalIssuedPynths,
            uint256 _totalLoansCreated,
            uint256 _totalOpenLoanCount,
            uint256 _ethBalance,
            uint256 _liquidationDeadline,
            bool _loanLiquidationOpen
        )
    {
        _collateralizationRatio = collateralizationRatio;
        _issuanceRatio = issuanceRatio();
        _interestRate = interestRate;
        _interestPerSecond = interestPerSecond;
        _issueFeeRate = issueFeeRate;
        _issueLimit = issueLimit;
        _minLoanSize = minLoanSize;
        _totalIssuedPynths = totalIssuedPynths;
        _totalLoansCreated = totalLoansCreated;
        _totalOpenLoanCount = totalOpenLoanCount;
        _ethBalance = address(this).balance;
        _liquidationDeadline = liquidationDeadline;
        _loanLiquidationOpen = loanLiquidationOpen;
    }

    // returns value of 100 / collateralizationRatio.
    // e.g. 100/125 = 0.8
    // or in wei 100000000000000000000/125000000000000000000 = 800000000000000000
    function issuanceRatio() public view returns (uint256) {
        // this Rounds so you get slightly more rather than slightly less
        // 4999999999999999995000
        return ONE_HUNDRED.divideDecimalRound(collateralizationRatio);
    }

    function loanAmountFromCollateral(uint256 collateralAmount) public view returns (uint256) {
        return collateralAmount.multiplyDecimal(issuanceRatio());
    }

    function collateralAmountForLoan(uint256 loanAmount) external view returns (uint256) {
        return loanAmount.multiplyDecimal(collateralizationRatio.divideDecimalRound(ONE_HUNDRED));
    }

    function currentInterestOnLoan(address _account, uint256 _loanID) external view returns (uint256) {
        // Get the loan from storage
        PynthLoanStruct memory pynthLoan = _getLoanFromStorage(_account, _loanID);
        uint256 loanLifeSpan = _loanLifeSpan(pynthLoan);
        return accruedInterestOnLoan(pynthLoan.loanAmount, loanLifeSpan);
    }

    function accruedInterestOnLoan(uint256 _loanAmount, uint256 _seconds) public view returns (uint256 interestAmount) {
        // Simple interest calculated per second
        // Interest = Principal * rate * time
        interestAmount = _loanAmount.multiplyDecimalRound(interestPerSecond.mul(_seconds));
    }

    function calculateMintingFee(address _account, uint256 _loanID) external view returns (uint256) {
        // Get the loan from storage
        PynthLoanStruct memory pynthLoan = _getLoanFromStorage(_account, _loanID);
        return _calculateMintingFee(pynthLoan);
    }

    function openLoanIDsByAccount(address _account) external view returns (uint256[] memory) {
        PynthLoanStruct[] memory pynthLoans = accountsPynthLoans[_account];

        uint256[] memory _openLoanIDs = new uint256[](pynthLoans.length);
        uint256 _counter = 0;

        for (uint256 i = 0; i < pynthLoans.length; i++) {
            if (pynthLoans[i].timeClosed == 0) {
                _openLoanIDs[_counter] = pynthLoans[i].loanID;
                _counter++;
            }
        }
        // Create the fixed size array to return
        uint256[] memory _result = new uint256[](_counter);

        // Copy loanIDs from dynamic array to fixed array
        for (uint256 j = 0; j < _counter; j++) {
            _result[j] = _openLoanIDs[j];
        }
        // Return an array with list of open Loan IDs
        return _result;
    }

    function getLoan(address _account, uint256 _loanID)
        external
        view
        returns (
            address account,
            uint256 collateralAmount,
            uint256 loanAmount,
            uint256 timeCreated,
            uint256 loanID,
            uint256 timeClosed,
            uint256 interest,
            uint256 totalFees
        )
    {
        PynthLoanStruct memory pynthLoan = _getLoanFromStorage(_account, _loanID);
        account = pynthLoan.account;
        collateralAmount = pynthLoan.collateralAmount;
        loanAmount = pynthLoan.loanAmount;
        timeCreated = pynthLoan.timeCreated;
        loanID = pynthLoan.loanID;
        timeClosed = pynthLoan.timeClosed;
        interest = accruedInterestOnLoan(pynthLoan.loanAmount, _loanLifeSpan(pynthLoan));
        totalFees = interest.add(_calculateMintingFee(pynthLoan));
    }

    function loanLifeSpan(address _account, uint256 _loanID) external view returns (uint256 loanLifeSpanResult) {
        PynthLoanStruct memory pynthLoan = _getLoanFromStorage(_account, _loanID);
        loanLifeSpanResult = _loanLifeSpan(pynthLoan);
    }

    // ========== PUBLIC FUNCTIONS ==========

    function openLoan() external payable notPaused nonReentrant pETHRateNotInvalid returns (uint256 loanID) {
        systemStatus().requireIssuanceActive();

        // Require ETH sent to be greater than minLoanSize
        require(msg.value >= minLoanSize, "Not enough ETH to create this loan. Please see the minLoanSize");

        // Require loanLiquidationOpen to be false or we are in liquidation phase
        require(loanLiquidationOpen == false, "Loans are now being liquidated");

        // Each account is limted to creating 50 (accountLoanLimit) loans
        require(accountsPynthLoans[msg.sender].length < accountLoanLimit, "Each account is limted to 50 loans");

        // Calculate issuance amount
        uint256 loanAmount = loanAmountFromCollateral(msg.value);

        // Require pETH to mint does not exceed cap
        require(totalIssuedPynths.add(loanAmount) < issueLimit, "Loan Amount exceeds the supply cap.");

        // Get a Loan ID
        loanID = _incrementTotalLoansCounter();

        // Create Loan storage object
        PynthLoanStruct memory pynthLoan =
            PynthLoanStruct({
                account: msg.sender,
                collateralAmount: msg.value,
                loanAmount: loanAmount,
                timeCreated: now,
                loanID: loanID,
                timeClosed: 0
            });

        // Record loan in mapping to account in an array of the accounts open loans
        accountsPynthLoans[msg.sender].push(pynthLoan);

        // Increment totalIssuedPynths
        totalIssuedPynths = totalIssuedPynths.add(loanAmount);

        // Issue the pynth
        pynthpETH().issue(msg.sender, loanAmount);

        // Tell the Dapps a loan was created
        emit LoanCreated(msg.sender, loanID, loanAmount);
    }

    function closeLoan(uint256 loanID) external nonReentrant pETHRateNotInvalid {
        _closeLoan(msg.sender, loanID);
    }

    // Liquidation of an open loan available for anyone
    function liquidateUnclosedLoan(address _loanCreatorsAddress, uint256 _loanID) external nonReentrant pETHRateNotInvalid {
        require(loanLiquidationOpen, "Liquidation is not open");
        // Close the creators loan and send collateral to the closer.
        _closeLoan(_loanCreatorsAddress, _loanID);
        // Tell the Dapps this loan was liquidated
        emit LoanLiquidated(_loanCreatorsAddress, _loanID, msg.sender);
    }

    // ========== PRIVATE FUNCTIONS ==========

    function _closeLoan(address account, uint256 loanID) private {
        systemStatus().requireIssuanceActive();

        // Get the loan from storage
        PynthLoanStruct memory pynthLoan = _getLoanFromStorage(account, loanID);

        require(pynthLoan.loanID > 0, "Loan does not exist");
        require(pynthLoan.timeClosed == 0, "Loan already closed");
        require(
            IERC20(address(pynthpETH())).balanceOf(msg.sender) >= pynthLoan.loanAmount,
            "You do not have the required Pynth balance to close this loan."
        );

        // Record loan as closed
        _recordLoanClosure(pynthLoan);

        // Decrement totalIssuedPynths
        totalIssuedPynths = totalIssuedPynths.sub(pynthLoan.loanAmount);

        // Calculate and deduct interest(5%) and minting fee(50 bips) in ETH
        uint256 interestAmount = accruedInterestOnLoan(pynthLoan.loanAmount, _loanLifeSpan(pynthLoan));
        uint256 mintingFee = _calculateMintingFee(pynthLoan);
        uint256 totalFeeETH = interestAmount.add(mintingFee);

        // Burn all Pynths issued for the loan
        pynthpETH().burn(msg.sender, pynthLoan.loanAmount);

        // Fee Distribution. Purchase pUSD with ETH from Depot
        require(
            IERC20(address(pynthpUSD())).balanceOf(address(depot())) >= depot().pynthsReceivedForEther(totalFeeETH),
            "The pUSD Depot does not have enough pUSD to buy for fees"
        );
        depot().exchangeEtherForPynths.value(totalFeeETH)();

        // Transfer the pUSD to distribute to PERI holders.
        IERC20(address(pynthpUSD())).transfer(FEE_ADDRESS, IERC20(address(pynthpUSD())).balanceOf(address(this)));

        // Send remainder ETH to caller
        address(msg.sender).transfer(pynthLoan.collateralAmount.sub(totalFeeETH));

        // Tell the Dapps
        emit LoanClosed(account, loanID, totalFeeETH);
    }

    function _getLoanFromStorage(address account, uint256 loanID) private view returns (PynthLoanStruct memory) {
        PynthLoanStruct[] memory pynthLoans = accountsPynthLoans[account];
        for (uint256 i = 0; i < pynthLoans.length; i++) {
            if (pynthLoans[i].loanID == loanID) {
                return pynthLoans[i];
            }
        }
    }

    function _recordLoanClosure(PynthLoanStruct memory pynthLoan) private {
        // Get storage pointer to the accounts array of loans
        PynthLoanStruct[] storage pynthLoans = accountsPynthLoans[pynthLoan.account];
        for (uint256 i = 0; i < pynthLoans.length; i++) {
            if (pynthLoans[i].loanID == pynthLoan.loanID) {
                // Record the time the loan was closed
                pynthLoans[i].timeClosed = now;
            }
        }

        // Reduce Total Open Loans Count
        totalOpenLoanCount = totalOpenLoanCount.sub(1);
    }

    function _incrementTotalLoansCounter() private returns (uint256) {
        // Increase the total Open loan count
        totalOpenLoanCount = totalOpenLoanCount.add(1);
        // Increase the total Loans Created count
        totalLoansCreated = totalLoansCreated.add(1);
        // Return total count to be used as a unique ID.
        return totalLoansCreated;
    }

    function _calculateMintingFee(PynthLoanStruct memory pynthLoan) private view returns (uint256 mintingFee) {
        mintingFee = pynthLoan.loanAmount.multiplyDecimalRound(issueFeeRate);
    }

    function _loanLifeSpan(PynthLoanStruct memory pynthLoan) private view returns (uint256 loanLifeSpanResult) {
        // Get time loan is open for, and if closed from the timeClosed
        bool loanClosed = pynthLoan.timeClosed > 0;
        // Calculate loan life span in seconds as (Now - Loan creation time)
        loanLifeSpanResult = loanClosed ? pynthLoan.timeClosed.sub(pynthLoan.timeCreated) : now.sub(pynthLoan.timeCreated);
    }

    /* ========== INTERNAL VIEWS ========== */

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function pynthpETH() internal view returns (IPynth) {
        return IPynth(requireAndGetAddress(CONTRACT_PYNTHPETH));
    }

    function pynthpUSD() internal view returns (IPynth) {
        return IPynth(requireAndGetAddress(CONTRACT_PYNTHPUSD));
    }

    function depot() internal view returns (IDepot) {
        return IDepot(requireAndGetAddress(CONTRACT_DEPOT));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    /* ========== MODIFIERS ========== */

    modifier pETHRateNotInvalid() {
        require(!exchangeRates().rateIsInvalid("pETH"), "Blocked as pETH rate is invalid");
        _;
    }

    // ========== EVENTS ==========

    event CollateralizationRatioUpdated(uint256 ratio);
    event InterestRateUpdated(uint256 interestRate);
    event IssueFeeRateUpdated(uint256 issueFeeRate);
    event IssueLimitUpdated(uint256 issueLimit);
    event MinLoanSizeUpdated(uint256 minLoanSize);
    event AccountLoanLimitUpdated(uint256 loanLimit);
    event LoanLiquidationOpenUpdated(bool loanLiquidationOpen);
    event LoanCreated(address indexed account, uint256 loanID, uint256 amount);
    event LoanClosed(address indexed account, uint256 loanID, uint256 feesPaid);
    event LoanLiquidated(address indexed account, uint256 loanID, address liquidator);
}