pragma solidity ^0.4.18;

/*
Developed by: https://www.investbtceur.com
*/

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}

contract ALUXToken is owned, TokenERC20 {
    uint256 public sellPrice = 10000000000000000;
    uint256 public buyPrice = 10000000000000000;
    bool public closeBuy = false;
    bool public closeSell = false;
    address public commissionGetter = 0xCd8bf69ad65c5158F0cfAA599bBF90d7f4b52Bb0;
    uint256 public minimumCommission = 100000000000000;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address receiver, uint amount);

    function ALUXToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    function refillTokens(uint256 _value) public onlyOwner{
        _transfer(msg.sender, this, _value);
    }

    function transfer(address _to, uint256 _value) public {
        uint market_value = _value * sellPrice;
        uint commission = market_value * 4 / 1000;
        if (commission < minimumCommission){ commission = minimumCommission; }
        address contr = this;
        require(contr.balance >= commission);
        commissionGetter.transfer(commission);
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        uint market_value = _value * sellPrice;
        uint commission = market_value * 4 / 1000;
        if (commission < minimumCommission){ commission = minimumCommission; }
        address contr = this;
        require(contr.balance >= commission);
        commissionGetter.transfer(commission);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function mintToken(uint256 mintedAmount) onlyOwner public {
        balanceOf[owner] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, owner, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function setStatus(bool isClosedBuy, bool isClosedSell) onlyOwner public {
        closeBuy = isClosedBuy;
        closeSell = isClosedSell;
    }

    function deposit() payable public returns(bool success) {
        address contr = this;
        require((contr.balance + msg.value) > contr.balance);
        LogDeposit(msg.sender, msg.value);
        return true;
    }

    function withdraw(uint amountInWeis) onlyOwner public {
        LogWithdrawal(msg.sender, amountInWeis);
        owner.transfer(amountInWeis);
    }

    function buy() payable public {
        require(!closeBuy);
        uint amount = msg.value / buyPrice;
        uint market_value = amount * buyPrice;
        uint commission = market_value * 4 / 1000;
        if (commission < minimumCommission){ commission = minimumCommission; }
        address contr = this;
        require(contr.balance >= commission);
        commissionGetter.transfer(commission);
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) public {
    	require(!closeSell);
        address contr = this;
        uint market_value = amount * sellPrice;
        uint commission = market_value * 4 / 1000;
        if (commission < minimumCommission){ commission = minimumCommission; }
        uint amount_weis = market_value + commission;
        require(contr.balance >= amount_weis);
        commissionGetter.transfer(commission);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(market_value);
    }

    function () public payable { buy(); }
}