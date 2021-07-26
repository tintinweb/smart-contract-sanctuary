/**
 *Submitted for verification at BscScan.com on 2021-07-26
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


//code modded by shadow3friend
library SafeMath {

// 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    ///
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    ///
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
//
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    ///
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Sdoge is IERC20 {
    
    using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint8 internal  _decimals;
    uint256 internal  _totalSupply;
    uint8 internal  _brate;
    uint256 internal   _minimumSupply;
    address internal _admin;
    mapping (address => uint256) internal  balances;
    mapping (address => mapping (address => uint256)) internal  allowed;
  

    constructor()  {
        _admin = msg.sender;
        _symbol = "SMART DOGE";  
        _name = "SDOGE"; 
        _decimals = 18;
        _brate = 10;  // 10%  burn 
        _totalSupply = 1000000000* 10**uint(_decimals);
        balances[msg.sender]=_totalSupply;
       _minimumSupply = 998000000* 10** uint (_decimals);
    }
    function changeBurnRate(uint8 brate) public {
         require(msg.sender==_admin);
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
     
     require(_to != address(0) && _value > 0);

        uint burn_token = (_value*_brate)/100;
        require(_value+burn_token > _value);
        require(_value + burn_token <= balances[msg.sender]);
        balances[msg.sender] = (balances[msg.sender]).sub(_value - burn_token);
        balances[_to] = (balances[_to]).add(_value - burn_token);
        emit Transfer(msg.sender, _to, _value - burn_token);
        require( burn(burn_token));
        return true;
   }
 function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0) && _from != address(0) && _value > 0);

        uint burn_token = (_value*_brate)/100;
     require(_value+burn_token > _value);


        require(_value + burn_token <= balances[_from]);
     require(_value + burn_token <= allowed[_from][msg.sender]);
        
        balances[_from] = (balances[_from]).sub(_value - burn_token);
        balances[_to] = (balances[_to]).add(_value - burn_token);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub( _value - burn_token);
        emit Transfer(_from, _to, _value - burn_token);
        require( burn(burn_token));
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
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        require (_totalSupply > _minimumSupply);    // requiere que el total supply sea mayor que el minimo existente 
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
        
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        require (_totalSupply > _minimumSupply);            // requiere que el total supply sea mayor que el minimo existente
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        _totalSupply >= _minimumSupply;
        emit Burn(_from, _value);
        return true;
    }
  //Admin can transfer his ownership to new address
  function transferownership(address _newaddress) public returns(bool){
      require(msg.sender==_admin);
      _admin=_newaddress;
      return true;
  }
    
}