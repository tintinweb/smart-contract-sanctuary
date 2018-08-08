// AP Ok - Recent version
pragma solidity ^0.4.13;

// ----------------------------------------------------------------------------
// Arenaplay Crowdsale Token Contract
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd
// The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    // AP Ok - Overflow protected
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    // AP Ok - Underflow protected
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    // AP Next 3 lines Ok
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    // AP Ok - Constructor assigns `owner` variable
    function Owned() {
        owner = msg.sender;
    }

    // AP Ok - Only owner can execute function
    modifier onlyOwner {
        // AP Ok - Could be replaced with `require(msg.sender == owner);`
        require(msg.sender == owner);
        _;
    }

    // AP Ok - Propose ownership transfer
    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    // AP Ok - Accept ownership transfer
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
    // AP Ok - For overflow and underflow protection
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Total Supply
    // ------------------------------------------------------------------------
    // AP Ok
    uint256 _totalSupply = 0;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    // AP Ok
    mapping(address => uint256) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    // AP Ok
    mapping(address => mapping (address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Get the total token supply
    // ------------------------------------------------------------------------
    // AP Ok
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    // AP Ok
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    // AP NOTE - This function will return true/false instead of throwing an
    //           error, as the conditions protect against overflows and 
    //           underflows
    // AP NOTE - This function does not protect against the short address
    //           bug, but the short address bug is more the responsibility
    //           of automated processes checking the data sent to this function
    function transfer(address _to, uint256 _amount) returns (bool success) {
        // AP Ok - Account has sufficient balance to transfer
        if (balances[msg.sender] >= _amount                // User has balance
            // AP Ok - Non-zero amount
            && _amount > 0                                 // Non-zero transfer
            // AP Ok - Overflow protection
            && balances[_to] + _amount > balances[_to]     // Overflow check
        ) {
            // AP Ok
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            // AP Ok
            balances[_to] = balances[_to].add(_amount);
            // AP Ok - Logging
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
    // AP NOTE - This simpler method of `approve(...)` together with 
    //           `transferFrom(...)` can be used in the double spending attack, 
    //           but the risk is low, and can be mitigated by the user setting 
    //           the approval limit to 0 before changing the limit 
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        // AP Ok
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to the spender&#39;s account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    // AP NOTE - This function will return true/false instead of throwing an
    //           error, as the conditions protect against overflows and 
    //           underflows
    // AP NOTE - This simpler method of `transferFrom(...)` together with 
    //           `approve(...)` can be used in the double spending attack, 
    //           but the risk is low, and can be mitigated by the user setting 
    //           the approval limit to 0 before changing the limit 
    // AP NOTE - This function does not protect against the short address
    //           bug, but the short address bug is more the responsibility
    //           of automated processes checking the data sent to this function
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        // AP Ok - Account has sufficient balance to transfer
        if (balances[_from] >= _amount                  // From a/c has balance
            // AP Ok - Account is authorised to spend at least this amount
            && allowed[_from][msg.sender] >= _amount    // Transfer approved
            // AP Ok - Non-zero amount
            && _amount > 0                              // Non-zero transfer
            // AP Ok - Overflow protection
            && balances[_to] + _amount > balances[_to]  // Overflow check
        ) {
            // AP Ok
            balances[_from] = balances[_from].sub(_amount);
            // AP Ok
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            // AP Ok
            balances[_to] = balances[_to].add(_amount);
            // AP Ok
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
    // AP Ok
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // AP Ok
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // AP Ok
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract ArenaplayToken is ERC20Token {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    // AP Next 3 lines Ok. Using uint8 for decimals instead of uint256
    string public constant symbol = "APY";
    string public constant name = "Arenaplay.io";
    uint8 public constant decimals = 18;

    // > new Date("2017-06-29T13:00:00").getTime()/1000
    // 1498741200
    // Do not use `now` here
    // AP NOTE - This contract uses the date/time instead of blocks to determine
    //           the start, end and BET/ETH scale. The use of date/time in 
    //           these contracts can be used by miners to skew the block time.
    //           This is not a significant risk in a crowdfunding contract.
    uint256 public constant STARTDATE = 1501173471;
    // BK Ok
    uint256 public constant ENDDATE = STARTDATE + 39 days;

    // Cap USD 10mil @ 200 ETH/USD
    // AP NOTE - The following constant will need to be updated with the correct
    //           ETH/USD exchange rate. The aim for Arenaplay.io is to raise
    //           USD 10 million, INCLUDING the precommitments. This cap will
    //           have to take into account the ETH equivalent amount of the
    //           precommitment 
    uint256 public constant CAP = 50000 ether;

    // Cannot have a constant address here - Solidity bug
    // https://github.com/ethereum/solidity/issues/2441
    // AP Ok
    address public multisig = 0x0e43311768025D0773F62fBF4a6cd083C508d979;

    // AP Ok - To compare against the `CAP` variable
    uint256 public totalEthers;

    // AP Ok - Constructor
    function ArenaplayToken() {
    }


    // ------------------------------------------------------------------------
 
    // ------------------------------------------------------------------------
    // AP Ok - Calculate the APY/ETH at this point in time
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    // AP Ok - Calculate APY/ETH at any point in time. Can be used in EtherScan
    //         to determine past, current or future APY/ETH rate 
    // AP NOTE - Scale is continuous
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
    // AP Ok - Account can send tokens directly to this contract&#39;s address
    function () payable {
        proxyPayment(msg.sender);
    }


    // ------------------------------------------------------------------------
    // Exchanges can buy on behalf of participant
    // ------------------------------------------------------------------------
    // AP Ok
    function proxyPayment(address participant) payable {
        // No contributions before the start of the crowdsale
        // AP Ok
        require(now >= STARTDATE);
        // No contributions after the end of the crowdsale
        // AP Ok
        require(now <= ENDDATE);
        // No 0 contributions
        // AP Ok
        require(msg.value > 0);

        // Add ETH raised to total
        // AP Ok - Overflow protected
        totalEthers = totalEthers.add(msg.value);
        // Cannot exceed cap
        // AP Ok
        require(totalEthers <= CAP);

        // What is the APY to ETH rate
        // AP Ok
        uint256 _buyPrice = buyPrice();

        // Calculate #APY - this is safe as _buyPrice is known
        // and msg.value is restricted to valid values
        // AP Ok
        uint tokens = msg.value * _buyPrice;

        // Check tokens > 0
        // AP Ok
        require(tokens > 0);
        // Compute tokens for foundation 20%
        // Number of tokens restricted so maths is safe
        // AP Ok
        uint multisigTokens = tokens * 2 / 10 ;

        // Add to total supply
        // AP Ok
        _totalSupply = _totalSupply.add(tokens);
        // AP Ok
        _totalSupply = _totalSupply.add(multisigTokens);

        // Add to balances
        // AP Ok
        balances[participant] = balances[participant].add(tokens);
        // AP Ok
        balances[multisig] = balances[multisig].add(multisigTokens);

        // Log events
        // AP Next 4 lines Ok
        TokensBought(participant, msg.value, totalEthers, tokens,
            multisigTokens, _totalSupply, _buyPrice);
        Transfer(0x0, participant, tokens);
        Transfer(0x0, multisig, multisigTokens);

        // Move the funds to a safe wallet
        // https://github.com/ConsenSys/smart-contract-best-practices#be-aware-of-the-tradeoffs-between-send-transfer-and-callvalue
        multisig.transfer(msg.value);
    }
    // AP Ok
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, uint256 multisigTokens, 
        uint256 newTotalSupply, uint256 buyPrice);


    // ------------------------------------------------------------------------
    // Owner to add precommitment funding token balance before the crowdsale
    // commences
    // ------------------------------------------------------------------------
    // AP NOTE - Owner can only execute this before the crowdsale starts
    // AP NOTE - Owner must add amount * 3 / 7 for the foundation for each
    //           precommitment amount
    // AP NOTE - The CAP must take into account the equivalent ETH raised
    //           for the precommitment amounts
    function addPrecommitment(address participant, uint balance) onlyOwner {
        //APK Ok
        require(now < STARTDATE);
        // AP Ok
        require(balance > 0);
        // AP Ok
        balances[participant] = balances[participant].add(balance);
        // AP Ok
        _totalSupply = _totalSupply.add(balance);
        // AP Ok
        Transfer(0x0, participant, balance);
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account, with a
    // check that the crowdsale is finalised
    // ------------------------------------------------------------------------
    // AP Ok
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends or cap reached
        // AP Ok
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transfer
        // AP Ok
        return super.transfer(_to, _amount);
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account, with a check that the crowdsale is
    // finalised
    // ------------------------------------------------------------------------
    // AP Ok
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
        // Cannot transfer before crowdsale ends or cap reached
        // AP Ok
        require(now > ENDDATE || totalEthers == CAP);
        // Standard transferFrom
        // AP Ok
        return super.transferFrom(_from, _to, _amount);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    // AP Ok - Only owner
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        // AP Ok
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}