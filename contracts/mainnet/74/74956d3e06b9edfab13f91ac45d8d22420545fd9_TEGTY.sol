pragma solidity ^0.4.16;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

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

contract TEGTY is owned, SafeMath {

    string public name;
    string public symbol;
    uint public decimals = 8;
    uint public totalSupply;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint) public lockInfo;

    uint constant valueTotal = 20 * 10000 * 10000 * 10 ** 8;	//A total of two hundred million
    uint constant valueSale = valueTotal / 100 * 15;  // sell 15%
    uint constant valueTeam = valueTotal / 100 * 85;   // other 85%

    uint public minEth = 0.1 ether;

    uint public maxEth = 1000 ether;

	uint256 public buyPrice = 5000;	//Purchase price
    uint256 public sellPrice = 1;	//The price /10000
    
    bool public buyTradeConfir = false;	//buy
    bool public sellTradeConfir = false;	//sell
    
    uint public saleQuantity = 0;

    uint public ethQuantity = 0;

    modifier validAddress(address _address) {
        assert(0x0 != _address);
        _;
    }

    modifier validEth {
        assert(msg.value >= minEth && msg.value <= maxEth);
        _;
    }

    modifier validPeriod {
        assert(buyTradeConfir);
        _;
    }

    modifier validQuantity {
        assert(valueSale >= saleQuantity);
        _;
    }


    function TEGTY() public
    {
    	totalSupply = valueTotal;
    	//buy
    	balanceOf[this] = valueSale;
        Transfer(0x0, this, valueSale);
        // owner
        balanceOf[msg.sender] = valueTeam;
        Transfer(0x0, msg.sender, valueTeam);
    	name = &#39;Engagementy&#39;;
    	symbol = &#39;EGTY&#39;; 
    }

    function transfer(address _to, uint _value) public validAddress(_to) returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(validTransfer(msg.sender, _value));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferInner(address _to, uint _value) private returns (bool success)
    {
        balanceOf[this] -= _value;
        balanceOf[_to] += _value;
        Transfer(this, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint _value) public validAddress(_from) validAddress(_to) returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        require(validTransfer(_from, _value));
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public validAddress(_spender) returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function lock(address _to, uint _value) private validAddress(_to)
    {
        require(_value > 0);
        require(lockInfo[_to] + _value <= balanceOf[_to]);
        lockInfo[_to] += _value;
    }

    function validTransfer(address _from, uint _value) private constant returns (bool)
    {
        if (_value == 0)
            return false;

        return lockInfo[_from] + _value <= balanceOf[_from];
    }


    function () public payable
    {
        buy();
    }

    function buy() public payable validEth validPeriod validQuantity
    {
        uint eth = msg.value;

        uint quantity = eth * buyPrice / 10 ** 10;

        uint leftQuantity = safeSub(valueSale, saleQuantity);
        if (quantity > leftQuantity) {
            quantity = leftQuantity;
        }

        saleQuantity = safeAdd(saleQuantity, quantity);
        ethQuantity = safeAdd(ethQuantity, eth);

        require(transferInner(msg.sender, quantity));

        lock(msg.sender, quantity);

        Buy(msg.sender, eth, quantity);

    }

    function sell(uint256 amount) public {
		if(sellTradeConfir){
			require(this.balance >= amount * sellPrice / 10000);
			transferFrom(msg.sender, this, amount);
			msg.sender.transfer(amount * sellPrice / 10000);
		}
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function starBuy() public onlyOwner returns (bool)
	{
	    buyTradeConfir = true;
	    StarBuy();
	    return true;
	}
    
    function stopBuy() public onlyOwner returns (bool)
    {
        buyTradeConfir = false;
        StopBuy();
        return true;
    }
    
    function starSell() public onlyOwner returns (bool)
	{
	    sellTradeConfir = true;
	    StarSell();
	    return true;
	}
    
    function stopSell() public onlyOwner returns (bool)
	{
	    sellTradeConfir = false;
	    StopSell();
	    return true;
	}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event Buy(address indexed sender, uint eth, uint token);
    event Burn(address indexed from, uint256 value);
    event StopSell();
    event StopBuy();
    event StarSell();
    event StarBuy();
}