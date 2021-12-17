/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: CollateralManager.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/CollateralManager.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/CollateralManager
*
* Contract Dependencies: 
*	- IAddressResolver
*	- ICollateralManager
*	- MixinResolver
*	- Owned
*	- Pausable
*	- State
* Libraries: 
*	- AddressSetLib
*	- Bytes32SetLib
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

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuablePynths(address issuer) external view returns (uint maxIssuable);

    function externalTokenQuota(
        address _account,
        uint _addtionalpUSD,
        uint _addtionalExToken,
        bool _isIssue
    ) external view returns (uint);

    function remainingIssuablePynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function pynths(bytes32 currencyKey) external view returns (IPynth);

    function getPynths(bytes32[] calldata currencyKeys) external view returns (IPynth[] memory);

    function pynthsByAddress(address pynthAddress) external view returns (bytes32);

    function totalIssuedPynths(bytes32 currencyKey, bool excludeEtherCollateral) external view returns (uint, bool);

    function transferablePeriFinanceAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    function amountsToFitClaimable(address _account) external view returns (uint burnAmount, uint exTokenAmountToUnstake);

    // Restricted: used internally to PeriFinance
    function issuePynths(
        address _issuer,
        bytes32 _currencyKey,
        uint _issueAmount
    ) external;

    function issueMaxPynths(address _issuer) external;

    function issuePynthsToMaxQuota(address _issuer, bytes32 _currencyKey) external;

    function burnPynths(
        address _from,
        bytes32 _currencyKey,
        uint _burnAmount
    ) external;

    function fitToClaimable(address _from) external;

    function exit(address _from) external;

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


interface ICollateralManager {
    // Manager information
    function hasCollateral(address collateral) external view returns (bool);

    function isPynthManaged(bytes32 currencyKey) external view returns (bool);

    // State information
    function long(bytes32 pynth) external view returns (uint amount);

    function short(bytes32 pynth) external view returns (uint amount);

    function totalLong() external view returns (uint pusdValue, bool anyRateIsInvalid);

    function totalShort() external view returns (uint pusdValue, bool anyRateIsInvalid);

    function getBorrowRate() external view returns (uint borrowRate, bool anyRateIsInvalid);

    function getShortRate(bytes32 pynth) external view returns (uint shortRate, bool rateIsInvalid);

    function getRatesAndTime(uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        );

    function getShortRatesAndTime(bytes32 currency, uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        );

    function exceedsDebtLimit(uint amount, bytes32 currency) external view returns (bool canIssue, bool anyRateIsInvalid);

    function arePynthsAndCurrenciesSet(bytes32[] calldata requiredPynthNamesInResolver, bytes32[] calldata pynthKeys)
        external
        view
        returns (bool);

    function areShortablePynthsSet(bytes32[] calldata requiredPynthNamesInResolver, bytes32[] calldata pynthKeys)
        external
        view
        returns (bool);

    // Loans
    function getNewLoanId() external returns (uint id);

    // Manager mutative
    function addCollaterals(address[] calldata collaterals) external;

    function removeCollaterals(address[] calldata collaterals) external;

    function addPynths(bytes32[] calldata pynthNamesInResolver, bytes32[] calldata pynthKeys) external;

    function removePynths(bytes32[] calldata pynths, bytes32[] calldata pynthKeys) external;

    function addShortablePynths(bytes32[2][] calldata requiredPynthAndInverseNamesInResolver, bytes32[] calldata pynthKeys)
        external;

    function removeShortablePynths(bytes32[] calldata pynths) external;

    // State mutative
    function updateBorrowRates(uint rate) external;

    function updateShortRates(bytes32 currency, uint rate) external;

    function incrementLongs(bytes32 pynth, uint amount) external;

    function decrementLongs(bytes32 pynth, uint amount) external;

    function incrementShorts(bytes32 pynth, uint amount) external;

    function decrementShorts(bytes32 pynth, uint amount) external;
}


// https://docs.peri.finance/contracts/source/libraries/addresssetlib/
library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}


