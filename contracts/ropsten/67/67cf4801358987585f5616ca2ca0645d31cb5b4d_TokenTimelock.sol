// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    // ERC20 basic token contract being held
    IERC721 private _token;
    
    uint256 private _index;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;


    constructor (IERC721 token_, address beneficiary_, uint256 releaseTime_, uint256 index_) {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        require(beneficiary_ != address(0), "ERC20: transfer to the zero address");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _index = index_;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC721) {
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
    function release() external {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        token().safeTransferFrom(address(this), beneficiary(), _index);
    }
}