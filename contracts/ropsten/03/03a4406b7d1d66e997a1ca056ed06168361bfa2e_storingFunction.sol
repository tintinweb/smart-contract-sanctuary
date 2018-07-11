contract storingFunction {
    string public stateStorage;
    
    function storeIt(string _value) {
        stateStorage = _value;
    }
}