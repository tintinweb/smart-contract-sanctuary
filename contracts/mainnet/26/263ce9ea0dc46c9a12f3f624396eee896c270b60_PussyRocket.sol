/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract PussyRocket is IERC20 {
   
    string public constant name         = 'PussyRocket';
    string public constant symbol       = 'PROCK';
    uint8 public constant decimals      = 18;
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    address public tokenOwner;
    address public crowdsale;
    
    uint256 public totalSupply_                     = 69e27; // 69B tokens
    uint256 public constant unlockTime              = 1640008800; //After this date, tokens are no longer locked
    uint256 public limitCrowdsale                   = 58e27;    // 84% of token goes for sale
    uint256 public tokensDistributedCrowdsale       = 0;    // The amount of tokens already sold to the ICO buyers
    bool public remainingTokenBurnt                 = false;  


    modifier onlyOwner {
    require(msg.sender == tokenOwner);
    _;
    }
    
    modifier onlyCrowdsale {
    require(msg.sender == crowdsale);
    _;
    }
    
    modifier afterCrowdsale {
    require(block.timestamp > unlockTime || msg.sender == crowdsale);
    _;
    }
    
    constructor() public {
        tokenOwner = msg.sender;
        balances[msg.sender] = totalSupply_ - limitCrowdsale;
            emit Transfer(address(0), msg.sender, totalSupply_ - limitCrowdsale);
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public afterCrowdsale override returns (bool) {
        require(recipient != address(0));
        require(amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public afterCrowdsale override returns (bool) {
        require(recipient != address(0));
        require(amount <= balances[sender]);
        require(amount <= allowed[sender][msg.sender]);

        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public afterCrowdsale override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address account,address spender) public override view returns (uint256) {
        return allowed[account][spender];
    }

    function increaseApproval(address spender, uint256 amount) public afterCrowdsale returns (bool) {
        allowed[msg.sender][spender] = (allowed[msg.sender][spender] + amount);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 amount) public afterCrowdsale returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (amount >= oldValue) {
          allowed[msg.sender][spender] = 0;
        } else {
          allowed[msg.sender][spender] = oldValue - amount;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
   
   
    // Functions to support the Crowdsale
    function setCrowdsale(address _crowdsale) external onlyOwner {
        require(_crowdsale != address(0));
        crowdsale = _crowdsale;
    }
    
    function distribute(address buyer, uint tokens) external onlyCrowdsale {
        require(buyer != address(0));
        require(tokens > 0);

        // Check that the limit of ICO tokens hasn't been met yet
        require(tokensDistributedCrowdsale < limitCrowdsale);
        require(tokensDistributedCrowdsale + tokens <= limitCrowdsale);

        tokensDistributedCrowdsale = tokensDistributedCrowdsale + tokens;
        balances[buyer] = balances[buyer] + tokens;
        emit Transfer(address(0), buyer, tokens);
      }
   
   function airdrop(address recipient, uint amount) external onlyOwner returns (bool){
        require(block.timestamp < unlockTime);
        require(recipient != address(0));
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
      }
   
    function burn() external onlyCrowdsale {
        uint256 remainingICOToken = limitCrowdsale - tokensDistributedCrowdsale;
        if(remainingICOToken > 0 && !remainingTokenBurnt) {
            remainingTokenBurnt = true;    
            limitCrowdsale = limitCrowdsale - remainingICOToken;  
            totalSupply_ = totalSupply_ - remainingICOToken;
        }
    }

    function emergencyExtract() external onlyOwner {
        payable(tokenOwner).transfer(address(this).balance);
    }
}