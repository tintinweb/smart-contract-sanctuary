pragma solidity ^0.4.24;

import "./OptimusShop.sol";



contract OptimusFactory {
    
    ERC20 public governanceToken;
    mapping (address => address) public OptimusShopList;
    // mapping (address => address) public tokenList;
    // mapping (address => address) public crowdsaleList;
    constructor (address optToken) public{
        governanceToken = ERC20 (optToken);
    }
    
    function CreateShop(
        string name, 
        string symbol, 
        uint8 decimals, 
        uint256 cap,
        uint256 rate,
        address wallet,
        uint256 goal_in_eth,
        uint256 openingtime,
        uint256 closingtime     
    ) 
        public 
    {
        require(governanceToken.balanceOf(msg.sender) >= 100000*10**18,"Insufficient OPT token balance");
        OptimusShop shoptoken = new OptimusShop();
        shoptoken.initializeShop(name,symbol,decimals,cap,rate,wallet,goal_in_eth,openingtime,closingtime);
        OptimusShopList[msg.sender]=address(shoptoken);
        // tokenList[msg.sender]=address(shoptoken._token);
        // crowdsaleList[msg.sender]=address(shoptoken._crowdsale);
        
    }
    
    function getshop() public view  returns(address){
        return address(OptimusShopList[msg.sender]);
    }
    
    // function gettoken() public view  returns(address){
    //     return address((OptimusShop(OptimusShopList[msg.sender]))._token);
    // }
    
    // function getcrowdsale() public view  returns(address){
    //     return address((OptimusShop(OptimusShopList[msg.sender]))._crowdsale);
    // }
}