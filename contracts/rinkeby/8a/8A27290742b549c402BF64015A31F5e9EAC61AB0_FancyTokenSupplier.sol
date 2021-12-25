// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TrustedContacts.sol";
import "./RecoverableErc20ByOwner.sol";
import "./interfaces/IFancyTokenSupplier.sol";

/// @custom:security-contact [email protected]
contract FancyTokenSupplier is
    TrustedContacts,
    RecoverableErc20ByOwner,
    IFancyTokenSupplier
{
    using SafeMath for uint256;

    address public token;
    uint256 public startTime; // TODO
    bool public isFrozenRewardRate;
    // 900000000000000 / (10*365*24*60*60) = 2853881.27854
    uint256 public rewardRate = 2853881.27854 ether;

    bool public isFrozenPools;
    address[] public pools;
    uint256 public sharesTotal;
    mapping(address => uint256) public shares;

    mapping(address => uint256) private _lastSupply;

    constructor() {
        //_setPools(pools_, shares_);
    }

    // Token
    function setToken(address token_) external onlyOwner {
        require(token == address(0), "Token is already set");
        token = token_;
    }

    // Start Time
    function setStartTime(uint256 startTime_) external onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = startTime_;
    }

    // Reward Rate
    function rewardRateOf(address pool_) public view returns (uint256) {
        return rewardRate.mul(shares[pool_]).div(sharesTotal);
    }

    function freezeRewardRate() public onlyOwner {
        require(rewardRate > 0, "RewardRate not setted");
        isFrozenRewardRate = true;
    }

    function setRewardRate(uint256 rewardRate_) external onlyOwner {
        require(!isFrozenRewardRate, "is Frozen");
        rewardRate = rewardRate_;
    }

    // Pools
    function freezePools() public onlyOwner {
        require(poolsTotal() > 0, "Pools not setted");
        isFrozenPools = true;
    }

    function poolsTotal() public view returns (uint256) {
        return pools.length;
    }

    function setPools(address[] memory accounts, uint256[] memory shares_)
        public
        onlyOwner
    {
        require(
            accounts.length == shares_.length,
            "Accounts and shares length mismatch"
        );
        require(accounts.length > 0, "No accounts");
        require(!isFrozenPools, "Is frozen");

        _setPools(accounts, shares_);
    }

    function _setPools(address[] memory accounts, uint256[] memory shares_)
        private
    {
        for (uint256 i = 0; i < pools.length; i++) {
            shares[pools[i]] = 0;
        }
        delete pools;
        sharesTotal = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            _addPayee(accounts[i], shares_[i]);
        }
    }

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "Aaccount is the zero address");
        require(shares_ > 0, "Shares are 0");
        pools.push(account);
        shares[account] = shares_;
        sharesTotal += shares_;
    }

    function lastSupply(address pool_) public view returns (uint256) {
        uint256 lastTime = _lastSupply[pool_];
        if (lastTime > 0 && lastTime > startTime) return lastTime;
        return startTime;
    }

    function supplyToken(uint256 maxTime) external override returns (uint256) {
        require(startTime > 0, "Start time is unsettled");

        if (maxTime > block.timestamp) maxTime = block.timestamp;

        uint256 lastTime = lastSupply(_msgSender());
        _lastSupply[_msgSender()] = maxTime;

        uint256 supply = maxTime
            .sub(lastTime)
            .mul(rewardRate)
            .mul(shares[_msgSender()])
            .div(sharesTotal);

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (supply >= balance) supply = balance;
        bool transferred = IERC20(token).transfer(_msgSender(), supply);
        require(transferred, "TOKEN_FAILED_TRANSFER");
        return supply;
    }

    function sendRewards(address to, uint256 amount)
        external
        override
        onlyTrusted
    {
        bool transferred = IERC20(token).transfer(to, amount);
        require(transferred, "TOKEN_FAILED_TRANSFER");
    }

    function _getRecoverableAmount(address tokenAddress)
        internal
        view
        override
        returns (uint256)
    {
        require(tokenAddress != token, "Cannot withdraw native token");
        return RecoverableErc20ByOwner._getRecoverableAmount(tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITrustedContacts {
    function isTrusted(address contract_) external view returns (bool);

    function addTrustedContract(address contract_) external;

    function removeTrustedContract(address contract_) external;

    event NewTrustedContract(address indexed contract_);
    event RemovedTrustedContract(address indexed contract_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFancyTokenSupplier {
    function supplyToken(uint256 maxTime) external returns (uint256);

    function sendRewards(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITrustedContacts.sol";

/// @custom:security-contact [email protected]
abstract contract TrustedContacts is Ownable, ITrustedContacts {
    mapping(address => bool) private _isTrusted;

    function isTrusted(address contract_) public view override returns (bool) {
        return _isTrusted[contract_];
    }

    modifier onlyTrusted() {
        require(
            isTrusted(_msgSender()),
            "TrustedContacts: caller is not the trusted contact"
        );
        _;
    }

    function addTrustedContract(address contract_) public override onlyOwner {
        _isTrusted[contract_] = true;
        emit NewTrustedContract(contract_);
    }

    function removeTrustedContract(address contract_)
        public
        override
        onlyOwner
    {
        _isTrusted[contract_] = false;
        emit RemovedTrustedContract(contract_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev The contract is intendent to help recovering arbitrary ERC20 tokens
 * accidentally transferred to the contract address.
 */
abstract contract RecoverableErc20ByOwner is Ownable {
    function _getRecoverableAmount(address tokenAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @param tokenAddress ERC20 token's address to recover
     * @param amount to recover from contract's address
     * @param to address to receive tokens from the contract
     */
    function recoverFunds(
        address tokenAddress,
        uint256 amount,
        address to
    ) external virtual onlyOwner {
        uint256 recoverableAmount = _getRecoverableAmount(tokenAddress);
        require(
            amount <= recoverableAmount,
            "RecoverableByOwner: RECOVERABLE_AMOUNT_NOT_ENOUGH"
        );
        recoverErc20(tokenAddress, amount, to);
    }

    function recoverErc20(
        address tokenAddress,
        uint256 amount,
        address to
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = tokenAddress.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RecoverableByOwner: TRANSFER_FAILED"
        );
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