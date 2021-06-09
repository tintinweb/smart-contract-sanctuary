pragma solidity ^0.8.0;

import "./wsat.sol";

contract Deployer {
    address public token;
    address public owner;
    uint256 public claimAmmount = 10000000000000000000000; //10,000 Airdrop
    
    mapping(address => bool)public claimed;
    
    constructor() {
        owner = msg.sender;
        token = 0x318b7F26Ae48e41f3941bA4eC95d93CaABb2Fc80;
    }
    
    function claim() public {
    require(claimed[msg.sender] == false);
    ERC20(token).transfer(msg.sender,claimAmmount);
    claimed[msg.sender] = true;
    }
    
    function setTokenAddress(address _tokenAddress)public {
    require(msg.sender == owner);
    token = _tokenAddress;
    }
    
}