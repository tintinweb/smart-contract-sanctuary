pragma solidity ^0.8.0;

import './@openzeppelin/contracts/utils/Context.sol';
import './@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Investment is Context {
    address public investor;
    address public immutable treasury = address(0x0CCD9d7D59dB8404B289a75d88f834DE706cc5c4); // Treasury
    address public immutable takshTreasury = address(0x0CCD9d7D59dB8404B289a75d88f834DE706cc5c4);

    IERC20 public TAKSH = IERC20(0x80D6180F7AF1E86dfa1241AC363D4dbA82B9CaeC);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    uint256[] vestingUnlock = [10368000, 20736000, 31104000];
    uint256 upfront = 1176470588000000000000000;
    uint256[] unlock = [914509803816400000000000,914509803816400000000000,914509803816400000000000];  
    uint256 investmentAmount = 200000000000000000000000; // 200,000 USDC
    bool invested = false;
    uint256 investmentTime;


    function invest() public {
        require(invested == false, 'already invested');
        USDC.transferFrom(msg.sender, takshTreasury, investmentAmount);
        TAKSH.transferFrom(treasury, msg.sender, upfront);
        TAKSH.transferFrom(treasury, address(this), 2746529411449200000000000);
        investmentTime = block.timestamp;
        investor = address(msg.sender);
        invested = true;
    }

    function unlock1() external {
        require(block.timestamp >= vestingUnlock[0]+investmentTime, "vesting period not over yet");
        require(invested == true);
        TAKSH.transfer(investor, unlock[0]);
    }

    function unlock2() external {
        require(block.timestamp >= vestingUnlock[1]+investmentTime, "vesting period not over yet");
        require(invested == true);
        TAKSH.transfer(investor, unlock[1]);
    }

    function unlock3() external {
        require(block.timestamp >= vestingUnlock[2]+investmentTime, "vesting period not over yet");
        require(invested == true);
        TAKSH.transfer(investor, unlock[2]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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