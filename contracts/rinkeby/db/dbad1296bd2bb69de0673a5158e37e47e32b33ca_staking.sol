/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

//SPDX-License-Identifier: UNLICENSED
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
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId) external view returns (uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound);

  function latestRoundData() external view returns (uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound);

}
interface Token  {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(uint256 _amount) external;
    function burn(uint256 _amount) external;
}

contract staking {
    using SafeMath for uint256;
    Token tokenA;
    Token tokenB;
    AggregatorV3Interface internal priceFeed;
    event Transfer(address from, address to, uint256 amount);
    event StakeTransfer(address from ,address to, uint256 amount);
    
    struct Stake {
        uint256 stakeAmount;
        uint256 receiptAmount;
        address stakeAddress;
    }
    
    mapping (address => Stake) public stakeDetails;
    uint256 public noOfTokenA;
    uint256 public priceOfDAI;
    constructor(Token _tokenA , Token _tokenB) {
        priceFeed = AggregatorV3Interface(0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D);
        tokenA = _tokenA;
        tokenB = _tokenB;
        }
        
        function setPrice() public {
            ( , int price, , , ) = priceFeed.latestRoundData();
            priceOfDAI = uint256(price); 
        }
        
        function getPrice() public view returns(uint256 ) {
            return priceOfDAI;
        }
        
        function buyTokenA(uint256 amount) public payable {
        require(msg.value>0,"Pay some ethers");
        require(amount>0,"Amount can't be zero"); 
        setPrice(); 
        noOfTokenA = msg.value.div(priceOfDAI);
        require(tokenA.balanceOf(address(this))>=noOfTokenA,"Not enough Tokens");
        tokenA.transfer(msg.sender,noOfTokenA);
        emit Transfer(address(this),msg.sender,noOfTokenA);
    }
    
    function stake(uint256 _amount) public {
        require(_amount>0,"Stake some amount");
        require(tokenA.balanceOf(msg.sender)>=_amount,"Not enough Tokens for staking" );
        tokenA.transferFrom(msg.sender,address(this),_amount);
        uint256 y=5;
        uint256 receipt;
        receipt = y.mul(_amount).div(1000);
        stakeDetails[msg.sender].stakeAddress=msg.sender;
        stakeDetails[msg.sender].stakeAmount=stakeDetails[msg.sender].stakeAmount.add(_amount);
        stakeDetails[msg.sender].receiptAmount=receipt;
        tokenB.transfer(msg.sender,receipt);
        emit StakeTransfer(msg.sender,address(this),_amount);
    }
    
    function getTokenABack() public {
        uint256 receipt = stakeDetails[msg.sender].receiptAmount;
        uint256 amount  = stakeDetails[msg.sender].stakeAmount;
        require(receipt>0,"User has not Staked");
        tokenB.transferFrom(msg.sender,address(this),receipt);
        tokenA.transfer(msg.sender,amount);
        emit Transfer(address(this),msg.sender,amount);
        delete stakeDetails[msg.sender]; 
    }
}