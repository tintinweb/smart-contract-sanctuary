pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// OxBio token
// 
// Deployed to : 0x
// Symbol      : OXB
// Name        : OxBio
// Total supply: 500000000 of which 200M available.
// Decimals    : 18
//
// ----------------------------------------------------------------------------


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
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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
// ERC20 compliant token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract OxBioToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string  public symbol;
    string  public  name;
    uint8   public decimals;
    uint256 public _totalSupply;
    uint256 public weiRaised;                              // total wei received
    uint256 public USDETH;                                 // price of 1 ether in USD

    uint internal available_USD_per_round_01 = 5600000;          // represents 40M tokens at a 0.14 USD per token rate, will be used as a strike off variable. 
    uint internal available_USD_per_round_02 = 6400000;          // represents 40M tokens at a 0.16 USD per token rate, will be used as a strike off variable. 
    uint internal available_USD_per_round_03 = 7200000;          // represents 40M tokens at a 0.18 USD per token rate, will be used as a strike off variable. 
    uint internal available_USD_per_round_04 = 7600000;          // represents 40M tokens at a 0.19 USD per token rate, will be used as a strike off variable. 
    uint internal available_USD_per_round_05 = 8400000;          // represents 40M tokens at a 0.21 USD per token rate, will be used as a strike off variable. 
    
    uint constant internal ratio_round_01 = 140;                 // 1000 * 0.14
    uint constant internal ratio_round_02 = 160;                 // 1000 * 0.16
    uint constant internal ratio_round_03 = 180;                 // 1000 * 0.18
    uint constant internal ratio_round_04 = 190;                 // 1000 * 0.19
    uint constant internal ratio_round_05 = 210;                 // 1000 * 0.21
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function OxBioToken() public {
      
        symbol = &quot;OXB&quot;;
        name = &quot;OxBio&quot;;
        decimals = 18;
        USDETH = 530;

        _totalSupply = 500000000 * 10**uint(decimals); // 200M out of 500M 
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require( to != address(0) );
        require( tokens <= balances[msg.sender] );
        
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
    function approve(address spender, uint tokens) public returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
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
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Accept ETH and convert this into OxBio tokens at a ETH:OxBio respectively 1:XXXX ratio 
    // ------------------------------------------------------------------------
    function () public payable {
        uint256 WEIamount = msg.value;
        uint256 USDamount = WEIamount.mul( USDETH ).div( 10**18 );
        uint256 OXBtokens = 0;
        
        require( msg.value  != 0 );
        require( msg.sender != address(0) );
        
        if (USDamount > 0) {
          if (available_USD_per_round_01 > 0) {
            if (available_USD_per_round_01 >= USDamount) {
              available_USD_per_round_01 = available_USD_per_round_01.sub ( USDamount );
              USDamount = 0;
              // number of OXB tokens:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, USDETH), ratio_round_01 ) );
            } else {
              // use a part of the incoming ether for this round:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, available_USD_per_round_01), ratio_round_01 ) );
              USDamount = USDamount.sub ( available_USD_per_round_01 );
              available_USD_per_round_01 = 0;
            }
          }
        }
        
        // 02 repeat the same for the next round
        if (USDamount > 0) {
          if (available_USD_per_round_02 > 0) {
            if (available_USD_per_round_02 >= USDamount) {
              available_USD_per_round_02 = available_USD_per_round_02.sub( USDamount );
              USDamount = 0;
              // number of OXB tokens:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, USDETH), ratio_round_02 ) );
            } else {
              // use a part of the incoming ether for this round:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, available_USD_per_round_02), ratio_round_02 ) );
              USDamount = USDamount.sub ( available_USD_per_round_02 );
              available_USD_per_round_02 = 0;
            }
          }
        }

        // 03 repeat the same for the next round
        if (USDamount > 0) {
          if (available_USD_per_round_03 > 0) {
            if (available_USD_per_round_03 >= USDamount) {
              available_USD_per_round_03 = available_USD_per_round_03.sub( USDamount );
              USDamount = 0;
              // number of OXB tokens:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, USDETH), ratio_round_03 ) );
            } else {
              // use a part of the incoming ether for this round:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, available_USD_per_round_03), ratio_round_03 ) );
              USDamount = USDamount.sub ( available_USD_per_round_03 );
              available_USD_per_round_03 = 0;
            }
          }
        }        
        // 04 repeat the same for the next round
        if (USDamount > 0) {
          if (available_USD_per_round_04 > 0) {
            if (available_USD_per_round_04 >= USDamount) {
              available_USD_per_round_04 = available_USD_per_round_04.sub( USDamount );
              USDamount = 0;
              // number of OXB tokens:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, USDETH), ratio_round_04 ) );
            } else {
              // use a part of the incoming ether for this round:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, available_USD_per_round_04), ratio_round_04 ) );
              USDamount = USDamount.sub ( available_USD_per_round_04 );
              available_USD_per_round_04 = 0;
            }
          }
        }

        // 05 repeat the same for the next round
        if (USDamount > 0) {
          if (available_USD_per_round_05 > 0) {
            if (available_USD_per_round_05 >= USDamount) {
              available_USD_per_round_05 = available_USD_per_round_05.sub( USDamount );
              USDamount = 0;
              // number of OXB tokens:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, USDETH), ratio_round_05 ) );
            } else {
              // use a part of the incoming ether for this round:
              OXBtokens = OXBtokens.add ( SafeMath.div( SafeMath.mul(1000, available_USD_per_round_05), ratio_round_05 ) );
              USDamount = USDamount.sub ( available_USD_per_round_05 );
              available_USD_per_round_05 = 0;
            }
          }
        }
        
        // now is known how much OXBtokens to issue for the transferred amount of ETH.
        require( OXBtokens > 0 );
        require( totalSupply().sub( OXBtokens ) > 300000000 );
        //require( OXBtokens < 100000000 );                             // noone can buy more than 50% at once
        //require( balances[msg.sender].add( OXBtokens ) < 100000000 ); // noone can have more than 50%
        
        weiRaised = weiRaised.add( WEIamount );
        
        Transfer(address(0), msg.sender, OXBtokens);
        balances[owner] = balances[owner].sub(OXBtokens);
        balances[msg.sender] = balances[msg.sender].add(OXBtokens); // increase the OXBtoken balance of sender
        owner.transfer(msg.value);                                  // ether to owner

    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Owner can change the USDETH rate
    // ------------------------------------------------------------------------
    function updateUSDETH(uint256 _USDETH) public onlyOwner {
      require(_USDETH > 0);
      USDETH = _USDETH;
    }
    
}