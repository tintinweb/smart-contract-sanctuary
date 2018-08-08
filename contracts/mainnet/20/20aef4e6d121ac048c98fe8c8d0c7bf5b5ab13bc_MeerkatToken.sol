pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// ERC Token BASIC #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract MeerkatToken is ERC20Interface {
    address public owner;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = msg.sender;
        symbol = "MCT";
        name = "Meerkat Token";
        decimals = 18;
        _totalSupply = 10000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Safele Transfer the balance from msg.sender&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _value) public returns (bool success) {
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        // Check for overflows
        require(balances[_to] + _value >= balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[msg.sender] + balances[_to];
        // Subtract from the sender
        balances[msg.sender] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


}