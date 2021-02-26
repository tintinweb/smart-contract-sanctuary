// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./Ownable.sol";

contract TEST is Ownable {
    event TestEvent(uint amount, uint valueEth);

    function staked(uint amount) public payable {
        address payable admin = address(uint(address(owner)));
        admin.transfer(msg.value);

        emit TestEvent(amount, msg.value);
    }
}