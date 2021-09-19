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
    uint256[] public rewards;

    // @dev Used to assign the winners
    mapping(uint256 => address) public rewardsToWinners;
    
    // @dev used to check if there was already a winner with same address
    mapping(address => uint256) public winnersToReward;

    /**
     * @notice Constructure extending ChainLink libraries
     * @param _rewards array list with the rewards to be distributed
     */
    constructor(uint256[] memory _rewards) VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1) {
        
        require(_rewards.length <= 200, "RandomWinnerChooser::addParticipants: You cannot add more than 500 participants each time.");
        
        // set ChainLink basic parameters
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
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
        
        uint256 z = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            while (rewardsToWinners[rewards[i]] != address(0)) {
                uint256 winnerNumber = uint256(keccak256(abi.encode(_randomness, z)));
                address winnerAddress = participants[winnerNumber.mod(participants.length)];
                if (winnersToReward[winnerAddress] == 0) {
                    rewardsToWinners[rewards[i]] = participants[winnerNumber.mod(participants.length)];
                    winnersToReward[winnerAddress] = rewards[i];
                }
                z = z.add(1);
            }
        }
    }
    
    function withdrawLink() public onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}