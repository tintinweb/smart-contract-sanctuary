pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}


// Migration Agent interface
contract MigrationAgent {
    function migrateFrom(address _from, uint _value);
}

contract GVToken is StandardToken {
    
    // Constants
    string public constant name = "Genesis Vision Token";
    string public constant symbol = "GVT";
    uint   public constant decimals = 18;
    uint   constant TOKEN_LIMIT = 44 * 1e6 * 1e18; 
    
    address public ico;

    // GVT transfers are blocked until ICO is finished.
    bool public isFrozen = true;

    // Token migration variables
    address public migrationMaster;
    address public migrationAgent;
    uint public totalMigrated;

    event Migrate(address indexed _from, address indexed _to, uint _value);

    // Constructor
    function GVToken(address _ico, address _migrationMaster) {
        require(_ico != 0);
        require(_migrationMaster != 0);
        ico = _ico;
        migrationMaster = _migrationMaster;
    }

    // Create tokens
    function mint(address holder, uint value) {
        require(msg.sender == ico);
        require(value > 0);
        require(totalSupply + value <= TOKEN_LIMIT);

        balances[holder] += value;
        totalSupply += value;
        Transfer(0x0, holder, value);
    }

    // Allow token transfer.
    function unfreeze() {
        require(msg.sender == ico);
        isFrozen = false;
    }

    // ERC20 functions
    // =========================

    function transfer(address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(!isFrozen);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(!isFrozen);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require(!isFrozen);
        return super.approve(_spender, _value);
    }

    // Token migration
    function migrate(uint value) external {
        require(migrationAgent != 0);
        require(value > 0);
        require(value <= balances[msg.sender]);

        balances[msg.sender] -= value;
        totalSupply -= value;
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        Migrate(msg.sender, migrationAgent, value);
    }

    // Set address of migration contract
    function setMigrationAgent(address _agent) external {
        require(migrationAgent == 0);
        require(msg.sender == migrationMaster);
        migrationAgent = _agent;
    }

    function setMigrationMaster(address _master) external {
        require(msg.sender == migrationMaster);
        require(_master != 0);
        migrationMaster = _master;
    }
}

contract GVOptionToken is StandardToken {
    
    address public optionProgram;

    string public name;
    string public symbol;
    uint   public constant decimals = 18;

    uint TOKEN_LIMIT;

    // Modifiers
    modifier optionProgramOnly { require(msg.sender == optionProgram); _; }

    // Constructor
    function GVOptionToken(
        address _optionProgram,
        string _name,
        string _symbol,
        uint _TOKEN_LIMIT
    ) {
        require(_optionProgram != 0);        
        optionProgram = _optionProgram;
        name = _name;
        symbol = _symbol;
        TOKEN_LIMIT = _TOKEN_LIMIT;
    }

    // Create tokens
    function buyOptions(address buyer, uint value) optionProgramOnly {
        require(value > 0);
        require(totalSupply + value <= TOKEN_LIMIT);

        balances[buyer] += value;
        totalSupply += value;
        Transfer(0x0, buyer, value);
    }
    
    function remainingTokensCount() returns(uint) {
        return TOKEN_LIMIT - totalSupply;
    }
    
    // Burn option tokens after execution during ICO
    function executeOption(address addr, uint optionsCount) 
        optionProgramOnly
        returns (uint) {
        if (balances[addr] < optionsCount) {
            optionsCount = balances[addr];
        }
        if (optionsCount == 0) {
            return 0;
        }

        balances[addr] -= optionsCount;
        totalSupply -= optionsCount;

        return optionsCount;
    }
}

