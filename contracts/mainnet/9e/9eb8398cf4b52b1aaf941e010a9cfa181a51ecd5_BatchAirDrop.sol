/*
Name : Cryptonia Poker Chips
Descrition : Play poker online with cryptocurrency. This blockchain-powered platform lets you play in a fair and safe environment.
Url : www.cryptonia.poker
*/
pragma solidity 0.4.23;


contract MintableTokenIface {
    function mint(address beneficiary, uint256 amount) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
}


contract BatchAirDrop {
    MintableTokenIface public token;
    address public owner;

    constructor(MintableTokenIface _token) public {
        owner = msg.sender;
        token = _token;
    }

    function batchSend(uint256 amount, address[] wallets) public {
        require(msg.sender == owner);
        require(amount != 0);
        token.mint(this, amount * wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            token.transfer(wallets[i], amount);
        }
    }
}