pragma solidity ^0.4.18;

contract CoinStacks {

  // Contract owner
  address private admin;

  // Game parameters
  uint256 private constant BOTTOM_LAYER_BET = 0.005 ether;
  uint16 private constant INITIAL_UNLOCKED_COLUMNS = 10;
  uint256 private maintenanceFeePercent;
  uint private  NUM_COINS_TO_HIT_JACKPOT = 30; // every 30th coin placed win a prize
  uint private MIN_AVG_HEIGHT = 5;
  uint256 private constant JACKPOT_PRIZE = 2 * BOTTOM_LAYER_BET;

  // Coin stack data representation
  //
  // coordinates are represented by a uint32
  // where the first 16 bits represents the _x value as a 16-bit unsigned int
  // where the second 16 bits represents the _y value as a 16-bit unsigned int
  // For example 0x0010000B corresponse to (_x,_y) = (0x10,0xB) = (16,11)
  // Decoding from _coord to (_x,_y):
  // _x = _coord >> 16
  // _y = _coord & 0xFFFF
  // Encoding (_x,_y) to _coord:
  // _coord = (_x << 16) | _y

  mapping(uint32 => address) public coordinatesToAddresses;
  uint32[] public coinCoordinates;

  // Prize
  uint256 public reserveForJackpot;

  // withdrawable address balance
  mapping(address => uint256) public balances;

  // Event
  event coinPlacedEvent (
    uint32 _coord,
    address indexed _coinOwner
  );

  function CoinStacks() public {
    admin = msg.sender;
    maintenanceFeePercent = 1; // Default fee is 1%
    reserveForJackpot = 0;

    // Set the first coin at the leftmost of the bottom row (0,0)
    coordinatesToAddresses[uint32(0)] = admin;
    coinCoordinates.push(uint32(0));
    coinPlacedEvent(uint32(0),admin);
  }

  function isThereACoinAtCoordinates(uint16 _x, uint16 _y) public view returns (bool){
    return coordinatesToAddresses[(uint32(_x) << 16) | uint16(_y)] != 0;
  }

  function getNumCoins() external view returns (uint){
    return coinCoordinates.length;
  }

  function getAllCoins() external view returns (uint32[]){
    return coinCoordinates;
  }

  function placeCoin(uint16 _x, uint16 _y) external payable{
    // check no coin has been placed at (_x,_y)
    require(!isThereACoinAtCoordinates(_x,_y));
    // check the coin below has been placed
    require(_y==0 || isThereACoinAtCoordinates(_x,_y-1));
    // cannot place to locked column
    require(_x<INITIAL_UNLOCKED_COLUMNS || coinCoordinates.length >= MIN_AVG_HEIGHT * _x);

    uint256 betAmount = BOTTOM_LAYER_BET * (uint256(1) << _y); // * pow(2,_y)

    // check if the user has enough balance to place the current coin
    require(balances[msg.sender] + msg.value >= betAmount);

    // Add the transaction amount to the user&#39;s balance
    // and deduct current coin cost from user&#39;s balance
    balances[msg.sender] += (msg.value - betAmount);

    uint32 coinCoord = (uint32(_x) << 16) | uint16(_y);

    coinCoordinates.push(coinCoord);
    coordinatesToAddresses[coinCoord] = msg.sender;

    if(_y==0) { // placing a coin in the bottom layer
      if(reserveForJackpot < JACKPOT_PRIZE) { // goes to jackpot reserve
        reserveForJackpot += BOTTOM_LAYER_BET;
      } else { // otherwise goes to admin
        balances[admin]+= BOTTOM_LAYER_BET;
      }
    } else { // reward the owner of the coin below, minus maintenance fee
      uint256 adminFee = betAmount * maintenanceFeePercent /100;
      balances[coordinatesToAddresses[(uint32(_x) << 16) | _y-1]] +=
        (betAmount - adminFee);
      balances[admin] += adminFee;
    }

    // hitting jackpot: send jackpot prize if this is every 30 th coin
    if(coinCoordinates.length % NUM_COINS_TO_HIT_JACKPOT == 0){
      balances[msg.sender] += reserveForJackpot;
      reserveForJackpot = 0;
    }

    //trigger the event
    coinPlacedEvent(coinCoord,msg.sender);
  }

  // Withdrawing balance
  function withdrawBalance(uint256 _amountToWithdraw) external{
    require(_amountToWithdraw != 0);
    require(balances[msg.sender] >= _amountToWithdraw);
    // Subtract the withdrawn amount from the user&#39;s balance
    balances[msg.sender] -= _amountToWithdraw;

    msg.sender.transfer(_amountToWithdraw);
  }

  //transfer ownership of the contract
  function transferOwnership(address _newOwner) external {
    require (msg.sender == admin);
    admin = _newOwner;
  }

  //change maintenance fee
  function setFeePercent(uint256 _newPercent) external {
    require (msg.sender == admin);
    if(_newPercent<=2) // Fee will never exceed 2%
      maintenanceFeePercent = _newPercent;
  }

  //fallback function for handling unexpected payment
  function() external payable{
    //if any ether is sent to the address, credit the admin balance
    balances[admin] += msg.value;
  }
}