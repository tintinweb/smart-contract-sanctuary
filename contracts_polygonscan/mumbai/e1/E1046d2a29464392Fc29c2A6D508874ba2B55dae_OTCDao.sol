/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: OTCDao.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/OTCDao.sol
* Docs: https://docs.synthetix.io/contracts/OTCDao
*
* Contract Dependencies: 
*	- IAddressResolver
*	- IOTCDao
*	- MixinResolver
*	- Owned
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2022 Synthetix
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


// Inheritance


// Libraries


// reffer


contract OTCDao is Owned, IOTCDao, MixinResolver {
    struct NoCollateral {
        bool verified;
        uint256 usedNoCollateralCount;
    }

    struct AdjudicationInfo {
        // id
        uint256 id;
        // deal id
        uint256 dealID;
        // plaintiff
        address plaintiff;
        // defendant
        address defendant;
        // adjudicator
        address adjudicator;
        // winner
        address winner;
        // evidence path in ipfs
        string evidence;
        // defendant explanation
        string explanation;
        // verdict
        string verdict;
        // progress
        AdjudicationState progress;
        uint256 cTime;
        uint256 uTime;
    }

    // name list who need has verified unique verify source
    mapping(address => NoCollateral) public verifiedList;
    // name list who is disallowed for trading for ever
    mapping(address => bool) public blackList;
    // record how many time a user violate rule
    mapping(address => uint256) public violationCount;
    // record adjudication info
    mapping(uint256 => AdjudicationInfo) public adjudications;
    // increase AdjudicationInfo count
    uint256 public adjudicationCount;
    // respond expired period
    uint256 public respondExpiredPeriod = 3 days;
    // compensate rate for victim
    uint256 public daoCompensationRatio = 0.5 ether;
    uint256 public selfCompensationRatio = 1 ether;
    // max trade chances with no collateral
    uint256 public maxNoCollateralTradeCount = 1;

    bytes32 private constant CONTRACT_OTC = "OTC";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_OTC;
    }

    function otc() internal view returns (IOTC) {
        return IOTC(requireAndGetAddress(CONTRACT_OTC));
    }

    function setCompensationRatio(uint256 _daoCompensationRatio, uint256 _selfCompensationRatio) public onlyOwner {
        daoCompensationRatio = _daoCompensationRatio;
        selfCompensationRatio = _selfCompensationRatio;
    }

    function setRespondExpiredPeriod(uint256 period) public onlyOwner {
        respondExpiredPeriod = period;
    }

    function setMaxNoCollateralTradeCount(uint256 count) public onlyOwner {
        maxNoCollateralTradeCount = count;
    }

    function addToVerifyList(address who) public onlyOwner {
        if (!verifiedList[who].verified) {
            verifiedList[who] = NoCollateral({verified: true, usedNoCollateralCount: 0});
        }

        emit UpdateVerifiedList(msg.sender, who, ListAction.Added);
    }

    function useOneChance(address who) public onlyOwnerOrOTC {
        if (verifiedList[who].verified) {
            verifiedList[who].usedNoCollateralCount++;
        }

        emit UpdateVerifiedList(msg.sender, who, ListAction.Updated);
    }

    function isInVerifyList(address who) public view returns (bool) {
        return verifiedList[who].verified;
    }

    function needCollateral(address who) public view returns (bool) {
        return !verifiedList[who].verified || (verifiedList[who].usedNoCollateralCount >= maxNoCollateralTradeCount);
    }

    function removeFromVerifyList(address who) public onlyOwner {
        delete verifiedList[who];

        emit UpdateVerifiedList(msg.sender, who, ListAction.Removed);
    }

    function addToBlackList(address who) public onlyOwnerOrOTC {
        blackList[who] = true;

        emit UpdateBlackList(msg.sender, who, ListAction.Added);
    }

    function removeFromBlackList(address who) public onlyOwner {
        delete blackList[who];

        emit UpdateBlackList(msg.sender, who, ListAction.Removed);
    }

    function increaseViolation(address who) internal {
        violationCount[who]++;

        emit UpdateViolationCount(msg.sender, who);
    }

    function isInBlackList(address who) public view returns (bool) {
        return blackList[who];
    }

    function applyAdjudication(uint256 dealID, string memory evidence) public dealAdjudicatable(dealID) {
        require(adjudications[dealID].cTime == 0, "Adjudication has existed!");

        (bool _, address maker, address taker) = otc().getDealInfo(dealID);

        address defendant;
        if (maker == msg.sender) {
            defendant = taker;
        } else if (taker == msg.sender) {
            defendant = maker;
        } else {
            revert("Invalid plaintiff!");
        }

        adjudications[dealID] = AdjudicationInfo({
            id: dealID,
            dealID: dealID,
            plaintiff: msg.sender,
            defendant: defendant,
            winner: address(0),
            adjudicator: address(0),
            evidence: evidence,
            explanation: "",
            verdict: "",
            progress: AdjudicationState.Applied,
            cTime: block.timestamp,
            uTime: block.timestamp
        });

        emit UpdateAdjudication(msg.sender, dealID);
        adjudicationCount++;
    }

    function respondAdjudication(uint256 dealID, string memory explanation) public {
        AdjudicationInfo storage adjudicationInfo = adjudications[dealID];

        require(adjudicationInfo.cTime > 0, "Adjudication not exist!");

        require(adjudicationInfo.progress == AdjudicationState.Applied, "Adjudication adjudicated!");

        require(msg.sender == adjudicationInfo.defendant, "Only defendant can respond!");

        require(block.timestamp < (adjudicationInfo.uTime + respondExpiredPeriod), "Respond exceed expired period!");

        adjudicationInfo.explanation = explanation;
        adjudicationInfo.progress = AdjudicationState.Responded;
        adjudicationInfo.uTime = block.timestamp;

        emit UpdateAdjudication(msg.sender, adjudicationInfo.id);
    }

    function adjudicate(
        uint256 dealID,
        address winner,
        string memory verdict
    ) public {
        AdjudicationInfo storage adjudicationInfo = adjudications[dealID];

        // Adjudication exist
        require(adjudicationInfo.cTime > 0, "Adjudication not exist!");

        // respond time has passed
        require((adjudicationInfo.cTime + respondExpiredPeriod) <= block.timestamp, "RespondExpiredPeriod is valid!");

        // Adjudication not adjudicated
        require(adjudicationInfo.progress != AdjudicationState.Adjudicated, "Adjudication adjudicated!");

        // if defendant dose not respond in respondExpiredPeriod, deal shall be adjudicated to plaintiff,
        // or the DAO give the result
        if (adjudicationInfo.progress == AdjudicationState.Responded) {
            require(msg.sender == owner, "Only the DAO can adjudicate!");

            // defendant has respond where the DAO shall give the result
            otc().adjudicateDeal(adjudicationInfo.dealID, winner, daoCompensationRatio);
            adjudicationInfo.winner = winner;
            adjudicationInfo.verdict = verdict;
        } else {
            // defendant has not respond where the result adjudicated to plaintiff
            // all Collateral go to winner
            winner = adjudicationInfo.plaintiff;
            otc().adjudicateDeal(adjudicationInfo.dealID, winner, selfCompensationRatio);
            adjudicationInfo.winner = adjudicationInfo.plaintiff;
            adjudicationInfo.verdict = "Defendant did not respond";
        }
        adjudicationInfo.adjudicator = msg.sender;
        adjudicationInfo.progress = AdjudicationState.Adjudicated;
        adjudicationInfo.uTime = block.timestamp;

        // update Violation count
        if (winner == adjudicationInfo.plaintiff) {
            increaseViolation(adjudicationInfo.defendant);
        } else {
            increaseViolation(adjudicationInfo.plaintiff);
        }

        emit UpdateAdjudication(msg.sender, adjudicationInfo.id);
    }

    modifier onlyOwnerOrOTC {
        require((msg.sender == owner || msg.sender == requireAndGetAddress(CONTRACT_OTC)), "Only owner or OTC!");
        _;
    }

    modifier dealAdjudicatable(uint256 dealID) {
        require(otc().hasDeal(dealID), "Deal not exists!");
        require(otc().isDealExpired(dealID), "Deal is not expired!");
        require(!otc().isDealClosed(dealID), "Deal closed!");
        _;
    }
}