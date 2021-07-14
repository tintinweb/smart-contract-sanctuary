/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: DebtCache.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/DebtCache.sol
* Docs: https://docs.synthetix.io/contracts/DebtCache
*
* Contract Dependencies: 
*	- BaseDebtCache
*	- IAddressResolver
*	- IDebtCache
*	- MixinResolver
*	- MixinSystemSettings
*	- Owned
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



pragma solidity ^0.5.0;

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
        uint cusdAmount,
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


// solhint-disable payable-fallback

// https://docs.synthetix.io/contracts/source/contracts/readproxy
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


// https://docs.synthetix.io/contracts/source/interfaces/iflexiblestorage
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


// https://docs.synthetix.io/contracts/source/contracts/mixinsystemsettings
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
    bytes32 internal constant SETTING_ETHER_WRAPPER_MAX_ETH = "etherWrapperMaxETH";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MINT_FEE_RATE = "etherWrapperMintFeeRate";
    bytes32 internal constant SETTING_ETHER_WRAPPER_BURN_FEE_RATE = "etherWrapperBurnFeeRate";

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

    function getEtherWrapperMaxETH() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MAX_ETH);
    }

    function getEtherWrapperMintFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MINT_FEE_RATE);
    }

    function getEtherWrapperBurnFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_BURN_FEE_RATE);
    }
}


interface IDebtCache {
    // Views

    function cachedDebt() external view returns (uint);

    function cachedSynthDebt(bytes32 currencyKey) external view returns (uint);

    function cacheTimestamp() external view returns (uint);

    function cacheInvalid() external view returns (bool);

    function cacheStale() external view returns (bool);

    function currentSynthDebts(bytes32[] calldata currencyKeys)
        external
        view
        returns (
            uint[] memory debtValues,
            uint excludedDebt,
            bool anyRateIsInvalid
        );

    function cachedSynthDebts(bytes32[] calldata currencyKeys) external view returns (uint[] memory debtValues);

    function totalNonSnxBackedDebt() external view returns (uint excludedDebt, bool isInvalid);

    function currentDebt() external view returns (uint debt, bool anyRateIsInvalid);

    function cacheInfo()
        external
        view
        returns (
            uint debt,
            uint timestamp,
            bool isInvalid,
            bool isStale
        );

    // Mutative functions

    function updateCachedSynthDebts(bytes32[] calldata currencyKeys) external;

    function updateCachedSynthDebtWithRate(bytes32 currencyKey, uint currencyRate) external;

    function updateCachedSynthDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external;

    function updateDebtCacheValidity(bool currentlyInvalid) external;

    function purgeCachedSynthDebt(bytes32 currencyKey) external;

    function takeDebtSnapshot() external;
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


// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) external view returns (uint amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate);

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    // Mutative functions
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualSynth,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function setLastExchangeRateForSynth(bytes32 currencyKey, uint rate) external;

    function resetLastExchangeRate(bytes32[] calldata currencyKeys) external;

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;
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


// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
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

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iethercollateral
interface IEtherCollateral {
    // Views
    function totalIssuedSynths() external view returns (uint256);

    function totalLoansCreated() external view returns (uint256);

    function totalOpenLoanCount() external view returns (uint256);

    // Mutative functions
    function openLoan() external payable returns (uint256 loanID);

    function closeLoan(uint256 loanID) external;

    function liquidateUnclosedLoan(address _loanCreatorsAddress, uint256 _loanID) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iethercollateralcusd
interface IEtherCollateralcUSD {
    // Views
    function totalIssuedSynths() external view returns (uint256);

    function totalLoansCreated() external view returns (uint256);

    function totalOpenLoanCount() external view returns (uint256);

    // Mutative functions
    function openLoan(uint256 _loanAmount) external payable returns (uint256 loanID);

    function closeLoan(uint256 loanID) external;

    function liquidateUnclosedLoan(address _loanCreatorsAddress, uint256 _loanID) external;

    function depositCollateral(address account, uint256 loanID) external payable;

    function withdrawCollateral(uint256 loanID, uint256 withdrawAmount) external;

    function repayLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _repayAmount
    ) external;
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


interface ICollateralManager {
    // Manager information
    function hasCollateral(address collateral) external view returns (bool);

    function isSynthManaged(bytes32 currencyKey) external view returns (bool);

    // State information
    function long(bytes32 synth) external view returns (uint amount);

