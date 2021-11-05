/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

/// @custom:security-contact [email protected]
contract BudgetDAODistributor is Pausable, Ownable {

    event BudgetWithdrawn(address indexed to, uint256 weiAmount);
    event RewardsAssigned(address indexed contributor, uint256 weiAmount);
    event RewardsReversed(address indexed contributor, uint256 weiAmount);
    event RewardsReleased(address indexed contributor, uint256 weiAmount);

    address private _token;
    address private _manager;
    mapping(address => uint256) private _rewards;
    uint256 private _assigned;
    uint256 private _released;


    constructor(address token) {
        require(token != address(0), "Need to supply a valid token address");
        _token = token;
        _assignManager(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function availableBudget() public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) - _assigned;
    }

    function withdraw(address payable wallet) public onlyOwner {
        uint256 balance = availableBudget();
        require(balance > 0 && balance <= IERC20(_token).balanceOf(address(this)), "No withdrawable balance");

        require(IERC20(_token).transfer(wallet, balance), "Withdrawal transfer failed");

        emit BudgetWithdrawn(wallet, balance);
    }

    function assignManager(address newManager) public onlyOwner {
        require(newManager != address(0), "Cannot assign manager to the zero address");
        _assignManager(newManager);
    }

    function _assignManager(address newManager) internal {
        _manager = newManager;
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(manager() == msg.sender, "Caller is not the assigned manager");
        _;
    }

    function rewardsOf(address contributor) public view returns (uint256) {
        return _rewards[contributor];
    }

    function rewardsAssigned() public view returns (uint256) {
        return _assigned;
    }

    function rewardsReleased() public view returns (uint256) {
        return _released;
    }

    function assign(address contributor, uint256 weiAmount) public onlyManager whenNotPaused {
        require(contributor != address(0), "Invalid contributor address");
        require(weiAmount > 0 && weiAmount <= availableBudget(), "Invalid amount to assign");

        _rewards[contributor] += weiAmount;
        _assigned += weiAmount;

        emit RewardsAssigned(contributor, weiAmount);
    }

    function reverse(address contributor, uint256 weiAmount) public onlyManager whenNotPaused {
        require(contributor != address(0), "Invalid contributor address");
        require(weiAmount > 0 && weiAmount <= rewardsOf(contributor), "Invalid amount to reverse");

        _rewards[contributor] -= weiAmount;
        _assigned -= weiAmount;

        emit RewardsReversed(contributor, weiAmount);
    }

    function release(address payable contributor, uint256 weiAmount) public onlyManager whenNotPaused {
        require(contributor != address(0), "Invalid contributor address");
        require(weiAmount > 0 && weiAmount <= rewardsOf(contributor), "Invalid amount to release");

        _rewards[contributor] -= weiAmount;
        _assigned -= weiAmount;
        _released += weiAmount;

        require(IERC20(_token).transfer(contributor, weiAmount), "Rewards release transfer failed");

        emit RewardsReleased(contributor, weiAmount);
    }
}