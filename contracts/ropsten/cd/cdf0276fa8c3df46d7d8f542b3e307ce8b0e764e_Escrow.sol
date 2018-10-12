//Lab 5 Escrow Contract
//The objective of this lab is to create a one-time use escrow contract. This means the smart contract will facilitate the trade between 2 ethereum addresses of 2 on-chain assets. The assets will be eth and an arbitrary token that must have a balanceOf field and a transfer function.
//The function allows the creator to destroy the sender&#39;s ERC20 contributions - extra code commented in to fix the problem&#39;

pragma solidity ^0.4.25;
//First include this contract declaration at the top of the .sol file:
contract Token {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success);
}

//The contract will include the following fields at the top of the contract:
contract Escrow{
    address public owner; // owner is whoever is initiating the escrow and deploying the contract
    address public requestedAddress; // the address of whoever the owner wants to exchange with
    uint public requestedTokenAmount; // The amount of the token the owner wants in exchange for eth
    Token public token; // the initialized token
    //uint ethOnOffer; //How much the owner is willing to trade for the requestedTokenAmount
    
    //The constructor should initialize all the fields that were declared.
    constructor(address ERC20Address, uint _requestedTokenAmount, address _requestedAddress) payable public{
        owner = msg.sender;
        requestedAddress= _requestedAddress;
        requestedTokenAmount = _requestedTokenAmount;
        token = Token(ERC20Address);
        //ethOnOffer =
    }
    
    //This function should check if the smart contract has the desired amount of the token. 
    //If so then the contract&#39;s eth should be sent to the requestedAddress and the contract&#39;s token will be sent to the owner.
    function fulfillEscrow() public{
        require(token.balanceOf(address(this)) >= requestedTokenAmount);
        //require(address(this).balance >= ethOnOffer);
            token.transfer(owner, token.balanceOf(address(this)) );
            requestedAddress.transfer(address(this).balance);
    }
    
    //This function will call selfdestruct only if the msg.sender is the owner and send any remaining eth to the owner.
    function eliminateSmartContractByteCode() public{
        require(msg.sender==owner);
            //token.transfer(token.balanceOf( address(this)), requestedAddress);
            selfdestruct(owner);
    }
    
    //view function to show how many tokens this contract has received
    function tokensSent() public view returns (uint){
        return (token.balanceOf(address(this)));
    }
    
    //view function returning true if the contract has more than requestedTokenAmount
    function readyToFulfill() public view returns(bool){
        return (token.balanceOf(address(this)) >= requestedTokenAmount);
    }
    
}