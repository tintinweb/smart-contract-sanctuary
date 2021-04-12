/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

/// @title An ERC token for Gold
contract GoldERC20 {
    /// @dev Returns the amount of tokens in existence.
    uint256 public totalSupply;
    /// @dev Returns the name of the token.
    string public name = 'GOLD';
    /// @dev Returns the symbol of the token.
    string public symbol = 'GLD20';
    /// @dev Returns the decimals places of the token.
    uint8 public decimals = 8;

    /// @dev Returns the amount of tokens owned by `account`
    mapping(address => uint256) public balanceOf;
    /// @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
    mapping(address => mapping(address => uint256)) public allowances;

    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(uint256 _initial_supply) {
        totalSupply = _initial_supply;
        balanceOf[msg.sender] = _initial_supply;
    }

    /// @notice Transfers amount of tokens to address, and MUST fire the Transfer event.
    /// @dev Moves `amount` tokens from the caller's account to `recipient`. Emits a {Transfer} event.
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function transfer(address _to, uint256 amount) external returns (bool) {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        balanceOf[_to] += amount;

        emit Transfer(msg.sender, _to, amount);

        return true;
    }

    /// @notice Transfers amount of tokens from address `_from` to address `_to`, and MUST fire the Transfer event.
    /// @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance. Emits a {Transfer} event.
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowances[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Allows _spender to withdraw from your account multiple times, up to the _value amount. If this function is called again it overwrites the current allowance with _value.
    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens. Emits an {Approval} event.
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}