/**
 *Submitted for verification at hooscan.com on 2021-06-23
*/

/*                                            

* SystemSettings.sol
*
*/



pragma solidity ^0.5.16;


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
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


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

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeEtherCollateral) external view returns (uint);

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

    function liquidateDelinquentAccount(
        address account,
        uint susdAmount,
        address liquidator
    ) external returns (uint totalRedeemed, uint amountToLiquidate);
}


// Inheritance


contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            repository[names[i]] = destinations[i];
        }
    }

    /* ========== VIEWS ========== */

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
}


// Inheritance


// Internal references


contract MixinResolver is Owned {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    bytes32[] public resolverAddressesRequired;

    uint public constant MAX_ADDRESSES_FROM_RESOLVER = 24;

    constructor(address _resolver, bytes32[MAX_ADDRESSES_FROM_RESOLVER] memory _addressesToCache) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        for (uint i = 0; i < _addressesToCache.length; i++) {
            if (_addressesToCache[i] != bytes32(0)) {
                resolverAddressesRequired.push(_addressesToCache[i]);
            } else {
                // End early once an empty item is found - assumes there are no empty slots in
                // _addressesToCache
                break;
            }
        }
        resolver = AddressResolver(_resolver);
        // Do not sync the cache as addresses may not be in the resolver yet
    }

    /* ========== SETTERS ========== */
    function setResolverAndSyncCache(AddressResolver _resolver) external onlyOwner {
        resolver = _resolver;

        for (uint i = 0; i < resolverAddressesRequired.length; i++) {
            bytes32 name = resolverAddressesRequired[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            addressCache[name] = resolver.requireAndGetAddress(name, "Resolver missing target");
        }
    }

    /* ========== VIEWS ========== */

    function requireAndGetAddress(bytes32 name, string memory reason) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    // Note: this could be made external in a utility contract if addressCache was made public
    // (used for deployment)
    function isResolverCached(AddressResolver _resolver) external view returns (bool) {
        if (resolver != _resolver) {
            return false;
        }

        // otherwise, check everything
        for (uint i = 0; i < resolverAddressesRequired.length; i++) {
            bytes32 name = resolverAddressesRequired[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    // Note: can be made external into a utility contract (used for deployment)
    function getResolverAddressesRequired()
        external
        view
        returns (bytes32[MAX_ADDRESSES_FROM_RESOLVER] memory addressesRequired)
    {
        for (uint i = 0; i < resolverAddressesRequired.length; i++) {
            addressesRequired[i] = resolverAddressesRequired[i];
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    function appendToAddressCache(bytes32 name) internal {
        resolverAddressesRequired.push(name);
        require(resolverAddressesRequired.length < MAX_ADDRESSES_FROM_RESOLVER, "Max resolver cache size met");
        // Because this is designed to be called internally in constructors, we don't
        // check the address exists already in the resolver
        addressCache[name] = resolver.getAddress(name);
    }
}


interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int[] calldata values
    ) external;

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external;

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external;

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external;

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external;

    function setBytes32Value(
        bytes32 contractName,
        bytes32 record,
        bytes32 value
    ) external;

    function setBytes32Values(
        bytes32 contractName,
        bytes32[] calldata records,
        bytes32[] calldata values
    ) external;
}


// Internal references


contract MixinSystemSettings is MixinResolver {
    bytes32 internal constant SETTING_CONTRACT_NAME = "SystemSettings";

    bytes32 internal constant SETTING_WAITING_PERIOD_SECS = "waitingPeriodSecs";
    bytes32 internal constant SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR = "priceDeviationThresholdFactor";
    bytes32 internal constant SETTING_ISSUANCE_RATIO = "issuanceRatio";
    bytes32 internal constant SETTING_FEE_PERIOD_DURATION = "feePeriodDuration";
    bytes32 internal constant SETTING_TARGET_THRESHOLD = "targetThreshold";
    bytes32 internal constant SETTING_LIQUIDATION_DELAY = "liquidationDelay";
    bytes32 internal constant SETTING_LIQUIDATION_RATIO = "liquidationRatio";
    bytes32 internal constant SETTING_LIQUIDATION_PENALTY = "liquidationPenalty";
    bytes32 internal constant SETTING_RATE_STALE_PERIOD = "rateStalePeriod";
    bytes32 internal constant SETTING_EXCHANGE_FEE_RATE = "exchangeFeeRate";
    bytes32 internal constant SETTING_MINIMUM_STAKE_TIME = "minimumStakeTime";
    bytes32 internal constant SETTING_AGGREGATOR_WARNING_FLAGS = "aggregatorWarningFlags";
    bytes32 internal constant SETTING_TRADING_REWARDS_ENABLED = "tradingRewardsEnabled";

    bytes32 private constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    constructor() internal {
        appendToAddressCache(CONTRACT_FLEXIBLESTORAGE);
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE, "Missing FlexibleStorage address"));
    }

    function getTradingRewardsEnabled() internal view returns (bool) {
        return flexibleStorage().getBoolValue(SETTING_CONTRACT_NAME, SETTING_TRADING_REWARDS_ENABLED);
    }

    function getWaitingPeriodSecs() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS);
    }

    function getPriceDeviationThresholdFactor() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR);
    }

    function getIssuanceRatio() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ISSUANCE_RATIO);
    }

    function getFeePeriodDuration() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FEE_PERIOD_DURATION);
    }

    function getTargetThreshold() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_TARGET_THRESHOLD);
    }

    function getLiquidationDelay() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_DELAY);
    }

    function getLiquidationRatio() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_RATIO);
    }

    function getLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getRateStalePeriod() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    function getExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    function getMinimumStakeTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MINIMUM_STAKE_TIME);
    }

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }
}


