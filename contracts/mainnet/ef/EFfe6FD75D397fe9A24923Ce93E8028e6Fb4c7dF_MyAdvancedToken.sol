pragma solidity ^0.4.11;

/*
Token ini penyempurnaan untuk code pengiriman semua balance
*/

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract token {
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }




}

contract MyAdvancedToken is owned, token {

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}


    function freezeAccount(address target, bool freeze) onlyOwner {
        require (target != owner);           // owner tidak boleh membekukan dirinya sendiri
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (frozenAccount[msg.sender] != true);                 // Mencegah frozen account untuk mengirim
        require (balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }



    /* transfer dari akun ke akun tapi yang berhak melakukannya adalah akun itu saja */
    function transferDari(address _from, address _to, uint256 _value) returns (bool success) {
        require (_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        require (msg.sender == _from);                       // Mencegah user mengirim dari akun lain
        require (balanceOf[_from] >= _value);                 // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        Transfer(_from, _to, _value);
        return true;
    }

}