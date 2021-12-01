/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: ExternalTokenStakeManager.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/ExternalTokenStakeManager.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/ExternalTokenStakeManager
*
* Contract Dependencies: 
*	- IAddressResolver
*	- MixinResolver
*	- Owned
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

    function totalIssuedPynths(bytes32 currencyKey, bool excludeEtherCollateral) external view returns (uint);

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


// https://docs.peri.finance/contracts/source/interfaces/iflexiblestorage
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


// https://docs.peri.finance/contracts/source/contracts/mixinsystemsettings
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
    bytes32 internal constant SETTING_DEBT_SNAPSHOT_STALE_TIME = "debtSnapshotStaleTime";
    bytes32 internal constant SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT = "crossDomainDepositGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT = "crossDomainEscrowGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT = "crossDomainRewardGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT = "crossDomainWithdrawalGasLimit";
    bytes32 internal constant SETTING_EXTERNAL_TOKEN_QUOTA = "externalTokenQuota";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    enum CrossDomainMessageGasLimits {Deposit, Escrow, Reward, Withdrawal}

    constructor(address _resolver) internal MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function _getGasLimitSetting(CrossDomainMessageGasLimits gasLimitType) internal pure returns (bytes32) {
        if (gasLimitType == CrossDomainMessageGasLimits.Deposit) {
            return SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Escrow) {
            return SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Reward) {
            return SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Withdrawal) {
            return SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT;
        } else {
            revert("Unknown gas limit type");
        }
    }

    function getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, _getGasLimitSetting(gasLimitType));
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

    function getDebtSnapshotStaleTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_DEBT_SNAPSHOT_STALE_TIME);
    }

    function getExternalTokenQuota() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_EXTERNAL_TOKEN_QUOTA);
    }
}


// https://docs.peri.finance/contracts/source/contracts/limitedsetup
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


interface IStakingState {
    // Mutative
    function stake(
        bytes32 _currencyKey,
        address _account,
        uint _amount
    ) external;

    function unstake(
        bytes32 _currencyKey,
        address _account,
        uint _amount
    ) external;

    function refund(
        bytes32 _currencyKey,
        address _account,
        uint _amount
    ) external returns (bool);

    // View
    function targetTokens(bytes32 _currencyKey)
        external
        view
        returns (
            address tokenAddress,
            uint8 decimals,
            bool activated
        );

    function stakedAmountOf(bytes32 _currencyKey, address _account) external view returns (uint);

    function totalStakedAmount(bytes32 _currencyKey) external view returns (uint);

    function totalStakerCount(bytes32 _currencyKey) external view returns (uint);

    function tokenList(uint _index) external view returns (bytes32);

    function tokenAddress(bytes32 _currencyKey) external view returns (address);

    function tokenDecimals(bytes32 _currencyKey) external view returns (uint8);

    function tokenActivated(bytes32 _currencyKey) external view returns (bool);

    function getTokenCurrencyKeys() external view returns (bytes32[] memory);
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


contract ExternalTokenStakeManager is Owned, MixinResolver, MixinSystemSettings, LimitedSetup(8 weeks) {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    IStakingState public stakingState;

    bytes32 internal constant pUSD = "pUSD";
    bytes32 internal constant PERI = "PERI";
    bytes32 internal constant USDC = "USDC";

    bytes32 public constant CONTRACT_NAME = "ExternalTokenStakeManager";

    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    // This key order is used from unstaking multiple coins
    bytes32[] public currencyKeyOrder;

    constructor(
        address _owner,
        address _stakingState,
        address _resolver
    ) public Owned(_owner) MixinSystemSettings(_resolver) {
        stakingState = IStakingState(_stakingState);
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](2);

        newAddresses[0] = CONTRACT_ISSUER;
        newAddresses[1] = CONTRACT_EXRATES;

        return combineArrays(existingAddresses, newAddresses);
    }

