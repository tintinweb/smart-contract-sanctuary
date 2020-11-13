pragma solidity >=0.4.21 <=0.7.0;

contract election2020 {
  address payable public owner;
  uint256 constant public feePerc = 5;
  mapping (address => uint256) public betsBiden;
  uint256 public betsBidenTotal;
  mapping (address => uint256) public betsTrump;
  uint256 public betsTrumpTotal;
  uint256 public fees;
  uint8 public electionResult; // 0 - election not completed, 1 - Biden won, 2 - Trump won
  string public dappURL;
  uint256 public electionDay = 1604379600; // 11/3/2020 12:00:00 AM EST

  constructor() {
    owner = tx.origin;
    //electionResult = 0;
    //betsBidenTotal = 0;
    //betsTrumpTotal = 0;
    //fees = 0;
  }

  /**
   * Make sure cannot receive ETH any other way.
   */
  fallback() external payable {
    revert("Not accepting payments any other way.");
  }

  /**
   * Change election day, in case it is changed officially.
   */
  function setElectionDay(uint256 _electionDay) external {
    require(tx.origin == owner && 0 == electionResult);
    electionDay = _electionDay;
  }

  function betOnBiden() external payable {
    require(block.timestamp < electionDay, "Too late - election has started!");
    uint256 fee = (msg.value * feePerc) / 100;
    fees += fee;
    betsBidenTotal += msg.value - fee;
    betsBiden[tx.origin] = betsBiden[tx.origin] + msg.value - fee;
  }

  function betOnTrump() external payable {
    require(block.timestamp < electionDay, "Too late - election has started!");
    uint256 fee = (msg.value * feePerc) / 100;
    fees += fee;
    betsTrumpTotal += msg.value - fee;
    betsTrump[tx.origin] = betsTrump[tx.origin] + msg.value - fee;
  }

  /**
   * Enter results after election completes / oracle function.
   */
  function setElectionResult(uint8 _electionResult) external {
    require(tx.origin == owner && 0 == electionResult);
    electionResult = _electionResult;
  }

  /**
   * Owner withdrawal of fees.
   */
  function withdrawFees() external {
    require(tx.origin == owner && electionResult != 0, "Election not complete!");
    owner.transfer(fees);
    fees = 0;
  }

  /**
   * Better withdrawal of fees.
   */
  function withdrawWins() public {
    require(electionResult != 0, "Election not complete!");
    uint256 win;
    if (1 == electionResult) { // Biden won
      win = ((betsBiden[tx.origin] * (100000 * betsTrumpTotal / betsBidenTotal)) / 100000) + betsBiden[tx.origin];
    } else { // Trump won
      win = ((betsTrump[tx.origin] * (100000 * betsBidenTotal / betsTrumpTotal)) / 100000) + betsTrump[tx.origin];
    }
    betsBiden[tx.origin] = 0;
    betsTrump[tx.origin] = 0;
    tx.origin.transfer(win);
  }

  /**
   * Receive ETH to withdraw your wins.
   */
  receive() external payable {
    require(msg.value == 0, "Must send 0 to retrieve your wins.");
    withdrawWins();
  }

  function setDAppURL(string memory _dappURL) external {
    require(tx.origin == owner);
    dappURL = _dappURL;
  }

  function getMyBets() external view returns (uint256 myBetsTrump, uint256 myBetsBiden) {
    myBetsTrump = betsTrump[tx.origin];
    myBetsBiden = betsBiden[tx.origin];
  }

  // ERC-20 Methods
  function name() public pure returns (string memory) { return "EL20 - Bet on US Presidential Election 2020"; }
  function symbol() public pure returns (string memory) { return "EL20"; }
  function decimals() public pure returns (uint8) { return 18; }
  function totalSupply() public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool success) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool success) { return false; }
  function approve(address, uint256) public pure returns (bool success) { return false; }
  function allowance(address, address) public pure returns (uint256 remaining) { return 0; }

  function balanceOf(address _owner) public view returns (uint256) {
    return betsTrump[_owner] + betsBiden[_owner];
  }
}


contract betOnTrump {
    election2020 theE2020;

    constructor(address payable _electionContract) {
        theE2020 = election2020(_electionContract);
    }

    /**
    * Make sure cannot receive ETH any other way.
    */
    fallback() external payable {
        revert("Not accepting payments any other way.");
    }

    /**
    * Receive ETH to bet on Trump.
    */
    receive() external payable {
        theE2020.betOnTrump{value: msg.value}();
    }
}