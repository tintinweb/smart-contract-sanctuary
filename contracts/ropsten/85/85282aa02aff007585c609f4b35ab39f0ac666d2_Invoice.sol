pragma solidity ^0.4.18;

contract Invoice{
    
    address admin;

    constructor() public{
	admin = msg.sender;
    }

    struct hashstruct{
	string hash;
	address adr;
    }
	
    mapping (address => hashstruct) hashmap;
    address[] public hashstore;
       
    mapping(string => hashstruct) adrmap;
    string[] public adrstore;
             
    modifier onlyOwner(){
        require(msg.sender == admin);
        _;
    }

    function saveHash(address _address, string _hash) public onlyOwner {
        
        var a = hashmap[_address];
        a.hash = _hash;  
     	hashstore.push(_address) -1;
         
    	var b = adrmap[_hash];
     	b.adr = (_address);
     	adrstore.push(_hash) -1;
    }
 
    function getHash(address adr) view public returns (string) {
 	    return (hashmap[adr].hash);
    }
    
    function getAddress(string hash) view public returns (address) {
        return (adrmap[hash].adr);
    }

    function count() view public returns (uint) {
   	    return hashstore.length;
    }
    
}