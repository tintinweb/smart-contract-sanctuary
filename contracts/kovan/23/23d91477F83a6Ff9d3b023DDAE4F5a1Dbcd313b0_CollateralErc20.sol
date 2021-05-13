/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: CollateralErc20.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/CollateralErc20.sol
* Docs: https://docs.synthetix.io/contracts/CollateralErc20
*
* Contract Dependencies: 
*	- Collateral
*	- CollateralStaking
*	- IAddressResolver
*	- ICollateralErc20
*	- ICollateralLoan
*	- MixinResolver
*	- MixinSystemSettings
*	- Owned
*	- State
* Libraries: 
*	- DataTypesLib
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


// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
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
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
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

    bytes32 internal constant SETTING_LIQUIDATION_PENALTY = "liquidationPenalty";
    bytes32 internal constant SETTING_RATE_STALE_PERIOD = "rateStalePeriod";
    bytes32 internal constant SETTING_AGGREGATOR_WARNING_FLAGS = "aggregatorWarningFlags";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    constructor(address _resolver) internal MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function getLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getRateStalePeriod() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }
}


pragma experimental ABIEncoderV2;

interface ICollateralLoan {
    struct Loan {
        // ID for the loan
        uint id;
        //  Acccount that created the loan
        address account;
        //  Amount of collateral deposited
        uint collateral;
        //  Amount of synths borrowed
        uint amount;
    }

    struct Fund {
        uint debt;
        uint donation;
    }

    struct Staking {
        //V1 + V2
        uint lastCollaterals;
        uint lastRewardPerToken;
        //V2
        uint collaterals;
        uint round;
        //奖励
        uint rewards;
    }

    //aave
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
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
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/state
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


interface IFunctionX {
    // Views
    function currencyKey() external view returns (bytes32);

    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
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


// Inheritance


// Libraries


contract CollateralState is Owned, State, MixinSystemSettings, ICollateralLoan {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    mapping(address => Loan) public loans;
    address public currency;
    //抵押合约负债
    Fund public fund;

    bytes32 private constant CONTRACT_FUNCTIONXUSD = "FunctionxUSD";

    constructor(
        address _owner,
        address _resolver,
        address _associatedContract,
        address _currency
    ) public Owned(_owner) State(_associatedContract) MixinSystemSettings(_resolver) {
        currency = _currency;
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_FUNCTIONXUSD;

        return combineArrays(existingAddresses, newAddresses);
    }

    function _functionxUSD() internal view returns (IFunctionX) {
        return IFunctionX(requireAndGetAddress(CONTRACT_FUNCTIONXUSD));
    }

    //获取借贷信息
    function getLoan(address account) external view returns (Loan memory) {
        Loan memory loan = loans[account];
        if (loan.account == address(0)) {
            loan.account = account;
        }
        return loan;
    }

    //更新借贷信息
    function updateLoan(Loan memory loan) public onlyAssociatedContract {
        loans[loan.account] = loan;

        emit UpdateLoan(loan.account, currency, loan.collateral, loan.amount);
    }

    //关闭借贷
    function closeLoan(address account) public onlyAssociatedContract {
        delete (loans[account]);

        emit UpdateLoan(account, currency, 0, 0);
    }

    //增加负债
    function increaseDebt(uint amount) public onlyAssociatedContract {
        if (fund.donation >= amount) {
            //捐款剩余余额充足
            //燃烧fxUSD
            _functionxUSD().burn(address(this), amount);
            //减去增加的负债
            fund.donation = fund.donation.sub(amount);
        } else {
            //燃烧fxUSD
            _functionxUSD().burn(address(this), fund.donation);
            //捐款余额不足，但是可以消减部分负债
            amount = amount.sub(fund.donation);
            fund.donation = 0;
            //增加负债
            fund.debt = fund.debt.add(amount);
        }
    }

    //减少负债
    function reduceDebt(uint amount) public onlyAssociatedContract {
        //接收捐款
        IERC20(address(_functionxUSD())).transferFrom(msg.sender, address(this), amount);
        if (fund.debt >= amount) {
            //负债大于等于捐款金额
            //燃烧fxUSD
            _functionxUSD().burn(address(this), amount);
            //减去负债
            fund.debt = fund.debt.sub(amount);
        } else {
            //燃烧fxUSD
            _functionxUSD().burn(address(this), fund.debt);
            //捐款金额充足
            amount = amount.sub(fund.debt);
            fund.debt = 0;
            fund.donation = fund.donation.add(amount);
        }
    }

    //转账
    function transfer(
        address token,
        address account,
        uint amount
    ) public onlyAssociatedContract {
        require(token == currency, "Invalid Token address");
        IERC20(currency).transfer(account, amount);
    }

    //授权
    function approve(
        address token,
        address spender,
        uint amount
    ) public onlyAssociatedContract {
        require(token == currency, "Invalid Token address");
        IERC20(currency).approve(spender, amount);
    }

    //staking专用
    function callStaking(address pool, bytes memory extraData) public onlyAssociatedContract {
        (bool b, ) = pool.call(extraData);
        if (!b) {
            revert();
        }
    }

    function getFund() public view returns (uint, uint) {
        return (fund.debt, fund.donation);
    }

    /*========== EVENTS ==========*/

    event UpdateLoan(address indexed account, address indexed currency, uint collateral, uint amount);
}


interface ICollateralManager {
    // Manager information
    function hasCollateral(address collateral) external view returns (bool);

