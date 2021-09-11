// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/**
 * @title EthroneContract
 * @dev Manages the Ethrone game contract
 *
 * Rules:
 * fixed amount to enter (low) goes into prize pool
 * only one player can take the throne per block
 * players can only capture the throne `maxAttempts` times per round (default: 3)
 * time spent accumulates for the user everytimes they takes over the throne
 * a round lasts `roundDuration` seconds (default: 24h)
 * at the end of the round - prizepool goes to user who spent the most time on the Throne
 * if multiple top users with the same time spent -> the first player that has reached the time gets the prize
 */
contract EthroneContract is KeeperCompatibleInterface {

    uint8 public immutable maxAttempts;
    uint32 public immutable roundDuration;
    address public immutable contractOwner;
    uint256 public immutable throneCost;

    uint256 public lastRoundStartTime;
    uint32 public round;
    address public lastWinner;
    ThroneOwner public currentThroneOwner;
    address[] public participants;
    mapping (address => uint32) timeSpentMapping;
    mapping (address => uint8) attemptsMapping;

    event ThroneTaken(address prevOwner, address newOwner, uint32 prevOwnerTimeSpent, uint32 round);
    event WinnerChosen(address winner, uint256 prize, uint32 totalTimeSpent, uint32 round, uint32 totalPlayers);

    struct ThroneOwner {
        address user;
        uint256 timestamp;
        bytes32 hash;
    }

    constructor(uint32 duration, uint8 maxAttemptsPerPlayer, uint256 cost) {
        contractOwner = msg.sender;
        round = 1;
        roundDuration = duration;
        lastRoundStartTime = block.timestamp;
        maxAttempts = maxAttemptsPerPlayer;
        throneCost = cost;
    }

    // Keeper interface

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastRoundStartTime) > roundDuration;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        awardPrize();
    }

    // Game public methods   

    /**
      Main game function
     */
    function takeThrone() public payable {
        require(msg.value == throneCost, "Exactly 0.01 ether is required to take the Ethrone"); // mandatory fixed price
        require((block.timestamp - lastRoundStartTime) < roundDuration, "The round is over! Wait for the next one to start");
        // contractOwner cannot take the throne
        address newOwner = msg.sender;
        require(newOwner != currentThroneOwner.user, "You already own the Ethrone!");
        require(newOwner != contractOwner, "The contract owner is not allowed to play");

        // reject transaction if the current owner already owns this block
        bytes32 currentHash = blockhash(block.number - 1);
        require(currentThroneOwner.hash != currentHash, "The throne is already taken for this block!");

        // reject transaction if player already reached the max attempts this round
        require(attemptsMapping[newOwner] < maxAttempts, "You have reached the maximum attempts for this round");

        // record new participant if not already recorded
        if (attemptsMapping[newOwner] == 0) {
          participants.push(newOwner);
        }

        // increment attempts for player
        attemptsMapping[newOwner] = attemptsMapping[newOwner] + 1;        

        // record time for last owner
        updateLastTimeSpent();

        // set the new owner
        address previousOwner = currentThroneOwner.user;
        currentThroneOwner = ThroneOwner(newOwner, block.timestamp, currentHash);
        emit ThroneTaken(previousOwner, newOwner, accumulatedTimeSpent(previousOwner), round);
    }

    /**
     * Find the winner of the round and transfers the prize to it
     */
    function awardPrize() public {
        require((block.timestamp - lastRoundStartTime) > roundDuration, "The round is not over yet!");
        
        // find winner
        uint32 participantSize = uint32(participants.length);
        uint32 longestTimeSpent = 0;
        address winner;

        // no players this round, start the next one
        if (participantSize == 0) {
            resetGameAndStartNextRound();
            return;
        }

        // update last owner's time spent
        updateLastTimeSpent();

        // find the winner address
        for (uint32 i = 0; i < participantSize; i++) {
            address participant = participants[i];
            uint32 timeSpent = timeSpentMapping[participant];
            if (timeSpent > longestTimeSpent && participant != contractOwner) {
                winner = participant;
                longestTimeSpent = timeSpent;
            }
        }

        // assert valid winner
        require(winner != address(0x0), "Did not find a winner");
        require(winner != contractOwner, "Winner cannot be the owner");
        // transfer prize
        uint256 totalPrize = currentPrizePool();
        uint256 winnerPrize = totalPrize * 90 / 100; // 90% for the winner
        uint256 maintenanceBudget = totalPrize - winnerPrize; // 10% for maintenance costs
        payable(winner).transfer(winnerPrize);
        payable(contractOwner).transfer(maintenanceBudget);
        lastWinner = winner;
        emit WinnerChosen(winner, winnerPrize, accumulatedTimeSpent(winner), round, participantSize);

        // cleanup and start next round
        resetGameAndStartNextRound();
    }

    /**
     * The total prize pool for this round
     */
    function currentPrizePool() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * The time spent by the last owner
     */
    function currentTimeSpent() public view returns (uint32) {
        return uint32(block.timestamp - currentThroneOwner.timestamp);
    }

    /**
     * The address of the current owner
     */
    function currentOwner() public view returns (address) {
      return currentThroneOwner.user;
    }

    /**
     * The previous time spent for a given address (excluding current)
     */
    function accumulatedTimeSpent(address user) public view returns (uint32) {
        return timeSpentMapping[user];
    }

    /**
     * The total time spent (including current) for the given address
     */
    function totalTimeSpent(address user) public view returns (uint32) {
        if (user == currentThroneOwner.user) {
          return currentTimeSpent() + accumulatedTimeSpent(user);
        }
        return accumulatedTimeSpent(user);
    }

    /**
     * Total number of participants for this round
     */
    function totalParticipants() public view returns (uint32) {
        return uint32(participants.length);
    }

    /**
     * The amount of time since current round started
     */
    function currentRoundTime() public view returns (uint32) {
        return uint32(block.timestamp - lastRoundStartTime);
    }

    /**
     * The number of attempts for a given player this round
     */
    function numberOfAttemts(address user) public view returns (uint8) {
        return attemptsMapping[user];
    }

    // PRIVATE

    /**
     * Records the time spent for the current owner 
     */
    function updateLastTimeSpent() private {
        address user = currentThroneOwner.user;
        if (user != address(0x0)) {
          uint256 timeTaken = currentThroneOwner.timestamp;
          timeSpentMapping[user] += uint32(block.timestamp - timeTaken);
        }
    }

    function resetGameAndStartNextRound() private {
        uint32 participantSize = uint32(participants.length);
        for (uint32 i = 0; i < participantSize; i++) {
            address participant = participants[i];
            delete timeSpentMapping[participant]; // clear mapping entry
            delete attemptsMapping[participant];
        }
        delete participants; // clear all participants
        delete currentThroneOwner; // reset current owner

        // prepare for new round
        round = round + 1;
        lastRoundStartTime = block.timestamp;
    }

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == contractOwner, "Caller is not owner");
        _;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}