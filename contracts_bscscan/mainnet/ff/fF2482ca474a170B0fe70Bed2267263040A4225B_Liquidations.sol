/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Oikos: Liquidations.sol
*
* Latest source (may be newer): https://github.com/Oikosio/synthetix/blob/master/contracts/Liquidations.sol
* Docs: https://docs.synthetix.io/contracts/Liquidations
*
* Contract Dependencies: 
*	- IAddressResolver
*	- ILiquidations
*	- MixinResolver
*	- Owned
*	- State
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2021 Oikos
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

/* ===============================================
* Flattened with Solidifier by Coinage
* 
* https://solidifier.coina.ge
* ===============================================
*/


pragma solidity ^0.5.16;


// https://docs.oikos.cash/contracts/Owned
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

    // Restricted: used internally to Oikos
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


interface IIssuer {
    // Views
    function anySynthOrOKSRateIsStale() external view returns (bool anyRateStale);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesStale(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsStale);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function lastIssueEvent(address account) external view returns (uint);

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

    function totalIssuedSynths(bytes32 currencyKey, bool excludeEtherCollateral) external view returns (uint);

    function transferableOikosAndAnyRateIsStale(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsStale);

    // Restricted: used internally to Oikos
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

    function liquidateDelinquentAccount(address account, uint susdAmount, address liquidator) external returns (uint totalRedeemed, uint amountToLiquidate);
}


// Inheritance


// https://docs.oikos.cash/contracts/AddressResolver
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


// https://docs.oikos.cash/contracts/MixinResolver
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


interface ILiquidations {
    // Views
    function isOpenForLiquidation(address account) external view returns (bool);

    function getLiquidationDeadlineForAccount(address account) external view returns (uint);

    function isLiquidationDeadlinePassed(address account) external view returns (bool);

    function liquidationDelay() external view returns (uint);

    function liquidationRatio() external view returns (uint);

    function liquidationPenalty() external view returns (uint);

    function calculateAmountToFixCollateral(
        uint debtBalance,
        uint collateral
    ) external view returns (uint);

    // Mutative Functions
    function flagAccountForLiquidation(address account) external;

    // Restricted: used internally to Oikos
    function removeAccountInLiquidation(address account) external;

