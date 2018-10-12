pragma solidity ^0.4.18;

contract owned {
    address public owner;

    constructor() public {
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

contract WeiFangQiCoin is owned {
    string constant public name="Wei Fang Qi Coin";
    uint8 constant public decimals=2; 
    string constant public symbol="WFQ";
    uint256 constant private _initialAmount = 950000;

    uint256 constant private MAX_UINT256 = 2**256 - 1;

    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public sellPrice; //=10000000000000000;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from,uint256 _value);
    event FrozenFunds(address indexed target, bool frozen);
    event MintToken(address indexed target,uint256 _value);
    event Buy(address indexed target,uint256 _value);
    event WithDraw(address _value);

    constructor(
        /* uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol */) 
            public payable {
        uint256 mint_total=_initialAmount * 10 ** uint256(decimals);
        balanceOf[msg.sender] = mint_total;
        totalSupply = mint_total;
        /*
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol; 
        */
    }
    function() public payable {
        buy();
    }

    function buy() payable public returns (bool success) {
        //require(!frozenAccount[msg.sender]); 
        uint256 amount = msg.value / buyPrice; 
        _transfer(owner, msg.sender, amount); 
        emit Buy(msg.sender,amount);
        //token(owner).transfer(msg.sender,msg.value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]); 
        if (_from == _to)
            return;
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    /*
    function adminTransfer(address _from,address _to, uint256 _value) onlyOwner public returns (bool success) {
        _transfer(_from,_to,_value);
        return true;
    }*/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balanceOf[_from] >= _value && allowance >= _value);
        _transfer(_from,_to,_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function burn(uint256 _value) public  {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        //balanceOf[msg.sender] -= _value * 10 ** uint256(decimals);
        //totalSupply -= _value * 10 ** uint256(decimals);
        emit Burn(msg.sender, _value);
    }
    function burnFrom(address _from, uint256 _value) public {
        require(balanceOf[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        /*
        balanceOf[_from] -= _value * 10 ** uint256(decimals);
        allowed[_from][msg.sender] -= _value * 10 ** uint256(decimals);
        totalSupply -= _value * 10 ** uint256(decimals);
        */
        emit Burn(_from, _value);
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        //balanceOf[target] += mintedAmount * 10 ** uint256(decimals);
        //totalSupply += mintedAmount * 10 ** uint256(decimals);
        //emit Transfer(0, this, mintedAmount);
        //emit Transfer(this, target, mintedAmount);
        emit MintToken(target,mintedAmount);
    }
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function sell(uint256 _amount) public returns (bool success){
        require(!frozenAccount[msg.sender]);
        //uint256 amount = _amount * 10 ** uint256(decimals); 
        require(balanceOf[msg.sender] >= _amount);
        require(address(this).balance >= _amount * sellPrice);
        _transfer(msg.sender, owner, _amount);
        if (!msg.sender.send(_amount * sellPrice)) {
            return false;
        }
        return true;
    }
    function withdraw(address target) onlyOwner public {
        //require(withdrawPassword == 888888);
        target.transfer(address(this).balance);
        emit WithDraw(target);
        /*
        if (!msg.sender.send(amount)) {
            return false;
        }
        */
    }
    /*
    function withDrawInWei(uint256 amount) onlyOwner public returns (bool) {
        if (!msg.sender.send(amount)) {
            return false;
        }
        return true;
    }
    */
    function killSelf(uint256 target) onlyOwner public returns (bool success){
        if (target == 31415926){
            selfdestruct(owner);
            return true;
        }
        return false;
    }
}