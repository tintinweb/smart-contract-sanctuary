/**
 *Submitted for verification at Etherscan.io on 2020-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
     function balanceOf(address _addr)  external view returns (uint);
    function transfer(address _to, uint _value)  external returns (bool);
}

interface ERC223 {
    function transfer(address _to, uint _value, bytes memory _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}



 contract SonergyToken {
    string internal _symbol;
    string internal _name;
    uint internal _decimals;
    uint internal _totalSupply = 21000000000000000000000000;
    mapping (address => uint) _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

    constructor (string memory __symbol, string memory __name, uint __decimals, uint __totalSupply) {
        _symbol = __symbol;
        _name = __name;
        _decimals = __decimals;
        _totalSupply = __totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() virtual public view returns (uint) {
        return _totalSupply;
    }

   
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

library SafeMath {
 
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

contract Sonergy is SonergyToken("SNEGY", "Sonergy", 18, 21000000000000000000000000), ERC20, ERC223 {
    address private _owner;
  
 
    
  
    
    using SafeMath for uint;
    
 
    
    constructor() {
        _balanceOf[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }
   
    
  
  
  
  
    
  
    function totalSupply() override public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) override public view returns (uint) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint _value) override public returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            !isContract(_to) ) {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    
    

    function transfer(address _to, uint _value, bytes memory _data) override public returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            isContract(_to)) {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        return false;
    }
    
   
  

    function isContract(address _addr) private view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint _value) override public returns (bool) {
        if (_allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            _allowances[_from][msg.sender] >= _value &&
            _balanceOf[_from] >= _value) {
            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }
    

   
    function approve(address _spender, uint _value) override public returns (bool) {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].add(_value);
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _addressOwner, address _spender) override public view returns (uint) {
        return _allowances[_addressOwner][_spender];
    }
}