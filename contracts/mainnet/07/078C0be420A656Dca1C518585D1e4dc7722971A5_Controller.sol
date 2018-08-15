pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
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

contract MyCryptoChampCore{
    struct Champ {
        uint id;
        uint attackPower;
        uint defencePower;
        uint cooldownTime; 
        uint readyTime;
        uint winCount;
        uint lossCount;
        uint position; 
        uint price; 
        uint withdrawCooldown; 
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale; 
    }
    
    struct AddressInfo {
        uint withdrawal;
        uint champsCount;
        uint itemsCount;
        string name;
    }

    struct Item {
        uint id;
        uint8 itemType; 
        uint8 itemRarity; 
        uint attackPower;
        uint defencePower;
        uint cooldownReduction;
        uint price;
        uint onChampId; 
        bool onChamp; 
        bool forSale;
    }
    
    Champ[] public champs;
    Item[] public items;
    mapping (uint => uint) public leaderboard;
    mapping (address => AddressInfo) public addressInfo;
    mapping (bool => mapping(address => mapping (address => bool))) public tokenOperatorApprovals;
    mapping (bool => mapping(uint => address)) public tokenApprovals;
    mapping (bool => mapping(uint => address)) public tokenToOwner;
    mapping (uint => string) public champToName;
    mapping (bool => uint) public tokensForSaleCount;
    uint public pendingWithdrawal = 0;

    function addWithdrawal(address _address, uint _amount) public;
    function clearTokenApproval(address _from, uint _tokenId, bool _isTokenChamp) public;
    function setChampsName(uint _champId, string _name) public;
    function setLeaderboard(uint _x, uint _value) public;
    function setTokenApproval(uint _id, address _to, bool _isTokenChamp) public;
    function setTokenOperatorApprovals(address _from, address _to, bool _approved, bool _isTokenChamp) public;
    function setTokenToOwner(uint _id, address _owner, bool _isTokenChamp) public;
    function setTokensForSaleCount(uint _value, bool _isTokenChamp) public;
    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) public;
    function newChamp(uint _attackPower,uint _defencePower,uint _cooldownTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale,address _owner) public returns (uint);
    function newItem(uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale,address _owner) public returns (uint);
    function updateAddressInfo(address _address, uint _withdrawal, bool _updatePendingWithdrawal, uint _champsCount, bool _updateChampsCount, uint _itemsCount, bool _updateItemsCount, string _name, bool _updateName) public;
    function updateChamp(uint _champId, uint _attackPower,uint _defencePower,uint _cooldownTime,uint _readyTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _withdrawCooldown,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale) public;
    function updateItem(uint _id,uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale) public;

    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256);
    function getChampsByOwner(address _owner) external view returns(uint256[]);
    function getTokensForSale(bool _isTokenChamp) view external returns(uint256[]);
    function getItemsByOwner(address _owner) external view returns(uint256[]);
    function getTokenCount(bool _isTokenChamp) external view returns(uint);
    function getTokenURIs(uint _tokenId, bool _isTokenChamp) public view returns(string);
    function onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) external view returns(bool);
    
}

contract Inherit is Ownable{
  address internal coreAddress;
  MyCryptoChampCore internal core;

  modifier onlyCore(){
    require(msg.sender == coreAddress);
    _;
  }

  function loadCoreAddress(address newCoreAddress) public onlyOwner {
    require(newCoreAddress != address(0));
    coreAddress = newCoreAddress;
    core = MyCryptoChampCore(coreAddress);
  }

}

contract Strings {

    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

}

//ERC721 Contract 
interface EC {
    function emitTransfer(address _from, address _to, uint _tokenId) external; //Controller uses only this one function
}