contract GVOptionProgram {

    // Constants
    uint constant option30perCent = 26 * 1e16; // GVOT30 tokens per usd cent during option purchase 
    uint constant option20perCent = 24 * 1e16; // GVOT20 tokens per usd cent during option purchase
    uint constant option10perCent = 22 * 1e16; // GVOT10 tokens per usd cent during option purchase
    uint constant token30perCent  = 13684210526315800;  // GVT tokens per usd cent during execution of GVOT30
    uint constant token20perCent  = 12631578947368500;  // GVT tokens per usd cent during execution of GVOT20
    uint constant token10perCent  = 11578947368421100;  // GVT tokens per usd cent during execution of GVOT10

    string public constant option30name = "30% GVOT";
    string public constant option20name = "20% GVOT";
    string public constant option10name = "10% GVOT";

    string public constant option30symbol = "GVOT30";
    string public constant option20symbol = "GVOT20";
    string public constant option10symbol = "GVOT10";

    uint constant option30_TOKEN_LIMIT = 26 * 1e5 * 1e18;
    uint constant option20_TOKEN_LIMIT = 36 * 1e5 * 1e18;
    uint constant option10_TOKEN_LIMIT = 55 * 1e5 * 1e18;

    // Events
    event BuyOptions(address buyer, uint amount, string tx, uint8 optionType);
    event ExecuteOptions(address buyer, uint amount, string tx, uint8 optionType);

    // State variables
    address public gvAgent; // payments bot account
    address public team;    // team account
    address public ico;     

    GVOptionToken public gvOptionToken30;
    GVOptionToken public gvOptionToken20;
    GVOptionToken public gvOptionToken10;

    // Modifiers
    modifier icoOnly { require(msg.sender == ico); _; }
    
    // Constructor
    function GVOptionProgram(address _ico, address _gvAgent, address _team) {
        gvOptionToken30 = new GVOptionToken(this, option30name, option30symbol, option30_TOKEN_LIMIT);
        gvOptionToken20 = new GVOptionToken(this, option20name, option20symbol, option20_TOKEN_LIMIT);
        gvOptionToken10 = new GVOptionToken(this, option10name, option10symbol, option10_TOKEN_LIMIT);
        gvAgent = _gvAgent;
        team = _team;
        ico = _ico;
    }

    // Get remaining tokens for all types of option tokens
    function getBalance() public returns (uint, uint, uint) {
        return (gvOptionToken30.remainingTokensCount(), gvOptionToken20.remainingTokensCount(), gvOptionToken10.remainingTokensCount());
    }

    // Execute options during the ICO token purchase. Priority: GVOT30 -> GVOT20 -> GVOT10
    function executeOptions(address buyer, uint usdCents, string txHash) icoOnly
        returns (uint executedTokens, uint remainingCents) {
        require(usdCents > 0);

        (executedTokens, remainingCents) = executeIfAvailable(buyer, usdCents, txHash, gvOptionToken30, 0, token30perCent);
        if (remainingCents == 0) {
            return (executedTokens, 0);
        }

        uint executed20;
        (executed20, remainingCents) = executeIfAvailable(buyer, remainingCents, txHash, gvOptionToken20, 1, token20perCent);
        if (remainingCents == 0) {
            return (executedTokens + executed20, 0);
        }

        uint executed10;
        (executed10, remainingCents) = executeIfAvailable(buyer, remainingCents, txHash, gvOptionToken10, 2, token10perCent);
        
        return (executedTokens + executed20 + executed10, remainingCents);
    }

    // Buy option tokens. Priority: GVOT30 -> GVOT20 -> GVOT10
    function buyOptions(address buyer, uint usdCents, string txHash) icoOnly {
        require(usdCents > 0);

        var remainUsdCents = buyIfAvailable(buyer, usdCents, txHash, gvOptionToken30, 0, option30perCent);
        if (remainUsdCents == 0) {
            return;
        }

        remainUsdCents = buyIfAvailable(buyer, remainUsdCents, txHash, gvOptionToken20, 1, option20perCent);
        if (remainUsdCents == 0) {
            return;
        }

        remainUsdCents = buyIfAvailable(buyer, remainUsdCents, txHash, gvOptionToken10, 2, option10perCent);
    }   

    // Private functions
    
    function executeIfAvailable(address buyer, uint usdCents, string txHash,
        GVOptionToken optionToken, uint8 optionType, uint optionPerCent)
        private returns (uint executedTokens, uint remainingCents) {
        
        var optionsAmount = usdCents * optionPerCent;
        executedTokens = optionToken.executeOption(buyer, optionsAmount);
        remainingCents = usdCents - (executedTokens / optionPerCent);
        if (executedTokens > 0) {
            ExecuteOptions(buyer, executedTokens, txHash, optionType);
        }
        return (executedTokens, remainingCents);
    }

    function buyIfAvailable(address buyer, uint usdCents, string txHash,
        GVOptionToken optionToken, uint8 optionType, uint optionsPerCent)
        private returns (uint) {
        
        var availableTokens = optionToken.remainingTokensCount(); 
        if (availableTokens > 0) {
            var tokens = usdCents * optionsPerCent;
            if(availableTokens >= tokens) {
                optionToken.buyOptions(buyer, tokens);
                BuyOptions(buyer, tokens, txHash, optionType);
                return 0;
            }
            else {
                optionToken.buyOptions(buyer, availableTokens);
                BuyOptions(buyer, availableTokens, txHash, optionType);
                return usdCents - availableTokens / optionsPerCent;
            }
        }
        return usdCents;
    }
}

contract Initable {
    function init(address token);
}

