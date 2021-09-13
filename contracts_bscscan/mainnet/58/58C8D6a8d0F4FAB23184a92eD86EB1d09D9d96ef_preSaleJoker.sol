/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-03
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
contract preSaleJoker{
    using SafeMath for uint256;
    
    IBEP20 public token;
    AggregatorV3Interface public priceFeedBnb;
    address payable public owner;
    
    uint256 public tokenPrice;
    uint256 public tokenpriceWhitelist;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public minAmountWhitelisted;
    uint256 public maxAmountWhitelisted;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSaleStartTimeWhiteListed;
    uint256 public preSaleEndTimeWhiteListed;
    uint256 public soldToken;
    uint256 public soldTokenWhitelisted;
    uint256 public amountRaised;
    uint256 public amountRaisedWhitelisted;
    uint256 public supply;
    uint256 public supplyWhitelisted;
    
    mapping(address => bool) public whiteList;    
    
    modifier onlyOwner() {
        require(msg.sender == owner,"PRESALE: Not an owner");
        _;
    }
    modifier onlyWhiteListed() {
        require(whiteList[msg.sender],"PRESALE: only for white listed");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);
    
    constructor(address payable _owner, IBEP20 _token) {
        owner = _owner;
        token = _token;
        priceFeedBnb = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        tokenpriceWhitelist = 250000;
        minAmountWhitelisted = 0.1 ether;
        maxAmountWhitelisted = 1 ether;
        preSaleStartTimeWhiteListed = 1631559600;
        preSaleEndTimeWhiteListed = preSaleStartTimeWhiteListed + 100 minutes;
        supplyWhitelisted = 50000000;
        
    }
    
    receive() external payable{}
    
    // to get real time price of BNB
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }
    
    // to buy token during preSale time => for web3 use
    function buyToken() payable public {
        uint256 numberOfTokens = bnbToToken(msg.value);
        uint256 maxToken = bnbToToken(maxAmount);
        
        require(msg.value >= minAmount && msg.value <= maxAmount,"PRESALE: Amount not correct");
        require(numberOfTokens.add(token.balanceOf(msg.sender)) <= maxToken,"PRESALE: Amount exceeded max limit");
        require(block.timestamp >= preSaleStartTime && block.timestamp < preSaleEndTime,"PRESALE: PreSale over");
                
        token.transferFrom(owner, msg.sender, numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        emit BuyToken(msg.sender, numberOfTokens);
    }
    
    // for white listed addresses to buy token during preSale time => for web3 use
    function buyTokenWhiteListed() payable public onlyWhiteListed {
        uint256 numberOfTokens = bnbToTokenWhitelisted(msg.value);
        uint256 maxToken = bnbToTokenWhitelisted(maxAmountWhitelisted);
        
        require(msg.value >= minAmountWhitelisted && msg.value <= maxAmountWhitelisted,"PRESALE: Amount not correct");
        require(numberOfTokens.add(token.balanceOf(msg.sender)) <= maxToken,"PRESALE: Amount exceeded max limit");
        require(block.timestamp >= preSaleStartTimeWhiteListed && block.timestamp < preSaleEndTimeWhiteListed,"PRESALE: PreSale over");        
        
        token.transferFrom(owner, msg.sender, numberOfTokens);
        soldTokenWhitelisted = soldTokenWhitelisted.add(numberOfTokens);
        amountRaisedWhitelisted = amountRaisedWhitelisted.add(msg.value);
        
        emit BuyToken(msg.sender, numberOfTokens);
    }
    
    // to check number of token for given BNB
    function bnbToTokenWhitelisted(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenpriceWhitelist);
        return numberOfTokens.div(10 ** token.decimals());
    }
    
    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPrice);
        return numberOfTokens.div(10 ** token.decimals());
    }
    
    
    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner{
        tokenPrice = _price;
    }
    
    function changePriceWhiteListed(uint256 _price) external onlyOwner{
        tokenpriceWhitelist = _price;
    }
    
    // to change preSale amount limits
    function setPreSaletLimits(uint256 _minAmount, uint256 _maxAmount) external onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }
    
    function setPreSaletLimitsWhitelisted(uint256 _minAmount, uint256 _maxAmount) external onlyOwner{
        minAmountWhitelisted = _minAmount;
        maxAmountWhitelisted = _maxAmount;
    }
    
    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime) external onlyOwner{
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }
    
    // to change preSale time duration
    function setPreSaleTimeWhiteListed(uint256 _startTime, uint256 _endTime) external onlyOwner{
        preSaleStartTimeWhiteListed = _startTime;
        preSaleEndTimeWhiteListed = _endTime;
    }
    
    // to enlist or remove any User
    function whiteListUser(address _user, bool _state) public onlyOwner{
        whiteList[_user] = _state;
    }
    
    // to white list users => for web3 use
    function whiteListUser(address[] memory _user) public onlyOwner{
        for(uint i=0 ; i<_user.length ; i++){
            whiteList[_user[i]] = true;
        }
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
    
    function getContractTokenBalance() external view returns(uint256){
        return token.balanceOf(address(this));
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