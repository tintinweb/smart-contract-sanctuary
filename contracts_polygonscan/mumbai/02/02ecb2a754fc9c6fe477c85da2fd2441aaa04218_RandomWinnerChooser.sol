pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

/**
 * @title RandomWinnerChooser
 * @dev A random winner choose for X amount of rewards based on a single random number from ChainLink
 * Taken from https://github.com/dandelionlabs-io/random-winner-chooser/blob/master/contracts/RandomWinnerChooser.sol
 */
contract RandomWinnerChooser is Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    
    // @dev Used for chainlink integration
    bytes32 internal keyHash;
    uint256 internal fee;
    bytes32 internal requestId = 0x00;
    
    // @dev Used to assign the participants
    address[] public participants;
    
    // @dev rewardsData
    string[] public rewards;

    // @dev Used to assign the winners
    mapping(string => address) public winners;

    /**
     * @notice Constructure extending ChainLink libraries
     * @param _rewards array list with the rewards to be distributed
     */
    constructor(string[] memory _rewards) VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB) {
        
        require(_rewards.length <= 500, "RandomWinnerChooser::addParticipants: You cannot add more than 500 participants each time.");
        
        // set ChainLink basic parameters
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 100000000000000;
    
        // set the rewards array
        rewards = _rewards;
    }
    
    /**
     * @notice Add participants to the rewards event
     * @param _participants array list of participants
     */
    function addParticipants(address[] memory _participants) external onlyOwner {
        
        require(requestId == 0x00, "RandomWinnerChooser::addParticipants: The rewards are already being distributed.");
        require(_participants.length <= 500, "RandomWinnerChooser::addParticipants: You cannot add more than 500 participants each time.");
        
        for (uint16 i = 0; i < _participants.length; i++) {
            participants.push(_participants[i]);
        }
    }
    
    /**
     * @notice Randomly choose the winners of the event
     */
    function chooseWinners() external onlyOwner {
        
        require(requestId == 0x00, "RandomWinnerChooser::chooseWinners: The rewards are already being distributed.");
        require(participants.length > 0, "RandomWinnerChooser::chooseWinners: You need to add participants first.");
    
        requestId = requestRandomness(keyHash, fee);
    }
    
    /**
     * @notice ChainLink call to distribute randomly the rewards
     * @param _requestId unused
     * @param _randomness random seed to generate as much random numbers as needed
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        
        require(requestId == _requestId, "RandomWinnerChooser::fulfillRandomness: There's an error on ChainLink's call.");
        
        for (uint256 i = 0; i < rewards.length; i++) {
            uint256 winnerNumber = uint256(keccak256(abi.encode(_randomness, i)));
            winners[rewards[i]] = participants[winnerNumber.mod(participants.length)];
        }
    }
    
    function withdrawLink() public onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}