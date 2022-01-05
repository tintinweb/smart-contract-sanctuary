/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/governance/implementation/GovernedBase.sol

pragma solidity 0.7.6;


/**
 * @title Governed Base
 * @notice This abstract base class defines behaviors for a governed contract.
 * @dev This class is abstract so that specific behaviors can be defined for the constructor.
 *   Contracts should not be left ungoverned, but not all contract will have a constructor
 *   (for example those pre-defined in genesis).
 **/
abstract contract GovernedBase {
    address public governance;
    address public proposedGovernance;
    bool private initialised;

    event GovernanceProposed(address proposedGovernance);
    event GovernanceUpdated (address oldGovernance, address newGoveranance);

    modifier onlyGovernance () {
        require (msg.sender == governance, "only governance");
        _;
    }

    constructor(address _governance) {
        if (_governance != address(0)) {
            initialise(_governance);
        }
    }

    /**
     * @notice First of a two step process for turning over governance to another address.
     * @param _governance The address to propose to receive governance role.
     * @dev Must hold governance to propose another address.
     */
    function proposeGovernance(address _governance) external onlyGovernance {
        proposedGovernance = _governance;
        emit GovernanceProposed(_governance);
    }

    /**
     * @notice Once proposed, claimant can claim the governance role as the second of a two-step process.
     */
    function claimGovernance() external {
        require(msg.sender == proposedGovernance, "not claimaint");

        emit GovernanceUpdated(governance, proposedGovernance);
        governance = proposedGovernance;
        proposedGovernance = address(0);
    }

    /**
     * @notice In a one-step process, turn over governance to another address.
     * @dev Must hold governance to transfer.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        emit GovernanceUpdated(governance, _governance);
        governance = _governance;
        proposedGovernance = address(0);
    }

    /**
     * @notice Initialize the governance address if not first initialized.
     */
    function initialise(address _governance) public virtual {
        require(initialised == false, "initialised != false");

        initialised = true;
        emit GovernanceUpdated(governance, _governance);
        governance = _governance;
        proposedGovernance = address(0);
    }
}


// File @openzeppelin/contracts/math/[email protected]

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/token/lib/CheckPointHistory.sol

/**
 * @title Check Point History library
 * @notice A contract to manage checkpoints as of a given block.
 * @dev Store value history by block number with detachable state.
 **/
library CheckPointHistory {
    using SafeMath for uint256;

    /**
     * @dev `CheckPoint` is the structure that attaches a block number to a
     *  given value; the block number attached is the one that last changed the
     *  value
     **/
    struct CheckPoint {
        // `fromBlock` is the block number that the value was generated from
        uint256 fromBlock;
        // `value` is the amount of tokens at a specific block number
        uint256 value;
    }

    struct CheckPointHistoryState {
        // `checkpoints` is an array that tracks values at non-contiguous block numbers
        CheckPoint[] checkpoints;
        // `checkpoints` before `startIndex` have been deleted
        // INVARIANT: checkpoints.length == 0 || startIndex < checkpoints.length      (strict!)
        uint256 startIndex;
    }

    /**
     * @notice Binary search of _checkpoints array.
     * @param _checkpoints An array of CheckPoint to search.
     * @param _startIndex Smallest possible index to be returned.
     * @param _blockNumber The block number to search for.
     */
    function _indexOfGreatestBlockLessThan(
        CheckPoint[] storage _checkpoints, 
        uint256 _startIndex,
        uint256 _blockNumber
    )
        private view 
        returns (uint256 index)
    {
        // Binary search of the value by given block number in the array
        uint256 min = _startIndex;
        uint256 max = _checkpoints.length.sub(1);
        while (max > min) {
            uint256 mid = (max.add(min).add(1)).div(2);
            if (_checkpoints[mid].fromBlock <= _blockNumber) {
                min = mid;
            } else {
                max = mid.sub(1);
            }
        }
        return min;
    }

    /**
     * @notice Queries the value at a specific `_blockNumber`
     * @param _self A CheckPointHistoryState instance to manage.
     * @param _blockNumber The block number of the value active at that time
     * @return _value The value at `_blockNumber`     
     **/
    function valueAt(
        CheckPointHistoryState storage _self, 
        uint256 _blockNumber
    )
        internal view 
        returns (uint256 _value)
    {
        uint256 historyCount = _self.checkpoints.length;

        // No _checkpoints, return 0
        if (historyCount == 0) return 0;

        // Shortcut for the actual value (extra optimized for current block, to save one storage read)
        // historyCount - 1 is safe, since historyCount != 0
        if (_blockNumber >= block.number || _blockNumber >= _self.checkpoints[historyCount - 1].fromBlock) {
            return _self.checkpoints[historyCount - 1].value;
        }
        
        // guard values at start    
        uint256 startIndex = _self.startIndex;
        if (_blockNumber < _self.checkpoints[startIndex].fromBlock) {
            // reading data before `startIndex` is only safe before first cleanup
            require(startIndex == 0, "CheckPointHistory: reading from cleaned-up block");
            return 0;
        }

        // Find the block with number less than or equal to block given
        uint256 index = _indexOfGreatestBlockLessThan(_self.checkpoints, startIndex, _blockNumber);

        return _self.checkpoints[index].value;
    }

    /**
     * @notice Queries the value at `block.number`
     * @param _self A CheckPointHistoryState instance to manage.
     * @return _value The value at `block.number`
     **/
    function valueAtNow(CheckPointHistoryState storage _self) internal view returns (uint256 _value) {
        return valueAt(_self, block.number);
    }

    /**
     * @notice Writes the value at the current block.
     * @param _self A CheckPointHistoryState instance to manage.
     * @param _value Value to write.
     **/
    function writeValue(
        CheckPointHistoryState storage _self, 
        uint256 _value
    )
        internal
    {
        uint256 historyCount = _self.checkpoints.length;
        if (historyCount == 0) {
            // checkpoints array empty, push new CheckPoint
            _self.checkpoints.push(CheckPoint({fromBlock: block.number, value: _value}));
        } else {
            // historyCount - 1 is safe, since historyCount != 0
            CheckPoint storage lastCheckpoint = _self.checkpoints[historyCount - 1];
            uint256 lastBlock = lastCheckpoint.fromBlock;
            // slither-disable-next-line incorrect-equality
            if (block.number == lastBlock) {
                // If last check point is the current block, just update
                lastCheckpoint.value = _value;
            } else {
                // we should never have future blocks in history
                assert (block.number > lastBlock);
                // push new CheckPoint
                _self.checkpoints.push(CheckPoint({fromBlock: block.number, value: _value}));
            }
        }
    }
    
    /**
     * Delete at most `_count` of the oldest checkpoints.
     * At least one checkpoint at or before `_cleanupBlockNumber` will remain 
     * (unless the history was empty to start with).
     */    
    function cleanupOldCheckpoints(
        CheckPointHistoryState storage _self, 
        uint256 _count,
        uint256 _cleanupBlockNumber
    )
        internal
        returns (uint256)
    {
        if (_cleanupBlockNumber == 0) return 0;   // optimization for when cleaning is not enabled
        uint256 length = _self.checkpoints.length;
        if (length == 0) return 0;
        uint256 startIndex = _self.startIndex;
        // length - 1 is safe, since length != 0 (check above)
        uint256 endIndex = Math.min(startIndex.add(_count), length - 1);    // last element can never be deleted
        uint256 index = startIndex;
        // we can delete `checkpoint[index]` while the next checkpoint is at `_cleanupBlockNumber` or before
        while (index < endIndex && _self.checkpoints[index + 1].fromBlock <= _cleanupBlockNumber) {
            delete _self.checkpoints[index];
            index++;
        }
        if (index > startIndex) {   // index is the first not deleted index
            _self.startIndex = index;
        }
        return index - startIndex;  // safe: index >= startIndex at start and then increases
    }
}


// File contracts/utils/implementation/SafePct.sol

/**
 * @dev Compute percentages safely without phantom overflows.
 *
 * Intermediate operations can overflow even when the result will always
 * fit into computed type. Developers usually
 * assume that overflows raise errors. `SafePct` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafePct {
    using SafeMath for uint256;
    /**
     * Requirements:
     *
     * - intermediate operations must revert on overflow
     */
    function mulDiv(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        require(z > 0, "Division by zero");

        if (x == 0) return 0;
        uint256 xy = x * y;
        if (xy / x == y) { // no overflow happened - same as in SafeMath mul
            return xy / z;
        }

        //slither-disable-next-line divide-before-multiply
        uint256 a = x / z;
        uint256 b = x % z; // x = a * z + b

        //slither-disable-next-line divide-before-multiply
        uint256 c = y / z;
        uint256 d = y % z; // y = c * z + d

        return (a.mul(c).mul(z)).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(z));
    }
}


// File contracts/token/lib/DelegationHistory.sol



/**
 * @title DelegationHistory library
 * @notice A contract to manage checkpoints as of a given block.
 * @dev Store value history by block number with detachable state.
 **/
