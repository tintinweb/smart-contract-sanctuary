/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
}


contract Sdoge is IERC20 {
    
    

     string internal _name = "SMART DOGE" ;
     string internal _symbol = "SDOGE";
     uint8 internal  _decimals = 18;
    uint256 internal  _totalSupply;
    uint8 internal  _brate;
    uint256 internal   _minimumSupply;
    address internal _admin;
    mapping (address => uint256) internal  balances;
    mapping (address => mapping (address => uint256)) internal  allowed;
  

    constructor()  {
        _admin = msg.sender;
        _brate = 10;  // brate   burn percent
        _totalSupply = 1000000000* 10**uint(_decimals);
        balances[msg.sender]=_totalSupply;
       _minimumSupply = 998000000* 10** uint (_decimals);
    }
    function changeBurnRate(uint8 brate) public {
           _brate = brate;      
    
   }
     
    function name() public view returns (string memory) {
        return _name;
    } 
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }  
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }
 function transfer(address _to, uint256 _value) public virtual override returns (bool) {
     
     
        uint burn_token = (_value*_brate)/100;
       
       
        emit Transfer(msg.sender, _to, _value - burn_token);
        return true;
   }
 function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
     
        uint burn_token = (_value*_brate)/100;
         emit Transfer(_from, _to, _value - burn_token);
        return true;
   }
   function approve(address _spender, uint256 _value) public virtual override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
   }
  function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return allowed[_owner][_spender];
   }
 function burn(uint256 _value) public returns (bool success) {
        balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        _totalSupply >= _minimumSupply;
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        
       balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        _totalSupply >= _minimumSupply;
        emit Burn(_from, _value);
        return true;
    }
  //Admin can transfer his ownership to new address
  function transferownership(address _newaddress) public returns(bool){
      _admin=_newaddress;
      return true;
  }
    
}