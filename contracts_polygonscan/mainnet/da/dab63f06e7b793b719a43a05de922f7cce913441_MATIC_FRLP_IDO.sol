/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.8;

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

contract MATIC_FRLP_IDO{
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfMATIC = priceConsumerV3.getThePrice();
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }

  struct Claim {
    uint[] claimAmounts;
    uint[] claimTimes;
    bool[] claimWithdrawns;
}

  address public buyTokenAddr;
  address public contractAddr = address(this);

  uint public seedTokenPrice         = 14;
  uint public seedTokenPriceDecimal  = 100;

  uint public strategicTokenPrice         = 24;
  uint public strategicTokenPriceDecimal  = 100;

  uint public privateTokenPrice         = 44;
  uint public privateTokenPriceDecimal  = 100;

  uint public publicTokenPrice         = 64;
  uint public publicTokenPriceDecimal  = 100;

  uint public seedRoundStartTime = 1639978200; // Monday, December 20, 2021 11:00:00 AM GMT+05:30
  uint public seedRoundEndTime = 1640583000;  // Monday, December 27, 2021 11:00:00 AM GMT+05:30

  uint public strategicRoundStartTime = 1640669400; // Tuesday, December 28, 2021 11:00:00 AM GMT+05:30
  uint public strategicRoundEndTime = 1641274200;   // Tuesday, January 4, 2022 11:00:00 AM GMT+05:30

  uint public privateRoundStartTime = 1641447000; // Thursday, January 6, 2022 11:00:00 AM GMT+05:30
  uint public privateRoundEndTime = 1642051800;   // Thursday, January 13, 2022 11:00:00 AM GMT+05:30

  uint public publicRoundStartTime = 1642397400; // Monday, January 17, 2022 11:00:00 AM GMT+05:30
  uint public publicRoundEndTime = 1642483800;  // Tuesday, January 18, 2022 11:00:00 AM GMT+05:30      

  event OwnershipTransferred(address);
  event Claimed(address user,uint amount, uint time);

  address public owner = msg.sender;
  

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public claimStartTime;
  bool public saleStatus;
  uint public oneDay = 86400;
  
  
  mapping (address => Investor) public investors;
  mapping(address => Claim) claim;
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  
  constructor() {
        saleStatus = false;
        claimStartTime = 1642656600; // Thursday, January 20, 2022 11:00:00 AM GMT+05:30
  }
  
  function buyTokenWithMATIC() external payable {

    require(saleStatus == true, "Sale has not started");  
    require(msg.value >= 0,"Invalid Amount");
    
   
    address sender = msg.sender;
    if(!investors[sender].registered) {
      investors[sender].registered = true;
      totalInvestors++;
    }
    
    (uint tariff, uint currentTokenPrice, uint currrentTokenPriceDecimal) = getTokenPrice();
    
    uint tokenVal = (msg.value * priceOfMATIC / (100000000/currrentTokenPriceDecimal)) / currentTokenPrice;
    
    investors[sender].invested += tokenVal;
    totalInvested += tokenVal;
    
    investors[sender].deposits.push(Deposit(tariff, tokenVal, block.number));
    
    uint claimAmount = tokenVal * 5 / 100;
    
    if(tariff==0){
        claim[sender].claimAmounts.push(claimAmount);
        claim[sender].claimTimes.push(claimStartTime);
        claim[sender].claimWithdrawns.push(false);
        
         for(uint i = 30; i<=570; i=i+30 ){
            uint addTime = oneDay*i; // 86400 = 1 days
            claim[sender].claimAmounts.push(claimAmount);
            claim[sender].claimTimes.push(claimStartTime + addTime);
            claim[sender].claimWithdrawns.push(false);
        }
    }

    if(tariff==1){
        claim[sender].claimAmounts.push(claimAmount);
        claim[sender].claimTimes.push(claimStartTime);
        claim[sender].claimWithdrawns.push(false);
        
         for(uint i = 21; i<=399; i=i+21 ){
            uint addTime = oneDay*i; // 86400 = 1 days
            claim[sender].claimAmounts.push(claimAmount);
            claim[sender].claimTimes.push(claimStartTime + addTime);
            claim[sender].claimWithdrawns.push(false);
        }
    }

    if(tariff==2){
        claim[sender].claimAmounts.push(claimAmount);
        claim[sender].claimTimes.push(claimStartTime);
        claim[sender].claimWithdrawns.push(false);
        
         for(uint i = 14; i<=266; i=i+14 ){
            uint addTime = oneDay*i; // 86400 = 1 days
            claim[sender].claimAmounts.push(claimAmount);
            claim[sender].claimTimes.push(claimStartTime + addTime);
            claim[sender].claimWithdrawns.push(false);
        }
    }

    if(tariff==3){
        claim[sender].claimAmounts.push(claimAmount);
        claim[sender].claimTimes.push(claimStartTime);
        claim[sender].claimWithdrawns.push(false);
        
         for(uint i = 7; i<=133; i=i+7 ){
            uint addTime = oneDay*i; // 86400 = 1 days
            claim[sender].claimAmounts.push(claimAmount);
            claim[sender].claimTimes.push(claimStartTime + addTime);
            claim[sender].claimWithdrawns.push(false);
        }
    }

    // send token to user
    //token.transfer(msg.sender, tokenVal);
    
    emit DepositAt(sender, tariff, tokenVal);
  } 

  
    function usd_price() public view returns (uint) {
        return priceOfMATIC;
    }

    function setSaleStatus(bool status) external {
        require(msg.sender == owner, "Only owner");
        saleStatus = status;
        
    }

    function updateOneDay(uint _oneDay) external {
        require(msg.sender == owner, "Only owner");
        oneDay = _oneDay;
        
    }
  
    function myTotalInvestment() public view returns (uint) {
        Investor storage investor = investors[msg.sender];
        uint amount = investor.invested;
        return amount;
    }


    
    
    function tokenInMATIC(uint amount) public view returns (uint) {
        
        (uint tariff,uint currentTokenPrice, uint currrentTokenPriceDecimal) = getTokenPrice();
        
        uint tokenVal = (amount * priceOfMATIC *currrentTokenPriceDecimal) / (100000000*currentTokenPrice);
        
        return tokenVal;
    }


    function getTokenPrice() public view returns (uint, uint, uint) {
        uint currentTime = block.timestamp;
        uint tariff = 3 ;
        uint currentTokenPrice = publicTokenPrice;
        uint currrentTokenPriceDecimal = publicTokenPriceDecimal;

       if(currentTime >= seedRoundStartTime && currentTime <= seedRoundEndTime){
            tariff = 0;
            currentTokenPrice = seedTokenPrice;
            currrentTokenPriceDecimal = seedTokenPriceDecimal;
        }
        else if(currentTime >= strategicRoundStartTime && currentTime <= strategicRoundEndTime){
            tariff = 1;
            currentTokenPrice = strategicTokenPrice;
            currrentTokenPriceDecimal = strategicTokenPriceDecimal;
        }
        else if(currentTime >= privateRoundStartTime && currentTime <= privateRoundEndTime){
            tariff = 2;
            currentTokenPrice = privateTokenPrice;
            currrentTokenPriceDecimal = privateTokenPriceDecimal;
        }
        else if(currentTime >= publicRoundStartTime && currentTime <= publicRoundEndTime){
            tariff = 3;
            currentTokenPrice = publicTokenPrice;
            currrentTokenPriceDecimal = publicTokenPriceDecimal;
        }
        return (tariff,currentTokenPrice,currrentTokenPriceDecimal);
    } 



    /*
    like tokenPrice = 0.0000000001
    setBuyPrice = 1 
    tokenPriceDecimal= 10
    */
    // Set buy price  
    function setBuyPrice(uint _seedTokenPrice, 
                        uint _seedTokenPriceDecimal,
                        uint _strategicTokenPrice, 
                        uint _strategicTokenPriceDecimal,
                        uint _privateTokenPrice, 
                        uint _privateTokenPriceDecimal,
                        uint _publicTokenPrice, 
                        uint _publicTokenPriceDecimal
                        ) external {
      require(msg.sender == owner, "Only owner");
      seedTokenPrice        = _seedTokenPrice;
      seedTokenPriceDecimal     = _seedTokenPriceDecimal;

      strategicTokenPrice = _strategicTokenPrice;
      strategicTokenPriceDecimal = _strategicTokenPriceDecimal;

      privateTokenPrice = _privateTokenPrice;
      privateTokenPriceDecimal = _privateTokenPriceDecimal;

      publicTokenPrice = _publicTokenPrice;
      publicTokenPriceDecimal = _publicTokenPriceDecimal;
    }

    function updateSeedRoundTime(uint _seedRoundStartTime, uint _seedRoundEndTime) external {
        require(msg.sender == owner, "Only owner");
        seedRoundStartTime   = _seedRoundStartTime;
         seedRoundEndTime     = _seedRoundEndTime;
    }

    function updateStrategicRoundTime(uint _strategicRoundStartTime, uint _strategicRoundEndTime) external {
        require(msg.sender == owner, "Only owner");
        strategicRoundStartTime   = _strategicRoundStartTime;
        strategicRoundEndTime   = _strategicRoundEndTime;
    }

    function updatePrivateRoundTime(uint _privateRoundStartTime, uint _privateRoundEndTime) external {
        require(msg.sender == owner, "Only owner");
        privateRoundStartTime   = _privateRoundStartTime;
        privateRoundEndTime   = _privateRoundEndTime;
    }

    function updatePublicRoundTime(uint _publicRoundStartTime, uint _publicRoundEndTime) external {
        require(msg.sender == owner, "Only owner");
        publicRoundStartTime   = _publicRoundStartTime;
        publicRoundEndTime     = _publicRoundEndTime;
    }


    function setBuyTokenAddr(address _buyTokenAddr) external {
        buyTokenAddr = _buyTokenAddr;
    }

    function setClaimStartTime(uint _claimStartTime) external {
        claimStartTime = _claimStartTime;
    }

   
    // Claim function
    function claimTokensAll() external {
        BEP20 token = BEP20(buyTokenAddr);
        address addr = msg.sender;
        uint len = claim[addr].claimAmounts.length;
        uint amt = 0;
        for(uint i = 0; i < len; i++){
            if(block.timestamp > claim[addr].claimTimes[i] && claim[addr].claimWithdrawns[i]==false) {
                amt += claim[addr].claimAmounts[i];
            }
        }
        require(token.balanceOf(address(this)) >= amt, "Insufficient amount on contract");
        require(amt != 0, "Not bought or already claimed");
        token.transfer(addr, amt);
        for(uint i = 0; i < len; i++){
            if(block.timestamp > claim[addr].claimTimes[i]) {
               claim[addr].claimWithdrawns[i] = true;
            }
        }
       
        emit Claimed(addr,amt, block.timestamp);
    }
    

    /// Show Buyer Details
    function depositList(address addr) public view returns(uint[] memory tarrif, uint[] memory amount, uint[] memory at){
        //require(msg.sender == owner, "Only owner");
      
        uint len = investors[addr].deposits.length;
        tarrif = new uint[](len);
        amount = new uint[](len);
        at = new uint[](len);
        for(uint i = 0; i < len; i++){
            tarrif[i] = investors[addr].deposits[i].tariff;
            amount[i] = investors[addr].deposits[i].amount;
            at[i] = investors[addr].deposits[i].at;
        }
        return (tarrif, amount, at);
    }



  

    // View details
    function claimDetailsAll(address addr) public view returns (uint,uint,uint,uint) {
        uint len = claim[addr].claimAmounts.length;
        uint totalAmount = 0;
        uint available = 0;
        uint withdrawn = 0;
        uint nextWithdrawnDate = 0;
        bool nextWithdrawnFound;
        for(uint i = 0; i < len; i++){
            totalAmount += claim[addr].claimAmounts[i];
            if(claim[addr].claimWithdrawns[i]==false){
                nextWithdrawnDate = (nextWithdrawnFound==false) ?  claim[addr].claimTimes[i] : nextWithdrawnDate;
                nextWithdrawnFound = true;
            }
            if(block.timestamp > claim[addr].claimTimes[i] && claim[addr].claimWithdrawns[i]==false){
                available += claim[addr].claimAmounts[i];
            }
            if(claim[addr].claimWithdrawns[i]==true){
                withdrawn += claim[addr].claimAmounts[i];
            }
        }
        return (totalAmount,available,withdrawn,nextWithdrawnDate);
    }

    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 _token = BEP20(tokenAddress);
        _token.transfer(to, amount);
    }
    
    // Owner MATIC Withdraw
    // Only owner can withdraw MATIC from contract
    function withdrawMATIC(address payable to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
    }

    // MATIC Price Update
    // Only owner can call this function
    function maticpriceChange() external {
        require(msg.sender == owner, "Only owner");
        priceOfMATIC = priceConsumerV3.getThePrice();
    }
}