/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.6;

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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function maxSupply() external view returns (uint256);
    function totalMint() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ESPT {
  using SafeMath for uint256;
  //use token0 to buy token1
  address public token0;
  address public token1;
  uint256 public startTime;
  uint256 public rate;  //rate == token0/token1 * 10^18
  uint256 public token0Limit;
  bool public paused;
  address public owner;
  mapping(address => bool) public whiteList;
  mapping(address => bool) public forbiddenUsers;

  //mapping (address=> uint256) balanceOf;
  
  modifier onlyOwner() {
        require(msg.sender == owner, "not a contract owner");
        _;
  }

  event Buy(uint256 tokenAAmount,uint256 tokenBAmount);
  event AddWhiteList(address indexed user);
  
  constructor(uint256 _startTime, address _token0, address _token1, uint256 _rate, uint256 _token0Limit) {
     startTime = _startTime;
     token0 = _token0;
     token1 = _token1;
     rate = _rate;
     token0Limit = _token0Limit;
     owner = msg.sender;
  }
  
  function setStartTime(uint256 _startTime) public onlyOwner {
      startTime = _startTime;
  }
  function setToken0(address _token0) public onlyOwner {
      token0 = _token0;
  }
  function setToken1(address _token1) public onlyOwner {
      token1 = _token1;
  }
  function setRate(uint256 _rate) public onlyOwner {
      rate = _rate;
  }
  function setToken0Limit(uint256 _token0Limit) public onlyOwner {
      token0Limit = _token0Limit;
  }
  function addWhiteList() public {
      require(whiteList[msg.sender] == false, "user already existed");
      whiteList[msg.sender] = true;
      emit AddWhiteList(msg.sender);
  }

  function buy(uint256 token0Amount) public {
    require(block.timestamp >= startTime && startTime != 0, "presale not started");
    require(forbiddenUsers[msg.sender] == false, "forbidden user");
    require(token0Amount > 0, "too less token0Amount");
    require(token0Amount <= token0Limit, "too much token0Amount");
    
    uint256 token1Amount = token0Amount.mul(rate);
    uint256 token1AmountLeft = IERC20(token1).balanceOf(address(this));
    require(token1AmountLeft >= token1Amount, "not enough token1 left");
    
    uint256 allowance = IERC20(token0).allowance(msg.sender, address(this));
    require(allowance >= token0Amount, 'too less allowance for token0');
    
    bool succcess = IERC20(token0).transferFrom(msg.sender, address(this), token0Amount);
    require(succcess, 'fail to transfer token1 to user');
    
    forbiddenUsers[msg.sender] = true;
    
    emit Buy(token0Amount, token1Amount);
  }
  
  
  function claim(address token, uint256 amount) public onlyOwner {
    bool succcess = IERC20(token).transferFrom(address(this), msg.sender, amount);
    require(succcess, 'token transfer failed');
  }
}