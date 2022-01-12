/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Icebreaker {

    struct Challenge {
        address payable challenger;
        address payable inspector;
        uint challengerStakeAtRisk;
        string description;
        uint timeout;
        uint inspectorReward;
    }
    
    mapping (uint => Challenge) public challenges;
    mapping (address => uint) public addressChallengesCount;
    mapping (address => uint) public addressInspectionsCount;
    uint nextChallengeId = 0;

    modifier ifInspectorOf(uint _challengeId) {
        require(challenges[_challengeId].inspector == msg.sender, "You should be the inspector of this challenge");
        _;
    }

    modifier ifChallengeExists(uint _challengeId) {
        require(challenges[_challengeId].challengerStakeAtRisk > 0, "Challenge doesn't exist");
        _;
    }

    modifier onlyWithValue() {
        require(msg.value > 0, "You should put some money here");
        _;
    }

    modifier ifChallengeTimedOut(uint _challengeId) {
        uint timeout = challenges[_challengeId].timeout;
        if (timeout <= block.timestamp) {
            _;
        } else {
            revert(string(abi.encodePacked("The challenge isn`t timouted yet. ", uint2str(timeout - block.timestamp), " seconds left.")));
        }
    }

    //@title GAME MECHANICS
    function createChallenge(string memory _description, address payable _inspector, uint _timeoutAfter, uint _inspectorReward) external payable onlyWithValue {
        require(_inspectorReward < msg.value, "inspector reward should be less or equal than all money you send ");
        challenges[nextChallengeId] = Challenge({
            challenger: payable(msg.sender),
            inspector: _inspector,
            challengerStakeAtRisk: msg.value,
            description: _description,
            timeout: _timeoutAfter + block.timestamp,
            inspectorReward: _inspectorReward
        });
        addressChallengesCount[msg.sender]++;
        addressInspectionsCount[_inspector]++;
        nextChallengeId++;
    }

    function claimChallengeSuccess(uint _challengeId, bool _isInspectorRewarded) external ifChallengeExists(_challengeId) ifInspectorOf(_challengeId) {
        Challenge storage currentChallenge = challenges[_challengeId];

        uint transferToChallenger;
        uint transferToInspector;

        if (_isInspectorRewarded && currentChallenge.inspectorReward > 0) {
            transferToChallenger = currentChallenge.challengerStakeAtRisk - currentChallenge.inspectorReward;
            transferToInspector = currentChallenge.inspectorReward;
        } else {
            transferToChallenger = currentChallenge.challengerStakeAtRisk;
        }

        
        currentChallenge.challenger.transfer(transferToChallenger);
        currentChallenge.inspector.transfer(transferToInspector);
        
        addressChallengesCount[currentChallenge.challenger]--;
        addressInspectionsCount[currentChallenge.inspector]--;
        delete challenges[_challengeId];
    }
    function claimChallengeFailure(uint _challengeId) public
        ifChallengeExists(_challengeId) 
        ifInspectorOf(_challengeId) 
        ifChallengeTimedOut(_challengeId) 
    {
        Challenge storage currentChallenge = challenges[_challengeId];
        
        currentChallenge.inspector.transfer(currentChallenge.challengerStakeAtRisk);
        
        addressChallengesCount[currentChallenge.challenger]--;
        addressInspectionsCount[currentChallenge.inspector]--;
        delete challenges[_challengeId];
    }

    //@title VIEWS
    function getChallengesByUser(address _user) external view returns (uint[] memory) {
        uint[] memory result = new uint[](addressChallengesCount[_user]);
        uint counter = 0;

        for (uint i = 0; i < nextChallengeId; i++) {
            if (challenges[i].challenger == _user) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getInspectionsByUser(address _user) external view returns (uint[] memory) {
        uint[] memory result = new uint[](addressInspectionsCount[_user]);
        uint counter = 0;

        for (uint i = 0; i < nextChallengeId; i++) {
            if (challenges[i].inspector == _user) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getChallengeInfo(uint _challengeId) external view ifChallengeExists(_challengeId) returns (
        address challenger, 
        address inspector, 
        uint challengerStakeAtRisk, 
        uint inspectorReward,
        string memory  description,
        uint timeout
    )  {
        Challenge memory challenge = challenges[_challengeId];
        return (challenge.challenger, challenge.inspector, challenge.challengerStakeAtRisk, challenge.inspectorReward, challenge.description, challenge.timeout);
    }
}

//@title UTILS

function uint2str(uint _i) pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
}