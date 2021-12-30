/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SendETH {
    constructor() payable {}

    receive() external payable {}

    event TransferEther(address to, uint amount, uint gasUsed, bytes data);

    function sendViaTransfer(address payable _to) external payable {
        uint startGas = gasleft();

        _to.transfer(msg.value);
        
        uint gasUsed = startGas - gasleft();
        emit TransferEther(_to, msg.value, gasUsed, "");
    }

    function sendViaSend(address payable _to) external payable {
        uint startGas = gasleft();
        
        bool success = _to.send(msg.value);
        require(success, "Transfer fail");

        uint gasUsed = startGas - gasleft();
        emit TransferEther(_to, msg.value, gasUsed, "");
    }

    function sendViaCall(address payable _to) external payable {
        uint startGas = gasleft();
        
        (bool success, bytes memory data) = _to.call{value: msg.value}("");
        require(success, "Transfer fail");
        
        uint gasUsed = startGas - gasleft();
        emit TransferEther(_to, msg.value, gasUsed, data);
    }
}