    function getBorrowRate() external view returns (uint borrowRate, bool anyRateIsInvalid);

    function getRatesAndTime(uint index)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        );

    // Manager mutative
    function addCollaterals(address[] calldata collaterals) external;

    function removeCollaterals(address[] calldata collaterals) external;

    // State mutative
    function updateBorrowRates(uint rate) external;
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

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

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

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function oracle() external view returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

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
}


interface ICollateralState {
    function callStaking(address pool, bytes calldata extraData) external;

    function getLoan(address account) external view returns (ICollateralLoan.Loan memory);

    function getFund() external view returns (uint, uint);

    function updateLoan(ICollateralLoan.Loan calldata loan) external;

    function closeLoan(address account) external;

    function increaseDebt(uint amount) external;

    function reduceDebt(uint amount) external;

    function approve(
        address token,
        address spender,
        uint amount
    ) external;

    function transfer(
        address token,
        address account,
        uint amount
    ) external;
}


// Inheritance


// Libraries


// Internal references


contract Collateral is ICollateralLoan, Owned, MixinSystemSettings {
    /* ========== LIBRARIES ========== */
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== CONSTANTS ========== */

    bytes32 private constant fxUSD = "fxUSD";

    // ========== STATE VARIABLES ==========

    // The fxUSD corresponding to the collateral.
    bytes32 public collateralKey;

    // Stores loans
    ICollateralState public state;

    address public manager;

    // ========== SETTER STATE VARIABLES ==========

    // The minimum collateral ratio required to avoid liquidation.
    uint public minCratio;

    // The collateral ration after liquidate, default equal to minCratio
    uint public cRatioAfterLiquidate;

    // The minimum amount of collateral to create a loan.
    uint public minCollateral;

    // The on-off of contract
    bool public canOptionLoans = true;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_FUNCTIONXUSD = "FunctionxUSD";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _state,
        address _owner,
        address _manager,
        address _resolver,
        bytes32 _collateralKey,
        uint _minCratio,
        uint _minCollateral
    ) public Owned(_owner) MixinSystemSettings(_resolver) {
        manager = _manager;
        state = ICollateralState(_state);
        collateralKey = _collateralKey;
        minCratio = _minCratio;
        minCollateral = _minCollateral;
        cRatioAfterLiquidate = _minCratio;
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](3);
        newAddresses[0] = CONTRACT_EXRATES;
        newAddresses[1] = CONTRACT_SYSTEMSTATUS;
        newAddresses[2] = CONTRACT_FUNCTIONXUSD;

