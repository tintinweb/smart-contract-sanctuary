// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.6.8;

contract ParticipantList {
    bool public initialized;
    mapping(address => uint256) public participantAmounts;
    mapping(address => bool) public listManagers;

    event ListInitialized(address[] managers);
    event AmountsUpdated(address indexed account, uint256 amounts);

    function init(address[] memory managers) external {
        require(!initialized, "ParticipantList: ALREADY_INITIALIZED");
        require(managers.length > 0, "ParticipantList: NO_MANAGERS");
        initialized = true;
        for (uint256 i = 0; i < managers.length; i++) {
            listManagers[managers[i]] = true;
        }
        emit ListInitialized(managers);
    }

    function isInList(address account) public view returns (bool) {
        return participantAmounts[account] > 0;
    }

    function setParticipantAmounts(
        address[] memory accounts,
        uint256[] memory amounts
    ) external {
        require(listManagers[msg.sender], "ParticipantList: FORBIDDEN");
        require(
            accounts.length == amounts.length,
            "ParticipantList: INVALID_LENGTH"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 amount = amounts[i];

            participantAmounts[account] = amount;
            emit AmountsUpdated(account, amount);
        }
    }
}