    function short(bytes32 synth) external view returns (uint amount);

    function totalLong() external view returns (uint cusdValue, bool anyRateIsInvalid);

    function totalShort() external view returns (uint cusdValue, bool anyRateIsInvalid);

    function getBorrowRate() external view returns (uint borrowRate, bool anyRateIsInvalid);

    function getShortRate(bytes32 synth) external view returns (uint shortRate, bool rateIsInvalid);

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

    function areSynthsAndCurrenciesSet(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys)
        external
        view
        returns (bool);

    function areShortableSynthsSet(bytes32[] calldata requiredSynthNamesInResolver, bytes32[] calldata synthKeys)
        external
        view
        returns (bool);

    // Loans
    function getNewLoanId() external returns (uint id);

    // Manager mutative
    function addCollaterals(address[] calldata collaterals) external;

    function removeCollaterals(address[] calldata collaterals) external;

    function addSynths(bytes32[] calldata synthNamesInResolver, bytes32[] calldata synthKeys) external;

    function removeSynths(bytes32[] calldata synths, bytes32[] calldata synthKeys) external;

    function addShortableSynths(bytes32[2][] calldata requiredSynthAndInverseNamesInResolver, bytes32[] calldata synthKeys)
        external;

    function removeShortableSynths(bytes32[] calldata synths) external;

    // State mutative
    function updateBorrowRates(uint rate) external;

    function updateShortRates(bytes32 currency, uint rate) external;

    function incrementLongs(bytes32 synth, uint amount) external;

    function decrementLongs(bytes32 synth, uint amount) external;

    function incrementShorts(bytes32 synth, uint amount) external;

    function decrementShorts(bytes32 synth, uint amount) external;
}


interface IWETH {
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

    // WETH-specific functions.
    function deposit() external payable;

    function withdraw(uint amount) external;

    // Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Deposit(address indexed to, uint amount);
    event Withdrawal(address indexed to, uint amount);
}


// https://docs.synthetix.io/contracts/source/interfaces/ietherwrapper
contract IEtherWrapper {
    function mint(uint amount) external;

    function burn(uint amount) external;

    function distributeFees() external;

    function capacity() external view returns (uint);

    function getReserves() external view returns (uint);

    function totalIssuedSynths() external view returns (uint);

    function calculateMintFee(uint amount) public view returns (uint);

    function calculateBurnFee(uint amount) public view returns (uint);

    function maxETH() public view returns (uint256);

    function mintFeeRate() public view returns (uint256);

    function burnFeeRate() public view returns (uint256);

    function weth() public view returns (IWETH);
}


// Inheritance


// Libraries


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/debtcache
contract BaseDebtCache is Owned, MixinSystemSettings, IDebtCache {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    uint internal _cachedDebt;
    mapping(bytes32 => uint) internal _cachedSynthDebt;
    uint internal _cacheTimestamp;
    bool internal _cacheInvalid = true;

    /* ========== ENCODED NAMES ========== */

    bytes32 internal constant cUSD = "cUSD";
    bytes32 internal constant sETH = "sETH";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_ETHERCOLLATERAL = "EtherCollateral";
    bytes32 private constant CONTRACT_ETHERCOLLATERAL_CUSD = "EtherCollateralcUSD";
    bytes32 private constant CONTRACT_COLLATERALMANAGER = "CollateralManager";
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](8);
        newAddresses[0] = CONTRACT_ISSUER;
        newAddresses[1] = CONTRACT_EXCHANGER;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_SYSTEMSTATUS;
        newAddresses[4] = CONTRACT_ETHERCOLLATERAL;
        newAddresses[5] = CONTRACT_ETHERCOLLATERAL_CUSD;
        newAddresses[6] = CONTRACT_COLLATERALMANAGER;
        newAddresses[7] = CONTRACT_ETHER_WRAPPER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function etherCollateral() internal view returns (IEtherCollateral) {
        return IEtherCollateral(requireAndGetAddress(CONTRACT_ETHERCOLLATERAL));
    }

    function etherCollateralcUSD() internal view returns (IEtherCollateralcUSD) {
        return IEtherCollateralcUSD(requireAndGetAddress(CONTRACT_ETHERCOLLATERAL_CUSD));
    }

    function collateralManager() internal view returns (ICollateralManager) {
        return ICollateralManager(requireAndGetAddress(CONTRACT_COLLATERALMANAGER));
    }

