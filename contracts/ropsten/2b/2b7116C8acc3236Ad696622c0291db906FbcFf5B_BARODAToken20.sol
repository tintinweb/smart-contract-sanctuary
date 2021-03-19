// SPDX-License-Identifier: MIT
// ERC 20 Token
pragma solidity ^0.7.0;
import "./MYERC20.sol";
import "./SafeMath.sol";

contract BARODAToken20 is MYERC20{
    using SafeMath for uint256;
    string public constant name = "BARODAERC20";
    string public constant symbol = "BRD20";
    uint8 public constant decimals = 5;

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) _allowed;
    uint256 private _totalSupply = 10000000000;  
     
    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256){
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256){
        return _allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool){
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool){
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = _value;        
        emit Approval(msg.sender, _spender, _value);
        return true;
    } 
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value); 
        emit Transfer(_from, _to , _value);    
        return true;
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface MYERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 _value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}