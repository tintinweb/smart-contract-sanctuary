pragma solidity ^0.4.2;

contract owned {
    address owner;

    function owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

contract LuxToken is owned {
    string public name = "Luxury Token";
    string public symbol = "LUX";
    uint8 public decimals = 0;
    uint256 issuePrice = 1 ether / 100;

    bool public isAllowedToPurchase = false;

    uint256 minTokensRequiredForMessage = 10;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => string) messages;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event MessageAdded(address indexed from, string message, uint256 contributed);

    function LuxToken() {
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value == 0) { return false; }

        if (balanceOf[msg.sender] < _value) { return false; }
        if (balanceOf[_to] + _value < balanceOf[_to]) { return false; }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function enablePurchasing() onlyOwner {
        isAllowedToPurchase = true;
    }
    
    function disablePurchasing() onlyOwner {
        isAllowedToPurchase = false;
    }

    function () payable {
        require(isAllowedToPurchase);

        uint256 issuedTokens = msg.value / issuePrice;
        balanceOf[msg.sender] += issuedTokens;

        Transfer(address(this), msg.sender, 10);
    }

    function getBalance(address addr) constant returns(uint256) {
        return balanceOf[addr];
    }
    
    function sendFundsTo(address _to, uint256 _amount) onlyOwner {
        _to.transfer(_amount);
    }
    
    function setMinTokensRequiredForMessage(uint256 _newValue) onlyOwner {
        minTokensRequiredForMessage = _newValue;
    }
    
    function setSymbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }
    
    function setMessage(string _message) {
        uint256 tokenBalance = balanceOf[msg.sender];
        require(tokenBalance >= minTokensRequiredForMessage);
        MessageAdded(msg.sender, _message, tokenBalance);
    }
}