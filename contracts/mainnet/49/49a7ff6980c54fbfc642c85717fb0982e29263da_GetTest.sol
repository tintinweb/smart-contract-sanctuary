contract GetTest{
    uint a = 1;
    string b = "b";
    address c;
    constructor() public {
        c = msg.sender;
    }
    function getOne() public constant returns(uint) {
        return a;
    }
    function getTwo() public constant returns(uint, string){
        return (a, b);
    }
    function getThree() public constant returns (uint, string, address){
        return (a, b, c);
    }
}