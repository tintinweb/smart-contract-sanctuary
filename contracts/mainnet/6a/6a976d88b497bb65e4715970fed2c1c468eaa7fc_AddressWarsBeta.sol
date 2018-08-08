pragma solidity ^0.4.18;


//
// AddressWars
// (http://beta.addresswars.io/)
// Public Beta
//
//
//     .d8888b.                                    .d8888b.          
//    d88P  Y88b                                  d88P  Y88b         
//    888    888                                  888    888         
//    888    888888  888     888  888.d8888b      888    888888  888 
//    888    888`Y8bd8P&#39;     888  88888K          888    888`Y8bd8P&#39; 
//    888    888  X88K       Y88  88P"Y8888b.     888    888  X88K   
//    Y88b  d88P.d8""8b.      Y8bd8P      X88     Y88b  d88P.d8""8b. 
//     "Y8888P" 888  888       Y88P   88888P&#39;      "Y8888P" 888  888 
//
//
// ******************************
//  Welcome to AddressWars Beta!
// ******************************
//
// This contract is currently in a state of being tested and bug hunted,
// as this is the beta, there will be no fees for enlisting or wagering.
// This will encourage anyone to come and try out AddressWars for free
// before deciding to play the live version (when released) as well as
// making it so that the contract is tested to the fullest ability before
// the live version is deployed. The website is currently under development
// and will be continually improved as time goes on, once the live version
// is deployed, you can access it&#39;s contract and data through the root url
// (https://addresswars.io/) and there will always be a copy of the website
// on a subdomain that you can visit in order to view and interact with this
// contract at any time in the future.
//
// This contract is pushing the limits of the current Ethereum blockchain as
// there are quite a lot of variables that it needs to keep track of as well
// as being able to handle the statistical generation of key numbers. As a
// result, the estimated gas cost to deploy this contract is 7.5M whereas
// the current block gas limit is only 8M so this contract will take up
// almost a whole block! Another problem with complex contracts is the fact
// that there is a 16 local variable limit per function and in a few cases,
// the functions needed access to a lot more than that so a lot of filtering
// functions have been developed to handle the calculation internally then
// simply return the useful parts.
//
//
// **************************
//  How to play AddressWars!
// **************************
//
// Enlisting
// In order to start playing AddressWars, you must first have an Ethereum
// wallet address which you can issue transactions from but only non-contract 
// addresses (ie addresses where you can issue a transaction directly) can play.
// From here, you can simply call the enlist() function and send the relevant
// fee (in the beta it&#39;s 0 ETH, for the live it will be 0.01 ETH). After the
// transaction succeeds, you will have your very own, randomly generated
// address card that you can now put up for wager or use to attempt to claim
// other address cards with!
//
// Wagering
// You can choose to wager any card you own assuming you are not already 
// wagering a copy of that card. For your own address, you can provide a
// maximum of 10 other copies to any other addresses (by either transferring 
// or wagering), once 10 copies of your own address are circulating, you will
// no longer be able to transfer or wager your own address (although you can
// still use it to claim other addresses). It is important to note that there
// is no way to &#39;destroy&#39; a copy of a card in circulation and your own address
// card cannot be transferred back to you (and you can&#39;t attempt to claim your
// own address card).
// To wager a card, simply call the wagerCardForAmount() function and send
// the relevant fee (in the beta it&#39;s 0 ETH, for the live it will be 0.005 ETH)
// as well as the address of the card you wish to wager and the amount you are
// willing to wager it for (in wei). From this point, any other address can
// attempt to claim the address card you listed but the card that will be put up
// for claim will be the one with the lowest claim price (this may not be yours 
// at the time but as soon as a successful claim happens and you are the next
// cheapest price, the next time someone attempts to claim that address, you
// will receive the wager and your card may be claimed and taken from you).
//
// Claiming
// Assuming your address has already enlisted, you are free to attempt to
// claim any card that has a current wager on it. You can only store up to
// 8 unique card addresses (your own address + 7 others) in your inventory
// and you cannot claim if you are already at this limit (unless you already own
// that card). You can claim as many copies of a card you own as you like but you
// can only get rid of them by wagering off one at a time. As mentioned above,
// the claim contender will be the owner of the cheapest claim wager. You cannot 
// claim a card if you are the current claim contender or if the card address is 
// the same as your address (ie you enlisted and got that card).
// To attempt to claim, you need to first assemble an army of 3 address cards
// (these cards don&#39;t have to be unique but you do have to own them) and send the 
// current cheapest wager price to the attemptToClaimCard() function. This function  
// will do all of the calculation work for you and determine if you managed to claim
// the card or not. The first thing that happens is the contract randomly picks 
// your claim contenders cards ensuring that at least one of the cards is the card
// address you are attempting to claim and the rest are from their inventory.
// After this point, all of the complex maths happens and the final attack
// and defence numbers will be calculated based on all of the cards types,
// modifiers and the base attack and defence stats.
// From here it&#39;s simply a matter of determining how many hits got through
// on both claimer and claim contender, it&#39;s calculated as follows;
// opponentsHits = yourCard[attack] - opponentsCard[defence]
//  ^ will be 0 if opponentsCard[defence] > yourCard[attack]
// This is totalled up for both the claimer and the claim contender and the
// one with the least amount of hits wins!
//
// Claim Outcomes
// There are 3 situations that can result from a claim attempt;
// 1. The total hits for both the claimer and the claim contender are equal
//    - this means that you have drawn with your opponent, the wager will
//      then be distributed;
//      98% -> the claimer (you get most of the wager back)
//      2% -> the dev
// 2. The claimer has more hits than the claim contender
//    - this means that you have lost against your opponent as they ended
//      up taking less hits than you, the wager will then be distributed;
//      98% -> the claim contender (they get most of the wager)
//      2% -> the dev
// 3. The claimer has less hits than the claim contender
//    - this means that you have succeeded in claiming the card and hence
//      that card address will be transferred from the claim contender
//      to the claimer. in this case, both claimer and claim contender
//      receive a portion of the wager as follow;
//      50% -> the claimer (you get half of the wager back)
//      48% -> the claim contender (they get about half of the wager)
//      2% -> the dev
//
// Transferring
// You are free to transfer any card you own to another address that has
// already enlisted. Upon transfer, only one copy of the card will be removed
// from your inventory so if you have multiple copies of that card, it will
// not be completely removed from your inventory. If you only had one copy
// though, that address will be removed from your inventory and you will
// be able to claim/receive another address in its place.
// There are some restrictions when transferring a card; 
//   1. you cannot be currently wagering the card
//   2. the address you are transferring to must already be enlisted
//   3. the address you are transferring the card to must have less than 
//      8 unique cards already (or they must already own the card)
//   4. you cannot transfer a card back to it&#39;s original address
//   5. if you are gifting your own address card, the claim limit will apply
//      and if 10 copies already exist, you will not be able to gift your card.
//
// Withdrawing
// All ETH transferred to the contract will stay in there until an
// address wishes to withdraw from their account. Balances are tracked
// per address and you can either withdraw an amount (assuming you have
// a balance higher than that amount) or you can just withdraw it all.
// For both of these cases there will be no fees associated with withdrawing
// from the contract and after you choose to withdraw, your balance will
// update accordingly.
//
//
// Have fun and good luck claiming!
//


