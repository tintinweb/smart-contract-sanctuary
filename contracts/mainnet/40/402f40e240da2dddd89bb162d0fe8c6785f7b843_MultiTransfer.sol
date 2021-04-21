/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.4.25;
contract MultiTransfer {
    function multiTransfer(address[] _addresses, uint256 amount) payable {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].call.value(amount).gas(21000)();
        }
    }
    function() payable {}
}