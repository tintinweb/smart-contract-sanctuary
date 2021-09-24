/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity 0.8.7;

contract VendingMachine {

    // Declare state variables of the contract
    address public owner;
    
    mapping (address => uint) public cupcakeBalances;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = 0x6d74e0fd773F321772B09Edc95cD2c30d7fAd0ff;
        cupcakeBalances[address(this)] = 100;
    }


    // Allow anyone to purchase cupcakes
    function purchase() public payable {
        require(msg.value >= 1000 wei, "You must pay at least 1000 wei per cupcake");
        require(cupcakeBalances[address(this)] >= 1, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= 1;
        cupcakeBalances[msg.sender] += 1;
    }
    
    //withdraw to anyone
    function withdrawETH(address payable recipient, uint256 amount) public {
    (bool succeed, bytes memory data) = recipient.call{value: amount}("");
    require(succeed, "Failed to withdraw Ether");
    }
}