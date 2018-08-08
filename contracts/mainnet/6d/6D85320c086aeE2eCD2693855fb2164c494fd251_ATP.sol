pragma solidity ^0.4.11;

contract ATP {
    
    string public constant name = "ATL Presale Token";
    string public constant symbol = "ATP";
    uint   public constant decimals = 18;
    
    uint public constant PRICE = 505;
    uint public constant TOKEN_SUPPLY_LIMIT = 2812500 * (1 ether / 1 wei);
    
    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }
    
    Phase public currentPhase = Phase.Created;
    
    address public tokenManager;
    address public escrow;
    address public crowdsaleManager;
    
    uint public totalSupply = 0;
    mapping (address => uint256) private balances;
    
    event Buy(address indexed buyer, uint amount);
    event Burn(address indexed owner, uint amount);
    event PhaseSwitch(Phase newPhase);
    
    function ATP(address _tokenManager, address _escrow) {
        tokenManager = _tokenManager;
        escrow = _escrow;
    }
    
    function() payable {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address _buyer) public payable {
        require(currentPhase == Phase.Running);
        require(msg.value != 0);
        
        uint tokenAmount = msg.value * PRICE;
        require(totalSupply + tokenAmount <= TOKEN_SUPPLY_LIMIT);
        
        balances[_buyer] += tokenAmount;
        totalSupply += tokenAmount;
        Buy(_buyer, tokenAmount);
    }
    
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }
    
    modifier onlyTokenManager() {
        require(msg.sender == tokenManager);
        _;
    }
    
    function setPresalePhase(Phase _nextPhase) public onlyTokenManager {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);
        
        require(canSwitchPhase);
        currentPhase = _nextPhase;
        PhaseSwitch(_nextPhase);
    }
    
    function setCrowdsaleManager(address _mgr) public onlyTokenManager {
        require(currentPhase != Phase.Migrating);
        crowdsaleManager = _mgr;
    }
    
    function withdrawEther() public onlyTokenManager {
        if(this.balance > 0) {
            escrow.transfer(this.balance);
        }
    }
    
    modifier onlyCrowdsaleManager() { 
        require(msg.sender == crowdsaleManager); 
        _;
    }
    
    function burnTokens(address _owner) public onlyCrowdsaleManager {
        require(currentPhase == Phase.Migrating);
        
        uint tokens = balances[_owner];
        require(tokens > 0);
        
        balances[_owner] = 0;
        totalSupply -= tokens;
        Burn(_owner, tokens);
        
        if(totalSupply == 0) {
            currentPhase = Phase.Migrated;
            PhaseSwitch(Phase.Migrated);
        }
    }
    
}