// Presale interface

pragma solidity ^0.4.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Presale {
  using SafeMath for uint256;

  mapping (address => uint256) public balances;

  // Minimum amount of wei required for presale to be successful.  If not successful, refunds are provided.
  uint256 public minGoal;
  // Maximum amount of wei for presale to raise.
  uint256 public maxGoal;
  // The epoch unix timestamp of when the presale starts
  uint256 public startTime;
  // The epoch unix timestamp of when the presale ends
  uint256 public endTime;
  // The wallet address that the funds will be sent to
  address public projectWallet;

  uint256 private totalRaised;

  function Presale(
    uint256 _minGoal,
    uint256 _maxGoal,
    uint256 _startTime,
    uint256 _endTime,
    address _projectWallet
  )
  {
    require(_minGoal > 0);
    require(_endTime > _startTime);
    require(_projectWallet != address(0x0));
    require(_maxGoal > _minGoal);

    minGoal = _minGoal;
    maxGoal = _maxGoal;
    startTime = _startTime;
    endTime = _endTime;
    projectWallet = _projectWallet;
  }

  function transferToProjectWallet() {
    // only allow transfers if there is balance
    require(this.balance > 0);
    // only allow transfers if minimum goal is met
    require(totalRaised >= minGoal);
    if(!projectWallet.send(this.balance)) {
      revert();
    }
  }

  function refund() {
    // only allow refund if the presale has ended
    require(now > endTime);
    // only allow refund if the minGoal has not been reached
    require(totalRaised < minGoal);
    // only allow refund during a 60 day window after presale ends
    require(now < (endTime + 60 days));
    uint256 amount = balances[msg.sender];
    // only allow refund if investor has invested
    require(amount > 0);
    // after refunding, zero out balance
    balances[msg.sender] = 0;
    if (!msg.sender.send(amount)) {
      revert();
    }
  }

  function transferRemaining() {
    // only allow transfer if presale has failed
    require(totalRaised < minGoal);
    // only allow transfer after refund window has passed
    require(now >= (endTime + 60 days));
    // only allow transfer if there is remaining balance
    require(this.balance > 0);
    projectWallet.transfer(this.balance);
  }

  function () payable {
    // only allow payments greater than 0
    require(msg.value > 0);
    // only allow payments after presale has started
    require(now >= startTime);
    // only allow payments before presale has ended
    require(now <= endTime);
    // only allow payments if the maxGoal has not been reached
    require(totalRaised < maxGoal);

    // If this investment should cause the max to be achieved
    // Then it should only accept up to the max goal
    // And refund the remaining
    if (totalRaised.add(msg.value) > maxGoal) {
      var refundAmount = totalRaised + msg.value - maxGoal;
      if (!msg.sender.send(refundAmount)) {
        revert();
      }
      var raised = maxGoal - totalRaised;
      balances[msg.sender] = balances[msg.sender].add(raised);
      totalRaised = totalRaised.add(raised);
    } else {
      // if all checks pass, then add amount to balance of the sender
      balances[msg.sender] = balances[msg.sender].add(msg.value);
      totalRaised = totalRaised.add(msg.value);
    }
  }
}

contract OpenMoneyPresale is Presale {
  function OpenMoneyPresale() Presale(83.33 ether,
                                      2000 ether,
                                      1505649600,
                                      1505995200,
                                      address(0x2a00BFd8379786ADfEbb6f2F59011535a4f8d4E4))
                                      {}

}