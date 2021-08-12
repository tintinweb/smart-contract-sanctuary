/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    }


    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

interface BEP20 {
             function totalSupply() external view returns (uint theTotalSupply);
             function balanceOf(address _owner) external view returns (uint balance);
             function transfer(address _to, uint _value) external returns (bool success);
             function transferFrom(address _from, address _to, uint _value) external returns (bool success);
             function approve(address _spender, uint _value) external returns (bool success);
             function allowance(address _owner, address _spender) external view returns (uint remaining);
             event Transfer(address indexed _from, address indexed _to, uint _value);
             event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Presale {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint priceOfBNB = priceConsumerV3.getThePrice();
    address contractAddr = address(this);
    address owner = msg.sender;
    event OwnershipTransferred(address);
    event Received(address, uint);
    
    // Buy tokens with BUSD
    function buyTokenWithBUSD(uint tokenAmount) public returns (bool) {
        

        BEP20 token = BEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD address 
        address sender = msg.sender;
        
        token.transferFrom(sender, contractAddr, tokenAmount);
        
        return true;
    }
    
    /// View owner address
    function getOwner() public view returns(address){
        return owner;
    }
    
    /// Show USD Price of 1 BNB
    function usdPrice(uint amount) external view returns(uint) {
        uint bnbAmt = amount * priceOfBNB;
        return bnbAmt/100000000;
    }
    
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}