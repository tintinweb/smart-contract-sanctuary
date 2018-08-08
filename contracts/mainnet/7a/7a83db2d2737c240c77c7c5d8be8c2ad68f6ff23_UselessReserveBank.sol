pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
// The Useless Reserve Bank Token Contract
//
// - If you need welfare support, claim your free URB token entitlements from
//   the gubberment.
//
//   Call the default function `()` to claim 1,000 URBs by sending a 0 value
//   transaction to this contract address.
//
//   NOTE that any ethers sent with this call will fill the coffers of this
//   gubberment&#39;s token contract.
//
// - If you consider yourself to be in the top 1%, make a donation for world
//   peace.
//
//   Call `philanthropise({message})` and 100,000 URBs will be sent to
//   your account for each ether you donate. Fractions of ethers are always
//   accepted.
//
//   Your message and donation amount will be etched into the blockchain
//   forever, to recognise your generousity. Thank you.
//
//   As you are making this world a better place, your philanthropic donation
//   is eligible for a special discounted 20% tax rate. Your taxes will be
//   shared equally among the current gubberment treasury officials.
//   Thank you.
//
// - If you have fallen into hard times and have accumulated some URB tokens,
//   you can convert your URBs into ethers.
//
//   Liquidate your URBs by calling `liquidate(amountOfTokens)`, where
//   1 URB is specified as 1,000,000,000,000,000,000 (18 decimal places).
//   You will receive 1 ether for each 30,000 URBs you liquidate.
//
//   NOTE that this treasury contract can only dish out ethers in exchange
//   for URB tokens **IF** there are sufficient ethers in this contract.
//   Only 25% of the ether balance of this contract can be claimed at any
//   one time.
//
// - Any gifts of ERC20 tokens send to this contract will be solemnly accepted
//   by the gubberment. The treasury will at it&#39;s discretion disburst these 
//   gifts to friendly officials. Thank you.
//
// Token Contract:
// - Symbol: URB
// - Name: Useless Reserve Bank
// - Decimals: 18
// - Contract address; 0x7a83db2d2737c240c77c7c5d8be8c2ad68f6ff23
// - Block: 4,000,000
//
// Usage:
// - Watch this contract at address:
//     0x7A83dB2d2737C240C77C7C5D8be8c2aD68f6FF23
//   with the application binary interface published at:
//     https://etherscan.io/address/0x7a83db2d2737c240c77c7c5d8be8c2ad68f6ff23#code
//   to execute this token contract functions in Ethereum Wallet / Mist or
//   MyEtherWallet.
//
// User Functions:
// - default send function ()
//   Users can send 0 or more ethers to this contract address and receive back
//   1000 URBs
//
// - philanthropise(name)
//   Rich users can send a non-zero ether amount, calling this function with
//   a name or dedication message. 100,000 URBs will be minted for each
//   1 ETH sent. Fractions of an ether can be sent.
//   Remember that your goodwill karma is related to the size of your donation.
//
// - liquidate(amountOfTokens)
//   URB token holders can liquidate part or all of their tokens and receive
//   back 1 ether for every 30,000 URBs liquidated, ONLY if the ethers to be
//   received is less than 25% of the outstanding ETH balance of this contract
//
// - bribe()
//   Send ethers directly to the gubberment treasury officials. Your ethers
//   will be distributed equally among the current treasury offcials.
//
// Info Functions:
// - currentEtherBalance()
//   Returns the current ether balance of this contract.
//
// - currentTokenBalance()
//   Returns the total supply of URB tokens, where 1 URB is represented as
//   1,000,000,000,000,000,000 (18 decimal places).
//
// - numberOfTreasuryOfficials()
//   Returns the number of officials on the payroll of the gubberment
//   treasury.
//
// Gubberment Functions:
// - pilfer(amount)
//   Gubberment officials can pilfer any ethers in this contract when necessary.
//
// - acceptGiftTokens(tokenAddress)
//   The gubberment can accept any ERC20-compliant gift tokens send to this
//   contract.
//
// - replaceOfficials([accounts])
//   The gubberment can sack and replace all it&#39;s treasury officials in one go.
//
// Standard ERC20 Functions:
// - balanceOf(account)
// - totalSupply
// - transfer(to, amount)
// - approve(spender, amount)
// - transferFrom(owner, spender, amount)
//
// Yes, I made it into block 4,000,000 .
//
// Remember to make love and peace, not war!
//
// (c) The Gubberment 2017. The MIT Licence.
// ----------------------------------------------------------------------------

