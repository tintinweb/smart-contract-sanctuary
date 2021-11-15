// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./interface/IStake.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stake is IStake, Ownable {

    struct Payout {
        address owner;
        uint256 amount;
        bool active;
        uint256 unlockTimestamp;
    }

    // state variables
    uint256 public payoutId;
    uint256 public unlockWaitingTime = 30 days;
    mapping (address => uint256) public stake;
    address public immutable awxToken;
    mapping (uint256 => Payout) public payouts;
    uint256 public minStake = 0;
    uint256 public maxStake = type(uint256).max;


    constructor(address _awxToken) public {
        awxToken = _awxToken;
    }

    // public

    function stakeTokens (uint256 amount) external override returns (bool){
        require (amount > 0, "Stake: Invalid amount");
        require (amount >= minStake, "Stake: min amount");
        require (amount <= maxStake, "Stake: max amount");
        uint balanceBefore = IERC20(awxToken).balanceOf(address (this));
        // fails with revert from ERC20 if allowance is not enough
        IERC20(awxToken).transferFrom(msg.sender, address(this), amount);
        require (balanceBefore + amount == IERC20(awxToken).balanceOf(address (this)), "Stake: Transfer failed");
        stake[msg.sender] += amount;
        emit Stake(msg.sender, amount);
        return true;
    }

    function unstakeTokens (uint256 amount) external override returns (uint256 _payoutId){
        require (amount > 0, "Unstake: invalid amount");
        require (amount <= stake[msg.sender], "Unstake: insufficient funds");
        uint256 _releaseDate = block.timestamp + unlockWaitingTime;
        // create payout
        _payoutId = ++payoutId;
        Payout storage _payout = payouts[_payoutId];
        _payout.owner = msg.sender;
        _payout.amount = amount;
        _payout.active = true;
        _payout.unlockTimestamp = _releaseDate;


        stake[msg.sender] -= amount;
        // event Unstake(address owner, uint amount, uint period);
        emit Unstake(msg.sender, amount, _releaseDate);
    }
    /**
    * @dev - can be called by anyone any address
    */
    function executePayouts (uint256[] calldata payoutIds) external {
        for (uint i=0; i<payoutIds.length; i++) {
            if (payouts[payoutIds[i]].active && block.timestamp >= payouts[payoutIds[i]].unlockTimestamp) {
                Payout storage _payout = payouts[payoutIds[i]];
                // set status 0
                _payout.active = false;
                // tranfer erc20
                IERC20(awxToken).transfer(_payout.owner, _payout.amount);
                emit PayoutExecuted (payoutIds[i], _payout.owner, _payout.amount);
            }
        }
    }

    // setters

    function setMinStake (uint256 amount) external onlyOwner {
        minStake = amount;
    }

    function setMaxStake (uint256 amount) external onlyOwner {
        maxStake = amount;
    }

    function setUnlockWaitingTime (uint256 period) external onlyOwner {
        unlockWaitingTime = period;
    }

    function forceTransferFunds (address _oldUserAddress, address _newUserAddress) external override onlyOwner {
        require (stake[_oldUserAddress] > 0, "Force: no funds on address");
        stake[_newUserAddress] += stake[_oldUserAddress];
        stake[_oldUserAddress] = 0;
        emit ForceTransferFunds(_oldUserAddress, _newUserAddress);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

interface IStake {
    /**
     * @dev Lock `amount` of tokens from the caller's account to current staking contract.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Stake} event.
     */
    function stakeTokens(uint256 amount) external returns (bool);

    /**
     * @dev Submit a request for an `amount` of tokens to be unstaked.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that tokens are not sent directly. They are locked
     * for a period defined in the contract by governor.
     *
     * Emits a {Unstake} event.
     */
    function unstakeTokens(uint256 amount) external returns (uint256 payoutId);

    function forceTransferFunds(address _oldUserAddress, address _newUserAddress) external;

    /**
     * @dev Emitted when balance for a token is increased
     */
    event Stake(address owner, uint256 amount);
    /**
     * @dev Emitted when request balance is increase for a token
     */
    event Unstake(address owner, uint256 amount, uint256 period);
    /**
     * @dev Emitted when a payout is executed
     */
    event PayoutExecuted(uint256 _payoutId, address receiver, uint256 amount);
    /**
     * @dev Emitted when a force transfer is executed
     */
    event ForceTransferFunds(address _oldUserAddress, address _newUserAddress);
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

