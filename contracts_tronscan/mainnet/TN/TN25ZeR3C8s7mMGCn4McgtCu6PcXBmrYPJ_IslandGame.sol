//SourceUnit: islandcontract.sol

pragma solidity 0.4.25;

contract IslandGame {
    uint256 public RESOURCES_TO_GET_1POWER=86400;
    
    uint256 PSN=10000;
    uint256 PSNH=5000;

    bool public initialized=false;
    
    mapping (address => uint256) public islandPower;
    mapping (address => uint256) public claimedIslandResources;
    mapping (address => uint256) public lastConvert;
    
    uint256 public marketIslandResources;
    constructor() public{}
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {return a < b ? a : b;}
    
    function getBalance() public view returns(uint256){return address(this).balance;}
    function getMyIslandPower() public view returns(uint256){return islandPower[msg.sender];}
    function getMyIslandResources() public view returns(uint256){return SafeMath.add(claimedIslandResources[msg.sender],getIslandResourcesSinceLastConvert(msg.sender));}
    
    function calculateResourceSell(uint256 resources) public view returns(uint256){return calculateTrade(resources,marketIslandResources,address(this).balance);}
    function calculateResourceBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){return calculateTrade(eth,contractBalance,marketIslandResources);}
    function calculateResourceBuySimple(uint256 eth) public view returns(uint256){return calculateResourceBuy(eth,address(this).balance);}

    function convertIslandResources() public {
        require(initialized);
        uint256 resourcesUsed=getMyIslandResources();
        uint256 newIslandPower=SafeMath.div(resourcesUsed,RESOURCES_TO_GET_1POWER);
        islandPower[msg.sender]=SafeMath.add(islandPower[msg.sender],newIslandPower);
        claimedIslandResources[msg.sender]=0;
        lastConvert[msg.sender]=now;
        marketIslandResources=SafeMath.add(marketIslandResources,SafeMath.div(resourcesUsed,10));
    }
    
    function sellIslandResources() public {
        require(initialized);
        uint256 hasIslandResources=getMyIslandResources();
        uint256 islandresourceValue=calculateResourceSell(hasIslandResources);
        claimedIslandResources[msg.sender]=0;
        lastConvert[msg.sender]=now;
        marketIslandResources=SafeMath.add(marketIslandResources,hasIslandResources);
        msg.sender.transfer(islandresourceValue);
    }
    
    function buyIslandResources() public payable {
        require(initialized);
        uint256 resourcesBought=calculateResourceBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        claimedIslandResources[msg.sender]=SafeMath.add(claimedIslandResources[msg.sender],resourcesBought);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function seedMarket(uint256 resources) public payable {
        require(marketIslandResources==0);
        initialized=true;
        marketIslandResources=resources;
    }
    
    function getIslandResourcesSinceLastConvert(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(RESOURCES_TO_GET_1POWER,SafeMath.sub(now,lastConvert[adr]));
        return SafeMath.mul(secondsPassed,islandPower[adr]);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;} uint256 c = a * b; assert(c / a == b); return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b; return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}
}