pragma solidity ^0.4.18;

contract Hypes {
  event NewOne(address owner, uint256 cost, uint256 new_price);

  struct Hype {
    address owner;
    uint256 cost;
  }

  mapping (uint256 => Hype) public hypes;
  mapping (address => string) public msgs;

  address public ceoAddress;
  uint256 public seatPrice = 2500000000000000;

  modifier onlyCEO() { require(msg.sender == ceoAddress); _; }

  function Hypes() public {
    ceoAddress = msg.sender;
    hypes[1] = Hype(msg.sender, 0);
    hypes[2] = Hype(msg.sender, 0);
    hypes[3] = Hype(msg.sender, 0);
    hypes[4] = Hype(msg.sender, 0);
    hypes[5] = Hype(msg.sender, 0);
    hypes[6] = Hype(msg.sender, 0);
    hypes[7] = Hype(msg.sender, 0);
    hypes[8] = Hype(msg.sender, 0);
    hypes[9] = Hype(msg.sender, 0);
    msgs[msg.sender] = "Claim this spot!";
  }

  function getHype(uint256 _slot) public view returns (
    uint256 slot,
    address owner,
    uint256 cost,
    string message
  ) {
    slot = _slot;
    owner = hypes[_slot].owner;
    cost = hypes[_slot].cost;
    message = msgs[hypes[_slot].owner];
  }

  function purchase() public payable {
    require(msg.sender != address(0));
    require(msg.value >= seatPrice);
    uint256 excess = SafeMath.sub(msg.value, seatPrice);
    hypes[1].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 2)));
    hypes[2].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 4)));
    hypes[3].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 6)));
    hypes[4].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 8)));
    hypes[5].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 10)));
    hypes[6].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 12)));
    hypes[7].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 14)));
    hypes[8].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 16)));
    hypes[9].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 18)));
    hypes[9] = hypes[8]; hypes[8] = hypes[7]; hypes[7] = hypes[6];
    hypes[6] = hypes[5]; hypes[5] = hypes[4]; hypes[4] = hypes[3];
    hypes[3] = hypes[2]; hypes[2] = hypes[1];
    hypes[1] = Hype(msg.sender, seatPrice);
    ceoAddress.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 10)));
    NewOne(msg.sender, seatPrice, SafeMath.mul(SafeMath.div(seatPrice, 100), 120));
    seatPrice = SafeMath.mul(SafeMath.div(seatPrice, 100), 120);
    msg.sender.transfer(excess);
  }

  function setMessage(string message) public payable {
    msgs[msg.sender] = message;
  }

  function payout() public onlyCEO {
    ceoAddress.transfer(this.balance);
  }
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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