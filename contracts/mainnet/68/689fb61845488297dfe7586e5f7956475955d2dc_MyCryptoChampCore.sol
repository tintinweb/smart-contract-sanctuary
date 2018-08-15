/* 		
		https://mycryptochamp.io/
		<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e088858c8c8fa08d9983929990948f8388818d90ce898f">[email&#160;protected]</a>
*/

pragma solidity 0.4.24;

contract Controller{
	function getChampReward(uint _position) public view returns(uint);
	function changeChampsName(uint _champId, string _name, address _msgsender) external;
	function withdrawChamp(uint _id, address _msgsender) external;
	function attack(uint _champId, uint _targetId, address _msgsender) external;
	function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) external;
	function cancelTokenSale(uint _id, address _msgsender, bool _isTokenChamp) public;
	function giveToken(address _to, uint _id, address _msgsender, bool _isTokenChamp) external;
	function setTokenForSale(uint _id, uint _price, address _msgsender, bool _isTokenChamp) external;
	function getTokenURIs(uint _id, bool _isTokenChamp) public pure returns(string);
	function takeOffItem(uint _champId, uint8 _type, address _msgsender) public;
	function putOn(uint _champId, uint _itemId, address _msgsender) external;
	function forgeItems(uint _parentItemID, uint _childItemID, address _msgsender) external;
}

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

