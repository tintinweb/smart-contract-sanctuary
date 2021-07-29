pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PharoPhactory.sol";


// Goal is to 
contract ConstitutePharo is PharoPhactory {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Updateable by the DAO
  uint256 public pharoFee = 800;

  IERC20 private _pharoToken;
  //IERC20 public stablecoin;

  using Counters for Counters.Counter;

  // let's keep track internally of all the Pharo id's
  Counters.Counter private _pharoIds;


  struct Event {
      address creator;
      string eventType;
      EventStatus eventStatus;
      Pharo pharo;
  }

  mapping(address => Event) creatorToEvent;
  mapping(string => Event) eventHashToEvent;
  mapping(string => Event) eventDict;


  constructor(IERC20 pharoToken)
    public
  {
      pharoToken = _pharoToken;
      transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
  }

  function updatePharoFee(uint256 _newFee)
    public
    onlyOwner
  {
    pharoFee = _newFee;
  }


  /// @notice Creates the event hash
  /// @dev Before a Pharo can be created it will need this hash
  ///      we may want more attributes to generate the hash??
  /// @param _name the name of the event
  /// @param _eventCreatorAddress the address of the event creator
  /// @param _eventType the event type
  /// @return the eventHash
  function getEventHash(string memory _name, address _eventCreatorAddress, string memory _eventType)
    public
    pure
    returns(bytes32)
  {
    bytes32 hashedValue = keccak256(abi.encodePacked(_name, _eventCreatorAddress, _eventType));
    //string memory stringValue = string(hashedValue);
    return hashedValue;
  }

  /// @dev Converts bytes32 to a string
  function bytes32ToString(bytes32 _bytes32)
    public
    pure
    returns (string memory)
  {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
  }

  /// @notice Creates a new Pharo in Mummy state
  /// @dev also creates the Pharo and the Event.
  /// @param _fee the fee
  function createNewPharo(
    //string memory _eventHash, 
    uint256 _fee,  // fee will be paid in PHRO tokens
    string memory _name, 
    string memory _description,
    string memory _eventType,
    address _creatorAddress,
    uint256 _lengthOfTime,
    address _asset
  )
    public
  {
    require(_fee >= pharoFee, "ConstitutePharo:: not enough for fee");
    require(_creatorAddress != address(0), "ConstitutePharo:: 0 address not allowed");

    // get an event hash
    bytes32 eventHash = getEventHash(_name, _creatorAddress, _eventType);
    string memory stringHash = bytes32ToString(eventHash);

    // increment id for the new Pharo id
    _pharoIds.increment();

    // transfer the fee from the market manager or user
    _pharoToken.transferFrom(msg.sender, address(this), _fee);

    // Create a new Pharo object tracked by the event hash
    Pharo storage pharo = eventHashToPharo[string(stringHash)];
    pharo.birthday = block.timestamp; // the birthday will be set on pharo creation
    pharo.eventHash = stringHash; // the event hash
    pharo.id = _pharoIds.current();
    pharo.nftId = _pharoIds.current();
    pharo.state = PharoState.MUMMY; // set the Pharo to be in Mummy state
    pharo.name = _name; // name of the Pharo
    uint256[] memory sOdds;
    pharo.sortedOdds = sOdds; // empty uint256 array to hold the sorted odds tranches
    pharo.lifetime = _lengthOfTime; // How long the Pharo lives...
    // initialise buyersCount with 0 value since there are no buyers yet on pharo creation
    pharo.pharoBuyerCount[stringHash] = 0;
    // initialise pharoProvidersCount with 0
    pharo.pharoProviderCount[stringHash] = 0;
    // initialise pharoBuyIns with 0
    pharo.pharoBuyInCount[stringHash] = 0;

    // FIX: consolidate these two? :XIF \\
    pharoDict[stringHash] = pharo;
    //eventHashToPharo[stringHash] = pharo;
    pharoList.push(pharo);

    _addEvent(stringHash, _eventType, _creatorAddress);

    emit EventCreated(_eventType, EventStatus.Active, pharo.id, stringHash);
    emit MummyCreated(stringHash, _name, block.timestamp);
  }

  /// @notice Explain to an end user what this does
  /// @dev Explain to a developer any extra details
  /// @param _eventHash the event hash
  function _addEvent(string memory _eventHash, string memory _eventType, address _creator)
    internal
  {
    // create the event
    Event storage newEvent = eventHashToEvent[_eventHash];
    newEvent.creator = _creator;
    newEvent.eventType = _eventType;
    newEvent.eventStatus = EventStatus.Pending;

    eventDict[_eventHash] = newEvent;
  }

  function endEvent(string memory _eventHash)
    public 
  {
    // What happens when an event ends?
    // 1. Pharo becomes Anubis for payouts
    // 2. Funds are dispursed based on outcome of event
    //  a. get the outcome of the event using the eventHash
    EventStatus eventStatus = _closeEvent(_eventHash);

  }

  function triggerEvent(string memory _eventHash, EventStatus _eventStatus)
    internal
    returns(EventStatus)
  {
    Event storage theEvent = eventDict[_eventHash];

    // trigger event too payout
    theEvent.eventStatus = EventStatus.Triggered;
    
    return EventStatus.Triggered;
  }

  function _closeEvent(string memory _eventHash)
    internal
    returns(EventStatus)
  {
    Event storage theEvent = eventDict[_eventHash];

    // trigger event too payout
    theEvent.eventStatus = EventStatus.Closed;
    
    return EventStatus.Closed;
  }

  function setOdds(address _providerAddress, string memory _eventHash, uint256 _over, uint256 _under)
    public
  {

  }



  // We need to know the type of token they are sending.. Should we just
  // start with Matic native token?
  // Can we make this payable to have access to msg.value for native?


  /// @notice Add new buyer
  /// @dev Adds the new buyer
  /// @param _eventHash the event hash
  /// @return Buyer
  function addNewCoverBuyer(string memory _eventHash)
    public
    payable
    returns(Buyer memory)
  {
    // 1. add the buyer's money to the Pharo Buyer pool
    Buyer storage buyer = eventHashToBuyer[_eventHash];
    buyer.buyerAddress = msg.sender;
    buyer.buyerPhroBalance = 0; // let's get the actual balance here

    // 2. add the buyer to the Pharo data struct
    Pharo storage pharo = pharoDict[_eventHash];

    // **SMG** we can add the buyers to both buyers
    // lists in the pharo struct and the buyers below.
    pharo.buyerList.push(buyer);
    buyers.push(buyer);
    // the buyerList needs to be the set of unique buyers.
    // This is different than the pharoDict[eventHash].buyInList as that tracks 
    // each FIFO buyer for tranche payments
       
    pharoDict[_eventHash].buyers[_eventHash] = buyer;
    pharoDict[_eventHash].pharoBuyInCount[_eventHash] += 1;

    // 3. trigger state balancing. 
    //updateProviderTranches(_eventHash);
    //updateBuyerTranches(_eventHash);

    emit BuyerCreated(msg.sender, msg.value);

    return buyer;
  }


  function _buyIn(string memory eventHash, address buyerAddress, uint256 amount)
    internal 
  {
    BuyIn storage newBuyIn = eventHashToBuyIn[eventHash];
    newBuyIn.buyerAddress = msg.sender;
    newBuyIn.staked = amount;
    // todo: newBuyIn.tranches = ...
    
    uint256 xx = pharoDict[eventHash].pharoBuyInCount[eventHash] + 1;
    uint256[] memory tranches;
    tranches[0] = 0;
    pharoDict[eventHash].pharoBuyIns[0][xx] = newBuyIn;
    eventHashToBuyIn[eventHash] = pharoDict[eventHash].pharoBuyIns[0][xx];
    pharoDict[eventHash].pharoBuyInCount[eventHash] = xx;
  }



  function addNewProviderERC20(
    address _providerAddress,
    string memory _eventHash,
    uint256 _odds,
    uint256 _amount,
    address _token
  )
    public
    returns(Provider memory)
  {
    Pharo storage pharo = pharoDict[_eventHash];
    IERC20 incomingToken = IERC20(_token);

    setOdds(_providerAddress, _eventHash, _odds, 1);

    Provider storage provider = addressToProvider[_providerAddress];
    provider.staked = _amount;
    provider.odds = _odds;
    provider.asset = _token;
    provider.providerAddress = _providerAddress;
    eventHashToProvider[_eventHash] = provider;
    providers.push(provider);
    // add the provider to the pharoDict
    pharo.providerList.push(provider);

    uint xx = pharoDict[_eventHash].pharoProviderCount[_eventHash] + 1;
    pharoDict[_eventHash].pharoProviders[0][xx] = provider;

    //updateProviderTranches(_eventHash);
    //updateBuyerTranches(_eventHash);

    incomingToken.transferFrom(_providerAddress, address(this), _amount);

    emit ProviderCreated(msg.sender, _odds, _amount);

    return provider;

  }


  function addNewProviderEth(address _providerAddress, string memory _eventHash, uint256 _odds)
    public
    payable
    returns(Provider memory)
  {
    // 1. Constiture Pharo with provider info
    // Pharo has already been created in previous steps
    Pharo storage pharo = pharoDict[_eventHash];
    
    // set pharo values
    setOdds(_providerAddress, _eventHash, _odds, 1);

    // 2. add the LP to the Pharo data struct and trigger state balancing
    // if odds are covered we can raise this mummy to a pharo
    // Add LP to a Pharo? Done by state transition functions?

    Provider storage provider = addressToProvider[_providerAddress];
    provider.staked = msg.value;
    provider.odds = _odds;
    provider.providerAddress = _providerAddress;
    eventHashToProvider[_eventHash] = provider;
    providers.push(provider);
    // add the provider to the pharoDict
    pharo.providerList.push(provider);

    uint xx = pharoDict[_eventHash].pharoProviderCount[_eventHash] + 1;
    pharoDict[_eventHash].pharoProviders[0][xx] = provider;

    //updateProviderTranches(_eventHash);
    //updateBuyerTranches(_eventHash);

    msg.sender.transfer(msg.value);

    emit ProviderCreated(msg.sender, _odds, msg.value);

    return provider;
  }

  function _liquidityIn(string memory eventHash, address providerAddress, uint amount, uint odds, address asset)
    internal 
  {
    uint256 xx = pharoDict[eventHash].pharoProviderCount[eventHash] +1;
    uint[] memory tranches;
    tranches[0] = 0;
    pharoDict[eventHash].pharoProviders[0][xx] = Provider(providerAddress, odds, amount, asset);
    eventHashToProvider[eventHash] = pharoDict[eventHash].pharoProviders[0][xx];
    pharoDict[eventHash].pharoProviderCount[eventHash] = xx;
  }

  // event CoverPurchased(address buyer, uint256 eventId, uint256 coverId, uint256 amount);

  // -------------- STATE TRANSITIONS -------------- //

  function transitionMummy2Pharo(string memory _eventHash) 
    public 
  {
    // As a Mummy, the Pharo is undead because the LPs are not covering the exposure.
    Pharo storage pharo = pharoDict[_eventHash];
    require(pharo.state == PharoState.MUMMY, "Must be Mummy to transition to Imhotep");
    pharo.state = PharoState.PHARO;
  }

  function transitionPharoToImhotep(string memory _eventHash) 
    public  
  {
    Pharo storage pharo = pharoDict[_eventHash];
    require(pharo.state == PharoState.PHARO, "Must be Pharo to transition to Imhotep");
    pharo.state = PharoState.IMHOTEP;
  }

  function transitionImhotepToAnubis(string memory _eventHash) 
    public
  {
    Pharo storage pharo = pharoDict[_eventHash];
    require(pharo.state == PharoState.IMHOTEP, "Must be Imhotep to transition to Anubus");
    pharo.state = PharoState.ANUBIS;
  }

  function transitionAnubusToObelisk(string memory _eventHash) 
    public
  {
    Pharo storage pharo = pharoDict[_eventHash];
    require(pharo.state == PharoState.ANUBIS, "Must be Anubus to transition to Obelisk");
    pharo.state = PharoState.OBELISK;
  }

  // -------------- PHARO STATISTICS -------------- //
  
  function calcEventTotalStaked(string memory _eventHash)
    public
    view
    returns(uint256) 
  {
    // get the pharo with the event hash
    // the pharo is holding everything inside
    Pharo memory pharo = pharoDict[_eventHash];

    // 1. Gather all cover buyers
    
    // 2. Add up their stakes

    // 3. Return floating value * 100000 to remove decimals
    
    return 0 * 1000;
  }


  function calcNonEventTotalStaked(string memory _eventHash)
    public 
  {
    // make sure the event has buyers
    require(pharoDict[_eventHash].pharoProviderCount[_eventHash] > 0, "Buyer count is zero");
    // 1. Gather all Liquidity Providers
    Provider[] memory providers = pharoDict[_eventHash].providerList;
    // lps are mapping only.. we will need a list to hold them for this

    // 2. Add up their stakes in the insurance pool
    // 3. Return floating value
  }

  function gatherEventStakeDistribution(string memory _eventHash)
    public 
    returns(uint256[] memory)
  { 
    uint256[] memory buyInStakes;
    for (uint k=0; k < pharoDict[_eventHash].pharoBuyInCount[_eventHash]; k++) {
      buyInStakes[k] = pharoDict[_eventHash].pharoBuyIns[0][k].staked;
    }
    return buyInStakes;
  }

  // -------------------- EVENT ODDS CALCULATIONS -------------------- 
  // If 10/1 odds are full and 20/1 odds are full:
  //
  // If the Event happens, we pay
  // buyerStake = $
  // CoveredBuyersTOTAL = $ * (10/1 + 20/1)/2
  // which pays half at each odds 
  //
  // If the Event DOESN'T happen, we pay
  // TranchPercentOfTotal = 10 / (10+20) = 1/3
  // PercentOfTranch = lpStake / tranchStake
  // lpTOTAL = lpStake + $ / TranchPercentOfTotal / PercentOfTranch 

  function calcEventOdds(string memory _eventHash) //, PharoStates _state)
    public 
    returns(uint256[] memory odds) 
  {
    // make sure the event has buyers
    require(pharoDict[_eventHash].pharoBuyerCount[_eventHash] > 0, "Buyer count is zero");

    // 1. get all buyers
    Buyer[] memory buyers = pharoDict[_eventHash].buyerList;
   
    // 2. get the tranche odds distribution

    // 3. get 'A' the area under the tranche odds distribution
    // return A
  }

  // function simpleLoopFor (uint256 id) public returns(uint256) {
  //   require (totalStructs[id] > 0);
  //   uint256 totalAmount;
  //   for(uint8 i=0; i<= totalStructs[id]; i++){
  //       address addr   = structs[id][i].addr;
  //       uint256 amount = structs[id][i].amount;
  //       log0(bytes32(uint256(addr)));
  //       totalAmount = totalAmount + amount;
  //   }
  //   return totalAmount;
  // }

  // -------------- PHARO INTERFACE -------------- //

  function getTranches(string memory eventHash)
    public
    returns(Tranche[] memory)
  {
    //address temp = 0xBe89CFCc5303870Fe9eCAeBDBf12C1183A3CC228;
    Tranche[] memory tranches;
    uint odds;

    for (uint t = 0; t < pharoDict[eventHash].sortedOdds.length; t++) {
      odds = pharoDict[eventHash].sortedOdds[t];
      tranches[t].odds = odds;
      tranches[t].buyers = pharoDict[eventHash].trancheDict[odds].buyers;
      tranches[t].providers = pharoDict[eventHash].trancheDict[odds].providers;
      tranches[t].buyerPool = pharoDict[eventHash].trancheDict[odds].buyerPool;
      tranches[t].providerPool = pharoDict[eventHash].trancheDict[odds].providerPool;
    }

    return tranches;
  }


  function getUnsuppliedDemand(string memory eventHash)
    public
    returns(uint)
  {
    return pharoDict[eventHash].trancheDict[0].buyerPool;
  }



  // -------------- TRANCHE CALCULATIONS -------------- //

  // function gatherNonEventStakeDistribution(string memory eventHash)
  function updateProviderTranches(string memory eventHash)
    public 
  {
    bool oddsListed = false;
    uint odds;
    uint staked;

    for (uint k=0; k < pharoDict[eventHash].pharoProviderCount[eventHash]; k++) {
      oddsListed = false;
      // sortedOdds will be empty here... length not found..
      //uint length = sortedOdds[k].length;
      for (uint s=0; s < 10; s++) {
        if (pharoDict[eventHash].pharoProviders[0][k].odds == pharoDict[eventHash].sortedOdds[s]) {
          oddsListed = true;
          break;
        }
      }
      if (!oddsListed) {
        odds = pharoDict[eventHash].pharoProviders[0][k].odds;
        staked = pharoDict[eventHash].pharoProviders[0][k].staked;
        pharoDict[eventHash].sortedOdds.push(odds);
        // sortedStakes.push(staked);
        trancheStakes[odds] += staked;
      }
    }
    pharoDict[eventHash].sortedOdds = sortTranches(pharoDict[eventHash].sortedOdds);
  }

  // function gatherNonEventStakeDistribution(string memory eventHash)
  function updateBuyerTranches(string memory eventHash)
    public 
  {
    bool oddsListed = false;
    uint odds;
    uint staked;
    uint[] memory tranche_buyer_pools;
    BuyIn memory buyer;
    uint bix = 0;
    uint delta = 0;
    uint liquidity = 0;
    address buyerAddress;

    for (uint k = 0; k < pharoDict[eventHash].sortedOdds.length; k++) {
      odds = pharoDict[eventHash].sortedOdds[k];
      liquidity = trancheStakes[odds]; // what providers have staked in this tranche.
      uint buyer_pool = 0;
      uint test_pool = 0;

      while (bix < pharoDict[eventHash].pharoBuyInCount[eventHash]) {
        
        buyerAddress = pharoDict[eventHash].pharoBuyIns[0][bix].buyerAddress;
        pharoDict[eventHash].trancheDict[odds].buyers.push(buyerAddress);

        if (delta==0) {
          test_pool += pharoDict[eventHash].pharoBuyIns[0][bix].staked;
        } else {
          test_pool = delta;
        }

        if ((test_pool*odds) == liquidity) {

          delta = 0;
          trancheBuyIn[odds] = test_pool;
          pharoDict[eventHash].trancheDict[odds].buyerPool = trancheBuyIn[odds];
          pharoDict[eventHash].pharoBuyIns[0][bix].tranches.push(odds); // This will be called more than once, so push() needs to be updated to ? what?...
          bix++;
          // break;
        } 
        else if ((test_pool*odds) < liquidity) {

          delta = 0;
          pharoDict[eventHash].pharoBuyIns[0][bix].tranches.push(odds);
          bix++;
          // continue;
        }
        else if ((test_pool*odds) > liquidity) {

          // bix = bix; // repeat the same buyin with the new tranche
          delta = ((test_pool*odds) - liquidity)/odds;
          trancheBuyIn[odds] = test_pool - delta;
          pharoDict[eventHash].trancheDict[odds].buyerPool = trancheBuyIn[odds];
          pharoDict[eventHash].pharoBuyIns[0][bix].tranches.push(odds);
          // break;
        }
      }
    }

    if (delta>0) { // Collect buyers that don't fit into a tranche as unmet demand
      pharoDict[eventHash].trancheDict[0].buyerPool = 0;
      for (uint b=bix; b < pharoDict[eventHash].pharoBuyInCount[eventHash]; b++) {
        pharoDict[eventHash].trancheDict[0].buyerPool += pharoDict[eventHash].pharoBuyIns[0][b].staked;
      }
    }
  }


/** @dev PAYMENT FUNCTIONS 
**************************************************************************/
  function payout2Buyers(string memory eventHash)
    public
    returns(uint256) 
  {
    // 1. get the event odds: A = calcEventOdds(_eventHash)
    // 2. divide each buyer's stake by the number of Tranche's
    // 3. multiply each buyer's fractional stake by A
    // 4. TOTAL = add up the buyer's multiplied stakes    
    // return TOTAL
    // get the pharo for this event hash for payout amounts
    Pharo storage pharo = eventHashToPharo[eventHash];

    updateProviderTranches(eventHash);
    uint256 last_buyer = 0;

    for (uint256 k=0; k < pharoDict[eventHash].sortedOdds.length; k++) {
      // For each odds tranche, calculate the coverage for that tranche
      // Then loops through the BuyIns until the tranche pool is paid out.
      // There will likely be remainders for any given BuyIn, 
      // which will roll over as a remainder to the next odds tranche.

      if (last_buyer > pharoDict[eventHash].pharoBuyerCount[eventHash]) { break; }

      // bool tranche_paid;
      bool tranche_paid = false;
      uint256 odds = pharoDict[eventHash].sortedOdds[k];
      uint256 tranche_stake = trancheStakes[k];

      // 1. Loop through the odds and stakes
      // 2. for each buyer, 
      //    a. calc their payout, 
      //    b. calc remaining in that odds tranche
      //    c. repeat for next buyer.
      for (uint256 k=last_buyer; k < pharoDict[eventHash].pharoBuyInCount[eventHash]; k++) {

        BuyIn memory buyer = pharoDict[eventHash].pharoBuyIns[0][k];

        uint256 buyer_payout = odds * buyer.staked;

        if (buyer_payout == 0) {//ERROR HANDLING?
          // todo

        }
        if (buyer_payout == tranche_stake) { 
          bool success = _payBuyer( buyer.buyerAddress, buyer_payout );
          pharoDict[eventHash].pharoBuyIns[0][k].staked = 0;
          trancheStakes[k] = 0;
          tranche_paid = true;
          last_buyer = k+1;
        } 
        else if (buyer_payout < tranche_stake) {
          bool success = _payBuyer( buyer.buyerAddress, buyer_payout );
          pharoDict[eventHash].pharoBuyIns[0][k].staked = 0;
          trancheStakes[k] -= buyer_payout;
        }
        else if (buyer_payout > tranche_stake) {
          uint256 buyer_remainder = buyer_payout - tranche_stake;
          bool success = _payBuyer( buyer.buyerAddress, tranche_stake );
          pharoDict[eventHash].pharoBuyIns[0][k].staked = buyer_remainder;
          trancheStakes[k] = 0;
          tranche_paid = true;
          last_buyer = k;
        }

        if (tranche_paid==true) { 
          break; 
        }
      }
    }
    return 0;
  }

  function _payBuyer(address _buyerAddress, uint256 _trancheStake)
    internal
    returns(bool)
  {

    return true;
  }

  function _payProvider(address _providerAddress, uint payem)
    internal
    returns(bool)
  {

    return true;
  }

  function payout2Providers(string memory eventHash)
    public 
    returns(uint256 odds)
  {
    // 1. sort the trache odds
    // 2. get TBS = the total buyers' stake
    // 3. get each LP's percentage of total staked
    // 4. divide TBS by each LP's percentage and pay'em!

    address providerAddress;
    uint buyer_pool;
    uint provider_pool;
    uint payem;

    updateBuyerTranches(eventHash);

    for (uint k = 0; k < pharoDict[eventHash].sortedOdds.length; k++) {
      odds = pharoDict[eventHash].sortedOdds[k];
      buyer_pool = pharoDict[eventHash].trancheDict[odds].buyerPool; // trancheBuyin[odds];
      provider_pool = pharoDict[eventHash].trancheDict[odds].providerPool;

      for (uint p = 0; p < pharoDict[eventHash].trancheDict[odds].providers.length; p++) {
        providerAddress = pharoDict[eventHash].trancheDict[odds].providers[p];
        payem = pharoDict[eventHash].providerDict[providerAddress].staked / provider_pool;
        _payProvider(providerAddress, payem);
      }
    }
  }

  /** @dev UTILITIES
  *********************************************************/

  function sortTranches(uint[] storage tranches) 
    internal 
    returns(uint[] storage)
  {
    uint temp;
    bool sorted = false;
    uint start = 0;
    while (!sorted) {
      for (uint k = start; k < tranches.length - 1; k++) {
        if (tranches[k] > tranches[k+1]) {
          temp = tranches[k];
          tranches[k] = tranches[k + 1];
          tranches[k + 1] = temp;
          sorted = false;
          start = k - 1;
          if (start < 0) { start = k; }
          break;
        }
      }
    }
    return tranches;
  }

  // function uniqueSort(uint256[] memory data, uint setSize) public { // internal pure {
  //   uint length = data.length;
  //   bool[] memory set = new bool[](setSize);
  //   for (uint i = 0; i < length; i++) {
  //     set[data[i]] = true;
  //   }
  //   uint n = 0;
  //   for (uint i = 0; i < setSize; i++) {
  //     if (set[i]) {
  //       data[n] = i;
  //       if (++n >= length) break;
  //     }
  //   }
  // }

  /** Utility */
  // Function to transfer Ether from this contract to address from input
  // function transfer(address payable _to, uint _amount)
  //     public
  //     onlyOwner
  // {
  //     // Note that "to" is declared as payable
  //     (bool success,) = _to.call{value: _amount}("");
  //     require(success, "Failed to send Ether");
  // }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

// import our contracts
import "./utility/PharoState.sol";
import "./utility/PharoPayouts.sol";
import "./utility/PharoConstants.sol";
import "./entities/Pharo.sol";
import "./PharoCover.sol";

// add openzeppelin references
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

/**
* @title PharoPhactory
* @author seanmgonzales, jaxcoder
* @notice main pharo phactory contract
* @dev additional comments for developer
*/
contract PharoPhactory is PharoState, PharoPayouts, PharoConstants, Pharo {

  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

 
  // What can we hedge against?

  

  constructor()
    public   
  {
    // A Pharo is created using:
    // 1. A ChainLink EventType(enum)::(wind? flood? fire? smoke? F-bombs in Justice League...)

    // 2. Timeout (3 days? 3 weeks? 3 months? --> goes to zero once timed out.)
    // birthday and lifetime
  }

  // -------------- CODE STARTS -------------- 

  // PharoPhactory.CreatePharoContract
  



  
  // -------------------- FRACTIONAL BUYER & LP -------------------- 
  // As we add Buyers and LP's, how do we redistribute their money?
  // What is the definition of a Pharo? When is it constituted?

  // -------------------- ADD BUYERS AND LPs -------------------- 

  // Let's walk through an example with 3 LPs
  // first LP stakes $10 on 2/1 odds
  // second LP stakes $10 on 2/1 odds
  // Pharo Constituted!
  // third person stakes $10 on 2/1 odds 
  // LP payouts are now diluted from 50% to 33% each
  // -> do we need more buyers? 
  //    No, but the LPs want more money for the same risk. Maybe they'll advertise?
  // -> LPs complaining they're being diluted? 
  //    Take your money out (FIFO) and put it in a new Pharo with more risky odds.
  //    Automatically create new Pharo with same odds, advertise?
  

  /** Utility */
  // Function to transfer Ether from this contract to address from input
  function transfer(address payable _to, uint _amount)
      public
      onlyOwner
  {
      // Note that "to" is declared as payable
      (bool success,) = _to.call{value: _amount}("");
      require(success, "Failed to send Ether");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity 0.6.6;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract PharoState {
   
  // -------------------- EVENT STATE CALCULATIONS -------------------- 
  // Calcualte the Pharo states.

  function calcLiquidityRequired()
    public
  {
    // How much do LPs need to provide for the contract to be formalized?
  }

  function getEventHistory()
    public 
  {
    // Return a list of Obelisks
    // LPs and Insured need to understand event history to better determine event odds.
  }

  function getEventVariations()
    public
  {
    
    // Like spreads in sports, Treasury notes, or futures contracts, there are lots of variations on an event that people may be more comfortable estimating the risk and thereby the odds.
  }

  /// @dev determines the pool liquidity for a specific event
  /// @param _eventHash the event hash
  function detPoolLiquidity(string memory _eventHash)
    public
    view
  {
    // 1. Gather list of all Event stakes
    // 2. Calculate their total staked
    // 3. Calculate average odds by liquidity providers (non-event) (10/1 + 20/1 + 7/1)
    // 4. Multiple average by total Event staked (insurance buyers, what do they pay if event occurs?)

    // 1 person has staked $10
    // Q How many people have to provide liquidity at 10/1 odds with $10 investment?
    // A 10 people ($100)

    // 1 buyer stakes $10
    // 2 liquidity providers 
    // 2.1 1 @ 10/1 ($50)
    // 2.2 2 @ 8/1
    // Event happens
    // 3 Pay buyer $90
    // Commission is $0 (for now, lol)
    // 4 

  }
}

pragma solidity 0.6.6;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../PharoToken.sol";

/** 
* @title Pharo Payouts.
* @author jaxcoder, seanmgonzales.
* @notice Handles payments to buyers and providers.
*/
contract PharoPayouts is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 private payoutToken;
  PharoToken private pharoToken;

  // If no more funds it will revert
  modifier noMoreFunds(){
        require(address(this).balance == 0);
        _;
  }
  

  constructor ()
    public
  {
    
  }

  // function payProviders(address[] memory _providers)
  //   public
  // {
  //   for (uint256 i = 0; i < _providers.length; i++) {
  //     payProvider(_amount, _providers[i]);
  //   }
  // }

  // function payCoverBuyers(address[] memory _buyers)
  //   public
  // {
  //   for (uint256 i = 0; i < _buyers.length; i++) {
  //     payCoverBuyer(_amount, _buyers[i]);
  //   }
  // }

  /**
  * @dev pays `_amount` to provider.
  * @param _amount amount to pay.
  * @param _provider address of the provider.
  */
  function payProvider(uint256 _amount, address _provider)
    public
    returns (bool success)
  {

    // payout the stablecoin
    payoutToken.transfer(_provider, _amount);

    // payout rewards
    pharoToken.transfer(_provider, _amount);

    return true;
  }

  /**
  * @dev pays `_amount` to buyer.
  * @param _amount amount to pay.
  * @param _buyer address of the buyer.
  * @return success 
  */
  function payCoverBuyer(uint256 _amount, address _buyer)
    public
    returns (bool success)
  {
    
    // payout the stablecoin
    payoutToken.transfer(_buyer, _amount);

    // payout rewards
    pharoToken.transfer(_buyer, _amount);

    return true;
  }

  


  function payDaMoFo(uint256 amount, address LP) 
    external
    returns(bool success) 
  {
    // what token(s) are we going to pay in??
    // LP.transfer(msg.sender,amount);
    //msg.sender.transfer(LP,amount);
    return true;
  }

}

pragma solidity 0.6.6;
//pragma abicoder v2;
//SPDX-License-Identifier: MIT

/// @title Pharo Constants Contract
/// @author jaxcoder, seanmgonzales
/// @notice holds contants and mappings
/// @dev moonmoon
contract PharoConstants {

    address[] public pharoNftAddresses;
    address payable feeReceiverAddress;

    address payable founder1;
    address payable founder2;
    address payable master;

    uint256 fee = 3; // 3% of total buyin and 3% of total liquidity

    //Mappings for balances to be held
    mapping(address => uint256) public stakerBalances;
    mapping(address => uint256) public poolBalances;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;
        
    enum EventType {
        Wind,
        Hail,
        Snow,
        Water,
        Flood,
        Fire,
        Smoke,
        Rain,
        Misc
    }

    EventType public weatherEvents;
    string public eventType;

    enum EventStatus {
        Active, // fully capitalized Pharo
        Pending, // Imhotep, awaiting full capitalization
        Closed, // Obelisk NFT has been minted
        Cancelled, // All assets returned
        Triggered, // Oracle has triggered the event
        Executed // Anubis has paid out all parties
    }
    EventStatus public eventStatus;

    // Events //
    event PharoCreated(address pharoAddress, uint256 pharoId);
    event PharoBurned(address pharoAddress, uint256 pharoId);
    event BuyerCreated(address buyer, uint256 balance);
    event MummyCreated(string eventHash, string name, uint256 birtday);
    event ProviderCreated(address provider, uint amount, uint odds);
    event EventCreated(string eventType, EventStatus eventStatus, uint256 pharoId, string eventHash);
    

    // make sure any condition is met before access to function
    modifier condition(bool _condition) {
		require(_condition);
		_;
	}


    constructor () public {}


}

pragma solidity 0.6.6;

import "./Provider.sol";
import "./Buyer.sol";
import "./BuyIn.sol";
import "./Tranche.sol";


contract Pharo is Provider, Buyer, BuyIn, Tranche {
    mapping(address => Pharo) public buyerToPharo;
    mapping(address => Pharo) public providerToPharo;
    mapping(string => Pharo) public eventHashToPharo;


    enum PharoState{ MUMMY, PHARO, IMHOTEP, ANUBIS, OBELISK }

    PharoState public pharoState;

    struct Pharo {
        uint256 id;
        uint256 nftId;
        string eventHash;
        string name;
        string description;
        uint256 lifetime;
        uint256 birthday;
        PharoState state;
        Provider[] providerList;
        mapping(string => uint256) pharoProviderCount;
        mapping(uint256 => mapping(uint256 => Provider)) pharoProviders;
        mapping(address => Provider) providerDict;
        BuyIn[] buyInList;
        mapping(string => BuyIn) buyIns;
        mapping(string => uint256) pharoBuyInCount;
        mapping(uint256 => mapping(uint256 => BuyIn)) pharoBuyIns;
        Buyer[] buyerList;
        mapping(string => Buyer) buyers;
        mapping(string => uint256) pharoBuyerCount;
        mapping(uint256 => mapping(uint256 => Buyer)) pharoBuyers;
        mapping(uint256 => Tranche) trancheDict;
        uint256[] sortedOdds;
    }
    
    Pharo[] public pharoList;
    mapping(string => Pharo) public pharoDict;

    // Require Pharo to be in a certain state to call function
    modifier inPharoState(PharoState _state) {
		require(pharoState == _state);
		_;
	}


    constructor () public {}

    // Pharo Logic here...

   
   
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "./utility/ReentrancyGuard.sol";
import "./entities/Buyer.sol";

/// @title Pharo Cover Contract
/// @author JER
/// @notice Creates a new Cover Policy for a Cover Buyer
///         PharoPhactory will call the functions from this contract
///         in the future ...
/// @dev the payments are still in this contract and will be
///      moved at a later time to PharoPayouts contract.
contract PharoCover is Context, AccessControl, ReentrancyGuard, Buyer, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _policyIds;
    EnumerableSet.AddressSet private coverBuyersSet;

    IERC20 public pharoTokenAddress;
    address public pharoPhactoryAddress;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    enum CoverPolicyStatus { INITIALIZING, ACTIVE, INACTIVE, PENDING, CLOSED, OPEN }
    
    struct CoverPolicy {
        uint256 id;
        address owner; // policy owner
        uint256 balance;
        uint256 coverAmount;
        uint256 rewardDebt; // not sure if I want this here or in the CoverBuyer struct
        CoverPolicyStatus status;
        uint256 serviceFee;
    }
    
    // map the pharo id to the cover buyers address and return the CoverBuyer struct
    mapping(uint256 => mapping(address => Buyer)) public pharoIdToCoverBuyer;

    // map all the cover policies to an address
    mapping(uint256 => mapping(address => CoverPolicy)) public pharoIdToCoverPolicy;

    // lps addresses to the the pharoId as index
    address[] public liquidityProviders;

    constructor 
    (
        address _pharoPhactoryAddress,
        IERC20 _pharoTokenAddress
    )
        public
        ReentrancyGuard()
    {
        pharoPhactoryAddress = _pharoPhactoryAddress;
        pharoTokenAddress = _pharoTokenAddress;
        // Set up the Operator Role to the calling actor ~ msg.sender for now, which is the deployer account.
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, 0x3f15B8c6F9939879Cb030D6dd935348E57109637);
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
    }

    event CoverBuyerCreated(uint256 pharoId, address coverBuyer, uint256 coverAmount, uint256 lengthOfCover);
    event CoverPolicyCreated(uint256 pharoId, address coverBuyer, uint256 coverAmoount); 
    event CoverPolicyClosed (uint256 policyId, uint256 pharoId, address coverBuyer);

    /// @notice This function will approve any token
    /// @dev Approve any token
    /// @param _token the token address
    /// @param _amount the amount to approve
    function approveCoverPurchaseToken
    (
        IERC20 _token,
        uint256 _amount
    )
        public
        returns(bool)
    {
        _token.approve(address(this), _amount);
        
        return true;
    }

    /// @notice This binds a cover policy to a cover buyer
    /// @dev 
    /// @param _coverAmount the amount to be covered
    /// @return newPolicyId
    function bindCoverPolicyToCoverBuyerAndPharo (
        uint256 _coverAmount,
        uint256 _lengthOfCover,
        address payable _coverBuyer,
        uint256 _serviceFee,
        uint256 _pharoId,
        address payable _eventCreatorAddress,
        IERC20 _token,
        uint256 _lpPercentage
    )
        public
        returns (uint256)
    {
        //require(hasRole(OPERATOR_ROLE, msg.sender), "PharoCover::Not Allowed, Not In Role => OPERATOR_ROLE");
        
        // paid with stablecoin
        // currently using address(this) for the pool address. todo: set up the transfer to the risk pool
        // NOT Working, it is reverting for some fucking reason!!!
        _token.safeTransferFrom(_coverBuyer, address(this), _serviceFee);
        
        // Does the Cover Buyer exist already?

        // Create a new cover buyer for the pharoId passed in
        Buyer storage coverBuyer = pharoIdToCoverBuyer[_pharoId][_coverBuyer];
        coverBuyer.rewardDebt = 0;
        coverBuyer.buyerAddress = _coverBuyer;

        emit CoverBuyerCreated(_pharoId, _coverBuyer, _coverAmount, _lengthOfCover);

        // Create a new policy and assign some values for the pharo passed in
        _policyIds.increment(); // incremenet the policy counter
        uint256 newPolicyId = _policyIds.current();

        CoverPolicy storage coverPolicy = pharoIdToCoverPolicy[_pharoId][_coverBuyer];
        require(coverPolicy.status != CoverPolicyStatus.ACTIVE, "Policy is already active!");
        coverPolicy.status = CoverPolicyStatus.ACTIVE;
        coverPolicy.owner = _coverBuyer;
        coverPolicy.rewardDebt = 0;
        coverPolicy.balance = 0;
        coverPolicy.coverAmount = _coverAmount;
        coverPolicy.id = newPolicyId;
        coverPolicy.serviceFee = _serviceFee;

        // Mint an NFT for the representation of their policy

        emit CoverPolicyCreated(_pharoId, _coverBuyer, _coverAmount);

        // Split up the service fee to the proper actors for the pharoId passed in
        _payEventCreatorFromServiceFees(_pharoId, _serviceFee, _eventCreatorAddress, _lpPercentage);

        // return the new policy id
        return newPolicyId;
    }

   
    function triggerClaimOnCoverPolicy
    (
        uint256 _pharoId,
        uint256 _policyId
        
    )
        public
    {

    }


    function _closePolicy
    (
        uint256 policyId,
        uint256 pharoId,
        address coverBuyer
    )
        internal
    {
        CoverPolicy storage coverPolicy = pharoIdToCoverPolicy[pharoId][coverBuyer];
        require(coverPolicy.status == CoverPolicyStatus.ACTIVE, "Policy must be active to close!");
        require(coverPolicy.id == policyId, "Policy Id's don't match!");

        emit CoverPolicyClosed(policyId, pharoId, coverBuyer);
    }


// **** Will be moving all the payment functions to the PharoPayouts contract after we get working *** JER

    function _payEventCreatorFromServiceFees
    (
        uint256 pharoId,
        uint256 serviceFee,
        address eventCreatorAddress,
        uint256 lpPercentage
    )
        internal
    {
        // DAO / Treasury gets 10% of every service fee
        _payPharoDaoServiceFee(serviceFee);

        // pay the liquidity providers addresses using the pharoId somehow...
        _payPharoLiquidityProviderServiceFee(serviceFee, lpPercentage);

        // pay the event creator address
        // the funds come from the risk pool contract
        // todo: hook up the RiskPoolContract

    }



    function _payPharoDaoServiceFee
    (
        uint256 fee
    )
        internal
    {
        // pay the 10% to pharo
        uint256 fee = fee.div(100).mul(10);

    }



    function _payPharoLiquidityProviderServiceFee
    (
        uint256 fee,
        uint256 percentage
    )
        internal
    {

    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: GPL

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

/// @title PHRO Token Contract
/// @author jaxcoder
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract PharoToken is ERC20Burnable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
    * @dev Error messages for require statements
    */
    string internal constant ALREADY_LOCKED = 'Tokens already locked';
    string internal constant NOT_LOCKED = 'No tokens locked';
    string internal constant AMOUNT_ZERO = 'Amount can not be 0';
    string internal constant ZERO_ADDRESS = 'Cannot be zero address';

    // We cannot mint tokens past this cap, and can not be changed later!
    uint256 public immutable cap = 1000000000 * 10 ** 18; // One Billion Tokens...

    uint256 public constant _TIMELOCK_YEAR = 31536000; // needs to be 1 year in seconds
    uint256 public constant _TIMELOCK_6MONTHS = _TIMELOCK_YEAR / 2; // needs to be 6 months in seconds

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor()
        public
        ERC20("Pharo Token", "PHRO")
        ERC20Burnable()
        
    {
        // Mint some tokens... test....
        _mint(0x3f15B8c6F9939879Cb030D6dd935348E57109637, 100000 ether);
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner
    function mintTokens(address _to, uint256 _amount)
        public
        onlyOwner
    {
        require(_to != address(0), ZERO_ADDRESS);
        balances[_to] = balances[_to].add(_amount);

        _mint(_to, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _amount)
        public
        virtual
        override
    {
        require(balances[_msgSender()] >= _amount, "PharoToken :: Not enough balance to burn.");
        balances[_msgSender()] = balances[_msgSender()].sub(_amount);

        _burn(_msgSender(), _amount);
    }

    /**
     * @dev Mints `amount` tokens from the caller.
     *
     * See {ERC20-_mint}.
     */
    function mint(uint256 amount)
        public
        virtual
        onlyOwner
    {
        balances[_msgSender()] = balances[_msgSender()].add(amount);
        _mint(_msgSender(), amount);
    }

    // need to add access control to this to be able to be called on creation of the 
    // exchange contract.
    function mintForContract(address cont, uint256 amount)
        public
        virtual
    {
        balances[cont] = balances[cont].add(amount);
        _mint(cont, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount)  
        public
        virtual
        override
    {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "PharoToken:: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /**
    * @dev See {ERC20-_beforeTokenTransfer}.
    *
    * Requirements:
    *
    * - minted tokens must not cause the total supply to go over the cap.
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        // todo: what do we need to do before a transfer takes place?
        
    }



    /** TOKEN LOCKING CRAP */

    /**
    * @dev Reasons why a user's tokens have been locked
    */
    mapping(address => bytes32[]) public lockReason;

    /**
    * @dev locked token structure
    */
    struct LockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    /**
    * @dev Holds number & validity of tokens locked for a given reason for
    *      a specified address
    */
    mapping(address => mapping(bytes32 => LockToken)) public locked;

    /**
    * @dev Records data of all the tokens Locked
    */
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    /**
    * @dev Records data of all the tokens unlocked
    */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );

    /**
    * @dev Locks a specified amount of tokens against an address,
    *      for a specified reason and time
    * @param _reason The reason to lock tokens
    * @param _amount Number of tokens to be locked
    * @param _time Lock time in seconds
    */
    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public
        onlyOwner
        returns (bool)
    {
        uint256 validUntil = now.add(_time);

        // If tokens are already locked, then functions extendLock or
        // increaseLockAmount should be used to make any changes
        require(tokensLocked(_msgSender(), _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_msgSender()][_reason].amount == 0)
            lockReason[_msgSender()].push(_reason);

        transfer(address(this), _amount);

        locked[_msgSender()][_reason] = LockToken(_amount, validUntil, false);

        emit Locked(_msgSender(), _reason, _amount, validUntil);
        return true;
    }

    /**
    * @dev Transfers and Locks a specified amount of tokens,
    *      for a specified reason and time
    * @param _to adress to which tokens are to be transfered
    * @param _reason The reason to lock tokens
    * @param _amount Number of tokens to be transfered and locked
    * @param _time Lock time in seconds
    */
    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        onlyOwner
        returns (bool)
    {
        uint256 validUntil = now.add(_time);

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = LockToken(_amount, validUntil, false);
        
        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

    /**
    * @dev Returns tokens locked for a specified address for a
    *      specified reason
    *
    * @param _of The address whose tokens are locked
    * @param _reason The reason to query the lock tokens for
    */
    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }
    
    /**
    * @dev Returns tokens locked for a specified address for a
    *      specified reason at a specific time
    *
    * @param _of The address whose tokens are locked
    * @param _reason The reason to query the lock tokens for
    * @param _time The timestamp to query the lock tokens for
    */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

    /**
    * @dev Returns total tokens held by an address (locked + transferable)
    * @param _of The address to query the total balance of
    */
    function totalBalanceOf(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        amount = balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(tokensLocked(_of, _reason));
        }   
    }    
    
    /**
    * @dev Extends lock for a specified reason and time
    * @param _reason The reason to lock tokens
    * @param _time Lock extension time in seconds
    */
    function extendLock(bytes32 _reason, uint256 _time)
        public
        onlyOwner
        returns (bool)
    {
        require(tokensLocked(_msgSender(), _reason) > 0, NOT_LOCKED);

        locked[_msgSender()][_reason].validity = locked[_msgSender()][_reason].validity.add(_time);

        emit Locked(_msgSender(), _reason, locked[_msgSender()][_reason].amount, locked[_msgSender()][_reason].validity);
        return true;
    }
    
    /**
    * @dev Increase number of tokens locked for a specified reason
    * @param _reason The reason to lock tokens
    * @param _amount Number of tokens to be increased
    */
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(tokensLocked(_msgSender(), _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[_msgSender()][_reason].amount = locked[_msgSender()][_reason].amount.add(_amount);

        emit Locked(_msgSender(), _reason, locked[_msgSender()][_reason].amount, locked[_msgSender()][_reason].validity);
        return true;
    }

    /**
    * @dev Returns unlockable tokens for a specified address for a specified reason
    * @param _of The address to query the the unlockable token count of
    * @param _reason The reason to query the unlockable tokens for
    */
    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) //solhint-disable-line
            amount = locked[_of][_reason].amount;
    }

    /**
    * @dev Unlocks the unlockable tokens of a specified address
    * @param _of Address of user, claiming back unlockable tokens
    */
    function unlock(address _of)
        public
        onlyOwner
        returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }  

        if (unlockableTokens > 0)
            this.transfer(_of, unlockableTokens);
    }

    /**
    * @dev Gets the unlockable tokens of a specified address
    * @param _of The address to query the the unlockable token count of
    */
    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
        }  
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

