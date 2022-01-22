/**
 *Submitted for verification at FtmScan.com on 2022-01-22
*/

// File: ..\Contracts\interfaces\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// File: ..\Contracts\Adapter.sol


pragma solidity 0.6.12;


contract Target{}

library Adapter {
    // Pool info
    function lockableToken(Target target, uint256 poolId) external view returns (IERC20) {
        (bool success, bytes memory result) = address(target).staticcall(abi.encodeWithSignature("lockableToken(uint256)", poolId));
        require(success, "lockableToken(uint256 poolId) staticcall failed.");
        return abi.decode(result, (IERC20));
    }

    function lockedAmount(Target target, uint256 poolId) external view returns (uint256) {
        // note the impersonation
        (bool success, bytes memory result) = address(target).staticcall(abi.encodeWithSignature("lockedAmount(address,uint256)", address(this), poolId));
        require(success, "lockedAmount(uint256 poolId) staticcall failed.");
        return abi.decode(result, (uint256));
    }

    // Pool actions
    function deposit(Target target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("deposit(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "deposit(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function withdraw(Target target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("withdraw(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "withdraw(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function claimReward(Target target, uint256 poolId) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("claimReward(address,uint256)", address(target), poolId));
        require(success, "claimReward(uint256 poolId) delegatecall failed.");
    }

    function poolUpdate(Target target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("poolUpdate(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "poolUpdate(uint256 poolId, uint256 amount) delegatecall failed.");
    }

}