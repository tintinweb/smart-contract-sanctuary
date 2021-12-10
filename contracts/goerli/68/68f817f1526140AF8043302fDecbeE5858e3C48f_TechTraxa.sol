/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.5.0;


contract TechTraxa {
     address owner;
    constructor(uint256 _qty) public {
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_ = "TechTrax1";
        symbol_= "PNK";
        decimal_= 0;
    }


    string name_;
    function name() public view returns(string memory){
     return name_;
    }
    string symbol_;
    function symbol() public view returns(string memory){
     return symbol_;
    }
     uint256 decimal_;
    function decimal() public view returns(uint256){
     return decimal_;
    }
    uint256 tsupply;
    function tatalSupply() public view returns(uint256){
    return tsupply;
    }
    mapping (address => uint256) balances;
    
    function balanceOf(address _owner) public view returns(uint256 Balance){
    return balances[_owner];
    }
    event Transfer(address _from, address _too, uint256 _amt);
    function transfer(address _to,uint256 _value ) public returns(bool success){
        require(balances[msg.sender]>= _value,"insufficient Balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success){
       require(balances[_from]>= _value,"insufficient Balance");
       // check
       require (allowed[_from][msg.sender]  >= _value, "not enough allowed");
       balances[_from] -= _value;
       balances[_to] += _value;
       allowed[_from][msg.sender] -= _value;

       emit Transfer(_from,_to,_value);
       return true;

    }
    
    // function for incresing allowance

    function increseAllowances(address _spender, uint256 _value) public  returns (bool){
     allowed[msg.sender][_spender] += _value;
     return true;
    
    }


    function decreseAllowances(address _spender, uint256 _value) public  returns (bool){
     allowed[msg.sender][_spender] -= _value;
     return true;
    
    }




    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping (address => mapping (address => uint256)) allowed;
   function approve(address _spender, uint256 _value) public returns (bool success){
      allowed[msg.sender][_spender] = _value;
      return true;
   }


   function allowance(address _owner, address _spender) public view returns (uint256 remaining){
      return allowed[_owner][_spender];
   }
   modifier onlyOwner{
       require(msg.sender == owner, "only owner");
     _;

   }

   //Mint 

   function mint(uint256 _qty, address _to) public returns(bool) {
   tsupply += _qty;
   // newllt minted token to some one specified address
   balances[_to] += _qty;
  // balances[msg.sender] +=_qty;
  // balances[owner]= _qty;
   return true;
   }
   // Burn

   function burn(uint256 _qty) public onlyOwner returns (bool){
       require (balances[msg.sender] >= _qty, "not enough token to burn");
       tsupply -= _qty;
       balances[owner] -= _qty;
       return true;
   }

}