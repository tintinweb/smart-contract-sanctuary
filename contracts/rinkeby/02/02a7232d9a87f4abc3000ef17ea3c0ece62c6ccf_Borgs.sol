/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

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
    
    struct Token{
        bool exists;
        string[] hexPixals;
    }
}

contract QuickSort is CommonObjects {
    
    function sort(LayerMetaData[] memory data) public returns(LayerMetaData[] memory) {
       quickSort(data, data[0], data[1]);
       return data;
    }
    
    function quickSort(LayerMetaData[] memory arr, LayerMetaData memory left, LayerMetaData memory right) internal{
        LayerMetaData memory  i = left;
        LayerMetaData memory  j = right;
        if(i.position==j.position) return;
        
        uint256 pivot = arr[uint256(left.position + (right.position - left.position) / 2)].position;
        while (i.position <= j.position) {
            while (arr[uint256(i.position)].position < pivot) i.position++;
            while (pivot < arr[uint256(j.position)].position) j.position--;
            if (i.position <= j.position) {
                (arr[uint(i.position)], arr[uint256(j.position)]) = (arr[uint(j.position)], arr[uint(i.position)]);
                i.position++;
                j.position--;
            }
        }
        if (left.position < j.position)
            quickSort(arr, left, j);
        if (i.position < right.position)
            quickSort(arr, i, right);
    }
}

contract Borgs is CommonObjects, QuickSort{
    
    // TODO: not public
    LayerMetaData[] public _layerMetaData;
    mapping (string => Layer) public _layers;
    Token[] public _tokens;
    
    constructor(){
    }
    
    function generateToken() external returns(string[] memory hexPixals){
        //if(_layerMetaData.length > 1)
        //    _layerMetaData = sort(_layerMetaData);

        for(uint256 i=0;i<_layerMetaData.length;i++){
            Layer storage layer = _layers[_layerMetaData[i].name];
            LayerItem[] memory items = new LayerItem[](20);
            
            for(uint256 i=0;i<layer.layerItemSize;i++){
                items[i] = layer.layerItems[i];
            }
            
            // TODO: Randomly select
            hexPixals = addLayerToImage(items[0].hexPixals, hexPixals);
        }
        
        _tokens.push(Token(true, hexPixals));
        
        return hexPixals;
    }
    
    function addLayerToImage(string[] memory layerPixals, string[] memory hexPixals) public returns(string[] memory newHexPixals)
    {
        for(uint256 i=0;i<hexPixals.length;i++){
            string memory originalPixal = hexPixals[i];
            string memory potentialNewPixal = layerPixals[i];
            string memory newPixal = originalPixal;
            if(keccak256(bytes(newPixal)) != keccak256(bytes('000000')))
                newHexPixals[i] = newPixal;
        }
        
        return newHexPixals;
    }
    
    function addLayer(string memory layerName, uint256 position) external {
        Layer storage layer = _layers[layerName];
        layer.name = layerName;
        layer.exists = true;
       
        LayerMetaData memory metaData = LayerMetaData(layerName, position);
        _layerMetaData.push(metaData);
    }
    
    function addLayerItem(string memory layerName, uint256 chance, string memory hexImage) external{
        Layer storage layer = _layers[layerName];
        require(layer.exists, 'Layer doesnt exist');
        
        string[] memory parsedImage = splitStr(hexImage,',');
        
        LayerItem memory item = LayerItem(true, chance, parsedImage);
        
        uint256 position = layer.layerItemSize++;
        layer.layerItems[position] = item;
        layer.layerItemSize = position;
    }

    bytes hexValue ; //temporarily hold the string part until a space is recieved
    string[] hexValues;

    function splitStr(string memory str, string memory delimiter) internal returns (string[] memory){ //delimiter can be any character that separates the integers 
        
        // Clear from previous
        delete hexValues;
        
        bytes memory b = bytes(str); //cast the string to bytes to iterate
        bytes memory delm = bytes(delimiter); 

        for(uint i; i<b.length ; i++){          

            if(b[i] != delm[0]) { //check if a not space
                hexValue.push(b[i]);             
            }
            else { 
                hexValues.push(string(hexValue)); //push the int value converted from string to numbers array             
            }                
        }

        if(b[b.length-1] != delm[0]) { 
           hexValues.push(string(hexValue));
        }
        
        return hexValues;
    }
}