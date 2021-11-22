/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.8.3;

contract BulkSender {

    function bulkSend(address payable _add) public payable {
       (bool success, bytes memory _d) = _add.call{value: msg.value, gas: 70000}("");
       require(success);
    }
}