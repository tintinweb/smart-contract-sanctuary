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
    string[] Domains;
    address public resolver = 0x0000000000000000000000000000000000000000;
    uint256  expireAfter = 157784630;
    
    /**
     * Modifer to check if He wons the shortcode before changing it
     */
   modifier OnlyDomainOwner(string memory index) 
   {
      require(msg.sender ==  _registry[_toLower(index)].owner, "You don't own this short code");
      _;
   }
   
   modifier DomainExistence(string memory domain)
   {
       require(!isExist(_toLower(domain)),"Already Exists");
       _;
   }
   
   modifier notDomainExistence(string memory domain)
   {
       require(isExist(_toLower(domain)),"Doesn't Exists");
       _;
   }
   
    modifier isStringSanitised(string memory str)
   {
       require(StrSanitised(str),"Domain not allowed, Use only 0-9,a-z and . ");
       _;
   }
    //Thanks to https://gist.github.com/ottodevs/c43d0a8b4b891ac2da675f825b1d1dbf
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    // Thanks to https://ethereum.stackexchange.com/questions/50369/string-validation-solidity-alpha-numeric-and-length
    function StrSanitised(string memory str) internal pure returns (bool){
    bytes memory b = bytes(str);
    if(b.length > 13) return false;

    for(uint i; i<b.length; i++){
        bytes1 char = b[i];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }

    return true;
}
   
    function CreatePolyDomain(string memory domain)  public isStringSanitised(domain) DomainExistence(domain.concat(".poly")){
         
        domain =_toLower(domain).concat(".poly");
        _registry[domain] =Registry(msg.sender,resolver,block.timestamp,block.timestamp+expireAfter);
        Domains.push(domain) ;
    }
    
    function getDomainOwner(string memory index) view public returns (address owner) {
        
        return _registry[_toLower(index)].owner;
    }
    
    function isExist(string memory index) view public returns(bool created)
    {
        return _registry[_toLower(index)].genesis!=0;
    }
    
     function getRecord(string memory index) view public returns(address owner,address resolverContract,uint256 createdAt,uint256 ttl)
     {
         return ( _registry[_toLower(index)].owner, _registry[_toLower(index)].resolverContract, _registry[_toLower(index)].genesis,_registry[_toLower(index)].ttl);
     }
    
     function setPolyDomainOwner(string memory index,address addr) isStringSanitised(index) public OnlyDomainOwner(index)  {
       
       _registry[_toLower(index)].owner =addr;
    }
    
    function CreateSubPolyDomain(string memory index,string memory sub) public isStringSanitised(sub) notDomainExistence(index) OnlyDomainOwner(index) DomainExistence(sub.concat(".").concat(index)) {
       sub = _toLower(sub.concat(".").concat(index));
       _registry[sub] =Registry(msg.sender,resolver,block.timestamp,block.timestamp+expireAfter);
        Domains.push(sub);
    }
    
    function getLengthOfRegistry() view public returns (uint count) {
        return Domains.length;
    }
    
    function setGlobalResolver(address addr) public onlyOwner {
        resolver = addr;
    }
    
     function setExpireAfter(uint256 epoch) public onlyOwner {
        expireAfter =epoch ;
    }
    
    function setResolverForPolyDomain(string memory index, address  addr ) public OnlyDomainOwner(index) {
       _registry[_toLower(index)].resolverContract = addr;
    }
    
}