pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) onlyOwner private {
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
    function balanceOf(address _owner) constant public returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value amount of token from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

   // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/// @title Yoyo Ark Coin (YAC)
contract YoyoArkCoin is owned, ERC20Interface {
    // Public variables of the token
    string public constant standard = &#39;ERC20&#39;;
    string public constant name = &#39;Yoyo Ark Coin&#39;;
    string public constant symbol = &#39;YAC&#39;;
    uint8  public constant decimals = 18;
    uint public registrationTime = 0;
    bool public registered = false;

    uint256 totalTokens = 960 * 1000 * 1000 * 10**18;


    // This creates an array with all balances
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // These are related to YAC team members
    mapping (address => bool) public frozenAccount;
    mapping (address => uint[3]) public frozenTokens;

    // Variable of token frozen rules for YAC team members.
    uint public unlockat;

    // Constructor
    constructor() public
    {
    }

    // This unnamed function is called whenever someone tries to send ether to it
    function () private
    {
        revert(); // Prevents accidental sending of ether
    }

    function totalSupply()
        constant
        public
        returns (uint256)
    {
        return totalTokens;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(msg.sender, _amount)) return false;

        if (balances[msg.sender] >= _amount
            && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
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
    function transferFrom(address _from, address _to, uint256 _amount) public
        returns (bool success)
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(_from, _amount)) return false;

        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && balances[_to] + _amount > balances[_to]) {

            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Register for Token Initialize,
    /// 100% of total Token will initialize to dev Account.
    function initRegister()
        public
    {
        // (85%) of total supply to sender contract
        balances[msg.sender] = 960 * 1000 * 1000 * 10**18;
        // Frozen 15% of total supply for team members.
        registered = true;
        registrationTime = now;

        unlockat = registrationTime + 6 * 30 days;

        // Frozen rest (15%) of total supply for development team and contributors
        // 144,000,000 * 10**18;
        frozenForTeam();
    }

    /// @dev Frozen for the team members.
    function frozenForTeam()
        internal
    {
        uint totalFrozeNumber = 144 * 1000 * 1000 * 10**18;
        freeze(msg.sender, totalFrozeNumber);
    }

    /// @dev Frozen 15% of total supply for team members.
    /// @param _account The address of account to be frozen.
    /// @param _totalAmount The amount of tokens to be frozen.
    function freeze(address _account, uint _totalAmount)
        public
        onlyOwner
    {
        frozenAccount[_account] = true;
        frozenTokens[_account][0] = _totalAmount;            // 100% of locked token within 6 months
    }

    /// @dev Token frozen rules for token holders.
    /// @param _from The token sender.
    /// @param _value The token amount.
    function frozenRules(address _from, uint256 _value)
        internal
        returns (bool success)
    {
        if (frozenAccount[_from]) {
            if (now < unlockat) {
               // 100% locked within the first 6 months.
               if (balances[_from] - _value < frozenTokens[_from][0])
                    return true;
            } else {
               // 100% unlocked after 6 months.
               frozenAccount[_from] = false;
            }
        }
        return false;
    }
}