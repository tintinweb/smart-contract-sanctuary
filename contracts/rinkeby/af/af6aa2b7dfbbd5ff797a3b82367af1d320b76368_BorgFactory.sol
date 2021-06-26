/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

contract BorgFactory{
    
    mapping (string => string[]) public _borgs;
    
    function addBorgPeice(string memory name, string memory fragment, string memory delimiter) public{
        string[] storage image = _borgs[name];
        string[] memory formattedFragment = splitStr(fragment, delimiter);
        for(uint256 i =0;i<formattedFragment.length;i++){
            image.push(formattedFragment[i]);
        }
    }
    
    function resetBorgPeice(string memory borgPeice) public{
        delete _borgs[borgPeice];
    }
    
    function getBorgPeice(string memory name) public view returns(string memory borgPeice){
        string[] memory image = _borgs[name];
        for(uint256 i =0;i<image.length;i++){
            borgPeice = concat(borgPeice, image[i]);
        }
        
        return borgPeice;
    }
    
    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
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