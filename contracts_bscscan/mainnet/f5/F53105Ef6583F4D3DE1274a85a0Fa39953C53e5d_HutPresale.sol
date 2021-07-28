/**
 *Submitted for verification at BscScan.com on 2021-07-28
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
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract HutPresale is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    address public tokenAddress = 0xA9A56CF6A0c73F6Ba27b19e235202C86AF546632;
    uint256 public tokenDecimals = 9;
    
    
    uint256 public tokenRatePerEth = 60000000000;
    uint256 public rateDecimals = 0;
    
    uint256 public minEthLimit = 1e17; // 0.1 BNB
    uint256 public maxEthLimit = 10e18; // 10 BNB
    
    uint256 public totalSupply;
    
    uint256 public intervalDays;
    
    uint256 public endTime = 2 days;
    
    mapping(address => uint256) public usersInvestments;
    
    mapping(address => uint256) public balanceOf;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function startPresale(uint256 numberOfdays) external onlyOwner{
        require(!isPresaleOpen, "Presale is open");
        intervalDays = numberOfdays.mul(1 days);
        endTime = block.timestamp.add(intervalDays);
        isPresaleOpen = true;
    }
    
    function closePresale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet or ended.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        require(tokenAddress == address(0), "Token address is already set.");
        require(token != address(0), "Token address zero not allowed.");
        
        tokenAddress = token;
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

    
    
    receive() external payable{
        if(block.timestamp > endTime)
        isPresaleOpen = false;
        
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );

        uint256 tokenAmount = getTokensPerEth(msg.value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenAmount);
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
    }
    
    function claimTokens() public{
         require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
        require(balanceOf[msg.sender] > 0 , "No Tokens left !");
        require(IToken(tokenAddress).transfer(msg.sender, balanceOf[msg.sender]), "Insufficient balance of presale contract!");
    }
    
    function finalizeSale() public onlyOwner{
        require(address(this).balance > 0 , "No Funds Left");
        isPresaleOpen=false;
         owner.transfer(address(this).balance);
    }
    
    function getTokensPerEth(uint256 amount) public view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
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
        
        IToken(tokenAddress).transfer(owner, IToken(tokenAddress).balanceOf(address(this)) );
    }
}