    function etherWrapper() internal view returns (IEtherWrapper) {
        return IEtherWrapper(requireAndGetAddress(CONTRACT_ETHER_WRAPPER));
    }

    function debtSnapshotStaleTime() external view returns (uint) {
        return getDebtSnapshotStaleTime();
    }

    function cachedDebt() external view returns (uint) {
        return _cachedDebt;
    }

    function cachedSynthDebt(bytes32 currencyKey) external view returns (uint) {
        return _cachedSynthDebt[currencyKey];
    }

    function cacheTimestamp() external view returns (uint) {
        return _cacheTimestamp;
    }

    function cacheInvalid() external view returns (bool) {
        return _cacheInvalid;
    }

    function _cacheStale(uint timestamp) internal view returns (bool) {
        // Note a 0 timestamp means that the cache is uninitialised.
        // We'll keep the check explicitly in case the stale time is
        // ever set to something higher than the current unix time (e.g. to turn off staleness).
        return getDebtSnapshotStaleTime() < block.timestamp - timestamp || timestamp == 0;
    }

    function cacheStale() external view returns (bool) {
        return _cacheStale(_cacheTimestamp);
    }

    function _issuedSynthValues(bytes32[] memory currencyKeys, uint[] memory rates)
        internal
        view
        returns (uint[] memory values)
    {
        uint numValues = currencyKeys.length;
        values = new uint[](numValues);
        ISynth[] memory synths = issuer().getSynths(currencyKeys);

        for (uint i = 0; i < numValues; i++) {
            address synthAddress = address(synths[i]);
            require(synthAddress != address(0), "Synth does not exist");
            uint supply = IERC20(synthAddress).totalSupply();
            values[i] = supply.multiplyDecimalRound(rates[i]);
        }

        return (values);
    }

    function _currentSynthDebts(bytes32[] memory currencyKeys)
        internal
        view
        returns (
            uint[] memory snxIssuedDebts,
            uint _excludedDebt,
            bool anyRateIsInvalid
        )
    {
        (uint[] memory rates, bool isInvalid) = exchangeRates().ratesAndInvalidForCurrencies(currencyKeys);
        uint[] memory values = _issuedSynthValues(currencyKeys, rates);
        (uint excludedDebt, bool isAnyNonSnxDebtRateInvalid) = _totalNonSnxBackedDebt();
        return (values, excludedDebt, isInvalid || isAnyNonSnxDebtRateInvalid);
    }

    function currentSynthDebts(bytes32[] calldata currencyKeys)
        external
        view
        returns (
            uint[] memory debtValues,
            uint excludedDebt,
            bool anyRateIsInvalid
        )
    {
        return _currentSynthDebts(currencyKeys);
    }

    function _cachedSynthDebts(bytes32[] memory currencyKeys) internal view returns (uint[] memory) {
        uint numKeys = currencyKeys.length;
        uint[] memory debts = new uint[](numKeys);
        for (uint i = 0; i < numKeys; i++) {
            debts[i] = _cachedSynthDebt[currencyKeys[i]];
        }
        return debts;
    }

    function cachedSynthDebts(bytes32[] calldata currencyKeys) external view returns (uint[] memory snxIssuedDebts) {
        return _cachedSynthDebts(currencyKeys);
    }

    // Returns the total cUSD debt backed by non-SNX collateral.
    function totalNonSnxBackedDebt() external view returns (uint excludedDebt, bool isInvalid) {
        return _totalNonSnxBackedDebt();
    }

    function _totalNonSnxBackedDebt() internal view returns (uint excludedDebt, bool isInvalid) {
        // Calculate excluded debt.
        // 1. Ether Collateral.
        excludedDebt = excludedDebt.add(etherCollateralcUSD().totalIssuedSynths()); // Ether-backed cUSD

        uint etherCollateralTotalIssuedSynths = etherCollateral().totalIssuedSynths();
        // We check the supply > 0 as on L2, we may not yet have up-to-date rates for sETH.
        if (etherCollateralTotalIssuedSynths > 0) {
            (uint sETHRate, bool sETHRateIsInvalid) = exchangeRates().rateAndInvalid(sETH);
            isInvalid = isInvalid || sETHRateIsInvalid;
            excludedDebt = excludedDebt.add(etherCollateralTotalIssuedSynths.multiplyDecimalRound(sETHRate)); // Ether-backed sETH
        }

        // 2. MultiCollateral long debt + short debt.
        (uint longValue, bool anyTotalLongRateIsInvalid) = collateralManager().totalLong();
        (uint shortValue, bool anyTotalShortRateIsInvalid) = collateralManager().totalShort();
        isInvalid = isInvalid || anyTotalLongRateIsInvalid || anyTotalShortRateIsInvalid;
        excludedDebt = excludedDebt.add(longValue).add(shortValue);

        // 3. EtherWrapper.
        // Subtract sETH and cUSD issued by EtherWrapper.
        excludedDebt = excludedDebt.add(etherWrapper().totalIssuedSynths());

        return (excludedDebt, isInvalid);
    }