library DelegationHistory {
    using SafeMath for uint256;
    using SafePct for uint256;

    uint256 public constant MAX_DELEGATES_BY_PERCENT = 2;
    string private constant MAX_DELEGATES_MSG = "Max delegates exceeded";
    
    /**
     * @dev `CheckPoint` is the structure that attaches a block number to a
     *  given value; the block number attached is the one that last changed the
     *  value
     **/
    struct CheckPoint {
        // `fromBlock` is the block number that the value was generated from
        uint256 fromBlock;
        // the list of active delegates at this time
        address[] delegates;
        // the values delegated to the corresponding delegate at this time
        uint256[] values;
    }

    struct CheckPointHistoryState {
        // `checkpoints` is an array that tracks delegations at non-contiguous block numbers
        CheckPoint[] checkpoints;
        // `checkpoints` before `startIndex` have been deleted
        // INVARIANT: checkpoints.length == 0 || startIndex < checkpoints.length      (strict!)
        uint256 startIndex;
    }

    /**
     * @notice Queries the value at a specific `_blockNumber`
     * @param _self A CheckPointHistoryState instance to manage.
     * @param _delegate The delegate for which we need value.
     * @param _blockNumber The block number of the value active at that time
     * @return _value The value of the `_delegate` at `_blockNumber`     
     **/
    function valueOfAt(
        CheckPointHistoryState storage _self, 
        address _delegate, 
        uint256 _blockNumber
    )
        internal view 
        returns (uint256 _value)
    {
        (bool found, uint256 index) = _findGreatestBlockLessThan(_self.checkpoints, _self.startIndex, _blockNumber);
        if (!found) return 0;

        // find the delegate and return the corresponding value
        CheckPoint storage cp = _self.checkpoints[index];
        uint256 length = cp.delegates.length;
        for (uint256 i = 0; i < length; i++) {
            if (cp.delegates[i] == _delegate) {
                return cp.values[i];
            }
        }
        return 0;   // _delegate not found
    }

    /**
     * @notice Queries the value at `block.number`
     * @param _self A CheckPointHistoryState instance to manage.
     * @param _delegate The delegate for which we need value.
     * @return _value The value at `block.number`
     **/
    function valueOfAtNow(
        CheckPointHistoryState storage _self, 
        address _delegate
    )
        internal view
        returns (uint256 _value)
    {
        return valueOfAt(_self, _delegate, block.number);
    }

    /**
     * @notice Writes the value at the current block.
     * @param _self A CheckPointHistoryState instance to manage.
     * @param _delegate The delegate tu update.
     * @param _value The new value to set for this delegate (value `0` deletes `_delegate` from the list).
     **/
    function writeValue(
        CheckPointHistoryState storage _self, 
        address _delegate, 
        uint256 _value
    )
        internal
    {
        uint256 historyCount = _self.checkpoints.length;
        if (historyCount == 0) {
            // checkpoints array empty, push new CheckPoint
            if (_value != 0) {
                CheckPoint storage cp = _self.checkpoints.push();
                cp.fromBlock = block.number;
                cp.delegates.push(_delegate);
                cp.values.push(_value);
            }
        } else {
            // historyCount - 1 is safe, since historyCount != 0
            CheckPoint storage lastCheckpoint = _self.checkpoints[historyCount - 1];
            uint256 lastBlock = lastCheckpoint.fromBlock;
            // slither-disable-next-line incorrect-equality
            if (block.number == lastBlock) {
                // If last check point is the current block, just update
                _updateDelegates(lastCheckpoint, _delegate, _value);
            } else {
                // we should never have future blocks in history
                assert(block.number > lastBlock); 
                // last check point block is before
                CheckPoint storage cp = _self.checkpoints.push();
                cp.fromBlock = block.number;
                _copyAndUpdateDelegates(cp, lastCheckpoint, _delegate, _value);
            }
        }
    }
    
    /**
     * Get all percentage delegations active at a time.
     * @param _self A CheckPointHistoryState instance to manage.
     * @param _blockNumber The block number to query. 
     * @return _delegates The active percentage delegates at the time. 
     * @return _values The delegates' values at the time. 
     **/
    function delegationsAt(
        CheckPointHistoryState storage _self,
        uint256 _blockNumber
    )
        internal view
        returns (
            address[] memory _delegates,
            uint256[] memory _values
        )
    {
        (bool found, uint256 index) = _findGreatestBlockLessThan(_self.checkpoints, _self.startIndex, _blockNumber);
        if (!found) {
            return (new address[](0), new uint256[](0));
        }

        // copy delegates and values to memory arrays
        // (to prevent caller updating the stored value)
        CheckPoint storage cp = _self.checkpoints[index];
        uint256 length = cp.delegates.length;
        _delegates = new address[](length);
        _values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            _delegates[i] = cp.delegates[i];
            _values[i] = cp.values[i];
        }
    }
    
    /**
     * Get all percentage delegations active now.
     * @param _self A CheckPointHistoryState instance to manage.
     * @return _delegates The active percentage delegates. 
     * @return _values The delegates' values. 
     **/
    function delegationsAtNow(
        CheckPointHistoryState storage _self
    )
        internal view
        returns (address[] memory _delegates, uint256[] memory _values)
    {
        return delegationsAt(_self, block.number);
    }
    
    /**
     * Get the number of delegations.
     * @param _self A CheckPointHistoryState instance to query.
     * @param _blockNumber The block number to query. 
     * @return _count Count of delegations at the time.
     **/
    function countAt(
        CheckPointHistoryState storage _self,
        uint256 _blockNumber
    )
        internal view
        returns (uint256 _count)
    {
        (bool found, uint256 index) = _findGreatestBlockLessThan(_self.checkpoints, _self.startIndex, _blockNumber);
        if (!found) return 0;
        return _self.checkpoints[index].delegates.length;
    }
    
    /**
     * Get the sum of all delegation values.
     * @param _self A CheckPointHistoryState instance to query.
     * @param _blockNumber The block number to query. 
     * @return _total Total delegation value at the time.
     **/
    function totalValueAt(
        CheckPointHistoryState storage _self, 
        uint256 _blockNumber
    )
        internal view
        returns (uint256 _total)
    {
        (bool found, uint256 index) = _findGreatestBlockLessThan(_self.checkpoints, _self.startIndex, _blockNumber);
        if (!found) return 0;
        
        CheckPoint storage cp = _self.checkpoints[index];
        uint256 length = cp.values.length;
        _total = 0;
        for (uint256 i = 0; i < length; i++) {
            _total = _total.add(cp.values[i]);
        }
    }

    /**
     * Get the sum of all delegation values.
     * @param _self A CheckPointHistoryState instance to query.
     * @return _total Total delegation value at the time.
     **/
    function totalValueAtNow(
        CheckPointHistoryState storage _self
    )
        internal view
        returns (uint256 _total)
    {
        return totalValueAt(_self, block.number);
    }

    /**
     * Get the sum of all delegation values, every one scaled by `_mul/_div`.
     * @param _self A CheckPointHistoryState instance to query.
     * @param _mul The multiplier.
     * @param _div The divisor.
     * @param _blockNumber The block number to query. 
     * @return _total Total scaled delegation value at the time.
     **/
    function scaledTotalValueAt(
        CheckPointHistoryState storage _self, 
        uint256 _mul,
        uint256 _div,
        uint256 _blockNumber
    )
        internal view
        returns (uint256 _total)
    {
        (bool found, uint256 index) = _findGreatestBlockLessThan(_self.checkpoints, _self.startIndex, _blockNumber);
        if (!found) return 0;
        
        CheckPoint storage cp = _self.checkpoints[index];
        uint256 length = cp.values.length;
        _total = 0;
        for (uint256 i = 0; i < length; i++) {
            _total = _total.add(cp.values[i].mulDiv(_mul, _div));
        }
    }

    /**
     * Clear all delegations at this moment.
     * @param _self A CheckPointHistoryState instance to manage.
     */    
    function clear(CheckPointHistoryState storage _self) internal {
        if (_self.checkpoints.length > 0) {
            // add an empty checkpoint
            CheckPoint storage cp = _self.checkpoints.push();
            cp.fromBlock = block.number;
        }
    }

    /**
     * Delete at most `_count` of the oldest checkpoints.
     * At least one checkpoint at or before `_cleanupBlockNumber` will remain 
     * (unless the history was empty to start with).
     */    
    function cleanupOldCheckpoints(
        CheckPointHistoryState storage _self, 
        uint256 _count,
        uint256 _cleanupBlockNumber
    )
        internal
        returns (uint256)
    {
        if (_cleanupBlockNumber == 0) return 0;   // optimization for when cleaning is not enabled
        uint256 length = _self.checkpoints.length;
        if (length == 0) return 0;
        uint256 startIndex = _self.startIndex;
        // length - 1 is safe, since length != 0 (check above)
        uint256 endIndex = Math.min(startIndex.add(_count), length - 1);    // last element can never be deleted
        uint256 index = startIndex;
        // we can delete `checkpoint[index]` while the next checkpoint is at `_cleanupBlockNumber` or before
        while (index < endIndex && _self.checkpoints[index + 1].fromBlock <= _cleanupBlockNumber) {
            delete _self.checkpoints[index];
            index++;
        }
        if (index > startIndex) {   // index is the first not deleted index
            _self.startIndex = index;
        }
        return index - startIndex;  // safe: index = startIndex at start and increases in loop
    }

    /////////////////////////////////////////////////////////////////////////////////
    // helper functions for writeValueAt
    
    function _copyAndUpdateDelegates(
        CheckPoint storage _cp, 
        CheckPoint storage _orig, 
        address _delegate, 
        uint256 _value
    )
        private
    {
        uint256 length = _orig.delegates.length;
        bool updated = false;
        for (uint256 i = 0; i < length; i++) {
            address origDelegate = _orig.delegates[i];
            if (origDelegate == _delegate) {
                // copy delegate, but with new value
                _appendDelegate(_cp, origDelegate, _value, i);
                updated = true;
            } else {
                // just copy the delegate with original value
                _appendDelegate(_cp, origDelegate, _orig.values[i], i);
            }
        }
        if (!updated) {
            // delegate is not in the original list, so add it
            _appendDelegate(_cp, _delegate, _value, length);
        }
    }

    function _updateDelegates(CheckPoint storage _cp, address _delegate, uint256 _value) private {
        uint256 length = _cp.delegates.length;
        uint256 i = 0;
        while (i < length && _cp.delegates[i] != _delegate) ++i;
        if (i < length) {
            if (_value != 0) {
                _cp.values[i] = _value;
            } else {
                _deleteDelegate(_cp, i, length - 1);  // length - 1 is safe:  0 <= i < length
            }
        } else {
            _appendDelegate(_cp, _delegate, _value, length);
        }
    }
    
    function _appendDelegate(CheckPoint storage _cp, address _delegate, uint256 _value, uint256 _length) private {
        if (_value != 0) {
            require(_length < MAX_DELEGATES_BY_PERCENT, MAX_DELEGATES_MSG);
            _cp.delegates.push(_delegate);
            _cp.values.push(_value);
        }
    }
    
    function _deleteDelegate(CheckPoint storage _cp, uint256 _index, uint256 _last) private {
        if (_index < _last) {
            _cp.delegates[_index] = _cp.delegates[_last];
            _cp.values[_index] = _cp.values[_last];
        }
        _cp.delegates.pop();
        _cp.values.pop();
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    // helper functions for querying
    
    /**
     * @notice Binary search of _checkpoints array.
     * @param _checkpoints An array of CheckPoint to search.
     * @param _startIndex Smallest possible index to be returned.
     * @param _blockNumber The block number to search for.
     */
    function _binarySearchGreatestBlockLessThan(
        CheckPoint[] storage _checkpoints, 
        uint256 _startIndex,
        uint256 _blockNumber
    )
        private view
        returns (uint256 _index)
    {
        // Binary search of the value by given block number in the array
        uint256 min = _startIndex;
        uint256 max = _checkpoints.length.sub(1);
        while (max > min) {
            uint256 mid = (max.add(min).add(1)).div(2);
            if (_checkpoints[mid].fromBlock <= _blockNumber) {
                min = mid;
            } else {
                max = mid.sub(1);
            }
        }
        return min;
    }

    /**
     * @notice Binary search of _checkpoints array. Extra optimized for the common case when we are 
     *   searching for the last block.
     * @param _checkpoints An array of CheckPoint to search.
     * @param _startIndex Smallest possible index to be returned.
     * @param _blockNumber The block number to search for.
     * @return _found true if value was found (only `false` if `_blockNumber` is before first 
     *   checkpoint or the checkpoint array is empty)
     * @return _index index of the newest block with number less than or equal `_blockNumber`
     */
    function _findGreatestBlockLessThan(
        CheckPoint[] storage _checkpoints, 
        uint256 _startIndex,
        uint256 _blockNumber
    )
        private view
        returns (
            bool _found,
            uint256 _index
        )
    {
        uint256 historyCount = _checkpoints.length;
        if (historyCount == 0) {
            _found = false;
        } else if (_blockNumber >= block.number || _blockNumber >= _checkpoints[historyCount - 1].fromBlock) {
            // _blockNumber >= block.number saves one storage read for reads at current block
            _found = true;
            _index = historyCount - 1;  // safe, historyCount != 0 in this branch
        } else if (_blockNumber < _checkpoints[_startIndex].fromBlock) {
            // reading data before `_startIndex` is only safe before first cleanup
            require(_startIndex == 0, "DelegationHistory: reading from cleaned-up block");
            _found = false;
        } else {
            _found = true;
            _index = _binarySearchGreatestBlockLessThan(_checkpoints, _startIndex, _blockNumber);
        }
    }
}


// File contracts/token/lib/PercentageDelegation.sol


/**
 * @title PercentageDelegation library
 * @notice Only handles percentage delegation  
 * @notice A library to manage a group of _delegates for allocating voting power by a delegator.
 **/
library PercentageDelegation {
    using CheckPointHistory for CheckPointHistory.CheckPointHistoryState;
    using DelegationHistory for DelegationHistory.CheckPointHistoryState;
    using SafeMath for uint256;
    using SafePct for uint256;

    uint256 public constant MAX_BIPS = 10000;
    string private constant MAX_BIPS_MSG = "Max delegation bips exceeded";
    
    /**
     * @dev `DelegationState` is the state structure used by this library to contain/manage
     *  a grouing of _delegates (a PercentageDelegation) for a delegator.
     */
    struct DelegationState {
        // percentages by _delegates
        DelegationHistory.CheckPointHistoryState delegation;
    }

    /**
     * @notice Add or replace an existing _delegate with allocated vote power in basis points.
     * @param _self A DelegationState instance to manage.
     * @param _delegate The address of the _delegate to add/replace
     * @param _bips Allocation of the delegation specified in basis points (1/100 of 1 percent)
     * @dev If you send a `_bips` of zero, `_delegate` will be deleted if one
     *  exists in the delegation; if zero and `_delegate` does not exist, it will not be added.
     */
    function addReplaceDelegate(
        DelegationState storage _self, 
        address _delegate, 
        uint256 _bips
    )
        internal
    {
        // Check for max delegation basis points
        assert(_bips <= MAX_BIPS);

        // Change the delegate's percentage
        _self.delegation.writeValue(_delegate, _bips);
        
        // check the total
        require(_self.delegation.totalValueAtNow() <= MAX_BIPS, MAX_BIPS_MSG);
    }

    /**
     * @notice Get the total of the explicit vote power delegation bips of all delegates at given block.
     * @param _self A DelegationState instance to manage.
     * @param _blockNumber The block to query.
     * @return _totalBips The total vote power bips delegated.
     */
    function getDelegatedTotalAt(
        DelegationState storage _self,
        uint256 _blockNumber
    )
        internal view
        returns (uint256 _totalBips)
    {
        return _self.delegation.totalValueAt(_blockNumber);
    }

    /**
     * @notice Get the total of the bips vote power delegation bips of all _delegates.
     * @param _self A DelegationState instance to manage.
     * @return _totalBips The total vote power bips delegated.
     */
    function getDelegatedTotal(
        DelegationState storage _self
    )
        internal view
        returns (uint256 _totalBips)
    {
        return _self.delegation.totalValueAtNow();
    }

    /**
     * @notice Given a _delegate address, return the bips of the vote power delegation.
     * @param _self A DelegationState instance to manage.
     * @param _delegate The delegate address to find.
     * @param _blockNumber The block to query.
     * @return _bips The percent of vote power allocated to the delegate address.
     */
    function getDelegatedValueAt(
        DelegationState storage _self, 
        address _delegate,
        uint256 _blockNumber
    )
        internal view 
        returns (uint256 _bips)
    {
        return _self.delegation.valueOfAt(_delegate, _blockNumber);
    }

    /**
     * @notice Given a delegate address, return the bips of the vote power delegation.
     * @param _self A DelegationState instance to manage.
     * @param _delegate The delegate address to find.
     * @return _bips The percent of vote power allocated to the delegate address.
     */
    function getDelegatedValue(
        DelegationState storage _self, 
        address _delegate
    )
        internal view
        returns (uint256 _bips)
    {
        return _self.delegation.valueOfAtNow(_delegate);
    }

    /**
     * @notice Returns lists of delegate addresses and corresponding values at given block.
     * @param _self A DelegationState instance to manage.
     * @param _blockNumber The block to query.
     * @return _delegates Positional array of delegation addresses.
     * @return _values Positional array of delegation percents specified in basis points (1/100 or 1 percent)
     */
    function getDelegationsAt(
        DelegationState storage _self,
        uint256 _blockNumber
    )
        internal view 
        returns (
            address[] memory _delegates,
            uint256[] memory _values
        )
    {
        return _self.delegation.delegationsAt(_blockNumber);
    }
    
    /**
     * @notice Returns lists of delegate addresses and corresponding values.
     * @param _self A DelegationState instance to manage.
     * @return _delegates Positional array of delegation addresses.
     * @return _values Positional array of delegation percents specified in basis points (1/100 or 1 percent)
     */
    function getDelegations(
        DelegationState storage _self
    )
        internal view
        returns (
            address[] memory _delegates,
            uint256[] memory _values
        ) 
    {
        return _self.delegation.delegationsAtNow();
    }
    
    /**
     * Get the number of delegations.
     * @param _self A DelegationState instance to manage.
     * @param _blockNumber The block number to query. 
     * @return _count Count of delegations at the time.
     **/
    function getCountAt(
        DelegationState storage _self,
        uint256 _blockNumber
    )
        internal view 
        returns (uint256 _count)
    {
        return _self.delegation.countAt(_blockNumber);
    }

    /**
     * Get the number of delegations.
     * @param _self A DelegationState instance to manage.
     * @return _count Count of delegations at the time.
     **/
    function getCount(
        DelegationState storage _self
    )
        internal view
        returns (uint256 _count)
    {
        return _self.delegation.countAt(block.number);
    }
    
    /**
     * @notice Get the total amount (absolute) of the vote power delegation of all delegates.
     * @param _self A DelegationState instance to manage.
     * @param _balance Owner's balance.
     * @return _totalAmount The total vote power amount delegated.
     */
    function getDelegatedTotalAmountAt(
        DelegationState storage _self, 
        uint256 _balance,
        uint256 _blockNumber
    )
        internal view 
        returns (uint256 _totalAmount)
    {
        return _self.delegation.scaledTotalValueAt(_balance, MAX_BIPS, _blockNumber);
    }
    
    /**
     * @notice Clears all delegates.
     * @param _self A DelegationState instance to manage.
     * @dev Delegation mode remains PERCENTAGE, even though the delgation is now empty.
     */
    function clear(DelegationState storage _self) internal {
        _self.delegation.clear();
    }


    /**
     * Delete at most `_count` of the oldest checkpoints.
     * At least one checkpoint at or before `_cleanupBlockNumber` will remain 
     * (unless the history was empty to start with).
     */    
    function cleanupOldCheckpoints(
        DelegationState storage _self, 
        uint256 _count,
        uint256 _cleanupBlockNumber
    )
        internal
        returns (uint256)
    {
        return _self.delegation.cleanupOldCheckpoints(_count, _cleanupBlockNumber);
    }
}


// File contracts/token/lib/CheckPointsByAddress.sol

