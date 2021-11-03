/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

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

contract Disperse {
    function disperseEther(address payable[] calldata recipients, uint256[] calldata values) external payable {
        // Раздаем эфиры адресам
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        
        // Смотрим оставшийся баланс
        uint256 balance = address(this).balance;

        // Возвращаем сдачу вызывающему метод
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }
    
    function _disperseTokenInternal(IERC20 token, address[] calldata recipients, uint256[] calldata values) internal {
                // Считаем сумму токенов, которые нужно разослать
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
            
        // Требуем пересылку этих токенов на адрес контракта
        require(token.transferFrom(msg.sender, address(this), total));
        
        // Рассылаем токены по адресам
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function disperseToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        _disperseTokenInternal(token, recipients, values);
    }
    
    function disperseMKSToken(address[] calldata recipients, uint256[] calldata values) external {
        // https://ropsten.etherscan.io/token/0xF926701DBE68b78a6ef26ADab5Fca499404cd0e7
        IERC20 token = IERC20(0xF926701DBE68b78a6ef26ADab5Fca499404cd0e7);
        _disperseTokenInternal(token, recipients, values);
    }
}