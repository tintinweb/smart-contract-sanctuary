/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner!");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract Presale is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    //@dev ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals = 9;
    
    //@dev amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth = 10000;
    //@dev decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;
    uint256 public tokenSold = 0;
    bool private allowance = false;
    uint256 public totalBNBAmount = 0;
    uint256[] public rPercent;
    uint256[] public rStep;
    uint256 public hardcap = 0;
   
    //@dev max and min token buy limit per account
    uint256 public minEthLimit = 1;
    uint256 public maxEthLimit = ~uint256(0);
    
    mapping(address => uint256) public usersInvestments;
    
    address public recipient;
   
    constructor(address _token,address _recipient) public {
        tokenAddress = _token;
        recipient = _recipient;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setRStep(uint256[] memory _rStep) external onlyOwner {
        rStep = _rStep;
    }

    function setRPercentage(uint256[] memory _rPercent) external onlyOwner {
        rPercent = _rPercent;
    }

    function setHardcap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }
     
    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }
    
    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
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
    
    receive() external payable{
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        
        //@dev calculate the amount of tokens to transfer for the given eth
        uint256 tokenAmount = getTokensPerEth(msg.value);

        if (totalBNBAmount < rStep[0] * (10**18))
            tokenAmount = tokenAmount.mul(rPercent[0]).div(100);
        else if (totalBNBAmount < rStep[1] * (10**18))
            tokenAmount = tokenAmount.mul(rPercent[1]).div(100);
        else if (totalBNBAmount < rStep[2] * (10**18))
            tokenAmount = tokenAmount.mul(rPercent[2]).div(100);
       
        require(IToken(tokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        tokenSold += tokenAmount;
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);

        totalBNBAmount = totalBNBAmount + msg.value;
        //@dev send received funds to the owner
        payable(recipient).transfer(msg.value);
        if (totalBNBAmount > hardcap)
            isPresaleOpen = false;
    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
        
        IToken(tokenAddress).burn(IToken(tokenAddress).balanceOf(address(this)));   
    }
    
    function getUnsoldTokens(address to) external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IToken(tokenAddress).transfer(to, IToken(tokenAddress).balanceOf(address(this)) );
    }
}