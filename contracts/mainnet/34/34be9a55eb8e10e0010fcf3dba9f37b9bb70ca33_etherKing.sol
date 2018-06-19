pragma solidity ^0.4.18;


/**
 * ether King contract
 **/
contract etherKing{
    
    
    //contract owner
    address private owner;
    
    uint256 private battleCount = 1;
    
    uint256 private price;
    
    address[] private countryOwners = new address[](6);
    
    uint256 private win = 6;
    
    
    //history
    uint256 private historyCount;
    
    mapping(uint256 => address) private winAddressHistory;
    
    mapping(uint256 => uint8) private winItemIdHistory;
    
    
    
    function etherKing(uint256 _price) public {
        price = _price;
        owner = msg.sender;
    }
    
    
    event BuyCountry(address indexed to, uint256 indexed countryId, uint256 indexed price);
    
    event Win(address indexed win, uint256 indexed reward, uint256 indexed winNum);
    
    
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
    
    
    
    function withdrawAll () onlyOwner() public {
        msg.sender.transfer(this.balance);
    }

    function withdrawAmount (uint256 _amount) onlyOwner() public {
        msg.sender.transfer(_amount);
    }
    
    
    
    function battleCountOf() public view returns(uint256){
        return battleCount;
    }
    
    
    function countryLengthOf()public view returns(uint256){
        return countryOwners.length;
    }
    
    
    function winAddressOf() public view returns(address _address, uint256 winNum){
        if(win >= 6){
            winNum = win;
            _address = address(0);
        } else {
            winNum = win;
            _address = countryOwners[winNum];
        }
    }
    
    function countryOwnersOf() public view returns(address[]){
        return countryOwners;
    }
    
    
    
    function ownerOfCountryCount(address _owner) public view returns(uint256){
        require(_owner != address(0));
        uint256 count = 0;
        for(uint256 i = 0; i < countryOwners.length; i++){
            if(countryOwners[i] == _owner){
                count++;
            }
        }
        return count;
    }
    

    
    function isBuyFull() public view returns(bool){
        for(uint256 i = 0; i < countryOwners.length; i++){
            if(countryOwners[i] == address(0)){
                return false;
            }
        }
        return true;
    }
    
    
    
    function buyCountry(uint256 countryId) public payable{
        require(msg.value >= price);
        require(countryId < countryOwners.length);
        require(countryOwners[countryId] == address(0));
        require(!isContract(msg.sender));
        require(msg.sender != address(0));
        
        countryOwners[countryId] = msg.sender;
        
        BuyCountry(msg.sender, countryId, msg.value);
    }
    
    
    function calculateWin() onlyOwner public {
        require(isBuyFull());
        
        win = getRandom(uint128(battleCount), countryOwners.length);
        
        address winAddress = countryOwners[win];
        
        uint256 reward = 1 ether;
        
        if(reward > this.balance)
        {
            reward = this.balance;
        }
        
        winAddress.transfer(reward);
        
        Win(winAddress, reward, win);
        
        //add History
        addHistory(battleCount, winAddress, uint8(win));
    }
    
        
    function reset() onlyOwner public {
        require(win < 6);
        
        win = 6;
        
        battleCount++;
        
        for(uint256 i = 0; i < countryOwners.length; i++){
            delete countryOwners[i];
        }
    }
    
    
    function getRandom(uint128 count, uint256 limit) private view returns(uint256){
        uint lastblocknumberused = block.number - 1 ;
    	bytes32 lastblockhashused = block.blockhash(lastblocknumberused);
    	uint128 lastblockhashused_uint = uint128(lastblockhashused) + count;
    	uint256 hashymchasherton = sha(lastblockhashused_uint, lastblockhashused);
    	
    	return hashymchasherton % limit;
    }
    

    function sha(uint128 wager, bytes32 _lastblockhashused) private view returns(uint256)
    { 
        return uint256(keccak256(block.difficulty, block.coinbase, now, _lastblockhashused, wager));  
    }

    
    /* Util */
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) } // solium-disable-line
        return size > 0;
    }
   
    
    
    function historyCountOf() public view returns (uint256){
        return historyCount;
    }
    
    
    function addressHistoryOf(uint256 _battleId) public view returns(address) {
        address _address = winAddressHistory[_battleId];
        return _address;
    }
    
    
    function itemHistoryOf(uint256 _battleId) public view returns(uint8){
        uint8 _item = winItemIdHistory[_battleId];
        return _item;
    }
    
    
    
    function getHistory(uint256 minBattleId, uint256 maxBattleId) public view returns(address[] _addressArray, uint8[] _itemArray, uint256 _minBattleId){
        require(minBattleId > 0);
        require(maxBattleId <= historyCount);
        
        uint256 length = (maxBattleId - minBattleId) + 1;
        _addressArray = new address[](length);
        _itemArray = new uint8[](length);
        _minBattleId = minBattleId;
        
        for(uint256 i = 0; i < length; i++){
            _addressArray[i] = addressHistoryOf(minBattleId + i);
            _itemArray[i] = itemHistoryOf(minBattleId + i);
        }
    }
    
    
    
    
    function addHistory(uint256 _battleId, address _win, uint8 _itemId) private {
        require(addressHistoryOf(_battleId) == address(0));
        
        winAddressHistory[_battleId] = _win;
        winItemIdHistory[_battleId] = _itemId;
        historyCount++;
    }
    
    

}