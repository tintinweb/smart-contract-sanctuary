/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// File: Feeder.sol

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

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function testWithdraw()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 sumWithdrawn = 0;
        for (uint256 i = 0; i < users.length; i++) {
            sumWithdrawn += user[users[i]].withdrawn;
        }
        uint256 total = sumWithdrawn + uint256(address(this).balance);
        uint256 alloc = ((total * user[msg.sender].allocation) / 100) -
            user[msg.sender].withdrawn;

        return (sumWithdrawn, total, alloc, uint256(address(this).balance));
    }

    function withdraw(address payable _to) public payable {
        require(user[_to].allocation > 0, "Zero allocation");
        uint256 sumWithdrawn = 0;
        for (uint256 i = 0; i < users.length; i++) {
            sumWithdrawn += user[users[i]].withdrawn;
        }
        uint256 total = sumWithdrawn + uint256(address(this).balance);

        require(
            msg.value <=
                ((total * user[_to].allocation) / 100) - user[_to].withdrawn,
            "Allocation overflow"
        );
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "Failed to send");
        user[_to].withdrawn += msg.value;
    }
}