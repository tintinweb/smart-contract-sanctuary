/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/TokenTimelock.sol)
 
pragma solidity ^0.8.0;
 
interface QZ {
    function transfer (address recipient, uint256 amount)  external returns (bool);
    function balanceOf(address account) external  view returns (uint256);
}
 
contract TokenTimelock {
    
 
    // ERC20 basic token contract being held
    QZ private immutable _token;
 
    // beneficiary of tokens after they are released
    address private immutable _beneficiary;
 
    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;
 
    constructor(
        QZ token_,//代币地址
        address beneficiary_,//锁仓结束回退地址
        uint256 releaseTime_//解锁时间
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }
 
    /**
     * @return the token being held.
     */
    function token() public view virtual returns (QZ) {
        return _token;
    }
 
    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }
 
    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }
 
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");
 
        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");
 
        token().transfer(beneficiary(), amount);
    }
}