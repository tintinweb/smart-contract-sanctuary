/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

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
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
}


// File contracts/core/Vester.sol

/**
 * Vester Error Codes
 * V1: vesting start time (_vestingBegin) must be set greater than or equal to current block time
 * V2: vesting cliff must be set greater than or equal to vesting start time (_vestingBegin)
 * V3: vesting end time (_vestingEnd) must be set greater than vesting cliff
 * V4: cannot call claim, the current block time must be greater than or equal to the vesting cliff period
 * V5: setRecipient can only be called by the current set recipient
 */

/**
 * @title Vester
 */

contract Vester {
    address public recipient;
    address public immutable token;

    uint256 public lastUpdate;

    uint256 public immutable vestingAmount;
    uint256 public immutable vestingBegin;
    uint256 public immutable vestingCliff;
    uint256 public immutable vestingEnd;

    constructor(
        address _recipient,
        address _token,
        uint256 _vestingAmount,
        uint256 _vestingBegin,
        uint256 _vestingCliff,
        uint256 _vestingEnd
    ) {
        require(_vestingBegin >= block.timestamp, "V1");
        require(_vestingCliff >= _vestingBegin, "V2");
        require(_vestingEnd > _vestingCliff, "V3");

        recipient = _recipient;
        token = _token;

        vestingAmount = _vestingAmount;
        vestingBegin = _vestingBegin;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        lastUpdate = _vestingBegin;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, "V4");

        uint256 amount;
        uint256 _vestingEnd = vestingEnd;

        if (block.timestamp >= _vestingEnd) {
            amount = IERC20(token).balanceOf(address(this));
        } else {
            amount =
                (vestingAmount * (block.timestamp - lastUpdate)) /
                (_vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }

        IERC20(token).transfer(recipient, amount);
    }

    function setRecipient(address _recipient) public {
        require(msg.sender == recipient, "V5");

        recipient = _recipient;
    }
}