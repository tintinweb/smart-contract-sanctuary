/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;

contract ERC20Token{

 address deployer;

    constructor(string memory _name ,string memory _symbol ,uint8 _decimal) public {
           tsupply = 0;
           deployer = msg.sender;

           balances[msg.sender] = 0;
           name_ = _name;
           symbol_ = _symbol;
           decimal_ = _decimal;

    }


 string name_;
    function name () public view returns(string memory){
        return name_;

    }
 string symbol_;
    function symbol () public view returns(string memory){
        return symbol_;
    }
 uint8 decimal_;
    function decimals () public view returns(uint8){
        return decimal_;
        
    }
 uint256 tsupply;
     function totalsupply () public view returns(uint256){
        return tsupply;
    }
    
  mapping(address => uint256) balances;
    
    
 
 function balanceof(address _owner) public view returns(uint256 Balance){
     return balances[_owner];
 }
  

  event Transfer(address _from, address _too,uint256 _amt);

 function transfer(address _to , uint256 _value) public returns(bool success){
     require(balances[msg.sender]>= _value,"insufficient balance");
     balances[msg.sender] -= _value;
     balances[_to] += _value;

     emit Transfer(msg.sender,_to,_value);
     return true;
 }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
     require(balances[_from]>= _value,"insufficient balance");

     /// cheak allowence is availabe

     require(allowed[_from][msg.sender] >= _value,"not enough allowance");
     balances[_from] -= _value;
     balances[_to] -= _value;

     allowed[_from][msg.sender] -= _value;
      
      emit Transfer(_from,_to,_value);

     return true;

  }
  
   mapping(address => mapping(address => uint256)) allowed;
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);   
  function approve(address _spender, uint256 _value) public returns (bool success){
      
       // no cheaking of the balance of owner
       
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;

  }


 /// Increase the allowance

 function increaseAllowance(address _spender, uint256 _value) public returns (bool success){
      
       // no cheaking of the balance of owner
  
    
      

      allowed[msg.sender][_spender] += _value;
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;

  }

  // Decreasing allowance

  function decreaseAllowance(address _spender, uint256 _value) public returns (bool success){
      
       // no cheaking of the balance of owner
      allowed[msg.sender][_spender] -= _value;
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;

  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining){
       return allowed[_owner][_spender];
  }


  // Mint

  modifier onlyOwner (){
  require(msg.sender == deployer ," only deployer can mint");
  _;
  }

   
   function mint(uint256 _qty ,address _adr) public onlyOwner returns (bool){
   tsupply += _qty;
   // newly minted tokens to some specified address

   balances[_adr] += _qty;
   // newly minted tokens to who runs this function
   //balances[msg.sender] += _qty;
  

   // newly minted tokens to deployer
  // balances[deployer] += _qty;
    return true;
   

   }


  // Burn

  function burn (uint256 _qty) public onlyOwner returns(bool){

      require( balances[deployer]>= _qty,"not enough to burn");
      tsupply -= _qty;
      balances[deployer] -= _qty;
      return true;
   
  }

}

contract IXIONO is ERC20Token {
constructor () ERC20Token( "IXIONO","IXI",0) public {
    mint(1000,deployer);
    
}
}