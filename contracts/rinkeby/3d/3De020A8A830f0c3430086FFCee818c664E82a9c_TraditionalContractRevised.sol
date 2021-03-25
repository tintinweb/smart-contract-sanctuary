/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

contract TraditionalContractRevised{
    
    address payable public arup; // This is arup
    address payable public client; // This is the client
    uint public fee; // in ether
    bool public didWithdraw = false;
    // uint public expenses; // The fee in eth to be stored in the smart contract (for example)


    
    // Arup deploys the smart contract as owner: specify the ammount of the fee
    
    constructor (address payable _client, uint _fee){
        arup = payable(msg.sender); // Arup deploys the contract and becomes the owner
        client = _client; // Specify the client who is going to pay? Could take multiple clients also with different properties
        fee = _fee * (1 ether);
    }


    // The client to make the payment that will be transfered to Arup. Only the client can
    function clientDeposit () public payable {
        require(msg.sender == client);
        require(msg.value >= fee);
    }

    // The balance of the smart contract in ether
    function balance() public view returns (uint) {
        return (address(this).balance) / 1 ether;
    }

    // The client can reset the withdraw from Arup
    function resetWithdraw () public {
        require(msg.sender == client);
        didWithdraw = false;
    }


    // Arup to take the ether from the contract or the client to withdraw if the deposit is higher than the fee
    function withdraw () public payable {
        require(msg.sender == arup || msg.sender == client);
        if(msg.sender == arup) {
            require(didWithdraw == false);
            didWithdraw = true;
            arup.transfer(fee);
        }
        // If Arup already withdraw or if the deposit is higer than the fee
        else {
            if (address(this).balance > fee) {
                client.transfer(address(this).balance - fee);
            }
            else if (didWithdraw) {
                client.transfer(address(this).balance);
            }
        }
        
    }
    
 
}