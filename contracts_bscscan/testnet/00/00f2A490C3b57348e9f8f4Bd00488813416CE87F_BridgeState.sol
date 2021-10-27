/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: BridgeState.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/BridgeState.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/BridgeState
*
* Contract Dependencies: 
*	- Owned
*	- State
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


contract BridgeState is Owned, State {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    // Sending coin data to external network
    struct Outbounding {
        address account;
        uint amount;
        uint destChainId;
        uint periodId;
    }

    // Getting coin data from external network
    struct Inbounding {
        address account;
        uint amount;
        uint srcChainId;
        uint srcOutboundingId;
        bool claimed;
    }

    struct OutboundPeriod {
        uint periodId;
        uint startTime;
        uint[] outboundingIds;
        bool processed;
    }

    // Managing authorization
    mapping(bytes32 => mapping(address => bool)) public roles;
    // Network status. If false, network is not ready for bridge.
    mapping(uint => bool) public networkOpened;
    // Account's outbounding request ids, address => periodId => outboundingIds
    mapping(address => mapping(uint => uint[])) public accountOutboundings;
    // Account's inbounding ids to be claimed.
    mapping(address => uint[]) public accountInboundings;
    // ChainId => SrcOutboundingId => bool, It prevents double append inbounding request
    mapping(uint => mapping(uint => bool)) public srcOutboundingIdRegistered;
    // Outbound periods by its id
    mapping(uint => OutboundPeriod) public outboundPeriods;

    // The outbound period id list to be processed
    uint[] public outboundPeriodIdsToProcess;

    // Inbounding ids to Inbounding
    Inbounding[] public inboundings;
    // Outbounding ids to Outbounding
    Outbounding[] public outboundings;

    bytes32 private constant ROLE_VALIDATOR = "Validator";

    uint public numberOfOutboundPerPeriod = 10;
    uint public periodDuration = 300;

    // total transferred amount
    uint public totalOutboundAmount = 0;
    // total claimed amount
    uint public totalInboundAmount = 0;

    // Current Outbound PeriodId, starts from 0
    uint public currentOutboundPeriodId;

    event SetRole(bytes32 role, address target, bool set);
    event OutboundingAppended(address indexed from, uint amount, uint destChainId, uint outboundId, uint periodId);
    event InboundingAppended(address indexed from, uint amount, uint srcChainId, uint srcOutboundingId, uint inboundId);
    event InboundingClaimed(uint inboundId);
    event PeriodProcessed(uint periodId);
    event NetworkStatusChanged(uint chainId, bool changedTo);
    event PeriodClosed(uint periodId);

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {
        outboundPeriods[0] = OutboundPeriod(0, now, new uint[](0), false);
    }

    // ---- VIEWS

    function isOnRole(bytes32 _roleKey, address _account) external view returns (bool) {
        return roles[_roleKey][_account];
    }

    function outboundingsLength() external view returns (uint) {
        return outboundings.length;
    }

    function inboundingsLength() external view returns (uint) {
        return inboundings.length;
    }

    function outboundIdsInPeriod(uint _outboundPeriodId) external view returns (uint[] memory) {
        return outboundPeriods[_outboundPeriodId].outboundingIds;
    }

    function accountOutboundingsInPeriod(address _account, uint _period) external view returns (uint[] memory) {
        return accountOutboundings[_account][_period];
    }

    function applicableInboundIds(address _account) external view returns (uint[] memory) {
        return accountInboundings[_account];
    }

    function outboundRequestIdsInPeriod(address _account, uint _periodId) external view returns (uint[] memory) {
        return accountOutboundings[_account][_periodId];
    }

    function periodIdsToProcess() external view returns (uint[] memory) {
        return outboundPeriodIdsToProcess;
    }

    // ---- MUTATIVE

    function appendOutboundingRequest(
        address _account,
        uint _amount,
        uint _destChainIds
    ) external onlyAssociatedContract {
        _appendOutboundingRequest(_account, _amount, _destChainIds);
    }

    function appendMultipleInboundingRequests(
        address[] calldata _accounts,
        uint[] calldata _amounts,
        uint[] calldata _srcChainIds,
        uint[] calldata _srcOutboundingIds
    ) external onlyValidator {
        uint length = _accounts.length;
        require(length > 0, "Input length is invalid");
        require(
            _amounts.length == length && _srcChainIds.length == length && _srcOutboundingIds.length == length,
            "Input length is not matched"
        );

        for (uint i = 0; i < _amounts.length; i++) {
            _appendInboundingRequest(_accounts[i], _amounts[i], _srcChainIds[i], _srcOutboundingIds[i]);
        }
    }

    function appendInboundingRequest(
        address _account,
        uint _amount,
        uint _srcChainId,
        uint _srcOutboundingId
    ) external onlyValidator {
        require(_appendInboundingRequest(_account, _amount, _srcChainId, _srcOutboundingId), "Append inbounding failed");
    }

    function claimInbound(uint _index, uint _amount) external onlyAssociatedContract {
        Inbounding storage _inbounding = inboundings[_index];

        require(!_inbounding.claimed, "This inbounding has already been claimed");

        _inbounding.claimed = true;
        totalInboundAmount = totalInboundAmount.add(_amount);

        emit InboundingClaimed(_index);

        uint[] storage ids = accountInboundings[_inbounding.account];
        uint _accountIndex;
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == _index) {
                _accountIndex = i;

                break;
            }
        }

        if (_accountIndex < ids.length - 1) {
            for (uint i = _accountIndex; i < ids.length - 1; i++) {
                ids[i] = ids[i + 1];
            }
        }

        delete ids[ids.length - 1];
        ids.length--;
    }

    function closeOutboundPeriod() external onlyValidator {
        require(outboundPeriods[currentOutboundPeriodId].outboundingIds.length > 0, "No outbounding request is in period");

        _closeAndOpenOutboundPeriod();
    }

    function processOutboundPeriod(uint _outboundPeriodId) external onlyValidator {
        require(outboundPeriods[_outboundPeriodId].startTime > 0, "This period id is not started yet");
        require(_isPeriodOnTheProcessList(_outboundPeriodId), "Period is not on the process list");
        require(!outboundPeriods[_outboundPeriodId].processed, "Period has already been processed");

        uint[] storage ids = outboundPeriodIdsToProcess;
        uint _index;
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == _outboundPeriodId) {
                _index = i;

                break;
            }
        }

        if (_index < ids.length - 1) {
            for (uint i = _index; i < ids.length - 1; i++) {
                ids[i] = ids[i + 1];
            }
        }

        delete ids[ids.length - 1];
        ids.length--;

        outboundPeriods[_outboundPeriodId].processed = true;

        emit PeriodProcessed(_outboundPeriodId);
    }

    // ---- INTERNAL

    function _appendOutboundingRequest(
        address _account,
        uint _amount,
        uint _destChainId
    ) internal {
        require(networkOpened[_destChainId], "Invalid target network");

        uint nextOutboundingId = outboundings.length;

        accountOutboundings[_account][currentOutboundPeriodId].push(nextOutboundingId);

        outboundings.push(Outbounding(_account, _amount, _destChainId, currentOutboundPeriodId));

        totalOutboundAmount = totalOutboundAmount.add(_amount);

        // The first outbounding request will newly start the period
        if (outboundPeriods[currentOutboundPeriodId].outboundingIds.length == 0) {
            outboundPeriods[currentOutboundPeriodId].startTime = now;
        }
        outboundPeriods[currentOutboundPeriodId].outboundingIds.push(nextOutboundingId);

        emit OutboundingAppended(_account, _amount, _destChainId, nextOutboundingId, currentOutboundPeriodId);

        _periodRefresher();
    }

    function _appendInboundingRequest(
        address _account,
        uint _amount,
        uint _srcChainId,
        uint _srcOutboundingId
    ) internal returns (bool) {
        require(!srcOutboundingIdRegistered[_srcChainId][_srcOutboundingId], "Request id is already registered to inbound");

        srcOutboundingIdRegistered[_srcChainId][_srcOutboundingId] = true;

        uint nextInboundingId = inboundings.length;
        inboundings.push(Inbounding(_account, _amount, _srcChainId, _srcOutboundingId, false));
        accountInboundings[_account].push(nextInboundingId);

        emit InboundingAppended(_account, _amount, _srcChainId, _srcOutboundingId, nextInboundingId);

        return true;
    }

    function _periodRefresher() internal {
        if (_periodIsStaled()) {
            _closeAndOpenOutboundPeriod();
        }
    }

    function _periodIsStaled() internal view returns (bool) {
        uint periodStartTime = outboundPeriods[currentOutboundPeriodId].startTime;
        if (outboundPeriods[currentOutboundPeriodId].outboundingIds.length >= numberOfOutboundPerPeriod) return true;
        if (now.sub(periodStartTime) > periodDuration) return true;

        return false;
    }

    function _closeAndOpenOutboundPeriod() internal {
        outboundPeriodIdsToProcess.push(currentOutboundPeriodId);

        emit PeriodClosed(currentOutboundPeriodId);

        currentOutboundPeriodId = currentOutboundPeriodId.add(1);

        outboundPeriods[currentOutboundPeriodId] = OutboundPeriod(currentOutboundPeriodId, now, new uint[](0), false);
    }

    function _isPeriodOnTheProcessList(uint _outboundPeriodId) internal view returns (bool) {
        for (uint i = 0; i < outboundPeriodIdsToProcess.length; i++) {
            if (outboundPeriodIdsToProcess[i] == _outboundPeriodId) {
                return true;
            }
        }

        return false;
    }

    // ---- Admins ----

    function setRole(
        bytes32 _roleKey,
        address _target,
        bool _set
    ) external onlyOwner {
        roles[_roleKey][_target] = _set;

        emit SetRole(_roleKey, _target, _set);
    }

    function setNumberOfOutboundPerPeriod(uint _number) external onlyOwner {
        require(_number > 0, "Number should larger than zero");

        numberOfOutboundPerPeriod = _number;
    }

    function setPeriodDuration(uint _time) external onlyOwner {
        require(_time > 0, "Time cannot be zero");

        periodDuration = _time;
    }

    function setNetworkStatus(uint _chainId, bool _setTo) external onlyOwner {
        networkOpened[_chainId] = _setTo;

        emit NetworkStatusChanged(_chainId, _setTo);
    }

    modifier onlyValidator() {
        require(roles[ROLE_VALIDATOR][msg.sender], "Caller is not validator");
        _;
    }
}