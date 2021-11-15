// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

address payable constant level7 = payable(
    0xE1Ec04a91cCd5686b053eA8892FF6fBeE141f3C1
);

contract Self {
    function end() public {
        selfdestruct(level7);
    }
}