/**
 * @title Check Points By Address library
 * @notice A contract to manage checkpoint history for a collection of addresses.
 * @dev Store value history by address, and then by block number.
 **/
library CheckPointsByAddress {
    using SafeMath for uint256;
    using CheckPointHistory for CheckPointHistory.CheckPointHistoryState;

    struct CheckPointsByAddressState {
        // `historyByAddress` is the map that stores the check point history of each address
        mapping(address => CheckPointHistory.CheckPointHistoryState) historyByAddress;
    }

    /**
    /**
     * @notice Send `amount` value to `to` address from `from` address.
     * @param _self A CheckPointsByAddressState instance to manage.
     * @param _from Address of the history of from values 
     * @param _to Address of the history of to values 
     * @param _amount The amount of value to be transferred
     **/
    function transmit(
        CheckPointsByAddressState storage _self, 
        address _from, 
        address _to, 
        uint256 _amount
    )
        internal
    {
        // Shortcut
        if (_amount == 0) return;

        // Both from and to can never be zero
        assert(!(_from == address(0) && _to == address(0)));

        // Update transferer value
        if (_from != address(0)) {
            // Compute the new from balance
            uint256 newValueFrom = valueOfAtNow(_self, _from).sub(_amount);
            writeValue(_self, _from, newValueFrom);
        }

        // Update transferee value
        if (_to != address(0)) {
            // Compute the new to balance
            uint256 newValueTo = valueOfAtNow(_self, _to).add(_amount);
            writeValue(_self, _to, newValueTo);
        }
    }

    /**
     * @notice Queries the value of `_owner` at a specific `_blockNumber`.
     * @param _self A CheckPointsByAddressState instance to manage.
     * @param _owner The address from which the value will be retrieved.
     * @param _blockNumber The block number to query for the then current value.
     * @return The value at `_blockNumber` for `_owner`.
     **/
    function valueOfAt(
        CheckPointsByAddressState storage _self, 
        address _owner, 
        uint256 _blockNumber
    )
        internal view
        returns (uint256)
    {
        // Get history for _owner
        CheckPointHistory.CheckPointHistoryState storage history = _self.historyByAddress[_owner];
        // Return value at given block
        return history.valueAt(_blockNumber);
    }

    /**
     * @notice Get the value of the `_owner` at the current `block.number`.
     * @param _self A CheckPointsByAddressState instance to manage.
     * @param _owner The address of the value is being requested.
     * @return The value of `_owner` at the current block.
     **/
    function valueOfAtNow(CheckPointsByAddressState storage _self, address _owner) internal view returns (uint256) {
        return valueOfAt(_self, _owner, block.number);
    }

    /**
     * @notice Writes the `value` at the current block number for `_owner`.
     * @param _self A CheckPointsByAddressState instance to manage.
     * @param _owner The address of `_owner` to write.
     * @param _value The value to write.
     * @dev Sender must be the owner of the contract.
     **/
    function writeValue(
        CheckPointsByAddressState storage _self, 
        address _owner, 
        uint256 _value
    )
        internal
    {
        // Get history for _owner
        CheckPointHistory.CheckPointHistoryState storage history = _self.historyByAddress[_owner];
        // Write the value
        history.writeValue(_value);
    }
    
    /**
     * Delete at most `_count` of the oldest checkpoints.
     * At least one checkpoint at or before `_cleanupBlockNumber` will remain 
     * (unless the history was empty to start with).
     */    
    function cleanupOldCheckpoints(
        CheckPointsByAddressState storage _self, 
        address _owner, 
        uint256 _count,
        uint256 _cleanupBlockNumber
    )
        internal
        returns (uint256)
    {
        if (_owner != address(0)) {
            return _self.historyByAddress[_owner].cleanupOldCheckpoints(_count, _cleanupBlockNumber);
        }
        return 0;
    }
}


// File contracts/token/lib/ExplicitDelegation.sol



/**
 * @title ExplicitDelegation library
 * @notice A library to manage a group of delegates for allocating voting power by a delegator.
 **/
library ExplicitDelegation {
    using CheckPointHistory for CheckPointHistory.CheckPointHistoryState;
    using CheckPointsByAddress for CheckPointsByAddress.CheckPointsByAddressState;
    using SafeMath for uint256;
    using SafePct for uint256;

    /**
     * @dev `DelegationState` is the state structure used by this library to contain/manage
     *  a grouing of delegates (a ExplicitDelegation) for a delegator.
     */
    struct DelegationState {
        CheckPointHistory.CheckPointHistoryState delegatedTotal;

        // `delegatedVotePower` is a map of delegators pointing to a map of delegates
        // containing a checkpoint history of delegated vote power balances.
        CheckPointsByAddress.CheckPointsByAddressState delegatedVotePower;
    }

    /**
     * @notice Add or replace an existing _delegate with new vote power (explicit).
     * @param _self A DelegationState instance to manage.
     * @param _delegate The address of the _delegate to add/replace
     * @param _amount Allocation of the delegation as explicit amount
     */
    function addReplaceDelegate(
        DelegationState storage _self, 
        address _delegate, 
        uint256 _amount
    )
        internal
    {
        uint256 prevAmount = _self.delegatedVotePower.valueOfAtNow(_delegate);
        uint256 newTotal = _self.delegatedTotal.valueAtNow().sub(prevAmount, "Total < 0").add(_amount);
        _self.delegatedVotePower.writeValue(_delegate, _amount);
        _self.delegatedTotal.writeValue(newTotal);
    }
    

    /**
     * Delete at most `_count` of the oldest checkpoints.
     * At least one checkpoint at or before `_cleanupBlockNumber` will remain 
     * (unless the history was empty to start with).
     */    
    function cleanupOldCheckpoints(
        DelegationState storage _self, 
        address _owner, 
        uint256 _count,
        uint256 _cleanupBlockNumber
    )
        internal
        returns(uint256 _deleted)
    {
        _deleted = _self.delegatedTotal.cleanupOldCheckpoints(_count, _cleanupBlockNumber);
        // safe: cleanupOldCheckpoints always returns the number of deleted elements which is small, so no owerflow
        _deleted += _self.delegatedVotePower.cleanupOldCheckpoints(_owner, _count, _cleanupBlockNumber);
    }
    
    /**
     * @notice Get the _total of the explicit vote power delegation amount.
     * @param _self A DelegationState instance to manage.
     * @param _blockNumber The block to query.
     * @return _total The _total vote power amount delegated.
     */
    function getDelegatedTotalAt(
        DelegationState storage _self, uint256 _blockNumber
    )
        internal view 
        returns (uint256 _total)
    {
        return _self.delegatedTotal.valueAt(_blockNumber);
    }
    
    /**
     * @notice Get the _total of the explicit vote power delegation amount.
     * @param _self A DelegationState instance to manage.
     * @return _total The total vote power amount delegated.
     */
    function getDelegatedTotal(
        DelegationState storage _self
    )
        internal view 
        returns (uint256 _total)
    {
        return _self.delegatedTotal.valueAtNow();
    }
    
    /**
     * @notice Given a delegate address, return the explicit amount of the vote power delegation.
     * @param _self A DelegationState instance to manage.
     * @param _delegate The _delegate address to find.
     * @param _blockNumber The block to query.
     * @return _value The percent of vote power allocated to the _delegate address.
     */
    function getDelegatedValueAt(
        DelegationState storage _self, 
        address _delegate,
        uint256 _blockNumber
    )
        internal view
        returns (uint256 _value)
    {
        return _self.delegatedVotePower.valueOfAt(_delegate, _blockNumber);
    }

    /**
     * @notice Given a delegate address, return the explicit amount of the vote power delegation.
     * @param _self A DelegationState instance to manage.
     * @param _delegate The _delegate address to find.
     * @return _value The percent of vote power allocated to the _delegate address.
     */
    function getDelegatedValue(
        DelegationState storage _self, 
        address _delegate
    )
        internal view 
        returns (uint256 _value)
    {
        return _self.delegatedVotePower.valueOfAtNow(_delegate);
    }
}


// File contracts/token/lib/VotePower.sol


/**
 * @title Vote power library
 * @notice A library to record delegate vote power balances by delegator 
 *  and delegatee.
 **/
library VotePower {
    using CheckPointHistory for CheckPointHistory.CheckPointHistoryState;
    using CheckPointsByAddress for CheckPointsByAddress.CheckPointsByAddressState;
    using SafeMath for uint256;

    /**
     * @dev `VotePowerState` is state structure used by this library to manage vote
     *  power amounts by delegator and it's delegates.
     */
    struct VotePowerState {
        // `votePowerByAddress` is the map that tracks the voting power balance
        //  of each address, by block.
        CheckPointsByAddress.CheckPointsByAddressState votePowerByAddress;
    }

    /**
     * @notice This modifier checks that both addresses are non-zero.
     * @param _delegator A delegator address.
     * @param _delegatee A delegatee address.
     */
    modifier addressesNotZero(address _delegator, address _delegatee) {
        // Both addresses cannot be zero
        assert(!(_delegator == address(0) && _delegatee == address(0)));
        _;
    }

    /**
     * @notice Burn vote power.
     * @param _self A VotePowerState instance to manage.
     * @param _owner The address of the vote power to be burned.
     * @param _amount The amount of vote power to burn.
     */
    function _burn(
        VotePowerState storage _self, 
        address _owner, 
        uint256 _amount
    )
        internal
    {
        // Shortcut
        if (_amount == 0) {
            return;
        }

        // Cannot burn the zero address
        assert(_owner != address(0));

        // Burn vote power for address
        _self.votePowerByAddress.transmit(_owner, address(0), _amount);
    }

    /**
     * @notice Delegate vote power `_amount` to `_delegatee` address from `_delegator` address.
     * @param _delegator Delegator address 
     * @param _delegatee Delegatee address
     * @param _amount The _amount of vote power to send from _delegator to _delegatee
     * @dev Amount recorded at the current block.
     **/
    function delegate(
        VotePowerState storage _self, 
        address _delegator, 
        address _delegatee,
        uint256 _amount
    )
        internal 
        addressesNotZero(_delegator, _delegatee)
    {
        // Shortcut
        if (_amount == 0) {
            return;
        }

        // Transmit vote power
        _self.votePowerByAddress.transmit(_delegator, _delegatee, _amount);
    }

    /**
     * @notice Mint vote power.
     * @param _self A VotePowerState instance to manage.
     * @param _owner The address owning the new vote power.
     * @param _amount The amount of vote power to mint.
     */
    function _mint(
        VotePowerState storage _self, 
        address _owner, 
        uint256 _amount
    )
        internal
    {
        // Shortcut
        if (_amount == 0) {
            return;
        }

        // Cannot mint the zero address
        assert(_owner != address(0));

        // Mint vote power for address
        _self.votePowerByAddress.transmit(address(0), _owner, _amount);
    }

    /**
     * @notice Transmit current vote power `_amount` from `_delegator` to `_delegatee`.
     * @param _delegator Address of delegator.
     * @param _delegatee Address of delegatee.
     * @param _amount Amount of vote power to transmit.
     */
    function transmit(
        VotePowerState storage _self, 
        address _delegator, 
        address _delegatee,
        uint256 _amount
    )
        internal
        addressesNotZero(_delegator, _delegatee)
    {
        _self.votePowerByAddress.transmit(_delegator, _delegatee, _amount);
    }

    /**
     * @notice Undelegate vote power `_amount` from `_delegatee` address 
     *  to `_delegator` address
     * @param _delegator Delegator address 
     * @param _delegatee Delegatee address
     * @param _amount The amount of vote power recovered by delegator from delegatee
     **/
    function undelegate(
        VotePowerState storage _self, 
        address _delegator, 
        address _delegatee,
        uint256 _amount
    )
        internal
        addressesNotZero(_delegator, _delegatee)
    {
        // Shortcut
        if (_amount == 0) {
            return;
        }

        // Recover vote power
        _self.votePowerByAddress.transmit(_delegatee, _delegator, _amount);
    }

    /**
     * Delete at most `_count` of the oldest checkpoints.
     * At least one checkpoint at or before `_cleanupBlockNumber` will remain 
     * (unless the history was empty to start with).
     */    
    function cleanupOldCheckpoints(
        VotePowerState storage _self, 
        address _owner, 
        uint256 _count,
        uint256 _cleanupBlockNumber
    )
        internal
        returns (uint256)
    {
        return _self.votePowerByAddress.cleanupOldCheckpoints(_owner, _count, _cleanupBlockNumber);
    }

    /**
     * @notice Get the vote power of `_who` at `_blockNumber`.
     * @param _self A VotePowerState instance to manage.
     * @param _who Address to get vote power.
     * @param _blockNumber Block number of the block to fetch vote power.
     * @return _votePower The fetched vote power.
     */
    function votePowerOfAt(
        VotePowerState storage _self, 
        address _who, 
        uint256 _blockNumber
    )
        internal view 
        returns(uint256 _votePower)
    {
        return _self.votePowerByAddress.valueOfAt(_who, _blockNumber);
    }

    /**
     * @notice Get the current vote power of `_who`.
     * @param _self A VotePowerState instance to manage.
     * @param _who Address to get vote power.
     * @return _votePower The fetched vote power.
     */
    function votePowerOfAtNow(
        VotePowerState storage _self, 
        address _who
    )
        internal view
        returns(uint256 _votePower)
    {
        return votePowerOfAt(_self, _who, block.number);
    }
}


// File contracts/token/lib/VotePowerCache.sol


/**
 * @title Vote power library
 * @notice A library to record delegate vote power balances by delegator 
 *  and delegatee.
 **/
