/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

pragma solidity >=0.5.15;
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

contract LockBox  {

    struct Deposit {
        uint tiempo;
        uint amount;
        uint at;
    }

    struct Investor {
        uint id;
        uint ingresed;
        uint out;
        Deposit[] deposits;
        
        uint paidAt;
        
    }

    mapping (address => Investor) public investors;
    mapping (address => bool) public ids;

    function changeIdAcount(address user, uint id) internal  {
        
        investors[user].id = id;
    }

    function frezzAmount(uint _value, uint _unlockTime) internal returns (uint) {
        
        investors[msg.sender].ingresed += _value;
       
        investors[msg.sender].deposits.push(Deposit(_unlockTime, _value, block.timestamp));
        
        return (_value);
    }
    
    function viewDeposits(address any_user, uint paso) public view returns (uint , uint , uint , bool , uint) {
        
        uint desde;
        uint hasta;
        uint cantidad;
        bool completado;

        Investor storage investor = investors[any_user];
        Deposit storage dep = investor.deposits[paso];
        
        uint largo = investor.deposits.length;

        desde = dep.at;
        hasta = dep.at + dep.tiempo;
        cantidad = dep.amount;

        uint tiempoD = dep.tiempo;

        uint finish = dep.at + tiempoD;
        uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
        uint till = block.timestamp > finish ? finish : block.timestamp;

        if (since < till) {
            completado = true;
        }else{
            completado = false;
        }
        
    
        return (desde, hasta, cantidad, completado, largo);
        
      }
    
    function withdrawable(address any_user) public view returns (uint amount) {
    Investor storage investor = investors[any_user];

    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      uint tiempoD = dep.tiempo;

      uint finish = dep.at + tiempoD;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.timestamp > finish ? finish : block.timestamp;

      if (since < till && block.timestamp >= finish) {
        amount += dep.amount;
          
      }
      
    }
  }


  function MYwithdrawable() public view returns (uint amount) {
    Investor storage investor = investors[msg.sender];

    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      uint tiempoD = dep.tiempo;

      uint finish = dep.at + tiempoD;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.timestamp > finish ? finish : block.timestamp;

      if (since < till && block.timestamp >= finish) {
        amount += dep.amount;
      }
    }
  }



  function withdraw() internal returns(uint){
      
    Investor storage investor = investors[msg.sender];

    investor.out += MYwithdrawable();

    investor.paidAt = block.timestamp;

    return MYwithdrawable();

  }
  
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
    
}


contract ProCash is LockBox{

    string public name;
    string public symbol;
    
    uint8 public decimals = 8;
    uint256 public totalSupply;
    

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                    
        name = tokenName;                                       
        symbol = tokenSymbol;                          
    }
     
    function balanceFrozen(address _from) public view returns(uint){
        return investors[_from].ingresed-investors[_from].out;
    }
     
    

    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_from] - balanceFrozen(msg.sender) >= _value, "fondos insuficientes por congelación");
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
        require(_value <= allowance[_from][msg.sender]);     // Comprueba lo asignado
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Revisa si el enviador tiene suficientes
        balanceOf[msg.sender] -= _value;            // Resta los token del enviador
        totalSupply -= _value;                      // Actualiza el total totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Revisa si la direccion objetivo tiene el balance suficiente
        require(_value <= allowance[_from][msg.sender]);    // Comprueba lo asignado
        balanceOf[_from] -= _value;                         // Resta los token de la direccion objetivo
        allowance[_from][msg.sender] -= _value;             // Resta el valor asignado
        totalSupply -= _value;                              // Actualiza el total supply
        emit Burn(_from, _value);
        return true;
    }
}

contract PCASH is owned, ProCash {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public MIN_TIME;


    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) ProCash(initialSupply, tokenName, tokenSymbol) public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));                          
        require (balanceOf[_from] >= _value); 
        require (balanceOf[_from] - balanceFrozen(msg.sender) >= _value);  
        require (balanceOf[_to] + _value >= balanceOf[_to]);    
        require (!frozenAccount[_from]);                         
        require (!frozenAccount[_to]);                           
        balanceOf[_from] -= _value;                             
        balanceOf[_to] += _value;                               
        emit Transfer(_from, _to, _value);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    function claimAcount(uint id) public {
        require(!ids[msg.sender]);
        changeIdAcount(msg.sender, id);
        ids[msg.sender] = true;
    }
    
    function changeIdUserAcount(address user, uint id, bool status) onlyOwner public {
        changeIdAcount(user, id);
        ids[user] = status;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function freezPCASH(uint _value, uint _unlockTime) public {
        require(ids[msg.sender]);
        require(balanceOf[msg.sender] >= _value);
        require(_unlockTime >= MIN_TIME);
        frezzAmount( _value, _unlockTime);
    }
    
    function unFreezPCASH() public {
        require( MYwithdrawable() > 0 );
        withdraw();
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function setMinTime(uint256 newMinTime) onlyOwner public {
        MIN_TIME = newMinTime;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;                 
        _transfer(address(this), msg.sender, amount);       
    }

    function sell(uint256 amount) public {
        address myAddress = address(this);
        require(myAddress.balance >= amount * sellPrice);   
        _transfer(msg.sender, address(this), amount);       
        msg.sender.transfer(amount * sellPrice);    
    }
}