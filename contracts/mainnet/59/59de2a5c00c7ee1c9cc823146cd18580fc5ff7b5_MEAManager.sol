pragma solidity ^0.4.19;



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<span class="__cf_email__" data-cfemail="a5c1c0d1c0e5c4ddcccac8dfc0cb8bc6ca">[email&#160;protected]</span>> (https://github.com/dete)
contract CSCERC721 {
  // Required methods
  function balanceOf(address _owner) public view returns (uint256 balance) { 
      return 0;
      
  }
  function ownerOf(uint256 _tokenId) public view returns (address owner) { return;}

  function getCollectibleDetails(uint256 _assetId) external view returns(uint256 assetId, uint256 sequenceId, uint256 collectibleType, uint256 collectibleClass, bool isRedeemed, address owner) {
        assetId = 0;
        sequenceId = 0;
        collectibleType = 0;
        collectibleClass = 0;
        owner = 0;
        isRedeemed = false;
  }

   function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        return;
   }

}

contract CSCFactoryERC721 {
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) { return;}

    function getCollectibleDetails(uint256 _tokenId) external view returns(uint256 assetId, uint256 sequenceId, uint256 collectibleType, uint256 collectibleClass, bytes32 collectibleName, bool isRedeemed, address owner) {

        assetId = 0;
        sequenceId = 0;
        collectibleType = 0;
        collectibleClass = 0;
        owner = 0;
        collectibleName = 0x0;
        isRedeemed = false;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        return;
   }
}

contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract CSCResourceFactory {
    mapping(uint16 => address) public resourceIdToAddress; 
}


contract MEAHiddenLogic {


    function getTotalTonsClaimed() external view returns(uint32) {
        return;
    }

    function getTotalSupply() external view returns(uint32) {
        return;
    }

     function getStarTotalSupply(uint8 _starId) external view returns(uint32) {
        return;
    }

    function getReturnTime(uint256 _assetId) external view returns(uint256 time) {
        return;
    }

    //uint256 iron, uint256 quartz, uint256 nickel, uint256 cobalt, uint256 silver, uint256 titanium, uint256 lucinite, uint256 gold, uint256 cosmethyst, uint256 allurum,  uint256 platinum,  uint256 trilite 
    function setResourceForStar(uint8[5] _resourceTypes, uint16[5] _resourcePer, uint32[5] _resourceAmounts) public returns(uint8 starId) {
    }

    
    /// @dev Method to fetch collected ore details
    function getAssetCollectedOreBallances(uint256 _assetID) external view returns(uint256 iron, uint256 quartz, uint256 nickel, uint256 cobalt, uint256 silver, uint256 titanium, uint256 lucinite, uint256 gold, uint256 cosmethyst, uint256 allurum,  uint256 platinum,  uint256 trilite);

    function getAssetCollectedOreBallancesArray(uint256 _assetID) external view returns(uint256[12] ores);

    function emptyShipCargo(uint32 _assetId) external;

     /// @dev For creating CSC Collectible
    function startMEAMission(uint256 _assetId, uint256 oreMax, uint8 starId, uint256 _travelTime) public returns(uint256);

    
}

