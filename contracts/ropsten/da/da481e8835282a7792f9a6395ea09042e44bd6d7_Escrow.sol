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
    
    constructor(address ERC20Address, uint _requestedTokenAmount, address _requestedAddress) public {
        owner = msg.sender;
        token = Token(ERC20Address);
        _requestedTokenAmount = requestedTokenAmount;
        _requestedAddress = requestedAddress;
    }
    
    function fulfillEscrow() public payable {
        require(token.balanceOf(this) >= requestedTokenAmount);
        requestedAddress.transfer(msg.value);
        owner.transfer(requestedTokenAmount);
    }
    
    function eliminateSmartContractByteCode() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}