library VotePowerCache {
    using SafeMath for uint256;
    using VotePower for VotePower.VotePowerState;

    struct RevocationCacheRecord {
        // revoking delegation only affects cached value therefore we have to track
        // the revocation in order not to revoke twice
        // mapping delegatee => revokedValue
        mapping(address => uint256) revocations;
    }
    
    /**
     * @dev `CacheState` is state structure used by this library to manage vote
     *  power amounts by delegator and it's delegates.
     */
    struct CacheState {
        // map keccak256([address, _blockNumber]) -> (value + 1)
        mapping(bytes32 => uint256) valueCache;
        
        // map keccak256([address, _blockNumber]) -> RevocationCacheRecord
        mapping(bytes32 => RevocationCacheRecord) revocationCache;
    }

    /**
    * @notice Get the cached value at given block. If there is no cached value, original
    *    value is returned and stored to cache. Cache never gets stale, because original
    *    value can never change in a past block.
    * @param _self A VotePowerCache instance to manage.
    * @param _votePower A VotePower instance to read from if cache is empty.
    * @param _who Address to get vote power.
    * @param _blockNumber Block number of the block to fetch vote power.
    * precondition: _blockNumber < block.number
    */
    function valueOfAt(
        CacheState storage _self,
        VotePower.VotePowerState storage _votePower,
        address _who,
        uint256 _blockNumber
    )
        internal 
        returns (uint256 _value, bool _createdCache)
    {
        bytes32 key = keccak256(abi.encode(_who, _blockNumber));
        // is it in cache?
        uint256 cachedValue = _self.valueCache[key];
        if (cachedValue != 0) {
            return (cachedValue - 1, false);    // safe, cachedValue != 0
        }
        // read from _votePower
        uint256 votePowerValue = _votePower.votePowerOfAt(_who, _blockNumber);
        _writeCacheValue(_self, key, votePowerValue);
        return (votePowerValue, true);
    }

    /**
    * @notice Get the cached value at given block. If there is no cached value, original
    *    value is returned. Cache is never modified.
    * @param _self A VotePowerCache instance to manage.
    * @param _votePower A VotePower instance to read from if cache is empty.
    * @param _who Address to get vote power.
    * @param _blockNumber Block number of the block to fetch vote power.
    * precondition: _blockNumber < block.number
    */
    function valueOfAtReadonly(
        CacheState storage _self,
        VotePower.VotePowerState storage _votePower,
        address _who,
        uint256 _blockNumber
    )
        internal view 
        returns (uint256 _value)
    {
        bytes32 key = keccak256(abi.encode(_who, _blockNumber));
        // is it in cache?
        uint256 cachedValue = _self.valueCache[key];
        if (cachedValue != 0) {
            return cachedValue - 1;     // safe, cachedValue != 0
        }
        // read from _votePower
        return _votePower.votePowerOfAt(_who, _blockNumber);
    }
    
    /**
    * @notice Delete cached value for `_who` at given block.
    *   Only used for history cleanup.
    * @param _self A VotePowerCache instance to manage.
    * @param _who Address to get vote power.
    * @param _blockNumber Block number of the block to fetch vote power.
    * @return _deleted The number of cache items deleted (always 0 or 1).
    * precondition: _blockNumber < cleanupBlockNumber
    */
    function deleteValueAt(
        CacheState storage _self,
        address _who,
        uint256 _blockNumber
    )
        internal
        returns (uint256 _deleted)
    {
        bytes32 key = keccak256(abi.encode(_who, _blockNumber));
        if (_self.valueCache[key] != 0) {
            delete _self.valueCache[key];
            return 1;
        }
        return 0;
    }
    
    /**
    * @notice Revoke vote power delegation from `from` to `to` at given block.
    *   Updates cached values for the block, so they are the only vote power values respecting revocation.
    * @dev Only delegatees cached value is changed, delegator doesn't get the vote power back; so
    *   the revoked vote power is forfeit for as long as this vote power block is in use. This is needed to
    *   prevent double voting.
    * @param _self A VotePowerCache instance to manage.
    * @param _votePower A VotePower instance to read from if cache is empty.
    * @param _from The delegator.
    * @param _to The delegatee.
    * @param _revokedValue Value of delegation is not stored here, so it must be supplied by caller.
    * @param _blockNumber Block number of the block to modify.
    * precondition: _blockNumber < block.number
    */
    function revokeAt(
        CacheState storage _self,
        VotePower.VotePowerState storage _votePower,
        address _from,
        address _to,
        uint256 _revokedValue,
        uint256 _blockNumber
    )
        internal
    {
        if (_revokedValue == 0) return;
        bytes32 keyFrom = keccak256(abi.encode(_from, _blockNumber));
        if (_self.revocationCache[keyFrom].revocations[_to] != 0) {
            revert("Already revoked");
        }
        // read values and prime cacheOf
        (uint256 valueTo,) = valueOfAt(_self, _votePower, _to, _blockNumber);
        // write new values
        bytes32 keyTo = keccak256(abi.encode(_to, _blockNumber));
        _writeCacheValue(_self, keyTo, valueTo.sub(_revokedValue, "Revoked value too large"));
        // mark as revoked
        _self.revocationCache[keyFrom].revocations[_to] = _revokedValue;
    }
    
    /**
    * @notice Delete revocation from `_from` to `_to` at block `_blockNumber`.
    *   Only used for history cleanup.
    * @param _self A VotePowerCache instance to manage.
    * @param _from The delegator.
    * @param _to The delegatee.
    * @param _blockNumber Block number of the block to modify.
    * precondition: _blockNumber < cleanupBlockNumber
    */
    function deleteRevocationAt(
        CacheState storage _self,
        address _from,
        address _to,
        uint256 _blockNumber
    )
        internal
        returns (uint256 _deleted)
    {
        bytes32 keyFrom = keccak256(abi.encode(_from, _blockNumber));
        RevocationCacheRecord storage revocationRec = _self.revocationCache[keyFrom];
        uint256 value = revocationRec.revocations[_to];
        if (value != 0) {
            delete revocationRec.revocations[_to];
            return 1;
        }
        return 0;
    }

    /**
    * @notice Returns true if `from` has revoked vote pover delgation of `to` in block `_blockNumber`.
    * @param _self A VotePowerCache instance to manage.
    * @param _from The delegator.
    * @param _to The delegatee.
    * @param _blockNumber Block number of the block to fetch result.
    * precondition: _blockNumber < block.number
    */
    function revokedFromToAt(
        CacheState storage _self,
        address _from,
        address _to,
        uint256 _blockNumber
    )
        internal view
        returns (bool revoked)
    {
        bytes32 keyFrom = keccak256(abi.encode(_from, _blockNumber));
        return _self.revocationCache[keyFrom].revocations[_to] != 0;
    }
    
    function _writeCacheValue(CacheState storage _self, bytes32 _key, uint256 _value) private {
        // store to cacheOf (add 1 to differentiate from empty)
        _self.valueCache[_key] = _value.add(1);
    }
}


// File contracts/userInterfaces/IVPContractEvents.sol

interface IVPContractEvents {
    /**
     * Event triggered when an account delegates or undelegates another account. 
     * Definition: `votePowerFromTo(from, to)` is `changed` from `priorVotePower` to `newVotePower`.
     * For undelegation, `newVotePower` is 0.
     *
     * Note: the event is always emitted from VPToken's `writeVotePowerContract`.
     */
    event Delegate(address indexed from, address indexed to, uint256 priorVotePower, uint256 newVotePower);
    
    /**
     * Event triggered only when account `delegator` revokes delegation to `delegatee`
     * for a single block in the past (typically the current vote block).
     *
     * Note: the event is always emitted from VPToken's `writeVotePowerContract` and/or `readVotePowerContract`.
     */
    event Revoke(address indexed delegator, address indexed delegatee, uint256 votePower, uint256 blockNumber);
}


// File contracts/token/implementation/Delegatable.sol


/**
 * @title Delegateable ERC20 behavior
 * @notice An ERC20 Delegateable behavior to delegate voting power
 *  of a token to delegates. This contract orchestrates interaction between
 *  managing a delegation and the vote power allocations that result.
 **/
