/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/bounty-board/packages/truffle/contracts/Escrow.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/bounty-board/packages/truffle/contracts/Escrow.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
  enum State {
    AWAITING_PAYMENT,
    AWAITING_DELIVERY,
    COMPLETE
  }

  struct Bounty {
    State state;
    address payable contributor;
    address payable payer;
    IERC20 token;
    uint256 value;
    uint256 expirationDays;
    uint256 depositTimestamp;
    Levels contributorLevel;
  }

  enum Levels {
    GUEST_PASS,
    LEVEL_0,
    LEVEL_1,
    LEVEL_2
  }

  uint256 public constant ONE = 10**18;

  mapping(Levels => uint256) private _firstPaymentPercentage;
  mapping(bytes32 => Bounty) private _bounties; // bouty hash => State

  address private _owner;

  modifier onlyPayer(bytes32 bountyHash) {
    require(msg.sender == _bounties[bountyHash].payer, "ONLY_BOUNTY_PAYER");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "ONLY_OWNER");
    _;
  }

  constructor() {
    _owner = msg.sender;
  }

  function firstPaymentPercentage(Levels level) public view returns (uint256) {
    return _firstPaymentPercentage[level];
  }

  function bounties(bytes32 bountyHash)
    public
    view
    returns (Bounty memory bouty)
  {
    return _bounties[bountyHash];
  }

  function balance() public view returns (uint256) {
    return address(this).balance;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function changeOwner(address newOwner) public onlyOwner {
    _owner = newOwner;
  }

  fallback() external payable {}

  function changeFirstPaymentPercentage(Levels level, uint256 newPercentage)
    public
    onlyOwner
  {
    _firstPaymentPercentage[level] = newPercentage;
  }

  modifier notZeroAddress(address addr) {
    require(addr != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
    _;
  }

  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );

  event Transfer(address indexed from, address indexed to, uint256 tokens);

  function hashBountyInfo(
    string memory title,
    string memory description,
    string memory doneCriteria,
    string memory reward
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(title, description, doneCriteria, reward));
  }

  function defineNewBounty(
    bytes32 bountyHash,
    IERC20 token_,
    address payable contributor_,
    address payable payer_,
    uint256 value_,
    uint256 expirationDays_,
    Levels contributorLevel_
  ) public notZeroAddress(contributor_) notZeroAddress(payer_) {
    _bounties[bountyHash].contributor = contributor_;
    _bounties[bountyHash].token = token_;
    _bounties[bountyHash].payer = payer_;
    _bounties[bountyHash].value = value_;
    _bounties[bountyHash].expirationDays = expirationDays_;
    _bounties[bountyHash].contributorLevel = contributorLevel_;
  }

  function getContributorPercentage(Levels contributorLevel)
    public
    view
    returns (uint256)
  {
    return firstPaymentPercentage(contributorLevel);
  }

  function deposit(uint256 amount, bytes32 bountyHash)
    external
    payable
    onlyPayer(bountyHash)
  {
    require(amount == _bounties[bountyHash].value, "WRONG_BOUNTY_VALUE");

    require(
      _bounties[bountyHash].state == State.AWAITING_PAYMENT,
      "BOUNTY_ALREADY_PAYED_FOR"
    );

    _bounties[bountyHash].depositTimestamp = block.timestamp;

    _bounties[bountyHash].state = State.AWAITING_DELIVERY;

    uint256 contributorPercentage = getContributorPercentage(
      _bounties[bountyHash].contributorLevel
    );

    uint256 contributorReceivalbe = (_bounties[bountyHash].value *
      contributorPercentage) / ONE;

    // value is subtracted here in case contributor initial percentage changes afterwards
    _bounties[bountyHash].value =
      (_bounties[bountyHash].value * (ONE - contributorPercentage)) /
      ONE;

    require(
      _bounties[bountyHash].token.transferFrom(
        msg.sender,
        address(this),
        _bounties[bountyHash].value
      ),
      "TOKEN_NOT_APPROVED"
    );
    require(
      _bounties[bountyHash].token.transferFrom(
        msg.sender,
        _bounties[bountyHash].contributor,
        contributorReceivalbe
      ),
      "TOKEN_NOT_APPROVED"
    );
  }

  uint256 constant daysInSeconds = 24 * 60 * 60;

  function emergencyWithdrawal(bytes32 bountyHash)
    public
    onlyPayer(bountyHash)
  {
    require(
      block.timestamp - _bounties[bountyHash].depositTimestamp >
        _bounties[bountyHash].expirationDays * daysInSeconds,
      "FUNDS_STILL_IN_ESCROW"
    );

    uint256 amount = _bounties[bountyHash].value; ////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
    _bounties[bountyHash].value = 0;
    require(_bounties[bountyHash].token.transfer(msg.sender, amount));
  }

  function confirmDelivery(bytes32 bountyHash) external onlyPayer(bountyHash) {
    require(
      _bounties[bountyHash].state == State.AWAITING_DELIVERY,
      "BOUNTY_NOT_DEPOSITED"
    );
    _bounties[bountyHash].state = State.COMPLETE;

    _bounties[bountyHash].token.transfer(
      _bounties[bountyHash].contributor,
      _bounties[bountyHash].value
    );
  }
}