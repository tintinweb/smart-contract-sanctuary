/**
 *Submitted for verification at Etherscan.io on 2021-02-06
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
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0),"Invalid address passed");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


// ----------------------------------------------------------------------------
// 'Infinity Yeild Token' token contract

// Symbol      : IFY
// Name        : Infinity Yeild Token
// Total supply: 250,000 (250 Thousand)
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public constant symbol = "IFY";
    string public  constant name = "Infinity Yeild";
    uint256 public constant decimals = 18;
    uint256 private _totalSupply = 250000 * 10 ** (decimals);
    uint256 public tax = 5;
    
    address public STAKING_ADDRESS;
    address public PRESALE_ADDRESS;
    address public taxReceiver; // 10%
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    event TaxChanged(uint256 newTax, address changedBy);
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _stakingAddress, address preSaleAddress) public {
        taxReceiver = 0x8D74DaBe71b1b95b4e4c90E5A97850FEB9C20855;
        owner = 0xa97F07bc8155f729bfF5B5312cf42b6bA7c4fCB9;
        STAKING_ADDRESS = _stakingAddress;
        PRESALE_ADDRESS = preSaleAddress;
        balances[owner] = totalSupply();
        emit Transfer(address(0), owner, totalSupply());

    }
    
    function ChangeTax(uint256 _newTax) external onlyOwner{
        tax = _newTax;
        emit TaxChanged(_newTax, msg.sender);
    }

    /** ERC20Interface function's implementation **/

    function totalSupply() public override view returns (uint256){
       return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        require(address(to) != address(0) , "Invalid address");
        require(balances[msg.sender] >= tokens, "insufficient sender's balance");

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        uint256 deduction = 0;
        // if the sender and receiver address is not staking address, apply tax 
        if (to != STAKING_ADDRESS && msg.sender != STAKING_ADDRESS && to!= PRESALE_ADDRESS && msg.sender != PRESALE_ADDRESS){
            deduction = onePercent(tokens).mul(tax); // Calculates the tax to be applied on the amount transferred
            uint256 _OS = onePercent(deduction).mul(10); // 10% will go to owner
            balances[taxReceiver] = balances[taxReceiver].add(_OS);
            emit Transfer(address(this), taxReceiver, _OS);
            balances[STAKING_ADDRESS] = balances[STAKING_ADDRESS].add(deduction.sub(_OS)); // add the tax deducted to the staking pool for rewards
            emit Transfer(address(this), STAKING_ADDRESS, deduction.sub(_OS));
        }
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(msg.sender, to, tokens.sub(deduction));
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender], "insufficient allowance"); //check allowance
        require(balances[from] >= tokens, "Insufficient senders balance");
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        uint256 deduction = 0;
        // if the sender and receiver address is not staking address, apply tax 
        if (to != STAKING_ADDRESS && from != STAKING_ADDRESS && to!= PRESALE_ADDRESS && from != PRESALE_ADDRESS){
            deduction = onePercent(tokens).mul(tax); // Calculates the tax to be applied on the amount transferred
            uint256 _OS = onePercent(deduction).mul(10); // 10% will go to owner
            balances[taxReceiver] = balances[taxReceiver].add(_OS); 
            emit Transfer(address(this), taxReceiver, _OS);
            balances[STAKING_ADDRESS] = balances[STAKING_ADDRESS].add(deduction.sub(_OS)); // add the tax deducted to the staking pool for rewards
            emit Transfer(address(this), STAKING_ADDRESS, deduction.sub(_OS));
        }
        
        balances[to] = balances[to].add(tokens.sub(deduction)); // send rest of the amount to the receiver after deduction
        emit Transfer(from, to, tokens.sub(tokens));
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    /**UTILITY***/
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}