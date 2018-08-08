pragma solidity 0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal contractOwner;

  constructor () internal {
    if(contractOwner == address(0)){
      contractOwner = msg.sender;
    }
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }
  

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    contractOwner = newOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  bool private paused = false;

  /**
   * @dev Modifier to allow actions only when the contract IS paused
     @dev If is paused msg.value is send back
   */
  modifier whenNotPaused() {
    if(paused == true && msg.value > 0){
      msg.sender.transfer(msg.value);
    }
    require(!paused);
    _;
  }


  /**
   * @dev Called by the owner to pause, triggers stopped state
   */
  function triggerPause() onlyOwner external {
    paused = !paused;
  }

}


/// @title A contract for creating new champs and making withdrawals
contract ChampFactory is Pausable{

    event NewChamp(uint256 champID, address owner);

    using SafeMath for uint; //SafeMath for overflow prevention

    /*
     * Variables
     */
    struct Champ {
        uint256 id; //same as position in Champ[]
        uint256 attackPower;
        uint256 defencePower;
        uint256 cooldownTime; //how long does it take to be ready attack again
        uint256 readyTime; //if is smaller than block.timestamp champ is ready to fight
        uint256 winCount;
        uint256 lossCount;
        uint256 position; //position in leaderboard. subtract 1 and you got position in leaderboard[]
        uint256 price; //selling price
        uint256 withdrawCooldown; //if you one of the 800 best champs and withdrawCooldown is less as block.timestamp then you get ETH reward
        uint256 eq_sword; 
        uint256 eq_shield; 
        uint256 eq_helmet; 
        bool forSale; //is champ for sale?
    }
    
    struct AddressInfo {
        uint256 withdrawal;
        uint256 champsCount;
        uint256 itemsCount;
        string name;
    }

    //Item struct
    struct Item {
        uint8 itemType; // 1 - Sword | 2 - Shield | 3 - Helmet
        uint8 itemRarity; // 1 - Common | 2 - Uncommon | 3 - Rare | 4 - Epic | 5 - Legendery | 6 - Forged
        uint256 attackPower;
        uint256 defencePower;
        uint256 cooldownReduction;
        uint256 price;
        uint256 onChampId; //can not be used to decide if item is on champ, because champ&#39;s id can be 0, &#39;bool onChamp&#39; solves it.
        bool onChamp; 
        bool forSale; //is item for sale?
    }
    
    mapping (address => AddressInfo) public addressInfo;
    mapping (uint256 => address) public champToOwner;
    mapping (uint256 => address) public itemToOwner;
    mapping (uint256 => string) public champToName;
    
    Champ[] public champs;
    Item[] public items;
    uint256[] public leaderboard;
    
    uint256 internal createChampFee = 5 finney;
    uint256 internal lootboxFee = 5 finney;
    uint256 internal pendingWithdrawal = 0;
    uint256 private randNonce = 0; //being used in generating random numbers
    uint256 public champsForSaleCount;
    uint256 public itemsForSaleCount;
    

    /*
     * Modifiers
     */
    /// @dev Checks if msg.sender is owner of champ
    modifier onlyOwnerOfChamp(uint256 _champId) {
        require(msg.sender == champToOwner[_champId]);
        _;
    }
    

    /// @dev Checks if msg.sender is NOT owner of champ
    modifier onlyNotOwnerOfChamp(uint256 _champId) {
        require(msg.sender != champToOwner[_champId]);
        _;
    }
    

    /// @notice Checks if amount was sent
    modifier isPaid(uint256 _price){
        require(msg.value >= _price);
        _;
    }


    /// @notice People are allowed to withdraw only if min. balance (0.01 gwei) is reached
    modifier contractMinBalanceReached(){
        require( (address(this).balance).sub(pendingWithdrawal) > 1000000 );
        _;
    }


    /// @notice Checks if withdraw cooldown passed 
    modifier isChampWithdrawReady(uint256 _id){
        require(champs[_id].withdrawCooldown < block.timestamp);
        _;
    }


    /// @notice Distribute input funds between contract owner and players
    modifier distributeInput(address _affiliateAddress){

        //contract owner
        uint256 contractOwnerWithdrawal = (msg.value / 100) * 50; // 50%
        addressInfo[contractOwner].withdrawal += contractOwnerWithdrawal;
        pendingWithdrawal += contractOwnerWithdrawal;

        //affiliate
        //checks if _affiliateAddress is set & if affiliate address is not buying player
        if(_affiliateAddress != address(0) && _affiliateAddress != msg.sender){
            uint256 affiliateBonus = (msg.value / 100) * 25; //provision is 25%
            addressInfo[_affiliateAddress].withdrawal += affiliateBonus;
            pendingWithdrawal += affiliateBonus;
        }

        _;
    }



    /*
     * View
     */
    /// @notice Gets champs by address
    /// @param _owner Owner address
    function getChampsByOwner(address _owner) external view returns(uint256[]) {
        uint256[] memory result = new uint256[](addressInfo[_owner].champsCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < champs.length; i++) {
            if (champToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }


    /// @notice Gets total champs count
    function getChampsCount() external view returns(uint256){
        return champs.length;
    }
    

    /// @notice Gets champ&#39;s reward in wei
    function getChampReward(uint256 _position) public view returns(uint256) {
        if(_position <= 800){
            //percentageMultipier = 10,000
            //maxReward = 2000 = .2% * percentageMultipier
            //subtractPerPosition = 2 = .0002% * percentageMultipier
            //2000 - (2 * (_position - 1))
            uint256 rewardPercentage = uint256(2000).sub(2 * (_position - 1));

            //available funds are all funds - already pending
            uint256 availableWithdrawal = address(this).balance.sub(pendingWithdrawal);

            //calculate reward for champ&#39;s position
            //1000000 = percentageMultipier * 100
            return availableWithdrawal / 1000000 * rewardPercentage;
        }else{
            return uint256(0);
        }
    }


    /*
     * Internal
     */
    /// @notice Generates random modulus
    /// @param _modulus Max random modulus
    function randMod(uint256 _modulus) internal returns(uint256) {
        randNonce++;
        return uint256(keccak256(randNonce, blockhash(block.number - 1))) % _modulus;
    }
    


    /*
     * External
     */
    /// @notice Creates new champ
    /// @param _affiliateAddress Affiliate address (optional)
    function createChamp(address _affiliateAddress) external payable 
    whenNotPaused
    isPaid(createChampFee) 
    distributeInput(_affiliateAddress) 
    {

        /* 
        Champ memory champ = Champ({
             id: 0,
             attackPower: 2 + randMod(4),
             defencePower: 1 + randMod(4),
             cooldownTime: uint256(1 days) - uint256(randMod(9) * 1 hours),
             readyTime: 0,
             winCount: 0,
             lossCount: 0,
             position: leaderboard.length + 1, //Last place in leaderboard is new champ&#39;s position. Used in new champ struct bellow. +1 to avoid zero position.
             price: 0,
             withdrawCooldown: uint256(block.timestamp), 
             eq_sword: 0,
             eq_shield: 0, 
             eq_helmet: 0, 
             forSale: false 
        });   
        */

        // This line bellow is about 30k gas cheaper than lines above. They are the same. Lines above are just more readable.
        uint256 id = champs.push(Champ(0, 2 + randMod(4), 1 + randMod(4), uint256(1 days)  - uint256(randMod(9) * 1 hours), 0, 0, 0, leaderboard.length + 1, 0, uint256(block.timestamp), 0,0,0, false)) - 1;     
        
        
        champs[id].id = id; //sets id in Champ struct  
        leaderboard.push(id); //push champ on the last place in leaderboard  
        champToOwner[id] = msg.sender; //sets owner of this champ - msg.sender
        addressInfo[msg.sender].champsCount++;

        emit NewChamp(id, msg.sender);

    }


    /// @notice Change "CreateChampFee". If ETH price will grow up it can expensive to create new champ.
    /// @param _fee New "CreateChampFee"
    /// @dev Only owner of contract can change "CreateChampFee"
    function setCreateChampFee(uint256 _fee) external onlyOwner {
        createChampFee = _fee;
    }
    

    /// @notice Change champ&#39;s name
    function changeChampsName(uint _champId, string _name) external 
    onlyOwnerOfChamp(_champId){
        champToName[_champId] = _name;
    }


    /// @notice Change players&#39;s name
    function changePlayersName(string _name) external {
        addressInfo[msg.sender].name = _name;
    }


    /// @notice Withdraw champ&#39;s reward
    /// @param _id Champ id
    /// @dev Move champ reward to pending withdrawal to his wallet. 
    function withdrawChamp(uint _id) external 
    onlyOwnerOfChamp(_id) 
    contractMinBalanceReached  
    isChampWithdrawReady(_id) 
    whenNotPaused {
        Champ storage champ = champs[_id];
        require(champ.position <= 800);

        champ.withdrawCooldown = block.timestamp + 1 days; //one withdrawal 1 per day

        uint256 withdrawal = getChampReward(champ.position);
        addressInfo[msg.sender].withdrawal += withdrawal;
        pendingWithdrawal += withdrawal;
    }
    

    /// @dev Send all pending funds of caller&#39;s address
    function withdrawToAddress(address _address) external 
    whenNotPaused {
        address playerAddress = _address;
        if(playerAddress == address(0)){ playerAddress = msg.sender; }
        uint256 share = addressInfo[playerAddress].withdrawal; //gets pending funds
        require(share > 0); //is it more than 0?

        //first sets players withdrawal pending to 0 and subtract amount from playerWithdrawals then transfer funds to avoid reentrancy
        addressInfo[playerAddress].withdrawal = 0; //set player&#39;s withdrawal pendings to 0 
        pendingWithdrawal = pendingWithdrawal.sub(share); //subtract share from total pendings 
        
        playerAddress.transfer(share); //transfer
    }
    
}



/// @title  Moderates items and creates new ones
contract Items is ChampFactory {

    event NewItem(uint256 itemID, address owner);

    constructor () internal {
        //item -> nothing
        items.push(Item(0, 0, 0, 0, 0, 0, 0, false, false));
    }

    /*
     * Modifiers
     */
    /// @notice Checks if sender is owner of item
    modifier onlyOwnerOfItem(uint256 _itemId) {
        require(_itemId != 0);
        require(msg.sender == itemToOwner[_itemId]);
        _;
    }
    

    /// @notice Checks if sender is NOT owner of item
    modifier onlyNotOwnerOfItem(uint256 _itemId) {
        require(msg.sender != itemToOwner[_itemId]);
        _;
    }


    /*
     * View
     */
    ///@notice Check if champ has something on
    ///@param _type Sword, shield or helmet
    function hasChampSomethingOn(uint _champId, uint8 _type) internal view returns(bool){
        Champ storage champ = champs[_champId];
        if(_type == 1){
            return (champ.eq_sword == 0) ? false : true;
        }
        if(_type == 2){
            return (champ.eq_shield == 0) ? false : true;
        }
        if(_type == 3){
            return (champ.eq_helmet == 0) ? false : true;
        }
    }


    /// @notice Gets items by address
    /// @param _owner Owner address
    function getItemsByOwner(address _owner) external view returns(uint256[]) {
        uint256[] memory result = new uint256[](addressInfo[_owner].itemsCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (itemToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }


    /*
     * Public
     */
    ///@notice Takes item off champ
    function takeOffItem(uint _champId, uint8 _type) public 
        onlyOwnerOfChamp(_champId) {
            uint256 itemId;
            Champ storage champ = champs[_champId];
            if(_type == 1){
                itemId = champ.eq_sword; //Get item ID
                if (itemId > 0) { //0 = nothing
                    champ.eq_sword = 0; //take off sword
                }
            }
            if(_type == 2){
                itemId = champ.eq_shield; //Get item ID
                if(itemId > 0) {//0 = nothing
                    champ.eq_shield = 0; //take off shield
                }
            }
            if(_type == 3){
                itemId = champ.eq_helmet; //Get item ID
                if(itemId > 0) { //0 = nothing
                    champ.eq_helmet = 0; //take off 
                }
            }
            if(itemId > 0){
                items[itemId].onChamp = false; //item is free to use, is not on champ
            }
    }



    /*
     * External
     */
    ///@notice Puts item on champ
    function putOn(uint256 _champId, uint256 _itemId) external 
        onlyOwnerOfChamp(_champId) 
        onlyOwnerOfItem(_itemId) {
            Champ storage champ = champs[_champId];
            Item storage item = items[_itemId];

            //checks if items is on some other champ
            if(item.onChamp){
                takeOffItem(item.onChampId, item.itemType); //take off from champ
            }

            item.onChamp = true; //item is on champ
            item.onChampId = _champId; //champ&#39;s id

            //put on
            if(item.itemType == 1){
                //take off actual sword 
                if(champ.eq_sword > 0){
                    takeOffItem(champ.id, 1);
                }
                champ.eq_sword = _itemId; //put on sword
            }
            if(item.itemType == 2){
                //take off actual shield 
                if(champ.eq_shield > 0){
                    takeOffItem(champ.id, 2);
                }
                champ.eq_shield = _itemId; //put on shield
            }
            if(item.itemType == 3){
                //take off actual helmet 
                if(champ.eq_helmet > 0){
                    takeOffItem(champ.id, 3);
                }
                champ.eq_helmet = _itemId; //put on helmet
            }
    }



    /// @notice Opens loot box and generates new item
    function openLootbox(address _affiliateAddress) external payable 
    whenNotPaused
    isPaid(lootboxFee) 
    distributeInput(_affiliateAddress) {

        uint256 pointToCooldownReduction;
        uint256 randNum = randMod(1001); //random number <= 1000
        uint256 pointsToShare; //total points given
        uint256 itemID;

        //sets up item
        Item memory item = Item({
            itemType: uint8(uint256(randMod(3) + 1)), //generates item type - max num is 2 -> 0 + 1 SWORD | 1 + 1 SHIELD | 2 + 1 HELMET;
            itemRarity: uint8(0),
            attackPower: 0,
            defencePower: 0,
            cooldownReduction: 0,
            price: 0,
            onChampId: 0,
            onChamp: false,
            forSale: false
        });
        
        // Gets Rarity of item
        // 45% common
        // 27% uncommon
        // 19% rare
        // 7%  epic
        // 2%  legendary
        if(450 > randNum){
            pointsToShare = 25 + randMod(9); //25 basic + random number max to 8
            item.itemRarity = uint8(1);
        }else if(720 > randNum){
            pointsToShare = 42 + randMod(17); //42 basic + random number max to 16
            item.itemRarity = uint8(2);
        }else if(910 > randNum){
            pointsToShare = 71 + randMod(25); //71 basic + random number max to 24
            item.itemRarity = uint8(3);
        }else if(980 > randNum){
            pointsToShare = 119 + randMod(33); //119 basic + random number max to 32
            item.itemRarity = uint8(4);
        }else{
            pointsToShare = 235 + randMod(41); //235 basic + random number max to 40
            item.itemRarity = uint8(5);
        }
        

        //Gets type of item
        if(item.itemType == uint8(1)){ //ITEM IS SWORDS
            item.attackPower = pointsToShare / 10 * 7; //70% attackPower
            pointsToShare -= item.attackPower; //points left;
                
            item.defencePower = pointsToShare / 10 * randMod(6); //up to 15% defencePower
            pointsToShare -= item.defencePower; //points left;
                
            item.cooldownReduction = pointsToShare * uint256(1 minutes); //rest of points is cooldown reduction
            item.itemType = uint8(1);
        }
        
        if(item.itemType == uint8(2)){ //ITEM IS SHIELD
            item.defencePower = pointsToShare / 10 * 7; //70% defencePower
            pointsToShare -= item.defencePower; //points left;
                
            item.attackPower = pointsToShare / 10 * randMod(6); //up to 15% attackPowerPower
            pointsToShare -= item.attackPower; //points left;
                
            item.cooldownReduction = pointsToShare * uint256(1 minutes); //rest of points is cooldown reduction
            item.itemType = uint8(2);
        }
        
        if(item.itemType == uint8(3)){ //ITEM IS HELMET
            pointToCooldownReduction = pointsToShare / 10 * 7; //70% cooldown reduction
            item.cooldownReduction = pointToCooldownReduction * uint256(1 minutes); //points to time
            pointsToShare -= pointToCooldownReduction; //points left;
                
            item.attackPower = pointsToShare / 10 * randMod(6); //up to 15% attackPower
            pointsToShare -= item.attackPower; //points left;
                
            item.defencePower = pointsToShare; //rest of points is defencePower
            item.itemType = uint8(3);
        }

        itemID = items.push(item) - 1;
        
        itemToOwner[itemID] = msg.sender; //sets owner of this item - msg.sender
        addressInfo[msg.sender].itemsCount++; //every address has count of items    

        emit NewItem(itemID, msg.sender);    

    }

    /// @notice Change "lootboxFee". 
    /// @param _fee New "lootboxFee"
    /// @dev Only owner of contract can change "lootboxFee"
    function setLootboxFee(uint _fee) external onlyOwner {
        lootboxFee = _fee;
    }
}



/// @title Moderates buying and selling items
contract ItemMarket is Items {

    event TransferItem(address from, address to, uint256 itemID);

    /*
     * Modifiers
     */
    ///@notice Checks if item is for sale
    modifier itemIsForSale(uint256 _id){
        require(items[_id].forSale);
        _;
    }

    ///@notice Checks if item is NOT for sale
    modifier itemIsNotForSale(uint256 _id){
        require(items[_id].forSale == false);
        _;
    }

    ///@notice If item is for sale then cancel sale
    modifier ifItemForSaleThenCancelSale(uint256 _itemID){
      Item storage item = items[_itemID];
      if(item.forSale){
          _cancelItemSale(item);
      }
      _;
    }


    ///@notice Distribute sale eth input
    modifier distributeSaleInput(address _owner) { 
        uint256 contractOwnerCommision; //1%
        uint256 playerShare; //99%
        
        if(msg.value > 100){
            contractOwnerCommision = (msg.value / 100);
            playerShare = msg.value - contractOwnerCommision;
        }else{
            contractOwnerCommision = 0;
            playerShare = msg.value;
        }

        addressInfo[_owner].withdrawal += playerShare;
        addressInfo[contractOwner].withdrawal += contractOwnerCommision;
        pendingWithdrawal += playerShare + contractOwnerCommision;
        _;
    }



    /*
     * View
     */
    function getItemsForSale() view external returns(uint256[]){
        uint256[] memory result = new uint256[](itemsForSaleCount);
        if(itemsForSaleCount > 0){
            uint256 counter = 0;
            for (uint256 i = 0; i < items.length; i++) {
                if (items[i].forSale == true) {
                    result[counter]=i;
                    counter++;
                }
            }
        }
        return result;
    }
    
     /*
     * Private
     */
    ///@notice Cancel sale. Should not be called without checking if item is really for sale.
    function _cancelItemSale(Item storage item) private {
      //No need to overwrite item&#39;s price
      item.forSale = false;
      itemsForSaleCount--;
    }


    /*
     * Internal
     */
    /// @notice Transfer item
    function transferItem(address _from, address _to, uint256 _itemID) internal 
      ifItemForSaleThenCancelSale(_itemID) {
        Item storage item = items[_itemID];

        //take off      
        if(item.onChamp && _to != champToOwner[item.onChampId]){
          takeOffItem(item.onChampId, item.itemType);
        }

        addressInfo[_to].itemsCount++;
        addressInfo[_from].itemsCount--;
        itemToOwner[_itemID] = _to;

        emit TransferItem(_from, _to, _itemID);
    }



    /*
     * Public
     */
    /// @notice Calls transfer item
    /// @notice Address _from is msg.sender. Cannot be used is market, bc msg.sender is buyer
    function giveItem(address _to, uint256 _itemID) public 
      onlyOwnerOfItem(_itemID) {
        transferItem(msg.sender, _to, _itemID);
    }
    

    /// @notice Calcels item&#39;s sale
    function cancelItemSale(uint256 _id) public 
    itemIsForSale(_id) 
    onlyOwnerOfItem(_id){
      Item storage item = items[_id];
       _cancelItemSale(item);
    }


    /*
     * External
     */
    /// @notice Sets item for sale
    function setItemForSale(uint256 _id, uint256 _price) external 
      onlyOwnerOfItem(_id) 
      itemIsNotForSale(_id) {
        Item storage item = items[_id];
        item.forSale = true;
        item.price = _price;
        itemsForSaleCount++;
    }
    
    
    /// @notice Buys item
    function buyItem(uint256 _id) external payable 
      whenNotPaused 
      onlyNotOwnerOfItem(_id) 
      itemIsForSale(_id) 
      isPaid(items[_id].price) 
      distributeSaleInput(itemToOwner[_id]) 
      {
        transferItem(itemToOwner[_id], msg.sender, _id);
    }
    
}



/// @title Manages forging
contract ItemForge is ItemMarket {

	event Forge(uint256 forgedItemID);

	///@notice Forge items together
	function forgeItems(uint256 _parentItemID, uint256 _childItemID) external 
	onlyOwnerOfItem(_parentItemID) 
	onlyOwnerOfItem(_childItemID) 
	ifItemForSaleThenCancelSale(_parentItemID) 
	ifItemForSaleThenCancelSale(_childItemID) {

		//checks if items are not the same
        require(_parentItemID != _childItemID);
        
		Item storage parentItem = items[_parentItemID];
		Item storage childItem = items[_childItemID];

		//take child item off, because child item will be burned
		if(childItem.onChamp){
			takeOffItem(childItem.onChampId, childItem.itemType);
		}

		//update parent item
		parentItem.attackPower = (parentItem.attackPower > childItem.attackPower) ? parentItem.attackPower : childItem.attackPower;
		parentItem.defencePower = (parentItem.defencePower > childItem.defencePower) ? parentItem.defencePower : childItem.defencePower;
		parentItem.cooldownReduction = (parentItem.cooldownReduction > childItem.cooldownReduction) ? parentItem.cooldownReduction : childItem.cooldownReduction;
		parentItem.itemRarity = uint8(6);

		//burn child item
		transferItem(msg.sender, address(0), _childItemID);

		emit Forge(_parentItemID);
	}

}


/// @title Manages attacks in game
contract ChampAttack is ItemForge {
    
    event Attack(uint256 winnerChampID, uint256 defeatedChampID, bool didAttackerWin);

    /*
     * Modifiers
     */
     /// @notice Is champ ready to fight again?
    modifier isChampReady(uint256 _champId) {
      require (champs[_champId].readyTime <= block.timestamp);
      _;
    }


    /// @notice Prevents from self-attack
    modifier notSelfAttack(uint256 _champId, uint256 _targetId) {
        require(_champId != _targetId); 
        _;
    }


    /// @notice Checks if champ does exist
    modifier targetExists(uint256 _targetId){
        require(champToOwner[_targetId] != address(0)); 
        _;
    }


    /*
     * View
     */
    /// @notice Gets champ&#39;s attack power, defence power and cooldown reduction with items on
    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256){
        Champ storage champ = champs[_champId];
        Item storage sword = items[champ.eq_sword];
        Item storage shield = items[champ.eq_shield];
        Item storage helmet = items[champ.eq_helmet];

        //AP
        uint256 totalAttackPower = champ.attackPower + sword.attackPower + shield.attackPower + helmet.attackPower; //Gets champs AP

        //DP
        uint256 totalDefencePower = champ.defencePower + sword.defencePower + shield.defencePower + helmet.defencePower; //Gets champs  DP

        //CR
        uint256 totalCooldownReduction = sword.cooldownReduction + shield.cooldownReduction + helmet.cooldownReduction; //Gets  CR

        return (totalAttackPower, totalDefencePower, totalCooldownReduction);
    }


    /*
     * Pure
     */
    /// @notice Subtracts ability points. Helps to not cross minimal attack ability points -> 2
    /// @param _playerAttackPoints Actual player&#39;s attack points
    /// @param _x Amount to subtract 
    function subAttack(uint256 _playerAttackPoints, uint256 _x) internal pure returns (uint256) {
        return (_playerAttackPoints <= _x + 2) ? 2 : _playerAttackPoints - _x;
    }
    

    /// @notice Subtracts ability points. Helps to not cross minimal defence ability points -> 1
    /// @param _playerDefencePoints Actual player&#39;s defence points
    /// @param _x Amount to subtract 
    function subDefence(uint256 _playerDefencePoints, uint256 _x) internal pure returns (uint256) {
        return (_playerDefencePoints <= _x) ? 1 : _playerDefencePoints - _x;
    }
    

    /*
     * Private
     */
    /// @dev Is called from from Attack function after the winner is already chosen
    /// @dev Updates abilities, champ&#39;s stats and swaps positions
    function _attackCompleted(Champ storage _winnerChamp, Champ storage _defeatedChamp, uint256 _pointsGiven, uint256 _pointsToAttackPower) private {
        /*
         * Updates abilities after fight
         */
        //winner abilities update
        _winnerChamp.attackPower += _pointsToAttackPower; //increase attack power
        _winnerChamp.defencePower += _pointsGiven - _pointsToAttackPower; //max point that was given - already given to AP
                
        //defeated champ&#39;s abilities update
        //checks for not cross minimal AP & DP points
        _defeatedChamp.attackPower = subAttack(_defeatedChamp.attackPower, _pointsToAttackPower); //decrease attack power
        _defeatedChamp.defencePower = subDefence(_defeatedChamp.defencePower, _pointsGiven - _pointsToAttackPower); // decrease defence power



        /*
         * Update champs&#39; wins and losses
         */
        _winnerChamp.winCount++;
        _defeatedChamp.lossCount++;
            


        /*
         * Swap positions
         */
        if(_winnerChamp.position > _defeatedChamp.position) { //require loser to has better (lower) postion than attacker
            uint256 winnerPosition = _winnerChamp.position;
            uint256 loserPosition = _defeatedChamp.position;
        
            _defeatedChamp.position = winnerPosition;
            _winnerChamp.position = loserPosition;
        
            //position in champ struct is always one point bigger than in leaderboard array
            leaderboard[winnerPosition - 1] = _defeatedChamp.id;
            leaderboard[loserPosition - 1] = _winnerChamp.id;
        }
    }
    
    
    /// @dev Gets pointsGiven and pointsToAttackPower
    function _getPoints(uint256 _pointsGiven) private returns (uint256 pointsGiven, uint256 pointsToAttackPower){
        return (_pointsGiven, randMod(_pointsGiven+1));
    }



    /*
     * External
     */
    /// @notice Attack function
    /// @param _champId Attacker champ
    /// @param _targetId Target champ
    function attack(uint256 _champId, uint256 _targetId) external 
    onlyOwnerOfChamp(_champId) 
    isChampReady(_champId) 
    notSelfAttack(_champId, _targetId) 
    targetExists(_targetId) {
        Champ storage myChamp = champs[_champId]; 
        Champ storage enemyChamp = champs[_targetId]; 
        uint256 pointsGiven; //total points that will be divided between AP and DP
        uint256 pointsToAttackPower; //part of points that will be added to attack power, the rest of points go to defence power
        uint256 myChampAttackPower;  
        uint256 enemyChampDefencePower; 
        uint256 myChampCooldownReduction;
        
        (myChampAttackPower,,myChampCooldownReduction) = getChampStats(_champId);
        (,enemyChampDefencePower,) = getChampStats(_targetId);


        //if attacker&#39;s AP is more than target&#39;s DP then attacker wins
        if (myChampAttackPower > enemyChampDefencePower) {
            
            //this should demotivate players from farming on way weaker champs than they are
            //the bigger difference between AP & DP is, the reward is smaller
            if(myChampAttackPower - enemyChampDefencePower < 5){
                
                //big experience - 3 ability points
                (pointsGiven, pointsToAttackPower) = _getPoints(3);
                
                
            }else if(myChampAttackPower - enemyChampDefencePower < 10){
                
                //medium experience - 2 ability points
                (pointsGiven, pointsToAttackPower) = _getPoints(2);
                
            }else{
                
                //small experience - 1 ability point to random ability (attack power or defence power)
                (pointsGiven, pointsToAttackPower) = _getPoints(1);
                
            }
            
            _attackCompleted(myChamp, enemyChamp, pointsGiven, pointsToAttackPower);

            emit Attack(myChamp.id, enemyChamp.id, true);

        } else {
            
            //1 ability point to random ability (attack power or defence power)
            (pointsGiven, pointsToAttackPower) = _getPoints(1);

            _attackCompleted(enemyChamp, myChamp, pointsGiven, pointsToAttackPower);

            emit Attack(enemyChamp.id, myChamp.id, false);
             
        }
        
        //Trigger cooldown for attacker
        myChamp.readyTime = uint256(block.timestamp + myChamp.cooldownTime - myChampCooldownReduction);

    }
    
}


/// @title Moderates buying and selling champs
contract ChampMarket is ChampAttack {

    event TransferChamp(address from, address to, uint256 champID);

    /*
     * Modifiers
     */
    ///@notice Require champ to be sale
    modifier champIsForSale(uint256 _id){
        require(champs[_id].forSale);
        _;
    }
    

    ///@notice Require champ NOT to be for sale
    modifier champIsNotForSale(uint256 _id){
        require(champs[_id].forSale == false);
        _;
    }
    

    ///@notice If champ is for sale then cancel sale
    modifier ifChampForSaleThenCancelSale(uint256 _champID){
      Champ storage champ = champs[_champID];
      if(champ.forSale){
          _cancelChampSale(champ);
      }
      _;
    }
    

    /*
     * View
     */
    ///@notice Gets all champs for sale
    function getChampsForSale() view external returns(uint256[]){
        uint256[] memory result = new uint256[](champsForSaleCount);
        if(champsForSaleCount > 0){
            uint256 counter = 0;
            for (uint256 i = 0; i < champs.length; i++) {
                if (champs[i].forSale == true) {
                    result[counter]=i;
                    counter++;
                }
            }
        }
        return result;
    }
    
    
    /*
     * Private
     */
     ///@dev Cancel sale. Should not be called without checking if champ is really for sale.
     function _cancelChampSale(Champ storage champ) private {
        //cancel champ&#39;s sale
        //no need waste gas to overwrite his price.
        champ.forSale = false;
        champsForSaleCount--;
     }
     

    /*
     * Internal
     */
    /// @notice Transfer champ
    function transferChamp(address _from, address _to, uint256 _champId) internal ifChampForSaleThenCancelSale(_champId){
        Champ storage champ = champs[_champId];

        //transfer champ
        addressInfo[_to].champsCount++;
        addressInfo[_from].champsCount--;
        champToOwner[_champId] = _to;

        //transfer items
        if(champ.eq_sword != 0) { transferItem(_from, _to, champ.eq_sword); }
        if(champ.eq_shield != 0) { transferItem(_from, _to, champ.eq_shield); }
        if(champ.eq_helmet != 0) { transferItem(_from, _to, champ.eq_helmet); }

        emit TransferChamp(_from, _to, _champId);
    }



    /*
     * Public
     */
    /// @notice Champ is no more for sale
    function cancelChampSale(uint256 _id) public 
      champIsForSale(_id) 
      onlyOwnerOfChamp(_id) {
        Champ storage champ = champs[_id];
        _cancelChampSale(champ);
    }


    /*
     * External
     */
    /// @notice Gift champ
    /// @dev Address _from is msg.sender
    function giveChamp(address _to, uint256 _champId) external 
      onlyOwnerOfChamp(_champId) {
        transferChamp(msg.sender, _to, _champId);
    }


    /// @notice Sets champ for sale
    function setChampForSale(uint256 _id, uint256 _price) external 
      onlyOwnerOfChamp(_id) 
      champIsNotForSale(_id) {
        Champ storage champ = champs[_id];
        champ.forSale = true;
        champ.price = _price;
        champsForSaleCount++;
    }
    
    
    /// @notice Buys champ
    function buyChamp(uint256 _id) external payable 
      whenNotPaused 
      onlyNotOwnerOfChamp(_id) 
      champIsForSale(_id) 
      isPaid(champs[_id].price) 
      distributeSaleInput(champToOwner[_id]) {
        transferChamp(champToOwner[_id], msg.sender, _id);
    }
    
}



/// @title Only used for deploying all contracts
contract MyCryptoChampCore is ChampMarket {
	/* 
		&#169; Copyright 2018 - Patrik Mojzis
		Redistributing and modifying is prohibited.
		
		https://mycryptochamp.io/

		What is MyCryptoChamp?
		- Blockchain game about upgrading champs by fighting, getting better items,
		  trading them and the best 800 champs are daily rewarded by real Ether.

		Feel free to ask any questions
		<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="127a777e7e7d527f6b71606b62667d717a737f623c7b7d">[email&#160;protected]</a>
	*/
}