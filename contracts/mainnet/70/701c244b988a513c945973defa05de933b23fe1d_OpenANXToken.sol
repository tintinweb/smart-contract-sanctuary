pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
// OAX &#39;openANX Token&#39; crowdfunding contract
//
// Refer to http://openanx.org/ for further information.
//
// Enjoy. (c) openANX and BokkyPooBah / Bok Consulting Pty Ltd 2017. 
// The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// OAX &#39;openANX Token&#39; crowdfunding contract - ERC20 Token Interface
//
// Refer to http://openanx.org/ for further information.
//
// Enjoy. (c) openANX and BokkyPooBah / Bok Consulting Pty Ltd 2017. 
// The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) 
        returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant 
        returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, 
        uint _value);
}


// ----------------------------------------------------------------------------
// OAX &#39;openANX Token&#39; crowdfunding contract - Owned contracts
//
// Refer to http://openanx.org/ for further information.
//
// Enjoy. (c) openANX and BokkyPooBah / Bok Consulting Pty Ltd 2017. 
// The MIT Licence.
// ----------------------------------------------------------------------------

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
    function Owned() {
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
    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

 
    // ------------------------------------------------------------------------
    // New owner has to accept transfer of contract
    // ------------------------------------------------------------------------
    function acceptOwnership() {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


// ----------------------------------------------------------------------------
// OAX &#39;openANX Token&#39; crowdfunding contract
//
// Refer to http://openanx.org/ for further information.
//
// Enjoy. (c) openANX and BokkyPooBah / Bok Consulting Pty Ltd 2017. 
// The MIT Licence.
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
// OAX &#39;openANX Token&#39; crowdfunding contract - Configuration
//
// Refer to http://openanx.org/ for further information.
//
// Enjoy. (c) openANX and BokkyPooBah / Bok Consulting Pty Ltd 2017. 
// The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// openANX crowdsale token smart contract - configuration parameters
// ----------------------------------------------------------------------------
contract OpenANXTokenConfig {

    // ------------------------------------------------------------------------
    // Token symbol(), name() and decimals()
    // ------------------------------------------------------------------------
    string public constant SYMBOL = "OAX";
    string public constant NAME = "openANX Token";
    uint8 public constant DECIMALS = 18;


    // ------------------------------------------------------------------------
    // Decimal factor for multiplications from OAX unit to OAX natural unit
    // ------------------------------------------------------------------------
    uint public constant DECIMALSFACTOR = 10**uint(DECIMALS);

    // ------------------------------------------------------------------------
    // Tranche 1 soft cap and hard cap, and total tokens
    // ------------------------------------------------------------------------
    uint public constant TOKENS_SOFT_CAP = 13000000 * DECIMALSFACTOR;
    uint public constant TOKENS_HARD_CAP = 30000000 * DECIMALSFACTOR;
    uint public constant TOKENS_TOTAL = 100000000 * DECIMALSFACTOR;

    // ------------------------------------------------------------------------
    // Tranche 1 crowdsale start date and end date
    // Do not use the `now` function here
    // Start - Thursday, 22-Jun-17 13:00:00 UTC / 1pm GMT 22 June 2017
    // End - Saturday, 22-Jul-17 13:00:00 UTC / 1pm GMT 22 July 2017 
    // ------------------------------------------------------------------------
    uint public constant START_DATE = 1498136400;
    uint public constant END_DATE = 1500728400;

    // ------------------------------------------------------------------------
    // 1 year and 2 year dates for locked tokens
    // Do not use the `now` function here 
    // ------------------------------------------------------------------------
    uint public constant LOCKED_1Y_DATE = START_DATE + 365 days;
    uint public constant LOCKED_2Y_DATE = START_DATE + 2 * 365 days;

    // ------------------------------------------------------------------------
    // Individual transaction contribution min and max amounts
    // Set to 0 to switch off, or `x ether`
    // ------------------------------------------------------------------------
    uint public CONTRIBUTIONS_MIN = 0 ether;
    uint public CONTRIBUTIONS_MAX = 0 ether;
}


// ----------------------------------------------------------------------------
// OAX &#39;openANX Token&#39; crowdfunding contract - locked tokens
//
// Refer to http://openanx.org/ for further information.
//
// Enjoy. (c) openANX and BokkyPooBah / Bok Consulting Pty Ltd 2017. 
// The MIT Licence.
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// Contract that holds the 1Y and 2Y locked token information
// ----------------------------------------------------------------------------
contract LockedTokens is OpenANXTokenConfig {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // 1y and 2y locked totals, not including unsold tranche1 and all tranche2
    // tokens
    // ------------------------------------------------------------------------
    uint public constant TOKENS_LOCKED_1Y_TOTAL = 14000000 * DECIMALSFACTOR;
    uint public constant TOKENS_LOCKED_2Y_TOTAL = 26000000 * DECIMALSFACTOR;
    
    // ------------------------------------------------------------------------
    // Tokens locked for 1 year for sale 2 in the following account
    // ------------------------------------------------------------------------
    address public TRANCHE2_ACCOUNT = 0x813703Eb676f3B6C76dA75cBa0cbC49DdbCA7B37;

    // ------------------------------------------------------------------------
    // Current totalSupply of 1y and 2y locked tokens
    // ------------------------------------------------------------------------
    uint public totalSupplyLocked1Y;
    uint public totalSupplyLocked2Y;

    // ------------------------------------------------------------------------
    // Locked tokens mapping
    // ------------------------------------------------------------------------
    mapping (address => uint) public balancesLocked1Y;
    mapping (address => uint) public balancesLocked2Y;

    // ------------------------------------------------------------------------
    // Address of openANX crowdsale token contract
    // ------------------------------------------------------------------------
    ERC20Interface public tokenContract;


    // ------------------------------------------------------------------------
    // Constructor - called by crowdsale token contract
    // ------------------------------------------------------------------------
    function LockedTokens(address _tokenContract) {
        tokenContract = ERC20Interface(_tokenContract);

        // --- 1y locked tokens ---

        // Confirm 1Y totals        
        add1Y(0x4beE088efDBCC610EEEa101ded7204150AF1C8b9,1000000 * DECIMALSFACTOR);
        add1Y(0x839551201f866907Eb5017bE79cEB48aDa58650c,925000 * DECIMALSFACTOR);
        add1Y(0xa92d4Cd3412862386c234Be572Fe4A8FA4BB09c6,925000 * DECIMALSFACTOR);
        add1Y(0xECf2B5fce33007E5669D63de39a4c663e56958dD,925000 * DECIMALSFACTOR);
        add1Y(0xD6B7695bc74E2C950eb953316359Eab283C5Bda8,925000 * DECIMALSFACTOR);
        add1Y(0xBE3463Eae26398D55a7118683079264BcF3ab24B,150000 * DECIMALSFACTOR);
        add1Y(0xf47428Fb9A61c9f3312cB035AEE049FBa76ba62a,150000 * DECIMALSFACTOR);
        add1Y(0xfCcc77165D822Ef9004714d829bDC267C743658a,50000 * DECIMALSFACTOR);
        add1Y(0xaf8df2aCAec3d5d92dE42a6c19d7706A4F3E8D8b,50000 * DECIMALSFACTOR);
        add1Y(0x22a6f9693856374BF2922cd837d07F6670E7FA4d,250000 * DECIMALSFACTOR);
        add1Y(0x3F720Ca8FfF598F00a51DE32A8Cb58Ca73f22aDe,50000 * DECIMALSFACTOR);
        add1Y(0xBd0D1954B301E414F0b5D0827A69EC5dD559e50B,50000 * DECIMALSFACTOR);
        add1Y(0x2ad6B011FEcDE830c9cc4dc0d0b77F055D6b5990,50000 * DECIMALSFACTOR);
        add1Y(0x0c5cD0E971cA18a0F0E0d581f4B93FaD31D608B0,2000085 * DECIMALSFACTOR);
        add1Y(0xFaaDC4d80Eaf430Ab604337CB67d77eC763D3e23,200248 * DECIMALSFACTOR);
        add1Y(0xDAef46f89c264182Cd87Ce93B620B63c7AfB14f7,1616920 * DECIMALSFACTOR);
        add1Y(0x19cc59C30cE54706633dC29EdEbAE1efF1757b25,224980 * DECIMALSFACTOR);
        add1Y(0xa130fE5D399104CA5AF168fbbBBe19F95d739741,745918 * DECIMALSFACTOR);
        add1Y(0xC0cD1bf6F2939095a56B0DFa085Ba2886b84E7d1,745918 * DECIMALSFACTOR);
        add1Y(0xf2C26e79eD264B0E3e5A5DFb1Dd91EA61f512C6e,745918 * DECIMALSFACTOR);
        add1Y(0x5F876a8A5F1B66fbf3D0D119075b62aF4386e319,745918 * DECIMALSFACTOR);
        add1Y(0xb8E046570800Dd76720aF6d42d3cCae451F54f15,745920 * DECIMALSFACTOR);
        add1Y(0xA524fa65Aac4647fa7bA2c20D22F64450c351bBd,714286 * DECIMALSFACTOR);
        add1Y(0x27209b276C15a936BCE08D7D70f0c97aeb3CE8c3,13889 * DECIMALSFACTOR);

        assert(totalSupplyLocked1Y == TOKENS_LOCKED_1Y_TOTAL);

        // --- 2y locked tokens ---
        add2Y(0x4beE088efDBCC610EEEa101ded7204150AF1C8b9,1000000 * DECIMALSFACTOR);
        add2Y(0x839551201f866907Eb5017bE79cEB48aDa58650c,925000 * DECIMALSFACTOR);
        add2Y(0xa92d4Cd3412862386c234Be572Fe4A8FA4BB09c6,925000 * DECIMALSFACTOR);
        add2Y(0xECf2B5fce33007E5669D63de39a4c663e56958dD,925000 * DECIMALSFACTOR);
        add2Y(0xD6B7695bc74E2C950eb953316359Eab283C5Bda8,925000 * DECIMALSFACTOR);
        add2Y(0xBE3463Eae26398D55a7118683079264BcF3ab24B,150000 * DECIMALSFACTOR);
        add2Y(0xf47428Fb9A61c9f3312cB035AEE049FBa76ba62a,150000 * DECIMALSFACTOR);
        add2Y(0xfCcc77165D822Ef9004714d829bDC267C743658a,50000 * DECIMALSFACTOR);
        add2Y(0xDAef46f89c264182Cd87Ce93B620B63c7AfB14f7,500000 * DECIMALSFACTOR);
        add2Y(0xaf8df2aCAec3d5d92dE42a6c19d7706A4F3E8D8b,50000 * DECIMALSFACTOR);
        add2Y(0x22a6f9693856374BF2922cd837d07F6670E7FA4d,250000 * DECIMALSFACTOR);
        add2Y(0x3F720Ca8FfF598F00a51DE32A8Cb58Ca73f22aDe,50000 * DECIMALSFACTOR);
        add2Y(0xBd0D1954B301E414F0b5D0827A69EC5dD559e50B,50000 * DECIMALSFACTOR);
        add2Y(0x2ad6B011FEcDE830c9cc4dc0d0b77F055D6b5990,50000 * DECIMALSFACTOR);

        //treasury
        add2Y(0x990a2D172398007fcbd5078D84696BdD8cCDf7b2,20000000 * DECIMALSFACTOR);

        assert(totalSupplyLocked2Y == TOKENS_LOCKED_2Y_TOTAL);
    }


    // ------------------------------------------------------------------------
    // Add remaining tokens to locked 1y balances
    // ------------------------------------------------------------------------
    function addRemainingTokens() {
        // Only the crowdsale contract can call this function
        require(msg.sender == address(tokenContract));
        // Total tokens to be created
        uint remainingTokens = TOKENS_TOTAL;
        // Minus precommitments and public crowdsale tokens
        remainingTokens = remainingTokens.sub(tokenContract.totalSupply());
        // Minus 1y locked tokens
        remainingTokens = remainingTokens.sub(totalSupplyLocked1Y);
        // Minus 2y locked tokens
        remainingTokens = remainingTokens.sub(totalSupplyLocked2Y);
        // Unsold tranche1 and tranche2 tokens to be locked for 1y 
        add1Y(TRANCHE2_ACCOUNT, remainingTokens);
    }


    // ------------------------------------------------------------------------
    // Add to 1y locked balances and totalSupply
    // ------------------------------------------------------------------------
    function add1Y(address account, uint value) private {
        balancesLocked1Y[account] = balancesLocked1Y[account].add(value);
        totalSupplyLocked1Y = totalSupplyLocked1Y.add(value);
    }


    // ------------------------------------------------------------------------
    // Add to 2y locked balances and totalSupply
    // ------------------------------------------------------------------------
    function add2Y(address account, uint value) private {
        balancesLocked2Y[account] = balancesLocked2Y[account].add(value);
        totalSupplyLocked2Y = totalSupplyLocked2Y.add(value);
    }


    // ------------------------------------------------------------------------
    // 1y locked balances for an account
    // ------------------------------------------------------------------------
    function balanceOfLocked1Y(address account) constant returns (uint balance) {
        return balancesLocked1Y[account];
    }


    // ------------------------------------------------------------------------
    // 2y locked balances for an account
    // ------------------------------------------------------------------------
    function balanceOfLocked2Y(address account) constant returns (uint balance) {
        return balancesLocked2Y[account];
    }


    // ------------------------------------------------------------------------
    // 1y and 2y locked balances for an account
    // ------------------------------------------------------------------------
    function balanceOfLocked(address account) constant returns (uint balance) {
        return balancesLocked1Y[account].add(balancesLocked2Y[account]);
    }


    // ------------------------------------------------------------------------
    // 1y and 2y locked total supply
    // ------------------------------------------------------------------------
    function totalSupplyLocked() constant returns (uint) {
        return totalSupplyLocked1Y + totalSupplyLocked2Y;
    }


    // ------------------------------------------------------------------------
    // An account can unlock their 1y locked tokens 1y after token launch date
    // ------------------------------------------------------------------------
    function unlock1Y() {
        require(now >= LOCKED_1Y_DATE);
        uint amount = balancesLocked1Y[msg.sender];
        require(amount > 0);
        balancesLocked1Y[msg.sender] = 0;
        totalSupplyLocked1Y = totalSupplyLocked1Y.sub(amount);
        if (!tokenContract.transfer(msg.sender, amount)) throw;
    }


    // ------------------------------------------------------------------------
    // An account can unlock their 2y locked tokens 2y after token launch date
    // ------------------------------------------------------------------------
    function unlock2Y() {
        require(now >= LOCKED_2Y_DATE);
        uint amount = balancesLocked2Y[msg.sender];
        require(amount > 0);
        balancesLocked2Y[msg.sender] = 0;
        totalSupplyLocked2Y = totalSupplyLocked2Y.sub(amount);
        if (!tokenContract.transfer(msg.sender, amount)) throw;
    }
}



// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// ----------------------------------------------------------------------------
contract ERC20Token is ERC20Interface, Owned {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // symbol(), name() and decimals()
    // ------------------------------------------------------------------------
    string public symbol;
    string public name;
    uint8 public decimals;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ERC20Token(
        string _symbol, 
        string _name, 
        uint8 _decimals, 
        uint _totalSupply
    ) Owned() {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[owner] = _totalSupply;
    }


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
        if (balances[msg.sender] >= _amount             // User has balance
            && _amount > 0                              // Non-zero transfer
            && balances[_to] + _amount > balances[_to]  // Overflow check
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
        uint _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(
        address _from,
        address _to,
        uint _amount
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
    ) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}


// ----------------------------------------------------------------------------
// openANX crowdsale token smart contract
// ----------------------------------------------------------------------------
contract OpenANXToken is ERC20Token, OpenANXTokenConfig {

    // ------------------------------------------------------------------------
    // Has the crowdsale been finalised?
    // ------------------------------------------------------------------------
    bool public finalised = false;

    // ------------------------------------------------------------------------
    // Number of tokens per 1,000 ETH
    // This can be adjusted as the ETH/USD rate changes
    //
    // Indicative rate of ETH per token of 0.00290923 at 8 June 2017
    // 
    // This is the same as 1 / 0.00290923 = 343.733565238912015 OAX per ETH
    //
    // tokensPerEther  = 343.733565238912015
    // tokensPerKEther = 343,733.565238912015
    // tokensPerKEther = 343,734 rounded to an uint, six significant figures
    // ------------------------------------------------------------------------
    uint public tokensPerKEther = 343734;

    // ------------------------------------------------------------------------
    // Locked Tokens - holds the 1y and 2y locked tokens information
    // ------------------------------------------------------------------------
    LockedTokens public lockedTokens;

    // ------------------------------------------------------------------------
    // Wallet receiving the raised funds 
    // ------------------------------------------------------------------------
    address public wallet;

    // ------------------------------------------------------------------------
    // Crowdsale participant&#39;s accounts need to be KYC verified KYC before
    // the participant can move their tokens
    // ------------------------------------------------------------------------
    mapping(address => bool) public kycRequired;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function OpenANXToken(address _wallet) 
        ERC20Token(SYMBOL, NAME, DECIMALS, 0)
    {
        wallet = _wallet;
        lockedTokens = new LockedTokens(this);
        require(address(lockedTokens) != 0x0);
    }

    // ------------------------------------------------------------------------
    // openANX can change the crowdsale wallet address
    // Can be set at any time before or during the crowdsale
    // Not relevant after the crowdsale is finalised as no more contributions
    // are accepted
    // ------------------------------------------------------------------------
    function setWallet(address _wallet) onlyOwner {
        wallet = _wallet;
        WalletUpdated(wallet);
    }
    event WalletUpdated(address newWallet);


    // ------------------------------------------------------------------------
    // openANX can set number of tokens per 1,000 ETH
    // Can only be set before the start of the crowdsale
    // ------------------------------------------------------------------------
    function setTokensPerKEther(uint _tokensPerKEther) onlyOwner {
        require(now < START_DATE);
        require(_tokensPerKEther > 0);
        tokensPerKEther = _tokensPerKEther;
        TokensPerKEtherUpdated(tokensPerKEther);
    }
    event TokensPerKEtherUpdated(uint tokensPerKEther);


    // ------------------------------------------------------------------------
    // Accept ethers to buy tokens during the crowdsale
    // ------------------------------------------------------------------------
    function () payable {
        proxyPayment(msg.sender);
    }


    // ------------------------------------------------------------------------
    // Accept ethers from one account for tokens to be created for another
    // account. Can be used by exchanges to purchase tokens on behalf of 
    // it&#39;s user
    // ------------------------------------------------------------------------
    function proxyPayment(address participant) payable {
        // No contributions after the crowdsale is finalised
        require(!finalised);

        // No contributions before the start of the crowdsale
        require(now >= START_DATE);
        // No contributions after the end of the crowdsale
        require(now <= END_DATE);

        // No contributions below the minimum (can be 0 ETH)
        require(msg.value >= CONTRIBUTIONS_MIN);
        // No contributions above a maximum (if maximum is set to non-0)
        require(CONTRIBUTIONS_MAX == 0 || msg.value < CONTRIBUTIONS_MAX);

        // Calculate number of tokens for contributed ETH
        // `18` is the ETH decimals
        // `- decimals` is the token decimals
        // `+ 3` for the tokens per 1,000 ETH factor
        uint tokens = msg.value * tokensPerKEther / 10**uint(18 - decimals + 3);

        // Check if the hard cap will be exceeded
        require(totalSupply + tokens <= TOKENS_HARD_CAP);

        // Add tokens purchased to account&#39;s balance and total supply
        balances[participant] = balances[participant].add(tokens);
        totalSupply = totalSupply.add(tokens);

        // Log the tokens purchased 
        Transfer(0x0, participant, tokens);
        TokensBought(participant, msg.value, this.balance, tokens,
             totalSupply, tokensPerKEther);

        // KYC verification required before participant can transfer the tokens
        kycRequired[participant] = true;

        // Transfer the contributed ethers to the crowdsale wallet
        if (!wallet.send(msg.value)) throw;
    }
    event TokensBought(address indexed buyer, uint ethers, 
        uint newEtherBalance, uint tokens, uint newTotalSupply, 
        uint tokensPerKEther);


    // ------------------------------------------------------------------------
    // openANX to finalise the crowdsale - to adding the locked tokens to 
    // this contract and the total supply
    // ------------------------------------------------------------------------
    function finalise() onlyOwner {
        // Can only finalise if raised > soft cap or after the end date
        require(totalSupply >= TOKENS_SOFT_CAP || now > END_DATE);

        // Can only finalise once
        require(!finalised);

        // Calculate and add remaining tokens to locked balances
        lockedTokens.addRemainingTokens();

        // Allocate locked and premined tokens
        balances[address(lockedTokens)] = balances[address(lockedTokens)].
            add(lockedTokens.totalSupplyLocked());
        totalSupply = totalSupply.add(lockedTokens.totalSupplyLocked());

        // Can only finalise once
        finalised = true;
    }


    // ------------------------------------------------------------------------
    // openANX to add precommitment funding token balance before the crowdsale
    // commences
    // ------------------------------------------------------------------------
    function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now < START_DATE);
        require(balance > 0);
        balances[participant] = balances[participant].add(balance);
        totalSupply = totalSupply.add(balance);
        Transfer(0x0, participant, balance);
    }
    event PrecommitmentAdded(address indexed participant, uint balance);


    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account, with KYC
    // verification check for the crowdsale participant&#39;s first transfer
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends
        require(finalised);
        // Cannot transfer if KYC verification is required
        require(!kycRequired[msg.sender]);
        // Standard transfer
        return super.transfer(_to, _amount);
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account, with KYC verification check for the
    // crowdsale participant&#39;s first transfer
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
        // Cannot transfer before crowdsale ends
        require(finalised);
        // Cannot transfer if KYC verification is required
        require(!kycRequired[_from]);
        // Standard transferFrom
        return super.transferFrom(_from, _to, _amount);
    }


    // ------------------------------------------------------------------------
    // openANX to KYC verify the participant&#39;s account
    // ------------------------------------------------------------------------
    function kycVerify(address participant) onlyOwner {
        kycRequired[participant] = false;
        KycVerified(participant);
    }
    event KycVerified(address indexed participant);


    // ------------------------------------------------------------------------
    // Any account can burn _from&#39;s tokens as long as the _from account has 
    // approved the _amount to be burnt using
    //   approve(0x0, _amount)
    // ------------------------------------------------------------------------
    function burnFrom(
        address _from,
        uint _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                  // From a/c has balance
            && allowed[_from][0x0] >= _amount           // Transfer approved
            && _amount > 0                              // Non-zero transfer
            && balances[0x0] + _amount > balances[0x0]  // Overflow check
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][0x0] = allowed[_from][0x0].sub(_amount);
            balances[0x0] = balances[0x0].add(_amount);
            totalSupply = totalSupply.sub(_amount);
            Transfer(_from, 0x0, _amount);
            return true;
        } else {
            return false;
        }
    }


    // ------------------------------------------------------------------------
    // 1y locked balances for an account
    // ------------------------------------------------------------------------
    function balanceOfLocked1Y(address account) constant returns (uint balance) {
        return lockedTokens.balanceOfLocked1Y(account);
    }


    // ------------------------------------------------------------------------
    // 2y locked balances for an account
    // ------------------------------------------------------------------------
    function balanceOfLocked2Y(address account) constant returns (uint balance) {
        return lockedTokens.balanceOfLocked2Y(account);
    }


    // ------------------------------------------------------------------------
    // 1y and 2y locked balances for an account
    // ------------------------------------------------------------------------
    function balanceOfLocked(address account) constant returns (uint balance) {
        return lockedTokens.balanceOfLocked(account);
    }


    // ------------------------------------------------------------------------
    // 1y locked total supply
    // ------------------------------------------------------------------------
    function totalSupplyLocked1Y() constant returns (uint) {
        if (finalised) {
            return lockedTokens.totalSupplyLocked1Y();
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // 2y locked total supply
    // ------------------------------------------------------------------------
    function totalSupplyLocked2Y() constant returns (uint) {
        if (finalised) {
            return lockedTokens.totalSupplyLocked2Y();
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // 1y and 2y locked total supply
    // ------------------------------------------------------------------------
    function totalSupplyLocked() constant returns (uint) {
        if (finalised) {
            return lockedTokens.totalSupplyLocked();
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // Unlocked total supply
    // ------------------------------------------------------------------------
    function totalSupplyUnlocked() constant returns (uint) {
        if (finalised && totalSupply >= lockedTokens.totalSupplyLocked()) {
            return totalSupply.sub(lockedTokens.totalSupplyLocked());
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // openANX can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }
}