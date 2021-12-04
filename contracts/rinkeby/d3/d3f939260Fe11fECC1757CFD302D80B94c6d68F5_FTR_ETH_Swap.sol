// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeMath} from "./safe_math.sol";
import "./futuristic_token.sol";
import "./AggregatorV3Interface.sol";
import "./ierc20.sol";

interface IHome2{
     function getStudentsList() external view returns (string[] memory); 
}


contract FTR_ETH_Swap {
    using SafeMath for *;
    string private _name = "FTR/ETH Swapper";

    AggregatorV3Interface internal priceFeed;

// /**
//  * Network: Rinkeby
//  * Aggregator: ETH/USD
//  * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
//  */    
    address private rateSource = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e; 
    address private home2 = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D; // From previous HW2
    uint256 private NumberOfStudents;

    event Selling(address indexed receiver, uint value);
    event Failure(address indexed receiver, uint value, bytes data);
    event Interception(bytes message);
    event Recepting(bytes message);

    address private _owner;
    FuturisticToken internal token;

    constructor(address tokenAddress) {
        priceFeed = AggregatorV3Interface(rateSource);
        NumberOfStudents = uint256(IHome2(home2).getStudentsList().length);
        token = FuturisticToken(tokenAddress);
        _owner = msg.sender;
    }
    
    fallback() external payable {
        buyTokens();
        emit Interception(msg.data);
    }

    receive() external payable {
        buyTokens();
        emit Recepting("Assets came back");
    }

    function getExchange() public payable returns (uint) {   
        uint res_;
        uint8 priceFeedDecimals = priceFeed.decimals(); // = 8
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        res_ = uint ( uint(price) / uint(priceFeedDecimals));
        return uint (res_ / NumberOfStudents);
    }

    function buyTokens() public payable returns (bool) {
        require(msg.value > 0, "Some Eth required");

        uint amount;
        amount = uint(msg.value * getExchange()) ;

        uint currentBalance = token.balanceOf(address(token));
    
        if( currentBalance > amount ) {
            bool is_sent = token.transfer(msg.sender, amount);
            require(is_sent, "Failled to transfer FTR tokens");
            emit Selling(msg.sender, amount);
            return true;
        }
        else {
            (bool is_sent, bytes memory data) = msg.sender.call {value : msg.value} ("Sorry,there is not enough tokens");
            require(is_sent, "Failled to return Eth back to buyer");
            emit Failure(msg.sender, amount, data);
            return false;
       }
    }
}