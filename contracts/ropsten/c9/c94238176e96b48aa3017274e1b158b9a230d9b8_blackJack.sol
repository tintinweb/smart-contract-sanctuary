pragma solidity ^0.4.19;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract blackJack is Ownable {

    uint minBet = 0.001 ether;
    uint maxBet = 0.1 ether;
    uint requiredHouseBankroll = 5 ether; //use math of maxBet * 500
    uint autoWithdrawBuffer = 1 ether; // only automatically withdraw if requiredHouseBankroll is exceeded by this amount


    mapping (address => bool) public isActive;
    mapping (address => bool) public isPlayerActive;
    mapping (address => uint) public betAmount;
    mapping (address => uint) public gamestatus; //1 = Player Turn, 2 = Player Blackjack!, 3 = Dealer Blackjack!, 4 = Push, 5 = Game Finished. Bets resolved.
    mapping (address => uint) public payoutAmount;
    mapping (address => uint) dealTime;
    mapping (address => uint) blackJackHouseProhibited;
    mapping (address => uint[]) playerCards;
    mapping (address => uint[]) houseCards;


    mapping (address => bool) playerExists; //check whether the player has played before, if so, he must have a playerHand

    //TODO: later implement event notifiers so hand histories can be displayed and looked up

    //PRNG / RANDOM NUMBER GENERATION. REPLACE THIS AS NEEDED WITH MORE EFFICIENT RNG

    uint randNonce = 0;
    function randgenNewHand() internal returns(uint,uint,uint) { //returns 3 numbers from 0-51.
        //If new hand, generate 3 cards. If not, generate just 1.
        randNonce++;
        uint a = uint(keccak256(now, msg.sender, randNonce)) % 52;
        randNonce++;
        uint b = uint(keccak256(now, msg.sender, randNonce)) % 52;
        randNonce++;
        uint c = uint(keccak256(now, msg.sender, randNonce)) % 52;
        return (a,b,c);
      }

    function randgen() internal returns(uint) { //returns number from 0-51.
        //If new hand, generate 3 cards. If not, generate just 1.
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % 52; //range: 0-51
      }

    modifier requireHandActive(bool truth) {
        require(isActive[msg.sender] == truth);
        _;
    }

    modifier requirePlayerActive(bool truth) {
        require(isPlayerActive[msg.sender] == truth);
        _;
    }

    function _play() public payable { //TEMP: Care, public.. ensure this is the public point of entry to play. Only allow 1 point of entry.
        //check whether or not player has played before
        if (playerExists[msg.sender]) {
            require(isActive[msg.sender] == false);
        }
        else {
            playerExists[msg.sender] = true;
        }
        require(msg.value >= minBet); //now check player has sent ether within betting requirements
        require(msg.value <= maxBet); //TODO Do unit testing to ensure ETH is not deducted if previous conditional fails
        //Now all checks have passed, the betting can proceed
        uint a; //generate 3 cards, 2 for player, 1 for the house
        uint b;
        uint c;
        (a,b,c) = randgenNewHand();
        gamestatus[msg.sender] = 1;
        payoutAmount[msg.sender] = 0;
        isActive[msg.sender] = true;
        isPlayerActive[msg.sender] = true;
        betAmount[msg.sender] = msg.value;
        dealTime[msg.sender] = now;
        playerCards[msg.sender] = new uint[](0);
        playerCards[msg.sender].push(a);
        playerCards[msg.sender].push(b);
        houseCards[msg.sender] = new uint[](0);
        houseCards[msg.sender].push(c);
        isBlackjack();
        //checkGameState(); I think this can be removed here, test it without
        withdrawToOwnerCheck();
        //TODO UPDATE playerHand correctly and also commence play utilizing game logic
        //PLACEHOLDER FOR THE GAMBLING, DELEGATE TO OTHER FUNCTIONS SOME OF THE GAME LOGIC HERE
        //END PLACEHOLDER, REMOVE THESE COMMENTS
    }

    function _Hit() public requireHandActive(true) requirePlayerActive(true) { //both the hand and player turn must be active in order to hit
        uint a=randgen(); //generate a new card
        playerCards[msg.sender].push(a);
        checkGameState();
    }

    function _Stand() public requireHandActive(true) requirePlayerActive(true) { //both the hand and player turn must be active in order to stand
        isPlayerActive[msg.sender] = false; //Player ends their turn, now dealer&#39;s turn
        checkGameState();
    }

    function checkGameState() internal requireHandActive(true) { //checks game state, processing it as needed. Should be called after any card is dealt or action is made (eg: stand).
        //IMPORTANT: Make sure this function is NOT called in the event of a blackjack. Blackjack should calculate things separately
        if (isPlayerActive[msg.sender] == true) {
            uint handPower = card2PowerConverter(playerCards[msg.sender]);
            if (handPower > 21) { //player busted
                processHandEnd(false);
            }
            else if (handPower == 21) { //autostand. Ensure same logic in stand is used
                isPlayerActive[msg.sender] = false;
                dealerHit();
            }
            else if (handPower <21) {
                //do nothing, player is allowed another action
            }
        }
        else if (isPlayerActive[msg.sender] == false) {
            dealerHit();
        }

    }

    function dealerHit() internal requireHandActive(true) requirePlayerActive(false)  { //dealer hits after player ends turn legally. Nounces can be incrimented with hits until turn finished.
        uint[] storage houseCardstemp = houseCards[msg.sender];
        uint[] storage playerCardstemp = playerCards[msg.sender];

        uint tempCard;
        while (card2PowerConverter(houseCardstemp) < 17) { //keep hitting on the same block for everything under 17. Same block is fine for dealer due to Nounce increase
            //The house cannot cheat here since the player is forcing the NEXT BLOCK to be the source of randomness for all hits, and this contract cannot voluntarily skip blocks.
            tempCard = randgen();
            if (blackJackHouseProhibited[msg.sender] != 0) {
                while (card2PowerConverterSingle(tempCard) == blackJackHouseProhibited[msg.sender]) { //don&#39;t deal the first card as prohibited card
                    tempCard = randgen();
                }
                blackJackHouseProhibited[msg.sender] = 0;
                }
            houseCardstemp.push(tempCard);
        }
        //First, check if the dealer busted for an auto player win
        if (card2PowerConverter(houseCardstemp) > 21 ) {
            processHandEnd(true);
        }
        //If not, we do win logic here, since this is the natural place to do it (after dealer hitting). 3 Scenarios are possible... =>
        if (card2PowerConverter(playerCardstemp) == card2PowerConverter(houseCardstemp)) {
            //push, return bet
            msg.sender.transfer(betAmount[msg.sender]);
            payoutAmount[msg.sender]=betAmount[msg.sender];
            gamestatus[msg.sender] = 4;
            isActive[msg.sender] = false; //let&#39;s declare this manually only here, since processHandEnd is not called. Not needed for other scenarios.
        }
        else if (card2PowerConverter(playerCardstemp) > card2PowerConverter(houseCardstemp)) {
            //player hand has more strength
            processHandEnd(true);
        }
        else {
            //only one possible scenario remains.. dealer hand has more strength
            processHandEnd(false);
        }
    }

    function processHandEnd(bool _win) internal { //hand is over and win is either true or false, now process it
        if (_win == false) {
            //do nothing, as player simply lost
        }
        else if (_win == true) {
            uint winAmount = betAmount[msg.sender] * 2;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender]=winAmount;
        }
        gamestatus[msg.sender] = 5;
        isActive[msg.sender] = false;
    }

    function card2PowerConverter(uint[] cards) internal pure returns (uint) { //converts an array of cards to their actual power. 1 is 1 or 11 (Ace)
        uint powerMax = 0;
        uint aces = 0; //count number of aces
        for (uint i=0; i<cards.length; i++) {
            if (cards[i] == 0 || cards[i] == 13 || cards[i] == 26 || cards[i] == 39) { // card is an Ace
                powerMax+=11;
                aces += 1;
            }
            else if (cards[i] == 1 || cards[i] == 14 || cards[i] == 27 || cards[i] == 40) { // card is a 2
                powerMax+=2;
            }
            else if (cards[i] == 2 || cards[i] == 15 || cards[i] == 28 || cards[i] == 41) { // card is a 3
                powerMax+=3;
            }
            else if (cards[i] == 3 || cards[i] == 16 || cards[i] == 29 || cards[i] == 42) { // card is a 4
                powerMax+=4;
            }
            else if (cards[i] == 4 || cards[i] == 17 || cards[i] == 30 || cards[i] == 43) { // card is a 5
                powerMax+=5;
            }
            else if (cards[i] == 5 || cards[i] == 18 || cards[i] == 31 || cards[i] == 44) { // card is a 6
                powerMax+=6;
            }
            else if (cards[i] == 6 || cards[i] == 19 || cards[i] == 32 || cards[i] == 45) { // card is a 7
                powerMax+=7;
            }
            else if (cards[i] == 7 || cards[i] == 20 || cards[i] == 33 || cards[i] == 46) { // card is a 8
                powerMax+=8;
            }
            else if (cards[i] == 8 || cards[i] == 21 || cards[i] == 34 || cards[i] == 47) { // card is a 9
                powerMax+=9;
            }
            else if (cards[i] == 9 || cards[i] == 22 || cards[i] == 35 || cards[i] == 48) { // card is a 10
                powerMax+=10;
            }
            else if (cards[i] == 10 || cards[i] == 23 || cards[i] == 36 || cards[i] == 49) { // card is a J
                powerMax+=10;
            }
            else if (cards[i] == 11 || cards[i] == 24 || cards[i] == 37 || cards[i] == 50) { // card is a Q
                powerMax+=10;
            }
            else if (cards[i] == 12 || cards[i] == 25 || cards[i] == 38 || cards[i] == 51) { // card is a K
                powerMax+=10;
            }
        }
        if (powerMax > 21) { //remove 10 for each ace until under 21, if possible.
            for (uint i2=0; i2<aces; i2++) {
                powerMax-=10;
                if (powerMax <= 21) {
                    break;
                }
            }
        }
        return uint(powerMax);
    }

    function card2PowerConverterSingle(uint cards) internal pure returns (uint) { //converts an array of cards to their actual power. 1 is 1 or 11 (Ace)
        uint powerMax = 0;
            for (uint i=0; i<1; i++) {
                if (cards == 0 || cards == 13 || cards == 26 || cards == 39) { // card is an Ace
                    powerMax+=11;
                }
                else if (cards == 1 || cards == 14 || cards == 27 || cards == 40) { // card is a 2
                    powerMax+=2;
                }
                else if (cards == 2 || cards == 15 || cards == 28 || cards == 41) { // card is a 3
                    powerMax+=3;
                }
                else if (cards == 3 || cards == 16 || cards == 29 || cards == 42) { // card is a 4
                    powerMax+=4;
                }
                else if (cards == 4 || cards == 17 || cards == 30 || cards == 43) { // card is a 5
                    powerMax+=5;
                }
                else if (cards == 5 || cards == 18 || cards == 31 || cards == 44) { // card is a 6
                    powerMax+=6;
                }
                else if (cards == 6 || cards == 19 || cards == 32 || cards == 45) { // card is a 7
                    powerMax+=7;
                }
                else if (cards == 7 || cards == 20 || cards == 33 || cards == 46) { // card is a 8
                    powerMax+=8;
                }
                else if (cards == 8 || cards == 21 || cards == 34 || cards == 47) { // card is a 9
                    powerMax+=9;
                }
                else if (cards == 9 || cards == 22 || cards == 35 || cards == 48) { // card is a 10
                    powerMax+=10;
                }
                else if (cards == 10 || cards == 23 || cards == 36 || cards == 49) { // card is a J
                    powerMax+=10;
                }
                else if (cards == 11 || cards == 24 || cards == 37 || cards == 50) { // card is a Q
                    powerMax+=10;
                }
                else if (cards == 12 || cards == 25 || cards == 38 || cards == 51) { // card is a K
                    powerMax+=10;
                }
            }
        return uint(powerMax);
    }

    //TODO: Log an event after hand, showing outcome

    function isBlackjack() internal { //fill this function later to check both player and dealer for a blackjack after _play is called, then process
        //4 possibilities: dealer blackjack, player blackjack (paying 3:2), both blackjack (push), no blackjack
        //copy processHandEnd for remainder
        blackJackHouseProhibited[msg.sender]=0; //set to 0 incase it already has a value
        bool houseIsBlackjack = false;
        bool playerIsBlackjack = false;
        //First thing: For dealer check, ensure if dealer doesn&#39;t get blackjack they are prohibited from their first hit resulting in a blackjack
        uint housePower = card2PowerConverter(houseCards[msg.sender]); //read the 1 and only house card, if it&#39;s 11 or 10, then deal temporary new card for bj check
        if (housePower == 10 || housePower == 11) {
            uint _card = randgen();
            if (housePower == 10) {
                if (_card == 0 || _card == 13 || _card == 26 || _card == 39) {
                    //dealer has blackjack, process
                    houseCards[msg.sender].push(_card); //push card as record, since game is now over
                    houseIsBlackjack = true;
                }
                else {
                    blackJackHouseProhibited[msg.sender]=uint(11); //ensure dealerHit doesn&#39;t draw this powerMax
                }
            }
            else if (housePower == 11) {
                if (_card == 9 || _card == 10 || _card == 11 || _card == 12 || _card == 22 || _card == 23 || _card == 24 || _card == 25
                        || _card == 35 || _card == 36 || _card == 37 || _card == 38 || _card == 48 || _card == 49 || _card == 50 || _card == 51) { //all 10s
                    //dealer has blackjack, process
                    houseCards[msg.sender].push(_card);  //push card as record, since game is now over
                    houseIsBlackjack = true;
                }
                else{
                    blackJackHouseProhibited[msg.sender]=uint(10); //ensure dealerHit doesn&#39;t draw this powerMax
                }

            }
        }
        //Second thing: Check if player has blackjack
        uint playerPower = card2PowerConverter(playerCards[msg.sender]);
        if (playerPower == 21) {
            playerIsBlackjack = true;
        }
        //Third thing: Return all four possible outcomes: Win 1.5x, Push, Loss, or Nothing (no blackjack, continue game)
        if (playerIsBlackjack == false && houseIsBlackjack == false) {
            //do nothing. Call this first since it&#39;s the most likely outcome
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == false) {
            //Player has blackjack, dealer doesn&#39;t, reward 1.5x bet (plus bet return)
            uint winAmount = betAmount[msg.sender] * 5/2;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender] = betAmount[msg.sender] * 5/2;
            gamestatus[msg.sender] = 2;
            isActive[msg.sender] = false;
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == true) {
            //Both player and dealer have blackjack. Push - return bet only
            uint winAmountPush = betAmount[msg.sender];
            msg.sender.transfer(winAmountPush);
            payoutAmount[msg.sender] = winAmountPush;
            gamestatus[msg.sender] = 4;
            isActive[msg.sender] = false;
        }
        else if (playerIsBlackjack == false && houseIsBlackjack == true) {
            //Only dealer has blackjack, player loses
            gamestatus[msg.sender] = 3;
            isActive[msg.sender] = false;
        }
    }

    function readCards() external view returns(uint[],uint[]) { //returns the cards in play, as an array of playercards, then houseCards
        return (playerCards[msg.sender],houseCards[msg.sender]);
    }

    function readPower() external view returns(uint, uint) { //returns current card power of player and house
        return (card2PowerConverter(playerCards[msg.sender]),card2PowerConverter(houseCards[msg.sender]));
    }

    function donateEther() public payable {
        //do nothing
    }

    function withdrawToOwnerCheck() internal { //auto call this
        //Contract profit withdrawal to the current contract owner is disabled unless contract balance exceeds requiredHouseBankroll
        //If this condition is  met, requiredHouseBankroll must still always remain in the contract and cannot be withdrawn.
        uint houseBalance = address(this).balance;
        if (houseBalance > requiredHouseBankroll + autoWithdrawBuffer) { //see comments at top of contract
            uint permittedWithdraw = houseBalance - requiredHouseBankroll; //leave the required bankroll behind, withdraw the rest
            owner.transfer(permittedWithdraw);
        }
    }
}