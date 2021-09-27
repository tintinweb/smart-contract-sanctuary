/**
 *Submitted for verification at Etherscan.io on 2021-09-27
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

// File: stack.sol


pragma solidity ^0.8.3;


// This contract handles staking PKN per creator
contract PKNStake4Creator {

    mapping(address => mapping(address => uint256)) private _staked;
    mapping(address => uint256) private _totalStakedBy;
    mapping(address => uint256) private _totalStakedFor;

    IERC20 public immutable PKN;

    event Staked(address user, address creator, uint256 amount);
    event Unstaked(address user, address creator, uint256 amount);

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function staked(address user, address creator) public view returns(uint256) {
        return _staked[user][creator];
    }

    function totalStakedBy(address user) public view returns(uint256) {
        return _totalStakedBy[user];
    }

    function totalStakedFor(address creator) public view returns(uint256) {
        return _totalStakedFor[creator];
    }

    // Stake PKN for for a specific creator
    function stake(address creator, uint256 amount) external {
        uint256 _actualAmount = _receivePKN(msg.sender, amount);

        _staked[msg.sender][creator] += _actualAmount;
        _totalStakedBy[msg.sender] += _actualAmount;
        _totalStakedFor[creator] += _actualAmount;

        emit Staked(msg.sender, creator, _actualAmount);
    }

    // Unstake the staked PKN
    function unstake(address creator, uint256 amount) external {
        require(staked(msg.sender, creator) >= amount, "PKNStake4Creator: Amount too high!");

        _staked[msg.sender][creator] -= amount;
        _totalStakedBy[msg.sender] -= amount;
        _totalStakedFor[creator] -= amount;

        PKN.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, creator, amount);
    }

    function _receivePKN(address from, uint256 amount) internal returns(uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        uint256 balanceAfter = PKN.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
}