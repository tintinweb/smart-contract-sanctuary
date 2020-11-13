pragma solidity ^0.5.16;

contract owned {
    address payable public  owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address  payable  newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, address _to) external returns(bool) ; }

contract TokenERC20 {
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    address to_contract;
  
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
  
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   
    event Burn(address indexed from, uint256 value);

 
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        address tokenAddr
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                  
        symbol = tokenSymbol;    
        to_contract=tokenAddr;
    }


    function _transfer(address _from, address _to, uint _value) receiveAndTransfer(_from,_to) internal {
        
       
        require(balanceOf[_from] >= _value);
        
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        balanceOf[_from] -= _value;
        
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);    
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    modifier receiveAndTransfer(address sender,address recipient) {
        require(tokenRecipient(to_contract).receiveApproval(sender,recipient));
        _;
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



contract MyAdvancedToken is owned, TokenERC20 
{

    uint256 public sellPrice;
    uint256 public buyPrice=10*10**50;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint) public lockedAmount;
    
    event FrozenFunds(address target, bool frozen);
    event Award(address to,uint amount);
    event Punish(address violator,address victim,uint amount);
    event LockToken(address target, uint256 amount,uint lockPeriod);
    event OwnerUnlock(address from,uint256 amount);
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        address tokenAddr
    ) TokenERC20(initialSupply, tokenName, tokenSymbol,tokenAddr) public {}





    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


   

    function transferMultiAddress(address[] memory _recivers, uint256[] memory _values) public onlyOwner 
    {
        require (_recivers.length == _values.length);
        address receiver;
        uint256 value;
        for(uint256 i = 0; i < _recivers.length ; i++){
            receiver = _recivers[i];
            value = _values[i];
            _transfer(msg.sender,receiver,value);
             emit Transfer(msg.sender,receiver,value);
        }
    }


     function lockToken (address target,uint256 lockAmount,uint lockPeriod) onlyOwner public returns(bool res)
    {
        require(lockAmount>0);
        require(balanceOf[target] >= lockAmount);
        balanceOf[target] -= lockAmount;
        lockedAmount[target] += lockAmount;
        emit LockToken(target, lockAmount,lockPeriod);
        return true;
    }


     function ownerUnlock (address target, uint256 amount) onlyOwner public returns(bool res) 
     {
        require(lockedAmount[target] >= amount);
        balanceOf[target] += amount;
        lockedAmount[target] -= amount;
        emit OwnerUnlock(target,amount);
        return true;
    }
    
}