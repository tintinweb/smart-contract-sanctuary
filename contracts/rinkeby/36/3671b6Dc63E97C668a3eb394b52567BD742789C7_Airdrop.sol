// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./Vinyl.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
    using SafeMath for uint256;

    VINYL vinyl;

    constructor(address _vinyl) {
        vinyl = VINYL(_vinyl);
    }

    function airdrop(address[] calldata users, uint256[] calldata numOwned) public onlyOwner {
        vinyl.transferFrom(_msgSender(), address(this), 2500e18);
        require(users.length == numOwned.length, "Array lengths must match.");
        uint256 total = 0;
        for (uint i = 0; i < numOwned.length; i++)
            total = total.add(numOwned[i]);
        uint256 remaining = 2500e18;
        uint256 rate = 2500e18;
        rate = rate.div(total);
        for (uint i = 0; i < users.length; i++) {
            uint256 amount;
            if (i < users.length - 1)
                amount = rate.mul(numOwned[i]);
            else
                amount = remaining;
            vinyl.transferFrom(address(this), users[i], amount);
            remaining.sub(amount);
        }
    }
}