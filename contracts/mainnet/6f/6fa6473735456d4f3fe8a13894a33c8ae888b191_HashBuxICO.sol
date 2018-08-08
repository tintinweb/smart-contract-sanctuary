//
// compiler: solcjs -o ./build/contracts --optimize --abi --bin <this file>
//  version: 0.4.15+commit.bbb8e64f.Emscripten.clang
//
pragma solidity ^0.4.15;

contract owned {
  address public owner;

  function owned() { owner = msg.sender; }

  modifier onlyOwner {
    if (msg.sender != owner) { revert(); }
    _;
  }

  function changeOwner( address newowner ) onlyOwner {
    owner = newowner;
  }

  function closedown() onlyOwner {
    selfdestruct( owner );
  }
}

// "extern" declare functions from token contract
interface HashBux {
  function transfer(address to, uint256 value);
  function balanceOf( address owner ) constant returns (uint);
}

contract HashBuxICO is owned {

  uint public constant STARTTIME = 1522072800; // 26 MAR 2018 00:00 GMT
  uint public constant ENDTIME = 1522764000;   // 03 APR 2018 00:00 GMT
  uint public constant HASHPERETH = 1000;       // price: approx $0.65 ea

  HashBux public tokenSC;

  function HashBuxICO() {}

  function setToken( address tok ) onlyOwner {
    if ( tokenSC == address(0) )
      tokenSC = HashBux(tok);
  }

  function() payable {
    if (now < STARTTIME || now > ENDTIME)
      revert();

    // (amountinwei/weipereth * hash/eth) * ( (100 + bonuspercent)/100 )
    // = amountinwei*hashpereth/weipereth*(bonus+100)/100
    uint qty =
      div(mul(div(mul(msg.value, HASHPERETH),1000000000000000000),(bonus()+100)),100);

    if (qty > tokenSC.balanceOf(address(this)) || qty < 1)
      revert();

    tokenSC.transfer( msg.sender, qty );
  }

  // unsold tokens can be claimed by owner after sale ends
  function claimUnsold() onlyOwner {
    if ( now < ENDTIME )
      revert();

    tokenSC.transfer( owner, tokenSC.balanceOf(address(this)) );
  }

  function withdraw( uint amount ) onlyOwner returns (bool) {
    if (amount <= this.balance)
      return owner.send( amount );

    return false;
  }

  function bonus() constant returns(uint) {
    uint elapsed = now - STARTTIME;

    if (elapsed < 24 hours) return 50;
    if (elapsed < 48 hours) return 30;
    if (elapsed < 72 hours) return 20;
    if (elapsed < 96 hours) return 10;
    return 0;
  }

  // ref:
  // github.com/OpenZeppelin/zeppelin-solidity/
  // blob/master/contracts/math/SafeMath.sol
  function mul(uint256 a, uint256 b) constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }
}