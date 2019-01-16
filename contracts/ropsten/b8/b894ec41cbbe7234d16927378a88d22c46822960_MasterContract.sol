pragma solidity ^0.4.21;

contract BetToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _tokenOwner) public constant returns (uint256 balance);
    function allowance(address _tokenOwner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract MasterContract {
  event ChallengeCreated(
    address indexed msgSender,
    address indexed challengeContract,
    uint indexed challengeId,
    string gameType,
    uint stake
  );

  address public house;
  address public tokenAddress;
  uint[] public validStakes = [500, 1000, 5000];

  modifier onlyHouse() {
    require(
      msg.sender == house
    );
    _;
  }

  modifier checkValidStake(uint _stake) {
    bool result;

    for (uint i=0; i < validStakes.length; i++) {
      if (validStakes[i] == _stake) {
        result = true;
        break;
      }
    }
    require(result);
    _;
  }

  modifier checkUsersTokenBalance(uint _amountToTransfer) {
    require(
      _amountToTransfer <= BetToken(tokenAddress).balanceOf(msg.sender)
    );
    _;
  }

  modifier checkUsersAllowance(uint _amountToTransfer) {
    require(
      _amountToTransfer <= BetToken(tokenAddress).allowance(msg.sender, address(this))
    );
    _;
  }

  function MasterContract(address _tokenAddress) public {
    house = msg.sender;
    tokenAddress = _tokenAddress;
  }

  function createChallenge(uint _stake, string _gameType, uint _challengeId)
    public
    checkValidStake(_stake)
    checkUsersTokenBalance(_stake)
    checkUsersAllowance(_stake)
    {
    // We transfer users tokens to our master contract, wait for user to approve  transaction first.
    require(BetToken(tokenAddress).transferFrom(msg.sender, address(this), _stake));

    address contractAddress = new ChallengeContract(_stake, _gameType, _challengeId, house, tokenAddress);

    // We transfer users tokens from master contract to subcontract
    require(BetToken(tokenAddress).transfer(contractAddress, _stake));

    emit ChallengeCreated(
      msg.sender,
      contractAddress,
      _challengeId,
      _gameType,
      _stake
    );
  }

  function withdrawFunds() public onlyHouse {
    house.transfer(address(this).balance);
    BetToken(tokenAddress).transfer(house, BetToken(tokenAddress).balanceOf(address(this)));
  }

  function () payable public {}
}

contract ChallengeContract {
  event Created(
    address indexed bookie,
    uint indexed amountTransfered,
    uint indexed stake
  );

  event Joined(
    address indexed punter,
    bool indexed isValid
  );

  event Resolved(
    address indexed winner,
    uint indexed commission,
    uint indexed wonAmount
  );

  event WithdrawnAll(
    uint indexed leftToClaim,
    uint indexed withdrawnAmountHouse,
    uint indexed withdrawnAmountWinner
  );

  event HouseAlwaysWins(
    address indexed withdrawer,
    uint indexed amount,
    uint indexed amountLeft
  );

  address public house;
  address public bookie;
  address public punter;
  address public winner;
  address public tokenAddress;
  bool public finished;
  uint public stake;
  uint public challengeId;
  string public gameType;
  string[] validGameTypes = [&#39;fortnite&#39;, &#39;fifa_18&#39;];
  mapping(address => uint) public fundsPaidIn;
  mapping(address => uint) rewards;

  function ChallengeContract(uint _stake, string _gameType, uint _challengeId, address _house, address _tokenAddress)
    onlyValidGameType(_gameType)
    public
  {
    bookie = tx.origin;
    house = _house;
    tokenAddress = _tokenAddress;
    fundsPaidIn[bookie] = _stake;
    gameType = _gameType;
    stake = _stake;
    challengeId = _challengeId;

    emit Created(bookie, _stake, _stake);
  }

  modifier onlyHouse {
    require(
      msg.sender == house
    );
    _;
  }

  modifier onlyValidGameType(string _gameType) {
    bool result;

    for (uint i=0; i < validGameTypes.length; i++) {
      if (keccak256(validGameTypes[i]) == keccak256(_gameType)) {
        result = true;
        break;
      }
    }

    require(
      result
    );
    _;
  }

  modifier checkUsersTokenBalance(uint _amountToTransfer) {
    require(
      _amountToTransfer <= BetToken(tokenAddress).balanceOf(msg.sender)
    );
    _;
  }

  modifier canJoinChallenge(uint _punterPaidInAmount) {
    require(
      address(0) == punter && stake == _punterPaidInAmount && msg.sender != bookie && msg.sender != house
    );
    _;
  }

  modifier canSetWinner(address _winner) {
    require(winner == address(0));
    require(
      punter != address(0) && (_winner == bookie || _winner == punter)
    );
    _;
  }

  modifier canWithdrawFunds {
    require(winner != address(0));
    require(msg.sender == address(house));
    _;
  }

  function joinChallenge(uint _punterPaidInAmount)
    public
    canJoinChallenge(_punterPaidInAmount)
    checkUsersTokenBalance(_punterPaidInAmount)
  {
    require(BetToken(tokenAddress).transferFrom(msg.sender, address(this), _punterPaidInAmount));
    punter = msg.sender;
    fundsPaidIn[punter] = BetToken(tokenAddress).balanceOf(address(this)) - fundsPaidIn[bookie];

    emit Joined(
      punter,
      isValid()
    );
  }

  function setWinner(address _winner) public onlyHouse canSetWinner(_winner) {
    winner = _winner;
    uint totalFunds = fundsPaidIn[bookie] + fundsPaidIn[punter];
    uint commission = calculateCommission(totalFunds);
    uint wonAmount = totalFunds - commission;

    rewards[_winner] = wonAmount;
    rewards[house] = commission;

    emit Resolved(
      _winner,
      commission,
      wonAmount
    );
  }

  function setWinnerAndWithdrawAllFunds(address _winner) onlyHouse public {
    setWinner(_winner);
    withdrawAllFunds();
  }

  function houseAlwaysWins() onlyHouse public {
    uint amountToTransfer = fundsPaidIn[punter] + fundsPaidIn[bookie];

    BetToken(tokenAddress).transfer(house, amountToTransfer);

    emit HouseAlwaysWins(
      msg.sender,
      amountToTransfer,
      BetToken(tokenAddress).balanceOf(address(this))
    );
  }

  function withdrawAllFunds() canWithdrawFunds onlyHouse public {
    uint wonAmount = rewards[winner];
    uint commission = rewards[house];

    rewards[winner] = 0;
    rewards[house] = 0;
    BetToken(tokenAddress).transfer(winner, wonAmount);
    BetToken(tokenAddress).transfer(house, commission);

    finished = true;

    emit WithdrawnAll(
      BetToken(tokenAddress).balanceOf(address(this)),
      commission,
      wonAmount
    );
  }

  function isValid() public constant returns (bool) {
    require(address(0) != punter && fundsPaidIn[punter] == stake && fundsPaidIn[bookie] == stake);
    return (fundsPaidIn[bookie] != 0 && fundsPaidIn[punter] != 0);
  }

  function calculateCommission(uint _total) private pure returns (uint) {
    return (_total / 100) * 5;
  }

  function withdrawFunds() public onlyHouse {
    house.transfer(address(this).balance);
    BetToken(tokenAddress).transfer(house, BetToken(tokenAddress).balanceOf(address(this)));
  }

  function () payable public {}
}