pragma solidity ^0.4.16;

contract SSOrgToken {
    // Public variables of the token
    address public owner;
    string public name;
    string public symbol;
    uint8 public constant decimals = 2;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => uint8) public sellTypeOf;
    mapping (address => uint256) public sellTotalOf;
    mapping (address => uint256) public sellPriceOf;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function SSOrgToken(
        string tokenName,
        string tokenSymbol,
        uint256 tokenSupply
    ) public {
        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = tokenSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        owner = msg.sender;
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Subtract from the sender
        balanceOf[msg.sender] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function setSellInfo(uint8 newSellType, uint256 newSellTotal, uint256 newSellPrice) public returns (uint256) {
        require(newSellPrice > 0 && newSellTotal >= 0);
        if (newSellTotal > sellTotalOf[msg.sender]) {
            require(balanceOf[msg.sender] >= newSellTotal - sellTotalOf[msg.sender]);
            balanceOf[msg.sender] -= newSellTotal - sellTotalOf[msg.sender];
        } else {
            balanceOf[msg.sender] += sellTotalOf[msg.sender] - newSellTotal;
        }
        sellTotalOf[msg.sender] = newSellTotal;
        sellPriceOf[msg.sender] = newSellPrice;
        sellTypeOf[msg.sender] = newSellType;
        return balanceOf[msg.sender];
    }

    function buy(address seller) payable public returns (uint256 amount) {
        amount = msg.value / sellPriceOf[seller];        // calculates the amount
        require(sellTypeOf[seller] == 0 ? sellTotalOf[seller] == amount : sellTotalOf[seller] >= amount);
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        sellTotalOf[seller] -= amount;                        // subtracts amount from seller&#39;s balance
        Transfer(seller, msg.sender, amount);               // execute an event reflecting the change
        seller.transfer(msg.value);
        return amount;                                    // ends function and returns
    }
}