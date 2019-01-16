pragma solidity ^0.4.23;


contract TokenSwap{
    mapping (address=>address) internal _ethToPubKey;
    event AccountRegister (address ethAccount, address pubKey);

    constructor() public{
    }

    function register(address pubKey) public{
        //require(bytes(pubKey).length == 42);
        //NOTE: THE CAPITAL LETTERS AND SMALL LETTERS ARE ALL IMPORTANT!
        // require(bytes(_ethToPubKey[msg.sender]).length == 0);
        require(_ethToPubKey[msg.sender] == address(0x0));
        _ethToPubKey[msg.sender] = pubKey;
        emit AccountRegister(msg.sender, pubKey);
    }

    function keys(address addr) constant public returns (address){
        return _ethToPubKey[addr];
    }
}