// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./TAP.sol";
import "./TAPw.sol";
import "./Vote.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// For passing votes to other functions / testing as you cannot
// pass mappings as params
struct RecipientToVote {
  address recipient;
  uint256 vote;
}

contract Vault is Ownable {
  // Contracts
  address voteContract;
  TAP TAPToken;
  TAPw TAPwToken;

  // Percent to burn before fund distribution
  uint256 public burnPercent;
  uint256 public burnPercentDecimals;

  // TAP foundation wallet
  address foundationWallet;

  // Distribution schedule variables
  bool public is7DayDistributionSent;
  bool public is21DayDistributionSent;
  uint256 timeOfLastVoteEnd;
  uint256 monthlyTotalVotes;
  uint256 distributionAmountTAPw;
  uint256 distributionAmountTAP;

  // Reward users get for distributing the funds
  uint256 wishReward;

  constructor(address _foundationWallet) {
    burnPercent = 50;
    burnPercentDecimals = 0;

    foundationWallet = _foundationWallet;
    wishReward = 10 * 10**18;
  }

  modifier onlyVoteContract() {
    require(msg.sender == voteContract, "Can only be called by vote contract");
    _;
  }

  function setContractAddresses(
    address _voteContract,
    address TAPAddress,
    address TAPwAddress
  ) public onlyOwner {
    voteContract = _voteContract;
    TAPToken = TAP(TAPAddress);
    TAPwToken = TAPw(TAPwAddress);
  }

  function setWishReward(uint256 reward) public onlyOwner {
    wishReward = reward;
  }

  // Sets the burn percent to _burnPercent / 10 ** _burnPercentDecimals
  // e.g setBurnPercent(12, 1) = 1.2%
  function setBurnPercent(uint256 _burnPercent, uint256 _burnPercentDecimals)
    public
    onlyOwner
  {
    burnPercent = _burnPercent;
    burnPercentDecimals = _burnPercentDecimals;
  }

  function setFoundationWallet(address newAddress) public onlyOwner {
    foundationWallet = newAddress;
  }

  // Gets the amount that would be burned given the current burn amount
  function getBurnAmount(uint256 amount) public view returns (uint256) {
    uint256 numerator = amount * burnPercent;
    uint256 denominator = 100 * (10**burnPercentDecimals);
    return numerator / denominator;
  }

  // Returns the portion a recipient would be eligible to recieve if they had 'recipientVotes'
  // votes out of a total of 'totalVotes' and the total pool amounted to totalDistributionAmount
  function getDistributionAmount(
    uint256 recipientVotes,
    uint256 totalVotes,
    uint256 totalDistributionAmount
  ) public pure returns (uint256) {
    require(
      recipientVotes <= totalVotes,
      "A recipient cannot have more votes than the total"
    );
    if (totalVotes == 0) return 0;
    uint256 numerator = recipientVotes * totalDistributionAmount;
    return numerator / totalVotes;
  }

  // Seven day distribution can be triggered if it has not already been sent and 7 days has elapsed
  function canTrigger7DayDistribution() public view returns (bool) {
    bool has7DaysElapsed = block.timestamp >= timeOfLastVoteEnd + 7 days;
    return !is7DayDistributionSent && has7DaysElapsed;
  }

  // Returns the seconds until the 7 day distribution can be called
  // If the distribution has already been sent or 7 days has passed, it returns -1
  function timeToTrigger7DayDistribution() external view returns (int256) {
    // If distribution sent, or time has elapsed, return -1
    if (block.timestamp > timeOfLastVoteEnd + 7 days || is7DayDistributionSent)
      return -1;
    // Else returns the difference in seconds between 7 days from the monthly vote end and
    // the current time
    else return int256(timeOfLastVoteEnd + 7 days - block.timestamp);
  }

  // 21 day distribution can be triggered if it has not already been sent and 21 days has elapsed
  function canTrigger21DayDistribution() public view returns (bool) {
    bool has21DaysElapsed = block.timestamp >= timeOfLastVoteEnd + 21 days;
    return !is21DayDistributionSent && has21DaysElapsed;
  }

  // Returns the seconds until the 21 day distribution can be called
  // If the distribution has already been sent or 21 days has passed, it returns -1
  function timeToTrigger21DayDistribution() external view returns (int256) {
    // If distribution sent, or time has elapsed, return -1
    if (
      block.timestamp > timeOfLastVoteEnd + 21 days || is21DayDistributionSent
    ) return -1;
    // Else returns the difference in seconds between 21 days from the monthly vote end and
    // the current time
    else return int256(timeOfLastVoteEnd + 21 days - block.timestamp);
  }

  // Gets the most recent vote count
  function getRecipientToVotesArray()
    internal
    view
    returns (RecipientToVote[] memory)
  {
    return Vote(voteContract).getLastMonthVotes();
  }

  // This will be called on the first of every month
  function initiateMonthlyDistribution(uint256 totalVotes)
    public
    onlyVoteContract
  {
    // Burn and mint to foundation
    uint256 TAPwBalance = TAPwToken.balanceOf(address(this));
    uint256 remaining;
    if (TAPwBalance > 0) {
      // burn a designated percent of the TAPw
      uint256 wishToBurn = getBurnAmount(TAPwBalance);
      TAPwToken.burn(wishToBurn);
      // Get the remaining TAPw in the wallet
      remaining = TAPwToken.balanceOf(address(this));
      // Transfer half of the remaining to the foundation
      TAPwToken.transfer(foundationWallet, remaining / 2);
    }

    // Prepare variables for next distribution
    monthlyTotalVotes = totalVotes;
    timeOfLastVoteEnd = block.timestamp;
    is7DayDistributionSent = false;
    is21DayDistributionSent = false;

    // Distribution amount must be set as fees will come in later and change balance
    distributionAmountTAPw = TAPwToken.balanceOf(address(this)) / 2;
    distributionAmountTAP = TAPToken.balanceOf(address(this)) / 2;
  }

  // Distributes funds 7 days after initiateMonthlyDistribution is called
  function distribute7Days() public {
    require(canTrigger7DayDistribution(), "This function cannot be called yet");
    distributeFunds();
    is7DayDistributionSent = true;
  }

  // Distributes funds 21 days after initiateMonthlyDistribution is called
  function distribute21Days() public {
    require(
      canTrigger21DayDistribution(),
      "This function cannot be called yet"
    );
    distributeFunds();
    is21DayDistributionSent = true;
  }

  // Distributes funds according to the amount of votes a recipient has in the previous month
  function distributeFunds() internal {
    RecipientToVote[] memory distribution = getRecipientToVotesArray();
    // Sends TAP and TAPw to each recipient
    for (uint256 i; i < distribution.length; i++) {
      uint256 TAPwRecipientAmount = getDistributionAmount(
        distribution[i].vote,
        monthlyTotalVotes,
        distributionAmountTAPw
      );
      uint256 TAPRecipientAmount = getDistributionAmount(
        distribution[i].vote,
        monthlyTotalVotes,
        distributionAmountTAP
      );
      TAPwToken.transfer(distribution[i].recipient, TAPwRecipientAmount);
      TAPToken.transfer(distribution[i].recipient, TAPRecipientAmount);
    }
    // Mints a reward to the caller of this function
    TAPwToken.mint(msg.sender, wishReward);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./TAPw.sol";

contract TAP is ERC20, AccessControl {
  using SafeERC20 for ERC20;

  // reference to the $WISH coin
  TAPw private immutable Wish;
  uint256 wishReward;
  uint256 wishRewardDecimals;

  address vaultAddress;
  uint256 public vaultFee;
  uint256 public vaultFeeDecimals;

  address foundationAddress;
  uint256 public foundationFee;
  uint256 public foundationFeeDecimals;

  bool public waiveFees;

  mapping(address => bool) _isRecipient;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  mapping(address => bool) public whitelist;

  modifier onlyValidAddress(address wallet) {
    require(wallet != address(0), "The address cannot be the zero address");
    require(wallet != msg.sender, "The address cannot be the sender");
    require(wallet != vaultAddress, "The address cannot be the vault");
    require(
      wallet != foundationAddress,
      "The address cannot be the foundation"
    );
    require(wallet != address(this), "The address cannot be the contract");
    _;
  }

  modifier onlyAdmin() {
    require(
      hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender),
      "Address does not have admin permission"
    );
    _;
  }

  modifier onlyOwner() {
    require(
      hasRole(OWNER_ROLE, msg.sender),
      "Address does not have owner permission"
    );
    _;
  }

  constructor(
    TAPw _wish,
    address _vaultAddress,
    address _foundationAddress
  ) ERC20("Thoughts and Prayers", "TAP-v3") {
    _setupRole(OWNER_ROLE, msg.sender);
    _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
    _mint(msg.sender, 10000000000 * 10**decimals()); // 10 billion

    Wish = _wish;

    vaultAddress = _vaultAddress;
    foundationAddress = _foundationAddress;

    whitelist[vaultAddress] = true;
    whitelist[foundationAddress] = true;

    // set the Foundation fee to be 0.5%
    setFoundationFee(5, 1);
    // set the Vault fee to be 0.5%
    setVaultFee(5, 1);
    // set the WISH reward to be 10%
    setWISHReward(10, 0);
  }

  // Sets the fee percentage for the foundation wallet
  function setFoundationFee(uint256 fee, uint256 feeDecimals) public onlyAdmin {
    require(fee > 0, "The TAP Foundation fee must be greater than 0");

    foundationFee = fee;
    foundationFeeDecimals = feeDecimals;
  }

  // Sets the fee percentage for the TAP Vault
  function setVaultFee(uint256 fee, uint256 feeDecimals) public onlyAdmin {
    require(fee > 0, "The TAP Vault fee must be greater than 0");

    vaultFee = fee;
    vaultFeeDecimals = feeDecimals;
  }

  // Sets the TAPw reward
  function setWISHReward(uint256 reward, uint256 decimals) public onlyAdmin {
    require(reward >= 0, "The TAPw reward must not be less than 0");

    wishReward = reward;
    wishRewardDecimals = decimals;
  }

  // Toggles the in-built transaction fee on and off for all transactions
  function toggleTransactionFees() public onlyAdmin {
    waiveFees = !waiveFees;
  }

  // add a wallet address to the whitelist
  function exemptFromFee(address wallet)
    public
    onlyAdmin
    onlyValidAddress(wallet)
  {
    whitelist[wallet] = true;
  }

  // remove a wallet address from the whitelist
  function includeInFee(address wallet)
    public
    onlyAdmin
    onlyValidAddress(wallet)
  {
    whitelist[wallet] = false;
  }

  // update the vault contract address
  function updateTAPVaultAddress(address newAddress) public onlyAdmin {
    vaultAddress = newAddress;
  }

  // update the foundation wallet address
  function updateFoundationAddress(address newAddress) public onlyAdmin {
    foundationAddress = newAddress;
  }

  // number of tokens to hold as the fee
  function calculatePortion(
    uint256 _amount,
    uint256 _feePercentage,
    uint256 _feeDecimals
  ) public pure returns (uint256) {
    uint256 numerator = _amount * _feePercentage;
    // 2, because e.g. 1% = 1 * 10^-2 = 0.01
    uint256 denominator = 10**(_feeDecimals + 2);
    return numerator / denominator;
  }

  function getFees(uint256 amount) public view returns (uint256, uint256) {
    uint256 tokensForFoundation = calculatePortion(
      amount,
      foundationFee,
      foundationFeeDecimals
    );
    uint256 tokensForVault = calculatePortion(
      amount,
      vaultFee,
      vaultFeeDecimals
    );
    return (tokensForVault, tokensForFoundation);
  }

  function donate(address to, uint256 amount, bool claimingWish) public {
    // only mint TAPw to the donor if donating (not simply transferring)
    require(_isRecipient[to], "'To' address must be a recipient");
    
    transfer(to, amount);

    if (claimingWish) {
      uint256 wishAmount = calculatePortion(
        amount,
        wishReward,
        wishRewardDecimals
      );
      Wish.mint(msg.sender, wishAmount);
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(amount > 0, "The amount must be greater than 0");
    require(
      balanceOf(from) >= amount,
      "ERC20: transfer amount exceeds balance"
    );

    uint256 tokensForVault;
    uint256 tokensForFoundation;
    uint256 remainder = amount;

    // calculate the number of tokens the Vault should take
    if (!whitelist[to] && !whitelist[msg.sender] && !waiveFees) {
      (tokensForVault, tokensForFoundation) = getFees(amount);
      remainder -= tokensForVault;
      remainder -= tokensForFoundation;
    }

    super._transfer(from, vaultAddress, tokensForVault);
    super._transfer(from, foundationAddress, tokensForFoundation);
    super._transfer(from, to, remainder);
  }

  function setRecipientStatus(address recipient, bool recipientStatus)
    public
    onlyAdmin
  {
    _isRecipient[recipient] = recipientStatus;
  }

  function updateRecipientWallet(address oldAddress, address newAddress)
    public
    onlyAdmin
  {
    require(
      _isRecipient[oldAddress] == true,
      "The old wallet address is not a recipient"
    );
    require(
      _isRecipient[newAddress] == false,
      "The new wallet address is already a recipient"
    );
    _isRecipient[oldAddress] = false;
    _isRecipient[newAddress] = true;
  }

  function isRecipient(address recipient) public view returns (bool) {
    return _isRecipient[recipient];
  }

  function setAdmin(address admin) public onlyOwner {
    grantRole(ADMIN_ROLE, admin);
  }

  function transferOwnership(address owner) public onlyOwner {
    grantRole(OWNER_ROLE, owner);
    revokeRole(OWNER_ROLE, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TAPw is ERC20, AccessControl, ERC20Burnable {
  address public tapAddress;

  address vaultAddress;
  uint256 public vaultFee;
  uint256 public vaultFeeDecimals;

  address foundationAddress;
  uint256 public foundationFee;
  uint256 public foundationFeeDecimals;

  bool public waiveFees;
  mapping(address => bool) public whitelist;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  modifier onlyAuthContractsOrOwner() {
    require(
      msg.sender == tapAddress ||
        hasRole(OWNER_ROLE, msg.sender) ||
        msg.sender == vaultAddress,
      "Address is not TAP, Vault, or Owner"
    );
    _;
  }

  modifier onlyAdmin() {
    require(
      hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender),
      "Address does not have admin permission"
    );
    _;
  }

  modifier onlyValidAddress(address wallet) {
    require(wallet != address(0), "The address cannot be the zero address");
    require(wallet != msg.sender, "The address cannot be the sender");
    require(wallet != vaultAddress, "The address cannot be the wishing well");
    require(
      wallet != foundationAddress,
      "The address cannot be the foundation"
    );
    require(wallet != address(this), "The address cannot be the contract");
    _;
  }

  constructor(address _vaultAddress, address _foundationAddress)
    ERC20("Wish", "TAPw-v3")
  {
    vaultAddress = _vaultAddress;
    foundationAddress = _foundationAddress;

    whitelist[vaultAddress] = true;
    whitelist[foundationAddress] = true;

    _setupRole(OWNER_ROLE, msg.sender);
    _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);

    // set the Foundation fee to be 0.5%
    setVaultFee(5, 1);
    // set the Vault fee to be 0.5%
    setFoundationFee(5, 1);
  }

  function mint(address to, uint256 amount) public onlyAuthContractsOrOwner {
    _mint(to, amount);
  }

  // sets the $TAP token's address, once it's known
  function setTapAddress(address _tapAddress) public onlyAdmin {
    tapAddress = _tapAddress;
  }

  // Sets the fee percentage for the foundation wallet
  function setFoundationFee(uint256 fee, uint256 feeDecimals) public onlyAdmin {
    require(fee >= 0, "The TAP Foundation fee must be greater than 0");

    foundationFee = fee;
    foundationFeeDecimals = feeDecimals;
  }

  // Sets the fee percentage for the TAP Vault
  function setVaultFee(uint256 fee, uint256 feeDecimals) public onlyAdmin {
    require(fee >= 0, "The TAPw Wishing Well fee must be greater than 0");

    vaultFee = fee;
    vaultFeeDecimals = feeDecimals;
  }

  // Toggles the in-built transaction fee on and off for all transactions
  function toggleTransactionFees() public onlyAdmin {
    waiveFees = !waiveFees;
  }

  // add a wallet address to the whitelist
  function exemptFromFee(address wallet)
    public
    onlyAdmin
    onlyValidAddress(wallet)
  {
    whitelist[wallet] = true;
  }

  // remove a wallet address from the whitelist
  function includeInFee(address wallet)
    public
    onlyAdmin
    onlyValidAddress(wallet)
  {
    whitelist[wallet] = false;
  }

  // update the vault contract address
  function updateWishingWellAddress(address newAddress) public onlyAdmin {
    vaultAddress = newAddress;
  }

  // update the foundation wallet address
  function updateFoundationAddress(address newAddress) public onlyAdmin {
    foundationAddress = newAddress;
  }

  // number of tokens to hold as the fee
  function calculatePortion(
    uint256 _amount,
    uint256 _feePercentage,
    uint256 _feeDecimals
  ) internal pure returns (uint256) {
    uint256 numerator = _amount * _feePercentage;
    // 2, because e.g. 1% = 1 * 10^-2 = 0.01
    uint256 denominator = 10**(_feeDecimals + 2);
    return numerator / denominator;
  }

  function getFees(uint256 amount) public view returns (uint256, uint256) {
    uint256 tokensForFoundation = calculatePortion(
      amount,
      foundationFee,
      foundationFeeDecimals
    );
    uint256 tokensForVault = calculatePortion(
      amount,
      vaultFee,
      vaultFeeDecimals
    );
    return (tokensForVault, tokensForFoundation);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(amount > 0, "The amount must be greater than 0");
    require(
      balanceOf(from) >= amount,
      "ERC20: transfer amount exceeds balance"
    );
    require(
      balanceOf(from) >= amount,
      "ERC20: transfer amount exceeds balance"
    );

    uint256 tokensForWishingWell;
    uint256 tokensForFoundation;
    uint256 remainder = amount;

    // calculate the number of tokens the Wishing Well should take
    if (!whitelist[to] && !whitelist[msg.sender] && !waiveFees) {
      (tokensForWishingWell, tokensForFoundation) = getFees(amount);
      remainder -= tokensForWishingWell;
      remainder -= tokensForFoundation;
    }

    super._transfer(from, vaultAddress, tokensForWishingWell);
    super._transfer(from, foundationAddress, tokensForFoundation);
    super._transfer(from, to, remainder);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TAPw.sol";
import "./TAP.sol";
import "./Vault.sol";

import { BokkyPooBahsDateTimeLibrary } from "./BokkyPooBahsDateTimeLibrary.sol";

struct _Vote {
  address from;
  address to;
  uint256 amount;
  uint256 timestamp;
  bool isVoted;
}

contract Vote is Ownable {
  // Tokens
  TAPw _TAPwToken;
  TAP _TAPToken;

  // Mapping of vote Ids to votes
  mapping(bytes32 => _Vote) voteId;

  event Voted(
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 indexed timestamp
  );

  // A variable used to 'reset' the mapping of recipients to votes.
  // When a reset is needed, this value is incremented
  uint256 recipientVotesResets;
  mapping(uint256 => mapping(address => uint256)) recipientVotes;

  address[] public recipients;
  // Variable to determine if recipient has already been added to array
  // for the current vote period
  mapping(uint256 => mapping(address => bool)) isRecipientCounted;

  uint256 totalVotes;

  // An array keeping track of last months recipient-to-vote count
  // Note RecipientToVote is defined in Vault.sol
  RecipientToVote[] lastMonthVotes;

  // Current month of voting
  uint256 public _currentMonth;
  uint256 public _currentYear;

  Vault vault;

  constructor(
    address wishAddress,
    address tapAddress,
    address _vaultAddress
  ) {
    _TAPwToken = TAPw(wishAddress);
    _TAPToken = TAP(tapAddress);
    vault = Vault(_vaultAddress);
    (_currentYear, _currentMonth, ) = BokkyPooBahsDateTimeLibrary
      .timestampToDate(block.timestamp);
  }

  function setVaultAddress(address newVaultAddress) public onlyOwner {
    vault = Vault(newVaultAddress);
  }

  // This assumes this contract has the approval of the user to spend wish
  function vote(
    address to,
    uint256 amount,
    bytes32 key
  ) public {
    require(
      _TAPToken.isRecipient(to),
      "You cannot vote for an account that is not a recipient"
    );
    require(voteId[key].timestamp == 0, "This vote already exists");
    require(amount > 0, "Vote must be greater than zero");
    require(votePeriodEnd() > block.timestamp, "The voting period has ended");
    _TAPwToken.transferFrom(msg.sender, address(this), amount);
    (uint256 wishingWellFee, uint256 foundationFee) = _TAPwToken.getFees(
      amount
    );
    voteId[key] = _Vote(
      msg.sender,
      to,
      amount - wishingWellFee - foundationFee,
      block.timestamp,
      true
    );
    if (!isRecipientCounted[recipientVotesResets][to]) {
      recipients.push(to);
      isRecipientCounted[recipientVotesResets][to] = true;
    }
    recipientVotes[recipientVotesResets][to] += amplify(
      amount - wishingWellFee - foundationFee,
      block.timestamp
    );
    totalVotes += amplify(
      amount - wishingWellFee - foundationFee,
      block.timestamp
    );
    emit Voted(
      msg.sender,
      to,
      amount - wishingWellFee - foundationFee,
      block.timestamp
    );
  }

  function getVote(bytes32 id)
    public
    view
    returns (
      address,
      address,
      uint256,
      uint256,
      bool
    )
  {
    return (
      voteId[id].to,
      voteId[id].from,
      voteId[id].amount,
      voteId[id].timestamp,
      voteId[id].isVoted
    );
  }

  // Returns the end of the voting period
  function votePeriodEnd() public view returns (uint256) {
    // initalises the end of the voting period to the beginning of next month
    uint256 currentMonth = _currentMonth;
    uint256 currentYear = _currentYear;
    if (++currentMonth == 13) {
      currentMonth = 1;
      currentYear++;
    }
    return
      BokkyPooBahsDateTimeLibrary.timestampFromDate(
        currentYear,
        currentMonth,
        1
      );
  }

  function votePeriodStart() public view returns (uint256) {
    (uint256 currentYear, , ) = BokkyPooBahsDateTimeLibrary.timestampToDate(
      block.timestamp
    );
    return
      BokkyPooBahsDateTimeLibrary.timestampFromDate(
        currentYear,
        _currentMonth,
        1
      );
  }

  function unvote(bytes32 key) public {
    require(
      voteId[key].from == msg.sender,
      "You do not have permission unvote this vote"
    );
    require(voteId[key].isVoted, "This vote is already unvoted");
    require(
      voteId[key].timestamp > votePeriodStart(),
      "You can only unvote a vote from this month"
    );
    _TAPwToken.transfer(msg.sender, voteId[key].amount);
    voteId[key].isVoted = false;
    recipientVotes[recipientVotesResets][voteId[key].to] -= amplify(
      voteId[key].amount,
      block.timestamp
    );
    totalVotes -= amplify(voteId[key].amount, block.timestamp);
  }

  // Increase vote by 1% per day from when the vote is locked
  function amplify(uint256 amount, uint256 timestamp)
    public
    view
    returns (uint256)
  {
    require(
      votePeriodEnd() > timestamp,
      "Timestamp cannot be greater than end of voting period"
    );
    // days between the end of the voting period and the vote timestamp
    // where the first day gives a plus votePeriod% bonus
    uint256 daysSince = BokkyPooBahsDateTimeLibrary.diffDays(
      timestamp,
      votePeriodEnd()
    );
    // Increases the original vote by the days it has been locked
    return increaseByPercentage(amount, daysSince);
  }

  // Increases an amount by a percentage. E.g. if amount: 100, percentage: 12
  // are passed in as params, the result will be 112.
  function increaseByPercentage(uint256 amount, uint256 percentage)
    public
    pure
    returns (uint256)
  {
    uint256 increase = (amount * percentage) / 100;
    return amount + increase;
  }

  // Returns the percentage increase a vote would have if voted at the current time
  function getVotingPower() public view returns (uint256) {
    return
      1 +
      BokkyPooBahsDateTimeLibrary.diffDays(block.timestamp, votePeriodEnd());
  }

  // Sets class variables for total number of votes
  function countVotes() public view returns (RecipientToVote[] memory) {
    RecipientToVote[] memory recipientToVotes = new RecipientToVote[](
      recipients.length
    );
    for (uint256 i; i < recipients.length; i++) {
      recipientToVotes[i] = RecipientToVote(
        recipients[i],
        recipientVotes[recipientVotesResets][recipients[i]]
      );
    }
    return recipientToVotes;
  }

  function copyMemoryToLastMonthVotes(RecipientToVote[] memory array) internal {
    for (uint256 i; i < array.length; i++) {
      lastMonthVotes.push(array[i]);
    }
  }

  // Returns an array of structs containing a recipient address and their votes
  function getLastMonthVotes() public view returns (RecipientToVote[] memory) {
    return lastMonthVotes;
  }

  function endVotingPeriod() public {
    require(
      block.timestamp > votePeriodEnd(),
      "The voting period has not ended"
    );
    delete lastMonthVotes;
    copyMemoryToLastMonthVotes(countVotes());
    (_currentYear, _currentMonth, ) = BokkyPooBahsDateTimeLibrary
      .timestampToDate(block.timestamp);
    uint256 TAPwBalance = _TAPwToken.balanceOf(address(this));
    if (TAPwBalance > 0) {
      _TAPwToken.transfer(address(vault), TAPwBalance);
    }
    vault.initiateMonthlyDistribution(totalVotes);
    delete recipients;
    recipientVotesResets++;
    totalVotes = 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}