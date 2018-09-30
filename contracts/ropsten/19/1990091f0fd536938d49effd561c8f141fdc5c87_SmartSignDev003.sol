pragma solidity ^0.4.24;

contract SmartSignDev003 {
    // region Configuration
    bool private deprecated;
    address private owner;
    struct signRegister{
        int256 hashData;
        uint256 index;
        string codedData;
        string csv;
        uint256 timestamp;
    }
    signRegister [] public tableRegisters;
    mapping(int256 => signRegister) public mappingSignRegister;
    int256 [] private hashIndex;
    constructor(){
        owner = msg.sender;
        deprecated = false;
    }
    // end region
    // region Modifiers
    modifier isOwner(address _sender){
        require(msg.sender == _sender,
        "sender not authorized"
            );
            _;
    }
    modifier isDeprecated(){
        require(deprecated == false,
        "contract deprecated");
        _;
    }
    // end region
    // region Internal
    function isRepeated(int256 hashData) public constant returns(bool){
        if(hashIndex.length == 0) return false;
        return(hashIndex[mappingSignRegister[hashData].index] == hashData);
    }
    // end region
    // region Create
    function setNewRegister(int256 _hashData,string _codedData, string _csv, uint256 _timestamp)  
        isOwner(msg.sender) 
        isDeprecated() 
        public returns(int256, string, string, uint256){
            
            if(isRepeated(_hashData)) return (_hashData,"Repeated", _csv, 0);

            mappingSignRegister[_hashData].hashData = _hashData;
            mappingSignRegister[_hashData].codedData =_codedData;
            mappingSignRegister[_hashData].csv = _csv;
            mappingSignRegister[_hashData].timestamp = _timestamp;
            mappingSignRegister[_hashData].index = hashIndex.push(_hashData) - 1;
            
            
            return(_hashData,_codedData, _csv, _timestamp);
    }
    // end region
    // region Retrieve
    function getRegister(int256 hashData, string csv) 
        isOwner(msg.sender)
        isDeprecated()
        public returns(int256, string ,string, uint256){
            if(!isRepeated(hashData)) return (hashData, "not found","0", 0);
            return (
                mappingSignRegister[hashData].hashData,
                mappingSignRegister[hashData].codedData,
                mappingSignRegister[hashData].csv,
                mappingSignRegister[hashData].timestamp);
    }
    // end region
    
    function deprecate() 
        isOwner(msg.sender)
        public 
        returns(string){
            deprecated == true;
            return "Contract deprecated";
    }
    
}