pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
// Abab.io preICO 
// The MIT Licence
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Token is Owned {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Total Supply
    // ------------------------------------------------------------------------
    uint256 _totalSupply = 0;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint256) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Get the total token supply
    // ------------------------------------------------------------------------
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount                // User has balance
            && _amount > 0                                 // Non-zero transfer
            && balances[_to] + _amount > balances[_to]     // Overflow check
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount. If this function is called again it overwrites the
    // current allowance with _value.
    // ------------------------------------------------------------------------
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to the spender&#39;s account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                  // From a/c has balance
            && allowed[_from][msg.sender] >= _amount    // Transfer approved
            && _amount > 0                              // Non-zero transfer
            && balances[_to] + _amount > balances[_to]  // Overflow check
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract AbabPreICOToken is ERC20Token {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    string public constant symbol   = "pAA";
    string public constant name     = "AbabPreICOToken_Ver2";
    uint8  public constant decimals = 18;

    uint256 public STARTDATE;  
    uint256 public ENDDATE;    
    uint256 public BUYPRICE;   
    uint256 public CAP;

    function AbabPreICOToken() {
        STARTDATE = 1499951593;        // 13 July 2017 г., 13:13:13
        ENDDATE   = 1817029631;        // 31 July 2027 г., 10:27:11
        BUYPRICE  = 3333;              // $0.06 @ $200 ETH/USD
        CAP       = 2500*1 ether;      // in eth ($500K / 0.05 ) / etherPrice
        
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x2EDE66ED71E557CC90B9A76C298185C09591991B, 0.25 ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x56B8729FFCC28C4BB5718C94261543477A4EB4E5, 0.5  ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x56B8729FFCC28C4BB5718C94261543477A4EB4E5, 0.5  ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xCC89FB091E138D5087A8742306AEDBE0C5CF8CE6, 0.15 ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xCC89FB091E138D5087A8742306AEDBE0C5CF8CE6, 0.35 ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x5FB3DC3EC639F33429AEA0773ED292A37B87A4D8, 1    ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xD428F83278B587E535C414DFB32C24F7272DCFE9, 1    ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xFD4876F2BEDFEAE635F70E010FC3F78D2A01874C, 2.9  ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xC2C319C7E7C678E060945D3203F46E320D3BC17B, 3.9  ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xCD4A005339CC97DE0466332FFAE0215F68FBDFAF, 10   ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x04DA469D237E85EC55A4085874E1737FB53548FD, 9.6  ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x8E32917F0FE7D9069D753CAFF946D7146FAC528A, 5    ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0x72EC91441AB84639CCAB04A31FFDAC18756E70AA, 7.4  ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xE5389809FEDFB0225719D136D9734845A7252542, 2    ether);
InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(0xE1D8D6D31682D8A901833E60DA15EE1A870B8370, 5    ether);
    }
	
    function ActualizePrice(uint256 _start, uint256 _end, uint256 _buyPrice, uint256 _cap) 
    onlyOwner returns (bool success) 
    {
        STARTDATE = _start;
        ENDDATE   = _end;
        BUYPRICE  = _buyPrice;
        CAP       = _cap; 
        return true;
    }
    
    uint BUYPRICE961e593b36920a767dad75f9fda07723231d9b77 = 4000;
    
    function InitBalanceFrom961e593b36920a767dad75f9fda07723231d9b77(address sender, uint val)
    onlyOwner
    {
        totalEthers = totalEthers.add(val);
        uint tokens = val * BUYPRICE961e593b36920a767dad75f9fda07723231d9b77;
        _totalSupply = _totalSupply.add(tokens);
        balances[sender] = balances[sender].add(tokens);

        Transfer(0x0, sender, tokens);
    }

    uint256 public totalEthers;

    // ------------------------------------------------------------------------
    // Buy tokens from the contract
    // ------------------------------------------------------------------------
    function () payable {
        // No contributions before the start of the crowdsale
        require(now >= STARTDATE);
        // No contributions after the end of the crowdsale
        require(now <= ENDDATE);
        // No 0 contributions
        require(msg.value > 0);

        // Add ETH raised to total
        totalEthers = totalEthers.add(msg.value);
        // Cannot exceed cap
        require(totalEthers <= CAP);

        uint tokens = msg.value * BUYPRICE;

        // Check tokens > 0
        require(tokens > 0);

        // Add to total supply
        _totalSupply = _totalSupply.add(tokens);

        // Add to balances
        balances[msg.sender] = balances[msg.sender].add(tokens);

        // Log events
        Transfer(0x0, msg.sender, tokens);

        // Move the funds to a safe wallet
        owner.transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account, with a
    // check that the crowdsale is finalised
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends or cap reached
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transfer
        return super.transfer(_to, _amount);
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account, with a check that the crowdsale is
    // finalised
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
        // Cannot transfer before crowdsale ends or cap reached
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transferFrom
        return super.transferFrom(_from, _to, _amount);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}