    function checkAndRemoveAccountInLiquidation(address account) external;
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


// https://docs.oikos.cash/contracts/SafeDecimalMath
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


// https://docs.oikos.cash/contracts/State
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


// Inheritance


/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
// https://docs.oikos.cash/contracts/EternalStorage
contract EternalStorage is Owned, State {
    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) internal UIntStorage;
    mapping(bytes32 => string) internal StringStorage;
    mapping(bytes32 => address) internal AddressStorage;
    mapping(bytes32 => bytes) internal BytesStorage;
    mapping(bytes32 => bytes32) internal Bytes32Storage;
    mapping(bytes32 => bool) internal BooleanStorage;
    mapping(bytes32 => int) internal IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint) {
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external onlyAssociatedContract {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external onlyAssociatedContract {
        delete UIntStorage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory) {
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string calldata value) external onlyAssociatedContract {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external onlyAssociatedContract {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address) {
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external onlyAssociatedContract {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external onlyAssociatedContract {
        delete AddressStorage[record];
    }

    // BytesStorage
    function getBytesValue(bytes32 record) external view returns (bytes memory) {
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes calldata value) external onlyAssociatedContract {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external onlyAssociatedContract {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32) {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external onlyAssociatedContract {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external onlyAssociatedContract {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool) {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external onlyAssociatedContract {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external onlyAssociatedContract {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int) {
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external onlyAssociatedContract {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external onlyAssociatedContract {
        delete IntStorage[record];
    }
}


interface IOikos {
    // Views
    function anySynthOrOKSRateIsStale() external view returns (bool anyRateStale);

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

    function transferableOikos(address account) external view returns (uint transferable);

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

    function liquidateDelinquentAccount(address account, uint susdAmount) external returns (bool);
}


interface IOikosState {
    // Views
    function debtLedger(uint index) external view returns (uint);

    function issuanceRatio() external view returns (uint);

    function issuanceData(address account) external view returns (uint initialDebtOwnership, uint debtEntryIndex);

    function debtLedgerLength() external view returns (uint);

    function hasIssued(address account) external view returns (bool);

    function lastDebtLedgerEntry() external view returns (uint);

    // Mutative functions
    function incrementTotalIssuerCount() external;

    function decrementTotalIssuerCount() external;

    function setCurrentIssuanceData(address account, uint initialDebtOwnership) external;

    function appendDebtLedgerValue(uint value) external;

    function clearIssuanceData(address account) external;
}


// https://docs.oikos.cash/contracts/source/interfaces/IExchangeRates
interface IExchangeRates {
    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function anyRateIsStale(bytes32[] calldata currencyKeys) external view returns (bool);

    function currentRoundForRate(bytes32 currencyKey) external view returns (uint);

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
            bool frozen
        );

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function oracle() external view returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFrozen(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(bytes32 currencyKey, uint numRounds)
        external
        view
        returns (uint[] memory rates, uint[] memory times);

    function ratesAndStaleForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory, bool);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);
}


interface ISystemStatus {
    // Views
    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;
}


// Inheritance


// Libraries


// Internal references


// https://docs.oikos.cash/contracts/Liquidations
contract Liquidations is Owned, MixinResolver, ILiquidations {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    struct LiquidationEntry {
        uint deadline;
        address caller;
    }

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_OIKOS = "Oikos";
    bytes32 private constant CONTRACT_ETERNALSTORAGE_LIQUIDATIONS = "EternalStorageLiquidations";
    bytes32 private constant CONTRACT_OIKOSSTATE = "OikosState";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    bytes32[24] private addressesToCache = [
        CONTRACT_SYSTEMSTATUS,
        CONTRACT_OIKOS,
        CONTRACT_ETERNALSTORAGE_LIQUIDATIONS,
        CONTRACT_OIKOSSTATE,
        CONTRACT_ISSUER,
        CONTRACT_EXRATES
    ];

    /* ========== CONSTANTS ========== */
    uint public constant MAX_LIQUIDATION_RATIO = 1e18; // 100% issuance ratio

    uint public constant MAX_LIQUIDATION_PENALTY = 1e18 / 4; // Max 25% liquidation penalty / bonus

    uint public constant RATIO_FROM_TARGET_BUFFER = 2e18; // 200% - mininimum buffer between issuance ratio and liquidation ratio

    uint public constant MAX_LIQUIDATION_DELAY = 30 days;
    uint public constant MIN_LIQUIDATION_DELAY = 1 days;

    // Storage keys
    bytes32 public constant LIQUIDATION_DEADLINE = "LiquidationDeadline";
    bytes32 public constant LIQUIDATION_CALLER = "LiquidationCaller";

    /* ========== STATE VARIABLES ========== */
    uint public liquidationDelay = 2 weeks; // liquidation time delay after address flagged
    uint public liquidationRatio = 1e18 / 2; // 0.5 issuance ratio when account can be flagged for liquidation
    uint public liquidationPenalty = 1e18 / 10; // 10%

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver, addressesToCache) {}

    /* ========== VIEWS ========== */
    function oikos() internal view returns (IOikos) {
        return IOikos(resolver.requireAndGetAddress(CONTRACT_OIKOS, "Missing Oikos address"));
    }

    function oikosState() internal view returns (IOikosState) {
        return IOikosState(resolver.requireAndGetAddress(CONTRACT_OIKOSSTATE, "Missing OikosState address"));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(resolver.requireAndGetAddress(CONTRACT_SYSTEMSTATUS, "Missing SystemStatus address"));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(resolver.requireAndGetAddress(CONTRACT_ISSUER, "Missing Issuer address"));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(resolver.requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
    }

    // refactor to oikos storage eternal storage contract once that's ready
    function eternalStorageLiquidations() internal view returns (EternalStorage) {
        return
            EternalStorage(
                resolver.requireAndGetAddress(CONTRACT_ETERNALSTORAGE_LIQUIDATIONS, "Missing EternalStorageLiquidations address")
            );
    }

    /* ========== VIEWS ========== */

    function liquidationCollateralRatio() external view returns (uint) {
        return SafeDecimalMath.unit().divideDecimalRound(liquidationRatio);
    }

    function getLiquidationDeadlineForAccount(address account) external view returns (uint) {
        LiquidationEntry memory liquidation = _getLiquidationEntryForAccount(account);
        return liquidation.deadline;
    }

    function isOpenForLiquidation(address account) external view returns (bool) {
        uint accountCollateralisationRatio = oikos().collateralisationRatio(account);

        // Liquidation closed if collateral ratio less than or equal target issuance Ratio
        // Account with no oks collateral will also not be open for liquidation (ratio is 0)
        if (accountCollateralisationRatio <= oikosState().issuanceRatio()) {
            return false;
        }

        LiquidationEntry memory liquidation = _getLiquidationEntryForAccount(account);

        // liquidation cap at issuanceRatio is checked above
        if (_deadlinePassed(liquidation.deadline)) {
            return true;
        }
        return false;
    }

    function isLiquidationDeadlinePassed(address account) external view returns (bool) {
        LiquidationEntry memory liquidation = _getLiquidationEntryForAccount(account);
        return _deadlinePassed(liquidation.deadline);
    }

    function _deadlinePassed(uint deadline) internal view returns (bool) {
        // check deadline is set > 0
        // check now > deadline
        return deadline > 0 && now > deadline;
    }

    /**
     * r = target issuance ratio
     * D = debt balance
     * V = Collateral
     * P = liquidation penalty
     * Calculates amount of synths = (D - V * r) / (1 - (1 + P) * r)
     */
    function calculateAmountToFixCollateral(uint debtBalance, uint collateral) external view returns (uint) {
        uint ratio = oikosState().issuanceRatio();
        uint unit = SafeDecimalMath.unit();

        uint dividend = debtBalance.sub(collateral.multiplyDecimal(ratio));
        uint divisor = unit.sub(unit.add(liquidationPenalty).multiplyDecimal(ratio));

        return dividend.divideDecimal(divisor);
    }

    // get liquidationEntry for account
    // returns deadline = 0 when not set
    function _getLiquidationEntryForAccount(address account) internal view returns (LiquidationEntry memory _liquidation) {
        _liquidation.deadline = eternalStorageLiquidations().getUIntValue(_getKey(LIQUIDATION_DEADLINE, account));

        // liquidation caller not used
        _liquidation.caller = address(0);
    }

    function _getKey(bytes32 _scope, address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_scope, _account));
    }

    /* ========== SETTERS ========== */
    function setLiquidationDelay(uint time) external onlyOwner {
        require(time <= MAX_LIQUIDATION_DELAY, "Must be less than 30 days");
        require(time >= MIN_LIQUIDATION_DELAY, "Must be greater than 1 day");

        liquidationDelay = time;

        emit LiquidationDelayUpdated(time);
    }

    // Accounts Collateral/Issuance ratio is higher when there is less collateral backing their debt
    // Upper bound liquidationRatio is 1 + penalty (100% + 10% = 110%) to allow collateral to cover debt and penalty
    function setLiquidationRatio(uint _liquidationRatio) external onlyOwner {
        require(
            _liquidationRatio <= MAX_LIQUIDATION_RATIO.divideDecimal(SafeDecimalMath.unit().add(liquidationPenalty)),
            "liquidationRatio > MAX_LIQUIDATION_RATIO / (1 + penalty)"
        );

        // MIN_LIQUIDATION_RATIO is a product of target issuance ratio * RATIO_FROM_TARGET_BUFFER
        // Ensures that liquidation ratio is set so that there is a buffer between the issuance ratio and liquidation ratio.
        uint MIN_LIQUIDATION_RATIO = oikosState().issuanceRatio().multiplyDecimal(RATIO_FROM_TARGET_BUFFER);
        require(_liquidationRatio >= MIN_LIQUIDATION_RATIO, "liquidationRatio < MIN_LIQUIDATION_RATIO");

        liquidationRatio = _liquidationRatio;

        emit LiquidationRatioUpdated(_liquidationRatio);
    }

    function setLiquidationPenalty(uint penalty) external onlyOwner {
        require(penalty <= MAX_LIQUIDATION_PENALTY, "penalty > MAX_LIQUIDATION_PENALTY");
        liquidationPenalty = penalty;

        emit LiquidationPenaltyUpdated(penalty);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // totalIssuedSynths checks synths for staleness
    // check oks rate is not stale
    function flagAccountForLiquidation(address account) external rateNotStale("OKS") {
        systemStatus().requireSystemActive();

        LiquidationEntry memory liquidation = _getLiquidationEntryForAccount(account);
        require(liquidation.deadline == 0, "Account already flagged for liquidation");

        uint accountsCollateralisationRatio = oikos().collateralisationRatio(account);

        // if accounts issuance ratio is greater than or equal to liquidation ratio set liquidation entry
        require(accountsCollateralisationRatio >= liquidationRatio, "Account issuance ratio is less than liquidation ratio");

        uint deadline = now.add(liquidationDelay);

        _storeLiquidationEntry(account, deadline, msg.sender);

        emit AccountFlaggedForLiquidation(account, deadline);
    }

    // Internal function to remove account from liquidations
    // Does not check collateral ratio is fixed
    function removeAccountInLiquidation(address account) external onlyIssuer {
        LiquidationEntry memory liquidation = _getLiquidationEntryForAccount(account);
        if (liquidation.deadline > 0) {
            _removeLiquidationEntry(account);
        }
    }

    // Public function to allow an account to remove from liquidations
    // Checks collateral ratio is fixed - below target issuance ratio
    // Check OKS rate is not stale
    function checkAndRemoveAccountInLiquidation(address account) external rateNotStale("OKS") {
        systemStatus().requireSystemActive();

        LiquidationEntry memory liquidation = _getLiquidationEntryForAccount(account);

        require(liquidation.deadline > 0, "Account has no liquidation set");

        uint accountsCollateralisationRatio = oikos().collateralisationRatio(account);

        // Remove from liquidations if accountsCollateralisationRatio is fixed (less than equal target issuance ratio)
        if (accountsCollateralisationRatio <= oikosState().issuanceRatio()) {
            _removeLiquidationEntry(account);
        }
    }

    function _storeLiquidationEntry(
        address _account,
        uint _deadline,
        address _caller
    ) internal {
        // record liquidation deadline
        eternalStorageLiquidations().setUIntValue(_getKey(LIQUIDATION_DEADLINE, _account), _deadline);
        eternalStorageLiquidations().setAddressValue(_getKey(LIQUIDATION_CALLER, _account), _caller);
    }

    function _removeLiquidationEntry(address _account) internal {
        // delete liquidation deadline
        eternalStorageLiquidations().deleteUIntValue(_getKey(LIQUIDATION_DEADLINE, _account));
        // delete liquidation caller
        eternalStorageLiquidations().deleteAddressValue(_getKey(LIQUIDATION_CALLER, _account));

        emit AccountRemovedFromLiquidation(_account, now);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyIssuer() {
        require(msg.sender == address(issuer()), "Liquidations: Only the Issuer contract can perform this action");
        _;
    }

    modifier rateNotStale(bytes32 currencyKey) {
        require(!exchangeRates().rateIsStale(currencyKey), "Rate stale or not a synth");
        _;
    }

    /* ========== EVENTS ========== */

    event AccountFlaggedForLiquidation(address indexed account, uint deadline);
    event AccountRemovedFromLiquidation(address indexed account, uint time);
    event LiquidationDelayUpdated(uint newDelay);
    event LiquidationRatioUpdated(uint newRatio);
    event LiquidationPenaltyUpdated(uint newPenalty);
}