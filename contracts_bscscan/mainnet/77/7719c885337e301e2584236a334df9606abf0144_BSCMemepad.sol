/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

/**
 *BSC MemePad Presale Contract
*/

pragma solidity ^0.6.12;

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
    function decimals() external view returns (uint256 balance);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

contract BSCMemepad is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    address public tokenAddress = 0x63133dE69e94f225726426FA729a7c515A51D75a;
    uint256 public tokenDecimals = 18;
    
    uint256 public tokenRatePerEth = 300000000000000000000000;
    uint256 public rateDecimals = 0;
    
    uint256 public minEthLimit = 1e17; // 0.1 BNB
    uint256 public maxEthLimit = 5e17; // 0.5 BNB
    
    uint256 public totalSupply;
    
    uint256 public soldTokens = 0;
    
    uint256 public totalsold = 0;
    
    uint256 public intervalDays;
    
    uint256 public endTime = 1 days;
    
    bool public isClaimable = false;
    
    bool public isWhitelisted = false;
    
    mapping(address => uint256) public usersInvestments;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => mapping(address => uint256)) public whitelistedAddresses;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function startPresale(uint256 numberOfdays) external onlyOwner{
        require(IToken(tokenAddress).balanceOf(address(this)) > 0,"No Funds");
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
        tokenDecimals = IToken(tokenAddress).decimals();
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
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
    
    function addWhitelistedAddress(address _address) external onlyOwner {
        whitelistedAddresses[tokenAddress][_address] = maxEthLimit;
    }
    
    function addMultipleWhitelistedAddresses(address[] calldata _addresses) external onlyOwner {
         for (uint i=0; i<_addresses.length; i++) {
             whitelistedAddresses[tokenAddress][_addresses[i]] = maxEthLimit;
         }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        whitelistedAddresses[tokenAddress][_address] = 0;
    }
    
    receive() external payable{
        if(block.timestamp > endTime)
        isPresaleOpen = false;
        
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        if(isWhitelisted){
            require(whitelistedAddresses[tokenAddress][msg.sender] > 0, "you are not whitelisted");
            require(whitelistedAddresses[tokenAddress][msg.sender] >= msg.value, "amount too high");
            require(usersInvestments[msg.sender].add(msg.value) <= whitelistedAddresses[tokenAddress][msg.sender], "Maximum purchase cap hit");
       
        }
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
        uint256 tokenAmount = getTokensPerEth(msg.value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
    }
    
    function claimTokens() public{
        require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
        require(balanceOf[msg.sender] > 0 , "No Tokens left !");
        require(IToken(tokenAddress).transfer(msg.sender, balanceOf[msg.sender]), "Insufficient balance of presale contract!");
        balanceOf[msg.sender] = 0;
    }
    
    function finalizeSale() public onlyOwner{
        isClaimable = !(isClaimable);
        totalsold = totalsold.add(soldTokens);
        soldTokens = 0;
    }
    
    function whitelistedSale() public onlyOwner{
        isWhitelisted = !(isWhitelisted);
    }
    
    function getTokensPerEth(uint256 amount) public view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(10**(uint256(tokenDecimals)));
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
        IToken(tokenAddress).transfer(owner, (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
    }
}