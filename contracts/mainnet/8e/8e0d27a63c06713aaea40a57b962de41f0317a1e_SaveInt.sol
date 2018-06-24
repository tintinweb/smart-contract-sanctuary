contract SaveInt{
    constructor() public {
    }
    mapping (string=>uint) data;
    function setStr(string key, uint value) public {
        data[key] = value;
    }
    function getStr(string key) public constant returns(uint){
        return data[key];
    }
}