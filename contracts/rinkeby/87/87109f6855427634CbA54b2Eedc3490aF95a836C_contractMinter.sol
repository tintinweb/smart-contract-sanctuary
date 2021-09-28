/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.8.0;

interface catMinter {
    function mintCats(uint _times) external payable;
}

contract contractMinter {
    function mintCatsHyper(uint amount_) external payable {
        for (uint i = 0; i < amount_; i++) {
            catMinter(0xc1bB26d22718BB6E30f2d3b170d657E207614aE6).mintCats{value:msg.value}(20);
        }
    }
}