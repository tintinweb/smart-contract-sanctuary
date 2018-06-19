pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract owned {
    address public owner;
    uint8 public  n=0;
    function owned(){
     if(n==0){
            owner = msg.sender;
	    n=n+1;
        }        
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
       
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
contract TokenERC20 is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;  // 18 是建议的默认值
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;  
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint minBalanceForAccounts;  
   
    event FrozenFunds(address target, bool frozen);
    mapping (address => bool) public frozenAccount;

    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
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
    
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
            balanceOf[target] += mintedAmount;
            totalSupply += mintedAmount;
            Transfer(0, owner, mintedAmount);
            Transfer(owner, target, mintedAmount);
        }

    function freezeAccount(address target,bool _bool) onlyOwner{
        if(target != 0){
            frozenAccount[target] = _bool;
        }
    }
     
     function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
            sellPrice = newSellPrice;
            buyPrice = newBuyPrice;
        }
       
     function buy() returns (uint amount){
            amount = msg.value / buyPrice;                     // calculates the amount
            if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
            balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
            balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
            Transfer(this, msg.sender, amount);                // execute an event reflecting the change
            return amount;                                     // ends function and returns
        }
       
        function sell(uint amount) returns (uint revenue){
            if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
            balanceOf[this] += amount;                         // adds the amount to owner&#39;s balance
            balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
            revenue = amount * sellPrice;                      // calculate the revenue
            msg.sender.send(revenue);                          // sends ether to the seller
            Transfer(msg.sender, this, amount);                // executes an event reflecting on the change
            return revenue;                                    // ends function and returns
        }

    
        function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
            minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
        }
}