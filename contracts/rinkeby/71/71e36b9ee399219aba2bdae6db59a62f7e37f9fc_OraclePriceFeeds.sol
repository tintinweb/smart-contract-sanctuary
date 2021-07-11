pragma solidity 0.6.0;

import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

// SPDX-License-Identifier: MIT
contract OraclePriceFeeds {

    using SafeMath for uint256;
    address public owner;

    //token == token-usdt
    mapping(address => address) public feedsManager;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setFeedAddressManager(address tokenAddress,address feedAddress) public onlyOwner{
       require(tokenAddress != address(0),"setFeedAddressManager tokenAddress error .");
       require(feedAddress != address(0),"setFeedAddressManager feedAddress error .");
       feedsManager[tokenAddress] = feedAddress;
    }
    
    //srcToken contains weth
    //Dec:8
    function getPriceTokenToUsdt(address srcTokenAddress) public view returns(uint256,int256){
        address feedAddress = feedsManager[srcTokenAddress];
        if(feedAddress == address(0)){
            return(0,0);
        }
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        (
            ,
            int256 answer,
            ,
            ,
            
        )   = priceFeed.latestRoundData();
        return (10,answer);
    }
}