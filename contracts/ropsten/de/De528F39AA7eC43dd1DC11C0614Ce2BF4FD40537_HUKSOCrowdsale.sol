/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity ^0.4.16;

// ----------------------------------------------------------------------------
// HUK 'HUKSOToken' crowdsale/token contract sample contract.
//
// NOTE: Use at your own risk as this contract has not been audited
//
// Deployed to : 
// Symbol      : HUK
// Name        : HUKSOToken
// Total supply: Unlimited
// Decimals    : 18
//
// Enjoy.
//
// (c) Aly Toure / 2021. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address account) public constant returns (uint balance);
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value)
        public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function allowance(address owner, address spender) public constant
        returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {

    // ------------------------------------------------------------------------
    // Current owner, and proposed new owner
    // ------------------------------------------------------------------------
    address public owner;
    address public newOwner;

    // ------------------------------------------------------------------------
    // Constructor - assign creator as the owner
    // ------------------------------------------------------------------------
    function Owned() public {
        owner = msg.sender;
    }


    // ------------------------------------------------------------------------
    // Modifier to mark that a function can only be executed by the owner
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    // ------------------------------------------------------------------------
    // Owner can initiate transfer of contract to a new owner
    // ------------------------------------------------------------------------
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }


    // ------------------------------------------------------------------------
    // New owner has to accept transfer of contract
    // ------------------------------------------------------------------------
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed from, address indexed to);
}


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // ------------------------------------------------------------------------
    // Multiply two numbers
    // ------------------------------------------------------------------------
    function mul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Multiply one number by another number
    // ------------------------------------------------------------------------
    function div(uint a, uint b) pure internal returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// ----------------------------------------------------------------------------
contract HUKSOToken is ERC20Interface, Owned {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Token parameters
    // ------------------------------------------------------------------------
    string public constant symbol = "HUK";
    string public constant name = "HUKSOToken";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer tokens to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function HUKSOToken() public Owned() {
    }


    // ------------------------------------------------------------------------
    // Get the account balance of another account with address account
    // ------------------------------------------------------------------------
    function balanceOf(address account) public constant returns (uint balance) {
        return balances[account];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner's account to another account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Allow spender to withdraw from your account, multiple times, up to the
    // value tokens. If this function is called again it overwrites the
    // current allowance with value.
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an tokens of tokens from the token owner's
    // balance to another account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public
        returns (bool success)
    {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the number of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address owner, address spender ) public 
        constant returns (uint remaining)
    {
        return allowed[owner][spender];
    }


    // ------------------------------------------------------------------------
    // Mint coins for a single account
    // ------------------------------------------------------------------------
    function mint(address to, uint tokens) internal {
        require(to != 0x0 && tokens != 0);
        balances[to] = balances[to].add(tokens);
        totalSupply = totalSupply.add(tokens);
        Transfer(0x0, to, tokens);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens)
      public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


contract HUKSOCrowdsale is HUKSOToken {

    // ------------------------------------------------------------------------
    // Start Date
    //   > new Date('2021-09-25T18:45:50+00:00').getTime()/1000
    //   1632595550
    //   > new Date(1632595550 * 1000).toString()
    //   "Sat, 25 Sept 2021 18:45:50 AEDT"
    // End Date
    //   Start Date + 4 weeks
    // ------------------------------------------------------------------------
    uint public constant START_DATE = 1632595550;
    uint public constant END_DATE = START_DATE + 4 weeks;

    // Hard cap
    uint public constant ETH_HARD_CAP = 5 ether;

    // Tokens per 1,000 ETH
    uint public constant tokensPerKEther = 1000000; 

    // Keep track of ETH raised
    uint public ethersRaised;

    // Crowdsale finalised?
    bool public finalised;

    // Tokens transferable?
    bool public transferable;

    // My coffer
    address public wallet; 


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function HUKSOCrowdsale() public HUKSOToken() {
        wallet = msg.sender;
    }


    // ------------------------------------------------------------------------
    // Add precommitment funding token balance and ether cost before the
    // crowdsale commences
    // ------------------------------------------------------------------------
    function addPrecommitment(address participant, uint tokens, uint ethers) public onlyOwner {
        // Can only add precommitments before the crowdsale starts
        require(block.timestamp < START_DATE);

        // Check tokens > 0
        require(tokens > 0);

        // Mint tokens
        mint(participant, tokens);

        // Keep track of ethers raised
        ethersRaised = ethersRaised.add(ethers);

        // Log event
        PrecommitmentAdded(participant, tokens, ethers);
    }
    event PrecommitmentAdded(address indexed participant, uint tokens, uint ethers);


    // ------------------------------------------------------------------------
    // Fallback function to receive ETH contributions send directly to the
    // contract address
    // ------------------------------------------------------------------------
    function() public payable {
        proxyPayment(msg.sender);
    }


    // ------------------------------------------------------------------------
    // Receive ETH contributions. Can use this to send tokens to another
    // account
    // ------------------------------------------------------------------------
    function proxyPayment(address contributor) public payable {
        // Check we are still in the crowdsale period
        require(block.timestamp >= START_DATE && block.timestamp <= END_DATE);

        // Check for invalid address
        require(contributor != 0x0);

        // Check that contributor has sent ETH
        require(msg.value > 0);

        // Keep track of ETH raised
        ethersRaised = ethersRaised.add(msg.value);

        // Check we have not exceeded the hard cap
        require(ethersRaised <= ETH_HARD_CAP);

        // Calculate tokens for contributed ETH
        uint tokens = msg.value.mul(tokensPerKEther).div(1000);

        // Mint tokens for contributor
        mint(contributor, tokens);

        // Log ETH contributed and tokens generated
        TokensBought(contributor, msg.value, tokens);

        // Transfer ETH to coffer 
        wallet.transfer(msg.value);
    }
    event TokensBought(address indexed contributor, uint ethers, uint tokens);


    // ------------------------------------------------------------------------
    // Finalise crowdsale, 20% of tokens for myself
    // ------------------------------------------------------------------------
    function finalise() public onlyOwner {
        // Can only finalise once
        require(!finalised);

        // Can only finalise if we are past end date, or hard cap reached
        require(block.timestamp > END_DATE || ethersRaised == ETH_HARD_CAP);

        // Mark as finalised 
        finalised = true;

        // Allow tokens to be transferable
        transferable = true;

        // Mint tokens for my coffer, being 20% of crowdsold tokens
        uint HUKSOTokens = totalSupply.mul(20).div(80);
        mint(owner, HUKSOTokens);
    }


    // ------------------------------------------------------------------------
    // transfer tokens, only transferable after the crowdsale is finalised
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // Can only transfer after crowdsale completed
        require(transferable);
        return super.transfer(to, tokens);
    }


    // ------------------------------------------------------------------------
    // transferFrom tokens, only transferable after the crowdsale is finalised
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public
        returns (bool success)
    {
        // Can only transfer after crowdsale completed
        require(transferable);
        return super.transferFrom(from, to, tokens);
    }
}