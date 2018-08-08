pragma solidity ^0.4.23;


contract Lottery {

  // Structure to represent a single game of one player
  struct BetsUser {
    // Height of blockchain at the time of placement.
    uint placementTime;
    // Position of bet on the desk, to be matched with corresponding value below.
    uint8[MAX_BETTING_AT_ONCE] positions;
    // Value of bet. values[i] and positions[i] are used to represent a single bet.
    uint16[MAX_BETTING_AT_ONCE] values;
    // The number of bets the user has done at once.
    uint8 betsLength;
  }

  // Contract owner
  address owner;

  // The main storage in the contract. Mapping of player to last game of this player.
  // Each player should claim his bet before playing again.
  mapping (address => BetsUser) betsPerUser;

  // Various constants listed below
  uint8 constant NUM_BETTING_POSITIONS = 49;
  uint8 constant MAX_BETTING_AT_ONCE = 10;
  uint16 constant MAX_BETTING_VALUE_SUM = 5000;
  uint16 constant MAX_BET_FINNEY = 1000;
  uint constant FINNEY_TO_WEI = 1000000000000000;

  // We use the numbers after 36 to designate non-numeric bets like evens, reds and so on.
  uint8 constant FIRST_COLLUMN = 37;
  uint8 constant SECOND_COLLUMN = 38;
  uint8 constant THIRD_COLLUMN = 39;
  uint8 constant FIRST_THIRD = 40;
  uint8 constant MIDDLE_THIRD = 41;
  uint8 constant LAST_THIRD = 42;
  uint8 constant FIRST_HALF = 43;
  uint8 constant SECOND_HALF = 44;
  uint8 constant ODDS = 45;
  uint8 constant EVENS = 46;
  uint8 constant REDS = 47;
  uint8 constant BLACKS = 48;


  constructor() public {
    owner = msg.sender;
  }

  // First step of the uesr interaction with the contract. Placing a bet is done here.
  function placeBets(uint8[MAX_BETTING_AT_ONCE] positions,
                    uint16[MAX_BETTING_AT_ONCE] values,
                    uint8 length) public payable {
      require(0 == betsPerUser[msg.sender].placementTime);
      require(length <= MAX_BETTING_AT_ONCE);

      uint16 sumValues = 0;
      for(uint8 index = 0; index < length; ++index) {
        require(positions[index] <= NUM_BETTING_POSITIONS);
        require(values[index] <= MAX_BET_FINNEY);
        sumValues += values[index];
      }
      // Make sure that the sum of the bets equals what has been paid to the method
      require(msg.value == FINNEY_TO_WEI * sumValues);
      require(sumValues <= MAX_BETTING_VALUE_SUM);

      betsPerUser[msg.sender].positions = positions;
      betsPerUser[msg.sender].values = values;
      betsPerUser[msg.sender].placementTime = block.number;
      betsPerUser[msg.sender].betsLength = length;
  }

  // Option to clear a bet without claiming it. Will use less gas if you know that you are not winning.
  // Currently not exposed through the Web frontend.
  function clearBets() public {
    betsPerUser[msg.sender].placementTime = 0;
    betsPerUser[msg.sender].betsLength = 0;
  }

  // Return 0 if the user has not active bet currenly - meaning a bet can be made.
  // If the user does have an active bet will return the block height when the bet was made
  function hasActiveBet() public view returns (uint) {
    return betsPerUser[msg.sender].placementTime;
  }

  // Second step of the user interaction with the contract. Claiming a bet.
  function claimBets() public {
    uint placementTime = betsPerUser[msg.sender].placementTime;
    require(placementTime > 0 && placementTime <= block.number - 2);

    /* Make sure the hash is still visible
     *
     * "You can only access the hashes of the most recent 256 blocks, all other values will be zero."
     */
    uint blockHashRandomness = uint(blockhash(placementTime + 2));
    require(blockHashRandomness > 0);

    uint8 chosenNumber = uint8( blockHashRandomness % 37);

    uint profitFinney = 0;
    for(uint8 index = 0; index < betsPerUser[msg.sender].betsLength; ++index) {
      uint8 curBetPosition = betsPerUser[msg.sender].positions[index];
      uint16 curBetValue = betsPerUser[msg.sender].values[index];
      if(curBetPosition <= 36) {
        if(curBetPosition == chosenNumber) {
          // Win on exact number
          profitFinney += 36 * curBetValue;
        }
      } else {
        // The current bet is not a number, check group bets
        if (( FIRST_COLLUMN == curBetPosition && 1 == (chosenNumber % 3)) ||
            ( SECOND_COLLUMN == curBetPosition && 2 == (chosenNumber % 3)) ||
            ( THIRD_COLLUMN == curBetPosition && 0 == (chosenNumber % 3)) ||
            ( FIRST_THIRD == curBetPosition && (chosenNumber >= 1 && chosenNumber <= 12)) ||
            ( MIDDLE_THIRD == curBetPosition && (chosenNumber >= 13 && chosenNumber <= 24)) ||
            ( LAST_THIRD == curBetPosition && (chosenNumber >= 25 && chosenNumber <= 36)))
        {
            profitFinney += 3 * curBetValue;
        }
        else if (( FIRST_HALF == curBetPosition && (chosenNumber >= 0 && chosenNumber <= 18)) ||
                 ( SECOND_HALF == curBetPosition && (chosenNumber >= 19 && chosenNumber <= 36)) ||
                 ( ODDS == curBetPosition && (chosenNumber % 2 == 1 )) ||
                 ( EVENS == curBetPosition && (chosenNumber % 2 == 0 )) ||
                 ( REDS == curBetPosition && isNumRed(chosenNumber)) ||
                 ( BLACKS == curBetPosition && isNumBlack(chosenNumber)))
        {
            profitFinney += 2 * curBetValue;
        }
      }


    }
    if(profitFinney > 0) {
      msg.sender.transfer(profitFinney * FINNEY_TO_WEI);
    }

    clearBets();
    emit claimWin(msg.sender, chosenNumber, profitFinney);
    emit balanceUpdated(address(this).balance);
  }

  // Events currently not used in the frontend due to limitations of the web3 provider
  event claimWin(address from, uint8 number, uint value);
  event balanceUpdated(uint newBalance);

  function deposit() public payable {
    emit balanceUpdated(address(this).balance);
  }

  function checkBalance() public view returns (uint) {
    return address(this).balance;
  }

  function isNumRed(uint8 num) private pure returns (bool){
    if( 1 == num  || 3 == num || 5 == num || 7 == num || 9 == num ||
      12 == num || 14 == num || 16 == num || 18 == num || 19 == num ||
      21 == num || 23 == num || 25 == num || 27 == num || 30 == num ||
      32 == num || 34 == num || 36 == num) {
        return true;
      }
  }

  function isNumBlack(uint8 num) private pure returns (bool){
    if( 2 == num  || 4 == num || 6 == num || 8 == num || 10 == num ||
      11 == num || 13 == num || 15 == num || 17 == num || 20 == num ||
      22 == num || 24 == num || 26 == num || 28 == num || 29 == num ||
      31 == num || 33 == num || 35 == num) {
        return true;
      }
  }
}