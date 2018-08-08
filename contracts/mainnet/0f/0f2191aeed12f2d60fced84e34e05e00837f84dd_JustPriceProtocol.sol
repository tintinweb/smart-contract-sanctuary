/*
 * Just Price Protocol Smart Contract.
 * Copyright &#169; 2018 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<span class="__cf_email__" data-cfemail="d3bebab8bbb2babffda5bfb2b7babebaa1bca593b4beb2babffdb0bcbe">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.20;

//import "./SafeMath.sol";
//import "./OrgonToken.sol";
//import "./OrisSpace.sol";
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Add two uint256 values, throw in case of overflow.
   *
   * @param x first value to add
   * @param y second value to add
   * @return x + y
   */
  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

  /**
   * Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param x value to subtract from
   * @param y value to subtract
   * @return x - y
   */
  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

  /**
   * Multiply two uint256 values, throw in case of overflow.
   *
   * @param x first value to multiply
   * @param y second value to multiply
   * @return x * y
   */
  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}

contract Token {
  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public view returns (uint256 supply);

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public view returns (uint256 balance);

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public returns (bool success);

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public returns (bool success);

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

  /**
   * Logged when tokens were transferred from one owner to another.
   *
   * @param _from address of the owner, tokens were transferred from
   * @param _to address of the owner, tokens were transferred to
   * @param _value number of tokens transferred
   */
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  /**
   * Logged when owner approved his tokens to be transferred by some spender.
   *
   * @param _owner owner who approved his tokens to be transferred
   * @param _spender spender who were allowed to transfer the tokens belonging
   *        to the owner
   * @param _value number of tokens belonging to the owner, approved to be
   *        transferred by the spender
   */
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

contract OrisSpace {
  /**
   * Start Oris Space smart contract.
   *
   * @param _returnAmount amount of tokens to return to message sender.
   */
  function start (uint256 _returnAmount) public;
}

contract OrgonToken is Token {
  /**
   * Create _value new tokens and give new created tokens to msg.sender.
   * May only be called by smart contract owner.
   *
   * @param _value number of tokens to create
   * @return true if tokens were created successfully, false otherwise
   */
  function createTokens (uint256 _value) public returns (bool);

  /**
   * Burn given number of tokens belonging to message sender.
   * May only be called by smart contract owner.
   *
   * @param _value number of tokens to burn
   * @return true on success, false on error
   */
  function burnTokens (uint256 _value) public returns (bool);
}

/**
 * Just Price Protocol Smart Contract that serves as market maker for Orgon
 * tokens.
 */
contract JustPriceProtocol is SafeMath {
  /**
   * 2^128.
   */
  uint256 internal constant TWO_128 = 0x100000000000000000000000000000000;

  /**
   * Sale start time (2018-04-19 06:00:00 UTC)
   */
  uint256 internal constant SALE_START_TIME = 1524117600;

  /**
   * "Reserve" stage deadline (2018-07-08 00:00:00 UTC)
   */
  uint256 internal constant RESERVE_DEADLINE = 1531008000;

  /**
   * Maximum amount to be collected during "reserve" stage.
   */
  uint256 internal constant RESERVE_MAX_AMOUNT = 72500 ether;

  /**
   * Minimum amount to be collected during "reserve" stage.
   */
  uint256 internal constant RESERVE_MIN_AMOUNT = 30000 ether;

  /**
   * Maximum number of tokens to be sold during "reserve" stage.
   */
  uint256 internal constant RESERVE_MAX_TOKENS = 82881476.72e9;

  /**
   * ORNG/ETH ratio after "reserve" stage in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_RATIO = 72500 ether / 725000000e9;

  /**
   * Maximum amount of ETH to collect at price 1.
   */
  uint256 internal constant RESERVE_THRESHOLD_1 = 10000 ether;

  /**
   * Price 1 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_1 = 0.00080 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 2.
   */
  uint256 internal constant RESERVE_THRESHOLD_2 = 20000 ether;

  /**
   * Price 2 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_2 = 0.00082 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 3.
   */
  uint256 internal constant RESERVE_THRESHOLD_3 = 30000 ether;

  /**
   * Price 3 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_3 = 0.00085 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 4.
   */
  uint256 internal constant RESERVE_THRESHOLD_4 = 40000 ether;

  /**
   * Price 4 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_4 = 0.00088 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 5.
   */
  uint256 internal constant RESERVE_THRESHOLD_5 = 50000 ether;

  /**
   * Price 5 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_5 = 0.00090 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 6.
   */
  uint256 internal constant RESERVE_THRESHOLD_6 = 60000 ether;

  /**
   * Price 6 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_6 = 0.00092 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 7.
   */
  uint256 internal constant RESERVE_THRESHOLD_7 = 70000 ether;

  /**
   * Price 7 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_7 = 0.00095 ether / 1e9;

  /**
   * Maximum amount of ETH to collect at price 8.
   */
  uint256 internal constant RESERVE_THRESHOLD_8 = 72500 ether;

  /**
   * Price 8 in Wei per ORGN unit.
   */
  uint256 internal constant RESERVE_PRICE_8 = 0.00098 ether / 1e9;

  /**
   * "Growth" stage ends once this many tokens were issued.
   */
  uint256 internal constant GROWTH_MAX_TOKENS = 1000000000e9;

  /**
   * Maximum duration of "growth" stage.
   */
  uint256 internal constant GROWTH_MAX_DURATION = 285 days;

  /**
   * Numerator of fraction of tokens bought at "reserve" stage to be delivered
   * before "growth" stage start.
   */
  uint256 internal constant GROWTH_MIN_DELIVERED_NUMERATOR = 75;

  /**
   * Denominator of fraction of tokens bought at "reserve" stage to be delivered
   * before "growth" stage start.
   */
  uint256 internal constant GROWTH_MIN_DELIVERED_DENOMINATIOR = 100;

  /**
   * Numerator of fraction of total votes to be given to a new K1 address for
   * vote to succeed.
   */
  uint256 internal constant REQUIRED_VOTES_NUMERATIOR = 51;

  /**
   * Denominator of fraction of total votes to be given to a new K1 address for
   * vote to succeed.
   */
  uint256 internal constant REQUIRED_VOTES_DENOMINATOR = 100;

  /**
   * Fee denominator (1 / 20000 = 0.00005).
   */
  uint256 internal constant FEE_DENOMINATOR = 20000;

  /**
   * Delay after start of "growth" stage before fee may be changed.
   */
  uint256 internal constant FEE_CHANGE_DELAY = 650 days;

  /**
   * Minimum fee (1 / 20000 = 0.0005).
   */
  uint256 internal constant MIN_FEE = 1;

  /**
   * Maximum fee (2000 / 20000 = 0.1).
   */
  uint256 internal constant MAX_FEE = 2000;

  /**
   * Deploy Just Price Protocol smart contract with given Orgon Token,
   * Oris Space, and K1 wallet.
   *
   * @param _orgonToken Orgon Token to use
   * @param _orisSpace Oris Space to use
   * @param _k1 address of K1 wallet
   */
  function JustPriceProtocol (
    OrgonToken _orgonToken, OrisSpace _orisSpace, address _k1)
  public {
    orgonToken = _orgonToken;
    orisSpace = _orisSpace;
    k1 = _k1;
  }

  /**
   * When called with no data does the same as buyTokens ().
   */
  function () public payable {
    require (msg.data.length == 0);

    buyTokens ();
  }

  /**
   * Buy tokens.
   */
  function buyTokens () public payable {
    require (msg.value > 0);

    updateStage ();

    if (stage == Stage.RESERVE)
      buyTokensReserve ();
    else if (stage == Stage.GROWTH || stage == Stage.LIFE)
      buyTokensGrowthLife ();
    else revert (); // No buying in current stage
  }

  /**
   * Sell tokens.
   *
   * @param _value number of tokens to sell
   */
  function sellTokens (uint256 _value) public {
    require (_value > 0);
    require (_value < TWO_128);

    updateStage ();
    require (stage == Stage.LIFE);

    assert (reserveAmount < TWO_128);
    uint256 totalSupply = orgonToken.totalSupply ();
    require (totalSupply < TWO_128);

    require (_value <= totalSupply);

    uint256 toPay = safeMul (
      reserveAmount,
      safeSub (
        TWO_128,
        pow_10 (safeSub (TWO_128, (_value << 128) / totalSupply)))) >> 128;

    require (orgonToken.transferFrom (msg.sender, this, _value));
    require (orgonToken.burnTokens (_value));

    reserveAmount = safeSub (reserveAmount, toPay);

    msg.sender.transfer (toPay);
  }

  /**
   * Deliver tokens sold during "reserve" stage to corresponding investors.
   *
   * @param _investors addresses of investors to deliver tokens to
   */
  function deliver (address [] _investors) public {
    updateStage ();
    require (
      stage == Stage.BEFORE_GROWTH ||
      stage == Stage.GROWTH ||
      stage == Stage.LIFE);

    for (uint256 i = 0; i < _investors.length; i++) {
      address investorAddress = _investors [i];
      Investor storage investor = investors [investorAddress];

      uint256 toDeliver = investor.tokensBought;
      investor.tokensBought = 0;
      investor.etherInvested = 0;

      if (toDeliver > 0) {
        require (orgonToken.transfer (investorAddress, toDeliver));
        reserveTokensDelivered = safeAdd (reserveTokensDelivered, toDeliver);

        Delivery (investorAddress, toDeliver);
      }
    }

    if (stage == Stage.BEFORE_GROWTH &&
      safeMul (reserveTokensDelivered, GROWTH_MIN_DELIVERED_DENOMINATIOR) >=
        safeMul (reserveTokensSold, GROWTH_MIN_DELIVERED_NUMERATOR)) {
      stage = Stage.GROWTH;
      growthDeadline = currentTime () + GROWTH_MAX_DURATION;
      feeChangeEnableTime = currentTime () + FEE_CHANGE_DELAY;
    }
  }

  /**
   * Refund investors who bought tokens during "reserve" stage.
   *
   * @param _investors addresses of investors to refund
   */
  function refund (address [] _investors) public {
    updateStage ();
    require (stage == Stage.REFUND);

    for (uint256 i = 0; i < _investors.length; i++) {
      address investorAddress = _investors [i];
      Investor storage investor = investors [investorAddress];

      uint256 toBurn = investor.tokensBought;
      uint256 toRefund = investor.etherInvested;

      investor.tokensBought = 0;
      investor.etherInvested = 0;

      if (toBurn > 0)
        require (orgonToken.burnTokens (toBurn));

      if (toRefund > 0) {
        investorAddress.transfer (toRefund);

        Refund (investorAddress, toRefund);
      }
    }
  }

  function vote (address _newK1) public {
    updateStage ();

    require (stage == Stage.LIFE);
    require (!k1Changed);

    uint256 votesCount = voteNumbers [msg.sender];
    if (votesCount > 0) {
      address oldK1 = votes [msg.sender];
      if (_newK1 != oldK1) {
        if (oldK1 != address (0)) {
          voteResults [oldK1] = safeSub (voteResults [oldK1], votesCount);

          VoteRevocation (msg.sender, oldK1, votesCount);
        }

        votes [msg.sender] = _newK1;

        if (_newK1 != address (0)) {
          voteResults [_newK1] = safeAdd (voteResults [_newK1], votesCount);
          Vote (msg.sender, _newK1, votesCount);

          if (safeMul (voteResults [_newK1], REQUIRED_VOTES_DENOMINATOR) >=
            safeMul (totalVotesNumber, REQUIRED_VOTES_NUMERATIOR)) {
            k1 = _newK1;
            k1Changed = true;

            K1Change (_newK1);
          }
        }
      }
    }
  }

  /**
   * Set new fee numerator.
   *
   * @param _fee new fee numerator.
   */
  function setFee (uint256 _fee) public {
    require (msg.sender == k1);

    require (_fee >= MIN_FEE);
    require (_fee <= MAX_FEE);

    updateStage ();

    require (stage == Stage.GROWTH || stage == Stage.LIFE);
    require (currentTime () >= feeChangeEnableTime);

    require (safeSub (_fee, 1) <= fee);
    require (safeAdd (_fee, 1) >= fee);

    if (fee != _fee) {
      fee = _fee;

      FeeChange (_fee);
    }
  }

  /**
   * Get number of tokens bought by given investor during reserve stage that are
   * not yet delivered to him.
   *
   * @param _investor address of investor to get number of outstanding tokens
   *       for
   * @return number of non-delivered tokens given investor bought during reserve
   *         stage
   */
  function outstandingTokens (address _investor) public view returns (uint256) {
    return investors [_investor].tokensBought;
  }

  /**
   * Get current stage of Just Price Protocol.
   *
   * @param _currentTime current time in seconds since epoch
   * @return current stage of Just Price Protocol
   */
  function getStage (uint256 _currentTime) public view returns (Stage) {
    Stage currentStage = stage;

    if (currentStage == Stage.BEFORE_RESERVE) {
      if (_currentTime >= SALE_START_TIME)
        currentStage = Stage.RESERVE;
      else return currentStage;
    }

    if (currentStage == Stage.RESERVE) {
      if (_currentTime >= RESERVE_DEADLINE) {
        if (reserveAmount >= RESERVE_MIN_AMOUNT)
          currentStage = Stage.BEFORE_GROWTH;
        else currentStage = Stage.REFUND;
      }

      return currentStage;
    }

    if (currentStage == Stage.GROWTH) {
      if (_currentTime >= growthDeadline) {
        currentStage = Stage.LIFE;
      }
    }

    return currentStage;
  }

  /**
   * Return total number of votes eligible for choosing new K1 address.
   *
   * @return total number of votes eligible for choosing new K1 address
   */
  function totalEligibleVotes () public view returns (uint256) {
    return totalVotesNumber;
  }

  /**
   * Return number of votes eligible for choosing new K1 address given investor
   * has.
   *
   * @param _investor address of investor to get number of eligible votes of
   * @return Number of eligible votes given investor has
   */
  function eligibleVotes (address _investor) public view returns (uint256) {
    return voteNumbers [_investor];
  }

  /**
   * Get number of votes for the given new K1 address.
   *
   * @param _newK1 new K1 address to get number of votes for
   * @return number of votes for the given new K1 address
   */
  function votesFor (address _newK1) public view returns (uint256) {
    return voteResults [_newK1];
  }

  /**
   * Buy tokens during "reserve" stage.
   */
  function buyTokensReserve () internal {
    require (stage == Stage.RESERVE);

    uint256 toBuy = 0;
    uint256 toRefund = msg.value;
    uint256 etherInvested = 0;
    uint256 tokens;
    uint256 tokensValue;

    if (reserveAmount < RESERVE_THRESHOLD_1) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_1, reserveAmount)) /
        RESERVE_PRICE_1;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_1);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_2) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_2, reserveAmount)) /
        RESERVE_PRICE_2;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_2);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_3) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_3, reserveAmount)) /
        RESERVE_PRICE_3;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_3);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_4) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_4, reserveAmount)) /
        RESERVE_PRICE_4;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_4);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_5) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_5, reserveAmount)) /
        RESERVE_PRICE_5;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_5);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_6) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_6, reserveAmount)) /
        RESERVE_PRICE_6;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_6);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_7) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_7, reserveAmount)) /
        RESERVE_PRICE_7;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_7);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_8) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_8, reserveAmount)) /
        RESERVE_PRICE_8;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_8);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (toBuy > 0) {
      Investor storage investor = investors [msg.sender];

      investor.tokensBought = safeAdd (
        investor.tokensBought, toBuy);

      investor.etherInvested = safeAdd (
        investor.etherInvested, etherInvested);

      reserveTokensSold = safeAdd (reserveTokensSold, toBuy);

      require (orgonToken.createTokens (toBuy));

      voteNumbers [msg.sender] = safeAdd (voteNumbers [msg.sender], toBuy);
      totalVotesNumber = safeAdd (totalVotesNumber, toBuy);

      Investment (msg.sender, etherInvested, toBuy);

      if (safeSub (RESERVE_THRESHOLD_8, reserveAmount) <
        RESERVE_PRICE_8) {

        orisSpace.start (0);

        stage = Stage.BEFORE_GROWTH;
      }
    }

    if (toRefund > 0)
      msg.sender.transfer (toRefund);
  }

  /**
   * Buy tokens during "growth" or "life" stage.
   */
  function buyTokensGrowthLife () internal {
    require (stage == Stage.GROWTH || stage == Stage.LIFE);

    require (msg.value < TWO_128);

    uint256 totalSupply = orgonToken.totalSupply ();
    assert (totalSupply < TWO_128);

    uint256 toBuy = safeMul (
      totalSupply,
      safeSub (
        root_10 (safeAdd (TWO_128, (msg.value << 128) / reserveAmount)),
        TWO_128)) >> 128;

    reserveAmount = safeAdd (reserveAmount, msg.value);
    require (reserveAmount < TWO_128);

    if (toBuy > 0) {
      require (orgonToken.createTokens (toBuy));
      require (orgonToken.totalSupply () < TWO_128);

      uint256 feeAmount = safeMul (toBuy, fee) / FEE_DENOMINATOR;

      require (orgonToken.transfer (msg.sender, safeSub (toBuy, feeAmount)));

      if (feeAmount > 0)
        require (orgonToken.transfer (k1, feeAmount));

      if (stage == Stage.GROWTH) {
        uint256 votesCount = toBuy;

        totalSupply = orgonToken.totalSupply ();
        if (totalSupply >= GROWTH_MAX_TOKENS) {
          stage = Stage.LIFE;
          votesCount = safeSub (
            votesCount,
            safeSub (totalSupply, GROWTH_MAX_TOKENS));
        }

        voteNumbers [msg.sender] =
          safeAdd (voteNumbers [msg.sender], votesCount);
        totalVotesNumber = safeAdd (totalVotesNumber, votesCount);
      }
    }
  }

  /**
   * Update stage of Just Price Protocol and return updated stage.
   *
   * @return updated stage of Just Price Protocol
   */
  function updateStage () internal returns (Stage) {
    Stage currentStage = getStage (currentTime ());
    if (stage != currentStage) {
      if (currentStage == Stage.BEFORE_GROWTH) {
        // "Reserve" stage deadline reached and minimum amount collected
        uint256 tokensToBurn =
          safeSub (
            safeAdd (
              safeAdd (
                safeSub (RESERVE_MAX_AMOUNT, reserveAmount),
                safeSub (RESERVE_RATIO, 1)) /
                RESERVE_RATIO,
              reserveTokensSold),
            RESERVE_MAX_TOKENS);

        orisSpace.start (tokensToBurn);
        if (tokensToBurn > 0)
          require (orgonToken.burnTokens (tokensToBurn));
      }

      stage = currentStage;
    }
  }

  /**
   * Get minimum of two values.
   *
   * @param x first value
   * @param y second value
   * @return minimum of two values
   */
  function min (uint256 x, uint256 y) internal pure returns (uint256) {
    return x < y ? x : y;
  }

  /**
   * Calculate 2^128 * (x / 2^128)^(1/10).
   *
   * @param x parameter x
   * @return 2^128 * (x / 2^128)^(1/10)
   */
  function root_10 (uint256 x) internal pure returns (uint256 y) {
    uint256 shift = 0;

    while (x > TWO_128) {
      x >>= 10;
      shift += 1;
    }

    if (x == TWO_128 || x == 0) y = x;
    else {
      uint256 x128 = x << 128;
      y = TWO_128;

      uint256 t = x;
      while (true) {
        t <<= 10;
        if (t < TWO_128) y >>= 1;
        else break;
      }

      for (uint256 i = 0; i < 16; i++) {
        uint256 y9;

        if (y == TWO_128) y9 = y;
        else {
          uint256 y2 = (y * y) >> 128;
          uint256 y4 = (y2 * y2) >> 128;
          uint256 y8 = (y4 * y4) >> 128;
          y9 = (y * y8) >> 128;
        }

        y = (9 * y + x128 / y9) / 10;

        assert (y <= TWO_128);
      }
    }

    y <<= shift;
  }

  /**
   * Calculate 2^128 * (x / 2^128)^10.
   *
   * @param x parameter x
   * @return 2^128 * (x / 2^128)^10
   */
  function pow_10 (uint256 x) internal pure returns (uint256) {
    require (x <= TWO_128);

    if (x == TWO_128) return x;
    else {
      uint256 x2 = (x * x) >> 128;
      uint256 x4 = (x2 * x2) >> 128;
      uint256 x8 = (x4 * x4) >> 128;
      return (x2 * x8) >> 128;
    }
  }

  /**
   * Get current time in seconds since epoch.
   *
   * @return current time in seconds since epoch
   */
  function currentTime () internal view returns (uint256) {
    return block.timestamp;
  }

  /**
   * Just Price Protocol stages.
   * +----------------+
   * | BEFORE_RESERVE |
   * +----------------+
   *         |
   *         | Sale start time reached
   *         V
   *    +---------+   Reserve deadline reached
   *    | RESERVE |-------------------------------+
   *    +---------+                               |
   *         |                                    |
   *         | 72500 ETH collected                |
   *         V                                    |
   * +---------------+ 39013,174672 ETH collected |
   * | BEFORE_GROWTH |<---------------------------O
   * +---------------+                            |
   *         |                                    | 39013,174672 ETH not collected
   *         | 80% of tokens delivered            |
   *         V                                    V
   *  +------------+                         +--------+
   *  |   GROWTH   |                         | REFUND |
   *  +------------+                         +--------+
   *         |
   *         | 1,500,000,000 tokens issued or 365 days passed since start of "GROWTH" stage
   *         V
   *     +------+
   *     | LIFE |
   *     +------+
   */
  enum Stage {
    BEFORE_RESERVE, // Before start of "Reserve" stage
    RESERVE, // "Reserve" stage
    BEFORE_GROWTH, // Between "Reserve" and "Growth" stages
    GROWTH, // "Grows" stage
    LIFE, // "Life" stage
    REFUND // "Refund" stage
  }

  /**
   * Orgon Token smart contract.
   */
  OrgonToken internal orgonToken;

  /**
   * Oris Space spart contract.
   */
  OrisSpace internal orisSpace;

  /**
   * Address of K1 smart contract.
   */
  address internal k1;

  /**
   * Last known stage of Just Price Protocol
   */
  Stage internal stage = Stage.BEFORE_RESERVE;

  /**
   * Amount of ether in reserve.
   */
  uint256 internal reserveAmount;

  /**
   * Number of tokens sold during "reserve" stage.
   */
  uint256 internal reserveTokensSold;

  /**
   * Number of tokens sold during "reserve" stage that were already delivered to
   * investors.
   */
  uint256 internal reserveTokensDelivered;

  /**
   * "Growth" stage deadline.
   */
  uint256 internal growthDeadline;

  /**
   * Mapping from address of a person who bought some tokens during "reserve"
   * stage to information about how many tokens he bought to how much ether
   * invested.
   */
  mapping (address => Investor) internal investors;

  /**
   * Mapping from address of an investor to the number of votes this investor
   * has.
   */
  mapping (address => uint256) internal voteNumbers;

  /**
   * Mapping from address of an investor to the new K1 address this investor
   * voted for.
   */
  mapping (address => address) internal votes;

  /**
   * Mapping from suggested new K1 address to the number of votes for this
   * address.
   */
  mapping (address => uint256) internal voteResults;

  /**
   * Total number of eligible votes.
   */
  uint256 internal totalVotesNumber;

  /**
   * Whether K1 address was already changed via voting.
   */
  bool internal k1Changed = false;

  /**
   * Fee enumerator.  (2 / 20000 = 0.0001);
   */
  uint256 internal fee = 2;

  /**
   * Time when fee changing is enabled.
   */
  uint256 internal feeChangeEnableTime;

  /**
   * Encapsulates information about a person who bought some tokens during
   * "reserve" stage.
   */
  struct Investor {
    /**
     * Number of tokens bought during reserve stage.
     */
    uint256 tokensBought;

    /**
     * Ether invested during reserve stage.
     */
    uint256 etherInvested;
  }

  /**
   * Logged when investor invested some ether during "reserve" stage.
   *
   * @param investor address of investor
   * @param value amount of ether invested
   * @param amount number of tokens issued for investor
   */
  event Investment (address indexed investor, uint256 value, uint256 amount);

  /**
   * Logged when tokens bought at "reserve" stage were delivered to investor.
   *
   * @param investor address of investor whom tokens were delivered to
   * @param amount number of tokens delivered
   */
  event Delivery (address indexed investor, uint256 amount);

  /**
   * Logged when investment was refunded.
   *
   * @param investor address of investor whose investment was refunded
   * @param value amount of ether refunded
   */
  event Refund (address indexed investor, uint256 value);

  /**
   * Logged when K1 address was changed.
   *
   * @param k1 new K1 address
   */
  event K1Change (address k1);

  /**
   * Logged when investor voted for new K1 address.
   * 
   * @param investor investor who voted for new K1 address
   * @param newK1 new K1 address investor voted for
   * @param votes number of votes investor has
   */
  event Vote (address indexed investor, address indexed newK1, uint256 votes);

  /**
   * Logged when investor revoked vote for new K1 address.
   * 
   * @param investor investor who revoked vote for new K1 address
   * @param newK1 new K1 address investor revoked vote for
   * @param votes number of votes investor has
   */
  event VoteRevocation (
    address indexed investor, address indexed newK1, uint256 votes);

  /**
   * Logged when fee was changed.
   *
   * @param fee new fee numerator
   */
  event FeeChange (uint256 fee);
}