contract Delegatable is IVPContractEvents {
    using PercentageDelegation for PercentageDelegation.DelegationState;
    using ExplicitDelegation for ExplicitDelegation.DelegationState;
    using SafeMath for uint256;
    using SafePct for uint256;
    using VotePower for VotePower.VotePowerState;
    using VotePowerCache for VotePowerCache.CacheState;

    enum DelegationMode { 
        NOTSET, 
        PERCENTAGE, 
        AMOUNT
    }

    // The number of history cleanup steps executed for every write operation.
    // It is more than 1 to make as certain as possible that all history gets cleaned eventually.
    uint256 private constant CLEANUP_COUNT = 2;
    
    string constant private UNDELEGATED_VP_TOO_SMALL_MSG = 
        "Undelegated vote power too small";

    // Map that tracks delegation mode of each address.
    mapping(address => DelegationMode) private delegationModes;

    // `percentageDelegations` is the map that tracks the percentage voting power delegation of each address.
    // Explicit delegations are tracked directly through votePower.
    mapping(address => PercentageDelegation.DelegationState) private percentageDelegations;
    
    mapping(address => ExplicitDelegation.DelegationState) private explicitDelegations;

    // `votePower` tracks all voting power balances
    VotePower.VotePowerState private votePower;

    // `votePower` tracks all voting power balances
    VotePowerCache.CacheState private votePowerCache;

    // Historic data for the blocks before `cleanupBlockNumber` can be erased,
    // history before that block should never be used since it can be inconsistent.
    uint256 private cleanupBlockNumber;
    
    // Address of the contract that is allowed to call methods for history cleaning.
    address private cleanerContract;
    
    /**
     * Emitted when a vote power cache entry is created.
     * Allows history cleaners to track vote power cache cleanup opportunities off-chain.
     */
    event CreatedVotePowerCache(address _owner, uint256 _blockNumber);
    
    // Most history cleanup opportunities can be deduced from standard events:
    // Transfer(from, to, amount):
    //  - vote power checkpoints for `from` (if nonzero) and `to` (if nonzero)
    //  - vote power checkpoints for percentage delegatees of `from` and `to` are also created,
    //    but they don't have to be checked since Delegate events are also emitted in case of 
    //    percentage delegation vote power change due to delegators balance change
    //  - Note: Transfer event is emitted from VPToken but vote power checkpoint delegationModes
    //    must be called on its writeVotePowerContract
    // Delegate(from, to, priorVP, newVP):
    //  - vote power checkpoints for `from` and `to`
    //  - percentage delegation checkpoint for `from` (if `from` uses percentage delegation mode)
    //  - explicit delegation checkpoint from `from` to `to` (if `from` uses explicit delegation mode)
    // Revoke(from, to, vp, block):
    //  - vote power cache for `from` and `to` at `block`
    //  - revocation cache block from `from` to `to` at `block`
    
    /**
     * Reading from history is not allowed before `cleanupBlockNumber`, since data before that
     * might have been deleted and is thus unreliable.
     */    
    modifier notBeforeCleanupBlock(uint256 _blockNumber) {
        require(_blockNumber >= cleanupBlockNumber, "Delegatable: reading from cleaned-up block");
        _;
    }
    
    /**
     * History cleaning methods can be called only from the cleaner address.
     */
    modifier onlyCleaner {
        require(msg.sender == cleanerContract, "Only cleaner contract");
        _;
    }

    /**
     * @notice (Un)Allocate `_owner` vote power of `_amount` across owner delegate
     *  vote power percentages.
     * @param _owner The address of the vote power owner.
     * @param _priorBalance The owner's balance before change.
     * @param _newBalance The owner's balance after change.
     */
    function _allocateVotePower(address _owner, uint256 _priorBalance, uint256 _newBalance) private {
        // Only proceed if we have a delegation by percentage
        if (delegationModes[_owner] == DelegationMode.PERCENTAGE) {
            // Get the voting delegation for the _owner
            PercentageDelegation.DelegationState storage delegation = percentageDelegations[_owner];
            // Iterate over the delegates
            (address[] memory delegates, uint256[] memory bipses) = delegation.getDelegations();
            for (uint256 i = 0; i < delegates.length; i++) {
                address delegatee = delegates[i];
                // Compute the delegated vote power for the delegatee
                uint256 priorValue = _priorBalance.mulDiv(bipses[i], PercentageDelegation.MAX_BIPS);
                uint256 newValue = _newBalance.mulDiv(bipses[i], PercentageDelegation.MAX_BIPS);
                // Compute new voting power
                if (newValue > priorValue) {
                    // increase (subtraction is safe as newValue > priorValue)
                    votePower.delegate(_owner, delegatee, newValue - priorValue);
                } else {
                    // decrease (subtraction is safe as newValue < priorValue)
                    votePower.undelegate(_owner, delegatee, priorValue - newValue);
                }
                votePower.cleanupOldCheckpoints(_owner, CLEANUP_COUNT, cleanupBlockNumber);
                votePower.cleanupOldCheckpoints(delegatee, CLEANUP_COUNT, cleanupBlockNumber);
                
                emit Delegate(_owner, delegatee, priorValue, newValue);
            }
        }
    }

    /**
     * @notice Burn `_amount` of vote power for `_owner`.
     * @param _owner The address of the _owner vote power to burn.
     * @param _ownerCurrentBalance The current token balance of the owner (which is their allocatable vote power).
     * @param _amount The amount of vote power to burn.
     */
    function _burnVotePower(address _owner, uint256 _ownerCurrentBalance, uint256 _amount) internal {
        // for PERCENTAGE delegation: reduce owner vote power allocations
        // revert with the same error as ERC20 in case transfer exceeds balance
        uint256 newOwnerBalance = _ownerCurrentBalance.sub(_amount, "ERC20: transfer amount exceeds balance");
        _allocateVotePower(_owner, _ownerCurrentBalance, newOwnerBalance);
        // for AMOUNT delegation: is there enough unallocated VP _to burn if explicitly delegated?
        require(_isTransmittable(_owner, _ownerCurrentBalance, _amount), UNDELEGATED_VP_TOO_SMALL_MSG);
        // burn vote power
        votePower._burn(_owner, _amount);
        votePower.cleanupOldCheckpoints(_owner, CLEANUP_COUNT, cleanupBlockNumber);
    }

    /**
     * @notice Get whether `_owner` current delegation can be delegated by percentage.
     * @param _owner Address of delegation to check.
     * @return True if delegation can be delegated by percentage.
     */
    function _canDelegateByPct(address _owner) internal view returns(bool) {
        // Get the delegation mode.
        DelegationMode delegationMode = delegationModes[_owner];
        // Return true if delegation is safe _to store percents, which can also
        // apply if there is not delegation mode set.
        return delegationMode == DelegationMode.NOTSET || delegationMode == DelegationMode.PERCENTAGE;
    }

    /**
     * @notice Get whether `_owner` current delegation can be delegated by amount.
     * @param _owner Address of delegation to check.
     * @return True if delegation can be delegated by amount.
     */
    function _canDelegateByAmount(address _owner) internal view returns(bool) {
        // Get the delegation mode.
        DelegationMode delegationMode = delegationModes[_owner];
        // Return true if delegation is safe to store explicit amounts, which can also
        // apply if there is not delegation mode set.
        return delegationMode == DelegationMode.NOTSET || delegationMode == DelegationMode.AMOUNT;
    }

    /**
     * @notice Delegate `_amount` of voting power to `_to` from `_from`
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _senderCurrentBalance The senders current balance (not their voting power)
     * @param _amount The amount of voting power to be delegated
     **/
    function _delegateByAmount(
        address _from, 
        address _to, 
        uint256 _senderCurrentBalance, 
        uint256 _amount
    )
        internal virtual 
    {
        require (_to != address(0), "Cannot delegate to zero");
        require (_to != _from, "Cannot delegate to self");
        require (_canDelegateByAmount(_from), "Cannot delegate by amount");
        
        // Get the vote power delegation for the sender
        ExplicitDelegation.DelegationState storage delegation = explicitDelegations[_from];
        
        // the prior value
        uint256 priorAmount = delegation.getDelegatedValue(_to);
        
        // Delegate new power
        if (_amount < priorAmount) {
            // Prior amount is greater, just reduce the delegated amount.
            // subtraction is safe since _amount < priorAmount
            votePower.undelegate(_from, _to, priorAmount - _amount);
        } else {
            // Is there enough undelegated vote power?
            uint256 availableAmount = _undelegatedVotePowerOf(_from, _senderCurrentBalance).add(priorAmount);
            require(availableAmount >= _amount, UNDELEGATED_VP_TOO_SMALL_MSG);
            // Increase the delegated amount of vote power.
            // subtraction is safe since _amount >= priorAmount
            votePower.delegate(_from, _to, _amount - priorAmount);
        }
        votePower.cleanupOldCheckpoints(_from, CLEANUP_COUNT, cleanupBlockNumber);
        votePower.cleanupOldCheckpoints(_to, CLEANUP_COUNT, cleanupBlockNumber);
        
        // Add/replace delegate
        delegation.addReplaceDelegate(_to, _amount);
        delegation.cleanupOldCheckpoints(_to, CLEANUP_COUNT, cleanupBlockNumber);

        // update mode if needed
        if (delegationModes[_from] != DelegationMode.AMOUNT) {
            delegationModes[_from] = DelegationMode.AMOUNT;
        }
        
        // emit event for delegation change
        emit Delegate(_from, _to, priorAmount, _amount);
    }

    /**
     * @notice Delegate `_bips` of voting power to `_to` from `_from`
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _senderCurrentBalance The senders current balance (not their voting power)
     * @param _bips The percentage of voting power in basis points (1/100 of 1 percent) to be delegated
     **/
    function _delegateByPercentage(
        address _from, 
        address _to, 
        uint256 _senderCurrentBalance, 
        uint256 _bips
    )
        internal virtual
    {
        require (_to != address(0), "Cannot delegate to zero");
        require (_to != _from, "Cannot delegate to self");
        require (_canDelegateByPct(_from), "Cannot delegate by percentage");
        
        // Get the vote power delegation for the sender
        PercentageDelegation.DelegationState storage delegation = percentageDelegations[_from];

        // Get prior percent for delegate if exists
        uint256 priorBips = delegation.getDelegatedValue(_to);
        uint256 reverseVotePower = 0;
        uint256 newVotePower = 0;

        // Add/replace delegate
        delegation.addReplaceDelegate(_to, _bips);
        delegation.cleanupOldCheckpoints(CLEANUP_COUNT, cleanupBlockNumber);
        
        // First, back out old voting power percentage, if not zero
        if (priorBips != 0) {
            reverseVotePower = _senderCurrentBalance.mulDiv(priorBips, PercentageDelegation.MAX_BIPS);
        }

        // Calculate the new vote power
        if (_bips != 0) {
            newVotePower = _senderCurrentBalance.mulDiv(_bips, PercentageDelegation.MAX_BIPS);
        }

        // Delegate new power
        if (newVotePower < reverseVotePower) {
            // subtraction is safe since newVotePower < reverseVotePower
            votePower.undelegate(_from, _to, reverseVotePower - newVotePower);
        } else {
            // subtraction is safe since newVotePower >= reverseVotePower
            votePower.delegate(_from, _to, newVotePower - reverseVotePower);
        }
        votePower.cleanupOldCheckpoints(_from, CLEANUP_COUNT, cleanupBlockNumber);
        votePower.cleanupOldCheckpoints(_to, CLEANUP_COUNT, cleanupBlockNumber);
        
        // update mode if needed
        if (delegationModes[_from] != DelegationMode.PERCENTAGE) {
            delegationModes[_from] = DelegationMode.PERCENTAGE;
        }

        // emit event for delegation change
        emit Delegate(_from, _to, reverseVotePower, newVotePower);
    }

    /**
     * @notice Get the delegation mode for '_who'. This mode determines whether vote power is
     *  allocated by percentage or by explicit value.
     * @param _who The address to get delegation mode.
     * @return Delegation mode
     */
    function _delegationModeOf(address _who) internal view returns (DelegationMode) {
        return delegationModes[_who];
    }

    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `_bips` of an `_owner`. Returned in two separate positional arrays.
    * @param _owner The address to get delegations.
    * @param _blockNumber The block for which we want to know the delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    */
    function _percentageDelegatesOfAt(
        address _owner,
        uint256 _blockNumber
    )
        internal view
        notBeforeCleanupBlock(_blockNumber) 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips
        )
    {
        PercentageDelegation.DelegationState storage delegation = percentageDelegations[_owner];
        address[] memory allDelegateAddresses;
        uint256[] memory allBips;
        (allDelegateAddresses, allBips) = delegation.getDelegationsAt(_blockNumber);
        // delete revoked addresses
        for (uint256 i = 0; i < allDelegateAddresses.length; i++) {
            if (votePowerCache.revokedFromToAt(_owner, allDelegateAddresses[i], _blockNumber)) {
                allBips[i] = 0;
            }
        }
        uint256 length = 0;
        for (uint256 i = 0; i < allDelegateAddresses.length; i++) {
            if (allBips[i] != 0) length++;
        }
        _delegateAddresses = new address[](length);
        _bips = new uint256[](length);
        uint256 destIndex = 0;
        for (uint256 i = 0; i < allDelegateAddresses.length; i++) {
            if (allBips[i] != 0) {
                _delegateAddresses[destIndex] = allDelegateAddresses[i];
                _bips[destIndex] = allBips[i];
                destIndex++;
            }
        }
    }

    /**
     * @notice Checks if enough undelegated vote power exists to allow a token
     *  transfer to occur if vote power is explicitly delegated.
     * @param _owner The address of transmittable vote power to check.
     * @param _ownerCurrentBalance The current balance of `_owner`.
     * @param _amount The amount to check.
     * @return True is `_amount` is transmittable.
     */
    function _isTransmittable(
        address _owner, 
        uint256 _ownerCurrentBalance, 
        uint256 _amount
    )
        private view returns(bool)
    {
        // Only proceed if we have a delegation by _amount
        if (delegationModes[_owner] == DelegationMode.AMOUNT) {
            // Return true if there is enough vote power _to cover the transfer
            return _undelegatedVotePowerOf(_owner, _ownerCurrentBalance) >= _amount;
        } else {
            // Not delegated by _amount, so transfer always allowed
            return true;
        }
    }

    /**
     * @notice Mint `_amount` of vote power for `_owner`.
     * @param _owner The address of the owner to receive new vote power.
     * @param _amount The amount of vote power to mint.
     */
    function _mintVotePower(address _owner, uint256 _ownerCurrentBalance, uint256 _amount) internal {
        votePower._mint(_owner, _amount);
        votePower.cleanupOldCheckpoints(_owner, CLEANUP_COUNT, cleanupBlockNumber);
        // Allocate newly minted vote power over delegates
        _allocateVotePower(_owner, _ownerCurrentBalance, _ownerCurrentBalance.add(_amount));
    }
    
    /**
    * @notice Revoke the vote power of `_to` at block `_blockNumber`
    * @param _from The address of the delegator
    * @param _to The delegatee address of vote power to revoke.
    * @param _senderBalanceAt The sender's balance at the block to be revoked.
    * @param _blockNumber The block number at which to revoke.
    */
    function _revokeDelegationAt(
        address _from, 
        address _to, 
        uint256 _senderBalanceAt, 
        uint256 _blockNumber
    )
        internal 
        notBeforeCleanupBlock(_blockNumber)
    {
        require(_blockNumber < block.number, "Revoke is only for the past, use undelegate for the present");
        
        // Get amount revoked
        uint256 votePowerRevoked = _votePowerFromToAtNoRevokeCheck(_from, _to, _senderBalanceAt, _blockNumber);
        
        // Revoke vote power
        votePowerCache.revokeAt(votePower, _from, _to, votePowerRevoked, _blockNumber);

        // Emit revoke event
        emit Revoke(_from, _to, votePowerRevoked, _blockNumber);
    }

    /**
    * @notice Transmit `_amount` of vote power `_from` address `_to` address.
    * @param _from The address of the sender.
    * @param _to The address of the receiver.
    * @param _fromCurrentBalance The current token balance of the transmitter.
    * @param _toCurrentBalance The current token balance of the receiver.
    * @param _amount The amount of vote power to transmit.
    */
    function _transmitVotePower(
        address _from, 
        address _to, 
        uint256 _fromCurrentBalance, 
        uint256 _toCurrentBalance,
        uint256 _amount
    )
        internal
    {
        // for PERCENTAGE delegation: reduce sender vote power allocations
        // revert with the same error as ERC20 in case transfer exceeds balance
        uint256 newFromBalance = _fromCurrentBalance.sub(_amount, "ERC20: transfer amount exceeds balance");
        _allocateVotePower(_from, _fromCurrentBalance, newFromBalance);
        // for AMOUNT delegation: transmit vote power _to receiver
        require(_isTransmittable(_from, _fromCurrentBalance, _amount), UNDELEGATED_VP_TOO_SMALL_MSG);
        votePower.transmit(_from, _to, _amount);
        votePower.cleanupOldCheckpoints(_from, CLEANUP_COUNT, cleanupBlockNumber);
        votePower.cleanupOldCheckpoints(_to, CLEANUP_COUNT, cleanupBlockNumber);
        // Allocate receivers new vote power according _to their delegates
        _allocateVotePower(_to, _toCurrentBalance, _toCurrentBalance.add(_amount));
    }

    /**
     * @notice Undelegate all vote power by percentage for `delegation` of `_who`.
     * @param _from The address of the delegator
     * @param _senderCurrentBalance The current balance of message sender.
     * precondition: delegationModes[_who] == DelegationMode.PERCENTAGE
     */
    function _undelegateAllByPercentage(address _from, uint256 _senderCurrentBalance) internal {
        DelegationMode delegationMode = delegationModes[_from];
        if (delegationMode == DelegationMode.NOTSET) return;
        require(delegationMode == DelegationMode.PERCENTAGE,
            "undelegateAll can only be used in percentage delegation mode");
            
        PercentageDelegation.DelegationState storage delegation = percentageDelegations[_from];
        
        // Iterate over the delegates
        (address[] memory delegates, uint256[] memory _bips) = delegation.getDelegations();
        for (uint256 i = 0; i < delegates.length; i++) {
            address to = delegates[i];
            // Compute vote power to be reversed for the delegate
            uint256 reverseVotePower = _senderCurrentBalance.mulDiv(_bips[i], PercentageDelegation.MAX_BIPS);
            // Transmit vote power back to _owner
            votePower.undelegate(_from, to, reverseVotePower);
            votePower.cleanupOldCheckpoints(_from, CLEANUP_COUNT, cleanupBlockNumber);
            votePower.cleanupOldCheckpoints(to, CLEANUP_COUNT, cleanupBlockNumber);
            // Emit vote power reversal event
            emit Delegate(_from, to, reverseVotePower, 0);
        }

        // Clear delegates
        delegation.clear();
        delegation.cleanupOldCheckpoints(CLEANUP_COUNT, cleanupBlockNumber);
    }

    /**
     * @notice Undelegate all vote power by amount delegates for `_from`.
     * @param _from The address of the delegator
     * @param _delegateAddresses Explicit delegation does not store delegatees' addresses, 
     *   so the caller must supply them.
     */
    function _undelegateAllByAmount(
        address _from,
        address[] memory _delegateAddresses
    ) 
        internal 
        returns (uint256 _remainingDelegation)
    {
        DelegationMode delegationMode = delegationModes[_from];
        if (delegationMode == DelegationMode.NOTSET) return 0;
        require(delegationMode == DelegationMode.AMOUNT,
            "undelegateAllExplicit can only be used in explicit delegation mode");
            
        ExplicitDelegation.DelegationState storage delegation = explicitDelegations[_from];
        
        // Iterate over the delegates
        for (uint256 i = 0; i < _delegateAddresses.length; i++) {
            address to = _delegateAddresses[i];
            // Compute vote power _to be reversed for the delegate
            uint256 reverseVotePower = delegation.getDelegatedValue(to);
            if (reverseVotePower == 0) continue;
            // Transmit vote power back _to _owner
            votePower.undelegate(_from, to, reverseVotePower);
            votePower.cleanupOldCheckpoints(_from, CLEANUP_COUNT, cleanupBlockNumber);
            votePower.cleanupOldCheckpoints(to, CLEANUP_COUNT, cleanupBlockNumber);
            // change delagation
            delegation.addReplaceDelegate(to, 0);
            delegation.cleanupOldCheckpoints(to, CLEANUP_COUNT, cleanupBlockNumber);
            // Emit vote power reversal event
            emit Delegate(_from, to, reverseVotePower, 0);
        }
        
        return delegation.getDelegatedTotal();
    }
    
    /**
     * @notice Check if the `_owner` has made any delegations.
     * @param _owner The address of owner to get delegated vote power.
     * @return The total delegated vote power at block.
     */
    function _hasAnyDelegations(address _owner) internal view returns(bool) {
        DelegationMode delegationMode = delegationModes[_owner];
        if (delegationMode == DelegationMode.NOTSET) {
            return false;
        } else if (delegationMode == DelegationMode.AMOUNT) {
            return explicitDelegations[_owner].getDelegatedTotal() > 0;
        } else { // delegationMode == DelegationMode.PERCENTAGE
            return percentageDelegations[_owner].getCount() > 0;
        }
    }

    /**
     * @notice Get the total delegated vote power of `_owner` at some block.
     * @param _owner The address of owner to get delegated vote power.
     * @param _ownerBalanceAt The balance of the owner at that block (not their vote power).
     * @param _blockNumber The block number at which to fetch.
     * @return _votePower The total delegated vote power at block.
     */
    function _delegatedVotePowerOfAt(
        address _owner, 
        uint256 _ownerBalanceAt,
        uint256 _blockNumber
    ) 
        internal view
        notBeforeCleanupBlock(_blockNumber)
        returns(uint256 _votePower)
    {
        // Get the vote power delegation for the _owner
        DelegationMode delegationMode = delegationModes[_owner];
        if (delegationMode == DelegationMode.NOTSET) {
            return 0;
        } else if (delegationMode == DelegationMode.AMOUNT) {
            return explicitDelegations[_owner].getDelegatedTotalAt(_blockNumber);
        } else { // delegationMode == DelegationMode.PERCENTAGE
            return percentageDelegations[_owner].getDelegatedTotalAmountAt(_ownerBalanceAt, _blockNumber);
        }
    }

    /**
     * @notice Get the undelegated vote power of `_owner` at some block.
     * @param _owner The address of owner to get undelegated vote power.
     * @param _ownerBalanceAt The balance of the owner at that block (not their vote power).
     * @param _blockNumber The block number at which to fetch.
     * @return _votePower The undelegated vote power at block.
     */
    function _undelegatedVotePowerOfAt(
        address _owner, 
        uint256 _ownerBalanceAt,
        uint256 _blockNumber
    ) 
        internal view 
        notBeforeCleanupBlock(_blockNumber) 
        returns(uint256 _votePower)
    {
        // Return the current balance less delegations or zero if negative
        uint256 delegated = _delegatedVotePowerOfAt(_owner, _ownerBalanceAt, _blockNumber);
        bool overflow;
        uint256 result;
        (overflow, result) = _ownerBalanceAt.trySub(delegated);
        return result;
    }

    /**
     * @notice Get the undelegated vote power of `_owner`.
     * @param _owner The address of owner to get undelegated vote power.
     * @param _ownerCurrentBalance The current balance of the owner (not their vote power).
     * @return _votePower The undelegated vote power.
     */
    function _undelegatedVotePowerOf(
        address _owner, 
        uint256 _ownerCurrentBalance
    ) 
        internal view 
        returns(uint256 _votePower)
    {
        return _undelegatedVotePowerOfAt(_owner, _ownerCurrentBalance, block.number);
    }
    
    /**
    * @notice Get current delegated vote power `_from` delegator delegated `_to` delegatee.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @return _votePower The delegated vote power.
    */
    function _votePowerFromTo(
        address _from, 
        address _to, 
        uint256 _currentFromBalance
    ) 
        internal view 
        returns(uint256 _votePower)
    {
        // no need for revocation check at current block
        return _votePowerFromToAtNoRevokeCheck(_from, _to, _currentFromBalance, block.number);
    }

    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _fromBalanceAt From's balance at the block `_blockNumber`.
    * @param _blockNumber The block number at which to fetch.
    * @return _votePower The delegated vote power.
    */
    function _votePowerFromToAt(
        address _from, 
        address _to, 
        uint256 _fromBalanceAt, 
        uint256 _blockNumber
    ) 
        internal view 
        notBeforeCleanupBlock(_blockNumber) 
        returns(uint256 _votePower) 
    {
        // if revoked, return 0
        if (votePowerCache.revokedFromToAt(_from, _to, _blockNumber)) return 0;
        return _votePowerFromToAtNoRevokeCheck(_from, _to, _fromBalanceAt, _blockNumber);
    }

    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    *   Private use only - ignores revocations.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _fromBalanceAt From's balance at the block `_blockNumber`.
    * @param _blockNumber The block number at which to fetch.
    * @return _votePower The delegated vote power.
    */
    function _votePowerFromToAtNoRevokeCheck(
        address _from, 
        address _to, 
        uint256 _fromBalanceAt, 
        uint256 _blockNumber
    )
        private view 
        returns(uint256 _votePower)
    {
        // assumed: notBeforeCleanupBlock(_blockNumber)
        DelegationMode delegationMode = delegationModes[_from];
        if (delegationMode == DelegationMode.NOTSET) {
            return 0;
        } else if (delegationMode == DelegationMode.PERCENTAGE) {
            uint256 _bips = percentageDelegations[_from].getDelegatedValueAt(_to, _blockNumber);
            return _fromBalanceAt.mulDiv(_bips, PercentageDelegation.MAX_BIPS);
        } else { // delegationMode == DelegationMode.AMOUNT
            return explicitDelegations[_from].getDelegatedValueAt(_to, _blockNumber);
        }
    }

    /**
     * @notice Get the current vote power of `_who`.
     * @param _who The address to get voting power.
     * @return Current vote power of `_who`.
     */
    function _votePowerOf(address _who) internal view returns(uint256) {
        return votePower.votePowerOfAtNow(_who);
    }

    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function _votePowerOfAt(
        address _who, 
        uint256 _blockNumber
    )
        internal view 
        notBeforeCleanupBlock(_blockNumber) 
        returns(uint256)
    {
        // read cached value for past blocks to respect revocations (and possibly get a cache speedup)
        if (_blockNumber < block.number) {
            return votePowerCache.valueOfAtReadonly(votePower, _who, _blockNumber);
        } else {
            return votePower.votePowerOfAtNow(_who);
        }
    }

    /**
     * Return vote powers for several addresses in a batch.
     * Only works for past blocks.
     * @param _owners The list of addresses to fetch vote power of.
     * @param _blockNumber The block number at which to fetch.
     * @return _votePowers A list of vote powers corresponding to _owners.
     */    
    function _batchVotePowerOfAt(
        address[] memory _owners, 
        uint256 _blockNumber
    ) 
        internal view 
        notBeforeCleanupBlock(_blockNumber) 
        returns(uint256[] memory _votePowers)
    {
        require(_blockNumber < block.number, "Can only be used for past blocks");
        _votePowers = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            // read through cache, much faster if it has been set
            _votePowers[i] = votePowerCache.valueOfAtReadonly(votePower, _owners[i], _blockNumber);
        }
    }
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    *   Reads/updates cache and upholds revocations.
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function _votePowerOfAtCached(
        address _who, 
        uint256 _blockNumber
    )
        internal 
        notBeforeCleanupBlock(_blockNumber)
        returns(uint256) 
    {
        require(_blockNumber < block.number, "Can only be used for past blocks");
        (uint256 vp, bool createdCache) = votePowerCache.valueOfAt(votePower, _who, _blockNumber);
        if (createdCache) emit CreatedVotePowerCache(_who, _blockNumber);
        return vp;
    }
    
    /**
     * Set the cleanup block number.
     */
    function _setCleanupBlockNumber(uint256 _blockNumber) internal {
        require(_blockNumber >= cleanupBlockNumber, "Cleanup block number must never decrease");
        require(_blockNumber < block.number, "Cleanup block must be in the past");
        cleanupBlockNumber = _blockNumber;
    }

    /**
     * Get the cleanup block number.
     */
    function _cleanupBlockNumber() internal view returns (uint256) {
        return cleanupBlockNumber;
    }
    
    /**
     * Set the contract that is allowed to call history cleaning methods.
     */
    function _setCleanerContract(address _cleanerContract) internal {
        cleanerContract = _cleanerContract;
    }
    
    // history cleanup methods
    
    /**
     * Delete vote power checkpoints that expired (i.e. are before `cleanupBlockNumber`).
     * Method can only be called from the `cleanerContract` (which may be a proxy to external cleaners).
     * @param _owner vote power owner account address
     * @param _count maximum number of checkpoints to delete
     * @return the number of checkpoints deleted
     */    
    function votePowerHistoryCleanup(address _owner, uint256 _count) external onlyCleaner returns (uint256) {
        return votePower.cleanupOldCheckpoints(_owner, _count, cleanupBlockNumber);
    }

    /**
     * Delete vote power cache entry that expired (i.e. is before `cleanupBlockNumber`).
     * Method can only be called from the `cleanerContract` (which may be a proxy to external cleaners).
     * @param _owner vote power owner account address
     * @param _blockNumber the block number for which total supply value was cached
     * @return the number of cache entries deleted (always 0 or 1)
     */    
    function votePowerCacheCleanup(address _owner, uint256 _blockNumber) external onlyCleaner returns (uint256) {
        require(_blockNumber < cleanupBlockNumber, "No cleanup after cleanup block");
        return votePowerCache.deleteValueAt(_owner, _blockNumber);
    }

    /**
     * Delete revocation entry that expired (i.e. is before `cleanupBlockNumber`).
     * Method can only be called from the `cleanerContract` (which may be a proxy to external cleaners).
     * @param _from the delegator address
     * @param _to the delegatee address
     * @param _blockNumber the block number for which total supply value was cached
     * @return the number of revocation entries deleted (always 0 or 1)
     */    
    function revocationCleanup(
        address _from, 
        address _to, 
        uint256 _blockNumber
    )
        external onlyCleaner 
        returns (uint256)
    {
        require(_blockNumber < cleanupBlockNumber, "No cleanup after cleanup block");
        return votePowerCache.deleteRevocationAt(_from, _to, _blockNumber);
    }
    
    /**
     * Delete percentage delegation checkpoints that expired (i.e. are before `cleanupBlockNumber`).
     * Method can only be called from the `cleanerContract` (which may be a proxy to external cleaners).
     * @param _owner balance owner account address
     * @param _count maximum number of checkpoints to delete
     * @return the number of checkpoints deleted
     */    
    function percentageDelegationHistoryCleanup(address _owner, uint256 _count)
        external onlyCleaner 
        returns (uint256)
    {
        return percentageDelegations[_owner].cleanupOldCheckpoints(_count, cleanupBlockNumber);
    }
    
    /**
     * Delete explicit delegation checkpoints that expired (i.e. are before `cleanupBlockNumber`).
     * Method can only be called from the `cleanerContract` (which may be a proxy to external cleaners).
     * @param _from the delegator address
     * @param _to the delegatee address
     * @param _count maximum number of checkpoints to delete
     * @return the number of checkpoints deleted
     */    
    function explicitDelegationHistoryCleanup(address _from, address _to, uint256 _count)
        external
        onlyCleaner 
        returns (uint256)
    {
        return explicitDelegations[_from].cleanupOldCheckpoints(_to, _count, cleanupBlockNumber);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/userInterfaces/IGovernanceVotePower.sol

interface IGovernanceVotePower {
    /**
     * @notice Delegate all governance vote power of `msg.sender` to `_to`.
     * @param _to The address of the recipient
     **/
    function delegate(address _to) external;

    /**
     * @notice Undelegate all governance vote power that `msg.sender` has delegated.
     **/
    function undelegate() external;

    /**
    * @notice Get the governance vote power of `_who` at block `_blockNumber`
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Governance vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAt(address _who, uint256 _blockNumber) external view returns(uint256);
}


// File contracts/userInterfaces/IVPToken.sol


pragma solidity 0.7.6;



interface IVPToken is IERC20 {
    /**
     * @notice Delegate by percentage `_bips` of voting power to `_to` from `msg.sender`.
     * @param _to The address of the recipient
     * @param _bips The percentage of voting power to be delegated expressed in basis points (1/100 of one percent).
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/
    function delegate(address _to, uint256 _bips) external;
    
    /**
     * @notice Explicitly delegate `_amount` of voting power to `_to` from `msg.sender`.
     * @param _to The address of the recipient
     * @param _amount An explicit vote power amount to be delegated.
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/    
    function delegateExplicit(address _to, uint _amount) external;

    /**
    * @notice Revoke all delegation from sender to `_who` at given block. 
    *    Only affects the reads via `votePowerOfAtCached()` in the block `_blockNumber`.
    *    Block `_blockNumber` must be in the past. 
    *    This method should be used only to prevent rogue delegate voting in the current voting block.
    *    To stop delegating use delegate/delegateExplicit with value of 0 or undelegateAll/undelegateAllExplicit.
    * @param _who Address of the delegatee
    * @param _blockNumber The block number at which to revoke delegation.
    */
    function revokeDelegationAt(address _who, uint _blockNumber) external;
    
    /**
     * @notice Undelegate all voting power for delegates of `msg.sender`
     *    Can only be used with percentage delegation.
     *    Does not reset delegation mode back to NOTSET.
     **/
    function undelegateAll() external;
    
    /**
     * @notice Undelegate all explicit vote power by amount delegates for `msg.sender`.
     *    Can only be used with explicit delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _delegateAddresses Explicit delegation does not store delegatees' addresses, 
     *   so the caller must supply them.
     * @return The amount still delegated (in case the list of delegates was incomplete).
     */
    function undelegateAllExplicit(address[] memory _delegateAddresses) external returns (uint256);


    /**
     * @dev Should be compatible with ERC20 method
     */
    function name() external view returns (string memory);

    /**
     * @dev Should be compatible with ERC20 method
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Should be compatible with ERC20 method
     */
    function decimals() external view returns (uint8);
    

    /**
     * @notice Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     **/
    function totalSupplyAt(uint _blockNumber) external view returns(uint256);

    /**
     * @dev Queries the token balance of `_owner` at a specific `_blockNumber`.
     * @param _owner The address from which the balance will be retrieved.
     * @param _blockNumber The block number when the balance is queried.
     * @return The balance at `_blockNumber`.
     **/
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint256);

    
    /**
     * @notice Get the current total vote power.
     * @return The current total vote power (sum of all accounts' vote powers).
     */
    function totalVotePower() external view returns(uint256);
    
    /**
    * @notice Get the total vote power at block `_blockNumber`
    * @param _blockNumber The block number at which to fetch.
    * @return The total vote power at the block  (sum of all accounts' vote powers).
    */
    function totalVotePowerAt(uint _blockNumber) external view returns(uint256);

    /**
     * @notice Get the current vote power of `_owner`.
     * @param _owner The address to get voting power.
     * @return Current vote power of `_owner`.
     */
    function votePowerOf(address _owner) external view returns(uint256);
    
    /**
    * @notice Get the vote power of `_owner` at block `_blockNumber`
    * @param _owner The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_owner` at `_blockNumber`.
    */
    function votePowerOfAt(address _owner, uint256 _blockNumber) external view returns(uint256);


    /**
     * @notice Get the delegation mode for '_who'. This mode determines whether vote power is
     *  allocated by percentage or by explicit value. Once the delegation mode is set, 
     *  it never changes, even if all delegations are removed.
     * @param _who The address to get delegation mode.
     * @return delegation mode: 0 = NOTSET, 1 = PERCENTAGE, 2 = AMOUNT (i.e. explicit)
     */
    function delegationModeOf(address _who) external view returns(uint256);
        
    /**
    * @notice Get current delegated vote power `_from` delegator delegated `_to` delegatee.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @return The delegated vote power.
    */
    function votePowerFromTo(address _from, address _to) external view returns(uint256);
    
    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _blockNumber The block number at which to fetch.
    * @return The delegated vote power.
    */
    function votePowerFromToAt(address _from, address _to, uint _blockNumber) external view returns(uint256);
    
    /**
     * @notice Compute the current undelegated vote power of `_owner`
     * @param _owner The address to get undelegated voting power.
     * @return The unallocated vote power of `_owner`
     */
    function undelegatedVotePowerOf(address _owner) external view returns(uint256);
    
    /**
     * @notice Get the undelegated vote power of `_owner` at given block.
     * @param _owner The address to get undelegated voting power.
     * @param _blockNumber The block number at which to fetch.
     * @return The undelegated vote power of `_owner` (= owner's own balance minus all delegations from owner)
     */
    function undelegatedVotePowerOfAt(address _owner, uint256 _blockNumber) external view returns(uint256);
    
    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `_bips` of `_who`. Returned in two separate positional arrays.
    * @param _who The address to get delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOf(address _who)
        external view 
        returns (
            address[] memory _delegateAddresses,
            uint256[] memory _bips,
            uint256 _count, 
            uint256 _delegationMode
        );
        
    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `pcts` of `_who`. Returned in two separate positional arrays.
    * @param _who The address to get delegations.
    * @param _blockNumber The block for which we want to know the delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOfAt(address _who, uint256 _blockNumber)
        external view 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips, 
            uint256 _count, 
            uint256 _delegationMode
        );

    /**
     * Returns VPContract used for readonly operations (view methods).
     * The only non-view method that might be called on it is `revokeDelegationAt`.
     *
     * @notice `readVotePowerContract` is almost always equal to `writeVotePowerContract`
     * except during upgrade from one VPContract to a new version (which should happen
     * rarely or never and will be anounced before).
     *
     * @notice You shouldn't call any methods on VPContract directly, all are exposed
     * via VPToken (and state changing methods are forbidden from direct calls). 
     * This is the reason why this method returns `IVPContractEvents` - it should only be used
     * for listening to events (`Revoke` only).
     */
    function readVotePowerContract() external view returns (IVPContractEvents);

    /**
     * Returns VPContract used for state changing operations (non-view methods).
     * The only non-view method that might be called on it is `revokeDelegationAt`.
     *
     * @notice `writeVotePowerContract` is almost always equal to `readVotePowerContract`
     * except during upgrade from one VPContract to a new version (which should happen
     * rarely or never and will be anounced before). In the case of upgrade,
     * `writeVotePowerContract` will be replaced first to establish delegations, and
     * after some perio (e.g. after a reward epoch ends) `readVotePowerContract` will be set equal to it.
     *
     * @notice You shouldn't call any methods on VPContract directly, all are exposed
     * via VPToken (and state changing methods are forbidden from direct calls). 
     * This is the reason why this method returns `IVPContractEvents` - it should only be used
     * for listening to events (`Delegate` and `Revoke` only).
     */
    function writeVotePowerContract() external view returns (IVPContractEvents);
    
    /**
     * When set, allows token owners to participate in governance voting
     * and delegate governance vote power.
     */
    function governanceVotePower() external view returns (IGovernanceVotePower);
}


