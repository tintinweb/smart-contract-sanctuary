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

    function airdrop(uint256 amount, address[] calldata users, uint256[] calldata numOwned) public onlyOwner {
        vinyl.transferFrom(_msgSender(), address(this), amount);
        require(users.length == numOwned.length, "Array lengths must match.");
        uint256 total = 0;
        for (uint i = 0; i < numOwned.length; i++)
            total = total.add(numOwned[i]);
        uint256 remaining = amount;
        uint256 rate = amount.div(total);
        for (uint i = 0; i < users.length; i++) {
            uint256 sent;
            if (i < users.length - 1)
                sent = rate.mul(numOwned[i]);
            else
                sent = remaining;
            vinyl.transferFrom(address(this), users[i], sent);
            remaining = remaining.sub(sent);
        }
    }
}