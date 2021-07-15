pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface ISwap {
  /**
   * @dev Pricing function for converting between TRX && Tokens.
   * @param input_amount Amount of TRX or Tokens being sold.
   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
   * @return Amount of TRX or Tokens bought.
   */
  function getInputPrice(
    uint256 input_amount,
    uint256 input_reserve,
    uint256 output_reserve
  ) external view returns (uint256);

  /**
   * @dev Pricing function for converting between TRX && Tokens.
   * @param output_amount Amount of TRX or Tokens being bought.
   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
   * @return Amount of TRX or Tokens sold.
   */
  function getOutputPrice(
    uint256 output_amount,
    uint256 input_reserve,
    uint256 output_reserve
  ) external view returns (uint256);

  /**
   * @notice Convert TRX to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param min_tokens Minimum Tokens bought.
   * @return Amount of Tokens bought.
   */
  function trxToTokenSwapInput(uint256 min_tokens)
  external
  payable
  returns (uint256);

  /**
   * @notice Convert TRX to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @return Amount of TRX sold.
   */
  function trxToTokenSwapOutput(uint256 tokens_bought)
  external
  payable
  returns (uint256);

  /**
   * @notice Convert Tokens to TRX.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_trx Minimum TRX purchased.
   * @return Amount of TRX bought.
   */
  function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx)
  external
  returns (uint256);

  /**
   * @notice Convert Tokens to TRX.
   * @dev User specifies maximum input && exact output.
   * @param trx_bought Amount of TRX purchased.
   * @param max_tokens Maximum Tokens sold.
   * @return Amount of Tokens sold.
   */
  function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens)
  external
  returns (uint256);

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Public price function for TRX to Token trades with an exact input.
   * @param trx_sold Amount of TRX sold.
   * @return Amount of Tokens that can be bought with input TRX.
   */
  function getTrxToTokenInputPrice(uint256 trx_sold)
  external
  view
  returns (uint256);

  /**
   * @notice Public price function for TRX to Token trades with an exact output.
   * @param tokens_bought Amount of Tokens bought.
   * @return Amount of TRX needed to buy output Tokens.
   */
  function getTrxToTokenOutputPrice(uint256 tokens_bought)
  external
  view
  returns (uint256);

  /**
   * @notice Public price function for Token to TRX trades with an exact input.
   * @param tokens_sold Amount of Tokens sold.
   * @return Amount of TRX that can be bought with input Tokens.
   */
  function getTokenToTrxInputPrice(uint256 tokens_sold)
  external
  view
  returns (uint256);

  /**
   * @notice Public price function for Token to TRX trades with an exact output.
   * @param trx_bought Amount of output TRX.
   * @return Amount of Tokens needed to buy output TRX.
   */
  function getTokenToTrxOutputPrice(uint256 trx_bought)
  external
  view
  returns (uint256);

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function tokenAddress() external view returns (address);

  function tronBalance() external view returns (uint256);

  function tokenBalance() external view returns (uint256);

  function getTrxToLiquidityInputPrice(uint256 trx_sold)
  external
  view
  returns (uint256);

  function getLiquidityToReserveInputPrice(uint256 amount)
  external
  view
  returns (uint256, uint256);

  function txs(address owner) external view returns (uint256);

  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /**
   * @notice Deposit TRX && Tokens (token) at current ratio to mint SWAP tokens.
   * @dev min_liquidity does nothing when total SWAP supply is 0.
   * @param min_liquidity Minimum number of SWAP sender will mint if total SWAP supply is greater than 0.
   * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total SWAP supply is 0.
   * @return The amount of SWAP minted.
   */
  function addLiquidity(uint256 min_liquidity, uint256 max_tokens)
  external
  payable
  returns (uint256);

  /**
   * @dev Burn SWAP tokens to withdraw TRX && Tokens at current ratio.
   * @param amount Amount of SWAP burned.
   * @param min_trx Minimum TRX withdrawn.
   * @param min_tokens Minimum Tokens withdrawn.
   * @return The amount of TRX && Tokens withdrawn.
   */
  function removeLiquidity(
    uint256 amount,
    uint256 min_trx,
    uint256 min_tokens
  ) external returns (uint256, uint256);
}

interface IToken {
  function remainingMintableSupply() external view returns (uint256);

