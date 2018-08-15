pragma solidity ^0.4.20;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) public pure  returns (uint256)  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b)public pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function _assert(bool assertion)public pure {
    assert(!assertion);
  }
}


contract ERC20Interface {
  string public name;
  string public symbol;
  uint8 public  decimals;
  uint public totalSupply;
  uint256 public currentTotalSupply;
  uint256 startBalance ;
  function transfer(address _to, uint256 _value)public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value)public returns (bool success);
  
  function approve(address _spender, uint256 _value)public returns (bool success);
  function allowance(address _owner, address _spender)public view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
contract ERC20 is ERC20Interface,SafeMath {

    // ?????????????balanceOf????
    mapping(address => uint256) public balances;
    
    // allowed?????????????????address?? ????????????(?????address)?????uint256??
    mapping(address => mapping(address => uint256)) allowed;
    
    mapping(address => bool) touched;

    constructor(string _name) public {
       name = _name;  // "UpChain";
       symbol = "CSB";
       decimals = 4;
       totalSupply = 100000000000000 ether;
       currentTotalSupply = 0;
       startBalance = 1000000 ether ;
       balances[msg.sender] = totalSupply;
    }

  // ???
  function transfer(address _to, uint256 _value)public returns (bool success) {
      require(_to != address(0));
       if( !touched[msg.sender] && currentTotalSupply < totalSupply ){
            balances[msg.sender] = safeSub(balances[msg.sender], startBalance );
            touched[msg.sender] = true;
            currentTotalSupply = safeAdd(currentTotalSupply, startBalance );
        }
      require(balances[msg.sender] >= _value);
      require(balances[ _to] + _value >= balances[ _to]);   // ??????

      balances[msg.sender] =SafeMath.safeSub(balances[msg.sender],_value) ;
      balances[_to] =SafeMath.safeAdd(balances[_to] ,_value);

      // ???????
      emit Transfer(msg.sender, _to, _value);

      return true;
  }


  function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
      require(_to != address(0));
      require(allowed[_from][msg.sender] >= _value);
       if( !touched[_from] && currentTotalSupply < totalSupply ){
            touched[_from] = true;
            balances[_from] =safeAdd( balances[_from],startBalance );
            currentTotalSupply =safeAdd(currentTotalSupply,startBalance );
        }
      require(balances[_from] >= _value);
      require(balances[_to] + _value >= balances[_to]);
      
      balances[_from] =SafeMath.safeSub(balances[_from],_value) ;
      balances[_to] = SafeMath.safeAdd(balances[_to],_value);

      allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender], _value);

      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function approve(address _spender, uint256 _value)public returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }
  
  function getBalance(address _owner) internal constant returns(uint256)
    {
        if( currentTotalSupply < totalSupply ){
            if( touched[_owner] )
                return balances[_owner];
            else
                balances[_owner]=safeAdd(balances[_owner],startBalance);
                return safeAdd(balances[_owner], startBalance );
        } else {
            return balances[_owner];
        }
    }
    
  function balanceOf(address _owner) public view returns (uint256 balance) {
        return getBalance( _owner );
    }

}


contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract SelfDesctructionContract is owned {
   
   string  public someValue;
   modifier ownerRestricted {
      require(owner == msg.sender);
      _;
   } 
   // constructor
   function SelfDesctruction()public {
      owner = msg.sender;
   }
   // a simple setter function
   function setSomeValue(string value)public{
      someValue = value;
   } 
   // you can call it anything you want
   function destroyContract() ownerRestricted public{
     selfdestruct(owner);
   }
}



contract AdvanceToken is ERC20, SelfDesctructionContract{

    mapping (address => bool) public frozenAccount;

    event AddSupply(uint amount);
    event FrozenFunds(address target, bool frozen);
    event Burn(address target, uint amount);

    constructor (string _name) ERC20(_name) public {

    }

    function mine(address target, uint amount) public onlyOwner {
        totalSupply =SafeMath.safeAdd(totalSupply,amount) ;
        balances[target] = SafeMath.safeAdd(balances[target],amount);

        emit AddSupply(amount);
        emit Transfer(0, target, amount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


  function transfer(address _to, uint256 _value) public returns (bool success) {
        
      
        success = _transfer(msg.sender, _to, _value);
        

        
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);
        
        if( !touched[_from] && currentTotalSupply < totalSupply ){
            touched[_from] = true;
            balances[_from] =safeAdd( balances[_from],startBalance );
            currentTotalSupply =safeAdd(currentTotalSupply,startBalance );
        }
        
        success =  _transfer(_from, _to, _value);
        allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender],_value) ;
  }

  function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
      require(_to != address(0));
      require(!frozenAccount[_from]);
      
      if( !touched[_from] && currentTotalSupply < totalSupply ){
            touched[_from] = true;
            balances[_from] =safeAdd( balances[_from],startBalance );
            currentTotalSupply =safeAdd(currentTotalSupply,startBalance );
        }

      require(balances[_from] >= _value);
      require(balances[ _to] + _value >= balances[ _to]);

      balances[_from] =SafeMath.safeSub(balances[_from],_value) ;
      balances[_to] =SafeMath.safeAdd(balances[_to],_value) ;

      emit Transfer(_from, _to, _value);
      return true;
  }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);

        totalSupply =SafeMath.safeSub(totalSupply,_value) ;
        balances[msg.sender] =SafeMath.safeSub(balances[msg.sender],_value) ;

        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value)  public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        totalSupply =SafeMath.safeSub(totalSupply,_value) ;
        balances[msg.sender] =SafeMath.safeSub(balances[msg.sender], _value);
        allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender],_value);

        emit Burn(msg.sender, _value);
        return true;
    }
}