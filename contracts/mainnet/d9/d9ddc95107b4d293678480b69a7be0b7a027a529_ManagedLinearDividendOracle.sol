// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/library/WadRayMath.sol


/******************
@title WadRayMath library
@notice borrowed from Aave V1 open source code https://raw.githubusercontent.com/aave/aave-protocol/master/contracts/libraries/WadRayMath.sol
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }
    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    /**
    * @dev calculates base^exp. The code uses the ModExp precompile
    * @return z base^exp, in ray
    */
    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }

}

// File: openzeppelin-solidity/contracts/GSN/Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/access/Roles.sol


/**
 * @title Roles
 * @notice copied from openzeppelin-solidity
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/access/WhitelistAdminRole.sol


/**
 * @title WhitelistAdminRole
 * @notice copied from openzeppelin-solidity
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: contracts/access/WhitelistedRole.sol


/**
 * @title WhitelistedRole
 * @notice copied from openzeppelin-solidity
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/oracle/ILinearDividendOracle.sol


/**
 * @title ILinearDividendOracle
 * @notice provides dividend information and calculation strategies for linear dividends.
*/
interface ILinearDividendOracle {

    /**
     * @notice calculate the total dividend accrued since last dividend checkpoint to now
     * @param tokenAmount           amount of token being held
     * @param timestamp             timestamp to start calculating dividend accrued
     * @param fromIndex             index in the dividend history that the timestamp falls into
     * @return amount of dividend accrued in 1e18, and the latest dividend index
     */
    function calculateAccruedDividends(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex
    ) external view returns (uint256, uint256);

