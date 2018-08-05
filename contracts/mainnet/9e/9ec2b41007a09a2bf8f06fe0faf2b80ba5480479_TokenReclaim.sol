pragma solidity ^0.4.23;

contract TokenRequestStub{
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract TokenReclaim{
    TokenRequestStub tokenAddress;
    mapping (address=>string) internal _ethToPubKey;
    event AccountRegister (address ethAccount, string pubKey, uint holding);

    constructor() public{
        tokenAddress = TokenRequestStub(0x3833ddA0AEB6947b98cE454d89366cBA8Cc55528);
    }

    function register(string pubKey) public{
        require(bytes(pubKey).length <= 64 && bytes(pubKey).length >= 50 );
        uint holding = tokenAddress.balanceOf(msg.sender);
        _ethToPubKey[msg.sender] = pubKey;
        emit AccountRegister(msg.sender, pubKey, holding);
    }

    function keys(address addr) constant public returns (string){
        return _ethToPubKey[addr];
    }
}