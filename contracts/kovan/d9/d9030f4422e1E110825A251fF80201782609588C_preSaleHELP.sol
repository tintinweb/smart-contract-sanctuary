/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


contract preSaleHELP{

    using SafeMath for uint256;
    
    IBEP20 public token;
    AggregatorV3Interface public priceFeedBnb;

    address payable public owner;
    
    uint256 public tokenPerEth;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaisedBnb;

    modifier onlyOwner() {
        require(msg.sender == owner,"PRESALE: Not an owner");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);
    
    constructor(address payable _owner, IBEP20 _token) {
        owner = _owner;
        token = _token;
        priceFeedBnb = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        tokenPerEth = 333333;
        minAmount = 0.05 ether;
        maxAmount = 3 ether;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 20 days;
    }
    
    receive() external payable{}
    
    // to get real time price of BNB
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price);
    }
    
    // to buy token during preSale time => for web3 use

    function buyToken() payable public {
        require(block.timestamp >= preSaleStartTime && block.timestamp < preSaleEndTime,"PRESALE: PreSale time not met");

        uint256 numberOfTokens = bnbToToken(msg.value);        
        require(msg.value >= minAmount,"PRESALE: Amount not correct");
                
        token.transferFrom(owner, msg.sender, numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaisedBnb = amountRaisedBnb.add(msg.value);

        emit BuyToken(msg.sender, numberOfTokens);
    }
    
    // to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 bnbToUsd = _amount.mul(getLatestPriceBnb());
        uint256 numberOfTokens = bnbToUsd.mul(tokenPerEth);
        return numberOfTokens.div(1e8);
    }
    
    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner{
        tokenPerEth = _price;
    }
    
    // to change preSale amount limits
    function setPreSaletLimits(uint256 _minAmount) external onlyOwner{
        minAmount = _minAmount;
    }
    
    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime) external onlyOwner{
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }
    
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    // to draw funds for liquidity
    function transferFunds() external onlyOwner returns(bool){
        owner.transfer(address(this).balance);
        return true;
    }
    
    // to get current UTC time
    function getCurrentTime() external view returns(uint256){
        return block.timestamp;
    }

    function contractBalanceBnb() external view returns(uint256){
        return address(this).balance;
    }

    function getContractTokenApproval() external view returns(uint256){
        return token.allowance(owner, address(this));
    }
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}