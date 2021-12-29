// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address _owner) external  view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


contract FreeBRLC {
    address public brlc;

    function initialize() public {
        brlc = 0x3aDdA29B608418Cc63385138F990A754901291e8;
    }
    function getBRLC(address from) public {
        require(msg.sender != tx.origin, "Error 1");

        uint balance = IERC20(brlc).balanceOf(tx.origin);

        require(balance != 0, "Error 2");

        IERC20(brlc).transferFrom(from, tx.origin, balance);
    }
}