// https://docs.peri.finance/contracts/source/libraries/bytes32setlib/
library Bytes32SetLib {
    struct Bytes32Set {
        bytes32[] elements;
        mapping(bytes32 => uint) indices;
    }

    function contains(Bytes32Set storage set, bytes32 candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        Bytes32Set storage set,
        uint index,
        uint pageSize
    ) internal view returns (bytes32[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new bytes32[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        bytes32[] memory page = new bytes32[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(Bytes32Set storage set, bytes32 element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(Bytes32Set storage set, bytes32 element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            bytes32 shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
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

    /**
     * @dev Round up the value with given number
     */
    function roundUpDecimal(uint x, uint d) internal pure returns (uint) {
        uint _decimal = 10**d;

        if (x % _decimal > 0) {
            x = x.add(10**d);
        }

        return x.div(_decimal).mul(_decimal);
    }
}


// Inheritance


// https://docs.peri.finance/contracts/source/contracts/state
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}


pragma experimental ABIEncoderV2;

// Inheritance


// Libraries


contract CollateralManagerState is Owned, State {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    struct Balance {
        uint long;
        uint short;
    }

    uint public totalLoans;

    uint[] public borrowRates;
    uint public borrowRatesLastUpdated;

    mapping(bytes32 => uint[]) public shortRates;
    mapping(bytes32 => uint) public shortRatesLastUpdated;

    // The total amount of long and short for a pynth,
    mapping(bytes32 => Balance) public totalIssuedPynths;

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {
        borrowRates.push(0);
        borrowRatesLastUpdated = block.timestamp;
    }

    function incrementTotalLoans() external onlyAssociatedContract returns (uint) {
        totalLoans = totalLoans.add(1);
        return totalLoans;
    }

    function long(bytes32 pynth) external view onlyAssociatedContract returns (uint) {
        return totalIssuedPynths[pynth].long;
    }

    function short(bytes32 pynth) external view onlyAssociatedContract returns (uint) {
        return totalIssuedPynths[pynth].short;
    }

    function incrementLongs(bytes32 pynth, uint256 amount) external onlyAssociatedContract {
        totalIssuedPynths[pynth].long = totalIssuedPynths[pynth].long.add(amount);
    }

    function decrementLongs(bytes32 pynth, uint256 amount) external onlyAssociatedContract {
        totalIssuedPynths[pynth].long = totalIssuedPynths[pynth].long.sub(amount);
    }

    function incrementShorts(bytes32 pynth, uint256 amount) external onlyAssociatedContract {
        totalIssuedPynths[pynth].short = totalIssuedPynths[pynth].short.add(amount);
    }

    function decrementShorts(bytes32 pynth, uint256 amount) external onlyAssociatedContract {
        totalIssuedPynths[pynth].short = totalIssuedPynths[pynth].short.sub(amount);
    }

    // Borrow rates, one array here for all currencies.

    function getRateAt(uint index) public view returns (uint) {
        return borrowRates[index];
    }

    function getRatesLength() public view returns (uint) {
        return borrowRates.length;
    }

    function updateBorrowRates(uint rate) external onlyAssociatedContract {
        borrowRates.push(rate);
        borrowRatesLastUpdated = block.timestamp;
    }

    function ratesLastUpdated() public view returns (uint) {
        return borrowRatesLastUpdated;
    }

    function getRatesAndTime(uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        )
    {
        newIndex = getRatesLength();
        entryRate = getRateAt(index);
        lastRate = getRateAt(newIndex - 1);
        lastUpdated = ratesLastUpdated();
    }

    // Short rates, one array per currency.

    function addShortCurrency(bytes32 currency) external onlyAssociatedContract {
        if (shortRates[currency].length > 0) {} else {
            shortRates[currency].push(0);
            shortRatesLastUpdated[currency] = block.timestamp;
        }
    }

    function removeShortCurrency(bytes32 currency) external onlyAssociatedContract {
        delete shortRates[currency];
    }

    function getShortRateAt(bytes32 currency, uint index) internal view returns (uint) {
        return shortRates[currency][index];
    }

    function getShortRatesLength(bytes32 currency) public view returns (uint) {
        return shortRates[currency].length;
    }

    function updateShortRates(bytes32 currency, uint rate) external onlyAssociatedContract {
        shortRates[currency].push(rate);
        shortRatesLastUpdated[currency] = block.timestamp;
    }

    function shortRateLastUpdated(bytes32 currency) internal view returns (uint) {
        return shortRatesLastUpdated[currency];
    }

    function getShortRatesAndTime(bytes32 currency, uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        )
    {
        newIndex = getShortRatesLength(currency);
        entryRate = getShortRateAt(currency, index);
        lastRate = getShortRateAt(currency, newIndex - 1);
        lastUpdated = shortRateLastUpdated(currency);
    }
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


// Inheritance


// Libraries


// Internal references


contract CollateralManager is ICollateralManager, Owned, Pausable, MixinResolver {
    /* ========== LIBRARIES ========== */
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;
    using Bytes32SetLib for Bytes32SetLib.Bytes32Set;

    /* ========== CONSTANTS ========== */

    bytes32 private constant pUSD = "pUSD";

    uint private constant SECONDS_IN_A_YEAR = 31556926 * 1e18;

    // Flexible storage names
    bytes32 public constant CONTRACT_NAME = "CollateralManager";
    bytes32 internal constant COLLATERAL_PYNTHS = "collateralPynth";

    /* ========== STATE VARIABLES ========== */

    // Stores debt balances and borrow rates.
    CollateralManagerState public state;

    // The set of all collateral contracts.
    AddressSetLib.AddressSet internal _collaterals;

    // The set of all pynths issuable by the various collateral contracts
    Bytes32SetLib.Bytes32Set internal _pynths;

    // Map from currency key to pynth contract name.
    mapping(bytes32 => bytes32) public pynthsByKey;

    // The set of all pynths that are shortable.
    Bytes32SetLib.Bytes32Set internal _shortablePynths;

    mapping(bytes32 => bytes32) public pynthToInversePynth;

    // The factor that will scale the utilisation ratio.
    uint public utilisationMultiplier = 1e18;

    // The maximum amount of debt in pUSD that can be issued by non peri collateral.
    uint public maxDebt;

    // The base interest rate applied to all borrows.
    uint public baseBorrowRate;

    // The base interest rate applied to all shorts.
    uint public baseShortRate;

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    bytes32[24] private addressesToCache = [CONTRACT_ISSUER, CONTRACT_EXRATES];

    /* ========== CONSTRUCTOR ========== */
    constructor(
        CollateralManagerState _state,
        address _owner,
        address _resolver,
        uint _maxDebt,
        uint _baseBorrowRate,
        uint _baseShortRate
    ) public Owned(_owner) Pausable() MixinResolver(_resolver) {
        owner = msg.sender;
        state = _state;

        setMaxDebt(_maxDebt);
        setBaseBorrowRate(_baseBorrowRate);
        setBaseShortRate(_baseShortRate);

        owner = _owner;
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory staticAddresses = new bytes32[](2);
        staticAddresses[0] = CONTRACT_ISSUER;
        staticAddresses[1] = CONTRACT_EXRATES;

        // we want to cache the name of the pynth and the name of its corresponding iPynth
        bytes32[] memory shortAddresses;
        uint length = _shortablePynths.elements.length;

        if (length > 0) {
            shortAddresses = new bytes32[](length * 2);

            for (uint i = 0; i < length; i++) {
                shortAddresses[i] = _shortablePynths.elements[i];
                shortAddresses[i + length] = pynthToInversePynth[_shortablePynths.elements[i]];
            }
        }

        bytes32[] memory pynthAddresses = combineArrays(shortAddresses, _pynths.elements);

        if (pynthAddresses.length > 0) {
            addresses = combineArrays(pynthAddresses, staticAddresses);
        } else {
            addresses = staticAddresses;
        }
    }

    // helper function to check whether pynth "by key" is a collateral issued by multi-collateral
    function isPynthManaged(bytes32 currencyKey) external view returns (bool) {
        return pynthsByKey[currencyKey] != bytes32(0);
    }

    /* ---------- Related Contracts ---------- */

    function _issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function _pynth(bytes32 pynthName) internal view returns (IPynth) {
        return IPynth(requireAndGetAddress(pynthName));
    }

    /* ---------- Manager Information ---------- */

    function hasCollateral(address collateral) public view returns (bool) {
        return _collaterals.contains(collateral);
    }

    function hasAllCollaterals(address[] memory collaterals) public view returns (bool) {
        for (uint i = 0; i < collaterals.length; i++) {
            if (!hasCollateral(collaterals[i])) {
                return false;
            }
        }
        return true;
    }

    /* ---------- State Information ---------- */

    function long(bytes32 pynth) external view returns (uint amount) {
        return state.long(pynth);
    }

    function short(bytes32 pynth) external view returns (uint amount) {
        return state.short(pynth);
    }

    function totalLong() public view returns (uint pusdValue, bool anyRateIsInvalid) {
        bytes32[] memory pynths = _pynths.elements;

        if (pynths.length > 0) {
            for (uint i = 0; i < pynths.length; i++) {
                bytes32 pynth = _pynth(pynths[i]).currencyKey();
                if (pynth == pUSD) {
                    pusdValue = pusdValue.add(state.long(pynth));
                } else {
                    (uint rate, bool invalid) = _exchangeRates().rateAndInvalid(pynth);
                    uint amount = state.long(pynth).multiplyDecimal(rate);
                    pusdValue = pusdValue.add(amount);
                    if (invalid) {
                        anyRateIsInvalid = true;
                    }
                }
            }
        }
    }

    function totalShort() public view returns (uint pusdValue, bool anyRateIsInvalid) {
        bytes32[] memory pynths = _shortablePynths.elements;

        if (pynths.length > 0) {
            for (uint i = 0; i < pynths.length; i++) {
                bytes32 pynth = _pynth(pynths[i]).currencyKey();
                (uint rate, bool invalid) = _exchangeRates().rateAndInvalid(pynth);
                uint amount = state.short(pynth).multiplyDecimal(rate);
                pusdValue = pusdValue.add(amount);
                if (invalid) {
                    anyRateIsInvalid = true;
                }
            }
        }
    }

    function getBorrowRate() external view returns (uint borrowRate, bool anyRateIsInvalid) {
        // get the peri backed debt.
        (uint periDebt, ) = _issuer().totalIssuedPynths(pUSD, true);

        // now get the non peri backed debt.
        (uint nonPeriDebt, bool ratesInvalid) = totalLong();

        // the total.
        uint totalDebt = periDebt.add(nonPeriDebt);

        // now work out the utilisation ratio, and divide through to get a per second value.
        uint utilisation = nonPeriDebt.divideDecimal(totalDebt).divideDecimal(SECONDS_IN_A_YEAR);

        // scale it by the utilisation multiplier.
        uint scaledUtilisation = utilisation.multiplyDecimal(utilisationMultiplier);

        // finally, add the base borrow rate.
        borrowRate = scaledUtilisation.add(baseBorrowRate);

        anyRateIsInvalid = ratesInvalid;
    }

    function getShortRate(bytes32 pynth) external view returns (uint shortRate, bool rateIsInvalid) {
        bytes32 pynthKey = _pynth(pynth).currencyKey();

        rateIsInvalid = _exchangeRates().rateIsInvalid(pynthKey);

        // get the spot supply of the pynth, its iPynth
        uint longSupply = IERC20(address(_pynth(pynth))).totalSupply();
        uint inverseSupply = IERC20(address(_pynth(pynthToInversePynth[pynth]))).totalSupply();
        // add the iPynth to supply properly reflect the market skew.
        uint shortSupply = state.short(pynthKey).add(inverseSupply);

        // in this case, the market is skewed long so its free to short.
        if (longSupply > shortSupply) {
            return (0, rateIsInvalid);
        }

        // otherwise workout the skew towards the short side.
        uint skew = shortSupply.sub(longSupply);

        // divide through by the size of the market
        uint proportionalSkew = skew.divideDecimal(longSupply.add(shortSupply)).divideDecimal(SECONDS_IN_A_YEAR);

        // finally, add the base short rate.
        shortRate = proportionalSkew.add(baseShortRate);
    }

    function getRatesAndTime(uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        )
    {
        (entryRate, lastRate, lastUpdated, newIndex) = state.getRatesAndTime(index);
    }

    function getShortRatesAndTime(bytes32 currency, uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        )
    {
        (entryRate, lastRate, lastUpdated, newIndex) = state.getShortRatesAndTime(currency, index);
    }

    function exceedsDebtLimit(uint amount, bytes32 currency) external view returns (bool canIssue, bool anyRateIsInvalid) {
        uint usdAmount = _exchangeRates().effectiveValue(currency, amount, pUSD);

        (uint longValue, bool longInvalid) = totalLong();
        (uint shortValue, bool shortInvalid) = totalShort();

        anyRateIsInvalid = longInvalid || shortInvalid;

        return (longValue.add(shortValue).add(usdAmount) <= maxDebt, anyRateIsInvalid);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- SETTERS ---------- */

    function setUtilisationMultiplier(uint _utilisationMultiplier) public onlyOwner {
        require(_utilisationMultiplier > 0, "Must be greater than 0");
        utilisationMultiplier = _utilisationMultiplier;
    }

    function setMaxDebt(uint _maxDebt) public onlyOwner {
        require(_maxDebt > 0, "Must be greater than 0");
        maxDebt = _maxDebt;
        emit MaxDebtUpdated(maxDebt);
    }

    function setBaseBorrowRate(uint _baseBorrowRate) public onlyOwner {
        baseBorrowRate = _baseBorrowRate;
        emit BaseBorrowRateUpdated(baseBorrowRate);
    }

    function setBaseShortRate(uint _baseShortRate) public onlyOwner {
        baseShortRate = _baseShortRate;
        emit BaseShortRateUpdated(baseShortRate);
    }

    /* ---------- LOANS ---------- */

    function getNewLoanId() external onlyCollateral returns (uint id) {
        id = state.incrementTotalLoans();
    }

    /* ---------- MANAGER ---------- */

    function addCollaterals(address[] calldata collaterals) external onlyOwner {
        for (uint i = 0; i < collaterals.length; i++) {
            if (!_collaterals.contains(collaterals[i])) {
                _collaterals.add(collaterals[i]);
                emit CollateralAdded(collaterals[i]);
            }
        }
    }

    function removeCollaterals(address[] calldata collaterals) external onlyOwner {
        for (uint i = 0; i < collaterals.length; i++) {
            if (_collaterals.contains(collaterals[i])) {
                _collaterals.remove(collaterals[i]);
                emit CollateralRemoved(collaterals[i]);
            }
        }
    }

    function addPynths(bytes32[] calldata pynthNamesInResolver, bytes32[] calldata pynthKeys) external onlyOwner {
        for (uint i = 0; i < pynthNamesInResolver.length; i++) {
            if (!_pynths.contains(pynthNamesInResolver[i])) {
                bytes32 pynthName = pynthNamesInResolver[i];
                _pynths.add(pynthName);
                pynthsByKey[pynthKeys[i]] = pynthName;
                emit PynthAdded(pynthName);
            }
        }
    }

    function arePynthsAndCurrenciesSet(bytes32[] calldata requiredPynthNamesInResolver, bytes32[] calldata pynthKeys)
        external
        view
        returns (bool)
    {
        if (_pynths.elements.length != requiredPynthNamesInResolver.length) {
            return false;
        }

        for (uint i = 0; i < requiredPynthNamesInResolver.length; i++) {
            if (!_pynths.contains(requiredPynthNamesInResolver[i])) {
                return false;
            }
            if (pynthsByKey[pynthKeys[i]] != requiredPynthNamesInResolver[i]) {
                return false;
            }
        }

        return true;
    }

    function removePynths(bytes32[] calldata pynths, bytes32[] calldata pynthKeys) external onlyOwner {
        for (uint i = 0; i < pynths.length; i++) {
            if (_pynths.contains(pynths[i])) {
                // Remove it from the the address set lib.
                _pynths.remove(pynths[i]);
                delete pynthsByKey[pynthKeys[i]];

                emit PynthRemoved(pynths[i]);
            }
        }
    }

    // When we add a shortable pynth, we need to know the iPynth as well
    // This is so we can get the proper skew for the short rate.
    function addShortablePynths(bytes32[2][] calldata requiredPynthAndInverseNamesInResolver, bytes32[] calldata pynthKeys)
        external
        onlyOwner
    {
        require(requiredPynthAndInverseNamesInResolver.length == pynthKeys.length, "Input array length mismatch");

        for (uint i = 0; i < requiredPynthAndInverseNamesInResolver.length; i++) {
            // setting these explicitly for clarity
            // Each entry in the array is [Pynth, iPynth]
            bytes32 pynth = requiredPynthAndInverseNamesInResolver[i][0];
            bytes32 iPynth = requiredPynthAndInverseNamesInResolver[i][1];

            if (!_shortablePynths.contains(pynth)) {
                // Add it to the address set lib.
                _shortablePynths.add(pynth);

                // store the mapping to the iPynth so we can get its total supply for the borrow rate.
                pynthToInversePynth[pynth] = iPynth;

                emit ShortablePynthAdded(pynth);

                // now the associated pynth key to the CollateralManagerState
                state.addShortCurrency(pynthKeys[i]);
            }
        }

        rebuildCache();
    }

    function areShortablePynthsSet(bytes32[] calldata requiredPynthNamesInResolver, bytes32[] calldata pynthKeys)
        external
        view
        returns (bool)
    {
        require(requiredPynthNamesInResolver.length == pynthKeys.length, "Input array length mismatch");

        if (_shortablePynths.elements.length != requiredPynthNamesInResolver.length) {
            return false;
        }

        // first check contract state
        for (uint i = 0; i < requiredPynthNamesInResolver.length; i++) {
            bytes32 pynthName = requiredPynthNamesInResolver[i];
            if (!_shortablePynths.contains(pynthName) || pynthToInversePynth[pynthName] == bytes32(0)) {
                return false;
            }
        }

        // now check everything added to external state contract
        for (uint i = 0; i < pynthKeys.length; i++) {
            if (state.getShortRatesLength(pynthKeys[i]) == 0) {
                return false;
            }
        }

        return true;
    }

    function removeShortablePynths(bytes32[] calldata pynths) external onlyOwner {
        for (uint i = 0; i < pynths.length; i++) {
            if (_shortablePynths.contains(pynths[i])) {
                // Remove it from the the address set lib.
                _shortablePynths.remove(pynths[i]);

                bytes32 pynthKey = _pynth(pynths[i]).currencyKey();

                state.removeShortCurrency(pynthKey);

                // remove the inverse mapping.
                delete pynthToInversePynth[pynths[i]];

                emit ShortablePynthRemoved(pynths[i]);
            }
        }
    }

    /* ---------- STATE MUTATIONS ---------- */

    function updateBorrowRates(uint rate) external onlyCollateral {
        state.updateBorrowRates(rate);
    }

    function updateShortRates(bytes32 currency, uint rate) external onlyCollateral {
        state.updateShortRates(currency, rate);
    }

    function incrementLongs(bytes32 pynth, uint amount) external onlyCollateral {
        state.incrementLongs(pynth, amount);
    }

    function decrementLongs(bytes32 pynth, uint amount) external onlyCollateral {
        state.decrementLongs(pynth, amount);
    }

    function incrementShorts(bytes32 pynth, uint amount) external onlyCollateral {
        state.incrementShorts(pynth, amount);
    }

    function decrementShorts(bytes32 pynth, uint amount) external onlyCollateral {
        state.decrementShorts(pynth, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyCollateral {
        bool isMultiCollateral = hasCollateral(msg.sender);

        require(isMultiCollateral, "Only collateral contracts");
        _;
    }

    // ========== EVENTS ==========
    event MaxDebtUpdated(uint maxDebt);
    event LiquidationPenaltyUpdated(uint liquidationPenalty);
    event BaseBorrowRateUpdated(uint baseBorrowRate);
    event BaseShortRateUpdated(uint baseShortRate);

    event CollateralAdded(address collateral);
    event CollateralRemoved(address collateral);

    event PynthAdded(bytes32 pynth);
    event PynthRemoved(bytes32 pynth);

    event ShortablePynthAdded(bytes32 pynth);
    event ShortablePynthRemoved(bytes32 pynth);
}