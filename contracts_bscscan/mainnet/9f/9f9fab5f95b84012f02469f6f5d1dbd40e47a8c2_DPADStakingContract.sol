/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

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

contract DPADStakingContract {
    IERC20 constant token = IERC20(0x601564b128C5bc2F3aB7e0E6FaB474625354f54c);

    struct Stake {
        uint8 amount;
        uint32 endAt;
    }

    mapping (address => Stake) stakes;
    address[] users;

    function _stake(address _user, uint8 _amount) internal {
        require(token.transferFrom(_user, address(this), (_amount - stakes[_user].amount)*1e18), 'DS: Token transfer failed');
        stakes[_user].amount = _amount;
        stakes[_user].endAt = uint32(block.timestamp + 30 days);
    }

    function stake(uint8 _amount) external {
        require(_amount == 120 || _amount == 320 || _amount == 520, 'DS: Can only stake 120, 320 or 520 DPAD');
        require(stakes[msg.sender].amount < _amount, 'DS: Can not downgrade stake');
        _stake(msg.sender, _amount);
    }

    function _unstake(address _user) internal {
        require(token.transfer(_user, stakes[_user].amount*1e18), 'DS: Token transfer failed');
        delete stakes[_user];
    }

    function unstake() external {
        require(stakes[msg.sender].amount > 0, 'DS: No stakes');
        require(stakes[msg.sender].endAt <= block.timestamp, 'DS: staking is not over');

        _unstake(msg.sender);
    }

    function getUserCount() external view returns (uint) {
        return users.length;
    }
}