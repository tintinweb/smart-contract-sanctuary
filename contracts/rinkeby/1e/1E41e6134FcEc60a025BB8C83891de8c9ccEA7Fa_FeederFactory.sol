/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// Part: Feeder

contract Feeder {
    struct UserProperties {
        uint256 allocation;
        uint256 withdrawn;
    }

    mapping(address => UserProperties) public user;
    address[] public users;

    constructor(address[] memory _wallet, uint256[] memory _allocation) public {
        uint256 percent = 0;
        for (uint256 i = 0; i < _allocation.length; i++) {
            percent += _allocation[i];
        }
        require(percent == 100);

        require(_wallet.length == _allocation.length);
        for (uint256 i = 0; i < _wallet.length; i++) {
            user[_wallet[i]] = UserProperties({
                allocation: _allocation[i],
                withdrawn: 0
            });

            users.push(_wallet[i]);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function withdraw(address payable _to) public payable {
        require(user[_to].allocation > 0, "Zero allocation");

        uint256 sumWithdrawn = 0;
        for (uint256 i = 0; i < users.length; i++) {
            sumWithdrawn += user[users[i]].withdrawn;
        }
        uint256 total = sumWithdrawn + address(this).balance;

        require(
            msg.value <= (total * user[_to].allocation) / 100,
            "Allocation overflow"
        );
        bool sent = _to.send(msg.value);
        user[_to].withdrawn += msg.value;
        require(sent, "Failed to send");
    }
}

// File: FeederFactory.sol

contract FeederFactory {
    Feeder[] public feeders;

    function createFeeder(
        address[] memory _wallet,
        uint256[] memory _allocation
    ) public {
        Feeder feeder = new Feeder(_wallet, _allocation);
        feeders.push(feeder);
    }
}