/// @title MyCryptoChamp Core - Stores all of game data. Functions are stored in the replaceable contracts. This solution was required in order to avoid unexpected bugs and make game upgradeable.
/// @author Patrik Mojzis
contract MyCryptoChampCore {

    using SafeMath for uint;

    struct Champ {
        uint id; //same as position in Champ[]
        uint attackPower;
        uint defencePower;
        uint cooldownTime; //how long does it take to be able attack again
        uint readyTime; //if is smaller than block.timestamp champ is ready to fight
        uint winCount;
        uint lossCount;
        uint position; //subtract 1 and you get position in leaderboard[]
        uint price; //sale price
        uint withdrawCooldown; //if you one of the 800 best champs and withdrawCooldown is less as block.timestamp then you get ETH reward
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale; //is champ for sale?
    }
    
    struct AddressInfo {
        uint withdrawal;
        uint champsCount;
        uint itemsCount;
        string name;
    }

    //Item struct
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
    
    Champ[] public champs;
    Item[] public items;
    mapping (uint => uint) public leaderboard;
    mapping (address => bool) private trusted;
    mapping (address => AddressInfo) public addressInfo;
    mapping (bool => mapping(address => mapping (address => bool))) public tokenOperatorApprovals;
    mapping (bool => mapping(uint => address)) public tokenApprovals;
    mapping (bool => mapping(uint => address)) public tokenToOwner;
    mapping (uint => string) public champToName;
    mapping (bool => uint) public tokensForSaleCount;
    uint public pendingWithdrawal = 0;
    address private contractOwner;
    Controller internal controller;


    constructor () public 
    {
        trusted[msg.sender] = true;
        contractOwner = msg.sender;
    }
    

    /*============== MODIFIERS ==============*/
    modifier onlyTrusted(){
        require(trusted[msg.sender]);
        _;
    }

    modifier isPaid(uint _price)
    {
        require(msg.value >= _price);
        _;
    }

    modifier onlyNotOwnerOfItem(uint _itemId) {
        require(_itemId != 0);
        require(msg.sender != tokenToOwner[false][_itemId]);
        _;
    }

    modifier isItemForSale(uint _id){
        require(items[_id].forSale);
        _;
    }

    modifier onlyNotOwnerOfChamp(uint _champId) 
    {
        require(msg.sender != tokenToOwner[true][_champId]);
        _;
    }

    modifier isChampForSale(uint _id)
    {
        require(champs[_id].forSale);
        _;
    }


    /*============== CONTROL COTRACT ==============*/
    function loadController(address _address) external onlyTrusted {
        controller = Controller(_address);
    }

    
    function setTrusted(address _address, bool _trusted) external onlyTrusted {
        trusted[_address] = _trusted;
    }
    
    function transferOwnership(address newOwner) public onlyTrusted {
        require(newOwner != address(0));
        contractOwner = newOwner;
    }
    

    /*============== PRIVATE FUNCTIONS ==============*/
    function _addWithdrawal(address _address, uint _amount) private 
    {
        addressInfo[_address].withdrawal += _amount;
        pendingWithdrawal += _amount;
    }

    /// @notice Distribute input funds between contract owner and players
    function _distributeNewSaleInput(address _affiliateAddress) private 
    {
        //contract owner
        _addWithdrawal(contractOwner, ((msg.value / 100) * 60)); // 60%

        //affiliate
        //checks if _affiliateAddress is set & if affiliate address is not buying player
        if(_affiliateAddress != address(0) && _affiliateAddress != msg.sender){
            _addWithdrawal(_affiliateAddress, ((msg.value / 100) * 25)); //provision is 25%
            
        }
    }

    
    /*============== ONLY TRUSTED ==============*/
    function addWithdrawal(address _address, uint _amount) public onlyTrusted 
    {
        _addWithdrawal(_address, _amount);
    }

    function clearTokenApproval(address _from, uint _tokenId, bool _isTokenChamp) public onlyTrusted
    {
        require(tokenToOwner[_isTokenChamp][_tokenId] == _from);
        if (tokenApprovals[_isTokenChamp][_tokenId] != address(0)) {
            tokenApprovals[_isTokenChamp][_tokenId] = address(0);
        }
    }

    function emergencyWithdraw() external onlyTrusted
    {
        contractOwner.transfer(address(this).balance);
    }

    function setChampsName(uint _champId, string _name) public onlyTrusted 
    {
        champToName[_champId] = _name;
    }

    function setLeaderboard(uint _x, uint _value) public onlyTrusted
    {
        leaderboard[_x] = _value;
    }

    function setTokenApproval(uint _id, address _to, bool _isTokenChamp) public onlyTrusted
    {
        tokenApprovals[_isTokenChamp][_id] = _to;
    }

    function setTokenOperatorApprovals(address _from, address _to, bool _approved, bool _isTokenChamp) public onlyTrusted
    {
        tokenOperatorApprovals[_isTokenChamp][_from][_to] = _approved;
    }

    function setTokenToOwner(uint _id, address _owner, bool _isTokenChamp) public onlyTrusted
    {
        tokenToOwner[_isTokenChamp][_id] = _owner;
    }

    function setTokensForSaleCount(uint _value, bool _isTokenChamp) public onlyTrusted 
    {
        tokensForSaleCount[_isTokenChamp] = _value;
    }

    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) public onlyTrusted
    {
        controller.transferToken(_from, _to, _id, _isTokenChamp);
    }

    function updateAddressInfo(address _address, uint _withdrawal, bool _updatePendingWithdrawal, uint _champsCount, bool _updateChampsCount, uint _itemsCount, bool _updateItemsCount, string _name, bool _updateName) public onlyTrusted {
        AddressInfo storage ai = addressInfo[_address];
        if(_updatePendingWithdrawal){ ai.withdrawal = _withdrawal; }
        if(_updateChampsCount){ ai.champsCount = _champsCount; }
        if(_updateItemsCount){ ai.itemsCount = _itemsCount; }
        if(_updateName){ ai.name = _name; }
    }

    function newChamp(
        uint _attackPower,
        uint _defencePower,
        uint _cooldownTime,
        uint _winCount,
        uint _lossCount,
        uint _position,
        uint _price,
        uint _eq_sword, 
        uint _eq_shield, 
        uint _eq_helmet, 
        bool _forSale,
        address _owner
    ) public onlyTrusted returns (uint){

        Champ memory champ = Champ({
            id: 0,
            attackPower: 0, //CompilerError: Stack too deep, try removing local variables.
            defencePower: _defencePower,
            cooldownTime: _cooldownTime,
            readyTime: 0,
            winCount: _winCount,
            lossCount: _lossCount,
            position: _position,
            price: _price,
            withdrawCooldown: 0,
            eq_sword: _eq_sword,
            eq_shield: _eq_shield,
            eq_helmet: _eq_helmet,
            forSale: _forSale
        });
        champ.attackPower = _attackPower;

        uint id = champs.push(champ) - 1; 
        champs[id].id = id; 
        leaderboard[_position] = id;

        addressInfo[_owner].champsCount++;
        tokenToOwner[true][id] = _owner;

        if(_forSale){
            tokensForSaleCount[true]++;
        }

        return id;
    }

    function newItem(
        uint8 _itemType,
        uint8 _itemRarity,
        uint _attackPower,
        uint _defencePower,
        uint _cooldownReduction,
        uint _price,
        uint _onChampId,
        bool _onChamp,
        bool _forSale,
        address _owner
    ) public onlyTrusted returns (uint)
    { 
        //create that struct
        Item memory item = Item({
            id: 0,
            itemType: _itemType,
            itemRarity: _itemRarity, 
            attackPower: _attackPower,
            defencePower: _defencePower,
            cooldownReduction: _cooldownReduction,
            price: _price,
            onChampId: _onChampId,
            onChamp: _onChamp, 
            forSale: _forSale

        });

        uint id = items.push(item) - 1;
        items[id].id = id; 

        addressInfo[_owner].itemsCount++;
        tokenToOwner[false][id] = _owner;

        if(_forSale){
            tokensForSaleCount[false]++;
        }

        return id;
    }

    function updateChamp(
        uint _champId, 
        uint _attackPower,
        uint _defencePower,
        uint _cooldownTime,
        uint _readyTime,
        uint _winCount,
        uint _lossCount,
        uint _position,
        uint _price,
        uint _withdrawCooldown,
        uint _eq_sword, 
        uint _eq_shield, 
        uint _eq_helmet, 
        bool _forSale
    ) public onlyTrusted {
        Champ storage champ = champs[_champId];
        if(champ.attackPower != _attackPower){champ.attackPower = _attackPower;}
        if(champ.defencePower != _defencePower){champ.defencePower = _defencePower;}
        if(champ.cooldownTime != _cooldownTime){champ.cooldownTime = _cooldownTime;}
        if(champ.readyTime != _readyTime){champ.readyTime = _readyTime;}
        if(champ.winCount != _winCount){champ.winCount = _winCount;}
        if(champ.lossCount != _lossCount){champ.lossCount = _lossCount;}
        if(champ.position != _position){
            champ.position = _position;
            leaderboard[_position] = _champId;
        }
        if(champ.price != _price){champ.price = _price;}
        if(champ.withdrawCooldown != _withdrawCooldown){champ.withdrawCooldown = _withdrawCooldown;}
        if(champ.eq_sword != _eq_sword){champ.eq_sword = _eq_sword;}
        if(champ.eq_shield != _eq_shield){champ.eq_shield = _eq_shield;}
        if(champ.eq_helmet != _eq_helmet){champ.eq_helmet = _eq_helmet;}
        if(champ.forSale != _forSale){ 
            champ.forSale = _forSale; 
            if(_forSale){
                tokensForSaleCount[true]++;
            }else{
                tokensForSaleCount[true]--;
            }
        }
    }

    function updateItem(
        uint _id,
        uint8 _itemType,
        uint8 _itemRarity,
        uint _attackPower,
        uint _defencePower,
        uint _cooldownReduction,
        uint _price,
        uint _onChampId,
        bool _onChamp,
        bool _forSale
    ) public onlyTrusted
    {
        Item storage item = items[_id];
        if(item.itemType != _itemType){item.itemType = _itemType;}
        if(item.itemRarity != _itemRarity){item.itemRarity = _itemRarity;}
        if(item.attackPower != _attackPower){item.attackPower = _attackPower;}
        if(item.defencePower != _defencePower){item.defencePower = _defencePower;}
        if(item.cooldownReduction != _cooldownReduction){item.cooldownReduction = _cooldownReduction;}
        if(item.price != _price){item.price = _price;}
        if(item.onChampId != _onChampId){item.onChampId = _onChampId;}
        if(item.onChamp != _onChamp){item.onChamp = _onChamp;}
        if(item.forSale != _forSale){
            item.forSale = _forSale;
            if(_forSale){
                tokensForSaleCount[false]++;
            }else{
                tokensForSaleCount[false]--;
            }
        }
    }


    /*============== CALLABLE BY PLAYER ==============*/
    function buyItem(uint _id, address _affiliateAddress) external payable 
    onlyNotOwnerOfItem(_id) 
    isItemForSale(_id)
    isPaid(items[_id].price) 
    {
        if(tokenToOwner[false][_id] == address(this)){
            _distributeNewSaleInput(_affiliateAddress);
        }else{
            _addWithdrawal(tokenToOwner[false][_id], msg.value);
        }
        controller.transferToken(tokenToOwner[false][_id], msg.sender, _id, false);
    }

    function buyChamp(uint _id, address _affiliateAddress) external payable
    onlyNotOwnerOfChamp(_id) 
    isChampForSale(_id) 
    isPaid(champs[_id].price) 
    {
        if(tokenToOwner[true][_id] == address(this)){
            _distributeNewSaleInput(_affiliateAddress);
        }else{
            _addWithdrawal(tokenToOwner[true][_id], msg.value);
        }
        controller.transferToken(tokenToOwner[true][_id], msg.sender, _id, true);
    }

    function changePlayersName(string _name) external {
        addressInfo[msg.sender].name = _name;
    }

    function withdrawToAddress(address _address) external 
    {
        address playerAddress = _address;
        if(playerAddress == address(0)){ playerAddress = msg.sender; }
        uint share = addressInfo[playerAddress].withdrawal; //gets pending funds
        require(share > 0); //is it more than 0?

        addressInfo[playerAddress].withdrawal = 0; //set player&#39;s withdrawal pendings to 0 
        pendingWithdrawal = pendingWithdrawal.sub(share); //subtract share from total pendings 
        
        playerAddress.transfer(share); //transfer
    }


    /*============== VIEW FUNCTIONS ==============*/
    function getChampsByOwner(address _owner) external view returns(uint256[]) {
        uint256[] memory result = new uint256[](addressInfo[_owner].champsCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < champs.length; i++) {
            if (tokenToOwner[true][i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getTokensForSale(bool _isTokenChamp) view external returns(uint256[]){
        uint256[] memory result = new uint256[](tokensForSaleCount[_isTokenChamp]);
        if(tokensForSaleCount[_isTokenChamp] > 0){
            uint256 counter = 0;
            if(_isTokenChamp){
                for (uint256 i = 0; i < champs.length; i++) {
                    if (champs[i].forSale == true) {
                        result[counter]=i;
                        counter++;
                    }
                }
            }else{
                for (uint256 n = 0; n < items.length; n++) {
                    if (items[n].forSale == true) {
                        result[counter]=n;
                        counter++;
                    }
                }
            }
        }
        return result;
    }

    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256){
        Champ storage champ = champs[_champId];
        Item storage sword = items[champ.eq_sword];
        Item storage shield = items[champ.eq_shield];
        Item storage helmet = items[champ.eq_helmet];

        uint totalAttackPower = champ.attackPower + sword.attackPower + shield.attackPower + helmet.attackPower; //Gets champs AP
        uint totalDefencePower = champ.defencePower + sword.defencePower + shield.defencePower + helmet.defencePower; //Gets champs  DP
        uint totalCooldownReduction = sword.cooldownReduction + shield.cooldownReduction + helmet.cooldownReduction; //Gets  CR

        return (totalAttackPower, totalDefencePower, totalCooldownReduction);
    }

    function getItemsByOwner(address _owner) external view returns(uint256[]) {
        uint256[] memory result = new uint256[](addressInfo[_owner].itemsCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (tokenToOwner[false][i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getTokenCount(bool _isTokenChamp) external view returns(uint)
    {
        if(_isTokenChamp){
            return champs.length - addressInfo[address(0)].champsCount;
        }else{
            return items.length - 1 - addressInfo[address(0)].itemsCount;
        }
    }
    
    function getTokenURIs(uint _tokenId, bool _isTokenChamp) public view returns(string)
    {
        return controller.getTokenURIs(_tokenId,_isTokenChamp);
    }

    function onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) external view returns(bool)
    {
        if(!_isTokenChamp){
            require(_id != 0);
        }
        address owner = tokenToOwner[_isTokenChamp][_id];
        return(_msgsender == owner || _msgsender == tokenApprovals[_isTokenChamp][_id] || tokenOperatorApprovals[_isTokenChamp][owner][_msgsender]);
    }


    /*============== DELEGATE ==============*/
    function attack(uint _champId, uint _targetId) external{
        controller.attack(_champId, _targetId, msg.sender);
    }

    function cancelTokenSale(uint _id, bool _isTokenChamp) public{
        controller.cancelTokenSale(_id, msg.sender, _isTokenChamp);
    }

    function changeChampsName(uint _champId, string _name) external{
        controller.changeChampsName(_champId, _name, msg.sender);
    }

    function forgeItems(uint _parentItemID, uint _childItemID) external{
        controller.forgeItems(_parentItemID, _childItemID, msg.sender);
    }

    function giveToken(address _to, uint _champId, bool _isTokenChamp) external{
        controller.giveToken(_to, _champId, msg.sender, _isTokenChamp);
    }

    function setTokenForSale(uint _id, uint _price, bool _isTokenChamp) external{
        controller.setTokenForSale(_id, _price, msg.sender, _isTokenChamp);
    }

    function putOn(uint _champId, uint _itemId) external{
        controller.putOn(_champId, _itemId, msg.sender);
    }

    function takeOffItem(uint _champId, uint8 _type) public{
        controller.takeOffItem(_champId, _type, msg.sender);
    }

    function withdrawChamp(uint _id) external{
        controller.withdrawChamp(_id, msg.sender); 
    }

    function getChampReward(uint _position) public view returns(uint){
        return controller.getChampReward(_position);
    }
}