/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5; 

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
     constructor () {
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

}
   
contract PolyRegistry is Ownable{
    
    //Importing a library for String concatination
    
     using Strings for string;
      
    // Defining structure
    struct  Registry {
        address owner;
        address resolverContract;
        uint256 genesis;
        uint256 ttl;
    }
    
    // Creating mapping for shortCode => Registry
    
    mapping (string => Registry)  _registry;
    string[]  public  ShortCodes;
    address public resolver = 0x0000000000000000000000000000000000000000;
    uint256 public expireAfter = 157784630;
    
    //decade epochtime
    /**
     * Modifer to check if He wons the shortcode before changing it
     */
     modifier OnlyDomainOwner(string memory index) {
      require(msg.sender ==  _registry[index].owner, "You don't own this short code");
      _;
   }
   
   modifier DomainExistence(string memory domain)
   {
       require(!isExist(domain),"Already Exists");
       _;
   }
   
    function CreatePolyDomain(string memory domain)  public DomainExistence(domain.concat(".poly")){
         
        domain =domain.concat(".poly");
        _registry[domain] =Registry(msg.sender,resolver,block.timestamp,block.timestamp+expireAfter);
        ShortCodes.push(domain) ;
    }
    
 
    function getDomainOwner(string memory index) view public returns (address owner) {
        
        return _registry[index].owner;
    }
    
    function isExist(string memory index) view public returns(bool created)
    {
        return _registry[index].genesis!=0;
    }
    
     function getRecord(string memory index) view public returns(address owner,address resolverContract,uint256 createdAt,uint256 amount)
     {
         return ( _registry[index].owner, _registry[index].resolverContract, _registry[index].genesis,_registry[index].genesis);
     }
    
     function setPolyDomainOwner(string memory index,address addr)  public OnlyDomainOwner(index)  {
       
       _registry[index].owner =addr;
    }
    
    function CreateSubPolyDomain(string memory index,string memory sub) public  DomainExistence(index) OnlyDomainOwner(index) DomainExistence(sub.concat(".").concat(index)) {
        sub = sub.concat(".").concat(index);
       _registry[sub] =Registry(msg.sender,resolver,block.timestamp,block.timestamp+expireAfter);
        ShortCodes.push(sub);
    }
    
    function getLengthOfRegistry() view public returns (uint count) {
        return ShortCodes.length;
    }
    
    function setGlobalResolver(address addr) public onlyOwner {
        resolver = addr;
    }
    
     function setExpireAfter(uint256 epoch) public onlyOwner {
        expireAfter =epoch ;
    }
    
    function setResolverForPolyDomain(string memory  index, address  addr ) public OnlyDomainOwner(index) {
       _registry[index].resolverContract = addr;
    }
    
  
    
    
    
}