pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
}


contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
}

contract ZenswapContributeTest is Ownable {
    
    address public beneficiary;
    uint256 public amountTokensPerEth = 200000000;
    uint256 public amountEthRaised = 0;
    uint256 public availableTokens;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    
    /**
     * Constructor function
     *
     */
    constructor() public {
        
        beneficiary = msg.sender;
        tokenReward = token(0xbaD16E6bACaF330D3615539dbf3884836071f279);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        
        uint256 amount = msg.value;
        uint256 tokens = amount * amountTokensPerEth;
        require(availableTokens >= amount);
        
        balanceOf[msg.sender] += amount;
        availableTokens -= tokens;
        amountEthRaised += amount;
        tokenReward.transfer(msg.sender, tokens);
        beneficiary.transfer(amount);
    }

    /**
     * Withdraw an "amount" of available tokens in this contract
     * 
     */
    function withdrawAvailableToken(address _address, uint amount) public onlyOwner {
        require(availableTokens >= amount);
        availableTokens -= amount;
        tokenReward.transfer(_address, amount);
    }
    
    /**
     * Set the amount of tokens per one ether
     * 
     */
    function setTokensPerEth(uint value) public onlyOwner {
        
        amountTokensPerEth = value;
    }
    
   /**
     * Set a token contract address and available tokens
     * 
     */
    function setTokenReward(address _address, uint amount) public onlyOwner {
        
        tokenReward = token(_address);
        availableTokens = amount;
    }
    
   /**
     * Set available tokens to synchronized or force halt contribution campaign
     * 
     */
    function setAvailableToken(uint value) public onlyOwner {
        
        availableTokens = value;
    }
    
   /**
     * Returns available token 
     * 
     */  
    function tokensAvailable() public constant returns (uint256) {
        return availableTokens;
    }
    
    
}