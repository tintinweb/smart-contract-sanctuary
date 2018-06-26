pragma solidity ^0.4.24;

/******************************************/
/*       Netkiller Mini TOKEN             */
/******************************************/
/* Author netkiller <netkiller@msn.com>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-05-31 Fixed transfer bool */
/******************************************/

contract NetkillerMiniToken {
    address public owner;
    string public name;
    string public symbol;
    uint public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) public {
        owner = msg.sender;
        name = tokenName;
        symbol = tokenSymbol; 
        decimals = decimalUnits;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
 
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}


contract NetkillerExchangeToken is NetkillerMiniToken{

    uint256 public sellPrice;
    uint256 public buyPrice;

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) NetkillerMiniToken(initialSupply, tokenName, tokenSymbol, decimalUnits) public {}

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public returns (uint amount) {
        amount = msg.value / buyPrice;                    // calculates the amount
        _transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, amount);          // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }

}