pragma solidity ^0.4.13;
pragma experimental ABIEncoderV2;
contract A {
    string public constant name = "Bincentive Token";
    
    constructor() {
        B b = new B();    
    }
}
contract B{
    string public constant name = "B";
    constructor() {
        
    }
}