pragma solidity ^0.4.25;

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }


  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function withdrawAllEther() public onlyOwner { //to be executed on contract close
    _owner.transfer(this.balance);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract blackJack is Ownable {
    mapping (uint => uint) cardsPower;
    uint public minBet = 0.01 ether;
    uint public maxBet = 0.1 ether;
    uint requiredHouseBankroll = 3 ether; //use math of maxBet * 300
    uint autoWithdrawBuffer = 1 ether; // only automatically withdraw if requiredHouseBankroll is exceeded by this amount
    mapping (address => bool) public isActive;
    mapping (address => bool) public isPlayerActive;
    mapping (address => bool) public insuranceOption; //is the game paused to offer insurance?
    mapping (address => bool) public insurancePurchased; //did the player purchase insurance?
    mapping (address => bool) public splitPossible;
    mapping (address => bool) public isSplit; //is the player currently split into two hands?
    mapping (address => bool) public isSplitActive; //is the 2nd hand of the player the active one?
    mapping (address => uint) public betAmount;
    mapping (address => uint) public gamestatus; //1 = Player Turn, 2 = Player Blackjack!, 3 = Dealer Blackjack!, 4 = Push, 5 = Game Finished. Bets resolved. 6= Successful insurance, 7=insured blackjack
    mapping (address => uint) public payoutAmount;
    mapping (address => uint) dealTime;
    mapping (address => uint) blackJackHouseProhibited;
    mapping (address => uint[]) playerCards;
    mapping (address => uint[]) playerCards2; //second hand for splitting
    mapping (address => uint[]) houseCards;
    mapping (address => bool) public playerExists; //check whether the player has played before, if so, he must have a playerHand

    event blackjackEvent(bool indexed playerBlackjack, bool indexed dealerBlackjack);
    event logHand(address indexed playerAddress, uint[] playerHand, uint[] dealerHand, uint playerBet, bool playerSplit);

    function eventLogHand() internal {
        emit logHand(msg.sender, playerCards[msg.sender], houseCards[msg.sender], betAmount[msg.sender], isSplit[msg.sender]);
    }

    constructor() {
    cardsPower[0] = 11; // aces
    cardsPower[1] = 2;
    cardsPower[2] = 3;
    cardsPower[3] = 4;
    cardsPower[4] = 5;
    cardsPower[5] = 6;
    cardsPower[6] = 7;
    cardsPower[7] = 8;
    cardsPower[8] = 9;
    cardsPower[9] = 10;
    cardsPower[10] = 10; // j
    cardsPower[11] = 10; // q
    cardsPower[12] = 10; // k
    }

    function contractbalance() public view returns (uint) {
        return uint(address(this).balance);
    }


    //TODO LOG EVENTS OF CARDS FOR STATISTICAL ANALYSIS. LOG EVENTS OF BLACKJACKS (player vs dealer)
    //Keep track of starting hand power (both hard and soft) and both count and % won, keep track of dealer face card and % won
    //Keep track of player >21 (with no split)



    function card2PowerConverter(uint[] cards) internal view returns (uint) { //converts an array of cards to their actual power. 1 is 1 or 11 (Ace)
        uint powerMax = 0;
        uint aces = 0; //count number of aces
        uint power;
        for (uint i = 0; i < cards.length; i++) {
             power = cardsPower[(cards[i] + 13) % 13];
             powerMax += power;
             if (power == 11) {
                 aces += 1;
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


    //PRNG / RANDOM NUMBER GENERATION. REPLACE THIS AS NEEDED WITH MORE EFFICIENT RNG

    uint randNonce = 0;
    function randgenNewHand() internal returns(uint,uint,uint) { //returns 3 numbers from 0-51.
        //If new hand, generate 3 cards. If not, generate just 1.
        randNonce++;
        uint a = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
        randNonce++;
        uint b = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
        randNonce++;
        uint c = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
        return (a,b,c);
      }

    function randgen() internal returns(uint) { //returns number from 0-51.
        //If new hand, generate 3 cards. If not, generate just 1.
        randNonce++;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52; //range: 0-51
      }

    modifier requireHandActive(bool truth) {
        require(isActive[msg.sender] == truth);
        _;
    }

    modifier requirePlayerActive(bool truth) {
        require(isPlayerActive[msg.sender] == truth);
        require(insuranceOption[msg.sender] == false);
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
        require(msg.value <= maxBet);
        //Now all checks have passed, the betting can proceed
        uint a; //generate 3 cards, 2 for player, 1 for the house
        uint b;
        uint c;
        (a,b,c) = randgenNewHand();
        gamestatus[msg.sender] = 1;
        payoutAmount[msg.sender] = 0;
        isActive[msg.sender] = true;
        isPlayerActive[msg.sender] = true;
        isSplit[msg.sender] = false;
        betAmount[msg.sender] = msg.value;
        dealTime[msg.sender] = now;
        playerCards[msg.sender] = new uint[](0);
        playerCards[msg.sender].push(a);
        playerCards[msg.sender].push(b);
        houseCards[msg.sender] = new uint[](0);
        houseCards[msg.sender].push(c);
        if (cardsPower[(a + 13) % 13] == cardsPower[(b + 13) % 13]) { //cards have same value, allow split
            splitPossible[msg.sender] = true;
        }
        else {
            splitPossible[msg.sender] = false;
        }
        if (cardsPower[(c + 13) % 13] == 11) {
            //dealer hole card is an ace, pause game to check if player wishes to purchase insurance
            insuranceOption[msg.sender] = true;
        }
        else {
            isBlackjack();
        }
        withdrawToOwnerCheck();
    }

    function _DeclineInsurance() public requireHandActive(true) {
        require(insuranceOption[msg.sender] == true);
        require(playerCards[msg.sender].length == 2);
        require(isSplit[msg.sender] == false);
        require(card2PowerConverter(houseCards[msg.sender]) == 11);
        insuranceOption[msg.sender] = false;
        insurancePurchased[msg.sender] = false;
        isBlackjack();
    }

    function _PurchaseInsurance() public payable requireHandActive(true) {
        require(insuranceOption[msg.sender] == true);
        require(msg.value == betAmount[msg.sender]/2);
        require(playerCards[msg.sender].length == 2);
        require(isSplit[msg.sender] == false);
        require(card2PowerConverter(houseCards[msg.sender]) == 11);
        insuranceOption[msg.sender] = false;
        insurancePurchased[msg.sender] = true;
        isBlackjack();
    }

    function _Split() public payable requireHandActive(true) requirePlayerActive(true) {
        require(msg.value == betAmount[msg.sender]); //update the msg.value sent to betAmount in the web3 frontend
        require(splitPossible[msg.sender] == true);
        require(isSplit[msg.sender] == false);
        require(playerCards[msg.sender].length == 2);
        isSplit[msg.sender] = true;
        isSplitActive[msg.sender] = false;
        uint card1 = playerCards[msg.sender][0];
        uint card2 = playerCards[msg.sender][1];
        playerCards2[msg.sender] = new uint[](0);
        playerCards2[msg.sender].push(card2);
        playerCards[msg.sender][1] = randgen();
        //now check for 21, or if first card is an ace
        if (cardsPower[(card1 + 13) % 13] == 0 || card2PowerConverter(playerCards[msg.sender]) == 21) { //Aces split or 21 present, autostand
            uint newCard = randgen();
            playerCards2[msg.sender].push(newCard);
            if (cardsPower[(card2 + 13) % 13] == 0 || card2PowerConverter(playerCards2[msg.sender]) == 21) { //hand2 is immediately 21/Ace after hand1 autostand, both hands autostand
                isPlayerActive[msg.sender] = false;
                dealerHit();
            }
            else {
                isSplitActive[msg.sender] = true;
            }
        }
    }

    function _DoubleDown() public payable requireHandActive(true) requirePlayerActive(true) {
        require(msg.value == betAmount[msg.sender]);
        require(playerCards[msg.sender].length == 2);
        require(isSplit[msg.sender] == false);
        uint newCard = randgen();
        playerCards[msg.sender].push(newCard);
        betAmount[msg.sender] += msg.value;
        uint handPower1 = card2PowerConverter(playerCards[msg.sender]);
        if (handPower1 > 21) { //player busted
                    processHandEnd(false);
                }
        else {
            assert(handPower1 < 21); //prevent bug
            isPlayerActive[msg.sender] = false;
            checkGameState();
            }
    }

    function _Hit() public requireHandActive(true) requirePlayerActive(true) { //both the hand and player turn must be active in order to hit
        uint a=randgen();
        if (isSplitActive[msg.sender] == true && isSplit[msg.sender] == true) {
            playerCards2[msg.sender].push(a);
        }
        else {
             //generate a new card
            playerCards[msg.sender].push(a);
        }
        checkGameState();
    }

    function _Stand() public requireHandActive(true) requirePlayerActive(true) { //both the hand and player turn must be active in order to stand
        if (isSplitActive[msg.sender] == false && isSplit[msg.sender] == true) { //player stands on one hand, moves to split hand
            isSplitActive[msg.sender] = true;
            uint a=randgen();
            playerCards2[msg.sender].push(a);
        }
        else {
            isPlayerActive[msg.sender] = false; //Player ends their turn, now dealer&#39;s turn
        }
        checkGameState();
    }

    function checkGameState() internal requireHandActive(true) { //checks game state, processing it as needed. Should be called after any card is dealt or action is made (eg: stand).
        //IMPORTANT: Make sure this function is NOT called in the event of a blackjack. Blackjack should calculate things separately
        if (isPlayerActive[msg.sender] == true) {
            uint handPower1 = card2PowerConverter(playerCards[msg.sender]);
            if (isSplit[msg.sender] == true && isSplitActive[msg.sender] == false) {
                if (handPower1 >= 21) { //hand1 finished, move on to hand2
                    uint firstCardHand2 = playerCards2[msg.sender][0];
                    isSplitActive[msg.sender] = true;
                    uint a=randgen();
                    playerCards2[msg.sender].push(a);
                    if (cardsPower[(firstCardHand2 + 13) % 13] == 0 || card2PowerConverter(playerCards2[msg.sender]) == 21) { //both hands finished
                        isPlayerActive[msg.sender] = false;
                        dealerHit();
                    }
                    else {
                        //player is now transitioned to their 2nd hand
                    }
                }
                else {
                    //do nothing, player continues playing their 1st hand
                }
            }
            else if (isSplit[msg.sender] == true && isSplitActive[msg.sender] == true) {
                uint handPower2 = card2PowerConverter(playerCards2[msg.sender]);
                if (handPower1 > 21 && handPower2 > 21) { //player busted completely in both hands, hard loss
                    processHandEnd(false);
                }
                else if (handPower2 >= 21) { //both checks can be combined here, since hand1 is uncertain
                    isPlayerActive[msg.sender] = false;
                    dealerHit();
                }
                else {
                    //do nothing, player is allowed another action (on hand2)
                }
            }
            else {
                if (handPower1 > 21) { //player busted
                    processHandEnd(false);
                }
                else if (handPower1 == 21) { //autostand. Ensure same logic in stand is used
                    isPlayerActive[msg.sender] = false;
                    dealerHit();
                }
                else if (handPower1 <21) {
                    //do nothing, player is allowed another action
                }
            }
        }
        else if (isPlayerActive[msg.sender] == false) {
            dealerHit();
            }
    }


    function dealerHit() internal requireHandActive(true) requirePlayerActive(false)  { //dealer hits after player ends turn legally. Nounces can be incrimented with hits until turn finished.
        uint[] storage houseCardstemp = houseCards[msg.sender];
        uint[] storage playerCardstemp = playerCards[msg.sender];
        uint[] storage playerCards2temp = playerCards2[msg.sender];

        uint tempCard;
        while (card2PowerConverter(houseCardstemp) < 17) { //keep hitting on the same block for everything under 17. Same block is fine for dealer due to Nounce increase
            //The house cannot cheat here since the player is forcing the NEXT BLOCK to be the source of randomness for all hits, and this contract cannot voluntarily skip blocks.
            tempCard = randgen();
            if (blackJackHouseProhibited[msg.sender] != 0) {
                while (cardsPower[(tempCard + 13) % 13] == blackJackHouseProhibited[msg.sender]) { //don&#39;t deal the first card as prohibited card
                    tempCard = randgen();
                }
                blackJackHouseProhibited[msg.sender] = 0;
                }
            houseCardstemp.push(tempCard);
        }
        //BEGIN GAME LOGIC
        if (isSplit[msg.sender] == true) {
            bool hand1Checked;
            bool hand2Checked;
            bool hand1win;
            bool hand2win;
            //auto loss for busted hands
            if (card2PowerConverter(playerCardstemp) > 21) {
                hand1win = false;
                hand1Checked = true;
            }
            if (card2PowerConverter(playerCards2temp) > 21) {
                hand2win = false;
                hand2Checked = true;
            }
            //no need to check for double bust, this is already done in checkGameState(). This means at least 1 player hand here is not busted
            if (card2PowerConverter(houseCardstemp) > 21 && hand1Checked == false) {
                hand1win = true;
            }
            if (card2PowerConverter(houseCardstemp) > 21 && hand2Checked == false) {
                hand2win = true;
            }
            if (card2PowerConverter(houseCardstemp) > 21) {  //outcome can be decided immediately in this scenario
                if (hand1win && hand2win) {
                    processHandEndSplit(4, 5); //2x wins for 4x bet amount
                }
                else if (hand1win || hand2win) {
                    processHandEndSplit(2, 4); //1 win, 1 loss, breakeven
                }
                else {
                    assert(hand1win || hand2win); //STATE SHOULD NEVER BE REACHED HERE
                    //player double bust loss, this scenario should never be reached however as it&#39;s already handled in checkGameState()
                }
            }
            else if (hand1Checked == false && hand2Checked == false) { //neither hand busted
                if (card2PowerConverter(playerCardstemp) == card2PowerConverter(houseCardstemp)) {
                    if (card2PowerConverter(playerCards2temp) == card2PowerConverter(houseCardstemp)) {
                        //double push (break even)
                        processHandEndSplit(2, 4);
                    }
                    else if (card2PowerConverter(playerCards2temp) > card2PowerConverter(houseCardstemp)) {
                        //1 push, 1 win, for a net result of x3 bet amount
                        processHandEndSplit(3, 5);
                    }
                    else {
                        //1 push, 1 loss, for a net result of 1x bet amount
                        processHandEndSplit(1, 4);
                    }
                }
                else if (card2PowerConverter(playerCardstemp) > card2PowerConverter(houseCardstemp)) {
                    if (card2PowerConverter(playerCards2temp) == card2PowerConverter(houseCardstemp)) {
                        //1 win, 1 push, for a net result of 3x bet amount
                        processHandEndSplit(3, 5);
                    }
                    else if (card2PowerConverter(playerCards2temp) > card2PowerConverter(houseCardstemp)) {
                        //2 wins, for a net result of 4x bet amount
                        processHandEndSplit(4, 5);
                    }
                    else {
                        //1 win, 1 loss, for a net result of 2x bet amount (break event)
                        processHandEndSplit(2, 4);
                    }
                }
                else if (card2PowerConverter(playerCardstemp) < card2PowerConverter(houseCardstemp)) {
                    if (card2PowerConverter(playerCards2temp) == card2PowerConverter(houseCardstemp)) {
                        //1 loss, 1 push for a net result of 1x bet amount
                        processHandEndSplit(1, 4);
                    }
                    else if (card2PowerConverter(playerCards2temp) > card2PowerConverter(houseCardstemp)) {
                        //1 win, 1 loss for a net result of 2x bet amount (break even)
                        processHandEndSplit(2, 4);
                    }
                    else {
                        //2 losses, end immediately
                        processHandEnd(false);
                    }
                }
            }
            else if (hand1Checked == false) {
                if (card2PowerConverter(playerCardstemp) == card2PowerConverter(houseCardstemp)) {
                        //1 loss, 1 push for a net result of 1x bet amount
                        processHandEndSplit(1, 4);
                    }
                else if (card2PowerConverter(playerCardstemp) > card2PowerConverter(houseCardstemp)) {
                    //1 win, 1 loss for a net result of 2x bet amount (break even)
                    processHandEndSplit(2, 4);
                }
                else {
                    //2 losses, end immediately
                    processHandEnd(false);
                    }
                }
            else if (hand2Checked == false) {
                if (card2PowerConverter(playerCards2temp) == card2PowerConverter(houseCardstemp)) {
                        //1 loss, 1 push for a net result of 1x bet amount
                        processHandEndSplit(1, 4);
                    }
                else if (card2PowerConverter(playerCards2temp) > card2PowerConverter(houseCardstemp)) {
                    //1 win, 1 loss for a net result of 2x bet amount (break even)
                    processHandEndSplit(2, 4);
                }
                else {
                    //2 losses, end immediately
                    processHandEnd(false);
                    }
                }
        }
        else {
        //First, check if the dealer busted for an auto player win
            if (card2PowerConverter(houseCardstemp) > 21 ) {
                processHandEnd(true);
            }
            //If not, we do win logic here, since this is the natural place to do it (after dealer hitting). 3 Scenarios are possible... =>
            else if (card2PowerConverter(playerCardstemp) == card2PowerConverter(houseCardstemp)) {
                //push, return bet
                isActive[msg.sender] = false;
                msg.sender.transfer(betAmount[msg.sender]);
                payoutAmount[msg.sender]=betAmount[msg.sender];
                gamestatus[msg.sender] = 4;
                eventLogHand();
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
    }

    function processHandEnd(bool _win) internal { //hand is over and win is either true or false, now process it
        if (_win == false) {

            }
        else if (_win == true) {
            uint winAmount = betAmount[msg.sender] * 2;
            isActive[msg.sender] = false;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender]=winAmount;

        }
        gamestatus[msg.sender] = 5;
        isActive[msg.sender] = false;
        eventLogHand();

    }

    function processHandEndSplit(uint _betMultiplierReturned, uint _gamestatus) internal { //hand1, hand2 result
        if (_betMultiplierReturned != 0) {
            uint winAmount = betAmount[msg.sender] * _betMultiplierReturned;
            isActive[msg.sender] = false;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender]=winAmount;
        }
        gamestatus[msg.sender] = _gamestatus;
        isActive[msg.sender] = false;
        eventLogHand();
}


    //TODO: Log an event after hand, showing outcome

    function isBlackjack() internal returns (bool aceHole){
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
                if (cardsPower[(_card + 13) % 13] == 11) {
                    //dealer has blackjack, process
                    houseCards[msg.sender].push(_card); //push card as record, since game is now over
                    houseIsBlackjack = true;
                }
                else {
                    blackJackHouseProhibited[msg.sender]=uint(11); //ensure dealerHit doesn&#39;t draw this powerMax
                }
            }
            else if (housePower == 11) {
                if (cardsPower[(_card + 13) % 13] == 10) {
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
        uint winAmount;
        if (playerIsBlackjack == false && houseIsBlackjack == false) {
            //do nothing. Call this first since it&#39;s the most likely outcome
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == false) {
            //Player has blackjack, dealer doesn&#39;t, reward 1.5x bet (plus bet return)
            winAmount = betAmount[msg.sender] * 5/2; //player already lost half bet for insurance earlier in payable function
            if (insurancePurchased[msg.sender] == true) {
                gamestatus[msg.sender] = 7;
            }
            else {
                gamestatus[msg.sender] = 2;
            }
            isActive[msg.sender] = false;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender] = betAmount[msg.sender] * 5/2;
            emit blackjackEvent(bool(true), bool(false));
            eventLogHand();
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == true) {
            //Both player and dealer have blackjack. Push - return bet only
            if (insurancePurchased[msg.sender] == true) {
                winAmount = betAmount[msg.sender] * 5/2;
                gamestatus[msg.sender] = 7;
            }
            else {
                winAmount = betAmount[msg.sender];
                gamestatus[msg.sender] = 4;
            }
            isActive[msg.sender] = false;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender] = winAmount;
            emit blackjackEvent(bool(true), bool(true));
            eventLogHand();
        }
        else if (playerIsBlackjack == false && houseIsBlackjack == true) {
            //Only dealer has blackjack, player loses
            if (insurancePurchased[msg.sender] == true) {
                winAmount = betAmount[msg.sender] * 3/2;
                gamestatus[msg.sender] = 6;
                isActive[msg.sender] = false;
                msg.sender.transfer(winAmount);
                payoutAmount[msg.sender] = winAmount;
            }
            else {
                gamestatus[msg.sender] = 3;
                isActive[msg.sender] = false;
                }
            emit blackjackEvent(bool(false), bool(true));
            eventLogHand();
        }
        insurancePurchased[msg.sender] = false;
        return false;
    }

    function readCards() external view returns(uint[],uint[],uint[]) { //returns the cards in play, as an array of playercards, then houseCards
        return (playerCards[msg.sender],houseCards[msg.sender],playerCards2[msg.sender]);
    }

    function readPower() external view returns(uint, uint, uint) { //returns current card power of player and house
        return (card2PowerConverter(playerCards[msg.sender]),card2PowerConverter(houseCards[msg.sender]), card2PowerConverter(playerCards2[msg.sender]));
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
            address _owner = owner();
            _owner.transfer(permittedWithdraw);
        }
    }
}