pragma solidity ^0.4.24;

contract EventEmit {

    uint256 contractInt;
    string contractString;
    bool contractBool;
    address contractAddress;
    
    event Event1(string message, uint256 value);
    event Event2(string message, string value);
    event Event3(string message, bool value);
    event Event4(string message, address value);

    constructor(uint256 _int, string _string, address _address) public{
        contractInt =  _int;
        contractString = _string;
        contractAddress = _address;
    }
    
    function setInt(uint256 _set) public {
        contractInt = _set;
    }
    
    function setString(string _set) public {
        contractString = _set;
    }
    
    function setBool(bool _set) public {
        contractBool = _set;
    }
    
    function setAddress(address _set) public {
        contractAddress = _set;
    }

    function emitEvent(uint256 eventNumber) public{
        
        uint256 myInt = contractInt;
        string memory myString = contractString;
        bool myBool = contractBool;
        address myAddress = contractAddress;
        
        if(eventNumber ==  1){
            emit Event1("This event returns a uint256", myInt);
        }
        if(eventNumber ==  2){
            emit Event2("This event returns a string", myString);
        }
        if(eventNumber ==  3){
            emit Event3("This event returns an  boolean", myBool);
        }
        if(eventNumber ==  4){
            emit Event4("This event returns YOUR eth address", myAddress);   
        }
    }
}