// Crowdfunding code for Genesis Vision Project
contract ICO {

    // Constants
    uint public constant TOKENS_FOR_SALE = 33 * 1e6 * 1e18;

    // Events
    event StartOptionsSelling();
    event StartICOForOptionsHolders();
    event RunIco();
    event PauseIco();
    event ResumeIco();
    event FinishIco();

    event BuyTokens(address buyer, uint amount, string txHash);

    address public gvAgent; // payments bot account
    address public team;    // team account

    GVToken public gvToken;
    GVOptionProgram public optionProgram;
    Initable public teamAllocator;
    address public migrationMaster;

    // Modifiers
    modifier teamOnly { require(msg.sender == team); _; }
    modifier gvAgentOnly { require(msg.sender == gvAgent); _; }

    // Current total token supply
    uint tokensSold = 0;

    bool public isPaused = false;
    enum IcoState { Created, RunningOptionsSelling, RunningForOptionsHolders, Running, Finished }
    IcoState public icoState = IcoState.Created;

    // Constructor
    function ICO(address _team, address _gvAgent, address _migrationMaster, address _teamAllocator) {
        gvAgent = _gvAgent;
        team = _team;
        teamAllocator = Initable(_teamAllocator);
        migrationMaster = _migrationMaster;
        gvToken = new GVToken(this, migrationMaster);
    }

    // Initialize Option Program contract
    function initOptionProgram() external teamOnly {
        if (optionProgram == address(0)) {
            optionProgram = new GVOptionProgram(this, gvAgent, team);
        }
    }

    // ICO and Option Program state management
    function startOptionsSelling() external teamOnly {
        require(icoState == IcoState.Created);
        // Check if Option Program is initialized
        require(optionProgram != address(0));    
        icoState = IcoState.RunningOptionsSelling;
        StartOptionsSelling();
    }

    // Finish options selling and start ICO for the option holders
    function startIcoForOptionsHolders() external teamOnly {
        require(icoState == IcoState.RunningOptionsSelling);       
        icoState = IcoState.RunningForOptionsHolders;
        StartICOForOptionsHolders();
    }

    function startIco() external teamOnly {
        require(icoState == IcoState.RunningForOptionsHolders);
        icoState = IcoState.Running;
        RunIco();
    }

    function pauseIco() external teamOnly {
        require(!isPaused);
        require(icoState == IcoState.Running || icoState == IcoState.RunningForOptionsHolders || icoState == IcoState.RunningOptionsSelling);
        isPaused = true;
        PauseIco();
    }

    function resumeIco() external teamOnly {
        require(isPaused);
        require(icoState == IcoState.Running || icoState == IcoState.RunningForOptionsHolders || icoState == IcoState.RunningOptionsSelling);
        isPaused = false;
        ResumeIco();
    }

    function finishIco(address _fund, address _bounty) external teamOnly {
        require(icoState == IcoState.Running);
        icoState = IcoState.Finished;

        uint mintedTokens = gvToken.totalSupply();
        if (mintedTokens > 0) {
            uint totalAmount = mintedTokens * 4 / 3;              // 75% of total tokens are for sale, get 100%
            gvToken.mint(teamAllocator, 11 * totalAmount / 100);  // 11% for team to the time-locked wallet
            gvToken.mint(_fund, totalAmount / 20);                // 5% for Genesis Vision fund
            gvToken.mint(_bounty, 9 * totalAmount / 100);         // 9% for Advisers, Marketing, Bounty
            gvToken.unfreeze();
        }
        
        FinishIco();
    }    

    // Buy GVT without options
    function buyTokens(address buyer, uint usdCents, string txHash)
        external gvAgentOnly returns (uint) {
        require(icoState == IcoState.Running);
        require(!isPaused);
        return buyTokensInternal(buyer, usdCents, txHash);
    }

    // Buy GVT for option holders. At first buy GVT with option execution, then buy GVT in regular way if ICO is running
    function buyTokensByOptions(address buyer, uint usdCents, string txHash)
        external gvAgentOnly returns (uint) {
        require(!isPaused);
        require(icoState == IcoState.Running || icoState == IcoState.RunningForOptionsHolders);
        require(usdCents > 0);

        uint executedTokens; 
        uint remainingCents;
        // Execute options
        (executedTokens, remainingCents) = optionProgram.executeOptions(buyer, usdCents, txHash);

        if (executedTokens > 0) {
            require(tokensSold + executedTokens <= TOKENS_FOR_SALE);
            tokensSold += executedTokens;
            
            gvToken.mint(buyer, executedTokens);
            BuyTokens(buyer, executedTokens, txHash);
        }

        //Buy GVT for remaining cents without options
        if (icoState == IcoState.Running) {
            return buyTokensInternal(buyer, remainingCents, txHash);
        } else {
            return remainingCents;
        }
    }

    // Buy GVOT during the Option Program
    function buyOptions(address buyer, uint usdCents, string txHash)
        external gvAgentOnly {
        require(!isPaused);
        require(icoState == IcoState.RunningOptionsSelling);
        optionProgram.buyOptions(buyer, usdCents, txHash);
    }

    // Internal buy GVT without options
    function buyTokensInternal(address buyer, uint usdCents, string txHash)
    private returns (uint) {
        //ICO state is checked in external functions, which call this function        
        require(usdCents > 0);
        uint tokens = usdCents * 1e16;
        require(tokensSold + tokens <= TOKENS_FOR_SALE);
        tokensSold += tokens;
            
        gvToken.mint(buyer, tokens);
        BuyTokens(buyer, tokens, txHash);

        return 0;
    }
}