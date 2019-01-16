pragma solidity ^0.4.0;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    // OwnershipTransferred(owner, newOwner);
   emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract FreedomCoin is Ownable {

  string public constant symbol = "FC";
  string public constant name = "Freedom Coin";
  uint8 public constant decimals = 0;
  uint256 public totalSupply = 100000000;
  uint256 public rate = 5000000000000 wei;

  uint256 private constant JUNE_01_2018 = 1522822146;
  // uint256 private constant JUNE_01_2018 = 1527791400;
  uint256 private constant JUNE_30_2018 = 1530297000;

  uint256 private constant JUL_01_2018 = 1522822146;
   // uint256 private constant JUL_01_2018 = 1530383400;
  uint256 private constant JUL_31_2018 = 1532975400;

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function FreedomCoin() public{
  balances[owner] = totalSupply;
}

 function inPreSalePeriod() public constant returns (bool) {
        if (now >= JUNE_01_2018 && now < JUNE_30_2018) {
            return true;
        } else {
            return false;
        }
    }

 function inMainSalePeriod() public constant returns (bool) {
        if (now >= JUL_01_2018 && now < JUL_31_2018) {
            return true;
        } else {
            return false;
        }
    }

  function () public payable {
    create(msg.sender);
  }

  function create(address beneficiary)public payable{
      require(beneficiary != address(0));
      //require(inPreSalePeriod());

      uint256 amount = msg.value;

      uint256 token = (amount/rate);

      require(token <= balances[owner]);

      if(amount > 0){
        balances[beneficiary] += token;
        totalSupply += token;
        balances[owner] -= token;
      }
    }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
  }


  function balanceMaxSupply() public constant returns (uint256 balance) {
      return balances[owner];
  }


  function balanceEth(address _owner) public constant returns (uint256 balance) {
      return _owner.balance;
  }

  function collect(uint256 amount) onlyOwner public{
    msg.sender.transfer(amount);
  }

  function transfer(address _to, uint256 _amount) public returns (bool success) {
      //require(inMainSalePeriod());
      require(_to != address(0));
      if (balances[msg.sender] >= _amount && _amount > 0) {
          balances[msg.sender] -= _amount;
          balances[_to] += _amount;
          emit Transfer(msg.sender, _to, _amount);
          return true;
      } else {
          return false;
      }
  }

  // function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
      
  //     //require(inMainSalePeriod());
  //     require(_from != address(0));
  //     require(_to != address(0));
  //     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && balances[_to] + _amount >= balances[_to]);

  //     if (balances[_from] >= _amount
  //         && allowed[_from][msg.sender] >= _amount
  //         && _amount > 0
  //         && balances[_to] + _amount > balances[_to]) {
  //         balances[_from] -= _amount;
  //         allowed[_from][msg.sender] -= _amount;
  //         balances[_to] += _amount;
  //         emit Transfer(_from, _to, _amount);
  //         return true;
  //     } else {
  //         return false;
  //     }
  // }

  // function approve(address _spender, uint256 _amount) public returns (bool success) {
  //     allowed[msg.sender][_spender] = _amount;
  //     emit Approval(msg.sender, _spender, _amount);
  //     return true;
  // }

  // function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
  //     return allowed[_owner][_spender];
  // }

}