/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.8.0;

contract Utils {
    address owner;
    
    
    constructor () {
        owner = msg.sender;
    }
    
    address[] private Contracts;
   
    modifier restricted {
        for (uint i = 0; i < Contracts.length; i++) {
            if (msg.sender == Contracts[i]) {
                _;
                return;
            }
        }
        revert();
    }
   
    function getContractsLength() external view restricted returns (uint256) {
        return Contracts.length;
    }
    
    function getContracts() external view restricted returns (address[] memory)  {
        return Contracts;
    }
    
    function addContract (address _contract) public {
        require(msg.sender == owner);
        Contracts.push(_contract);
    }
    
    function removeContract (address _contract) public {
        require(msg.sender == owner);
        uint index;
        for (uint i = 0; i < Contracts.length; i++) {
            if (Contracts[i] == _contract) {
                index = i;
            }
        }

        for (uint i = index; i < Contracts.length-1; i++){
            Contracts[i] = Contracts[i+1];
        }
        Contracts.pop();

    }
    
       
    function isContract(address addr) public view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

}