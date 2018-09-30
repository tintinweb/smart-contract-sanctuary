pragma solidity ^0.4.11;

contract owned {
    address public owner;

    constructor() {
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

/// @title Sotoin (SOTOX)
contract Sotoin is owned, ERC20Interface {
    // Public variables of the token
    string public constant standard = &#39;ERC20&#39;;
    string public constant name = &#39;Sotoin&#39;;  
    string public constant symbol = &#39;SOTOX&#39;;
    uint8  public constant decimals = 18;
    uint public registrationTime = 0;
    bool public registered = false;

    uint256 public totalMigrated = 0;
    address public migrationAgent = 0;

    uint256 totalTokens = 500000000000000000000000000; 


    // This creates an array with all balances 
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
   
    // These are related to SOTOX team members
    mapping (address => bool) public frozenAccount;
    mapping (address => uint[3]) public frozenTokens;

    // Variables of token frozen rules for SOTOX team members.
    uint[3] public unlockat;

    event Migrate(address _from, address _to, uint256 _value);

    // Constructor
    function Sotoin() 
    {
    }

    // This unnamed function is called whenever someone tries to send ether to it 
    function () 
    {

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
    /// @param _reserveAddress The address of multisig token contract
    function registerSale(address _tokenFactory, address _reserveAddress) 
        public
        onlyOwner 
    {
        // The token contract can be only registered once.
        if (!registered) {
            // Total supply
            totalTokens  = 500 * 1000 * 1000 * 10**18; 

            // (50%) of total supply to ico-sale contract
            balances[_tokenFactory]    = 250 * 1000 * 1000 * 10**18;

            // (27%) of total supply to the congress address for congress and partners
            balances[_reserveAddress] = 135 * 1000 * 1000 * 10**18;

            // Allocate rest (15%) of total supply to development team and adviors
            // 75,000,000 * 10**18;
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

    /// @dev Allocate 15% of total supply to the team members and advisors.
    function teamAllocation() 
        internal 
    {
        // 1% of total supply allocated to each team member.
        uint individual = 5000 * 1000 * 10**18;

        balances[0x7F959E124BF6174cA36e899F230a515810140b52] = individual; // 1% 
        balances[0x3D26f6D102aCF839243f9e006Ab4d86e6ff5D623] = individual; // 1% 
        balances[0x75e46EeF9d9F2fD9C6902c4b41CBa8D9c19aFb34] = individual; // 1% 
        balances[0x68522F3D9bcB9227d24dD0107e56Fdb78C403266] = individual; // 1% 
        balances[0x11f8f4b49ddBe4eA85Fb1B1698833720D7986611] = individual; // 1% 
        balances[0x950f7d328ebc7A593C33Ae357b85ec1D0eC27e98] = individual; // 1%
        balances[0x6d6d77e971A8fb833c5f8dC3C582EC6e833d2017] = individual; // 1% 
        balances[0x063b54A94Ff34Bb2646a90629176166563BD40C2] = individual; // 1% 
        balances[0x83b861fcfDaebbBBc2fB23aB9EdECbc99E99D997] = individual; // 1% 
        balances[0x37F423c65A27fDa83986Faf0a933A370dCB9bbBa] = individual; // 1% 
        balances[0x49290391f973C387dB4916C4edCFd281eCC90C3c] = individual; // 1%
        balances[0x6AF12c4738816FDA3d89b968b06A55F638E4F079] = individual; // 1%
        balances[0x82572bd65f6068C0BC7d193fC8a4e8FDCB03627F] = individual; // 1%
        balances[0x257A64D7FBA905d1c2Fb8ba7914Ff80989602C5A] = individual; // 1%
        balances[0x0981F0BD7790B18A3a2B55f40960b5c4472574BE] = individual; // 1%

        // Freeze tokens allocated to the team for at most two years.
        // Freeze tokens in three phases
        // 75000 * 1000 * 10**18; 100% of locked tokens within 6 months
        // 60000 * 1000 * 10**18;  80% of locked tokens within 12 months
        // 37500 * 1000 * 10**18;  50% of locked tokens within 24 months
        freeze(0x7F959E124BF6174cA36e899F230a515810140b52, individual);
        freeze(0x3D26f6D102aCF839243f9e006Ab4d86e6ff5D623, individual);
        freeze(0x75e46EeF9d9F2fD9C6902c4b41CBa8D9c19aFb34, individual);
        freeze(0x68522F3D9bcB9227d24dD0107e56Fdb78C403266, individual);
        freeze(0x11f8f4b49ddBe4eA85Fb1B1698833720D7986611, individual);
        freeze(0x950f7d328ebc7A593C33Ae357b85ec1D0eC27e98, individual);
        freeze(0x6d6d77e971A8fb833c5f8dC3C582EC6e833d2017, individual); 
        freeze(0x063b54A94Ff34Bb2646a90629176166563BD40C2, individual);
        freeze(0x37F423c65A27fDa83986Faf0a933A370dCB9bbBa, individual);
        freeze(0x49290391f973C387dB4916C4edCFd281eCC90C3c, individual);
        freeze(0x6AF12c4738816FDA3d89b968b06A55F638E4F079, individual);
        freeze(0x82572bd65f6068C0BC7d193fC8a4e8FDCB03627F, individual);
        freeze(0x257A64D7FBA905d1c2Fb8ba7914Ff80989602C5A, individual);
        freeze(0x0981F0BD7790B18A3a2B55f40960b5c4472574BE, individual);
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