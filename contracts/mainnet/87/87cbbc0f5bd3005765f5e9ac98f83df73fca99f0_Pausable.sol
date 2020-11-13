// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Timelocked.sol";

contract Pausable is Timelocked {
    bool private isPaused = false;

    event Paused();
    event Unpaused();

    function pause() public onlyOwner whenNotLocked {
        isPaused = true;
    }

    function unpause() public onlyOwner whenNotLocked {
        isPaused = false;
    }

    modifier whenNotPaused {
        require(!isPaused, "Contract is paused");
        _;
    }
}
