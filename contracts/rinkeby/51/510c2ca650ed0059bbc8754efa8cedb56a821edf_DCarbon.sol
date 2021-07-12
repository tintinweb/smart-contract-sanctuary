/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


struct StakeInfo {
    uint256 quantity;
    uint64 escapeTime;
}

contract DCarbon is IERC20 {
    uint256 _totalSupply = 456789;

    mapping(address => StakeInfo) _stakes;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;

    constructor() {
        _balances[msg.sender] = 456789;
    }

    modifier isShareHolder() {
        if (_balances[msg.sender] > 0) {
            _;
        }
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account] + _stakes[account].quantity;
    }

    function transfer(address receiver, uint256 amount)
        external
        override
        returns (bool)
    {
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender] - amount;
        _balances[receiver] = _balances[receiver] + amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external override returns (bool) {
        require(amount <= _balances[sender]);
        require(amount <= _allowed[sender][msg.sender]);

        _balances[sender] = _balances[sender] - (amount);
        _allowed[sender][msg.sender] = _allowed[sender][msg.sender] - (amount);
        _balances[receiver] = _balances[receiver] + (amount);
        emit Transfer(sender, receiver, amount);
        return true; 
    }

    function stake(uint256 amount, uint64 escape) public isShareHolder {
        require(amount <= _balances[msg.sender]);
        StakeInfo storage info = _stakes[msg.sender];
        require(info.escapeTime <= escape);
        _balances[msg.sender] -= amount;
        info.quantity += amount;
        info.escapeTime = escape;
    }

    function unstake(uint256 amount) public isShareHolder {
        StakeInfo storage info = _stakes[msg.sender];
        require(amount <= info.quantity);
        require(info.escapeTime <= uint64(block.timestamp));
        _balances[msg.sender] += amount;
        info.quantity -= amount;
    }
}