// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAdventureTime {
    function adventureTime(uint256[] calldata _summoner) external;
}

contract DaycareManager {
    IAdventureTime adventureTime =
        IAdventureTime(0xeAAe5c3C28A468E3dB4B044B2Bc2Dc1403638163);
    uint256 public constant DAILY_FEE = 0.01 * 1e18;

    mapping(uint256 => uint256) public daysPaid;

    event registeredDaycare(
        address _registerer,
        uint256 _summonerId,
        uint256 _days
    );
    event executedDaycare(address _executor, uint256 _summonerId);

    function registerDaycare(
        uint256[] calldata _summonerIds,
        uint256[] calldata _days
    ) external payable {
        uint256 len = _summonerIds.length;
        require(len == _days.length, "DCM: Invalid lengths");
        uint256 totalFee = 0;
        for (uint256 i = 0; i < len; i++) {
            require(_days[i] > 0, "DCM: Cannot daycare for 0 days");
            daysPaid[_summonerIds[i]] += _days[i];
            totalFee += _days[i] * DAILY_FEE;
            emit registeredDaycare(msg.sender, _summonerIds[i], _days[i]);
        }
        require(msg.value >= totalFee, "DCM: Insufficient fee");
        // Don't send too much FTM, otherwise it will be stuck in the contract
    }

    function executeDaycare(uint256[] calldata _summonerIds) external {
        for (uint256 i = 0; i < _summonerIds.length; i++) {
            daysPaid[_summonerIds[i]] -= 1;
            emit executedDaycare(msg.sender, _summonerIds[i]);
        }
        // Below line will revert if any summoners can't be adventured
        adventureTime.adventureTime(_summonerIds);
        payable(msg.sender).transfer(_summonerIds.length * DAILY_FEE);
    }
}

