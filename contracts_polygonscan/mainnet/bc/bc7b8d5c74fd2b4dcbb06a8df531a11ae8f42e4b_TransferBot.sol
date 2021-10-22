//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract TransferBot {
    using SafeMath for uint256;

    function transferEth(address payable[] calldata addrs) public payable {
        for (uint256 i = 0; i < addrs.length; i++) {
            addrs[i].transfer(msg.value.div(addrs.length));
        }
    }

    function transferErc20Token(
        address tokenAddress,
        address[] calldata addrs,
        uint256 amountPerAddress
    ) public {
        for (uint256 i = 0; i < addrs.length; i++) {
            IERC20(tokenAddress).transfer(addrs[i], amountPerAddress);
        }
    }
}