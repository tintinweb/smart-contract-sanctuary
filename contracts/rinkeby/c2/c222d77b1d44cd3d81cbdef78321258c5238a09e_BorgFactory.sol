/**
 *Submitted for verification at Etherscan.io on 2021-06-26
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
    
    function toString(string[] memory pixals) public pure returns(string memory value){
        for(uint256 i=1;i<pixals.length;i++){
            value = _concat(value, pixals[i]);
        }
        return value;
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

contract BorgFactory is Ownable, IBorgFactory, StringUtils{
    
    mapping (string => string[]) _borgs;
    bool _isLocked;
    
    constructor(){
        _isLocked = false;
    }
    
    function addBorgPeice(string memory name, string memory fragment, string memory delimiter) public override onlyOwner{
        string[] storage image = _borgs[name];
        string[] memory formattedFragment = _splitStr(fragment, delimiter);
        for(uint256 i =0;i<formattedFragment.length;i++){
            image.push(formattedFragment[i]);
        }
    }
    
    function resetBorgPeice(string memory borgPeice) public override onlyOwner{
        delete _borgs[borgPeice];
    }
    
    function lockContractForEdit() onlyOwner override external {
        _isLocked = true;
    }
    
    function getBorgPeiceForDisplay(string memory name) public view override returns(string memory borgPeice){
        string[] memory image = _borgs[name];
        for(uint256 i =0;i<image.length;i++){
            borgPeice = _concat(borgPeice, image[i]);
        }
        
        return borgPeice;
    }
    
    function getBorgPeice(string memory name) public view override returns(string[] memory borgPeice){
        borgPeice = _borgs[name];
    }
    
    function isLocked() public override view returns(bool locked){
        return _isLocked;
    }
}