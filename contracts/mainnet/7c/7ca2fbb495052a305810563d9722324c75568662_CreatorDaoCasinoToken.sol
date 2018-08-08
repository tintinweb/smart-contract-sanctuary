pragma solidity ^0.4.11;

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
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract DaoCasinoToken is ERC20Token {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    string public constant symbol = "BET";
    string public constant name = "Dao.Casino";
    uint8 public constant decimals = 18;

    // Do not use `now` here
    uint256 public STARTDATE;
    uint256 public ENDDATE;

    // Cap USD 25mil @ 296.1470 ETH/USD
    uint256 public CAP;

    // Cannot have a constant address here - Solidity bug
    // https://github.com/ethereum/solidity/issues/2441
    address public multisig;

    function DaoCasinoToken(uint256 _start, uint256 _end, uint256 _cap, address _multisig) {
        STARTDATE = _start;
        ENDDATE   = _end;
        CAP       = _cap;
        multisig  = _multisig;
    }

    // > new Date("2017-06-29T13:00:00").getTime()/1000
    // 1498741200

    uint256 public totalEthers;

    // ------------------------------------------------------------------------
    // Tokens per ETH
    // Day  1    : 2,000 BET = 1 Ether
    // Days 2–14 : 1,800 BET = 1 Ether
    // Days 15–17: 1,700 BET = 1 Ether
    // Days 18–20: 1,600 BET = 1 Ether
    // Days 21–23: 1,500 BET = 1 Ether
    // Days 24–26: 1,400 BET = 1 Ether
    // Days 27–28: 1,300 BET = 1 Ether
    // ------------------------------------------------------------------------
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < STARTDATE) {
            return 0;
        } else if (at < (STARTDATE + 1 days)) {
            return 2000;
        } else if (at < (STARTDATE + 15 days)) {
            return 1800;
        } else if (at < (STARTDATE + 18 days)) {
            return 1700;
        } else if (at < (STARTDATE + 21 days)) {
            return 1600;
        } else if (at < (STARTDATE + 24 days)) {
            return 1500;
        } else if (at < (STARTDATE + 27 days)) {
            return 1400;
        } else if (at <= ENDDATE) {
            return 1300;
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


    // ------------------------------------------------------------------------
    // Exchanges can buy on behalf of participant
    // ------------------------------------------------------------------------
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

        // What is the BET to ETH rate
        uint256 _buyPrice = buyPrice();

        // Calculate #BET - this is safe as _buyPrice is known
        // and msg.value is restricted to valid values
        uint tokens = msg.value * _buyPrice;

        // Check tokens > 0
        require(tokens > 0);
        // Compute tokens for foundation 30%
        // Number of tokens restricted so maths is safe
        uint multisigTokens = tokens * 3 / 7;

        // Add to total supply
        _totalSupply = _totalSupply.add(tokens);
        _totalSupply = _totalSupply.add(multisigTokens);

        // Add to balances
        balances[participant] = balances[participant].add(tokens);
        balances[multisig] = balances[multisig].add(multisigTokens);

        // Log events
        TokensBought(participant, msg.value, totalEthers, tokens,
            multisigTokens, _totalSupply, _buyPrice);
        Transfer(0x0, participant, tokens);
        Transfer(0x0, multisig, multisigTokens);

        // Move the funds to a safe wallet
        multisig.transfer(msg.value);
    }
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, uint256 multisigTokens, 
        uint256 newTotalSupply, uint256 buyPrice);


    // ------------------------------------------------------------------------
    // Owner to add precommitment funding token balance before the crowdsale
    // commences
    // ------------------------------------------------------------------------
    function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now < STARTDATE);
        require(balance > 0);
        balances[participant] = balances[participant].add(balance);
        _totalSupply = _totalSupply.add(balance);
        Transfer(0x0, participant, balance);
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

library CreatorDaoCasinoToken {
    function create(uint256 _start, uint256 _end, uint256 _cap, address _multisig) returns (DaoCasinoToken)
    { return new DaoCasinoToken(_start, _end, _cap, _multisig); }

    function version() constant returns (string)
    { return "v0.6.3"; }
}