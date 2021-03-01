pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./SafeMath.sol";
import "./ERC20.sol";

contract MyTestToken is ERC20 {
    using SafeMath for uint256;
    address owner;

    constructor() public ERC20("PKTest", "PKT") {
        owner = msg.sender;
        super._mint(_msgSender(), 800000000 * 10 ** 18);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
          owner = newOwner;
        }
    }

    function multisend(address[] memory dests, uint256 amount) public onlyOwner
        returns (uint256) {
            require(dests.length > 0, "Require at least 1 address");
            uint256 value = amount / dests.length;
            uint256 i = 0;
            while (i < dests.length) {
                transfer(dests[i], value);
                i += 1;
            }
            return(i);
    }
}