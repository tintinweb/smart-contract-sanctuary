/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity >=0.4.22 <0.9.0;


contract Storehash {

    bytes wasteHash;
    

    //address payable wasteHash;
    
    function store(bytes memory hash) public {
        wasteHash = hash;
    }
    

    
    function retrieve() public view returns (bytes memory){
        return wasteHash;
    }
}