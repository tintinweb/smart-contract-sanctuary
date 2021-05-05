/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

abstract contract IFlashbotsMinerPaymentV1 {
    function payMiner() external payable virtual;
    function queueEther() external payable virtual;
}

contract PayMinerForNothing {
    IFlashbotsMinerPaymentV1 private constant flashbotsMinerPaymentV1 = IFlashbotsMinerPaymentV1(0xf1A54b075Fb71768ac31B33fd7c61ad8f9f7Dd18);

    function payMinerDirectly() external payable {
        block.coinbase.transfer(msg.value);
    }
    
    function payMinerViaProxy() external payable {
        flashbotsMinerPaymentV1.payMiner{value: msg.value}();
    }
}