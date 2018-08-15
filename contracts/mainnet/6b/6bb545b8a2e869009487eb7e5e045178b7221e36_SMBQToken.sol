pragma solidity ^0.4.24;

/*
Developed by: https://www.tradecryptocurrency.com/
*/

contract owned {
    address public owner;

    constructor() public {
        owner = 0x858A045e0559ffCc1bB0bB394774CF49b02593F0;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner)
    onlyOwner public {
        owner = newOwner;
    }
}


contract pays_commission {
    address public commissionGetter;
    uint256 public minimumEtherCommission;
    uint public minimumTokenCommission;

    constructor() public {
        commissionGetter = 0xCd8bf69ad65c5158F0cfAA599bBF90d7f4b52Bb0;
        minimumEtherCommission = 50000000000;
        minimumTokenCommission = 1;
    }

    modifier onlyCommissionGetter {
        require(msg.sender == commissionGetter);
        _;
    }

    function transferCommissionGetter(address newCommissionGetter)
    onlyCommissionGetter public {
        commissionGetter = newCommissionGetter;
    }

    function changeMinimumCommission(
        uint256 newMinEtherCommission, uint newMinTokenCommission)
    onlyCommissionGetter public {
        minimumEtherCommission = newMinEtherCommission;
        minimumTokenCommission = newMinTokenCommission;
    }
}


contract SMBQToken is pays_commission, owned {
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    uint256 public buyPrice = 1700000000000000;
    uint256 public sellPrice = 1500000000000000;
    bool public closeSell = false;
    mapping (address => bool) public frozenAccount;


    // Events

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address sender, uint amount);
    event Withdrawal(address receiver, uint amount);


    // Constructor

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol)
    public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[owner] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }


    // Internal functions

    function _transfer(address _from, address _to, uint _value)
    internal {
        require(_to != 0x0);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function _pay_token_commission (uint256 _value)
    internal {
        uint market_value = _value * sellPrice;
        uint commission_value = market_value * 1 / 100;
        // The comision is paid with tokens
        uint commission = commission_value / sellPrice;
        if (commission < minimumTokenCommission){ 
            commission = minimumTokenCommission;
        }
        address contr = this;
        _transfer(contr, commissionGetter, commission);
    }


    // Only owner functions

    function refillTokens(uint256 _value)
    onlyOwner public {
        _transfer(msg.sender, this, _value);
    }

    function mintToken(uint256 mintedAmount)
    onlyOwner public {
        balanceOf[owner] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, owner, mintedAmount);
    }

    function freezeAccount(address target, bool freeze)
    onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice)
    onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function setStatus(bool isClosedSell)
    onlyOwner public {
        closeSell = isClosedSell;
    }

    function withdrawEther(uint amountInWeis)
    onlyOwner public {
        address contr = this;
        require(contr.balance >= amountInWeis);
        emit Withdrawal(msg.sender, amountInWeis);
        owner.transfer(amountInWeis);
    }


    // Public functions

    function transfer(address _to, uint256 _value)
    public {
        _pay_token_commission(_value);
        _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value)
    public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        _pay_token_commission(_value);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function depositEther() payable
    public returns(bool success) {
        address contr = this;
        require((contr.balance + msg.value) > contr.balance);
        emit Deposit(msg.sender, msg.value);
        return true;
    }

    function buy() payable
    public {
        uint amount = msg.value / buyPrice;
        uint market_value = amount * buyPrice;
        uint commission = market_value * 1 / 100;
        // The comision is paid with Ether
        if (commission < minimumEtherCommission){
            commission = minimumEtherCommission;
        }
        address contr = this;
        require(contr.balance >= commission);
        commissionGetter.transfer(commission);
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount)
    public {
    	require(!closeSell);
        _pay_token_commission(amount);
        _transfer(msg.sender, this, amount);
        uint market_value = amount * sellPrice;
        address contr = this;
        require(contr.balance >= market_value);
        msg.sender.transfer(market_value);
    }

    function () payable
    public {
        buy();
    }
}