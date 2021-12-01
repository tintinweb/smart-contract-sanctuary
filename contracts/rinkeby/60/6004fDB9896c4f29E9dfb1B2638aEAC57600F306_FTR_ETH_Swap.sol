pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

import {SafeMath} from "./safe_math.sol";
import "./futuristic_token.sol";


// --- Interfaces section --------------------------------------------------------
import "./AggregatorV3Interface.sol";

interface IHome2{
     function getStudentsList() external view returns (string[] memory); 
}

interface IFTR{
     function balanceOf(address ftr) external view returns (uint);
     function transfer(address _to, uint256 _value) external returns (bool);
}

// --- Interfaces section end -----------------------------------------------------



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
    event Fail(address indexed receiver, uint value, bytes data);
    event Intercept(bytes message);

    address private owner = msg.sender;
    FuturisticToken internal token;

    constructor(address tokenAddress) {
        priceFeed = AggregatorV3Interface(rateSource);
        NumberOfStudents = uint256(IHome2(home2).getStudentsList().length);
        token = FuturisticToken(tokenAddress);
    }
    
    fallback() external payable {
        emit Intercept(msg.data);
    }

    function getExchange() public payable returns (uint) {   
        ( , int256 price, , , ) = priceFeed.latestRoundData();   
        return uint (SafeMath.div (uint256(price / 1e18), NumberOfStudents));
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
            emit Fail(msg.sender, amount, data);
            return false;
       }
    }
}

contract Interceptor {

    address public owner = msg.sender;
    event INTERCEPT(bytes message);

    fallback() external payable {
        emit INTERCEPT(msg.data);
    }

    function getBackEther() public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function buy(address _exchangeInstance) public payable {
        (bool success, ) = _exchangeInstance.call{gas: 300000, value: msg.value}(abi.encodeWithSignature("buyOnePieceOfToken()"));
        require(success, "External call failed");
    }
}