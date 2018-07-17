pragma solidity 0.4.18;

contract Nines {
  event NewOne(address owner, uint256 cost, uint256 new_price);

  struct Nine {
    address owner;
    uint256 cost;
  }    

  mapping (uint256 => Nine) public nines;
  mapping (address => string) public msgs;

  address public ceoAddress;
  uint256 public seatPrice = 1000000000000000;

  modifier onlyCEO() { require(msg.sender == ceoAddress); _; }

  function Nines() public {
    ceoAddress = msg.sender;
    nines[1] = Nine(msg.sender, 0);
    nines[2] = Nine(msg.sender, 0);
    nines[3] = Nine(msg.sender, 0);
    nines[4] = Nine(msg.sender, 0);
    nines[5] = Nine(msg.sender, 0);
    nines[6] = Nine(msg.sender, 0);
    nines[7] = Nine(msg.sender, 0);
    nines[8] = Nine(msg.sender, 0);
    nines[9] = Nine(msg.sender, 0);
    nines[10] = Nine(msg.sender, 0);
    msgs[msg.sender] = &quot;Claim this spot!&quot;;
  }

  function getNine(uint256 _slot) public view returns (
    uint256 slot,
    address owner,
    uint256 cost,
    string message
  ) {
    slot = _slot;
    owner = nines[_slot].owner;
    cost = nines[_slot].cost;
    message = msgs[nines[_slot].owner];
  }

  function purchase() public payable {
    require(msg.sender != address(0));
    require(msg.value >= seatPrice);
    uint256 excess = SafeMath.sub(msg.value, seatPrice);
    nines[1].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[2].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[3].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[4].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[5].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[6].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[7].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[8].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[9].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100,SafeMath.div(200,17)))));
    nines[10] = nines[9]; nines[9] = nines[8]; nines[8] = nines[7]; nines[7] = nines[6];
    nines[6] = nines[5]; nines[5] = nines[4]; nines[4] = nines[3];
    nines[3] = nines[2]; nines[2] = nines[1];
    nines[1] = Nine(msg.sender, seatPrice);
    ceoAddress.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), 15)));
    NewOne(msg.sender, seatPrice, SafeMath.mul(SafeMath.div(seatPrice, 100), 115));
    seatPrice = SafeMath.mul(SafeMath.div(seatPrice, 100), 115);
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