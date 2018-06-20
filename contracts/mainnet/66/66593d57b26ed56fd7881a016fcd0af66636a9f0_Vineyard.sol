pragma solidity ^0.4.18;

contract Vineyard{

    // All grape units are in grape-secs/day
    uint256 constant public GRAPE_SECS_TO_GROW_VINE = 86400; // 1 grape
    uint256 constant public STARTING_VINES = 300;
    uint256 constant public VINE_CAPACITY_PER_LAND = 1000;

    bool public initialized=false;
    address public ceoAddress;
    address public ceoWallet;

    mapping (address => uint256) public vineyardVines;
    mapping (address => uint256) public purchasedGrapes;
    mapping (address => uint256) public lastHarvest;
    mapping (address => address) public referrals;

    uint256 public marketGrapes;

    mapping (address => uint256) public landMultiplier;
    mapping (address => uint256) public totalVineCapacity;
    mapping (address => uint256) public wineInCellar;
    mapping (address => uint256) public wineProductionRate;
    uint256 public grapesToBuildWinery = 43200000000; // 500000 grapes
    uint256 public grapesToProduceBottle = 3456000000; //40000 grapes

    address constant public LAND_ADDRESS = 0x2C1E693cCC537c8c98C73FaC0262CD7E18a3Ad60;
    LandInterface landContract;

    function Vineyard(address _wallet) public{
        require(_wallet != address(0));
        ceoAddress = msg.sender;
        ceoWallet = _wallet;
        landContract = LandInterface(LAND_ADDRESS);
    }

    function transferWalletOwnership(address newWalletAddress) public {
      require(msg.sender == ceoAddress);
      require(newWalletAddress != address(0));
      ceoWallet = newWalletAddress;
    }

    modifier initializedMarket {
        require(initialized);
        _;
    }

    function harvest(address ref) initializedMarket public {
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 grapesUsed = getMyGrapes();
        uint256 newVines = SafeMath.div(grapesUsed, GRAPE_SECS_TO_GROW_VINE);
        if (SafeMath.add(vineyardVines[msg.sender], newVines) > totalVineCapacity[msg.sender]) {
            purchasedGrapes[msg.sender] = SafeMath.mul(SafeMath.sub(SafeMath.add(vineyardVines[msg.sender], newVines), totalVineCapacity[msg.sender]), GRAPE_SECS_TO_GROW_VINE);
            vineyardVines[msg.sender] = totalVineCapacity[msg.sender];
            grapesUsed = grapesUsed - purchasedGrapes[msg.sender];
        }
        else
        {
            vineyardVines[msg.sender] = SafeMath.add(vineyardVines[msg.sender], newVines);
            purchasedGrapes[msg.sender] = 0;
        }
        lastHarvest[msg.sender] = now;

        //send referral grapes (add to purchase talley)
        purchasedGrapes[referrals[msg.sender]]=SafeMath.add(purchasedGrapes[referrals[msg.sender]],SafeMath.div(grapesUsed,5));
    }

    function produceWine() initializedMarket public {
        uint256 hasGrapes = getMyGrapes();
        uint256 wineBottles = SafeMath.div(SafeMath.mul(hasGrapes, wineProductionRate[msg.sender]), grapesToProduceBottle);
        purchasedGrapes[msg.sender] = 0; //Remainder of grapes are lost in wine production process
        lastHarvest[msg.sender] = now;
        //Every bottle of wine increases the grapes to make next by 10
        grapesToProduceBottle = SafeMath.add(SafeMath.mul(864000, wineBottles), grapesToProduceBottle);
        wineInCellar[msg.sender] = SafeMath.add(wineInCellar[msg.sender],wineBottles);
    }

    function buildWinery() initializedMarket public {
        require(wineProductionRate[msg.sender] <= landMultiplier[msg.sender]);
        uint256 hasGrapes = getMyGrapes();
        require(hasGrapes >= grapesToBuildWinery);

        uint256 grapesLeft = SafeMath.sub(hasGrapes, grapesToBuildWinery);
        purchasedGrapes[msg.sender] = grapesLeft;
        lastHarvest[msg.sender] = now;
        wineProductionRate[msg.sender] = wineProductionRate[msg.sender] + 1;
        grapesToBuildWinery = SafeMath.add(grapesToBuildWinery, 21600000000);
        // winery uses some portion of land, so must remove some vines
        vineyardVines[msg.sender] = SafeMath.sub(vineyardVines[msg.sender],1000);
    }

    function sellGrapes() initializedMarket public {
        uint256 hasGrapes = getMyGrapes();
        uint256 grapesToSell = hasGrapes;
        if (grapesToSell > marketGrapes) {
          // don&#39;t allow sell larger than the current market holdings
          grapesToSell = marketGrapes;
        }
        uint256 grapeValue = calculateGrapeSell(grapesToSell);
        uint256 fee = devFee(grapeValue);
        purchasedGrapes[msg.sender] = SafeMath.sub(hasGrapes,grapesToSell);
        lastHarvest[msg.sender] = now;
        marketGrapes = SafeMath.add(marketGrapes,grapesToSell);
        ceoWallet.transfer(fee);
        msg.sender.transfer(SafeMath.sub(grapeValue, fee));
    }

    function buyGrapes() initializedMarket public payable{
        require(msg.value <= SafeMath.sub(this.balance,msg.value));
        require(vineyardVines[msg.sender] > 0);

        uint256 grapesBought = calculateGrapeBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        grapesBought = SafeMath.sub(grapesBought, devFee(grapesBought));
        marketGrapes = SafeMath.sub(marketGrapes, grapesBought);
        ceoWallet.transfer(devFee(msg.value));
        purchasedGrapes[msg.sender] = SafeMath.add(purchasedGrapes[msg.sender],grapesBought);
    }

    function calculateTrade(uint256 valueIn, uint256 marketInv, uint256 Balance) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(Balance, 10000), SafeMath.add(SafeMath.div(SafeMath.add(SafeMath.mul(marketInv,10000), SafeMath.mul(valueIn, 5000)), valueIn), 5000));
    }

    function calculateGrapeSell(uint256 grapes) public view returns(uint256) {
        return calculateTrade(grapes, marketGrapes, this.balance);
    }

    function calculateGrapeBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketGrapes);
    }

    function calculateGrapeBuySimple(uint256 eth) public view returns(uint256) {
        return calculateGrapeBuy(eth,this.balance);
    }

    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3), 100);
    }

    function seedMarket(uint256 grapes) public payable{
        require(marketGrapes == 0);
        initialized = true;
        marketGrapes = grapes;
    }

    function getFreeVines() initializedMarket public {
        require(vineyardVines[msg.sender] == 0);
        createPlotVineyard(msg.sender);
    }

    // For existing plot holders to get added to Mini-game
    function addFreeVineyard(address adr) initializedMarket public {
        require(msg.sender == ceoAddress);
        require(vineyardVines[adr] == 0);
        createPlotVineyard(adr);
    }

    function createPlotVineyard(address player) private {
        lastHarvest[player] = now;
        vineyardVines[player] = STARTING_VINES;
        wineProductionRate[player] = 1;
        landMultiplier[player] = 1;
        totalVineCapacity[player] = VINE_CAPACITY_PER_LAND;
    }

    function setLandProductionMultiplier(address adr) public {
        landMultiplier[adr] = SafeMath.add(1,SafeMath.add(landContract.addressToNumVillages(adr),SafeMath.add(SafeMath.mul(landContract.addressToNumTowns(adr),3),SafeMath.mul(landContract.addressToNumCities(adr),9))));
        totalVineCapacity[adr] = SafeMath.mul(landMultiplier[adr],VINE_CAPACITY_PER_LAND);
    }

    function setLandProductionMultiplierCCUser(bytes32 user, address adr) public {
        require(msg.sender == ceoAddress);
        landMultiplier[adr] = SafeMath.add(1,SafeMath.add(landContract.userToNumVillages(user), SafeMath.add(SafeMath.mul(landContract.userToNumTowns(user), 3), SafeMath.mul(landContract.userToNumCities(user), 9))));
        totalVineCapacity[adr] = SafeMath.mul(landMultiplier[adr],VINE_CAPACITY_PER_LAND);
    }

    function getBalance() public view returns(uint256) {
        return this.balance;
    }

    function getMyVines() public view returns(uint256) {
        return vineyardVines[msg.sender];
    }

    function getMyGrapes() public view returns(uint256) {
        return SafeMath.add(purchasedGrapes[msg.sender],getGrapesSinceLastHarvest(msg.sender));
    }

    function getMyWine() public view returns(uint256) {
        return wineInCellar[msg.sender];
    }

    function getWineProductionRate() public view returns(uint256) {
        return wineProductionRate[msg.sender];
    }

    function getGrapesSinceLastHarvest(address adr) public view returns(uint256) {
        uint256 secondsPassed = SafeMath.sub(now, lastHarvest[adr]);
        return SafeMath.mul(secondsPassed, SafeMath.mul(vineyardVines[adr], SafeMath.add(1,SafeMath.div(SafeMath.sub(landMultiplier[adr],1),5))));
    }

    function getMyLandMultiplier() public view returns(uint256) {
        return landMultiplier[msg.sender];
    }

    function getGrapesToBuildWinery() public view returns(uint256) {
        return grapesToBuildWinery;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

}

contract LandInterface {
    function addressToNumVillages(address adr) public returns (uint256);
    function addressToNumTowns(address adr) public returns (uint256);
    function addressToNumCities(address adr) public returns (uint256);

    function userToNumVillages(bytes32 userId) public returns (uint256);
    function userToNumTowns(bytes32 userId) public returns (uint256);
    function userToNumCities(bytes32 userId) public returns (uint256);
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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