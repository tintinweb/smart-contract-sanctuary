/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

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


contract Owner
{

    //0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee busd

    //IERC20(0x98e0Ce598a5536C89C5d1D4264f0Fa4E21FA16fF);

function balance() external view returns (uint256) {
    return IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balanceOf(msg.sender);
}
function approbation(uint _amount) external returns (bool) {
    return IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).approve(address(this), _amount);
}

function allowance(address owner, address spender) external view returns (uint256) {
    return IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).allowance(owner, spender);
}
function transferFr(uint _amount) external {
    IERC20(0xC8856C0f54c4CB1ea091A5Ee46E60FC8C2ed9373).transferFrom(msg.sender, address(this), _amount);
}
}