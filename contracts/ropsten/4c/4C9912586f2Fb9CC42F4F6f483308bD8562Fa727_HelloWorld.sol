pragma solidity ^0.4.24;

contract HelloWorld{
    //Declaring Variables
    string word = "hello world";
    address public myAddress;
    
    //constructor immediately initialized
    constructor() public {
        myAddress = msg.sender;    
    }
    
    //Modifiers limiting access
    modifier onlyOwner(){ 
        require(myAddress==msg.sender);
        _;
    }
    
    //Function of getter
    function getWord() public view returns(string) {
        return word;
    }
    
    //Function of setter only owner is authorized 
    function setWord(string newWord) public onlyOwner returns(string) {
        word = newWord;
        return word;
    }
}