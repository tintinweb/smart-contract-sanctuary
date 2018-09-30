pragma solidity ^0.4.24;

contract Owned {

  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, &#39;Authorization denied, only owner&#39;);
    _;
  }

  constructor() internal {
    owner = msg.sender;
  }
}

contract RgbWallet is Owned {

  struct Rgb {
    uint r;
    uint g;
    uint b;
  }

  struct Player {
    uint interactionPrice;
    Rgb rgb;
  }

  mapping(address => Player) public wallets;

  address[] public playerList;

  uint startTime;

  /* Throw if the sender is not a player */
  modifier onlyPlayer() {
    require(isPlayer(msg.sender), &#39;Not a player&#39;);
    _;
  }

  /* Throw if the game is over */
  modifier gameInProgress() {
    require(now <= startTime + 1 weeks, &#39;Game over&#39;);
    _;
  }

  /* Throw if the game is not over */
  modifier gameOver() {
    require(now > startTime + 1 weeks, &#39;Game in progress&#39;);
    _;
  }

  /* Emitted each time a player join the game */
  event NewPlayer(address indexed playerAddress);

  /* Emitted each time a blending is realized */
  event Blending(
    address indexed blender,
    uint r,
    uint g,
    uint b
  );

  /* Emitted each time a player modifies its interaction price */
  event PriceModification(
    address indexed playerAddress,
    uint interactionPrice
  );

  /* Initializes the owner and the start time */
  constructor() public {
    owner = msg.sender;
    startTime = now;
  }

  /* Sender joins the game */
  function play() gameInProgress public {
    // The sender must not be already a player
    require(!isPlayer(msg.sender), &#39;Already a player&#39;);
    // Register the address in the array of player
    playerList.push(msg.sender);
    // Given the address, derive the corresponding rgb
    uint defaultChoice = uint(msg.sender) % 3;
    Rgb memory defaultColor;
    if (defaultChoice == 0) {
      defaultColor = Rgb(255, 0, 0);
    } else if (defaultChoice == 1){
      defaultColor = Rgb(0, 255, 0);
    } else {
      defaultColor = Rgb(0, 0, 255);
    }
    // Assign the address a token of color derived from it
    wallets[msg.sender] = Player(20, defaultColor);
    // Emit the event
    emit NewPlayer(msg.sender);
  }

  /* Set your interaction price with others */
  function setInteractionPrice(uint _interactionPrice) public {
    wallets[msg.sender].interactionPrice = _interactionPrice;
    emit PriceModification(msg.sender, _interactionPrice);
  }

  /* Sender blends his token with the one of an other address */
  function blendWithOthers(
    address otherPlayer,
    uint targetRgbR,
    uint targetRgbG,
    uint targetRgbB
  ) gameInProgress onlyPlayer public payable {
    // Get the coin of otherPlayer
    Player memory otherCoin = wallets[otherPlayer];
    // The sender must at least send the interactionPrice of the other player
    require(msg.value >= otherCoin.interactionPrice * 1 finney, &#39;Not enough Ether&#39;);
    // The color of the target must be the one in argument
    require(targetRgbR == otherCoin.rgb.r && targetRgbG == otherCoin.rgb.g && targetRgbB == otherCoin.rgb.b, &#39;Target coin has changed&#39;);
    // Get the coin of the sender
    Player storage myCoin = wallets[msg.sender];
    // Blend your coin with the other one
    myCoin.rgb.r = (myCoin.rgb.r + otherCoin.rgb.r) / 2;
    myCoin.rgb.g = (myCoin.rgb.g + otherCoin.rgb.g) / 2;
    myCoin.rgb.b = (myCoin.rgb.b + otherCoin.rgb.b) / 2;
    // Transfer the Ethers
    otherPlayer.transfer(msg.value / 2);
    // Emit the event
    emit Blending(msg.sender, myCoin.rgb.r, myCoin.rgb.g, myCoin.rgb.b);
  }

  /* Sender blends his token with his default rgb code */
  function blendWithYourself() gameInProgress onlyPlayer public payable {
    // The sender must at least send 0.02 ethers
    require(msg.value >= 20 finney, &#39;Not enough Ether&#39;);
    // Get the default color of the sender
    uint defaultChoice = uint(msg.sender) % 3;
    Rgb memory otherCoin;
    if (defaultChoice == 0) {
      otherCoin = Rgb(255, 0, 0);
    } else if (defaultChoice == 1){
      otherCoin = Rgb(0, 255, 0);
    } else {
      otherCoin = Rgb(0, 0, 255);
    }
    // Get the coin of the sender
    Player storage myCoin = wallets[msg.sender];
    // Blend your coin with the other one
    myCoin.rgb.r = (myCoin.rgb.r + otherCoin.r) / 2;
    myCoin.rgb.g = (myCoin.rgb.g + otherCoin.g) / 2;
    myCoin.rgb.b = (myCoin.rgb.b + otherCoin.b) / 2;
    // Emit the event
    emit Blending(msg.sender, myCoin.rgb.r, myCoin.rgb.g, myCoin.rgb.b);
  }

  /* Get the default rgb code of an address */
  function getDefaultRgb(address player) public pure returns (uint[3]) {
    uint defaultChoice = uint(player) % 3;
    Rgb memory defaultRgb;
    if (defaultChoice == 0) {
      defaultRgb = Rgb(255, 0, 0);
    } else if (defaultChoice == 1){
      defaultRgb = Rgb(0, 255, 0);
    } else {
      defaultRgb = Rgb(0, 0, 255);
    }
    return [ defaultRgb.r, defaultRgb.g, defaultRgb.b ];
  }

  /* The owner rewards the winner */
  function rewardWinner() public onlyOwner gameOver {
    address winnerAddress = playerList[0];
    int min = computeScore(playerList[0]);
    uint i;
    while (i < playerList.length) {
      if (computeScore(playerList[i]) < min) {
        winnerAddress = playerList[i];
        min = computeScore(winnerAddress);
      }
      i++;
    }
    winnerAddress.transfer(address(this).balance);
  }

  /* Get the current rgb code of an address */
  function getCurrentRgb(address player) public view returns (uint[3]) {
    Player memory currentRgb = wallets[player];
    return [ currentRgb.rgb.r, currentRgb.rgb.g, currentRgb.rgb.b ];
  }

  /* Get the list of players */
  function getPlayers() public view returns (address[]) {
    return playerList;
  }

  /* Get the price of interaction of an address */
  function getInteractionPrice(address player) public view returns (uint) {
    return wallets[player].interactionPrice;
  }

  /* Check if an address is a player */
  function isPlayer(address _address) public view returns (bool) {
    uint i;
    while (i < playerList.length) {
      if (playerList[i] == _address) {
        return true;
      }
      i++;
    }
    return false;
  }

  function computeScore(address playerAddress) internal view returns (int) {
    Player memory target = wallets[playerAddress];
    int rValue = int(target.rgb.r);
    int gValue = int(target.rgb.g);
    int bValue = int(target.rgb.b);
    int rScore = (rValue - 44) * (rValue - 44);
    int gScore = (gValue - 86) * (gValue - 86);
    int bScore = (bValue - 221) * (bValue - 221);
    return (rScore + gScore + bScore);
  }
}