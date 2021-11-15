// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISwapRewarder} from "./interfaces/ISwapRewarder.sol";

contract SwapRewarder is ISwapRewarder {
    IERC20 public immutable dcs;
    address public immutable owner;
    address public immutable minter;
    uint256 public mintRewardAmount = 2000 ether;
    uint256 public burnRewardAmount = 100 ether;

    event RewarderAbort(address indexed to, uint256 amount);

    modifier onlyMinter() {
        require(minter == msg.sender, "require system role");
        _;
    }

    constructor(IERC20 _dcs, address _minter) {
        dcs = _dcs;
        minter = _minter;
        owner = msg.sender;
    }

    function mintReward(address to, uint256) external override onlyMinter {
        if (mintRewardAmount == 0) return;

        dcs.transfer(to, mintRewardAmount);

        emit SwapRewarded(to, mintRewardAmount, true);
    }

    function burnReward(address to, uint256) external override onlyMinter {
        if (burnRewardAmount == 0) return;

        dcs.transfer(to, burnRewardAmount);

        emit SwapRewarded(to, burnRewardAmount, false);
    }

    function abort() external {
        require(owner == msg.sender, "only owner");

        uint256 balance = dcs.balanceOf(address(this));

        dcs.transfer(msg.sender, balance);

        emit RewarderAbort(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapRewarder {
    function mintReward(address to, uint256 amount) external;

    function burnReward(address to, uint256 amount) external;

    event SwapRewarded(address indexed to, uint256 amount, bool isMint);
}

