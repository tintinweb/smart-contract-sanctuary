pragma solidity ^0.4.11;


contract Owner {
    address public owner;

    function Owner() {
        owner = msg.sender;
    }

    modifier  onlyOwner() {
        require(msg.sender != owner);
        _;
    }

    function  transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract TokenRecipient { 
    function receiveApproval(
        address _from, 
        uint256 _value, 
        address _token, 
        bytes _extraData); 
}


contract Token {
    string public standard = "Token 0.1";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function Token (
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
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) {
            revert();           // Check if the sender has enough
        }
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert(); // Check for overflows
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    returns (bool success) 
    {    
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                this,
                _extraData
            );
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) {
            revert();                                        // Check if the sender has enough
        }                 
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert();  // Check for overflows
        }
        if (_value > allowance[_from][msg.sender]) {
            revert();   // Check allowance
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function () {
        revert();
    }
}


contract ISeeVoiceToken is Token, Owner {
    uint256 public constant INITIAL_SUPPLY = 60000000000000000000000000;
    string public constant NAME = "I See Voice Token";
    string public constant SYMBOL = "ISVT";
    // string public constant STANDARD = "Token 1.0";
    uint8 public constant DECIMALS = 10;
    uint256 public constant BUY = 300000000000000000000000;

    // string public standard = STANDARD;
    // string public name;
    // string public symbol;
    // uint public decimals;

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint minBalanceForAccounts;

    mapping (address => uint256) public balanceOf;
    mapping (address => bool) frozenAccount;

    event FrozenFunds(address indexed _target, bool _frozen);
    event Burn(address indexed from, uint256 value);

    function ISeeVoiceToken() Token(INITIAL_SUPPLY, NAME, DECIMALS, SYMBOL) {
        balanceOf[msg.sender] = totalSupply;
        balanceOf[msg.sender] -= BUY;
        balanceOf[this] = BUY;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) {
            revert();           // Check if the sender has enough
        }
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert(); // Check for overflows
        }
        if (frozenAccount[msg.sender]) {
            revert();                // Check if frozen
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) {
            revert();                        // Check if frozen       
        }     
        if (balanceOf[_from] < _value) {
            revert();                 // Check if the sender has enough
        }
        if (balanceOf[_to] + _value < balanceOf[_to]) {
            revert();  // Check for overflows
        }
        if (_value > allowance[_from][msg.sender]) {
            revert();   // Check allowance
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address _target, bool freeze) onlyOwner {
        frozenAccount[_target] = freeze;
        FrozenFunds(_target, freeze);
    }

    function burn(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[msg.sender] + _value >= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] + _value >= balanceOf[_from]);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        allowance[_from][msg.sender] -= _value;
        Burn(_from, _value);
        return true;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable returns (uint amount) {
        amount = msg.value / buyPrice;
        require(balanceOf[this] >= amount);
        balanceOf[this] -= amount;
        balanceOf[msg.sender] += amount;
        Transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint256 amount) returns (uint256 revenue) {
        require(balanceOf[msg.sender] >= amount);
        require(!frozenAccount[msg.sender]);

        revenue = amount * sellPrice;
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;
        require(msg.sender.send(revenue));
        Transfer(msg.sender, this, amount);
        return revenue;
    }

    function withdraw(uint256 amount) onlyOwner returns (bool success){
        require(msg.sender.send(amount));
        return true;
    }

    function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
        minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

}