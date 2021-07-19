/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // Solidity only automatically asserts when dividing by 0
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

contract LuckySaleAndStake {

    using SafeMath for uint256;
    IBEP20 public token;
    AggregatorV3Interface public priceFeedBnb;
    address payable public owner;
    address payable public tokenOwner;
    uint256 saleAbletoken;
    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public tokeBought;
    uint256 public tokenremaining;
    bool public allow;
    struct Stake{
        uint256 time;
        uint256 amount;
        uint256 bonus;
        bool withdrawan;
    }
    struct User{
        address  reffrer;
        uint256 refBonus;
        uint256 totalstakeduser;
        uint256 stakecount;
        mapping(uint256 => Stake) stakerecord;
    }
    mapping(address => User) public Holders;
    modifier onlyOwner(){
        require(msg.sender == owner,"HODL: Not an owner");
        _;
    }

    modifier onlyTokenOwner(){
        require(msg.sender == tokenOwner,"HODL: Not a token owner");
        _;
    }

    modifier allowed(){
        require(allow == true,"HODL: Not allowed");
        _;
    }
    
    event BuyToken(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);
    constructor(address _token) {
        allow = true;
        token = IBEP20(_token);
        priceFeedBnb = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        owner = payable(msg.sender);
        tokenOwner = owner;
        saleAbletoken = token.totalSupply().mul(30).div(100);
        tokenPrice = 20;
        preSaleTime = block.timestamp + 30 days;
        minAmount = 1e18;
        maxAmount = saleAbletoken.mul(5).div(100);
        tokeBought = 0;
        tokenremaining = saleAbletoken;
    }
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }
    // to buy token during preSale time => for web3 use
    function buyToken(address ref) public payable allowed{
        require(block.timestamp < preSaleTime,"HODL: Time over"); // time check
        require(tokenremaining > 0,"token not available");
        require(bnbToToken(msg.value).mul(1e18) >= minAmount && bnbToToken(msg.value).mul(1e18) <= maxAmount,"HODL: Invalid Amount");
        require(ref != msg.sender && ref != address(0) ,"cannot refer yourself");
        User storage user = Holders[msg.sender];
        user.reffrer = ref;
        uint256 numberOfTokens = bnbToToken(msg.value).mul(1e18);
        token.transferFrom(tokenOwner,user.reffrer,(numberOfTokens.mul(10).div(100)));
        Holders[user.reffrer].refBonus += (numberOfTokens.mul(10).div(100));
        token.transferFrom(tokenOwner,msg.sender, (numberOfTokens.mul(90).div(100)));
        tokeBought += numberOfTokens;
        tokenremaining -= numberOfTokens;
        emit BuyToken(msg.sender, numberOfTokens, msg.value);
    }
        function stake(uint256 amount) public{
        token.transferFrom(msg.sender,address(this),(amount.mul(1e18)));
        User storage user = Holders[msg.sender];
        user.totalstakeduser += amount.mul(1e18);
        user.stakerecord[user.stakecount].time = block.timestamp + 7 days;
        user.stakerecord[user.stakecount].amount = amount.mul(1e18);
        user.stakerecord[user.stakecount].bonus = amount.mul(25).mul(1e18).div(1000);
        user.stakecount++;
    }
    function withdraw(uint256 count) public{
        User storage user = Holders[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(user.stakerecord[count].time  < block.timestamp,"cannot withdraw before time");
        require(!user.stakerecord[count].withdrawan,"withdraw only once");
        user.stakerecord[count].withdrawan = true;
        token.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        token.transfer(msg.sender,user.stakerecord[count].amount);
    }
    function unstake(uint256 count) public{
        User storage user = Holders[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(!user.stakerecord[count].withdrawan,"withdraw only once");
        user.stakerecord[count].withdrawan = true;
        uint256 unstakeable = user.stakerecord[count].amount;
        token.transfer(msg.sender,unstakeable);
        user.stakerecord[user.stakecount].bonus = 0;
        
    }
    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 precision = 1e2;
        uint256 bnbToUsd = precision.mul(_amount).mul(getLatestPriceBnb()).div(1e18);
        uint256 numberOfTokens = bnbToUsd.mul(tokenPrice);
        return numberOfTokens.div(precision);
    }
    function stakedetails(address add,uint256 count) public view returns(
        uint256 _time,
        uint256 _amount,
        uint256 _bonus,
        bool _withdrawan){
        
        return(
        Holders[add].stakerecord[count].time,
        Holders[add].stakerecord[count].amount,
        Holders[add].stakerecord[count].bonus,
        Holders[add].stakerecord[count].withdrawan
        );
    }
    
    // to change Price of the token
    function changePrice(uint256 _tokenPerUsd) external onlyOwner{
        tokenPrice = _tokenPerUsd;
    }
    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyOwner{
        allow = _enable;
    }

    // to draw unSold tokens from preSale
    function migrateTokenFunds() external onlyTokenOwner allowed{
        require(getCurrentTime() > preSaleTime,"HODL: Time error");
        tokenOwner.transfer(getContractTokenBalance());
    }
    
    function getContractTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
}