// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract GulagLock is Ownable {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 immutable private _token;

    // beneficiary of tokens after they are released
    address immutable private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor () {
        _token = IERC20(0x9Ddd23c1Ec9c69BC833008D4D2f86F6aA491bC91);
        _beneficiary = 0x411e5DF5F2E962C0EA497E04A56e949CE1416663;
        _releaseTime = block.timestamp + 180 days;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }

    /**
     * @notice Increase lock time. Decreasing is not available.
     */
    function setReleaseTime(uint256 releaseTime_) public onlyOwner {
        require(releaseTime_ > _releaseTime, "Release time cannot be decreased");
        _releaseTime = releaseTime_;
    }

    /**
     * @notice Withdraw accidentally added tokens, other than LP-tokens.
     */
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner {
        IERC20 token_ = IERC20(tokenAddress);
        require(token_ != _token, "LP-tokens are not allowed to take");
        uint256 amount = token_.balanceOf(address(this));
        require(amount > 0, "Insufficient balance");
        token_.safeTransfer(owner(), tokens);
    }
}