/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity 0.8.1;

contract CommonObjects{
    
    struct BorgPeice{
        bool exists;
        string[] colors;
        int colorSize;
        mapping (string => uint256[]) colorPositions;
    }
    
    struct LayerMetaData{
        string name;
        uint256 position;
    }
    
    struct Layer{
        bool exists;
        string name;
        mapping(uint => LayerItem) layerItems;
        uint256 layerItemSize;
        uint256 layerItemsCumulativeTotal;
    }
    
    struct LayerItem{
        bool exists;
        uint256 chance;
        string borgPeiceName;
    }
    
    struct Borg{
        uint256 id;
        bool exists;
        uint256 descendants;
        string[] borgPeiceNames;
        uint256[] borgPeiceLayerPositions;
        uint256 borgPeicesSize;
    }
}

/**
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract Ownable {
    /**
    * @dev The owner of the contract
    */
    address payable internal _owner;
    
    /**
    * @dev The new owner of the contract (for ownership swap)
    */
    address payable internal _potentialNewOwner;
 
    /**
     * @dev Emitted when ownership of the contract has been transferred and is set by 
     * a call to {AcceptOwnership}.
    */
    event OwnershipTransferred(address payable indexed from, address payable indexed to, uint date);
 
    /**
     * @dev Sets the owner upon contract creation
     **/
    constructor() {
      _owner = payable(msg.sender);
    }
  
    modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
    }
  
    function transferOwnership(address payable newOwner) external onlyOwner {
      _potentialNewOwner = newOwner;
    }
  
    function acceptOwnership() external {
      require(msg.sender == _potentialNewOwner);
      emit OwnershipTransferred(_owner, _potentialNewOwner, block.timestamp);
      _owner = _potentialNewOwner;
    }
  
    function getOwner() view external returns(address){
        return _owner;
    }
  
    function getPotentialNewOwner() view external returns(address){
        return _potentialNewOwner;
    }
}

contract BorgFactory is CommonObjects, Ownable{
    
    //TODO: NOT PUBLIC
    mapping (string => BorgPeice) public _borgPeices;

    bool _isLocked;
    
    constructor(){
        _isLocked = false;
    }
    
    function resetBorgPeice(string memory borgPeiceName) public onlyOwner{
        BorgPeice storage borgPeice = _borgPeices[borgPeiceName];
        require(borgPeice.exists, "Borg Peice doesn't exist");
        
        require(_isLocked == false, "Factory is locked");
                
        borgPeice.exists = false;
        for(uint256 i = 0;i<borgPeice.colors.length;i++){
            delete borgPeice.colorPositions[borgPeice.colors[i]];
        }
        borgPeice.colorSize = 0;
        delete borgPeice.colors;
    }
    
    function addColorToBorgPeice(string memory borgPeiceName, string memory color, uint256[] memory positions) public onlyOwner{
        require(_isLocked == false, "Factory is locked");
        
        BorgPeice storage borgPeice = _borgPeices[borgPeiceName];
        borgPeice.colors.push(color);
        borgPeice.colorSize = borgPeice.colorSize + 1;
        borgPeice.colorPositions[color] = positions;
        borgPeice.exists = true;
    }
    
    function getBorgPeice(string memory borgPeiceName, uint256 expectedSize) public view returns (string[] memory imagePixals){
        BorgPeice storage borgPeice = _borgPeices[borgPeiceName];
        require(borgPeice.exists, "Borg peice doesn't exist");
        
        imagePixals = new string[](expectedSize);
        
        for(uint256 i = 0;i<borgPeice.colors.length;i++){
            string memory color = borgPeice.colors[i];
            uint256[] memory positions = borgPeice.colorPositions[color];
            for(uint256 j = 0;j<positions.length;j++){
                imagePixals[positions[j]] = color;
            }
        }
        
        return imagePixals;
    }
    
    function combineBorgPeices(string[] memory borgPeiceNames, uint256 expectedSize) public view returns (string[] memory imagePixals){
        
        imagePixals = new string[](expectedSize);
        
        for(uint256 i=0;i<borgPeiceNames.length;i++){
             BorgPeice storage borgPeice = _borgPeices[borgPeiceNames[i]];
             require(borgPeice.exists, "Borg peice doesn't exist");
             
             for(uint256 j = 0;j<borgPeice.colors.length;j++){
                string memory color = borgPeice.colors[j];
                uint256[] memory positions = borgPeice.colorPositions[color];
                for(uint256 k = 0;k<positions.length;k++){
                    imagePixals[positions[k]] = color;
                }
            }
        }
 
        return imagePixals;
    }
    
    function isLocked() public view returns(bool locked){
        return _isLocked;
    }
}

contract NumberUtils{
    // Intializing the state variable
    uint _randNonce = 0;
          
    function _getRandomNumber(uint256 modulus) internal returns(uint){
           // increase nonce
           _randNonce++;  
           return uint(keccak256(abi.encodePacked(block.timestamp, 
                                                  msg.sender, 
                                                  _randNonce))) % modulus;
    }
}

