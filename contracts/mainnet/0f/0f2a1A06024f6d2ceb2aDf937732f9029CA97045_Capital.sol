//StrongCapital v1.2.2



pragma solidity ^0.4.24;


contract Capital {
  uint constant public CASH_BACK_PERCENT = 3;
  uint constant public PROJECT_FEE_PERCENT = 20;
  uint constant public PER_BLOCK = 48;
  uint constant public MINIMUM_INVEST = 10000000000000000 wei;
  uint public wave;
  
  address public owner;
  address public admin;
  address[] public addresses;

  bool public pause;

  mapping(address => Investor) public investors;
  TheStrongest public boss;
  
  modifier onlyOwner {
    require(owner == msg.sender);
    _;
  }

  struct Investor {
    uint ID;
    uint deposit;
    uint depositCount;
    uint blockNumber;
    address referrer;
  }

  struct TheStrongest {
    address addr;
    uint deposit;
  }

  constructor () public {
    owner = msg.sender;
    admin = msg.sender;
    addresses.length = 1;
    wave = 1;
  }

  function() payable public {
    if(owner == msg.sender){
      return;
    }

    require(pause == false);
    require(msg.value == 0 || msg.value >= MINIMUM_INVEST);

    Investor storage user = investors[msg.sender];
    
    if(user.ID == 0){
      msg.sender.transfer(0 wei);
      user.ID = addresses.push(msg.sender);

      address referrer = bytesToAddress(msg.data);
      if (investors[referrer].deposit > 0 && referrer != msg.sender) {
        user.referrer = referrer;
      }
    }

    if(user.deposit != 0) {
      uint amount = getInvestorDividendsAmount(msg.sender);
      if(address(this).balance < amount){
        pause = true;
        return;
      }

      msg.sender.transfer(amount);
    }

    admin.transfer(msg.value * PROJECT_FEE_PERCENT / 100);

    user.deposit += msg.value;
    user.depositCount += 1;
    user.blockNumber = block.number;

    uint bonusAmount = msg.value * CASH_BACK_PERCENT / 100;

    if (user.referrer != 0x0) {
      user.referrer.transfer(bonusAmount);
      if (user.depositCount == 1) {
        msg.sender.transfer(bonusAmount);
      }
    } else if (boss.addr > 0x0) {
      if(msg.sender != boss.addr){
        if(user.deposit < boss.deposit){
          boss.addr.transfer(bonusAmount);
        }
      }
    }

    if(user.deposit > boss.deposit) {
      boss = TheStrongest(msg.sender, user.deposit);
    }
  }

  function getInvestorCount() public view returns (uint) {
    return addresses.length - 1;
  }

  function getInvestorDividendsAmount(address addr) public view returns (uint) {
    uint amount = ((investors[addr].deposit * ((block.number - investors[addr].blockNumber) * PER_BLOCK)) / 10000000);
    return amount;
  }

  function Restart() private {
    address addr;

    for (uint256 i = addresses.length - 1; i > 0; i--) {
      addr = addresses[i];
      addresses.length -= 1;
      delete investors[addr];
    }

    pause = false;
    wave += 1;

    delete boss;
  }

  function payout() public {
    if (pause) {
      Restart();
      return;
    }

    uint amount;

    for(uint256 i = addresses.length - 1; i >= 1; i--){
      address addr = addresses[i];

      amount = getInvestorDividendsAmount(addr);
      investors[addr].blockNumber = block.number;

      if (address(this).balance < amount) {
        pause = true;
        return;
      }

      addr.transfer(amount);
    }
  }
  
  function transferOwnership(address addr) onlyOwner public {
    owner = addr;
  }

  function bytesToAddress(bytes bys) private pure returns (address addr) {
    assembly {
      addr := mload(add(bys, 20))
    }
  }
}