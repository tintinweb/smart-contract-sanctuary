pragma solidity ^0.4.11;

    // ----------------------------------------------------------------------------
    // Integrative Wallet Token & Crowdsale
    // Iwtoken.com
    // Developer from @Adatum
    // Taking ideas from @BokkyPooBah 
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
    uint256 _totalSupply = 100000000.000000000000000000;

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
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract IntegrativeWalletToken is ERC20Token {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    string public constant symbol = "IWT";
    string public constant name = "Integrative Wallet Token";
    uint256 public constant decimals = 18;
    uint256 public constant IWTfund = 55 * (10**6) * 10**decimals;   // 55m reserved for foundation and expenses.

    // Initial date 2017-08-31 : 13 00 hs UTC
    uint256 public constant STARTDATE = 1504184400;
    uint256 public constant ENDDATE = STARTDATE + 28 days;

    // Cap USD 12.5 mil @ 196.88 ETH/USD -> 12.5m / 196.88 -> 63490 -> 63500
    uint256 public constant CAP = 63500 ether;

    // Cannot have a constant address here - Solidity bug
    address public multisig = 0xf82D89f274e2C5FE9FD3202C5426ABE47D2099Cd;
    address public iwtfundtokens = 0x1E408cE343F4a392B430dFC5E3e2fE3B6a9Cc580;


    uint256 public totalEthers;

    function IntegrativeWalletToken() {
		
	  balances[iwtfundtokens] = IWTfund;   // 55m IWT reserved for use Fundation

    }

  
    // ------------------------------------------------------------------------
    // Tokens per ETH
    // Day  1-7  : 1,200 IWT = 1 Ether
    // Days 8–14 : 1,000 IWT = 1 Ether
    // Days 15–21: 800   IWT = 1 Ether
    // Days 22–27: 600   IWT = 1 Ether
    // ------------------------------------------------------------------------
	
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < STARTDATE) {
            return 0;
        } else if (at < (STARTDATE + 1 days)) {
            return 1200;
        } else if (at < (STARTDATE + 8 days)) {
            return 1000;
        } else if (at < (STARTDATE + 15 days)) {
            return 800;
        } else if (at < (STARTDATE + 22 days)) {
            return 600;
        } else if (at <= ENDDATE) {
            return 600;
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // Buy tokens from the contract
    // ------------------------------------------------------------------------
    function () payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address participant) payable {
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

        // What is the IWT to ETH rate
        uint256 _buyPrice = buyPrice();

        // Calculate #IWT - this is safe as _buyPrice is known
        // and msg.value is restricted to valid values
        uint tokens = msg.value * _buyPrice;

        // Check tokens > 0
        require(tokens > 0);
   

        // Add to balances
        balances[participant] = balances[participant].add(tokens);

        // Log events
        TokensBought(participant, msg.value, totalEthers, tokens, _totalSupply, _buyPrice);
        Transfer(0x0, participant, tokens);

        // Move the funds to a safe wallet
        multisig.transfer(msg.value);
    }
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, 
        uint256 newTotalSupply, uint256 buyPrice);


    function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now < STARTDATE);
        require(balance > 0);
        balances[participant] = balances[participant].add(balance);
        _totalSupply = _totalSupply.add(balance);
        Transfer(0x0, participant, balance);
    }


    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends or cap reached
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transfer
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
        // Cannot transfer before crowdsale ends or cap reached
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transferFrom
        return super.transferFrom(_from, _to, _amount);
    }


    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
    
    // ----------------------------------------------------------------------------
    // Integrative Wallet Token & Crowdsale
    // Iwtoken.com
    // Developer from @Adatum
    // Taking ideas from @BokkyPooBah 
    // ----------------------------------------------------------------------------
    
    
}