pragma solidity 0.6.6;


/// @title Provider Contract
/// @author jaxcoder, seanmgonzales
/// @notice Provider objects and mappings
/// @dev it's coming..
contract Provider {

    struct Provider {
        address providerAddress;
        uint256 odds;
        uint256 staked;
        address asset;
    }

    // maps event hash to a provider
    mapping(string => Provider) public eventHashToProvider;
    // stores a Provider struct for each possible address
    mapping(address => Provider) public addressToProvider;

    // dynamic array of Providers
    Provider[] public providers;

    constructor () public {}


    /// @dev Add the over/under lp odds to the pool
    /// @param _lpAddress liquidity providers address
    /// @param _over numerator
    /// @param _under denominator
    function addProviderodds(address _lpAddress, uint256 _over, uint256 _under)
        public
    {
        // 1. update the LP's data struct

        // 2. trigger the state balancing
        //balancePharo(_pharoAddress);
    }

    // internal provider logic and functions here...
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

/// @title Cover Buyer Contract
/// @author jaxcoder
/// @notice buyer objects and mappings
/// @dev working on it...
contract Buyer {
    // will represent a single
    struct Buyer {
        address buyerAddress;
        uint256 buyerPhroBalance; // PHRO balance
        uint256 rewardDebt; // what we owe the user
        // reason we want this is so if we see that they are 
        // holding PHRO we can reward them somehow.
    }

    // maps the event hash to the Buyer struct
    mapping(string => Buyer) eventHashToBuyer;

    // dynamically sized array of Buyers
    Buyer[] public buyers;

    constructor () public {}

    /// @notice Get a list of all the buyers... not sure we will even want to do this?
    /// @dev this has no sort function yet
    function getAllBuyers()
        public
        //returns(Buyer[] memory)
    {

    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _buyerId a parameter just like in doxygen (must be followed by parameter name)
    /// @return the buyers address
    function getBuyerAddress(uint256 _buyerId)
        public
        view
        returns(address)
    {
        Buyer memory buyer = buyers[_buyerId];

        return buyer.buyerAddress;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _buyerId a parameter just like in doxygen (must be followed by parameter name)
    /// @return the buyers balance
    function getBuyerPhroBalance(uint256 _buyerId)
        public
        view
        returns(uint256)
    {
        Buyer memory buyer = buyers[_buyerId];

        return buyer.buyerPhroBalance;
    }



    // Internal buyer logic and funcitons...

  
}

pragma solidity 0.6.6;


/// @title BuyIn Contract
/// @author jaxcoder
/// @notice handles all buy in's for buyers and providers
/// @dev working on it...
contract BuyIn {

    struct BuyIn {
        address buyerAddress;
        uint staked;
        uint[] tranches;
    }

    // maps the event hash to a buy in -
    // buyers can have multiple buy ins associated
    // with their address, so we use an event hash
    // to associate it with the event/pharo itself.
    mapping(string => BuyIn) eventHashToBuyIn;

    // dyanamic array of buy ins
    BuyIn[] public buyins;

    constructor () public {}

    /// @notice Get a list of all the buy ins
    /// @dev this has no sort function yet
    function getAllBuyIns()
        public
        //returns(BuyIn[] memory)
    {

    }

    // Internal buy in logic and functions here..
    
}

pragma solidity 0.6.6;


/// @title Tranche Contract
/// @author jaxcoder, seanmgonzales
/// @notice Tranche objects and mappings
/// @dev when moon?
contract Tranche {

    struct Tranche {
        address[] providers;
        address[] buyers;
        uint providerPool;
        uint buyerPool;
        uint odds;
    }
    uint[] sortedOdds;
    uint[] sortedStakes;

    mapping(uint => uint) trancheStakes; // Provider stakes
    mapping(uint => uint) trancheBuyIn;  // Buyer stakes

    // stores a balance for each address
    mapping(address => uint256) providerStakes;
    mapping(address => uint256) buyerStakes;

    // dynamic array of tranche structs
    Tranche[] public tranches;


    constructor () public {}

    // Any internal tranche logic/functions go here...
    

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "./PharoToken.sol";
//import "./utility/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice SAFT contract to hold deposits and distribute PHRO tokens when available
contract Saft is Context, AccessControl, Ownable, ReentrancyGuard, ERC721 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    EnumerableSet.AddressSet private addressSet;
    Counters.Counter private _tokenIds;

    IERC20 public pharoToken;

    struct Deposit {
        uint value;
        uint time;
    }

    struct Investor {
        uint256 amount;
        uint256 phroDebt;
    }

    mapping(address => uint256) public balances;
    mapping(address => uint256) public pharoDebt;
    mapping(uint256 => mapping(address => Investor)) public investorInfo;
    mapping(uint256 => mapping(address => Deposit)) public deposits;
    mapping(address => uint256) public tokenHoldersToTokenId;

    event DepositMade(address indexed user, uint256 amount);
    event Deposited(address token, address user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount);

    constructor 
    (
        IERC20 _pharoToken
    ) 
        public
        ERC721("Pharo SAFT Token", "Pharo SAFT Token")
        ReentrancyGuard() 
    {
        pharoToken = _pharoToken;

        _setBaseURI("https://ipfs.io/ipfs/");

        // Set up owner and roles
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x3f15B8c6F9939879Cb030D6dd935348E57109637);


    }

    /// @notice deposit stablecoin asset
    /// @dev An approve will have to be done on the asset first!!
    /// @param _asset address of the stablecoin they want to deposit
    /// @param _amount amount to deposit for PHRO tokens later
    function depositAsset (IERC20 _asset, uint256 _amount)
        public
    {
        require(msg.sender != address(0));
        Investor storage investor = investorInfo[0][msg.sender];
        Deposit storage deposit = deposits[0][msg.sender];
        balances[msg.sender] += _amount;
        deposit.value = _amount;
        deposit.time = block.timestamp;
        // calculate the amount of PHRO they will get
        uint256 phroTokens = calculatePhroTokens(_amount, 15); // .015
        investor.phroDebt += phroTokens;
        investor.amount += _amount;

        _asset.safeTransferFrom(msg.sender, address(this), _amount);
        transferAssetsToPharoSafeAccount(_asset, _amount);

        emit DepositMade(msg.sender, _amount);
    }

    // For ETH deposits only
    function depositEth()
        external
        payable
    {
        require(msg.value > 0, "SAFT::must be greater than 0 (zero)");

    }


    /// @dev Moves the deposited assets to the Phoro Safe Wallet
    function transferAssetsToPharoSafeAccount (IERC20 _asset, uint256 _amount)
        public
    {
        _asset.transferFrom(address(this), 0xDbE2F64680C965Cf52dBD493B4a821B5cDbB9ee2, _amount);
    }

    /// @dev Calculates the amount of PHRO tokens for the deposited amount
    function calculatePhroTokens (uint256 _amount, uint256 _pharoPrice)
        public
        view
        returns(uint256)
    {
        uint256 phroTokens = _amount.div(_pharoPrice).mul(1000);

        return phroTokens;
    }

    // ToDo: create the ipfs hash for the nft 


    // MINT the NFT
    function mintSaftNft
    (
        address investor,
        string memory ipfsHash
    )
        public
        returns(uint256)
    {
        _tokenIds.increment();

        uint256 nextTokenId = _tokenIds.current();
        _mint(investor, nextTokenId);
        _setTokenURI(nextTokenId, ipfsHash);

        tokenHoldersToTokenId[investor] = nextTokenId;

        return nextTokenId;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.6.0; // todo: need to deploy 0.8.4
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./utility/ReentrancyGuard.sol";
import "./PharoToken.sol";
import "./governancePharoToken.sol";

/// @dev interface for interacting with WETH (wrapped ether) for handling ETH
/// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

/**
 * @title TokenRecover
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}


contract PharoStakePool is Context, AccessControl, ReentrancyGuard, TokenRecover {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private asset;

    // The PHRO Token
    PharoToken public phroToken;
    governancePharoToken public gphroToken;
    address public WETH;

    uint256 public currentApy;

    // Burn tokens address
    address public burnAddress;// = 0x000000000000000000000000000000000000dEaD;

    // The block number when PHRO bonus mining starts.
    uint256 public startBlock;

    // PHRO per block rewarded
    // todo: need to calculate this a bit better... SMG??
    // This is also adjustable by the DAO
    uint256 public PHRO_PER_BLOCK = 10 ether;

    uint256 constant MAX_PHRO_SUPPLY = 1000000000 ether; // 1 Billion

    // Total must equal the sum of all allocation points in all pools
    uint256 public totalAllocationPoint = 0;

    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    /// @notice WETH token contract this pool is using for handling ETH
    //address public immutable WETH;

    /// @dev token deposits per token contract and per user
    /// each sender has only a single deposit 
    mapping(address => mapping(address => Deposit)) internal depositsInContracts; 

    /// @dev sum of all deposits currently held in the pool for each token contract
    mapping(address => uint) depositSums;

    /// @dev sum of all bonuses currently available for withdrawal 
    /// for each token contract
    mapping(address => uint) bonusSums;

    struct Deposit {
        uint256 value;
        uint256 time;
    }

    struct StakerInfo {
        uint256 amount; // How many tokens the user has deposited
        uint256 rewardDebt; // Reward Debt: the amount of PHRO tokens
        // the user is entitiled to based on the following distribution.
        // pending reward = (staker.amount * pool.accumulatedPharoPerShare) - staker.rewardDebt
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedPharoPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 asset; // Address of the pools token contract
        uint256 allocationPoint; // How many allocation points assigned to this pool. PHROs to dist per block.
        uint256 accumulatedPharoPerShare; // last block that PHRO dist occurred
        uint256 lastRewardBlock; // Accumulated PHROs per share, times 1e12.
        mapping(address => Deposit) deposits; // the pools deposits for each user
        uint256 depositSum;
    }

    mapping(uint256 => PoolInfo) public poolInfoMap;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => StakerInfo)) public stakerInfo;
    mapping(uint256 => mapping(address => Deposit)) public deposits;

    event DepositMade(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposited(address token, address user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accPhroPerShare);
    event UpdateEmissionRate(address indexed _sender, uint256 _pharoPerBlock);
    event BurnAddressUpdated(address indexed _sender, address indexed _burnAddress);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event Entered(address indexed user, uint256 amount, uint256 timestamp);
    event Exited(address indexed user, uint256 amount, uint256 timestamp);

    constructor (
        uint256 _startBlock,
        PharoToken _phroToken,
        governancePharoToken _gphroToken,
        address _WETH
    ) 
        public
        ReentrancyGuard()
    {
        startBlock = _startBlock;
        phroToken = _phroToken;
        gphroToken = _gphroToken;
        WETH = _WETH;

        // ** add the phro/xphro stake pool with 100 allocation,
        // this will be the only pool even though we have 
        // the ability to add more.
        addStakePool(100, _phroToken);

        // hardhat deployer dev: 0x765495849b296cfc05228b613562a09a39d47ed6
        _setupRole(OPERATOR_ROLE, 0x3f15B8c6F9939879Cb030D6dd935348E57109637);

        // todo: setup the dao role here...
        _setupRole(DAO_ROLE, 0x3f15B8c6F9939879Cb030D6dd935348E57109637);
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
    }

    // Functions for DAO Operator address //  
    function updateBurnAddress(address _burnAddress)
        public
        onlyOwner
    {
        require(hasRole(DAO_ROLE, msg.sender), "PharoDao :: not in the DAO role, sorry...");
        burnAddress = _burnAddress;
        emit BurnAddressUpdated(msg.sender, _burnAddress);
    }

    function updateEmissionRate(uint256 _pharoPerBlock)
        public
        onlyOwner
    {
        require(hasRole(DAO_ROLE, msg.sender), "PharoStakePool :: not in the DAO role, sorry...");
        PHRO_PER_BLOCK = _pharoPerBlock;
        emit UpdateEmissionRate(msg.sender, _pharoPerBlock);
    }

    /// @notice contract doesn't support sending ETH directly
    receive() external payable {
        require(
        msg.sender == WETH, 
        "PharoStakePool :: No receive() except from WETH contract, use depositETH()");
    }

    function depositETH()
        public
        payable
    {
        require(msg.value > 0, "PharoStakePool :: can't deposit 0");
        msg.sender.transfer(msg.value);
    }

    /// @dev Calculate the APY for a pool
    /// @param _poolId the id of the pool
    /// @return the APY uint256
    function calculateApyOnPharoRewards(uint256 _poolId)
        public
        view
        returns(uint256)
    {
        PoolInfo memory pool = poolInfo[_poolId];
        // ToDo: need more accurate formula
        // ** these rewards are not tied to the LP and CB
        // rewards from a Pharo. **
        return pool.accumulatedPharoPerShare.div(100);


    }

    function poolDetails(uint256 poolId)
        external
        view
        returns(uint256[4] memory)
    {
        PoolInfo storage pool = poolInfo[poolId];
        // todo: return the deposits array...
        return [
            pool.allocationPoint,
            pool.accumulatedPharoPerShare,
            pool.lastRewardBlock,
            pool.depositSum
        ];
    }

    function stakerDetails(uint256 poolId, address staker)
        external
        view
        returns(uint[2] memory)
    {
        StakerInfo storage staker = stakerInfo[poolId][staker];
        return [
            staker.amount,
            staker.rewardDebt
        ];
    }

    function depositDetails(uint256 poolId, address staker)
        external
        view
        returns(uint[2] memory)
    {
        Deposit storage deposit = deposits[poolId][staker];
        return [
            deposit.value,
            deposit.time
        ];
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addStakePool(uint256 _allocationPoint, IERC20 _asset) 
        public
        onlyOwner
    {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocationPoint = totalAllocationPoint.add(_allocationPoint);
        poolInfo.push(
            PoolInfo({
                asset: _asset,
                allocationPoint: _allocationPoint,
                lastRewardBlock: lastRewardBlock,
                accumulatedPharoPerShare: 0,
                depositSum: 0
            })
        );

        // poolInfoMap[0] = poolInfo[0];
    }

    // function withdrawPhro(uint256 poolId)
    //     external
    //     returns(bool success)
    // {
    //     PoolInfo storage pool = poolInfo[poolId];
    //     Deposit storage dep = pool.deposits[msg.sender];

    //     uint256 withdrawAmt = dep.value;
    //     pool.depositSum = pool.depositSum.sub(withdrawAmt);
    //     gphroToken.transferFrom(msg.sender, address(this), withdrawAmt);
    //     phroToken.transfer(msg.sender, withdrawAmt);

    //     delete pool.deposits[msg.sender];

    //     return true;
    // }

    // ** Need to call approve on the token first from UI **  
    // function stake(uint256 _poolId, uint256 _amount) 
    //     external
    // {
    //     require(msg.sender != address(0));
    //     require(_amount > 0, "PharoStakePool :: `_amount` too small, must be greater than zero.");

    //     // Balance of the contract before this deposit
    //     uint256 contractBeforePhroBalance = phroToken.balanceOf(address(this));
    //     address staker = msg.sender;

    //     _stakeAndUpdateState(_poolId, _amount);           
    // }

    // function _stakeAndUpdateState(uint256 _poolId, uint256 _amount)
    //     private
    // {
    //     PoolInfo storage pool = poolInfo[_poolId];
    //     StakerInfo storage staker = stakerInfo[_poolId][msg.sender];

    //     // Update the pool, settle rewards.
    //     // updatePool(_poolId);

    //     if(staker.amount > 0) {
    //         uint256 pending = staker.amount.mul(pool.accumulatedPharoPerShare).div(1e12).sub(staker.rewardDebt);
    //         if(pending > 0) {
    //             safePharoTransfer(msg.sender, pending);
    //         }
    //     }

    //     // let's get the token from the depositor, they must be approved already!
    //     pool.asset.safeTransferFrom(address(msg.sender), address(this), _amount);
    //     staker.amount = staker.amount.add(_amount);

    //     // Mint the gPHRO token at a 1:1 ratio
    //     gphroToken.mintStakerTokens(msg.sender, _amount);

    //     // burn the phro tokens sent in or hold them in the contract??
    //     // for now they are held in the contract
        
    //     staker.rewardDebt = staker.amount.mul(pool.accumulatedPharoPerShare).div(1e12);
    //     emit DepositMade(msg.sender, _poolId, _amount);
    // }

    
    function enter(uint256 _poolId, uint256 _amount)
        external
    {
        PoolInfo storage pool = poolInfo[_poolId];
        Deposit storage dep = pool.deposits[msg.sender];

        pool.depositSum = pool.depositSum.add(_amount);

        // gets the amount of PHRO locked in the contract
        uint256 totalPhro = phroToken.balanceOf(address(this));
        // gets the amount of gPHRO in existence
        uint256 totalGovTokens = gphroToken.totalSupply();
        // if no gPHRO exists, mint it 1:1 to the `_amount`
        if (totalGovTokens == 0 || totalPhro == 0) {
            gphroToken.mintStakerTokens(msg.sender, _amount);
        }
        // calculate and mint the `_amount` of gPHRO the PHRO is worth. The ratio will 
        // change over time, as gPHRO is burned/minted and PHRO deposited + gained from
        // fees / withdrawn.
        else {
            uint256 what = _amount.mul(1);
            gphroToken.mintStakerTokens(msg.sender, what);
        }

        // lock the PHRO in the contract
        phroToken.transferFrom(msg.sender, address(this), _amount);

        emit Entered(msg.sender, _amount, block.timestamp);
    }

    function exit(uint256 _poolId, uint256 _share)
        external
    {
        PoolInfo storage pool = poolInfo[_poolId];
        Deposit storage dep = pool.deposits[msg.sender];

        // get the amount to gPHRO in existence
        uint256 totalShares = gphroToken.totalSupply();

        // calculate the amount of PHRO the gPHRO is worth
        uint256 what = _share.mul(1);
        gphroToken.burnFrom(msg.sender, _share);
        phroToken.transfer(msg.sender, what);

        // pay rewards
        if(pool.lastRewardBlock < block.number) {
            uint256 numOfBlocksForReward = block.number.sub(pool.lastRewardBlock);
            uint256 reward = numOfBlocksForReward.mul(PHRO_PER_BLOCK).div(1e12);
            pool.lastRewardBlock = block.timestamp;
            phroToken.mintForContract(msg.sender, reward);
        }
        
        emit Exited(msg.sender, _share, block.timestamp);
    }
    

    // Safe $PHRO transfer
    // Transfers the balance or amount to _to address
    // must be a WITHDRAW_ROLE
    function safePharoTransfer(address _to, uint256 _amount)
        nonReentrant
        private 
    {
        //require(hasRole(WITHDRAWER_ROLE, msg.sender), "PharoStakePool::Not Allowed, Not In Role => WITHDRAWER_ROLE");
        uint256 pharoBalance = phroToken.balanceOf(address(this));
        bool transferSuccess = false;
        if(_amount > pharoBalance) {
            transferSuccess = phroToken.transfer(_to, pharoBalance);
        } else {
            transferSuccess = phroToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safePharoTransfer:: Transfer Failed");
    }

    // Update reward variables of the given pool to be up to date and 
    // correct and pay out PHRO tokens to burn address and provider.
    function updatePool(uint256 _poolId)
        public
        onlyOwner
    {
        // require(hasRole(OPERATOR_ROLE, msg.sender), "PharoStakePool::Not Allowed, Not In Role => OPERATOR_ROLE");
        PoolInfo storage pool = poolInfo[_poolId];
        if(block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 poolTokenSupply = pool.asset.balanceOf(address(this));
        if(poolTokenSupply == 0 || pool.allocationPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pharoReward = multiplier.mul(PHRO_PER_BLOCK).mul(pool.allocationPoint).div(totalAllocationPoint);
        
        // need to transfer the reward to the staker...
        phroToken.transfer(address(this), pharoReward);

        // add the reward amount when its paid
        bonusSums[msg.sender] = bonusSums[msg.sender] + pharoReward;

        pool.accumulatedPharoPerShare = pool.accumulatedPharoPerShare.add(pharoReward.mul(1e12).div(poolTokenSupply));
        pool.lastRewardBlock = block.number;
    }

    // Return the multiplier over the given _from to _to block
    function getMultiplier(uint256 _from, uint256 _to)
        private
        view
        returns(uint256) 
    {
        if(phroToken.totalSupply() >= MAX_PHRO_SUPPLY) return 0;

        return _to.sub(_from);
    }

    // View function to see the pending pharo on the front-end
    function pendingPharo(uint256 _poolId, address _staker)
        external
        view
        returns(uint256) 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        StakerInfo storage staker = stakerInfo[_poolId][_staker];
        uint256 accumulatedPharoPerShare = pool.accumulatedPharoPerShare;
        uint256 stakedSupply = pool.asset.balanceOf(address(this));
        if(stakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pharoReward = multiplier.mul(PHRO_PER_BLOCK).mul(pool.allocationPoint).div(totalAllocationPoint);
            accumulatedPharoPerShare = accumulatedPharoPerShare.add(pharoReward.mul(1e12).div(stakedSupply));
        }

        return staker.amount.mul(accumulatedPharoPerShare).div(1e12).sub(staker.rewardDebt);
    }

    // Do we want to use an amount here? Should we just
    // default to returning all assets with their interest?
    function unstake(uint256 _poolId, uint256 _amount)
        external
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_poolId];
        StakerInfo storage staker = stakerInfo[_poolId][msg.sender];
        require(_amount > 0, "Can't withdraw 0");
        require(staker.amount >= _amount, "Withdraw not good");

        updatePool(_poolId);

        uint256 pending = staker.amount.mul(pool.accumulatedPharoPerShare).div(1e12).sub(staker.rewardDebt);
        if(pending > 0) {
            safePharoTransfer(msg.sender, pending);
        }

        staker.amount = staker.amount.sub(_amount);
        staker.rewardDebt = staker.amount.mul(pool.accumulatedPharoPerShare).div(1e12);
        bonusSums[msg.sender] = bonusSums[msg.sender] + staker.rewardDebt;
        
        // Need to have an approval mechanism in place in the front end 
        // to call the approve funciton on the xPharo token for the _amount.
        // get the _amount of the gphro from the users wallet
        gphroToken.transferFrom(address(msg.sender), address(this), _amount);

        // Burn the gPHRO token at a 1:1 ratio of PHRO withdrawn
        // todo: figure out why I cannot use burn()
        // To burn them we just send to the dead address
        // Must have an approval
        // gphroToken.burnFrom(address(msg.sender), _amount);
        // gphroToken.transferFrom(address(msg.sender), 0x000000000000000000000000000000000000dEaD, _amount);

        emit Withdraw(msg.sender, _poolId, _amount);
    }

    function withdrawPhroTokens(uint256 _amount)
        external
        onlyOwner
        returns (bool success)
    {
        require(phroToken.balanceOf(address(this)) >= _amount, "PharoStakePool :: `_amount` more than balance.");

        return true;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _poolId) 
        public 
        nonReentrant 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        StakerInfo storage staker = stakerInfo[_poolId][msg.sender];

        uint256 amount = staker.amount;
        staker.amount = 0;
        staker.rewardDebt = 0;
        pool.asset.safeTransfer(address(msg.sender), amount);

        emit Withdraw(msg.sender, _poolId, amount);
    }
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: GPL

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

// todo: need to get this working...
//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @title The gPHRO token is the governance token of the Pharo protocol
/// @author jaxcoder
/// @notice Handles voting and delegation of token voting rights and all other ERC20 functions
/// @dev Contract is pretty straightforward token contract with some governance.
contract governancePharoToken is ERC20Burnable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // We cannot mint tokens past this cap, and can not be changed later!
    uint256 private _cap; // One Billion Tokens...

    mapping(address => address) internal _delegates;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name, uint256 chainId, address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee, uint256 nonce, uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    constructor()
        public
        ERC20("gPharo Token", "gPHRO")
        ERC20Burnable()
    {
        // Mint some tokens... test....
        _mint(0x3f15B8c6F9939879Cb030D6dd935348E57109637, 100000 ether);
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mintTokens(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

     /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Mints `amount` tokens from the caller.
     *
     * See {ERC20-_mint}.
     */
    function mintStakerTokens(address payable to, uint256 amount)
        external
    {
        // need to add security still...
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount)
        public
        virtual
        override
    {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "gPharoToken:: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegator The address to get delegatee for
    */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

    /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig (
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "gPharoToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "gPharoToken::delegateBySig: invalid nonce");
        require(now <= expiry, "gPharoToken::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "gPharoToken::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying PHRO (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "gPharoToken::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

import "./utility/ReentrancyGuard.sol";


contract PharoRiskPool is Context, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private addressSet;

    IERC20 public pharoToken;

    uint256 public currentApy;

    // Burn tokens address
    address public burnAddress;

    // Liquidity Provider
    struct ProviderInfo {
        uint256 amount;
    }
    ProviderInfo[] public providerInfo;

    // Risk Pool Info
    struct PoolInfo {
        IERC20 asset; // the event creator can select what token to use for their Pharo
        uint256 pharoId; // The Pharo NFT id this pool is backing with its capital/balance
        uint256 balance;
    }

    PoolInfo[] public poolInfo;

    mapping(address => uint256) providerBalances;
    mapping(address => ProviderInfo) providerInfoMap;
    // PoolId => providerAddress => Provider Info
    mapping(uint256 => mapping(address => ProviderInfo)) public providerInfoPerPool;
    mapping(uint256 => mapping(uint256 => PoolInfo)) public pharoIdToPoolInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);


    // this contract will be accessed by other contracts and the public
    // Access control will be important!!
    constructor 
    (
        IERC20 _pharoToken
    )
        public
        ReentrancyGuard()
    {
        pharoToken = _pharoToken;
    }


    // deposit assets to the risk pool
    // there will be different assets on different Pharos
    // need to give them an asset selection
    function deposit 
    (
        uint256 poolId, 
        uint256 pharoId, 
        IERC20 asset, 
        uint256 amount, 
        address providerAddress
    )
        public
    {
        // get the right pool and update the values
        PoolInfo storage pool = poolInfo[poolId];
        pool.balance = pool.balance.add(amount);
        pool.pharoId = pharoId;
        pool.asset = asset;

        // track the pharo to the pool
        pharoIdToPoolInfo[pharoId][poolId] = pool;

        // tracking the provider balance for PHRO rewards and % of the service fees they will earn
        ProviderInfo storage provider = providerInfo[poolId];
        provider.amount = amount;

        // track the providerInfo from the provider address
        // not sure if we even need this
        providerInfoMap[providerAddress] = provider;

        asset.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, poolId, amount);
    }


    // withdraw assets from the Risk pool to make the payouts
    // send the funds to PharoPayouts.sol to make all the payments??
    // todo: still need to set up ownership and access control here
    function withdraw 
    (
        uint256 poolId, 
        uint256 pharoId, 
        uint256 amount
    )
        public
    {
        // get the right pool
        PoolInfo storage pool = poolInfo[poolId];
        pool.balance = pool.balance - amount;
        require(pool.balance >= amount, "Balance to low in pool for withdrawl");

        pool.asset.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, poolId, amount);
    }



}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "./utility/ReentrancyGuard.sol";


contract PharoReservePool is Context, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public currentApy;

    // Burn tokens address
    address public burnAddress;

    // Liquidity Provider
    struct PharoInfo {
        uint256 amount;
    }
    PharoInfo[] public providerInfo;

    // Risk Pool Info
    struct PoolInfo {
        IERC20 asset; // the event creator can select what token to use for their Pharo
        uint256 pharoId; // The Pharo NFT id this pool is backing with its capital/balance
        uint256 balance;
    }

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => uint256)) pharoBalances;
    // PoolId => providerAddress => Provider Info
    //mapping(uint256 => mapping(address => PharoInfo)) public pharoInfoPerPool;
    mapping(uint256 => mapping(uint256 => PoolInfo)) public pharoIdToPoolInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, string memo);


    // this contract will be accessed by other contracts and the public
    // Access control will be important!!
    constructor 
    (

    )
        public
        ReentrancyGuard()
    {
        
    }


    // deposit assets to the risk pool
    // there will be different assets on different Pharos
    // need to give them an asset selection
    function depositToReserve
    (
        uint256 poolId,
        uint256 pharoId,
        IERC20 asset,
        uint256 amount,
        address providerAddress
    )
        public
    {
        // get the right pool and update the values
        PoolInfo storage pool = poolInfo[poolId];
        pool.balance += amount;
        pool.pharoId = pharoId;
        pool.asset = asset;

        // track the pharo to the pool
        pharoIdToPoolInfo[pharoId][poolId] = pool;

        // tracking the provider balance for PHRO rewards and % of the service fees they will earn
        PharoInfo storage pharo = providerInfo[poolId];
        pharo.amount = amount;

        // track the providerInfo from the provider address
        // not sure if we even need this
        

        asset.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, poolId, amount);
    }


    // withdraw assets from the Risk pool to make the payouts
    // send the funds to PharoPayouts.sol to make all the payments??
    // 
    function withdrawFromReserve
    (
        uint256 poolId, 
        uint256 pharoId, 
        uint256 amount,
        string memory memo
    )
        public
        nonReentrant
    {
        // get the right pool
        PoolInfo storage pool = poolInfo[poolId];
        pool.balance = pool.balance + amount;

        pool.asset.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, poolId, amount, memo);
    }

    // Allocate
    // Allocates funds for payouts when the Risk Pool has been depleted.
    // This will be called from the Risk Pool when the balance is too low 
    // to make the payout.
    function allocate
    (
        uint256 poolId,
        uint256 pharoId,
        uint256 amount,
        string memory memo
    )
        public
        nonReentrant
    {

    }

    // Do we need a payback?
    function payback
    (
        uint256 poolId,
        uint256 pharoId,
        uint256 amount,
        string memory memo
    )
        public
    {

    }



}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./utility/ReentrancyGuard.sol";