    /**
     * @notice calculate the total dividend accrued since last dividend checkpoint to (inclusive) a given dividend index
     * @param tokenAmount           amount of token being held
     * @param timestamp             timestamp to start calculating dividend accrued
     * @param fromIndex             index in the dividend history that the timestamp falls into
     * @param toIndex               index in the dividend history to stop the calculation at, inclusive
     * @return amount of dividend accrued in 1e18, dividend index and timestamp to use for remaining dividends
     */
    function calculateAccruedDividendsBounded(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice get the current dividend index
     * @return the latest dividend index
     */
    function getCurrentIndex() external view returns (uint256);

    /**
     * @notice return the current dividend accrual rate, in USD per second
     * @return dividend in USD per second
     */
    function getCurrentValue() external view returns (uint256);

    /**
     * @notice return the dividend accrual rate, in USD per second, of a given dividend index
     * @return dividend in USD per second of the corresponding dividend phase.
     */
    function getHistoricalValue(uint256 dividendIndex) external view returns (uint256);
}

// File: contracts/oracle/ManagedLinearDividendOracle.sol


/**
 * @title ManagedLinearDividendOracle
 * @notice Provides managed linear dividend rate queries, and calculations
*/
contract ManagedLinearDividendOracle is ILinearDividendOracle, WhitelistedRole {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    event DividendUpdated(uint256 value, uint256 timestamp);

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    struct CalcReturnInfo {
        uint256 dividendInWad;
        uint256 index;
        uint256 timestamp;
    }

    /**
    * @dev records one phase of a given dividend rate
    **/
    struct DividendPhase {
        // amount of usd accrued per second per token in 1e27
        uint256 USDPerSecondInRay;

        // timestamp for start of this dividend phase
        uint256 start;

        // timestamp for end of this dividend phase
        uint256 end;
    }

    DividendPhase[] internal _dividendPhases;


    constructor(uint256 USDPerAnnumInWad) public {
        _addWhitelisted(msg.sender);

        newDividendPhase(USDPerAnnumInWad);
    }

    /**
     * @notice calculate the total dividend accrued since last dividend checkpoint to now
     * @dev this contains a unbounded loop, use calculateAccruedDividendBounded for determimistic gas cost
     * @param tokenAmount           amount of token being held
     * @param timestamp             timestamp to start calculating dividend accrued
     * @param fromIndex             index in the dividend history that the timestamp falls into
     * @return amount of dividend accrued in 1e18, and the latest dividend index
     */
    function calculateAccruedDividends(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex
    ) external view virtual override returns (uint256, uint256) {
        (uint256 totalDividendInWad, uint256 resultIndex,) = calculateAccruedDividendsBounded(
            tokenAmount,
            timestamp,
            fromIndex,
            _dividendPhases.length.sub(1)
        );

        return (totalDividendInWad, resultIndex);
    }

    /**
     * @notice calculate the total dividend accrued since last dividend checkpoint to a given dividend index
     * @param tokenAmount           amount of token being held
     * @param timestamp             timestamp to start calculating dividend accrued
     * @param fromIndex             index in the dividend history that the timestamp falls into
     * @param toIndex               index in the dividend history to stop the calculation at
     * @return amount of dividend accrued in 1e18, dividend index and timestamp to use for remaining dividends
     */
    function calculateAccruedDividendsBounded(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex,
        uint256 toIndex
    ) public view virtual override returns (uint256, uint256, uint256){
        require(toIndex < _dividendPhases.length, "toIndex out of bounds");
        require(fromIndex <= toIndex, "fromIndex must be smaller than or equal to toIndex");

        // culumative dividend per token, in ray
        uint256 dividendPerToken = 0;

        uint256 lastIndex = _dividendPhases.length.sub(1);

        // sanity check, timestamp must match fromIndex
        DividendPhase storage firstPhase = _dividendPhases[fromIndex];
        require(timestamp >= firstPhase.start, "Timestamp must be within the specified starting phase");


        if (fromIndex == toIndex && toIndex == lastIndex) {
            // only calculating the last dividend phase
            dividendPerToken = calculatePhaseDividend(timestamp, block.timestamp, firstPhase.USDPerSecondInRay);
        } else {
            // start the 1st phase calculation from the timestamp to phase end
            dividendPerToken = calculatePhaseDividend(timestamp, firstPhase.end, firstPhase.USDPerSecondInRay);

            for (uint256 i = fromIndex.add(1); i <= toIndex && i < lastIndex; i = i.add(1)) {
                DividendPhase storage phase = _dividendPhases[i];

                uint256 phaseDividend = calculatePhaseDividend(phase.start, phase.end, phase.USDPerSecondInRay);

                dividendPerToken = dividendPerToken.add(phaseDividend);
            }

            if (toIndex == lastIndex) {
                DividendPhase storage lastPhase = _dividendPhases[lastIndex];

                uint256 phaseDividend = calculatePhaseDividend(lastPhase.start, block.timestamp, lastPhase.USDPerSecondInRay);

                dividendPerToken = dividendPerToken.add(phaseDividend);
            }
        }

        // reduce number of local variables to avoid stack too deep
        CalcReturnInfo memory result = CalcReturnInfo(0, 0, 0);

        if (toIndex == lastIndex) {
            result.index = lastIndex;
            result.timestamp = block.timestamp;
        } else {
            result.index = toIndex.add(1);
            result.timestamp = _dividendPhases[result.index].start;
        }

        result.dividendInWad = tokenAmount
            .wadToRay()
            .rayMul(dividendPerToken)
            .rayToWad();

        return (result.dividendInWad, result.index, result.timestamp);
    }

    /**
     * @notice get the current dividend index
     * @return the latest dividend index
     */
    function getCurrentIndex() external view virtual override returns (uint256) {
        return _dividendPhases.length.sub(1);
    }


    /**
     * @notice return the current dividend accrual rate, in USD per second
     * @dev the returned value in 1e18 may not be precise enough
     * @return dividend in USD per second
     */
    function getCurrentValue() external view virtual override returns (uint256) {
        return getHistoricalValue(_dividendPhases.length.sub(1));
    }


    /**
     * @notice return the dividend accrual rate, in USD per second, of a given dividend index
     * @dev the returned value in 1e18 may not be precise enough
     * @return dividend in USD per second of the corresponding dividend phase.
     */
    function getHistoricalValue(uint256 dividendIndex) public view virtual override returns (uint256) {
        (uint256 USDPerSecondInRay,,) = getPreciseDividendData(dividendIndex);

        return USDPerSecondInRay.rayToWad();
    }

    /**
     * @notice return the precise dividend accural rate in 1e27 for a given dividend index
     * @return dividend in USD per second, and timestamp, of the corresponding dividend index
     */
    function getPreciseDividendData(uint256 dividendIndex) public view virtual returns (uint256, uint256, uint256) {
        require(dividendIndex < _dividendPhases.length, "Dividend index out of bounds");

        // storage type here points to existing storage, thus consuming less gas than memory
        DividendPhase storage dividendPhase = _dividendPhases[dividendIndex];

        return (dividendPhase.USDPerSecondInRay, dividendPhase.start, dividendPhase.end);
    }

    /**
     * @notice admin can update the dividend accrual rate by creating a new dividend phase
     * @param USDPerAnnumInWad     the new USD per annum accrued in 1e18
     * @return  true if success
     */
    function newDividendPhase(uint256 USDPerAnnumInWad) public onlyWhitelisted returns (bool) {
        uint256 rateInRay = USDPerAnnumInWadToPerSecondInRay(USDPerAnnumInWad);

        if (_dividendPhases.length > 0) {
            DividendPhase storage previousDividendPhase = _dividendPhases[_dividendPhases.length.sub(1)];

            // phase.end is exclusive in sub calc, thus end of the previous phase should equal start of next phase
            previousDividendPhase.end = block.timestamp;
        }

        DividendPhase memory newPhase = DividendPhase({ USDPerSecondInRay: rateInRay, start: block.timestamp, end: 0});
        _dividendPhases.push(newPhase);
        return true;
    }


    /**
     * @notice convenience method for converting annual dividends to per second dividends with higher precision
     * @param USDPerAnnumInWad       amount of USD accrued over a year in 1e18
     * @return amount of USD accrued per second in 1e27
     */
    function USDPerAnnumInWadToPerSecondInRay(uint256 USDPerAnnumInWad) public pure returns (uint256) {
        return USDPerAnnumInWad
            .wadToRay()
            .div(SECONDS_PER_YEAR);
    }

    /**
     * @notice calculate the dividend between a time range
     * @param start         start of dividend phase
     * @param end           end of dividend phase
     * @param USDPerSecondInRay     dividend accrual rate
     * @return amount of USD accrued per second in 1e27
     */
    function calculatePhaseDividend(uint256 start, uint256 end, uint256 USDPerSecondInRay) public pure returns (uint256) {
        return end
            .sub(start, "Phase start end mismatch")
            .mul(USDPerSecondInRay);
    }
}