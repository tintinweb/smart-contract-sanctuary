/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function reward(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract BonusNFT {
    struct Bonus {
        uint256 level;
        uint256 amount;
        bool claimed;
    }

    mapping(address => Bonus) public bonuses;

    IERC20 public ovlToken;
    address public dev;

    constructor(address _ovlToken) {
        ovlToken = IERC20(_ovlToken);
        dev = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == dev, "access denied");
        _;
    }

    function changeDev(address _dev) public restricted {
        dev = _dev;
    }

    function addBonuses(
        address[] memory _users,
        uint256[] memory _levels,
        uint256[] memory _amount
    ) public restricted {
        require(_users.length == _levels.length, "Invalid data");
        require(_users.length == _amount.length, "Invalid data");
        for (uint256 index = 0; index < _users.length; index++) {
            bonuses[_users[index]] = Bonus({
                level: _levels[index],
                amount: _amount[index],
                claimed: false
            });
        }
    }

    function claimBonus() public {
        Bonus memory bonus = bonuses[msg.sender];
        require(!bonus.claimed, "claimed");
        require(bonus.level > 0, "invalid level");
        ovlToken.reward(msg.sender, bonus.amount);

        bonuses[msg.sender].claimed = true;
    }
}