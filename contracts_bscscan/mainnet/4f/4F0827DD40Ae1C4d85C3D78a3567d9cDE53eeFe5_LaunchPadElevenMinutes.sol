// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract LaunchPadElevenMinutes is Ownable {
    using SafeMath for uint256;

    // 4 rounds : 0 = not open, 1 = guaranty round, 2 = First come first serve, 3 = sale finished

    uint256 public round1BeganAt;

    function roundNumber() external view returns (uint256) {
        return _roundNumber();
    }

    function _roundNumber() internal view returns (uint256) {
        uint256 _round;
        if (block.timestamp < round1BeganAt || round1BeganAt == 0) {
            _round = 0;
        } else if (
            block.timestamp >= round1BeganAt &&
            block.timestamp < round1BeganAt.add(round1Duration)
        ) {
            _round = 1;
        } else if (
            block.timestamp >= round1BeganAt.add(round1Duration) && !endUnlocked
        ) {
            _round = 2;
        } else if (endUnlocked) {
            _round = 3;
        }

        return _round;
    }

    function setRound1Timestamp(uint256 _round1BeginAt) external onlyOwner {
        round1BeganAt = _round1BeginAt;
    }

    uint256 public round1Duration = 3600; // in secondes 3600 = 1h

    IERC20 public stableCoin =
        IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //Busd

    mapping(address => uint256) public round1Allowance;
    mapping(address => uint256) _round2Allowance;
    mapping(address => bool) _hasParticipated;

    function isWhitelisted(address _address) public view returns (bool) {
        bool result;
        if (_hasParticipated[_address]) {
            result = true;
        } else if (
            round1Allowance[_address] > 0 || _round2Allowance[_address] > 0
        ) {
            result = true;
        }
        return result;
    }

    function round2Allowance(address _address) public view returns (uint256) {
        uint256 result;
        if (_hasParticipated[_address]) {
            result = _round2Allowance[msg.sender];
        } else if (round1Allowance[_address] > 0) {
            result = round1Allowance[_address].mul(4);
        }
        return result;
    }

    uint256 public tokenTarget = 5262000 * 1E18;
    uint256 public stableTarget = 150000 * 1E18;
    uint256 public multiplier = 3508; // div per 100

    bool public endUnlocked;

    uint256 public totalOwed;
    mapping(address => uint256) public claimable;
    uint256 public stableRaised;

    uint256 public participants;

    event StartSale(uint256 startTimestamp);
    event EndUnlockedEvent(uint256 endTimestamp);
    event ClaimUnlockedEvent(uint256 claimTimestamp);

    event RoundChange(uint256 roundNumber);

    function initSale(uint256 _tokenTarget, uint256 _stableTarget)
        external
        onlyOwner
    {
        require(_stableTarget > 0, "stable target can't be Zero");
        require(_tokenTarget > 0, "token target can't be Zero");
        tokenTarget = _tokenTarget;
        stableTarget = _stableTarget;
        multiplier = tokenTarget.mul(100).div(stableTarget);
    }

    function setTokenTarget(uint256 _tokenTarget) external onlyOwner {
        require(_roundNumber() == 0, "Presale already started!");
        tokenTarget = _tokenTarget;
        multiplier = tokenTarget.mul(100).div(stableTarget);
    }

    function setStableTarget(uint256 _stableTarget) external onlyOwner {
        require(_roundNumber() == 0, "Presale already started!");
        stableTarget = _stableTarget;
        multiplier = tokenTarget.mul(100).div(stableTarget);
    }

    function startSale() external onlyOwner {
        require(_roundNumber() == 0, "Presale round isn't 0");

        round1BeganAt = block.timestamp;
        emit StartSale(block.timestamp);
    }

    function finishSale() external onlyOwner {
        require(!endUnlocked, "Presale already ended!");

        endUnlocked = true;
        emit EndUnlockedEvent(block.timestamp);
    }

    function addWhitelistedAddress(address _address, uint256 _allocation)
        external
        onlyOwner
    {
        round1Allowance[_address] = _allocation;
    }

    function addMultipleWhitelistedAddresses(
        address[] calldata _addresses,
        uint256[] calldata _allocations
    ) external onlyOwner {
        require(
            _addresses.length == _allocations.length,
            "Issue in _addresses and _allocations length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            round1Allowance[_addresses[i]] = _allocations[i];
        }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        round1Allowance[_address] = 0;
    }

    function withdrawStable() external onlyOwner returns (bool) {
        require(endUnlocked, "presale has not yet ended");

        return
            stableCoin.transfer(
                msg.sender,
                stableCoin.balanceOf(address(this))
            );
    }

    //update from original contract
    function claimableAmount(address user) external view returns (uint256) {
        return claimable[user].mul(multiplier).div(100);
    }

    function emergencyWithdrawToken(address _token)
        external
        onlyOwner
        returns (bool)
    {
        return
            IERC20(_token).transfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
    }

    function buyRound1Stable(uint256 _amount) external {
        require(_roundNumber() == 1, "presale isn't on good round");

        require(
            stableRaised.add(_amount) <= stableTarget,
            "Target already hit"
        );
        require(
            round1Allowance[msg.sender] >= _amount,
            "Amount too high or not white listed"
        );
        if (!_hasParticipated[msg.sender]) {
            _hasParticipated[msg.sender] = true;
            _round2Allowance[msg.sender] = round1Allowance[msg.sender].mul(4);
        }

        require(stableCoin.transferFrom(msg.sender, address(this), _amount));

        uint256 amount = _amount.mul(multiplier).div(100);

        require(totalOwed.add(amount) <= tokenTarget, "sold out");

        round1Allowance[msg.sender] = round1Allowance[msg.sender].sub(
            _amount,
            "Maximum purchase cap hit"
        );

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(_amount);
        totalOwed = totalOwed.add(amount);
        stableRaised = stableRaised.add(_amount);

        if (stableRaised == stableTarget) {
            emit RoundChange(3);
            endUnlocked = true;
            emit EndUnlockedEvent(block.timestamp);
        }
    }

    function buyRound2Stable(uint256 _amount) external {
        require(_roundNumber() == 2, "Not the good round");
        require(round2Allowance(msg.sender) > 0, "you are not whitelisted");
        require(_amount > 0, "amount too low");
        require(
            stableRaised.add(_amount) <= stableTarget,
            "target already hit"
        );
        if (!_hasParticipated[msg.sender]) {
            _hasParticipated[msg.sender] = true;
            _round2Allowance[msg.sender] = round1Allowance[msg.sender].mul(4);
        }

        _round2Allowance[msg.sender] = _round2Allowance[msg.sender].sub(
            _amount,
            "Maximum purchase cap hit"
        );

        require(stableCoin.transferFrom(msg.sender, address(this), _amount));

        uint256 amount = _amount.mul(multiplier).div(100);
        require(totalOwed.add(amount) <= tokenTarget, "sold out");

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(_amount);
        totalOwed = totalOwed.add(amount);
        stableRaised = stableRaised.add(_amount);

        if (stableRaised == stableTarget) {
            emit RoundChange(3);
            endUnlocked = true;
            emit EndUnlockedEvent(block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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