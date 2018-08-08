pragma solidity ^ 0.4.19;

// DopeRaider Districts Contract
// by gasmasters.io
// contact: team@doperaider.com

// special thanks to :
//                    8฿ł₮₮Ɽł₱
//                    Etherguy

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
  function implementsERC721() public pure returns(bool);
  function totalSupply() public view returns(uint256 total);
  function balanceOf(address _owner) public view returns(uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns(address owner);
  function approve(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

// File: contracts/NarcoCoreInterface.sol

contract NarcosCoreInterface is ERC721 {
  function getNarco(uint256 _id)
  public
  view
  returns(
    string  narcoName,
    uint256 weedTotal,
    uint256 cokeTotal,
    uint16[6] skills,
    uint8[4] consumables,
    string genes,
    uint8 homeLocation,
    uint16 level,
    uint256[6] cooldowns,
    uint256 id,
    uint16[9] stats
  );

  function updateWeedTotal(uint256 _narcoId, bool _add, uint16 _total) public;
  function updateCokeTotal(uint256 _narcoId, bool _add,  uint16 _total) public;
  function updateConsumable(uint256 _narcoId, uint256 _index, uint8 _new) public;
  function updateSkill(uint256 _narcoId, uint256 _index, uint16 _new) public;
  function incrementStat(uint256 _narcoId, uint256 _index) public;
  function setCooldown(uint256 _narcoId , uint256 _index , uint256 _new) public;
  function getRemainingCapacity(uint256 _id) public view returns (uint8 capacity);
}

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: contracts/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


// File: contracts/Districts/DistrictsAdmin.sol

contract DistrictsAdmin is Ownable, Pausable {
  event ContractUpgrade(address newContract);

  address public newContractAddress;
  address public coreAddress;

  NarcosCoreInterface public narcoCore;

  function setNarcosCoreAddress(address _address) public onlyOwner {
    _setNarcosCoreAddress(_address);
  }

  function _setNarcosCoreAddress(address _address) internal {
    NarcosCoreInterface candidateContract = NarcosCoreInterface(_address);
    require(candidateContract.implementsERC721());
    coreAddress = _address;
    narcoCore = candidateContract;
  }

  /// @dev Used to mark the smart contract as upgraded, in case there is a serious
  ///  breaking bug. This method does nothing but keep track of the new contract and
  ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
  ///  contract to update to the new contract address in that case.
  /// @param _v2Address new address
  function setNewAddress(address _v2Address) public onlyOwner whenPaused {
    newContractAddress = _v2Address;

    ContractUpgrade(_v2Address);
  }


  // token manager contract
  address [6] public tokenContractAddresses;

  function setTokenAddresses(address[6] _addresses) public onlyOwner {
      tokenContractAddresses = _addresses;
  }

  modifier onlyDopeRaiderContract() {
    require(msg.sender == coreAddress);
    _;
  }

  modifier onlyTokenContract() {
    require(
        msg.sender == tokenContractAddresses[0] ||
        msg.sender == tokenContractAddresses[1] ||
        msg.sender == tokenContractAddresses[2] ||
        msg.sender == tokenContractAddresses[3] ||
        msg.sender == tokenContractAddresses[4] ||
        msg.sender == tokenContractAddresses[5]
      );
    _;
  }

}


// File: contracts/DistrictsCore.sol

contract DistrictsCore is DistrictsAdmin {

  // DISTRICT EVENTS
  event NarcoArrived(uint8 indexed location, uint256 indexed narcoId); // who just arrived here
  event NarcoLeft(uint8 indexed location, uint256 indexed narcoId); // who just left here
  event TravelBust(uint256 indexed narcoId, uint16 confiscatedWeed, uint16 confiscatedCoke);
  event Hijacked(uint256 indexed hijacker, uint256 indexed victim , uint16 stolenWeed , uint16 stolenCoke);
  event HijackDefended(uint256 indexed hijacker, uint256 indexed victim);
  event EscapedHijack(uint256 indexed hijacker, uint256 indexed victim , uint8 escapeLocation);

  uint256 public airLiftPrice = 0.01 ether; // home dorothy price
  uint256 public hijackPrice = 0.008 ether; // universal hijackPrice
  uint256 public travelPrice = 0.002 ether; // universal travelPrice
  uint256 public spreadPercent = 5; // universal spread between buy and sell
  uint256 public devFeePercent = 2; // on various actions
  uint256 public currentDevFees = 0;
  uint256 public bustRange = 10;

  function setAirLiftPrice(uint256 _price) public onlyOwner{
    airLiftPrice = _price;
  }

  function setBustRange(uint256 _range) public onlyOwner{
    bustRange = _range;
  }

  function setHijackPrice(uint256 _price) public onlyOwner{
    hijackPrice = _price;
  }

  function setTravelPrice(uint256 _price) public onlyOwner{
    travelPrice = _price;
  }

  function setSpreadPercent(uint256 _spread) public onlyOwner{
    spreadPercent = _spread;
  }

  function setDevFeePercent(uint256 _fee) public onlyOwner{
    devFeePercent = _fee;
  }

  function isDopeRaiderDistrictsCore() public pure returns(bool){ return true; }


  // Market Items

  struct MarketItem{
    uint256 id;
    string itemName;
    uint8 skillAffected;
    uint8 upgradeAmount;
    uint8 levelRequired; // the level a narco must have before they
  }

  // there is a fixed amount of items - they are not tokens bc iterations will be needed.
  // 0,1 = weed , coke , 2 - 4 consumables , 5-23 items
  MarketItem[24] public marketItems;

  function configureMarketItem(uint256 _id, uint8 _skillAffected, uint8  _upgradeAmount, uint8 _levelRequired, string _itemName) public onlyOwner{
    marketItems[_id].skillAffected = _skillAffected;
    marketItems[_id].upgradeAmount = _upgradeAmount;
    marketItems[_id].levelRequired = _levelRequired;
    marketItems[_id].itemName = _itemName;
    marketItems[_id].id = _id;
  }


  struct District {
    uint256[6] exits;
    uint256 weedPot;
    uint256 weedAmountHere;
    uint256 cokePot;
    uint256 cokeAmountHere;
    uint256[24] marketPrices;
    bool[24] isStocked;
    bool hasMarket;
    string name;
  }

  District[8] public districts; // there is no &#39;0&#39; district - this will be used to indicate no exit

  // for keeping track of who is where
  mapping(uint256 => uint8) narcoIndexToLocation;

  function DistrictsCore() public {
  }

  function getDistrict(uint256 _id) public view returns(uint256[6] exits, bool hasMarket, uint256[24] prices, bool[24] isStocked, uint256 weedPot, uint256 cokePot, uint256 weedAmountHere, uint256 cokeAmountHere, string name){
    District storage district = districts[_id];
    exits = district.exits;
    hasMarket = district.hasMarket;
    prices = district.marketPrices;

    // minimum prices for w/c set in the districts configuration file
    prices[0] = max(prices[0], (((district.weedPot / district.weedAmountHere)/100)*(100+spreadPercent)));// Smeti calc this is the buy price (contract sells)
    prices[1] = max(prices[1], (((district.cokePot / district.cokeAmountHere)/100)*(100+spreadPercent)));  // Smeti calc this is the buy price (contract sells)
    isStocked = district.isStocked;
    weedPot = district.weedPot;
    cokePot = district.cokePot;
    weedAmountHere = district.weedAmountHere;
    cokeAmountHere = district.cokeAmountHere;
    name = district.name;
  }

  function createNamedDistrict(uint256 _index, string _name, bool _hasMarket) public onlyOwner{
    districts[_index].name = _name;
    districts[_index].hasMarket = _hasMarket;
    districts[_index].weedAmountHere = 1;
    districts[_index].cokeAmountHere = 1;
    districts[_index].weedPot = 0.001 ether;
    districts[_index].cokePot = 0.001 ether;
  }

  function initializeSupply(uint256 _index, uint256 _weedSupply, uint256 _cokeSupply) public onlyOwner{
    districts[_index].weedAmountHere = _weedSupply;
    districts[_index].cokeAmountHere = _cokeSupply;
  }

  function configureDistrict(uint256 _index, uint256[6]_exits, uint256[24] _prices, bool[24] _isStocked) public onlyOwner{
    districts[_index].exits = _exits; // clockwise starting at noon
    districts[_index].marketPrices = _prices;
    districts[_index].isStocked = _isStocked;
  }

  // callable by other contracts to control economy
  function increaseDistrictWeed(uint256 _district, uint256 _quantity) public onlyDopeRaiderContract{
    districts[_district].weedAmountHere += _quantity;
  }
  function increaseDistrictCoke(uint256 _district, uint256 _quantity) public onlyDopeRaiderContract{
    districts[_district].cokeAmountHere += _quantity;
  }

  // proxy updates to main contract
  function updateConsumable(uint256 _narcoId,  uint256 _index ,uint8 _newQuantity) public onlyTokenContract {
    narcoCore.updateConsumable(_narcoId,  _index, _newQuantity);
  }

  function updateWeedTotal(uint256 _narcoId,  uint16 _total) public onlyTokenContract {
    narcoCore.updateWeedTotal(_narcoId,  true , _total);
    districts[getNarcoLocation(_narcoId)].weedAmountHere += uint8(_total);
  }

  function updatCokeTotal(uint256 _narcoId,  uint16 _total) public onlyTokenContract {
    narcoCore.updateCokeTotal(_narcoId,  true , _total);
    districts[getNarcoLocation(_narcoId)].cokeAmountHere += uint8(_total);
  }


  function getNarcoLocation(uint256 _narcoId) public view returns(uint8 location){
    location = narcoIndexToLocation[_narcoId];
    // could be they have not travelled, so just return their home location
    if (location == 0) {
      (
            ,
            ,
            ,
            ,
            ,
            ,
        location
        ,
        ,
        ,
        ,
        ) = narcoCore.getNarco(_narcoId);

    }

  }

  function getNarcoHomeLocation(uint256 _narcoId) public view returns(uint8 location){
      (
            ,
            ,
            ,
            ,
            ,
            ,
        location
        ,
        ,
        ,
        ,
        ) = narcoCore.getNarco(_narcoId);
  }

  // function to be called when wanting to add funds to all districts
  function floatEconony() public payable onlyOwner {
        if(msg.value>0){
          for (uint district=1;district<8;district++){
              districts[district].weedPot+=(msg.value/14);
              districts[district].cokePot+=(msg.value/14);
            }
        }
    }

  // function to be called when wanting to add funds to a district
  function distributeRevenue(uint256 _district , uint8 _splitW, uint8 _splitC) public payable onlyDopeRaiderContract {
        if(msg.value>0){
         _distributeRevenue(msg.value, _district, _splitW, _splitC);
        }
  }

  uint256 public localRevenuePercent = 80;

  function setLocalRevenuPercent(uint256 _lrp) public onlyOwner{
    localRevenuePercent = _lrp;
  }

  function _distributeRevenue(uint256 _grossRevenue, uint256 _district , uint8 _splitW, uint8 _splitC) internal {
          // subtract dev fees
          uint256 onePc = _grossRevenue/100;
          uint256 netRevenue = onePc*(100-devFeePercent);
          uint256 devFee = onePc*(devFeePercent);

          uint256 districtRevenue = (netRevenue/100)*localRevenuePercent;
          uint256 federalRevenue = (netRevenue/100)*(100-localRevenuePercent);

          // distribute district revenue
          // split evenly between weed and coke pots
          districts[_district].weedPot+=(districtRevenue/100)*_splitW;
          districts[_district].cokePot+=(districtRevenue/100)*_splitC;

          // distribute federal revenue
           for (uint district=1;district<8;district++){
              districts[district].weedPot+=(federalRevenue/14);
              districts[district].cokePot+=(federalRevenue/14);
            }

          // acrue dev fee
          currentDevFees+=devFee;
  }

  function withdrawFees() external onlyOwner {
        if (currentDevFees<=address(this).balance){
          currentDevFees = 0;
          msg.sender.transfer(currentDevFees);
        }
    }


  function buyItem(uint256 _narcoId, uint256 _district, uint256 _itemIndex, uint256 _quantity) public payable whenNotPaused{
    require(narcoCore.ownerOf(_narcoId) == msg.sender); // must be owner

    uint256 narcoWeedTotal;
    uint256 narcoCokeTotal;
    uint16[6] memory narcoSkills;
    uint8[4] memory narcoConsumables;
    uint16 narcoLevel;

    (
                ,
      narcoWeedTotal,
      narcoCokeTotal,
      narcoSkills,
      narcoConsumables,
                ,
                ,
      narcoLevel,
                ,
                ,
    ) = narcoCore.getNarco(_narcoId);

    require(getNarcoLocation(_narcoId) == uint8(_district)); // right place to buy
    require(uint8(_quantity) > 0 && districts[_district].isStocked[_itemIndex] == true); // there is enough of it
    require(marketItems[_itemIndex].levelRequired <= narcoLevel || _district==7); //  must be level to buy this item or black market
    require(narcoCore.getRemainingCapacity(_narcoId) >= _quantity || _itemIndex>=6); // narco can carry it or not a consumable

    // progression through the upgrades for non consumable items (>=6)
    if (_itemIndex>=6) {
      require (_quantity==1);

      if (marketItems[_itemIndex].skillAffected!=5){
            // regular items
            require (marketItems[_itemIndex].levelRequired==0 || narcoSkills[marketItems[_itemIndex].skillAffected]<marketItems[_itemIndex].upgradeAmount);
          }else{
            // capacity has 20 + requirement
            require (narcoSkills[5]<20+marketItems[_itemIndex].upgradeAmount);
      }
    }

    uint256 costPrice = districts[_district].marketPrices[_itemIndex] * _quantity;

    if (_itemIndex ==0 ) {
      costPrice = max(districts[_district].marketPrices[0], (((districts[_district].weedPot / districts[_district].weedAmountHere)/100)*(100+spreadPercent))) * _quantity;
    }
    if (_itemIndex ==1 ) {
      costPrice = max(districts[_district].marketPrices[1], (((districts[_district].cokePot / districts[_district].cokeAmountHere)/100)*(100+spreadPercent))) * _quantity;
    }

    require(msg.value >= costPrice); // paid enough?
    // ok purchase here
    if (_itemIndex > 1 && _itemIndex < 6) {
      // consumable
      narcoCore.updateConsumable(_narcoId, _itemIndex - 2, uint8(narcoConsumables[_itemIndex - 2] + _quantity));
       _distributeRevenue(costPrice, _district , 50, 50);
    }

    if (_itemIndex >= 6) {
        // skills boost
        // check which skill is updated by this item
        narcoCore.updateSkill(
          _narcoId,
          marketItems[_itemIndex].skillAffected,
          uint16(narcoSkills[marketItems[_itemIndex].skillAffected] + (marketItems[_itemIndex].upgradeAmount))
        );
        _distributeRevenue(costPrice, _district , 50, 50);
    }
    if (_itemIndex == 0) {
        // weedTotal
        narcoCore.updateWeedTotal(_narcoId, true,  uint16(_quantity));
        districts[_district].weedAmountHere += uint8(_quantity);
        _distributeRevenue(costPrice, _district , 100, 0);
    }
    if (_itemIndex == 1) {
       // cokeTotal
       narcoCore.updateCokeTotal(_narcoId, true, uint16(_quantity));
       districts[_district].cokeAmountHere += uint8(_quantity);
       _distributeRevenue(costPrice, _district , 0, 100);
    }

    // allow overbid
    if (msg.value>costPrice){
        msg.sender.transfer(msg.value-costPrice);
    }

  }


  function sellItem(uint256 _narcoId, uint256 _district, uint256 _itemIndex, uint256 _quantity) public whenNotPaused{
    require(narcoCore.ownerOf(_narcoId) == msg.sender); // must be owner
    require(_itemIndex < marketItems.length && _district < 8 && _district > 0 && _quantity > 0); // valid item and district and quantity

    uint256 narcoWeedTotal;
    uint256 narcoCokeTotal;

    (
                ,
      narcoWeedTotal,
      narcoCokeTotal,
                ,
                ,
                ,
                ,
                ,
                ,
                ,
            ) = narcoCore.getNarco(_narcoId);


    require(getNarcoLocation(_narcoId) == _district); // right place to buy
    // at this time only weed and coke can be sold to the contract
    require((_itemIndex == 0 && narcoWeedTotal >= _quantity) || (_itemIndex == 1 && narcoCokeTotal >= _quantity));

    uint256 salePrice = 0;

    if (_itemIndex == 0) {
      salePrice = districts[_district].weedPot / districts[_district].weedAmountHere;  // Smeti calc this is the sell price (contract buys)
    }
    if (_itemIndex == 1) {
      salePrice = districts[_district].cokePot / districts[_district].cokeAmountHere;  // Smeti calc this is the sell price (contract buys)
    }
    require(salePrice > 0); // yeah that old chestnut lol

    // do the updates
    if (_itemIndex == 0) {
      narcoCore.updateWeedTotal(_narcoId, false, uint16(_quantity));
      districts[_district].weedPot=sub(districts[_district].weedPot,salePrice*_quantity);
      districts[_district].weedAmountHere=sub(districts[_district].weedAmountHere,_quantity);
    }
    if (_itemIndex == 1) {
      narcoCore.updateCokeTotal(_narcoId, false, uint16(_quantity));
      districts[_district].cokePot=sub(districts[_district].cokePot,salePrice*_quantity);
      districts[_district].cokeAmountHere=sub(districts[_district].cokeAmountHere,_quantity);
    }
    narcoCore.incrementStat(_narcoId, 0); // dealsCompleted
    // transfer the amount to the seller - should be owner of, but for now...
    msg.sender.transfer(salePrice*_quantity);

  }



  // allow a Narco to travel between districts
  // travelling is done by taking "exit" --> index into the loctions
  function travelTo(uint256 _narcoId, uint256 _exitId) public payable whenNotPaused{
    require(narcoCore.ownerOf(_narcoId) == msg.sender); // must be owner
    require((msg.value >= travelPrice && _exitId < 7) || (msg.value >= airLiftPrice && _exitId==7));

    // exitId ==7 is a special exit for airlifting narcos back to their home location


    uint256 narcoWeedTotal;
    uint256 narcoCokeTotal;
    uint16[6] memory narcoSkills;
    uint8[4] memory narcoConsumables;
    uint256[6] memory narcoCooldowns;

    (
                ,
      narcoWeedTotal,
      narcoCokeTotal,
      narcoSkills,
      narcoConsumables,
                ,
                ,
                ,
      narcoCooldowns,
                ,
    ) = narcoCore.getNarco(_narcoId);

    // travel cooldown must have expired and narco must have some gas
    require(now>narcoCooldowns[0] && (narcoConsumables[0]>0 || _exitId==7));

    uint8 sourceLocation = getNarcoLocation(_narcoId);
    District storage sourceDistrict = districts[sourceLocation]; // find out source
    require(_exitId==7 || sourceDistrict.exits[_exitId] != 0); // must be a valid exit

    // decrease the weed pot and cocaine pot for the destination district
    uint256 localWeedTotal = districts[sourceLocation].weedAmountHere;
    uint256 localCokeTotal = districts[sourceLocation].cokeAmountHere;

    if (narcoWeedTotal < localWeedTotal) {
      districts[sourceLocation].weedAmountHere -= narcoWeedTotal;
    } else {
      districts[sourceLocation].weedAmountHere = 1; // always drop to 1
    }

    if (narcoCokeTotal < localCokeTotal) {
      districts[sourceLocation].cokeAmountHere -= narcoCokeTotal;
    } else {
      districts[sourceLocation].cokeAmountHere = 1; // always drop to 1
    }

    // do the move
    uint8 targetLocation = getNarcoHomeLocation(_narcoId);
    if (_exitId<7){
      targetLocation =  uint8(sourceDistrict.exits[_exitId]);
    }

    narcoIndexToLocation[_narcoId] = targetLocation;

    // distribute the travel revenue
    _distributeRevenue(msg.value, targetLocation , 50, 50);

    // increase the weed pot and cocaine pot for the destination district with the travel cost
    districts[targetLocation].weedAmountHere += narcoWeedTotal;
    districts[targetLocation].cokeAmountHere += narcoCokeTotal;

    // consume some gas (gas index = 0)
    if (_exitId!=7){
      narcoCore.updateConsumable(_narcoId, 0 , narcoConsumables[0]-1);
    }
    // set travel cooldown (speed skill = 0)
    //narcoCore.setCooldown( _narcoId ,  0 , now + min(3 minutes,(455-(5*narcoSkills[0])* 1 seconds)));
    narcoCore.setCooldown( _narcoId ,  0 , now + (455-(5*narcoSkills[0])* 1 seconds));

    // update travel stat
    narcoCore.incrementStat(_narcoId, 7);
    // Travel risk
     uint64 bustChance=random(50+(5*narcoSkills[0])); // 0  = speed skill

     if (bustChance<=bustRange){
      busted(_narcoId,targetLocation,narcoWeedTotal,narcoCokeTotal);
     }

     NarcoArrived(targetLocation, _narcoId); // who just arrived here
     NarcoLeft(sourceLocation, _narcoId); // who just left here

  }

  function busted(uint256 _narcoId, uint256 targetLocation, uint256 narcoWeedTotal, uint256 narcoCokeTotal) private  {
       uint256 bustedWeed=narcoWeedTotal/2; // %50
       uint256 bustedCoke=narcoCokeTotal/2; // %50
       districts[targetLocation].weedAmountHere -= bustedWeed; // smeti fix
       districts[targetLocation].cokeAmountHere -= bustedCoke; // smeti fix
       districts[7].weedAmountHere += bustedWeed; // smeti fix
       districts[7].cokeAmountHere += bustedCoke; // smeti fix
       narcoCore.updateWeedTotal(_narcoId, false, uint16(bustedWeed)); // 50% weed
       narcoCore.updateCokeTotal(_narcoId, false, uint16(bustedCoke)); // 50% coke
       narcoCore.updateWeedTotal(0, true, uint16(bustedWeed)); // 50% weed confiscated into office lardass
       narcoCore.updateCokeTotal(0, true, uint16(bustedCoke)); // 50% coke confiscated into office lardass
       TravelBust(_narcoId, uint16(bustedWeed), uint16(bustedCoke));
  }


  function hijack(uint256 _hijackerId, uint256 _victimId)  public payable whenNotPaused{
    require(narcoCore.ownerOf(_hijackerId) == msg.sender); // must be owner
    require(msg.value >= hijackPrice);

    // has the victim escaped?
    if (getNarcoLocation(_hijackerId)!=getNarcoLocation(_victimId)){
        EscapedHijack(_hijackerId, _victimId , getNarcoLocation(_victimId));
        narcoCore.incrementStat(_victimId, 6); // lucky escape
    }else
    {
      // hijack calculation
      uint256 hijackerWeedTotal;
      uint256 hijackerCokeTotal;
      uint16[6] memory hijackerSkills;
      uint8[4] memory hijackerConsumables;
      uint256[6] memory hijackerCooldowns;

      (
                  ,
        hijackerWeedTotal,
        hijackerCokeTotal,
        hijackerSkills,
        hijackerConsumables,
                  ,
                  ,
                  ,
        hijackerCooldowns,
                  ,
      ) = narcoCore.getNarco(_hijackerId);

      // does hijacker have capacity to carry any loot?

      uint256 victimWeedTotal;
      uint256 victimCokeTotal;
      uint16[6] memory victimSkills;
      uint256[6] memory victimCooldowns;
      uint8 victimHomeLocation;
      (
                  ,
        victimWeedTotal,
        victimCokeTotal,
        victimSkills,
                  ,
                  ,
       victimHomeLocation,
                  ,
        victimCooldowns,
                  ,
      ) = narcoCore.getNarco(_victimId);

      // victim is not in home location , or is officer lardass
      require(getNarcoLocation(_victimId)!=victimHomeLocation || _victimId==0);
      require(hijackerConsumables[3] >0); // narco has ammo

      require(now>hijackerCooldowns[3]); // must be outside cooldown

      // consume the ammo
      narcoCore.updateConsumable(_hijackerId, 3 , hijackerConsumables[3]-1);
      // attempt the hijack

      // 3 = attackIndex
      // 4 = defenseIndex

      if (random((hijackerSkills[3]+victimSkills[4]))+1 >victimSkills[4]) {
        // successful hijacking

        doHijack(_hijackerId  , _victimId , victimWeedTotal , victimCokeTotal);

        // heist character
        if (_victimId==0){
             narcoCore.incrementStat(_hijackerId, 5); // raidSuccessful
        }

      }else{
        // successfully defended
        narcoCore.incrementStat(_victimId, 4); // defendedSuccessfully
        HijackDefended( _hijackerId,_victimId);
      }

    } // end if escaped

    //narcoCore.setCooldown( _hijackerId ,  3 , now + min(3 minutes,(455-(5*hijackerSkills[3])* 1 seconds))); // cooldown
     narcoCore.setCooldown( _hijackerId ,  3 , now + (455-(5*hijackerSkills[3])* 1 seconds)); // cooldown

      // distribute the hijack revenue
      _distributeRevenue(hijackPrice, getNarcoLocation(_hijackerId) , 50, 50);

  } // end hijack function

  function doHijack(uint256 _hijackerId  , uint256 _victimId ,  uint256 victimWeedTotal , uint256 victimCokeTotal) private {

        uint256 hijackerCapacity =  narcoCore.getRemainingCapacity(_hijackerId);

        // fill pockets starting with coke
        uint16 stolenCoke = uint16(min(hijackerCapacity , (victimCokeTotal/2))); // steal 50%
        uint16 stolenWeed = uint16(min(hijackerCapacity - stolenCoke, (victimWeedTotal/2))); // steal 50%

        // 50% chance to start with weed
        if (random(100)>50){
           stolenWeed = uint16(min(hijackerCapacity , (victimWeedTotal/2))); // steal 50%
           stolenCoke = uint16(min(hijackerCapacity - stolenWeed, (victimCokeTotal/2))); // steal 50
        }

        // steal some loot this calculation tbd
        // for now just take all coke / weed
        if (stolenWeed>0){
          narcoCore.updateWeedTotal(_hijackerId, true, stolenWeed);
          narcoCore.updateWeedTotal(_victimId,false, stolenWeed);
        }
        if (stolenCoke>0){
          narcoCore.updateCokeTotal(_hijackerId, true , stolenCoke);
          narcoCore.updateCokeTotal(_victimId,false, stolenCoke);
        }

        narcoCore.incrementStat(_hijackerId, 3); // hijackSuccessful
        Hijacked(_hijackerId, _victimId , stolenWeed, stolenCoke);


  }


  // pseudo random - but does that matter?
  uint64 _seed = 0;
  function random(uint64 upper) private returns (uint64 randomNumber) {
     _seed = uint64(keccak256(keccak256(block.blockhash(block.number-1), _seed), now));
     return _seed % upper;
   }

   function min(uint a, uint b) private pure returns (uint) {
            return a < b ? a : b;
   }
   function max(uint a, uint b) private pure returns (uint) {
            return a > b ? a : b;
   }
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
     assert(b <= a);
     return a - b;
   }
  // never call this from a contract
  /// @param _loc that we are interested in
  function narcosByDistrict(uint8 _loc) public view returns(uint256[] narcosHere) {
    uint256 tokenCount = numberOfNarcosByDistrict(_loc);
    uint256 totalNarcos = narcoCore.totalSupply();
    uint256[] memory result = new uint256[](tokenCount);
    uint256 narcoId;
    uint256 resultIndex = 0;
    for (narcoId = 0; narcoId <= totalNarcos; narcoId++) {
      if (getNarcoLocation(narcoId) == _loc) {
        result[resultIndex] = narcoId;
        resultIndex++;
      }
    }
    return result;
  }

  function numberOfNarcosByDistrict(uint8 _loc) public view returns(uint256 number) {
    uint256 count = 0;
    uint256 narcoId;
    for (narcoId = 0; narcoId <= narcoCore.totalSupply(); narcoId++) {
      if (getNarcoLocation(narcoId) == _loc) {
        count++;
      }
    }
    return count;
  }

}