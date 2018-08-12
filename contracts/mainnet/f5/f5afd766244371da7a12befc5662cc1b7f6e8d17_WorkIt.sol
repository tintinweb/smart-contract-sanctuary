pragma solidity ^0.4.0;

contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract WorkIt is ERC20Interface {

  // non-fixed supply ERC20 implementation
  string public constant name = "WorkIt Token";
  string public constant symbol = "WIT";
  uint _totalSupply = 0;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowances;

  function totalSupply() public constant returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowances[tokenOwner][spender];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    require(balances[msg.sender] >= tokens);
    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    allowances[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    require(allowances[from][msg.sender] >= tokens);
    require(balances[from] >= tokens);
    allowances[from][msg.sender] = allowances[from][msg.sender] - tokens;
    balances[from] = balances[from] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(from, to, tokens);
    return true;
  }

  // End ERC-20 implementation

  struct WeekCommittment {
    uint daysCompleted;
    uint daysCommitted;
    mapping(uint => uint) workoutProofs;
    uint tokensCommitted;
    uint tokensEarned;
    bool tokensPaid;
  }

  struct WeekData {
    bool initialized;
    uint totalPeopleCompleted;
    uint totalPeople;
    uint totalDaysCommitted;
    uint totalDaysCompleted;
    uint totalTokensCompleted;
    uint totalTokens;
  }

  uint public weiPerToken = 1000000000000000; // 1000 WITs per eth
  uint secondsPerDay = 86400;
  uint daysPerWeek = 7;

  mapping(uint => WeekData) public dataPerWeek;
  mapping (address => mapping(uint => WeekCommittment)) public commitments;

  mapping(uint => string) imageHashes;
  uint imageHashCount;

  uint public startDate;
  address public owner;

  constructor() public {
    owner = msg.sender;
    // Round down to the nearest day at 00:00Z (UTC -6)
    startDate = (block.timestamp / secondsPerDay) * secondsPerDay - 60 * 6;
  }

  event Log(string message);

  // Fallback function executed when ethereum is received with no function call
  function () public payable {
    buyTokens(msg.value / weiPerToken);
  }

  // Buy tokens
  function buyTokens(uint tokens) public payable {
    require(msg.value >= tokens * weiPerToken);
    balances[msg.sender] += tokens;
    _totalSupply += tokens;
  }

  // Commit to exercising this week
  function commitToWeek(uint tokens, uint _days) public {
    // Need at least 10 tokens to participate
    if (balances[msg.sender] < tokens || tokens < 10) {
      emit Log("You need to bet at least 10 tokens to commit");
      require(false);
    }
    if (_days == 0) {
      emit Log("You cannot register for 0 days of activity");
      require(false);
    }
    if (_days > daysPerWeek) {
      emit Log("You cannot register for more than 7 days per week");
      require(false);
    }
    if (_days > daysPerWeek - currentDayOfWeek()) {
      emit Log("It is too late in the week for you to register");
      require(false);
    }

    WeekCommittment storage commitment = commitments[msg.sender][currentWeek()];

    if (commitment.tokensCommitted != 0) {
      emit Log("You have already committed to this week");
      require(false);
    }
    balances[0x0] = balances[0x0] + tokens;
    balances[msg.sender] = balances[msg.sender] - tokens;
    emit Transfer(msg.sender, 0x0, tokens);

    initializeWeekData(currentWeek());
    WeekData storage data = dataPerWeek[currentWeek()];
    data.totalPeople++;
    data.totalTokens += tokens;
    data.totalDaysCommitted += _days;

    commitment.daysCommitted = _days;
    commitment.daysCompleted = 0;
    commitment.tokensCommitted = tokens;
    commitment.tokensEarned = 0;
    commitment.tokensPaid = false;
  }

  // Payout your available balance based on your activity in previous weeks
  function payout() public {
    require(currentWeek() > 0);
    for (uint activeWeek = currentWeek() - 1; true; activeWeek--) {
      WeekCommittment storage committment = commitments[msg.sender][activeWeek];
      if (committment.tokensPaid) {
        break;
      }
      if (committment.daysCommitted == 0) {
        committment.tokensPaid = true;
        // Handle edge case and avoid -1
        if (activeWeek == 0) break;
        continue;
      }
      initializeWeekData(activeWeek);
      WeekData storage week = dataPerWeek[activeWeek];
      uint tokensFromPool = 0;
      uint tokens = committment.tokensCommitted * committment.daysCompleted / committment.daysCommitted;
      if (week.totalPeopleCompleted == 0) {
        tokensFromPool = (week.totalTokens - week.totalTokensCompleted) / week.totalPeople;
        tokens = 0;
      } else if (committment.daysCompleted == committment.daysCommitted) {
        tokensFromPool = (week.totalTokens - week.totalTokensCompleted) / week.totalPeopleCompleted;
      }
      uint totalTokens = tokensFromPool + tokens;
      if (totalTokens == 0) {
        committment.tokensPaid = true;
        // Handle edge case and avoid -1
        if (activeWeek == 0) break;
        continue;
      }
      balances[0x0] = balances[0x0] - totalTokens;
      balances[msg.sender] = balances[msg.sender] + totalTokens;
      emit Transfer(0x0, msg.sender, totalTokens);
      committment.tokensEarned = totalTokens;
      committment.tokensPaid = true;

      // Handle edge case and avoid -1
      if (activeWeek == 0) break;
    }
  }

  // Post image data to the blockchain and log completion
  // TODO: If not committed for this week use last weeks tokens and days (if it exists)
  function postProof(string proofHash) public {
    WeekCommittment storage committment = commitments[msg.sender][currentWeek()];
    if (committment.daysCompleted > currentDayOfWeek()) {
      emit Log("You have already uploaded proof for today");
      require(false);
    }
    if (committment.tokensCommitted == 0) {
      emit Log("You have not committed to this week yet");
      require(false);
    }
    if (committment.workoutProofs[currentDayOfWeek()] != 0) {
      emit Log("Proof has already been stored for this day");
      require(false);
    }
    if (committment.daysCompleted >= committment.daysCommitted) {
      // Don&#39;t allow us to go over our committed days
      return;
    }
    committment.workoutProofs[currentDayOfWeek()] = storeImageString(proofHash);
    committment.daysCompleted++;

    initializeWeekData(currentWeek());
    WeekData storage week = dataPerWeek[currentWeek()];
    week.totalDaysCompleted++;
    week.totalTokensCompleted = week.totalTokens * week.totalDaysCompleted / week.totalDaysCommitted;
    if (committment.daysCompleted >= committment.daysCommitted) {
      week.totalPeopleCompleted++;
    }
  }

  // Withdraw tokens to eth
  function withdraw(uint tokens) public returns (bool success) {
    require(balances[msg.sender] >= tokens);
    uint weiToSend = tokens * weiPerToken;
    require(address(this).balance >= weiToSend);
    balances[msg.sender] = balances[msg.sender] - tokens;
    _totalSupply -= tokens;
    return msg.sender.send(tokens * weiPerToken);
  }

  // Store an image string and get back a numerical identifier
  function storeImageString(string hash) public returns (uint index) {
    imageHashes[++imageHashCount] = hash;
    return imageHashCount;
  }

  // Initialize a week data struct
  function initializeWeekData(uint _week) public {
    if (dataPerWeek[_week].initialized) return;
    WeekData storage week = dataPerWeek[_week];
    week.initialized = true;
    week.totalTokensCompleted = 0;
    week.totalPeopleCompleted = 0;
    week.totalTokens = 0;
    week.totalPeople = 0;
    week.totalDaysCommitted = 0;
    week.totalDaysCompleted = 0;
  }

  // Get the current day (from contract creation)
  function currentDay() public view returns (uint day) {
    return (block.timestamp - startDate) / secondsPerDay;
  }

  // Get the current week (from contract creation)
  function currentWeek() public view returns (uint week) {
    return currentDay() / daysPerWeek;
  }

  // Get current relative day of week (0-6)
  function currentDayOfWeek() public view returns (uint dayIndex) {
    // Uses the floor to calculate offset
    return currentDay() - (currentWeek() * daysPerWeek);
  }
}