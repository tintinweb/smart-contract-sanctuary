// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract ETHPrizeMultisender{

    function multisend(uint _sendingAmount, address[] memory _addresses) external payable {
        uint len = _addresses.length;
        require(msg.value == _sendingAmount*len, "ETH amount is incorrect");
        for(uint i = 0; i < _addresses.length; i++){
            payable(_addresses[i]).transfer(_sendingAmount);
        }
    }
}