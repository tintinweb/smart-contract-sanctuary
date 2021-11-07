pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Hilo is Ownable, Pausable{
    using SafeMath for uint256;
    mapping(address=>uint) nextBetTime;
    uint betDelay = 10;
    uint public nounce=0;
    uint betRange = 13;
    uint betFee = 200; //2 %
    uint denominator = 10000;
    uint public betLimit = 10000 ether;
    uint winRatio = 80;
    uint winRatioMax = 100;
    IERC20 public token;
    event BetResult(address indexed user, uint time, uint betValue, uint diceValue, uint betAmount, uint earnAmount, bool win);
    event BetWin(bool win);
    constructor(address _token){
        require(_token!=address(0));
        token = IERC20(_token);
    }

    function setFee(uint _fee) external onlyOwner{
        betFee = _fee;
    }

    function setNounce(uint _nounce) external onlyOwner{
        nounce = _nounce;
    }

    function setWinR(uint _ratio) external onlyOwner{
        require(_ratio <= winRatioMax, "ratio great than 100");
        winRatio = _ratio;
    }

    function setDelay(uint _delay) external onlyOwner{
        betDelay = _delay;
    }

    function setBetLimit(uint _limit) external onlyOwner{
        betLimit = _limit;
    }

    function setAssetToken(address _token) external onlyOwner{
        token = IERC20(_token);
    }

    function withDrawAsset(address _to, uint _amount) external onlyOwner{
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance");
        token.transfer(_to, _amount);
    }

    function _earnRatio(uint _bettype, uint _number) private view returns(uint ratio){
        if(_bettype == 0){
            return (denominator - betFee).mul(100).mul(10).div(_winRateTheory(_bettype, _number));
        }else if(_bettype == 1){
            return (denominator - betFee).mul(100).mul(10).div(_winRateTheory(_bettype, _number));
        }
    }

    function earnExpected(uint _bettype, uint _number, uint _amount) public view returns(uint earn){
        if(_bettype == 1 && _number == 1){
            return _amount.sub(betFee);
        }
        if(_bettype == 0 && _number == 13){
            return _amount.sub(betFee);
        }
        return _earnRatio(_bettype, _number).mul(_amount).div(denominator);
    }

    function _betValidate(uint _bettype, uint _number, uint _amount) private view{
        // validate balance
        require(_bettype  == 0 || _bettype==1, "Bet type is 0 or 1");
        require(_amount > 0, "Bet value is 0");
        require(_amount <= betLimit, "Bet amount exceed");
        require(nextBetTime[_msgSender()] <= block.timestamp, "Too fast");
        require(token.balanceOf(_msgSender()) >= _amount, "Insufficient balance");
        require(token.allowance(_msgSender(), address(this)) >= _amount, "Insufficient allowance");
        // less than or equal
        if(_bettype == 0){
            require(_number <= 13, "Less than or equal 13");
            require(_number > 1, "Great than 1");
        // great than or equal
        }else if(_bettype == 1){
            require(_number >= 1, "Great than or equal 1");
            require(_number < 13, "Less than 13");
        }
    }

    //mul 10 time
    function _winRateTheory(uint _bettype, uint _number) private view returns(uint){
        uint winrateTheory = 0;
        if(_bettype == 0){
            winrateTheory = (_number - 0).mul(1000).div(betRange);
        }else if(_bettype == 1){
            winrateTheory = (14 - _number).mul(1000).div(betRange);
        }
        return winrateTheory;
    }

    function isWin(uint _bettype, uint _number, uint _amount) private returns(bool){
        if(_number == 1 && _bettype == 1){
            return true;
        }
        if(_number == 13 && _bettype == 0){
            return true;
        }
        nounce++;
        uint tmp = uint(keccak256(abi.encodePacked(nounce, msg.sender, block.timestamp, _number, _amount)));
        uint winrateTheory = _winRateTheory(_bettype, _number);
        uint winrateReal = winRatio.mul(winrateTheory).div(10);
        uint rndNumber = tmp % denominator;
        emit BetWin(rndNumber < winrateReal);
        return rndNumber < winrateReal;
    }

    function _random(uint _bettype, uint _number, uint _amount, bool _win) private returns(uint){
        uint tmp_nounce = nounce;
        uint _start=1;
        uint _end=13;
        if(_bettype == 0){
            if(_win){
                _end = _number;
            }else{
                _start = _number + 1;
            }
        }else if(_bettype == 1){
            if(_win){
                _start = _number;
            }else{
                _end = _number - 1;
            }
        }
        while(true){
            tmp_nounce++;
            uint tmp = uint(keccak256(abi.encodePacked(tmp_nounce, msg.sender, block.timestamp, _number, _amount)));
            tmp = tmp % (betRange + 1);
            if (tmp == 0){
                tmp = 1;
            }
            if(tmp <= _end && tmp >= _start){
                nounce = tmp_nounce;
                return tmp;
            }
        }
    }

    //bet type
    //0: less than or equal
    //1: great than or equal
    function bet(uint _bettype, uint _number, uint _amount) external whenNotPaused{
        _betValidate(_bettype, _number, _amount);
        nextBetTime[_msgSender()] = block.timestamp + betDelay;
        bool win = isWin(_bettype, _number, _amount);
        uint earn = 0;
        uint rndNumber = _random(_bettype, _number, _amount, win);
        if(win){
            earn = earnExpected(_bettype, _number, _amount);
            if(earn > _amount){
                uint reward = earn.sub(_amount);
                token.transfer(_msgSender(), reward);
            }else{
                token.transferFrom(_msgSender(), address(this), _amount.sub(earn));
            }            
        }else{
            token.transferFrom(_msgSender(), address(this), _amount);
        }
        emit BetResult(_msgSender(), block.timestamp, _number, rndNumber, _amount, earn, win);
    }

    function pauseGame() external onlyOwner{
        _pause();
    }

    function unpauseGame() external onlyOwner{
        _unpause();
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

import "../token/ERC20/IERC20.sol";

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