        return combineArrays(existingAddresses, newAddresses);
    }

    /* ---------- Related Contracts ---------- */

    function _systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function _functionxUSD() internal view returns (IFunctionX) {
        return IFunctionX(requireAndGetAddress(CONTRACT_FUNCTIONXUSD));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function _manager() internal view returns (ICollateralManager) {
        return ICollateralManager(manager);
    }

    /* ---------- Public Views ---------- */

    function collateralRatio(Loan memory loan) public view returns (uint cratio) {
        uint cvalue = _exchangeRates().effectiveValue(collateralKey, loan.collateral, fxUSD);
        cratio = cvalue.divideDecimal(loan.amount);
    }

    function _checkCollateralRatio(Loan memory loan) internal view returns (bool) {
        //如果fxUSD为0，则没有生成，可以全部提取
        if (loan.amount == 0) {
            return true;
        }
        return (collateralRatio(loan) > minCratio);
    }

    // The maximum number of fxUSD issuable for this amount of collateral
    function maxLoan(uint amount) public view returns (uint max) {
        max = issuanceRatio().multiplyDecimal(_exchangeRates().effectiveValue(collateralKey, amount, fxUSD));
    }

    function maxDraw(address account) public view returns (uint max) {
        Loan memory loan = state.getLoan(account);
        uint value = maxLoan(loan.collateral);
        max = value.sub(loan.amount);
    }

    function maxWithdraw(address account) public view returns (uint max) {
        Loan memory loan = state.getLoan(account);
        uint collateral = minCratio.multiplyDecimal(loan.amount);
        uint value = _exchangeRates().effectiveValue(fxUSD, collateral, collateralKey);
        max = loan.collateral.sub(value);
    }

    /**
     * r = target issuance ratio
     * D = debt value in fxUSD
     * V = collateral value in fxUSD
     * P = liquidation penalty
     * Calculates amount of fxUSD = (D - V * r) / (1 - (1 + P) * r)
     * Note: if you pass a loan in here that is not eligible for liquidation it will revert.
     * We check the ratio first in liquidateInternal and only pass eligible loans in.
     */
    function liquidationAmount(Loan memory loan) public view returns (uint amount) {
        uint liquidationPenalty = getLiquidationPenalty();
        uint debtValue = loan.amount;
        uint collateralValue = _exchangeRates().effectiveValue(collateralKey, loan.collateral, fxUSD);
        uint unit = SafeDecimalMath.unit();

        uint dividend = debtValue.sub(collateralValue.divideDecimal(cRatioAfterLiquidate));
        uint divisor = unit.sub(unit.add(liquidationPenalty).divideDecimal(cRatioAfterLiquidate));
        return dividend.divideDecimal(divisor);
    }

    function maxLiquidationValue(Loan memory loan) public view returns (uint amount) {
        uint liquidationPenalty = getLiquidationPenalty();
        uint unit = SafeDecimalMath.unit();
        uint maxLiquidate = loan.collateral.divideDecimal(unit.add(liquidationPenalty));
        return maxLoan(maxLiquidate);
    }

    // amount is the amount of fxUSD we are liquidating
    function collateralRedeemed(bytes32 currency, uint amount) public view returns (uint collateral) {
        uint liquidationPenalty = getLiquidationPenalty();
        collateral = _exchangeRates().effectiveValue(fxUSD, amount, currency);

        collateral = collateral.multiplyDecimal(SafeDecimalMath.unit().add(liquidationPenalty));
    }

    /* ---------- UTILITIES ---------- */

    // Check the account has enough of the fxUSD to make the payment
    function _checkFxUSDBalance(address payer, uint amount) internal view {
        require(IERC20(address(_functionxUSD())).balanceOf(payer) >= amount, "Not enough fxUSD balance");
    }

    function issuanceRatio() internal view returns (uint ratio) {
        ratio = SafeDecimalMath.unit().divideDecimal(minCratio);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- SETTERS ---------- */

    function setMinCratio(uint _minCratio) external onlyOwner {
        require(_minCratio > SafeDecimalMath.unit(), "Must be greater than 1");
        minCratio = _minCratio;
        emit MinCratioRatioUpdated(minCratio);
    }

    function setCRatioAfterLiquidate(uint _cRatioAfterLiquidate) external onlyOwner {
        require(_cRatioAfterLiquidate > minCratio, "Must be greater than minimum collateral ratio");
        cRatioAfterLiquidate = _cRatioAfterLiquidate;
        emit CRatioAfterLiquidateUpdated(cRatioAfterLiquidate);
    }

    function setManager(address _newManager) external onlyOwner {
        manager = _newManager;
        emit ManagerUpdated(manager);
    }

    function setCanOptionLoans(bool _canOptionLoans) external onlyOwner {
        canOptionLoans = _canOptionLoans;
        emit CanOptionLoansUpdated(canOptionLoans);
    }

    /* ---------- GET ---------- */
    //查询抵押率
    function getCollateralRatio(address account) public view returns (uint) {
        Loan memory loan = state.getLoan(account);
        if (loan.amount == 0) {
            return 0;
        }
        return _exchangeRates().effectiveValue(collateralKey, loan.collateral, fxUSD).divideDecimal(loan.amount);
    }

    //获取抵押信息
    function getLoan(address account) public view returns (uint collateral, uint amount) {
        Loan memory loan = state.getLoan(account);
        return (loan.collateral, loan.amount);
    }

    // 查询罚款比率
    function liquidationPenalty() public view returns (uint) {
        return getLiquidationPenalty();
    }

    function getFund() public view returns (uint debt, uint donation) {
        (debt, donation) = state.getFund();
    }

    /* ---------- LOAN INTERACTIONS ---------- */

    event Deposit(address indexed account, uint collateral);
    event Withdraw(address indexed accout, uint amount);
    event Draw(address indexed account, uint amount);
    event Repay(address indexed account, uint payment);
    event Liquidate(address indexed account, address indexed liquidator, uint liquidated, uint collateralLiquidated);
    event LiquidateClose(
        address indexed account,
        address indexed liquidator,
        uint liquidated,
        uint collateralLiquidated,
        uint debt
    );
    event Close(address indexed account, uint collateral, uint amount);

    function depositInternal(address borrower, uint collateral) internal canOption rateIsValid {
        //大于最小抵押数量
        require(collateral >= minCollateral, "Not enough collateral to open");
        //获取抵押贷款数据
        Loan memory loan = state.getLoan(borrower);
        //更新抵押数量
        loan.collateral = loan.collateral.add(collateral);
        //更新
        state.updateLoan(loan);
        //事件Event
        emit Deposit(borrower, collateral);
    }

    function withdrawInternal(address borrower, uint amount) internal canOption rateIsValid {
        //获取抵押贷款数据
        Loan memory loan = state.getLoan(borrower);
        require(amount > 0 && amount <= loan.collateral, "Withdraw amount must be greater than 0 and less than collateral");
        //扣除抵押物和fxUSD
        loan.collateral = loan.collateral.sub(amount);
        //检查抵押率是否达标
        require(_checkCollateralRatio(loan), "Cratio too low");
        //更新
        state.updateLoan(loan);
        //事件Event
        emit Withdraw(borrower, amount);
    }

    function drawInternal(address borrower, uint amount) internal canOption rateIsValid {
        //获取抵押贷款数据
        Loan memory loan = state.getLoan(borrower);
        //计算fxUSD最大贷款数量
        uint maxLoanAmount = maxLoan(loan.collateral);
        //计算可贷款数量
        uint canLoanAmount = maxLoanAmount.sub(loan.amount);
        require(amount > 0 && amount < canLoanAmount, "Invalid amount or exceeds max borrowing power");
        //更新贷款数量
        loan.amount = loan.amount.add(amount);
        //检查抵押率是否达标
        require(_checkCollateralRatio(loan), "Cratio too low");
        //更新
        state.updateLoan(loan);
        //生成fxUSD
        _functionxUSD().issue(borrower, amount);
        //事件Event
        emit Draw(borrower, amount);
    }

    function repayInternal(address borrower, uint payment) internal canOption rateIsValid {
        //获取抵押贷款数据
        Loan memory loan = state.getLoan(borrower);
        require(payment > 0 && loan.amount > 0, "Payment and Loan must be greater than 0");
        _checkFxUSDBalance(borrower, payment);
        if (payment <= loan.amount) {
            loan.amount = loan.amount.sub(payment);
        } else {
            loan.amount = 0;
            payment = loan.amount;
        }
        //燃烧fxUSD
        _functionxUSD().burn(borrower, payment);
        //更新
        state.updateLoan(loan);
        //事件Event
        emit Repay(borrower, payment);
    }

    function liquidateInternal(
        address liquidator,
        uint payment,
        address borrower
    ) internal canOption rateIsValid returns (uint collateralLiquidated) {
        //检查清算人清算金额
        require(payment > 0, "Payment must be greater than 0");
        _checkFxUSDBalance(liquidator, payment);
        //获取抵押贷款数据
        Loan memory loan = state.getLoan(borrower);
        require(loan.amount > 0, "Loan amount must greater than 0");
        //满足最小抵押率
        require(collateralRatio(loan) < minCratio, "Cratio above liquidation ratio");
        //需要清算的金额(fxUSD)
        uint liqAmount = liquidationAmount(loan);
        //当前最大可清算抵押物价值(fxUSD，已扣除罚款)
        uint maxValue = maxLiquidationValue(loan);
        //资不抵债，且清算人输入金额大于可清算抵押物价值(扣除惩罚)，可以交换所有抵押物
        if (liqAmount >= loan.amount && payment >= maxValue) {
            return _liquidateClose(liquidator, borrower, loan, maxValue);
        }
        //若资不抵债，但是输入清算金额较小，无法交换所有抵押物，所以取payment作为清算金额
        //若未达到资不抵债，取liqAmount和payment中较小的
        uint amountToLiquidate = liqAmount >= loan.amount ? payment : (liqAmount < payment ? liqAmount : payment);
        //更新抵押数据
        loan.amount = loan.amount.sub(amountToLiquidate);
        collateralLiquidated = collateralRedeemed(collateralKey, amountToLiquidate);
        loan.collateral = loan.collateral.sub(collateralLiquidated);
        //燃烧fxUSD
        _functionxUSD().burn(liquidator, amountToLiquidate);
        //更新
        state.updateLoan(loan);
        //事件Event
        emit Liquidate(borrower, liquidator, amountToLiquidate, collateralLiquidated);
    }

    function _liquidateClose(
        address liquidator,
        address borrower,
        Loan memory loan,
        uint currentValue
    ) internal returns (uint collateralLiquidated) {
        //剩余负债
        uint residual = loan.amount.sub(currentValue);
        //返还抵押物
        collateralLiquidated = loan.collateral;
        //燃烧fxUSD
        _functionxUSD().burn(liquidator, currentValue);
        //清空抵押人
        state.closeLoan(borrower);
        //记录合约负债
        state.increaseDebt(residual);
        //事件Event
        emit LiquidateClose(borrower, liquidator, currentValue, collateralLiquidated, residual);
    }

    function closeInternal(address borrower) internal canOption rateIsValid returns (uint collateral) {
        //获取贷款数据
        Loan memory loan = state.getLoan(borrower);
        //检查借款人是否有足够的fxUSD
        _checkFxUSDBalance(loan.account, loan.amount);
        //燃烧fxUSD
        _functionxUSD().burn(borrower, loan.amount);
        //提取抵押物
        collateral = loan.collateral;
        //关闭
        state.closeLoan(loan.account);
        //事件Event
        emit Close(borrower, loan.collateral, loan.amount);
    }

    function reduceDebtInternal(uint amount) internal {
        //授权
        IERC20(address(_functionxUSD())).approve(address(state), amount);
        //捐款
        state.reduceDebt(amount);
    }

    // ========== MODIFIERS ==========

    modifier rateIsValid() {
        _requireRateIsValid();
        _;
    }

    modifier canOption() {
        //系统状态
        //        _systemStatus().requireIssuanceActive();
        //是否可以操作
        require(canOptionLoans, "Option is disabled");
        _;
    }

    function _requireRateIsValid() private view {
        require(!_exchangeRates().rateIsInvalid(collateralKey), "Collateral rate is invalid");
    }

    // ========== EVENTS ==========
    // Setters
    event MinCratioRatioUpdated(uint minCratio);
    event CRatioAfterLiquidateUpdated(uint cRationAfterLiqudidate);
    event MinCollateralUpdated(uint minCollateral);
    event MaxLoansPerAccountUpdated(uint maxLoansPerAccount);
    event ManagerUpdated(address manager);
    event CanOptionLoansUpdated(bool canOptionLoans);
}


interface ICollateralErc20 {
    function depositAndDraw(uint collateral, uint amount) external;

    function deposit(address borrower, uint collateral) external;

    function withdraw(address account, uint amount) external;

    function draw(uint amount) external;

    function repay(uint amount) external;

    function liquidate(address borrower, uint amount) external;

    function close() external;
}


interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}


