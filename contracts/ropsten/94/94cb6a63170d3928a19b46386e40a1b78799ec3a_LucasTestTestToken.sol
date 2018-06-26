pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
//增發前必須提取ＯＷＮＥＲ權限
contract owned {
    address public owner;
    

    constructor()public{
       owner = msg.sender; 
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // 实现所有权转移
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

//增發前必須調用ＯＷＮＥＲ權限
contract LucasTestTestToken is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;  // 18 是建议的默认值
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;  // 
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string tokenName, /*uint8 decimalUnits,*/ string tokenSymbol, address centralMinter) public {
        if(centralMinter != 0 ) owner = centralMinter;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    
    //增發
    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    //買賣合同
    
    //設置買賣價格
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    //設置市場可供買賣
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    //設置市場可供買
    function buy() public payable returns (uint amount){
        amount = msg.value / buyPrice;                    // calculates the amount
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[this] -= amount;                        // subtracts amount from seller&#39;s balance
        emit Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }
    //設置市場可供賣
    function sell(uint amount) public returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }

    //GAS Automatic add amount
    uint minBalanceForAccounts;

    function setMinBalance(uint minimumBalanceInFinney) public onlyOwner {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
    
    

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
     
        if(msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
        /*if(_to.balance<minBalanceForAccounts)   // 可选，让接受者也补充余额，以便接受者使用代币。
            _to.send(sell((minBalanceForAccounts - _to.balance) / sellPrice));*/
        if (_to == 0x0) revert();//throw;                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert();//throw; 
        if (balanceOf[msg.sender] < _value) revert();//throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();//throw; // Check for overflows
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}