    function _currentDebt() internal view returns (uint debt, bool anyRateIsInvalid) {
        bytes32[] memory currencyKeys = issuer().availableCurrencyKeys();
        (uint[] memory rates, bool isInvalid) = exchangeRates().ratesAndInvalidForCurrencies(currencyKeys);

        // Sum all issued synth values based on their supply.
        uint[] memory values = _issuedSynthValues(currencyKeys, rates);
        (uint excludedDebt, bool isAnyNonSnxDebtRateInvalid) = _totalNonSnxBackedDebt();

        uint numValues = values.length;
        uint total;
        for (uint i; i < numValues; i++) {
            total = total.add(values[i]);
        }
        total = total < excludedDebt ? 0 : total.sub(excludedDebt);

        return (total, isInvalid || isAnyNonSnxDebtRateInvalid);
    }

    function currentDebt() external view returns (uint debt, bool anyRateIsInvalid) {
        return _currentDebt();
    }

    function cacheInfo()
        external
        view
        returns (
            uint debt,
            uint timestamp,
            bool isInvalid,
            bool isStale
        )
    {
        uint time = _cacheTimestamp;
        return (_cachedDebt, time, _cacheInvalid, _cacheStale(time));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Stub out all mutative functions as no-ops;
    // since they do nothing, there are no restrictions

    function updateCachedSynthDebts(bytes32[] calldata currencyKeys) external {}

    function updateCachedSynthDebtWithRate(bytes32 currencyKey, uint currencyRate) external {}

    function updateCachedSynthDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external {}

    function updateDebtCacheValidity(bool currentlyInvalid) external {}

    function purgeCachedSynthDebt(bytes32 currencyKey) external {}

    function takeDebtSnapshot() external {}

    /* ========== MODIFIERS ========== */

    function _requireSystemActiveIfNotOwner() internal view {
        if (msg.sender != owner) {
            systemStatus().requireSystemActive();
        }
    }

    modifier requireSystemActiveIfNotOwner() {
        _requireSystemActiveIfNotOwner();
        _;
    }

    function _onlyIssuer() internal view {
        require(msg.sender == address(issuer()), "Sender is not Issuer");
    }

    modifier onlyIssuer() {
        _onlyIssuer();
        _;
    }

    function _onlyIssuerOrExchanger() internal view {
        require(msg.sender == address(issuer()) || msg.sender == address(exchanger()), "Sender is not Issuer or Exchanger");
    }

    modifier onlyIssuerOrExchanger() {
        _onlyIssuerOrExchanger();
        _;
    }
}


// Libraries


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/debtcache
contract DebtCache is BaseDebtCache {
    using SafeDecimalMath for uint;

    constructor(address _owner, address _resolver) public BaseDebtCache(_owner, _resolver) {}

    bytes32 internal constant EXCLUDED_DEBT_KEY = "EXCLUDED_DEBT";

    /* ========== MUTATIVE FUNCTIONS ========== */

    // This function exists in case a synth is ever somehow removed without its snapshot being updated.
    function purgeCachedSynthDebt(bytes32 currencyKey) external onlyOwner {
        require(issuer().synths(currencyKey) == ISynth(0), "Synth exists");
        delete _cachedSynthDebt[currencyKey];
    }

    function takeDebtSnapshot() external requireSystemActiveIfNotOwner {
        bytes32[] memory currencyKeys = issuer().availableCurrencyKeys();
        (uint[] memory values, uint excludedDebt, bool isInvalid) = _currentSynthDebts(currencyKeys);

        uint numValues = values.length;
        uint snxCollateralDebt;
        for (uint i; i < numValues; i++) {
            uint value = values[i];
            snxCollateralDebt = snxCollateralDebt.add(value);
            _cachedSynthDebt[currencyKeys[i]] = value;
        }
        _cachedSynthDebt[EXCLUDED_DEBT_KEY] = excludedDebt;
        _cachedDebt = snxCollateralDebt.floorsub(excludedDebt);
        _cacheTimestamp = block.timestamp;
        emit DebtCacheUpdated(snxCollateralDebt);
        emit DebtCacheSnapshotTaken(block.timestamp);

        // (in)validate the cache if necessary
        _updateDebtCacheValidity(isInvalid);
    }

    function updateCachedSynthDebts(bytes32[] calldata currencyKeys) external requireSystemActiveIfNotOwner {
        (uint[] memory rates, bool anyRateInvalid) = exchangeRates().ratesAndInvalidForCurrencies(currencyKeys);
        _updateCachedSynthDebtsWithRates(currencyKeys, rates, anyRateInvalid, false);
    }

    function updateCachedSynthDebtWithRate(bytes32 currencyKey, uint currencyRate) external onlyIssuer {
        bytes32[] memory synthKeyArray = new bytes32[](1);
        synthKeyArray[0] = currencyKey;
        uint[] memory synthRateArray = new uint[](1);
        synthRateArray[0] = currencyRate;
        _updateCachedSynthDebtsWithRates(synthKeyArray, synthRateArray, false, false);
    }

    function updateCachedSynthDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates)
        external
        onlyIssuerOrExchanger
    {
        _updateCachedSynthDebtsWithRates(currencyKeys, currencyRates, false, false);
    }

