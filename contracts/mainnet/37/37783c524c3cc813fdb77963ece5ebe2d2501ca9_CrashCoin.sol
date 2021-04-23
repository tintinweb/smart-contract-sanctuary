/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: UNLICENSED" 
pragma solidity ^0.6.0;

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

contract CrashCoin {

    string public constant name = "CrashCoin";
    string public constant symbol = "CRASC";
    uint8 public constant decimals = 18;  

    AggregatorV3Interface internal priceFeed;

    bool under50ktrigger = false;
    bool under40ktrigger = false;
    bool under30ktrigger = false;
    bool under20ktrigger = false;
    bool under10ktrigger = false;
    mapping(address => bool) x50kreg;
    mapping(address => bool) x40kreg;
    mapping(address => bool) x30kreg;
    mapping(address => bool) x20kreg;
    mapping(address => bool) x10kreg;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {  
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_;
    priceFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // BTCUSD
    }  

    function totalSupply() public view returns (uint256) {
    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        int price = getLatestPrice();
        if(price<5000000000000) {
            under50ktrigger = true;
        }
        if(price<4000000000000) {
            under40ktrigger = true;
        }
        if(price<3000000000000) {
            under30ktrigger = true;
        }
        if(price<2000000000000) {
            under20ktrigger = true;
        }
        if(price<1000000000000) {
            under10ktrigger = true;
        }
        if(under50ktrigger && !x50kreg[msg.sender]){
            totalSupply_.add(balances[msg.sender]);
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].add(balances[msg.sender]);
            x50kreg[msg.sender] = true;
        }
        if(under40ktrigger && !x40kreg[msg.sender]){
            totalSupply_.add(balances[msg.sender]);
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].add(balances[msg.sender]);
            x40kreg[msg.sender] = true;
        }
        if(under30ktrigger && !x30kreg[msg.sender]){
            totalSupply_.add(balances[msg.sender]);
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].add(balances[msg.sender]);
            x30kreg[msg.sender] = true;
        }
        if(under20ktrigger && !x20kreg[msg.sender]){
            totalSupply_.add(balances[msg.sender]);
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].add(balances[msg.sender]);
            x20kreg[msg.sender] = true;
        }
        if(under10ktrigger && !x10kreg[msg.sender]){
            totalSupply_.add(balances[msg.sender]);
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].add(balances[msg.sender]);
            x10kreg[msg.sender] = true;
        }
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);

        emit Transfer(owner, buyer, numTokens);
        return true;
    }

     function getLatestPrice() private view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}