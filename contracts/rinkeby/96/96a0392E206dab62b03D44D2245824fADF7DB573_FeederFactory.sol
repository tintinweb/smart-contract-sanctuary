// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Feeder.sol";

contract FeederFactory {
    struct Birds {
        address[] addresses;
        uint256 len;
    }
    mapping(address => Birds) public feeders;

    function getFeeders(address _addr) public view returns (Birds memory) {
        return feeders[_addr];
    }

    function createFeeder(
        address[] memory _wallet,
        uint256[] memory _allocation,
        string memory _name
    ) public {
        Feeder feeder = new Feeder(_wallet, _allocation, _name);
        for (uint256 i = 0; i < _wallet.length; i++) {
            feeders[_wallet[i]].addresses.push(address(feeder));
            feeders[_wallet[i]].len += 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Feeder {
    struct UserProperties {
        uint256 allocation;
        uint256 withdrawn;
        STATE state;
    }
    string public name;
    mapping(address => UserProperties) public user;
    address[] public users;

    enum STATE {
        OPEN,
        ONGOING
    }

    constructor(
        address[] memory _wallet,
        uint256[] memory _allocation,
        string memory _name
    ) {
        uint256 percent = 0;
        for (uint256 i = 0; i < _allocation.length; i++) {
            percent += _allocation[i];
        }
        require(percent == 100);

        name = _name;

        require(_wallet.length == _allocation.length);
        for (uint256 i = 0; i < _wallet.length; i++) {
            user[_wallet[i]] = UserProperties({
                allocation: _allocation[i],
                withdrawn: 0,
                state: STATE.OPEN
            });

            users.push(_wallet[i]);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalFunded() public view returns (uint256) {
        uint256 sumWithdrawn = 0;
        for (uint256 i = 0; i < users.length; i++) {
            sumWithdrawn += user[users[i]].withdrawn;
        }
        uint256 total = sumWithdrawn + uint256(address(this).balance);
        return total;
    }

    function getAllMembers() public view returns (address[] memory) {
        return users;
    }

    modifier hasAccess(uint256 _amount) {
        require(user[msg.sender].state == STATE.OPEN);
        require(user[msg.sender].allocation > 0, "Zero allocation");
        uint256 total = getTotalFunded();
        require(
            _amount <=
                ((total * user[msg.sender].allocation) / 100) -
                    user[msg.sender].withdrawn,
            "Allocation overflow"
        );
        _;
    }

    function withdraw(uint256 _amount) public payable hasAccess(_amount) {
        user[msg.sender].state = STATE.ONGOING;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to send");
        user[msg.sender].withdrawn += _amount;
        user[msg.sender].state = STATE.OPEN;
    }
}