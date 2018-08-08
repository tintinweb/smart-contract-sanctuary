pragma solidity ^0.4.8;
 
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
  string public constant symbol = "OX"; 
 
  event Receipt( address indexed _to,
                 uint _oxen,
                 uint _paymentwei ); 

  event Transfer( address indexed _from,
                  address indexed _to,
                  uint _ox );

  uint public starttime;
  bool public expanded;
  uint public inCirculation;
  mapping( address => uint ) public oxen;

  function OX_TOKEN() {
    starttime = 0;
    expanded = false;
    inCirculation = 0;
  }

  function closedown() onlyOwner {
    selfdestruct( owner );
  }

  function() payable {}

  function withdraw( uint amount ) onlyOwner {
    if (amount <= this.balance)
      bool result = owner.send( amount );
  }

  function startSale() onlyOwner {
    if (starttime != 0) return;

    starttime = now; // now is block timestamp, units are unix-seconds

    // allocate 2 for the org itself, so only 5 can be sold
    inCirculation = 200000000;
    oxen[OX_ORG] = inCirculation;
    Transfer( OX_ORG, OX_ORG, inCirculation );
  }

  // TEST CODE ONLY
  //function hack() { starttime = now - 32 days; }
  //function setstart( uint newstart ) { starttime = newstart; }
  //function gettime() constant returns (uint) { return now; }

  function expand() {
    if (expanded || saleOn()) { return; }

    expanded = true;

    // 1 / 0.7 = 1.428571..., ext is the number to add
    uint ext = inCirculation * 1428571428 / 10**9 - inCirculation;
    oxen[OX_ORG] += ext;
    inCirculation += ext;
    Transfer( this, OX_ORG, ext );
  }

  function buyOx() payable {

    // min purchase .1 E = 10**17 wei
    if (!saleOn() || msg.value < 10**17) {
      throw; // returns customer&#39;s Ether and unused gas
    }

    // rate: 1 eth <==> 3000 ox
    //
    // to buy: msg.value * 3000 * (100 + bonus)
    //         ---------          -------------
    //          10**18                 100

    uint tobuy = (msg.value * 3 * (100 + bonus())) / 10**17;

    if (inCirculation + tobuy > 700000000) {
      throw; // returns customer&#39;s Ether and unused gas
    }

    inCirculation += tobuy;
    oxen[msg.sender] += tobuy;
    Receipt( msg.sender, tobuy, msg.value );
  }

  function transfer( address to, uint ox ) {
    if ( ox > oxen[msg.sender] || saleOn() ) {
      return;
    }

    if (!expanded) { expand(); }

    oxen[msg.sender] -= ox;
    oxen[to] += ox;
    Transfer( msg.sender, to, ox );
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

  address public constant OX_ORG = 0x8f256c71a25344948777f333abd42f2b8f32be8e;
  address public constant AUTHOR = 0x8e9342eb769c4039aaf33da739fb2fc8af9afdc1;
}