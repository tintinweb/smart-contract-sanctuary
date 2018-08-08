pragma solidity
^0.4.21;

/*
http://www.cryptophoenixes.fun/
CryptoPhoenixes: Civil War Edition

Original game design and website development by Anyhowclick.
Art design by Tilly.
*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

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
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CryptoPhoenixesCivilWar is Ownable, Pausable {
  using SafeMath for uint256;

  address public subDevOne;
  address public subDevTwo;
  
  Phoenix[] public PHOENIXES;
  /*
  id 0: Rainbow Phoenix
  ids 1-2: Red / Blue capt respectively
  ids 3-6: Red bombers
  ids 7-10: Red thieves
  ids 11-14: Blue bombers
  ids 15-18: Blue thieves
  */
  
  uint256 public DENOMINATOR = 10000; //Eg explosivePower = 300 -> 3%
  
  uint256[2] public POOLS; //0 = red, 1 = blue
  uint256[2] public SCORES; //0 = red, 1 = blue
  
  bool public GAME_STARTED = false;
  uint public GAME_END = 0;
  
  // devFunds
  mapping (address => uint256) public devFunds;

  // userFunds
  mapping (address => uint256) public userFunds;

  // Constant
  uint256 constant public BASE_PRICE = 0.0025 ether;
  
  //Permission control
  modifier onlyAuthorized() {
      require(msg.sender == owner || msg.sender == subDevOne); //subDevTwo is NOT authorized
      _;
  }
  
  //to check that a game has ended
  modifier gameHasEnded() {
      require(GAME_STARTED); //Check if a game was started in the first place
      require(now >= GAME_END); //Check if game has ended
      _;
  }
  
  //to check that a game is in progress
  modifier gameInProgress() {
      require(GAME_STARTED);
      require(now <= GAME_END);
      _;
  }
  
  //to check the reverse, that no game is in progress
  modifier noGameInProgress() {
      require(!GAME_STARTED);
      _;
  }
  
  // Events
  event GameStarted();
      
  event PhoenixPurchased(
      uint256 phoenixID,
      address newOwner,
      uint256 price,
      uint256 nextPrice,
      uint256 currentPower,
      uint abilityAvailTime
  );

  event CaptainAbilityUsed(
      uint256 captainID
  );
  
  event PhoenixAbilityUsed(
      uint256 phoenixID,
      uint256 payout,
      uint256 price,
      uint256 currentPower,
      uint abilityAvailTime,
      address previousOwner
  );
  
  event GameEnded();

  event WithdrewFunds(
    address owner
  );
  
  // Struct to store Phoenix Data
  struct Phoenix {
    uint256 price;  // Current price of phoenix
    uint256 payoutPercentage; // The percent of the funds awarded upon explosion / steal / end game
    uint abilityAvailTime; // Time when phoenix&#39;s ability is available
    uint cooldown; // Time to add after cooldown
    uint cooldownDecreaseAmt; // Amt of time to decrease upon each flip
    uint basePower; // Starting exploding / stealing power of phoenix
    uint currentPower; // Current exploding / stealing power of phoenix
    uint powerIncreaseAmt; // Amt of power to increase with every flip
    uint powerDrop; // Power drop of phoenix upon ability usage
    uint powerCap; // Power should not exceed this amount
    address previousOwner;  // Owner of phoenix in previous round
    address currentOwner; // Current owner of phoenix
  }
  
