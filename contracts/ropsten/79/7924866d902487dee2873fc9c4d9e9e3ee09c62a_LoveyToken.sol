pragma solidity ^0.4.4;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Disableable is Owned {
  event Enable();
  event Disable();

  bool public isEnabled = true;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier enabled {
    require(isEnabled);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier disabled {
    require(!isEnabled);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function enable() onlyOwner disabled returns (bool) {
    isEnabled = true;
    emit Enable();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function disable() onlyOwner enabled returns (bool) {
    isEnabled = false;
    emit Disable();
    return true;
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PayableToken is Disableable {
  event PaymentEnable();
  event PaymentDisable();

  bool public isPaymentEnabled = true;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier paymentEnabled {
    require(isPaymentEnabled);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier paymentDisabled {
    require(!isPaymentEnabled);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function paymentEnable() onlyOwner paymentDisabled returns (bool) {
    isPaymentEnabled = true;
    emit PaymentEnable();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function paymentDisable() onlyOwner paymentEnabled returns (bool) {
    isPaymentEnabled = false;
    emit PaymentDisable();
    return true;
  }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract BaseToken is ERC20Interface, PayableToken {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public validDestination(to) enabled returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint tokens)  public validDestination(to) enabled returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract LoveyToken is BaseToken {
    
    uint public averageEthPrice = 550000; // in case eth price will change // todo
    uint public lastAmount = 0;
    uint public totalEth = 0;
    uint integers = 12;
    uint totalCapInDollars = 10**uint(5); // 8 // todo
    bool public isTotalCapReached = false;
    uint public totalTokensSold = 0;
    
    uint[] tokenCaps = new uint[](5);
    uint[] tokenDisc = new uint[](5);
    uint public totalTokenCap;
    
    
    constructor() public {
        symbol = &quot;Lovey&quot;;
        name = &quot;Lovey Token&quot;;
        decimals = 6;
        totalSupply = 1 * 10**uint(integers + decimals);
        balances[owner] = totalSupply;
        
        totalTokenCap = totalSupply / 2;
        
        tokenCaps[0] = totalSupply / 100; // 1% for 10x discount
        tokenCaps[1] = tokenCaps[0] * 2; // 2% for 5x discount
        tokenCaps[2] = tokenCaps[0] * 10; // 10% for 2x discount
        tokenCaps[3] = tokenCaps[0] * 15;  // 15% for 1.25x discount
        tokenCaps[4] = totalTokenCap - tokenCaps[0] - tokenCaps[1] - tokenCaps[2] - tokenCaps[3]; // no discount cap
        
        tokenDisc[0] = 1000;
        tokenDisc[1] = 500;
        tokenDisc[2] = 200;
        tokenDisc[3] = 125;
        tokenDisc[4] = 100;
        
        emit Transfer(address(0), owner, totalSupply);
    }
    
    
    function () public payable enabled paymentEnabled {
        if(isTotalCapReached) throw;
        if (msg.value == 0) { return; }
        
        uint rate = ethToLoveyRate();
        uint amount = (msg.value * rate) / (10**uint(18 - decimals));
        
        if(amount == 0) throw;
        if(amount < (dollarToLoveyRate() * 10)) throw; // don&#39;t allow small amounts
        
        require(balances[owner] >= amount);
        
        lastAmount = amount;
        totalEth = totalEth + msg.value;
        
        uint totalBoughtAmount = 0;
        
        do
        {
            if(amount == 0) break;
            
            uint8 stage = getStage();
            uint discount = tokenDisc[stage];
            uint amountWithDiscount = (amount * discount) / 100;
            
            if(tokenCaps[stage] < amountWithDiscount)
                amountWithDiscount = tokenCaps[stage];
            
            if(amountWithDiscount == 0) break;
            
            tokenCaps[stage] = tokenCaps[stage].sub(amountWithDiscount);
            totalBoughtAmount += amountWithDiscount;
            
            if(amount > ((amountWithDiscount * 100) / discount))
                amount = amount.sub((amountWithDiscount * 100) / discount);
            else
                amount = 0;
            
            require(balances[owner] >= amountWithDiscount);
            balances[owner] = balances[owner].sub(amountWithDiscount);
            balances[msg.sender] = balances[msg.sender].add(amountWithDiscount);
            totalTokensSold += amountWithDiscount;
            
        }while((stage < (tokenCaps.length - 1)) && (amount > 0));
        
        if(totalBoughtAmount == 0) throw;
        lastAmount = totalBoughtAmount;
        
        emit Transfer(owner, msg.sender, totalBoughtAmount); // Broadcast a message to the blockchain
        
        //Transfer ether to owner
        owner.transfer(msg.value);   
        
        if(totalTokensSold >= totalTokenCap)
            isTotalCapReached = true;
    }
    
    function getStage() public view returns (uint8) {
        for(uint8 i = 0; i < tokenCaps.length; i++) {
            if(tokenCaps[i] > 0) {
                return i;
            }
        }
        throw;
    }
    
    
    function setEthPrice(uint ethPrice) public onlyOwner {
        if(ethPrice == 0) throw;
        averageEthPrice = ethPrice;
    }
    
    
    function ethToLoveyRate() public view returns (uint) {
        uint oneDollarRate = dollarToLoveyRate();
        uint rate = averageEthPrice * oneDollarRate;
        return rate;
    }
    
    function dollarToLoveyRate() public view returns (uint) {
        uint oneDollarRate = totalSupply / (totalCapInDollars * 10**uint(decimals)); 
        return oneDollarRate;
    }
    
    

}