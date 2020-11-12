pragma solidity 0.5.17;

import "./TeamStorage.sol";

interface GAMER {
    function gamersScalingFactor() external view returns (uint256);
    function balanceOfUnderlying(address amount) external returns(uint256);
    function mint(address to, uint256 amount) external;
}

contract Team is TeamStorage {

    /// @notice An event thats emitted when someone builds a new team.
    event BuildTeam(string teamName);

    /// @notice An event thats emitted when someone joins a team.
    event JoinTeam(string teamName);

    /// @notice An event thats emitted when someone's staking GAMER amount changes.
    event UpdateTeamPoolStaking(address user, bool positive, uint256 amount);


    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }
    
    modifier onlyStakingPool() {
        require(msg.sender == gamerStakingPool, "Only the gamer's staking pool has authority");
        _;
    }

    modifier onlyInTeam(address account) {
        bytes32 targetTeamKey = teamRelationship[account];
        if (targetTeamKey != bytes32(0)) {
            _;
        }
    }

    modifier onlyFreeMan(address account) {
        require(teamRelationship[msg.sender] == bytes32(0), "This user is already in a team.");
        _;
    }

    function _update(address account, bool positive, uint256 amount) internal returns(bool) {
        require(amount != 0, "Amount can't be Zero");
        TeamStructure storage targetTeam = teamsKeyMap[teamRelationship[account]];
        if (positive) {
            if (targetTeam.teamLeader == account && _balances[account] > leaderThreshold) {
                targetTeam.isLeaderValid = true;
            }
            targetTeam.teamTotalStakingAmount = targetTeam.teamTotalStakingAmount.add(amount);
        } else {
            if (targetTeam.teamLeader == account && _balances[account] < leaderThreshold) {
                targetTeam.isLeaderValid = false;
            }
            targetTeam.teamTotalStakingAmount = targetTeam.teamTotalStakingAmount.sub(amount);
        }

        emit UpdateTeamPoolStaking(account, positive, amount);
        return true;
    }

    // Public functions

    function getTeamInfo(address account) external view returns(string memory, uint256) {
        TeamStructure storage targetTeam = teamsKeyMap[teamRelationship[account]];
        uint256 scalingFactor = GAMER(gamerTokenAddress).gamersScalingFactor();
        return (targetTeam.teamName, targetTeam.teamTotalStakingAmount.mul(scalingFactor).div(10**18));
    }

    function isTeamLeader(address account) external view returns(bool) {
        bytes32 targetTeamKey = teamRelationship[account];
        TeamStructure storage targetTeam = teamsKeyMap[targetTeamKey];
        if (targetTeam.teamLeader == account) {
            return true;
        } else {
            return false;
        }
    }

    function getAllTeams() external view returns(bytes32[] memory, uint256[] memory) {
        bytes32[] memory teamKeyList = new bytes32[](teamList.length);
        uint256[] memory teamTotalStakingAmountList = new uint256[](teamList.length);
        for (uint256 i = 0; i < teamList.length; i++) {
            teamKeyList[i] = teamList[i];
            teamTotalStakingAmountList[i] = teamsKeyMap[teamList[i]].teamTotalStakingAmount;
        }
        return (teamKeyList, teamTotalStakingAmountList);
    }

    function _generateTeamKey(string memory teamName) internal pure returns(bytes32) {
        bytes memory packedMsg = abi.encode(teamName);
        bytes32 teamKey = keccak256(packedMsg);
        require(teamKey != bytes32(0), "Team name is not valid.");
        return teamKey;
    }
}