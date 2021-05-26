// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./SafeERC20.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time. 
 * 
 * NOTE THIS ONE WORKS WITH UNI V3 TOKENS!!!! SPECIFICALLY FOR EPSTEIN TOKEN!!!
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock is IERC721Receiver{
    using SafeERC20 for IERC20;

    // ERC721 basic token contract being held
    IERC721 immutable private _token;

    // beneficiary of tokens after they are released
    address immutable private _beneficiary;

    // timestamp when token release is enabled
    uint256 immutable private _releaseTime;

    constructor (IERC721 token_, address beneficiary_, uint256 releaseTime_) {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC721) {
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
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransferFrom(address(this), beneficiary(), 20234);
        
    }
}