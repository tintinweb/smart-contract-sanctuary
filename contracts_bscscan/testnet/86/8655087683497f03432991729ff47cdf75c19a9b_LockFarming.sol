/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FarmingFactory.sol";

contract LockFarming is Ownable {
    using SafeMath for uint256;

    struct LockItem {
        uint256 amount;
        uint256 expiredAt;
        uint256 lastClaim;
    }

    address[] public participants;
    uint256 public duration;
    IERC20 public lpContract;
    IERC20 public dfyContract;
    FarmingFactory public farmingFactory;
    address private _rewardWallet;
    uint256 private _totalDFYPerMonth;
    mapping(address => LockItem[]) private _lockItemsOf;

    event ReceiveFromSavingFarming(
        address lpToken,
        address participant,
        uint256 amount
    );
    event Deposit(address lpToken, address participant, uint256 amount);
    event ClaimInterest(address lpToken, address participant, uint256 interest);
    event Withdraw(
        address lpToken,
        address participant,
        uint256 amount,
        uint256 interest
    );

    constructor(
        uint256 duration_,
        address lpToken,
        address dfyToken,
        address rewardWallet,
        uint256 totalDFYPerMonth,
        address owner_
    ) Ownable() {
        duration = duration_;
        lpContract = IERC20(lpToken);
        dfyContract = IERC20(dfyToken);
        _rewardWallet = rewardWallet;
        _totalDFYPerMonth = totalDFYPerMonth;
        farmingFactory = FarmingFactory(msg.sender);
        transferOwnership(owner_);
    }

    function getValidLockAmount(address participant)
        external
        view
        returns (uint256)
    {
        LockItem[] memory lockItems = _lockItemsOf[participant];
        uint256 lockAmount = 0;
        for (uint256 i = 0; i < lockItems.length; i++)
            if (block.timestamp < lockItems[i].expiredAt)
                lockAmount = lockAmount.add(lockItems[i].amount);
        return lockAmount;
    }

    function getNumParticipants() external view returns (uint256) {
        return participants.length;
    }

    function getLockItems(address participant)
        external
        view
        returns (LockItem[] memory)
    {
        return _lockItemsOf[participant];
    }

    function getCurrentInterest(address participant, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < _lockItemsOf[participant].length);
        LockItem memory item = _lockItemsOf[participant][index];
        uint256 farmingPeriod = block.timestamp - item.lastClaim;
        if (farmingPeriod > duration) farmingPeriod = duration;
        uint256 totalLpToken = lpContract.balanceOf(address(this));
        if (totalLpToken == 0) return 0;
        return
            item
                .amount
                .mul(_totalDFYPerMonth)
                .div(259200)
                .mul(farmingPeriod)
                .div(totalLpToken);
    }

    function setTotalDFYPerMonth(uint256 dfyAmount) external onlyOwner {
        _totalDFYPerMonth = dfyAmount;
    }

    function receiveLpFromSavingFarming(address participant, uint256 amount)
        external
    {
        address savingFarming = farmingFactory.getSavingFarmingContract(
            address(lpContract)
        );
        require(msg.sender == savingFarming);
        if (_lockItemsOf[participant].length == 0)
            participants.push(participant);
        _lockItemsOf[participant].push(
            LockItem(amount, block.timestamp.add(duration), block.timestamp)
        );
        emit ReceiveFromSavingFarming(address(lpContract), participant, amount);
    }

    function deposit(uint256 amount) external {
        require(lpContract.balanceOf(msg.sender) >= amount);
        require(lpContract.allowance(msg.sender, address(this)) >= amount);
        lpContract.transferFrom(msg.sender, address(this), amount);
        if (_lockItemsOf[msg.sender].length == 0) participants.push(msg.sender);
        _lockItemsOf[msg.sender].push(
            LockItem(amount, block.timestamp.add(duration), block.timestamp)
        );
        emit Deposit(address(lpContract), msg.sender, amount);
    }

    function claimInterest(uint256 index) external {
        uint256 numLockItems = _lockItemsOf[msg.sender].length;
        require(index < numLockItems);
        LockItem storage item = _lockItemsOf[msg.sender][index];
        require(block.timestamp < item.expiredAt);
        uint256 interest = getCurrentInterest(msg.sender, index);
        dfyContract.transferFrom(_rewardWallet, msg.sender, interest);
        item.lastClaim = block.timestamp;
        emit ClaimInterest(address(lpContract), msg.sender, interest);
    }

    function claimAllInterest() external {
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < _lockItemsOf[msg.sender].length; i++) {
            LockItem storage item = _lockItemsOf[msg.sender][i];
            if (block.timestamp < item.expiredAt) {
                uint256 interest = getCurrentInterest(msg.sender, i);
                totalInterest = totalInterest.add(interest);
                item.lastClaim = block.timestamp;
            }
        }
        dfyContract.transferFrom(_rewardWallet, msg.sender, totalInterest);
        emit ClaimInterest(address(lpContract), msg.sender, totalInterest);
    }

    function withdraw(uint256 index) external {
        uint256 numLockItems = _lockItemsOf[msg.sender].length;
        require(index < numLockItems);
        LockItem storage item = _lockItemsOf[msg.sender][index];
        require(block.timestamp >= item.expiredAt);
        uint256 withdrawnAmount = item.amount;
        lpContract.transfer(msg.sender, withdrawnAmount);
        uint256 interest = getCurrentInterest(msg.sender, index);
        dfyContract.transferFrom(_rewardWallet, msg.sender, interest);
        item.amount = _lockItemsOf[msg.sender][numLockItems - 1].amount;
        item.expiredAt = _lockItemsOf[msg.sender][numLockItems - 1].expiredAt;
        item.lastClaim = _lockItemsOf[msg.sender][numLockItems - 1].lastClaim;
        _lockItemsOf[msg.sender].pop();
        if (numLockItems == 1) {
            for (uint256 i = 0; i < participants.length; i++)
                if (participants[i] == msg.sender) {
                    participants[i] = participants[participants.length - 1];
                    participants.pop();
                    break;
                }
        }
        emit Withdraw(
            address(lpContract),
            msg.sender,
            withdrawnAmount,
            interest
        );
    }

    function emergencyWithdraw() external onlyOwner {
        lpContract.transfer(owner(), lpContract.balanceOf(address(this)));
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

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SavingFarming.sol";
import "./LockFarming.sol";

contract FarmingFactory is Ownable {
    address[] public lpTokens;
    address public dfyToken;
    address private _rewardWallet;
    mapping(address => bool) private _isLpTokenSupported;
    mapping(address => address) private _savingFarmingOf;
    mapping(address => uint8) private _numLockTypesOf;
    mapping(address => mapping(uint8 => address)) private _lockFarmingOf;

    event NewSavingFarming(address lpToken, address savingFarmingContract);
    event NewLockFarming(
        address lpToken,
        uint256 duration,
        address lockFarmingContract
    );

    constructor(address dfyToken_, address rewardWallet) Ownable() {
        dfyToken = dfyToken_;
        _rewardWallet = rewardWallet;
    }

    function checkLpTokenStatus(address lpToken) external view returns (bool) {
        return _isLpTokenSupported[lpToken];
    }

    function getNumSupportedLpTokens() external view returns (uint256) {
        return lpTokens.length;
    }

    function getSavingFarmingContract(address lpToken)
        external
        view
        returns (address)
    {
        return _savingFarmingOf[lpToken];
    }

    function getNumLockTypes(address lpToken) external view returns (uint8) {
        return _numLockTypesOf[lpToken];
    }

    function getLockFarmingContract(address lpToken, uint8 lockType)
        external
        view
        returns (address)
    {
        require(lockType > 0 && lockType <= _numLockTypesOf[lpToken]);
        return _lockFarmingOf[lpToken][lockType];
    }

    function createSavingFarming(address lpToken, uint256 totalDFYPerMonth)
        external
        onlyOwner
    {
        require(_savingFarmingOf[lpToken] == address(0));
        SavingFarming newSavingContract = new SavingFarming(
            lpToken,
            dfyToken,
            _rewardWallet,
            totalDFYPerMonth,
            owner()
        );
        _savingFarmingOf[lpToken] = address(newSavingContract);
        if (!_isLpTokenSupported[lpToken]) {
            lpTokens.push(lpToken);
            _isLpTokenSupported[lpToken] = true;
        }
        emit NewSavingFarming(lpToken, address(newSavingContract));
    }

    function createLockFarming(
        address lpToken,
        uint256 duration,
        uint256 totalDFYPerMonth
    ) external onlyOwner {
        LockFarming newLockContract = new LockFarming(
            duration,
            lpToken,
            dfyToken,
            _rewardWallet,
            totalDFYPerMonth,
            owner()
        );
        if (!_isLpTokenSupported[lpToken]) {
            lpTokens.push(lpToken);
            _isLpTokenSupported[lpToken] = true;
        }
        _numLockTypesOf[lpToken]++;
        _lockFarmingOf[lpToken][_numLockTypesOf[lpToken]] = address(
            newLockContract
        );
        emit NewLockFarming(lpToken, duration, address(newLockContract));
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

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LockFarming.sol";
import "./FarmingFactory.sol";

contract SavingFarming is Ownable {
    using SafeMath for uint256;

    struct FarmingInfo {
        uint256 startedAt;
        uint256 amount;
    }

    address[] public participants;
    IERC20 public lpContract;
    IERC20 public dfyContract;
    FarmingFactory public farmingFactory;
    address private _rewardWallet;
    uint256 private _totalDFYPerMonth;
    mapping(address => FarmingInfo) private _farmingInfoOf;

    event Deposit(address lpToken, address participant, uint256 amount);
    event Withdraw(address lpToken, address participant, uint256 amount);
    event TransferToLockFarming(
        address lpToken,
        address participant,
        uint256 amount
    );
    event Settle(address lpToken, address participant, uint256 interest);

    constructor(
        address lpToken,
        address dfyToken,
        address rewardWallet,
        uint256 totalDFYPerMonth,
        address owner_
    ) Ownable() {
        lpContract = IERC20(lpToken);
        dfyContract = IERC20(dfyToken);
        _rewardWallet = rewardWallet;
        _totalDFYPerMonth = totalDFYPerMonth;
        farmingFactory = FarmingFactory(msg.sender);
        transferOwnership(owner_);
    }

    function getNumParticipants() external view returns (uint256) {
        return participants.length;
    }

    function getFarmingAmount(address participant)
        external
        view
        returns (uint256)
    {
        return _farmingInfoOf[participant].amount;
    }

    function getCurrentInterest(address participant)
        public
        view
        returns (uint256)
    {
        FarmingInfo memory info = _farmingInfoOf[participant];
        uint256 farmingPeriod = block.timestamp - info.startedAt;
        uint256 totalLpToken = lpContract.balanceOf(address(this));
        if (totalLpToken == 0) return 0;
        return
            info
                .amount
                .mul(_totalDFYPerMonth)
                .div(259200)
                .mul(farmingPeriod)
                .div(totalLpToken);
    }

    function setTotalDFYPerMonth(uint256 dfyAmount) external onlyOwner {
        _totalDFYPerMonth = dfyAmount;
    }

    function deposit(uint256 amount) external {
        require(lpContract.balanceOf(msg.sender) >= amount);
        require(lpContract.allowance(msg.sender, address(this)) >= amount);
        _settle(msg.sender);
        lpContract.transferFrom(msg.sender, address(this), amount);
        if (_farmingInfoOf[msg.sender].amount == 0)
            participants.push(msg.sender);
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
        _farmingInfoOf[msg.sender].amount = _farmingInfoOf[msg.sender]
            .amount
            .add(amount);
        emit Deposit(address(lpContract), msg.sender, amount);
    }

    function claimInterest() external {
        _settle(msg.sender);
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
    }

    function withdraw(uint256 amount) external {
        require(_farmingInfoOf[msg.sender].amount >= amount);
        _settle(msg.sender);
        lpContract.transfer(msg.sender, amount);
        if (_farmingInfoOf[msg.sender].amount == amount)
            for (uint256 i = 0; i < participants.length; i++)
                if (participants[i] == msg.sender) {
                    participants[i] = participants[participants.length - 1];
                    participants.pop();
                    break;
                }
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
        _farmingInfoOf[msg.sender].amount = _farmingInfoOf[msg.sender]
            .amount
            .sub(amount);
        emit Withdraw(address(lpContract), msg.sender, amount);
    }

    function transferToLockFarming(uint256 amount, uint8 option) external {
        require(_farmingInfoOf[msg.sender].amount >= amount);
        uint8 numLockTypes = farmingFactory.getNumLockTypes(
            address(lpContract)
        );
        require(option > 0 && option <= numLockTypes);
        address lockFarming = farmingFactory.getLockFarmingContract(
            address(lpContract),
            option
        );
        require(lockFarming != address(0));
        _settle(msg.sender);
        lpContract.transfer(lockFarming, amount);
        LockFarming(lockFarming).receiveLpFromSavingFarming(msg.sender, amount);
        if (_farmingInfoOf[msg.sender].amount == amount)
            for (uint256 i = 0; i < participants.length; i++)
                if (participants[i] == msg.sender) {
                    participants[i] = participants[participants.length - 1];
                    participants.pop();
                    break;
                }
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
        _farmingInfoOf[msg.sender].amount = _farmingInfoOf[msg.sender]
            .amount
            .sub(amount);
        emit TransferToLockFarming(address(lpContract), msg.sender, amount);
    }

    function _settle(address participant) private {
        uint256 interest = getCurrentInterest(participant);
        require(dfyContract.balanceOf(_rewardWallet) >= interest);
        require(
            dfyContract.allowance(_rewardWallet, address(this)) >= interest
        );
        dfyContract.transferFrom(_rewardWallet, participant, interest);
        emit Settle(address(lpContract), participant, interest);
    }

    function emergencyWithdraw() external onlyOwner {
        lpContract.transfer(owner(), lpContract.balanceOf(address(this)));
    }
}