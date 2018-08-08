/**
 * The Edgeless blackjack contract only allows calls from the authorized casino proxy contracts. 
 * The proxy contract only forward moves if called by an authorized wallet owned by the Edgeless casino, but the game
 * data has to be signed by the player to show his approval. This way, Edgeless can provide a fluid game experience
 * without having to wait for transaction confirmations.
 * author: Julia Altenried
 **/

pragma solidity ^ 0.4 .17;

contract owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function owned() public {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}

contract mortal is owned {
  function close() onlyOwner public {
    selfdestruct(owner);
  }
}

contract casino is mortal {
  /** the minimum bet**/
  uint public minimumBet;
  /** the maximum bet **/
  uint public maximumBet;
  /** tells if an address is authorized to call game functions **/
  mapping(address => bool) public authorized;

  /** notify listeners that an error occurred**/
  event Error(uint8 errorCode);

  /** 
   * constructur. initialize the contract with initial values. 
   * @param minBet         the minimum bet
   *        maxBet         the maximum bet
   **/
  function casino(uint minBet, uint maxBet) public {
    minimumBet = minBet;
    maximumBet = maxBet;
  }

  /** 
   * allows the owner to change the minimum bet
   * @param newMin the new minimum bet
   **/
  function setMinimumBet(uint newMin) onlyOwner public {
    minimumBet = newMin;
  }

  /** 
   * allows the owner to change the maximum bet
   * @param newMax the new maximum bet
   **/
  function setMaximumBet(uint newMax) onlyOwner public {
    maximumBet = newMax;
  }


  /**
   * authorize a address to call game functions.
   * @param addr the address to be authorized
   **/
  function authorize(address addr) onlyOwner public {
    authorized[addr] = true;
  }

  /**
   * deauthorize a address to call game functions.
   * @param addr the address to be deauthorized
   **/
  function deauthorize(address addr) onlyOwner public {
    authorized[addr] = false;
  }


  /**
   * checks if an address is authorized to call game functionality
   **/
  modifier onlyAuthorized {
    require(authorized[msg.sender]);
    _;
  }
}