// Main function to set the beta period and sub developer
  function CryptoPhoenixesCivilWar(address _subDevOne, address _subDevTwo) {
    subDevOne = _subDevOne;
    subDevTwo = _subDevTwo;
    createPhoenixes();
  }

  function createPhoenixes() private {
      //First, create rainbow phoenix and captains
      for (uint256 i = 0; i < 3; i++) {
          Phoenix memory phoenix = Phoenix({
              price: 0.005 ether,
              payoutPercentage: 2400, //redundant for rainbow phoenix. Set to 24% for captains
              cooldown: 20 hours, //redundant for rainbow phoenix
              abilityAvailTime: 0, //will be set when game starts
              //Everything else not used
              cooldownDecreaseAmt: 0,
              basePower: 0,
              currentPower: 0,
              powerIncreaseAmt: 0,
              powerDrop: 0,
              powerCap: 0,
              previousOwner: address(0),
              currentOwner: address(0)
          });
          
          PHOENIXES.push(phoenix);
      }
      
      //set rainbow phoenix price to 0.01 ether
      PHOENIXES[0].price = 0.01 ether;
      
      //Now, for normal phoenixes
      uint16[4] memory PAYOUTS = [400,700,1100,1600]; //4%, 7%, 11%, 16%
      uint16[4] memory COOLDOWN = [2 hours, 4 hours, 8 hours, 16 hours];
      uint16[4] memory COOLDOWN_DECREASE = [9 minutes, 15 minutes, 26 minutes, 45 minutes];
      uint8[4] memory POWER_INC_AMT = [25,50,100,175]; //0.25%, 0.5%, 1%, 1.75%
      uint16[4] memory POWER_DROP = [150,300,600,1000]; //1.5%, 3%, 6%, 10%
      uint16[4] memory CAPPED_POWER = [800,1500,3000,5000]; //8%, 15%, 30%, 50%
      
      
      for (i = 0; i < 4; i++) {
          for (uint256 j = 0; j < 4; j++) {
              phoenix = Phoenix({
              price: BASE_PRICE,
              payoutPercentage: PAYOUTS[j],
              abilityAvailTime: 0,
              cooldown: COOLDOWN[j],
              cooldownDecreaseAmt: COOLDOWN_DECREASE[j],
              basePower: (j+1)*100, //100, 200, 300, 400 = 1%, 2%, 3%, 4%
              currentPower: (j+1)*100,
              powerIncreaseAmt: POWER_INC_AMT[j],
              powerDrop: POWER_DROP[j],
              powerCap: CAPPED_POWER[j],
              previousOwner: address(0),
              currentOwner: address(0)
              });
              
              PHOENIXES.push(phoenix);
          }
      }
  }
  
  function startGame() public noGameInProgress onlyAuthorized {
      //reset scores
      SCORES[0] = 0;
      SCORES[1] = 0;
      
      //reset normal phoenixes&#39; abilityAvailTimes
      for (uint i = 1; i < 19; i++) {
          PHOENIXES[i].abilityAvailTime = now + PHOENIXES[i].cooldown;
      }
      
      GAME_STARTED = true;
      //set game duration to be 1 day
      GAME_END = now + 1 days;
      emit GameStarted();
  }
  
  //Set bag holders from version 1.0
  function setPhoenixOwners(address[19] _owners) onlyOwner public {
      require(PHOENIXES[0].previousOwner == address(0)); //Just need check once
      for (uint256 i = 0; i < 19; i++) {
          Phoenix storage phoenix = PHOENIXES[i];
          phoenix.previousOwner = _owners[i];
          phoenix.currentOwner = _owners[i];
      }
  }

