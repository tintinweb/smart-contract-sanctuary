//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

type Token is address;

contract Faucet {
    mapping(Token => bool) public tokens;
    Token public defaultToken;

    event TokenRegistered(Token indexed token, uint256 initialBalance);
    event GotSomeJuice(address indexed receiver, Token indexed token, uint256 juice);

    modifier tokenRegistered(Token _token) {
        require(tokens[_token], "Faucet: token not registered");
        _;
    }

    function registerNewToken(Token _token) external {
        tokens[_token] = true;
        emit TokenRegistered(_token, _getBalance(_token, address(this)));
    }

    function giveMeDefaultJuice() external {
        _giveMeSomeJuice(defaultToken);
    }

    function giveMeJuice(Token _token) external {
        _giveMeSomeJuice(_token);
    }

    function setDefaultToken(Token _token) external tokenRegistered(_token) {
        defaultToken = _token;
    }

    function getBalance(Token _token) external view tokenRegistered(_token) returns(uint256) {
        return _getBalance(_token, address(this));
    }

    function _getBalance(Token _token, address _address) private view returns(uint256) {
        return IERC20(Token.unwrap(_token)).balanceOf(_address);
    }

    function _getErc20(Token _token) private pure returns(IERC20){
        return IERC20(Token.unwrap(_token));
    }

    function _giveMeSomeJuice(Token _token) private {
        uint256 juiceQuantity = _getBalance(_token, address(this))/10;
        _getErc20(_token).transfer(msg.sender, juiceQuantity);
        emit GotSomeJuice(msg.sender, _token, juiceQuantity);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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