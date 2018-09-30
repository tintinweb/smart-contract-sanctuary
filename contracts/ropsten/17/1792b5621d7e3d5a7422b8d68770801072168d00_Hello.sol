pragma solidity 0.4.25;

contract Hello {
    string _text;
    
    constructor (string text) public {
        _text = text;
    }
    
    function showText() public view returns(string) {
        return _text;
    }
}