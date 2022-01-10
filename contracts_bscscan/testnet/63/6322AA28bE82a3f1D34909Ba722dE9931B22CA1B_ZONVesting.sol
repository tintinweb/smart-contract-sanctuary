// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ZONVesting is Ownable {
    IERC20 public immutable _zon;

    uint256 public immutable _tgePercentage;
    uint256 public immutable _cliffPercentage;
    uint256 public immutable _startTime;
    uint256 public immutable _claimTime;
    uint256 public immutable _endTime;
    uint256 public immutable _periods;

    uint256 public _totalLocked;
    uint256 public _totalReleased;
    uint256 public _totalUsers;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _locked;
    mapping(address => uint256) private _released;

    Stage public _stage;

    enum Stage {
        PENDING,
        WHITELISTING,
        CLAIM,
        CLOSE
    }

    event WhitelisterAdded(address indexed user, uint256 amount);

    event Claimed(address indexed account, uint256 amount, uint256 time);

    // ZON = ...
    constructor(
        address zon,
        uint256 tgePercentage,
        uint256 cliffPercentage,
        uint256 startTime,
        uint256 claimTime,
        uint256 endTime,
        uint256 periods
    ) {
        _zon = IERC20(zon);
        _tgePercentage = tgePercentage;
        _cliffPercentage = cliffPercentage;
        _startTime = startTime;
        _claimTime = claimTime;
        _endTime = endTime;
        _periods = periods;

        _stage = Stage.PENDING;
    }

    modifier canAddWhitelister() {
        require(_stage == Stage.WHITELISTING, "Cannot add whitelister now");
        _;
    }

    modifier canClaim() {
        require(_stage == Stage.CLAIM, "Cannot claim now");
        _;
    }

    function changeStage(Stage stage) public onlyOwner {
        require(stage > _stage, "Cannot change stage");
        _stage = stage;
    }

    modifier onlyWhitelister() {
        require(_whitelist[_msgSender()], "Not in whitelist");
        _;
    }

    function addWhitelisters(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyOwner canAddWhitelister {
        require(users.length == amounts.length, "Input invalid");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < users.length; i++) {
            if (_locked[users[i]] == 0) {
                _totalUsers += 1;
            }

            _locked[users[i]] += amounts[i];
            _totalLocked += amounts[i];
            totalAmount += amounts[i];

            _whitelist[users[i]] = true;

            emit WhitelisterAdded(users[i], amounts[i]);
        }

        _zon.transferFrom(_msgSender(), address(this), totalAmount);
    }

    function claim() external onlyWhitelister canClaim {
        require(block.timestamp >= _startTime, "Still locked");
        require(_locked[_msgSender()] > _released[_msgSender()], "No locked");

        uint256 amount = _claimableAmount(_msgSender());
        require(amount > 0, "Nothing to claim");

        _released[_msgSender()] += amount;

        _zon.transfer(_msgSender(), amount);

        _totalLocked -= amount;
        _totalReleased += amount;

        emit Claimed(_msgSender(), amount, block.timestamp);
    }

    function _claimableAmount(address account) private view returns (uint256) {
        if (block.timestamp < _startTime) {
            return 0;
        } else if (block.timestamp < _claimTime) {
            uint256 tgeUnlock = (_locked[account] * _tgePercentage) / 10000;

            return tgeUnlock - _released[account];
        } else if (block.timestamp >= _endTime) {
            return _locked[account] - _released[account];
        } else {
            uint256 passedPeriods = _passedPeriods();
            uint256 unlockAmount = (_locked[account] *
                (_tgePercentage + _cliffPercentage)) / 10000;

            return
                unlockAmount +
                (((_locked[account] - unlockAmount) * passedPeriods) /
                    _periods) -
                _released[account];
        }
    }

    function _passedPeriods() private view returns (uint256) {
        return
            (block.timestamp >= _endTime)
                ? _periods
                : ((block.timestamp - _claimTime) * _periods) /
                    (_endTime - _claimTime);
    }

    /* For FE
        0: isWhitelister
        1: locked amount
        2: released amount
        3: claimable amount
    */
    function infoWallet(address user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _whitelist[user],
            _locked[user],
            _released[user],
            _claimableAmount(user)
        );
    }

    /* ========== EMERGENCY ========== */
    function governanceRecoverUnsupported(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
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