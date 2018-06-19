pragma solidity ^0.4.19;

contract Club {
  struct Member {
    bytes20 username;
    uint64 karma; 
    uint16 canWithdrawPeriod;
    uint16 birthPeriod;
  }

  // Manage members.
  mapping(address => Member) public members;
}

// Last person to press the button before time runs out, wins the pot.
// Button presses cost $.50
// You must pay .5% of the total pot to press the button the first time. (this amount is donated to the reddithereum community).
// After the first button press, a 6 hour countdown will begin, and you won&#39;t be able to press the button for 12 hours.
// Each time you press the button, the countdown will decrease by 10%, and cooldown will increase by 10%.
// The pot starts at $100.
contract Button {
  event Pressed(address indexed presser, uint256 endBlock);
  event Winner(address winner, uint256 winnings);

  uint64 public countdown;
  uint64 public countdownDecrement;
  uint64 public cooloffIncrement;

  uint64 public pressFee;
  uint64 public signupFee; // basis points * contract value
  Club public club; // collects signup, bypasses signup.

  address public lastPresser;
  uint64 public endBlock;

  struct Presser {
    uint64 numPresses;
    uint64 cooloffEnd;
  }

  mapping (address => Presser) public pressers;

  function Button(
    uint64 _countdown, 
    uint64 _countdownDecrement, 
    uint64 _cooloffIncrement, 
    uint64 _pressFee, 
    uint64 _signupFee, 
    address _club
  ) public payable {
    countdown = _countdown;
    countdownDecrement = _countdownDecrement;
    cooloffIncrement = _cooloffIncrement;
    pressFee = _pressFee;
    signupFee = _signupFee;
    club = Club(_club);

    lastPresser = msg.sender;
    endBlock = uint64(block.number + countdown);
  }

  function press() public payable {
    require(block.number <= endBlock);

    uint256 change = msg.value-pressFee;
    Presser storage p = pressers[msg.sender];
    require(p.cooloffEnd < block.number);

    if (p.numPresses == 0) {
      // balance - value will never be negative.
      uint128 npf = _newPresserFee(address(this).balance - msg.value);
      change -= npf;
      address(club).transfer(npf);
    }
    // Breaks when pressFee+presserFee > 2^256
    require(change <= msg.value);

    lastPresser = msg.sender;
    uint64 finalCountdown = countdown - (p.numPresses*countdownDecrement);
    if (finalCountdown < 10 || finalCountdown > countdown) {
      finalCountdown = 10;
    }
    endBlock = uint64(block.number + finalCountdown);

    p.numPresses++;
    p.cooloffEnd = uint64(block.number + (p.numPresses*cooloffIncrement));

    if (change > 0) {
      msg.sender.transfer(change);
    }

    Pressed(msg.sender, endBlock);
  }

  function close() public {
    require(block.number > endBlock);
    require(lastPresser == msg.sender);
    Winner(msg.sender, address(this).balance);
    selfdestruct(msg.sender);
  }

  // Breaks when balance = 10^20 ether.
  function newPresserFee() public view returns (uint128) {
    return _newPresserFee(address(this).balance);
  }

  function isMember() public view returns (bool) {
    return _isMember();
  }

  // Caller must assure that _balance < max_uint128.
  function _newPresserFee(uint256 _balance) private view returns (uint128) {
    if (_isMember()){
      return 0;
    }
    return uint128((_balance * signupFee) / 10000);
  }

  function _isMember() private view returns (bool) {
    var(un, k, cwp, bp) = club.members(msg.sender);
    // members have non-zero birthPeriods
    return bp != 0;
  }

  // Up the stakes...
  function() payable public {}
}