/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


interface IToken {
     function decimals() external view returns (uint256);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract TATPresale is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    address public tokenAddress = 0xA9A56CF6A0c73F6Ba27b19e235202C86AF546632;
    uint256 public tokenDecimals = 9;
    
    address public _crypto = 0x290c665656a67e0ea0784f90ECBaeFF77c884217;
   
    
    uint256 public tokenRatePerEth = 60000000000;
    uint256 public rateDecimals = 0;
    
    uint256 public minEthLimit = 1e17; // 0.1 BNB
    uint256 public maxEthLimit = 10e18; // 10 BNB
    
    uint256 public soldTokens=0;
    
    uint256 public intervalDays;
    
    uint256 public endTime = 2 days;
    
    bool public isClaimable = false;
    
    bool public isWhitelisted = false;

    uint256 public hardCap = 0;
    
    uint256 public softCap = 0;
    
    uint256 public earnedCap =0;
    
    uint256 public whitelistLength = 0;
    
    mapping(address => uint256) public usersInvestments;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => mapping(address => uint256)) public whitelistedAddresses;
    
    constructor(address _token,uint256 _min,uint256 _max,uint256 _rate, uint256 _soft , uint256 _hard) public {
        tokenAddress = _token;
        minEthLimit = _min;
        maxEthLimit = _max;
        tokenRatePerEth = _rate;
        hardCap = _hard;
        softCap = _soft;
        tokenDecimals = IToken(tokenAddress).decimals();
        owner = msg.sender;
    }
    
    function startPresale(uint256 numberOfdays) external onlyOwner{
        require(!isPresaleOpen, "Presale is open");
        intervalDays = numberOfdays.mul(1 days);
        endTime = block.timestamp.add(intervalDays);
        isPresaleOpen = true;
        isClaimable = false;
    }
    
    function closePresale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet or ended.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        tokenAddress = token;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
     function setCryptoAddress(address token) external onlyOwner {
        _crypto = token;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    function getUserInvestments(address user) public view returns (uint256){
        return usersInvestments[user];
    }
    
    function getUserClaimbale(address user) public view returns (uint256){
        return balanceOf[user];
    }
    
    function addWhitelistedAddress(address _address, uint256 _allocation) external onlyOwner {
        whitelistedAddresses[tokenAddress][_address] = _allocation;
    }
    
    function addMultipleWhitelistedAddresses(address[] calldata _addresses, uint256[] calldata _allocation) external onlyOwner {
         for (uint i=0; i<_addresses.length; i++) {
             whitelistLength = whitelistLength.add(1);
             whitelistedAddresses[tokenAddress][_addresses[i]] = _allocation[i];
         }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        whitelistedAddresses[tokenAddress][_address] = 0;
        whitelistLength = whitelistLength.sub(1);
    }
    
    receive() external payable{}
    
    function buyToken(uint256 amount) public{
         if(block.timestamp > endTime || earnedCap.add(amount) > hardCap)
            isPresaleOpen = false;
        
        require(isPresaleOpen, "Presale is not open.");
       
        if(isWhitelisted){
            require(whitelistedAddresses[tokenAddress][msg.sender] > 0, "you are not whitelisted");
            require(whitelistedAddresses[tokenAddress][msg.sender] >= amount, "amount too high");
            require(usersInvestments[msg.sender].add(amount) <= whitelistedAddresses[tokenAddress][msg.sender], "Maximum purchase cap hit");
        }else{
             require(
                usersInvestments[msg.sender].add(amount) <= maxEthLimit
                && usersInvestments[msg.sender].add(amount) >= minEthLimit,
                "Installment Invalid."
            );
        }
        require(earnedCap.add(amount) <= hardCap,"Hard Cap Exceeds");
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
        uint256 tokenAmount = getTokensPerEth(amount);
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) >= tokenAmount ,"No Presale Funds left");
        require(IToken(_crypto).transferFrom(msg.sender,address(this), amount),"Insufficient balance from User");
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(amount);
        earnedCap = earnedCap.add(amount);
    }
    
  function claimTokens() public{
        require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
        require(isClaimable, "You cannot claim tokens until the finalizeSale.");
        require(balanceOf[msg.sender] > 0 , "No Tokens left !");
        require(IToken(tokenAddress).transfer(msg.sender, balanceOf[msg.sender]), "Insufficient balance of presale contract!");
        balanceOf[msg.sender]=0;
    }
    
    function finalizeSale() public onlyOwner{
        isClaimable = !(isClaimable);
        soldTokens = 0;
    }
    
    function whitelistedSale() public onlyOwner{
        isWhitelisted = !(isWhitelisted);
    }
    
    function getTokensPerEth(uint256 amount) public view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function getTokenPerCrypto(uint256 _amount) public view returns (uint256){
         return _amount.mul(tokenRatePerEth).div(10**(uint256(IToken(_crypto).decimals()).sub(uint256(IToken(tokenAddress).decimals()).add(rateDecimals))));
    }
    
    function withdrawBNB() public onlyOwner{
        require(address(this).balance > 0 , "No Funds Left");
         owner.transfer(address(this).balance);
    }
    
    function getUnsoldTokensBalance() public view returns(uint256) {
        return IToken(tokenAddress).balanceOf(address(this));
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
        IToken(tokenAddress).burnTokens(IToken(tokenAddress).balanceOf(address(this)));   
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        soldTokens = 0;
        IToken(tokenAddress).transfer(owner, (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
    }
}