contract Borgs is BorgFactory, NumberUtils{
    
    // TODO: not public
    mapping (string => Layer) public _layers;
    mapping (uint256 => Borg) public _borgs;
    LayerMetaData[] public _layerMetaData;
    uint256[] _allGeneratedBorgIds;
    
    uint256 _currentBorgId = 0;
    uint256 public IMAGE_SIZE = 576;

    constructor(){
    }
    
    function getBorgImage(uint256 borgId) public view returns(string[] memory){
        Borg memory borg = _borgs[borgId];
        return combineBorgPeices(borg.borgPeiceNames, IMAGE_SIZE);
    }
    
    function getLayersBorgPeice(string memory layerName, uint256 position) public view returns (string[] memory){
        Layer storage layer = _layers[layerName];
        LayerItem storage layerItem = layer.layerItems[position];
        string[] memory borgPeice = getBorgPeice(layerItem.borgPeiceName, IMAGE_SIZE);
        return borgPeice;
    }
    
    function generateToken() external
    {
        require(_layerMetaData.length > 0, "No layers present");
        
        // This means if we want to have no selection, blank images will have to be instered as borg peices
        string[] memory borgPeiceNames = new string[](_layerMetaData.length);
        uint256[] memory layerItemPositions = new uint256[](_layerMetaData.length);

        for(uint256 i=0;i<_layerMetaData.length;i++){
            LayerMetaData storage layerMetaData = _layerMetaData[i];
            (borgPeiceNames[i], layerItemPositions[i]) = _getRandomLayerItemName(layerMetaData.name);
        }
        
        // Set in token
        uint256 borgId = _currentBorgId++;
        Borg storage borg = _borgs[borgId];
        borg.id = borgId;
        borg.exists = true;
        borg.borgPeicesSize = _layerMetaData.length;
        borg.borgPeiceNames = borgPeiceNames;
        borg.borgPeiceLayerPositions = layerItemPositions;
        
        // Set in all generated list
        _allGeneratedBorgIds.push(borgId);
    }
    
    function _getRandomLayerItemName(string memory layerItemName) internal returns(string memory, uint256 position){
        Layer storage layer = _layers[layerItemName];
        require(layer.exists, "No layer was found");
        require(layer.layerItemSize > 0, "No layer was found");
        
        uint256 randomChance = _getRandomNumber(layer.layerItemsCumulativeTotal);
        uint256 cumulativeChance = 0;
        
        for(uint256 i=0;i<layer.layerItemSize;i++){
            LayerItem memory item = layer.layerItems[i];
            cumulativeChance = (cumulativeChance + item.chance);
            if(cumulativeChance >= randomChance){
                return (item.borgPeiceName, i);
            }
        }
    }
    
    function addLayer(string memory layerName, uint256 position) external {
        Layer storage layer = _layers[layerName];
        layer.name = layerName;
        layer.exists = true;
       
        LayerMetaData memory metaData = LayerMetaData(layerName, position);
        _layerMetaData.push(metaData);
    }
    
    function addLayerItem(string memory layerName, uint256 chance, string memory borgPeiceName) external {
        Layer storage layer = _layers[layerName];
        require(layer.exists, 'Layer doesnt exist');
        
        LayerItem memory item = LayerItem(true, chance, borgPeiceName);
        
        uint256 position = layer.layerItemSize;
        layer.layerItems[position] = item;
        layer.layerItemSize = (position + 1);
        layer.layerItemsCumulativeTotal = (layer.layerItemsCumulativeTotal + chance);
    }
    
    function breedBorgs(uint256 borgId1, uint256 borgId2) external{
        // Get the first borg to breed
        Borg storage borg1 = _borgs[borgId1];
        require(borg1.exists, 'Borg 1 doesnt exist');
        require(borg1.descendants == 0, 'Borg already has descendants');
        
        // Get the second borg to breed
        Borg memory borg2 = _borgs[borgId2];
        require(borg2.exists, 'Borg 2 doesnt exist');
        require(borg2.descendants == 0, 'Borg already has descendants');
        
        // Check the peices size is the same
        require(borg1.borgPeiceNames.length == borg2.borgPeiceNames.length, 'Borg layer counts do not match');
        
        // Set thier new descendant count (as theyre now parents)
        borg1.descendants = 1;
        borg2.descendants = 1;
        
        // Select the borgs peices it is made up from (rareset from each)
        uint256[] memory layerItemPosition1 = borg1.borgPeiceLayerPositions;
        uint256[] memory layerItemPosition2 = borg2.borgPeiceLayerPositions;
        
        (uint256[] memory borgPeiceLayerPositions, string[] memory borgPeiceNames) = _filterRarestBorgPeices(layerItemPosition1, layerItemPosition2);
        
        // Build the borg
        uint256 borgId = _currentBorgId++;
        Borg storage borg = _borgs[borgId];
        borg.id = borgId;
        borg.exists = true;
        borg.borgPeicesSize = _layerMetaData.length;
        borg.borgPeiceNames = borgPeiceNames;
        borg.borgPeiceLayerPositions = borgPeiceLayerPositions;
    }
    
    function _filterRarestBorgPeices(uint256[] memory layerItemPosition1, uint256[] memory layerItemPosition2) internal view returns(uint256[] memory, string[] memory borgPeiceNames){
        // Check the peices size is the same
        require(layerItemPosition1.length == layerItemPosition1.length, 'Borg layer counts do not match');
        
        uint256[] memory rarestLayerPositions = new uint256[](layerItemPosition1.length);
        string[] memory rarestBorgPeiceNames = new string[](layerItemPosition1.length);
        
        for(uint256 i=0;i<_layerMetaData.length;i++){
            LayerMetaData storage layerMetaData = _layerMetaData[i];
            Layer storage layer = _layers[layerMetaData.name];
            LayerItem storage layerItem1 = layer.layerItems[layerItemPosition1[i]];
            LayerItem storage layerItem2 = layer.layerItems[layerItemPosition2[i]];
            
            if(layerItem1.chance < layerItem2.chance){
                rarestLayerPositions[i] = layerItemPosition1[i];
                rarestBorgPeiceNames[i] = layerItem1.borgPeiceName;
            }
        }
        
        return (rarestLayerPositions, rarestBorgPeiceNames);
    }
}