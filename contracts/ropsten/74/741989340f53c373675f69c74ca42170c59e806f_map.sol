/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.4.21; 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor () public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

library Strings {

    function concat(string _base, string _value) internal pure returns (string) {
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

}
   
contract map is Ownable{
    
    //Importing a library for String concatination
    
     using Strings for string;
      
    // Defining structure
    struct  Registry {
        address owner;
        address resolver;
    }
      
    // Creating mapping for shortCode => Registry
    
    mapping (string => Registry)  _registry;
    string[] public ShortCodes;
      
    /**
     * Modifer to check if He wons the shortcode before changing it
     */
     modifier OnlyShortCodeOwner(string index) {
      require(msg.sender ==  _registry[index].owner);
      _;
   }
    
     function CreateShortCode(string shortcode) public {
         
        shortcode =shortcode.concat(".matic");
        Registry storage registry
          = _registry[shortcode.concat(".matic")];
        registry.owner = msg.sender;
        registry.resolver = 0xD22B77AD97E75F4c98c3510a6669Fe1A581e907d;
        ShortCodes.push(shortcode) -1;
    }
    
    function getShortCodeOwner(string index) view public returns (address) {
        return _registry[index].owner;
    }
    
     function setShortCodeOwner(string index,address addr)  public OnlyShortCodeOwner(index) {
       _registry[index].owner =addr;
    }
    
    function CreateSubShortCode(string original,string sub) public OnlyShortCodeOwner(original) {
        string memory subShortCode = sub.concat(".").concat(original);
        Registry storage registry
          = _registry[subShortCode];
        registry.owner = msg.sender;
        registry.resolver = 0xD22B77AD97E75F4c98c3510a6669Fe1A581e907d;
        ShortCodes.push(subShortCode) -1;
    }
    
    
}