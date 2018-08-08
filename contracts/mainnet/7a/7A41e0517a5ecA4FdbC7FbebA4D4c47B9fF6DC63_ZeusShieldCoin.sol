pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

// ----------------------------------------------------------------------------------------------
// Original from:
// https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// (c) BokkyPooBah 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    // Get the total token supply     function totalSupply() constant returns (uint256 totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);

    // Send _value amount of token from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success); 
    
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

   // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// Migration Agent interface
contract migration {
    function migrateFrom(address _from, uint256 _value);
}

/// @title Zeus Shield Coin (ZSC)
contract ZeusShieldCoin is owned, ERC20Interface {
    // Public variables of the token
    string public constant standard = &#39;ERC20&#39;;
    string public constant name = &#39;Zeus Shield Coin&#39;;  
    string public constant symbol = &#39;ZSC&#39;;
    uint8  public constant decimals = 18;
    uint public registrationTime = 0;
    bool public registered = false;

    uint256 public totalMigrated = 0;
    address public migrationAgent = 0;

    uint256 totalTokens = 0; 


    // This creates an array with all balances 
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
   
    // These are related to ZSC team members
    mapping (address => bool) public frozenAccount;
    mapping (address => uint[3]) public frozenTokens;

    // Variables of token frozen rules for ZSC team members.
    uint[3] public unlockat;

    event Migrate(address _from, address _to, uint256 _value);

    // Constructor
    function ZeusShieldCoin() 
    {
    }

    // This unnamed function is called whenever someone tries to send ether to it 
    function () 
    {
        throw; // Prevents accidental sending of ether
    }

    function totalSupply() 
        constant 
        returns (uint256) 
    {
        return totalTokens;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) 
        constant 
        returns (uint256) 
    {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) 
        returns (bool success) 
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(msg.sender, _amount)) return false;

        if (balances[msg.sender] >= _amount
            && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }     
    }
 
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount) 
        returns (bool success) 
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(_from, _amount)) return false;

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
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

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.     
    function approve(address _spender, uint256 _amount) 
        returns (bool success) 
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) 
        constant 
        returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];
    }

    /// @dev Set address of migration agent contract and enable migration
    /// @param _agent The address of the MigrationAgent contract
    function setMigrationAgent(address _agent) 
        public
        onlyOwner
    {
        if (!registered) throw;
        if (migrationAgent != 0) throw;
        migrationAgent = _agent;
    }

    /// @dev Buyer can apply for migrating tokens to the new token contract.
    /// @param _value The amount of token to be migrated
    function applyMigrate(uint256 _value) 
        public
    {
        if (!registered) throw;
        if (migrationAgent == 0) throw;

        // Validate input value.
        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        migration(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }


    /// @dev Register for crowdsale and do the token pre-allocation.
    /// @param _tokenFactory The address of ICO-sale contract
    /// @param _congressAddress The address of multisig token contract
    function registerSale(address _tokenFactory, address _congressAddress) 
        public
        onlyOwner 
    {
        // The token contract can be only registered once.
        if (!registered) {
            // Total supply
            totalTokens  = 6100 * 1000 * 1000 * 10**18; 

            // (51%) of total supply to ico-sale contract
            balances[_tokenFactory]    = 3111 * 1000 * 1000 * 10**18;

            // (34%) of total supply to the congress address for congress and partners
            balances[_congressAddress] = 2074 * 1000 * 1000 * 10**18;

            // Allocate rest (15%) of total supply to development team and contributors
            // 915,000,000 * 10**18;
            teamAllocation();

            registered = true;
            registrationTime = now;

            unlockat[0] = registrationTime +  6 * 30 days;
            unlockat[1] = registrationTime + 12 * 30 days;
            unlockat[2] = registrationTime + 24 * 30 days;
        }
    }

    /// @dev Allocate 15% of total supply to ten team members.
    /// @param _account The address of account to be frozen.
    /// @param _totalAmount The amount of tokens to be frozen.
    function freeze(address _account, uint _totalAmount) 
        public
        onlyOwner 
    {
        frozenAccount[_account] = true;  
        frozenTokens[_account][0] = _totalAmount;            // 100% of locked token within 6 months
        frozenTokens[_account][1] = _totalAmount * 80 / 100; //  80% of locked token within 12 months
        frozenTokens[_account][2] = _totalAmount * 50 / 100; //  50% of locked token within 24 months
    }

    /// @dev Allocate 15% of total supply to the team members.
    function teamAllocation() 
        internal 
    {
        // 1.5% of total supply allocated to each team member.
        uint individual = 91500 * 1000 * 10**18;

        balances[0xCDc5BDEFC6Fddc66E73250fCc2F08339e091dDA3] = individual; // 1.5% 
        balances[0x8b47D27b085a661E6306Ac27A932a8c0b1C11b84] = individual; // 1.5% 
        balances[0x825f4977DB4cd48aFa51f8c2c9807Ee89120daB7] = individual; // 1.5% 
        balances[0xcDf5D7049e61b2F50642DF4cb5a005b1b4A5cfc2] = individual; // 1.5% 
        balances[0xab0461FB41326a960d3a2Fe2328DD9A65916181d] = individual; // 1.5% 
        balances[0xd2A131F16e4339B2523ca90431322f559ABC4C3d] = individual; // 1.5%
        balances[0xCcB4d663E6b05AAda0e373e382628B9214932Fff] = individual; // 1.5% 
        balances[0x60284720542Ff343afCA6a6DBc542901942260f2] = individual; // 1.5% 
        balances[0xcb6d0e199081A489f45c73D1D22F6de58596a99C] = individual; // 1.5% 
        balances[0x928D99333C57D31DB917B4c67D4d8a033F2143A7] = individual; // 1.5% 

        // Freeze tokens allocated to the team for at most two years.
        // Freeze tokens in three phases
        // 91500 * 1000 * 10**18; 100% of locked tokens within 6 months
        // 73200 * 1000 * 10**18;  80% of locked tokens within 12 months
        // 45750 * 1000 * 10**18;  50% of locked tokens within 24 months
        freeze("0xCDc5BDEFC6Fddc66E73250fCc2F08339e091dDA3", individual);
        freeze("0x8b47D27b085a661E6306Ac27A932a8c0b1C11b84", individual);
        freeze("0x825f4977DB4cd48aFa51f8c2c9807Ee89120daB7", individual);
        freeze("0xcDf5D7049e61b2F50642DF4cb5a005b1b4A5cfc2", individual);
        freeze("0xab0461FB41326a960d3a2Fe2328DD9A65916181d", individual);
        freeze("0xd2A131F16e4339B2523ca90431322f559ABC4C3d", individual);
        freeze("0xCcB4d663E6b05AAda0e373e382628B9214932Fff", individual);
        freeze("0x60284720542Ff343afCA6a6DBc542901942260f2", individual);
        freeze("0xcb6d0e199081A489f45c73D1D22F6de58596a99C", individual);
        freeze("0x928D99333C57D31DB917B4c67D4d8a033F2143A7", individual);
    }

    /// @dev Token frozen rules for token holders.
    /// @param _from The token sender.
    /// @param _value The token amount.
    function frozenRules(address _from, uint256 _value) 
        internal 
        returns (bool success) 
    {
        if (frozenAccount[_from]) {
            if (now < unlockat[0]) {
               // 100% locked within the first 6 months.
               if (balances[_from] - _value < frozenTokens[_from][0]) 
                    return true;  
            } else if (now >= unlockat[0] && now < unlockat[1]) {
               // 20% unlocked after 6 months.
               if (balances[_from] - _value < frozenTokens[_from][1]) 
                    return true;  
            } else if (now >= unlockat[1] && now < unlockat[2]) {
               // 50% unlocked after 12 months. 
               if (balances[_from]- _value < frozenTokens[_from][2]) 
                   return true;  
            } else {
               // 100% unlocked after 24 months.
               frozenAccount[_from] = false; 
            }
        }
        return false;
    }   
}