// File contracts/token/interface/IICleanable.sol


pragma solidity 0.7.6;

interface IICleanable {
    /**
     * Set the contract that is allowed to call history cleaning methods.
     */
    function setCleanerContract(address _cleanerContract) external;
    
    /**
     * Set the cleanup block number.
     * Historic data for the blocks before `cleanupBlockNumber` can be erased,
     * history before that block should never be used since it can be inconsistent.
     * In particular, cleanup block number must be before current vote power block.
     * @param _blockNumber The new cleanup block number.
     */
    function setCleanupBlockNumber(uint256 _blockNumber) external;
    
    /**
     * Set the contract that is allowed to set cleanupBlockNumber.
     * Usually this will be an instance of CleanupBlockNumberManager.
     */
    function setCleanupBlockNumberManager(address _cleanupBlockNumberManager) external;
    
    /**
     * Get the current cleanup block number.
     */
    function cleanupBlockNumber() external view returns (uint256);
}


// File contracts/token/interface/IIVPContract.sol


pragma solidity 0.7.6;



interface IIVPContract is IICleanable, IVPContractEvents {
    /**
     * Update vote powers when tokens are transfered.
     * Also update delegated vote powers for percentage delegation
     * and check for enough funds for explicit delegations.
     **/
    function updateAtTokenTransfer(
        address _from, 
        address _to, 
        uint256 _fromBalance,
        uint256 _toBalance,
        uint256 _amount
    ) external;

