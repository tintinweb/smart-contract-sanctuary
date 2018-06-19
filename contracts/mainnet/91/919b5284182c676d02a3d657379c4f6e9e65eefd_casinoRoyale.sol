pragma solidity ^0.4.24;
contract casinoRoyale {
    AbstractRandom m_RandomGen = AbstractRandom(0xba978d581bec0d735cf75f43a83f6d2b2a6015d0);
    address owner;
    event FlipCoinEvent(
    uint value,
    address owner
    );

    event PlaySlotEvent(
      uint value,
      address owner
    );
    
    constructor(){
        owner = msg.sender;
    }

  function() public payable {}

  function flipCoin() public payable {
    require(msg.value > 1500 szabo && tx.origin == msg.sender);
    uint value = m_RandomGen.random(100,uint8(msg.value));
    if (value > 55){
      msg.sender.transfer(msg.value * 2);
    }
    FlipCoinEvent(value, msg.sender);
  }

function playSlot() public payable {
    require(msg.value > 1500 szabo && tx.origin == msg.sender);
    uint r = m_RandomGen.random(100,uint8(msg.value));
       if(r >0 && r<3){ // 2
             PlaySlotEvent(3,msg.sender);
             msg.sender.transfer(msg.value * 12);
       }else if(r >3 && r<6){ // 5
             PlaySlotEvent(2,msg.sender);
             msg.sender.transfer(msg.value * 6);
       }else if(r >6 && r<9){ // 7
             PlaySlotEvent(1,msg.sender);
             msg.sender.transfer(msg.value * 3);
       }else{
            PlaySlotEvent(0,msg.sender);
       }

  }

  function getBalance() public constant returns(uint bal) {
    bal = this.balance;
    return bal;
  }
  
  function withdraw(uint256 value) public{
      require(owner == msg.sender);
      msg.sender.transfer(value);
        
  }

}

contract AbstractRandom
{
    function random(uint256 upper, uint8 seed) public returns (uint256 number);
}