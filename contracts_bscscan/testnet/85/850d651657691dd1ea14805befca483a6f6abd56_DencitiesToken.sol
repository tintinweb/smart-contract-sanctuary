// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Controlled.sol";
import "./Owned.sol";
import "./ERC20.sol";
import "./Initializable.sol";
import "./MathLib.sol";
import "./SafeMathLib.sol";
import "./IDencitiesDAO.sol";
import "./DencitiesLPM.sol";


/**
 * /////////  /////   /// //////// ////////////
 * //    //  /// //  ///  ///          /// 
 * //   //  ///  //////   ///          ///  
 * //////  ///   /////    ///////      ///
**/ 
contract DencitiesToken is Controlled, Owned, ERC20, Initializable {
  using MathLib for uint256;
  using SafeMathLib for uint256;

  struct Fees {
    uint256 sender; // percent from sender
    uint256 recipient; // percent from recipient
  }

  struct Settings {
    Fees burnFees; // fee taken and burned
    Fees lpFees; // fee taken and added to the liquidity pool manager
    Fees rewardsFees; // fee taken and added to rewards
    uint256 minTotalSupply; // min amount of tokens total supply
  }

  struct Summary {
    uint256 totalExcluded; // total held by excluded accounts
    uint256 totalHolding; // total held by holder accounts
    uint256 totalRewards; // total rewards
    uint256 totalSupply; // total supply
  }

  struct ExcludedAccount {
    bool exists; // true if exists
    bool excludeSenderFromFee; // removes the fee from all sender accounts on incoming transfers
    bool excludeRecipientFromFee; // removes the fee from all recipient accounts on outgoing transfers
  }

  // globals

  uint256 private constant MAX_FEE = 30; // max sum of all fees - 30%

  // metadata

  string private constant TOKEN_NAME = "Dencities";
  string private constant TOKEN_SYMBOL = "DNCT";
  uint8 private constant TOKEN_DECIMALS = 9; // 0.000000000

  /**
   * @return dao address
   */
  IDencitiesDAO public dao;

  /**
   * @return liquidity pool manager address
   */
  DencitiesLPM public lpm;

  /**
   * @return settings object
   */
  Settings public settings;

  /**
   * @return summary object
   */
  Summary public summary;

  /**
   * @return return true when presale is finished
   */
  bool public presaleFinished;

  mapping (address => uint256) private accountBalances;
  mapping (address => mapping (address => uint256)) private accountAllowances;
  mapping (address => ExcludedAccount) private excludedAccounts;

  // events

  /**
   * @dev Emitted when the contract is initialized
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   * @param minTotalSupply min total supply
   * @param lpm liquidity pool manager address
   * @param controller controller address
   */
  event Initialized(
    Fees burnFees,
    Fees lpFees,
    Fees rewardsFees,
    uint256 minTotalSupply,
    address lpm,
    address controller
  );

  /**
   * @dev Emitted when the dao is updated
   * @param dao dao address
   */
  event DAOUpdated(
    address dao
  );

  /**
   * @dev Emitted when fees are updated
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   */
  event FeesUpdated(
    Fees burnFees,
    Fees lpFees,
    Fees rewardsFees
  );

  /**
   * @dev Emitted when the presale is finished
   */
  event PresaleFinished();

  /**
   * @dev Emitted when account is excluded
   * @param account account address
   * @param excludeSenderFromFee exclude sender from fee
   * @param excludeRecipientFromFee exclude recipient from fee
   */
  event AccountExcluded(
    address indexed account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  );

  /**
   * @dev Emitted when total rewards amount is updated
   * @param totalRewards total rewards amount
   */
  event TotalRewardsUpdated(
    uint256 totalRewards
  );

  // modifiers

  /**
   * @dev Throws if msg.sender is not the dao
   */
  modifier onlyDAO() {
    require(
      msg.sender == address(dao),
      "DencitiesToken#1" // msg.sender is not the dao
    );

    _;
  }

  /**
   * @dev Throws if msg.sender is not the excluded account
   */
  modifier onlyExcludedAccount() {
    require(
      excludedAccounts[msg.sender].exists,
      "DencitiesToken#2" // msg.sender is not the excluded account
    );

    _;
  }

  /**
   * @dev Public constructor
   */
  constructor ()
    public
    Controlled()
    Owned()
    ERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS) // sets metadata
    Initializable()
  {
    //
  }

  // external functions

  /**
   * @dev Initializes the contract
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   * @param minTotalSupply min total supply
   * @param lpm_ liquidity pool manager address
   * @param controller_ controller address
   * @param totalSupply_ total supply
   */
  function initialize(
    Fees memory burnFees,
    Fees memory lpFees,
    Fees memory rewardsFees,
    uint256 minTotalSupply,
    address payable lpm_,
    address controller_,
    uint256 totalSupply_,
    address[] calldata excludedAccounts_
  )
    external
    onlyInitializer
  {
    _verifyFees(burnFees, lpFees, rewardsFees);

    settings.burnFees = burnFees;
    settings.lpFees = lpFees;
    settings.rewardsFees = rewardsFees;
    settings.minTotalSupply = minTotalSupply;

    if (
      lpFees.sender != 0 ||
      lpFees.recipient != 0
    ) {
      require(
        lpm_ != address(0),
        "DencitiesToken#3" // lpm is the zero address
      );

      lpm = DencitiesLPM(lpm_);
    }

    _initializeController(controller_);

    emit Initialized(
      burnFees,
      lpFees,
      rewardsFees,
      minTotalSupply,
      lpm_,
      controller_
    );

    // excludes owner account
    _excludeAccount(msg.sender, true, true);

    if (totalSupply_ != 0) {
      _mint(
        msg.sender,
        totalSupply_
      );
    }

    // adds predefined excluded accounts
    uint256 excludedAccountsLen = excludedAccounts_.length;

    for (uint256 index; index < excludedAccountsLen; index++) {
      _excludeAccount(excludedAccounts_[index], false, false);
    }
  }

  /**
   * @dev Sets the dao
   * @param dao_ dao address
   */
  function setDAO(
    address dao_
  )
    external
    onlyOwner
  {
    require(
      dao_ != address(0),
      "DencitiesToken#4" // lpm is the zero address
    );

    dao = IDencitiesDAO(dao_);

    emit DAOUpdated(
      dao_
    );

    // makes a dao an owner
    _setOwner(dao_);
  }

  /**
   * @dev Updates fees
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   */
  function updateFees(
    Fees memory burnFees,
    Fees memory lpFees,
    Fees memory rewardsFees
  )
    external
    onlyDAO // only for dao
  {
    _verifyFees(burnFees, lpFees, rewardsFees);

    settings.burnFees = burnFees;
    settings.lpFees = lpFees;
    settings.rewardsFees = rewardsFees;

    emit FeesUpdated(
      burnFees,
      lpFees,
      rewardsFees
    );
  }

  /**
   * @dev Set the presale as finished
   */
  function setPresaleAsFinished()
    external
    onlyOwner
  {
    require(
      !presaleFinished,
      "DencitiesToken#5" // the presale is already finished
    );

    presaleFinished = true;

    emit PresaleFinished();
  }

  /**
   * @dev Excludes account
   * @param account account address
   * @param excludeSenderFromFee exclude sender from fee
   * @param excludeRecipientFromFee exclude recipient from fee
   */
  function excludeAccount(
    address account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  )
    external
    onlyOwner
  {
    _excludeAccount(
      account,
      excludeSenderFromFee,
      excludeRecipientFromFee
    );
  }

  /**
   * @dev Approve spending limit
   * @param spender spender address
   * @param amount spending limit
   */
  function approve(
    address spender,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      amount
    );

    return true;
  }

  /**
   * @dev Mints tokens to recipient
   * @param recipient recipient address
   * @param amount tokens amount
   */
  function mintTo(
    address recipient,
    uint256 amount
  )
    external
    onlyController
  {
    _mint(
      recipient,
      amount
    );
  }

  /**
   * @dev Burns tokens from msg.sender
   * @param amount tokens amount
   */
  function burn(
    uint256 amount
  )
    external
    onlyExcludedAccount
  {
    _burn(
      msg.sender,
      amount
    );
  }

  /**
   * @dev Burns tokens from sender
   * @param sender sender address
   * @param amount tokens amount
   */
  function burnFrom(
    address sender,
    uint256 amount
  )
    external
    onlyController
  {
    _burn(
      sender,
      amount
    );
  }

  /**
   * @dev Transfers tokens to recipient
   * @param recipient recipient address
   * @param amount tokens amount
   */
  function transfer(
    address recipient,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _transfer(
      msg.sender,
      recipient,
      amount
    );

    return true;
  }

  /**
   * @dev Transfers tokens from sender to recipient
   * @param sender sender address
   * @param recipient recipient address
   * @param amount tokens amount
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _transfer(
      sender,
      recipient,
      amount
    );

    uint256 allowance = accountAllowances[sender][msg.sender];

    require(
      allowance >= amount,
      "DencitiesToken#6"  // amount exceeds allowance
    );

    _approve( // update allowance
      sender,
      msg.sender,
      allowance.sub(amount)
    );

    return true;
  }

  // external functions (views)

  /**
   * @dev Gets excluded account
   * @param account account address
   */
  function getExcludedAccount(
    address account
  )
    external
    view
    returns (
      bool exists,
      bool excludeSenderFromFee,
      bool excludeRecipientFromFee
    )
  {
    return (
      excludedAccounts[account].exists,
      excludedAccounts[account].excludeSenderFromFee,
      excludedAccounts[account].excludeRecipientFromFee
    );
  }

  /**
   * @dev Gets total supply
   * @return total supply
   */
  function totalSupply()
    external
    view
    override
    returns (uint256)
  {
    return summary.totalSupply;
  }

  /**
   * @dev Gets allowance
   * @param owner owner address
   * @param spender spender address
   * @return allowance
   */
  function allowance(
    address owner,
    address spender
  )
    external
    view
    override
    returns (uint256)
  {
    return accountAllowances[owner][spender];
  }

  /**
   * @dev Gets balance of
   * @param account account address
   * @return result account balance
   */
  function balanceOf(
    address account
  )
    external
    view
    override
    returns (uint256 result)
  {
    result = accountBalances[account].add(
      _calcRewards(account)
    );

    return result;
  }

  /**
   * @dev Gets balance summary
   * @param account account address
   */
  function getBalanceSummary(
    address account
  )
    external
    view
    returns (
      uint256 totalBalance,
      uint256 holdingBalance,
      uint256 totalRewards
    )
  {
    holdingBalance = accountBalances[account];
    totalRewards = _calcRewards(account);
    totalBalance = holdingBalance.add(totalRewards);

    return (totalBalance, holdingBalance, totalRewards);
  }

  // private functions

  function _excludeAccount(
    address account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  )
    private
  {
    require(
      account != address(0),
      "DencitiesToken#7" // account is the zero address
    );

    // if already excluded
    if (excludedAccounts[account].exists) {
      require(
        excludedAccounts[account].excludeSenderFromFee != excludeSenderFromFee ||
        excludedAccounts[account].excludeRecipientFromFee != excludeRecipientFromFee,
        "DencitiesToken#8" // does not update exclude account
      );

      excludedAccounts[account].excludeSenderFromFee = excludeSenderFromFee;
      excludedAccounts[account].excludeRecipientFromFee = excludeRecipientFromFee;
    } else {
      require(
        accountBalances[account] == 0,
        "DencitiesToken#9" // can not exclude holder account
      );

      excludedAccounts[account].exists = true;
      excludedAccounts[account].excludeSenderFromFee = excludeSenderFromFee;
      excludedAccounts[account].excludeRecipientFromFee = excludeRecipientFromFee;
    }

    emit AccountExcluded(
      account,
      excludeSenderFromFee,
      excludeRecipientFromFee
    );
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  )
    private
  {
    require(
      spender != address(0),
      "DencitiesToken#11" // spender is the zero address
    );

    accountAllowances[owner][spender] = amount;

    emit Approval(
      owner,
      spender,
      amount
    );
  }

  function _mint(
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      recipient != address(0),
      "DencitiesToken#12" // recipient is the zero address
    );

    require(
      amount != 0,
      "DencitiesToken#13" // amount is zero
    );

    summary.totalSupply = summary.totalSupply.add(amount);

    // if exclude account
    if (excludedAccounts[recipient].exists) {
      summary.totalExcluded = summary.totalExcluded.add(amount);

      accountBalances[recipient] = accountBalances[recipient].add(amount);
    } else {
      _updateHoldingBalance(
        recipient,
        accountBalances[recipient].add(amount),
        summary.totalHolding.add(amount)
      );
    }

    _emitTransfer(
      address(0),
      recipient,
      amount
    );
  }

  function _burn(
    address sender,
    uint256 amount
  )
    private
  {
    require(
      sender != address(0),
      "DencitiesToken#14" // sender is the zero address
    );

    require(
      amount != 0,
      "DencitiesToken#15" // amount is zero
    );

    require(
      accountBalances[sender] >= amount,
      "DencitiesToken#16" // amount exceeds sender balance
    );

    uint256 totalSupply_ = summary.totalSupply.sub(amount);

    if (settings.minTotalSupply != 0) {
      require(
        totalSupply_ >= settings.minTotalSupply,
        "DencitiesToken#17" // new total supply exceeds min total supply
      );
    }

    summary.totalSupply = totalSupply_;

    // if exclude account
    if (excludedAccounts[sender].exists) {
      summary.totalExcluded = summary.totalExcluded.sub(amount);

      accountBalances[sender] = accountBalances[sender].sub(amount);
    } else {
      _updateHoldingBalance(
        sender,
        accountBalances[sender].sub(amount),
        summary.totalHolding.sub(amount)
      );
    }

    _emitTransfer(
      sender,
      address(0),
      amount
    );
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      sender != address(0),
      "DencitiesToken#18" // sender is the zero address
    );

    require(
      recipient != address(0),
      "DencitiesToken#19" // recipient is the zero address
    );

    if (sender == recipient) { // special transfer type
      _syncLP(); // sync only LP

      _emitTransfer(
        sender,
        recipient,
        0
      );
    } else {
      require(
        excludedAccounts[sender].exists ||
        presaleFinished,
        "DencitiesToken#20" // presale not finished yet
      );

      require(
        amount != 0,
        "DencitiesToken#21" // amount is zero
      );

      if (
        !excludedAccounts[sender].exists &&
        !excludedAccounts[recipient].exists
      ) {
        _transferBetweenHolderAccounts(
          sender,
          recipient,
          amount
        );
      } else if (
        excludedAccounts[sender].exists &&
        !excludedAccounts[recipient].exists
      ) {
        _transferFromExcludedAccount(
          sender,
          recipient,
          amount
        );
      } else if (
        !excludedAccounts[sender].exists &&
        excludedAccounts[recipient].exists
      ) {
        _transferToExcludedAccount(
          sender,
          recipient,
          amount
        );
      } else {
        _transferBetweenExcludedAccounts(
          sender,
          recipient,
          amount
        );
      }
    }
  }

  function _transferBetweenHolderAccounts(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    uint256 senderAmount;
    uint256 senderBurnFee;
    uint256 senderLpFee;

    uint256 recipientAmount;
    uint256 recipientBurnFee;
    uint256 recipientLpFee;

    uint256 totalFee;

    {
      uint256 totalSupply_ = summary.totalSupply;

      // calc fees for sender and recipient
      {
        uint256 senderTotalFee;
        uint256 recipientTotalFee;

        (
          senderTotalFee,
          senderBurnFee,
          senderLpFee
        ) = _calcTransferSenderFees(amount);

        (
          totalSupply_,
          senderTotalFee,
          senderBurnFee
        ) = _matchTotalSupplyWithFees(totalSupply_, senderTotalFee, senderBurnFee);

        (
          recipientTotalFee,
          recipientBurnFee,
          recipientLpFee
        ) = _calcTransferRecipientFees(amount);

        (
          totalSupply_,
          recipientTotalFee,
          recipientBurnFee
        ) = _matchTotalSupplyWithFees(totalSupply_, recipientTotalFee, recipientBurnFee);

        totalFee = senderTotalFee.add(recipientTotalFee);
        senderAmount = amount.add(senderTotalFee);
        recipientAmount = amount.sub(recipientTotalFee);
      }

      // appends total rewards
      if (summary.totalRewards != 0) {
        uint256 totalHoldingWithRewards = summary.totalHolding.add(
          summary.totalRewards
        );

        senderAmount = senderAmount.mul(summary.totalHolding).div(
          totalHoldingWithRewards
        );
        recipientAmount = recipientAmount.mul(summary.totalHolding).div(
          totalHoldingWithRewards
        );
        totalFee = totalFee.mul(summary.totalHolding).div(
          totalHoldingWithRewards
        );
      }

      require(
        accountBalances[sender] >= senderAmount,
        "DencitiesToken#22" // amount exceeds sender balance
      );

      summary.totalSupply = totalSupply_;

      // reduce local vars
      senderAmount = accountBalances[sender].sub(senderAmount);
      recipientAmount = accountBalances[recipient].add(recipientAmount);

      _updateHoldingBalances(
        sender,
        senderAmount,
        recipient,
        recipientAmount,
        summary.totalHolding.sub(totalFee)
      );

      _increaseTotalLP(senderLpFee.add(recipientLpFee));
    }

    // emits events

    {
      _emitTransfer(
        sender,
        recipient,
        amount
      );

      _emitTransfer(
        sender,
        address(0),
        senderBurnFee
      );

      _emitTransfer(
        sender,
        address(lpm),
        senderLpFee
      );

      _emitTransfer(
        recipient,
        address(0),
        recipientBurnFee
      );

      _emitTransfer(
        recipient,
        address(lpm),
        recipientLpFee
      );

      _updateTotalRewards();

      _syncLP();
    }
  }

  function _transferFromExcludedAccount(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      accountBalances[sender] >= amount,
      "DencitiesToken#23" // amount exceeds sender balance
    );

    (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    ) = _canSyncLP(
      sender,
      address(0)
    );

    if (shouldSyncLPBefore) {
      lpm.syncLP();
    }

    uint256 recipientTotalFee;
    uint256 recipientBurnFee;
    uint256 recipientLPFee;

    uint256 totalSupply_ = summary.totalSupply;

    // when sender does not remove the fee from the recipient
    if (!excludedAccounts[sender].excludeRecipientFromFee) {
      (
        recipientTotalFee,
        recipientBurnFee,
        recipientLPFee
      ) = _calcTransferRecipientFees(amount);

      (
        totalSupply_,
        recipientTotalFee,
        recipientBurnFee
      ) = _matchTotalSupplyWithFees(totalSupply_, recipientTotalFee, recipientBurnFee);
    }

    uint256 recipientAmount = amount.sub(recipientTotalFee);

    summary.totalSupply = totalSupply_;
    summary.totalExcluded = summary.totalExcluded.sub(amount);

    accountBalances[sender] = accountBalances[sender].sub(amount);

    _updateHoldingBalance(
      recipient,
      accountBalances[recipient].add(recipientAmount),
      summary.totalHolding.add(recipientAmount)
    );

    _increaseTotalLP(recipientLPFee);

    // emits events

    _emitTransfer(
      sender,
      recipient,
      amount
    );

    _emitTransfer(
      recipient,
      address(0),
      recipientBurnFee
    );

    _emitTransfer(
      recipient,
      address(lpm),
      recipientLPFee
    );

    _updateTotalRewards();

    if (shouldSyncLPAfter) {
      lpm.syncLP();
    }
  }

  function _transferToExcludedAccount(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    ) = _canSyncLP(
      address(0),
      recipient
    );

    if (shouldSyncLPBefore) {
      lpm.syncLP();
    }

    uint256 senderTotalFee;
    uint256 senderBurnFee;
    uint256 senderLpFee;

    uint256 totalSupply_ = summary.totalSupply;

    // when recipient does not remove the fee from the sender
    if (!excludedAccounts[recipient].excludeSenderFromFee) {
      (
        senderTotalFee,
        senderBurnFee,
        senderLpFee
      ) = _calcTransferSenderFees(amount);

      (
        totalSupply_,
        senderTotalFee,
        senderBurnFee
      ) = _matchTotalSupplyWithFees(totalSupply_, senderTotalFee, senderBurnFee);
    }

    uint256 senderAmount = amount.add(senderTotalFee);

    // append total rewards
    if (summary.totalRewards != 0) {
      uint256 totalHoldingWithRewards = summary.totalHolding.add(
        summary.totalRewards
      );

      senderAmount = senderAmount.mul(summary.totalHolding).div(
        totalHoldingWithRewards
      );
    }

    require(
      accountBalances[sender] >= senderAmount,
      "DencitiesToken#24" // amount exceeds sender balance
    );

    summary.totalSupply = totalSupply_;
    summary.totalExcluded = summary.totalExcluded.add(amount);

    accountBalances[recipient] = accountBalances[recipient].add(amount);

    _updateHoldingBalance(
      sender,
      accountBalances[sender].sub(senderAmount),
      summary.totalHolding.sub(senderAmount)
    );

    _increaseTotalLP(senderLpFee);

    // emits events

    _emitTransfer(
      sender,
      recipient,
      amount
    );

    _emitTransfer(
      sender,
      address(0),
      senderBurnFee
    );

    _emitTransfer(
      sender,
      address(lpm),
      senderLpFee
    );

    _updateTotalRewards();

    if (shouldSyncLPAfter) {
      lpm.syncLP();
    }
  }

  function _transferBetweenExcludedAccounts(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      accountBalances[sender] >= amount,
      "DencitiesToken#25" // amount exceeds sender balance
    );

    (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    ) = _canSyncLP(
      address(0),
      recipient
    );

    if (shouldSyncLPBefore) {
      lpm.syncLP();
    }

    accountBalances[sender] = accountBalances[sender].sub(amount);
    accountBalances[recipient] = accountBalances[recipient].add(amount);

    _emitTransfer(
      sender,
      recipient,
      amount
    );

    if (shouldSyncLPAfter) {
      lpm.syncLP();
    }
  }

  function _updateHoldingBalance(
    address holder,
    uint256 holderBalance,
    uint256 totalHolding
  )
    private
  {
    accountBalances[holder] = holderBalance;
    summary.totalHolding = totalHolding;

    if (address(dao) != address(0)) { // if dao is not the zero address
      dao.syncMember(
        holder,
        holderBalance,
        totalHolding
      );
    }
  }

  function _updateHoldingBalances(
    address holderA,
    uint256 holderABalance,
    address holderB,
    uint256 holderBBalance,
    uint256 totalHolding
  )
    private
  {
    accountBalances[holderA] = holderABalance;
    accountBalances[holderB] = holderBBalance;
    summary.totalHolding = totalHolding;

    if (address(dao) != address(0)) { // if dao is not the zero address
      dao.syncMembers(
        holderA,
        holderABalance,
        holderB,
        holderBBalance,
        totalHolding
      );
    }
  }

  function _emitTransfer(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    if (amount != 0) { // when amount is not zero
      emit Transfer(
        sender,
        recipient,
        amount
      );
    }
  }

  function _increaseTotalLP(
    uint256 amount
  )
    private
  {
    if (amount != 0) { // when amount is not zero
      accountBalances[address(lpm)] = accountBalances[address(lpm)].add(amount);

      summary.totalExcluded = summary.totalExcluded.add(amount);
    }
  }

  function _syncLP()
    private
  {
    if (address(lpm) != address(0)) { // if lpm is not the zero address
      lpm.syncLP();
    }
  }

  function _updateTotalRewards()
    private
  {
    // totalRewards = totalSupply - totalExcluded - totalHolding
    uint256 totalRewards = summary.totalSupply
    .sub(summary.totalExcluded)
    .sub(summary.totalHolding);

    if (totalRewards != summary.totalRewards) {
      summary.totalRewards = totalRewards;

      emit TotalRewardsUpdated(
        totalRewards
      );
    }
  }

  // private functions (views)

  function _matchTotalSupplyWithFees(
    uint256 totalSupply_,
    uint256 totalFee,
    uint256 burnFee
  )
    private
    view
    returns (uint256, uint256, uint256)
  {
    if (burnFee != 0) {
      uint256 newTotalSupply = totalSupply_.sub(burnFee);

      if (newTotalSupply >= settings.minTotalSupply) {
        totalSupply_ = newTotalSupply;
      } else  { // turn of burn fee
        totalFee = totalFee.sub(burnFee);
        burnFee = 0;
      }
    }

    return (totalSupply_, totalFee, burnFee);
  }


  function _canSyncLP(
    address sender,
    address recipient
  )
    private
    view
    returns (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    )
  {
    if (address(lpm) != address(0)) { // if lpm is not the zero address
      (shouldSyncLPBefore, shouldSyncLPAfter) = lpm.canSyncLP(
        sender,
        recipient
      );
    }

    return (shouldSyncLPBefore, shouldSyncLPAfter);
  }

  function _calcRewards(
    address account
  )
    private
    view
    returns (uint256 result)
  {
    if (
      !excludedAccounts[account].exists && // only for holders
      summary.totalRewards != 0
    ) {
      result = summary.totalRewards
        .mul(accountBalances[account])
        .div(summary.totalHolding);
    }

    return result;
  }

  function _calcTransferSenderFees(
    uint256 amount
  )
    private
    view
    returns (
      uint256 totalFee,
      uint256 burnFee,
      uint256 lpFee
    )
  {
    uint256 rewardsFee = amount.percent(settings.rewardsFees.sender);

    lpFee = amount.percent(settings.lpFees.sender);
    burnFee = amount.percent(settings.burnFees.sender);

    totalFee = lpFee.add(rewardsFee).add(burnFee);

    return (totalFee, burnFee, lpFee);
  }

  function _calcTransferRecipientFees(
    uint256 amount
  )
    private
    view
    returns (
      uint256 totalFee,
      uint256 burnFee,
      uint256 lpFee
    )
  {
    uint256 rewardsFee = amount.percent(settings.rewardsFees.recipient);

    lpFee = amount.percent(settings.lpFees.recipient);
    burnFee = amount.percent(settings.burnFees.recipient);

    totalFee = lpFee.add(rewardsFee).add(burnFee);

    return (totalFee, burnFee, lpFee);
  }

  // private functions (pure)

  function _verifyFees(
    Fees memory burnFees,
    Fees memory lpFees,
    Fees memory rewardsFees
  )
    private
    pure
  {
    uint256 totalFee = burnFees.sender.add(
      burnFees.recipient
    ).add(
      lpFees.sender.add(lpFees.recipient)
    ).add(
      rewardsFees.sender.add(rewardsFees.recipient)
    );

    require(
      totalFee <= MAX_FEE,
      "DencitiesToken#26" // the total fee is too high
    );
  }
}