library DataTypesLib {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.

    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }
}


interface ILendingPool {

    function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;

    function withdraw(address asset,uint256 amount,address to) external returns (uint256);

    function addToToken(address token, address aToken) external;

    function getReserveData(address asset) external view returns (DataTypesLib.ReserveData memory);

}


interface ICollateralStakingState {
    function token() external view returns (address);

    function canStaking() external view returns (bool);

    function getStaking(address account) external view returns (ICollateralLoan.Staking memory);

    function totalCollateral() external view returns (uint);

    function surplus() external view returns (uint);

    function earned(uint total, address account) external view returns (uint);

    function calExtract(uint collateral, uint reward) external returns (uint);

    function extractUpdate(
        address account,
        uint amount,
        uint reward
    ) external returns (uint, uint);

    function pledgeUpdate(
        address account,
        uint collateral,
        uint reward
    ) external;

    function updateLastRecord(uint total) external;

    function updateLastBlockAndRewardPerToken(uint total) external;

    function savingsUpdate() external;
}


contract CollateralStaking is ICollateralLoan {
    using SafeMath for uint;

    //state
    ICollateralState public state;
    ICollateralStakingState public sState;
    //aave管理地址
    address public aaveProvider;

    constructor(
        address _state,
        address _sState,
        address _aaveProvider
    ) public {
        state = ICollateralState(_state);
        sState = ICollateralStakingState(_sState);
        aaveProvider = _aaveProvider;
    }

    /*
     * @notion 更新全局变量
     *
     */
    modifier updateGlobalVariable() {
        uint total = IERC20(aToken()).balanceOf(address(state));
        sState.updateLastBlockAndRewardPerToken(total);
        _;
        //每次存款或取款都会更新余额，但是同一个块内rewardPerToken只计算一次，不会使用后面更新的数据计算
        total = IERC20(aToken()).balanceOf(address(state));
        sState.updateLastRecord(total);
    }

    modifier canStakingOption() {
        require(canStaking(), "Staking option is disabled");
        _;
    }

    function canStaking() public view returns (bool) {
        if (address(sState) == address(0)) {
            return false;
        }
        return sState.canStaking();
    }

    function earned(address account) public view returns (uint) {
        //当前是aave，所以balance取回本金+奖励
        //如果换成其他生息池，需要统计本金加奖励
        uint total = IERC20(aToken()).balanceOf(address(state));
        return sState.earned(total, account);
    }

    function pledge(address account, uint collateral) internal canStakingOption updateGlobalVariable {
        sState.pledgeUpdate(account, collateral, earned(account));
    }

    function extract(address account, uint collateral) internal canStakingOption updateGlobalVariable returns (uint) {
        //更新
        (uint amount, uint reward) = sState.extractUpdate(account, collateral, earned(account));
        uint toWithdraw = sState.calExtract(amount, reward);
        //aave提现
        if (toWithdraw > 0) {
            bytes memory input =
                abi.encodeWithSignature("withdraw(address,uint256,address)", sState.token(), toWithdraw, address(state));
            state.callStaking(lendingPool(), input);
        }
        return amount.add(reward);
    }

    function savings() public canStakingOption updateGlobalVariable {
        //实际存款 = 存款 - 已提取的利息
        uint surplus = sState.surplus();
        require(surplus > 0, "Surplus must greater than 0");
        //aave存款
        state.approve(sState.token(), lendingPool(), surplus);
        bytes memory input =
            abi.encodeWithSignature("deposit(address,uint256,address,uint16)", sState.token(), surplus, address(state), 0);
        state.callStaking(lendingPool(), input);
        //更新
        sState.savingsUpdate();
    }

    function collaterals(address account) internal view returns (uint) {
        Staking memory s = sState.getStaking(account);
        return s.lastCollaterals.add(s.collaterals);
    }

    function lendingPool() public view returns (address) {
        return ILendingPoolAddressesProvider(aaveProvider).getLendingPool();
    }

    function aToken() public view returns (address) {
        return ILendingPool(lendingPool()).getReserveData(sState.token()).aTokenAddress;
    }
}


