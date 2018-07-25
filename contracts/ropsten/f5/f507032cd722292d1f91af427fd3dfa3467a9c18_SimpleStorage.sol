pragma solidity ^0.4.23;

contract SimpleStorage{
    string storedData;
    function set(string c) public{
        storedData = c;
    }
    function get() view internal returns (string x) {
    
        return storedData;
    }
}

// contract FindInternal is SimpleStorage{
//     function getten(string a)   {
//       SimpleStorage.set(a) ;
//     }
// }