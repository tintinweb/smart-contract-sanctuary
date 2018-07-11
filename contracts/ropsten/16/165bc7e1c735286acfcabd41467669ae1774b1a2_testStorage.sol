pragma solidity ^0.4.24;

contract storingFunction {
    string public stateStorage;
    
    function storeIt(string _value) {
        stateStorage = _value;
    }
}

contract testStorage {
    storingFunction x = new storingFunction();
    
    function storeSomething() public {
        string memory stringToStore = &quot;0x12345678901234678 and stuff&quot;;
        x.storeIt(stringToStore);
    }
    
    function show() public view returns (string) {
        string memory tmp = x.stateStorage();
        return tmp;
    }
}