    function updateDebtCacheValidity(bool currentlyInvalid) external onlyIssuer {
        _updateDebtCacheValidity(currentlyInvalid);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _updateDebtCacheValidity(bool currentlyInvalid) internal {
        if (_cacheInvalid != currentlyInvalid) {
            _cacheInvalid = currentlyInvalid;
            emit DebtCacheValidityChanged(currentlyInvalid);
        }
    }

    function _updateCachedSynthDebtsWithRates(
        bytes32[] memory currencyKeys,
        uint[] memory currentRates,
        bool anyRateIsInvalid,
        bool recomputeExcludedDebt
    ) internal {
        uint numKeys = currencyKeys.length;
        require(numKeys == currentRates.length, "Input array lengths differ");

        // Update the cached values for each synth, saving the sums as we go.
        uint cachedSum;
        uint currentSum;
        uint excludedDebtSum = _cachedSynthDebt[EXCLUDED_DEBT_KEY];
        uint[] memory currentValues = _issuedSynthValues(currencyKeys, currentRates);

        for (uint i = 0; i < numKeys; i++) {
            bytes32 key = currencyKeys[i];
            uint currentSynthDebt = currentValues[i];
            cachedSum = cachedSum.add(_cachedSynthDebt[key]);
            currentSum = currentSum.add(currentSynthDebt);
            _cachedSynthDebt[key] = currentSynthDebt;
        }

        // Always update the cached value of the excluded debt -- it's computed anyway.
        if (recomputeExcludedDebt) {
            (uint excludedDebt, bool anyNonSnxDebtRateIsInvalid) = _totalNonSnxBackedDebt();
            anyRateIsInvalid = anyRateIsInvalid || anyNonSnxDebtRateIsInvalid;
            excludedDebtSum = excludedDebt;
        }

        cachedSum = cachedSum.floorsub(_cachedSynthDebt[EXCLUDED_DEBT_KEY]);
        currentSum = currentSum.floorsub(excludedDebtSum);
        _cachedSynthDebt[EXCLUDED_DEBT_KEY] = excludedDebtSum;

        // Compute the difference and apply it to the snapshot
        if (cachedSum != currentSum) {
            uint debt = _cachedDebt;
            // This requirement should never fail, as the total debt snapshot is the sum of the individual synth
            // debt snapshots.
            require(cachedSum <= debt, "Cached synth sum exceeds total debt");
            debt = debt.sub(cachedSum).add(currentSum);
            _cachedDebt = debt;
            emit DebtCacheUpdated(debt);
        }

        // A partial update can invalidate the debt cache, but a full snapshot must be performed in order
        // to re-validate it.
        if (anyRateIsInvalid) {
            _updateDebtCacheValidity(anyRateIsInvalid);
        }
    }

    /* ========== EVENTS ========== */

    event DebtCacheUpdated(uint cachedDebt);
    event DebtCacheSnapshotTaken(uint timestamp);
    event DebtCacheValidityChanged(bool indexed isInvalid);
}