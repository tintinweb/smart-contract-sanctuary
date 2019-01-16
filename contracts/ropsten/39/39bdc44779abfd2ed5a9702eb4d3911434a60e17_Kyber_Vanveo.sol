pragma solidity 0.4.24;

contract Kyber_Vanveo {
    string welcome ;
   
    // recommand from dev use _ is better, no confuse//
    
    function setwelcome (string _welcome) public{
        welcome = _welcome;
    }
    function getwelcome () constant public returns (string) {
        return welcome;
    }
}