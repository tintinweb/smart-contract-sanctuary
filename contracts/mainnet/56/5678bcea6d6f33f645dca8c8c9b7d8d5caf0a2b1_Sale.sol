contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract HumanStandardToken is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract Disbursement {

    /*
     *  Storage
     */
    address public owner;
    address public receiver;
    uint public disbursementPeriod;
    uint public startDate;
    uint public withdrawnTokens;
    Token public token;

    /*
     *  Modifiers
     */
    modifier isOwner() {
        if (msg.sender != owner)
            // Only owner is allowed to proceed
            revert();
        _;
    }

    modifier isReceiver() {
        if (msg.sender != receiver)
            // Only receiver is allowed to proceed
            revert();
        _;
    }

    modifier isSetUp() {
        if (address(token) == 0)
            // Contract is not set up
            revert();
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor function sets contract owner
    /// @param _receiver Receiver of vested tokens
    /// @param _disbursementPeriod Vesting period in seconds
    /// @param _startDate Start date of disbursement period (cliff)
    function Disbursement(address _receiver, uint _disbursementPeriod, uint _startDate)
        public
    {
        if (_receiver == 0 || _disbursementPeriod == 0)
            // Arguments are null
            revert();
        owner = msg.sender;
        receiver = _receiver;
        disbursementPeriod = _disbursementPeriod;
        startDate = _startDate;
        if (startDate == 0)
            startDate = now;
    }

    /// @dev Setup function sets external contracts&#39; addresses
    /// @param _token Token address
    function setup(Token _token)
        public
        isOwner
    {
        if (address(token) != 0 || address(_token) == 0)
            // Setup was executed already or address is null
            revert();
        token = _token;
    }

    /// @dev Transfers tokens to a given address
    /// @param _to Address of token receiver
    /// @param _value Number of tokens to transfer
    function withdraw(address _to, uint256 _value)
        public
        isReceiver
        isSetUp
    {
        uint maxTokens = calcMaxWithdraw();
        if (_value > maxTokens)
            revert();
        withdrawnTokens += _value;
        token.transfer(_to, _value);
    }

    /// @dev Calculates the maximum amount of vested tokens
    /// @return Number of vested tokens to withdraw
    function calcMaxWithdraw()
        public
        constant
        returns (uint)
    {
        uint maxTokens = (token.balanceOf(this) + withdrawnTokens) * (now - startDate) / disbursementPeriod;
        if (withdrawnTokens >= maxTokens || startDate > now)
            return 0;
        return maxTokens - withdrawnTokens;
    }
}

contract Filter {

    event SetupAllowance(address indexed beneficiary, uint amount);

    Disbursement public disburser;
    address public owner;
    mapping(address => Beneficiary) public beneficiaries;

    struct Beneficiary {
        uint claimAmount;
        bool claimed;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Filter(
        address[] _beneficiaries,
        uint[] _beneficiaryTokens
    ) {
        owner = msg.sender;
        for(uint i = 0; i < _beneficiaries.length; i++) {
            beneficiaries[_beneficiaries[i]] = Beneficiary({
                claimAmount: _beneficiaryTokens[i],
                claimed: false
            });
            SetupAllowance(_beneficiaries[i],
                           beneficiaries[_beneficiaries[i]].claimAmount);
        }
    }

    function setup(Disbursement _disburser)
        public
        onlyOwner
    {
        require(address(disburser) == 0 && address(_disburser) != 0);
        disburser = _disburser; 
    }

    function claim()
        public
    {
        require(beneficiaries[msg.sender].claimed == false);
        beneficiaries[msg.sender].claimed = true;
        disburser.withdraw(msg.sender, beneficiaries[msg.sender].claimAmount);
    }
}

contract Sale {

    /*
     * Events
     */

    event PurchasedTokens(address indexed purchaser, uint amount);
    event TransferredPreBuyersReward(address indexed preBuyer, uint amount);
    event TransferredFoundersTokens(address vault, uint amount);

    /*
     * Storage
     */

    address public owner;
    address public wallet;
    HumanStandardToken public token;
    uint public price;
    uint public startBlock;
    uint public freezeBlock;
    bool public emergencyFlag = false;
    bool public preSaleTokensDisbursed = false;
    bool public foundersTokensDisbursed = false;
    address[] public filters;

    /*
     * Modifiers
     */

    modifier saleStarted {
        require(block.number >= startBlock);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notFrozen {
        require(block.number < freezeBlock);
        _;
    }

    modifier setupComplete {
        assert(preSaleTokensDisbursed && foundersTokensDisbursed);
        _;
    }

    modifier notInEmergency {
        assert(emergencyFlag == false);
        _;
    }

    /*
     * Public functions
     */

    /// @dev Sale(): constructor for Sale contract
    /// @param _owner the address which owns the sale, can access owner-only functions
    /// @param _wallet the sale&#39;s beneficiary address 
    /// @param _tokenSupply the total number of AdToken to mint
    /// @param _tokenName AdToken&#39;s human-readable name
    /// @param _tokenDecimals the number of display decimals in AdToken balances
    /// @param _tokenSymbol AdToken&#39;s human-readable asset symbol
    /// @param _price price of the token in Wei (ADT/Wei pair price)
    /// @param _startBlock the block at which this contract will begin selling its ADT balance
    function Sale(
        address _owner,
        address _wallet,
        uint256 _tokenSupply,
        string _tokenName,
        uint8 _tokenDecimals,
        string _tokenSymbol,
        uint _price,
        uint _startBlock,
        uint _freezeBlock
    ) {
        owner = _owner;
        wallet = _wallet;
        token = new HumanStandardToken(_tokenSupply, _tokenName, _tokenDecimals, _tokenSymbol);
        price = _price;
        startBlock = _startBlock;
        freezeBlock = _freezeBlock;

        assert(token.transfer(this, token.totalSupply()));
        assert(token.balanceOf(this) == token.totalSupply());
        assert(token.balanceOf(this) == 10**18);
    }

    /// @dev distributeFoundersRewards(): private utility function called by constructor
    /// @param _preBuyers an array of addresses to which awards will be distributed
    /// @param _preBuyersTokens an array of integers specifying preBuyers rewards
    function distributePreBuyersRewards(
        address[] _preBuyers,
        uint[] _preBuyersTokens
    ) 
        public
        onlyOwner
    { 
        assert(!preSaleTokensDisbursed);

        for(uint i = 0; i < _preBuyers.length; i++) {
            require(token.transfer(_preBuyers[i], _preBuyersTokens[i]));
            TransferredPreBuyersReward(_preBuyers[i], _preBuyersTokens[i]);
        }

        preSaleTokensDisbursed = true;
    }

    /// @dev distributeTimelockedRewards(): private utility function called by constructor
    /// @param _founders an array of addresses specifying disbursement beneficiaries
    /// @param _foundersTokens an array of integers specifying disbursement amounts
    /// @param _founderTimelocks an array of UNIX timestamps specifying vesting dates
    function distributeFoundersRewards(
        address[] _founders,
        uint[] _foundersTokens,
        uint[] _founderTimelocks
    ) 
        public
        onlyOwner
    { 
        assert(preSaleTokensDisbursed);
        assert(!foundersTokensDisbursed);

        /* Total number of tokens to be disbursed for a given tranch. Used when
           tokens are transferred to disbursement contracts. */
        uint tokensPerTranch = 0;
        // Alias of founderTimelocks.length for legibility
        uint tranches = _founderTimelocks.length;
        // The number of tokens which may be withdrawn per founder for each tranch
        uint[] memory foundersTokensPerTranch = new uint[](_foundersTokens.length);

        // Compute foundersTokensPerTranch and tokensPerTranch
        for(uint i = 0; i < _foundersTokens.length; i++) {
            foundersTokensPerTranch[i] = _foundersTokens[i]/tranches;
            tokensPerTranch = tokensPerTranch + foundersTokensPerTranch[i];
        }

        /* Deploy disbursement and filter contract pairs, initialize both and store
           filter addresses in filters array. Finally, transfer tokensPerTranch to
           disbursement contracts. */
        for(uint j = 0; j < tranches; j++) {
            Filter filter = new Filter(_founders, foundersTokensPerTranch);
            filters.push(filter);
            Disbursement vault = new Disbursement(filter, 1, _founderTimelocks[j]);
            // Give the disbursement contract the address of the token it disburses.
            vault.setup(token);             
            /* Give the filter contract the address of the disbursement contract
               it access controls */
            filter.setup(vault);             
            // Transfer to the vault the tokens it is to disburse
            assert(token.transfer(vault, tokensPerTranch));
            TransferredFoundersTokens(vault, tokensPerTranch);
        }

        assert(token.balanceOf(this) == 5 * 10**17);
        foundersTokensDisbursed = true;
    }

    /// @dev purchaseToken(): function that exchanges ETH for ADT (main sale function)
    /// @notice You&#39;re about to purchase the equivalent of `msg.value` Wei in ADT tokens
    function purchaseTokens()
        saleStarted
        payable
        setupComplete
        notInEmergency
    {
        /* Calculate whether any of the msg.value needs to be returned to
           the sender. The tokenPurchase is the actual number of tokens which
           will be purchased once any excessAmount included in the msg.value
           is removed from the purchaseAmount. */
        uint excessAmount = msg.value % price;
        uint purchaseAmount = msg.value - excessAmount;
        uint tokenPurchase = purchaseAmount / price;

        // Cannot purchase more tokens than this contract has available to sell
        require(tokenPurchase <= token.balanceOf(this));

        // Return any excess msg.value
        if (excessAmount > 0) {
            msg.sender.transfer(excessAmount);
        }

        // Forward received ether minus any excessAmount to the wallet
        wallet.transfer(purchaseAmount);

        // Transfer the sum of tokens tokenPurchase to the msg.sender
        assert(token.transfer(msg.sender, tokenPurchase));

        PurchasedTokens(msg.sender, tokenPurchase);
    }

    /*
     * Owner-only functions
     */

    function changeOwner(address _newOwner)
        onlyOwner
    {
        require(_newOwner != 0);
        owner = _newOwner;
    }

    function changePrice(uint _newPrice)
        onlyOwner
        notFrozen
    {
        require(_newPrice != 0);
        price = _newPrice;
    }

    function changeWallet(address _wallet)
        onlyOwner
        notFrozen
    {
        require(_wallet != 0);
        wallet = _wallet;
    }

    function changeStartBlock(uint _newBlock)
        onlyOwner
        notFrozen
    {
        require(_newBlock != 0);

        freezeBlock = _newBlock - (startBlock - freezeBlock);
        startBlock = _newBlock;
    }

    function emergencyToggle()
        onlyOwner
    {
        emergencyFlag = !emergencyFlag;
    }

}