function purchasePhoenix(uint256 _phoenixID) whenNotPaused gameInProgress public payable {
      //checking prerequisite
      require(_phoenixID < 19);
    
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      //Get current price of phoenix
      uint256 price = phoenix.price;
      
      //checking more prerequisites
      require(phoenix.currentOwner != address(0)); //check if phoenix was initialised
      require(msg.value >= phoenix.price);
      require(phoenix.currentOwner != msg.sender); //prevent consecutive purchases
      
      uint256 outgoingOwnerCut;
      uint256 purchaseExcess;
      uint256 poolCut;
      uint256 rainbowCut;
      uint256 captainCut;
      
      (outgoingOwnerCut, 
      purchaseExcess, 
      poolCut,
      rainbowCut,
      captainCut) = calculateCuts(msg.value,price);
      
      //give 1% for previous owner, abusing variable name here
      userFunds[phoenix.previousOwner] = userFunds[phoenix.previousOwner].add(captainCut); 
      
      //If purchasing rainbow phoenix, give the 2% rainbowCut and 1% captainCut to outgoingOwner
      if (_phoenixID == 0) {
          outgoingOwnerCut = outgoingOwnerCut.add(rainbowCut).add(captainCut);
          rainbowCut = 0; //necessary to set to zero since variable is used for other cases
          poolCut = poolCut.div(2); //split poolCut equally into 2, distribute to both POOLS
          POOLS[0] = POOLS[0].add(poolCut); //add pool cut to red team
          POOLS[1] = POOLS[1].add(poolCut); //add pool cut to blue team
          
      } else if (_phoenixID < 3) { //if captain, return 1% captainCut to outgoingOwner
          outgoingOwnerCut = outgoingOwnerCut.add(captainCut);
          uint256 poolID = _phoenixID.sub(1); //1 --> 0, 2--> 1 (detemine which pool to add pool cut to)
          POOLS[poolID] = POOLS[poolID].add(poolCut);
          
      } else if (_phoenixID < 11) { //for normal red phoenixes, set captain and adjust stats
          //transfer 1% captainCut to red captain
          userFunds[PHOENIXES[1].currentOwner] = userFunds[PHOENIXES[1].currentOwner].add(captainCut);
          upgradePhoenixStats(_phoenixID);
          POOLS[0] = POOLS[0].add(poolCut); //add pool cut to red team
      } else {
          //transfer 1% captainCut to blue captain
          userFunds[PHOENIXES[2].currentOwner] = userFunds[PHOENIXES[2].currentOwner].add(captainCut);
          upgradePhoenixStats(_phoenixID);
          POOLS[1] = POOLS[1].add(poolCut); //add pool cut to blue team
      }
      
      //transfer rainbowCut to rainbow phoenix owner
      userFunds[PHOENIXES[0].currentOwner] = userFunds[PHOENIXES[0].currentOwner].add(rainbowCut);

      // set new price
      phoenix.price = getNextPrice(price);
      
      // send funds to old owner 
      sendFunds(phoenix.currentOwner, outgoingOwnerCut);
    
      // set new owner
      phoenix.currentOwner = msg.sender;

      // Send refund to owner if needed
      if (purchaseExcess > 0) {
        sendFunds(msg.sender,purchaseExcess);
      }
      
      // raise event
      emit PhoenixPurchased(_phoenixID, msg.sender, price, phoenix.price, phoenix.currentPower, phoenix.abilityAvailTime);
  }
  
  function calculateCuts(
      uint256 _amtPaid,
      uint256 _price
      )
      private
      returns (uint256 outgoingOwnerCut, uint256 purchaseExcess, uint256 poolCut, uint256 rainbowCut, uint256 captainCut)
      {
      outgoingOwnerCut = _price;
      purchaseExcess = _amtPaid.sub(_price);
      
      //Take 5% cut from excess
      uint256 excessPoolCut = purchaseExcess.div(20); //5%, will be added to poolCut
      purchaseExcess = purchaseExcess.sub(excessPoolCut);
      
      //3% of price to devs
      uint256 cut = _price.mul(3).div(100); //3%
      outgoingOwnerCut = outgoingOwnerCut.sub(cut);
      distributeDevCut(cut);
      
      //1% of price to owner in previous round, 1% to captain (if applicable)
      //abusing variable name to use for previous owner and captain fees, since they are the same
      captainCut = _price.div(100); //1%
      outgoingOwnerCut = outgoingOwnerCut.sub(captainCut).sub(captainCut); //subtract twice, reason as explained
      
      //2% of price to rainbow (if applicable)
      rainbowCut = _price.mul(2).div(100); //2%
      outgoingOwnerCut = outgoingOwnerCut.sub(rainbowCut);
      
      //11-13% of price will go to the respective team pools
      poolCut = calculatePoolCut(_price);
      outgoingOwnerCut = outgoingOwnerCut.sub(poolCut);
      /*
      add the poolCut and excessPoolCut together
      so poolCut = 11-13% of price + 5% of purchaseExcess
      */
      poolCut = poolCut.add(excessPoolCut);
  }
  
  function distributeDevCut(uint256 _cut) private {
      devFunds[owner] = devFunds[owner].add(_cut.div(2)); //50% to owner
      devFunds[subDevOne] = devFunds[subDevOne].add(_cut.div(4)); //25% to subDevOne
      devFunds[subDevTwo] = devFunds[subDevTwo].add(_cut.div(4)); //25% to subDevTwo
  }
  