contract PharoCaptivePool is Ownable, ReentrancyGuard {
    

    constructor () public ReentrancyGuard() { }



    
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: GPL

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/TokenTimelock.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PharoLiquidityMining is Ownable, ERC721 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // State Variables
    IERC20 public pharoToken;

    Counters.Counter private _poolIds;
    Counters.Counter private _tokenIds;

    uint256 public currentApy;

    // Burn tokens address
    address public burnAddress;

    // The block number when PHRO bonus mining starts.
    uint256 public startBlock;

    // Block number when bonus PHRO period ends.
    uint256 public bonusEndBlock;

    // PHRO per block rewarded
    uint256 public pharoPerBlock;

    // Total must equal the sum of all allocation points in all pools
    uint256 public totalAllocationPoint = 0;

    // Bonus muliplier for early PHRO makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    /// @notice WETH token contract this pool is using for handling ETH
    address public immutable WETH;


    // Mappings
    /// @dev token deposits per token contract and per user
    /// each sender has only a single deposit 
    mapping(address => mapping(address => Deposit)) internal deposits; 

    /// @dev sum of all deposits currently held in the pool for each token contract
    mapping(address => uint) depositSums;

    /// @dev sum of all bonuses currently available for withdrawal 
    /// for each token contract
    mapping(address => uint) bonusSums;

    mapping(uint256 => PoolInfo) public poolInfoMap;
    mapping(address => uint256) providerStakeBalance;
    mapping(uint256 => mapping(address => StakerInfo)) public stakerInfo;


    // Arrays
    PoolInfo[] public poolInfo;

    // Structs
    struct Deposit {
        uint value;
        uint time;
    }

    struct StakerInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 stakedToken;
        uint256 allocationPoint;
        uint256 accumulatedPharoPerShare;
        //uint256 lastRewardBlock;
    }

    // Events
    event DepositMade(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposited(address token, address user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, bool update);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);
    

    constructor 
    (
        IERC20 _pharoToken,
        uint256 _pharoPerBlock,
        address _WETH
    )
        public
        ERC721("Pharo Mining Pool", "Pharo Mining Pool")
    {
        pharoToken = _pharoToken;
        WETH = _WETH;
        pharoPerBlock = _pharoPerBlock;
        _setBaseURI("https://ipfs.io/ipfs/");
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
    }


    // mint nft
    function mintMiningNft (address miner, string memory ipfsHash)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _mint(miner, newId);
        _setTokenURI(newId, ipfsHash);

        return newId;
    }

    // add new pool
    function addNewMiningPool(uint256 allocation, IERC20 token, bool updatePools)
        public
        onlyOwner
    {
        if(updatePools) {

        }

        totalAllocationPoint = totalAllocationPoint.add(allocation);
        poolInfo.push(
            PoolInfo({
                stakedToken: token,
                allocationPoint: allocation,
                accumulatedPharoPerShare: 0
            })
        );

        emit LogPoolAddition(poolInfo.length.sub(1), allocation, token);
    }

    // update a pool

    // deposit LP tokens

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor (IERC20 token_, address beneficiary_, uint256 releaseTime_) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/TokenTimelock.sol";

