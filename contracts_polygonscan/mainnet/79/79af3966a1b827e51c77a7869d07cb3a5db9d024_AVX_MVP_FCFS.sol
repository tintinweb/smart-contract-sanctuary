/**
 *Submitted for verification at polygonscan.com on 2022-01-21
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
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // Mainnet MATIC/USD 
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

contract AVX_MVP_FCFS {
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfMATIC = priceConsumerV3.getThePrice();
    address public owner = 0x3bf69788E5Da1505E35101eA20F55B972F35D825;
    address public subOwner;
    uint public minLimit;
    uint public maxLimit;
    uint public maxCollectionLimit;
    uint public totalDeposit;
    uint public time;
	uint public buyPrice;
	uint public buyPriceDecimal;
	address public claimTokenAddr;
    
    struct Deposit {
        uint[] amounts;
        uint[] times;
    }
    
    struct Claim {
        uint[] claimAmounts;
        uint[] claimTimes;
    }

    struct Buyer{
        uint totalTokensBought;
    }
    
    
    mapping(address => Deposit) private dep;
    mapping(address => Claim) claim;
    mapping(address => Buyer) public buyer;
   
    event OwnershipTransferred(address to);
    event SubOwnershipTransferred(address to);
    event Received(address, uint);
    
    constructor() {
        subOwner = msg.sender;
        minLimit = 10 * 10**18;
        maxLimit = 1000 * 10**18;
        maxCollectionLimit = 400000 * 10**18;
        buyPrice = 16;
        buyPriceDecimal = 1000;
        time = 1641575700; // Friday, January 7, 2022 10:45:00 PM GMT+05:30
    }
    
   function updateLiveMaticPrice() external {
      priceOfMATIC = priceConsumerV3.getThePrice();
      
    } 
    
    function deposit() external payable {
        uint amount  = msg.value;        
        require(amount >= minLimit && amount <= maxLimit, "Min Max Limit Found");
        require(totalDeposit < maxCollectionLimit , "Max Deposit Limit Reached");
        address sender = msg.sender;
        dep[sender].amounts.push(amount);
        dep[sender].times.push(block.timestamp);
        totalDeposit += amount;
        uint tokens = (amount * priceOfMATIC / (100000000/buyPriceDecimal)) / buyPrice;
        buyer[sender].totalTokensBought += tokens; 
    }
    
    // Set buy price 
    // Upto _price_decimal decimals
    function setBuyPrice(uint _price,uint _price_decimal) external {
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        buyPrice = _price;
        buyPriceDecimal = _price_decimal;
    }
    
    function setClaimTokenAddress(address addr) external {
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        claimTokenAddr = addr;
        
    }
    /// Return bought tokens of user
    function userBuyTokens(address user) public view returns (uint) {
        return buyer[user].totalTokensBought;
    }
    
    // Transfer ownership 
    // Only owner can do that
    function ownershipTransfer(address to) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Zero address error");
        owner = to;
        emit OwnershipTransferred(to);
    }

    // Transfer subownership 
    // Only owner can do that
    function subownershipTransfer(address to) external {
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        require(to != address(0), "Zero address error");
        subOwner = to;
        emit SubOwnershipTransferred(to);
    }
    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) external {
        require(msg.sender == owner, "Only owner");
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }
    
    // Owner MATIC withdrawal
    function ownerMaticWithdraw(uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
    
    // update max limit
    function updateMaxLimit(uint maxLimitAmt) external {
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        maxLimit = maxLimitAmt * 10**18;
       
    }
    
    // update min limit
    function updateMinLimit(uint minLimitAmt) external{
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        minLimit = minLimitAmt * 10**18;
        
    }
    
    // update max Collection limit
    function updateMaxCollectionLimit(uint maxCollectionLimitAmt) external {
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        maxCollectionLimit = maxCollectionLimitAmt * 10**18;        
    }
      
  
    
    function viewDeposits(address addr) public view returns(uint[] memory amt, uint[] memory at) {
        uint len = dep[addr].amounts.length;
        amt = new uint[](len);
        at = new uint[](len);
        for(uint i = 0; i < len; i++){
            amt[i] = dep[addr].amounts[i];
            at[i] = dep[addr].times[i];
        }
        return (amt,at);
    }
    
     // Set first claim time 
    function setFirstClaimTime(uint _time) external {
        require( (msg.sender == owner || msg.sender == subOwner ), "Only owner");
        time = _time;
    }

    function claimTokens(uint index) public returns (bool) {
        require(claimTokenAddr != address(0), "Claim token address not set");
        BEP20 token = BEP20(claimTokenAddr);
        Claim storage _claim = claim[msg.sender];
        uint amount = _claim.claimAmounts[index];
        require(block.timestamp > _claim.claimTimes[index], "Claim time not reached");
        require(_claim.claimAmounts[index] != 0, "Already claimed");
        token.transfer(msg.sender, amount);
        delete _claim.claimAmounts[index];
        return true;
    }    
    
    
    /// Show Buyer Details
    function claimDetails(address addr) public view returns(uint[] memory amounts, uint[] memory times){
        uint len = claim[addr].claimAmounts.length;
        amounts = new uint[](len);
        times = new uint[](len);
        for(uint i = 0; i < len; i++){
            amounts[i] = claim[addr].claimAmounts[i];
            times[i] = claim[addr].claimTimes[i];
        }
        return (amounts, times);
    }
    
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}