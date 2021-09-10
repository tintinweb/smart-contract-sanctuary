// SPDX-License-Identifier: Unlicensed

pragma solidity 0.7.5;

import "./ERC20.sol";

contract NFTLv1 is ERC20 {
    constructor() ERC20("nftlv1", "NFTLv1") {
        _mint(_msgSender(), 1400010* 10 ** 18);
    }
}