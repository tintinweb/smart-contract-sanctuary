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
   
contract PolyRegistry is Ownable{
    
    //Importing a library for String concatination
    
     using Strings for string;
      
    // Defining structure
    struct  Registry {
        address owner;
        address resolverContract;
        uint256 genesis;
    }
      
    // Creating mapping for shortCode => Registry
    
    mapping (string => Registry)  _registry;
    string[]  public  ShortCodes;
    address public resolver = 0x0000000000000000000000000000000000000000;
    
    //decade epochtime
    /**
     * Modifer to check if He wons the shortcode before changing it
     */
     modifier OnlyShortCodeOwner(string index) {
      require(msg.sender ==  _registry[index].owner, "You don't own this short code");
      _;
   }
   
   modifier ShortCodeExistence(string shortcode)
   {
       require(_registry[shortcode].owner== 0x0000000000000000000000000000000000000000,"Already Exists");
       _;
   }
   
 
     function CreateShortCode(string shortcode) public ShortCodeExistence(shortcode.concat(".poly")){
         
        shortcode =shortcode.concat(".poly");
        _registry[shortcode] =Registry(msg.sender,resolver,now);
        ShortCodes.push(shortcode) -1;
    }
    
    function getShortCodeOwner(string index) view public returns (address) {
        
        return _registry[index].owner;
    }
    

     
     function setShortCodeOwner(string index,address addr)  public OnlyShortCodeOwner(index)  {
       
       _registry[index].owner =addr;
    }
    
     function getShortCodeGenesis(string index) view public returns (uint256)   {
       return _registry[index].genesis ;
    }
    
    function CreateSubShortCode(string index,string sub) public OnlyShortCodeOwner(index)  {
        sub = sub.concat(".").concat(index);
       _registry[sub] =Registry(msg.sender,resolver,now);
        ShortCodes.push(sub) -1;
    }
    
     function getLengthOfRegistry() view public returns (uint) {
        return ShortCodes.length;
    }
    
    function setGlobalResolver(address addr) public onlyOwner {
        resolver = addr;
    }
    
    function setResolverForSpecific(string index, address addr ) public OnlyShortCodeOwner(index) {
       _registry[index].resolverContract = addr;
    }
    
    function getResolverForSpecific(string index ) view public OnlyShortCodeOwner(index) returns (address){
      return  _registry[index].resolverContract;
    }
    
    //  function getGlobalResolver( ) view public returns (address){
    //   return  resolver;
    // }
    
    
    
    
}