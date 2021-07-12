/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// File: Assignment/Distribution.sol
pragma solidity 0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath : subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0)
        {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a,uint256 b) internal pure returns (uint256)
    {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}
interface Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract distribution{
    using SafeMath for uint256;
    Token tokenA;
    Token tokenB;
    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;
    address public admin;
    uint256 public totalETHAmount=0;
    uint256 public totalBTCAmount=0;
    struct UserDetails1
    {
        address userAddress;
        uint256 amountETH;
        uint256 tokenAmount1;
    }
        struct UserDetails2
    {
        address userAddress;
        uint256 amountBTC;
        uint256 tokenAmount2;
    }
    mapping(address=>UserDetails1)public EthUser;
    mapping(address=>UserDetails2)public BtcUser;
    mapping(address=>uint256)balance;
    event TokenTransfer(address indexed owner,address indexed receiver, uint256 value);
    event Transfer(address indexed owner,address indexed receiver, uint256 value);
    constructor(Token _tokenA, Token _tokenB)
    {
        tokenA=_tokenA;
        tokenB=_tokenB;
        admin=msg.sender;
        priceFeed1=AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //ETH/USD    
        priceFeed2=AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404); //BTC/USD
    }
    uint256 public oneETHPrice;
    uint256 public oneBTCPrice;
    modifier onlyAdmin() 
    {
        require(admin==msg.sender,"Only admin can access");
        _;
    }
    function setETH() public returns(uint256)
    {
       (, int price,, ,) = priceFeed1.latestRoundData();
           oneETHPrice=uint256(price).div(10E8);
            return oneETHPrice;
    }
    
    function setBTC() public returns(uint256)
    {
        (, int price,, ,) = priceFeed2.latestRoundData();
            oneBTCPrice=uint256(price).div(10E8);
            return oneBTCPrice;
    }
    
    function changeAdmin(address newAdmin)public onlyAdmin returns(address)
    {
        require(newAdmin!=address(0),"Enter valid address");
        require(newAdmin!=admin,"Same admin address");
        admin=newAdmin;
        return admin;
    }
    
    function getTokenA(uint256 _amount) payable public returns(uint256)
    {
        require(msg.value>0,"Insufficient amount");
        require(msg.value==_amount,"Enter equal amount");
        EthUser[msg.sender].userAddress=msg.sender;
        EthUser[msg.sender].amountETH = msg.value;
        totalETHAmount=totalETHAmount.add(EthUser[msg.sender].amountETH);
        EthUser[msg.sender].tokenAmount1=((EthUser[msg.sender].amountETH).mul(oneETHPrice)).mul(10E18);// decimal conversion
        require(Token(tokenA).balanceOf(address(this))>=EthUser[msg.sender].tokenAmount1,"Not Enough Tokens");
        Token(tokenA).transfer(msg.sender,EthUser[msg.sender].tokenAmount1); //token transfser from contract address to user
        emit TokenTransfer(address(this),msg.sender,EthUser[msg.sender].tokenAmount1);
        return totalETHAmount;
    }
    function getTokenB(uint256 _amount) payable public returns(uint256)
    {
        require(msg.value>0,"Insufficient amount");
        require(msg.value==_amount,"Enter equal amount");
        BtcUser[msg.sender].userAddress=msg.sender;
        BtcUser[msg.sender].amountBTC=msg.value;
        totalBTCAmount=totalBTCAmount.add(BtcUser[msg.sender].amountBTC);
        BtcUser[msg.sender].tokenAmount2 = ((BtcUser[msg.sender].amountBTC).mul(oneBTCPrice)).mul(10E18);//decimal conversion
        require(Token(tokenB).balanceOf(address(this))>=BtcUser[msg.sender].tokenAmount2,"Not Enough Tokens");
        Token(tokenB).transfer(msg.sender,BtcUser[msg.sender].tokenAmount2);           //token transfser from contract address to user
        emit TokenTransfer(address(this),msg.sender,BtcUser[msg.sender].tokenAmount2);
        return totalBTCAmount;
    }
    function withdrawETH()public onlyAdmin 
    {
        payable(admin).transfer(totalETHAmount); 
        emit Transfer(address(this),admin,totalETHAmount); //ETH transfer from contract address to admin account
        totalETHAmount=0;
    }
       function withdrawBTC()public onlyAdmin 
    {
        payable(admin).transfer(totalBTCAmount); 
        emit Transfer(address(this),admin,totalBTCAmount);         //BTC transfer from contract address to admin account
        totalBTCAmount=0;
    }
    
}