    /**
     * @notice Delegate `_bips` percentage of voting power to `_to` from `_from`
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _balance The delegator's current balance
     * @param _bips The percentage of voting power to be delegated expressed in basis points (1/100 of one percent).
     *   Not cummulative - every call resets the delegation value (and value of 0 revokes delegation).
     **/
    function delegate(
        address _from, 
        address _to, 
        uint256 _balance, 
        uint256 _bips
    ) external;
    
    /**
     * @notice Explicitly delegate `_amount` of voting power to `_to` from `msg.sender`.
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _balance The delegator's current balance
     * @param _amount An explicit vote power amount to be delegated.
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/    
    function delegateExplicit(
        address _from, 
        address _to, 
        uint256 _balance, 
        uint _amount
    ) external;    

    /**
     * @notice Revoke all delegation from sender to `_who` at given block. 
     *    Only affects the reads via `votePowerOfAtCached()` in the block `_blockNumber`.
     *    Block `_blockNumber` must be in the past. 
     *    This method should be used only to prevent rogue delegate voting in the current voting block.
     *    To stop delegating use delegate/delegateExplicit with value of 0 or undelegateAll/undelegateAllExplicit.
     * @param _from The address of the delegator
     * @param _who Address of the delegatee
     * @param _balance The delegator's current balance
     * @param _blockNumber The block number at which to revoke delegation.
     **/
    function revokeDelegationAt(
        address _from, 
        address _who, 
        uint256 _balance,
        uint _blockNumber
    ) external;
    
        /**
     * @notice Undelegate all voting power for delegates of `msg.sender`
     *    Can only be used with percentage delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _from The address of the delegator
     **/
    function undelegateAll(
        address _from,
        uint256 _balance
    ) external;
    
    /**
     * @notice Undelegate all explicit vote power by amount delegates for `msg.sender`.
     *    Can only be used with explicit delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _from The address of the delegator
     * @param _delegateAddresses Explicit delegation does not store delegatees' addresses, 
     *   so the caller must supply them.
     * @return The amount still delegated (in case the list of delegates was incomplete).
     */
    function undelegateAllExplicit(
        address _from, 
        address[] memory _delegateAddresses
    ) external returns (uint256);
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    *   Reads/updates cache and upholds revocations.
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAtCached(address _who, uint256 _blockNumber) external returns(uint256);
    
    /**
     * @notice Get the current vote power of `_who`.
     * @param _who The address to get voting power.
     * @return Current vote power of `_who`.
     */
    function votePowerOf(address _who) external view returns(uint256);
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAt(address _who, uint256 _blockNumber) external view returns(uint256);

    /**
     * Return vote powers for several addresses in a batch.
     * @param _owners The list of addresses to fetch vote power of.
     * @param _blockNumber The block number at which to fetch.
     * @return A list of vote powers.
     */    
    function batchVotePowerOfAt(
        address[] memory _owners, 
        uint256 _blockNumber
    )
        external view returns(uint256[] memory);

    /**
    * @notice Get current delegated vote power `_from` delegator delegated `_to` delegatee.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _balance The delegator's current balance
    * @return The delegated vote power.
    */
    function votePowerFromTo(
        address _from, 
        address _to, 
        uint256 _balance
    ) external view returns(uint256);
    
    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _balance The delegator's current balance
    * @param _blockNumber The block number at which to fetch.
    * @return The delegated vote power.
    */
    function votePowerFromToAt(
        address _from, 
        address _to, 
        uint256 _balance,
        uint _blockNumber
    ) external view returns(uint256);

    /**
     * @notice Compute the current undelegated vote power of `_owner`
     * @param _owner The address to get undelegated voting power.
     * @param _balance Owner's current balance
     * @return The unallocated vote power of `_owner`
     */
    function undelegatedVotePowerOf(
        address _owner,
        uint256 _balance
    ) external view returns(uint256);

    /**
     * @notice Get the undelegated vote power of `_owner` at given block.
     * @param _owner The address to get undelegated voting power.
     * @param _blockNumber The block number at which to fetch.
     * @return The undelegated vote power of `_owner` (= owner's own balance minus all delegations from owner)
     */
    function undelegatedVotePowerOfAt(
        address _owner, 
        uint256 _balance,
        uint256 _blockNumber
    ) external view returns(uint256);

    /**
     * @notice Get the delegation mode for '_who'. This mode determines whether vote power is
     *  allocated by percentage or by explicit value.
     * @param _who The address to get delegation mode.
     * @return Delegation mode (NOTSET=0, PERCENTAGE=1, AMOUNT=2))
     */
    function delegationModeOf(address _who) external view returns (uint256);
    
    /**
    * @notice Get the vote power delegation `_delegateAddresses` 
    *  and `pcts` of an `_owner`. Returned in two separate positional arrays.
    * @param _owner The address to get delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOf(
        address _owner
    )
        external view 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips,
            uint256 _count,
            uint256 _delegationMode
        );

    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `pcts` of an `_owner`. Returned in two separate positional arrays.
    * @param _owner The address to get delegations.
    * @param _blockNumber The block for which we want to know the delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOfAt(
        address _owner,
        uint256 _blockNumber
    )
        external view 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips,
            uint256 _count,
            uint256 _delegationMode
        );

    /**
     * The VPToken (or some other contract) that owns this VPContract.
     * All state changing methods may be called only from this address.
     * This is because original msg.sender is sent in `_from` parameter
     * and we must be sure that it cannot be faked by directly calling VPContract.
     * Owner token is also used in case of replacement to recover vote powers from balances.
     */
    function ownerToken() external view returns (IVPToken);
    
    /**
     * Return true if this IIVPContract is configured to be used as a replacement for other contract.
     * It means that vote powers are not necessarily correct at the initialization, therefore
     * every method that reads vote power must check whether it is initialized for that address and block.
     */
    function isReplacement() external view returns (bool);
}


// File contracts/token/interface/IIGovernanceVotePower.sol


pragma solidity 0.7.6;


interface IIGovernanceVotePower is IGovernanceVotePower {
    /**
     * Update vote powers when tokens are transfered.
     **/
    function updateAtTokenTransfer(
        address _from, 
        address _to, 
        uint256 _fromBalance,
        uint256 _toBalance,
        uint256 _amount
    ) external;
    
    /**
     * Set the cleanup block number.
     * Historic data for the blocks before `cleanupBlockNumber` can be erased,
     * history before that block should never be used since it can be inconsistent.
     * In particular, cleanup block number must be before current vote power block.
     * @param _blockNumber The new cleanup block number.
     */
    function setCleanupBlockNumber(uint256 _blockNumber) external;
    
    /**
     * Set the contract that is allowed to call history cleaning methods.
     */
    function setCleanerContract(address _cleanerContract) external;
        
   /**
    * @notice Get the token that this governance vote power contract belongs to.
    */
    function ownerToken() external view returns(IVPToken);
}


// File contracts/token/interface/IIVPToken.sol


pragma solidity 0.7.6;





interface IIVPToken is IVPToken, IICleanable {
    /**
     * Sets new governance vote power contract that allows token owners to participate in governance voting
     * and delegate governance vote power. 
     */
    function setGovernanceVotePower(IIGovernanceVotePower _governanceVotePower) external;
    
    /**
    * @notice Get the total vote power at block `_blockNumber` using cache.
    *   It tries to read the cached value and if not found, reads the actual value and stores it in cache.
    *   Can only be used if `_blockNumber` is in the past, otherwise reverts.    
    * @param _blockNumber The block number at which to fetch.
    * @return The total vote power at the block (sum of all accounts' vote powers).
    */
    function totalVotePowerAtCached(uint256 _blockNumber) external returns(uint256);
    
    /**
    * @notice Get the vote power of `_owner` at block `_blockNumber` using cache.
    *   It tries to read the cached value and if not found, reads the actual value and stores it in cache.
    *   Can only be used if _blockNumber is in the past, otherwise reverts.    
    * @param _owner The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_owner` at `_blockNumber`.
    */
    function votePowerOfAtCached(address _owner, uint256 _blockNumber) external returns(uint256);

    /**
     * Return vote powers for several addresses in a batch.
     * @param _owners The list of addresses to fetch vote power of.
     * @param _blockNumber The block number at which to fetch.
     * @return A list of vote powers.
     */    
    function batchVotePowerOfAt(
        address[] memory _owners, 
        uint256 _blockNumber
    ) external view returns(uint256[] memory);
}


// File contracts/token/implementation/VPContract.sol


pragma solidity 0.7.6;







