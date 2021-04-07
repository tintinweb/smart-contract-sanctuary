/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

contract HashHelloWorld {
    
    string public Hash;
    
    function HashHelloWorld() public {
        Hash = "a3614fe562b348399b7e0a97c5720f71857caa90906434b2a7ad4d2e4ea5c27d";
        
        
    }
    
    function printHash() constant public returns(string){
        return Hash;
    }
}