pragma solidity ^0.4.18;

// sol to LUSD token
// 
// Senior Development Engineer  CHIEH-HSUAN WANG of Lucas. 
// Jason Wang  <ixhxpns@gmail.com>
// reference https://ethereum.org/token
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

//Get Owner
contract owned {
    address public owner;
    constructor() public{
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
contract LUSD is owned {
    address public deployer;
    // Public variables of the token
    string public name ="Lucas Credit Cooperative";
    string public symbol = "LUSD";
    uint8 public decimals = 4;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply = 1000000000000;

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
        deployer = msg.sender;
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

    //GAS Automatic add amount
    uint minBalanceForAccounts;

    function setMinBalance(uint minimumBalanceInFinney) public onlyOwner {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
      
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        /*if(msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
        if(_to.balance<minBalanceForAccounts)   // 可选，让接受者也补充余额，以便接受者使用代币。
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
    
    /*function kill() public {
       if (owner == msg.sender) { // 检查谁在调用
          selfdestruct(owner); // 销毁合约
       }
    }*/
    //function increaseSupply(uint _value, address _to) public returns (bool);//ERC223 增發
    //function decreaseSupply(uint _value, address _from) public returns (bool);
    
}