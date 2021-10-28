// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ILotteryTracker.sol";
import "./LotteryWinner.sol";

contract LotteryTracker is Ownable, ILotteryTracker , LotteryWinner {
     using SafeMath for uint256;
     
    struct ParticipantInfo {
        uint256 index;
        uint256 balance;
    }

    uint256[] private  _participantsEntries;
    mapping (address => ParticipantInfo) private _participantBalance;
    address[] private _participants;

    uint256 currentDeleteIndex;

    address public lotteryContract;
    modifier lotteryOperator () {
        require(owner() == _msgSender() || msg.sender == lotteryContract, "Not allowed");
        _;
    }

    constructor() {}

    function dropAllPreviousEntries() external onlyOwner {
        uint256 len =  _participants.length;
        uint256 iter;
        uint256 index = currentDeleteIndex;
        while (index < len && iter < 10000) {
            delete _participantBalance[_participants[index]];
            index++;
            iter++;
        }
        currentDeleteIndex = index;

        if (currentDeleteIndex == len) {
            delete _participantsEntries;
            delete _participants;
            currentDeleteIndex = 0;
        }
    }

    function isActiveAccount(address account) external override view returns(bool){
        return _participantBalance[account].balance > 0;
    }

    function getEntryCountForAccount(address account) external  view returns(uint256){
        return _participantBalance[account].balance;
    }

    function removeEntryFromWallet(address account, uint256 amount) external override lotteryOperator {
        if (currentDeleteIndex > 0) {
            return;
        }
        uint256 balanceToUpdate = 0;
        if(_participantBalance[account].balance > amount){
            balanceToUpdate = _participantBalance[account].balance.sub(amount);
        }
        if (_participantBalance[account].balance != 0) {
           _participantsEntries[_participantBalance[account].index] = balanceToUpdate;
            _participantBalance[account].balance = balanceToUpdate;
        } 

        emit UpdateAccountEntries(account, amount, _participantBalance[account].balance);
    }

    function updateAccount(address account, uint256 amount) external override lotteryOperator {
        if (currentDeleteIndex > 0) {
            return;
        }

        if (_participantBalance[account].balance == 0) {
            _participantBalance[account].index = _participants.length;
            _participants.push(account);
            _participantsEntries.push(amount);
        } else {
            _participantsEntries[_participantBalance[account].index] += amount;
        }

        _participantBalance[account].balance += amount;
        emit UpdateAccountEntries(account, amount, _participantBalance[account].balance);
    }

    function removeAccount(address account) external override lotteryOperator {
        if (currentDeleteIndex > 0) {
            return;
        }

        uint256 indexOfDel = _participantBalance[account].index;
        uint256 indexLast = _participants.length - 1;
        _participants[indexOfDel] = _participants[indexLast];
        _participantsEntries[indexOfDel] = _participantsEntries[indexLast];

        _participantBalance[_participants[indexLast]].index = indexOfDel;
        _participants.pop();
        _participantsEntries.pop();
        delete _participantBalance[account];
        emit UpdateAccountEntries(account, 0, 0);

    }

    function getActiveParticipantAddresses() external view returns(address[] memory) {
        return _participants;
    }

    function getActiveParticipantsCount() external view returns(uint256) {
        return _participants.length;
    }

    function getActiveParticipantEntries() external view returns(uint256[] memory) {
        return _participantsEntries;
    }


    function setLotteryContract(address _lotteryContract) external onlyOwner {
        lotteryContract = _lotteryContract;
    }

    event UpdateAccountEntries(address account, uint256 increaseAmount, uint256 accountBalance);
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface ILotteryTracker {
    function updateAccount(address account, uint256 amount) external;
    function removeEntryFromWallet(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function isActiveAccount(address account) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract LotteryWinner is Ownable {
    struct WinnerInfo {
        uint256 amount;
        uint256 time;
        address winner;
        string txhash;
    }

    mapping(address => uint256) private _winnerIndexByAddress;

    WinnerInfo[] internal _winners;

    constructor() {
        WinnerInfo memory zeroInfo = WinnerInfo(0, 0, address(0),"");
        _winners.push(zeroInfo);
    }

    function addWinner(address winner, uint256 amount, uint256 time, string memory txhash) external onlyOwner returns (uint256 index) {
        index = _winners.length;
        WinnerInfo memory winnerInfo = WinnerInfo(amount, time, winner,txhash);
        _winners.push(winnerInfo);
        _winnerIndexByAddress[winner] = index;
    }

    function getWinnerInfoByAddress(address winner) public view returns(WinnerInfo memory winnerInfo) {
        // if no address in map will get 0 index and zeroInfo.
        uint256 index = _winnerIndexByAddress[winner];
        return _winners[index];
    }


    function getLastWinners(uint256 n) external view returns(WinnerInfo[] memory) {
        uint256 len = n > _winners.length ? _winners.length : n;

        WinnerInfo[] memory winInfo = new WinnerInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            winInfo[i] = _winners[_winners.length - i - 1];
        }

        return winInfo;
    }

    function getWinnersCount() external view returns (uint256 ) {
        return  _winners.length;
    }

}