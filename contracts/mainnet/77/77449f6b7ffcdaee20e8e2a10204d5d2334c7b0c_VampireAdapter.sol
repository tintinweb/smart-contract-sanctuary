// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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


contract Victim{}


library VampireAdapter {
    // Victim info
    function rewardToken(Victim victim) external view returns (IERC20) {
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("rewardToken()"));
        require(success, "rewardToken() staticcall failed.");
        return abi.decode(result, (IERC20));
    }

    function poolCount(Victim victim) external view returns (uint256) {
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("poolCount()"));
        require(success, "poolCount() staticcall failed.");
        return abi.decode(result, (uint256));
    }

    function sellableRewardAmount(Victim victim) external view returns (uint256) {
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("sellableRewardAmount()"));
        require(success, "sellableRewardAmount() staticcall failed.");
        return abi.decode(result, (uint256));
    }

    // Victim actions
    function sellRewardForWeth(Victim victim, uint256 rewardAmount, address to) external returns(uint256) {
        (bool success, bytes memory result) = address(victim).delegatecall(abi.encodeWithSignature("sellRewardForWeth(address,uint256,address)", address(victim), rewardAmount, to));
        require(success, "sellRewardForWeth(uint256 rewardAmount, address to) delegatecall failed.");
        return abi.decode(result, (uint256));
    }

    // Pool info
    function lockableToken(Victim victim, uint256 poolId) external view returns (IERC20) {
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("lockableToken(uint256)", poolId));
        require(success, "lockableToken(uint256 poolId) staticcall failed.");
        return abi.decode(result, (IERC20));
    }

    function lockedAmount(Victim victim, uint256 poolId) external view returns (uint256) {
        // note the impersonation
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("lockedAmount(address,uint256)", address(this), poolId));
        require(success, "lockedAmount(uint256 poolId) staticcall failed.");
        return abi.decode(result, (uint256));
    }

    // Pool actions
    function deposit(Victim victim, uint256 poolId, uint256 amount) external {
        (bool success,) = address(victim).delegatecall(abi.encodeWithSignature("deposit(address,uint256,uint256)", address(victim), poolId, amount));
        require(success, "deposit(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function withdraw(Victim victim, uint256 poolId, uint256 amount) external {
        (bool success,) = address(victim).delegatecall(abi.encodeWithSignature("withdraw(address,uint256,uint256)", address(victim), poolId, amount));
        require(success, "withdraw(uint256 poolId, uint256 amount) delegatecall failed.");
    }
    
    function claimReward(Victim victim, uint256 poolId) external {
        (bool success,) = address(victim).delegatecall(abi.encodeWithSignature("claimReward(address,uint256)", address(victim), poolId));
        require(success, "claimReward(uint256 poolId) delegatecall failed.");
    }
    
    function emergencyWithdraw(Victim victim, uint256 poolId) external {
        (bool success,) = address(victim).delegatecall(abi.encodeWithSignature("emergencyWithdraw(address,uint256)", address(victim), poolId));
        require(success, "emergencyWithdraw(uint256 poolId) delegatecall failed.");
    }
    
    // Service methods
    function poolAddress(Victim victim, uint256 poolId) external view returns (address) {
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("poolAddress(uint256)", poolId));
        require(success, "poolAddress(uint256 poolId) staticcall failed.");
        return abi.decode(result, (address));
    }

    function rewardToWethPool(Victim victim) external view returns (address) {
        (bool success, bytes memory result) = address(victim).staticcall(abi.encodeWithSignature("rewardToWethPool()"));
        require(success, "rewardToWethPool() staticcall failed.");
        return abi.decode(result, (address));
    }
}