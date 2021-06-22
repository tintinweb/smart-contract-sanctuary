/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract IronManToken is IERC20 {

    string public constant name = "IronManToken";
    string public constant symbol = "IMT";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 _totalSupply;

    using SafeMath for uint256;


   constructor(uint256 total) public {
    _totalSupply = total;
    balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public override view returns (uint256) {
    return _totalSupply;
    }

    function balanceOf(address _tokenowner) public override view returns (uint256) {
        return balances[_tokenowner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _owner, address _to, uint256 _value) public override returns (bool) {
        require(_value <= balances[_owner]);
        require(_value <= allowed[_owner][msg.sender]);

        balances[_owner] = balances[_owner].sub(_value);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_owner, _to, _value);
        return true;
    }
}