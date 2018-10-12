contract Token {
    
    mapping (address => uint256) public balanceOf;

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;

        balanceOf[_to] += _value;
        

        return true;
    }
}

contract escrow {

    address owner;  // owner is whoever is initiating the escrow and deploying the contract

    address requestedAddress; // the address of whoever the owner wants to exchange with

    uint requestedTokenAmount; // The amount of the token the owner wants in exchange for eth

    Token token; // the initialized token


    constructor (address ERC20Address, uint _requestedTokenAmount, address _requestedAddress) public {

        owner = msg.sender;

        requestedAddress = _requestedAddress;

        requestedTokenAmount = _requestedTokenAmount;
        
        token = Token(ERC20Address);


    }

    function fulfillEscrow() public {

        require(token.balanceOf(msg.sender) >= requestedTokenAmount);

        token.transfer( owner , requestedTokenAmount);

    }

    function eliminateSmartContractByteCode() public {

        require(owner == msg.sender );

        selfdestruct( msg.sender );
    }

}