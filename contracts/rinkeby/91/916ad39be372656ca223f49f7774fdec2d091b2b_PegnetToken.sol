/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-12-11
*/

pragma solidity ^0.5.12;

contract SafeMath {
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface is SafeMath {

    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract PegnetToken is ERC20Interface {
    string public symbol;
    string public name;
    uint8 public decimals = 8;
    uint256 _totalSupply = 0;
    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Constructor
    constructor(string memory _symbol,string memory _name) public {
        owner = msg.sender;
        symbol = _symbol;
        name = _name;
    }

    function totalSupply() view public returns (uint256 ts) {
        ts = _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from sender's account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = safeSub(balances[msg.sender], _amount);
            balances[_to] = safeAdd(balances[_to], _amount);
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
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] = safeSub(balances[_from], _amount);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _amount);
            balances[_to] = safeAdd(balances[_to], _amount);
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    // change the owner of this smart contract
    function changeOwner(address new_owner) public {
        require (msg.sender == owner, "only the owner can change ownership");
        owner = new_owner;
    }
    // create token and send to user
    function issue(address _receiver, uint256 _amount) public {
        require (msg.sender == owner, "only contract owner can issue.");
        _totalSupply = safeAdd(_totalSupply, _amount);
        balances[_receiver] = safeAdd(balances[_receiver], _amount);
        emit Transfer(owner, _receiver, _amount);
    }

    // destroy token when the user claims their tokens
    function burn(uint256 _amount) public {
        require (msg.sender == owner, "only contract owner can burn.");
        require (balances[owner] >= _amount && _totalSupply >= _amount, "the consumer must have at least the amount of tokens to be burned, and there must be at least that much in the total supply");
        _totalSupply = safeSub(_totalSupply, _amount);
        balances[owner] = safeSub(balances[owner], _amount);
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}