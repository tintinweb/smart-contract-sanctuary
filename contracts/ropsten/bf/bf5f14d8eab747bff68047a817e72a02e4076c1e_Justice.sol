pragma solidity 0.4.25;

contract Justice {

  using SafeMath for uint;

  /// Variables
  address public admin; // the admin address
  uint256 public feePerK; // percentage times (1 ether)
  uint256 public endTime; // time betting ends
  uint256 public limitTime; //
  uint256 private iterA;
  uint256 private iterB;
  
  mapping (address => uint256) public agreeMap; // bets on agree mapped by sent address
  mapping (address => uint256) public disagreeMap; // bets on disagree mapped by sent address
  address[] agreeList; // lists to iterate payments over
  address[] disagreeList;
  uint256 public totalAgree;
  uint256 public totalDisagree;
  string public statement;

  /// Logging Events
  event Deposit(bool agree);
  event Withdraw(bool agree, uint value);
  event Result(string msg);
  
  /// This is a modifier for functions to check if the sending user address is the same as the admin user address.
  modifier isAdmin() {
      require(msg.sender == admin);
      _;
  }

  /// Constructor 
  constructor (string statement_, uint256 endTime_,  uint256 limitTime_) public {
    admin = msg.sender;
    statement = statement_;
    endTime = endTime_;
    limitTime = limitTime_;
    feePerK = 8;
    iterA = 0;
    iterB = 0;
  }


  ////////////////////////////////////////////////////////////////////////////////
  // Deposits, Withdrawals, Balances
  ////////////////////////////////////////////////////////////////////////////////
  
  
  // this is agree() but is using fallback mechanism 

  function() public payable {
    require(block.timestamp < endTime && agreeMap[msg.sender].add(msg.value) > 0.005 ether);
    if (agreeMap[msg.sender] == 0) { agreeList.push(msg.sender); }
    agreeMap[msg.sender] = agreeMap[msg.sender].add(msg.value);
    totalAgree =totalAgree.add(msg.value);
    emit Deposit(true);
  }

  function agreeWithdraw(uint amount) public {
    require(agreeMap[msg.sender] >= amount && block.timestamp < endTime);
    agreeMap[msg.sender] = agreeMap[msg.sender].sub(amount);
    totalAgree = totalAgree.sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(true, amount);
  }

  function disagree() public payable {
    require(block.timestamp < endTime && disagreeMap[tx.origin].add(msg.value) > 0.005 ether);
    if (disagreeMap[tx.origin] == 0) { disagreeList.push(tx.origin); }
    disagreeMap[tx.origin] = disagreeMap[tx.origin].add(msg.value);
    totalDisagree =totalDisagree.add(msg.value);
    emit Deposit(false);
  }

  function disagreeWithdraw(uint amount) public {
    require(disagreeMap[msg.sender] >= amount && block.timestamp < endTime);
    disagreeMap[msg.sender] = disagreeMap[msg.sender].sub(amount);
    totalDisagree = totalDisagree.sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(false, amount);
  }
  
  // Fallback in case admin is absent long after event. 
  // Allows players to Withdraw funds indefinately
  function lockBreak() public {
    require( limitTime < block.timestamp );
    endTime = 3000000000;
  }
  
  // In case fair conditions are disrupted
  function endBetting() public isAdmin {
    endTime = block.timestamp.sub(900);
    emit Result("early");
  }
  
  function resultDraw() public isAdmin {
    require( endTime < block.timestamp);

    if(iterA != agreeList.length)
    multiSendA(1000 - feePerK, 1000);
    else {
        if(iterB != disagreeList.length)
        multiSendB(1000 - feePerK, 1000);
        if(iterB == disagreeList.length) {
            admin.transfer(address(this).balance);
            emit Result("draw");
        }
    }
  }
  
  function resultAccept() public isAdmin {
    require( endTime < block.timestamp);
    multiSendA((totalDisagree+totalAgree).mul(1000 - feePerK), totalAgree.mul(1000));
    if(iterA == agreeList.length) {
        admin.transfer(address(this).balance);
        emit Result("agree");
    }
  }
  
  function resultReject() public isAdmin {
    require( endTime < block.timestamp);
    multiSendB((totalDisagree+totalAgree).mul(1000 - feePerK), totalDisagree.mul(1000));
    if(iterB == disagreeList.length) {
        admin.transfer(address(this).balance);
        emit Result("disagree");
    }
  }
  
  function multiSendA( uint256 numer, uint256 denom ) internal isAdmin {
    for (uint initi = iterA; iterA < initi + 150 && iterA < agreeList.length; iterA++) {
        agreeList[iterA].send(agreeMap[agreeList[iterA]].mul(numer).div(denom));
    }
  }
  
  function multiSendB( uint256 numer, uint256 denom ) internal isAdmin {
    for (uint initi = iterB; iterB < initi + 150 && iterB < disagreeList.length; iterB++) {
        disagreeList[iterB].send(disagreeMap[agreeList[iterB]].mul(numer).div(denom));
    }
  }

 }

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

}