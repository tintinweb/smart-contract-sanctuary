//
// compiler: solcjs -o ../build/contracts --optimize --abi --bin OX_TOKEN.sol
//  version: 0.4.11+commit.68ef5810.Emscripten.clang
//
pragma solidity ^0.4.11;

contract owned {
  address public owner;

  function owned() { owner = msg.sender; }

  modifier onlyOwner {
    if (msg.sender != owner) { throw; }
    _;
  }
  function changeOwner( address newowner ) onlyOwner {
    owner = newowner;
  }
}

contract OX_TOKEN is owned {

  string public constant name = "OX";
  string public constant symbol = "FIXED";

  event Transfer( address indexed _from,
                  address indexed _to,
                   uint256 _value );

  event Approval( address indexed _owner,
                  address indexed _spender,
                  uint256 _value);

  event Receipt( address indexed _to,
                 uint _oxen,
                 uint _paymentwei );

  uint public starttime;
  uint public inCirculation;
  mapping( address => uint ) public oxen;
  mapping( address => mapping (address => uint256) ) allowed;

  function OX_TOKEN() {
    starttime = 0;
    inCirculation = 0;
  }

  function closedown() onlyOwner {
    selfdestruct( owner );
  }

  function() payable {
    buyOx(); // forwards value, gas
  }

  function withdraw( uint amount ) onlyOwner returns (bool success) {
    if (amount <= this.balance)
      success = owner.send( amount );
    else
      success = false;
  }

  function startSale() onlyOwner {
    if (starttime != 0) return;

    starttime = now; // now is block timestamp in unix-seconds
    inCirculation = 500000000; // reserve for org
    oxen[owner] = inCirculation;
    Transfer( address(this), owner, inCirculation );
  }

  function buyOx() payable {

    // min purchase .1 E = 10**17 wei
    if (!saleOn() || msg.value < 100 finney) {
      throw; // returns caller&#39;s Ether and unused gas
    }

    // rate: 1 eth <==> 3000 ox
    // to buy: msg.value * 3000 * (100 + bonus)
    //         ---------          -------------
    //          10**18                 100
    uint ox = div( mul(mul(msg.value,3), 100 + bonus()), 10**17 );

    if (inCirculation + ox > 1000000000) {
      throw;
    }

    inCirculation += ox;
    oxen[msg.sender] += ox;
    Receipt( msg.sender, ox, msg.value );
  }

  function totalSupply() constant returns (uint256 totalSupply) {
    return inCirculation;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    balance = oxen[_owner];
  }

  function approve(address _spender, uint256 _amount) returns (bool success) {
    if (saleOn()) return false;

    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns
  (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function transfer( address to, uint ox ) returns (bool success) {
    if ( ox > oxen[msg.sender] || saleOn() ) {
      return false;
    }

    oxen[msg.sender] -= ox;
    oxen[to] += ox;
    Transfer( msg.sender, to, ox );
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amount)
  returns (bool success) {
    if (    oxen[_from] >= _amount
         && allowed[_from][msg.sender] >= _amount
         && _amount > 0
         && oxen[_to] + _amount > oxen[_to]
       )
    {
      oxen[_from] -= _amount;
      allowed[_from][msg.sender] -= _amount;
      oxen[_to] += _amount;
      Transfer(_from, _to, _amount);
      success = true;
    }
    else
    {
      success = false;
    }
  }

  function saleOn() constant returns(bool) {
    return now - starttime < 31 days;
  }

  function bonus() constant returns(uint) {
    uint elapsed = now - starttime;

    if (elapsed < 1 days) return 25;
    if (elapsed < 1 weeks) return 20;
    if (elapsed < 2 weeks) return 15;
    if (elapsed < 3 weeks) return 10;
    if (elapsed < 4 weeks) return 5;
    return 0;
  }

  // ref:
  // github.com/OpenZeppelin/zeppelin-solidity/
  // blob/master/contracts/SafeMath.sol
  function mul(uint256 a, uint256 b) constant returns (uint256) {
    uint256 c = a * b;
    if (a == 0 || c / a == b)
    return c;
    else throw;
  }
  function div(uint256 a, uint256 b) constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  address public constant AUTHOR = 0x008e9342eb769c4039aaf33da739fb2fc8af9afdc1;
}