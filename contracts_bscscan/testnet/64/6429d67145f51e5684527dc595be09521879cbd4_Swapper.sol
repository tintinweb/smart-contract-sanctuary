/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.2;


interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

contract Swapper {
    event Swap(uint256 amount, address indexed to);

    address immutable public BSC;
    address immutable public PRNT;

    constructor(address _BSC, address _PRNT) {
        BSC = _BSC;
        PRNT = _PRNT;
    }

    function swap(uint256 amount, address to) external {
        require(amount > 0, "PRNT: ZERO_AMOUNT_BSC");
        require(to != address(0), "PRNT: NULL_ADDRESS_BSC");

        IERC20(BSC).transferFrom(msg.sender, address(this), amount);
        IERC20(PRNT).transfer(to, amount * 10);

        emit Swap(amount, to);
    }
}