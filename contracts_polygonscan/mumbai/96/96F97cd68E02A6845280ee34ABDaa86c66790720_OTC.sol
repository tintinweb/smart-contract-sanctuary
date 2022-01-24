/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

/*

* DEMAA: OTC.sol
*
* Latest source (may be newer): https://github.com/demaa-team/synthetix/blob/master/contracts/OTC.sol
* Docs: https://docs.synthetix.io/contracts/OTC
*
* Contract Dependencies: 
*	- IAddressResolver
*	- IOTC
*	- MixinResolver
*	- Owned
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2022 DEMAA
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


// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
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


// https://docs.synthetix.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableSynthetixAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Synthetix
    function issueSynths(address from, uint amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint balance
    ) external;

    function liquidateDelinquentAccount(
        address account,
        uint susdAmount,
        address liquidator
    ) external returns (uint totalRedeemed, uint amountToLiquidate);
}


// Inheritance


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/addressresolver
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

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
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


interface IOTC {
    enum DealState {Confirming, Cancelled, Confirmed, Adjudicated}

    //Personal profile
    function registerProfile(string calldata ipfsHash) external;

    function updateProfile(string calldata ipfsHash) external;

    function destroyProfile() external;

    function hasProfile(address user) external view returns (bool);

    function getProfileHash(address user) external view returns (string memory ipfsHash);

    //Order
    function openOrder(
        bytes32 coinCode,
        bytes32 currencyCode,
        uint256 price,
        uint256 amount
    ) external;

    function closeOrder() external;

    function hasOrder(address maker) external view returns (bool);

    function updateOrder(uint256 price, uint256 amount) external;

    function updatePrice(uint256 price) external;

    function increaseAmount(uint256 amount) external;

    function decreaseAmount(uint256 amount) external;

    //Deal
    function makeDeal(
        address maker,
        uint256 amount,
        bytes32 collateralType
    ) external;

    function cancelDeal(uint256 dealID) external returns (bool);

    function confirmDeal(uint256 dealID) external returns (bool);

    function redeemCollateral(uint256 dealID) external;

    function hasDeal(uint256 dealID) external view returns (bool);

    function migrate(bytes32[] calldata coinCodes, address newOTC) external;

    function addAsset(bytes32[] calldata coinCodes, IERC20[] calldata contracts) external;

    function removeAsset(bytes32 assetKey) external;

    function getDealInfo(uint256 dealID)
        external
        view
        returns (
            bool,
            address,
            address
        );

    function isDealExpired(uint256 dealID) external view returns (bool);

    function isDealClosed(uint256 dealID) external view returns (bool);

    function adjudicateDeal(
        uint256 dealID,
        address complainant,
        uint256 compensationRatio
    ) external;

    event RegisterProfile(address indexed from, string ipfsHash);
    event UpdateProfile(address indexed from, string ipfsHash);
    event DestroyProfile(address indexed from);

    event OpenOrder(address indexed from, uint256 orderID);
    event CloseOrder(address indexed from, uint256 orderID);
    event UpdateOrder(address indexed from, uint256 orderID);
    event UpdateDeal(address indexed maker, address indexed taker, uint256 dealID, DealState dealState);

    event AdjudicateDeal(address from, uint256 deal);
}


interface IOTCDao {
    enum AdjudicationState {Applied, Responded, Adjudicated}
    enum ListAction {Added, Updated, Removed}

    function addToVerifyList(address who) external;

    function removeFromVerifyList(address who) external;

    function addToBlackList(address who) external;

    function removeFromBlackList(address who) external;

    function isInVerifyList(address who) external view returns (bool);

    function needCollateral(address who) external view returns (bool);

    function useOneChance(address who) external;

    function isInBlackList(address who) external view returns (bool);

    event UpdateVerifiedList(address indexed from, address indexed who, ListAction action);
    event UpdateBlackList(address indexed from, address indexed who, ListAction action);
    event UpdateViolationCount(address indexed from, address indexed who);
    event UpdateAdjudication(address indexed from, uint256 adjudicationID);
}


// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
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

    function totalIssuedSynthsExcludeOtherCollateral(bytes32 currencyKey) external view returns (uint);

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
    function liquidateDelinquentAccount(address account, uint susdAmount) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}


// Inheritance


// Libraries


// Internal references


contract OTC is MixinResolver, IOTC, Owned {
    /* ========== LIBRARIES ========== */
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    struct Deal {
        // underlying asset key
        bytes32 coinCode;
        // trade partener code
        bytes32 currencyCode;
        // a increasement number for 0
        uint256 dealID;
        // order id
        uint256 orderID;
        // deal price
        uint256 price;
        // deal amount
        uint256 amount;
        // fees charged from taker
        uint256 fee;
        // time when deal created or updated
        uint256 cTime;
        uint256 uTime;
        // record maker and taker
        address maker;
        address taker;
        // deal state
        DealState dealState;
    }

    struct DealCollateral {
        // collateral type ETH/USDT/
        bytes32 collateralType;
        // locked amount
        uint256 lockedAmount;
        // collateral for make this deal
        uint256 collateral;
    }

    // User profile
    struct Profile {
        // Hash point to the address in ipfs where user profile sotred
        string ipfsHash;
        // timestapm when order created
        uint256 cTime;
        uint256 uTime;
    }

    struct Order {
        // exange coin
        bytes32 coinCode;
        // trade partener code
        bytes32 currencyCode;
        // uinique order id
        uint256 orderID;
        // Price of order
        uint256 price;
        // Left usdt amount not been selled
        uint256 leftAmount;
        // locked amount
        uint256 lockedAmount;
        // timestapm when order created
        uint256 cTime;
        uint256 uTime;
    }

    // profile table
    mapping(address => Profile) public profiles;
    // order table
    mapping(address => Order) public orders;
    // deal table
    mapping(uint256 => Deal) public deals;
    // deal Collateral info
    mapping(uint256 => DealCollateral) public dealCollaterals;
    // underlying assetst for otc supported
    mapping(bytes32 => IERC20) public underlyingAssets;
    uint256 public underlyingAssetsCount;
    // count users
    uint256 public userCount;
    // an incresement number used for generating order id
    uint256 public orderCount;
    // an incresement number used for generating deal id
    uint256 public dealCount;
    // collater forzen period before taker redeem collateral
    // only have valid vaule when has reward schdule
    uint256 public dealFrozenPeriod;
    // collateral ration 20%
    uint256 public takerCRatio = 200000000000000000;
    uint256 public makerCRatio = 200000000000000000;
    // fee ratio charged on taker, normal 0.3%
    uint256 public feeRatio = 0.003 ether;
    uint256 public minTradeAmount = 50 * 1e18;
    uint256 public maxTradeAmountForVerified = 1000 * 1e18;
    // deal expired period before confimred
    uint256 public dealExpiredPeriod = 1 hours;
    // fee pool wallet
    address payable public treasuryWallet;

    bytes32 private constant DEM = "DEM";
    bytes32 private constant sUSD = "sUSD";
    bytes32 private constant USDT = "USDT";
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_OTCDao = "OTCDao";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_SYNTHETIX;
        addresses[1] = CONTRACT_EXRATES;
        addresses[2] = CONTRACT_OTCDao;
    }

    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function synthetixERC20() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function otcDao() internal view returns (IOTCDao) {
        return IOTCDao(requireAndGetAddress(CONTRACT_OTCDao));
    }

    function erc20(bytes32 coinCode) public view returns (IERC20) {
        IERC20 asset = underlyingAssets[coinCode];
        require(address(0) != address(asset), "Invalid underlying asset!");
        return IERC20(asset);
    }

    function setTreasuryWallet(address payable _treasuryWallet) public onlyOwner {
        require(address(0) != _treasuryWallet, "Invalid treasury wallet address!");
        treasuryWallet = _treasuryWallet;
    }

    function addAsset(bytes32[] memory coinCodes, IERC20[] memory contracts) public onlyOwner {
        require(coinCodes.length == contracts.length, "Should have the same length!");
        for (uint256 i = 0; i < coinCodes.length; i++) {
            require(contracts[i] != IERC20(address(0)), "Invalid contract address!");
            underlyingAssets[coinCodes[i]] = contracts[i];
        }
        underlyingAssetsCount = coinCodes.length;
    }

    function removeAsset(bytes32 coinCode) public onlyOwner {
        delete underlyingAssets[coinCode];
        underlyingAssetsCount--;
    }

    function setTakerCRatio(uint256 cRatio) public onlyOwner {
        takerCRatio = cRatio;
    }

    function setMakerCRatio(uint256 cRatio) public onlyOwner {
        makerCRatio = cRatio;
    }

    function setMinTradeAmount(uint256 minAmount) public onlyOwner {
        minTradeAmount = minAmount;
    }

    function setDealFrozenPeriod(uint256 period) public onlyOwner {
        dealFrozenPeriod = period;
    }

    function setMaxTradeAmountForVerified(uint256 amount) public onlyOwner {
        maxTradeAmountForVerified = amount;
    }

    function setFeeRatio(uint256 ratio) public onlyOwner {
        feeRatio = ratio;
    }

    function setDealExpiredPeriod(uint256 period) public onlyOwner {
        dealExpiredPeriod = period;
    }

    function getDealInfo(uint256 dealID)
        public
        view
        dealExist(dealID)
        returns (
            bool,
            address,
            address
        )
    {
        return (true, deals[dealID].maker, deals[dealID].taker);
    }

    function isDealExpired(uint256 dealID) public view dealExist(dealID) returns (bool) {
        return ((deals[dealID].uTime + dealExpiredPeriod) <= block.timestamp);
    }

    function isDealClosed(uint256 dealID) public view dealExist(dealID) returns (bool) {
        return (deals[dealID].dealState != DealState.Confirming);
    }

    // Personal profile
    function registerProfile(string memory ipfsHash) public {
        require(!hasProfile(msg.sender), "Profile exist!");

        profiles[msg.sender] = Profile({ipfsHash: ipfsHash, cTime: block.timestamp, uTime: block.timestamp});

        emit RegisterProfile(msg.sender, ipfsHash);

        userCount++;
    }

    function destroyProfile() public profileExist() {
        delete profiles[msg.sender];

        emit DestroyProfile(msg.sender);

        userCount--;
    }

    function updateProfile(string memory ipfsHash) public profileExist() {
        profiles[msg.sender].ipfsHash = ipfsHash;
        profiles[msg.sender].uTime = block.timestamp;

        emit UpdateProfile(msg.sender, ipfsHash);
    }

    function hasProfile(address user) public view returns (bool) {
        return profiles[user].cTime > 0;
    }

    function getProfileHash(address user) external view profileExist() returns (string memory ipfsHash) {
        return profiles[user].ipfsHash;
    }

    function getUserCount() public view returns (uint256) {
        return userCount;
    }

    function migrate(bytes32[] memory assetKeys, address newOTC) public onlyOwner {
        revert("Not implemet!");
    }

    function maxExchangeableAsset(address maker) public view orderExist(maker) returns (uint256) {
        return exchangeableAsset(orders[maker].leftAmount, makerCRatio);
    }

    function exchangeableAsset(uint256 amount, uint256 ratio) public pure returns (uint256) {
        // exchangeable = amount /(1 + ratio)
        return amount.divideDecimalRound(SafeDecimalMath.unit().add(ratio));
    }

    function lockedAsset(uint256 amount, uint256 ratio) public pure returns (uint256) {
        // locked = amount * ratio
        return amount.multiplyDecimalRound(ratio);
    }

    function tradeFee(uint256 amount) public view returns (uint256) {
        return amount.multiplyDecimalRound(feeRatio);
    }

    // Order
    function openOrder(
        bytes32 coinCode,
        bytes32 currencyCode,
        uint256 price,
        uint256 amount
    ) public {
        require(hasProfile(msg.sender), "Profile dose not exist!");
        require(!hasOrder(msg.sender), "Order has exist!");
        require(!otcDao().isInBlackList(msg.sender), "User is in the blacklist!");

        IERC20 asset = erc20(coinCode);

        // delegate token to this
        asset.transferFrom(msg.sender, address(this), amount);

        // create order
        orders[msg.sender] = Order({
            coinCode: coinCode,
            currencyCode: currencyCode,
            orderID: orderCount,
            price: price,
            leftAmount: amount,
            lockedAmount: uint256(0),
            cTime: block.timestamp,
            uTime: block.timestamp
        });

        emit OpenOrder(msg.sender, orderCount);

        orderCount++;
    }

    function closeOrder() public profileExist() orderExist(msg.sender) {
        // check if has pending deal
        Order storage order = orders[msg.sender];
        require(order.lockedAmount == uint256(0), "Has pending deals!");

        // refund maker with left asset
        erc20(order.coinCode).transfer(msg.sender, order.leftAmount);

        uint256 orderID = orders[msg.sender].orderID;
        delete orders[msg.sender];
        emit CloseOrder(msg.sender, orderID);
    }

    function hasOrder(address maker) public view returns (bool) {
        return orders[maker].cTime > 0;
    }

    function updateOrder(uint256 price, uint256 amount) public orderExist(msg.sender) {
        orders[msg.sender].price = price;
        orders[msg.sender].leftAmount = amount;

        _updateOrder(msg.sender);
    }

    function _updateOrder(address user) internal {
        orders[user].uTime = block.timestamp;
        emit UpdateOrder(user, orders[user].orderID);
    }

    function updatePrice(uint256 price) public orderExist(msg.sender) {
        orders[msg.sender].price = price;

        _updateOrder(msg.sender);
    }

    function increaseAmount(uint256 amount) public orderExist(msg.sender) {
        require(amount > 0, "Increase amount should gt than 0!");

        Order storage order = orders[msg.sender];
        order.leftAmount = order.leftAmount.add(amount);

        _updateOrder(msg.sender);

        erc20(order.coinCode).transferFrom(msg.sender, address(this), amount);
    }

    function decreaseAmount(uint256 amount) public orderExist(msg.sender) {
        require(amount > 0, "Decrease amount should gt than 0!");

        Order storage order = orders[msg.sender];
        require(order.leftAmount >= amount, "Left amount is insufficient!");
        order.leftAmount = order.leftAmount.sub(amount);
        _updateOrder(msg.sender);

        // send back assets to user
        erc20(order.coinCode).transfer(msg.sender, amount);
    }

    function hasDeal(uint256 dealID) public view returns (bool) {
        return deals[dealID].cTime > 0;
    }

    function makeDeal(
        address maker,
        uint256 amount,
        bytes32 collateralType
    ) public {
        uint256 collateral = 0;

        // verifed user dose not need collateral
        if (otcDao().needCollateral(msg.sender)) {
            collateral = amount;
            if (sUSD != collateralType && USDT != collateralType) {
                // caculate required collateral amount
                collateral = exchangeRates().effectiveValue(sUSD, amount, collateralType);
            }
            collateral = lockedAsset(collateral, takerCRatio);

            // delegate collateral to frozen
            erc20(collateralType).transferFrom(msg.sender, address(this), collateral);
        } else {
            // recorde user has used one no collateral chance
            otcDao().useOneChance(msg.sender);
        }

        _makeDeal(maker, amount, collateralType, collateral);
    }

    //Deal
    function _makeDeal(
        address maker,
        uint256 amount,
        bytes32 collateralType,
        uint256 collateral
    ) internal returns (uint256) {
        // check order
        require(hasOrder(maker), "Maker has no active order!");

        // check traders
        require(msg.sender != maker, "Can not trade with self!");

        IOTCDao dao = otcDao();

        // check if deal taker is disallowed for trading
        require(!dao.isInBlackList(msg.sender), "Taker is disallowed for tradding!");

        // check min deal amount
        require(amount >= minTradeAmount, "Trade amount less than min!");

        // verified taker only make no more than maxTradeAmountForVerified
        if (dao.isInVerifyList(msg.sender) && amount > maxTradeAmountForVerified) {
            amount = maxTradeAmountForVerified;
        }

        // check exchange able set
        Order storage order = orders[maker];
        uint256 maxExangeableAsset = exchangeableAsset(order.leftAmount, makerCRatio);
        require(maxExangeableAsset >= amount, "Amount exceed order max excangeable!");
        uint256 lockedAmount = lockedAsset(amount, makerCRatio);
        order.leftAmount = order.leftAmount.sub(amount.add(lockedAmount));
        order.lockedAmount = order.lockedAmount.add(lockedAmount);

        _updateOrder(maker);

        // make deal
        Deal memory deal =
            Deal({
                coinCode: order.coinCode,
                currencyCode: order.currencyCode,
                orderID: order.orderID,
                dealID: dealCount,
                price: order.price,
                amount: amount,
                fee: tradeFee(amount),
                cTime: block.timestamp,
                uTime: block.timestamp,
                maker: maker,
                taker: msg.sender,
                dealState: DealState.Confirming
            });
        DealCollateral memory dealCollateral =
            DealCollateral({lockedAmount: lockedAmount, collateral: collateral, collateralType: collateralType});
        deals[deal.dealID] = deal;
        dealCollaterals[deal.dealID] = dealCollateral;

        emit UpdateDeal(deal.maker, deal.taker, deal.dealID, deal.dealState);

        // increase deal count
        dealCount++;

        return deal.dealID;
    }

    function cancelDeal(uint256 dealID) public dealExist(dealID) returns (bool) {
        Deal storage deal = deals[dealID];

        require(msg.sender == deal.taker, "Only taker can cancel deal!");
        require(deal.dealState == DealState.Confirming, "Deal state should be confirming!");

        // refund maker and taker
        Order storage order = orders[deal.maker];
        DealCollateral storage dealCollateral = dealCollaterals[deal.dealID];
        order.leftAmount = order.leftAmount.add(deal.amount).add(dealCollateral.lockedAmount);
        order.lockedAmount = order.lockedAmount.sub(dealCollateral.lockedAmount);
        _updateOrder(deal.maker);

        deal.dealState = DealState.Cancelled;
        deal.uTime = block.timestamp;

        emit UpdateDeal(deal.maker, deal.taker, deal.dealID, deal.dealState);

        // transfer DEM back to taker
        // note: verified user has no collateral
        if (dealCollateral.collateral > 0) {
            erc20(dealCollateral.collateralType).transfer(deal.taker, dealCollateral.collateral);
        }

        return true;
    }

    function confirmDeal(uint256 dealID) public dealExist(dealID) returns (bool) {
        Deal storage deal = deals[dealID];
        require(deal.dealState == DealState.Confirming, "Deal should be confirming!");
        require(msg.sender == deal.maker, "Only maker can confirm deal!");

        // unlocker maker and transfer asset to taker
        Order storage order = orders[deal.maker];
        DealCollateral storage dealCollateral = dealCollaterals[deal.dealID];

        order.leftAmount = order.leftAmount.add(dealCollateral.lockedAmount);
        order.lockedAmount = order.lockedAmount.sub(dealCollateral.lockedAmount);
        _updateOrder(deal.maker);

        // mark deal confirmed
        deal.dealState = DealState.Confirmed;
        deal.uTime = block.timestamp;

        emit UpdateDeal(deal.maker, deal.taker, deal.dealID, deal.dealState);

        // transfer charged erc20 token to taker
        erc20(deal.coinCode).transfer(deal.taker, deal.amount.sub(deal.fee));

        // fund treasury
        if (deal.fee > 0) {
            erc20(deal.coinCode).transfer(treasuryWallet, deal.fee);
        }

        // trans back taker collateral if no reward schedule applyed
        if ((uint256(0) == dealFrozenPeriod) && dealCollateral.collateral > 0) {
            erc20(dealCollateral.collateralType).transfer(deal.taker, dealCollateral.collateral);
        }

        return true;
    }

    function adjudicateDeal(
        uint256 dealID,
        address complainant,
        uint256 compensationRatio
    ) public onlyOTCDao dealExist(dealID) {
        Deal storage deal = deals[dealID];
        DealCollateral storage dealCollateral = dealCollaterals[deal.dealID];

        require((deal.cTime + dealExpiredPeriod) <= block.timestamp, "Deal is valid for confirmation!");
        require(deal.dealState == DealState.Confirming, "Deal should be confirming!");

        // bad guys need be punished here
        // all collateral shall be taken away, part go to Treasury
        // reset will compensate victim
        Order storage order = orders[deal.maker];
        if (deal.maker == complainant) {
            IOTCDao dao = otcDao();

            // taker dose not confirmed intime
            if (0 == dealCollateral.collateral) {
                // taker has no collateral in the case we need to forbid the address trading for ever
                dao.addToBlackList(deal.taker);
            } else {
                // take away all collateral
                uint256 compensation = dealCollateral.collateral.multiplyDecimalRound(compensationRatio);
                // compensate taker
                if (compensation > 0) {
                    erc20(dealCollateral.collateralType).transfer(deal.maker, compensation);
                }
                // to Treasury
                erc20(dealCollateral.collateralType).transfer(treasuryWallet, dealCollateral.collateral.sub(compensation));
            }

            // refund maker
            order.leftAmount = order.leftAmount.add(deal.amount).add(dealCollateral.lockedAmount);
            order.lockedAmount = order.lockedAmount.sub(dealCollateral.lockedAmount);
        } else if (deal.taker == complainant) {
            // maker dose not confirm deal after receiving offline
            uint256 compensation = dealCollateral.lockedAmount.multiplyDecimalRound(compensationRatio);

            IERC20 asset = erc20(deal.coinCode);
            // fund taker with trade amount exclude fee +  compensation
            asset.transfer(deal.taker, deal.amount.sub(deal.fee).add(compensation));
            // fund treasury with trade compensation + fee
            asset.transfer(treasuryWallet, dealCollateral.lockedAmount.sub(compensation).add(deal.fee));
            // refund taker Collateral
            if ((uint256(0) == dealFrozenPeriod) && dealCollateral.collateral > 0) {
                erc20(dealCollateral.collateralType).transfer(deal.taker, dealCollateral.collateral);
            }
            // decrease locked assets
            order.lockedAmount = order.lockedAmount.sub(dealCollateral.lockedAmount);
        } else {
            revert("Invalid complainant!");
        }
        // update order
        _updateOrder(deal.maker);

        // update deal
        deal.uTime = block.timestamp;
        deal.dealState = DealState.Adjudicated;
        emit UpdateDeal(deal.maker, deal.taker, deal.dealID, deal.dealState);

        emit AdjudicateDeal(complainant, deal.dealID);
    }

    function redeemCollateral(uint256 dealID) public dealExist(dealID) {
        Deal storage deal = deals[dealID];

        require(deal.dealState == DealState.Confirmed, "Deal not confirmed!");
        require(deal.taker == msg.sender, "Only taker can redeem collateral!");
        require(uint256(0) != dealFrozenPeriod, "No collateral trans back!");
        require(deal.uTime + dealFrozenPeriod <= block.timestamp, "Frozen period dose not end!");

        // Transfer collateral back to taker if reward schedule applyed
        DealCollateral storage dealCollateral = dealCollaterals[deal.dealID];
        if (dealCollateral.collateral > 0) {
            erc20(dealCollateral.collateralType).transfer(deal.taker, dealCollateral.collateral);
        }
    }

    function leftFrozenTime(uint256 dealID) public view dealExist(dealID) returns (uint256) {
        Deal storage deal = deals[dealID];
        require(uint256(0) != dealFrozenPeriod, "No collateral trans back!");
        require(deal.dealState == DealState.Confirmed, "Deal not confirmed!");

        return (deal.uTime + dealFrozenPeriod <= block.timestamp ? 0 : (deal.uTime + dealFrozenPeriod - block.timestamp));
    }

    modifier onlyOTCDao {
        require(msg.sender == address(otcDao()), "Only OTC DAO contract can adjudicate deal!");
        _;
    }

    modifier profileExist() {
        require(hasProfile(msg.sender), "Profile dose not exist!");
        _;
    }

    modifier dealExist(uint256 dealID) {
        require(hasDeal(dealID), "Deal dose not exist!");
        _;
    }

    modifier orderExist(address user) {
        require(hasOrder(user), "Order dose not exist!");
        _;
    }
}