/* Controls state and access rights for contract functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    // Facilitates access & control for the game.
    // Roles:
    //  -The Managers (Primary/Secondary): Has universal control of all elements (No ability to withdraw)
    //  -The Banker: The Bank can withdraw funds and adjust fees / prices.
    //  -otherManagers: Contracts that need access to functions for gameplay

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    /// @dev Emited when other manager is set
    event OtherManagerUpdated(address otherManager, uint256 state);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

    // Contracts that require access for gameplay
    mapping(address => uint8) public otherManagers;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Keeps track whether the contract erroredOut. When that is true, most actions are blocked & refund can be claimed
    bool public error = false;

    /// @dev Operation modifiers for limiting access
    modifier onlyManager() {
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier onlyOtherManagers() {
        require(otherManagers[msg.sender] == 1);
        _;
    }


    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

    /// @dev Assigns a new address to act as the Other Manager. (State = 1 is active, 0 is disabled)
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require(_newOp != address(0));

        otherManagers[_newOp] = _state;

        OtherManagerUpdated(_newOp,_state);
    }

    /// @dev Assigns a new address to act as the Primary Manager.
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

    /// @dev Assigns a new address to act as the Secondary Manager.
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

    /// @dev Assigns a new address to act as the Banker.
    function setBanker(address _newBK) external onlyManager {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract has Error
    modifier whenError {
        require(error);
        _;
    }

    /// @dev Called by any Operator role to pause the contract.
    /// Used only if a bug or exploit is discovered (Here to limit losses / damage)
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function unpause() public onlyManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function hasError() public onlyManager whenPaused {
        error = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

contract MEAManager is OperationalControl {

    /*** EVENTS ***/

    /*** CONSTANTS ***/
    uint256 public constant REAPER_INTREPID = 3; 
    uint256 public constant REAPER_INTREPID_EXTRACTION_BASE = 10; // tons per hour of mining
    uint256 public constant REAPER_INTREPID_FTL_SPEED = 900; // Seconds to travel 1 light year
    uint256 public constant REAPER_INTREPID_MAX_CARGO = 320;

    uint256 public constant PHOENIX_CORSAIR = 2;
    uint256 public constant PHOENIX_CORSAIR_EXTRACTION_BASE = 40; // tons per hour of mining
    uint256 public constant PHOENIX_CORSAIR_FTL_SPEED = 1440; // Seconds to travel 1 light year
    uint256 public constant PHOENIX_CORSAIR_MAX_CARGO = 1500;

    uint256 public constant VULCAN_PROMETHEUS = 1;
    uint256 public constant VULCAN_PROMETHEUS_EXTRACTION_BASE = 300; // tons per hour of mining
    uint256 public constant VULCAN_PROMETHEUS_FTL_SPEED = 2057; // Seconds to travel 1 light year
    uint256 public constant VULCAN_PROMETHEUS_MAX_CARGO = 6000; 

    uint256 public constant SIGMA = 4;
    uint256 public constant SIGMA_EXTRACTION_BASE = 150; // tons per hour of mining
    uint256 public constant SIGMA_FTL_SPEED = 4235; // Seconds to travel 1 light year
    uint256 public constant SIGMA_MAX_CARGO = 15000; 

    uint256 public constant HAYATO = 5;
    uint256 public constant HAYATO_EXTRACTION_BASE = 150; // tons per hour of mining
    uint256 public constant HAYATO_FTL_SPEED = 360; // Seconds to travel 1 light year
    uint256 public constant HAYATO_MAX_CARGO = 1500; 

    uint256 public constant CPGPEREGRINE = 6;
    uint256 public constant CPGPEREGRINE_EXTRACTION_BASE = 150; // tons per hour of mining
    uint256 public constant CPGPEREGRINE_FTL_SPEED = 720; // Seconds to travel 1 light year
    uint256 public constant CPGPEREGRINE_MAX_CARGO = 4000; 

    uint256 public constant TACTICALCRUISER = 7;
    uint256 public constant TACTICALCRUISER_EXTRACTION_BASE = 150; // tons per hour of mining
    uint256 public constant TACTICALCRUISER_FTL_SPEED = 720; // Seconds to travel 1 light year
    uint256 public constant TACTICALCRUISER_MAX_CARGO = 1000;

    uint256 public constant OTHERCRUISER = 8;
    uint256 public constant OTHERCRUISER_EXTRACTION_BASE = 100; // tons per hour of mining
    uint256 public constant OTHERCRUISER_FTL_SPEED = 720; // Seconds to travel 1 light year
    uint256 public constant OTHERCRUISER_MAX_CARGO = 1500;  

    uint256 public constant VULCAN_POD = 9;
    uint256 public constant VULCAN_POD_EXTRACTION_BASE = 1; // tons per hour of mining
    uint256 public constant VULCAN_POD_FTL_SPEED = 2000; // Seconds to travel 1 light year
    uint256 public constant VULCAN_POD_MAX_CARGO = 75;  

    //For Devs to Travel Around
    uint256 public constant DEVCLASS = 99;
    uint256 public constant DEVCLASS_EXTRACTION_BASE = 50; // tons per hour of mining
    uint256 public constant DEVCLASS_FTL_SPEED = 10; // Seconds to travel 1 light year
    uint256 public constant DEVCLASS_MAX_CARGO = 500; 
    
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant NAME = "MEAGameManager";

    /*** Mappings ***/

     /// @dev assetID to ore type to qty collected
    mapping(uint32 => mapping(uint8 => uint32)) public collectedOreAssetMapping;

    /// @dev owner address to ore type to qty collected
    mapping(address => mapping(uint8 => uint32)) public collectedOreBalanceMapping;

    /// @dev owner address to ore type to qty collected
    mapping(address => mapping(uint8 => uint32)) public distributedOreBalanceMapping;

    /// @dev assetID to number of MEA trips it has completed
    mapping(uint32 => uint32) public assetIdNumberOfTripsMapping;

    /// @dev assetID to ore type to qty collected
    mapping(uint8 => uint16) public starLightyearDistanceMapping;

    /// @dev assetID to last star visited
    mapping(uint32 => uint8) public assetIdToStarVisitedMapping;

    /// @dev assetID to last star visited
    mapping(uint16 => address) public resourceERC20Address;

    /// @dev assetID to Start Time of Current Trip
    mapping(uint32 => uint32) public assetIdCurrentTripStartTimeMapping;


    /*** Variables ***/
    uint256 public miningTimePerTrip = 3600; // 3600 for 1 hour 10
    uint256 public aimeIncreasePerTrip = 2500; // 25.00

    address cscERC721Address;
    address cscFactoryERC721Address;
    address hiddenLogicAddress;
 

    function MEAManager() public {
        require(msg.sender != address(0));
        paused = true; 
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;
        cscERC721Address = address(0xe4f5e0d5c033f517a943602df942e794a06bc123);
        cscFactoryERC721Address = address(0xcc9a66acf8574141b0e025202dd57649765a4be7);
    }

    /*** Management Functions ***/

    /// @dev Set HiddenLogic
    function setHiddenLogic(address _hiddenLogicAddress) public onlyManager {
        hiddenLogicAddress = _hiddenLogicAddress;
    }

    /// @dev Set HiddenLogic
    function setResourceERC20Address(uint16 _resId, address _reourceAddress) public onlyManager {
        resourceERC20Address[_resId] = _reourceAddress;
    }

    /// @dev Set HiddenLogic
    function setAllResourceERC20Addresses(address _master) public onlyManager {
        CSCResourceFactory factory = CSCResourceFactory(_master);
        for(uint8 i = 0; i < 12; i++) {
            resourceERC20Address[i] = factory.resourceIdToAddress(i);
        }
    }

    /// @dev Set CSCErc721 Contract
    function setCSCERC721(address _cscERC721Address) public onlyManager {
        cscERC721Address = _cscERC721Address;
    }

     /// @dev Set CSCFactoryErc721 Contract
    function setCSCFactoryERC721(address _cscFactoryERC721Address) public onlyManager {
        cscFactoryERC721Address = _cscFactoryERC721Address;
    }

    /// @dev Set / Modify Lightyear Distance 3.456 ly = 3456
    function setStarDistance(uint8 _starId, uint16 _lightyearsInThousands) public anyOperator {
        starLightyearDistanceMapping[_starId] = _lightyearsInThousands;
    }

    /// @dev Set / Modify MEA Game Attributes
    function setMEAAttributes(uint256 _aime, uint256 _miningTime) public onlyManager {
        aimeIncreasePerTrip = _aime;
        miningTimePerTrip = _miningTime;
    }

    /// @dev Withdraw Remaining Resource Tokens
    function reclaimResourceDeposits(address _withdrawAddress) public onlyManager {
        require(_withdrawAddress != address(0));
        for(uint8 ii = 0; ii < 12; ii++) {
            if(resourceERC20Address[ii] != 0) {
                ERC20 resCont = ERC20(resourceERC20Address[ii]);
                uint256 bal = resCont.balanceOf(this);
                resCont.transfer(_withdrawAddress, bal);
            }
        }
    }

    /*** Public Functions ***/

     /// @dev Get Current Cargo Hold of AssetId (item names)
    function getAssetIdCargo(uint32 _assetId) public view returns(uint256 iron, uint256 quartz, uint256 nickel, uint256 cobalt, uint256 silver, uint256 titanium, uint256 lucinite, uint256 gold, uint256 cosmethyst, uint256 allurum,  uint256 platinum,  uint256 trilite) {
        uint256[12] memory _ores = getAssetIdCargoArray(_assetId);
        iron = _ores[0];
        quartz = _ores[1];
        nickel = _ores[2];
        cobalt = _ores[3];
        silver = _ores[4];
        titanium = _ores[5];
        lucinite = _ores[6];
        gold = _ores[7];
        cosmethyst = _ores[8];
        allurum = _ores[9];
        platinum = _ores[10];
        trilite = _ores[11];
    }

    // function getAllShipStats(uint32[] _shipIds) public view returns(uint32[] results) {
    //     //loop all results
    //     for(uint i = 0; i < _shipIds.length; i++) {
    //         results[]];
    //     }

    // }

    /// @dev Get Current Cargo Hold of AssetId (array)
    function getAssetIdCargoArray (uint32 _assetId) public view returns(uint256[12])  {
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);
        return logic.getAssetCollectedOreBallancesArray(_assetId);
    }

    /// @dev Get AssetId Trip Completed Time
    function getAssetIdTripCompletedTime(uint256 _assetId) external view returns(uint256 time) {
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);
        return logic.getReturnTime(uint32(_assetId));
    }

    /// @dev Get AssetId Trip Completed Time
    function getAssetIdTripStartTime(uint256 _assetId) external view returns(uint256 time) {

        return assetIdCurrentTripStartTimeMapping[uint32(_assetId)];
    }

    function getLastStarOfAssetId(uint32 _assetId) public view returns(uint8 starId){
        return assetIdToStarVisitedMapping[_assetId];
    }

    /// @dev Get Resource Address
    function getResourceERC20Address(uint16 _resId) public view returns(address resourceContract) {
        return resourceERC20Address[_resId];
    }

    /// @dev Get Time
    function getMEATime() external view returns(uint256 time) {
        return now;
    }

    /// @dev Method to fetch processed ore details
    function getCollectedOreBalances(address _owner) external view returns(uint256 iron, uint256 quartz, uint256 nickel, uint256 cobalt, uint256 silver, uint256 titanium, uint256 lucinite, uint256 gold, uint256 cosmethyst, uint256 allurum,  uint256 platinum,  uint256 trilite) {

        iron = collectedOreBalanceMapping[_owner][0];
        quartz = collectedOreBalanceMapping[_owner][1];
        nickel = collectedOreBalanceMapping[_owner][2];
        cobalt = collectedOreBalanceMapping[_owner][3];
        silver = collectedOreBalanceMapping[_owner][4];
        titanium = collectedOreBalanceMapping[_owner][5];
        lucinite = collectedOreBalanceMapping[_owner][6];
        gold = collectedOreBalanceMapping[_owner][7];
        cosmethyst = collectedOreBalanceMapping[_owner][8];
        allurum = collectedOreBalanceMapping[_owner][9];
        platinum = collectedOreBalanceMapping[_owner][10];
        trilite = collectedOreBalanceMapping[_owner][11];
    }

    /// @dev Method to fetch processed ore details
    function getDistributedOreBalances(address _owner) external view returns(uint256 iron, uint256 quartz, uint256 nickel, uint256 cobalt, uint256 silver, uint256 titanium, uint256 lucinite, uint256 gold, uint256 cosmethyst, uint256 allurum,  uint256 platinum,  uint256 trilite) {

        iron = distributedOreBalanceMapping[_owner][0];
        quartz = distributedOreBalanceMapping[_owner][1];
        nickel = distributedOreBalanceMapping[_owner][2];
        cobalt = distributedOreBalanceMapping[_owner][3];
        silver = distributedOreBalanceMapping[_owner][4];
        titanium = distributedOreBalanceMapping[_owner][5];
        lucinite = distributedOreBalanceMapping[_owner][6];
        gold = distributedOreBalanceMapping[_owner][7];
        cosmethyst = distributedOreBalanceMapping[_owner][8];
        allurum = distributedOreBalanceMapping[_owner][9];
        platinum = distributedOreBalanceMapping[_owner][10];
        trilite = distributedOreBalanceMapping[_owner][11];
    }

    function withdrawCollectedResources() public {

        for(uint8 ii = 0; ii < 12; ii++) {
            require(resourceERC20Address[ii] != address(0));
            uint32 oreOutstanding = collectedOreBalanceMapping[msg.sender][ii] - distributedOreBalanceMapping[msg.sender][ii];
            if(oreOutstanding > 0) {
                ERC20 resCont = ERC20(resourceERC20Address[ii]);
                distributedOreBalanceMapping[msg.sender][ii] += oreOutstanding;
                resCont.transfer(msg.sender, oreOutstanding);
            }
        }

    }

    //Gets star distance in thousandths of ly
    function getStarDistanceInLyThousandths(uint8 _starId) public view returns (uint32 total) {
        return starLightyearDistanceMapping[_starId];
    }
    
    //Gets total resources already claimed by commanders
    function totalMEATonsClaimed() public view returns (uint32 total) {
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);
        return logic.getTotalTonsClaimed();
    }

    //Gets total seeded supply commanders
    function totalMEATonsSupply() public view returns (uint32 total) {
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);
        return logic.getTotalSupply();
    }

     function totalStarSupplyRemaining(uint8 _starId) external view returns(uint32) {
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);
        return logic.getStarTotalSupply(_starId);
    }

    function claimOreOnlyFromAssetId(uint256 _assetId) {
        uint256 collectibleClass = 0;
        address shipOwner;
        (collectibleClass, shipOwner) = _getShipInfo(_assetId);

         require(shipOwner == msg.sender);

        _claimOreAndClear(uint32(_assetId), 0);
    }
    /// @dev For creating CSC Collectible
    function launchShipOnMEA(uint256 _assetId, uint8 starId) public whenNotPaused returns(uint256) {
        
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);

        uint256 collectibleClass = 0;
        address shipOwner;

        (collectibleClass, shipOwner) = _getShipInfo(_assetId);

        //Check if the ship owner is sender
        require(shipOwner == msg.sender);

        //Check if ship is back at earth
        require(now > logic.getReturnTime(_assetId));
        
        //Claims ore and clears
        _claimOreAndClear(uint32(_assetId), starId);

        //Get Asset Stats
        uint tripCount = assetIdNumberOfTripsMapping[uint32(_assetId)];
        uint starTripDist = starLightyearDistanceMapping[starId];
        uint256 oreMax = 5;
        uint256 tripSeconds = 10;

        if(collectibleClass == REAPER_INTREPID) {
            oreMax = REAPER_INTREPID_EXTRACTION_BASE + (REAPER_INTREPID_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = REAPER_INTREPID_FTL_SPEED * starTripDist / 1000; // 4LPH - 900 seconds per light year
            if(oreMax > REAPER_INTREPID_MAX_CARGO)
                oreMax = REAPER_INTREPID_MAX_CARGO;
        }
        else if(collectibleClass == PHOENIX_CORSAIR) {
            oreMax = PHOENIX_CORSAIR_EXTRACTION_BASE + (PHOENIX_CORSAIR_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = PHOENIX_CORSAIR_FTL_SPEED * starTripDist / 1000; // 2.5LPH - 1440 seconds per light year
            if(oreMax > PHOENIX_CORSAIR_MAX_CARGO)
                oreMax = PHOENIX_CORSAIR_MAX_CARGO;
        }
        else if(collectibleClass == VULCAN_PROMETHEUS) {
            oreMax = VULCAN_PROMETHEUS_EXTRACTION_BASE + (VULCAN_PROMETHEUS_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = VULCAN_PROMETHEUS_FTL_SPEED * starTripDist / 1000; // 1.75LPH - 2057 seconds per light year
            if(oreMax > VULCAN_PROMETHEUS_MAX_CARGO)
                oreMax = VULCAN_PROMETHEUS_MAX_CARGO;
        }
        else if(collectibleClass == SIGMA) {
            oreMax = SIGMA_EXTRACTION_BASE + (SIGMA_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = SIGMA_FTL_SPEED * starTripDist / 1000; // 0.85LPH - 4235 seconds per light year
            if(oreMax > SIGMA_MAX_CARGO)
                oreMax = SIGMA_MAX_CARGO;
        }
        else if(collectibleClass == HAYATO) { //Hayato
            oreMax = HAYATO_EXTRACTION_BASE + (HAYATO_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = HAYATO_FTL_SPEED * starTripDist / 1000; // 10LPH - 360 seconds per light year
            if(oreMax > HAYATO_MAX_CARGO)
                oreMax = HAYATO_MAX_CARGO;
        }
        else if(collectibleClass == CPGPEREGRINE) { //CPG Peregrine
            oreMax = CPGPEREGRINE_EXTRACTION_BASE + (CPGPEREGRINE_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = CPGPEREGRINE_FTL_SPEED * starTripDist / 1000; // 5LPH -720 seconds per light year
            if(oreMax > CPGPEREGRINE_MAX_CARGO)
                oreMax = CPGPEREGRINE_MAX_CARGO;
        }
        else if(collectibleClass == TACTICALCRUISER) { //TACTICA CRUISER Ships
            oreMax = TACTICALCRUISER_EXTRACTION_BASE + (TACTICALCRUISER_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = TACTICALCRUISER_FTL_SPEED * starTripDist / 1000; 
            if(oreMax > TACTICALCRUISER_MAX_CARGO)
                oreMax = TACTICALCRUISER_MAX_CARGO;
        }
        else if(collectibleClass == VULCAN_POD) { //TACTICA CRUISER Ships
            oreMax = VULCAN_POD_EXTRACTION_BASE + (VULCAN_POD_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = VULCAN_POD_FTL_SPEED * starTripDist / 1000; 
            if(oreMax > VULCAN_POD_MAX_CARGO)
                oreMax = VULCAN_POD_MAX_CARGO;
        }
        else if(collectibleClass >= DEVCLASS) { //Dev Ships
            oreMax = DEVCLASS_EXTRACTION_BASE + (DEVCLASS_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
            tripSeconds = DEVCLASS_FTL_SPEED * starTripDist / 1000;
            if(oreMax > DEVCLASS_MAX_CARGO)
                oreMax = DEVCLASS_MAX_CARGO;
        } else {
            if(collectibleClass >= OTHERCRUISER) { //Support Other Promo Ships
                oreMax = OTHERCRUISER_EXTRACTION_BASE + (OTHERCRUISER_EXTRACTION_BASE * tripCount * aimeIncreasePerTrip / 10000);
                tripSeconds = OTHERCRUISER_FTL_SPEED * starTripDist / 1000; 
                if(oreMax > OTHERCRUISER_MAX_CARGO)
                    oreMax = OTHERCRUISER_MAX_CARGO;
            }
        }

        //Make Round Trip + Mining
        tripSeconds = ((tripSeconds * 2) + miningTimePerTrip); //3600 for an hour - 0 for testing ***************************

        //calculate travel time
        uint256 returnTime = logic.startMEAMission(_assetId, oreMax, starId, tripSeconds);

        //Confirm trip
        if(returnTime > 0) {
            assetIdNumberOfTripsMapping[uint32(_assetId)] += 1;
            assetIdToStarVisitedMapping[uint32(_assetId)] = starId;
            assetIdCurrentTripStartTimeMapping[uint32(_assetId)] = uint32(now);
        }
        
        return returnTime;
    }


    /*** PRIVATE FUNCTIONS ***/

    /// @dev  Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) internal pure returns (bool) {
        return _to != address(0);
    }

    /// @dev  Claims and clears cargo -- ONLY INTERNAL
    function _claimOreAndClear (uint32 _assetId, uint8 _starId) internal {
        MEAHiddenLogic logic = MEAHiddenLogic(hiddenLogicAddress);
        uint256[12] memory _ores = logic.getAssetCollectedOreBallancesArray(_assetId);
        bool hasItems = false;

        for(uint8 i = 0; i < 12; i++) {
            if(_ores[i] > 0) {
                collectedOreBalanceMapping[msg.sender][i] += uint32(_ores[i]);
                hasItems = true;
            }
        }

        //Doesn&#39;t Let you Travel to empty stars but lets you collect
        if(hasItems == false && _starId > 0) {
            require(logic.getStarTotalSupply(_starId) > 0);
        }

        logic.emptyShipCargo(_assetId);
    }

    function _getShipInfo(uint256 _assetId) internal view returns (uint256 collectibleClass, address owner) {
        
        uint256 nulldata;
        bool nullbool;
        uint256 collectibleType;

        if(_assetId <= 3000) {
            CSCERC721 shipData = CSCERC721(cscERC721Address);
            (nulldata, nulldata, collectibleType, collectibleClass, nullbool, owner) = shipData.getCollectibleDetails(_assetId);
        } else {
            bytes32 nullstring;
            CSCFactoryERC721 shipFData = CSCFactoryERC721(cscFactoryERC721Address);
            (nulldata, nulldata, collectibleType, collectibleClass, nullstring, nullbool, owner) = shipFData.getCollectibleDetails(_assetId);
        }

    }

    
    
    
    
}