/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: stacking.sol


pragma solidity ^0.8.3;


// This contract handles staking PKN to get access to premium features
contract PKNPremium {

    uint256 constant LOCK_PERIOD = 365 days;

    mapping(address => uint256) _pknStakedBy;
    mapping(address => uint256) _unlockTimeOf;

    IERC20 public immutable PKN;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event Renew(address user, uint256 amount);

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function pknStackedBy(address user) public view returns(uint256) {
        return _pknStakedBy[user];
    }

    function unlockTimeOf(address user) public view returns(uint256) {
        return _unlockTimeOf[user];
    }

    function isSubscriptionActive(address user) public view returns(bool) {
        return block.timestamp < unlockTimeOf(user);
    }

    // Locks PKN for locking period
    function deposit(uint256 _amount) public {
        _unlockTimeOf[msg.sender] = _getUnlockTime(block.timestamp);
        _pknStakedBy[msg.sender] += _amount;
        PKN.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw the unlocked PKN
    function withdraw(uint256 _amount) public {
        require(pknStackedBy(msg.sender) >= _amount, "PKNPremium: Amount too high!");
        require(!isSubscriptionActive(msg.sender), "PKNPremium: PKN not unlocked yet!");

        _pknStakedBy[msg.sender] -= _amount;
        PKN.transfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    // renew an existing or expired subscription
    function renew() public {
        require(pknStackedBy(msg.sender) > 0, "PKNPremium: No PKN stacked!");

        _unlockTimeOf[msg.sender] = _getUnlockTime(block.timestamp);

        emit Renew(msg.sender, _pknStakedBy[msg.sender]);
    }

    function _getUnlockTime(uint256 startTime) internal pure returns(uint256) {
        return startTime + LOCK_PERIOD;
    }
}