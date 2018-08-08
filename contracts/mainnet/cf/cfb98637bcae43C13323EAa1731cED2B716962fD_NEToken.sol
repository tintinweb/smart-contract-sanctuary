pragma solidity ^0.4.11;

/* taking ideas from FirstBlood token */
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token, SafeMath {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function transfer(address _to, uint256 _value)
    returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSubtract(balances[_from], _value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
    onlyPayloadSize(2)
    returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    constant
    onlyPayloadSize(2)
    returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

/* Taking ideas from BAT token */
contract NEToken is StandardToken {

    // Token metadata
    string public constant name = "Nimiq Network Interim Token";
    string public constant symbol = "NET";
    uint256 public constant decimals = 18;
    string public version = "0.8";

    // Deposit address of Multisig account controlled by the creators
    address public ethFundDeposit;

    // Fundraising parameters
    enum ContractState { Fundraising, Finalized, Redeeming, Paused }
    ContractState public state;           // Current state of the contract
    ContractState private savedState;     // State of the contract before pause

    uint256 public fundingStartBlock;        // These two blocks need to be chosen to comply with the
    uint256 public fundingEndBlock;          // start date and 28 day duration requirements
    uint256 public exchangeRateChangesBlock; // block number that triggers the exchange rate change

    uint256 public constant TOKEN_FIRST_EXCHANGE_RATE = 175; // 175 NETs per 1 ETH
    uint256 public constant TOKEN_SECOND_EXCHANGE_RATE = 125; // 125 NETs per 1 ETH
    uint256 public constant TOKEN_CREATION_CAP = 10.5 * (10**6) * 10**decimals; // 10.5 million NETs
    uint256 public constant ETH_RECEIVED_CAP = 60 * (10**3) * 10**decimals; // 60 000 ETH
    uint256 public constant ETH_RECEIVED_MIN = 5 * (10**3) * 10**decimals; // 5 000 ETH
    uint256 public constant TOKEN_MIN = 1 * 10**decimals; // 1 NET

    // We need to keep track of how much ether have been contributed, since we have a cap for ETH too
    uint256 public totalReceivedEth = 0;

    // Since we have different exchange rates at different stages, we need to keep track
    // of how much ether each contributed in case that we need to issue a refund
    mapping (address => uint256) private ethBalances;

    // Events used for logging
    event LogRefund(address indexed _to, uint256 _value);
    event LogCreateNET(address indexed _to, uint256 _value);
    event LogRedeemNET(address indexed _to, uint256 _value, bytes32 _nimiqAddress);

    modifier isFinalized() {
        require(state == ContractState.Finalized);
        _;
    }

    modifier isFundraising() {
        require(state == ContractState.Fundraising);
        _;
    }

    modifier isRedeeming() {
        require(state == ContractState.Redeeming);
        _;
    }

    modifier isPaused() {
        require(state == ContractState.Paused);
        _;
    }

    modifier notPaused() {
        require(state != ContractState.Paused);
        _;
    }

    modifier isFundraisingIgnorePaused() {
        require(state == ContractState.Fundraising || (state == ContractState.Paused && savedState == ContractState.Fundraising));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ethFundDeposit);
        _;
    }

    modifier minimumReached() {
        require(totalReceivedEth >= ETH_RECEIVED_MIN);
        _;
    }

    // Constructor
    function NEToken(
    address _ethFundDeposit,
    uint256 _fundingStartBlock,
    uint256 _fundingEndBlock,
    uint256 _exchangeRateChangesBlock)
    {
        // Check that the parameters make sense
        require(block.number <= _fundingStartBlock); // The start of the fundraising should happen in the future
        require(_fundingStartBlock <= _exchangeRateChangesBlock); // The exchange rate change should happen after the start of the fundraising
        require(_exchangeRateChangesBlock <= _fundingEndBlock); // And the end of the fundraising should happen after the exchange rate change

        // Contract state
        state = ContractState.Fundraising;
        savedState = ContractState.Fundraising;

        ethFundDeposit = _ethFundDeposit;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        exchangeRateChangesBlock = _exchangeRateChangesBlock;
        totalSupply = 0;
    }

    // Overridden method to check for end of fundraising before allowing transfer of tokens
    function transfer(address _to, uint256 _value)
    isFinalized // Only allow token transfer after the fundraising has ended
    onlyPayloadSize(2)
    returns (bool success)
    {
        return super.transfer(_to, _value);
    }


    // Overridden method to check for end of fundraising before allowing transfer of tokens
    function transferFrom(address _from, address _to, uint256 _value)
    isFinalized // Only allow token transfer after the fundraising has ended
    onlyPayloadSize(3)
    returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }


    /// @dev Accepts ether and creates new NET tokens
    function createTokens()
    payable
    external
    isFundraising
    {
        require(block.number >= fundingStartBlock);
        require(block.number <= fundingEndBlock);
        require(msg.value > 0);

        // First we check the ETH cap, as it&#39;s easier to calculate, return
        // the contribution if the cap has been reached already
        uint256 checkedReceivedEth = safeAdd(totalReceivedEth, msg.value);
        require(checkedReceivedEth <= ETH_RECEIVED_CAP);

        // If all is fine with the ETH cap, we continue to check the
        // minimum amount of tokens and the cap for how many tokens
        // have been generated so far
        uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());
        require(tokens >= TOKEN_MIN);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        require(checkedSupply <= TOKEN_CREATION_CAP);

        // Only when all the checks have passed, then we update the state (ethBalances,
        // totalReceivedEth, totalSupply, and balances) of the contract
        ethBalances[msg.sender] = safeAdd(ethBalances[msg.sender], msg.value);
        totalReceivedEth = checkedReceivedEth;
        totalSupply = checkedSupply;
        balances[msg.sender] += tokens;  // safeAdd not needed; bad semantics to use here

        // Log the creation of this tokens
        LogCreateNET(msg.sender, tokens);
    }


    /// @dev Returns the current token price
    function getCurrentTokenPrice()
    private
    constant
    returns (uint256 currentPrice)
    {
        if (block.number < exchangeRateChangesBlock) {
            return TOKEN_FIRST_EXCHANGE_RATE;
        } else {
            return TOKEN_SECOND_EXCHANGE_RATE;
        }
    }


    /// @dev Redeems NETs and records the Nimiq address of the sender
    function redeemTokens(bytes32 nimiqAddress)
    external
    isRedeeming
    {
        uint256 netVal = balances[msg.sender];
        require(netVal >= TOKEN_MIN); // At least TOKEN_MIN tokens have to be redeemed

        // Move the tokens of the caller to Nimiq&#39;s address
        if (!super.transfer(ethFundDeposit, netVal)) throw;

        // Log the redeeming of this tokens
        LogRedeemNET(msg.sender, netVal, nimiqAddress);
    }


    /// @dev Allows to transfer ether from the contract as soon as the minimum is reached
    function retrieveEth(uint256 _value)
    external
    minimumReached
    onlyOwner
    {
        require(_value <= this.balance);

        // send the eth to Nimiq Creators
        ethFundDeposit.transfer(_value);
    }


    /// @dev Ends the fundraising period and sends the ETH to the Multisig wallet
    function finalize()
    external
    isFundraising
    minimumReached
    onlyOwner // Only the owner of the ethFundDeposit address can finalize the contract
    {
        require(block.number > fundingEndBlock || totalSupply >= TOKEN_CREATION_CAP || totalReceivedEth >= ETH_RECEIVED_CAP); // Only allow to finalize the contract before the ending block if we already reached any of the two caps

        // Move the contract to Finalized state
        state = ContractState.Finalized;
        savedState = ContractState.Finalized;

        // Send the ETH to Nimiq Creators
        ethFundDeposit.transfer(this.balance);
    }


    /// @dev Starts the redeeming period
    function startRedeeming()
    external
    isFinalized // The redeeming period can only be started after the contract is finalized
    onlyOwner   // Only the owner of the ethFundDeposit address can start the redeeming period
    {
        // Move the contract to Redeeming state
        state = ContractState.Redeeming;
        savedState = ContractState.Redeeming;
    }


    /// @dev Pauses the contract
    function pause()
    external
    notPaused   // Prevent the contract getting stuck in the Paused state
    onlyOwner   // Only the owner of the ethFundDeposit address can pause the contract
    {
        // Move the contract to Paused state
        savedState = state;
        state = ContractState.Paused;
    }


    /// @dev Proceeds with the contract
    function proceed()
    external
    isPaused
    onlyOwner   // Only the owner of the ethFundDeposit address can proceed with the contract
    {
        // Move the contract to the previous state
        state = savedState;
    }


    /// @dev Allows contributors to recover their ether in case the minimum funding goal is not reached
    function refund()
    external
    isFundraisingIgnorePaused // Refunding is only possible in the fundraising phase (no matter if paused) by definition
    {
        require(block.number > fundingEndBlock); // Prevents refund until fundraising period is over
        require(totalReceivedEth < ETH_RECEIVED_MIN);  // No refunds if the minimum has been reached

        uint256 netVal = balances[msg.sender];
        require(netVal > 0);
        uint256 ethVal = ethBalances[msg.sender];
        require(ethVal > 0);

        // Update the state only after all the checks have passed
        balances[msg.sender] = 0;
        ethBalances[msg.sender] = 0;
        totalSupply = safeSubtract(totalSupply, netVal); // Extra safe

        // Log this refund
        LogRefund(msg.sender, ethVal);

        // Send the contributions only after we have updated all the balances
        // If you&#39;re using a contract, make sure it works with .transfer() gas limits
        msg.sender.transfer(ethVal);
    }
}