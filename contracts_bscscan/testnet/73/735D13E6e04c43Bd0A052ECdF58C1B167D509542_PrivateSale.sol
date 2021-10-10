//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract PrivateSale is ReentrancyGuard, Context, Ownable{
    using SafeMath for uint256;
    mapping(address => bool) private Claimed;
    mapping(address => uint256) private _valPreSale;
    
    IERC20 private _token = IERC20(0xD38826add338Ba74E03a8A0B8A11B89FA4f916D9); // MilkyWayEx
    
    event PrivateSaleClaimed(address receiver, uint amount);
    event PrivateSaleContributed(address contributor, uint amount);
    
    uint public entries = 0;
    uint public maxEntries = 100;
    
    uint public minContribution = 1 ether;
    uint public maxContribution = 3 ether;
    
    uint startDate = 1633194000; // can change startdate here
    uint public endDate = startDate + 7 days;
    
    uint public soldToken = 0;
    uint public soldValue = 0;
    
    bool canClaim = false;
    
    uint public bnbRate = 10400000; // 10,400,000 MilkyWayEx per BNB
    
    
    function setToken(IERC20 tokenAddress) public onlyOwner{
        require(isPresaleLive() == false, 'dev: Private sale started');
        _token = tokenAddress;
    }
    
    function setMaxEntries(uint _maxEntries) public onlyOwner{
        require(_maxEntries >= entries, 'dev: You can only set a higher value as entries');
        maxEntries = _maxEntries;
    }
    
    function setMinMaxContribution(uint _min, uint _max) public onlyOwner{
        require(_max >= _min, 'dev: You can only set a max larger equal min value');
        minContribution = _min.mul(1 ether);
        maxContribution = _max.mul(1 ether);
    }
    
    function setStartDate(uint _startDate) public onlyOwner{
        //require(isPresaleLive() == false, 'dev: Private sale started');
        startDate = _startDate;
    }
    
    function setEndDate(uint _endDate) public onlyOwner{
        uint dateNow = block.timestamp;
        require(_endDate > startDate && _endDate >= dateNow, 'dev: Private sale started');
        endDate = _endDate;
    }
    
    function getPrivateSaleTokens() public view{
        _token.balanceOf(address(this));
    }
    
    function getUserPrivateSaleTokens(address user) public view returns (uint){
        return _valPreSale[user];
    }
    
    function isPresaleLive() public view returns (bool){
        uint dateNow = block.timestamp;
        bool result = false;
        if ((dateNow >= startDate && dateNow < endDate) && (entries < maxEntries)) {
            result = true;
        }
        return result;
    }
    
    function isPrivateSaleEnded() public view returns (bool){
        bool result = false;
        uint dateNow = block.timestamp;
        if(dateNow > endDate || entries >= maxEntries) {
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
        emit PrivateSaleClaimed(msg.sender, amount);
    }
    
    function contributePrivateSale() public payable{
        require(isPresaleLive() == true, 'dev: Private sale not live!');
        require(msg.value >= minContribution && msg.value <= maxContribution, "dev: You cannot pay that amount!");
        require(_valPreSale[msg.sender] == 0, "dev: You cannot have multiple Entries!");
        uint _tokens = msg.value.mul(bnbRate);
        soldToken = soldToken.add(_tokens);
        soldValue = soldValue.add(msg.value);
        entries = entries.add(1);
        _valPreSale[msg.sender] = _tokens;
        emit PrivateSaleContributed(msg.sender, _tokens);
    }
    
    function takeTokens()  public onlyOwner{
        uint256 tokenAmt = _token.balanceOf(address(this));
        require(tokenAmt > 0, 'ERC-20 balance is 0');
        address payable wallet = payable(msg.sender);
        _token.transfer(wallet, tokenAmt);
    }
}