contract VPContract is IIVPContract, Delegatable {
    using SafeMath for uint256;
    
    /**
     * The VPToken (or some other contract) that owns this VPContract.
     * All state changing methods may be called only from this address.
     * This is because original msg.sender is sent in `_from` parameter
     * and we must be sure that it cannot be faked by directly calling VPContract.
     * Owner token is also used in case of replacement to recover vote powers from balances.
     */
    IVPToken public immutable override ownerToken;
    
    /**
     * Return true if this IIVPContract is configured to be used as a replacement for other contract.
     * It means that vote powers are not necessarily correct at the initialization, therefore
     * every method that reads vote power must check whether it is initialized for that address and block.
     */
    bool public immutable override isReplacement;

    // the contract that is allowed to set cleanupBlockNumber
    // usually this will be an instance of CleanupBlockNumberManager
    // only set when detached from vptoken and directly registered to CleanupBlockNumberManager
    address private cleanupBlockNumberManager;
    
    // The block number when vote power for an address was first set.
    // Reading vote power before this block would return incorrect result and must revert.
    mapping (address => uint256) private votePowerInitializationBlock;

    // Vote power cache for past blocks when vote power was not initialized.
    // Reading vote power at that block would return incorrect result, so cache must be set by some other means.
    // No need for revocation info, since there can be no delegations at such block.
    mapping (bytes32 => uint256) private uninitializedVotePowerCache;
    
    string constant private ALREADY_EXPLICIT_MSG = "Already delegated explicitly";
    string constant private ALREADY_PERCENT_MSG = "Already delegated by percentage";
    
    string constant internal VOTE_POWER_NOT_INITIALIZED = "Vote power not initialized";

    /**
     * All external methods in VPContract can only be executed by the owner token.
     */
    modifier onlyOwnerToken {
        require(msg.sender == address(ownerToken), "only owner token");
        _;
    }

    /**
     * Setting cleaner contract is allowed from
     * owner token or owner token's governance (when VPContract is detached,
     * methods can no longer be called via the owner token, but the VPContract
     * still remembers the old owner token and can see its governance).
     */
    modifier onlyOwnerOrGovernance {
        require(msg.sender == address(ownerToken) || 
            msg.sender == GovernedBase(address(ownerToken)).governance(),
            "only owner or governance");
        _;
    }

    modifier onlyPercent(address sender) {
        // If a delegate cannot be added by percentage, revert.
        require(_canDelegateByPct(sender), ALREADY_EXPLICIT_MSG);
        _;
    }

    modifier onlyExplicit(address sender) {
        // If a delegate cannot be added by explicit amount, revert.
        require(_canDelegateByAmount(sender), ALREADY_PERCENT_MSG);
        _;
    }

    /**
     * Construct VPContract for given VPToken.
     */
    constructor(IVPToken _ownerToken, bool _isReplacement) {
        require(address(_ownerToken) != address(0), "VPContract must belong to a VPToken");
        ownerToken = _ownerToken;
        isReplacement = _isReplacement;
    }
    
    /**
     * Set the cleanup block number.
     * Historic data for the blocks before `cleanupBlockNumber` can be erased,
     * history before that block should never be used since it can be inconsistent.
     * In particular, cleanup block number must be before current vote power block.
     * The method can be called by the owner token, its governance or cleanupBlockNumberManager.
     * @param _blockNumber The new cleanup block number.
     */
    function setCleanupBlockNumber(uint256 _blockNumber) external override {
        require(msg.sender == address(ownerToken) || 
            msg.sender == cleanupBlockNumberManager ||
            msg.sender == GovernedBase(address(ownerToken)).governance(),
            "only owner, governance or cleanup block manager");
        _setCleanupBlockNumber(_blockNumber);
    }

    /**
     * Set the contract that is allowed to set cleanupBlockNumber.
     * Usually this will be an instance of CleanupBlockNumberManager.
     * Only to be set when detached from the owner token and directly attached to cleanup block number manager.
     */
    function setCleanupBlockNumberManager(address _cbnManager) external override onlyOwnerOrGovernance {
        cleanupBlockNumberManager = _cbnManager;
    }
    
    /**
     * Set the contract that is allowed to call history cleaning methods.
     * The method can be called by the owner token or its governance.
     */
    function setCleanerContract(address _cleanerContract) external override onlyOwnerOrGovernance {
        _setCleanerContract(_cleanerContract);
    }
    
    /**
     * Update vote powers when tokens are transfered.
     * Also update delegated vote powers for percentage delegation
     * and check for enough funds for explicit delegations.
     **/
    function updateAtTokenTransfer(
        address _from, 
        address _to, 
        uint256 _fromBalance,
        uint256 _toBalance,
        uint256 _amount
    )
        external override 
        onlyOwnerToken 
    {
        if (_from == address(0)) {
            // mint new vote power
            _initializeVotePower(_to, _toBalance);
            _mintVotePower(_to, _toBalance, _amount);
        } else if (_to == address(0)) {
            // burn vote power
            _initializeVotePower(_from, _fromBalance);
            _burnVotePower(_from, _fromBalance, _amount);
        } else {
            // transmit vote power _to receiver
            _initializeVotePower(_from, _fromBalance);
            _initializeVotePower(_to, _toBalance);
            _transmitVotePower(_from, _to, _fromBalance, _toBalance, _amount);
        }
    }

    /**
     * @notice Delegate `_bips` percentage of voting power to `_to` from `_from`
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _balance The delegator's current balance
     * @param _bips The percentage of voting power to be delegated expressed in basis points (1/100 of one percent).
     *   Not cummulative - every call resets the delegation value (and value of 0 revokes delegation).
     **/
    function delegate(
        address _from, 
        address _to, 
        uint256 _balance, 
        uint256 _bips
    )
        external override 
        onlyOwnerToken 
        onlyPercent(_from)
    {
        _initializeVotePower(_from, _balance);
        if (!_votePowerInitialized(_to)) {
            _initializeVotePower(_to, ownerToken.balanceOf(_to));
        }
        _delegateByPercentage(_from, _to, _balance, _bips);
    }
    
    /**
     * @notice Explicitly delegate `_amount` of voting power to `_to` from `_from`.
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _balance The delegator's current balance
     * @param _amount An explicit vote power amount to be delegated.
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/    
    function delegateExplicit(
        address _from, 
        address _to, 
        uint256 _balance, 
        uint _amount
    )
        external override 
        onlyOwnerToken
        onlyExplicit(_from)
    {
        _initializeVotePower(_from, _balance);
        if (!_votePowerInitialized(_to)) {
            _initializeVotePower(_to, ownerToken.balanceOf(_to));
        }
        _delegateByAmount(_from, _to, _balance, _amount);
    }

    /**
     * @notice Revoke all delegation from `_from` to `_to` at given block. 
     *    Only affects the reads via `votePowerOfAtCached()` in the block `_blockNumber`.
     *    Block `_blockNumber` must be in the past. 
     *    This method should be used only to prevent rogue delegate voting in the current voting block.
     *    To stop delegating use delegate/delegateExplicit with value of 0 or undelegateAll/undelegateAllExplicit.
     * @param _from The address of the delegator
     * @param _to Address of the delegatee
     * @param _balance The delegator's current balance
     * @param _blockNumber The block number at which to revoke delegation.
     **/
    function revokeDelegationAt(
        address _from, 
        address _to, 
        uint256 _balance,
        uint _blockNumber
    )
        external override 
        onlyOwnerToken
    {
        // ASSERT: if there was a delegation, _from and _to must be initialized
        if (!isReplacement || 
            (_votePowerInitializedAt(_from, _blockNumber) && _votePowerInitializedAt(_to, _blockNumber))) {
            _revokeDelegationAt(_from, _to, _balance, _blockNumber);
        }
    }

    /**
     * @notice Undelegate all voting power for delegates of `_from`
     *    Can only be used with percentage delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _from The address of the delegator
     **/
    function undelegateAll(
        address _from,
        uint256 _balance
    )
        external override 
        onlyOwnerToken 
        onlyPercent(_from)
    {
        if (_hasAnyDelegations(_from)) {
            // ASSERT: since there were delegations, _from and its targets must be initialized
            _undelegateAllByPercentage(_from, _balance);
        }
    }

    /**
     * @notice Undelegate all explicit vote power by amount delegates for `_from`.
     *    Can only be used with explicit delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _from The address of the delegator
     * @param _delegateAddresses Explicit delegation does not store delegatees' addresses, 
     *   so the caller must supply them.
     * @return The amount still delegated (in case the list of delegates was incomplete).
     */
    function undelegateAllExplicit(
        address _from, 
        address[] memory _delegateAddresses
    )
        external override 
        onlyOwnerToken 
        onlyExplicit(_from) 
        returns (uint256)
    {
        if (_hasAnyDelegations(_from)) {
            // ASSERT: since there were delegations, _from and its targets must be initialized
            return _undelegateAllByAmount(_from, _delegateAddresses);
        }
        return 0;
    }
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    *   Reads/updates cache and upholds revocations.
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAtCached(address _who, uint256 _blockNumber) external override returns(uint256) {
        if (!isReplacement || _votePowerInitializedAt(_who, _blockNumber)) {
            // use standard method
            return _votePowerOfAtCached(_who, _blockNumber);
        } else {
            // use uninitialized vote power cache
            bytes32 key = keccak256(abi.encode(_who, _blockNumber));
            uint256 cached = uninitializedVotePowerCache[key];
            if (cached != 0) {
                return cached - 1;  // safe, cached != 0
            }
            uint256 balance = ownerToken.balanceOfAt(_who, _blockNumber);
            uninitializedVotePowerCache[key] = balance.add(1);
            return balance;
        }
    }
    
    /**
     * Get the current cleanup block number.
     */
    function cleanupBlockNumber() external view override returns (uint256) {
        return _cleanupBlockNumber();
    }
    
    /**
     * @notice Get the current vote power of `_who`.
     * @param _who The address to get voting power.
     * @return Current vote power of `_who`.
     */
    function votePowerOf(address _who) external view override returns(uint256) {
        if (_votePowerInitialized(_who)) {
            return _votePowerOf(_who);
        } else {
            return ownerToken.balanceOf(_who);
        }
    }
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAt(address _who, uint256 _blockNumber) public view override returns(uint256) {
        if (!isReplacement || _votePowerInitializedAt(_who, _blockNumber)) {
            return _votePowerOfAt(_who, _blockNumber);
        } else {
            return ownerToken.balanceOfAt(_who, _blockNumber);
        }
    }
    
    /**
     * Return vote powers for several addresses in a batch.
     * @param _owners The list of addresses to fetch vote power of.
     * @param _blockNumber The block number at which to fetch.
     * @return _votePowers A list of vote powers corresponding to _owners.
     */    
    function batchVotePowerOfAt(
        address[] memory _owners, 
        uint256 _blockNumber
    )
        external view override 
        returns(uint256[] memory _votePowers)
    {
        _votePowers = _batchVotePowerOfAt(_owners, _blockNumber);
        // zero results might not have been initialized
        if (isReplacement) {
            for (uint256 i = 0; i < _votePowers.length; i++) {
                if (_votePowers[i] == 0 && !_votePowerInitializedAt(_owners[i], _blockNumber)) {
                    _votePowers[i] = ownerToken.balanceOfAt(_owners[i], _blockNumber);
                }
            }
        }
    }
    
    /**
    * @notice Get current delegated vote power `_from` delegator delegated `_to` delegatee.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _balance The delegator's current balance
    * @return The delegated vote power.
    */
    function votePowerFromTo(
        address _from, 
        address _to, 
        uint256 _balance
    )
        external view override 
        returns (uint256)
    {
        // ASSERT: if the result is nonzero, _from and _to are initialized
        return _votePowerFromTo(_from, _to, _balance);
    }
    
    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _balance The delegator's current balance
    * @param _blockNumber The block number at which to fetch.
    * @return The delegated vote power.
    */
    function votePowerFromToAt(
        address _from, 
        address _to, 
        uint256 _balance,
        uint _blockNumber
    )
        external view override
        returns (uint256)
    {
        // ASSERT: if the result is nonzero, _from and _to were initialized at _blockNumber
        return _votePowerFromToAt(_from, _to, _balance, _blockNumber);
    }
    
    /**
     * @notice Get the delegation mode for '_who'. This mode determines whether vote power is
     *  allocated by percentage or by explicit value.
     * @param _who The address to get delegation mode.
     * @return Delegation mode (NOTSET=0, PERCENTAGE=1, AMOUNT=2))
     */
    function delegationModeOf(address _who) external view override returns (uint256) {
        return uint256(_delegationModeOf(_who));
    }

    /**
     * @notice Compute the current undelegated vote power of `_owner`
     * @param _owner The address to get undelegated voting power.
     * @param _balance Owner's current balance
     * @return The unallocated vote power of `_owner`
     */
    function undelegatedVotePowerOf(
        address _owner,
        uint256 _balance
    )
        external view override
        returns (uint256)
    {
        if (_votePowerInitialized(_owner)) {
            return _undelegatedVotePowerOf(_owner, _balance);
        } else {
            // ASSERT: there are no delegations
            return _balance;
        }
    }
    
    /**
     * @notice Get the undelegated vote power of `_owner` at given block.
     * @param _owner The address to get undelegated voting power.
     * @param _blockNumber The block number at which to fetch.
     * @return The undelegated vote power of `_owner` (= owner's own balance minus all delegations from owner)
     */
    function undelegatedVotePowerOfAt(
        address _owner, 
        uint256 _balance,
        uint256 _blockNumber
    )
        external view override
        returns (uint256)
    {
        if (_votePowerInitialized(_owner)) {
            return _undelegatedVotePowerOfAt(_owner, _balance, _blockNumber);
        } else {
            // ASSERT: there were no delegations at _blockNumber
            return _balance;
        }
    }

    /**
    * @notice Get the vote power delegation `_delegateAddresses` 
    *  and `pcts` of an `_owner`. Returned in two separate positional arrays.
    *  Also returns the count of delegates and delegation mode.
    * @param _owner The address to get delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOf(address _owner)
        external view override 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips,
            uint256 _count,
            uint256 _delegationMode
        )
    {
        // ASSERT: either _owner is initialized or there are no delegations
        return delegatesOfAt(_owner, block.number);
    }
    
    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `_bips` of an `_owner`. Returned in two separate positional arrays.
    *  Also returns the count of delegates and delegation mode.
    * @param _owner The address to get delegations.
    * @param _blockNumber The block for which we want to know the delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOfAt(
        address _owner,
        uint256 _blockNumber
    )
        public view override 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips,
            uint256 _count,
            uint256 _delegationMode
        )
    {
        // ASSERT: either _owner was initialized or there were no delegations
        DelegationMode mode = _delegationModeOf(_owner);
        if (mode == DelegationMode.PERCENTAGE) {
            // Get the vote power delegation for the _owner
            (_delegateAddresses, _bips) = _percentageDelegatesOfAt(_owner, _blockNumber);
        } else if (mode == DelegationMode.NOTSET) {
            _delegateAddresses = new address[](0);
            _bips = new uint256[](0);
        } else {
            revert ("delegatesOf does not work in AMOUNT delegation mode");
        }
        _count = _delegateAddresses.length;
        _delegationMode = uint256(mode);
    }

    /**
     * Initialize vote power to current balance if not initialized already.
     * @param _owner The address to initialize voting power.
     * @param _balance The owner's current balance.
     */
    function _initializeVotePower(address _owner, uint256 _balance) internal {
        if (!isReplacement) return;
        if (votePowerInitializationBlock[_owner] == 0) {
            // consistency check - no delegations should be made from or to owner before vote power is initialized
            // (that would be dangerous, because vote power would have been delegated incorrectly)
            assert(_votePowerOf(_owner) == 0 && !_hasAnyDelegations(_owner));
            _mintVotePower(_owner, 0, _balance);
            votePowerInitializationBlock[_owner] = block.number.add(1);
        }
    }
    
    /**
     * Has the vote power of `_owner` been initialized?
     * @param _owner The address to check.
     * @return true if vote power of _owner is initialized
     */
    function _votePowerInitialized(address _owner) internal view returns (bool) {
        if (!isReplacement) return true;
        return votePowerInitializationBlock[_owner] != 0;
    }

    /**
     * Was vote power of `_owner` initialized at some block?
     * @param _owner The address to check.
     * @param _blockNumber The block for which we want to check.
     * @return true if vote power of _owner was initialized at _blockNumber
     */
    function _votePowerInitializedAt(address _owner, uint256 _blockNumber) internal view returns (bool) {
        if (!isReplacement) return true;
        uint256 initblock = votePowerInitializationBlock[_owner];
        return initblock != 0 && initblock - 1 <= _blockNumber;
    }
}