contract AddressWarsBeta {

  //////////////////////////////////////////////////////////////////////
  //  Constants


  // dev
  address public dev;
  uint256 constant devTax = 2; // 2% of all wagers

  // fees
  // in the live version the;
  // enlistingFee will be 0.01 ether and the
  // wageringFee will be 0.005 ether
  uint256 constant enlistingFee = 0;
  uint256 constant wageringFee = 0;

  // limits

  // the claim limit represents how many times an address can
  // wager/trasnfer their own address. in this case the limit
  // is set to 10 which means there can only ever be 10 other
  // copies of your address out there. once you have wagered
  // all 10 copies, you will no longer be able to wager your
  // own address card (although you can still use it in play).
  uint256 constant CLAIM_LIMIT = 10;

  // this will limit how many unique addresses you can own at
  // one time. you can own multiple copies of a unique address
  // but you can only own a total of 8 unique addresses (your
  // own address + 7 others) at a time. you can choose to wager
  // any address but if you wager one, the current claim price is the
  // lowest price offered from all owners. upon a successful claim,
  // one copy will transfer from your inventory and if you have no
  // copies remaining, it will remove that address card and you will
  // have another free slot.
  uint256 constant MAX_UNIQUE_CARDS_PER_ADDRESS = 8;


  //////////////////////////////////////////////////////////////////////
  //  Statistical Variables


  // this is used to calculate all of the statistics and random choices
  // within AddressWars
  // see the shuffleSeed() and querySeed() methods for more information.
  uint256 private _seed;

  // the type will determine a cards bonus numbers;
  // normal cards do not get any type advantage bonuses
  // fire gets 1.25x att and def when versing nature
  // water gets 1.25x att and def when versing fire
  // nature gets 1.25x att and def when versing water
  // *type advantages are applied after all modifiers
  // that use addition are calculated
  enum TYPE { NORMAL, FIRE, WATER, NATURE }
  uint256[] private typeChances = [ 6, 7, 7, 7 ];
  uint256 constant typeSum = 27;

  // the modifier will act like a bonus for your card(s)
  // NONE: no bonus will be applied
  // ALL_: if all cards are of the same type, they all get
  //       bonus att/def/att+def numbers
  // V_: if a versing card is of a certain type, your card
  //     will get bonus att/def numbers
  // V_SWAP: this will swap the versing cards att and def
  //         numbers after they&#39;ve been modified by any
  //         other active modifiers
  // R_V: your card resists the type advantages of the versing card,
  //      normal type cards cannot receive this modifier
  // A_I: your cards type advantage increases from 1.25x to 1.5x,
  //      normal type cards cannot receive this modifier
  enum MODIFIER {
    NONE,
    ALL_ATT, ALL_DEF, ALL_ATT_DEF,
    V_ATT, V_DEF,
    V_SWAP,
    R_V,
    A_I
  }
  uint256[] private modifierChances = [
    55,
    5, 6, 1,
    12, 14,
    3,
    7,
    4
  ];
  uint256 constant modifierSum = 107;

  // below are the chances for the bonus stats of the modifiers,
  // the seed will first choose a value between 0 and the sum, it will
  // then cumulatively count up until it reaches the index with the
  // matched roll
  // for example;
  // if your data was = [ 2, 3, 4, 2, 1 ], your cumulative total is 12,
  // from there a number will be rolled and it will add up all the values
  // until the cumulative total is greater than the number rolled
  // if we rolled a 9, 2(0) + 3(1) + 4(2) + 2(3) = 11 > 9 so the index
  // you matched in this case would be 3
  // the final value will be;
  // bonusMinimum + indexOf(cumulativeRoll)
  uint256 constant cardBonusMinimum = 1;
  uint256[] private modifierAttBonusChances = [ 2, 5, 8, 7, 3, 2, 1, 1 ]; // range: 1 - 8
  uint256 constant modifierAttBonusSum = 29;
  uint256[] private modifierDefBonusChances = [ 2, 3, 6, 8, 6, 5, 3, 2, 1, 1 ];  // range: 1 - 10
  uint256 constant modifierDefBonusSum = 37;

  // below are the distribution of the attack and defence numbers,
  // in general, the attack average should be slightly higher than the
  // defence average and defence should have a wider spread of values 
  // compared to attack which should be a tighter set of numbers
  // the final value will be;
  // cardMinimum + indexOf(cumulativeRoll)
  uint256 constant cardAttackMinimum = 10;
  uint256[] private cardAttackChances = [ 2, 2, 3, 5, 8, 9, 15, 17, 13, 11, 6, 5, 3, 2, 1, 1 ]; // range: 10 - 25
  uint256 constant cardAttackSum = 103;
  uint256 constant cardDefenceMinimum = 5;
  uint256[] private cardDefenceChances = [ 1, 1, 2, 3, 5, 6, 11, 15, 19, 14, 12, 11, 9, 8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 1, 1, 1 ]; // range: 5 - 30
  uint256 constant cardDefenceSum = 153;


  //////////////////////////////////////////////////////////////////////
  //  Registry Variables


  // overall address card tracking
  mapping (address => bool) _exists;
  mapping (address => uint256) _indexOf;
  mapping (address => address[]) _ownersOf;
  mapping (address => uint256[]) _ownersClaimPriceOf;
  struct AddressCard {
      address _cardAddress;
      uint8 _cardType;
      uint8 _cardModifier;
      uint8 _modifierPrimarayVal;
      uint8 _modifierSecondaryVal;
      uint8 _attack;
      uint8 _defence;
      uint8 _claimed;
      uint8 _forClaim;
      uint256 _lowestPrice;
      address _claimContender;
  }
  AddressCard[] private _addressCards;

  // owner and balance tracking
  mapping (address => uint256) _balanceOf;
  mapping (address => address[]) _cardsOf;


  //////////////////////////////////////////////////////////////////////
  //  Events


  event AddressDidEnlist(
    address enlistedAddress);
  event AddressCardWasWagered(
    address addressCard, 
    address owner, 
    uint256 wagerAmount);
  event AddressCardWagerWasCancelled(
    address addressCard, 
    address owner);
  event AddressCardWasTransferred(
    address addressCard, 
    address fromAddress, 
    address toAddress);
  event ClaimAttempt(
    bool wasSuccessful, 
    address addressCard, 
    address claimer, 
    address claimContender, 
    address[3] claimerChoices, 
    address[3] claimContenderChoices, 
    uint256[3][2] allFinalAttackValues,
    uint256[3][2] allFinalDefenceValues);


  //////////////////////////////////////////////////////////////////////
  //  Main Functions


  // start up the contract!
  function AddressWarsBeta() public {

    // set our dev
    dev = msg.sender;
    // now use the dev address as the initial seed mix
    shuffleSeed(uint256(dev));

  }

  // any non-contract address can call this function and begin playing AddressWars!
  // please note that as there are a lot of write to storage operations, this function
  // will be quite expensive in terms of gas so keep that in mind when sending your
  // transaction to the network!
  // 350k gas should be enough to handle all of the storage operations but MetaMask
  // will give a good estimate when you initialize the transaction
  // in order to enlist in AddressWars, you must first pay the enlistingFee (free for beta!)
  function enlist() public payable {

    require(cardAddressExists(msg.sender) == false);
    require(msg.value == enlistingFee);
    require(msg.sender == tx.origin); // this prevents contracts from enlisting,
    // only normal addresses (ie ones that can send a request) can play AddressWars.

    // first shuffle the main seed with the sender address as input
    uint256 tmpSeed = tmpShuffleSeed(_seed, uint256(msg.sender));
    uint256 tmpModulus;
    // from this point on, tmpSeed will shuffle every time tmpQuerySeed()
    // is called. it is used recursively so it will mutate upon each
    // call of that function and finally at the end we will update
    // the overall seed to save on gas fees

    // now we can query the different attributes of the card
    // first lets determine the card type
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, typeSum);
    uint256 cardType = cumulativeIndexOf(typeChances, tmpModulus);

    // now to get the modifier
    // special logic to handle normal type cards
    uint256 adjustedModifierSum = modifierSum;
    if (cardType == uint256(TYPE.NORMAL)) {
      // normal cards cannot have the advantage increase modifier (the last in the array)
      adjustedModifierSum -= modifierChances[modifierChances.length - 1];
      // normal cards cannot have the resistance versing modifier (second last in the array)
      adjustedModifierSum -= modifierChances[modifierChances.length - 2];
    }
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, adjustedModifierSum);
    uint256 cardModifier = cumulativeIndexOf(modifierChances, tmpModulus);

    // now we need to find our attack and defence values
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, cardAttackSum);
    uint256 cardAttack = cardAttackMinimum + cumulativeIndexOf(cardAttackChances, tmpModulus);
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, cardDefenceSum);
    uint256 cardDefence = cardDefenceMinimum + cumulativeIndexOf(cardDefenceChances, tmpModulus);

    // finally handle our modifier values
    uint256 primaryModifierVal = 0;
    uint256 secondaryModifierVal = 0;
    uint256 bonusAttackPenalty = 0;
    uint256 bonusDefencePenalty = 0;
    // handle the logic of our modifiers
    if (cardModifier == uint256(MODIFIER.ALL_ATT)) { // all of the same type attack bonus

      // the primary modifier value will hold our attack bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      primaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
      // now for the attack penalty
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      bonusAttackPenalty = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
      // penalty is doubled
      bonusAttackPenalty *= 2;

    } else if (cardModifier == uint256(MODIFIER.ALL_DEF)) { // all of the same type defence bonus

      // the primary modifier value will hold our defence bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      primaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
      // now for the defence penalty
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      bonusDefencePenalty = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
      // penalty is doubled
      bonusDefencePenalty *= 2;

    } else if (cardModifier == uint256(MODIFIER.ALL_ATT_DEF)) { // all of the same type attack and defence bonus

      // the primary modifier value will hold our attack bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      primaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
      // now for the attack penalty
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      bonusAttackPenalty = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
      // penalty is doubled
      bonusAttackPenalty *= 2;

      // the secondary modifier value will hold our defence bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      secondaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
      // now for the defence penalty
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      bonusDefencePenalty = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
      // penalty is doubled
      bonusDefencePenalty *= 2;

    } else if (cardModifier == uint256(MODIFIER.V_ATT)) { // versing a certain type attack bonus

      // the primary modifier value will hold type we need to verse in order to get our bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, typeSum);
      primaryModifierVal = cumulativeIndexOf(typeChances, tmpModulus);

      // the secondary modifier value will hold our attack bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      secondaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
      // now for the attack penalty
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      bonusAttackPenalty = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);

    } else if (cardModifier == uint256(MODIFIER.V_DEF)) { // versing a certain type defence bonus

      // the primary modifier value will hold type we need to verse in order to get our bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, typeSum);
      primaryModifierVal = cumulativeIndexOf(typeChances, tmpModulus);

      // the secondary modifier value will hold our defence bonus
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      secondaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
      // now for the defence penalty
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      bonusDefencePenalty = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);

    }

    // now apply the penalties
    if (bonusAttackPenalty >= cardAttack) {
      cardAttack = 0;
    } else {
      cardAttack -= bonusAttackPenalty;
    }
    if (bonusDefencePenalty >= cardDefence) {
      cardDefence = 0;
    } else {
      cardDefence -= bonusDefencePenalty;
    }


    // now to add it to the registry
    _exists[msg.sender] = true;
    _indexOf[msg.sender] = uint256(_addressCards.length);
    _ownersOf[msg.sender] = [ msg.sender ];
    _ownersClaimPriceOf[msg.sender] = [ uint256(0) ];
    _addressCards.push(AddressCard({
      _cardAddress: msg.sender,
      _cardType: uint8(cardType),
      _cardModifier: uint8(cardModifier),
      _modifierPrimarayVal: uint8(primaryModifierVal),
      _modifierSecondaryVal: uint8(secondaryModifierVal),
      _attack: uint8(cardAttack),
      _defence: uint8(cardDefence),
      _claimed: uint8(0),
      _forClaim: uint8(0),
      _lowestPrice: uint256(0),
      _claimContender: address(0)
    }));

    // ...and now start your own collection!
    _cardsOf[msg.sender] = [ msg.sender ];

    // dev receives the enlisting fee
    _balanceOf[dev] = SafeMath.add(_balanceOf[dev], enlistingFee);

    // finally we need to update the main seed and as we initially started with
    // the current main seed, tmpSeed will be the current representation of the seed
    _seed = tmpSeed;

    // now that we&#39;re done, it&#39;s time to log the event
    AddressDidEnlist(msg.sender);

  }

  // this is where you can wager one of your addresses for a certain amount.
  // any other player can then attempt to claim your address off you, if the
  // address is your own address, you will simply give them a copy (limited to 10
  // total copies) but otherwise the player will take that address off you if they
  // are successful.
  // here&#39;s what can happen when you wager;
  // 1. if an opponent is successful in claiming your card, they will receive 50%
  //    of the wager amount back, the dev gets 2% and you get 48%
  // 2. if an opponent is unsuccessful in claiming your card, you will receive
  //    98% of the wager amount and the dev will get 2%
  // 3. if an opponent is draws with you when claiming your card, they will receive
  //    98% of the wager amount back and the dev will get 2%
  // your wager will remain available for anyone to claim up until either you cancel
  // the wager or an opponent is successful in claiming your card
  // in order to wager in AddressWars, you must first pay the wageringFee (free for beta!)
  function wagerCardForAmount(address cardAddress, uint256 amount) public payable {

    require(amount > 0);

    require(cardAddressExists(msg.sender));
    require(msg.value == wageringFee);

    uint256 firstMatchedIndex;
    bool isAlreadyWagered;
    (firstMatchedIndex, isAlreadyWagered, , , ) = getOwnerOfCardsCheapestWager(msg.sender, cardAddress);
    // calling the above method will automatically reinforce the check that the cardAddress exists
    // as well as the sender actually owning the card
    // we cannot wager a card if we are already wagering it
    require(isAlreadyWagered == false);
    // double check to make sure the card is actually owned by the sender
    require(msg.sender == _ownersOf[cardAddress][firstMatchedIndex]);

    AddressCard memory addressCardForWager = _addressCards[_indexOf[cardAddress]];
    if (msg.sender == cardAddress) {
      // we need to enforce the claim limit if you are the initial owner
      require(addressCardForWager._claimed < CLAIM_LIMIT);
    }

    // now write the new data
    _ownersClaimPriceOf[cardAddress][firstMatchedIndex] = amount;

    // now update our statistics
    updateCardStatistics(cardAddress);

    // dev receives the wagering fee
    _balanceOf[dev] = SafeMath.add(_balanceOf[dev], wageringFee);

    // now that we&#39;re done, it&#39;s time to log the event
    AddressCardWasWagered(cardAddress, msg.sender, amount);

  }

  function cancelWagerOfCard(address cardAddress) public {

    require(cardAddressExists(msg.sender));

    uint256 firstMatchedIndex;
    bool isAlreadyWagered;
    (firstMatchedIndex, isAlreadyWagered, , , ) = getOwnerOfCardsCheapestWager(msg.sender, cardAddress);
    // calling the above method will automatically reinforce the check that the cardAddress exists
    // as well as the owner actually owning the card
    // we can only cancel a wager if there already is one
    require(isAlreadyWagered);
    // double check to make sure the card is actually owned by the sender
    require(msg.sender == _ownersOf[cardAddress][firstMatchedIndex]);

    // now write the new data
    _ownersClaimPriceOf[cardAddress][firstMatchedIndex] = 0;

    // now update our statistics
    updateCardStatistics(cardAddress);

    // now that we&#39;re done, it&#39;s time to log the event
    AddressCardWagerWasCancelled(cardAddress, msg.sender);

  }

  // this is the main battle function of the contract, it takes the card address you
  // wish to claim as well as your card choices as input. a lot of complex calculations
  // happen within this function and in the end, a result will be determined on whether
  // you won the claim or not. at the end, an event will be logged with all of the information
  // about what happened in the battle including the final result, the contenders,
  // the card choices (yours and your opponenets) as well as the final attack and defence numbers.
  // this function will revert if the msg.value does not match the current minimum claim value
  // of the card address you are attempting to claim.
  function attemptToClaimCard(address cardAddress, address[3] choices) public payable {

    // a lot of the functionality of attemptToClaimCard() is calculated in other methods as
    // there is only a 16 local variable limit per method and we need a lot more than that

    // see ownerCanClaimCard() below, this ensures we can actually claim the card we are after
    // by running through various requirement checks
    address claimContender;
    uint256 claimContenderIndex;
    (claimContender, claimContenderIndex) = ownerCanClaimCard(msg.sender, cardAddress, choices, msg.value);

    address[3] memory opponentCardChoices = generateCardsFromClaimForOpponent(cardAddress, claimContender);

    uint256[3][2] memory allFinalAttackFigures;
    uint256[3][2] memory allFinalDefenceFigures;
    (allFinalAttackFigures, allFinalDefenceFigures) = calculateAdjustedFiguresForBattle(choices, opponentCardChoices);
    // after this point we have all of the modified attack and defence figures
    // in the arrays above. the way the winner is determined is by counting 
    // how many attack points get through in total for each card, this is
    // calculated by simply doing;
    // opponentsHits = yourCard[attack] - opponentsCard[defence]
    // if the defence of the opposing card is greater than the attack value,
    // no hits will be taken.
    // at the end, all hits are added up and the winner is the one with
    // the least total amount of hits, if it is a draw, the wager will be
    // returned to the sender (minus the dev fee)
    uint256[2] memory totalHits = [ uint256(0), uint256(0) ];
    for (uint256 i = 0; i < 3; i++) {
      // start with the opponent attack to you
      totalHits[0] += (allFinalAttackFigures[1][i] > allFinalDefenceFigures[0][i] ? allFinalAttackFigures[1][i] - allFinalDefenceFigures[0][i] : 0);
      // then your attack to the opponent
      totalHits[1] += (allFinalAttackFigures[0][i] > allFinalDefenceFigures[1][i] ? allFinalAttackFigures[0][i] - allFinalDefenceFigures[1][i] : 0);
    }

    // before we process the outcome, we should log the event.
    // order is important here as we should log a successful 
    // claim attempt then a transfer (if that&#39;s what happens)
    // instead of the other way around
    ClaimAttempt(
      totalHits[0] < totalHits[1], // it was successful if we had less hits than the opponent
      cardAddress,
      msg.sender,
      claimContender,
      choices,
      opponentCardChoices,
      allFinalAttackFigures,
      allFinalDefenceFigures
      );

    // handle the outcomes
    uint256 tmpAmount;
    if (totalHits[0] == totalHits[1]) { // we have a draw

      // hand out the dev tax
      tmpAmount = SafeMath.div(SafeMath.mul(msg.value, devTax), 100); // 2%
      _balanceOf[dev] = SafeMath.add(_balanceOf[dev], tmpAmount);
      // now we return the rest to the sender
      _balanceOf[msg.sender] = SafeMath.add(_balanceOf[msg.sender], SafeMath.sub(msg.value, tmpAmount)); // 98%

    } else if (totalHits[0] > totalHits[1]) { // we have more hits so we were unsuccessful

      // hand out the dev tax
      tmpAmount = SafeMath.div(SafeMath.mul(msg.value, devTax), 100); // 2%
      _balanceOf[dev] = SafeMath.add(_balanceOf[dev], tmpAmount);
      // now we give the rest to the claim contender
      _balanceOf[claimContender] = SafeMath.add(_balanceOf[claimContender], SafeMath.sub(msg.value, tmpAmount)); // 98%

    } else { // this means we have less hits than the opponent so we were successful in our claim!

      // hand out the dev tax
      tmpAmount = SafeMath.div(SafeMath.mul(msg.value, devTax), 100); // 2%
      _balanceOf[dev] = SafeMath.add(_balanceOf[dev], tmpAmount);
      // return half to the sender
      _balanceOf[msg.sender] = SafeMath.add(_balanceOf[msg.sender], SafeMath.div(msg.value, 2)); // 50%
      // and now the remainder goes to the claim contender
      _balanceOf[claimContender] = SafeMath.add(_balanceOf[claimContender], SafeMath.sub(SafeMath.div(msg.value, 2), tmpAmount)); // 48%

      // finally transfer the ownership of the card from the claim contender to the sender but
      // first we need to make sure to cancel the wager
      _ownersClaimPriceOf[cardAddress][claimContenderIndex] = 0;
      transferCard(cardAddress, claimContender, msg.sender);

      // now update our statistics
      updateCardStatistics(cardAddress);

    }

  }

  function transferCardTo(address cardAddress, address toAddress) public {

    // you can view this internal method below for more details.
    // all of the requirements around transferring a card are
    // tested within the transferCard() method.
    // you are free to gift your own address card to anyone
    // (assuming there are less than 10 copies circulating).
    transferCard(cardAddress, msg.sender, toAddress);

  }


  //////////////////////////////////////////////////////////////////////
  //  Wallet Functions


  function withdrawAmount(uint256 amount) public {

    require(amount > 0);

    address sender = msg.sender;
    uint256 balance = _balanceOf[sender];
    
    require(amount <= balance);
    // transfer and update the balances
    _balanceOf[sender] = SafeMath.sub(_balanceOf[sender], amount);
    sender.transfer(amount);

  }

  function withdrawAll() public {

    address sender = msg.sender;
    uint256 balance = _balanceOf[sender];

    require(balance > 0);
    // transfer and update the balances
    _balanceOf[sender] = 0;
    sender.transfer(balance);

  }

  function getBalanceOfSender() public view returns (uint256) {
    return _balanceOf[msg.sender];
  }


  //////////////////////////////////////////////////////////////////////
  //  Helper Functions


  function tmpShuffleSeed(uint256 tmpSeed, uint256 mix) public view returns (uint256) {

    // really mix it up!
    uint256 newTmpSeed = tmpSeed;
    uint256 currentTime = now;
    uint256 timeMix = currentTime + mix;
    // in this instance, overflow is ok as we are just shuffling around the bits
    // first lets square the seed
    newTmpSeed *= newTmpSeed;
    // now add our time and mix
    newTmpSeed += timeMix;
    // multiply by the time
    newTmpSeed *= currentTime;
    // now add our mix
    newTmpSeed += mix;
    // and finally multiply by the time and mix
    newTmpSeed *= timeMix;

    return newTmpSeed;

  }

  function shuffleSeed(uint256 mix) private {

    // set our seed based on our last seed
    _seed = tmpShuffleSeed(_seed, mix);
  
  }

  function tmpQuerySeed(uint256 tmpSeed, uint256 modulus) public view returns (uint256 tmpShuffledSeed, uint256 result) {

    require(modulus > 0);

    // get our answer
    uint256 response = tmpSeed % modulus;

    // now we want to re-mix our seed based off our response
    uint256 mix = response + 1; // non-zero
    mix *= modulus;
    mix += response;
    mix *= modulus;

    // now return it
    return (tmpShuffleSeed(tmpSeed, mix), response);

  }

  function querySeed(uint256 modulus) private returns (uint256) {

    require(modulus > 0);

    uint256 tmpSeed;
    uint256 response;
    (tmpSeed, response) = tmpQuerySeed(_seed, modulus);

    // tmpSeed will now represent the suffled version of our last seed
    _seed = tmpSeed;

    // now return it
    return response;

  }

  function cumulativeIndexOf(uint256[] array, uint256 target) private pure returns (uint256) {

    bool hasFound = false;
    uint256 index;
    uint256 cumulativeTotal = 0;
    for (uint256 i = 0; i < array.length; i++) {
      cumulativeTotal += array[i];
      if (cumulativeTotal > target) {
        hasFound = true;
        index = i;
        break;
      }
    }

    require(hasFound);
    return index;

  }

  function cardAddressExists(address cardAddress) public view returns (bool) {
    return _exists[cardAddress];
  }

  function indexOfCardAddress(address cardAddress) public view returns (uint256) {
    require(cardAddressExists(cardAddress));
    return _indexOf[cardAddress];
  }

  function ownerCountOfCard(address owner, address cardAddress) public view returns (uint256) {

    // both card addresses need to exist in order to own cards
    require(cardAddressExists(owner));
    require(cardAddressExists(cardAddress));

    // check if it&#39;s your own address
    if (owner == cardAddress) {
      return 0;
    }

    uint256 ownerCount = 0;
    address[] memory owners = _ownersOf[cardAddress];
    for (uint256 i = 0; i < owners.length; i++) {
      if (owner == owners[i]) {
        ownerCount++;
      }
    }

    return ownerCount;

  }

  function ownerHasCard(address owner, address cardAddress) public view returns (bool doesOwn, uint256[] indexes) {

    // both card addresses need to exist in order to own cards
    require(cardAddressExists(owner));
    require(cardAddressExists(cardAddress));

    uint256[] memory ownerIndexes = new uint256[](ownerCountOfCard(owner, cardAddress));
    // check if it&#39;s your own address
    if (owner == cardAddress) {
      return (true, ownerIndexes);
    }

    if (ownerIndexes.length > 0) {
      uint256 currentIndex = 0;
      address[] memory owners = _ownersOf[cardAddress];
      for (uint256 i = 0; i < owners.length; i++) {
        if (owner == owners[i]) {
          ownerIndexes[currentIndex] = i;
          currentIndex++;
        }
      }
    }

    // this owner may own multiple copies of the card and so an array of indexes are returned
    // if the owner does not own the card, it will return (false, [])
    return (ownerIndexes.length > 0, ownerIndexes);

  }

  function ownerHasCardSimple(address owner, address cardAddress) private view returns (bool) {

    bool doesOwn;
    (doesOwn, ) = ownerHasCard(owner, cardAddress);
    return doesOwn;

  }

  function ownerCanClaimCard(address owner, address cardAddress, address[3] choices, uint256 amount) private view returns (address currentClaimContender, uint256 claimContenderIndex) {

    // you cannot claim back your own address cards
    require(owner != cardAddress);
    require(cardAddressExists(owner));
    require(ownerHasCardSimple(owner, cardAddress) || _cardsOf[owner].length < MAX_UNIQUE_CARDS_PER_ADDRESS);


    uint256 cheapestIndex;
    bool canClaim;
    address claimContender;
    uint256 lowestClaimPrice;
    (cheapestIndex, canClaim, claimContender, lowestClaimPrice, ) = getCheapestCardWager(cardAddress);
    // make sure we can actually claim it and that we are paying the correct amount
    require(canClaim);
    require(amount == lowestClaimPrice);
    // we also need to check that the sender is not the current claim contender
    require(owner != claimContender);

    // now check if we own all of our choices
    for (uint256 i = 0; i < choices.length; i++) {
      require(ownerHasCardSimple(owner, choices[i])); // if one is not owned, it will trigger a revert
    }

    // if no requires have been triggered by this point it means we are able to claim the card
    // now return the claim contender and their index
    return (claimContender, cheapestIndex);

  }

  function generateCardsFromClaimForOpponent(address cardAddress, address opponentAddress) private returns (address[3]) {

    require(cardAddressExists(cardAddress));
    require(cardAddressExists(opponentAddress));
    require(ownerHasCardSimple(opponentAddress, cardAddress));

    // generate the opponents cards from their own inventory
    // it is important to note that at least 1 of their choices
    // needs to be the card you are attempting to claim
    address[] memory cardsOfOpponent = _cardsOf[opponentAddress];
    address[3] memory opponentCardChoices;
    uint256 tmpSeed = tmpShuffleSeed(_seed, uint256(opponentAddress));
    uint256 tmpModulus;
    uint256 indexOfClaimableCard;
    (tmpSeed, indexOfClaimableCard) = tmpQuerySeed(tmpSeed, 3); // 0, 1 or 2
    for (uint256 i = 0; i < 3; i++) {
      if (i == indexOfClaimableCard) {
        opponentCardChoices[i] = cardAddress;
      } else {
        (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, cardsOfOpponent.length);
        opponentCardChoices[i] = cardsOfOpponent[tmpModulus];        
      }
    }

    // finally we need to update the main seed and as we initially started with
    // the current main seed, tmpSeed will be the current representation of the seed
    _seed = tmpSeed;

    return opponentCardChoices;

  }

  function updateCardStatistics(address cardAddress) private {

    AddressCard storage addressCardClaimed = _addressCards[_indexOf[cardAddress]];
    address claimContender;
    uint256 lowestClaimPrice;
    uint256 wagerCount;
    ( , , claimContender, lowestClaimPrice, wagerCount) = getCheapestCardWager(cardAddress);
    addressCardClaimed._forClaim = uint8(wagerCount);
    addressCardClaimed._lowestPrice = lowestClaimPrice;
    addressCardClaimed._claimContender = claimContender;

  }

  function transferCard(address cardAddress, address fromAddress, address toAddress) private {

    require(toAddress != fromAddress);
    require(cardAddressExists(cardAddress));
    require(cardAddressExists(fromAddress));
    uint256 firstMatchedIndex;
    bool isWagered;
    (firstMatchedIndex, isWagered, , , ) = getOwnerOfCardsCheapestWager(fromAddress, cardAddress);
    require(isWagered == false); // you cannot transfer a card if it&#39;s currently wagered

    require(cardAddressExists(toAddress));
    require(toAddress != cardAddress); // can&#39;t transfer a card to it&#39;s original address
    require(ownerHasCardSimple(toAddress, cardAddress) || _cardsOf[toAddress].length < MAX_UNIQUE_CARDS_PER_ADDRESS);

    // firstly, if toAddress doesn&#39;t have a copy we need to add one
    if (!ownerHasCardSimple(toAddress, cardAddress)) {
      _cardsOf[toAddress].push(cardAddress);
    } 

    // now check whether the fromAddress is just our original card
    // address, if this is the case, they are free to transfer out
    // one of their cards assuming the claim limit is not yet reached
    if (fromAddress == cardAddress) { // the card is being claimed/gifted

      AddressCard storage addressCardClaimed = _addressCards[_indexOf[cardAddress]];
      require(addressCardClaimed._claimed < CLAIM_LIMIT);

      // we need to push new data to our arrays
      _ownersOf[cardAddress].push(toAddress);
      _ownersClaimPriceOf[cardAddress].push(uint256(0));

      // now update the claimed count in the registry
      addressCardClaimed._claimed = uint8(_ownersOf[cardAddress].length - 1); // we exclude the original address

    } else {

      // firstly we need to cache the current index from our fromAddress&#39; _cardsOf
      uint256 cardIndexOfSender = getCardIndexOfOwner(cardAddress, fromAddress);

      // now just update the address at the firstMatchedIndex
      _ownersOf[cardAddress][firstMatchedIndex] = toAddress;

      // finally check if our fromAddress has any copies of the card left
      if (!ownerHasCardSimple(fromAddress, cardAddress)) {

        // if not delete that card from their inventory and make room in the array
        for (uint256 i = cardIndexOfSender; i < _cardsOf[fromAddress].length - 1; i++) {
          // shuffle the next value over
          _cardsOf[fromAddress][i] = _cardsOf[fromAddress][i + 1];
        }
        // now decrease the length
        _cardsOf[fromAddress].length--;

      }

    }

    // now that we&#39;re done, it&#39;s time to log the event
    AddressCardWasTransferred(cardAddress, fromAddress, toAddress);

  }

  function calculateAdjustedFiguresForBattle(address[3] yourChoices, address[3] opponentsChoices) private view returns (uint256[3][2] allAdjustedAttackFigures, uint256[3][2] allAdjustedDefenceFigures) {

    // [0] is yours, [1] is your opponents
    AddressCard[3][2] memory allCards;
    uint256[3][2] memory allAttackFigures;
    uint256[3][2] memory allDefenceFigures;
    bool[2] memory allOfSameType = [ true, true ];
    uint256[2] memory cumulativeAttackBonuses = [ uint256(0), uint256(0) ];
    uint256[2] memory cumulativeDefenceBonuses = [ uint256(0), uint256(0) ];

    for (uint256 i = 0; i < 3; i++) {
      // cache your cards
      require(_exists[yourChoices[i]]);
      allCards[0][i] = _addressCards[_indexOf[yourChoices[i]]];
      allAttackFigures[0][i] = allCards[0][i]._attack;
      allDefenceFigures[0][i] = allCards[0][i]._defence;

      // cache your opponents cards
      require(_exists[opponentsChoices[i]]);
      allCards[1][i] = _addressCards[_indexOf[opponentsChoices[i]]];
      allAttackFigures[1][i] = allCards[1][i]._attack;
      allDefenceFigures[1][i] = allCards[1][i]._defence;
    }

    // for the next part, order is quite important as we want the
    // addition to happen first and then the multiplication to happen 
    // at the very end for the type advantages/resistances

    //////////////////////////////////////////////////////////////
    // the first modifiers that needs to be applied is the
    // ALL_ATT, ALL_DEF and the ALL_ATT_DEF mod
    // if all 3 of the chosen cards match the same type
    // and if at least one of them have the ALL_ATT, ALL_DEF
    // or ALL_ATT_DEF modifier, all of the cards will receive
    // the cumulative bonus for att/def/att+def
    for (i = 0; i < 3; i++) {

      // start with your cards      
      // compare to see if the types are the same as the previous one
      if (i > 0 && allCards[0][i]._cardType != allCards[0][i - 1]._cardType) {
        allOfSameType[0] = false;
      }
      // next count up all the modifier values for a total possible bonus
      if (allCards[0][i]._cardModifier == uint256(MODIFIER.ALL_ATT)) { // all attack
        // for the ALL_ATT modifier, the additional attack bonus is
        // stored in the primary value
        cumulativeAttackBonuses[0] += allCards[0][i]._modifierPrimarayVal;
      } else if (allCards[0][i]._cardModifier == uint256(MODIFIER.ALL_DEF)) { // all defence
        // for the ALL_DEF modifier, the additional defence bonus is
        // stored in the primary value
        cumulativeDefenceBonuses[0] += allCards[0][i]._modifierPrimarayVal;
      } else if (allCards[0][i]._cardModifier == uint256(MODIFIER.ALL_ATT_DEF)) { // all attack + defence
        // for the ALL_ATT_DEF modifier, the additional attack bonus is
        // stored in the primary value and the additional defence bonus is
        // stored in the secondary value
        cumulativeAttackBonuses[0] += allCards[0][i]._modifierPrimarayVal;
        cumulativeDefenceBonuses[0] += allCards[0][i]._modifierSecondaryVal;
      }
      
      // now do the same for your opponent
      if (i > 0 && allCards[1][i]._cardType != allCards[1][i - 1]._cardType) {
        allOfSameType[1] = false;
      }
      if (allCards[1][i]._cardModifier == uint256(MODIFIER.ALL_ATT)) {
        cumulativeAttackBonuses[1] += allCards[1][i]._modifierPrimarayVal;
      } else if (allCards[1][i]._cardModifier == uint256(MODIFIER.ALL_DEF)) {
        cumulativeDefenceBonuses[1] += allCards[1][i]._modifierPrimarayVal;
      } else if (allCards[1][i]._cardModifier == uint256(MODIFIER.ALL_ATT_DEF)) {
        cumulativeAttackBonuses[1] += allCards[1][i]._modifierPrimarayVal;
        cumulativeDefenceBonuses[1] += allCards[1][i]._modifierSecondaryVal;
      }

    }
    // we void our bonus if they aren&#39;t all of the type
    if (!allOfSameType[0]) {
      cumulativeAttackBonuses[0] = 0;
      cumulativeDefenceBonuses[0] = 0;
    }
    if (!allOfSameType[1]) {
      cumulativeAttackBonuses[1] = 0;
      cumulativeDefenceBonuses[1] = 0;
    }
    // now add the bonus figures to the initial attack numbers, they will be 0
    // if they either weren&#39;t all of the same type or if no cards actually had
    // the ALL_ modifier
    for (i = 0; i < 3; i++) {
      // for your cards
      allAttackFigures[0][i] += cumulativeAttackBonuses[0];
      allDefenceFigures[0][i] += cumulativeDefenceBonuses[0];

      // ...and your opponents cards
      allAttackFigures[1][i] += cumulativeAttackBonuses[1];
      allDefenceFigures[1][i] += cumulativeDefenceBonuses[1]; 
    }

    //////////////////////////////////////////////////////////////
    // the second modifier that needs to be applied is the V_ATT
    // or the V_DEF mod
    // if the versing card matches the same type listed in the
    // primaryModifierVal, that card will receive the bonus in
    // secondaryModifierVal for att/def
    for (i = 0; i < 3; i++) {

      // start with your cards      
      if (allCards[0][i]._cardModifier == uint256(MODIFIER.V_ATT)) { // versing attack
        // check if the versing cards type matches the primary value
        if (allCards[1][i]._cardType == allCards[0][i]._modifierPrimarayVal) {
          // add the attack bonus (amount is held in the secondary value)
          allAttackFigures[0][i] += allCards[0][i]._modifierSecondaryVal;
        }
      } else if (allCards[0][i]._cardModifier == uint256(MODIFIER.V_DEF)) { // versing defence
        // check if the versing cards type matches the primary value
        if (allCards[1][i]._cardType == allCards[0][i]._modifierPrimarayVal) {
          // add the defence bonus (amount is held in the secondary value)
          allDefenceFigures[0][i] += allCards[0][i]._modifierSecondaryVal;
        }
      }

      // now do the same for your opponent
      if (allCards[1][i]._cardModifier == uint256(MODIFIER.V_ATT)) {
        if (allCards[0][i]._cardType == allCards[1][i]._modifierPrimarayVal) {
          allAttackFigures[1][i] += allCards[1][i]._modifierSecondaryVal;
        }
      } else if (allCards[1][i]._cardModifier == uint256(MODIFIER.V_DEF)) {
        if (allCards[0][i]._cardType == allCards[1][i]._modifierPrimarayVal) {
          allDefenceFigures[1][i] += allCards[1][i]._modifierSecondaryVal;
        }
      }

    }

    //////////////////////////////////////////////////////////////
    // the third modifier that needs to be applied is the type
    // advantage numbers as well as applying R_V (resists versing
    // cards type advantage) and A_I (increases your cards advantage)
    for (i = 0; i < 3; i++) {

      // start with your cards
      // first check if the card we&#39;re versing resists our type advantage
      if (allCards[1][i]._cardModifier != uint256(MODIFIER.R_V)) {
        // test all the possible combinations of advantages
        if (
          // fire vs nature
          (allCards[0][i]._cardType == uint256(TYPE.FIRE) && allCards[1][i]._cardType == uint256(TYPE.NATURE)) ||
          // water vs fire
          (allCards[0][i]._cardType == uint256(TYPE.WATER) && allCards[1][i]._cardType == uint256(TYPE.FIRE)) ||
          // nature vs water
          (allCards[0][i]._cardType == uint256(TYPE.NATURE) && allCards[1][i]._cardType == uint256(TYPE.WATER))
          ) {

          // now check if your card has a type advantage increase modifier
          if (allCards[0][i]._cardModifier != uint256(MODIFIER.A_I)) {
            allAttackFigures[0][i] = SafeMath.div(SafeMath.mul(allAttackFigures[0][i], 3), 2); // x1.5
            allDefenceFigures[0][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[0][i], 3), 2); // x1.5
          } else {
            allAttackFigures[0][i] = SafeMath.div(SafeMath.mul(allAttackFigures[0][i], 5), 4); // x1.25
            allDefenceFigures[0][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[0][i], 5), 4); // x1.25
          }
        }
      }

      // now do the same for your opponent
      if (allCards[0][i]._cardModifier != uint256(MODIFIER.R_V)) {
        if (
          (allCards[1][i]._cardType == uint256(TYPE.FIRE) && allCards[0][i]._cardType == uint256(TYPE.NATURE)) ||
          (allCards[1][i]._cardType == uint256(TYPE.WATER) && allCards[0][i]._cardType == uint256(TYPE.FIRE)) ||
          (allCards[1][i]._cardType == uint256(TYPE.NATURE) && allCards[0][i]._cardType == uint256(TYPE.WATER))
          ) {
          if (allCards[1][i]._cardModifier != uint256(MODIFIER.A_I)) {
            allAttackFigures[1][i] = SafeMath.div(SafeMath.mul(allAttackFigures[1][i], 3), 2); // x1.5
            allDefenceFigures[1][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[1][i], 3), 2); // x1.5
          } else {
            allAttackFigures[1][i] = SafeMath.div(SafeMath.mul(allAttackFigures[1][i], 5), 4); // x1.25
            allDefenceFigures[1][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[1][i], 5), 4); // x1.25
          }
        }
      }

    }

    //////////////////////////////////////////////////////////////
    // the final modifier that needs to be applied is the V_SWAP mod
    // if your card has this modifier, it will swap the final attack
    // and defence numbers of your card
    uint256 tmp;
    for (i = 0; i < 3; i++) {

      // start with your cards
      // check if the versing card has the V_SWAP modifier
      if (allCards[1][i]._cardModifier == uint256(MODIFIER.V_SWAP)) {
        tmp = allAttackFigures[0][i];
        allAttackFigures[0][i] = allDefenceFigures[0][i];
        allDefenceFigures[0][i] = tmp;
      }
      // ...and your opponents cards
      if (allCards[0][i]._cardModifier == uint256(MODIFIER.V_SWAP)) {
        tmp = allAttackFigures[1][i];
        allAttackFigures[1][i] = allDefenceFigures[1][i];
        allDefenceFigures[1][i] = tmp;
      }

    }

    // we&#39;re all done!
    return (allAttackFigures, allDefenceFigures);

  }


  //////////////////////////////////////////////////////////////////////
  //  Getter Functions


  function getCard(address cardAddress) public view returns (uint256 cardIndex, uint256 cardType, uint256 cardModifier, uint256 cardModifierPrimaryVal, uint256 cardModifierSecondaryVal, uint256 attack, uint256 defence, uint256 claimed, uint256 forClaim, uint256 lowestPrice, address claimContender) {

    require(cardAddressExists(cardAddress));

    uint256 index = _indexOf[cardAddress];
    AddressCard memory addressCard = _addressCards[index];
    return (
        index,
        uint256(addressCard._cardType),
        uint256(addressCard._cardModifier),
        uint256(addressCard._modifierPrimarayVal),
        uint256(addressCard._modifierSecondaryVal),
        uint256(addressCard._attack),
        uint256(addressCard._defence),
        uint256(addressCard._claimed),
        uint256(addressCard._forClaim),
        uint256(addressCard._lowestPrice),
        address(addressCard._claimContender)
      );

  }

  function getCheapestCardWager(address cardAddress) public view returns (uint256 cheapestIndex, bool isClaimable, address claimContender, uint256 claimPrice, uint256 wagerCount) {

    require(cardAddressExists(cardAddress));

    uint256 cheapestSale = 0;
    uint256 indexOfCheapestSale = 0;
    uint256 totalWagers = 0;
    uint256[] memory allOwnersClaimPrice = _ownersClaimPriceOf[cardAddress];
    for (uint256 i = 0; i < allOwnersClaimPrice.length; i++) {
      uint256 priceAtIndex = allOwnersClaimPrice[i];
      if (priceAtIndex != 0) {
        totalWagers++;
        if (cheapestSale == 0 || priceAtIndex < cheapestSale) {
          cheapestSale = priceAtIndex;
          indexOfCheapestSale = i;
        }
      }
    }

    return (
        indexOfCheapestSale,
        (cheapestSale > 0),
        (cheapestSale > 0 ? _ownersOf[cardAddress][indexOfCheapestSale] : address(0)),
        cheapestSale,
        totalWagers
      );

  }

  function getOwnerOfCardsCheapestWager(address owner, address cardAddress) public view returns (uint256 cheapestIndex, bool isSelling, uint256 claimPrice, uint256 priceRank, uint256 outOf) {

    bool doesOwn;
    uint256[] memory indexes;
    (doesOwn, indexes) = ownerHasCard(owner, cardAddress);
    require(doesOwn);

    uint256[] memory allOwnersClaimPrice = _ownersClaimPriceOf[cardAddress];
    uint256 cheapestSale = 0;
    uint256 indexOfCheapestSale = 0; // this will handle the case of owner == cardAddress
    if (indexes.length > 0) {
      indexOfCheapestSale = indexes[0]; // defaults to the first index matched
    } else { // also will handle the case of owner == cardAddress
      cheapestSale = allOwnersClaimPrice[0];
    }

    for (uint256 i = 0; i < indexes.length; i++) {
      if (allOwnersClaimPrice[indexes[i]] != 0 && (cheapestSale == 0 || allOwnersClaimPrice[indexes[i]] < cheapestSale)) {
        cheapestSale = allOwnersClaimPrice[indexes[i]];
        indexOfCheapestSale = indexes[i];
      }
    }

    uint256 saleRank = 0;
    uint256 totalWagers = 0;
    if (cheapestSale > 0) {
      saleRank = 1;
      for (i = 0; i < allOwnersClaimPrice.length; i++) {
        if (allOwnersClaimPrice[i] != 0) {
          totalWagers++;
          if (allOwnersClaimPrice[i] < cheapestSale) {
            saleRank++;
          }
        }
      }
    }

    return (
        indexOfCheapestSale,
        (cheapestSale > 0),
        cheapestSale,
        saleRank,
        totalWagers
      );

  }

  function getCardIndexOfOwner(address cardAddress, address owner) public view returns (uint256) {

    require(cardAddressExists(cardAddress));
    require(cardAddressExists(owner));
    require(ownerHasCardSimple(owner, cardAddress));

    uint256 matchedIndex;
    address[] memory cardsOfOwner = _cardsOf[owner];
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      if (cardsOfOwner[i] == cardAddress) {
        matchedIndex = i;
        break;
      }
    }

    return matchedIndex;

  }
  
  function getTotalUniqueCards() public view returns (uint256) {
    return _addressCards.length;
  }
  
  function getAllCardsAddress() public view returns (bytes20[]) {

    bytes20[] memory allCardsAddress = new bytes20[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsAddress[i] = bytes20(addressCard._cardAddress);
    }
    return allCardsAddress;

  }

  function getAllCardsType() public view returns (bytes1[]) {

    bytes1[] memory allCardsType = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsType[i] = bytes1(addressCard._cardType);
    }
    return allCardsType;

  }

  function getAllCardsModifier() public view returns (bytes1[]) {

    bytes1[] memory allCardsModifier = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsModifier[i] = bytes1(addressCard._cardModifier);
    }
    return allCardsModifier;

  }

  function getAllCardsModifierPrimaryVal() public view returns (bytes1[]) {

    bytes1[] memory allCardsModifierPrimaryVal = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsModifierPrimaryVal[i] = bytes1(addressCard._modifierPrimarayVal);
    }
    return allCardsModifierPrimaryVal;

  }

  function getAllCardsModifierSecondaryVal() public view returns (bytes1[]) {

    bytes1[] memory allCardsModifierSecondaryVal = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsModifierSecondaryVal[i] = bytes1(addressCard._modifierSecondaryVal);
    }
    return allCardsModifierSecondaryVal;

  }

  function getAllCardsAttack() public view returns (bytes1[]) {

    bytes1[] memory allCardsAttack = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsAttack[i] = bytes1(addressCard._attack);
    }
    return allCardsAttack;

  }

  function getAllCardsDefence() public view returns (bytes1[]) {

    bytes1[] memory allCardsDefence = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsDefence[i] = bytes1(addressCard._defence);
    }
    return allCardsDefence;

  }

  function getAllCardsClaimed() public view returns (bytes1[]) {

    bytes1[] memory allCardsClaimed = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsClaimed[i] = bytes1(addressCard._claimed);
    }
    return allCardsClaimed;

  }

  function getAllCardsForClaim() public view returns (bytes1[]) {

    bytes1[] memory allCardsForClaim = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsForClaim[i] = bytes1(addressCard._forClaim);
    }
    return allCardsForClaim;

  }

  function getAllCardsLowestPrice() public view returns (bytes32[]) {

    bytes32[] memory allCardsLowestPrice = new bytes32[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsLowestPrice[i] = bytes32(addressCard._lowestPrice);
    }
    return allCardsLowestPrice;

  }

  function getAllCardsClaimContender() public view returns (bytes4[]) {

    // returns the indexes of the claim contender
    bytes4[] memory allCardsClaimContender = new bytes4[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsClaimContender[i] = bytes4(_indexOf[addressCard._claimContender]);
    }
    return allCardsClaimContender;

  }

  function getAllOwnersOfCard(address cardAddress) public view returns (bytes4[]) {
    
    require(cardAddressExists(cardAddress));

    // returns the indexes of the owners
    address[] memory ownersOfCardAddress = _ownersOf[cardAddress];
    bytes4[] memory allOwners = new bytes4[](ownersOfCardAddress.length);
    for (uint256 i = 0; i < ownersOfCardAddress.length; i++) {
      allOwners[i] = bytes4(_indexOf[ownersOfCardAddress[i]]);
    }
    return allOwners;

  }

  function getAllOwnersClaimPriceOfCard(address cardAddress) public view returns (bytes32[]) {
    
    require(cardAddressExists(cardAddress));

    uint256[] memory ownersClaimPriceOfCardAddress = _ownersClaimPriceOf[cardAddress];
    bytes32[] memory allOwnersClaimPrice = new bytes32[](ownersClaimPriceOfCardAddress.length);
    for (uint256 i = 0; i < ownersClaimPriceOfCardAddress.length; i++) {
      allOwnersClaimPrice[i] = bytes32(ownersClaimPriceOfCardAddress[i]);
    }
    return allOwnersClaimPrice;

  }

  function getAllCardAddressesOfOwner(address owner) public view returns (bytes4[]) {
    
    require(cardAddressExists(owner));

    // returns the indexes of the cards owned
    address[] memory cardsOfOwner = _cardsOf[owner];
    bytes4[] memory allCardAddresses = new bytes4[](cardsOfOwner.length);
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      allCardAddresses[i] = bytes4(_indexOf[cardsOfOwner[i]]);
    }
    return allCardAddresses;

  }

  function getAllCardAddressesCountOfOwner(address owner) public view returns (bytes1[]) {
    
    require(cardAddressExists(owner));

    address[] memory cardsOfOwner = _cardsOf[owner];
    bytes1[] memory allCardAddressesCount = new bytes1[](cardsOfOwner.length);
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      allCardAddressesCount[i] = bytes1(ownerCountOfCard(owner, cardsOfOwner[i]));
    }
    return allCardAddressesCount;

  }


  //////////////////////////////////////////////////////////////////////
  
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (ie if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}