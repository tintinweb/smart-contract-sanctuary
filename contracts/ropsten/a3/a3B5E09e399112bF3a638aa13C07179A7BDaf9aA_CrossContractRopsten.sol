/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IToken{
    function mint(address _to, uint _amount) external;
    function burn(address _from, uint _amount)external;
    function balances(address ) external view returns(uint);
}

contract CrossContractRopsten{
    address public owner;
    address TokenSC;

    event BscToRopsten(address From,  address To, uint Amount);
    event RopstenToBsc(address From,  address To, uint Amount);

    constructor() {
        owner = msg.sender;
        TokenSC = 0x392206622410820610815D6F21298DA19dC55D98;
    }

    function ropstenToBsc(address _to, uint _amount)external{
        require(IToken(TokenSC).balances(msg.sender) >= _amount, "Insufficient funds");
        IToken(TokenSC).burn(msg.sender, _amount);
        emit RopstenToBsc(msg.sender, _to, _amount);
    }
    function bscToRopsten(address _to, uint _amount)external{
        require(IToken(TokenSC).balances(msg.sender) >= _amount, "Insufficient funds");
        IToken(TokenSC).mint(_to, _amount);
        emit BscToRopsten(msg.sender, _to, _amount);
    }
}