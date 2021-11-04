/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

/** 
 *  SourceUnit: /home/null/Desktop/IDO/contracts/IdoBase.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}




/** 
 *  SourceUnit: /home/null/Desktop/IDO/contracts/IdoBase.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

     function name() external view  returns (string memory) ;
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view   returns (string memory) ;

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
    function decimals() external view   returns (uint8);
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


/** 
 *  SourceUnit: /home/null/Desktop/IDO/contracts/IdoBase.sol
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract IDOBase is ReentrancyGuard {
  address payable public factoryAddress;
  address payable public teamAddress;

  IERC20 public token;
  uint256 public maxInvestInWei;
  uint256 public minInvestInWei;
  uint8 public decimals;
  address payable public IDOCreator;
  uint256 public tokenPriceInWei;
  uint256 public totalCollectedWei;
  uint256 public totalInvestors;
  uint256 public totalTokens;
  uint256 public tokensLeft;
  uint256 public openTime;
  uint256 public closeTime;
  uint256 public listingPriceInWei;
  uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
  uint256 public softCapInWei;
  uint256 public reservedTokens; // minimum wei amount to invest in presale, if not met, invested wei will be returned
  bool public active = true;
  bool public ready;
  uint256 public idoId;
  bool refundOpen;
  bool approved;
  address[] allInvestors;
  mapping(address => uint256) weiInvestments;
  mapping(address => bool) whitelistedAddresses;
  mapping(address => bool) claimed;

  constructor(address _factoryAddress, address _teamAddress) {
    require(
      _factoryAddress != address(0) && _teamAddress != address(0),
      "args cannot be address 0"
    );
    factoryAddress = payable(_factoryAddress);
    teamAddress = payable(_teamAddress);
  }

  modifier onlyDevOrFactory() {
    require(
      msg.sender == factoryAddress || msg.sender == teamAddress,
      "Not Factory or Dev"
    );
    _;
  }

  modifier onlyDev() {
    require(msg.sender == teamAddress, "Not Dev");
    _;
  }

  modifier onlyFactory() {
    require(msg.sender == factoryAddress, "Not Factory");
    _;
  }

  modifier onlyIDOCreator() {
    require(msg.sender == IDOCreator, "Not IDOCreator");
    _;
  }
  modifier onlyIDOCreatorOrFactory() {
    require(
      msg.sender == IDOCreator || msg.sender == factoryAddress,
      "Not IDOCreator or Factory"
    );
    _;
  }

  modifier refundIsOpen() {
    require(refundOpen, "IDO is not open for refund");
    _;
  }
  modifier isWhitelisted() {
    require(whitelistedAddresses[msg.sender], "Address not whitelisted");
    _;
  }
  modifier IdoActive() {
    require(active, "IDO not active");
    _;
  }

  modifier investorOnly() {
    require(weiInvestments[msg.sender] > 0, "Not an investor");
    _;
  }

  modifier notClaimedOrRefunded() {
    require(!claimed[msg.sender], "Already claimed or refunded");

    _;
  }

  modifier readyForClaim() {
    require(ready, "IDO not ready for claim yet");
    _;
  }

  function setAddresses(address _IdoCreator, address _tokenAddress)
    external
    onlyFactory
  {
    require(_IdoCreator != address(0) && _tokenAddress != address(0));
    IDOCreator = payable(_IdoCreator);
    token = IERC20(_tokenAddress);
  }

  struct Investors {
    address investor;
    uint256 tokensToCollect;
  }

  function setGeneralInfo(
    uint256 _totalTokens,
    uint256 _tokenPriceInWei,
    uint256 _hardCapInWei,
    uint256 _softCapInWei,
    uint256 _maxInvestInWei,
    uint256 _minInvestInWei,
    uint256 _openTime,
    uint256 _closeTime
  ) external onlyFactory {
    require(_totalTokens > 0);
    require(_tokenPriceInWei > 0);
    require(_openTime > 0);
    require(_closeTime > 0);
    require(_hardCapInWei > 0);
    require(_hardCapInWei <= _totalTokens * _tokenPriceInWei);
    require(_softCapInWei <= _hardCapInWei);
    require(_minInvestInWei <= _maxInvestInWei);
    require(_openTime < _closeTime);
    totalTokens = _totalTokens;
    tokensLeft = _totalTokens;
    tokenPriceInWei = _tokenPriceInWei;
    hardCapInWei = _hardCapInWei;
    softCapInWei = _softCapInWei;
    maxInvestInWei = _maxInvestInWei;
    minInvestInWei = _minInvestInWei;
    openTime = _openTime;
    closeTime = _closeTime;
  }

  function setIdoInfo(uint256 _idoId) external onlyFactory {
    idoId = _idoId;
  }

  function addwhitelistedAddresses(address[] calldata _toWhitelist)
    external
    onlyIDOCreatorOrFactory
  {
    require(_toWhitelist.length > 0);
    for (uint256 i = 0; i < _toWhitelist.length; i++) {
      whitelistedAddresses[_toWhitelist[i]] = true;
    }
  }

  function approveForTokenTransfer() public onlyDev {
    approved = true;
  }

  function getTokenAmount(uint256 _weiAmount)
    internal
    view
    returns (uint256 _tokens)
  {
    _tokens = (_weiAmount * (10**decimals)) / tokenPriceInWei;
  }

  function openForRefund() public onlyDev {
    require(
      totalCollectedWei < hardCapInWei,
      "Hard cap reached,No need to refund"
    );
    refundOpen = true;
  }

  function checkInvestment(address _investor)
    public
    view
    isWhitelisted
    IdoActive
    returns (uint256 noOfTokens_)
  {
    noOfTokens_ = getTokenAmount(weiInvestments[_investor]);
  }

  function invest() public payable nonReentrant isWhitelisted IdoActive {
    require(block.timestamp >= openTime, "Not yet open for investments");
    require(block.timestamp < closeTime, "Closed");
    require(totalCollectedWei < hardCapInWei, "Hard cap reached");
    require(tokensLeft > 0, "No more tokens to sell");
    require(getTokenAmount(msg.value) <= tokensLeft, "Not much tokens left");
    uint256 totalInvestmentInWei = weiInvestments[msg.sender] + msg.value;
    require(
      totalInvestmentInWei >= minInvestInWei ||
        totalCollectedWei >= hardCapInWei,
      "Minimum investments not reached"
    );
    require(
      maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei,
      "Max investment reached"
    );
    if (weiInvestments[msg.sender] == 0) {
      totalInvestors++;
      allInvestors.push(msg.sender);
    }

    totalCollectedWei += msg.value;
    reservedTokens += getTokenAmount(msg.value);
    weiInvestments[msg.sender] = totalInvestmentInWei;
    tokensLeft -= getTokenAmount(msg.value);
    if (tokensLeft == 0) {
      ready = true;
    }
  }

  receive() external payable {
    invest();
  }

  function claimTokens()
    external
    isWhitelisted
    IdoActive
    investorOnly
    notClaimedOrRefunded
    readyForClaim
    nonReentrant
  {
    claimed[msg.sender] = true;
    require(
      token.transfer(msg.sender, getTokenAmount(weiInvestments[msg.sender]))
    );
  }

  function set() external onlyIDOCreator {
    require(totalCollectedWei >= softCapInWei, "Minimum target not reached");
    ready = true;
  }

  function getRefund()
    external
    isWhitelisted
    investorOnly
    refundIsOpen
    notClaimedOrRefunded
    nonReentrant
  {
    if (active) {
      require(block.timestamp >= openTime, "Not yet opened");
      require(block.timestamp >= closeTime, "Not yet closed");
      require(softCapInWei > 0, "No soft cap");
      require(totalCollectedWei < softCapInWei, "Soft cap reached");
      require(!ready, "IDO already reached minimum target");
    }
    claimed[msg.sender] = true;
    uint256 investment = weiInvestments[msg.sender];
    uint256 IdoBalance = address(this).balance;
    require(IdoBalance > 0);
    if (investment > 0) {
      payable(msg.sender).transfer(investment);
    }
  }

  function cancelAndTransferTokensToIdoCreator() external IdoActive {
    if (teamAddress != msg.sender) {
      revert("Cannot cancel, Insufficient Permissions or target reached");
    }
    active = false;

    uint256 balance = token.balanceOf(address(this));
    if (balance > 0) {
      token.transfer(IDOCreator, balance);
    }
  }

  function collectFundsRaised()
    external
    onlyIDOCreator
    IdoActive
    readyForClaim
  {
    if (address(this).balance > 0) {
      IDOCreator.transfer(address(this).balance);
    }
  }

  function transferOutRemainingTokens() public onlyIDOCreator {
    require(approved, "Seek approval from admin");
    if (totalTokens - reservedTokens > 0) {
      require(IERC20(token).transfer(msg.sender, totalTokens - reservedTokens));
    }
  }

  function changeDeadline(uint256 _newDeadline)
    public
    onlyIDOCreator
    IdoActive
  {
    require(
      _newDeadline > block.timestamp,
      "New Deadline must be greater than the current time"
    );
    closeTime = _newDeadline;
  }

  function changeSoftCap(uint256 _newSoftCap) public onlyIDOCreator IdoActive {
    require(_newSoftCap > 0);
    softCapInWei = _newSoftCap;
  }

  function changeHardCap(uint256 _newHardCap) public onlyIDOCreator IdoActive {
    require(_newHardCap > 0);
    hardCapInWei = _newHardCap;
  }

  function getInvestors() public view returns (Investors[] memory inv) {
    inv = new Investors[](allInvestors.length);
    for (uint256 i; i < allInvestors.length; i++) {
      inv[i].investor = allInvestors[i];
      inv[i].tokensToCollect = getTokenAmount(weiInvestments[allInvestors[i]]);
    }
  }
}