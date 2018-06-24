contract SaveString{
    constructor() public {
    }
    mapping (uint=>string) data;
    function setStr(uint key, string value) public {
        data[key] = value;
    }
    function getStr(uint key) public constant returns(string){
        return data[key];
    }
}