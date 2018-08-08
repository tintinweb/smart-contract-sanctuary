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
contract VibeCoin {
    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success)
    {}
}


contract VIBEXToken is StandardToken {

    // Token metadata
    string public constant name = "VIBEX Exchange Token";
    string public constant symbol = "VIBEX";
    uint256 public constant decimals = 18;

    // Deposit address of account controlled by the creators
    address public ethFundDeposit = 0xFC1CCdcA6b4670516504409341A31e444FF6f43F;
    address public tokenExchangeAddress = 0xe8ff5c9c75deb346acac493c463c8950be03dfba;
    address public tokenAccountAddress = 0xFC1CCdcA6b4670516504409341A31e444FF6f43F;
    //Access to token contract for vibe exchange
    VibeCoin public tokenExchange;

    // Fundraising parameters
    enum ContractState { Fundraising, Finalized, Redeeming, Paused }
    ContractState public state;           // Current state of the contract
    ContractState private savedState;     // State of the contract before pause

    //start date: 08/07/2017 @ 12:00am (UTC)
    uint public startDate = 1502064000;
    //start date: 09/21/2017 @ 11:59pm (UTC)
    uint public endDate = 1506038399;
    //deadlines 1: 08/21/2017 @ 11:59pm (UTC) +30%
    //deadlines 2: 08/28/2017 @ 11:59pm (UTC) +20%
    //deadlines 3: 09/05/2017 @ 11:59pm (UTC) +10%
    //deadlines 4: 09/12/2017 @ 11:59pm (UTC) +5%
    //deadlines 5: 09/21/2017 @ 11:59pm (UTC) +0%
    uint[5] public deadlines = [1503359999, 1503964799, 1504655999, 1505260799, 1506038399];
	uint[5] public prices = [130, 120, 110, 105, 100];
    
    uint256 public constant ETH_RECEIVED_CAP = 115 * (10**3) * 10**decimals; // 115 000 ETH
    uint256 public constant ETH_RECEIVED_MIN = 0;//1 * 10**decimals; // 0 ETH
    uint256 public constant TOKEN_MIN = 1 * 10**decimals; // 1 VIBEX
    uint256 public constant MIN_ETH_TRANS = 25 * 10**decimals; // 25 ETH

    // We need to keep track of how much ether have been contributed, since we have a cap for ETH too
    uint256 public totalReceivedEth = 0;

    // Since we have different exchange rates at different stages, we need to keep track
    // of how much ether each contributed in case that we need to issue a refund
    mapping (address => uint256) private ethBalances;

    // Events used for logging
    event LogCreateVIBEX(address indexed _to, uint256 _value);
    event LogRedeemVIBE(address indexed _to, uint256 _value, uint256 _value2, uint256 _value3);

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
    function VIBEXToken()
    {
        // Contract state
        state = ContractState.Fundraising;
        savedState = ContractState.Fundraising;
        tokenExchange = VibeCoin(tokenExchangeAddress);
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
    
    /// @dev Accepts ether and creates new VIBEX tokens
    function ()
    payable
    external
    isFundraising
    {
        require(now >= startDate);
        require(now <= endDate);
        require(msg.value > 0);
        
        if(msg.value < MIN_ETH_TRANS && now < deadlines[0]) throw;

        // First we check the ETH cap, as it&#39;s easier to calculate, return
        // the contribution if the cap has been reached already
        uint256 checkedReceivedEth = safeAdd(totalReceivedEth, msg.value);
        require(checkedReceivedEth <= ETH_RECEIVED_CAP);

        // If all is fine with the ETH cap, we continue to check the
        // minimum amount of tokens
        uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());
        require(tokens >= TOKEN_MIN);

        // Only when all the checks have passed, then we update the state (ethBalances,
        // totalReceivedEth, totalSupply, and balances) of the contract
        ethBalances[msg.sender] = safeAdd(ethBalances[msg.sender], msg.value);
        totalReceivedEth = checkedReceivedEth;
        totalSupply = safeAdd(totalSupply, tokens);
        balances[msg.sender] += tokens;  // safeAdd not needed; bad semantics to use here
        
        // Send the ETH to Vibehub Creators
        ethFundDeposit.transfer(msg.value);

        // Log the creation of this tokens
        LogCreateVIBEX(msg.sender, tokens);
    }


    /// @dev Returns the current token price
    function getCurrentTokenPrice()
    private
    constant
    returns (uint256 currentPrice)
    {
        for(var i = 0; i < deadlines.length; i++)
            if(now<=deadlines[i])
                return prices[i];
        return prices[prices.length-1];//should never be returned, but to be sure to not divide by 0
    }


    /// @dev Redeems VIBEs and records the Vibehub address of the sender
    function redeemTokens()
    external
    isRedeeming
    {
        uint256 vibeVal = balances[msg.sender];
        require(vibeVal >= TOKEN_MIN); // At least TOKEN_MIN tokens have to be redeemed

        // Move the tokens of the caller to Vibehub&#39;s address
        //if (!super.transfer(ethFundDeposit, vibeVal)) throw;
        balances[msg.sender]=0;
        
        uint256 exchangeRate = ((160200000* 10**decimals)/totalSupply);
        uint256 numTokens = safeMult(exchangeRate, vibeVal); // Extra safe
        if(!tokenExchange.transferFrom(tokenAccountAddress, msg.sender, numTokens)) throw;

        // Log the redeeming of this tokens
        LogRedeemVIBE(msg.sender, numTokens, vibeVal, exchangeRate);
    }




    /// @dev Ends the fundraising period and sends the ETH to the ethFundDeposit wallet
    function finalize()
    external
    isFundraising
    minimumReached
    onlyOwner // Only the owner of the ethFundDeposit address can finalize the contract
    {
        require(now > endDate || totalReceivedEth >= ETH_RECEIVED_CAP); // Only allow to finalize the contract before the ending block if we already reached any of the caps

        // Move the contract to Finalized state
        state = ContractState.Finalized;
        savedState = ContractState.Finalized;
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

}