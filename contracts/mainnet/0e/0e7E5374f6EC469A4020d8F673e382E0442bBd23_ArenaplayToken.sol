// BK Ok - Recent version
pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
// Dao.Casino Crowdsale Token Contract
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd for Dao.Casino 2017
// The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    // BK Ok - Overflow protected
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    // BK Ok - Underflow protected
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    // BK Next 3 lines Ok
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    // BK Ok - Constructor assigns `owner` variable
    function Owned() {
        owner = msg.sender;
    }

    // BK Ok - Only owner can execute function
    modifier onlyOwner {
        // BK Ok - Could be replaced with `require(msg.sender == owner);`
        require(msg.sender == owner);
        _;
    }

    // BK Ok - Propose ownership transfer
    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    // BK Ok - Accept ownership transfer
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
    // BK Ok - For overflow and underflow protection
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Total Supply
    // ------------------------------------------------------------------------
    // BK Ok
    uint256 _totalSupply = 0;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    // BK Ok
    mapping(address => uint256) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    // BK Ok
    mapping(address => mapping (address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Get the total token supply
    // ------------------------------------------------------------------------
    // BK Ok
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    // BK Ok
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    // BK NOTE - This function will return true/false instead of throwing an
    //           error, as the conditions protect against overflows and 
    //           underflows
    // BK NOTE - This function does not protect against the short address
    //           bug, but the short address bug is more the responsibility
    //           of automated processes checking the data sent to this function
    function transfer(address _to, uint256 _amount) returns (bool success) {
        // BK Ok - Account has sufficient balance to transfer
        if (balances[msg.sender] >= _amount                // User has balance
            // BK Ok - Non-zero amount
            && _amount > 0                                 // Non-zero transfer
            // BK Ok - Overflow protection
            && balances[_to] + _amount > balances[_to]     // Overflow check
        ) {
            // BK Ok
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            // BK Ok
            balances[_to] = balances[_to].add(_amount);
            // BK Ok - Logging
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
    // BK NOTE - This simpler method of `approve(...)` together with 
    //           `transferFrom(...)` can be used in the double spending attack, 
    //           but the risk is low, and can be mitigated by the user setting 
    //           the approval limit to 0 before changing the limit 
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        // BK Ok
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to the spender&#39;s account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    // BK NOTE - This function will return true/false instead of throwing an
    //           error, as the conditions protect against overflows and 
    //           underflows
    // BK NOTE - This simpler method of `transferFrom(...)` together with 
    //           `approve(...)` can be used in the double spending attack, 
    //           but the risk is low, and can be mitigated by the user setting 
    //           the approval limit to 0 before changing the limit 
    // BK NOTE - This function does not protect against the short address
    //           bug, but the short address bug is more the responsibility
    //           of automated processes checking the data sent to this function
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        // BK Ok - Account has sufficient balance to transfer
        if (balances[_from] >= _amount                  // From a/c has balance
            // BK Ok - Account is authorised to spend at least this amount
            && allowed[_from][msg.sender] >= _amount    // Transfer approved
            // BK Ok - Non-zero amount
            && _amount > 0                              // Non-zero transfer
            // BK Ok - Overflow protection
            && balances[_to] + _amount > balances[_to]  // Overflow check
        ) {
            // BK Ok
            balances[_from] = balances[_from].sub(_amount);
            // BK Ok
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            // BK Ok
            balances[_to] = balances[_to].add(_amount);
            // BK Ok
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
    // BK Ok
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // BK Ok
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // BK Ok
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract ArenaplayToken is ERC20Token {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    // BK Next 3 lines Ok. Using uint8 for decimals instead of uint256
    string public constant symbol = "APY";
    string public constant name = "Arenaplay.io";
    uint8 public constant decimals = 18;

    // > new Date("2017-06-29T13:00:00").getTime()/1000
    // 1498741200
    // Do not use `now` here
    // BK NOTE - This contract uses the date/time instead of blocks to determine
    //           the start, end and BET/ETH scale. The use of date/time in 
    //           these contracts can be used by miners to skew the block time.
    //           This is not a significant risk in a crowdfunding contract.
    uint256 public constant STARTDATE = 1501173471;
    // BK Ok
    uint256 public constant ENDDATE = STARTDATE + 39 days;

    // Cap USD 25mil @ 296.1470 ETH/USD
    // BK NOTE - The following constant will need to be updated with the correct
    //           ETH/USD exchange rate. The aim for Dao.Casino is to raise
    //           USD 25 million, INCLUDING the precommitments. This cap will
    //           have to take into account the ETH equivalent amount of the
    //           precommitment 
    uint256 public constant CAP = 44432 ether;

    // Cannot have a constant address here - Solidity bug
    // https://github.com/ethereum/solidity/issues/2441
    // BK Ok
    address public multisig = 0x0e43311768025D0773F62fBF4a6cd083C508d979;

    // BK Ok - To compare against the `CAP` variable
    uint256 public totalEthers;

    // BK Ok - Constructor
    function ArenplayToken() {
    }


    // ------------------------------------------------------------------------
 
    // ------------------------------------------------------------------------
    // BK Ok - Calculate the BET/ETH at this point in time
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    // BK Ok - Calculate BET/ETH at any point in time. Can be used in EtherScan
    //         to determine past, current or future BET/ETH rate 
    // BK NOTE - Scale is continuous
    function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < STARTDATE) {
            return 0;
        } else if (at < (STARTDATE + 9 days)) {
            return 2700;
        } else if (at < (STARTDATE + 18 days)) {
            return 2400;
        } else if (at < (STARTDATE + 27 days)) {
            return 2050;
        } else if (at <= ENDDATE) {
            return 1500;
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // Buy tokens from the contract
    // ------------------------------------------------------------------------
    // BK Ok - Account can send tokens directly to this contract&#39;s address
    function () payable {
        proxyPayment(msg.sender);
    }


    // ------------------------------------------------------------------------
    // Exchanges can buy on behalf of participant
    // ------------------------------------------------------------------------
    // BK Ok
    function proxyPayment(address participant) payable {
        // No contributions before the start of the crowdsale
        // BK Ok
        require(now >= STARTDATE);
        // No contributions after the end of the crowdsale
        // BK Ok
        require(now <= ENDDATE);
        // No 0 contributions
        // BK Ok
        require(msg.value > 0);

        // Add ETH raised to total
        // BK Ok - Overflow protected
        totalEthers = totalEthers.add(msg.value);
        // Cannot exceed cap
        // BK Ok
        require(totalEthers <= CAP);

        // What is the BET to ETH rate
        // BK Ok
        uint256 _buyPrice = buyPrice();

        // Calculate #BET - this is safe as _buyPrice is known
        // and msg.value is restricted to valid values
        // BK Ok
        uint tokens = msg.value * _buyPrice;

        // Check tokens > 0
        // BK Ok
        require(tokens > 0);
        // Compute tokens for foundation 30%
        // Number of tokens restricted so maths is safe
        // BK Ok
        uint multisigTokens = tokens * 2 / 7;

        // Add to total supply
        // BK Ok
        _totalSupply = _totalSupply.add(tokens);
        // BK Ok
        _totalSupply = _totalSupply.add(multisigTokens);

        // Add to balances
        // BK Ok
        balances[participant] = balances[participant].add(tokens);
        // BK Ok
        balances[multisig] = balances[multisig].add(multisigTokens);

        // Log events
        // BK Next 4 lines Ok
        TokensBought(participant, msg.value, totalEthers, tokens,
            multisigTokens, _totalSupply, _buyPrice);
        Transfer(0x0, participant, tokens);
        Transfer(0x0, multisig, multisigTokens);

        // Move the funds to a safe wallet
        // https://github.com/ConsenSys/smart-contract-best-practices#be-aware-of-the-tradeoffs-between-send-transfer-and-callvalue
        multisig.transfer(msg.value);
    }
    // BK Ok
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, uint256 multisigTokens, 
        uint256 newTotalSupply, uint256 buyPrice);


    // ------------------------------------------------------------------------
    // Owner to add precommitment funding token balance before the crowdsale
    // commences
    // ------------------------------------------------------------------------
    // BK NOTE - Owner can only execute this before the crowdsale starts
    // BK NOTE - Owner must add amount * 3 / 7 for the foundation for each
    //           precommitment amount
    // BK NOTE - The CAP must take into account the equivalent ETH raised
    //           for the precommitment amounts
    function addPrecommitment(address participant, uint balance) onlyOwner {
        // BK Ok
        require(now < STARTDATE);
        // BK Ok
        require(balance > 0);
        // BK Ok
        balances[participant] = balances[participant].add(balance);
        // BK Ok
        _totalSupply = _totalSupply.add(balance);
        // BK Ok
        Transfer(0x0, participant, balance);
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account, with a
    // check that the crowdsale is finalised
    // ------------------------------------------------------------------------
    // BK Ok
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends or cap reached
        // BK Ok
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transfer
        // BK Ok
        return super.transfer(_to, _amount);
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account, with a check that the crowdsale is
    // finalised
    // ------------------------------------------------------------------------
    // BK Ok
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
        // Cannot transfer before crowdsale ends or cap reached
        // BK Ok
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transferFrom
        // BK Ok
        return super.transferFrom(_from, _to, _amount);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    // BK Ok - Only owner
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        // BK Ok
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}