/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.3;

// import "hardhat/console.sol";


// This is the main building block for smart contracts.
contract ChargerList {

    // An address type variable is used to store ethereum accounts.
    address public owner;
    address[] public list;

    constructor() {
        owner = msg.sender;
    }

    function put(address charger) external {
        require(msg.sender == owner, "You are not an owner");
        list.push(charger);
    }

    function del(address charger) external {
        require(msg.sender == owner, "You are not an owner");
        for (uint i=0; i<list.length; i++) {
            if(list[i]==charger) {
                list[i] = list[list.length - 1];
                list.pop();
            }
        }
    }    

    function get() view public returns (address[] memory) {
        address[] memory b = new address[](list.length);
        for (uint i=0; i < b.length; i++) {
            b[i] = list[i];
        }
        return b;
    }    
}