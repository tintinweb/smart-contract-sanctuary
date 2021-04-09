/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity ^0.4.24;

contract BasicToken {
    //store all the balances of wallets which have the token
    mapping(address => uint256) public balanceOf;
    // when the smart contract is deployed
    // this constructor will provide the creator of the contract 
    // all initial tokens when smart contract is deployed. 
    
    
    constructor (uint initialSupply) public {
        balanceOf[msg.sender] = initialSupply;
    }
    
    // we need a function that can transfer ownership of the token 
    // from one wallet to the other. 
    function transfer (address _to, uint256 _value) public returns (bool success) {
        // check if the sender has enough token to send
        // the balance of tokens the sender has must be more the amount to be transferd
        require(balanceOf[msg.sender] >= _value);
        // require(balanceOf[_to] + _value >= balanceOf[_to] ); // overflow check 
        balanceOf[msg.sender] -= _value;
        // deduct from senders account 
        balanceOf[_to] += _value;
        // add to destination account 
        return true;
        
   
        
    }
    
     function getBalance() returns (uint256) {
        return balanceOf[msg.sender];
    }
        
}



// //https://ethereum.stackexchange.com/questions/54874/remix-ide-error-send-transaction-failed-invalid-address-if-you-use-injected/70510
// // Metamask no longer exposes accounts by default. 
// // if u on't see the account listed in remix and you are sure you logged in to metamask but it still doesn't work, open the console on remix website and type:
// // window.ethereum.enable()
// The above line of code should open a metamask prompt asking to allow connecting to the site. Click connect and you should see the account listed in the accounts dropdown in remix.