/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity ^0.4.18;



contract ERC20Basic {

  function totalSupply() public view returns (uint256);  // totalSupply - 总发行量

  function balanceOf(address who) public view returns (uint256);  // 余额

  function transfer(address to, uint256 value) public returns (bool);  // 交易

  event Transfer(address indexed from, address indexed to, uint256 value);  // 交易事件

}



library SafeMath {



  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {

      return 0;

    }

    uint256 c = a * b;

    assert(c / a == b);

    return c;

  }

  /**

  * @dev Integer division of two numbers, truncating the quotient.

  */

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    // assert(b > 0); // Solidity automatically throws when dividing by 0

    uint256 c = a / b;

    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;

  }

 

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



contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) public view returns (uint256);  // 获取被授权令牌余额,获取 _owner 地址授权给 _spender 地址可以转移的令牌的余额

  function transferFrom(address from, address to, uint256 value) public returns (bool);  // A账户-》B账户的转账

  function approve(address spender, uint256 value) public returns (bool);  // 授权，允许 _spender 地址从你的账户中转移 _value 个令牌到任何地方

  event Approval(address indexed owner, address indexed spender, uint256 value);  // 授权事件

}

/**

* @title Basic token

* @dev Basic version of StandardToken, with no allowances.

*/

contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances; 

  uint256 totalSupply_;  



  function totalSupply() public view returns (uint256) {

    return totalSupply_;

  }


  function transfer(address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));  // 无效地址

    require(_value <= balances[msg.sender]);  // 转账账户余额大于转账数目

    // SafeMath.sub will throw if there is not enough balance.

    balances[msg.sender] = balances[msg.sender].sub(_value);  // 转账账户余额=账户余额-转账金额

    balances[_to] = balances[_to].add(_value); // 接收账户的余额=原先账户余额+账金额

    emit Transfer(msg.sender, _to, _value);  // 转账

    return true;

  }



  function balanceOf(address _owner) public view returns (uint256 balance) {

    return balances[_owner];  // 查询合约调用者的余额

  }

}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0)); // 到达B账户的地址不能为无效地址

    require(_value <= balances[_from]);  // 转账账户余额大于转账金额

    require(_value <= allowed[_from][msg.sender]);  // 允许_from地址转账给 _to地址

    balances[_from] = balances[_from].sub(_value); 

    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  // 允许转账的余额

    emit Transfer(_from, _to, _value);

    return true;

  }



  function approve(address _spender, uint256 _value) public returns (bool) {

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;

  }



  function allowance(address _owner, address _spender) public view returns (uint256) {

    return allowed[_owner][_spender];

  }

  

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }

 

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {

    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {

      allowed[msg.sender][_spender] = 0;

    } else {

      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }

}



contract EchoToken is StandardToken {

    string public constant name = "EchoToken";

    string public constant symbol = "Echo";

    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = (10 ** 9) * (10 ** uint256(decimals));

    /**

    * @dev Constructor that gives msg.sender all of existing tokens.

    */

    constructor() public {

        totalSupply_ = INITIAL_SUPPLY;

        balances[msg.sender] = INITIAL_SUPPLY;

        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);

    }

}