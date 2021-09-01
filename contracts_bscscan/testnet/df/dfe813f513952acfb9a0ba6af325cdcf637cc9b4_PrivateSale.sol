/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

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

contract PrivateSale {
    
    struct Buyer{
        address referer;
        uint tokensBought;
        bool registered;
    }
    
    struct Referral{
        bool refReg;
        uint referred;
        address[] referredUsers;
    }
    
    struct Scratch{
        uint[] tokenAmt;
        uint[] buyAt;
        bool claimed;
    }
    
    address public owner = msg.sender;
    //address private tokenAddr = 0xAe67Cf598a349aFff89f6045108c6C1850f82839; //Mainnet Token
    address private tokenAddr = 0x735b205D72F7F49974Baa06A9F518907C7e08737; //Testnet Token
    address private contractAddr = address(this);
    uint buyPrice;
    uint bonusPercent;
    uint startTime = 0;
    uint scratchAmount = 0;
    uint minimumTokenForScratch = 0;
    uint private priceOfBNB;
    address private priceSetter;
    
    
    mapping(address => Buyer) buyer;
    mapping(address => Scratch) scratch;
    mapping(address => Referral) ref;
    
    event Received(address, uint);
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    event Airdrop(address[], uint);
    
    // Set Start Time
    function setStartTime() public {
        require(msg.sender == owner, "Only owner");
        startTime = block.timestamp;
    }
    
    // Set price of BNB in usd 
    function setUsdPrice(uint _price) public {
        require(msg.sender == owner || msg.sender == priceSetter, "Only owner or priceSetter can call this function");
        priceOfBNB = _price;
    }
    
    // BUY TOKEN & Referral Reward
    function buyToken(address referer) public payable returns(bool) {
        
        uint amount = msg.value * priceOfBNB / 10000;
        buyPrice = buyPrice;
        
        BEP20 token = BEP20(tokenAddr);
        
        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(token.balanceOf(contractAddr) > 0, "Not enough balance on contract");
        require(msg.value > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        
        uint tokens;
        uint bonus;
        
        tokens = amount / buyPrice / 100;
        token.transfer(msg.sender, tokens);
        
        if(bonusPercent == 0){
            bonus = 0;
        }
        else if(bonusPercent != 0){
            bonus = tokens * bonusPercent / 100;
            token.transfer(msg.sender, bonus);
        }
        
        refReward(referer, tokens);

        buyer[msg.sender].tokensBought += tokens;
        buyer[msg.sender].registered = true;
        if(buyer[msg.sender].referer == address(0)){
            buyer[msg.sender].referer = referer;
        }

        scratch[msg.sender].tokenAmt.push(tokens);
        scratch[msg.sender].buyAt.push(block.timestamp);
        scratch[msg.sender].claimed = false;
        
        emit TokensBought(msg.sender, tokens);
        return true;
    }
    
    // Set Buy Price
    function setBuyPrice(uint price) public returns(bool) {
        require(msg.sender == owner,"Only owner");
        buyPrice = price;
        return true;
    }
    
    // Set bonus percent
    function setBonus(uint bonus) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        bonusPercent = bonus;
        return true;
    }
    
    // Referral Reward
    function refReward(address _ref, uint _amt) internal {
        
        uint referralReward;
        BEP20 token = BEP20(tokenAddr);
        
        if(!buyer[_ref].registered){
            referralReward = 0;
        }
        else{
            referralReward = _amt * 5 / 100;
            token.transfer(_ref, referralReward);
        }
        
        if(!ref[_ref].refReg){
            ref[_ref].refReg = true;
            ref[_ref].referred += 1;
            ref[_ref].referredUsers.push(msg.sender);
        }
        else if(ref[_ref].refReg == true){
            ref[_ref].referred += 1;
            ref[_ref].referredUsers.push(msg.sender);
        }
            
    }
    
    // View Buy Price
    function viewPrice() public view returns(uint){
        return buyPrice;
    }
    
    // Set minimum token limit for Scratch
    function minTokenForScratch(uint amount) public {
        require(msg.sender == owner, "Only owner");
        amount = amount * 10**18;
        minimumTokenForScratch = amount;
    }
    
    // View minimum token required for Scratch
    function viewMinLimit() public view returns(uint) {
        return minimumTokenForScratch;
    }
    
    // Set Scratch Amount
    function setScratchAmount(uint amount) public {
        require(msg.sender == owner, "Only owner");
        scratchAmount = amount * 10**18;
    }
     
    // View scratch amount
    function viewScratchAmount() public view returns(uint) {
        return scratchAmount;
    }
    
    // Claim Scratch Coupon tokens
    function claim() public returns (bool) {
        require(scratch[msg.sender].claimed == false, "User has already claimed tokens");
        require(minimumTokenForScratch != 0, "Minimum limit not set");
        require(buyer[msg.sender].tokensBought > minimumTokenForScratch, "Not eligible for scratch");
        require(scratchAmount != 0, "Scratch amount not set");
        BEP20 token = BEP20(tokenAddr);
        token.transfer(msg.sender, scratchAmount);
        scratch[msg.sender].claimed = true;
        return true;
    }
    
    // Update buyer Details
    function updateBuyerDetails(address user,
    address[] memory _referrals,
    address _referer,
    uint _tokensBought,
    uint[] memory _tokenBuy,
    uint[] memory _buyTime,
    bool _scratch
    )
    public returns (bool){
        require(msg.sender == owner, "Only owner");
        buyer[user].tokensBought = _tokensBought;
        buyer[user].registered = true;
        if(buyer[user].referer == address(0)){
            buyer[user].referer = _referer;
        }
        
        for(uint i = 0; i < _referrals.length; i++){
            ref[user].referredUsers.push(_referrals[i]);
        }
        
        for(uint j = 0; j < _tokenBuy.length; j++){
            scratch[user].tokenAmt.push(_tokenBuy[j]);
            scratch[user].buyAt.push(_buyTime[j]);
            scratch[user].claimed = _scratch;
        }
        
        return true;
    }
    
    // Show Buyer Details
    function buyerDetails(address user) public view returns(bool, address, uint, uint[] memory, uint[] memory, bool){
        bool reg = buyer[user].registered;
        address referer = buyer[user].referer;
        uint totalTokensBought = buyer[user].tokensBought;
        uint[] memory tokensBought = new uint[](scratch[user].tokenAmt.length);
        uint[] memory buyTime = new uint[](scratch[user].tokenAmt.length);
        
        for(uint i = 0; i< scratch[user].tokenAmt.length; i++){
            tokensBought[i] = scratch[user].tokenAmt[i];
            buyTime[i] = scratch[user].buyAt[i];
        }
        
        bool claimStatus = scratch[user].claimed;
        
        return (reg, referer, totalTokensBought, tokensBought, buyTime, claimStatus);
    }
    
    // View Current Bonus
    function viewBonusPercent() public view returns (uint) {
        return bonusPercent;
    }
    
    // Show referred users
    function referred(address user) public view returns(uint, address[] memory){
        uint refNum = ref[user].referred;
        address[] memory users = new address[](ref[user].referredUsers.length);
        
        for(uint i = 0; i < ref[user].referredUsers.length; i++){
            users = ref[user].referredUsers; 
        }
        
        return (refNum, users);
    }
    
    // Show USD Price of 1 BNB
    function usdPrice() external view returns(uint) {
        uint Amount = priceOfBNB;
        return Amount/100000000;
    }
    
    // Owner Token Withdraw    
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer    
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner);
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}