//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./TeamControl.sol";

contract ETHPool is TeamControl {
    mapping(address => uint256) private accountShares;
    uint256 private totalShares;

    event RewardsAdded(address indexed account, uint256 amount);
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    constructor() {
        totalShares = 0;
    }

    function deposit() external payable {
        require(msg.value > 0, "send some eth ser");

        uint256 shares;

        if (totalShares == 0) {
            shares = msg.value;
        } else {
            shares = msg.value * totalShares / (address(this).balance - msg.value);
        }

        totalShares += shares;
        accountShares[msg.sender] += shares;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 shares = accountShares[msg.sender];
        require(shares > 0, "you didnt send any eth ser");

        uint256 value = address(this).balance * shares / totalShares;
        totalShares -= shares;
        accountShares[msg.sender] = 0;

        (bool sent,) = msg.sender.call{value: value}("");
        require(sent, "failed to send eth");

        emit Withdrawn(msg.sender, value);
    }

    receive() external payable onlyTeam() {
        require(totalShares > 0, "cant deposit rewards if there are no deposits");

        emit RewardsAdded(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TeamControl {
    mapping (address => bool) private team;

    modifier onlyTeam() {
        require(isTeamMember(msg.sender), "restricted to team members only");
        _;
    }

    constructor() {
        team[msg.sender] = true;
    }

    function isTeamMember(address account) public view returns (bool) {
        return team[account];
    }

    function addTeamMember(address account) external onlyTeam {
        _addTeamMember(account);
    }

    function removeTeamMember(address account) external onlyTeam {
        _removeTeamMember(account);
    }

    function _addTeamMember(address account) internal virtual {
        team[account] = true;
    }

    function _removeTeamMember(address account) internal virtual {
        team[account] = false;
    }
}