//author Patrik Mojzis
contract Controller is Inherit, Strings {

    using SafeMath for uint; 

    struct Champ {
        uint id; //same as position in Champ[]
        uint attackPower;
        uint defencePower;
        uint cooldownTime; //how long does it take to be ready attack again
        uint readyTime; //if is smaller than block.timestamp champ is ready to fight
        uint winCount;
        uint lossCount;
        uint position; //position in leaderboard. subtract 1 and you got position in leaderboard[]
        uint price; //selling price
        uint withdrawCooldown; //if you one of the 800 best champs and withdrawCooldown is less as block.timestamp then you get ETH reward
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale; //is champ for sale?
    }

    struct Item {
        uint id;
        uint8 itemType; // 1 - Sword | 2 - Shield | 3 - Helmet
        uint8 itemRarity; // 1 - Common | 2 - Uncommon | 3 - Rare | 4 - Epic | 5 - Legendery | 6 - Forged
        uint attackPower;
        uint defencePower;
        uint cooldownReduction;
        uint price;
        uint onChampId; //can not be used to decide if item is on champ, because champ&#39;s id can be 0, &#39;bool onChamp&#39; solves it.
        bool onChamp; 
        bool forSale; //is item for sale?
    }

    EC champsEC;
    EC itemsEC;
     
    /// @notice People are allowed to withdraw only if min. balance (0.01 gwei) is reached
    modifier contractMinBalanceReached(){
        uint pendingWithdrawal = core.pendingWithdrawal();
        require( (address(core).balance).sub(pendingWithdrawal) > 1000000 );
        _;
    }
    
    modifier onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) 
    {
        require(core.onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp));
        _;
    }
    

    /// @notice Gets champ&#39;s reward in wei
    function getChampReward(uint _position) public view returns(uint) 
    {
        if(_position <= 800){
            //percentageMultipier = 10,000
            //maxReward = 2000 = .2% * percentageMultipier
            //subtractPerPosition = 2 = .0002% * percentageMultipier
            //2000 - (2 * (_position - 1))
            uint rewardPercentage = uint(2000).sub(2 * (_position - 1));

            //available funds are all funds - already pending
            uint availableWithdrawal = address(coreAddress).balance.sub(core.pendingWithdrawal());

            //calculate reward for champ&#39;s position
            //1000000 = percentageMultipier * 100
            return availableWithdrawal / 1000000 * rewardPercentage;
        }else{
            return uint(0);
        }
    }

    function setChampEC(address _address) public onlyOwner {
        champsEC = EC(_address);
    }


    function setItemsEC(address _address) public onlyOwner {
        itemsEC = EC(_address);
    }

    function changeChampsName(uint _champId, string _name, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_champId, _msgsender, true)
    onlyCore
    {
        core.setChampsName(_champId, _name);
    }

    /// @dev Move champ reward to pending withdrawal to his wallet. 
    function withdrawChamp(uint _id, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_id, _msgsender, true) 
    contractMinBalanceReached  
    onlyCore 
    {
        Champ memory champ = _getChamp(_id);
        require(champ.position <= 800); 
        require(champ.withdrawCooldown < block.timestamp); //isChampWithdrawReady

        champ.withdrawCooldown = block.timestamp + 1 days; //one withdrawal 1 per day
        _updateChamp(champ); //update core storage

        core.addWithdrawal(_msgsender, getChampReward(champ.position));
    }
    

    /// @dev Is called from from Attack function after the winner is already chosen. Updates abilities, champ&#39;s stats and swaps positions.
    function _attackCompleted(Champ memory _winnerChamp, Champ memory _defeatedChamp, uint _pointsGiven) private 
    {
        /*
         * Updates abilities after fight
         */
        //winner abilities update
        _winnerChamp.attackPower += _pointsGiven; //increase attack power
        _winnerChamp.defencePower += _pointsGiven; //max point that was given - already given to AP
                
        //defeated champ&#39;s abilities update
        //checks for not cross minimal AP & DP points
        //_defeatedChamp.attackPower = _subAttack(_defeatedChamp.attackPower, _pointsGiven); //decrease attack power
        _defeatedChamp.attackPower = (_defeatedChamp.attackPower <= _pointsGiven + 2) ? 2 : _defeatedChamp.attackPower - _pointsGiven; //Subtracts ability points. Helps to not cross minimal attack ability points -> 2

        //_defeatedChamp.defencePower = _subDefence(_defeatedChamp.defencePower, _pointsGiven); // decrease defence power
        _defeatedChamp.defencePower = (_defeatedChamp.defencePower <= _pointsGiven) ? 1 : _defeatedChamp.defencePower - _pointsGiven; //Subtracts ability points. Helps to not cross minimal defence ability points -> 1


        /*
         * Update champs&#39; wins and losses
         */
        _winnerChamp.winCount++;
        _defeatedChamp.lossCount++;
            

        /*
         * Swap positions
         */
        if(_winnerChamp.position > _defeatedChamp.position) { //require loser to has better (lower) postion than attacker
            uint winnerPosition = _winnerChamp.position;
            uint loserPosition = _defeatedChamp.position;
        
            _defeatedChamp.position = winnerPosition;
            _winnerChamp.position = loserPosition;
        }

        _updateChamp(_winnerChamp);
        _updateChamp(_defeatedChamp);
    }


    /*
     * External
     */
    function attack(uint _champId, uint _targetId, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_champId, _msgsender, true) 
    onlyCore 
    {
        Champ memory myChamp = _getChamp(_champId); 
        Champ memory enemyChamp = _getChamp(_targetId); 
        
        require (myChamp.readyTime <= block.timestamp); /// Is champ ready to fight again?
        require(_champId != _targetId); /// Prevents from self-attack
        require(core.tokenToOwner(true, _targetId) != address(0)); /// Checks if champ does exist
    
        uint pointsGiven; //total points that will be divided between AP and DP
        uint myChampAttackPower;  
        uint enemyChampDefencePower; 
        uint myChampCooldownReduction;
        
        (myChampAttackPower,,myChampCooldownReduction) = core.getChampStats(_champId);
        (,enemyChampDefencePower,) = core.getChampStats(_targetId);


        //if attacker&#39;s AP is more than target&#39;s DP then attacker wins
        if (myChampAttackPower > enemyChampDefencePower) {
            
            //this should demotivate players from farming on way weaker champs than they are
            //the bigger difference between AP & DP is, the reward is smaller
            if(myChampAttackPower - enemyChampDefencePower < 5){
                pointsGiven = 6; //big experience - 6 ability points
            }else if(myChampAttackPower - enemyChampDefencePower < 10){
                pointsGiven = 4; //medium experience - 4 ability points
            }else{
                pointsGiven = 2; //small experience - 2 ability point to random ability (attack power or defence power)
            }
            
            _attackCompleted(myChamp, enemyChamp, pointsGiven/2);

        } else {
            
            //1 ability point to random ability (attack power or defence power)
            pointsGiven = 2;

            _attackCompleted(enemyChamp, myChamp, pointsGiven/2);
             
        }
        
        //Trigger cooldown for attacker
        myChamp.readyTime = uint(block.timestamp + myChamp.cooldownTime - myChampCooldownReduction);

        _updateChamp(myChamp);

    }

     function _cancelChampSale(Champ memory _champ) private 
     {
        //cancel champ&#39;s sale
        //no need waste gas to overwrite his price.
        _champ.forSale = false;

        /*
        uint champsForSaleCount = core.champsForSaleCount() - 1;
        core.setTokensForSaleCount(champsForSaleCount, true);
        */

        _updateChamp(_champ);
     }
     

    function _transferChamp(address _from, address _to, uint _champId) private onlyCore
    {
        Champ memory champ = _getChamp(_champId);

        //ifChampForSaleThenCancelSale
        if(champ.forSale){
             _cancelChampSale(champ);
        }

        core.clearTokenApproval(_from, _champId, true);

        //transfer champ
        (,uint toChampsCount,,) = core.addressInfo(_to); 
        (,uint fromChampsCount,,) = core.addressInfo(_from);

        core.updateAddressInfo(_to,0,false,toChampsCount + 1,true,0,false,"",false);
        core.updateAddressInfo(_from,0,false,fromChampsCount - 1,true,0,false,"",false);

        core.setTokenToOwner(_champId, _to, true);

        champsEC.emitTransfer(_from,_to,_champId);

        //transfer items
        if(champ.eq_sword != 0) { _transferItem(_from, _to, champ.eq_sword); }
        if(champ.eq_shield != 0) { _transferItem(_from, _to, champ.eq_shield); }
        if(champ.eq_helmet != 0) { _transferItem(_from, _to, champ.eq_helmet); }
    }


    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) external
    onlyCore{
        if(_isTokenChamp){
            _transferChamp(_from, _to, _id);
        }else{
            _transferItem(_from, _to, _id);
        }
    }

    function cancelTokenSale(uint _id, address _msgsender, bool _isTokenChamp) public 
      onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp)
      onlyCore 
    {
        if(_isTokenChamp){
            Champ memory champ = _getChamp(_id);
            require(champ.forSale); //champIsForSale
            _cancelChampSale(champ);
        }else{
            Item memory item = _getItem(_id);
          require(item.forSale);
           _cancelItemSale(item);
        }
    }

    /// @dev Address _from is msg.sender
    function giveToken(address _to, uint _id, address _msgsender, bool _isTokenChamp) external 
      onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp)
      onlyCore 
    {
        if(_isTokenChamp){
            _transferChamp(core.tokenToOwner(true,_id), _to, _id);
        }else{
             _transferItem(core.tokenToOwner(false,_id), _to, _id);
        }
    }


    function setTokenForSale(uint _id, uint _price, address _msgsender, bool _isTokenChamp) external 
      onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp) 
      onlyCore 
    {
        if(_isTokenChamp){
            Champ memory champ = _getChamp(_id);
            require(champ.forSale == false); //champIsNotForSale
            champ.forSale = true;
            champ.price = _price;
            _updateChamp(champ);
            
            /*
            uint champsForSaleCount = core.champsForSaleCount() + 1;
            core.setTokensForSaleCount(champsForSaleCount,true);
            */
        }else{
            Item memory item = _getItem(_id);
            require(item.forSale == false);
            item.forSale = true;
            item.price = _price;
            _updateItem(item);
            
            /*
            uint itemsForSaleCount = core.itemsForSaleCount() + 1;
            core.setTokensForSaleCount(itemsForSaleCount,false);
            */
        }

    }

    function _updateChamp(Champ memory champ) private 
    {
        core.updateChamp(champ.id, champ.attackPower, champ.defencePower, champ.cooldownTime, champ.readyTime, champ.winCount, champ.lossCount, champ.position, champ.price, champ.withdrawCooldown, champ.eq_sword, champ.eq_shield, champ.eq_helmet, champ.forSale);
    }

    function _updateItem(Item memory item) private
    {
        core.updateItem(item.id, item.itemType, item.itemRarity, item.attackPower, item.defencePower, item.cooldownReduction,item.price, item.onChampId, item.onChamp, item.forSale);
    }
    
    function _getChamp(uint _champId) private view returns (Champ)
    {
        Champ memory champ;
        
        //CompilerError: Stack too deep, try removing local variables.
        (champ.id, champ.attackPower, champ.defencePower, champ.cooldownTime, champ.readyTime, champ.winCount, champ.lossCount, champ.position,,,,,,) = core.champs(_champId);
        (,,,,,,,,champ.price, champ.withdrawCooldown, champ.eq_sword, champ.eq_shield, champ.eq_helmet, champ.forSale) = core.champs(_champId);
        
        return champ;
    }
    
    function _getItem(uint _itemId) private view returns (Item)
    {
        Item memory item;
        
        //CompilerError: Stack too deep, try removing local variables.
        (item.id, item.itemType, item.itemRarity, item.attackPower, item.defencePower, item.cooldownReduction,,,,) = core.items(_itemId);
        (,,,,,,item.price, item.onChampId, item.onChamp, item.forSale) = core.items(_itemId);
        
        return item;
    }

    function getTokenURIs(uint _id, bool _isTokenChamp) public pure returns(string)
    {
        if(_isTokenChamp){
            return strConcat(&#39;https://mccapi.patrikmojzis.com/champ.php?id=&#39;, uint2str(_id));
        }else{
            return strConcat(&#39;https://mccapi.patrikmojzis.com/item.php?id=&#39;, uint2str(_id));
        }
    }


    function _takeOffItem(uint _champId, uint8 _type) private
    {
        uint itemId;
        Champ memory champ = _getChamp(_champId);
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
            Item memory item = _getItem(itemId);
            item.onChamp = false;
            _updateItem(item);
        }
    }

    function takeOffItem(uint _champId, uint8 _type, address _msgsender) public 
    onlyApprovedOrOwnerOfToken(_champId, _msgsender, true) 
    onlyCore
    {
            _takeOffItem(_champId, _type);
    }

    function putOn(uint _champId, uint _itemId, address _msgsender) external 
        onlyApprovedOrOwnerOfToken(_champId, _msgsender, true) 
        onlyApprovedOrOwnerOfToken(_itemId, _msgsender, false) 
        onlyCore 
        {
            Champ memory champ = _getChamp(_champId);
            Item memory item = _getItem(_itemId);

            //checks if items is on some other champ
            if(item.onChamp){
                _takeOffItem(item.onChampId, item.itemType); //take off from champ
            }

            item.onChamp = true; //item is on champ
            item.onChampId = _champId; //champ&#39;s id

            //put on
            if(item.itemType == 1){
                //take off actual sword 
                if(champ.eq_sword > 0){
                    _takeOffItem(champ.id, 1);
                }
                champ.eq_sword = _itemId; //put on sword
            }
            if(item.itemType == 2){
                //take off actual shield 
                if(champ.eq_shield > 0){
                    _takeOffItem(champ.id, 2);
                }
                champ.eq_shield = _itemId; //put on shield
            }
            if(item.itemType == 3){
                //take off actual helmet 
                if(champ.eq_helmet > 0){
                    _takeOffItem(champ.id, 3);
                }
                champ.eq_helmet = _itemId; //put on helmet
            }

            _updateChamp(champ);
            _updateItem(item);
    }


    function _cancelItemSale(Item memory item) private {
      //No need to overwrite item&#39;s price
      item.forSale = false;
      
      /*
      uint itemsForSaleCount = core.itemsForSaleCount() - 1;
      core.setTokensForSaleCount(itemsForSaleCount, false);
      */

      _updateItem(item);
    }

    function _transferItem(address _from, address _to, uint _itemID) private 
    {
        Item memory item = _getItem(_itemID);

        if(item.forSale){
              _cancelItemSale(item);
        }

        //take off      
        if(item.onChamp && _to != core.tokenToOwner(true, item.onChampId)){
          _takeOffItem(item.onChampId, item.itemType);
        }

        core.clearTokenApproval(_from, _itemID, false);

        //transfer item
        (,,uint toItemsCount,) = core.addressInfo(_to);
        (,,uint fromItemsCount,) = core.addressInfo(_from);

        core.updateAddressInfo(_to,0,false,0,false,toItemsCount + 1,true,"",false);
        core.updateAddressInfo(_from,0,false,0,false,fromItemsCount - 1,true,"",false);
        
        core.setTokenToOwner(_itemID, _to,false);

        itemsEC.emitTransfer(_from,_to,_itemID);
    }

    function forgeItems(uint _parentItemID, uint _childItemID, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_parentItemID, _msgsender, false) 
    onlyApprovedOrOwnerOfToken(_childItemID, _msgsender, false) 
    onlyCore
    {
        //checks if items are not the same
        require(_parentItemID != _childItemID);
        
        Item memory parentItem = _getItem(_parentItemID);
        Item memory childItem = _getItem(_childItemID);
        
        //if Item For Sale Then Cancel Sale
        if(parentItem.forSale){
          _cancelItemSale(parentItem);
        }
        
        //if Item For Sale Then Cancel Sale
        if(childItem.forSale){
          _cancelItemSale(childItem);
        }

        //take child item off, because child item will be burned
        if(childItem.onChamp){
            _takeOffItem(childItem.onChampId, childItem.itemType);
        }

        //update parent item
        parentItem.attackPower = (parentItem.attackPower > childItem.attackPower) ? parentItem.attackPower : childItem.attackPower;
        parentItem.defencePower = (parentItem.defencePower > childItem.defencePower) ? parentItem.defencePower : childItem.defencePower;
        parentItem.cooldownReduction = (parentItem.cooldownReduction > childItem.cooldownReduction) ? parentItem.cooldownReduction : childItem.cooldownReduction;
        parentItem.itemRarity = uint8(6);

        _updateItem(parentItem);

        //burn child item
        _transferItem(core.tokenToOwner(false,_childItemID), address(0), _childItemID);

    }


}