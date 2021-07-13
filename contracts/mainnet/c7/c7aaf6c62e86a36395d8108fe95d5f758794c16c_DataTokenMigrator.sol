/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// Sources flattened with hardhat v2.1.2 https://hardhat.org
// NOTE: manually removed extraneous licence identifies and pragmas to accommodate Etherscan Verify & Publish

// File @openzeppelin/contracts/token/ERC20/[email protected]




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


// File contracts/DataTokenMigrator.sol


contract DataTokenMigrator { // is UpgradeAgent, see Crowdsale.sol

    IERC20 public oldToken;
    IERC20 public newToken;

    constructor(IERC20 _oldToken, IERC20 _newToken) {
        oldToken = _oldToken;
        newToken = _newToken;
    }

    /**
     * Everything below this comment is the DATA token UpgradeAgent interface.
     * See https://etherscan.io/address/0x0cf0ee63788a0849fe5297f3407f701e122cc023#code
     */

    // See totalSupply at https://etherscan.io/address/0x0cf0ee63788a0849fe5297f3407f701e122cc023#readContract
    uint256 public originalSupply = 987154514 ether;

    /** UpgradeAgent Interface marker */
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

    /**
     * @param _from token holder that called CrowdsaleToken.upgrade(_value)
     * @param _value amount of tokens to upgrade, checked by the CrowdsaleToken
     */
    function upgradeFrom(address _from, uint256 _value) external {
        require(
            msg.sender == address(oldToken),
            "Call not permitted, UpgradableToken only"
        );
        newToken.transfer(_from, _value);
    }
}