interface ISystemSettings {
    // Views
    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    function issuanceRatio() external view returns (uint);

    function feePeriodDuration() external view returns (uint);

    function targetThreshold() external view returns (uint);

    function liquidationDelay() external view returns (uint);

    function liquidationRatio() external view returns (uint);

    function liquidationPenalty() external view returns (uint);

    function rateStalePeriod() external view returns (uint);

    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint);

    function minimumStakeTime() external view returns (uint);
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


// SafeDecimalMath
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
}


// Inheritance


// Libraries


contract SystemSettings is Owned, MixinResolver, MixinSystemSettings, ISystemSettings {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    // No more synths may be issued than the value of SNX backing them.
    uint public constant MAX_ISSUANCE_RATIO = 1e18;

    // The fee period must be between 1 day and 60 days.
    uint public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint public constant MAX_FEE_PERIOD_DURATION = 60 days;

    uint public constant MAX_TARGET_THRESHOLD = 50;

    uint public constant MAX_LIQUIDATION_RATIO = 1e18; // 100% issuance ratio

    uint public constant MAX_LIQUIDATION_PENALTY = 1e18 / 4; // Max 25% liquidation penalty / bonus

    uint public constant RATIO_FROM_TARGET_BUFFER = 2e18; // 200% - mininimum buffer between issuance ratio and liquidation ratio

    uint public constant MAX_LIQUIDATION_DELAY = 30 days;
    uint public constant MIN_LIQUIDATION_DELAY = 1 hours;

    // Exchange fee may not exceed 10%.
    uint public constant MAX_EXCHANGE_FEE_RATE = 1e18 / 10;

    // Minimum Stake time may not exceed 1 weeks.
    uint public constant MAX_MINIMUM_STAKE_TIME = 1 weeks;

    bytes32[24] private addressesToCache = [bytes32(0)];

    constructor(address _owner, address _resolver)
        public
        Owned(_owner)
        MixinResolver(_resolver, addressesToCache)
        MixinSystemSettings()
    {}

    // ========== VIEWS ==========

    // SIP-37 Fee Reclamation
    // The number of seconds after an exchange is executed that must be waited
    // before settlement.
    function waitingPeriodSecs() external view returns (uint) {
        return getWaitingPeriodSecs();
    }

    // SIP-65 Decentralized Circuit Breaker
    // The factor amount expressed in decimal format
    // E.g. 3e18 = factor 3, meaning movement up to 3x and above or down to 1/3x and below
    function priceDeviationThresholdFactor() external view returns (uint) {
        return getPriceDeviationThresholdFactor();
    }

    // The raio of collateral
    // Expressed in 18 decimals. So 800% cratio is 100/800 = 0.125 (0.125e18)
    function issuanceRatio() external view returns (uint) {
        return getIssuanceRatio();
    }

    // How long a fee period lasts at a minimum. It is required for
    // anyone to roll over the periods, so they are not guaranteed
    // to roll over at exactly this duration, but the contract enforces
    // that they cannot roll over any quicker than this duration.
    function feePeriodDuration() external view returns (uint) {
        return getFeePeriodDuration();
    }

    // Users are unable to claim fees if their collateralisation ratio drifts out of target threshold
    function targetThreshold() external view returns (uint) {
        return getTargetThreshold();
    }

    // SIP-15 Liquidations
    // liquidation time delay after address flagged (seconds)
    function liquidationDelay() external view returns (uint) {
        return getLiquidationDelay();
    }

    // SIP-15 Liquidations
    // issuance ratio when account can be flagged for liquidation (with 18 decimals), e.g 0.5 issuance ratio
    // when flag means 1/0.5 = 200% cratio
    function liquidationRatio() external view returns (uint) {
        return getLiquidationRatio();
    }

    // SIP-15 Liquidations
    // penalty taken away from target of liquidation (with 18 decimals). E.g. 10% is 0.1e18
    function liquidationPenalty() external view returns (uint) {
        return getLiquidationPenalty();
    }

    // How long will the ExchangeRates contract assume the rate of any asset is correct
    function rateStalePeriod() external view returns (uint) {
        return getRateStalePeriod();
    }

    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint) {
        return getExchangeFeeRate(currencyKey);
    }

    function minimumStakeTime() external view returns (uint) {
        return getMinimumStakeTime();
    }

    function aggregatorWarningFlags() external view returns (address) {
        return getAggregatorWarningFlags();
    }

    // SIP-63 Trading incentives
    // determines if Exchanger records fee entries in TradingRewards
    function tradingRewardsEnabled() external view returns (bool) {
        return getTradingRewardsEnabled();
    }

    // ========== RESTRICTED ==========

    function setTradingRewardsEnabled(bool _tradingRewardsEnabled) external onlyOwner {
        flexibleStorage().setBoolValue(SETTING_CONTRACT_NAME, SETTING_TRADING_REWARDS_ENABLED, _tradingRewardsEnabled);
        emit TradingRewardsEnabled(_tradingRewardsEnabled);
    }

    function setWaitingPeriodSecs(uint _waitingPeriodSecs) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS, _waitingPeriodSecs);
        emit WaitingPeriodSecsUpdated(_waitingPeriodSecs);
    }

    function setPriceDeviationThresholdFactor(uint _priceDeviationThresholdFactor) external onlyOwner {
        flexibleStorage().setUIntValue(
            SETTING_CONTRACT_NAME,
            SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR,
            _priceDeviationThresholdFactor
        );
        emit PriceDeviationThresholdUpdated(_priceDeviationThresholdFactor);
    }

    function setIssuanceRatio(uint _issuanceRatio) external onlyOwner {
        require(_issuanceRatio <= MAX_ISSUANCE_RATIO, "New issuance ratio cannot exceed MAX_ISSUANCE_RATIO");
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_ISSUANCE_RATIO, _issuanceRatio);
        emit IssuanceRatioUpdated(_issuanceRatio);
    }

    function setFeePeriodDuration(uint _feePeriodDuration) external onlyOwner {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "value < MIN_FEE_PERIOD_DURATION");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "value > MAX_FEE_PERIOD_DURATION");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_FEE_PERIOD_DURATION, _feePeriodDuration);

        emit FeePeriodDurationUpdated(_feePeriodDuration);
    }

    function setTargetThreshold(uint _percent) external onlyOwner {
        require(_percent <= MAX_TARGET_THRESHOLD, "Threshold too high");

        uint _targetThreshold = _percent.mul(SafeDecimalMath.unit()).div(100);

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_TARGET_THRESHOLD, _targetThreshold);

        emit TargetThresholdUpdated(_targetThreshold);
    }

    function setLiquidationDelay(uint time) external onlyOwner {
        require(time <= MAX_LIQUIDATION_DELAY, "Must be less than 30 days");
        require(time >= MIN_LIQUIDATION_DELAY, "Must be greater than 1 hours");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_DELAY, time);

        emit LiquidationDelayUpdated(time);
    }

    // The collateral / issuance ratio ( debt / collateral ) is higher when there is less collateral backing their debt
    // Upper bound liquidationRatio is 1 + penalty (100% + 10% = 110%) to allow collateral value to cover debt and liquidation penalty
    function setLiquidationRatio(uint _liquidationRatio) external onlyOwner {
        require(
            _liquidationRatio <= MAX_LIQUIDATION_RATIO.divideDecimal(SafeDecimalMath.unit().add(getLiquidationPenalty())),
            "liquidationRatio > MAX_LIQUIDATION_RATIO / (1 + penalty)"
        );

        // MIN_LIQUIDATION_RATIO is a product of target issuance ratio * RATIO_FROM_TARGET_BUFFER
        // Ensures that liquidation ratio is set so that there is a buffer between the issuance ratio and liquidation ratio.
        uint MIN_LIQUIDATION_RATIO = getIssuanceRatio().multiplyDecimal(RATIO_FROM_TARGET_BUFFER);
        require(_liquidationRatio >= MIN_LIQUIDATION_RATIO, "liquidationRatio < MIN_LIQUIDATION_RATIO");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_RATIO, _liquidationRatio);

        emit LiquidationRatioUpdated(_liquidationRatio);
    }

    function setLiquidationPenalty(uint penalty) external onlyOwner {
        require(penalty <= MAX_LIQUIDATION_PENALTY, "penalty > MAX_LIQUIDATION_PENALTY");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY, penalty);

        emit LiquidationPenaltyUpdated(penalty);
    }

    function setRateStalePeriod(uint period) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD, period);

        emit RateStalePeriodUpdated(period);
    }

    function setExchangeFeeRateForSynths(bytes32[] calldata synthKeys, uint256[] calldata exchangeFeeRates)
        external
        onlyOwner
    {
        require(synthKeys.length == exchangeFeeRates.length, "Array lengths dont match");
        for (uint i = 0; i < synthKeys.length; i++) {
            require(exchangeFeeRates[i] <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
            flexibleStorage().setUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_EXCHANGE_FEE_RATE, synthKeys[i])),
                exchangeFeeRates[i]
            );
            emit ExchangeFeeUpdated(synthKeys[i], exchangeFeeRates[i]);
        }
    }

    function setMinimumStakeTime(uint _seconds) external onlyOwner {
        require(_seconds <= MAX_MINIMUM_STAKE_TIME, "stake time exceed maximum 1 week");
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MINIMUM_STAKE_TIME, _seconds);
        emit MinimumStakeTimeUpdated(_seconds);
    }

    function setAggregatorWarningFlags(address _flags) external onlyOwner {
        require(_flags != address(0), "Valid address must be given");
        flexibleStorage().setAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS, _flags);
        emit AggregatorWarningFlagsUpdated(_flags);
    }

    // ========== EVENTS ==========
    event TradingRewardsEnabled(bool enabled);
    event WaitingPeriodSecsUpdated(uint waitingPeriodSecs);
    event PriceDeviationThresholdUpdated(uint threshold);
    event IssuanceRatioUpdated(uint newRatio);
    event FeePeriodDurationUpdated(uint newFeePeriodDuration);
    event TargetThresholdUpdated(uint newTargetThreshold);
    event LiquidationDelayUpdated(uint newDelay);
    event LiquidationRatioUpdated(uint newRatio);
    event LiquidationPenaltyUpdated(uint newPenalty);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    event ExchangeFeeUpdated(bytes32 synthKey, uint newExchangeFeeRate);
    event MinimumStakeTimeUpdated(uint minimumStakeTime);
    event AggregatorWarningFlagsUpdated(address flags);
}