contract Gubberment {
    address public gubberment;
    address public newGubberment;
    event GubbermentOverthrown(address indexed _from, address indexed _to);

    function Gubberment() {
        gubberment = msg.sender;
    }

    modifier onlyGubberment {
        if (msg.sender != gubberment) throw;
        _;
    }

    function coupDetat(address _newGubberment) onlyGubberment {
        newGubberment = _newGubberment;
    }
 
    function gubbermentOverthrown() {
        if (msg.sender == newGubberment) {
            GubbermentOverthrown(gubberment, newGubberment);
            gubberment = newGubberment;
        }
    }
}


// ERC Token Standard #20 - https://github.com/ethereum/EIPs/issues/20
contract ERC20Token {
    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Total token supply
    // ------------------------------------------------------------------------
    uint public totalSupply;

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
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
        uint _amount
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
        uint _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
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
    ) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint _value);
}


contract UselessReserveBank is ERC20Token, Gubberment {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    string public constant symbol = "URB";
    string public constant name = "Useless Reserve Bank";
    uint8 public constant decimals = 18;
    
    uint public constant WELFARE_HANDOUT = 1000;
    uint public constant ONEPERCENT_TOKENS_PER_ETH = 100000;
    uint public constant LIQUIDATION_TOKENS_PER_ETH = 30000;

    address[] public treasuryOfficials;
    uint public constant TAXRATE = 20;
    uint public constant LIQUIDATION_RESERVE_RATIO = 75;

    uint public totalTaxed;
    uint public totalBribery;
    uint public totalPilfered;

    uint public constant SENDING_BLOCK = 3999998; 

    function UselessReserveBank() {
        treasuryOfficials.push(0xDe18789c4d65DC8ecE671A4145F32F1590c4D802);
        treasuryOfficials.push(0x8899822D031891371afC369767511164Ef21e55c);
    }

    // ------------------------------------------------------------------------
    // Just give the welfare handouts
    // ------------------------------------------------------------------------
    function () payable {
        uint tokens = WELFARE_HANDOUT * 1 ether;
        totalSupply += tokens;
        balances[msg.sender] += tokens;
        WelfareHandout(msg.sender, tokens, totalSupply, msg.value, 
            this.balance);
        Transfer(0x0, msg.sender, tokens);
    }
    event WelfareHandout(address indexed recipient, uint tokens, 
        uint newTotalSupply, uint ethers, uint newEtherBalance);


    // ------------------------------------------------------------------------
    // If you consider yourself rich, donate for world peace
    // ------------------------------------------------------------------------
    function philanthropise(string name) payable {
        // Sending something real?
        require(msg.value > 0);

        // Calculate the number of tokens
        uint tokens = msg.value * ONEPERCENT_TOKENS_PER_ETH;

        // Assign tokens to account and inflate total supply
        balances[msg.sender] += tokens;
        totalSupply += tokens;

        // Calculate and forward taxes to the treasury
        uint taxAmount = msg.value * TAXRATE / 100;
        if (taxAmount > 0) {
            totalTaxed += taxAmount;
            uint taxPerOfficial = taxAmount / treasuryOfficials.length;
            for (uint i = 0; i < treasuryOfficials.length; i++) {
                treasuryOfficials[i].transfer(taxPerOfficial);
            }
        }

        Philanthropy(msg.sender, name, tokens, totalSupply, msg.value, 
            this.balance, totalTaxed);
        Transfer(0x0, msg.sender, tokens);
    }
    event Philanthropy(address indexed buyer, string name, uint tokens, 
        uint newTotalSupply, uint ethers, uint newEtherBalance,
        uint totalTaxed);


    // ------------------------------------------------------------------------
    // Liquidate your tokens for ETH, if this contract has sufficient ETH
    // ------------------------------------------------------------------------
    function liquidate(uint amountOfTokens) {
        // Account must have sufficient tokens
        require(amountOfTokens <= balances[msg.sender]);

        // Burn tokens
        balances[msg.sender] -= amountOfTokens;
        totalSupply -= amountOfTokens;

        // Calculate ETH to exchange
        uint ethersToSend = amountOfTokens / LIQUIDATION_TOKENS_PER_ETH;

        // Is there sufficient ETH to support this liquidation?
        require(ethersToSend > 0 && 
            ethersToSend <= (this.balance * (100 - LIQUIDATION_RESERVE_RATIO) / 100));

        // Log message
        Liquidate(msg.sender, amountOfTokens, totalSupply, 
            ethersToSend, this.balance - ethersToSend);
        Transfer(msg.sender, 0x0, amountOfTokens);

        // Send ETH
        msg.sender.transfer(ethersToSend);
    }
    event Liquidate(address indexed seller, 
        uint tokens, uint newTotalSupply, 
        uint ethers, uint newEtherBalance);


    // ------------------------------------------------------------------------
    // Gubberment officials will accept 100% of bribes
    // ------------------------------------------------------------------------
    function bribe() payable {
        // Briber must be offering something real
        require(msg.value > 0);

        // Do we really need to keep track of the total bribes?
        totalBribery += msg.value;
        Bribed(msg.value, totalBribery);

        uint bribePerOfficial = msg.value / treasuryOfficials.length;
        for (uint i = 0; i < treasuryOfficials.length; i++) {
            treasuryOfficials[i].transfer(bribePerOfficial);
        }
    }
    event Bribed(uint amount, uint newTotalBribery);


    // ------------------------------------------------------------------------
    // Gubberment officials can pilfer out of necessity
    // ------------------------------------------------------------------------
    function pilfer(uint amount) onlyGubberment {
        // Cannot pilfer more than the contract balance
        require(amount > this.balance);

        // Do we really need to keep track of the total pilfered amounts?
        totalPilfered += amount;
        Pilfered(amount, totalPilfered, this.balance - amount);

        uint amountPerOfficial = amount / treasuryOfficials.length;
        for (uint i = 0; i < treasuryOfficials.length; i++) {
            treasuryOfficials[i].transfer(amountPerOfficial);
        }
    }
    event Pilfered(uint amount, uint totalPilfered, 
        uint newEtherBalance);


    // ------------------------------------------------------------------------
    // Accept any ERC20 gifts
    // ------------------------------------------------------------------------
    function acceptGiftTokens(address tokenAddress) 
      onlyGubberment returns (bool success) 
    {
        ERC20Token token = ERC20Token(tokenAddress);
        uint amount = token.balanceOf(this);
        return token.transfer(gubberment, amount);
    }


    // ------------------------------------------------------------------------
    // Change gubberment officials
    // ------------------------------------------------------------------------
    function replaceOfficials(address[] newOfficials) onlyGubberment {
        treasuryOfficials = newOfficials;
    }


    // ------------------------------------------------------------------------
    // Information function
    // ------------------------------------------------------------------------
    function currentEtherBalance() constant returns (uint) {
        return this.balance;
    }

    function currentTokenBalance() constant returns (uint) {
        return totalSupply;
    }

    function numberOfTreasuryOfficials() constant returns (uint) {
        return treasuryOfficials.length;
    }
}