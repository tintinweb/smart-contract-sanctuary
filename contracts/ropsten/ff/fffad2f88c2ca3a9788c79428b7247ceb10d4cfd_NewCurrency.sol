pragma solidity ^0.4.24;

contract ERC20 {
  function totalSupply() external constant returns (uint supply);
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) external returns (bool ok);
  function transferFrom(address from, address to, uint value) external returns (bool ok);
  function approve(address spender, uint value) external returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract NewCurrency is ERC20 {

    uint public _totalSupply = 90000;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    string public symbol = "OMCUR";
    string public name = "Om Currency";
    uint8 public decimal = 3;
    string public version = &#39;OMCUR 0.1&#39;;

    constructor() public {
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() external constant returns (uint supply) {
        return _totalSupply;
    }
    function balanceOf(address who) public constant returns (uint value) {
        return balances[who];
    }

    function transfer( address to, uint value) external returns (bool ok) {
        require(
            balances[msg.sender] >= value
            && value > 0
        );
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom( address from, address to, uint value) external returns (bool ok) {
        require(
            allowed[from][msg.sender] >= value
            && balances[from] >= value
            && value > 0
        );
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
       emit Transfer(from, to, value);
        return true;
    }
    function approve( address spender, uint value ) external returns (bool ok) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function allowance( address owner, address spender ) public constant returns (uint _allowance) {
        return allowed[owner][spender];
    }

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);

}