/**
 *Submitted for verification at polygonscan.com on 2021-12-24
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

contract FundRaiseLaunchpadIDO{
    
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
    address referer;
    uint balanceRef;
    uint balanceRefWithdrawn;
    uint balanceRefWithdrawnAt;
    
  }

  struct Claim {
    uint[] claimAmounts;
    uint[] claimTimes;
    bool[] claimWithdrawns;
}

  address public buyTokenAddr;
  address public updater;
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

 
  

  address public owner = msg.sender;
  
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public claimStartTime;
  uint public totalRefRewards;
  bool public saleStatus;
  uint public referralClaimTime = 1647754200;  // Sunday, March 20, 2022 11:00:00 AM GMT+05:30
  uint public oneDay = 86400;
  
  
  mapping (address => Investor) public investors;
  mapping(address => Claim) claim;
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event OwnershipTransferred(address);
  event Claimed(address user,uint amount, uint time);
  event ClaimedReferral(address user,uint amount, uint time);
  
  constructor() {
        saleStatus = false;
        claimStartTime = 1642656600; // Thursday, January 20, 2022 11:00:00 AM GMT+05:30
        updater = msg.sender;
        for (uint i = 3; i >= 1; i--) {
            refRewards.push(i);
        }
  }



  function register(address referer) internal {
      
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
    
        if (investors[referer].registered && referer != msg.sender) {
            investors[msg.sender].referer = referer;
        }
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      uint refRewardPercent = 0;
      if(i==0){
          refRewardPercent = 3;
      }
      else if(i==1){
          refRewardPercent = 2;
      }
      else if(i==2){
          refRewardPercent = 1;
      }
      uint a = amount * refRewardPercent / 100;
      
      investors[rec].balanceRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  function buyTokenWithMATIC(address referer) external payable {

    require(saleStatus == true, "Sale has not started");  
    require(msg.value >= 0,"Invalid Amount");
    
   
    address sender = msg.sender;
    register(referer);
    
    (uint tariff, uint currentTokenPrice, uint currrentTokenPriceDecimal) = getTokenPrice();
    
    uint tokenVal = (msg.value * priceOfMATIC / (100000000/currrentTokenPriceDecimal)) / currentTokenPrice;
    
    investors[sender].invested += tokenVal;
    totalInvested += tokenVal;

    rewardReferers(tokenVal, investors[msg.sender].referer);

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

 
    function claimReferral() external {
        require(block.timestamp >= referralClaimTime ,"Claim Time not reached");
        uint referralAmt = investors[msg.sender].balanceRef;
        require(referralAmt>0,"Insufficient Referral Balance");
        BEP20 token = BEP20(buyTokenAddr);
        require(token.balanceOf(address(this)) >= referralAmt, "Insufficient amount on contract");
        token.transfer(msg.sender, referralAmt);
        investors[msg.sender].balanceRef = 0;
        investors[msg.sender].balanceRefWithdrawn = referralAmt;
        investors[msg.sender].balanceRefWithdrawnAt = block.timestamp;
        emit ClaimedReferral(msg.sender,referralAmt, block.timestamp);
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
  

    function setSaleStatus(bool status) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        saleStatus = status;
        
    }

    function updateOneDay(uint _oneDay) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        oneDay = _oneDay;
        
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
      require(msg.sender == owner || msg.sender == updater, "Permission error");
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
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        seedRoundStartTime   = _seedRoundStartTime;
         seedRoundEndTime     = _seedRoundEndTime;
    }

    function updateStrategicRoundTime(uint _strategicRoundStartTime, uint _strategicRoundEndTime) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        strategicRoundStartTime   = _strategicRoundStartTime;
        strategicRoundEndTime   = _strategicRoundEndTime;
    }

    function updatePrivateRoundTime(uint _privateRoundStartTime, uint _privateRoundEndTime) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        privateRoundStartTime   = _privateRoundStartTime;
        privateRoundEndTime   = _privateRoundEndTime;
    }

    function updatePublicRoundTime(uint _publicRoundStartTime, uint _publicRoundEndTime) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        publicRoundStartTime   = _publicRoundStartTime;
        publicRoundEndTime     = _publicRoundEndTime;
    }


    function setBuyTokenAddr(address _buyTokenAddr) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        buyTokenAddr = _buyTokenAddr;
    }

    function setClaimStartTime(uint _claimStartTime) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        claimStartTime = _claimStartTime;
    }

    function updateReferralClaimTime(uint _referralClaimTime) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        referralClaimTime = _referralClaimTime;
    }


   // Update claims for addresses with multiple entries
    function updateClaims(address addr, uint[] memory _amounts, uint[] memory _times) external {
        
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(_amounts.length == _times.length, "Array length error");

        Claim storage clm = claim[addr];
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
            clm.claimWithdrawns.push(false);
        }
        
    }
    
    // Update claims for multiple addresses with multiple entries
    function updateMultipleClaims(address[] memory multipleAddr, uint[][] memory _multipleAmounts, uint[][] memory _multipleTimes) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(multipleAddr.length == _multipleAmounts.length, "Array length error");
        require(_multipleAmounts.length == _multipleTimes.length, "Array length error");
        
        uint addrLength = multipleAddr.length;
        for(uint i = 0; i < addrLength; i++){
            require(_multipleAmounts[i].length == _multipleTimes[i].length, "Array length error");
            address addr = multipleAddr[i];
            Claim storage clm = claim[addr];
            
            uint len = _multipleAmounts[i].length;
            for(uint j = 0; j < len; j++){
                clm.claimAmounts.push(_multipleAmounts[i][j]);
                clm.claimTimes.push(_multipleTimes[i][j]);
                clm.claimWithdrawns.push(false);
            }
            
        }
    }    
    


    // Update claims for multiple addresses with multiple entries
    function updateMultipleClaimsWithSameTime(address[] memory multipleAddr, uint[][] memory _multipleAmounts, uint[] memory _multipleTimes) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(multipleAddr.length == _multipleAmounts.length, "Array length error");
        require(_multipleAmounts.length == _multipleTimes.length, "Array length error");
        
        uint addrLength = multipleAddr.length;
        for(uint i = 0; i < addrLength; i++){
           
            address addr = multipleAddr[i];
            Claim storage clm = claim[addr];
            
            uint len = _multipleAmounts[i].length;
            for(uint j = 0; j < len; j++){
                clm.claimAmounts.push(_multipleAmounts[i][j]);
                clm.claimTimes.push(_multipleTimes[j]);
                clm.claimWithdrawns.push(false);
            }
           
        }
    }  
   // add same claim to multiple addresses
    function updateClaimWithSameEntryForMultiAddress(address[] memory addr, uint[] memory amt, uint[] memory at) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(amt.length == at.length, "Array length error");
        
        for(uint i = 0; i <  addr.length; i++){
            address singleAddr = addr[i];
            for(uint j = 0; j < amt.length; j++){
                claim[singleAddr].claimAmounts.push(amt[j]);
                claim[singleAddr].claimTimes.push(at[j]);
                claim[singleAddr].claimWithdrawns.push(false);
            }
            
        }
    }

    // remove and update all chaims for single address
    function removeAndUpdateClaims(address addr, uint[] memory _amounts, uint[] memory _times) external {
        delete claim[addr];
        Claim storage clm = claim[addr];
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
            clm.claimWithdrawns.push(false);
        }
        
    }
    
    // Update entry for user at particular index 
    function indexValueUpdate(address addr, uint index, uint amount, uint _time) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        claim[addr].claimAmounts[index] = amount;
        claim[addr].claimTimes[index] = _time;
    }


    function buyFRLPManual(address addr,uint amt) external  {
    require(msg.sender == owner || msg.sender == updater, "Permission error");
    
   
    address sender = addr;
    
    (uint tariff, uint currentTokenPrice, uint currrentTokenPriceDecimal) = getTokenPrice();
    
    uint tokenVal = (amt * priceOfMATIC / (100000000/currrentTokenPriceDecimal)) / currentTokenPrice;
    
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


    // only by owner
    function changeUpdater(address _updater) external {
        require(msg.sender == owner, "Only owner");
        updater = _updater;
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


    function usd_price() public view returns (uint) {
        return priceOfMATIC;
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
}