pragma solidity ^0.4.18;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

/*
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
*/


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract StandardToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public constant symbol = "ast";
    string public constant name = "AllStocks Token";
    uint256 public constant decimals = 18;
    uint256 public _totalSupply;

    bool public isFinalized;              // switched to true in operational state
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => uint256) refunds;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function StandardToken() public {

        //_totalSupply = 1000000 * 10**uint(decimals);
        //balances[owner] = _totalSupply;
        //Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        
        // Prevent transfer to 0x0 address. Use burn() instead
        require(to != 0x0);
        
        //allow trading in tokens only if sale fhined or by token creator (for bounty program)
        if (msg.sender != owner)
            require(isFinalized);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
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
    function approve(address spender, uint256 tokens) public returns (bool success) {
        //allow trading in token only if sale fhined 
        require(isFinalized);

        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        //allow trading in token only if sale fhined 
        require(isFinalized);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        //allow trading in token only if sale fhined 
        require(isFinalized);
        
        return allowed[tokenOwner][spender];
    }

}

// note introduced onlyPayloadSize in StandardToken.sol to protect against short address attacks

contract AllstocksToken is StandardToken {
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;        // deposit address for ETH for Allstocks Fund

    // crowdsale parameters
    bool public isActive;                 // switched to true in after setup
    uint256 public fundingStartTime = 0;
    uint256 public fundingEndTime = 0;
    uint256 public allstocksFund = 25 * (10**6) * 10**decimals;     // 25m reserved for Allstocks use
    uint256 public tokenExchangeRate = 625;                         // 625 Allstocks tokens per 1 ETH
    uint256 public tokenCreationCap =  50 * (10**6) * 10**decimals; // 50m hard cap
    
    //this is for production
    uint256 public tokenCreationMin =  25 * (10**5) * 10**decimals; // 2.5m minimum


    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateAllstocksToken(address indexed _to, uint256 _value);

    // constructor
    function AllstocksToken() public {
      isFinalized = false;                         //controls pre through crowdsale state
      owner = msg.sender;
      _totalSupply = allstocksFund;
      balances[owner] = allstocksFund;             // Deposit Allstocks share
      CreateAllstocksToken(owner, allstocksFund);  // logs Allstocks fund
    }

    function setup (
        uint256 _fundingStartTime,
        uint256 _fundingEndTime) onlyOwner external
    {
      require (isActive == false); 
      require (isFinalized == false); 			        	   
      require (msg.sender == owner);                 // locks finalize to the ultimate ETH owner
      require (fundingStartTime == 0);              //run once
      require (fundingEndTime == 0);                //first time 
      require(_fundingStartTime > 0);
      require(_fundingEndTime > 0 && _fundingEndTime > _fundingStartTime);

      isFinalized = false;                          //controls pre through crowdsale state
      isActive = true;
      ethFundDeposit = owner;                       // set ETH wallet owner 
      fundingStartTime = _fundingStartTime;
      fundingEndTime = _fundingEndTime;
    }

    function () public payable {       
      createTokens(msg.value);
    }

    /// @dev Accepts ether and creates new Allstocks tokens.
    function createTokens(uint256 _value)  internal {
      require(isFinalized == false);    
      require(now >= fundingStartTime);
      require(now < fundingEndTime); 
      require(msg.value > 0);         

      uint256 tokens = _value.mul(tokenExchangeRate); // check that we&#39;re not over totals
      uint256 checkedSupply = _totalSupply.add(tokens);

      require(checkedSupply <= tokenCreationCap);

      _totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // safeAdd not needed

      //add sent eth to refunds list
      refunds[msg.sender] = _value.add(refunds[msg.sender]);  // safeAdd 

      CreateAllstocksToken(msg.sender, tokens);  // logs token creation
      Transfer(address(0), owner, _totalSupply);
    }
	
	//method for manageing bonus phases 
	function setRate(uint256 _value) external onlyOwner {
      require (isFinalized == false);
      require (isActive == true);
      require (_value > 0);
      require(msg.sender == owner); // Allstocks double chack 
      tokenExchangeRate = _value;

    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external onlyOwner {
      require (isFinalized == false);
      require(msg.sender == owner); // Allstocks double chack  
      require(_totalSupply >= tokenCreationMin + allstocksFund);  // have to sell minimum to move to operational
      require(_totalSupply > 0);

      if (now < fundingEndTime) {    //if try to close before end time, check that we reach target
        require(_totalSupply >= tokenCreationCap);
      }
      else 
        require(now >= fundingEndTime);
      
	    // move to operational
      isFinalized = true;
      ethFundDeposit.transfer(this.balance);  // send the eth to Allstocks
    }

    /// @dev send funding to safe wallet if minimum is reached 
    function vaultFunds() external onlyOwner {
      require(msg.sender == owner);            // Allstocks double chack
      require(_totalSupply >= tokenCreationMin + allstocksFund); // have to sell minimum to move to operational
      ethFundDeposit.transfer(this.balance);  // send the eth to Allstocks
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      require (isFinalized == false);  // prevents refund if operational
      require (isActive == true);
      require (now > fundingEndTime); // prevents refund until sale period is over
     
      require(_totalSupply < tokenCreationMin + allstocksFund);  // no refunds if we sold enough
      require(msg.sender != owner); // Allstocks not entitled to a refund
      
      uint256 allstocksVal = balances[msg.sender];
      uint256 ethValRefund = refunds[msg.sender];
     
      require(allstocksVal > 0);   
      require(ethValRefund > 0);  
     
      balances[msg.sender] = 0;
      refunds[msg.sender] = 0;
      
      _totalSupply = _totalSupply.sub(allstocksVal); // extra safe
      
      uint256 ethValToken = allstocksVal / tokenExchangeRate;     // should be safe; previous throws covers edges

      require(ethValRefund <= ethValToken);
      msg.sender.transfer(ethValRefund);                 // if you&#39;re using a contract; make sure it works with .send gas limits
      LogRefund(msg.sender, ethValRefund);               // log it
    }
}