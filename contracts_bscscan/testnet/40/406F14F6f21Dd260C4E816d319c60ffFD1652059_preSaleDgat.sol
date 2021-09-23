/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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


contract preSaleDgat{

    using SafeMath for uint256;
    
    IBEP20 public token;
    AggregatorV3Interface public priceFeedBnb;

    address payable public owner;
    address[] public referrers;
    
    uint256 private tokenPrice;
    uint256 private minAmount;
    uint256 private maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public maxSell;
    uint256 public referralPercent;
    uint256 public privateReferralPercent;

    struct Ref{
        bool isExist;
        uint256 referralCount;
        uint256 refAmount;
    }
    
    mapping(address => uint256) public balances;
    mapping(address => bool) public claimed;
    mapping(address => bool) public whiteList;
    mapping(address => Ref) private refData;
    

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
        owner = _owner;  // 0x0Df25c380e37D78A668cF6568E087Bf6629A7989
        token = _token;
        priceFeedBnb = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        tokenPrice = 3333333;
        minAmount = 0.2 ether;
        maxAmount = 5 ether;
        maxSell = 1 * 10 ** 12 * 10 ** 18;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 10 days; 
        referralPercent = 10;
        privateReferralPercent = 15;
    }
    
    receive() external payable{}
    
    // to get real time price of BNB
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }
    
    // to buy Dgat token during preSale time => for web3 use

    function buyTokenDgat(address _referrer) payable public {
        require(_referrer != address(0) && _referrer != msg.sender,"PRESALE: invalid referrer");
        uint256 numberOfTokens = bnbToToken(msg.value);
        uint256 maxToken = bnbToToken(maxAmount);
        uint256 refAmount;
        if(whiteList[_referrer]){
            refAmount = numberOfTokens.mul(privateReferralPercent).div(100);
        }else{
            refAmount = numberOfTokens.mul(referralPercent).div(100);
        }
        
        require(msg.value >= minAmount && msg.value <= maxAmount,"PRESALE: Amount not correct");
        require(numberOfTokens.add(balances[msg.sender]) <= maxToken,"PRESALE: Amount exceeded max limit");
        require(block.timestamp >= preSaleStartTime && block.timestamp < preSaleEndTime,"PRESALE: PreSale over");
        require(soldToken.add(numberOfTokens) <= maxSell,"PRESALE: Amount exceed preSale limit");
        
        if(!refData[_referrer].isExist){
            referrers.push(_referrer);
            refData[_referrer].isExist = true;
        }

        refData[_referrer].referralCount++;
        refData[_referrer].refAmount = refData[_referrer].refAmount.add(refAmount);
        
        if(msg.value >= minAmount && msg.value < 0.5 ether){
            balances[msg.sender] = balances[msg.sender].add(numberOfTokens.add(numberOfTokens.mul(3).div(100)));
            token.transferFrom(owner, address(this), numberOfTokens.add(numberOfTokens.mul(3).div(100)));
        }else if(msg.value >= 0.5 ether && msg.value < 1 ether){
            balances[msg.sender] = balances[msg.sender].add(numberOfTokens.add(numberOfTokens.mul(6).div(100)));
            token.transferFrom(owner, address(this), numberOfTokens.add(numberOfTokens.mul(6).div(100)));
        }else if(msg.value >= 1 ether && msg.value < 3 ether){
            balances[msg.sender] = balances[msg.sender].add(numberOfTokens.add(numberOfTokens.mul(9).div(100)));
            token.transferFrom(owner, address(this), numberOfTokens.add(numberOfTokens.mul(9).div(100)));
        }else if(msg.value >= 3 ether && msg.value < 5 ether){
            balances[msg.sender] = balances[msg.sender].add(numberOfTokens.add(numberOfTokens.mul(12).div(100)));
            token.transferFrom(owner, address(this), numberOfTokens.add(numberOfTokens.mul(12).div(100)));
        }else{
            balances[msg.sender] = balances[msg.sender].add(numberOfTokens.add(numberOfTokens.mul(15).div(100)));
            token.transferFrom(owner, address(this), numberOfTokens.add(numberOfTokens.mul(15).div(100)));
        }
        
        balances[_referrer] = balances[_referrer].add(refAmount);
        token.transferFrom(owner, address(this), refAmount);
        soldToken = soldToken.add(numberOfTokens).add(refAmount);
        amountRaised = amountRaised.add(msg.value);

        emit BuyToken(msg.sender, balances[msg.sender]);
    }

    // for white listed addresses to buy Dgat token during preSale time => for web3 use

    function buyTokenDgatWhiteListed(address _referrer) payable public onlyWhiteListed {
        require(_referrer != address(0) && _referrer != msg.sender,"PRESALE: invalid referrer");
        uint256 numberOfTokens = bnbToToken(msg.value);
        uint256 maxToken = bnbToToken(maxAmount);
        uint256 refAmount;
        if(whiteList[_referrer]){
            refAmount = numberOfTokens.mul(privateReferralPercent).div(100);
        }else{
            refAmount = numberOfTokens.mul(referralPercent).div(100);
        }
        
        require(msg.value >= minAmount && msg.value <= maxAmount,"PRESALE: Amount not correct");
        require(numberOfTokens.add(balances[msg.sender]) <= maxToken,"PRESALE: Amount exceeded max limit");
        require(block.timestamp >= preSaleStartTime && block.timestamp < preSaleEndTime,"PRESALE: PreSale over");
        require(soldToken.add(numberOfTokens) <= maxSell,"PRESALE: Amount exceed preSale limit");
        
        if(!refData[_referrer].isExist){
            referrers.push(_referrer);
            refData[_referrer].isExist = true;
        }

        refData[_referrer].referralCount++;
        refData[_referrer].refAmount = refData[_referrer].refAmount.add(refAmount);
        
        if(msg.value >= minAmount && msg.value < 0.5 ether){
            token.transferFrom(owner, msg.sender, numberOfTokens.add(numberOfTokens.mul(5).div(100)));
        }else if(msg.value >= 0.5 ether && msg.value < 1 ether){
            token.transferFrom(owner, msg.sender, numberOfTokens.add(numberOfTokens.mul(8).div(100)));
        }else if(msg.value >= 1 ether && msg.value < 3 ether){
            token.transferFrom(owner, msg.sender, numberOfTokens.add(numberOfTokens.mul(11).div(100)));
        }else if(msg.value >= 3 ether && msg.value < 5 ether){
            token.transferFrom(owner, msg.sender, numberOfTokens.add(numberOfTokens.mul(14).div(100)));
        }else{
            token.transferFrom(owner, msg.sender, numberOfTokens.add(numberOfTokens.mul(17).div(100)));
        }
        
        balances[_referrer] = balances[_referrer].add(refAmount);
        token.transferFrom(owner, address(this), refAmount);
        soldToken = soldToken.add(numberOfTokens).add(refAmount);
        amountRaised = amountRaised.add(msg.value);
        
        emit BuyToken(msg.sender, balances[msg.sender]);
    }

    
    // to claim token after launch => for web3 use

    function claim() public {
        require(block.timestamp >= preSaleEndTime,"PRESALE: Can not claim before PreSale End");
        require(claimed[msg.sender] == false,"PRESALE: Already claimed");
        require(balances[msg.sender] > 0,"PRESALE: Do not have any tokens");
        
        uint256 userBalance = balances[msg.sender];
        token.transfer(msg.sender, userBalance);
        balances[msg.sender] = 0;
        claimed[msg.sender] = true;

        emit ClaimToken(msg.sender, userBalance);
    }
    
    // to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 bnbToUsd = _amount.mul(getLatestPriceBnb());
        uint256 numberOfTokens = bnbToUsd.mul(tokenPrice);
        return numberOfTokens;
    }
    
    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner{
        tokenPrice = _price;
    }
    
    // to change preSale amount limits
    function setPreSaletLimits(uint256 _minAmount, uint256 _maxAmount, uint256 _percent, uint256 _maxSell) external onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        referralPercent = _percent;
        maxSell = _maxSell;
    }
    
    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime) external onlyOwner{
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
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

    function getReferrerData(address _user) public view returns(uint256 _refCount, uint256 _refAmount){
        return (refData[_user].referralCount, refData[_user].refAmount);
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