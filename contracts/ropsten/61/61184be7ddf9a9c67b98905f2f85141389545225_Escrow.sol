/* 
Lab 5: Escrow contract


The objective of this lab is to create a one-time use escrow contract.
This means the smart contract will facilitate the trade between 2 ethereum addresses of 2 on-chain assets.
The assets will be eth and an arbitrary token that must have a balanceOf field and a transfer function.

Yanesh
*/

pragma solidity ^0.4.25;

contract Token {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Escrow {
    
    address owner; // owner is whoever is initiating the escrow and deploying the contract
    address requestedAddress; // the address of whoever the owner wants to exchange with
    uint requestedTokenAmount; // The amount of the token the owner wants in exchange for eth
    Token token; // the initialized token
    
    constructor(address ERC20Address, uint _requestedTokenAmount, address _requestedAddress) public payable {
        owner = msg.sender;
        token = Token(ERC20Address);
        requestedTokenAmount = _requestedTokenAmount;
        requestedAddress = _requestedAddress;
    }
    
    function fulfillEscrow() public {
        require(token.balanceOf(requestedAddress) > requestedTokenAmount);
        require(address(this).balance > requestedTokenAmount);
        token.transfer(owner, requestedTokenAmount);
        requestedAddress.transfer(requestedTokenAmount);
    }
    
    function eliminateSmartContractByteCode() public {
        require(owner == msg.sender);
        selfdestruct(owner);
    }
}