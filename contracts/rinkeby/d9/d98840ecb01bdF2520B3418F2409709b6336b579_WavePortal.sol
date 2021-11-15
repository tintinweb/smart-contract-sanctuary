// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.0;

contract WavePortal {

  address public me;
  uint private seed;
  uint public prizeAmount = 0.05 ether;

  mapping(address => uint) public numOfWaves;
  mapping(address => uint) public lastWavedAt;

  constructor() payable {
    me = msg.sender;
  }

  /// @dev Lets this contract accept ether.
  receive() external payable {}

  event NewWave(address indexed from, uint timestamp, string message);
  event PrizeWon(address indexed winner, uint prizeAmount);

  /// @dev Lets someone wave at you.
  function waveAtMe(string calldata _message) external {

    require(lastWavedAt[msg.sender] + 15 minutes < block.timestamp, "Must wait 15 minutes before waving again.");
    
    // Update the `waves` mapping
    numOfWaves[msg.sender] += 1;
    lastWavedAt[msg.sender] = block.timestamp;

    // Distribute prize: 50% chance of winning.
    distributePrize();

    // Emit the `Wave` event.
    emit NewWave(msg.sender, block.timestamp, _message);
  }

  /// @dev Lets `me` set the prize amount.
  function setPrizeAmount(uint _newPrizeAmount) external {
    require(msg.sender == me, "Not authorized to change prize amount");
    prizeAmount = _newPrizeAmount;
  }

  /// @dev Lets `me` withdraw funds from the contract.
  function withdrawFunds(uint _amount) external {
    require(msg.sender == me, "Not authorized to withdraw money from the contract");
    require(_amount <= address(this).balance, "Trying to withraw more money than the contract has.");

    (bool success,) = (msg.sender).call{value: _amount}("");
    require(success, "Failed to withdraw money from contract.");
  }

  /// @dev Gives a wave-r a 50% of winning `prizeAmount`
  function distributePrize() internal {

    // Generate a PSEUDO random number in the range 100.
    uint randomNumber = (block.difficulty + block.timestamp + seed) % 100;

    // Set the generated random number as the seed for the next wave the contract will handle.
    seed =  randomNumber;

    // Distribute prize to wave-r if they're lucky.
    if(randomNumber < 50) {
      (bool success,) = (msg.sender).call{value: prizeAmount}("");
      require(success, "Failed to send prize money to waver.");

      emit PrizeWon(msg.sender, prizeAmount);
    }
  }
}

