/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// File: Feeder.sol

contract Feeder {
    struct UserProperties {
        uint256 allocation;
    }

    mapping(address => UserProperties) public user;

    constructor(address[] memory _wallet, uint256[] memory _allocation) public {
        require(_wallet.length == _allocation.length);
        for (uint256 i = 0; i < _wallet.length; i++) {
            user[_wallet[i]] = UserProperties({allocation: _allocation[i]});
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function withdraw(address payable _to) public payable {
        require(user[_to].allocation > 0, "Zero allocation");
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send");
    }
}