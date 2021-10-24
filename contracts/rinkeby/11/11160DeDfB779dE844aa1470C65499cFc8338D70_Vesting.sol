// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting is Ownable {

    /// @notice CPOOL token contract
    IERC20 public immutable cpool;

    /// @notice Timestamp of the vesting begin time
    uint256 public immutable vestingBegin;

    /// @notice Timestmap of the vesting end time
    uint256 public immutable vestingEnd;

    struct VestingParams {
        uint256 amount;
        uint256 vestingCliff;
        uint256 lastUpdate;
        uint256 claimed;
    }

    /// @notice Mapping of IDs to vesting params
    mapping(uint256 => VestingParams) public vestings;

    /// @notice Mapping of addresses to lists of their vesting IDs
    mapping(address => uint256[]) public vestingIds;

    /// @notice Total amount of vested tokens
    uint256 public totalVest;

    /// @notice Next vesting object ID
    uint256 private _nextVestingId;

    struct HoldParams {
        address recipient;
        uint256 amount;
        uint256 unlocked;
        uint256 vestingCliff;
    }

    // CONSTRUCTOR

    /**
     * @notice Contract constructor
     * @param cpool_ Address of the CPOOL contract
     * @param vestingBegin_ Timestamp of the vesting begin time
     * @param vestingEnd_ Timestamp of the vesting end time
     */
    constructor(IERC20 cpool_, uint256 vestingBegin_, uint256 vestingEnd_) Ownable() {
        require(vestingEnd_ > vestingBegin_, "Vesting: vesting end should be greater than vesting begin");

        cpool = cpool_;
        vestingBegin = vestingBegin_;
        vestingEnd = vestingEnd_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Function to claim tokens
     * @param account Address to claim tokens for
     */
    function claim(address account) external {
        uint256 totalAmount;
        for (uint8 i = 0; i < vestingIds[account].length; i++) {
            uint256 amount = getAvailableBalance(vestingIds[account][i]);
            if (amount > 0) {
                totalAmount += amount;
                vestings[vestingIds[account][i]].claimed += amount;
                vestings[vestingIds[account][i]].lastUpdate = block.timestamp;
            }
        }
        require(cpool.transfer(account, totalAmount), "Vesting::claim: transfer error");
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Owner function to hold tokens to a batch of accounts
     * @param params List of HoldParams objects with vesting params
     */
    function holdTokens(HoldParams[] memory params) external onlyOwner {
        uint256 totalAmount;
        for (uint8 i = 0; i < params.length; i++) {
            totalAmount += params[i].amount;
        }
        require(cpool.transferFrom(msg.sender, address(this), totalAmount), "Vesting::holdTokens: transfer failed");
        totalVest += totalAmount;
        for (uint8 i = 0; i < params.length; i++) {
            _holdTokens(params[i]);
        }
    }

    // VIEW FUNCTIONS

    /**
     * @notice Function gets total amount of available for claim tokens for account
     * @param account Account to calculate amount for
     * @return amount Total amount of available tokens
     */
    function getAvailableBalanceOf(address account) external view returns (uint256 amount) {
        for (uint8 i = 0; i < vestingIds[account].length; i++) {
            amount += getAvailableBalance(vestingIds[account][i]);
        }
    }

    /**
     * @notice Function gets amount of available for claim tokens in exact vesting object
     * @param id ID of the vesting object
     * @return Amount of available tokens
     */
    function getAvailableBalance(uint256 id) public view returns (uint256) {
        VestingParams memory vestParams = vestings[id];
        if (block.timestamp < vestParams.vestingCliff) {
            return 0;
        }
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = vestParams.amount - vestParams.claimed;
        } else {
            amount = vestParams.amount * (block.timestamp - vestParams.lastUpdate) / (vestingEnd - vestingBegin);
        }
        return amount;
    }

     /**
     * @notice Function gets amount of vesting objects for account
     * @param account Address of account
     * @return Amount of vesting objects
     */
    function vestingCountOf(address account) external view returns (uint256) {
        return vestingIds[account].length;
    }

    // PRIVATE FUNCTIONS

    /**
     * @notice Private function to hold tokens for one account
     * @param params HoldParams object with vesting params
     */
    function _holdTokens(HoldParams memory params) private {
        require(params.amount > 0, "Vesting::holdTokens: can not hold zero amount");
        require(vestingEnd >= params.vestingCliff, "Vesting::holdTokens: cliff is too late");
        require(params.vestingCliff >= vestingBegin, "Vesting::holdTokens: cliff is too early");
        require(params.unlocked <= params.amount, "Vesting::holdTokens: unlocked can not be greater than amount");

        if (params.unlocked > 0) {
            cpool.transfer(params.recipient, params.unlocked);
        }
        if (params.unlocked < params.amount) {
            vestings[_nextVestingId] = VestingParams({
                amount: params.amount - params.unlocked,
                vestingCliff: params.vestingCliff,
                lastUpdate: vestingBegin,
                claimed: 0
            });
            vestingIds[params.recipient].push(_nextVestingId);
            _nextVestingId++;
        }
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