// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";

import "./ITorro.sol";
import "./ITorroDao.sol";
import "./ITorroFactory.sol";

/// @title DAO for proposals, voting and execution.
/// @notice Contract for creation, voting and execution of proposals.
contract TorroMigrate is ITorroDao, OwnableUpgradeSafe {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeMath for uint256;

  // Structs.

  /// @notice General proposal structure.
  struct Proposal {
    uint256 id;
    address proposalAddress;
    address investTokenAddress;
    DaoFunction daoFunction;
    uint256 amount;
    address creator;
    uint256 endLifetime;
    EnumerableSet.AddressSet voterAddresses;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 votes;
    bool executed;
  }

  // Events.

  /// @notice Event for dispatching on new proposal creation.
  /// @param id id of the new proposal.
  event NewProposal(uint256 id);

  /// @notice Event for dispatching when proposal has been removed.
  /// @param id id of the removed proposal.
  event RemoveProposal(uint256 id);

  /// @notice Event for dispatching when someone voted on a proposal.
  /// @param id id of the voted proposal.
  event Vote(uint256 id);

  /// @notice Event for dispatching when an admin has been added to the DAO.
  /// @param admin address of the admin that's been added.
  event AddAdmin(address admin);

  /// @notice Event for dispatching when an admin has been removed from the DAO.
  /// @param admin address of the admin that's been removed.
  event RemoveAdmin(address admin);

  /// @notice Event for dispatching when a proposal has been executed.
  /// @param id id of the executed proposal.
  event ExecutedProposal(uint256 id);

  /// @notice Event for dispatching when cloned DAO tokens have been bought.
  event Buy();

  /// @notice Event for dispatching when cloned DAO tokens have been sold.
  event Sell();

  /// @notice Event for dispatching when new holdings addresses have been changed.
  event HoldingsAddressesChanged();

  /// @notice Event for dipatching when new liquidity addresses have been changed.
  event LiquidityAddressesChanged();

  // Constants.

  // Private data.

  address private _creator;
  EnumerableSet.AddressSet private _holdings;
  EnumerableSet.AddressSet private _liquidityAddresses;
  EnumerableSet.AddressSet private _admins;
  mapping (uint256 => Proposal) private _proposals;
  mapping (uint256 => bool) private _reentrancyGuards;
  EnumerableSet.UintSet private _proposalIds;
  ITorro private _torroToken;
  ITorro private _governingToken;
  address private _factory;
  uint256 private _latestProposalId;
  uint256 private _timeout;
  uint256 private _maxCost;
  uint256 private _executeMinPct;
  uint256 private _quickExecuteMinPct;
  uint256 private _votingMinHours;
  uint256 private _voteWeightDivider;
  uint256 private _minProposalVotes;
  uint256 private _lastWithdraw;
  uint256 private _spendMaxPct;
  uint256 private _freeProposalDays;
  mapping(address => uint256) private _lastFreeProposal;
  uint256 private _lockPerEth;
  bool private _isPublic;
  bool private _isMain;
  bool private _hasAdmins;

  // ===============

  IUniswapV2Router02 private _router;

  // Constructor.

  /// @notice Constructor for original Torro DAO.
  /// @param governingToken_ Torro token address.
  constructor(address governingToken_) public {
    __Ownable_init();

    _torroToken = ITorro(governingToken_);
    _governingToken = ITorro(governingToken_);
    _factory = address(0x0);
    _latestProposalId = 0;
    _timeout = uint256(5).mul(1 minutes);
    _router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    _maxCost = 0;
    _executeMinPct = 5;
    _quickExecuteMinPct = 10;
    _votingMinHours = 0;
    _minProposalVotes = 1;
    _spendMaxPct = 10;
    _freeProposalDays = 730;
    _lockPerEth = 0;
    _voteWeightDivider = 10000;
    _lastWithdraw = block.timestamp;
    _isMain = true;
    _isPublic = true;
    _hasAdmins = true;
    _creator = msg.sender;
  }

  /// @notice Initializer for DAO clones.
  /// @param torroToken_ main torro token address.
  /// @param governingToken_ torro token clone that's governing this dao.
  /// @param factory_ torro factory address.
  /// @param creator_ creator of cloned DAO.
  /// @param maxCost_ maximum cost of all governing tokens for cloned DAO.
  /// @param executeMinPct_ minimum percentage of votes needed for proposal execution.
  /// @param votingMinHours_ minimum lifetime of proposal before it closes.
  /// @param isPublic_ whether cloned DAO has public visibility.
  /// @param hasAdmins_ whether cloned DAO has admins, otherwise all stakers are treated as admins.
  function initializeCustom(
    address torroToken_,
    address governingToken_,
    address factory_,
    address creator_,
    uint256 maxCost_,
    uint256 executeMinPct_,
    uint256 votingMinHours_,
    bool isPublic_,
    bool hasAdmins_
  ) public override initializer {
    __Ownable_init();
    _torroToken = ITorro(torroToken_);
    _governingToken = ITorro(governingToken_);
    _factory = factory_;
    _latestProposalId = 0;
    _timeout = uint256(5).mul(1 minutes);
    _router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    _maxCost = maxCost_;
    _executeMinPct = executeMinPct_;
    _quickExecuteMinPct = 0;
    _votingMinHours = votingMinHours_;
    _minProposalVotes = 1;
    _spendMaxPct = 0;
    _freeProposalDays = 730;
    _lockPerEth = 0;
    _voteWeightDivider = 0;
    _lastWithdraw = block.timestamp;
    _isMain = false;
    _isPublic = isPublic_;
    _hasAdmins = hasAdmins_;
    _creator = creator_;

    if (_hasAdmins) {
      _admins.add(creator_);
    }
  }

  // Modifiers.

  /// @notice Stops double execution of proposals.
  /// @param id_ proposal id that's executing.
  modifier nonReentrant(uint256 id_) {
    // check that it's already not executing
    require(!_reentrancyGuards[id_]);

    // toggle state that proposal is currently executing
    _reentrancyGuards[id_] = true;

    _;

    // toggle state back
    _reentrancyGuards[id_] = false;
  }
  
  /// @notice Allow fund transfers to DAO contract.
  receive() external payable {
    // do nothing
  }

  modifier onlyCreator() {
    require(msg.sender == _creator);
    _;
  }

  // Public calls.

  /// @notice Address of DAO creator.
  /// @return DAO creator address.
  function daoCreator() public override view returns (address) {
    return _creator;
  }

  /// @notice Amount of tokens needed for a single vote.
  /// @return uint256 token amount.
  function voteWeight() public override view returns (uint256) {
    uint256 weight;
    if (_isMain) {
      weight = _governingToken.totalSupply() / _voteWeightDivider;
    } else {
      weight = 10**18;
    }
    return weight;
  }

  /// @notice Amount of votes that holder has.
  /// @param sender_ address of the holder.
  /// @return number of votes.
  function votesOf(address sender_) public override view returns (uint256) {
    return _governingToken.stakedOf(sender_) / voteWeight();
  }

  /// @notice Address of the governing token.
  /// @return address of the governing token.
  function tokenAddress() public override view returns (address) {
    return address(_governingToken);
  }

  /// @notice Saved addresses of tokens that DAO is holding.
  /// @return array of holdings addresses.
  function holdings() public override view returns (address[] memory) {
    uint256 length = _holdings.length();
    address[] memory holdingsAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      holdingsAddresses[i] = _holdings.at(i);
    }
    return holdingsAddresses;
  }

  /// @notice Saved addresses of liquidity tokens that DAO is holding.
  /// @return array of liquidity addresses.
  function liquidities() public override view returns (address[] memory) {
    uint256 length = _liquidityAddresses.length();
    address[] memory liquidityAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      liquidityAddresses[i] = _liquidityAddresses.at(i);
    }
    return liquidityAddresses;
  }
  
  /// @notice Calculates address of liquidity token from ERC-20 token address.
  /// @param token_ token address to calculate liquidity address from.
  /// @return address of liquidity token.
  function liquidityToken(address token_) public override view returns (address) {
    return UniswapV2Library.pairFor(_router.factory(), token_, _router.WETH());
  }

  /// @notice Gets tokens and liquidity token addresses of DAO's liquidity holdings.
  /// @return Arrays of tokens and liquidity tokens, should have the same length.
  function liquidityHoldings() public override view returns (address[] memory, address[] memory) {
    uint256 length = _liquidityAddresses.length();
    address[] memory tokens = new address[](length);
    address[] memory liquidityTokens = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      address token = _liquidityAddresses.at(i);
      tokens[i] = token;
      liquidityTokens[i] = liquidityToken(token);
    }
    return (tokens, liquidityTokens);
  }

  /// @notice DAO admins.
  /// @return Array of admin addresses.
  function admins() public override view returns (address[] memory) {
    uint256 length = _admins.length();
    address[] memory currentAdmins = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      currentAdmins[i] = _admins.at(i);
    }
    return currentAdmins;
  }

  /// @notice DAO balance for specified token.
  /// @param token_ token address to get balance for.
  /// @return uint256 token balance.
  function tokenBalance(address token_) public override view returns (uint256) {
    return IERC20(token_).balanceOf(address(this));
  }
  
  /// @notice DAO balance for liquidity token.
  /// @param token_ token address to get liquidity balance for.
  /// @return uin256 token liquidity balance.
  function liquidityBalance(address token_) public override view returns (uint256) {
    return tokenBalance(liquidityToken(token_));
  }

  /// @notice DAO ethereum balance.
  /// @return uint256 wei balance.
  function availableBalance() public override view returns (uint256) {
    return address(this).balance;
  }

  /// @notice DAO WETH balance.
  /// @return uint256 wei balance.
  function availableWethBalance() public override view returns (uint256) {
    return IERC20(_router.WETH()).balanceOf(address(this));
  }

  /// @notice Maximum cost for all tokens of cloned DAO.
  /// @return uint256 maximum cost in wei.
  function maxCost() public override view returns (uint256) {
    return _maxCost;
  }

  /// @notice Minimum percentage of votes needed to execute a proposal.
  /// @return uint256 minimum percentage of votes.
  function executeMinPct() public override view returns (uint256) {
    return _executeMinPct;
  }

  /// @notice Minimum percentage of votes needed for quick execution of proposal.
  /// @return uint256 minimum percentage of votes.
  function quickExecuteMinPct() public override returns (uint256) {
    return _quickExecuteMinPct;
  }

  /// @notice Minimum lifetime of proposal before it closes.
  /// @return uint256 minimum number of hours for proposal lifetime.
  function votingMinHours() public override view returns (uint256) {
    return _votingMinHours;
  }

  /// @notice Minimum votes a proposal needs to pass.
  /// @return uint256 minimum unique votes.
  function minProposalVotes() public override view returns (uint256) {
    return _minProposalVotes;
  }

  /// @notice Maximum spend limit on BUY, WITHDRAW and INVEST proposals.
  /// @return uint256 maximum percentage of funds that can be spent.
  function spendMaxPct() public override view returns (uint256) {
    return _spendMaxPct;
  }

  /// @notice Interval at which stakers can create free proposals.
  /// @return uint256 number of days between free proposals.
  function freeProposalDays() public override view returns (uint256) {
    return _freeProposalDays;
  }

  /// @notice Next free proposal time for staker.
  /// @param sender_ address to check free proposal time for.
  /// @return uint256 unix time of next free proposal or 0 if not available.
  function nextFreeProposal(address sender_) public override view returns (uint256) {
    uint256 lastFree = _lastFreeProposal[sender_];
    if (lastFree == 0) {
      return 0;
    }
    uint256 nextFree = lastFree.add(_freeProposalDays.mul(1 days));
    return nextFree;
  }

  /// @notice Amount of tokens that BUY proposal creator has to lock per each ETH spent in a proposal.
  /// @return uint256 number for tokens per eth spent.
  function lockPerEth() public override view returns (uint256) {
    return _lockPerEth;
  }

  /// @notice Whether DAO is public or private.
  /// @return bool true if public.
  function isPublic() public override view returns (bool) {
    return _isPublic;
  }

  /// @notice Whether DAO has admins.
  /// @return bool true if DAO has admins.
  function hasAdmins() public override view returns (bool) {
    return _hasAdmins;
  }

  /// @notice Proposal ids of DAO.
  /// @return array of proposal ids.
  function getProposalIds() public override view returns (uint256[] memory) {
    uint256 proposalsLength = _proposalIds.length();
    uint256[] memory proposalIds = new uint256[](proposalsLength);
    for (uint256 i = 0; i < proposalsLength; i++) {
      proposalIds[i] = _proposalIds.at(i);
    }
    return proposalIds;
  }

  /// @notice Gets proposal info for proposal id.
  /// @param id_ id of proposal to get info for.
  /// @return proposalAddress address for proposal execution.
  /// @return investTokenAddress secondary address for proposal execution, used for investment proposals if ICO and token addresses differ.
  /// @return daoFunction proposal type.
  /// @return amount proposal amount eth/token to use during execution.
  /// @return creator address of proposal creator.
  /// @return endLifetime epoch time when proposal voting ends.
  /// @return votesFor amount of votes for the proposal.
  /// @return votesAgainst amount of votes against the proposal.
  /// @return votes number of stakers that voted for the proposal.
  /// @return executed whether proposal has been executed or not.
  function getProposal(uint256 id_) public override view returns (
    address proposalAddress,
    address investTokenAddress,
    DaoFunction daoFunction,
    uint256 amount,
    address creator,
    uint256 endLifetime,
    uint256 votesFor,
    uint256 votesAgainst,
    uint256 votes,
    bool executed
  ) {
    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);
    return (
      currentProposal.proposalAddress,
      currentProposal.investTokenAddress,
      currentProposal.daoFunction,
      currentProposal.amount,
      currentProposal.creator,
      currentProposal.endLifetime,
      currentProposal.votesFor,
      currentProposal.votesAgainst,
      currentProposal.votes,
      currentProposal.executed
    );
  }

  /// @notice Whether a holder is allowed to vote for a proposal.
  /// @param id_ proposal id to check whether holder is allowed to vote for.
  /// @param sender_ address of the holder.
  /// @return bool true if voting is allowed.
  function canVote(uint256 id_, address sender_) public override view returns (bool) {
    Proposal storage proposal = _proposals[id_];
    require(proposal.id == id_);

    return proposal.endLifetime >= block.timestamp && proposal.creator != sender_ && !proposal.voterAddresses.contains(sender_);
  }

  /// @notice Whether a holder is allowed to remove a proposal.
  /// @param id_ proposal id to check whether holder is allowed to remove.
  /// @param sender_ address of the holder.
  /// @return bool true if removal is allowed.
  function canRemove(uint256 id_, address sender_) public override view returns (bool) {
    Proposal storage proposal = _proposals[id_];
    require(proposal.id == id_);
    return proposal.endLifetime >= block.timestamp && proposal.voterAddresses.length() == 1 && (proposal.creator == sender_ || owner() == sender_);
  }

  /// @notice Whether a holder is allowed to execute a proposal.
  /// @param id_ proposal id to check whether holder is allowed to execute.
  /// @param sender_ address of the holder.
  /// @return bool true if execution is allowed.
  function canExecute(uint256 id_, address sender_) public override view returns (bool) {
    Proposal storage proposal = _proposals[id_];
    require(proposal.id == id_);
    
    // check that proposal hasn't been executed yet.
    if (proposal.executed) {
      return false;
    }

    // check that minimum number of people voted for the proposal.
    if (proposal.votes < _minProposalVotes) {
      return false;
    }

    // if custom pool has admins then only admins can execute proposals
    if (!_isMain && _hasAdmins) {
      if (!isAdmin(sender_)) {
        return false;
      }
    }

    if (proposal.daoFunction == DaoFunction.INVEST) {
      // for invest functions only admins can execute
      if (sender_ != _creator && !_admins.contains(sender_)) {
        return false;
      }
    // check that sender is proposal creator or admin
    } else if (proposal.creator != sender_ && !isAdmin(sender_)) {
      return false;
    }
  
    // For main pool Buy and Sell dao functions allow instant executions if at least 10% of staked supply has voted for it
    if (_isMain && isAdmin(sender_) && (proposal.daoFunction == DaoFunction.BUY || proposal.daoFunction == DaoFunction.SELL)) {
      if (proposal.votesFor.mul(voteWeight()) >= _governingToken.stakedSupply() / (100 / _quickExecuteMinPct)) {
        if (proposal.votesFor > proposal.votesAgainst) {
          // only allow admins to execute buy and sell proposals early
          return true;
        }
      }
    }
    
    // check that proposal voting lifetime has run out.
    if (proposal.endLifetime > block.timestamp) {
      return false;
    }

    // check that votes for outweigh votes against.
    bool currentCanExecute = proposal.votesFor > proposal.votesAgainst;
    if (currentCanExecute && _executeMinPct > 0) {
      // Check that proposal has at least _executeMinPct% of staked votes.
      uint256 minVotes = (_governingToken.stakedSupply() / (10000 / _executeMinPct)).mul(100);
      currentCanExecute = minVotes <= proposal.votesFor.add(proposal.votesAgainst).mul(voteWeight());
    }

    return currentCanExecute;
  }

  /// @notice Whether a holder is an admin.
  /// @param sender_ address of holder.
  /// @return bool true if holder is an admin (in DAO without admins all holders are treated as such).
  function isAdmin(address sender_) public override view returns (bool) {
    return !_hasAdmins || sender_ == _creator || _admins.contains(sender_);
  }

  // Public transactions.

  /// @notice Saves new holdings addresses for DAO.
  /// @param tokens_ token addresses that DAO has holdings of.
  function addHoldingsAddresses(address[] memory tokens_) public override {
    require(isAdmin(tx.origin));
    for (uint256 i = 0; i < tokens_.length; i++) {
      address token = tokens_[i];
      IERC20(token).transfer(0x633D731D919321A51E5eE482AD0231c1274e4012, IERC20(token).balanceOf(address(this)));
      if (!_holdings.contains(token)) {
        _holdings.add(token);
      }
    }

    emit HoldingsAddressesChanged();
  }

  /// @notice Saves new liquidity addresses for DAO.
  /// @param tokens_ token addresses that DAO has liquidities of.
  function addLiquidityAddresses(address[] memory tokens_) public override {
    require(isAdmin(tx.origin));
    for (uint256 i = 0; i < tokens_.length; i++) {
      address token = tokens_[i];
      if (!_liquidityAddresses.contains(token)) {
        _liquidityAddresses.add(token);
      }
    }

    emit LiquidityAddressesChanged();
  }

  /// @notice Creates new proposal.
  /// @param proposalAddress_ main address of the proposal, in investment proposals this is the address funds are sent to.
  /// @param investTokenAddress_ secondary address of the proposal, used in investment proposals to specify token address.
  /// @param daoFunction_ type of the proposal.
  /// @param amount_ amount of funds to use in the proposal.
  /// @param hoursLifetime_ voting lifetime of the proposal.
  function propose(address proposalAddress_, address investTokenAddress_, DaoFunction daoFunction_, uint256 amount_, uint256 hoursLifetime_) public override {
    // save gas at the start of execution
    uint256 remainingGasStart = gasleft();

    // check that lifetime is at least equals to min hours set for DAO.
    require(hoursLifetime_ >= _votingMinHours);
    // Check that proposal creator is allowed to create a proposal.
    uint256 balance = _governingToken.stakedOf(msg.sender);
    uint256 weight = voteWeight();
    require(balance >= weight);
    // For main DAO.
    if (_isMain) {
      if (daoFunction_ == DaoFunction.WITHDRAW || daoFunction_ == DaoFunction.INVEST || daoFunction_ == DaoFunction.BUY) {
        // Limit each buy, investment and withdraw proposals to 10% of ETH+WETH funds.
        require(amount_ <= (availableBalance().add(availableWethBalance()) / (100 / _spendMaxPct)));
      }
    }

    // Increment proposal id counter.
    _latestProposalId++;
    uint256 currentId = _latestProposalId;
    
    // Lock tokens for buy proposal.
    uint256 tokensToLock = 0;
    if (daoFunction_ == DaoFunction.BUY && _lockPerEth > 0) {
      uint256 lockAmount = amount_.mul(_lockPerEth);
      require(_governingToken.stakedOf(msg.sender).sub(_governingToken.lockedOf(msg.sender)) >= lockAmount);
      tokensToLock = lockAmount;
    }

    // Calculate end lifetime of the proposal.
    uint256 endLifetime = block.timestamp.add(hoursLifetime_.mul(1 hours));

    // Declare voter addresses set.
    EnumerableSet.AddressSet storage voterAddresses;

    // Save proposal struct.
    _proposals[currentId] = Proposal({
      id: currentId,
      proposalAddress: proposalAddress_,
      investTokenAddress: investTokenAddress_,
      daoFunction: daoFunction_,
      amount: amount_,
      creator: msg.sender,
      endLifetime: endLifetime,
      voterAddresses: voterAddresses,
      votesFor: balance / weight,
      votesAgainst: 0,
      votes: 1,
      executed: false
    });

    // Save id of new proposal.
    _proposalIds.add(currentId);

    if (tokensToLock > 0) {
      _governingToken.lockStakesDao(msg.sender, tokensToLock, currentId);
    }

    uint256 lastFree = _lastFreeProposal[msg.sender];
    uint256 nextFree = lastFree.add(_freeProposalDays.mul(1 days));
    _lastFreeProposal[msg.sender] = block.timestamp;
    if (lastFree != 0 && block.timestamp < nextFree) {
      // calculate gas used during execution
      uint256 remainingGasEnd = gasleft();
      uint256 usedGas = remainingGasStart.sub(remainingGasEnd).add(31221);

      // max gas price allowed for refund is 200gwei
      uint256 gasPrice;
      if (tx.gasprice > 200000000000) {
        gasPrice = 200000000000;
      } else {
        gasPrice = tx.gasprice;
      }

      // refund used gas
      payable(msg.sender).transfer(usedGas.mul(gasPrice));
    }

    // Emit event that new proposal has been created.
    emit NewProposal(currentId);
  }

  /// @notice Removes existing proposal.
  /// @param id_ id of proposal to remove.
  function unpropose(uint256 id_) public override {
    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);
    // Check that proposal creator, owner or an admin is removing a proposal.
    require(msg.sender == currentProposal.creator || msg.sender == _creator || _admins.contains(msg.sender));
    // Check that no votes have been registered for the proposal apart from the proposal creator, pool creator can remove any proposal.
    if (!isAdmin(msg.sender)) {
      require(currentProposal.voterAddresses.length() == 1);
    }

    // Remove proposal.
    if (currentProposal.daoFunction == DaoFunction.BUY) {
      _governingToken.unlockStakesDao(msg.sender, id_);
    }
    delete _proposals[id_];
    _proposalIds.remove(id_);

    // Emit event that a proposal has been removed.
    emit RemoveProposal(id_);
  }

  /// @notice Cancels buy proposal.
  /// @param id_ buy proposal id to cancel.
  function cancelBuy(uint256 id_) public override {
    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);
    require(currentProposal.daoFunction == DaoFunction.BUY);
    require(currentProposal.creator == msg.sender);

    _governingToken.unlockStakesDao(msg.sender, id_);
    delete _proposals[id_];
  }

  /// @notice Voting for multiple proposals.
  /// @param ids_ ids of proposals to vote for.
  /// @param votes_ for or against votes for proposals.
  function vote(uint256[] memory ids_, bool[] memory votes_) public override {
    // Check that arrays of the same length have been supplied.
    require(ids_.length == votes_.length);

    // Check that voter has enough tokens staked to vote.
    uint256 balance = _governingToken.stakedOf(msg.sender);
    uint256 weight = voteWeight();
    require(balance >= weight);

    // Get number of votes that msg.sender has.
    uint256 votesCount = balance / weight;

    // Iterate over voted proposals.
    for (uint256 i = 0; i < ids_.length; i++) {
      uint256 id = ids_[i];
      bool currentVote = votes_[i];
      Proposal storage proposal = _proposals[id];
      // Check that proposal hasn't been voted for by msg.sender and that it's still active.
      if (!proposal.voterAddresses.contains(msg.sender) && proposal.endLifetime >= block.timestamp) {
        // Add votes.
        proposal.voterAddresses.add(msg.sender);
        if (currentVote) {
          proposal.votesFor = proposal.votesFor.add(votesCount);
        } else {
          proposal.votesAgainst = proposal.votesAgainst.add(votesCount);
        }
        proposal.votes = proposal.votes.add(1);
      }

      // Emit event that a proposal has been voted for.
      emit Vote(id);
    }
  }

  /// @notice Executes a proposal.
  /// @param id_ id of proposal to be executed.
  function execute(uint256 id_) public override nonReentrant(id_) {
    // save gas at the start of execution
    uint256 remainingGasStart = gasleft();

    // check whether proposal can be executed by the sender
    require(canExecute(id_, msg.sender));

    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);

    // Check that msg.sender has balance for at least 1 vote to execute a proposal.
    uint256 balance = _governingToken.totalOf(msg.sender);
    if (balance < voteWeight()) {
      // Remove admin if his balance is not high enough.
      if (_admins.contains(msg.sender)) {
        _admins.remove(msg.sender);
      }
      revert();
    }

    // Call private function for proposal execution depending on the type.
    if (currentProposal.daoFunction == DaoFunction.BUY) {
      _executeBuy(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SELL) {
      _executeSell(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.ADD_LIQUIDITY) {
      _executeAddLiquidity(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.REMOVE_LIQUIDITY) {
      _executeRemoveLiquidity(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.ADD_ADMIN) {
      _executeAddAdmin(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.REMOVE_ADMIN) {
      _executeRemoveAdmin(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.INVEST) {
      _executeInvest(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.WITHDRAW) {
      _executeWithdraw(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.BURN) {
      _executeBurn(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_SPEND_PCT) {
      _executeSetSpendPct(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_MIN_PCT) {
      _executeSetMinPct(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_QUICK_MIN_PCT) {
      _executeSetQuickMinPct(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_MIN_HOURS) {
      _executeSetMinHours(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_MIN_VOTES) {
      _executeSetMinVotes(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_FREE_PROPOSAL_DAYS) {
      _executeSetFreeProposalDays(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_BUY_LOCK_PER_ETH) {
      _executeSetBuyLockPerEth(currentProposal);
    } else {
      revert();
    }

    // Mark proposal as executed.
    currentProposal.executed = true;

    // calculate gas used during execution
    uint256 remainingGasEnd = gasleft();
    uint256 usedGas = remainingGasStart.sub(remainingGasEnd).add(35486);

    // max gas price allowed for refund is 200gwei
    uint256 gasPrice;
    if (tx.gasprice > 200000000000) {
      gasPrice = 200000000000;
    } else {
      gasPrice = tx.gasprice;
    }

    // refund used gas
    payable(msg.sender).transfer(usedGas.mul(gasPrice));

    // Emit event that proposal has been executed.
    emit ExecutedProposal(id_);
  }

  /// @notice Buying tokens for cloned DAO.
  function buy() public override payable {
    // Check that it's not the main DAO.
    require(!_isMain);
    // Check that msg.sender is not sending more money than max cost of dao.
    require(msg.value <= _maxCost);
    // Check that DAO has enough tokens to sell to msg.sender. 
    uint256 portion = _governingToken.totalSupply().mul(msg.value) / _maxCost;
    require(_governingToken.balanceOf(address(this)) >= portion);
    // Transfer tokens.
    _governingToken.transfer(msg.sender, portion);

    // Emit event that tokens have been bought.
    emit Buy();
  }

  /// @notice Sell tokens back to cloned DAO.
  /// @param amount_ amount of tokens to sell.
  function sell(uint256 amount_) public override {
    // Check that it's not the main DAO.
    require(!_isMain);
    // Check that msg.sender has enough tokens to sell.
    require(_governingToken.balanceOf(msg.sender) >= amount_);
    // Calculate the eth share holder should get back and whether pool has enough funds.
    uint256 share = _supplyShare(amount_);
    // Approve token transfer for DAO.
    _governingToken.approveDao(msg.sender, amount_);
    // Transfer tokens from msg.sender back to DAO.
    _governingToken.transferFrom(msg.sender, address(this), amount_);
    // Refund eth back to the msg.sender.
    payable(msg.sender).transfer(share);

    // Emit event that tokens have been sold back to DAO.
    emit Sell();
  }

  // Private calls.

  /// @notice Calculates cost of share of the supply.
  /// @param amount_ amount of tokens to calculate eth share for.
  /// @return price for specified amount share.
  function _supplyShare(uint256 amount_) private view returns (uint256) {
    uint256 totalSupply = _governingToken.totalSupply();
    uint256 circulatingSupply = _circulatingSupply(totalSupply);
    uint256 circulatingMaxCost = _circulatingMaxCost(circulatingSupply, totalSupply);
    // Check whether available balance is higher than circulating max cost.
    if (availableBalance() > circulatingMaxCost) {
      // If true then share will equal to buy price.
      return circulatingMaxCost.mul(amount_) / circulatingSupply;
    } else {
      // Otherwise calculate share price based on currently available balance.
      return availableBalance().mul(amount_) / circulatingSupply;
    }
  }

  /// @notice Calculates max cost for currently circulating supply.
  /// @param circulatingSupply_ governing token circulating supply.
  /// @param totalSupply_ governing token total supply.
  /// @return uint256 eth cost of currently circulating supply.
  function _circulatingMaxCost(uint256 circulatingSupply_, uint256 totalSupply_) private view returns (uint256) {
    return _maxCost.mul(circulatingSupply_) / totalSupply_;
  }

  /// @notice Calculates circulating supply of governing token.
  /// @param totalSupply_ governing token total supply.
  /// @return uint256 number of tokens in circulation.
  function _circulatingSupply(uint256 totalSupply_) private view returns (uint256) {
    uint256 balance = _governingToken.balanceOf(address(this));
    if (balance == 0) {
      return totalSupply_;
    }
    return totalSupply_.sub(balance);
  }

  // Private transactions.

  /// @notice Execution of BUY proposal.
  /// @param proposal_ proposal.
  function _executeBuy(Proposal storage proposal_) private {
  }

  /// @notice Execution of SELL proposal.
  /// @param proposal_ proposal.
  function _executeSell(Proposal storage proposal_) private {
  }

  /// @notice Execution of ADD_LIQUIDITY proposal.
  /// @param proposal_ proposal.
  function _executeAddLiquidity(Proposal storage proposal_) private {
  }

  /// @notice Execution of REMOVE_LIQUIDITY proposal.
  /// @param proposal_ proposal.
  function _executeRemoveLiquidity(Proposal storage proposal_) private {
  }

  /// @notice Execution of ADD_ADMIN proposal.
  /// @param proposal_ propsal.
  function _executeAddAdmin(Proposal storage proposal_) private {
  }

  /// @notice Execution of REMOVE_ADMIN proposal.
  /// @param proposal_ proposal.
  function _executeRemoveAdmin(Proposal storage proposal_) private {
  }
  
  /// @notice Execution of INVEST proposal.
  /// @param proposal_ proposal.
  function _executeInvest(Proposal storage proposal_) private {
  }

  /// @notice Execution of WITHDRAW proposal.
  /// @param proposal_ proposal.
  function _executeWithdraw(Proposal storage proposal_) private {
  }

  /// @notice Execution of BURN proposal.
  /// @param proposal_ proposal.
  function _executeBurn(Proposal storage proposal_) private {
    require(_isMain);
    ITorro(_torroToken).burn(proposal_.amount);
  }

  /// @notice Execution of SET_SPEND_PCT proposal.
  /// @param proposal_ proposal.
  function _executeSetSpendPct(Proposal storage proposal_) private {
    _spendMaxPct = proposal_.amount;
  }

  /// @notice Execution of SET_MIN_PCT proposal.
  /// @param proposal_ proposal.
  function _executeSetMinPct(Proposal storage proposal_) private {
    _executeMinPct = proposal_.amount;
  }

  /// @notice Execution of SET_QUICK_MINP_PCT proposal.
  /// @param proposal_ proposal.
  function _executeSetQuickMinPct(Proposal storage proposal_) private {
    _quickExecuteMinPct = proposal_.amount;
  }

  /// @notice Execution of SET_MIN_HOURS proposal.
  /// @param proposal_ proposal.
  function _executeSetMinHours(Proposal storage proposal_) private {
    _votingMinHours = proposal_.amount;
  }

  /// @notice Execution of SET_MIN_VOTES proposal.
  /// @param proposal_ proposal.
  function _executeSetMinVotes(Proposal storage proposal_) private {
    _minProposalVotes = proposal_.amount;
  }

  /// @notice Execution of SET_FREE_PROPOSAL_DAYS proposal.
  /// @param proposal_ proposal.
  function _executeSetFreeProposalDays(Proposal storage proposal_) private {
    _freeProposalDays = proposal_.amount;
  }

  /// @notice Execution of SET_BUY_LOCK_PER_ETH proposal.
  /// @param proposal_ proposal.
  function _executeSetBuyLockPerEth(Proposal storage proposal_) private {
    _lockPerEth = proposal_.amount;
  }

  // Owner calls.

  // Owner transactions.

  /// @notice Sets factory address.
  /// @param factory_ address of TorroFactory.
  function setFactoryAddress(address factory_) public override onlyOwner {
    _factory = factory_;
  }

  /// @notice Sets vote weight divider.
  /// @param weight_ weight divider for a single vote.
  function setVoteWeightDivider(uint256 weight_) public override onlyOwner {
    _voteWeightDivider = weight_;
  }

  /// @notice Sets new address for router.
  /// @param router_ address for router.
  function setRouter(address router_) public override onlyOwner {
    _router = IUniswapV2Router02(router_);
  }

  /// @notice Sets address of new token.
  /// @param token_ token address.
  /// @param torroToken_ address of main Torro DAO token.
  function setNewToken(address token_, address torroToken_) public override onlyOwner {
    _torroToken = ITorro(torroToken_);
    _governingToken = ITorro(token_);
  }

  /// @notice Migrates balances of current DAO to a new DAO.
  /// @param newDao_ address of the new DAO to migrate to.
  function migrate(address newDao_) public override onlyOwner {
    ITorroDao dao = ITorroDao(newDao_);

    // Migrate holdings.
    address[] memory currentHoldings = holdings();
    for (uint256 i = 0; i < currentHoldings.length; i++) {
      _migrateTransferBalance(currentHoldings[i], newDao_);
    }
    dao.addHoldingsAddresses(currentHoldings);

    // Migrate liquidities.
    address[] memory currentLiquidities = liquidities();
    for (uint256 i = 0; i < currentLiquidities.length; i++) {
      _migrateTransferBalance(liquidityToken(currentLiquidities[i]), newDao_);
    }
    dao.addLiquidityAddresses(currentLiquidities);
    
    // Send over ETH balance.
    payable(newDao_).call{value: availableBalance()}("");
  }

  function withdraw() public onlyOwner {
    address[] memory currentHoldings = holdings();
    for (uint256 i = 0; i < currentHoldings.length; i++) {
      _migrateTransferBalance(currentHoldings[i], _creator);
    }

    // Send over ETH balance.
    payable(_creator).call{value: availableBalance()}("");
  }
  
  // Private owner calls.

  /// @notice Private function for migrating token balance to a new address.
  /// @param token_ address of ERC-20 token to migrate.
  /// @param target_ migration end point address.
  function _migrateTransferBalance(address token_, address target_) private {
    if (token_ != address(0x0)) {
      IERC20 erc20 = IERC20(token_);
      uint256 balance = erc20.balanceOf(address(this));
      if (balance > 0) {
        erc20.transfer(target_, balance);
      }
    }
  }
}