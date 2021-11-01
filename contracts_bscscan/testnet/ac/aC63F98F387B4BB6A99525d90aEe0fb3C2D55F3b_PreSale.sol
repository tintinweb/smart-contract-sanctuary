//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract PreSale is ReentrancyGuard, Context, Ownable{
    using SafeMath for uint256;
    mapping(address => bool) private Claimed;
    mapping(address => uint256) private _valPreSale;
    
    IERC20 private _token = IERC20(0x70e450b8A8f64343bf47786a090198A0Fe573509); 
    
    event PreSaleClaimed(address receiver, uint amount);
    event PreSaleContributed(address contributor, uint amount);
    
    uint public maxCap = 150 ether;
    uint public eth = 1 ether;
    
    uint public minContribution;
    bool public isWhitelistEnabled = false;
    
    constructor(bool _whitelist) {
        minContribution = 0.1 ether;
        isWhitelistEnabled = _whitelist;
        whitelisted[msg.sender] = true;
    }
    
    uint public maxContribution = 3 ether;
    
    uint startDate = 1634906346; // Mon Oct 22 2021
    uint public endDate = startDate + 7 days;
    
    uint public soldToken = 0;
    uint public soldValue = 0;
    
    bool canClaim = false;
    
    uint public bnbRate = 6900000; // 6,900,000 MILKY per BNB

    mapping(address => bool) public whitelisted;
    
    event WhitelistChanged(bool newEnabled);
    
    function batchAddWhitelisted(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }
    
    function setToken(IERC20 tokenAddress) public onlyOwner{
        require(isPresaleLive() == false, 'dev: Private sale started');
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
        require(isPresaleLive() == false, 'dev: Private sale started');
        startDate = _startDate;
    }
    
    function setEndDate(uint _endDate) public onlyOwner{
        uint dateNow = block.timestamp;
        require(_endDate > startDate && _endDate >= dateNow, 'dev: Private sale started');
        endDate = _endDate;
    }
    
    function setWhitelistEnabled(bool enabled) public onlyOwner {
        isWhitelistEnabled = enabled;
        emit WhitelistChanged(enabled);
    }
    
    function getPrivateSaleTokens() public view{
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
        require(Claimed[msg.sender] == false, 'dev: Private sale already claimed!');
        if(_token.balanceOf(address(this)) == 0) { return;}
        Claimed[msg.sender] = true;
        uint256 amount = _valPreSale[msg.sender];
        _token.transfer(msg.sender, amount);
        emit PreSaleClaimed(msg.sender, amount);
    }
    
    function buyTokens() public payable{
        require(isPresaleLive() == true, 'dev: Private sale not live!');
        require(msg.value >= minContribution && msg.value <= maxContribution, "dev: You cannot pay that amount!");
        require(_valPreSale[msg.sender] == 0, "dev: You cannot have multiple Entries!");
        require(!isWhitelistEnabled || whitelisted[msg.sender], "dev: not in whitelist");
        require(soldValue + msg.value <= maxCap, "dev: cap reached");
        uint _tokens = msg.value.mul(bnbRate);
        soldToken = soldToken.add(_tokens);
        soldValue = soldValue.add(msg.value);
        _valPreSale[msg.sender] = _tokens;
        emit PreSaleContributed(msg.sender, _tokens);
    }
    
    function takeTokens()  public onlyOwner{
        uint256 tokenAmt = _token.balanceOf(address(this));
        require(tokenAmt > 0, 'ERC-20 balance is 0');
        address payable wallet = payable(msg.sender);
        _token.transfer(wallet, tokenAmt);
    }
}