// Inheritance


// Internal references


// This contract handles the specific ERC20 implementation details of managing a loan.
contract CollateralErc20 is ICollateralErc20, Collateral, CollateralStaking {
    // The underlying asset for this ERC20 collateral
    address public underlyingContract;

    uint public underlyingContractDecimals;

    constructor(
        address _owner,
        address _manager,
        address _resolver,
        bytes32 _collateralKey,
        uint _minCratio,
        uint _minCollateral,
        address _underlyingContract,
        uint _underlyingDecimals,
        address _aaveProvider,
        address _state,
        address _sState
    )
        public
        Collateral(_state, _owner, _manager, _resolver, _collateralKey, _minCratio, _minCollateral)
        CollateralStaking(_state, _sState, _aaveProvider)
    {
        underlyingContract = _underlyingContract;
        underlyingContractDecimals = _underlyingDecimals;
    }

    //抵押和生成fxUSD，只能抵押给自己
    function depositAndDraw(uint collateral, uint amount) external {
        deposit(msg.sender, collateral);
        draw(amount);
    }

    //添加抵押物
    function deposit(address borrower, uint collateral) public {
        //检查额度
        require(collateral <= IERC20(underlyingContract).allowance(msg.sender, address(this)), "Allowance not high enough");
        //转移ERC20
        IERC20(underlyingContract).transferFrom(msg.sender, address(state), collateral);
        //抵押贷款
        depositInternal(borrower, collateral);
        //记录抵押物
        if (canStaking()) {
            pledge(borrower, collateral);
        }
    }

    //赎回抵押物
    function withdraw(address account, uint amount) external {
        //赎回
        withdrawInternal(msg.sender, amount);
        //提取抵押物
        if (canStaking()) {
            amount = extract(msg.sender, amount);
        }
        //转移ERC20
        transferInternal(account, amount);
    }

    //生成fxUSD，降低抵押率
    function draw(uint amount) public {
        //生成fxUSD
        drawInternal(msg.sender, amount);
    }

    //燃烧fxUSD，提高抵押率
    function repay(uint amount) external {
        //燃烧fxUSD
        repayInternal(msg.sender, amount);
    }

    //清算
    function liquidate(address borrower, uint amount) external {
        //清算
        uint collateralLiquidated = liquidateInternal(msg.sender, amount, borrower);
        //提取抵押物
        if (canStaking()) {
            (uint collateral, ) = getLoan(borrower);
            if (collateral == 0) {
                //全部，提现奖励
                uint reward = extract(borrower, collaterals(borrower)).sub(collateralLiquidated);
                //转账奖励给抵押人
                transferInternal(borrower, reward);
            } else {
                //部分
                extract(borrower, collateralLiquidated);
            }
        }
        //转账抵押物给清算人
        transferInternal(msg.sender, collateralLiquidated);
    }

    //清空fxUSD，返还抵押物
    function close() external {
        //关闭
        uint collateral = closeInternal(msg.sender);
        //提取抵押物
        if (canStaking()) {
            collateral = extract(msg.sender, collaterals(msg.sender));
        }
        //转移ERC20
        transferInternal(msg.sender, collateral);
    }

    //捐款
    function donation(uint amount) external {
        //转移fxUSD
        IERC20(address(_functionxUSD())).transferFrom(msg.sender, address(this), amount);
        //减少合约负债
        reduceDebtInternal(amount);
    }

    function transferInternal(address account, uint amount) internal {
        state.transfer(underlyingContract, account, amount);
    }
}