pragma solidity ^0.4.8;
contract SmartSignFactum {

    address owner;
    bool deprecated;

    mapping(string => bool) map;
    string [] mapped;

    struct entry{
        string hash;
        string csv;
        uint dateOfProcess;
    }
    
    entry [] table;

    constructor() {
        owner = msg.sender;
        deprecated = false;
    }

    function isOwner(address _owner) internal returns (bool){
        return owner == _owner;
    }
    

    function isMapped(string _map) internal returns (bool){
        return map[_map];
    }

    function setMap(string _hash, string _csv) returns(string, string, string){
        if(deprecated){
            return ("Error : This version is deprecated", "0", "0");
        } else {
            if( isOwner(msg.sender) ){
                if( false ){
    
                    return ("Error : Repeated value", "0", "0");
    
                } else {
    
                    entry memory newEntry ;
                    newEntry.hash = _hash;
                    newEntry.csv = _csv;
                    newEntry.dateOfProcess = now;
    
                    table.push(newEntry);
                    
                    map[_hash] = true;
                    mapped.push(_hash);
                    
    
                    return ("Success : Correct push", _hash, _csv);
                }
            } else {
                return ("Error : Not the owner", "0", "0");
            }
        }
    }
    
    function changeStatus() returns(string){
        if( isOwner(msg.sender) ){
            if(deprecated){
                deprecated = false;
                return "Success : Not deprecated";
            } else {
               deprecated = true; 
               return "Success : Deprecated";
            }
        } else {
           return "Error : Not the owner"; 
        }
    }

}