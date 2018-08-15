pragma solidity ^0.4.24;
contract SimpleContract {

    function calculateSha3(string a) public pure returns(bytes32){
        return keccak256(abi.encodePacked(a));
    }
    
}