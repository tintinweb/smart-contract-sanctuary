/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

contract FlashbotsMinerBribe {
    function bribeMiner() external payable {
        (bool success,) = block.coinbase.call{value:msg.value}(new bytes(0));
        require(success, "!success");
    }
}