  function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function balanceOf(address who) external view returns (uint256);

  function mintedSupply() external returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);
}

interface ITokenMint {

  function mint(address beneficiary, uint256 tokenAmount) external returns (uint256);

  function estimateMint(uint256 _amount) external returns (uint256);

  function remainingMintableSupply() external returns (uint256);
}

interface IDripVault {

  function withdraw(uint256 tokenAmount) external;

}

contract Faucet is OwnableUpgradeable {

  using SafeMath for uint256;

  struct User {
    //Referral Info
    address upline;  //**
    uint256 referrals; //*
    uint256 total_structure; //*

    //Long-term Referral Accounting
    uint256 direct_bonus;  //**
    uint256 match_bonus;  //**

    //Deposit Accounting
    uint256 deposits;  //**
    uint256 deposit_time; //*

    //Payout and Roll Accounting
    uint256 payouts;  //**
    uint256 rolls;

    //Upline Round Robin tracking
    uint256 ref_claim_pos;
  }

  struct Airdrop {
    //Airdrop tracking
    uint256 airdrops; //*
    uint256 airdrops_received; //*
    uint256 last_airdrop;  //**
  }

  struct Custody {
    address manager;
    address beneficiary;
    uint256 last_heartbeat;
    uint256 last_checkin;
    uint256 heartbeat_interval;
  }

  address public fountainAddress;
  address public dripVaultAddress;

  ITokenMint private tokenMint;
  IToken private br34pToken;
  IToken private dripToken;
  IDripVault private dripVault;

  mapping(address => User) public users;
  mapping(address => Airdrop) public airdrops;
  mapping(address => Custody) public custody;

  uint256 public CompoundTax;
  uint256 public ExitTax;

  uint256 private constant payoutRate = 1;
  uint256 private constant ref_depth  = 15;
  uint256 private constant ref_bonus  = 10;

  uint256 private constant minimumInitial = 10e18;
  uint256 private constant minimumAmount = 1e18;

  uint256 public deposit_bracket_size;     // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
  uint256 public max_payout_cap;          // 100k DRIP or 10% of supply
  uint256 private constant deposit_bracket_max = 10;  // sustainability fee is (bracket * 5)

  uint256[] public ref_balances;

  uint256 public total_airdrops; //***
  uint256 public total_users; //***
  uint256 public total_deposited; //***
  uint256 public total_withdraw; //***
  uint256 public total_bnb; //***
  uint256 public total_txs; //***

  uint256 public constant MAX_UINT = 2**256 - 1;

  event Upline(address indexed addr, address indexed upline);
  event NewDeposit(address indexed addr, uint256 amount);
  event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
  event DirectPayout(address indexed addr, address indexed from, uint256 amount);
  event MatchPayout(address indexed addr, address indexed from, uint256 amount);
  event BalanceTransfer(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
  event Withdraw(address indexed addr, uint256 amount);
  event LimitReached(address indexed addr, uint256 amount);
  event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
  event ManagerUpdate(address indexed addr, address indexed manager, uint256 timestamp);
  event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
  event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
  event HeartBeat(address indexed addr, uint256 timestamp);
  event Checkin(address indexed addr, uint256 timestamp);


  //todo initializer here
  /* ========== INITIALIZER ========== */

  function initialize(address _mintAddress, address _BR34PTokenAddress, address _dripTokenAddress, address _fountainAddress, address _vaultAddress) external initializer {
    __Ownable_init();

    total_users = 1;
    deposit_bracket_size = 10000e18;     // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
    max_payout_cap = 100000e18;          // 100k DRIP or 10% of supply

    CompoundTax = 5;
    ExitTax = 10;

    tokenMint = ITokenMint(_mintAddress);
    br34pToken = IToken(_BR34PTokenAddress);
    dripToken = IToken(_dripTokenAddress);
    //IDripVault
    dripVaultAddress = _vaultAddress;
    dripVault = IDripVault(_vaultAddress);

    //Referral Balances
    ref_balances.push(2e8);
    ref_balances.push(3e8);
    ref_balances.push(5e8);
    ref_balances.push(8e8);
    ref_balances.push(13e8);
    ref_balances.push(21e8);
    ref_balances.push(34e8);
    ref_balances.push(55e8);
    ref_balances.push(89e8);
    ref_balances.push(144e8);
    ref_balances.push(233e8);
    ref_balances.push(377e8);
    ref_balances.push(610e8);
    ref_balances.push(987e8);
    ref_balances.push(1597e8);
  }

//  constructor(address _mintAddress, address _BR34PTokenAddress, address _dripTokenAddress, address _fountainAddress, address _vaultAddress) public Ownable() {
//  }

  //@dev Default payable is empty since Faucet executes trades and recieves BNB
  fallback() external payable  {
    //Do nothing, BNB will be sent to contract when selling tokens
  }

  /****** Administrative Functions *******/

  /****** Management Functions *******/

  //@dev Update the sender's manager
  function updateManager(address _manager) public {
    address _addr = msg.sender;

    //Checkin for custody management.  If a user rolls for themselves they are active
    checkin();

    custody[_addr].manager = _manager;

    emit ManagerUpdate(_addr, _manager, block.timestamp);
  }

  //@dev Update the sender's beneficiary
  function updateBeneficiary(address _beneficiary, uint256 _interval) public {
    address _addr = msg.sender;

    //Checkin for custody management.  If a user rolls for themselves they are active
    checkin();

    custody[_addr].beneficiary = _beneficiary;

    emit BeneficiaryUpdate(_addr, _beneficiary);

    //2 years is the inactivity limit for Google... (the UI will probably present a more practical upper limit)
    //If not launched the update interval can be set to anything for testng purposes
    require((_interval >= 90 days && _interval <= 730 days), "Time range is invalid");

    custody[_addr].heartbeat_interval =  _interval;

    emit HeartBeatIntervalUpdate(_addr, _interval);
  }

  function updateCompoundTax(uint256 _newCompoundTax) public onlyOwner {
    require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
    CompoundTax = _newCompoundTax;
  }

  function updateExitTax(uint256 _newExitTax) public onlyOwner {
    require(_newExitTax >= 0 && _newExitTax <= 20);
    ExitTax = _newExitTax;
  }

  function updateDepositBracketSize(uint256 _newBracketSize) public onlyOwner {
    deposit_bracket_size = _newBracketSize;
  }

  function updateMaxPayoutCap(uint256 _newPayoutCap) public onlyOwner {
    max_payout_cap = _newPayoutCap;
  }

  function updateHoldRequirements(uint256[] memory _newRefBalances) public onlyOwner {
    require(_newRefBalances.length == ref_depth);
    delete ref_balances;
    for(uint8 i = 0; i < ref_depth; i++) {
      ref_balances.push(_newRefBalances[i]);
    }
  }

  /********** User Fuctions **************************************************/

  //@dev Checkin disambiguates activity between an active manager and player; this allows a beneficiary to execute a call to "transferInactiveAccount" if the player is gone,
  //but a manager is still executing on their behalf!
  function checkin() public {
    address _addr = msg.sender;
    custody[_addr].last_checkin = block.timestamp;
    emit Checkin(_addr, custody[_addr].last_checkin);
  }

  //@dev Deposit specified DRIP amount supplying an upline referral
  function deposit(address _upline, uint256 _amount) external {

    address _addr = msg.sender;

    (uint256 realizedDeposit, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, _amount);
    uint256 _total_amount = realizedDeposit;

    //Checkin for custody management.  If a user rolls for themselves they are active
    checkin();

    require(_amount >= minimumAmount, "Minimum deposit of 1 DRIP");

    //If fresh account require 10 DRIP
    if (users[_addr].deposits == 0){
      require(_amount >= minimumInitial, "Initial deposit of 10 DRIP");
    }

    _setUpline(_addr, _upline);

    // Claim if divs are greater than 1% of the deposit
    if (claimsAvailable(_addr) > _amount / 100){
      uint256 claimedDivs = _claim(_addr, false);
      uint256 taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
      _total_amount += taxedDivs;
    }

    //Transfer DRIP to the contract
    require(
      dripToken.transferFrom(
        _addr,
        address(dripVaultAddress),
        _amount
      ),
      "DRIP token transfer failed"
    );
    /*
    User deposits 10;
    1 goes for tax, 9 are realized deposit
    */

    _deposit(_addr, _total_amount);

    emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
    total_txs++;

  }


  //@dev Claim, transfer, withdraw from vault
  function claim() external {

    //Checkin for custody management.  If a user rolls for themselves they are active
    checkin();

    address _addr = msg.sender;

    _claim_out(_addr);
  }

  //@dev Claim and deposit;
  function roll() public {

    //Checkin for custody management.  If a user rolls for themselves they are active
    checkin();

    address _addr = msg.sender;

    _roll(_addr);
  }

  /********** Internal Fuctions **************************************************/

  //@dev Is marked as a managed function
  function checkForManager(address _addr) internal {
    //Sender has to be the manager of the account
    require(custody[_addr].manager == msg.sender, "_addr is not set as manager");
  }

  //@dev Add direct referral and update team structure of upline
  function _setUpline(address _addr, address _upline) internal {
    /*
    1) User must not have existing up-line
    2) Up-line argument must not be equal to senders own address
    3) Senders address must not be equal to the owner
    4) Up-lined user must have a existing deposit
    */
    if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner() && (users[_upline].deposit_time > 0 || _upline == owner() )) {
      users[_addr].upline = _upline;
      users[_upline].referrals++;

      emit Upline(_addr, _upline);

      total_users++;

      for(uint8 i = 0; i < ref_depth; i++) {
        if(_upline == address(0)) break;

        users[_upline].total_structure++;

        _upline = users[_upline].upline;
      }
    }
  }

  //@dev Deposit
  function _deposit(address _addr, uint256 _amount) internal {
    //Can't maintain upline referrals without this being set

    require(users[_addr].upline != address(0) || _addr == owner(), "No upline");

    //stats
    users[_addr].deposits += _amount;
    users[_addr].deposit_time = block.timestamp;

    total_deposited += _amount;

    //events
    emit NewDeposit(_addr, _amount);

    //10% direct commission; only if net positive
    address _up = users[_addr].upline;
    if(_up != address(0) && isNetPositive(_up) && isBalanceCovered(_up, 1)) {
      uint256 _bonus = _amount / 10;

      //Log historical and add to deposits
      users[_up].direct_bonus += _bonus;
      users[_up].deposits += _bonus;

      emit NewDeposit(_up, _bonus);
      emit DirectPayout(_up, _addr, _bonus);
    }
  }

  //Payout upline; Bonuses are from 5 - 30% on the 1% paid out daily; Referrals only help
  function _refPayout(address _addr, uint256 _amount) internal {

    address _up = users[_addr].upline;
    uint256 _bonus = _amount * ref_bonus / 100;
    uint256 _share = _bonus / 4;
    uint256 _up_share = _bonus.sub(_share);
    bool _team_found = false;

    for(uint8 i = 0; i < ref_depth; i++) {

      // If we have reached the top of the chain, the owner
      if(_up == address(0)){
        //The equivalent of looping through all available
        users[_addr].ref_claim_pos = ref_depth;
        break;
      }

      //We only match if the claim position is valid
      if(users[_addr].ref_claim_pos == i && isBalanceCovered(_up, i + 1) && isNetPositive(_up)) {
        //Team wallets are split 75/25%
        if(users[_up].referrals >= 5 && !_team_found) {
          //This should only be called once
          _team_found = true;
          //upline is paid matching and
          users[_up].deposits += _up_share;
          users[_addr].deposits += _share;

          //match accounting
          users[_up].match_bonus += _up_share;

          //Synthetic Airdrop tracking; team wallets get automatic airdrop benefits
          airdrops[_up].airdrops += _share;
          airdrops[_up].last_airdrop = block.timestamp;
          airdrops[_addr].airdrops_received += _share;

          //Global airdrops
          total_airdrops += _share;

          //Events
          emit NewDeposit(_addr, _share);
          emit NewDeposit(_up, _up_share);

          emit NewAirdrop(_up, _addr, _share, block.timestamp);
          emit MatchPayout(_up, _addr, _up_share);
        } else {

          users[_up].deposits += _bonus;

          //match accounting
          users[_up].match_bonus += _bonus;

          //events
          emit NewDeposit(_up, _bonus);
          emit MatchPayout(_up, _addr, _bonus);
        }

        //The work has been done for the position; just break
        break;

      }

      _up = users[_up].upline;
    }

    //Reward the next
    users[_addr].ref_claim_pos += 1;

    //Reset if we've hit the end of the line
    if (users[_addr].ref_claim_pos >= ref_depth){
      users[_addr].ref_claim_pos = 0;
    }

  }

  //@dev General purpose heartbeat in the system used for custody/management planning
  function _heart(address _addr) internal {
    custody[_addr].last_heartbeat = block.timestamp;
    emit HeartBeat(_addr, custody[_addr].last_heartbeat);
  }


  //@dev Claim and deposit;
  function _roll(address _addr) internal {

    uint256 to_payout = _claim(_addr, false);

    uint256 payout_taxed = to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding

    //Recycle baby!
    _deposit(_addr, payout_taxed);

    //track rolls for net positive
    users[_addr].rolls += payout_taxed;

    emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
    total_txs++;

  }


  //@dev Claim, transfer, and topoff
  function _claim_out(address _addr) internal {

    uint256 to_payout = _claim(_addr, true);

    uint256 vaultBalance = dripToken.balanceOf(dripVaultAddress);
    if (vaultBalance < to_payout) {
      uint256 differenceToMint = to_payout.sub(vaultBalance);
      tokenMint.mint(dripVaultAddress, differenceToMint);
    }

    dripVault.withdraw(to_payout);

    uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(100); // 10% tax on withdraw
    require(dripToken.transfer(address(msg.sender), realizedPayout));

    emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
    total_txs++;

  }


  //@dev Claim current payouts
  function _claim(address _addr, bool isClaimedOut) internal returns (uint256) {
    (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
    require(users[_addr].payouts < _max_payout, "Full payouts");

    // Deposit payout
    if(_to_payout > 0) {

      // payout remaining allowable divs if exceeds
      if(users[_addr].payouts + _to_payout > _max_payout) {
        _to_payout = _max_payout.safeSub(users[_addr].payouts);
      }

      users[_addr].payouts += _gross_payout;
      //users[_addr].payouts += _to_payout;

      if (!isClaimedOut){
        //Payout referrals
        uint256 compoundTaxedPayout = _to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
        _refPayout(_addr, compoundTaxedPayout);
      }
    }

    require(_to_payout > 0, "Zero payout");

    //Update the payouts
    total_withdraw += _to_payout;

    //Update time!
    users[_addr].deposit_time = block.timestamp;

    emit Withdraw(_addr, _to_payout);

    if(users[_addr].payouts >= _max_payout) {
      emit LimitReached(_addr, users[_addr].payouts);
    }

    return _to_payout;
  }

  /********* Views ***************************************/

  //@dev Returns true if the address is net positive
  function isNetPositive(address _addr) public view returns (bool) {

    (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

    return _credits > _debits;

  }

  //@dev Returns the total credits and debits for a given address
  function creditsAndDebits(address _addr) public view returns (uint256 _credits, uint256 _debits) {
    User memory _user = users[_addr];
    Airdrop memory _airdrop = airdrops[_addr];

    _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
    _debits = _user.payouts;

  }

  //@dev Returns true if an account is active

  //@dev Returns whether BR34P balance matches level
  function isBalanceCovered(address _addr, uint8 _level) public view returns (bool) {
    return balanceLevel(_addr) >= _level;
  }

  //@dev Returns the level of the address
  function balanceLevel(address _addr) public view returns (uint8) {
    uint8 _level = 0;
    for (uint8 i = 0; i < ref_depth; i++) {
      if (br34pToken.balanceOf(_addr) < ref_balances[i]) break;
      _level += 1;
    }

    return _level;
  }

  //@dev Returns the realized sustainability fee of the supplied address
  function sustainabilityFee(address _addr) public view returns (uint256) {
    uint256 _bracket = users[_addr].deposits.div(deposit_bracket_size);
    _bracket = SafeMath.min(_bracket, deposit_bracket_max);
    return _bracket * 5;
  }

  //@dev Returns custody info of _addr
  function getCustody(address _addr) public view returns (address _beneficiary, uint256 _heartbeat_interval, address _manager) {
    return (custody[_addr].beneficiary, custody[_addr].heartbeat_interval, custody[_addr].manager);
  }

  //@dev Returns true if _manager is the manager of _addr
  function isManager(address _addr, address _manager) public view returns (bool) {
    return custody[_addr].manager == _manager;
  }

  //@dev Returns true if _beneficiary is the beneficiary of _addr
  function isBeneficiary(address _addr, address _beneficiary) public view returns (bool) {
    return custody[_addr].beneficiary == _beneficiary;
  }

  //@dev Returns true if _manager is valid for managing _addr
  function isManagementEligible(address _addr, address _manager) public view returns (bool) {
    return _manager != address(0) && _addr != _manager && users[_manager].deposits > 0 && users[_manager].deposit_time > 0;
  }

  //@dev Returns account activity timestamps
  function lastActivity(address _addr) public view returns (uint256 _heartbeat, uint256 _lapsed_heartbeat, uint256 _checkin, uint256 _lapsed_checkin) {
    _heartbeat = custody[_addr].last_heartbeat;
    _lapsed_heartbeat = block.timestamp.safeSub(_heartbeat);
    _checkin = custody[_addr].last_checkin;
    _lapsed_checkin = block.timestamp.safeSub(_checkin);
  }

  //@dev Returns amount of claims available for sender
  function claimsAvailable(address _addr) public view returns (uint256) {
    (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
    return _to_payout;
  }

  //@dev Maxpayout of 3.65 of deposit
  function maxPayoutOf(uint256 _amount) public pure returns(uint256) {
    return _amount * 365 / 100;
  }

  //@dev Calculate the current payout and maxpayout of a given address
  function payoutOf(address _addr) public view returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {

    //The max_payout is capped so that we can also cap available rewards daily
    max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);

    //This can  be 0 - 50 in increments of 5% @bb Whale tax bracket calcs here
    uint256 _fee = sustainabilityFee(_addr);
    uint256 share;

    // @BB: No need for negative fee

    if(users[_addr].payouts < max_payout) {
      //Using 1e18 we capture all significant digits when calculating available divs
      share = users[_addr].deposits.mul(payoutRate * 1e18).div(100e18).div(24 hours); //divide the profit by payout rate and seconds in the day
      payout = share * block.timestamp.safeSub(users[_addr].deposit_time);

      // payout remaining allowable divs if exceeds
      if(users[_addr].payouts + payout > max_payout) {
        payout = max_payout.safeSub(users[_addr].payouts);
      }

      sustainability_fee = payout * _fee / 100;

      net_payout = payout.safeSub(sustainability_fee);
    }
  }


  //@dev Get current user snapshot
  function userInfo(address _addr) external view returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop) {
    return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposits, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus, airdrops[_addr].last_airdrop);
  }

  //@dev Get user totals
  function userInfoTotals(address _addr) external view returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 airdrops_total, uint256 airdrops_received) {
    return (users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
  }

  //@dev Get contract snapshot
  function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_bnb, uint256 _total_txs, uint256 _total_airdrops) {
    return (total_users, total_deposited, total_withdraw, total_bnb, total_txs, total_airdrops);
  }

  /////// Airdrops ///////

  //@dev Send specified DRIP amount supplying an upline referral
  function airdrop(address _to, uint256 _amount) external {

    address _addr = msg.sender;

    (uint256 _realizedAmount, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, _amount);
    //This can only fail if the balance is insufficient
    require(
      dripToken.transferFrom(
        _addr,
        address(dripVaultAddress),
        _amount
      ),
      "DRIP to contract transfer failed; check balance and allowance, airdrop"
    );


    //Make sure _to exists in the system; we increase
    require(users[_to].upline != address(0), "_to not found");

    //Fund to deposits (not a transfer)
    users[_to].deposits += _realizedAmount;


    //User stats
    airdrops[_addr].airdrops += _realizedAmount;
    airdrops[_addr].last_airdrop = block.timestamp;
    airdrops[_to].airdrops_received += _realizedAmount;

    //Keep track of overall stats
    total_airdrops += _realizedAmount;
    total_txs += 1;


    //Let em know!
    emit NewAirdrop(_addr, _to, _realizedAmount, block.timestamp);
    emit NewDeposit(_to, _realizedAmount);
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /* @dev Subtracts two numbers, else returns zero */
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b > a) {
      return 0;
    } else {
      return a - b;
    }
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}