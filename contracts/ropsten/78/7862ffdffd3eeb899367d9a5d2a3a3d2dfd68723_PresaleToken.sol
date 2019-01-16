pragma solidity 0.4.25;
// ERC20 token interface is implemented only partially.
// Token transfer is prohibited due to spec (see PRESALE-SPEC.md),
// hence some functions are left undefined:
//  - transfer, transferFrom,
//  - approve, allowance.
contract PresaleToken {
    /// @dev Constructor
    /// @param _tokenManager Token manager address.
    function PresaleToken(address _tokenManager, address _escrow) {
        tokenManager = _tokenManager;
        escrow = _escrow;
    }
    /*/
     *  Constants
    /*/
    string public constant name = "XERX Presale Token";
    string public constant symbol = "XPT";
    uint   public constant decimals = 18;
    uint public constant PRICE = 420; // 420 XPT per Ether
    //  price
    // Cup is 2 381 ETH
    // 1 eth = 420 presale tokens
    // ETH price ~210$ for 12.11.2018
    // Cup in $ is ~ 500 000$
    uint public constant TOKEN_SUPPLY_LIMIT = 420 * 2381 * (1 ether / 1 wei);
    /*/
     *  Token state
    /*/
    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }
    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0; // amount of tokens already sold
    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager;
    // Gathered funds can be withdrawn only to escrow&#39;s address.
    address public escrow;
    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager;
    mapping (address => uint256) private balance;
    modifier onlyTokenManager()     { if(msg.sender != tokenManager) throw; _; }
    modifier onlyCrowdsaleManager() { if(msg.sender != crowdsaleManager) throw; _; }
    /*/
     *  Events
    /*/
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    /*/
     *  Public functions
    /*/
    function() payable {
        buyTokens(msg.sender);
    }
    /// @dev Lets buy you some tokens.
    function buyTokens(address _buyer) public payable {
        // Available only if presale is running.
        if(currentPhase != Phase.Running) throw;
        if(msg.value == 0) throw;
        uint newTokens = msg.value * PRICE;
        if (totalSupply + newTokens > TOKEN_SUPPLY_LIMIT) throw;
        balance[_buyer] += newTokens;
        totalSupply += newTokens;
        LogBuy(_buyer, newTokens);
    }
    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
        // Available only during migration phase
        if(currentPhase != Phase.Migrating) throw;
        uint tokens = balance[_owner];
        if(tokens == 0) throw;
        balance[_owner] = 0;
        totalSupply -= tokens;
        LogBurn(_owner, tokens);
        // Automatically switch phase when migration is done.
        if(totalSupply == 0) {
            currentPhase = Phase.Migrated;
            LogPhaseSwitch(Phase.Migrated);
        }
    }
    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
        return balance[_owner];
    }
    /*/
     *  Administrative functions
    /*/
    function setPresalePhase(Phase _nextPhase) public
        onlyTokenManager
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                // switch to migration phase only if crowdsale manager is set
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                // switch to migrated only if everyting is migrated
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);
        if(!canSwitchPhase) throw;
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }
    function withdrawEther() public
        onlyTokenManager
    {
        // Available at any phase.
        if(this.balance > 0) {
            if(!escrow.send(this.balance)) throw;
        }
    }
    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
        // You can&#39;t change crowdsale contract when migration is in progress.
        if(currentPhase == Phase.Migrating) throw;
        crowdsaleManager = _mgr;
    }
}