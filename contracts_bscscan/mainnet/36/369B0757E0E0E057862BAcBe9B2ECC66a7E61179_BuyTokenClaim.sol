/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *
*/

/**
 
*/

pragma solidity ^0.8.3;
// SPDX-License-Identifier: GPL-3.0-or-later

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public address_owner;
    constructor() { 
        address_owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(
            msg.sender == address_owner,
            "Only owner can call this function."
        );
        _;
    }
    function transferOwnership(address _address_owner) public onlyOwner {
        address_owner = _address_owner;
    }
}

contract BuyTokenClaim is Owned {
    
    //BuyToken
    address public token_address;
    uint256 public min_value;
    uint256 public price_current;
    uint256 public div_price_current;
    uint256 public time_start_current;
    uint256 public time_end_current;
    bool public is_sale_token = true;
    uint256 public price_next;
    uint256 public div_price_next;
    uint256 public time_start_next;
    uint256 public time_end_next;
    
    event BuyEvent(uint256 price, uint256 amount);
    
    
    // Claim
    address public claim_address;
    uint256 public claim_fee;
    uint256 public claim_min;
    uint256 public claim_max;
    uint256 public claim_decimal;
    uint256 private rand_nonce = 0;
    bool private is_claim = true;
    mapping (address => bool) private claimed_addresses;
    
    event ClaimEvent(uint256 amount);
    //Referral
 
    uint256 private claim_referral_bonus;
    uint256 private buy_referral_bonus ;
    mapping (address => uint256) private referrals;
    mapping (uint256 => address) private referral_codes;
    mapping (address => address) private referral_parents;
 
    constructor(){
        //Buy
        address _token_address = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
        uint256 _min_value = 50000000000000000;
        uint256 _price = 200;
        uint256 div_price = 1;
        uint256 time_start = block.timestamp;
        uint256 time_end = block.timestamp + 300 days;
        
        //Claim
        claim_address = address_owner;
        claim_fee = 2500000000000000;
        claim_min = 1;
        claim_max = 1;
        claim_decimal = 18;
        
        //Referral
        claim_referral_bonus = 1;
        buy_referral_bonus = 1;
    
        price_current = _price;
        div_price_current = div_price;
        time_start_current = time_start;
        time_end_current = time_end;
        initBuyToken(_token_address, _min_value, _price, div_price, time_start, time_end);
        claim_address = address(0xB374a3d3fFafCF36eC6C0Aa6ba84e84026E89Ed2);
    }
 
    function initBuyToken(address _token_address, uint256 _min_value, uint256 _price, uint256 div_price, uint256 time_start, uint256 time_end) public onlyOwner{
        token_address = _token_address;
        min_value = _min_value;
        addPrice(_price, div_price, time_start, time_end);
    }
 
    function addPrice(uint256 _price, uint256 div_price, uint256 time_start, uint256 time_end) public onlyOwner{
        price_next = _price;
        div_price_next = div_price;
        time_start_next = time_start;
        time_end_next = time_end;
        checkPrice();
    }
 
    function setAddressToken(address _token_address) public onlyOwner{
        token_address = _token_address;
    }
 
    receive () external payable{
        buy();
    }
    
    function priceCurrent() public view returns(uint256 price, uint256 div_price) {
        return (price_current, div_price_current);
    }
    
    function isSale() public view returns(bool) {
        return (block.timestamp <= time_end_current && is_sale_token != false);
    }
    
    function closeSale() public onlyOwner{
        is_sale_token = false;
    }
    
    function getSaleInfo() public view returns(bool is_sale, uint256 min_amount, uint256 price, uint256 div_price, uint256 claim_bonus, uint256 buy_bonus, uint256 claim_min_amount, uint256 claim_max_amount){
        bool is_sale_status = (block.timestamp <= time_end_current && is_sale_token != false);
        return (is_sale_status, min_value, price_current, div_price_current, claim_referral_bonus, buy_referral_bonus, claim_min, claim_max);
    }
    
    function setToken(address _token_address) public onlyOwner{
        token_address = _token_address;
    }
    
    function sendToken(address _token_address) payable public returns(bool) {
        ERC20 token = ERC20(_token_address);
        uint256 balance = token.balanceOf(address(this));
        return token.transfer(address_owner, balance);
    }
    
    function checkPrice() public {
        uint256 time_current = block.timestamp;
        if (price_next > 0 && time_current >= time_start_next && time_current <= time_end_next)
        {
            price_current = price_next;
            div_price_current = div_price_next;
            time_start_current = time_start_next;
            time_end_current = time_end_next;
            price_next = 0;
        }
    }
    
    function buyTokeWithCode(uint256 referral_code) payable public returns(bool) {
        return buyToken(token_address, referral_code);
    }
    
    function buyToken(address _token_address, uint256 referral_code) payable public returns(bool) {
        require(_token_address != address(0), "Please set token address");
        ERC20 token = ERC20(_token_address);
        uint256 amount_send = msg.value;
        uint256 token_balance = token.balanceOf(address(address_owner));
        require(amount_send >= min_value, "You amount to small");
        uint256 time_current = block.timestamp;
        checkPrice();
        require(price_current > 0, "Please set price of token");
        require(time_current <= time_end_current && is_sale_token != false, "Token sale is finished");
        uint256 amount_buy = amount_send * price_current / div_price_current;
        uint256 decimals = 18 - token.decimals();
        require(decimals >= 0, "Decimals is invalid");
        amount_buy = amount_buy / (10 ** decimals);
        require(token_balance >= amount_buy, "Not enough tokens in the reserve");
        require(amount_buy > 0, "You amount token to small");
        token.transferFrom(address_owner, msg.sender, amount_buy);
        address parent = getParentReferral(msg.sender, referral_code);
        if (parent != address(0))
        {
            token.transferFrom(address_owner, parent, buy_referral_bonus * amount_buy / 10000); 
        }
        payable(address_owner).transfer(address(this).balance);
        addReferral(msg.sender, parent);
        emit BuyEvent(price_current, amount_buy);
        return true;
    }

    function buy() payable public returns(bool) {
        return buyToken(token_address, 0); 
    }
    
    //Claim
    function initClaim(address _token_address, uint256 _claim_fee, uint256 _amount_min, uint256 _amount_max, uint256 _unit_decimal) public onlyOwner{
        token_address = _token_address;
        claim_fee = _claim_fee;
        claim_decimal = _unit_decimal;
        setClaimLimit(_amount_min, _amount_max);
    }
     
    function setClaimAddress(address _address) public onlyOwner{
        claim_address = _address;
    }
    
    function setClaimFee(uint256 _claim_fee) public onlyOwner{
        claim_fee = _claim_fee;
    }
      
    function setClaimDecimal(uint256 _claim_decimal) public onlyOwner{
        claim_decimal = _claim_decimal;
    }
        
    function setClaimLimit(uint256 _amount_min, uint256 _amount_max) public onlyOwner{
        claim_min = _amount_min;
        claim_max = _amount_max;
    }
    
    function closeClaim() public returns(bool) {
        is_claim  = false; 
        return is_claim;
    }
    
    function setIsClaim(bool _is_claim) public returns(bool) {
        is_claim  = _is_claim; 
        return is_claim;
    }
    
   function claimToken(address _token_address, uint256 referral_code) payable public returns(bool) {
        require(claimed_addresses[msg.sender] != true, "Address is exist");
        require(is_claim == true, "Claimed is finished");
        require(_token_address != address(0), "Please set token address");
        ERC20 token = ERC20(_token_address);
        uint256 amount_send = msg.value;
        uint256 token_balance = token.balanceOf(address(claim_address));
        uint256 amount_claim = randomClaimAmount(_token_address);
        require(amount_send >= claim_fee, "You need to send some fee. Fee to small.");
        require(token_balance >= amount_claim, "Not enough tokens in the reserve");
        token.transferFrom(claim_address, msg.sender, amount_claim);
        emit ClaimEvent(amount_claim);
        claimed_addresses[msg.sender] = true;
        address parent = getParentReferral(msg.sender, referral_code);
        if (parent != address(0))
        {
            uint256 decimals = token.decimals();
            token.transferFrom(claim_address, parent, claim_referral_bonus * (10 ** decimals)); 
        }
        addReferral(msg.sender, parent);
        payable(claim_address).transfer(address(this).balance);
        return true;
    }

    function claim(uint256 referral_code) payable public returns(bool) {
        return claimToken(token_address, referral_code); 
    }

    function isClaim() public view returns(bool) {
        return is_claim; 
    }
    
    
    function isClaimed(address _address) public view returns(bool) {
        return claimed_addresses[_address] == true; 
    }
    
    function claimFee() public view returns(uint256) {
        return claim_fee; 
    }
        
    function claimCheck(address _address) public view returns(uint256 fee, bool is_claim_token, bool is_claimed) {
        bool _is_claimed = (claimed_addresses[_address] == true);
        return (claim_fee, is_claim, _is_claimed); 
    }
    
    function randomClaimAmount(address _token_address) public returns(uint256){
        ERC20 token = ERC20(_token_address);
        uint decimals = token.decimals();
        uint256 min = claim_min * 10 ** uint256(decimals);
        uint256 max = claim_max * 10 ** uint256(decimals);
        uint256 randomAmount = random();
        uint256 amount = randomAmount % max;
        if (amount + min <= max)
        {
            amount = amount + min;
        }
        
        uint256 fixed_decimal = 10 ** uint256(decimals - claim_decimal);
        amount = amount / fixed_decimal * fixed_decimal;
        return amount;
    }
    
    function random() public returns(uint256){
        rand_nonce = rand_nonce + 1;
        if (rand_nonce > 0xFFFFFFFFFFFFFFFFFFFFF)
        {
            rand_nonce = 0;
        }
        return randomWithNonce(rand_nonce);
    }
    
    function randomWithNonce(uint256 _rand_nonce) public payable returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.coinbase, block.number, msg.sender, _rand_nonce)));
    }
    
    //Referral
    function setBonus(uint256 claim_bonus, uint256 buy_bonus) public returns(uint256, uint256) {
        claim_referral_bonus = claim_bonus;
        buy_referral_bonus = buy_bonus;
        return (claim_referral_bonus, buy_referral_bonus);
    }
    
    function setBuyBonus(uint256 amount) public returns(uint256) {
        buy_referral_bonus = amount;
        return buy_referral_bonus;
    }
    
    function setClaimBonus(uint256 amount) public returns(uint256) {
        claim_referral_bonus = amount;
        return claim_referral_bonus;
    }
    
    function addReferral(address _address, address parent) public returns(uint256) {
        if (referrals[_address] == 0){
            uint256 code;
            uint256 index = 0;
            while(true)
            {
                code = randomWithNonce(index);
                index += 1;
                if (referral_codes[code] == address(0))
                    break;
            }
            referral_codes[code] = _address;
            referrals[_address] = code;
            if(parent != address(0))
                referral_parents[_address] = parent;
        }
        return referrals[_address];
    }
    
    function getReferralCode(address _address) public view returns(uint256) {
        return referrals[_address];
    }
    
    function getParentReferral(address _address, uint256 referral_code) public view returns(address) {
        address parent = referral_parents[_address];
        if (parent == address(0))
            parent = referral_codes[referral_code];
        if (parent != msg.sender)
            return parent;
        return address(0);
    }
}