/**
  * @dev Determines next price of phoenix
*/
  function getNextPrice (uint256 _price) private pure returns (uint256 _nextPrice) {
    if (_price < 0.25 ether) {
      return _price.mul(3).div(2); //1.5x
    } else if (_price < 1 ether) {
      return _price.mul(14).div(10); //1.4x
    } else {
      return _price.mul(13).div(10); //1.3x
    }
  }
  
  function calculatePoolCut (uint256 _price) private pure returns (uint256 poolCut) {
      if (_price < 0.25 ether) {
          poolCut = _price.mul(13).div(100); //13%
      } else if (_price < 1 ether) {
          poolCut = _price.mul(12).div(100); //12%
      } else {
          poolCut = _price.mul(11).div(100); //11%
      }
  }
 
  function upgradePhoenixStats(uint256 _phoenixID) private {
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      //increase current power of phoenix
      phoenix.currentPower = phoenix.currentPower.add(phoenix.powerIncreaseAmt);
      //handle boundary case where current power exceeds cap
      if (phoenix.currentPower > phoenix.powerCap) {
          phoenix.currentPower = phoenix.powerCap;
      }
      //decrease cooldown of phoenix
      //no base case to take care off. Time shouldnt decrease too much to ever reach zero
      phoenix.abilityAvailTime = phoenix.abilityAvailTime.sub(phoenix.cooldownDecreaseAmt);
  }
  
  function useCaptainAbility(uint256 _captainID) whenNotPaused gameInProgress public {
      require(_captainID > 0 && _captainID < 3); //either 1 or 2
      Phoenix storage captain = PHOENIXES[_captainID];
      require(msg.sender == captain.currentOwner); //Only owner of captain can use ability
      require(now >= captain.abilityAvailTime); //Ability must be available for use
      
      if (_captainID == 1) { //red team
          uint groupIDStart = 3; //Start index of _groupID in PHOENIXES
          uint groupIDEnd = 11; //End index (excluding) of _groupID in PHOENIXES
      } else {
          groupIDStart = 11; 
          groupIDEnd = 19; 
      }
      
      for (uint i = groupIDStart; i < groupIDEnd; i++) {
          //Multiply team power by 1.5x
          PHOENIXES[i].currentPower = PHOENIXES[i].currentPower.mul(3).div(2); 
          //ensure cap not breached
          if (PHOENIXES[i].currentPower > PHOENIXES[i].powerCap) {
              PHOENIXES[i].currentPower = PHOENIXES[i].powerCap;
          }
      }
      
      captain.abilityAvailTime = GAME_END + 10 seconds; //Prevent ability from being used again in current round
      
      emit CaptainAbilityUsed(_captainID);
  }
  
  function useAbility(uint256 _phoenixID) whenNotPaused gameInProgress public {
      //phoenixID must be between 3 to 18
      require(_phoenixID > 2);
      require(_phoenixID < 19);
      
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      require(msg.sender == phoenix.currentOwner); //Only owner of phoenix can use ability
      require(now >= phoenix.abilityAvailTime); //Ability must be available for use

      //calculate which pool to take from
      //ids 3-6, 15-18 --> red
      //ids 7-14 --> blue
      if (_phoenixID >=7 &&  _phoenixID <= 14) {
          require(POOLS[1] > 0); //blue pool
          uint256 payout = POOLS[1].mul(phoenix.currentPower).div(DENOMINATOR); //calculate payout
          POOLS[1] = POOLS[1].sub(payout); //subtract from pool
      } else {
          require(POOLS[0] > 0); //red pool
          payout = POOLS[0].mul(phoenix.currentPower).div(DENOMINATOR);
          POOLS[0] = POOLS[0].sub(payout);
      }
      
      //determine which team the phoenix is on
      if (_phoenixID < 11) { //red team
          bool isRed = true; //to determine which team to distribute the 9% payout to
          SCORES[0] = SCORES[0].add(payout); //add payout to score (ie. payout is the score)
      } else {
          //blue team
          isRed = false;
          SCORES[1] = SCORES[1].add(payout);
      }
      
      uint256 ownerCut = payout;
      
      //drop power of phoenix
      decreasePower(_phoenixID);
      
      //decrease phoenix price
      decreasePrice(_phoenixID);
      
      //reset cooldown
      phoenix.abilityAvailTime = now + phoenix.cooldown;

      // set previous owner to be current owner, so he can get the 1% dividend from subsequent purchases
      phoenix.previousOwner = msg.sender;
      
      // Calculate the different cuts
      // 2% to rainbow
      uint256 cut = payout.div(50); //2%
      ownerCut = ownerCut.sub(cut);
      userFunds[PHOENIXES[0].currentOwner] = userFunds[PHOENIXES[0].currentOwner].add(cut);
      
      // 1% to dev
      cut = payout.div(100); //1%
      ownerCut = ownerCut.sub(cut);
      distributeDevCut(cut);
      
      //9% to team
      cut = payout.mul(9).div(100); //9%
      ownerCut = ownerCut.sub(cut);
      distributeTeamCut(isRed,cut);
      
      //Finally, send money to user
      sendFunds(msg.sender,ownerCut);
      
      emit PhoenixAbilityUsed(_phoenixID,ownerCut,phoenix.price,phoenix.currentPower,phoenix.abilityAvailTime,phoenix.previousOwner);
  }
  
  function decreasePrice(uint256 _phoenixID) private {
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      if (phoenix.price >= 0.75 ether) {
        phoenix.price = phoenix.price.mul(20).div(100); //drop to 20%
      } else {
        phoenix.price = phoenix.price.mul(10).div(100); //drop to 10%
        if (phoenix.price < BASE_PRICE) {
          phoenix.price = BASE_PRICE;
          }
      }
  }
  
  function decreasePower(uint256 _phoenixID) private {
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      phoenix.currentPower = phoenix.currentPower.sub(phoenix.powerDrop);
      //handle boundary case where currentPower is below basePower
      if (phoenix.currentPower < phoenix.basePower) {
          phoenix.currentPower = phoenix.basePower; 
      }
  }
  
  function distributeTeamCut(bool _isRed, uint256 _cut) private {
      /* 
      Note that captain + phoenixes payout percentages add up to 100%.
      Captain: 24%
      Phoenix 1 & 5: 4% x 2 = 8%
      Phoenix 2 & 6: 7% x 2 = 14%
      Phoenix 3 & 7: 11% x 2 = 22%
      Phoenix 4 & 8: 16% x 2 = 32%
      */
      
      if (_isRed) {
          uint captainID = 1;
          uint groupIDStart = 3;
          uint groupIDEnd = 11;
      } else {
          captainID = 2;
          groupIDStart = 11;
          groupIDEnd = 19;
      }
      
      //calculate and transfer capt payout
      uint256 payout = PHOENIXES[captainID].payoutPercentage.mul(_cut).div(DENOMINATOR);
      userFunds[PHOENIXES[captainID].currentOwner] = userFunds[PHOENIXES[captainID].currentOwner].add(payout);
      
      for (uint i = groupIDStart; i < groupIDEnd; i++) {
          //calculate how much to pay to each phoenix owner in the team
          payout = PHOENIXES[i].payoutPercentage.mul(_cut).div(DENOMINATOR);
          //transfer payout
          userFunds[PHOENIXES[i].currentOwner] = userFunds[PHOENIXES[i].currentOwner].add(payout);
      }
  }
  
  function endGame() gameHasEnded public {
      GAME_STARTED = false; //to allow this function to only be called once after the end of every round
      uint256 remainingPoolAmt = POOLS[0].add(POOLS[1]); //add the 2 pools together
      
      //Distribution structure -> 15% rainbow, 75% teams, 10% for next game
      uint256 rainbowCut = remainingPoolAmt.mul(15).div(100); //15% to rainbow
      uint256 teamCut = remainingPoolAmt.mul(75).div(100); //75% to teams
      remainingPoolAmt = remainingPoolAmt.sub(rainbowCut).sub(teamCut);
      
      //distribute 15% to rainbow phoenix owner
      userFunds[PHOENIXES[0].currentOwner] = userFunds[PHOENIXES[0].currentOwner].add(rainbowCut);
      
      //distribute 75% to teams
      //in the unlikely event of a draw, split evenly, so 37.5% cut to each team
      if (SCORES[0] == SCORES[1]) {
          teamCut = teamCut.div(2);
          distributeTeamCut(true,teamCut); //redTeam
          distributeTeamCut(false,teamCut); //blueTeam
      } else {
          //25% to losing team
          uint256 losingTeamCut = teamCut.div(3); // 1 third of 75% = 25%
          //SCORES[0] = red, SCORES[1] = blue
          //if red > blue, then award to redTeam, so bool _isRed = red > blue
          distributeTeamCut((SCORES[0] > SCORES[1]),losingTeamCut);
          
          //50% to winning team
          teamCut = teamCut.sub(losingTeamCut); //take the remainder
          //inverse of the winning condition
          distributeTeamCut(!(SCORES[0] > SCORES[1]),teamCut); 
      }
      
      // 5% to each pool for next game
      POOLS[0] = remainingPoolAmt.div(2);
      POOLS[1] = POOLS[0];
      
      resetPhoenixes();
      emit GameEnded();
  }
  
  function resetPhoenixes() private {
      //reset attributes of phoenixes
      PHOENIXES[0].price = 0.01 ether;
      PHOENIXES[1].price = 0.005 ether;
      PHOENIXES[2].price = 0.005 ether;
      
      for (uint i = 0; i < 3; i++) {
          PHOENIXES[i].previousOwner = PHOENIXES[i].currentOwner;
      }
      
      for (i = 3; i < 19; i++) {
          //Reset price and power levels of phoenixes
          //Ability time will be set during game start
          Phoenix storage phoenix = PHOENIXES[i];
          phoenix.price = BASE_PRICE;
          phoenix.currentPower = phoenix.basePower;
          phoenix.previousOwner = phoenix.currentOwner;
      }
  }
  
/**
* @dev Try to send funds immediately
* If it fails, user has to manually withdraw.
*/
  function sendFunds(address _user, uint256 _payout) private {
    if (!_user.send(_payout)) {
      userFunds[_user] = userFunds[_user].add(_payout);
    }
  }

/**
* @dev Withdraw dev cut.
*/
  function devWithdraw() public {
    uint256 funds = devFunds[msg.sender];
    require(funds > 0);
    devFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
  }

/**
* @dev Users can withdraw their funds
*/
  function withdrawFunds() public {
    uint256 funds = userFunds[msg.sender];
    require(funds > 0);
    userFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
    emit WithdrewFunds(msg.sender);
  }

/**
* @dev Transfer contract balance in case of bug or contract upgrade
*/ 
 function upgradeContract(address _newContract) public onlyOwner whenPaused {
        _newContract.transfer(address(this).balance);
 }
}