pragma solidity 0.4.25;

library SafeMath {

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Item is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(bytes => bool) signatures;
   
    uint256 internal totalSupply_ = 0;
    string public name = &#39;xxx&#39;;
    string public symbol = &#39;xxx&#39;;
    uint public decimals = 0;

    constructor(address _initialHolder, uint256 _initialValues, string _symbol,string _name) {
        name = _name;
        symbol = _symbol;
        balances[_initialHolder] = _initialValues;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return _approve(_spender,msg.sender, _value);
    }

    function _approve(address _spender, address _owner, uint256 _value) internal returns (bool) {
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }


    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_value <= balances[_from]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}

contract ItemFactory {
    
    uint256 public createdItem = 0;
    mapping(uint256 => address) public id;
    mapping(address => uint256) public items;
    
    function createContract (uint256 initialValues, string symbol, string name) {
        address newItemContract = new Item(msg.sender, initialValues, symbol, name);
        createdItem += 1;
        items[newItemContract] = createdItem;
        id[createdItem] = newItemContract;
    } 
}