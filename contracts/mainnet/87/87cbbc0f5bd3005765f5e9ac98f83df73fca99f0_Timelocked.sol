// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Timelocked is Ownable {
    using SafeMath for uint256;

    uint256 releaseTime = 0;

    event Locked();
    event UnlockInitiated(uint256 releaseTime);

    function initiateUnlock() public onlyOwner {
        releaseTime = now.add(60 * 60 * 24 * 10);
        emit UnlockInitiated(releaseTime);
    }

    function Lock() public onlyOwner {
        releaseTime = 0;
        emit Locked();
    }

    modifier whenNotLocked {
        require(releaseTime != 0 && now > releaseTime, "Contract is locked");
        _;
    }
}
