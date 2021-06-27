/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity 0.8.1;

contract StringUtils{
    
    function _concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
    
    bytes hexValue ; //temporarily hold the string part until a space is recieved
    string[] hexValues;

    function _splitStr(string memory str, string memory delimiter) internal returns (string[] memory)
    {
        // Clear from previous
        delete hexValues;
        delete hexValue;
        
        bytes memory b = bytes(str); //cast the string to bytes to iterate
        bytes memory delm = bytes(delimiter); 

        for(uint i; i<b.length ; i++)
        {          
            if(b[i] != delm[0]) { //check if a not space
                hexValue.push(b[i]);             
            }
            else { 
                hexValues.push(string(hexValue)); //push the int value converted from string to numbers array      
                delete hexValue;
            }                
        }

        if(b[b.length-1] != delm[0]) { 
           hexValues.push(string(hexValue));
        }
        
        return hexValues;
    }
    
    function _toString(string[] memory pixals) internal pure returns(string memory value){
        for(uint256 i=1;i<pixals.length;i++){
            value = _concat(value, pixals[i]);
        }
        return value;
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

interface IBorgFactory{
    function addBorgPeice(string memory name, string memory fragment, string memory delimiter) external;
    function resetBorgPeice(string memory borgPeice) external;
    function lockContractForEdit() external;
    function getBorgPeiceForDisplay(string memory name) external view returns(string memory borgPeice);
    function getBorgPeice(string memory name) external view returns(string[] memory borgPeice);
    function isLocked() external view returns(bool);
}

contract CommonObjects{
    
    struct LayerMetaData{
        string name;
        uint256 position;
    }
    
    struct Layer{
        bool exists;
        string name;
        mapping(uint => LayerItem) layerItems;
        uint layerItemSize;
    }
    
    struct LayerItem{
        bool exists;
        uint256 chance;
        string[] hexPixals;
    }
    
    struct Borg{
        uint256 id;
        bool exists;
        bool descendant;
        mapping(uint => GeneratedLayer) generatedLayers;
        uint generatedLayersSize;
        mapping(uint => string[]) image;
    }
    
    struct GeneratedLayer{
        string layerName;
        uint256 layerItemPosition;
    }
}

contract Borgs is CommonObjects, StringUtils, NumberUtils{
    
    // TODO: not public
    mapping (string => Layer) public _layers;
    mapping (uint256 => Borg) public _borgs;
    mapping (uint256 => string[]) private _allGeneratedBorgImages;
    LayerMetaData[] public _layerMetaData;
    
    IBorgFactory _borgFactory;
    
    uint256 _currentBorgId = 0;
    uint256 _maxLayerItemCount = 20;
    uint256 _imageSize = 9; // 3x3 for now but should be 576
    string _whitePixal = '000000';
    
    event Pixals(string strPixals);
    
    constructor(address borgFactory){
        _borgFactory = IBorgFactory(borgFactory);
    }
    
    function getBorgImage(uint256 borgId) public view returns(string[] memory){
        return _allGeneratedBorgImages[borgId];
    }
    
    function getMaxLayerCount() external view returns(uint256){
        return _maxLayerItemCount;
    }
    
    function getPixals(string memory layerName, uint256 position) public view returns (string[] memory){
        Layer storage layer = _layers[layerName];
        LayerItem storage layerItem = layer.layerItems[position];
        return layerItem.hexPixals;
    }
    
    function generateToken() external returns(string[] memory generatedPixals)
    {
        require(_layerMetaData.length > 0, "No layers present");
        
        // Init base
        generatedPixals = new string[](_imageSize);
        for(uint256 i=0;i<generatedPixals.length;i++){
            generatedPixals[i] = _whitePixal;
        }
        
        // Use layers to build image
        GeneratedLayer[] memory generatedLayers = new GeneratedLayer[](_layerMetaData.length);
    
        for(uint256 i=0;i<_layerMetaData.length;i++){
            LayerMetaData storage layerMetaData = _layerMetaData[i];
            Layer storage layer = _layers[layerMetaData.name];
            require(layer.exists, "No layer was found");
                      
            LayerItem[] memory items = new LayerItem[](_maxLayerItemCount);
            
            for(uint256 j=0;j<layer.layerItemSize;j++){
                LayerItem memory layerItemToAdd = layer.layerItems[j];
                items[j] = layerItemToAdd;
            }
            
            // TODO: Randomly select - items[0]/0
            // uint randomItemPosition = _getRandomItem(items);
            generatedLayers[i] = GeneratedLayer(layer.name, 0);
            generatedPixals = _addLayerToImage(items[0].hexPixals, generatedPixals);
        }
        
        // Set in token
        uint256 borgId = _currentBorgId++;
        Borg storage borg = _borgs[borgId];
        borg.id = borgId;
        borg.exists = true;
        borg.image[0] = generatedPixals;
        borg.generatedLayersSize = generatedLayers.length;
        for(uint256 i=0;i<generatedLayers.length;i++){
            borg.generatedLayers[i] = generatedLayers[i];
        }
        
        // Set in all generated list
        _allGeneratedBorgImages[borgId] = generatedPixals;
               
        // Event 
        // emit Pixals(strPixals);
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
        
        string[] memory borgPeice = _borgFactory.getBorgPeice(borgPeiceName);
        LayerItem memory item = LayerItem(true, chance, borgPeice);
        
        uint256 position = layer.layerItemSize;
        layer.layerItems[position] = item;
        layer.layerItemSize = position + 1;
    }
    
    function _addLayerToImage(string[] memory layerPixals, string[] memory basePixals) internal returns(string[] memory newHexPixals)
    {
        for(uint256 i=0;i<basePixals.length;i++){
            string memory originalPixal = basePixals[i];
            string memory newPixal = layerPixals[i];
            if(keccak256(bytes(newPixal)) != keccak256(bytes('000000'))){
                newHexPixals[i] = newPixal;
            }
            else {
                newHexPixals[i] = originalPixal;
            }
        }
        
        return newHexPixals;
    }
}