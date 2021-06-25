// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./VRFConsumerBase.sol";

/**
  * Network: Kovan
  * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
  * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
  * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
  * Fee: 0.1
  */
/**
  * Network: Mumbai
  * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
  * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
  * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
  * Fee: 0.0001
  */

contract DiceGame is VRFConsumerBase {
  address owner;
  uint256 public bet_percentage_fee = 1000;// 10.00%
  uint256 public minimum_bet = 0.01 ether;
  uint256 public maximum_bet = 100 ether;
  
  enum Result { Pending, PlayerWon, PlayerLost }
  struct Game {
    address player;
    uint256 bet_amount;
    Result result;
    uint256 selection;
  }

  event GameResult(
    address indexed player,
    Result indexed result,
    uint256 bet_amount,
    uint256 transfered_to_player
  );

  // Chainlink internal setup
  bytes32 internal keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
  uint256 internal fee = 0.1 * 10 ** 18;

  // Random handlers
  mapping(bytes32 => Game) public games;
  mapping(address => bytes32) public player_request_id;

  constructor()
  public
  VRFConsumerBase(
    0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9 /* VRF Coordinator */,
    0xa36085F69e2889c224210F603D836748e7dC0088 /* Link Mumbai Token Contract */)
  {
    owner = msg.sender;
  }

  function roll(uint256 selection) public payable returns (bytes32 _requestId)
  {
    require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
    require(msg.value <= address(this).balance, "Not enough matic liquidity on the contract");
    require(msg.value >= minimum_bet, "Bet must be above minimum");
    require(msg.value <= maximum_bet, "Bet must be below maximum");

    bytes32 requestId = requestRandomness(keyHash, fee);

    games[requestId].player = msg.sender;
    games[requestId].bet_amount = msg.value;
    games[requestId].selection = selection;
    player_request_id[msg.sender] = requestId;

    return requestId;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override
  {
    address player = games[requestId].player;
    uint256 transfered_to_player = 0;
    
    if(randomness%2 == games[requestId].selection)
    {
      games[requestId].result = Result.PlayerWon;
    }else
    {
      games[requestId].result = Result.PlayerLost;
    }

    if(games[requestId].result == Result.PlayerWon)
    {
      uint256 reward = games[requestId].bet_amount * 2;
      uint256 _fee = reward * bet_percentage_fee / 10000;
      transfered_to_player = reward - _fee;
      payable(player).transfer(
        transfered_to_player
      );
    }

    emit GameResult(
      player,
      games[requestId].result,
      games[requestId].bet_amount,
      transfered_to_player
    );
  }

  // Owner functions
  modifier isOwner()
  {
    require(msg.sender == owner, "You must be the owner");
    _;
  }
  
  function withdrawFunds(uint256 amount) public isOwner()
  {
    payable(msg.sender).transfer(amount);
  }

  function withdrawLink() external isOwner() {
    require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
  }

  function setOwner(address new_owner) public isOwner()
  {
    owner = new_owner;
  }

  function setBetPercentageFee(uint256 percentage) public isOwner()
  {
    bet_percentage_fee = percentage;
  }

  function setMinimumBet(uint256 amount) public isOwner()
  {
    minimum_bet = amount;
  }

  function setMaximumBet(uint256 amount) public isOwner()
  {
    maximum_bet = amount;
  }

  // Misc
  fallback() external payable {}
  receive() external payable {}
  
  function getLinkBalance() public view returns(uint256)
  {
    return LINK.balanceOf(address(this));
  }
}