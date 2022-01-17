// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./HauntedHouseLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
* @title House Game
* @notice A contract that allow users to stack ETH
*/

contract HouseGame {

    // Contract's Attributes
    using SafeMath for uint256;
    using Strings for uint256;

    address public manager1 = 0x24ba13E030757aeC2Af3e37e8ebF150f2bFF79Fc;
    address public manager2 = 0x561A4B4abA4D1A5F4424E8B4BCAE432F50456d6d;

    // Address set in the constructor for giving privileges to some functions
    address public creatorAddress;


    // ERC20 address - game currency contract
    address public oniCoinAddress; 

    // The starting ID for loot box items. Items ids and loot box items ids share the same mapping.
    uint256[1] public startIndexForLootedAttr = [10000000];

    // Upper threshold for the amount of lootboxes
    uint256[1] public maxIndexForLootedAttr = [20000000];

    // Cost to buy a new lootbox - check if there is unit tests
    uint256[1] public amountToBuyLootBox = [10 ether];

    // Holds the unix timestamp of the day the game start + the amount in seconds for each day.
    // (The amount in seconds can be set by the controler, so it does not always needs to be 84600)
    uint256[1] public currentDayUnix = [0];

    // CurrentDayInt[0] -> Which day the game is on. It goes from 0-20.
    // CurrentDayInt[1] -> Holds the timestamp of the block that changed the day. This here is used
    // in the daily check in function to perform a check when incrementing the day.
    uint256[2] public currentDayInt = [0,0];

    // Amount in secods that a day last in the game.
    uint256[1] public dayInSeconds;

    // Address set in the constructor for giving privileges to some functions
    address public owner;

    // Holds which NFT IDS can be specific haunted for a specific day.
    // specificHauntMissionNFTIDs[DAY][NFT_ADDRESS]
    mapping(uint256 => mapping(address => uint256[])) public specificHauntMissionNFTIDs; // day to nftAddres to IDS

    // Holds which attributes Ids for the house a specific NFT has.
    mapping(address => mapping(uint256 => uint256[])) public nftToAttrsIDS;

    // Holds the information of who is the msg.sender that open a loot box of id XXXX.
    mapping(uint256 => address) public lootedBoxtoAddress;

    // This mapping is used exclusevily in the openLootBox function. We are creating positions for each nft 
    // loot box item that he opened and using this information to know he already open lootbox for that position.
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public nftIdToLootBoxPositionToOpened;

    // This mapping is used exclusevily in the openLootBox function. We are creating positions for each nft 
    // loot box item that he opened and assgning the ID of that ATTR to that position.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public nftIdToLootBoxPositionToLootedAttrId;

    // Holds the information of how much a house Attr costs.
    mapping(uint256 => uint256) public idToPrice;


    // Holds the information if that NFT Contract Address is allowed to play the game
    mapping(address => bool) public allowedNFTContracts; 

    // Holds the information if that NFT already performed check in on that day.
    // nftLastCheckIn[NFT_CONTRACT_ADDRESS][NFT_ID][EVENT_DAY]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public nftLastCheckIn; 


    // Store if NFT already performed generic haunting for that day.
    // dailyGenericHauntingMission[NFT_CONTRACT_ADDRESS][NFT_ID][EVENT_DAY]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public dailyGenericHauntingMission;

    // Store if NFT already performed specific haunting for that day.
    // dailySpecificHauntingMission[NFT_CONTRACT_ADDRESS][NFT_ID][EVENT_DAY]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public dailySpecificHauntingMission;

    // Store if NFT already claimed the weekly bonus today. This was required so that the player
    // would not be able to perform the daily missions after he claimed the weekly bonus
    // claimedWeeklyBonusToday[NFT_CONTRACT_ADDRESS][NFT_ID][EVENT_DAY]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public claimedWeeklyBonusToday; 

    // Store if NFT already claimed the daily bonus today.
    // claimedDailyBonusToday[NFT_CONTRACT_ADDRESS][NFT_ID][EVENT_DAY]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public claimedDailyBonusToday;

    // Store how many missions are player already performed.
    mapping(address => mapping(uint256 => uint256)) public missionCounter;

    // Store how many times an nft has been haunted on that event day.
    // timesNFTHauntedOnDay[EVENT_DAY][NFT_ADDRESS][NFT_ID]
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public timesNFTHauntedOnDay;

    // Store how many times NFT has been hgaunted.
    mapping(address => mapping(uint256 => uint256)) public timesNFTHasBeenHaunted;

    // Track which nft contract has ever interacted in our game
    mapping(address => mapping(uint256 => address)) public interactedNFTToOwner;

    // Maps the ownership on other Blockchains to our game to enable users to play.
    mapping(address => mapping(uint256 => address)) public mappedNFTToOwner;

    // Contract Events

    event UpdatedOwnership(address indexed _nftContractAddress, uint256 indexed _nftID, address indexed _newOwner);
    event DayChangedTo(uint indexed _current_day);

    // Contract Structs

    // Holds the owner and id of an nft.
    struct NFTOwnership {
        address owner;
        uint id;
    }

    // Contract's Constructor
    /**
    * @notice Contract Constructor
    * @param _unixGameStartDate exact game starting day in unix. Every new other day will start after N _dayInSeconds.
    * @param _creatorAddress Creator and Owner Address of this contract.
    * @param _dayInSeconds how many seconds a day last for the game.
    */
    constructor(
        uint256 _unixGameStartDate,
        address _creatorAddress,
        uint256 _dayInSeconds
    ) {
        currentDayUnix[0] = _unixGameStartDate;
        dayInSeconds[0] = _dayInSeconds;
        creatorAddress = _creatorAddress;
        owner = _creatorAddress;
    }


    // Contract's Modifiers
    /**
    * @notice Modifier that only owner to perform this action.
    */
    modifier onlyOwner() {
        require(
            msg.sender == creatorAddress,
            "Only owner can perform this action"
        );
        _;
    }

    modifier onlyManagers() {
        require(
            msg.sender == creatorAddress || msg.sender == manager1 || msg.sender == manager2,
            "You can't perform this action"
        );
        _;
    }

    /**
    * @notice Modifier that checks if msg.sender is the owner of the NFT.
    * @param _nftAddress NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    modifier notNFTOwner(address _nftAddress, uint _nftID) {
        require(
            mappedNFTToOwner[_nftAddress][_nftID] == msg.sender,
            "You are not the owner of this NFT"
        );
        _;
    }

    /**
    * @notice Modifier that checks the daily check in was already done.
    * @param _nftContract NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    modifier dailyCheckInNotDoneYet(address _nftContract, uint _nftID ) {
        require(nftLastCheckIn[_nftContract][_nftID][currentDayInt[0]] == true,
            "Daily check in not done yet."
        );
        _;
    }

    /**
    * @notice Modifier that checks the maximum times has been reach for an NFT that is suffering haunting.
    * @param _nftContract NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    modifier nftAlreadyHauntedManyTimesToday(address _nftContract, uint _nftID ) {
        require(
            timesNFTHauntedOnDay[currentDayInt[0]][_nftContract][_nftID] < 5,
            "This oni was already haunted 5 times today"
        );
        _;
    }

    /**
    * @notice Modifier that checks if action is being performed on the correct game event day.
    * @param _eventDay game event day.
    */
    modifier notSameGameDay(uint _eventDay) {
        require(
            currentDayInt[0] == _eventDay,
            "You can't haunt an NFT for this day yet."
        );
        _;
    }

    /**
    * @notice Modifier that checks if trying to perform some action after weekly bonus has been claimed.
    * @param _nftContract NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    modifier cantAfterClaimWeeklyBonus(address _nftContract, uint _nftID) {
        require(
            claimedWeeklyBonusToday[_nftContract][_nftID][
                currentDayInt[0]
            ] == false,
            "You can't haunt again if you performed weekly bonus claim today"
        );
        _;
    }

    // Contract's Getters
    /**
    * @notice Returns all house attribute ids of that NFT
    * @param _nftContract NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    function getHouseAttrs(address _nftContract, uint256 _nftID)
        external
        view
        returns (uint256[] memory)
    {
        return HauntedHouseLibrary.getHouseAttrs(_nftContract, _nftID, nftToAttrsIDS);
    }

    /**
    * @notice Returns all the IDs of a specific NFT contract that can be used in specific haunting for an event day.
    * @param _eventDay event day.
    * @param _nftContract NFT contract address in any blockchain
    */
    function getSpecificHauntMissionNFTIDs(
        uint256 _eventDay,
        address _nftContract
    ) external view returns (uint256[] memory) {
        return HauntedHouseLibrary.getSpecificHauntMissionNFTIDs(_eventDay, _nftContract, specificHauntMissionNFTIDs);
    }

    /**
    * @notice Returns all the IDs with owner address for the following NFT.
    * @param _nftContract NFT contract Address.
    * @param _arraySize number of owners from 0 that you are requesting.
    */
    function getNFTsOwnershipData(
        address _nftContract,
        uint _arraySize
    ) external view returns (NFTOwnership[] memory) {
        NFTOwnership[] memory nftOwnershipArray = new NFTOwnership[](_arraySize);

        for (uint256 i = 0; i < _arraySize; i++) {
            nftOwnershipArray[i] = NFTOwnership(mappedNFTToOwner[_nftContract][i], i);
        }

        return nftOwnershipArray;
    }

    /**
    * @notice Returns true if user can retrieve Bonus.
    * @param _nftContract NFT contract Address.
    * @param _nftID NFT ID for that contract address.
    */
    function canUserGetStreakBonus(address _nftContract, uint _nftID) external view returns (bool) {
        return HauntedHouseLibrary.canUserGetStreakBonus(
          _nftContract, 
          _nftID, 
          dailyGenericHauntingMission,
          dailySpecificHauntingMission
        );
    }

    // Contract's Setters
    /**
    * @notice Set managers address.
    * @param _newAddress new value in matic.
    */
    function setManagerAddress(uint _pos, address _newAddress) external onlyOwner {
      if(_pos == 1) {
        manager1 = _newAddress;
      }
      if(_pos == 2) {
        manager2 = _newAddress;
      }
    }
    /**
    * @notice Sets how much costs to buy a loot box in Matic.
    * @param _newValue new value in matic.
    */
    function setAmountToBuyLootBox(
        uint256 _newValue
    ) external onlyManagers() {
        amountToBuyLootBox[0] = _newValue;
    }

    /**
    * @notice Sets mission counter for a specific NFT.
    * @param _nftContract NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    * @param _value number to set the mission counter.
    */
    function setMissionCounter(
        address _nftContract,
        uint256 _nftID,
        uint256 _value
    ) external onlyOwner() {
        missionCounter[_nftContract][_nftID] = _value;
    }

    /**
    * @notice Sets the upper threshold of how many loot box items there will be for game.
    * @param _newValue number to set the upper threshold.
    */
    function setMaxIndexForLootedAttr(uint _newValue) 
    external onlyManagers() {
        maxIndexForLootedAttr[0] = _newValue;
    }

    /**
    * @notice Sets all the IDs of a specific NFT contract that can be used in specific haunting for an event day.
    * @param _nftIds list of NFT IDS for that day.
    * @param _eventDay event day.
    * @param _nftContract NFT contract address in any blockchain
    */
    function setNFTIdsSpecificMission(
        uint256[] memory _nftIds,
        uint256 _eventDay,
        address _nftContract
    ) external onlyManagers() {
        specificHauntMissionNFTIDs[_eventDay][_nftContract] = _nftIds;
    }

    /**
    * @notice Sets which event game day are we on.
    * @param _currentDay event day.
    */
    // function setCurrentDayInt(uint256 _currentDay) external onlyOwner {
    //     currentDayInt[0] = _currentDay;
    // }

    /**
    * @notice Sets which event game day in unix timestamp are we on.
    * @param _currentDay event day.
    */
    // function setCurrentDayUnix(uint256 _currentDay) external onlyOwner {
    //     currentDayUnix[0] = _currentDay;
    // }

    /**
    * @notice Set ERC20 (game currency) coin address.
    * @param _oniCoinAddress Coin contract addresses.
    */
    function setOniCoinAddress(address _oniCoinAddress) external onlyOwner {
        oniCoinAddress = _oniCoinAddress;
    }

    /**
    * @notice Set House Attr price.
    * @param _attrID House attr id.
    * @param _price Haunted attr price in ERC20.
    */
    function setAttrPrice(uint256 _attrID, uint256 _price) public onlyManagers() {
        idToPrice[_attrID] = _price;
    }

    /**
    * @notice Sets House Attr price in batch.
    * @param _attrsIds House attr ids.
    * @param _attrsPrices Haunted attr prices in ERC20.
    */
    function setAttrsPrice(
        uint256[] memory _attrsIds,
        uint256[] memory _attrsPrices
    ) external onlyManagers() {
        HauntedHouseLibrary.setAttrsPrice(
        _attrsIds,
        _attrsPrices,
        idToPrice
        );
    }


    // Contracts owners restricted functions
    /**
    * @notice Sets/Maps the ownership of an NFT to some address.
    * @param _nftContract NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    * @param _ownerAddress owner address.
    */
    function updateNFTOwner(
        address _nftContract,
        uint256 _nftID,
        address _ownerAddress
    ) external onlyManagers() {
        HauntedHouseLibrary.updateNFTOwner(
            _nftContract,
            _nftID,
            _ownerAddress,
            allowedNFTContracts,
            mappedNFTToOwner
        );

        emit UpdatedOwnership(_nftContract, _nftID, _ownerAddress);
    }

    /**
    * @notice Sets/Maps the ownership of an NFT to some address in batches.
    * @param _contractAddresses NFT contract addresses in any blockchain
    * @param _nftIDS NFT IDs for that contract address.
    * @param _ownersAddresses owners addresses.
    */
    function updateOwners(
        address[] memory _contractAddresses,
        uint256[] memory _nftIDS,
        address[] memory _ownersAddresses
    ) external onlyManagers() {
        HauntedHouseLibrary.updateOwners(
            _contractAddresses,
            _nftIDS,
            _ownersAddresses,
            allowedNFTContracts,
            mappedNFTToOwner
        );

        for (uint256 i = 0; i < _nftIDS.length; i++) {
          emit UpdatedOwnership(_contractAddresses[i], _nftIDS[i], _ownersAddresses[i]);
        }
    }

    /**
    * @notice Enables NFT to play the game.
    * @param _nftContract Haunted House contract addresses.
    */
    function addNFTContract(address _nftContract) external onlyOwner() {
        allowedNFTContracts[_nftContract] = true;
    }


    // Contract's Daily Missions
    /**
    * @notice Performs daily check in for a specific NFT.
    * @param _nftAddress NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    function dailyCheckIn(address _nftAddress, uint256 _nftID) external {
        // Checks if the current block.timestamp is greater than the last time the day started + the amount of seconds in a day
        // AND if the clock that changed that day has changed because 2 players could be calling this funciton on the same block
        if (
            ((currentDayUnix[0] + dayInSeconds[0]) < block.timestamp)
                && (currentDayInt[1] != block.timestamp)

        ) {
            currentDayUnix[0] = currentDayUnix[0] + dayInSeconds[0];
            currentDayInt[0] = currentDayInt[0] + 1;
            currentDayInt[1] = block.timestamp;
            emit DayChangedTo(currentDayInt[0]);
        }
        HauntedHouseLibrary.dailyCheckIn(
            _nftAddress,
            _nftID,
            allowedNFTContracts,
            mappedNFTToOwner,
            interactedNFTToOwner,
            nftLastCheckIn,
            oniCoinAddress,
            currentDayInt,
            missionCounter
        );
    }

    /**
    * @notice This is one of the daily missions. Haunts any NFT in the game.
    * @param _nftHaunterContract NFT contract address that is performing the haunting.
    * @param _nftHaunterID NFT contract ID that is performing the haunting.
    * @param _nftHaunteeContract NFT contract address that is suffering the haunting.
    * @param _nftHaunteeID NFT contract ID that is suffering the haunting.
    * @param _eventDay event day that is executing the action.
    */
    function hauntGeneric(
        address _nftHaunterContract,
        uint256 _nftHaunterID,
        address _nftHaunteeContract,
        uint256 _nftHaunteeID,
        uint256 _eventDay
    ) external 
    notNFTOwner(_nftHaunterContract, _nftHaunterID) 
    dailyCheckInNotDoneYet(_nftHaunterContract, _nftHaunterID )
    nftAlreadyHauntedManyTimesToday( _nftHaunteeContract, _nftHaunteeID )
    notSameGameDay(_eventDay)
    {
        require(
            mappedNFTToOwner[_nftHaunteeContract][_nftHaunteeID] != msg.sender,
            "You can't haunt and nft that you own."
        );
        require(
            dailyGenericHauntingMission[_nftHaunterContract][_nftHaunterID][
                currentDayInt[0]
            ] == false,
            "Haunted Mission was already done today for this NFT."
        );
        require(
            claimedWeeklyBonusToday[_nftHaunterContract][_nftHaunterID][
                currentDayInt[0]
            ] == false,
            "You can't haunt again if you performed weekly bonus claim today"
        );

        dailyGenericHauntingMission[_nftHaunterContract][_nftHaunterID][currentDayInt[0]] = true;
        rewardHaunt(_nftHaunterContract, _nftHaunterID, _nftHaunteeContract, _nftHaunteeID );
    }

    /**
    * @notice This is one of the daily missions. Haunts a scpecific NFT in the game which the ID was set for this mission.
    * @param _nftHaunterContract NFT contract address that is performing the haunting.
    * @param _nftHaunterID NFT contract ID that is performing the haunting.
    * @param _nftHaunteeContract NFT contract address that is suffering the haunting.
    * @param _nftHaunteeID NFT contract ID that is suffering the haunting.
    * @param _eventDay event day that is executing the action.
    */
    function hauntSpecificNFT(
        address _nftHaunterContract,
        uint256 _nftHaunterID,
        address _nftHaunteeContract,
        uint256 _nftHaunteeID,
        uint256 _eventDay
    ) external 
    notNFTOwner(_nftHaunterContract, _nftHaunterID) 
    dailyCheckInNotDoneYet(_nftHaunterContract, _nftHaunterID )
    nftAlreadyHauntedManyTimesToday( _nftHaunteeContract,  _nftHaunteeID )
    notSameGameDay(_eventDay)
    {
        require(
            mappedNFTToOwner[_nftHaunteeContract][_nftHaunteeID] != msg.sender,
            "You can't haunt an nft that you own."
        );
        require(
            dailySpecificHauntingMission[_nftHaunterContract][_nftHaunterID][
                currentDayInt[0]
            ] == false,
            "Haunted Mission was already done today for this NFT."
        );
        require(
            claimedWeeklyBonusToday[_nftHaunterContract][_nftHaunterID][
                currentDayInt[0]
            ] == false,
            "You can't haunt again if you performed weekly bonus claim today"
        );

        require(
            checkIfHaunteeIdIsInSpecificDayMission(_nftHaunteeContract, _nftHaunteeID),
            "Haunted NFT ID does not have bounty trait."
        );
        dailySpecificHauntingMission[_nftHaunterContract][_nftHaunterID][currentDayInt[0]] = true;
        rewardHaunt(_nftHaunterContract, _nftHaunterID, _nftHaunteeContract, _nftHaunteeID );
    }


    // Contract's overall functions for game UI.
    /**
    * @notice Opens a loot box for that msg.sender and adds the attr into the players
    * house attr items.
    * @param _nftAddress NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    function openLootBox(
        address _nftAddress,
        uint256 _nftID
    ) external 
    notNFTOwner(_nftAddress,_nftID) {
        require(
            startIndexForLootedAttr[0] + 1 < maxIndexForLootedAttr[0],
            "Max Loot Box Open reached."
        );
        require(
            missionCounter[_nftAddress][_nftID] >= 21,
            "You need to have completed 21 missions or more."
        );

        uint256 amountOfMissionsDone = missionCounter[_nftAddress][_nftID];
        uint256 amountOfLootBoxes = amountOfMissionsDone.div(21) - 1;
        bool changed;

        for (uint256 i = 0; i <= amountOfLootBoxes; i++) {
            if (nftIdToLootBoxPositionToLootedAttrId[_nftAddress][_nftID][i] == 0) {
                nftIdToLootBoxPositionToLootedAttrId[_nftAddress][_nftID][i] = startIndexForLootedAttr[0];
                HauntedHouseLibrary.assignLootBoxItem(
                    _nftAddress, 
                    _nftID, 
                    lootedBoxtoAddress, 
                    nftToAttrsIDS,
                    startIndexForLootedAttr
                );
                changed = true;
            }
        }

        require(changed, "You can't claim yet");
    }

    /**
    * @notice Buy a loot box for that msg.sender for a value in matic and adds 
    * the attr into the players house attr items.
    * @param _nftAddress NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    */
    function buyLootBoxItem(
        address _nftAddress,
        uint256 _nftID
    ) external payable notNFTOwner(_nftAddress,_nftID) {
        require(
            msg.value >= amountToBuyLootBox[0],
            "Value paid is below the requested price in Matic."
        );
        require(
            startIndexForLootedAttr[0] + 1 < maxIndexForLootedAttr[0],
            "Max Loot Box Open reached."
        );
        HauntedHouseLibrary.assignLootBoxItem(
            _nftAddress, 
            _nftID, 
            lootedBoxtoAddress, 
            nftToAttrsIDS,
            startIndexForLootedAttr
        );
    }

    /**
    * @notice Buys attr for the house of a specific nft.
    * @param _nftContractAddress NFT contract address in any blockchain
    * @param _nftID NFT ID for that contract address.
    * @param _houseAttrsID House Attr ID.
    * @param _amount price in ERC20 (game currency) to buy the item.
    */
    function buyHouseAttrs(
        address _nftContractAddress,
        uint256 _nftID,
        uint256 _houseAttrsID,
        uint256 _amount
    ) external {
        HauntedHouseLibrary.buyHouseAttrs(
            _nftContractAddress,
            _nftID,
            _houseAttrsID,
            _amount,
            oniCoinAddress,
            idToPrice,
            nftToAttrsIDS
        );
    }

    /**
    * @notice Rewards the NFT holder if he performed all daily mission in a 7 days streak.
    * @param _nftContract NFT contract addresses in any blockchain
    * @param _nftID NFT IDs for that contract address.
    */
    function claimWeeklyBonus(address _nftContract, uint256 _nftID) external {
        HauntedHouseLibrary.claimWeeklyBonus(
            _nftContract,
            _nftID,
            mappedNFTToOwner,
            currentDayInt,
            dailyGenericHauntingMission,
            dailySpecificHauntingMission,
            oniCoinAddress,
            claimedWeeklyBonusToday
        );
    }

    /**
    * @notice Rewards the NFT holder if he performed all daily missions for the current event day.
    * @param _nftContract NFT contract addresses in any blockchain
    * @param _nftID NFT IDs for that contract address.
    */
    function claimDailyBonus(address _nftContract, uint256 _nftID) external {
        HauntedHouseLibrary.claimDailyBonus(
            _nftContract,
            _nftID,
            mappedNFTToOwner,
            currentDayInt,
            dailyGenericHauntingMission,
            dailySpecificHauntingMission,
            oniCoinAddress,
            claimedDailyBonusToday
        );
    }


    // Contract's Finance Functions
    /**
    * @notice Withdraw all contract matic to creator address.
    */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw.");
        _withdraw(creatorAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }


    // Contract's Internal Functions
    /**
    * @notice Rewards in ERC20 (currency game) the NFT involved in a particular haunt.
    * @param _nftHaunterContract NFT contract address that is performing the haunting.
    * @param _nftHaunterID NFT contract ID that is performing the haunting.
    * @param _nftHaunteeContract NFT contract address that is suffering the haunting.
    * @param _nftHaunteeID NFT contract ID that is suffering the haunting.
    */
    function rewardHaunt(
        address _nftHaunterContract,
        uint256 _nftHaunterID,
        address _nftHaunteeContract,
        uint256 _nftHaunteeID
    ) internal {
        HauntedHouseLibrary.rewardHaunt(
        _nftHaunterContract,
        _nftHaunterID,
        _nftHaunteeContract,
        _nftHaunteeID,
        missionCounter,
        timesNFTHasBeenHaunted,
        timesNFTHauntedOnDay,
        mappedNFTToOwner,
        currentDayInt,
        oniCoinAddress
        );
    }

    /**
    * @notice Checks if the NFT that is suffering haunt is in the specific IDS for the current day.
    * @param _nftHaunteeContract NFT contract addresses in any blockchain
    * @param _nftHaunteeID NFT IDs for that contract address.
    */
    function checkIfHaunteeIdIsInSpecificDayMission(address _nftHaunteeContract, uint _nftHaunteeID) internal view returns(bool) {
        return HauntedHouseLibrary.checkIfHaunteeIdIsInSpecificDayMission(
            _nftHaunteeContract,
            _nftHaunteeID,
            specificHauntMissionNFTIDs,
            currentDayInt
        );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IOniCoinToken {
    function faucet(address to, uint256 amount) external;

    function approvedToStore(address _msgSender) external returns (bool);
}

library HauntedHouseLibrary {
    using SafeMath for uint256;
    using Strings for uint256;


    function updateNFTOwner(
        address _nftContract,
        uint256 _nftID,
        address _ownerAddress,
        mapping(address => bool) storage allowedNFTContracts,
        mapping(address => mapping(uint256 => address)) storage mappedNFTToOwner
    ) external {
        require(
            allowedNFTContracts[_nftContract],
            "NFT contract address was not added to play this game"
        );
        // maps the ownership
        mappedNFTToOwner[_nftContract][_nftID] = _ownerAddress;
    }

    function updateOwners(
        address[] memory _contractAddresses,
        uint256[] memory _nftIDS,
        address[] memory _ownersAddresses,
        mapping(address => bool) storage allowedNFTContracts,
        mapping(address => mapping(uint256 => address)) storage mappedNFTToOwner
    ) external {
        // Checks if lists lengh are the same
        require(
            _nftIDS.length == _ownersAddresses.length &&
                _contractAddresses.length == _ownersAddresses.length,
            "Lists with not the same length"
        );

        // Checks if all nft addresses are able to play the game
        for (uint256 i = 0; i < _nftIDS.length; i++) {
            require(
                allowedNFTContracts[_contractAddresses[i]],
                "NFT contract address was not added to play this game"
            );
        }

        // maps the ownership
        for (uint256 i = 0; i < _nftIDS.length; i++) {
            mappedNFTToOwner[_contractAddresses[i]][
                _nftIDS[i]
            ] = _ownersAddresses[i];
        }
    }

    function dailyCheckIn(
        address _nftAddress,
        uint256 _nftID,
        mapping(address => bool) storage allowedNFTContracts,
        mapping(address => mapping(uint256 => address))
            storage mappedNFTToOwner,
        mapping(address => mapping(uint256 => address))
            storage interactedNFTToOwner,
        mapping(address => mapping(uint256 => mapping(uint256 => bool))) storage nftLastCheckIn,
        address oniCoinAddress,
        uint256[2] storage currentDayInt,
        mapping(address => mapping(uint256 => uint256)) storage missionCounter
    ) external {
        // Checks if all nft address is able to play the game
        require(
            allowedNFTContracts[_nftAddress],
            "You can't play the game with this NFT"
        );

        // Checks if it is the owner of that NFT
        require(
            mappedNFTToOwner[_nftAddress][_nftID] == msg.sender,
            "You are not the owner of this NFT"
        );

        // assing to that nft position the owner of it if ever interacted with our contract
        if (interactedNFTToOwner[_nftAddress][_nftID] == address(0)) {
            interactedNFTToOwner[_nftAddress][_nftID] = msg.sender;
        }

        // Checks if already performed daily check in for today
        require(nftLastCheckIn[_nftAddress][_nftID][currentDayInt[0]] == false,
            "You already did your daily check in"
        );

        // Increment mission counter, reward user and set check in to true
        missionCounter[_nftAddress][_nftID] =  missionCounter[_nftAddress][_nftID] + 1;
        IOniCoinToken(oniCoinAddress).faucet(msg.sender, 5);
        nftLastCheckIn[_nftAddress][_nftID][currentDayInt[0]] = true;
    }


    function buyHouseAttrs(
        address _nftContractAddress,
        uint256 _nftID,
        uint256 _houseAttrsID,
        uint256 _amount,
        address oniCoinAddress,
        mapping(uint256 => uint256) storage idToPrice,
        mapping(address => mapping(uint256 => uint256[])) storage nftToAttrsIDS
    ) external {

        // Checks if user has enough coins to buy the attr.
        require(
            IERC20(oniCoinAddress).balanceOf(msg.sender) >= _amount,
            "User does not have submitted amount"
        );

        // Checks if user has sent the right amount.
        require(
            idToPrice[_houseAttrsID] == _amount,
            "Submitted token ammount does not match item price"
        );

        // Checks if user approved the store to transfer tokens on it's behalf.
        require(
            IOniCoinToken(oniCoinAddress).approvedToStore(msg.sender),
            "User did not approve house coin to be an operator on its behalf"
        );

        // Checks if the user already bought that item.
        bool alreadyBought = false;
        for (uint256 i = 0; i < nftToAttrsIDS[_nftContractAddress][_nftID].length; i++) {
            if ( nftToAttrsIDS[_nftContractAddress][_nftID][i] == _houseAttrsID ) {
                alreadyBought = true;
            }
        }
        require(alreadyBought == false, "You already bought this item.");

        // transfer the token from the user to this contract and verify transaction.
       (bool sent) = IERC20(oniCoinAddress).transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to transfer coins.");

        // adds attr id to users house attributes.
        nftToAttrsIDS[_nftContractAddress][_nftID].push(_houseAttrsID);
    }

    function claimDailyBonus(
        address _nftContract,
        uint256 _nftID,
        mapping(address => mapping(uint256 => address))
            storage mappedNFTToOwner,
        uint256[2] storage currentDayInt,
        mapping(address => mapping(uint256 => mapping(uint256 => bool))) storage dailyGenericHauntingMission,
        mapping(address => mapping(uint256 => mapping(uint256 => bool))) storage dailySpecificHauntingMission,
        address oniCoinAddress,
        mapping(address => mapping(uint256 => mapping(uint256 => bool)))
            storage claimedDailyBonusToday
    ) external {
        // Checks if user is the owner of that NFT.
        require(
            mappedNFTToOwner[_nftContract][_nftID] == msg.sender,
            "You are not the owner of this NFT"
        );

        // Checks if user already claimed daily bonus.
        require(
            claimedDailyBonusToday[_nftContract][_nftID][currentDayInt[0]] ==
                false,
            "You already claimed the daily bonus today"
        );

        // Checks if user is already allowed to claim this daily bonus.
        // if so, reward the user.
        bool changed = false;
        if (
            dailyGenericHauntingMission[_nftContract][_nftID][
                currentDayInt[0]
            ] &&
            dailySpecificHauntingMission[_nftContract][_nftID][currentDayInt[0]]
        ) {
            IOniCoinToken(oniCoinAddress).faucet(msg.sender, 10);
            claimedDailyBonusToday[_nftContract][_nftID][currentDayInt[0]] = true;
            changed = true;
        }
        require(changed, "You can't claim daily yet.");
    }


    function getHouseAttrs(
        address _nftContract, 
        uint256 _nftID,
        mapping(address => mapping(uint256 => uint256[])) storage nftToAttrsIDS
        )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory houseAttrIDs = new uint256[](
            nftToAttrsIDS[_nftContract][_nftID].length
        );

        for (uint256 i = 0; i < nftToAttrsIDS[_nftContract][_nftID].length; i++) {
            houseAttrIDs[i] = nftToAttrsIDS[_nftContract][_nftID][i];
        }

        return houseAttrIDs;
    }

    function getSpecificHauntMissionNFTIDs(
        uint256 _eventDay,
        address _nftContract,
        mapping(uint256 => mapping(address => uint256[])) storage specificHauntMissionNFTIDs
    ) external view returns (uint256[] memory) {
        uint256[] memory nftIDs = new uint256[](
            specificHauntMissionNFTIDs[_eventDay][_nftContract].length
        );

        for (
            uint256 i = 0;
            i < specificHauntMissionNFTIDs[_eventDay][_nftContract].length;
            i++
        ) {
            nftIDs[i] = specificHauntMissionNFTIDs[_eventDay][_nftContract][i];
        }

        return nftIDs;
    }


    function checkIfHaunteeIdIsInSpecificDayMission(
        address _nftHaunteeContract, 
        uint _nftHaunteeID,
        mapping(uint256 => mapping(address => uint256[])) storage specificHauntMissionNFTIDs,
        uint256[2] storage currentDayInt
    ) public view returns(bool) {
        bool idInList = false;
        for (uint256 i = 0; i < specificHauntMissionNFTIDs[currentDayInt[0]][_nftHaunteeContract].length; i++) {
            if ( specificHauntMissionNFTIDs[currentDayInt[0]][_nftHaunteeContract][i] == _nftHaunteeID ) {
                idInList = true;
            }
        }
        return idInList;
    }

    function claimWeeklyBonus(
        address _nftContract,
        uint256 _nftID,
        mapping(address => mapping(uint256 => address))
            storage mappedNFTToOwner,
        uint256[2] storage currentDayInt,
        mapping(address => mapping(uint256 => mapping(uint256 => bool)))
            storage dailyGenericHauntingMission,
        mapping(address => mapping(uint256 => mapping(uint256 => bool))) storage dailySpecificHauntingMission,
        address oniCoinAddress,
        mapping(address => mapping(uint256 => mapping(uint256 => bool)))
            storage claimedWeeklyBonusToday
    ) external {
        require(
            mappedNFTToOwner[_nftContract][_nftID] == msg.sender,
            "You are not the owner of this NFT"
        );
        require(
            dailyGenericHauntingMission[_nftContract][_nftID][currentDayInt[0]],
            "You need to Generic Haunted before claim the weekly bonus."
        );
        require(
            dailySpecificHauntingMission[_nftContract][_nftID][
                currentDayInt[0]
            ],
            "You need to Specific Haunted before claim the weekly bonus."
        );
        bool[] memory daysWithBothMissions = new bool[](27);
        bool updatedBalance = false;

        // assign to true the days in which both generic and specific haunt has been done
        for (uint256 i = 0; i < 28; i++) {
            if (
                dailyGenericHauntingMission[_nftContract][_nftID][i] &&
                dailySpecificHauntingMission[_nftContract][_nftID][i]
            ) {
                daysWithBothMissions[i] = true;
            }
        }
        // if 7 days in a row is found, reward the player.
        for (uint256 i = 0; i < 28; i++) {
            if (
                daysWithBothMissions[i] &&
                daysWithBothMissions[i + 1] &&
                daysWithBothMissions[i + 2] &&
                daysWithBothMissions[i + 3] &&
                daysWithBothMissions[i + 4] &&
                daysWithBothMissions[i + 5] &&
                daysWithBothMissions[i + 6]
            ) {
                IOniCoinToken(oniCoinAddress).faucet(msg.sender, 30);
                for (uint256 y = 0; y < 7; y++) {
                    dailyGenericHauntingMission[_nftContract][_nftID][
                        i + y
                    ] = false;
                    dailySpecificHauntingMission[_nftContract][_nftID][
                        i + y
                    ] = false;
                    daysWithBothMissions[i + y] = false;
                }
                claimedWeeklyBonusToday[_nftContract][_nftID][
                    currentDayInt[0]
                ] = true;
                updatedBalance = true;
            }
        }
        require(updatedBalance, "You can't retrieve the weekly bonus yet");
    }

    function assignLootBoxItem(
        address _nftAddress,
        uint256 _nftID,
        mapping(uint256 => address) storage lootedBoxtoAddress,
        mapping(address => mapping(uint256 => uint256[])) storage nftToAttrsIDS,
        uint256[1] storage startIndexForLootedAttr
    ) external {
        // assign attr ID to msg.sender
        lootedBoxtoAddress[startIndexForLootedAttr[0]] = msg.sender;
        // adds attr id to users house attr
        nftToAttrsIDS[_nftAddress][_nftID].push(startIndexForLootedAttr[0]);
        // increment loot box counter
        startIndexForLootedAttr[0] = startIndexForLootedAttr[0] + 1;
    }

    function rewardHaunt(
        address _nftHaunterContract,
        uint256 _nftHaunterID,
        address _nftHaunteeContract,
        uint256 _nftHaunteeID,
        mapping(address => mapping(uint256 => uint256)) storage missionCounter,
        mapping(address => mapping(uint256 => uint256)) storage timesOniHasBeenHaunted,
        mapping(uint256 => mapping(address => mapping(uint256 => uint256))) storage timesNFTHaunted,
        mapping(address => mapping(uint256 => address)) storage mappedNFTToOwner,
        uint256[2] storage currentDayInt,
        address oniCoinAddress
    ) internal {
        // increment mission counter for that nft
        missionCounter[_nftHaunterContract][_nftHaunterID] =  missionCounter[_nftHaunterContract][_nftHaunterID] +  1;

        // increment how many times that oni has been haunted
        timesOniHasBeenHaunted[_nftHaunterContract][_nftHaunteeID] = timesOniHasBeenHaunted[_nftHaunterContract][_nftHaunteeID] +  1;

        // increment how many times that oni has been haunted on a specific game day event
        timesNFTHaunted[currentDayInt[0]][_nftHaunteeContract][_nftHaunteeID] = timesNFTHaunted[currentDayInt[0]][_nftHaunteeContract][_nftHaunteeID] +  1;

        // gets the the addres of the owner that is suffering haunting
        address haunteeOwnerAddress = mappedNFTToOwner[_nftHaunteeContract][_nftHaunteeID];

        // reward players
        IOniCoinToken(oniCoinAddress).faucet(haunteeOwnerAddress, 5);
        IOniCoinToken(oniCoinAddress).faucet(msg.sender, 5);
    }

    function setAttrsPrice(
        uint256[] memory _attrsIds,
        uint256[] memory _attrsPrices,
        mapping(uint256 => uint256) storage idToPrice
    ) external {
        require(
            _attrsIds.length == _attrsPrices.length,
            "Lists with not the same length"
        );
        for (uint256 i = 0; i < _attrsIds.length; i++) {
            idToPrice[_attrsIds[i]] = _attrsPrices[i];
        }
    }


    /**
    * @notice Returns true if user can retrieve Bonus.
    * @param _nftContract NFT contract Address.
    * @param _nftID NFT ID for that contract address.
    */
    function canUserGetStreakBonus(
      address _nftContract, 
      uint _nftID,
      mapping(address => mapping(uint256 => mapping(uint256 => bool))) storage dailyGenericHauntingMission,
      mapping(address => mapping(uint256 => mapping(uint256 => bool))) storage dailySpecificHauntingMission
    ) external view returns (bool) {
        bool[] memory daysWithBothMissions = new bool[](34);
        for (uint256 i = 0; i < 28; i++) {
            if (
                dailyGenericHauntingMission[_nftContract][_nftID][i] &&
                dailySpecificHauntingMission[_nftContract][_nftID][i]
            ) {
                daysWithBothMissions[i] = true;
            }
        }
        bool canRetrieveBonus = false;
        for (uint256 i = 0; i < 28; i++) {
            if (
                daysWithBothMissions[i] &&
                daysWithBothMissions[i + 1] &&
                daysWithBothMissions[i + 2] &&
                daysWithBothMissions[i + 3] &&
                daysWithBothMissions[i + 4] &&
                daysWithBothMissions[i + 5] &&
                daysWithBothMissions[i + 6]
            ) {
                canRetrieveBonus = true;
            }
        }
        return canRetrieveBonus;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return _owners[tokenId] != address(0);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}