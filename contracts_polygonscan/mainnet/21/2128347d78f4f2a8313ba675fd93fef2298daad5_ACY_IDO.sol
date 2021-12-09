/**
 *Submitted for verification at polygonscan.com on 2021-12-09
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

interface STAKE {
    function tierCount1() external view returns (uint);
    function tierCount2() external view returns (uint);
    function tierCount3() external view returns (uint);
    function tierCount4() external view returns (uint);
    function ongoingStakingStatus() external view returns (bool);
    function userStakeStastus(address) external view returns (bool);
    function details(address) external view returns(uint topTier, uint[] calldata amounts, uint[] calldata times, bool[] calldata withdrawStatus);
}

contract StakingDetails {
    
    STAKE public stakeGetter;
    
    constructor() {
        stakeGetter = STAKE(0x1843EC59C04ffbf349e21aBd317F6EC874DCAc9F); // live stake contract address
        
    }
    
    function oneCount() public view returns (uint) {
       return stakeGetter.tierCount1();
    }
    function twoCount() public view returns (uint) {
       return stakeGetter.tierCount2();
    }
    function threeCount() public view returns (uint) {
       return stakeGetter.tierCount3();
    }
    function fourCount() public view returns (uint) {
       return stakeGetter.tierCount4();
    }
    
    function stakeStatus(address addr) public view returns(bool){
        return stakeGetter.userStakeStastus(addr);
    }
    
    function getTopTier(address addr) public view returns (uint) {
        (
            uint topTier,
            uint[] memory amounts,
            uint[] memory times,
            bool[] memory withdrawStatus
        ) = stakeGetter.details(addr);
            
        return topTier;
    }
}

contract ACY_IDO {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfMATIC = priceConsumerV3.getThePrice();
    
    struct Buyer{
        bool buyStatus;
        uint totalTokensBought;
        Bought[] bought;
    }
    
    struct Bought {
        uint tokenBought;
        uint at;
    }
    
    struct Claim {
        uint[] claimAmounts;
        uint[] claimTimes;
    }
    
    StakingDetails stakeDetails = new StakingDetails();
    
    
    uint public tier1Number = stakeDetails.oneCount();
    uint public tier2Number = stakeDetails.twoCount();
    uint public tier3Number = stakeDetails.threeCount();
    uint public tier4Number = stakeDetails.fourCount();
    
    uint public totalAllocation = 325000 * 10**18;
    uint public tier1Alloc = 48750 * 10**18;
    uint public tier2Alloc = 81250 * 10**18;
    uint public tier3Alloc = 81250 * 10**18;
    uint public tier4Alloc = 81250 * 10**18;
    
    mapping(address => uint) public userAlloc;
    address public owner = msg.sender;
    address public claimTokenAddr; 
    
    address public contractAddr = address(this);
    uint public buyPrice;
    uint public buyPriceDecimal;
    mapping(address => Buyer) public buyer;
    mapping(address => Claim) claim;
    bool public saleStatus;
    uint public saleEndTime;
    address public updater;
    uint public time;

    address[] public userList;
    
    event Received(address, uint);
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    
    constructor() {
        buyPrice = 2;
        saleStatus = false;
        time = 1639747800; // Friday, December 17, 2021 7:00:00 PM GMT+05:30
        buyPriceDecimal = 10;
    }
    
    /// Fetch user top tier
    function getUserTier(address addr) public view returns(uint){
        return stakeDetails.getTopTier(addr);
    }
    
    function updateLiveMaticPrice() public returns(bool) {
          priceOfMATIC = priceConsumerV3.getThePrice();
          return true;
    }    
    
    /**
     * @dev Buy token 
     * 
     * Requirements:
     * USD amount should be between 50 and 500
     * totalAllocation cannot be overflown
     * saleStatus has to be true
     * cannot send zero value transaction
     */
     
     
    function buyToken() public payable returns(bool) {
        
        bool userStakeStatus = stakeDetails.stakeStatus(msg.sender);
        address sender = msg.sender;
        // uint amount = msg.value * priceOfMATIC / 10*10**18;
        uint userTier = getUserTier(sender);
        // uint time = block.timestamp;
        
        uint tokens = (msg.value * priceOfMATIC / (100000000/buyPriceDecimal)) / buyPrice;
        uint claimAmountFirst = tokens * 30 / 100;
        uint claimAmountSecond = tokens * 2333 / 10000;
        
        require(saleStatus == true, "Sale not started or has finished");
        require(msg.value > 0, "Zero value");
        require(userStakeStatus == true,"Not staked");
        
        if(userTier == 0){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier1Alloc / tier1Number;
                require(tokens <= userAlloc[sender], "User allocation error1");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error2");
                userAlloc[sender] -= tokens;
            }
            
        }
        else if(userTier == 1){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier2Alloc / tier2Number;
                require(tokens <= userAlloc[sender], "User allocation error3");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error4");
                userAlloc[sender] -= tokens;
            }
        }
        else if(userTier == 2){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier3Alloc / tier3Number;
                require(tokens <= userAlloc[sender], "User allocation error5");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error6");
                userAlloc[sender] -= tokens;
            }
        }
        else if(userTier == 3){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier4Alloc / tier4Number;
                require(tokens <= userAlloc[sender], "User allocation error7");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error8");
                userAlloc[sender] -= tokens;            
                
            }
        }
        
        claim[sender].claimAmounts.push(claimAmountFirst);
        claim[sender].claimAmounts.push(claimAmountSecond);
        claim[sender].claimAmounts.push(claimAmountSecond);
        claim[sender].claimAmounts.push(claimAmountSecond);
       
        
        claim[sender].claimTimes.push(time);
        claim[sender].claimTimes.push(time + 30 days);
        claim[sender].claimTimes.push(time + 60 days);
        claim[sender].claimTimes.push(time + 90 days);
        
        if(buyer[sender].buyStatus == false){
            userList.push(sender);
        }
        buyer[sender].bought.push(Bought(tokens, block.timestamp));
        buyer[sender].totalTokensBought += tokens;
        buyer[sender].buyStatus = true;
        
        emit TokensBought(sender, tokens);
        return true;
    }
    
    // Set buy price 
    // Upto _price = 3, _price_decimal = 1000 then actual price = 0.0003
    function setBuyPrice(uint _price,uint _price_decimal) public {
        require(msg.sender == owner, "Only owner");
        buyPrice = _price;
        buyPriceDecimal = _price_decimal;
    }
    
    
    function setTierMemberCount() public {
        require(msg.sender == owner, "Only owner");
       
        tier1Number = stakeDetails.oneCount();
        tier2Number = stakeDetails.twoCount();
        tier3Number = stakeDetails.threeCount();
        tier4Number = stakeDetails.fourCount();
    }
    
    
    // View tokens for bnb
    function getTokens(uint maticAmt) public view returns(uint tokens) {
        
        tokens = (maticAmt * priceOfMATIC / (100000000/buyPriceDecimal)) / buyPrice;
        return tokens;
    }
    
    // View tokens for busd
    function getTokensForBusd(uint busdAmount) public view returns(uint tokens) {
        
        tokens = busdAmount / buyPrice * buyPriceDecimal;
        return tokens;
    }
    
    
    /** 
     * @dev Set sale status
     * 
     * Only to temporarily pause sale if necessary
     * Otherwise use 'endSale' function to end sale
     */
    function setSaleStatus(bool status) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        saleStatus = status;
        return true;
    }
    
    // user stake status
    function stakeStat(address addr) public view returns(bool){
        bool status = stakeDetails.stakeStatus(addr);
        return status;
    }
    
    /** 
     * @dev End presale 
     * 
     * Requirements:
     * 
     * Only owner can call this function
     */
    function endSale() public returns (bool) {
        require(msg.sender == owner, "Only owner");
        saleStatus = false;
        saleEndTime = block.timestamp;
        return true;
    }
    
    /// Set claim token address
    function setClaimTokenAddress(address addr) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        claimTokenAddr = addr;
        return true;
    }
    
    /// Set first claim time 
    function setFirstClaimTime(uint _time) public {
        require(msg.sender == owner, "Only owner");
        time = _time;
    }
    
    /** 
     * @dev Claim tokens
     * 
     */
    function claimTokens(uint index) public returns (bool) {
        require(claimTokenAddr != address(0), "Claim token address not set");
        BEP20 token = BEP20(claimTokenAddr);
        Claim storage _claim = claim[msg.sender];
        uint amount = _claim.claimAmounts[index];
        require(buyer[msg.sender].buyStatus == true, "Not bought any tokens");
        require(block.timestamp > _claim.claimTimes[index], "Claim time not reached");
        require(_claim.claimAmounts[index] != 0, "Already claimed");
        token.transfer(msg.sender, amount);
        delete _claim.claimAmounts[index];
        return true;
    }
    
    
    // Update claims for addresses with multiple entries
    function updateClaims(address addr, uint[] memory _amounts, uint[] memory _times) public {
        Claim storage clm = claim[addr];
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
        }
        if(buyer[addr].buyStatus == false){
            userList.push(addr);
        }
        buyer[addr].buyStatus = true;
    }
    
    // Update claims for multiple addresses with multiple entries
    function updateMultipleClaims(address[] memory multipleAddr, uint[][] memory _multipleAmounts, uint[][] memory _multipleTimes) public {
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
            }
            if(buyer[addr].buyStatus == false){
                userList.push(addr);
            }
            buyer[addr].buyStatus = true;
        }
    }    
    
   // add same claim to multiple addresses
    function updateClaimWithSameEntryForMultiAddress(address[] memory addr, uint[] memory amt, uint[] memory at) public {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(amt.length == at.length, "Array length error");
        
        for(uint i = 0; i <  addr.length; i++){
            address singleAddr = addr[i];
            for(uint j = 0; j < amt.length; j++){
                claim[singleAddr].claimAmounts.push(amt[j]);
                claim[singleAddr].claimTimes.push(at[j]);
            }
            if(buyer[singleAddr].buyStatus == false){
                userList.push(singleAddr);
            }
            buyer[singleAddr].buyStatus = true;
        }
    }
    
    // remove and update all chaims for single address
    function removeAndUpdateClaims(address addr, uint[] memory _amounts, uint[] memory _times) public {
        delete claim[addr];
        Claim storage clm = claim[addr];
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
        }
        if(buyer[addr].buyStatus == false){
            userList.push(addr);
        }
        buyer[addr].buyStatus = true;
    }
    
    // Update entry for user at particular index 
    function indexValueUpdate(address addr, uint index, uint amount, uint _time) public {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        claim[addr].claimAmounts[index] = amount;
        claim[addr].claimTimes[index] = _time;
    }
    
    // Set updater address 
    function setUpdaterAddress(address to) public {
        require(msg.sender == owner, "Only owner");
        updater = to;
    }
    
    /// Tier allocation left 
    function getTier1Allocation() public view returns(uint) {
        return tier1Alloc;
    }
    
    function getTier2Allocation() public view returns(uint) {
        return tier2Alloc;
    }
    
    function getTier3Allocation() public view returns(uint) {
        return tier3Alloc;
    }
    
    function getTier4Allocation() public view returns(uint) {
        return tier4Alloc;
    }
    
    /// Get user allocation left
    function userAllocationLeft(address user) public view returns(uint amount) {
        uint tier = getUserTier(user);
        bool staked = stakeStat(user);
        
        if(staked == false){
            amount = 0;
        }
        else{
            if(userBuyStatus(user) == false){
                if(tier == 0){
                    amount = tier1Alloc / tier1Number;
                }
                else if(tier ==1){
                    amount = tier2Alloc / tier2Number;
                }
                else if(tier == 2){
                    amount = tier3Alloc / tier3Number;
                }
                else if(tier == 3){
                    amount = tier4Alloc / tier4Number;
                }
            }
            else{
                amount = userAlloc[user];
            }
        }
        return amount;
    }
    
    /// Return tier number values
    function tier1Count() public view returns (uint){
        return tier1Number;
    }
    
    function tier2Count() public view returns (uint){
        return tier2Number;
    }
    
    function tier3Count() public view returns (uint){
        return tier3Number;
    }
    
    function tier4Count() public view returns (uint){
        return tier4Number;
    }
    
    /// View owner address
    function getOwner() public view returns(address){
        return owner;
    }
    
    /// View sale end time
    function viewSaleEndTime() public view returns(uint) {
        return saleEndTime;
    }
    
    /// View Buy Price
    function viewPrice() public view returns(uint){
        return buyPrice;
    }
    
    /// Return bought status of user
    function userBuyStatus(address user) public view returns (bool) {
        return buyer[user].buyStatus;
    }
    
    /// Return sale status
    function showSaleStatus() public view returns (bool) {
        return saleStatus;
    }
    
    /// Return updater address
    function viewUpdater() public view returns (address) {
        return updater;
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


    function claimDetailsAll() public view returns(address[] memory addresses,uint[][] memory amounts, uint[][] memory times){
        uint mainArrLength = userList.length;
        amounts = new uint[][](mainArrLength);
        times = new uint[][](mainArrLength);
        for(uint j=0; j < mainArrLength; j++){
            address addr = userList[j];
            uint len = claim[addr].claimAmounts.length;
            uint[] memory amountsInner = new uint[](len);
            uint[] memory  timesInner = new uint[](len);
            for(uint i = 0; i < len; i++){
                amountsInner[i] = claim[addr].claimAmounts[i];
                timesInner[i] = claim[addr].claimTimes[i];
            }
            amounts[j]=amountsInner;
            times[j]=timesInner;
            
            
        }
        addresses = userList;
        return (addresses,amounts, times);
    }
     
    /// Show USD Price of 1 MATIC
    function usdPrice(uint amount) external view returns(uint) {
        uint maticAmt = amount * priceOfMATIC;
        return maticAmt/100000000;
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
    
    // Owner wMATIC Withdraw
    // Only owner can withdraw wMATIC from contract
    function withdrawMATIC(address payable to, uint amount) public returns(bool) {
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