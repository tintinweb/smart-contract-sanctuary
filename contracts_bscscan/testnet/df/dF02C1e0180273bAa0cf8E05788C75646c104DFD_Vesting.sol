// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/BEP20/IQuillToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract Vesting is Ownable {

    IQuillToken quillToken;
    IBEP20 nekoin;
    uint32 CLIFF_IN_MINUTES = 2 minutes;
    uint32 MINUTES_PER_PERIOD = 2;
    uint32 TOTAL_PERIOD = 10;

    struct Vest {
        uint256 amount;
        uint8 progress;
        uint256 claimedAmount;
        uint32 dateStarted;
    }

    struct ClaimHistory {
        uint32 dateClaimed;
        uint256 claimedAmount;
    }

    event VestCreated(uint index, uint256 amount, address owner);
    event VestClaimed(uint index, uint256 amount, address owner);

    Vest[] vests;
    mapping (uint => address) public vestToOwner;
    mapping (address => uint) public ownerVestCount;
    mapping (address => uint) public totalVest;
    ClaimHistory[] histories;
    mapping (uint => uint) public historyToVest;
    mapping (uint => uint) public vestHistoryCount;


    constructor(IQuillToken _quillToken, IBEP20 _nekoin) {
        quillToken = _quillToken;
        nekoin = _nekoin;
    }

    // Getters 

    /**
     * @dev gets all the vest of a wallet;
     *
     * Returns an array of indices for each vest
     */
    function vestsByOwner(address _owner) external view returns (uint[] memory) {
        uint[] memory result = new uint[](ownerVestCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < vests.length; i++) {
            if (vestToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * @dev return each vest of a wallet by index;
     *
     * Returns vest[_index]
     */
    function vestByIndex(uint _index) external view returns (
        uint256 index,
        uint256 amount, 
        uint8 progress,
        uint256 claimedAmount, 
        uint256 claimableAmount,
        uint32 dateCreated,
        uint256 nextClaimableDate
    ) 
    {
        Vest storage vest = vests[_index];
        return (
            _index,
            vest.amount, 
            vest.progress,
            vest.claimedAmount,
            getClaimableVestTokenByIndex(_index),
            vest.dateStarted,
            _getNextClaimDate(vest.dateStarted)
        );
    }

    function historiesByVest(uint _index) external view returns (uint[] memory) {
        uint[] memory result = new uint[](vestHistoryCount[_index]);
        uint counter = 0;
        for (uint i = 0; i < histories.length; i++) {
            if (historyToVest[i] == _index) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function historyByIndex(uint _index) external view returns (
        uint256 index,
        uint32 dateClaimed, 
        uint256 claimedAmount
    ) 
    {
        ClaimHistory storage history = histories[_index];
        return (
            _index,
            history.dateClaimed, 
            history.claimedAmount
        );
    }

    function getClaimableVestTokenByIndex(uint256 _index) public view returns (uint256 totalTokensToClaim) {
        Vest storage vest = vests[_index];
        uint256 tenPercentOfTotalVest = _tenPercentOf(vest.amount);
        uint256 claimedAmount = vest.claimedAmount - tenPercentOfTotalVest;
        uint256 ninetyPercentOfTotalVest = vest.amount - tenPercentOfTotalVest;
        totalTokensToClaim = 0;
        if (block.timestamp >= (vest.dateStarted + CLIFF_IN_MINUTES)) { 
            uint256 currentPeriod = _getCurrentPeriod(vest.dateStarted);
            uint256 partialTokensToClaim = (ninetyPercentOfTotalVest / TOTAL_PERIOD) * currentPeriod;
            totalTokensToClaim = partialTokensToClaim - claimedAmount;
        }
    }

    function _getCurrentPeriod(uint32 dateStarted) private view returns (uint256 currentPeriod) {
        uint256 timePassed = (block.timestamp - (dateStarted + CLIFF_IN_MINUTES)) / 60;
        currentPeriod = timePassed / MINUTES_PER_PERIOD;
        if (currentPeriod > TOTAL_PERIOD ) { currentPeriod = TOTAL_PERIOD; } // prevents tokensToClaim to exceed its 100% value
    }

    function _getNextClaimDate(uint32 dateStarted) private view returns (uint256 nextClaimDate) {
        uint256 currentPeriod = _getCurrentPeriod(dateStarted);
        nextClaimDate = (currentPeriod * CLIFF_IN_MINUTES) + (CLIFF_IN_MINUTES * 2) + dateStarted;
    }

    function addVest(uint256 _amount) external {
        require(_amount != 0, 'Amount cannot be zero');
        require(quillToken.transferFrom(msg.sender, address(this), _amount), 'QuillToken is required');

        uint256 initialClaimableTokens = _tenPercentOf(_amount);

        nekoin.transfer(msg.sender, initialClaimableTokens);

        Vest memory newVest;
        newVest.amount = _amount;
        newVest.claimedAmount = initialClaimableTokens;
        newVest.dateStarted = uint32(block.timestamp);
        newVest.progress = 10;
        vests.push(newVest);
        uint index = vests.length - 1;

        vestToOwner[index] = msg.sender;
        ownerVestCount[msg.sender]++;
        totalVest[msg.sender] += _amount;

        _addToHistory(initialClaimableTokens, index);

        emit VestCreated(index, _amount, msg.sender);
    }

    function claimVest(uint256 _index) external {
        require(vestToOwner[_index] == msg.sender, 'Caller is not the vestor');
        Vest storage vest = vests[_index];
        require(vest.amount != vest.claimedAmount, 'Already claimed');
        uint256 claimableVest = getClaimableVestTokenByIndex(_index);
        require(claimableVest != 0, 'Function cannot call now');
        
        nekoin.transfer(msg.sender, claimableVest);
        quillToken.burn(claimableVest);
        uint8 progress = SafeCast.toUint8(_getCurrentPeriod(vest.dateStarted)) * 9;
        vest.progress += progress;
        vest.claimedAmount += claimableVest;

        _addToHistory(claimableVest, _index);

        emit VestClaimed(_index, claimableVest, msg.sender);   
    }

    function _addToHistory(uint256 _claimableVest, uint256 _vestIndex) private {
        ClaimHistory memory newHistory;
        newHistory.dateClaimed = uint32(block.timestamp);
        newHistory.claimedAmount = _claimableVest;
        histories.push(newHistory);
        uint index = histories.length - 1;

        historyToVest[index] = _vestIndex;
        vestHistoryCount[_vestIndex]++;
    }

    function _tenPercentOf(uint256 _amount) private pure returns (uint256 tenPercent) {
        tenPercent = (_amount / 100) * 10;
    }

    function withraw() external onlyOwner {
        uint256 nekoinBalance = nekoin.balanceOf(address(this));
        require(nekoinBalance >= 0, 'Nekoin is 0 balance');
        nekoin.transfer(owner(), nekoinBalance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBEP20.sol";

interface IQuillToken is IBEP20 {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}