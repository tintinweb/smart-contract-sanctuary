pragma solidity ^0.4.18;
library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/*
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

/*
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC223 interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 is ERC20 {
    function transfer(address to, uint256 value, bytes data) public returns (bool ok);

    function transferFrom(address from, address to, uint256 value, bytes data) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) allowed;


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
  }


contract BurnableToken is BasicToken, Ownable {

      event Burn(address indexed burner, uint256 value);


      function burn(uint256 _value)  public onlyOwner{
          require(_value <= balances[msg.sender]);
          // no need to require value <= totalSupply, since that would imply the
          // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
          address burner = msg.sender;
          balances[burner] = balances[burner].sub(_value);
          totalSupply_ = totalSupply_.sub(_value);
          emit Burn(burner, _value);
      }
}

contract FrozenToken is Ownable {
      mapping(address => bool) public frozenAccount;

      event FrozenFunds(address target, bool frozen);

      function freezeAccount(address target, bool freeze) public onlyOwner {
          frozenAccount[target] = freeze;
          emit FrozenFunds(target, freeze);
      }

      modifier requireNotFrozen(address from){
          require(!frozenAccount[from]);
          _;
      }
}


contract ERC223Receiver {
      function tokenFallback(address _from, uint256 _value, bytes _data) public returns (bool ok);
  }

contract Standard223Token is ERC223, StandardToken {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
        require(super.transfer(_to, _value));
        if (isContract(_to)) return contractFallback(msg.sender, _to, _value, _data);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool success) {
        require(super.transferFrom(_from, _to, _value));
        if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
        return true;
    }

    function contractFallback(address _from, address _to, uint256 _value, bytes _data) private returns (bool success) {
        ERC223Receiver receiver = ERC223Receiver(_to);
        return receiver.tokenFallback(_from, _value, _data);
    }

    function isContract(address _addr) internal view returns (bool is_contract) {
        uint256 length;
        assembly {length := extcodesize(_addr)}
        return length > 0;
    }
}

/**
 * ERC20 token
 * DIO
 */
contract DistributedInvestmentOperationPlatformToken is Pausable, BurnableToken, Standard223Token, FrozenToken {

    string public name;
    string public symbol;
    uint256 public decimals;


    constructor (uint256 _initialSupply, string _name, string _symbol, uint256 _decimals) public {
        totalSupply_ = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[msg.sender] = _initialSupply;
        emit Transfer(0x0, msg.sender, _initialSupply);

}
    function transfer(address _to, uint256 _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_to) returns (bool) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_from) requireNotFrozen(_to) returns (bool) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    function approve(address _spender, uint256 _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    //ERC223
    function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_to) returns (bool success) {
        return super.transfer(_to, _value, _data);
    }
    //ERC223
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_from) requireNotFrozen(_to) returns (bool success) {
        return super.transferFrom(_from, _to, _value, _data);
    }
}