// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";
import "./IETHPool.sol";
import "./IStrongPool.sol";
import "./PlatformFees.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract ETHPoolV2 is IETHPool, IStrongPool, ReentrancyGuard, PlatformFees {

    using SafeMath for uint256;
    bool public initialized;

    uint256 public epochId;
    uint256 public totalStaked;
    mapping(address => bool) public poolContracts;

    mapping(uint256 => address) public stakeOwner;
    mapping(uint256 => uint256) public stakeAmount;
    mapping(uint256 => uint256) public stakeTimestamp;
    mapping(uint256 => bool) public stakeStatus;

    uint256 private stakeId;
    IERC20 private strongTokenContract;
    mapping(address => mapping(uint256 => uint256)) private _ownerIdIndex;
    mapping(address => uint256[]) private _ownerIds;

    event FallBackLog(address sender, uint256 value);
    event PaymentProcessed(address receiver, uint256 amount);

    function init(
        address strongAddress_,
        uint256 stakeFeeNumerator_,
        uint256 stakeFeeDenominator_,
        uint256 unstakeFeeNumerator_,
        uint256 unstakeFeeDenominator_,
        uint256 minStakeAmount_,
        uint256 stakeTxLimit_,
        address payable feeWallet_,
        address serviceAdmin_
    ) external {
        require(!initialized, "ETH2.0Pool: init done");
        PlatformFees.init(
            stakeFeeNumerator_,
            stakeFeeDenominator_,
            unstakeFeeNumerator_,
            unstakeFeeDenominator_,
            minStakeAmount_,
            stakeTxLimit_,
            feeWallet_,
            serviceAdmin_
        );
        ReentrancyGuard.init();

        epochId = 1;
        stakeId = 1;
        strongTokenContract = IERC20(strongAddress_);
        initialized = true;
    }

    function stake(uint256 amount_) external payable nonReentrant override {
        require(amount_.mul(stakeFeeNumerator).div(stakeFeeDenominator) == msg.value, "ETH2.0Pool: Value can not be greater or less than staking fee");
        stake_(amount_, msg.sender);
        require(strongTokenContract.transferFrom(msg.sender, address(this), amount_), "ETH2.0Pool: Insufficient funds");
        processPayment(feeWallet, msg.value);
    }

    function mineFor(address userAddress_, uint256 amount_) external override {
        require(poolContracts[msg.sender], "ETH2.0Pool: Caller not authorised to call this function");
        stake_(amount_, userAddress_);
        require(strongTokenContract.transferFrom(msg.sender, address(this), amount_), "ETH2.0Pool: Insufficient funds");
    }

    function unStake(uint256[] memory stakeIds_) external payable nonReentrant override {
        require(stakeIds_.length <= stakeTxLimit, "ETH2.0Pool: Input array length is greater than approved length");
        uint256 userTokens = 0;

        for (uint256 i = 0; i < stakeIds_.length; i++) {
            require(stakeOwner[stakeIds_[i]] == msg.sender, "ETH2.0Pool: Only owner can unstake");
            require(stakeStatus[stakeIds_[i]], "ETH2.0Pool: Transaction already unStaked");

            stakeStatus[stakeIds_[i]] = false;
            userTokens = userTokens.add(stakeAmount[stakeIds_[i]]);
            if (_ownerIdExists(msg.sender, stakeIds_[i])) {
                _deleteOwnerId(msg.sender, stakeIds_[i]);
            }
            emit Unstaked(msg.sender, stakeIds_[i], stakeAmount[stakeIds_[i]], block.timestamp);
        }

        if (userTokens.mul(unstakeFeeNumerator).div(unstakeFeeDenominator) != msg.value) {
            revert("ETH2.0Pool: Value can not be greater or less than unstaking fee");
        }

        totalStaked = totalStaked.sub(userTokens);
        require(strongTokenContract.transfer(msg.sender, userTokens), "ETH2.0Pool: Insufficient Strong tokens");
        processPayment(feeWallet, userTokens.mul(unstakeFeeNumerator).div(unstakeFeeDenominator));
    }

    function stake_(uint256 amount_, address userAddress_) internal {
        require(_ownerIds[userAddress_].length < stakeTxLimit, "ETH2.0Pool: User can not exceed stake tx limit");
        require(amount_ >= minStakeAmount, "ETH2.0Pool: Amount can not be less than minimum staking amount");
        require(userAddress_ != address(0), "ETH2.0Pool: Invalid user address");

        stakeOwner[stakeId] = userAddress_;
        stakeAmount[stakeId] = amount_;
        stakeTimestamp[stakeId] = block.timestamp;
        stakeStatus[stakeId] = true;
        totalStaked = totalStaked.add(amount_);

        if (!_ownerIdExists(userAddress_, stakeId)) {
            _addOwnerId(userAddress_, stakeId);
        }
        emit Staked(userAddress_,stakeId, amount_, block.timestamp);
        incrementStakeId();
    }

    function addVerifiedContract(address contractAddress_) external anyAdmin {
        require(contractAddress_ != address(0), "ETH2.0Pool: Invalid contract address");
        poolContracts[contractAddress_] = true;
    }

    function removeVerifiedContract(address contractAddress_) external anyAdmin {
        require(poolContracts[contractAddress_], "ETH2.0Pool: Contract address not verified");
        poolContracts[contractAddress_] = false;
    }

    function getUserIds(address user_) external view returns (uint256[] memory) {
        return _ownerIds[user_];
    }

    function getUserIdIndex(address user_, uint256 id_) external view returns (uint256) {
        return _ownerIdIndex[user_][id_];
    }

    // function to transfer eth to recipient account.
    function processPayment(address payable recipient_, uint256 amount_) private {
        (bool sent,) = recipient_.call{value : amount_}("");
        require(sent, "ETH2.0Pool: Failed to send Ether");

        emit PaymentProcessed(recipient_, amount_);
    }

    // function to increment the id counter of Staking entries
    function incrementStakeId() private {
        stakeId = stakeId.add(1);
    }

    function _deleteOwnerId(address owner_, uint256 id_) internal {
        uint256 lastIndex = _ownerIds[owner_].length.sub(1);
        uint256 lastId = _ownerIds[owner_][lastIndex];

        if (id_ == lastId) {
            _ownerIdIndex[owner_][id_] = 0;
            _ownerIds[owner_].pop();
        } else {
            uint256 indexOfId = _ownerIdIndex[owner_][id_];
            _ownerIdIndex[owner_][id_] = 0;
            _ownerIds[owner_][indexOfId] = lastId;
            _ownerIdIndex[owner_][lastId] = indexOfId;
            _ownerIds[owner_].pop();
        }
    }

    function _addOwnerId(address owner, uint256 id) internal {
        uint256 len = _ownerIds[owner].length;
        _ownerIdIndex[owner][id] = len;
        _ownerIds[owner].push(id);
    }

    function _ownerIdExists(address owner, uint256 id) internal view returns (bool) {
        if (_ownerIds[owner].length == 0) return false;

        uint256 index = _ownerIdIndex[owner][id];
        return id == _ownerIds[owner][index];
    }

    fallback() external payable {
        emit FallBackLog(msg.sender, msg.value);
    }

    receive() external nonReentrant payable {
        processPayment(feeWallet, msg.value);
        emit FallBackLog(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.8.0;

interface IETHPool {

    event Staked(address user, uint256 stakeId, uint256 amount, uint256 timestamp);

    event Unstaked(address user, uint256 stakeId, uint256 amount, uint256 timestamp);

    function stake(uint256 amount) external payable;

    function unStake(uint256[] memory stakeIds) external payable;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrongPool {

    function mineFor(address miner, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

import "./Ownable.sol";
import "./IPlatformFees.sol";

contract PlatformFees is Ownable, IPlatformFees {

    uint256 public stakeFeeNumerator;
    uint256 public stakeFeeDenominator;
    uint256 public unstakeFeeNumerator;
    uint256 public unstakeFeeDenominator;
    uint256 public minStakeAmount;
    uint256 public stakeTxLimit;

    address payable public feeWallet;
    bool private initDone;

    function init(
        uint256 stakeFeeNumerator_,
        uint256 stakeFeeDenominator_,
        uint256 unstakeFeeNumerator_,
        uint256 unstakeFeeDenominator_,
        uint256 minStakeAmount_,
        uint256 stakeTxLimit_,
        address payable feeWallet_,
        address serviceAdmin
    ) internal {
        require(!initDone, "PlatformFee: init done");

        stakeFeeNumerator = stakeFeeNumerator_;
        stakeFeeDenominator = stakeFeeDenominator_;
        unstakeFeeNumerator = unstakeFeeNumerator_;
        unstakeFeeDenominator = unstakeFeeDenominator_;
        minStakeAmount = minStakeAmount_;
        stakeTxLimit = stakeTxLimit_;
        feeWallet = feeWallet_;

        Ownable.init(serviceAdmin);
        initDone = true;
    }

    function setStakeFeeNumerator(uint256 numerator_) external override anyAdmin {
        stakeFeeNumerator = numerator_;
    }

    function setStakeFeeDenominator(uint256 denominator_) external override anyAdmin {
        require(denominator_ > 0, "PlatformFee: denominator can not be zero");
        stakeFeeDenominator = denominator_;
    }

    function setUnstakeFeeNumerator(uint256 numerator_) external override anyAdmin {
        unstakeFeeNumerator = numerator_;
    }

    function setUnstakeFeeDenominator(uint256 denominator_) external override anyAdmin {
        require(denominator_ > 0, "PlatformFee: denominator can not be zero");
        unstakeFeeDenominator = denominator_;
    }

    function setMinStakeAmount(uint256 amount_) external override anyAdmin {
        require(amount_ > 0, "PlatformFee: amount can not be zero");
        minStakeAmount = amount_;
    }

    function setStakeTxLimit(uint256 limit_) external override anyAdmin {
        require(limit_ > 0, "PlatformFee: limit can not zero");
        stakeTxLimit = limit_;
    }

    function setFeeWallet(address payable feeWallet_) external override anyAdmin {
        require(feeWallet_ != address(0), "PlatformFee: address can not be zero address");
        feeWallet = feeWallet_;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    bool private init_;

    function init()internal{
        require(!init_, "ReentrancyGuard: init done");
        _status = _NOT_ENTERED;
        init_ = true;        
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

import "./Context.sol";

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
    address private _serviceAdmin;
    bool private initialized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewServiceAdmin(address indexed previousServiceAdmin, address indexed newServiceAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function init(address serviceAdmin_) internal {
        require(!initialized, "Ownable: init done");
        _setOwner(_msgSender());
        _setServiceAdmin(serviceAdmin_);
        initialized = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current service admin.
     */
    function serviceAdmin() public view virtual returns (address) {
        return _serviceAdmin;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the service Admin.
     */
    modifier onlyServiceAdmin() {
        require(serviceAdmin() == _msgSender(), "Ownable: caller is not the serviceAdmin");
        _;
    }

    modifier anyAdmin(){
        require(serviceAdmin() == _msgSender() || owner() == _msgSender(), "Ownable: Caller is not authorized");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setServiceAdmin(address newServiceAdmin) private {
        address oldServiceAdmin = _serviceAdmin;
        _serviceAdmin = newServiceAdmin;
        emit NewServiceAdmin(oldServiceAdmin, newServiceAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPlatformFees {

  function setStakeFeeNumerator(uint256 numerator_) external;

  function setStakeFeeDenominator(uint256 denominator_) external;

  function setUnstakeFeeNumerator(uint256 numerator_) external;

  function setUnstakeFeeDenominator(uint256 denominator_) external;

  function setMinStakeAmount(uint256 _amount) external;

  function setStakeTxLimit(uint256 limit_) external;

  function setFeeWallet(address payable feeWallet_) external;

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