    function tokenInstance(bytes32 _currencyKey) internal view tokenRegistered(_currencyKey) returns (IERC20) {
        return IERC20(stakingState.tokenAddress(_currencyKey));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function getTokenList() external view returns (bytes32[] memory) {
        return stakingState.getTokenCurrencyKeys();
    }

    function getTokenAddress(bytes32 _currencyKey) external view returns (address) {
        return stakingState.tokenAddress(_currencyKey);
    }

    function getTokenDecimals(bytes32 _currencyKey) external view returns (uint8) {
        return stakingState.tokenDecimals(_currencyKey);
    }

    function getTokenActivation(bytes32 _currencyKey) external view returns (bool) {
        return stakingState.tokenActivated(_currencyKey);
    }

    function getCurrencyKeyOrder() external view returns (bytes32[] memory) {
        return currencyKeyOrder;
    }

    function combinedStakedAmountOf(address _user, bytes32 _unitCurrency) external view returns (uint) {
        return _combinedStakedAmountOf(_user, _unitCurrency);
    }

    function stakedAmountOf(
        address _user,
        bytes32 _currencyKey,
        bytes32 _unitCurrency
    ) external view returns (uint) {
        if (_currencyKey == _unitCurrency) {
            return stakingState.stakedAmountOf(_currencyKey, _user);
        } else {
            return _toCurrency(_currencyKey, _unitCurrency, stakingState.stakedAmountOf(_currencyKey, _user));
        }
    }

    function requireNotExceedsQuotaLimit(
        address _account,
        uint _debtBalance,
        uint _additionalpUSD,
        uint _additionalExToken,
        bool _isIssue
    ) external view {
        uint estimatedExternalTokenQuota =
            _externalTokenQuota(_account, _debtBalance, _additionalpUSD, _additionalExToken, _isIssue);

        bytes32[] memory tokenList = stakingState.getTokenCurrencyKeys();
        uint minDecimals = 18;
        for (uint i = 0; i < tokenList.length; i++) {
            uint decimals = stakingState.tokenDecimals(tokenList[i]);

            minDecimals = decimals < minDecimals ? decimals : minDecimals;
        }

        require(
            // due to the error caused by decimal difference, round down it upto minimum decimals among staking token list.
            estimatedExternalTokenQuota.roundDownDecimal(uint(18).sub(minDecimals)) <= getExternalTokenQuota(),
            "External token staking amount exceeds quota limit"
        );
    }

    function externalTokenQuota(
        address _account,
        uint _debtBalance,
        uint _additionalpUSD,
        uint _additionalExToken,
        bool _isIssue
    ) external view returns (uint) {
        return _externalTokenQuota(_account, _debtBalance, _additionalpUSD, _additionalExToken, _isIssue);
    }

    /**
     * @notice It calculates the quota of user's staked amount to the debt.
     *         If parameters are not 0, it estimates the quota assuming those value is applied to current status.
     *
     * @param _account account
     * @param _debtBalance Debt balance to estimate [USD]
     * @param _additionalpUSD The pUSD value to be applied for estimation [USD]
     * @param _additionalExToken The external token stake amount to be applied for estimation [USD]
     * @param _isIssue If true, it is considered issueing/staking estimation.
     */
    function _externalTokenQuota(
        address _account,
        uint _debtBalance,
        uint _additionalpUSD,
        uint _additionalExToken,
        bool _isIssue
    ) internal view returns (uint) {
        uint combinedStakedAmount = _combinedStakedAmountOf(_account, pUSD);

        if (_debtBalance == 0 || combinedStakedAmount == 0) {
            return 0;
        }

        if (_isIssue) {
            _debtBalance = _debtBalance.add(_additionalpUSD);
            combinedStakedAmount = combinedStakedAmount.add(_additionalExToken);
        } else {
            _debtBalance = _debtBalance.sub(_additionalpUSD);
            combinedStakedAmount = combinedStakedAmount.sub(_additionalExToken);
        }

        return combinedStakedAmount.divideDecimalRound(_debtBalance.divideDecimalRound(getIssuanceRatio()));
    }

    function _combinedStakedAmountOf(address _user, bytes32 _unitCurrency)
        internal
        view
        returns (uint combinedStakedAmount)
    {
        bytes32[] memory tokenList = stakingState.getTokenCurrencyKeys();

        for (uint i = 0; i < tokenList.length; i++) {
            uint _stakedAmount = stakingState.stakedAmountOf(tokenList[i], _user);

            if (_stakedAmount == 0) {
                continue;
            }

            uint stakedAmount = _toCurrency(tokenList[i], _unitCurrency, _stakedAmount);

            combinedStakedAmount = combinedStakedAmount.add(stakedAmount);
        }
    }

    function _toCurrency(
        bytes32 _fromCurrencyKey,
        bytes32 _toCurrencyKey,
        uint _amount
    ) internal view returns (uint) {
        if (_fromCurrencyKey == _toCurrencyKey) {
            return _amount;
        }

        uint amountToUSD;
        if (_fromCurrencyKey == pUSD) {
            amountToUSD = _amount;
        } else {
            (uint toUSDRate, bool fromCurrencyRateIsInvalid) = exchangeRates().rateAndInvalid(_fromCurrencyKey);

            _requireRatesNotInvalid(fromCurrencyRateIsInvalid);

            amountToUSD = _amount.multiplyDecimalRound(toUSDRate);
        }

        if (_toCurrencyKey == pUSD) {
            return amountToUSD;
        } else {
            (uint toCurrencyRate, bool toCurrencyRateIsInvalid) = exchangeRates().rateAndInvalid(_toCurrencyKey);

            _requireRatesNotInvalid(toCurrencyRateIsInvalid);

            return amountToUSD.divideDecimalRound(toCurrencyRate);
        }
    }

    /**
     * @notice Utils checking given two key arrays' value are matching each other(its order will not be considered).
     */
    function _keyChecker(bytes32[] memory _keysA, bytes32[] memory _keysB) internal pure returns (bool) {
        if (_keysA.length != _keysB.length) {
            return false;
        }

        for (uint i = 0; i < _keysA.length; i++) {
            bool exist;
            for (uint j = 0; j < _keysA.length; j++) {
                if (_keysA[i] == _keysB[j]) {
                    exist = true;

                    break;
                }
            }

            // given currency key is not matched
            if (!exist) {
                return false;
            }
        }

        return true;
    }

    function stake(
        address _staker,
        uint _amount,
        bytes32 _targetCurrency,
        bytes32 _inputCurrency
    ) external onlyIssuer {
        uint stakingAmountConverted = _toCurrency(_inputCurrency, _targetCurrency, _amount);

        uint targetDecimals = stakingState.tokenDecimals(_targetCurrency);
        require(targetDecimals <= 18, "Invalid decimal number");
        uint stakingAmountConvertedRoundedUp = stakingAmountConverted.roundUpDecimal(uint(18).sub(targetDecimals));

        require(
            tokenInstance(_targetCurrency).transferFrom(
                _staker,
                address(stakingState),
                stakingAmountConvertedRoundedUp.div(10**(uint(18).sub(targetDecimals)))
            ),
            "Transferring staking token has been failed"
        );

        stakingState.stake(_targetCurrency, _staker, stakingAmountConvertedRoundedUp);
    }

    function unstake(
        address _unstaker,
        uint _amount,
        bytes32 _targetCurrency,
        bytes32 _inputCurrency
    ) external onlyIssuer {
        uint unstakingAmountConverted = _toCurrency(_inputCurrency, _targetCurrency, _amount);

        _unstakeAndRefund(_unstaker, unstakingAmountConverted, _targetCurrency);
    }

    /**
     * @notice It unstakes multiple tokens by pre-defined order.
     *
     * @param _unstaker unstaker address
     * @param _amount amount to unstake
     * @param _inputCurrency the currency unit of _amount
     *
     * @dev bytes32 variable "order" is only able to be assigned by setUnstakingOrder(),
     *      and it checks its conditions there, here won't check its validation.
     */
    function unstakeMultipleTokens(
        address _unstaker,
        uint _amount,
        bytes32 _inputCurrency
    ) external onlyIssuer {
        bytes32[] memory currencyKeys = stakingState.getTokenCurrencyKeys();

        bytes32[] memory order;
        if (!_keyChecker(currencyKeys, currencyKeyOrder)) {
            order = currencyKeys;
        } else {
            order = currencyKeyOrder;
        }

        uint combinedStakedAmount = _combinedStakedAmountOf(_unstaker, _inputCurrency);
        require(combinedStakedAmount >= _amount, "Combined staked amount is not enough");

        uint[] memory unstakeAmountByCurrency = new uint[](order.length);
        for (uint i = 0; i < order.length; i++) {
            uint stakedAmountByCurrency = stakingState.stakedAmountOf(order[i], _unstaker);

            // Becacuse of exchange rate calculation error,
            // input amount is converted into each currency key rather than converting staked amount.
            uint amountConverted = _toCurrency(_inputCurrency, order[i], _amount);
            if (stakedAmountByCurrency < amountConverted) {
                // If staked amount is lower than amount to unstake, all staked amount will be unstaked.
                unstakeAmountByCurrency[i] = stakedAmountByCurrency;
                amountConverted = amountConverted.sub(stakedAmountByCurrency);
                _amount = _toCurrency(order[i], _inputCurrency, amountConverted);
            } else {
                unstakeAmountByCurrency[i] = amountConverted;
                _amount = 0;
            }

            if (_amount == 0) {
                break;
            }
        }

        for (uint i = 0; i < order.length; i++) {
            if (unstakeAmountByCurrency[i] == 0) {
                continue;
            }

            _unstakeAndRefund(_unstaker, unstakeAmountByCurrency[i], order[i]);
        }
    }

    function _unstakeAndRefund(
        address _unstaker,
        uint _amount,
        bytes32 _targetCurrency
    ) internal tokenRegistered(_targetCurrency) {
        uint targetDecimals = stakingState.tokenDecimals(_targetCurrency);
        require(targetDecimals <= 18, "Invalid decimal number");
        uint unstakingAmountConvertedRoundedUp = _amount.roundUpDecimal(uint(18).sub(targetDecimals));

        stakingState.unstake(_targetCurrency, _unstaker, unstakingAmountConvertedRoundedUp);

        require(
            stakingState.refund(_targetCurrency, _unstaker, unstakingAmountConvertedRoundedUp),
            "Refund has been failed"
        );
    }

    function setUnstakingOrder(bytes32[] calldata _order) external onlyOwner {
        bytes32[] memory currencyKeys = stakingState.getTokenCurrencyKeys();

        require(_keyChecker(currencyKeys, _order), "Given currency keys are not available");

        currencyKeyOrder = _order;
    }

    function setStakingState(address _stakingState) external onlyOwner {
        stakingState = IStakingState(_stakingState);
    }

    function _requireRatesNotInvalid(bool anyRateIsInvalid) internal pure {
        require(!anyRateIsInvalid, "A pynth or PERI rate is invalid");
    }

    function _onlyIssuer() internal view {
        require(msg.sender == address(issuer()), "Sender is not Issuer");
    }

    function _tokenRegistered(bytes32 _currencyKey) internal view {
        require(stakingState.tokenAddress(_currencyKey) != address(0), "Target token is not registered");
    }

    modifier onlyIssuer() {
        _onlyIssuer();
        _;
    }

    modifier tokenRegistered(bytes32 _currencyKey) {
        _tokenRegistered(_currencyKey);
        _;
    }
}