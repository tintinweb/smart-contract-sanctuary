pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b);
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}



interface token {
    function balanceOf(address who) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract Crowdsale {
    using SafeMath for uint256;

    // address where funds are collected.
    address public wallet;

    // Contract address of the token being sold.
    address public contractAddress;

    // The token being sold
    token public tokenReward;

    // Rate 1 ETH = crowdSaleCoeff Token
    uint256 public crowdSaleCoeff;

    // Begin and End date of CrowdSale.
    uint public startDate;
    uint public endDate;

    // crowdsale limit 
    // uint256 public constant CROWDSALE_LIMIT = 1 * (10 ** 6) * (10 ** 18);


    function Crowdsale() public{
        wallet = msg.sender;
        contractAddress = 0x8e72A97a158ACD1E7E14a7802e289f23afA54e24;
        tokenReward = token(contractAddress);
        crowdSaleCoeff = 8000000;
        startDate = now;
        endDate = now + 1 weeks;
    }

    function () public payable {
        require(msg.value > 0);
        require(startDate <= now && now <= endDate);
        uint256 numTokens = SafeMath.mul(msg.value, crowdSaleCoeff);
        require(numTokens <= tokenReward.balanceOf(wallet)); 
        tokenReward.transferFrom(wallet, msg.sender, numTokens);
        wallet.transfer(msg.value);
    }
 }