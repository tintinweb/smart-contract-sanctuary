/**
 *Submitted for verification at Etherscan.io on 2020-12-29
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: browser/WASPToken.sol

pragma solidity 0.7.6;


contract WASPToken is IERC20 {
    string public constant name = "Wasp";
    string public constant symbol = "WASP";
    uint8 public constant decimals = 6;
    uint256 private _totalSupply = 0;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private _balanceOf;

    constructor() {
        _balanceOf[msg.sender] = 360000000000000;  // 360m
        _totalSupply = 360000000000000;
    }

    function transfer(address to, uint256 value) override public returns (bool success) {
        require(_balanceOf[msg.sender] >= value);

        _balanceOf[msg.sender] -= value;  // deduct from sender's balance
        _balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) override public returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override public returns (bool success) {
        require(value <= _balanceOf[from]);
        require(value <= _allowances[from][msg.sender]);

        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function balanceOf(address account) override public view returns (uint256 balance) {
        return _balanceOf[account];
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
}