// version set default time
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Schema is Ownable, Pausable{
    using SafeMath for uint;

    address public tokenAddress;
    address public preventiveAdress;

    uint256 public totalPhase;
    uint256 public totalRound;

    mapping (uint256 => Phase) phases;  // danh sách các phase
    mapping (uint256 => Round) rounds;  // danh sách các round
    mapping (address => uint256[]) roundIdList; // danh sach cac roundId cua user
    
    event addRoundEvent(uint256 roundId, string nameRound, uint256 timeStart);
    event addPhaseEvent(uint256 phaseId, uint256 roundId, uint256 numerator, uint256 denominator, uint256 timeStartWithdraw);
    event addRoundOfUserEvent( address wallet, uint256 roundId, uint256 amount);
    event withdrawEvent( address wallet, uint256 amount);
    event urgentWithdrawalEvent(address preventiveAdress, uint256 balanceOfThis);

    struct Round {
        string name;
        uint256 timeStart;
        uint256[] phaseIDs;

        mapping (address => uint256) amount; 
        mapping (address => uint256) lastVest;
        mapping (address => uint256) withdrawed;
    }

    struct Phase {
        uint256 numerator;
        uint256 denominator;
        uint256 timeStartWithdraw;
    }

    constructor(address _tokenAddress, address _owner) {
        tokenAddress = _tokenAddress;
        transferOwnership(_owner);
        preventiveAdress = _owner;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addRound(string memory _nameRound, uint256 _timeStart) public onlyOwner {
        uint256 roundId = totalRound;

        Round storage round = rounds[roundId];
        round.name = _nameRound;
        round.timeStart = _timeStart;

        totalRound++;
        emit addRoundEvent(roundId, _nameRound, _timeStart);
    }

    function addMultiPhase(
        uint256[] memory _roundIdList, 
        uint256[] memory _numeratorList,
        uint256[] memory _denominatorList,
        uint256[] memory _timeStartWithdraw
        ) public onlyOwner {
            require(_roundIdList.length == _numeratorList.length); 
            require(_roundIdList.length == _denominatorList.length);
            require(_roundIdList.length == _timeStartWithdraw.length);
        for(uint256 i =0; i< _roundIdList.length; i++) {
            addPhase(_roundIdList[i], _numeratorList[i], _denominatorList[i], _timeStartWithdraw[i]);
        }
    }

    function addPhase(uint256 _roundId, uint256 _numerator, uint256 _denominator, uint256 _timeStartWithdraw ) public onlyOwner {
        require( totalRound > _roundId , 'roundId not exists');
        require( _timeStartWithdraw > rounds[_roundId].timeStart, '_timeStartWithdraw error' );

        uint256 phaseId = totalPhase;

        Phase storage phase = phases[phaseId];
        phase.numerator = _numerator;
        phase.denominator = _denominator;
        phase.timeStartWithdraw = _timeStartWithdraw;

        Round storage round = rounds[_roundId];
        round.phaseIDs.push(phaseId);
        
        totalPhase = totalPhase + 1;
        emit addPhaseEvent(phaseId, _roundId, _numerator, _denominator, _timeStartWithdraw);
    }

    function addRoundOfUser(address _wallet, uint256 _roundId, uint256 _amount) public onlyOwner {
        require(!checkExist(_wallet, _roundId), 'roundId is existed');

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        
        Round storage round = rounds[_roundId];
        round.amount[_wallet] = _amount;
 
        roundIdList[_wallet].push(_roundId);

        emit addRoundOfUserEvent(_wallet, _roundId, _amount);
    }

    function withdraw(address _wallet) whenNotPaused public {
        uint256 sum = 0;

        for(uint256 i = 0; i < roundIdList[_wallet].length; i++) {
            Round storage round = rounds[roundIdList[_wallet][i]];
            uint256 amount = round.amount[_wallet];
            // check timer
            if( block.timestamp > round.timeStart ) {
                for( uint256 j = round.lastVest[_wallet] ; j < round.phaseIDs.length; j++ ) {
                    Phase storage phase = phases[round.phaseIDs[j]];
    
                    if( block.timestamp > phase.timeStartWithdraw ) {
                        if ( j == round.phaseIDs.length - 1 ) {
                            uint256 withdrawal = amount.sub(round.withdrawed[_wallet]);
                            sum = sum.add( withdrawal );
                            round.withdrawed[_wallet] = amount;
                            round.lastVest[_wallet] = j;
                            break;
                        } else {
                            uint256 withdrawal = amount.mul(phase.numerator).div(phase.denominator);
                            sum = sum.add( withdrawal );
                            round.withdrawed[_wallet] = round.withdrawed[_wallet].add( withdrawal );
                            round.lastVest[_wallet] = j;
                        }
                    }
                }
            }
        }
        IERC20(tokenAddress).transfer(_wallet, sum);

        emit withdrawEvent(_wallet, sum);
    }

    function urgentWithdraw() public whenPaused onlyOwner {
        uint256 balanceOfThis = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(preventiveAdress, balanceOfThis);
        emit urgentWithdrawalEvent(preventiveAdress, balanceOfThis);
    }

    function checkExist(address _wallet, uint256 _roundId) public view returns(bool) {
        for(uint256 i=0; i< roundIdList[_wallet].length; i++) {
            if( _roundId == roundIdList[_wallet][i]) {
                return true;
            }
        }
        return false;
    }

    function checkRoundsOfWallet(address _wallet) public view returns(uint256[] memory roundIDs){
        roundIDs = roundIdList[_wallet];
    }
    
    function checkPhase(uint256 _phaseId) public view returns(Phase memory phase){
        phase = phases[_phaseId];
    }

    function checkNameOfRound(uint256 _roundId) public view returns(string memory name){
        name = rounds[_roundId].name;
    }

    function checkTimestartOfRound(uint256 _roundId) public view returns(uint256 timeStart){
        timeStart = rounds[_roundId].timeStart;
    }
    
    function checkPhaseIDsOfRound(uint256 _roundId) public view returns(uint256[] memory phaseIDs){
        phaseIDs = rounds[_roundId].phaseIDs;
    }
    
    function checkAmountOfWallet(address _wallet, uint256 _roundId) public view returns(uint256 amount){
        amount = rounds[_roundId].amount[_wallet];
    }
    
    function checkLastVestOfWallet(address _wallet, uint256 _roundId) public view returns(uint256 lastVest){
        lastVest = rounds[_roundId].lastVest[_wallet];
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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