contract PharoTokenTimelock is TokenTimelock {
    constructor(IERC20 token, address beneficiary, uint256 releaseTime)
        public
        TokenTimelock(token, beneficiary, releaseTime)
    {
        
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utility/ReentrancyGuard.sol";
import "./PharoToken.sol";

contract PharoExchange is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    // address payable private owner;

    PharoToken public pharoToken;

    uint256 public exchangeRate = 100;              // 1:1 for testing
    uint256 public contractEthBalance = 0;
    uint256 public contractTokenBalance = 0;

    bool private locked = false;
    bool public paused = false;

    mapping(address => uint256) public balances;    // Token holder balances

    constructor (PharoToken _pharoToken)
        public
        ReentrancyGuard()
    {
        pharoToken = _pharoToken;
        balances[address(this)] = balances[address(this)].add(1000000000 * 10 ** 18);
        contractTokenBalance = contractTokenBalance.add(1000000000 * 10 ** 18);
        transferOwnership(0x3f15B8c6F9939879Cb030D6dd935348E57109637);
        // Mint 100,000,000 tokens for sale on the exchange
        pharoToken.mintForContract(address(this), 1000000000 ether);
        
    }

    /**  
    *   @dev    Fallback function to receive ETH. It is compatible with 2300 gas for
    *          receiving funds via send or transfer methods.
    */
    fallback() external payable {
        require(msg.data.length == 0, "PharoExchange :: Only ETH!!");
        contractEthBalance = contractEthBalance.add(msg.value);
        emit Received(msg.sender, msg.value);
    }

    /** 
    *   @dev    Receive function to accept ETH
    */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
    *   @dev Receive function for stablecoins
    */
    function receiveStablecoin(address _stablecoin, uint256 _amount)
        public
    {
        // todo: ability to accept stablecoins
        IERC20 incommingToken = IERC20(_stablecoin);

        // Transfer the tokens
        incommingToken.transfer(address(this), _amount); 
    }

    /**
    *   @dev Supports selling tokens to the contract. It uses msg.sender.call.value()
    *        method to be compatible with EIP-1884. 
    */
    function sellPhroTokens(uint256 _tokens)
        external
        nonReentrant
        returns(bool success)
    {
        require(_tokens > 0, "PharoExchange :: Selling zero is not allowed.");
        require(balances[msg.sender] >= _tokens, "PharoExchange :: Not enough tokens to sell.");
        uint256 _wei = _tokens.div(exchangeRate); // calculate equivalent tokens in wei
        require(address(this).balance >= _wei, "PharoExchange :: Not enough wei in contract."); // Checks the contracts ETH balance
        require(contractEthBalance >= _wei, "PharoExchange :: Not enough wei in contract.");

        balances[msg.sender] = balances[msg.sender].sub(_tokens); // Decrease tokens of the seller
        balances[address(this)] = balances[address(this)].add(_tokens); // Increase the tokens bal in the contract
        contractEthBalance = contractEthBalance.sub(_wei); // Adjusts the contract balance
        contractTokenBalance = contractTokenBalance.add(_tokens);

        emit Sell(msg.sender, _tokens, address(this), _wei, address(this));
        (success, ) = msg.sender.call{value:_wei}("");
        require(success, "PharoExchange :: Ether transfer failed");

        return success;
    }

    /**
    *   @dev Supports buying PHRO tokens by transferring ETH
    */
    function buyPhroTokens()
        external
        payable
        nonReentrant
        returns(bool success)
    {
        require(msg.sender != owner(), "PharoExchange :: Can't be the owner.");
        uint256 _tokens = msg.value.mul(exchangeRate);
        require(balances[address(this)] >= _tokens, "PharoExchange :: Not enough PHRO tokens.");

        balances[msg.sender] = balances[msg.sender].add(_tokens); // Increase token bal of buyer
        balances[address(this)] = balances[address(this)].sub(_tokens); // Decrease token bal of contract/owner
        contractEthBalance = contractEthBalance.add(msg.value); // Adjust contract bal of ETH
        contractTokenBalance = contractTokenBalance.sub(_tokens);

        emit Buy(msg.sender, msg.value, address(this), _tokens);
        return true;
    }

    /**
    *   @dev Withdraw Ether from the contract and send to the Pharo DAO treasury address
    */
    function withdrawEth(uint256 _amount)
        external
        onlyOwner
        returns(bool success)
    {
        require(address(this).balance >= _amount, "PharoExchange :: Not enough ETH in contract for withdraw.");
        require(contractEthBalance >= _amount, "PharoExchange :: Not enough ETH in contract for withdraw.");

        contractEthBalance = contractEthBalance.sub(_amount);

        emit Withdrawal(msg.sender, address(this), _amount);
        (success, ) = msg.sender.call{value:_amount}("");
        return success;
    }

    /**
    *   @dev Returns the contract ETH balance
    */
    function getContractEthBalance()
        public
        view
        onlyOwner
        returns(uint256, uint256)
    {
        return (address(this).balance, contractEthBalance);
    }

    /** 
     * @dev Checks for unexpected received Ether (forced to the contract without using payable functions)
     */
    function unexpectedEther()
        public
        view
        onlyOwner
        returns(bool)
    {
        return (contractEthBalance != address(this).balance);
    }

    /**
     * @dev Sets new exchange rate. It can be called only by the owner.
     */
    function setExchangeRate(uint256 _newRate)
        external
        onlyOwner
        returns(bool success)
    {
        uint256 _currentRate = exchangeRate;
        exchangeRate = _newRate;
        emit ChangeRate(_currentRate, _newRate);
    }

    /**
    * @dev Changes owner of the contract
    */
    function changeOwner(address payable newOwner)
        external
        onlyOwner
        validAddress(newOwner)
    {
        address _current = owner();
        transferOwnership(newOwner);

        emit OwnerTransferred(_current, newOwner);
    }

    /**
    * @dev Pause the contract as result of self-checks (off-chain computations).
    */
    function pause()
        external
        onlyOwner
    {
        paused = true;
        emit Pause(msg.sender, paused);    
    }

    /**
    * @dev Unpause the contract after self-checks.
    */
    function unpause()
        external
        onlyOwner
    {
        paused = false;
        emit Pause(msg.sender, paused);
    }

    /**
     * @dev Checks validity of the address.
     */
    modifier validAddress(address addr)
    {
        require(addr != address(0x0), "PharoExchange :: Zero address.");
        require(addr != address(this), "PharoExchange :: Contract address.");
        _;
    }

    /**
    * @dev Modifier to support Fail-Safe Mode. In case, it disables most of the toekn features, hands off control to the owner.
    */
    modifier notPaused() 
    {
        require(!paused, "PharoExchange :: Fail-Safe mode.");
        _;
    }

    event Pause(address indexed pauser, bool paused);
    event ChangeRate(uint256 oldRate, uint256 newRate);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);
    event Received(address indexed sender, uint256 value);
    event Buy(address indexed _buyer, uint256 _wei, address indexed _owner, uint256 _tokens);
    event Sell(address indexed _seller, uint256 _tokens, address indexed _contract, uint256 _wei, address indexed _owner);
    event Withdrawal(address indexed _by, address indexed _contract, uint256 _wei);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}