contract blackjack is casino {
  struct Game {
    /** the hash of the (partial) deck **/
    bytes32 deck;
    /** the hash of the casino seed used for randomness generation and deck-hashing, also serves as id**/
    bytes32 seedHash;
    /** the player address **/
    address player;
    /** the bet **/
    uint bet;
  }

  /** the value of the cards: Ace, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K . Ace can be 1 or 11, of course. 
   *   the value of a card can be determined by looking up cardValues[cardId%13]**/
  uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];

  /** use the game id to reference the games **/
  mapping(bytes32 => Game) games;
  /** list of splits per game - length 0 in most cases **/
  mapping(bytes32 => uint8[]) splits;
  /** tells if a hand of a given game has been doubled **/
  mapping(bytes32 => mapping(uint8 => bool)) doubled;
  /** tells if the player already claimed his win **/
  mapping(bytes32 => bool) over;

  /** notify listeners that a new round of blackjack started **/
  event NewGame(bytes32 indexed id, bytes32 deck, bytes32 srvSeed, bytes32 cSeed, address player, uint bet);
  /** notify listeners of the game outcome **/
  event Result(bytes32 indexed id, address player, uint win);
  /** notify listeners that the player doubled **/
  event Double(bytes32 indexed id, uint8 hand);
  /** notify listeners that the player split **/
  event Split(bytes32 indexed id, uint8 hand);

  /** 
   * constructur. initialize the contract with a minimum bet and a signer address. 
   * @param minBet         the minimum bet
   *        maxBet         the maximum bet
   *        bankroll       the lower bound for profit sharing
   *        lotteryAddress the address of the lottery contract
   *        profitAddress  the address to send 60% of the profit to on payday
   **/
  function blackjack(uint minBet, uint maxBet) casino(minBet, maxBet) public {

  }

  /** 
   *   initializes a round of blackjack with an id, the hash of the (partial) deck and the hash of the server seed. 
   *   accepts the bet.
   *   throws an exception if the bet is too low or a game with the given id already exists.
   *   @param player  the address of the player
   *          value   the value of the bet in tokens
   *          deck    the hash of the deck
   *          srvSeed the hash of the server seed
   *          cSeed   the plain client seed
   **/
  function initGame(address player, uint value, bytes32 deck, bytes32 srvSeed, bytes32 cSeed) onlyAuthorized public {
    //throw if game with id already exists. later maybe throw only if game with id is still running
    assert(value >= minimumBet && value <= maximumBet);
    assert(!gameExists(srvSeed));
    games[srvSeed] = Game(deck, srvSeed, player, value);
    NewGame(srvSeed, deck, srvSeed, cSeed, player, value);
  }

  /**
   *   doubles the bet of the game with the given id if the correct amount is sent and the player did not double the hand yet.
   *   @param id    the game id
   *          hand  the index of the hand being doubled
   *          value the number of tokens sent by the player
   **/
  function double(bytes32 id, uint8 hand, uint value) onlyAuthorized public {
    Game storage game = games[id];
    require(value == game.bet);
    require(hand <= splits[id].length && !doubled[id][hand]);
    doubled[id][hand] = true;
    Double(id, hand);
  }

  /**
   *   splits the hands of the game with the given id if the correct amount is sent from the player address and the player
   *   did not split yet.
   *   @param id    the game id
   *          hand  the index of the hand being split
   *          value the number of tokens sent by the player
   **/
  function split(bytes32 id, uint8 hand, uint value) onlyAuthorized public {
    Game storage game = games[id];
    require(value == game.bet);
    require(splits[id].length < 3);
    splits[id].push(hand);
    Split(id, hand);
  }


  /**
   * by surrendering half the bet is returned to the player.
   * send the plain server seed to check if it&#39;s correct
   * @param seed the server seed
   **/
  function surrender(bytes32 seed) onlyAuthorized public {
    var id = keccak256(seed);
    Game storage game = games[id];
    require(id == game.seedHash);
    require(!over[id]);
    over[id] = true;
    assert(msg.sender.call(bytes4(keccak256("shift(address,uint256)")), game.player, game.bet / 2));
    Result(id, game.player, game.bet / 2);
  }

  /** 
   * first checks if deck and the player&#39;s number of cards are correct, then checks if the player won and if so, sends the win.
   * @param deck      the partial deck
   *        seed      the plain server seed
   *        numCards  the number of cards per hand
   **/
  function stand(uint8[] deck, bytes32 seed, uint8[] numCards) onlyAuthorized public {
    var gameId = keccak256(seed); //if seed is incorrect the first condition will already fail
    Game storage game = games[gameId];
    assert(!over[gameId]);
    assert(checkDeck(gameId, deck, seed));
    assert(splits[gameId].length == numCards.length - 1);
    over[gameId] = true;
    uint win = determineOutcome(gameId, deck, numCards);
    if (win > 0) assert(msg.sender.call(bytes4(keccak256("shift(address,uint256)")), game.player, win));
    Result(gameId, game.player, win);
  }

  /**
   * checks if a game with the given id already exists
   * @param id the game id
   **/
  function gameExists(bytes32 id) constant public returns(bool success) {
    if (games[id].player != 0x0) return true;
    return false;
  }

  /**
   * check if deck and casino seed are correct.
   * @param gameId the game id
   *        deck   the partial deck
   *        seed   the server seed
   * @return true if correct
   **/
  function checkDeck(bytes32 gameId, uint8[] deck, bytes32 seed) constant public returns(bool correct) {
    if (keccak256(convertToBytes(deck), seed) != games[gameId].deck) return false;
    return true;
  }

  /**
   * converts an uint8 array to bytes
   * @param byteArray the uint8 array to be converted
   * @return the bytes
   **/
  function convertToBytes(uint8[] byteArray) internal constant returns(bytes b) {
    b = new bytes(byteArray.length);
    for (uint8 i = 0; i < byteArray.length; i++)
      b[i] = byte(byteArray[i]);
  }

  /**
   * determines the outcome of a game and returns the win. 
   * in case of a loss, win is 0.
   * @param gameId    the id of the game
   *        cards     the cards / partial deck
   *        numCards  the number of cards per hand
   * @return the total win of all hands
   **/
  function determineOutcome(bytes32 gameId, uint8[] cards, uint8[] numCards) constant public returns(uint totalWin) {
    Game storage game = games[gameId];
    var playerValues = getPlayerValues(cards, numCards, splits[gameId]);
    var (dealerValue, dealerBJ) = getDealerValue(cards, sum(numCards));
    uint win;
    for (uint8 h = 0; h < numCards.length; h++) {
      uint8 playerValue = playerValues[h];
      //bust if value > 21
      if (playerValue > 21) win = 0;
      //player blackjack but no dealer blackjack
      else if (numCards.length == 1 && playerValue == 21 && numCards[h] == 2 && !dealerBJ) {
        win = game.bet * 5 / 2; //pay 3 to 2
      }
      //player wins regularly
      else if (playerValue > dealerValue || dealerValue > 21)
        win = game.bet * 2;
      //tie
      else if (playerValue == dealerValue)
        win = game.bet;
      //player looses
      else
        win = 0;

      if (doubled[gameId][h]) win *= 2;
      totalWin += win;
    }
  }

  /**
   *   calculates the value of the player&#39;s hands.
   *   @param cards     holds the (partial) deck.
   *          numCards  the number of cards per player hand
   *          pSplits   the player&#39;s splits (hand index)
   *   @return the values of the player&#39;s hands
   **/
  function getPlayerValues(uint8[] cards, uint8[] numCards, uint8[] pSplits) constant internal returns(uint8[5] playerValues) {
    uint8 cardIndex;
    uint8 splitIndex;
    (cardIndex, splitIndex, playerValues) = playHand(0, 0, 0, playerValues, cards, numCards, pSplits);
  }

  /**
   *   recursively plays the player&#39;s hands.
   *   @param hIndex        the hand index
   *          cIndex        the index of the next card to draw
   *          sIndex        the index of the next split, if there is any
   *          playerValues  the values of the player&#39;s hands (not yet complete)
   *          cards         holds the (partial) deck.
   *          numCards      the number of cards per player hand
   *          pSplits        the array of splits
   *   @return the values of the player&#39;s hands and the current card index
   **/
  function playHand(uint8 hIndex, uint8 cIndex, uint8 sIndex, uint8[5] playerValues, uint8[] cards, uint8[] numCards, uint8[] pSplits) constant internal returns(uint8, uint8, uint8[5]) {
    playerValues[hIndex] = cardValues[cards[cIndex] % 13];
    cIndex = cIndex < 4 ? cIndex + 2 : cIndex + 1;
    while (sIndex < pSplits.length && pSplits[sIndex] == hIndex) {
      sIndex++;
      (cIndex, sIndex, playerValues) = playHand(sIndex, cIndex, sIndex, playerValues, cards, numCards, pSplits);
    }
    uint8 numAces = playerValues[hIndex] == 11 ? 1 : 0;
    uint8 card;
    for (uint8 i = 1; i < numCards[hIndex]; i++) {
      card = cards[cIndex] % 13;
      playerValues[hIndex] += cardValues[card];
      if (card == 0) numAces++;
      cIndex = cIndex < 4 ? cIndex + 2 : cIndex + 1;
    }
    while (numAces > 0 && playerValues[hIndex] > 21) {
      playerValues[hIndex] -= 10;
      numAces--;
    }
    return (cIndex, sIndex, playerValues);
  }



  /**
   *   calculates the value of a dealer&#39;s hand.
   *   @param cards     holds the (partial) deck.
   *          numCards  the number of cards the player holds
   *   @return the value of the dealer&#39;s hand and a flag indicating if the dealer has got a blackjack
   **/
  function getDealerValue(uint8[] cards, uint8 numCards) constant internal returns(uint8 dealerValue, bool bj) {

    //dealer always receives second and forth card
    uint8 card = cards[1] % 13;
    uint8 card2 = cards[3] % 13;
    dealerValue = cardValues[card] + cardValues[card2];
    uint8 numAces;
    if (card == 0) numAces++;
    if (card2 == 0) numAces++;
    if (dealerValue > 21) { //2 aces,count as 12
      dealerValue -= 10;
      numAces--;
    } else if (dealerValue == 21) {
      return (21, true);
    }
    //take cards until value reaches 17 or more. 
    uint8 i;
    while (dealerValue < 17) {
      card = cards[numCards + i + 2] % 13;
      dealerValue += cardValues[card];
      if (card == 0) numAces++;
      if (dealerValue > 21 && numAces > 0) {
        dealerValue -= 10;
        numAces--;
      }
      i++;
    }
  }

  /**
   * sums up the given numbers
   * note:  player will always hold less than 100 cards
   * @param numbers   the numbers to sum up
   * @return the sum of the numbers
   **/
  function sum(uint8[] numbers) constant internal returns(uint8 s) {
    for (uint i = 0; i < numbers.length; i++) {
      s += numbers[i];
    }
  }

}