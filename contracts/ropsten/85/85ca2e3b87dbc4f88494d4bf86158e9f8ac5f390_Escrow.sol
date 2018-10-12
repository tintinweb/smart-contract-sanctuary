pragma solidity ^0.4.25;

contract Token {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Escrow {
    
    address public owner; // owner is whoever is initiating the escrow and deploying the contract
    address public requestedAddress; // the address of whoever the owner wants to exchange with
    uint public requestedTokenAmount; // The amount of the token the owner wants in exchange for eth
    Token public token; // the initialized token
    
    constructor(address ERC20Address, uint _requestedTokenAmount, address _requestedAddress) public payable {
        owner = msg.sender;
        requestedAddress = _requestedAddress;
        requestedTokenAmount = _requestedTokenAmount;
        token = Token(ERC20Address);
    }
    
    function fulfillEscrow() public {
        require(token.balanceOf(address(this)) >= requestedTokenAmount);
        requestedAddress.transfer(address(this).balance);
        token.transfer(owner, requestedTokenAmount);
    }
    
    function eliminateSmartContractByteCode() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
}