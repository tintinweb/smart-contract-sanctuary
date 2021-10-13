// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title Token
 * @dev API interface for interacting with the Grexie Token contract
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);

  function balanceOf(address _owner) external view returns (uint256 balance);
}

/**
 * @title GrexieICO
 * @dev GrexieICO contract is Ownable
 **/
contract GrexieICO is Ownable {
  using SafeMath for uint256;
  Token private token;

  bool public hasStarted = false;
  bool public hasEnded = false;

  uint256 private dividend = 10**18 * 10**6 * 10**18;
  uint256 private divisor = 10**18 * 1;
  uint256 public issue = 1;

  uint256 private constant ALPHA = 600 * 10**12 * 10**18;
  uint256 private constant GAMMA = 1 * 10**6 * 10**18;

  uint256 private _initialAlpha;
  uint256 private _alpha;
  uint256 private _alphaMinusGamma;

  uint256 public sentTokens = 0;

  mapping(bytes32 => bool) private _transactionHashes;
  address private _signer;

  /**
   * ReceivedTokens
   * @dev Log tokens received onto the blockchain
   */
  event ReceivedTokens(address indexed to, uint256 value);

  /**
   * ReceivedAffiliateTokens
   * @dev Log tokens received as an affiliate onto the blockchain
   */
  event ReceivedAffiliateTokens(address indexed to, uint256 value);

  /**
   * whenContractIsActive
   * @dev ensures that the contract is still active
   **/
  modifier whenContractIsActive() {
    // Check if sale is active
    require(isActive(), 'contract is not active');
    _;
  }

  /**
   * onlyUser
   * @dev guard contracts from calling method
   **/
  modifier onlyUser() {
    require(msg.sender == tx.origin);
    _;
  }

  /**
   * GrexieICO
   * @dev GrexieICO constructor
   **/
  constructor(
    address _tokenAddr,
    uint256 initialAlpha,
    uint256 initialDivisor,
    uint256 initialIssue,
    uint256 initialSentTokens
  ) public {
    require(_tokenAddr != address(0));
    token = Token(_tokenAddr);

    _initialAlpha = initialAlpha;
    issue = initialIssue;
    divisor = initialDivisor;
    sentTokens = initialSentTokens;
    _alpha = initialAlpha.mul(100).div(110);
    _alphaMinusGamma = _alpha.sub(GAMMA);
  }

  /**
   * start
   * @dev Start the contract
   **/
  function start() public onlyOwner {
    require(hasStarted == false, 'can only be initialized once');
    require(
      tokensAvailable() >= _initialAlpha,
      'must have enough tokens allocated'
    );
    hasStarted = true;
  }

  /**
   * end
   * @dev End the contract
   **/
  function end() public onlyOwner {
    require(hasStarted == true, 'contract not started');
    require(hasEnded == false, 'contract already ended');
    hasEnded = true;
  }

  /**
   * isActive
   * @dev Determines if the contract is still active
   **/
  function isActive() public view returns (bool) {
    return (hasStarted == true && hasEnded == false && goalReached() == false); // Goal must not already be reached
  }

  /**
   * goalReached
   * @dev Function to determine is goal has been reached
   **/
  function goalReached() public view returns (bool) {
    uint256 tokens = dividend.div(divisor);

    return sentTokens >= ALPHA || tokens == 0;
  }

  /**
   * Recovers the address for an ECDSA signature and transaction hash
   * @return address The address that was used to sign the transaction
   **/
  function recoverAddress(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private pure returns (address) {
    bytes memory prefix = '\x19Ethereum Signed Message:\n32';
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));

    return ecrecover(prefixedHash, v, r, s);
  }

  /**
   * isValidSignature
   * @dev checks whether the signature is valid and checks whether it has been
   * used before
   **/
  function isValidSignature(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private view returns (bool) {
    require(
      !_transactionHashes[hash],
      'signature has already been used for a previous transaction'
    );

    return recoverAddress(hash, v, r, s) == _signer;
  }

  /**
   * setSigner
   * @dev sets the signer address for the ICO contract
   **/
  function setSigner(address signer) public payable onlyOwner {
    require(signer != owner);

    _signer = signer;
  }

  function nextTokens()
    public
    view
    whenContractIsActive
    returns (uint256, uint256)
  {
    uint256 tokens = dividend.div(divisor);

    return (issue, tokens);
  }

  /**
   * receiveTokens
   * @dev function that gives away available tokens for free
   **/
  function receiveTokens(
    address affiliate,
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable whenContractIsActive onlyUser {
    require(msg.value == 0, 'you should not send currency to this contract');
    require(msg.sender != affiliate, 'message sender cannot be affiliate');
    require(isValidSignature(hash, v, r, s), 'invalid signature');

    uint256 tokens = calculateNextTokens();

    if (affiliate == address(0)) {
      require(
        tokens <= tokensAvailable(),
        'trying to allocate more tokens than are available'
      );

      emit ReceivedTokens(msg.sender, tokens);

      sentTokens = sentTokens.add(tokens);
    } else {
      uint256 affiliateTokens = tokens.div(10);
      uint256 totalTokens = tokens.add(affiliateTokens);

      require(
        totalTokens <= tokensAvailable(),
        'trying to allocate more tokens than are available'
      );

      emit ReceivedTokens(msg.sender, tokens);
      emit ReceivedAffiliateTokens(affiliate, affiliateTokens);

      sentTokens = sentTokens.add(totalTokens);

      token.transfer(affiliate, affiliateTokens);
    }

    _transactionHashes[hash] = true;
    token.transfer(msg.sender, tokens);
  }

  /**
   * sendTokens
   * @dev function that sends iterations worth of tokens for free
   **/
  function sendTokens(address user, uint256 iterations)
    public
    payable
    whenContractIsActive
    onlyOwner
  {
    require(msg.value == 0, 'you should not send currency to this contract');
    require(user != address(0), 'cannot be used to burn tokens');
    require(iterations > 0, 'at least 1 iteration is required');

    uint256 totalTokens = 0;

    for (uint256 i = 0; i < iterations; i = i.add(1)) {
      uint256 tokens = calculateNextTokens();

      totalTokens = totalTokens.add(tokens);
    }

    require(
      totalTokens <= tokensAvailable(),
      'trying to allocate more tokens than are available'
    );

    sentTokens = sentTokens.add(totalTokens);

    emit ReceivedTokens(user, totalTokens);

    token.transfer(user, totalTokens);
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() public onlyOwner {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(address(this));
    assert(balance > 0);
    token.transfer(owner, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }

  function calculateNextTokens()
    private
    whenContractIsActive
    returns (uint256)
  {
    uint256 tokens = dividend.div(divisor);

    divisor = divisor.mul(_alpha).div(_alphaMinusGamma);
    issue = issue.add(1);

    return tokens;
  }
}