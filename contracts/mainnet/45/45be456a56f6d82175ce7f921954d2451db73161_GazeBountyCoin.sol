pragma solidity ^0.4.16;

// ----------------------------------------------------------------------------
// GBC &#39;Gaze Bounty Coin&#39; token contract
//
// Deployed to : 0x45bE456a56f6D82175Ce7f921954d2451Db73161
// Symbol      : GBC
// Name        : Gaze Bounty Coin
// Total supply: Allocate as required
// Decimals    : 18
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for Gaze 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address _account) constant returns (uint balance);
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
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


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
// Administrators, borrowed from Gimli
// ----------------------------------------------------------------------------
contract Administered is Owned {

    // ------------------------------------------------------------------------
    // Mapping of administrators
    // ------------------------------------------------------------------------
    mapping (address => bool) public administrators;

    // ------------------------------------------------------------------------
    // Add and delete adminstrator events
    // ------------------------------------------------------------------------
    event AdminstratorAdded(address adminAddress);
    event AdminstratorRemoved(address adminAddress);


    // ------------------------------------------------------------------------
    // Modifier for functions that can only be executed by adminstrator
    // ------------------------------------------------------------------------
    modifier onlyAdministrator() {
        require(administrators[msg.sender] || owner == msg.sender);
        _;
    }


    // ------------------------------------------------------------------------
    // Owner can add a new administrator
    // ------------------------------------------------------------------------
    function addAdministrators(address _adminAddress) onlyOwner {
        administrators[_adminAddress] = true;
        AdminstratorAdded(_adminAddress);
    }


    // ------------------------------------------------------------------------
    // Owner can remove an administrator
    // ------------------------------------------------------------------------
    function removeAdministrators(address _adminAddress) onlyOwner {
        delete administrators[_adminAddress];
        AdminstratorRemoved(_adminAddress);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// ----------------------------------------------------------------------------
contract GazeBountyCoin is ERC20Interface, Administered {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Token parameters
    // ------------------------------------------------------------------------
    string public constant symbol = "GBC";
    string public constant name = "Gaze Bounty Coin";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;

    // ------------------------------------------------------------------------
    // Administrators can mint until sealed
    // ------------------------------------------------------------------------
    bool public sealed;

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
    function GazeBountyCoin() Owned() {
    }


    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _account
    // ------------------------------------------------------------------------
    function balanceOf(address _account) constant returns (uint balance) {
        return balances[_account];
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


    // ------------------------------------------------------------------------
    // After sealing, no more minting is possible
    // ------------------------------------------------------------------------
    function seal() onlyOwner {
        require(!sealed);
        sealed = true;
    }


    // ------------------------------------------------------------------------
    // Mint coins for a single account
    // ------------------------------------------------------------------------
    function mint(address _to, uint _amount) onlyAdministrator {
        require(!sealed);
        require(_to != 0x0);
        require(_amount != 0);
        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);
        Transfer(0x0, _to, _amount);
    }


    // ------------------------------------------------------------------------
    // Mint coins for a multiple accounts
    // ------------------------------------------------------------------------
    function multiMint(address[] _to, uint[] _amount) onlyAdministrator {
        require(!sealed);
        require(_to.length != 0);
        require(_to.length == _amount.length);
        for (uint i = 0; i < _to.length; i++) {
            require(_to[i] != 0x0);
            require(_amount[i] != 0);
            balances[_to[i]] = balances[_to[i]].add(_amount[i]);
            totalSupply = totalSupply.add(_amount[i]);
            Transfer(0x0, _to[i], _amount[i]);
        }
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ethers - no payable modifier
    // ------------------------------------------------------------------------
    function () {
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }
}