//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";


interface StakeInterface {
    function totalvaluelocked(address account) external view returns(uint256);
}

contract PreSaleTier is ReentrancyGuard, Context, Ownable{
    using SafeMath for uint256;
    mapping(address => bool) private Claimed;
    mapping(address => uint256) private _valPreSale;
    
    IERC20 private _token = IERC20(0x53227c9DEfD4775E4C70F31130e67290EE0bC1fB); 
    StakeInterface private stakeCt;

    
    event PreSaleClaimed(address receiver, uint amount);
    event PreSaleContributed(address contributor, uint amount);
    
    uint public maxCap = 150 ether;
    uint public eth = 1 ether;

    //uint256 tier1MilkyAmount = 10 * 1000000 * 1 ether;
    //uint256 tier2MilkyAmount = 20 * 1000000 * 1 ether;
    //uint256 tier3MilkyAmount = 50 * 1000000 * 1 ether;
    
    uint256 tier1MilkyAmount = 10 * 1000 * 1 ether;
    uint256 tier2MilkyAmount = 20 * 1000 * 1 ether;
    uint256 tier3MilkyAmount = 50 * 1000 * 1 ether;

    //uint256 tier1BnbAmount = 0.4 * 1 ether;
    //uint256 tier2BnbAmount = 0.7 * 1 ether;
    //uint256 tier3BnbAmount = 1.2 * 1 ether;
    
    uint256 tier1BnbAmount = 0.04 * 1 ether;
    uint256 tier2BnbAmount = 0.07 * 1 ether;
    uint256 tier3BnbAmount = 0.12 * 1 ether;
    
    
    uint public minContribution = 0.01 ether;//0.1
    uint public maxContribution = 3 ether;//3
    
    constructor(address _stakeCt) {
        stakeCt = StakeInterface(_stakeCt);
    }
    
    
    uint public startDate = 1636864543; // Mon Oct 22 2021
    uint public endDate = startDate + 7 days;
    
    uint public soldToken = 0;
    uint public soldValue = 0;
    
    bool canClaim = false;
    
    uint public bnbRate = 6900000; // 6,900,000 MILKY per BNB

    mapping(address => bool) public letherListed;
    
    function batchAddWhitelisted(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            letherListed[addresses[i]] = true;
        }
    }
    
    function setToken(IERC20 tokenAddress) public onlyOwner{
        require(isPresaleLive() == false, 'dev: Pre sale started');
        _token = tokenAddress;
    }
    
    function setMaxCap(uint _maxCap) public onlyOwner{
        require(_maxCap >= soldValue, 'dev: You can only set a higher value as max cap');
        maxCap = _maxCap;
    }
    
    function setMinMaxContribution(uint _min, uint _max) public onlyOwner{
        require(_max >= _min, 'dev: You can only set a max larger equal min value');
        minContribution = _min;
        maxContribution = _max;
    }
    
    function setStartDate(uint _startDate) public onlyOwner{
        //require(isPresaleLive() == false, 'dev: Pre sale started');
        startDate = _startDate;
    }
    
    function setEndDate(uint _endDate) public onlyOwner{
        uint dateNow = block.timestamp;
        require(_endDate > startDate && _endDate >= dateNow, 'dev: Pre sale started');
        endDate = _endDate;
    }
    
    function getPreSaleTokens() public view{
        _token.balanceOf(address(this));
    }
    
    function getUserPreSaleTokens(address user) public view returns (uint){
        return _valPreSale[user];
    }
    
    function isPresaleLive() public view returns (bool){
        uint dateNow = block.timestamp;
        bool result = false;
        if ((dateNow >= startDate && dateNow < endDate) && (soldValue < maxCap)) {
            result = true;
        }
        return result;
    }
    
    function isPreSaleEnded() public view returns (bool){
        bool result = false;
        uint dateNow = block.timestamp;
        if(dateNow > endDate || soldValue >= maxCap) {
            result = true;
        }
        return result;
    }
    
    function withdraw() external onlyOwner {
         require(address(this).balance > 0, 'Contract has no money');
         address payable wallet = payable(msg.sender);
         wallet.transfer(address(this).balance);    
    }
    
    function setCanClaim(bool _canClaim) public onlyOwner{
        canClaim = _canClaim;
    }
    
    function claimTokens() public nonReentrant {
        require(canClaim == true, 'dev: You cannot claim the token yet!');
        require(Claimed[msg.sender] == false, 'dev: Pre sale already claimed!');
        if(_token.balanceOf(address(this)) == 0) { return;}
        Claimed[msg.sender] = true;
        uint256 amount = _valPreSale[msg.sender];
        _token.transfer(msg.sender, amount);
        emit PreSaleClaimed(msg.sender, amount);
    }
    
    function buyTokens() public payable{
        require(isPresaleLive() == true, 'dev: Pre sale not live!');
        require(msg.value >= minContribution && msg.value <= maxContribution, "dev: You cannot pay that amount!");
        require(_valPreSale[msg.sender] == 0, "dev: You cannot have multiple Entries!");
        require(soldValue + msg.value <= maxCap, "dev: cap reached");
        require(isTierMapping(msg.sender, msg.value), "dev: Sorry! You can not pay that amount with current tier!");
        uint _tokens = msg.value.mul(bnbRate);
        soldToken = soldToken.add(_tokens);
        soldValue = soldValue.add(msg.value);
        _valPreSale[msg.sender] = _tokens;
        emit PreSaleContributed(msg.sender, _tokens);
    }

    function isTierMapping(address user, uint256 amount) public view returns (bool){
        bool result = false;
        uint256 amountLocked = stakeCt.totalvaluelocked(user);
        if(letherListed[msg.sender] && amount <= tier3BnbAmount) {
            result = true;
        } else if (amountLocked >= tier1MilkyAmount && amount <= tier1BnbAmount) {
            result = true;
        } else if (amountLocked >= tier2MilkyAmount && amount <= tier2BnbAmount) {
            result = true;
        } else if (amountLocked >= tier3MilkyAmount && amount <= tier3BnbAmount) {
            result = true;
        }
        return result;
    }
    
    function getValueLocked(address user) public view returns (uint256){
        return stakeCt.totalvaluelocked(user);
    }
    
    function takeTokens()  public onlyOwner{
        uint256 tokenAmt = _token.balanceOf(address(this));
        require(tokenAmt > 0, 'ERC-20 balance is 0');
        address payable wallet = payable(msg.sender);
        _token.transfer(wallet, tokenAmt);
    }
}